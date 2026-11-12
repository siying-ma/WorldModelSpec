"""The stage transition commands (`harness/tools/stage.py`) on a synthetic repository with a run at a
handed-over checkpoint: the transition table (review refused, labels from review only), every
precondition refusing with nothing written, the file classification with its effects, the scope
carried and only widened, the transaction stopped after every write point and continued, the
confirmation against a remote run branch, and the adoption of a run made before stages from its old
checkout (a `git init` repository whose own `python -m harness` is a stand-in recording its call).

The handoff export and verify for stages and the snapshot are other tracks' work; they are stood in
for here by functions with the agreed signatures that do what their contracts say."""
import hashlib
import json
import os
import shutil
import subprocess
import sys
import tempfile
import unittest
import uuid
from contextlib import contextmanager
from pathlib import Path
from unittest import mock

from harness import loop
from harness.phases import candidate, integrate, label_check
from harness.store import jsonl, owner, paths, snapshot, stages
from harness.store.state import Options, RUN_VERSION
from harness.tools import handoff, stage
from scripts.tests.test_split_handoff import SnapshotWhole, TOOLCHAIN

REAL_EXPORT = handoff.export
AGENT = Path(__file__).resolve().parents[2]


def sha(p: Path) -> str:
    return hashlib.sha256(p.read_bytes()).hexdigest()


def git(root: Path, *args: str) -> str:
    p = subprocess.run(["git", "-C", str(root), "-c", "user.name=t", "-c", "user.email=t@t", "-c", "commit.gpgsign=false", *args],
                       capture_output=True, text=True)
    if p.returncode != 0:
        raise AssertionError(f"git {args}: {p.stderr}")
    return p.stdout.strip()


FILES = {"harness/phases/label_check.py": "# check\n", "harness/phases/label_repair.py": "# repair\n",
         "harness/checks/gate.py": "# gate\n", "harness/loop.py": "# loop\n", "harness/tools/handoff.py": "# handoff\n",
         "harness/phases/review.py": "# concept review\n", "harness/model/definitions.py": "# resolver\n",
         "recorded/scoring.py": "# score\n", "prompts/plan.md": "plan\n", "ontology/ATOMS.md": "# atoms\n",
         "config/x.json": "{}", "library/Explain.lean": "-- explain\n",
         "laws.jsonl": "", "definitions.jsonl": "", "reading.json": "{\"params\": []}", "precedence.json": "{}",
         "pyproject.toml": "[project]\n", "scripts/run-generation.sh": "# launcher\n",
         "scripts/diagnostics/doctor.py": "# doctor\n"}


def build_repo(agent: Path, extra: dict | None = None) -> None:
    for rel, text in {**FILES, **(extra or {})}.items():
        (agent / rel).parent.mkdir(parents=True, exist_ok=True)
        (agent / rel).write_text(text)
    shutil.copytree(AGENT / "library" / "TrafficSpec" / "Core", agent / "library" / "TrafficSpec" / "Core", dirs_exist_ok=True)
    (agent / ".gitignore").write_text("*.lock\n.run.owner.json\n__pycache__/\n")


# -- the stand-ins for the other tracks' interfaces -------------------------------------------------

def fake_export(run_id, source_baseline="", transition=None):
    """The handoff export for a staged run: the active stage's baseline, its id and the stage record's digest."""
    rd = paths.run_dir(run_id)
    if transition is None and stages.transition_refusal(rd):
        raise SystemExit("[handoff] " + stages.transition_refusal(rd))
    bad = handoff.checkpoint_problems(run_id)
    if bad:
        raise SystemExit("[handoff] not at a checkpoint: " + "; ".join(bad))
    active = stages.active_stage(rd)
    files = handoff.artifact_files(run_id)
    m = {"export_id": uuid.uuid4().hex, "run": run_id, "baseline": active["code_baseline"], "semantic": active["semantic"],
         "acceptance_policy": {k: v for k, v in active["acceptance_policy"].items() if k != "review"},
         "stage_id": active["stage_id"], "stages_sha256": stages.stages_sha256(rd), "artifacts": {f: sha(paths.REPO / f) for f in files}}
    hd = rd / "handoff"
    jsonl.write_atomic(hd / "manifest.json", json.dumps(m, indent=1))
    listed = files + [(hd / "manifest.json").relative_to(paths.REPO).as_posix(), (hd / "files.txt").relative_to(paths.REPO).as_posix()]
    jsonl.write_atomic(hd / "files.txt", "".join(f + "\n" for f in listed))
    return m


def fake_verify(run_id, artifacts=True, for_transition=False):
    rd = paths.run_dir(run_id)
    m = jsonl.read_json(rd / "handoff" / "manifest.json", None)
    if m is None:
        return ["no manifest"], []
    bad = []
    if artifacts:
        miss = [f for f, h in m["artifacts"].items() if not (paths.REPO / f).is_file() or sha(paths.REPO / f) != h]
        if miss:
            bad.append(f"handed file(s) not as exported: {miss}")
    active = stages.active_stage(rd)
    if active is not None:
        if m.get("stage_id") != active["stage_id"]:
            bad.append("manifest stage is not the active stage")
        if m.get("stages_sha256") != stages.stages_sha256(rd):
            bad.append("stages_sha256 differs")
        if not for_transition and active["code_baseline"]["code"]["digest"] != handoff.code_digest()["digest"]:
            bad.append("code differs from the stage's baseline")
    if not for_transition and stages.transition_refusal(rd):
        bad.append(stages.transition_refusal(rd))
    return bad, []


def fake_snapshot_write(run_id, stage_id, transition_id):
    f = paths.run_dir(run_id) / stages.STAGES_DIR / stage_id / "manifest.json"
    m = {"stage_id": stage_id, "transition_id": transition_id}
    if not f.exists():
        jsonl.write_atomic(f, json.dumps(m))
    return jsonl.read_json(f, None)


SNAPSHOT_PROBLEMS: list = []


def fake_snapshot_verify(run_id, stage_id=None):
    return list(SNAPSHOT_PROBLEMS)


class Crash(BaseException):
    pass


