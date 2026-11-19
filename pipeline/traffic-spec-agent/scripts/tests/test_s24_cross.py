"""S4/S2 across the tracks, on the real components end to end: the loop (with the stand-in sessions of
`test_recovery`), the stage record, the transition commands, the handoff, the snapshot and a real
git checkout with a bare remote for the confirmations.

- A new run starts in G0 and generates (`--label_deferred`); it is exported; `stage enter` G0→G1 on a
  new code baseline that changes one tool file; the stage commit is pushed and confirmed; `handoff
  verify` is clean; one iteration runs in G1; the same again to G2 and G3. G1 and G2 are each
  restored into a clean checkout of their baseline commit, at a new root and at the same-named root
  with the original gone; there `handoff verify` is clean and one iteration resumes, the stage record
  ending at the restored stage.
- A stop after every write point of `stage enter` and `stage confirm` (the snapshot, the transition
  record, the library's pending pointer, the journal, each replacement, the export, `exported`,
  `done` before its export again, that export): the loop is refused until the transition is
  finished, `handoff verify` refuses, running the same command again finishes it, and then exactly
  one stage is active and the stage record, the manifest and the transition record agree.
- A label repair in a staged run whose checks passed is refused at its commit when a rule in the
  checked law's closure changed in the production library in between, and no key is recorded.
- `stage enter --kind review`, and labels from generation, are refused on a real G0 run with nothing
  written.
- A run made before stages still resumes, exports and verifies, with its texts unchanged."""
import json
import shutil
import subprocess
import unittest
from contextlib import ExitStack, contextmanager
from pathlib import Path
from unittest import mock

from harness import loop
from harness.phases import candidate
from harness.store import jsonl, paths, snapshot, stages
from harness.tools import handoff, stage
from scripts.tests import test_s24_merge_label_repair as merged
from scripts.tests.test_candidate import Base
from scripts.tests.test_recovery import PATH_NAMES, Crash, Fixture, node
from scripts.tests.test_split_handoff import SPLIT, TOOLCHAIN, options_at, split_world

TOOL = "scripts/diagnostics/probe.py"                    # a tool file of the code baseline (`stage.TOOL_DIRS`)
SPLIT_TOOL = "ontology_provenance/nrs_tools/atoms_train.py"
GIT = ("git", "-c", "user.name=t", "-c", "user.email=t@t", "-c", "init.defaultBranch=main", "-c", "commit.gpgsign=false")


def git(root: Path, *args: str) -> str:
    p = subprocess.run([*GIT, "-C", str(root), *args], capture_output=True, text=True)
    if p.returncode != 0:
        raise AssertionError(f"git {args}: {p.stderr}")
    return p.stdout.strip()


def tree(root: Path) -> dict:
    return {p.relative_to(root).as_posix(): p.read_bytes() for p in sorted(root.rglob("*"))
            if p.is_file() and ".git" not in p.relative_to(root).parts}


def beside(name: str) -> Path | None:
    """`paths.ontology_tool` as the real layout resolves it: beside the agent directory."""
    f = paths.REPO.parent / "ontology_provenance" / "nrs_tools" / f"{name}.py"
    return f.resolve() if f.is_file() else None


def place_tool(root: Path) -> None:
    f = root.parent / SPLIT_TOOL
    f.parent.mkdir(parents=True, exist_ok=True)
    f.write_text("# split tool\n")


def rows(rd: Path) -> list[dict]:
    return stages.read_stages(rd)


