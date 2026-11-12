"""The launcher with a staged run (`results/<run>/stages.jsonl`), on a temporary git repository with a
local bare remote: `STAGE=review` and `KIND=review` refused before anything runs; `stage-enter` replacing
exactly the code files with the new baseline's (additions, deletions and the doctor's split tool outside
the agent directory) and never a run artifact or a non-code file, committing one non-merge stage commit,
pushing it, confirming the transition at it and committing its `done` state; a refusal of the harness
putting the checkpoint's code back; a stop at every step continued by running the same `stage-enter`
again; and a staged `resume` anchored on the stage's transition commit (no merge after it, the code equal
to the stage's baseline, the launch kind the stage's), an adopted first stage keeping the baseline rule.

The harness is the stand-in of `test_split_launcher` with a stand-in `stage enter` (resumable through the
transition states, stopping or killing the launcher where a test says) and `stage confirm` (the commit
must be on the remote run branch). The stage record, its reader and the code digest are the real ones."""
import json
import os
import shutil
import subprocess
import sys
import unittest
from pathlib import Path

from harness.store.state import DEPENDENCY_POLICY
from scripts.tests import s24_helpers, test_split_launcher as legacy

FAKE_MAIN, LAUNCHER, git = legacy.FAKE_MAIN, legacy.LAUNCHER, legacy.git

REAL = LAUNCHER.parents[1] / "harness"
ORDER = ("prepared", "committed", "applied", "exported")

STAGE_PART = r'''
def _stop(ctl, key, value):
    if ctl.get(key) == value:
        if ctl.get("kill"):
            os.kill(os.getppid(), 9)                   # the launcher dies here, as on a power cut
        sys.exit(1)
if a[:2] in (["stage", "enter"], ["stage", "confirm"]):
    import subprocess
    from harness.store import stages
    from harness.tools.handoff import code_digest
    run = a[2]; rd = Path("results") / run; tf = rd / "stage_transition.json"
    ctl = json.loads(os.environ.get("FAKE_STAGE") or "{}")
    with open(os.environ["FAKE_LOG"] + ".stage", "a") as f:
        f.write(json.dumps({"argv": a, "probe": Path("harness/probe.py").read_text()}) + "\n")
    st = json.loads(tf.read_text()) if tf.exists() else {}
    if a[1] == "enter":
        T, kind, frm = opt("--transition"), opt("--kind"), opt("--from")
        _stop(ctl, "at", "start")
        active = stages.active_stage(rd)
        if st.get("transition_id") != T:
            if (active["stage_kind"], kind) not in stages.ALLOWED_TRANSITIONS:
                print(stages.LABELS_REFUSAL if kind == "labels" else "refused"); sys.exit(2)
            if active["stage_id"] != frm:
                print(f"the active stage is {active['stage_id']}"); sys.exit(2)
        done = ORDER.index(st["status"]) + 1 if st.get("transition_id") == T and st.get("status") in ORDER else 0
        for s in ORDER[done:]:
            if s == "committed":
                rows = stages.read_stages(rd)
                n = sum(r["event"] == "open" for r in rows)
                new_id = f"{kind[0].upper()}{n}"
                rows += [{"event": "close", "stage_id": frm, "transition_id": T, "output_checkpoint": None, "closed_at": 0},
                         {"event": "open", "run_id": run, "stage_id": new_id, "stage_kind": kind, "launch_kinds": [kind],
                          "previous_stage_id": frm, "transition_id": T, "code_baseline": {"source_commit": "new", "code": code_digest()},
                          "scope": "all", "opened_at": 0}]
                (rd / "stages.jsonl").write_text("".join(json.dumps(r) + "\n" for r in rows))
            if s == "exported":
                hd = rd / "handoff"
                tf.write_text(json.dumps({"transition_id": T, "status": s}))
                files = sorted(str(p) for p in rd.rglob("*") if p.is_file() and "handoff" not in p.parts)
                files += sorted(str(p) for p in Path("library/TrafficSpec/Rules").rglob("*") if p.is_file())
                m = json.loads((hd / "manifest.json").read_text())
                (hd / "manifest.json").write_text(json.dumps({**m, "export_id": uuid.uuid4().hex, "stage_id": stages.active_stage(rd)["stage_id"]}))
                (hd / "files.txt").write_text("".join(f + "\n" for f in files + [str(hd / "manifest.json"), str(hd / "files.txt")]))
            tf.write_text(json.dumps({"transition_id": T, "status": s}))
            _stop(ctl, "at", s)
        sys.exit(0)
    sha = opt("--commit")
    _stop(ctl, "at", "confirm")
    tip = subprocess.run(["git", "ls-remote", "origin", f"refs/heads/runs/{run}"], capture_output=True, text=True).stdout.split()
    if not tip or subprocess.run(["git", "merge-base", "--is-ancestor", sha, tip[0]]).returncode != 0:
        print("the commit is not on the remote run branch"); sys.exit(1)
    tf.write_text(json.dumps({**st, "status": "done", "commit": sha}))
    _stop(ctl, "at", "confirmed")
    sys.exit(0)
'''
STAGED_MAIN = FAKE_MAIN.rstrip()[:-len("sys.exit(2)")] + f"ORDER = {ORDER!r}\n" + STAGE_PART + "sys.exit(2)\n"
def state_stub() -> str:
    """The run state module of the temporary repository: every name the real handoff module imports
    from it (read from its source, so a name added there is stood in here too), the readable state
    schemas as the real harness reads them, and an `Options` with the two split flags."""
    import ast
    from harness.store.state import READABLE_RUN_VERSIONS
    tree = ast.parse((REAL / "tools" / "handoff.py").read_text())
    names = sorted({a.name for n in ast.walk(tree) if isinstance(n, ast.ImportFrom) and n.module == "store.state" and n.level == 2
                    for a in n.names} - {"Options", "READABLE_RUN_VERSIONS"})
    return ("from dataclasses import dataclass\n@dataclass\nclass Options:\n    label_deferred: bool = False\n    label_stage: bool = False\n"
            f"READABLE_RUN_VERSIONS = frozenset({sorted(READABLE_RUN_VERSIONS)!r})\n" + "".join(f"{n} = None\n" for n in names))