@contextmanager
def patched(agent: Path, results_owner_root: Path | None = None):
    """The harness pointed at the synthetic repository `agent`, with the stand-ins."""
    lib = agent / "library"
    layout = {**paths.library_layout(lib), "REPO": agent, "RESULTS": agent / "results"}
    tool = agent.parent / "ontology_provenance" / "nrs_tools" / "atoms_train.py"
    with mock.patch.multiple(paths, **layout), mock.patch.object(paths, "FOREIGN_ROOTS", []), \
            mock.patch.object(paths, "ontology_tool", lambda name: tool if tool.is_file() else None), \
            mock.patch.object(handoff, "toolchain", lambda: TOOLCHAIN), \
            mock.patch.object(owner, "acquire_for_command", lambda name: None), \
            mock.patch.object(owner, "acquire_for_transition",                     # the takeover's check, without the lock
                              lambda run_id, transition: owner.transitions_refusal((run_id, transition))), \
            mock.patch.object(handoff, "export", fake_export), mock.patch.object(handoff, "verify", fake_verify), \
            mock.patch.object(snapshot, "write", fake_snapshot_write), mock.patch.object(snapshot, "verify", fake_snapshot_verify), \
            mock.patch.object(loop, "_GENERATED_DIGESTS", {}):
        yield


def make_run(agent: Path, run_id: str = "r", roots=()) -> Path:
    opts = Options(run_id=run_id, laws=agent / "laws.jsonl", ontology=agent / "ontology" / "ATOMS.md",
                   reading=agent / "reading.json", definition_precedence=agent / "precedence.json")
    rd = paths.run_dir(run_id)
    rd.mkdir(parents=True)
    (rd / "options.json").write_text(json.dumps({**{k: v if isinstance(v, (bool, int, float)) else str(v)
                                                    for k, v in opts.__dict__.items() if v is not None},
                                                 "base_reading": str(opts.reading), "semantic": loop.semantic_inputs(opts),
                                                 "base_run": None, "budget_peers": [], "repo_roots": [str(agent), *roots]}))
    (rd / "state.json").write_text(json.dumps({**SnapshotWhole.empty(run_id), "iteration": 1, "prog": {"stage": "done"}}))
    for name in ("ledger.jsonl", "concept_ledger.jsonl", "node_ledger.jsonl", "accepted_nodes.jsonl", "accepted_concepts.jsonl"):
        (rd / name).write_text("")
    from harness.lean import index_sync
    index_sync.write_index()                             # the registries as every commit leaves them, before the freeze
    label_check.freeze(rd)
    return rd


def first_stage(run_id: str = "r", kind: str = "generation", scope="all", sid: str | None = None) -> dict:
    """A stage record written by hand: the run's first stage on this checkout's code."""
    rd = paths.run_dir(run_id)
    sem = stage._options(run_id) and loop.semantic_inputs(stage._options(run_id))
    row = {"event": "open", "run_id": run_id, "stage_id": sid or kind[0].upper() + "0", "stage_kind": kind,
           "launch_kinds": list(stages.LAUNCH_KINDS[kind]), "previous_stage_id": None, "transition_id": "t-first",
           "input_checkpoint": None, "code_baseline": {"source_commit": stage._head(paths.REPO), "code": handoff.code_digest()},
           "state_schema": RUN_VERSION, "semantic": sem, "acceptance_policy": {"label_repair": False, "dependency": "build_usable_v1",
                                                                               "review": "none"},
           "scope": scope, "changed_files": [], "effects": stage.effects_at(paths.REPO, sem), "prompts_approved": None, "opened_at": "x"}
    (rd / stages.STAGES_FILE).write_text(json.dumps(row) + "\n")
    fake_export(run_id)
    return row


def tree_bytes(root: Path) -> dict:
    return {p.relative_to(root).as_posix(): p.read_bytes() for p in sorted(root.rglob("*"))
            if p.is_file() and ".git" not in p.relative_to(root).parts and not p.name.endswith(".lock")}


COMPLETE = {"complete": True, "reason_if_null": None, "laws": {"generated": ["A", "B", "C"], "generating": [], "waiting_provider": {},
                                                               "to_plan": {}, "blocked": {}, "failed": [], "revoked": {}}}


def report(generated, others=None, complete=False):
    return {"complete": complete, "reason_if_null": None,
            "laws": {"generated": list(generated), "generating": list(others or []), "waiting_provider": {}, "to_plan": {},
                     "blocked": {}, "failed": [], "revoked": {}}}


class World:
    """A run `r` at a handed-over checkpoint of its first stage, in a git checkout with a bare remote."""

    def __init__(self, t: Path, kind: str = "generation", scope="all"):
        self.t = t
        self.root = t / "repo"
        self.remote = t / "remote.git"
        build_repo(self.root)
        git(self.root, "init", "-q", "-b", "main")
        git(self.root, "add", "-A"); git(self.root, "commit", "-q", "-m", "baseline")
        subprocess.run(["git", "init", "-q", "--bare", str(self.remote)], check=True)
        git(self.root, "remote", "add", "origin", str(self.remote))
        self.kind, self.scope = kind, scope

    def setup(self):
        self.rd = make_run(self.root)
        self.g0 = first_stage(kind=self.kind, scope=self.scope)

    def push(self) -> str:
        git(self.root, "add", "-A"); git(self.root, "commit", "-q", "--allow-empty", "-m", "checkpoint")
        git(self.root, "push", "-q", "origin", "HEAD:refs/heads/runs/r")
        return git(self.root, "rev-parse", "HEAD")

    def change(self, rel: str, text: str = "# changed\n", commit: bool = True):
        """The next stage's code: one file changed and, as the launcher does before a transition,
        committed (only that file), unless `commit` is false."""
        f = self.root / rel
        f.parent.mkdir(parents=True, exist_ok=True)
        f.write_text((f.read_text() if f.exists() else "") + text)
        if commit:
            git(self.root, "add", "--", rel); git(self.root, "commit", "-q", "-m", f"new code: {rel}", "--", rel)


@contextmanager
def world(kind: str = "generation", scope="all", gen=COMPLETE):
    with tempfile.TemporaryDirectory() as t:
        w = World(Path(t), kind, scope)
        with patched(w.root), mock.patch.object(stage, "_generation", lambda run_id: gen):
            SNAPSHOT_PROBLEMS.clear()
            w.setup()
            yield w