class Chain:
    """A staged run in a git checkout of its code baseline, with a bare remote: the launcher's steps
    (code replaced by a new baseline's, `stage enter`, the stage commit pushed, `stage confirm`, the
    `done` state committed and pushed) done here with git and the real commands."""

    def __init__(self, f: Fixture, stack: ExitStack):
        self.f, self.root = f, f.root
        self.remote = f.tmp / "remote.git"
        place_tool(self.root)
        stack.enter_context(mock.patch.object(paths, "ontology_tool", beside))
        stack.enter_context(mock.patch.object(handoff, "toolchain", lambda: TOOLCHAIN))
        (self.root / TOOL).parent.mkdir(parents=True, exist_ok=True)
        (self.root / TOOL).write_text("# probe v0\n")
        (self.root / ".gitignore").write_text("*.lock\n.run.owner.json\n__pycache__/\n")
        git(self.root, "init", "-q")
        git(self.root, "add", "-A"); git(self.root, "commit", "-q", "-m", "baseline")
        self.base = {"G0": git(self.root, "rev-parse", "HEAD")}
        subprocess.run(["git", "init", "-q", "--bare", str(self.remote)], check=True)
        git(self.root, "remote", "add", "origin", str(self.remote))
        git(self.root, "push", "-q", "origin", "main")
        git(self.root, "switch", "-q", "-c", "runs/r")
        self.n = 0

    @property
    def rd(self) -> Path:
        return paths.RESULTS / "r"

    def checkpoint(self, msg: str) -> str:
        git(self.root, "add", "-A", "-f", "."); git(self.root, "commit", "-q", "--allow-empty", "-m", msg)
        git(self.root, "push", "-q", "origin", "runs/r")
        return git(self.root, "rev-parse", "HEAD")

    def new_base(self, sid: str, text: str) -> str:
        """A development commit on main: the last baseline with the tool file changed."""
        prev = list(self.base.values())[-1]
        wt = self.f.tmp / f"dev-{sid}"
        git(self.root, "worktree", "add", "-q", "--detach", str(wt), prev)
        (wt / TOOL).write_text(text)
        git(wt, "commit", "-q", "-am", f"development for {sid}")
        sha = git(wt, "rev-parse", "HEAD")
        git(self.root, "worktree", "remove", "--force", str(wt))
        git(self.root, "push", "-q", "origin", f"{sha}:refs/heads/main")
        self.base[sid] = sha
        return sha

    def replace_code(self, sha: str) -> None:
        git(self.root, "checkout", sha, "--", TOOL)

    def enter(self, frm: str, to: str, t: str) -> dict:
        return stage.enter("r", "generation", frm, t, source_commit=self.base[to])

    def confirm(self, t: str, c: str) -> dict:
        return stage.confirm("r", t, c)

    def transition(self, frm: str, to: str, t: str, text: str) -> str:
        """The whole transition as the launcher makes it; returns the stage commit."""
        self.replace_code(self.new_base(to, text))
        self.assert_status(self.enter(frm, to, t), "exported", to)
        c = self.checkpoint(f"stage {to}: baseline {self.base[to]}\n\nStage-Transition: {t}")
        self.assert_status(self.confirm(t, c), "done", to)
        self.checkpoint(f"r: stage {to} confirmed")
        return c

    @staticmethod
    def assert_status(rec: dict, status: str, to: str) -> None:
        assert (rec["status"], rec["to"]) == (status, to), rec

    def drive(self, max_iterations: int, **over) -> list[str]:
        return self.f.drive(1, label_deferred=True, max_iterations=max_iterations, **over)


def agree(test: unittest.TestCase, rd: Path, active: str, opened: list[str]) -> None:
    """Exactly one stage active; the stage record, the manifest and the transition record agree."""
    rs = rows(rd)
    test.assertEqual([r["stage_id"] for r in rs if r["event"] == "open"], opened)
    test.assertEqual(stages.active_stage(rd)["stage_id"], active)
    test.assertEqual(sum(r["event"] == "open" for r in rs) - sum(r["event"] == "close" for r in rs), 1)
    m = json.loads((rd / "handoff" / "manifest.json").read_text())
    test.assertEqual((m["stage_id"], m["stages_sha256"]), (active, stages.stages_sha256(rd)))
    t = stages.transition_state(rd)
    test.assertEqual(t["status"], "done")
    test.assertEqual(t["stages_sha256"], stages.stages_sha256(rd))
    test.assertEqual(t["to"], active)
    test.assertIsNone(stages.transition_refusal(rd))


def stage_world():
    """`split_world` and a fourth law: the gate's scripted failures leave work for each next stage and
    each restored one, and G1 and G2 each publish a rule (L_22's repair, then L_21's)."""
    w = split_world()
    w.laws["L-23"] = "shall yield."
    w.plans["L-23"] = [node("L_23", "shall yield.", "L-23")]
    for n, its in (("L_22", (1,)), ("L_21", (2,)), ("L_23", (1, 2, 3))):
        for it in its:
            w.gate[(n, it)] = "CHECK_FAIL"
    return w


@contextmanager
def staged_world(stack: ExitStack):
    with Fixture(stage_world(), staged=True, **SPLIT) as f:
        yield f.w, f, Chain(f, stack)


@contextmanager
def at_root(f: Fixture, new: Path):
    """The harness's paths pointed at `new`, a root laid out as the fixture's."""
    rel = {k: new / Path(v).relative_to(f.root) for k, v in f.dirs.items()}
    with ExitStack() as s:
        for k in PATH_NAMES:
            s.enter_context(mock.patch.object(paths, k, rel[k]))
        yield