STATE_STUB = state_stub()
HOOK = "#!/bin/sh\nmode=$(cat {flag} 2>/dev/null)\n[ -z \"$mode\" ] && exit 0\nwhile read old new ref; do git log -1 --format=%s $new | grep -q \"$mode\" && exit 1; done\nexit 0\n"


class Staged(unittest.TestCase):
    setUp_base, launch, loops, remote_files = legacy.Launcher.setUp, legacy.Launcher.launch, legacy.Launcher.loops, legacy.Launcher.remote_files

    def setUp(self):
        self.setUp_base()
        a = self.agent
        for rel in ("store/stages.py", "store/jsonl.py", "tools/handoff.py"):
            (a / "harness" / rel).parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(REAL / rel, a / "harness" / rel)
        (a / "harness" / "tools" / "__init__.py").write_text("")
        (a / "harness" / "store" / "state.py").write_text(STATE_STUB)
        (a / "harness" / "__main__.py").write_text(STAGED_MAIN)
        (a / "harness" / "probe.py").write_text("v1\n")
        (a / "harness" / "old.py").write_text("old\n")
        (a / "prompts").mkdir()
        (a / "prompts" / "plan.md").write_text("plan v1\n")
        (a / "NOTES.txt").write_text("not code v1\n")
        git(self.work, "add", "-A"); git(self.work, "commit", "-q", "-m", "staged harness")
        git(self.work, "push", "-q", "-f", "origin", "HEAD:refs/heads/main", "HEAD:refs/heads/remote/full-train-generation")
        self.base = git(self.work, "rev-parse", "HEAD").stdout.strip()
        self.flag = self.t / "hook-mode"
        hook = self.remote / "hooks" / "pre-receive"
        hook.write_text(HOOK.format(flag=self.flag)); hook.chmod(0o755)
        self.new_base = self.make_base()
        out = self.launch("new", [{"status": "incomplete", "stop": "iteration_limit",
                                   "files": {"library/TrafficSpec/Rules/X/X_1.lean": "-- the run's rule\n", "results/t1/note.txt": "run\n"}}],
                          LAUNCHES="1")
        self.assertEqual(out.returncode, 0, out.stdout + out.stderr)
        self.adopt()

    def make_base(self):
        """The new baseline: one code file changed, one deleted, one added, the doctor's tool changed, a prompt
        changed; beside them a non-code file and the library's rules directory changed, which never travel."""
        wt = self.t / "nb"
        git(self.work, "worktree", "add", "-q", "--detach", str(wt), self.base)
        a, top = wt / "pipeline" / "agent", wt
        (a / "harness" / "probe.py").write_text("v2\n")
        (a / "harness" / "old.py").unlink()
        (a / "harness" / "new_mod.py").write_text("new\n")
        (a / "prompts" / "plan.md").write_text("plan v2\n")
        (top / "pipeline" / "ontology_provenance" / "nrs_tools" / "atoms_train.py").write_text("# tool v2\n")
        (a / "NOTES.txt").write_text("not code v2\n")
        (a / "library" / "TrafficSpec" / "Rules" / "X").mkdir(parents=True)
        (a / "library" / "TrafficSpec" / "Rules" / "X" / "X_1.lean").write_text("-- development's rule\n")
        git(wt, "add", "-A"); git(wt, "commit", "-q", "-m", "development")
        sha = git(wt, "rev-parse", "HEAD").stdout.strip()
        git(self.work, "worktree", "remove", "--force", str(wt))
        return sha

    def py(self, code):
        return subprocess.run([sys.executable, "-c", code], cwd=self.agent, capture_output=True, text=True, check=True,
                              env={**os.environ, "PYTHONPATH": str(self.work / "pipeline" / "ontology_provenance")}).stdout

    def adopt(self):
        """The run's first stage, adopted: its code baseline the checkout's, no transition commit."""
        rd = self.agent / "results" / "t1"
        digest = json.loads(self.py("import json; from harness.tools.handoff import code_digest; print(json.dumps(code_digest()))"))
        row = s24_helpers.open_row("G0", run_id="t1", transition="adopt-1", code_baseline={"source_commit": self.base, "code": digest},
                                   semantic={}, acceptance_policy={"label_repair": False, "dependency": DEPENDENCY_POLICY, "review": "none"},
                                   effects={})
        (rd / "stages.jsonl").write_text(json.dumps(row) + "\n")
        (rd / "stage_transition.json").write_text(json.dumps({"transition_id": "adopt-1", "status": "done"}))
        git(self.work, "add", "-f", "pipeline/agent/results/t1/stages.jsonl", "pipeline/agent/results/t1/stage_transition.json")
        git(self.work, "commit", "-q", "-m", "t1: adopted as G0"); git(self.work, "push", "-q", "origin", "runs/t1")

    def enter(self, **env):
        e = {"NEW_BASE": self.new_base, "KIND": "generation", "FROM": "G0", "TRANSITION": "t-g1", **env}
        return self.launch("stage-enter", [], **e)

    def stage_calls(self):
        f = Path(str(self.log) + ".stage")
        return [json.loads(x) for x in f.read_text().splitlines()] if f.exists() else []

    def head(self):
        return git(self.work, "rev-parse", "HEAD").stdout.strip()

    def clean(self):
        return git(self.work, "status", "--porcelain", "--untracked-files=no").stdout == ""

    def show(self, rel, ref="runs/t1"):
        p = git(self.remote, "show", f"{ref}:{rel}", check=False)
        return p.stdout if p.returncode == 0 else None

    def assert_entered(self):
        """The stage commit and its `done` commit are on the remote run branch, once, and say what the brief says."""
        subjects = git(self.remote, "log", "--format=%H %P|%s", "runs/t1").stdout.splitlines()
        stage = [s for s in subjects if s.split("|", 1)[1] == f"stage G1: baseline {self.new_base}"]
        self.assertEqual(len(stage), 1, subjects)
        c, *parents = stage[0].split("|")[0].split()
        self.assertEqual(len(parents), 1)                                                       # never a merge
        self.assertIn("Stage-Transition: t-g1", git(self.remote, "log", "-1", "--format=%B", c).stdout.splitlines())
        self.assertEqual(subjects[0].split("|", 1)[1], "t1: stage G1 confirmed")
        self.assertEqual(sum("confirmed" in s for s in subjects), 1)
        p = "pipeline/agent/"
        for ref in (c, "runs/t1"):
            self.assertEqual(self.show(p + "harness/probe.py", ref), "v2\n")                       # replaced
            self.assertIsNone(self.show(p + "harness/old.py", ref))                                # deleted
            self.assertEqual(self.show(p + "harness/new_mod.py", ref), "new\n")                    # added
            self.assertEqual(self.show(p + "prompts/plan.md", ref), "plan v2\n")
            self.assertEqual(self.show("pipeline/ontology_provenance/nrs_tools/atoms_train.py", ref), "# tool v2\n")   # outside the agent dir
            self.assertEqual(self.show(p + "NOTES.txt", ref), "not code v1\n")                     # not code: never travels
            self.assertEqual(self.show(p + "library/TrafficSpec/Rules/X/X_1.lean", ref), "-- the run's rule\n")   # a run artifact
            self.assertEqual(self.show(p + "results/t1/note.txt", ref), "run\n")
        self.assertEqual(json.loads(self.show(p + "results/t1/stage_transition.json", c))["status"], "exported")
        self.assertEqual(json.loads(self.show(p + "results/t1/stage_transition.json")), {"transition_id": "t-g1", "status": "done", "commit": c})
        self.assertEqual([json.loads(x)["stage_id"] for x in self.show(p + "results/t1/stages.jsonl").splitlines()], ["G0", "G0", "G1"])
        self.assertEqual(json.loads(self.show(p + "results/t1/handoff/manifest.json"))["stage_id"], "G1")
        self.assertTrue({x["probe"] for x in self.stage_calls() if x["argv"][1] == "enter"} <= {"v2\n"})   # the harness ran on the new code
        self.assertTrue(self.clean())
        self.assertEqual(self.head(), git(self.remote, "rev-parse", "runs/t1").stdout.strip())
        return c

    # ------------------------------------------------------------------ review refused
    def test_stage_review_is_refused_before_any_loop(self):
        for staged in (True, False):
            with self.subTest(staged=staged):
                if not staged:
                    git(self.work, "rm", "-q", "--cached", "pipeline/agent/results/t1/stages.jsonl")
                    (self.agent / "results" / "t1" / "stages.jsonl").unlink()
                out = self.launch("resume", [{"status": "complete"}], STAGE="review")
                self.assertEqual(out.returncode, 2, out.stdout + out.stderr)
                self.assertIn("the current baseline registers no reviewer", out.stderr)
                self.assertEqual(len(self.loops()), 1)

    def test_kind_review_is_refused_before_the_code_changes(self):
        before = self.head()
        out = self.enter(KIND="review")
        self.assertEqual(out.returncode, 2, out.stdout + out.stderr)
        self.assertIn("the current baseline registers no reviewer", out.stderr)
        self.assertEqual(self.stage_calls(), [])
        self.assertEqual((self.head(), self.clean()), (before, True))
        self.assertEqual((self.agent / "harness" / "probe.py").read_text(), "v1\n")

    # ------------------------------------------------------------------ stage-enter
    def test_stage_enter_replaces_the_code_and_confirms(self):
        out = self.enter(PROMPTS_APPROVED="abc123")
        self.assertEqual(out.returncode, 0, out.stdout + out.stderr)
        self.assert_entered()
        argv = self.stage_calls()[0]["argv"]
        self.assertEqual(argv[:3], ["stage", "enter", "t1"])
        self.assertEqual(argv[argv.index("--prompts_approved") + 1], "abc123")
        self.assertNotIn("--scope", argv)
        n = len(git(self.remote, "rev-list", "runs/t1").stdout.split())
        again = self.enter()                                                          # done already: 0, nothing new
        self.assertEqual(again.returncode, 0, again.stdout + again.stderr)
        self.assertEqual(len(git(self.remote, "rev-list", "runs/t1").stdout.split()), n)
        self.assertEqual(len(self.stage_calls()), 2)                                  # neither enter nor confirm ran again

    def test_the_stage_calls_are_ones_the_real_stage_commands_accept(self):
        """Every `stage enter` and `stage confirm` the launcher makes parses with the harness's own stage
        command line and reaches the command with the launcher's transition, remote and branch; the new
        stage's baseline commit is NEW_BASE (whose clean checkout a closed stage is restored into), never
        the run branch's checkpoint, which holds the old code and the run."""
        from unittest import mock
        from harness.tools import stage
        out = self.enter(PROMPTS_APPROVED="abc123")
        self.assertEqual(out.returncode, 0, out.stdout + out.stderr)
        c = self.assert_entered()
        got = []
        with mock.patch.object(stage, "enter", lambda *a: got.append(("enter", *a))), \
                mock.patch.object(stage, "confirm", lambda *a: got.append(("confirm", *a))):
            for call in self.stage_calls():
                self.assertEqual(stage.main(call["argv"][1:]), 0, call["argv"])
        self.assertEqual(got, [("enter", "t1", "generation", "G0", "t-g1", None, "abc123", self.new_base),   # the new code's own commit
                               ("confirm", "t1", "t-g1", c, "origin", "runs/t1")])

    def test_a_refusal_of_the_harness_puts_the_code_back(self):
        before = self.head()
        out = self.enter(KIND="labels")                                               # labels from generation: the harness refuses
        self.assertEqual(out.returncode, 2, out.stdout + out.stderr)
        self.assertIn("a labels stage is entered from a review stage only", out.stderr)
        self.assertIn("the checkpoint's code is restored", out.stderr)
        self.assertEqual(self.stage_calls()[0]["probe"], "v2\n")                     # it was asked on the new code
        self.assertEqual((self.head(), self.clean()), (before, True))
        self.assertEqual((self.agent / "harness" / "probe.py").read_text(), "v1\n")
        self.assertTrue((self.agent / "harness" / "old.py").exists())
        self.assertFalse((self.agent / "harness" / "new_mod.py").exists())
        self.assertEqual((self.work / "pipeline/ontology_provenance/nrs_tools/atoms_train.py").read_text(), "")
        out = self.enter()                                                            # a clean checkpoint again: the transition proceeds
        self.assertEqual(out.returncode, 0, out.stdout + out.stderr)
        self.assert_entered()

    def test_stage_enter_preconditions(self):
        with self.subTest("dirty"):
            (self.agent / "NOTES.txt").write_text("edited\n")
            out = self.enter()
            self.assertEqual(out.returncode, 2); self.assertIn("uncommitted changes", out.stderr)
            git(self.work, "checkout", "--", "pipeline/agent/NOTES.txt")
        with self.subTest("unpushed"):
            (self.agent / "NOTES.txt").write_text("local\n")
            git(self.work, "commit", "-q", "-am", "local only")
            out = self.enter()
            self.assertEqual(out.returncode, 2); self.assertIn("not on origin", out.stderr)
            git(self.work, "reset", "-q", "--hard", "HEAD~1")
        with self.subTest("not the run branch"):
            git(self.work, "switch", "-q", "--detach")
            out = self.enter()
            self.assertEqual(out.returncode, 2); self.assertIn("runs on the checked-out run branch", out.stderr)
            git(self.work, "switch", "-q", "runs/t1")
        with self.subTest("no commit"):
            out = self.enter(NEW_BASE="nosuchref")
            self.assertEqual(out.returncode, 2); self.assertIn("is not a commit", out.stderr)
        self.assertEqual(self.stage_calls(), [])
        self.assertEqual((self.agent / "harness" / "probe.py").read_text(), "v1\n")

    def test_a_stop_at_every_step_is_continued_by_the_same_stage_enter(self):
        stops = [("killed before the harness ran", {"FAKE_STAGE": json.dumps({"at": "start", "kill": True})}, None),
                 *[(f"stopped at {s}", {"FAKE_STAGE": json.dumps({"at": s})}, 1) for s in ORDER[:3]],
                 ("killed after the export", {"FAKE_STAGE": json.dumps({"at": "exported", "kill": True})}, None),
                 ("stage commit not pushed", {"HOOK": "stage G1"}, 3),
                 ("killed before the confirmation", {"FAKE_STAGE": json.dumps({"at": "confirm", "kill": True})}, None),
                 ("killed after the confirmation", {"FAKE_STAGE": json.dumps({"at": "confirmed", "kill": True})}, None),
                 ("done commit not pushed", {"HOOK": "confirmed"}, 3)]
        for name, env, code in stops:
            with self.subTest(name):
                self.setUp()
                hook = env.pop("HOOK", "")
                self.flag.write_text(hook)
                out = self.enter(**env)
                if code is None:
                    self.assertLess(out.returncode, 0, out.stdout + out.stderr)                # the launcher was killed
                else:
                    self.assertEqual(out.returncode, code, out.stdout + out.stderr)
                self.flag.write_text("")
                out = self.enter()
                self.assertEqual(out.returncode, 0, out.stdout + out.stderr)
                self.assert_entered()

    # ------------------------------------------------------------------ resume of a staged run
    def entered(self):
        out = self.enter()
        self.assertEqual(out.returncode, 0, out.stdout + out.stderr)
        return self.assert_entered()

    def test_a_staged_resume_runs_on_its_stage(self):
        self.entered()
        out = self.launch("resume", [{"status": "awaiting_labels"}])
        self.assertEqual(out.returncode, 0, out.stdout + out.stderr)
        self.assertEqual(len(self.loops()), 2)
        self.assertEqual(self.loops()[-1]["stage_flags"], ["--label_deferred"])

    def test_a_staged_resume_refuses_a_merge_after_the_transition_commit(self):
        c = self.entered()
        dev = git(self.work, "commit-tree", "-p", c, "-m", "development", git(self.work, "rev-parse", f"{c}^{{tree}}").stdout.strip()).stdout.strip()
        git(self.work, "merge", "-q", "--no-ff", "-m", "merge development into the run", dev)
        out = self.launch("resume", [{"status": "complete"}])
        self.assertEqual(out.returncode, 2, out.stdout + out.stderr)
        self.assertIn(f"merge commit after its stage's transition commit {c}", out.stderr)
        self.assertEqual(len(self.loops()), 1)

    def test_a_staged_resume_refuses_code_other_than_its_stage(self):
        self.entered()
        (self.agent / "harness" / "probe.py").write_text("v3\n")
        git(self.work, "commit", "-q", "-am", "a code change on the run branch")
        out = self.launch("resume", [{"status": "complete"}])
        self.assertEqual(out.returncode, 2, out.stdout + out.stderr)
        self.assertIn("differs from the code baseline of the run's stage `G1`", out.stderr)
        self.assertIn("harness/probe.py", out.stderr)
        self.assertEqual(len(self.loops()), 1)

    def test_a_staged_resume_refuses_another_launch_kind_and_an_unfinished_transition(self):
        self.entered()
        ds = self.t / "ds"; ds.mkdir()
        out = self.launch("resume", [{"status": "complete"}], STAGE="labels", LABEL_DATASET=str(ds))
        self.assertEqual(out.returncode, 2, out.stdout + out.stderr)
        self.assertIn("allows generation launches, not STAGE=labels", out.stderr)
        (self.agent / "results" / "t1" / "stage_transition.json").write_text(json.dumps({"transition_id": "t-g2", "status": "applied"}))
        git(self.work, "commit", "-q", "-am", "a transition begun elsewhere")
        out = self.launch("resume", [{"status": "complete"}])
        self.assertEqual(out.returncode, 2, out.stdout + out.stderr)
        self.assertIn("stopped at `applied`", out.stderr)
        self.assertEqual(len(self.loops()), 1)

    def test_an_adopted_first_stage_keeps_the_baseline_rule(self):
        out = self.launch("resume", [{"status": "awaiting_labels"}])                 # G0 without a transition commit
        self.assertEqual(out.returncode, 0, out.stdout + out.stderr)
        dev = git(self.work, "commit-tree", "-p", self.base, "-m", "development", git(self.work, "rev-parse", f"{self.base}^{{tree}}").stdout.strip()).stdout.strip()
        git(self.work, "merge", "-q", "--no-ff", "-m", "merge development into the run", dev)
        out = self.launch("resume", [{"status": "complete"}])
        self.assertEqual(out.returncode, 2, out.stdout + out.stderr)
        self.assertIn(f"merge commit after its baseline {self.base}", out.stderr)
        self.assertEqual(len(self.loops()), 2)


if __name__ == "__main__":
    unittest.main()