class Table(unittest.TestCase):
    """Only the allowed transitions; review refused before anything, labels from review only."""

    def test_review_is_refused_before_anything_is_written(self):
        with world() as w:
            before = tree_bytes(w.root)
            with mock.patch.object(owner, "acquire_for_command", side_effect=AssertionError("no lock is taken")):
                with self.assertRaises(SystemExit) as e:
                    stage.enter("r", "review", "G0", "t1")
            self.assertIn(stages.REVIEW_REFUSAL, str(e.exception))
            self.assertEqual(tree_bytes(w.root), before)

    def test_labels_from_generation_is_refused_with_its_own_reason(self):
        with world() as w:
            before = tree_bytes(w.root)
            with self.assertRaises(SystemExit) as e:
                stage.enter("r", "labels", "G0", "t1")
            self.assertIn(stages.LABELS_REFUSAL, str(e.exception))
            self.assertEqual(tree_bytes(w.root), before)

    def test_labels_to_labels_is_allowed(self):
        with world(kind="labels") as w:
            w.change("scripts/run-generation.sh")
            rec = stage.enter("r", "labels", "L0", "t1")
            self.assertEqual((rec["status"], rec["to"]), ("exported", "L1"))
            self.assertEqual(stages.active_stage(w.rd)["launch_kinds"], ["labels"])

    def test_generation_to_generation_records_the_stage(self):
        with world() as w:
            w.change("scripts/run-generation.sh")
            head = git(w.root, "rev-parse", "HEAD")
            rec = stage.enter("r", "generation", "G0", "t1", source_commit=head)
            rows = stages.read_stages(w.rd)
            self.assertEqual([r["event"] for r in rows], ["open", "close", "open"])
            close, opened = rows[1], rows[2]
            m = jsonl.read_json(w.rd / "handoff" / "manifest.json", None)
            self.assertEqual(close["output_checkpoint"]["export_id"], w.g0 and opened["input_checkpoint"]["export_id"])
            self.assertEqual(opened["stage_id"], "G1")
            self.assertEqual(opened["previous_stage_id"], "G0")
            self.assertEqual(opened["code_baseline"], {"source_commit": head, "code": handoff.code_digest()})
            self.assertEqual(opened["changed_files"], [{"path": "scripts/run-generation.sh", "class": "tool"}])
            self.assertEqual(opened["acceptance_policy"]["review"], "none")
            self.assertEqual(set(opened["effects"]), {"gate", "scoring", "generated_prompts", "prompts"})
            self.assertEqual(opened["state_schema"], RUN_VERSION)
            self.assertEqual((m["stage_id"], m["stages_sha256"]), ("G1", stages.stages_sha256(w.rd)))
            self.assertEqual(rec["status"], "exported")
            self.assertIsNotNone(stages.transition_refusal(w.rd))          # every launch refused until it is confirmed


class Preconditions(unittest.TestCase):
    """Each precondition broken alone refuses, and nothing of the run or the library is written."""

    def refused(self, w, words, *a, **k):
        before = tree_bytes(w.root)
        with self.assertRaises(SystemExit) as e:
            stage.enter("r", *a, **k) if a else stage.enter("r", "generation", "G0", "t1", **k)
        self.assertIn(words, str(e.exception))
        self.assertIn("nothing was written", str(e.exception))
        self.assertEqual(tree_bytes(w.root), before)

    def test_the_library_owned_by_another_process(self):
        with world() as w:
            with mock.patch.object(owner, "acquire_for_transition", side_effect=SystemExit("another process owns the library")):
                before = tree_bytes(w.root)
                with self.assertRaisesRegex(SystemExit, "another process owns"):
                    stage.enter("r", "generation", "G0", "t1")
                self.assertEqual(tree_bytes(w.root), before)

    def test_from_is_not_the_active_stage(self):
        with world() as w:
            self.refused(w, "the active stage is `G0`, not `G7`", "generation", "G7", "t1")

    def test_no_stage_record(self):
        with world() as w:
            (w.rd / stages.STAGES_FILE).unlink()
            self.refused(w, "stage adopt")

    def test_not_at_a_checkpoint(self):
        with world() as w:
            s = json.loads((w.rd / "state.json").read_text()); s["prog"] = {"stage": "code"}
            (w.rd / "state.json").write_text(json.dumps(s))
            self.refused(w, "short of `done`")

    def test_manifest_of_another_stage(self):
        with world() as w:
            m = json.loads((w.rd / "handoff" / "manifest.json").read_text()); m["stage_id"] = "G9"
            (w.rd / "handoff" / "manifest.json").write_text(json.dumps(m))
            self.refused(w, "names the stage `G9`")

    def test_disk_not_the_last_export(self):
        with world() as w:
            (w.rd / "summary.json").write_text("{}")
            fake_export("r")
            (w.rd / "summary.json").write_text('{"status": "x"}')
            self.refused(w, "not as exported")

    def test_an_active_label_repair_or_a_deferred_concept(self):
        for key, val, words in (("label_states", {"A": {"state": "repairing", "active": {"task": "x"}}}, "label repair(s) active: A"),
                                ("deferred_concepts", [{"id": "c"}], "concept review(s) deferred")):
            with self.subTest(key=key), world() as w:
                s = json.loads((w.rd / "state.json").read_text()); s[key] = val
                (w.rd / "state.json").write_text(json.dumps(s))
                label_check.freeze(w.rd); fake_export("r")
                self.refused(w, words)

    def test_another_transition_in_progress(self):
        with world() as w:
            jsonl.write_atomic(w.rd / stages.TRANSITION_FILE, json.dumps({"transition_id": "t0", "status": "prepared", "action": "enter"}))
            self.refused(w, "`t0` stopped at `prepared`")

    def test_a_second_transition_from_the_same_stage(self):
        with world() as w:
            w.change("scripts/run-generation.sh")
            stage.enter("r", "generation", "G0", "t1")
            commit = w.push()
            stage.confirm("r", "t1", commit)
            self.refused(w, "already left by the transition `t1`", "generation", "G0", "t2")

    def test_replacing_generation_code_asks_nothing_of_generation(self):
        """A code fix in the middle of generation is not held to generation being complete."""
        with world(gen=report(["A"], ["B"])) as w:
            w.change("scripts/run-generation.sh")
            stage.enter("r", "generation", "G0", "t1")
            self.assertEqual(stages.active_stage(w.rd)["scope"], "all")

    def test_forbidden_and_unclassified_files(self):
        for rel, words in (("ontology/ATOMS.md", "no transition may change"),
                           ("harness/model/definitions.py", "no transition may change"),
                           ("harness/phases/review.py", "no transition may change"),
                           ("prompts/review_concept.md", "no transition may change"),
                           ("harness/loop.py", "in no class a transition allows"),
                           ("harness/__main__.py", "in no class a transition allows")):
            with self.subTest(rel=rel), world() as w:
                w.change(rel, "-- changed\n")
                self.refused(w, words)
                self.refused(w, rel)

    def test_a_snapshot_not_whole_stops_before_the_transition(self):
        with world() as w:
            SNAPSHOT_PROBLEMS.append("blob x differs")
            with self.assertRaisesRegex(SystemExit, "blob x differs"):
                stage.enter("r", "generation", "G0", "t1")
            self.assertIsNone(stages.transition_state(w.rd))
            self.assertEqual([r["stage_id"] for r in stages.read_stages(w.rd)], ["G0"])