class Stages(unittest.TestCase):

    def test_g0_to_g3_and_g1_g2_restored(self):
        with ExitStack() as stack, staged_world(stack) as (w, f, ch):
            self.assertEqual(ch.drive(1, source_commit=ch.base["G0"]), ["incomplete"])
            rd = ch.rd
            self.assertEqual([r["stage_id"] for r in rows(rd)], ["G0"])
            m = handoff.export("r")
            self.assertEqual((m["stage_id"], m["baseline"]["source_commit"]), ("G0", ch.base["G0"]))
            ch.checkpoint("r: G0 iteration 1")

            exports = {"G0": {p: (paths.REPO / p).read_bytes() for p in m["artifacts"]}}
            for frm, to, t, it in (("G0", "G1", "t-g1", 2), ("G1", "G2", "t-g2", 3), ("G2", "G3", "t-g3", 4)):
                with self.subTest(transition=t):
                    c = ch.transition(frm, to, t, f"# probe {to}\n")
                    g = stages.active_stage(rd)
                    self.assertEqual((g["stage_id"], g["previous_stage_id"], g["code_baseline"]["source_commit"]),
                                     (to, frm, ch.base[to]))
                    self.assertEqual(g["changed_files"], [{"path": TOOL, "class": "tool"}])
                    self.assertEqual(stages.transition_state(rd)["commit"], c)
                    self.assertEqual(handoff.verify("r", artifacts=True), ([], []))
                    agree(self, rd, to, ["G0", "G1", "G2", "G3"][:int(to[1]) + 1])
                    if to == "G3":
                        break
                    self.assertNotIn(ch.drive(it), ["crash"])                     # one iteration on the new stage's code
                    self.assertEqual(json.loads((rd / "state.json").read_text())["iteration"], it)
                    self.assertEqual(stages.active_stage(rd)["stage_id"], to)
                    m = handoff.export("r")
                    self.assertEqual(m["stage_id"], to)
                    exports[to] = {p: (paths.REPO / p).read_bytes() for p in m["artifacts"]}
                    exports[to]["iteration"] = json.loads((rd / "state.json").read_text())["iteration"]
                    ch.checkpoint(f"r: {to} iteration {it}")
            for sid in ("G0", "G1", "G2"):
                self.assertEqual(snapshot.verify("r", sid), [], sid)
            rules = lambda sid: {p: b for p, b in exports[sid].items() if p.startswith("library/TrafficSpec/Rules/")}
            for prev, sid in (("G0", "G1"), ("G1", "G2")):                        # each of G1 and G2 changed a rule
                self.assertNotEqual(rules(sid), rules(prev), sid)

            source = f.tmp / "source"                                              # the run as the remote holds it
            for sid in ("G1", "G2"):
                for same_name in (False, True):
                    with self.subTest(restore=sid, same_name=same_name):
                        self.restore_and_resume(f, ch, sid, exports[sid], same_name, source)

    def restore_and_resume(self, f, ch, sid, exported, same_name, source):
        if same_name:                                    # another machine: the same path, the original root gone
            if source.exists():
                shutil.rmtree(source)
            shutil.copytree(ch.root, source, symlinks=True)
            target = ch.root
            gone = f.tmp / "gone"
            ch.root.rename(gone)
            restore_back = lambda: (shutil.rmtree(target), gone.rename(target))
        else:
            target = f.tmp / f"restore-{sid}" / "repo"
            original = tree(ch.root)
            restore_back = lambda: (shutil.rmtree(target.parent), self.assertEqual(tree(ch.root), original))   # the run is untouched
        try:
            subprocess.run(["git", "clone", "-q", str(ch.remote), str(target)], check=True, capture_output=True)
            git(target, "checkout", "-q", "--detach", ch.base[sid])
            place_tool(target)
            src_ctx = at_root(f, source) if same_name else ExitStack()
            with src_ctx:
                self.assertEqual(stage.main(["restore", "r", sid, "--into", str(target)]), 0)
            with at_root(f, target):
                rd = paths.RESULTS / "r"
                self.assertEqual(handoff.verify("r", artifacts=True), ([], []))
                self.assertEqual(rows(rd)[-1]["stage_id"], sid)
                self.assertEqual(stages.active_stage(rd)["stage_id"], sid)
                for p, b in exported.items():
                    if p != "iteration":
                        self.assertEqual((paths.REPO / p).read_bytes(), b, p)
                opts = options_at(f, target, label_deferred=True, max_iterations=exported["iteration"] + 1)
                res = loop.run_loop(opts)
                self.assertIn(res["status"], ("incomplete", "awaiting_review"))
                self.assertEqual(json.loads((rd / "state.json").read_text())["iteration"], exported["iteration"] + 1)
                self.assertEqual(rows(rd)[-1]["stage_id"], sid)
                self.assertTrue((rd / "handoff" / "imported.json").exists())
        finally:
            restore_back()


# -- a stop after every write point of the transition ------------------------------------------------

class Stop:
    """Stops the process (`Crash`) right after the `at`-th write the transition makes: every atomic file
    write, every replacement its journal applies and every snapshot blob, each counted once written."""

    def __init__(self, at: int | None = None):
        self.at, self.seen = at, []

    def wrap(self, stack: ExitStack) -> None:
        for owner_mod, name, arg in ((jsonl, "write_atomic", 0), (candidate, "_replace", 1), (snapshot, "_write_bytes", 0)):
            stack.enter_context(mock.patch.object(owner_mod, name, self.after(getattr(owner_mod, name), name, arg)))

    def after(self, fn, name, arg):
        def run(*a, **k):
            out = fn(*a, **k)
            path = Path(a[arg])
            self.seen.append("blob" if path.parent.name == "blobs" else
                             path.relative_to(paths.REPO).as_posix() if path.is_relative_to(paths.REPO) else path.name)
            if len(self.seen) == self.at:
                raise Crash(f"stopped after writing {self.seen[-1]}")
            return out
        return run


def points(seen: list[str]) -> list[int]:
    """The write points to stop at: every write, one blob standing for all (each is written once, by its digest)."""
    out, blob = [], False
    for i, label in enumerate(seen, 1):
        if label == "blob":
            if blob:
                continue
            blob = True
        out.append(i)
    return out