class BaselineCommit(unittest.TestCase):
    """The new stage's baseline commit holds the code it runs, so a clean checkout of it restores the stage."""

    def test_uncommitted_code_is_refused_and_a_commit_holding_it_is_taken(self):
        with world() as w:
            w.change("scripts/run-generation.sh", commit=False)
            before = tree_bytes(w.root)
            with self.assertRaisesRegex(SystemExit, "code differs from the baseline commit .*scripts/run-generation.sh"):
                stage.enter("r", "generation", "G0", "t1")                       # HEAD does not hold the new code
            with self.assertRaisesRegex(SystemExit, "is not a commit of this checkout"):
                stage.enter("r", "generation", "G0", "t1", source_commit="0" * 40)
            self.assertEqual(tree_bytes(w.root), before)
            git(w.root, "add", "--", "scripts/run-generation.sh")
            git(w.root, "commit", "-q", "-m", "new code", "--", "scripts/run-generation.sh")
            head = git(w.root, "rev-parse", "HEAD")
            git(w.root, "commit", "-q", "--allow-empty", "-m", "a later commit")   # the baseline is named, not HEAD
            stage.enter("r", "generation", "G0", "t1", source_commit=head)
            self.assertEqual(stages.active_stage(w.rd)["code_baseline"]["source_commit"], head)


class Classification(unittest.TestCase):
    """Effects decide before paths: gate, scoring with and without a fixed comparison set, generated text."""

    def test_gate_and_tool_changes_are_recorded(self):
        with world() as w:
            w.change("harness/checks/gate.py"); w.change("scripts/diagnostics/doctor.py")
            stage.enter("r", "generation", "G0", "t1")
            self.assertEqual(stages.active_stage(w.rd)["changed_files"],
                             [{"path": "harness/checks/gate.py", "class": "gate"}, {"path": "scripts/diagnostics/doctor.py", "class": "tool"}])

    def test_scoring_change_allowed_until_the_comparison_set_is_fixed(self):
        with world() as w:
            w.change("recorded/scoring.py")
            (w.rd / "comparison_set.json").write_text("{}")
            fake_export("r")
            before = tree_bytes(w.root)
            with self.assertRaisesRegex(SystemExit, "no transition may change: recorded/scoring.py"):
                stage.enter("r", "generation", "G0", "t1")
            self.assertEqual(tree_bytes(w.root), before)
        with world() as w:
            w.change("recorded/scoring.py")
            stage.enter("r", "generation", "G0", "t1")
            self.assertEqual(stages.active_stage(w.rd)["changed_files"], [{"path": "recorded/scoring.py", "class": "scoring"}])

    def test_the_classes_of_library_files(self):
        """A library file changed is also refused by the checkpoint (the run's freeze covers the
        library); its class is decided here alone."""
        was, now = {"gate": "g", "scoring": "s", "generated_prompts": "p"}, {"gate": "g", "scoring": "s2", "generated_prompts": "p"}
        files = ["library/TrafficSpec/Core/Extra.lean", "library/TrafficSpec/Core.lean", "library/lakefile.lean",
                 "library/lean-toolchain", "library/lake-manifest.json", "scripts/RegionKinds.lean", handoff.DOCTOR_TOOL,
                 "library/Explain.lean", "library/Main.lean"]
        changed = {c["path"]: c["class"] for c in stage.classify({}, {f: "x" for f in files}, was, now, True)}
        self.assertEqual(changed, {**{f: "forbidden" for f in files[:-1]}, "library/Main.lean": "unclassified"})
        changed = {c["path"]: c["class"] for c in stage.classify({}, {"library/Explain.lean": "x"}, was, now, False)}
        self.assertEqual(changed, {"library/Explain.lean": "scoring"})
        self.assertEqual(stage.classify({}, {}, was, now, True), [{"path": "(scoring digest)", "class": "forbidden"}])

    def test_a_tool_that_changes_the_generated_prompts_is_generated_text(self):
        with world() as w:
            w.change("harness/tools/handoff.py")
            with mock.patch.object(loop, "generated_prompts_digest", lambda core: "other"):
                with self.assertRaisesRegex(SystemExit, "give --prompts-approved ([0-9a-f]{64})") as e:
                    stage.enter("r", "generation", "G0", "t1")
                digest = e.exception.args[0].split("--prompts-approved ")[1].split()[0]
                with self.assertRaisesRegex(SystemExit, "is not the digest"):
                    stage.enter("r", "generation", "G0", "t1", prompts_approved="0" * 64)
                stage.enter("r", "generation", "G0", "t1", prompts_approved=digest)
            opened = stages.active_stage(w.rd)
            self.assertEqual(opened["changed_files"], [{"path": "harness/tools/handoff.py", "class": "generated_text"}])
            self.assertEqual(opened["prompts_approved"], digest)
            self.assertEqual(digest, stage.prompts_digest(opened["semantic"]))

    def test_a_written_prompt_needs_approval(self):
        with world() as w:
            w.change("prompts/plan.md")
            with self.assertRaisesRegex(SystemExit, "give --prompts-approved"):
                stage.enter("r", "generation", "G0", "t1")
            sem = loop.semantic_inputs(stage._options("r"))
            stage.enter("r", "generation", "G0", "t1", prompts_approved=stage.prompts_digest(sem))
            self.assertEqual(stages.active_stage(w.rd)["changed_files"], [{"path": "prompts/plan.md", "class": "generated_text"}])

    def test_the_effect_digests_are_the_harness_own_on_this_checkout(self):
        self.assertEqual(stage.gate_digest_at(paths.REPO), integrate.gate_digest())
        self.assertEqual(stage.scoring_version_at(paths.REPO), label_check.scoring_version())
        from harness.phases import review
        self.assertTrue({f"prompts/{p}" for p in review.CONCEPT_REVIEW_PROMPTS} <= stage.FORBIDDEN_FILES)
        for rel in stage.FORBIDDEN_FILES - {handoff.DOCTOR_TOOL}:
            self.assertTrue((paths.REPO / rel).is_file(), rel)