class StopEverywhere(unittest.TestCase):

    def at_g0(self, stack):
        """A fresh run at its exported, pushed G0 checkpoint, with G1's code in place."""
        w, f, ch = stack.enter_context(staged_world(stack))
        self.assertEqual(ch.drive(1, source_commit=ch.base["G0"]), ["incomplete"])
        handoff.export("r")
        ch.checkpoint("r: G0 iteration 1")
        ch.replace_code(ch.new_base("G1", "# probe G1\n"))
        return w, f, ch

    def dry(self, phase: str) -> list[str]:
        with ExitStack() as stack:
            _w, _f, ch = self.at_g0(stack)
            stop = Stop()
            with ExitStack() as s:
                if phase == "enter":
                    stop.wrap(s)
                ch.enter("G0", "G1", "t-g1")
            c = ch.checkpoint("stage G1")
            with ExitStack() as s:
                if phase == "confirm":
                    stop.wrap(s)
                ch.confirm("t-g1", c)
            return stop.seen

    def refused_while_unfinished(self, w, f, ch):
        """The loop and `handoff verify` refuse; the loop writes nothing of the run. Another transition
        from the same stage is refused while this one is short of `done`, and begins nothing: as the
        library's next owner it only completes a journal this one committed (or drops a pointer left
        short of the commit point), and writes nothing when there was none."""
        rd = ch.rd
        before = (tree(f.root), dict(w.calls))
        with self.assertRaises(SystemExit) as e:
            loop.run_loop(f.options(label_deferred=True, max_iterations=5))
        self.assertIn("nothing of", str(e.exception))
        self.assertEqual((tree(f.root), dict(w.calls)), before)
        refusals, _w = handoff.verify("r", artifacts=True)
        self.assertTrue(refusals)
        st = stages.transition_state(rd)
        if st is not None and st.get("status") != "done":
            self.assertEqual(refusals, [stages.transition_refusal(rd)])
            self.assertIn("stopped at", str(e.exception))
            pointer = candidate.pending_file().exists()
            with self.assertRaises(SystemExit) as other:
                stage.enter("r", "generation", "G0", "t-other", source_commit=ch.base["G1"])
            self.assertIn("nothing was written", str(other.exception))
            # another transition is refused before it completes any journal: the repository is as it was,
            # a pointer to t-g1's committed journal included, which t-g1's own run completes
            self.assertEqual(tree(f.root), before[0])
            self.assertEqual(candidate.pending_file().exists(), pointer)
            self.assertEqual(stages.transition_state(rd)["transition_id"], "t-g1")
            self.assertFalse([r for r in rows(rd) if r.get("transition_id") == "t-other"])
        elif st is None:                                 # stopped before `prepared`: G0 is whole, the code is G1's
            self.assertTrue(all("active stage `G0`" in r and TOOL in r for r in refusals), refusals)
        else:                                            # `done`, its export not yet written again
            self.assertTrue(any("stage_transition.json" in r for r in refusals), refusals)

    def finished(self, f, ch):
        agree(self, ch.rd, "G1", ["G0", "G1"])
        self.assertEqual(handoff.verify("r", artifacts=True), ([], []))
        self.assertEqual(snapshot.verify("r", "G0"), [])
        self.assertEqual(snapshot.verify("r"), [])
        self.assertNotIn("crash", ch.drive(2))                                   # the loop runs on G1 again
        self.assertEqual(stages.active_stage(ch.rd)["stage_id"], "G1")

    def test_a_stop_after_every_write_of_enter_is_finished_by_the_same_enter(self):
        seen = self.dry("enter")
        self.assertIn("results/r/stage_journal.json", seen)
        self.assertIn("library/.candidate_pending.json", seen)
        for at in points(seen):
            with self.subTest(at=at, after=seen[at - 1]), ExitStack() as stack:
                w, f, ch = self.at_g0(stack)
                stop = Stop(at)
                with self.assertRaises(Crash), ExitStack() as s:
                    stop.wrap(s)
                    ch.enter("G0", "G1", "t-g1")
                self.refused_while_unfinished(w, f, ch)
                ch.assert_status(ch.enter("G0", "G1", "t-g1"), "exported", "G1")            # the same transition, run again
                c = ch.checkpoint("stage G1")
                ch.assert_status(ch.confirm("t-g1", c), "done", "G1")
                ch.checkpoint("r: stage G1 confirmed")
                self.finished(f, ch)

    def test_a_stop_after_every_write_of_confirm_is_finished_by_the_same_confirm(self):
        seen = self.dry("confirm")
        self.assertEqual(seen[0], "results/r/stage_transition.json")                     # `done`, then the export again
        self.assertEqual(seen[1:], ["results/r/handoff/manifest.json", "results/r/handoff/files.txt"])
        for at in points(seen):
            with self.subTest(at=at, after=seen[at - 1]), ExitStack() as stack:
                w, f, ch = self.at_g0(stack)
                ch.assert_status(ch.enter("G0", "G1", "t-g1"), "exported", "G1")
                c = ch.checkpoint("stage G1")
                stop = Stop(at)
                with self.assertRaises(Crash), ExitStack() as s:
                    stop.wrap(s)
                    ch.confirm("t-g1", c)
                if seen[at - 1] == "results/r/stage_transition.json":
                    self.refused_while_unfinished(w, f, ch)
                else:                                    # the export again was written: the confirmation is whole
                    self.assertEqual(handoff.verify("r", artifacts=True), ([], []))
                ch.assert_status(ch.confirm("t-g1", c), "done", "G1")
                ch.checkpoint("r: stage G1 confirmed")
                self.finished(f, ch)


# -- refusals on a real G0 run, and a run made before stages ---------------------------------------

class G0Refusals(unittest.TestCase):

    def test_review_and_labels_from_generation_are_refused_with_nothing_written(self):
        with ExitStack() as stack, staged_world(stack) as (w, f, ch):
            self.assertEqual(ch.drive(1, source_commit=ch.base["G0"]), ["incomplete"])
            handoff.export("r")
            ch.checkpoint("r: G0 iteration 1")
            before = (tree(f.root), dict(w.calls))
            for argv, words in ((["enter", "r", "--kind", "review", "--from", "G0", "--transition", "t-r"], stages.REVIEW_REFUSAL),
                                (["enter", "r", "--kind", "labels", "--from", "G0", "--transition", "t-l"], stages.LABELS_REFUSAL)):
                with self.subTest(argv=argv):
                    with self.assertRaises(SystemExit) as e:
                        stage.main(argv)
                    self.assertIn(words, str(e.exception))
                    self.assertIn("nothing was written", str(e.exception))
                    self.assertEqual((tree(f.root), dict(w.calls)), before)
            with self.assertRaises(SystemExit) as e:                                    # nor a labels launch in G0
                loop.run_loop(f.options(label_stage=True, label_dataset="ds", max_iterations=3))
            self.assertIn("this is a `labels` launch", str(e.exception))
            self.assertEqual((tree(f.root), dict(w.calls)), before)
            self.assertIsNone(stages.transition_state(ch.rd))
            self.assertEqual([r["stage_id"] for r in rows(ch.rd)], ["G0"])


class LegacyRun(unittest.TestCase):

    def test_a_run_made_before_stages_resumes_exports_and_verifies_as_before(self):
        w = split_world()
        for it in (1, 2):
            w.gate[("L_22", it)] = "CHECK_FAIL"
        with Fixture(w, **SPLIT) as f, ExitStack() as stack:
            ch = Chain(f, stack)
            rd = ch.rd
            self.assertEqual(f.drive(1, label_deferred=True, max_iterations=1), ["incomplete"])
            self.assertFalse((rd / stages.STAGES_FILE).exists())
            self.assertNotIn("stage_policy", json.loads((rd / "options.json").read_text()))
            m = handoff.export("r", source_baseline=ch.base["G0"])
            self.assertFalse({"stage_id", "stages_sha256"} & set(m))
            self.assertEqual(handoff.verify("r", artifacts=True), ([], []))
            self.assertEqual(f.drive(1, label_deferred=True, max_iterations=2), ["incomplete"])
            m = handoff.export("r")
            self.assertEqual(m["baseline"]["source_commit"], ch.base["G0"])
            self.assertEqual(handoff.verify("r", artifacts=True), ([], []))
            (ch.root / TOOL).write_text("# probe, changed after the run started\n")
            text = ("the code that decides this run's results differs from its baseline (1 file(s): " + TOOL + "): a run continues only "
                    "on the code it started on — start a new run id, or continue from a checkout of the run's baseline "
                    f"(commit {ch.base['G0']})")
            self.assertEqual(handoff.verify("r", artifacts=False)[0], [text])
            with self.assertRaises(SystemExit) as e:
                handoff.export("r")
            self.assertEqual(str(e.exception), "[handoff] " + text)
            with self.assertRaises(SystemExit) as e:
                loop.run_loop(f.options(label_deferred=True, max_iterations=3))
            self.assertEqual(str(e.exception), f"[loop] the handed-over run `r` cannot continue here — {text} — nothing of the run was rewritten")
            self.assertFalse((rd / stages.STAGES_FILE).exists())


# -- the candidate's commit boundary ------------------------------------------------------------------

class CheckedNotPublished(Base):
    """Between a label repair's passing checks and its commit, a rule in the checked law's closure is
    changed in the production library: the commit is refused, nothing of the candidate is published,
    and no label state takes a key (the keys stay those of the checks before the repair)."""

    def test_a_rule_changed_after_the_check_refuses_the_commit(self):
        L, N = merged.L, merged.N
        real, refused = candidate.Candidate.commit, []

        def commit(txn, *a, **k):
            self_results = [r.status for r in txn.results]
            self.assertTrue(self_results and all(x == "pass" for x in self_results), self_results)     # its checks passed
            f = paths.LIBRARY / merged.RULE1                                       # L-1's own rule: L-1 was checked again
            f.write_text(f.read_text() + "-- changed in production after the check\n")
            try:
                return real(txn, *a, **k)
            except candidate.CommitRefused as e:
                refused.append(str(e))
                raise
        with merged.repairing("all", merged.OUTPUTS) as (run, ledger, training, by_id):
            keys = {law: run.label_states[law].get("key") for law in (L[1], L[5])}
            self.assertTrue(all(keys.values()), keys)                             # the stage's first checks recorded theirs
            rule5 = (paths.LIBRARY / merged.RULE5).read_text()
            snap_keys = lambda: {law: ((json.loads((run.dir / "state.json").read_text()).get("label_states") or {}).get(law) or {}).get("key")
                                 for law in (L[1], L[5])}
            committed_keys = snap_keys()
            merged.set_verdict(training, "r5a", N[5], "compliant")
            merged.set_verdict(training, "r5b", N[5], "violated")
            with mock.patch.object(candidate.Candidate, "commit", commit):
                result = merged.repair(run, ledger, training, by_id)
            self.assertNotEqual(result, "committed")
            self.assertEqual(len(refused), 1)
            self.assertIn("the production baseline moved", refused[0])
            self.assertEqual((paths.LIBRARY / merged.RULE5).read_text(), rule5)  # the candidate's rule is not published
            self.assertEqual({law: run.label_states[law].get("key") for law in (L[1], L[5])}, keys)
            self.assertEqual(snap_keys(), committed_keys)                         # nor in the committed snapshot
            self.assertNotEqual(ledger.entries[L[5]].state, "accepted")


if __name__ == "__main__":
    unittest.main()