class Scope(unittest.TestCase):
    """The scope is carried, only widened, every law it covers generated when generation closes."""

    def write_scope(self, w, laws) -> str:
        f = w.t / f"scope-{len(laws)}.json"
        f.write_text(json.dumps(laws))
        return str(f)

    def test_generation_to_generation_keeps_the_scope_and_takes_none(self):
        with world(gen=report(["A", "B"], ["C"])) as w:
            with self.assertRaisesRegex(SystemExit, "narrowed only when generation is left for review"):
                stage.enter("r", "generation", "G0", "t1", scope=self.write_scope(w, ["A", "B"]))
            stage.enter("r", "generation", "G0", "t1")
            self.assertEqual(stages.active_stage(w.rd)["scope"], "all")
        with world(gen=report(["A", "B"], ["C"]), scope=stage.scope_value(["A"])) as w:
            with self.assertRaisesRegex(SystemExit, "replaced with its scope as it is"):
                stage.enter("r", "generation", "G0", "t1", scope=self.write_scope(w, ["A", "B"]))
            with self.assertRaisesRegex(SystemExit, "replaced with its scope as it is"):
                stage.enter("r", "generation", "G0", "t1", scope=self.write_scope(w, ["A"]))     # the scope it has
        with world(gen=COMPLETE) as w:
            with self.assertRaisesRegex(SystemExit, "replaced with its scope as it is"):
                stage.enter("r", "generation", "G0", "t1", scope="all")                          # `all` while it is `all`
            self.assertIsNone(stages.transition_state(w.rd))

    def test_the_first_choice_of_a_scope_is_on_entering_review(self):
        """Review is refused until a reviewer is registered, so the rule is pinned on `new_scope` itself."""
        with world(gen=report(["A", "B"], ["C"])) as w:
            g = {"stage_kind": "generation", "scope": "all"}
            new, why = stage.new_scope("r", g, "review", self.write_scope(w, ["A", "B"]))
            self.assertEqual((new, why), (stage.scope_value(["A", "B"]), []))
            self.assertTrue(new["partial"])
            self.assertIn("not generated: C", stage.new_scope("r", g, "review", self.write_scope(w, ["A", "B", "C"]))[1][0])
            self.assertIn("generation is not complete", stage.new_scope("r", g, "review", None)[1][0])
            listed = {"stage_kind": "generation", "scope": stage.scope_value(["A"])}
            self.assertIn("leaves out laws", stage.new_scope("r", listed, "review", self.write_scope(w, ["B"]))[1][0])
        with world(gen=COMPLETE) as w:
            self.assertEqual(stage.new_scope("r", {"stage_kind": "generation", "scope": "all"}, "review", None), ("all", []))

    def test_all_is_never_narrowed_past_generation(self):
        with world(kind="labels") as w:
            with self.assertRaisesRegex(SystemExit, "narrowed only when generation is left for review"):
                stage.enter("r", "labels", "L0", "t1", scope=self.write_scope(w, ["A"]))

    def test_labels_widening_needs_the_added_laws_generated(self):
        with world(kind="labels", scope=stage.scope_value(["A"]), gen=report(["A", "B"], ["C"])) as w:
            with self.assertRaisesRegex(SystemExit, "not generated: C"):
                stage.enter("r", "labels", "L0", "t1", scope=self.write_scope(w, ["A", "B", "C"]))
            stage.enter("r", "labels", "L0", "t1", scope=self.write_scope(w, ["A", "B"]))
            self.assertEqual(stages.active_stage(w.rd)["scope"]["laws"], ["A", "B"])

    def test_the_real_generation_report_on_a_run_with_no_law(self):
        with tempfile.TemporaryDirectory() as t:
            w = World(Path(t))
            with patched(w.root):
                w.setup()
                self.assertIs(stage._generation("r")["complete"], True)


class StoppedTransition(unittest.TestCase):
    """The transition stopped after every write point: the run is the whole old or the whole new
    stage, every launch is refused until it is done, another transition is refused, and running the
    same one again finishes it."""

    @staticmethod
    def counting(k: int):
        real_write, real_replace = jsonl.write_atomic, candidate._replace
        n = [0]

        def tick():
            n[0] += 1
            if n[0] == k:
                raise Crash(k)

        def write(path, text):
            real_write(path, text); tick()

        def replace(src, dst):
            real_replace(src, dst); tick()
        return mock.patch.multiple(jsonl, write_atomic=write), mock.patch.object(candidate, "_replace", replace), n

    def test_every_write_point(self):
        k, finished = 0, False
        while not finished and k < 30:
            k += 1
            with self.subTest(stop_after=k), world() as w:
                w.change("scripts/run-generation.sh")
                rows0 = stages.read_stages(w.rd)
                pw, pr, n = self.counting(k)
                try:
                    with pw, pr:
                        stage.enter("r", "generation", "G0", "t1")
                    finished = True
                except Crash:
                    pass
                if finished:
                    break
                candidate.recover_pending()                         # the library's next owner
                rows = stages.read_stages(w.rd)
                active = stages.active_stage(w.rd)["stage_id"]
                self.assertIn(active, ("G0", "G1"))
                self.assertEqual(rows[:1], rows0)
                self.assertEqual(len(rows), 1 if active == "G0" else 3)
                st = stages.transition_state(w.rd)
                if st is not None:
                    self.assertIsNotNone(stages.transition_refusal(w.rd))
                    self.assertTrue(fake_verify("r")[0])           # no launch, no handoff on a transition short of done
                    before = tree_bytes(w.root)
                    with self.assertRaises(SystemExit):
                        stage.enter("r", "generation", active, "t-other")
                    self.assertEqual(tree_bytes(w.root), before)
                rec = stage.enter("r", "generation", "G0", "t1")   # the same transition again, from its recorded state
                self.assertEqual(rec["status"], "exported")
                commit = w.push()
                stage.confirm("r", "t1", commit)
                self.assertEqual([r["stage_id"] for r in stages.read_stages(w.rd) if r["event"] == "open"], ["G0", "G1"])
                self.assertEqual(fake_verify("r"), ([], []))
                self.assertIsNone(stages.transition_refusal(w.rd))
                self.assertEqual(stage.enter("r", "generation", "G0", "t1")["status"], "done")
        self.assertGreaterEqual(k, 9)

    def test_confirm_stopped_after_each_write(self):
        k, finished = 0, False
        while not finished and k < 30:
            k += 1
            with self.subTest(stop_after=k), world() as w:
                w.change("scripts/run-generation.sh")
                stage.enter("r", "generation", "G0", "t1")
                commit = w.push()
                pw, pr, n = self.counting(k)
                try:
                    with pw, pr:
                        stage.confirm("r", "t1", commit)
                    finished = True
                except Crash:
                    pass
                stage.confirm("r", "t1", commit)
                self.assertEqual(stages.transition_state(w.rd)["status"], "done")
                self.assertEqual(fake_verify("r"), ([], []))

    def test_a_committed_journal_is_completed_by_the_next_owner(self):
        with world() as w:
            w.change("scripts/run-generation.sh")
            with mock.patch.object(candidate, "_apply", side_effect=Crash("stopped at the commit point")):
                with self.assertRaises(Crash):
                    stage.enter("r", "generation", "G0", "t1")
            self.assertEqual(candidate.pending(), w.rd / stages.JOURNAL_FILE)
            self.assertIn("not yet applied", " ".join(handoff.checkpoint_problems("r")))
            done = candidate.recover_pending()
            self.assertIn("stage transition t1", done)
            self.assertEqual(stages.active_stage(w.rd)["stage_id"], "G1")
            self.assertEqual(stages.transition_state(w.rd)["status"], "applied")
            self.assertEqual(stage.enter("r", "generation", "G0", "t1")["status"], "exported")

    def test_a_prepared_transition_on_changed_code_is_refused(self):
        with world() as w:
            w.change("scripts/run-generation.sh")
            with mock.patch.object(stage, "_commit", side_effect=Crash("stopped")):
                with self.assertRaises(Crash):
                    stage.enter("r", "generation", "G0", "t1")
            w.change("scripts/run-generation.sh", "# again\n")
            with self.assertRaisesRegex(SystemExit, "changed since the transition was prepared"):
                stage.enter("r", "generation", "G0", "t1")
            with self.assertRaisesRegex(SystemExit, "begun as `enter` with other arguments"):
                stage.enter("r", "generation", "G9", "t1")


class Confirm(unittest.TestCase):

    def test_the_commit_must_be_on_the_remote_branch_and_hold_the_export(self):
        with world() as w:
            w.change("scripts/run-generation.sh")
            stage.enter("r", "generation", "G0", "t1")
            git(w.root, "add", "-A"); git(w.root, "commit", "-q", "-m", "not pushed")
            local = git(w.root, "rev-parse", "HEAD")
            with self.assertRaisesRegex(SystemExit, "origin has no branch runs/r"):
                stage.confirm("r", "t1", local)
            git(w.root, "push", "-q", "origin", "HEAD~1:refs/heads/runs/r")
            with self.assertRaisesRegex(SystemExit, "is not on origin/runs/r"):
                stage.confirm("r", "t1", local)
            with self.assertRaisesRegex(SystemExit, "holds no results/r/stages.jsonl"):
                stage.confirm("r", "t1", git(w.root, "rev-parse", "HEAD~1"))
            commit = w.push()
            with self.assertRaisesRegex(SystemExit, "origin has no branch other"):
                stage.confirm("r", "t1", commit, branch="other")
            self.assertEqual(stage.confirm("r", "t1", commit)["status"], "done")
            self.assertEqual(stages.transition_state(w.rd)["commit"], commit)

    def test_confirm_leaves_the_run_as_its_export(self):
        """The transition record is among the exported artifacts while it is `exported`; once `done`,
        the run is exported again so the manifest names the files on disk."""
        with world() as w:
            w.change("scripts/run-generation.sh")
            stage.enter("r", "generation", "G0", "t1")
            st = json.loads((w.rd / stages.TRANSITION_FILE).read_text())
            self.assertEqual((st["transition_id"], st["status"]), ("t1", "exported"))
            self.assertTrue((w.rd / "handoff" / "files.txt").is_file())
            stage.confirm("r", "t1", w.push())
            st = json.loads((w.rd / stages.TRANSITION_FILE).read_text())
            self.assertEqual(st["status"], "done")
            self.assertEqual(fake_verify("r", artifacts=True), ([], []))
            m = jsonl.read_json(w.rd / "handoff" / "manifest.json", None)
            self.assertEqual(m["artifacts"]["results/r/stage_transition.json"], sha(w.rd / stages.TRANSITION_FILE))

    def test_a_commit_holding_another_record_is_refused(self):
        with world() as w:
            w.change("scripts/run-generation.sh")
            stage.enter("r", "generation", "G0", "t1")
            commit_tree = w.root / "results" / "r" / "handoff" / "manifest.json"
            was = commit_tree.read_bytes()
            commit_tree.write_bytes(was.replace(b'"stage_id"', b'"stage_id" ', 1))
            commit = w.push()
            commit_tree.write_bytes(was)
            with self.assertRaisesRegex(SystemExit, "holds another handoff/manifest.json"):
                stage.confirm("r", "t1", commit)


class Adopt(unittest.TestCase):
    """A run made before stages, adopted from its old checkout after the independent checks."""

    STUB = ("import json, os, pathlib, sys\n"
            "log = os.environ.get('S24_OLD_VERIFY_LOG')\n"
            "if log: pathlib.Path(log).write_text(json.dumps({'argv': sys.argv[1:], 'cwd': os.getcwd(), "
            "'pythonpath': os.environ.get('PYTHONPATH', ''), 'module': __file__}))\n"
            "code = pathlib.Path(__file__).with_name('verify_exit')\n"
            "sys.exit(int(code.read_text()) if code.exists() else 0)\n")

    @contextmanager
    def worlds(self):
        with tempfile.TemporaryDirectory() as t:
            t = Path(t)
            old_top, old = t / "old", t / "old" / "pipeline" / "agent"
            build_repo(old, {"harness/__init__.py": "", "harness/__main__.py": self.STUB})
            tool = old.parent / "ontology_provenance" / "nrs_tools" / "atoms_train.py"
            tool.parent.mkdir(parents=True); tool.write_text("# split tool\n")
            git(old_top, "init", "-q", "-b", "main"); git(old_top, "add", "-A"); git(old_top, "commit", "-q", "-m", "baseline")
            src = git(old_top, "rev-parse", "HEAD")
            with patched(old), mock.patch.object(handoff, "export", REAL_EXPORT):
                make_run(old)
                m = REAL_EXPORT("r", source_baseline=src)
            git(old_top, "add", "-A"); git(old_top, "commit", "-q", "-m", "checkpoint")
            new = t / "new"
            build_repo(new, {"harness/__init__.py": "", "harness/__main__.py": self.STUB})     # the same code as the old checkout's
            (t / "ontology_provenance" / "nrs_tools").mkdir(parents=True)
            shutil.copy(tool, t / "ontology_provenance" / "nrs_tools" / "atoms_train.py")
            git(new, "init", "-q", "-b", "main"); git(new, "add", "-A"); git(new, "commit", "-q", "-m", "new baseline")
            subprocess.run(["git", "init", "-q", "--bare", str(t / "remote.git")], check=True)
            git(new, "remote", "add", "origin", str(t / "remote.git"))
            yield old, old_top, new, m, t

    def test_adopt_then_enter(self):
        with self.worlds() as (old, old_top, new, m, t):
            log = t / "verify.json"
            with patched(new), mock.patch.dict(os.environ, {"S24_OLD_VERIFY_LOG": str(log)}), \
                    mock.patch.object(stage, "_generation", lambda run_id: COMPLETE):
                rec = stage.adopt("r", str(old), "t-adopt")
                self.assertEqual((rec["status"], rec["to"]), ("exported", "G0"))
                called = json.loads(log.read_text())
                self.assertEqual(called["argv"], ["handoff", "verify", "r"])
                self.assertEqual(Path(called["cwd"]).resolve(), old.resolve())
                self.assertEqual(called["pythonpath"].split(os.pathsep)[0], str(old.resolve()))
                self.assertEqual(Path(called["module"]).resolve(), (old / "harness" / "__main__.py").resolve())
                rd = paths.run_dir("r")
                g0 = stages.active_stage(rd)
                self.assertEqual(g0["launch_kinds"], ["generation"])
                self.assertEqual(g0["acceptance_policy"], {**m["acceptance_policy"], "review": "none"})
                self.assertEqual((g0["scope"], g0["code_baseline"], g0["semantic"]), ("all", m["baseline"], m["semantic"]))
                self.assertEqual(g0["effects"]["scoring"], stage.scoring_version_at(old))
                g0m = jsonl.read_json(rd / "handoff" / "manifest.json", None)
                self.assertEqual(g0m["stage_id"], "G0")
                self.assertEqual(g0m["stages_sha256"], stages.stages_sha256(rd))
                self.assertNotEqual(g0m["export_id"], m["export_id"])
                self.assertEqual(g0m["artifacts"], {**m["artifacts"], "results/r/stages.jsonl": stages.stages_sha256(rd)})
                self.assertEqual({k: v for k, v in g0m.items() if k not in ("export_id", "exported_at", "stage_id", "stages_sha256", "artifacts")},
                                 {k: v for k, v in m.items() if k not in ("export_id", "exported_at", "artifacts")})
                for f, h in m["artifacts"].items():
                    self.assertEqual(sha(new / f), h, f)
                self.assertEqual(fake_verify("r", for_transition=True)[0], [])
                self.assertIsNotNone(stages.transition_refusal(rd))
                git(new, "add", "-A"); git(new, "commit", "-q", "-m", "adopt"); git(new, "push", "-q", "origin", "HEAD:refs/heads/runs/r")
                stage.confirm("r", "t-adopt", git(new, "rev-parse", "HEAD"))
                self.assertIsNone(stages.transition_refusal(rd))
                self.assertEqual(fake_verify("r", for_transition=True)[0], [])     # this checkout's code is the next stage's
                # the next stage on this checkout's code: the adopted baseline compared file by file
                (new / "scripts" / "run-generation.sh").write_text("# a new launcher\n")
                git(new, "commit", "-q", "-m", "new code", "--", "scripts/run-generation.sh")
                stage.enter("r", "generation", "G0", "t1")
                self.assertEqual(stages.active_stage(rd)["changed_files"], [{"path": "scripts/run-generation.sh", "class": "tool"}])

    def refused(self, old, new, words):
        with patched(new):
            with self.assertRaises(SystemExit) as e:
                stage.adopt("r", str(old), "t-adopt")
            self.assertIn(words, str(e.exception))
            self.assertFalse((new / "results" / "r").exists())

    def test_the_old_codes_verify_failing(self):
        with self.worlds() as (old, old_top, new, m, t):
            (old / "harness" / "verify_exit").write_text("1")
            self.refused(old, new, "own `handoff verify` exited 1")

    def test_an_old_code_file_changed(self):
        with self.worlds() as (old, old_top, new, m, t):
            (old / "harness" / "loop.py").write_text("# edited\n")
            self.refused(old, new, "code file(s) of the old checkout differ from its manifest: harness/loop.py")

    def test_the_old_checkouts_own_split_tool_is_hashed(self):
        """The doctor's split tool is read beside the old checkout, never where this process finds one."""
        with self.worlds() as (old, old_top, new, m, t):
            (t / "ontology_provenance" / "nrs_tools" / "atoms_train.py").write_text("# this process's other tool\n")
            with patched(new):
                self.assertNotEqual(handoff.code_digest()["files"][handoff.DOCTOR_TOOL], m["baseline"]["code"]["files"][handoff.DOCTOR_TOOL])
                self.assertEqual(stage.adopt("r", str(old), "t-adopt")["status"], "exported")
        with self.worlds() as (old, old_top, new, m, t):
            (old.parent / "ontology_provenance" / "nrs_tools" / "atoms_train.py").write_text("# edited\n")
            self.refused(old, new, f"differ from its manifest: {handoff.DOCTOR_TOOL}")

    def test_a_merge_after_the_source_commit(self):
        with self.worlds() as (old, old_top, new, m, t):
            git(old_top, "checkout", "-q", "-b", "side", "HEAD~1"); (old_top / "note.txt").write_text("x\n")
            git(old_top, "add", "-A"); git(old_top, "commit", "-q", "-m", "side")
            git(old_top, "checkout", "-q", "main"); git(old_top, "merge", "-q", "--no-edit", "side")
            self.refused(old, new, "merge commit(s) after")

    def test_a_code_path_committed_after_the_source_commit(self):
        with self.worlds() as (old, old_top, new, m, t):
            (old / "harness" / "extra.py").write_text("# added\n")
            git(old_top, "add", "-A"); git(old_top, "commit", "-q", "-m", "code")
            self.refused(old, new, "code paths changed since the source commit")

    def test_a_run_already_here_is_refused(self):
        with self.worlds() as (old, old_top, new, m, t):
            (new / "results" / "r").mkdir(parents=True)
            with patched(new):
                with self.assertRaisesRegex(SystemExit, "already holds a run `r`"):
                    stage.adopt("r", str(old), "t-adopt")

    def test_an_adoption_stopped_after_each_write_is_finished_by_running_it_again(self):
        k, finished = 0, False
        while not finished and k < 30:
            k += 1
            with self.subTest(stop_after=k), self.worlds() as (old, old_top, new, m, t):
                with patched(new):
                    pw, pr, n = StoppedTransition.counting(k)
                    try:
                        with pw, pr:
                            stage.adopt("r", str(old), "t-adopt")
                        finished = True
                    except Crash:
                        candidate.recover_pending()
                        rd = paths.run_dir("r")
                        self.assertIsNotNone(stages.transition_refusal(rd))
                        with self.assertRaises(SystemExit):
                            stage.adopt("r", str(old), "t-other")
                    rec = stage.adopt("r", str(old), "t-adopt")
                    self.assertEqual(rec["status"], "exported")
                    self.assertEqual(stages.active_stage(paths.run_dir("r"))["stage_id"], "G0")
                    self.assertEqual(fake_verify("r", for_transition=True)[0], [])
        self.assertGreaterEqual(k, 5)


class Commands(unittest.TestCase):

    def test_the_flags_reach_the_commands_as_written(self):
        calls = []
        with mock.patch.object(stage, "enter", lambda *a: calls.append(("enter", a))), \
                mock.patch.object(stage, "confirm", lambda *a: calls.append(("confirm", a))), \
                mock.patch.object(stage, "adopt", lambda *a: calls.append(("adopt", a))), \
                mock.patch.object(snapshot, "verify", lambda run, sid=None: calls.append(("verify", run, sid)) or ["x"]), \
                mock.patch.object(snapshot, "restore", lambda run, sid, into: calls.append(("restore", run, sid, into))):
            self.assertEqual(stage.main(["enter", "r", "--kind", "generation", "--from", "G0", "--transition", "t1",
                                         "--prompts-approved", "1e5", "--scope", "s.json"]), 0)
            self.assertEqual(stage.main(["confirm", "r", "--transition", "t1", "--commit", "12e4567", "--remote", "up"]), 0)
            self.assertEqual(stage.main(["enter", "r", "--kind", "generation", "--from", "G0", "--transition", "t1",
                                         "--prompts_approved", "d", "--source_commit", "c"]), 0)
            self.assertEqual(stage.main(["adopt", "r", "--old_checkout", "/o", "--transition", "t0"]), 0)
            self.assertEqual(stage.main(["adopt", "r", "--old-checkout", "/o", "--transition", "t0"]), 0)
            self.assertEqual(stage.main(["verify", "r", "G0"]), 1)
            self.assertEqual(stage.main(["restore", "r", "G0", "--into", "/d"]), 0)
        self.assertEqual(calls, [("enter", ("r", "generation", "G0", "t1", "s.json", "1e5", None)),
                                 ("confirm", ("r", "t1", "12e4567", "up", None)),
                                 ("enter", ("r", "generation", "G0", "t1", None, "d", "c")), ("adopt", ("r", "/o", "t0")),
                                 ("adopt", ("r", "/o", "t0")),
                                 ("verify", "r", "G0"), ("restore", "r", "G0", Path("/d"))])

    def test_show_lists_the_stages_and_the_transition(self):
        import io
        from contextlib import redirect_stdout
        with world() as w:
            w.change("scripts/run-generation.sh")
            stage.enter("r", "generation", "G0", "t1")
            out = io.StringIO()
            with redirect_stdout(out):
                self.assertEqual(stage.main(["show", "r"]), 0)
            text = out.getvalue()
            self.assertIn("close  G0", text); self.assertIn("open   G1", text)
            self.assertIn("active stage: G1", text); self.assertIn("last transition: t1 (enter) G0 → G1: exported", text)

    def test_the_cli_refuses_review(self):
        env = {k: v for k, v in os.environ.items()}
        p = subprocess.run([sys.executable, "-m", "harness", "stage", "enter", "no-such-run", "--kind", "review", "--from", "G0",
                            "--transition", "t1"], cwd=AGENT, env=env, capture_output=True, text=True)
        self.assertEqual(p.returncode, 1)
        self.assertIn(stages.REVIEW_REFUSAL, p.stderr)


if __name__ == "__main__":
    unittest.main()
