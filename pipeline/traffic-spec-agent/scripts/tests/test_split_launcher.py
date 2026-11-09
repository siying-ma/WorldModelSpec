"""The split run's launcher (`scripts/run-generation.sh`) on a temporary git repository with a local
bare remote: an explicit list of checkpoint files committed though ignored, deletions recorded, new
runs and resumes kept apart, no branch reset, staged changes refused, a push that fails retried on the
same commit and no further loop launched, the next launch pushing it first, an abnormal exit stopped
with diagnostics, continuation only on an iteration-limit checkpoint, each launch's iteration bound
from the persisted progress, and no key in a log or a commit.

The harness is a stand-in package in the temporary checkout: its `loop` writes what the script for
that launch says (state, summary, files) and counts its launches (the model calls a real loop would
make); its `handoff export` lists the run's files as the real one does."""
import json
import os
import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

LAUNCHER = Path(__file__).resolve().parents[1] / "run-generation.sh"
SECRET = "sk-test-NEVER-LOGGED-123"

FAKE_MAIN = r'''
import json, os, sys, uuid
from pathlib import Path
a = sys.argv[1:]
def opt(name, default=None):
    return a[a.index(name) + 1] if name in a else default
if a[0] == "split":
    print("train"); sys.exit(0)
if a[0] == "doctor":
    sys.exit(0)
if a[0] == "loop":
    run = opt("--run_id"); rd = Path("results") / run
    counter = Path(os.environ["FAKE_COUNTER"])
    n = int(counter.read_text()) if counter.exists() else 0
    counter.write_text(str(n + 1))
    given, i = {}, 1                           # the options as `Cli.loop` reads them: a flag alone is true
    while i < len(a):
        k = a[i][2:]
        if i + 1 < len(a) and not a[i + 1].startswith("--"):
            given[k], i = a[i + 1], i + 2
        else:
            given[k], i = True, i + 1
    saved_f = rd / "options.json"                # what the loop keeps of a run's options: the saved ones, then those given
    saved = json.loads(saved_f.read_text()) if saved_f.exists() else {}
    stage = ("label_deferred", "label_stage", "label_dataset", "max_iterations", "run_id")
    effective = {**{k: v for k, v in saved.items() if k not in stage}, **given}
    rd.mkdir(parents=True, exist_ok=True)
    saved_f.write_text(json.dumps(effective))
    with open(os.environ["FAKE_LOG"], "a") as f:
        f.write(json.dumps({"max_iterations": int(opt("--max_iterations")), "stage_flags": [x for x in a if x in ("--label_deferred", "--label_stage")],
                            "judge_effort": opt("--judge_effort"), "total": opt("--total_budget_usd"), "workers": opt("--workers"),
                            "argv": a, "effective": effective}) + "\n")
    o = json.loads(Path(os.environ["FAKE_SCRIPT"]).read_text())[n]
    if o.get("crash"):
        print("Traceback: a crash"); sys.exit(1)
    rd.mkdir(parents=True, exist_ok=True)
    it = int(opt("--max_iterations"))
    (rd / "state.json").write_text(json.dumps({"iteration": it, "prog": {"stage": o.get("stage", "done")}}))
    (rd / "summary.json").write_text(json.dumps({"status": o["status"], "stop": o.get("stop", ""), "n": n}))
    for rel, text in o.get("files", {}).items():
        Path(rel).parent.mkdir(parents=True, exist_ok=True); Path(rel).write_text(text)
    for rel in o.get("delete", []):
        Path(rel).unlink()
    sys.exit(0 if o["status"] == "complete" else 1)
if a[:2] == ["handoff", "export"]:
    run = a[2]; rd = Path("results") / run
    st = json.loads((rd / "state.json").read_text())
    if st["prog"]["stage"] != "done":
        print("not at a checkpoint"); sys.exit(1)
    hd = rd / "handoff"; hd.mkdir(exist_ok=True)
    files = sorted(str(p) for p in rd.rglob("*") if p.is_file() and "handoff" not in p.parts)
    files += sorted(str(p) for p in Path("library/TrafficSpec/Rules").rglob("*") if p.is_file())
    was = json.loads((hd / "manifest.json").read_text()) if (hd / "manifest.json").exists() else {}
    base = was.get("baseline") or {"source_commit": opt("--source_baseline"), "code": {"digest": "d"}}
    (hd / "manifest.json").write_text(json.dumps({"export_id": uuid.uuid4().hex, "baseline": base}))
    (hd / "files.txt").write_text("".join(f + "\n" for f in files + [str(hd / "manifest.json"), str(hd / "files.txt")]))
    sys.exit(0)
sys.exit(2)
'''


def git(cwd, *args, check=True):
    return subprocess.run(["git", *args], cwd=cwd, capture_output=True, text=True, check=check)


class Launcher(unittest.TestCase):

    def setUp(self):
        self.t = Path(tempfile.mkdtemp(prefix="launcher-"))
        self.addCleanup(shutil.rmtree, self.t, True)
        self.remote = self.t / "remote.git"
        git(self.t, "init", "-q", "--bare", str(self.remote))
        self.work = self.t / "work"
        git(self.t, "clone", "-q", str(self.remote), str(self.work))
        for k, v in (("user.name", "Test"), ("user.email", "t@example.org"), ("init.defaultBranch", "main")):
            git(self.work, "config", k, v)
        self.agent = self.work / "pipeline" / "agent"
        (self.agent / "scripts").mkdir(parents=True)
        shutil.copy2(LAUNCHER, self.agent / "scripts" / "run-generation.sh")
        (self.agent / "harness" / "store").mkdir(parents=True)
        (self.agent / "harness" / "__init__.py").write_text("")
        (self.agent / "harness" / "store" / "__init__.py").write_text("")
        (self.agent / "harness" / "store" / "state.py").write_text(
            "from dataclasses import dataclass\n@dataclass\nclass Options:\n    label_deferred: bool = False\n    label_stage: bool = False\n")
        (self.agent / "harness" / "__main__.py").write_text(FAKE_MAIN)
        shutil.copy2(LAUNCHER.parents[1] / "harness" / "store" / "paths.py", self.agent / "harness" / "store" / "paths.py")   # the real rule of a new run
        (self.agent / "library" / "TrafficSpec" / "Rules").mkdir(parents=True)
        (self.agent / "library" / "TrafficSpec" / "Rules" / ".keep").write_text("")
        (self.agent / ".gitignore").write_text("results/\n*harness*.lean\n")
        tools = self.work / "pipeline" / "ontology_provenance" / "nrs_tools"      # the WorldModelSpec layout: the doctor's split tools
        tools.mkdir(parents=True)
        (tools / "atoms_train.py").write_text("")
        git(self.work, "add", "-A"); git(self.work, "commit", "-q", "-m", "base")
        git(self.work, "push", "-q", "origin", "HEAD:refs/heads/main", "HEAD:refs/heads/remote/full-train-generation")
        self.base = git(self.work, "rev-parse", "HEAD").stdout.strip()
        self.bin = self.t / "bin"
        self.bin.mkdir()
        for name in ("lake", "claude"):
            (self.bin / name).write_text("#!/bin/sh\nexit 0\n"); (self.bin / name).chmod(0o755)
        self.counter, self.log, self.script = self.t / "counter", self.t / "loops.jsonl", self.t / "script.json"

    def launch(self, action, outcomes, cwd=None, unset=(), **env):
        self.script.write_text(json.dumps(outcomes))
        self.counter.write_text("0")                         # the script's outcomes are this launch's
        e = {"PATH": f"{self.bin}:{os.environ['PATH']}", "HOME": str(self.t), "RUN_ID": "t1", "PYTHON": sys.executable,
             "SKIP_BUILD": "1", "OPENAI_API_KEY": SECRET, "PUSH_RETRIES": "2", "PUSH_WAIT": "0", "LAUNCHES": "5",
             "FAKE_COUNTER": str(self.counter), "FAKE_LOG": str(self.log), "FAKE_SCRIPT": str(self.script),
             "LAWS": "laws.jsonl", "ONTOLOGY": "o.md", "READING": "r.json", "GIT_CONFIG_NOSYSTEM": "1", **env}
        e.pop("ANTHROPIC_API_KEY", None)
        for k in unset:                                      # a variable this invocation does not set
            e.pop(k, None)
        return subprocess.run(["bash", "scripts/run-generation.sh", action], cwd=cwd or self.agent, env=e, capture_output=True, text=True)

    def loops(self):
        return [json.loads(x) for x in self.log.read_text().splitlines()] if self.log.exists() else []

    def remote_files(self, ref="runs/t1"):
        return set(git(self.remote, "ls-tree", "-r", "--name-only", ref).stdout.split())

    def assert_no_secret(self):
        logs = "".join(p.read_text(errors="replace") for p in (self.agent / ".runtime").rglob("*") if p.is_file())
        history = git(self.work, "log", "-p", "--all").stdout
        self.assertNotIn(SECRET, logs + history)

    def test_a_new_run_checkpoints_each_iteration_and_stops_at_the_pause(self):
        out = self.launch("new", [
            {"status": "incomplete", "stop": "iteration_limit",
             "files": {"results/t1/iter-001/code/X/gate_harness.lean": "-- ignored by .gitignore\n",
                       "library/TrafficSpec/Rules/X/X_1.lean": "-- rule\n", "results/t1/gone.txt": "x"}},
            {"status": "awaiting_labels", "delete": ["results/t1/gone.txt"]}])
        self.assertEqual(out.returncode, 0, out.stdout + out.stderr)
        self.assertEqual([x["max_iterations"] for x in self.loops()], [1, 2])         # one more each launch
        self.assertEqual({tuple(x["stage_flags"]) for x in self.loops()}, {("--label_deferred",)})
        self.assertEqual(self.loops()[0]["judge_effort"], "high")                     # every role's effort passed
        self.assertEqual(self.loops()[0]["total"], "325")                              # summed as decimals
        self.assertEqual(self.loops()[0]["workers"], "4")
        files = self.remote_files()
        self.assertIn("pipeline/agent/results/t1/iter-001/code/X/gate_harness.lean", files)   # ignored, listed, committed
        self.assertIn("pipeline/agent/library/TrafficSpec/Rules/X/X_1.lean", files)
        self.assertNotIn("pipeline/agent/results/t1/gone.txt", files)                        # a deletion is recorded
        self.assertFalse(any(".runtime" in f for f in files))
        log = git(self.remote, "log", "--format=%s%n%b", "runs/t1").stdout
        self.assertIn(f"source baseline {self.base}", log)
        self.assertEqual(git(self.remote, "rev-parse", "main").stdout.strip(), self.base)     # no other branch touched
        self.assert_no_secret()

        again = self.launch("new", [])
        self.assertEqual(again.returncode, 2)
        self.assertIn("exists", again.stderr)                                          # never a reset of the branch

    def subset(self, law_ids=("L-1",)):
        """The real subset writer, as the operator runs it before `new`."""
        from unittest import mock
        from harness.store import paths
        from scripts.subset_laws import subset
        corpus = self.t / "corpus" / "laws.jsonl"
        corpus.parent.mkdir(exist_ok=True)
        corpus.write_text("".join(json.dumps({"id": i, "title": i, "text": "shall stop.", "source": "s"}) + "\n" for i in ("L-1", "L-2")))
        corpus.with_name("definitions.jsonl").write_text(json.dumps({"id": "DEF-1", "term": "vehicle", "text": "a vehicle"}) + "\n")
        with mock.patch.object(paths, "RESULTS", self.agent / "results"):
            return subset("t1", corpus, list(law_ids))

    def test_a_new_run_over_a_law_subset_checkpoints_it(self):
        lf = self.subset()
        out = self.launch("new", [{"status": "awaiting_labels"}], LAWS=str(lf.relative_to(self.agent)))
        self.assertEqual(out.returncode, 0, out.stdout + out.stderr)
        self.assertEqual(len(self.loops()), 1)
        files = self.remote_files()
        for name in ("laws.jsonl", "definitions.jsonl"):
            rel = f"pipeline/agent/results/t1/laws/{name}"
            self.assertIn(rel, files)
            self.assertEqual(git(self.remote, "show", f"runs/t1:{rel}").stdout, (self.agent / "results" / "t1" / "laws" / name).read_text())
        self.assertEqual(self.loops()[0]["argv"][self.loops()[0]["argv"].index("--laws") + 1], "results/t1/laws/laws.jsonl")

    def test_rehearsal_subset_new_launches_spent_then_resume(self):
        """subset → new → checkpoint → launches spent on an iteration limit (exit 0, summary
        incomplete / iteration_limit, the log says to resume, as the operators' guide does) → resume
        from the persisted progress with the saved options."""
        lf = self.subset()
        out = self.launch("new", [{"status": "incomplete", "stop": "iteration_limit"}], LAWS=str(lf.relative_to(self.agent)), LAUNCHES="1")
        self.assertEqual(out.returncode, 0, out.stdout + out.stderr)
        summary = json.loads(git(self.remote, "show", "runs/t1:pipeline/agent/results/t1/summary.json").stdout)
        self.assertEqual((summary["status"], summary["stop"]), ("incomplete", "iteration_limit"))
        self.assertIn("resume with: RUN_ID=t1 STAGE=generation", (self.agent / ".runtime" / "t1" / "launcher.log").read_text())
        guide = (LAUNCHER.parents[1] / "REMOTE_LAUNCH.md").read_text()
        self.assertRegex(guide, r"\| `incomplete` / `iteration_limit` \|[^\n]*\| `resume` \|")
        out = self.launch("resume", [{"status": "awaiting_labels"}], unset=("LAWS", "ONTOLOGY", "READING"))
        self.assertEqual(out.returncode, 0, out.stdout + out.stderr)
        first, second = self.loops()
        self.assertEqual((first["max_iterations"], second["max_iterations"]), (1, 2))
        self.assertNotIn("--laws", second["argv"])                              # the saved subset stands
        self.assertEqual(second["effective"]["laws"], "results/t1/laws/laws.jsonl")
        self.assertIn("pipeline/agent/results/t1/laws/laws.jsonl", self.remote_files())

    def test_new_refuses_a_run_directory_holding_more_than_its_subset(self):
        self.subset()
        for stray in ("results/t1/notes.txt", "results/t1/laws/notes.txt"):
            with self.subTest(stray=stray):
                (self.agent / stray).write_text("x")
                out = self.launch("new", [{"status": "awaiting_labels"}])
                self.assertEqual(out.returncode, 2, out.stdout + out.stderr)
                self.assertIn("holds more than the run's law subset", out.stderr)
                self.assertEqual(self.loops(), [])
                (self.agent / stray).unlink()

    def test_a_python_without_the_openai_sdk_is_refused_before_any_loop(self):
        stub = self.t / "no_sdk" / "openai"
        stub.mkdir(parents=True)
        (stub / "__init__.py").write_text("raise ImportError('the SDK is not installed')\n")
        out = self.launch("new", [{"status": "complete"}], PYTHONPATH=str(stub.parent))
        self.assertEqual(out.returncode, 2, out.stdout + out.stderr)
        self.assertIn("the OpenAI SDK", out.stderr)
        self.assertEqual(self.loops(), [])
        self.assertEqual(git(self.remote, "branch", "--list", "runs/t1").stdout.strip(), "")

    def test_staged_unrelated_changes_are_refused_before_any_loop(self):
        (self.agent / "notes.txt").write_text("mine\n")
        git(self.work, "add", "pipeline/agent/notes.txt")
        out = self.launch("new", [{"status": "complete"}])
        self.assertEqual(out.returncode, 2)
        self.assertIn("staged", out.stderr)
        self.assertEqual(self.loops(), [])

    def test_a_failed_push_stops_before_the_next_loop_and_is_pushed_first_on_resume(self):
        hook = self.remote / "hooks" / "pre-receive"
        hook.write_text("#!/bin/sh\nexit 1\n"); hook.chmod(0o755)                     # a dry run passes, a real push is refused
        out = self.launch("new", [{"status": "incomplete", "stop": "iteration_limit"}, {"status": "awaiting_labels"}])
        self.assertEqual(out.returncode, 3, out.stdout + out.stderr)
        self.assertEqual(len(self.loops()), 1)                                         # no further model call
        local = git(self.work, "rev-parse", "HEAD").stdout.strip()
        hook.unlink()
        out = self.launch("resume", [{"status": "awaiting_labels"}])
        self.assertEqual(out.returncode, 0, out.stdout + out.stderr)
        self.assertIn(local, git(self.remote, "rev-list", "runs/t1").stdout.split())   # the same commit, pushed first
        self.assertEqual([x["max_iterations"] for x in self.loops()], [1, 2])          # resumed from the persisted progress

    def test_an_abnormal_exit_stops_with_diagnostics(self):
        out = self.launch("new", [{"crash": True}])
        self.assertEqual(out.returncode, 1)
        self.assertTrue((self.agent / ".runtime" / "t1" / "diagnostics.txt").exists())
        self.assertEqual(git(self.remote, "branch", "--list", "runs/t1").stdout.strip(), "")    # nothing committed or pushed

    def test_a_status_other_than_an_iteration_limit_stops(self):
        out = self.launch("new", [{"status": "paused_budget", "stage": "nodes"}, {"status": "complete"}])
        self.assertEqual(out.returncode, 1)
        self.assertEqual(len(self.loops()), 1)
        self.assertIn("no checkpoint", out.stdout + out.stderr + (self.agent / ".runtime/t1/launcher.log").read_text())
        out = self.launch("resume", [{"status": "complete"}])                         # the unfinished iteration resumes: bound 1
        self.assertEqual(out.returncode, 0, out.stdout + out.stderr)
        self.assertEqual([x["max_iterations"] for x in self.loops()], [1, 1])

    def test_a_pause_for_the_operator_stops_at_its_checkpoint_and_hands_over_to_no_one(self):
        """`paused_budget` and `awaiting_operator` stop with 4 after the checkpoint is pushed, with the
        hint for each; a leftover `iteration_limit` beside them never continues the launches."""
        for status, hint in (("paused_budget", "raise the named limit explicitly and resume"),
                             ("awaiting_operator", "operator decision needed; see stop_reason and TO_USER.md")):
            for stop in ("", "iteration_limit"):
                with self.subTest(status=status, stop=stop):
                    self.setUp()
                    out = self.launch("new", [{"status": status, "stop": stop}, {"status": "awaiting_labels"}])
                    self.assertEqual(out.returncode, 4, out.stdout + out.stderr)
                    self.assertEqual(len(self.loops()), 1)                              # no further launch, no hand-over
                    self.assertIn(hint, out.stdout)
                    self.assertNotIn("STAGE=labels", out.stdout)
                    self.assertIn(f"{status}", git(self.remote, "log", "-1", "--format=%s", "runs/t1").stdout)   # its checkpoint, pushed
                    again = self.launch("resume", [{"status": status, "stop": stop}])
                    self.assertEqual(again.returncode, 4, again.stdout + again.stderr)   # resumed unchanged: the same stop
                    self.assertEqual(len(self.loops()), 2)

    def test_a_resume_refuses_a_checkout_behind_its_remote(self):
        self.assertEqual(self.launch("new", [{"status": "awaiting_labels"}]).returncode, 0)
        other = self.t / "other"
        git(self.t, "clone", "-q", "--branch", "runs/t1", str(self.remote), str(other))
        for k, v in (("user.name", "O"), ("user.email", "o@example.org")):
            git(other, "config", k, v)
        (other / "pipeline/agent/extra.txt").write_text("x\n")
        git(other, "add", "-A"); git(other, "commit", "-q", "-m", "another writer"); git(other, "push", "-q", "origin", "runs/t1")
        out = self.launch("resume", [{"status": "complete"}])
        self.assertEqual(out.returncode, 2)
        self.assertIn("pull first", out.stderr)
        self.assertEqual(len(self.loops()), 1)

    def test_the_label_stage_needs_its_dataset_and_ends_at_the_handback(self):
        self.assertEqual(self.launch("new", [{"status": "awaiting_labels"}]).returncode, 0)
        out = self.launch("resume", [{"status": "awaiting_generation"}], STAGE="labels")
        self.assertEqual(out.returncode, 2)
        self.assertIn("LABEL_DATASET", out.stderr)
        ds = self.t / "ds"; ds.mkdir()
        out = self.launch("resume", [{"status": "awaiting_generation"}], STAGE="labels", LABEL_DATASET=str(ds))
        self.assertEqual(out.returncode, 0, out.stdout + out.stderr)
        self.assertEqual(self.loops()[-1]["stage_flags"], ["--label_stage"])

    def test_the_acquisition_profile_is_given_to_a_new_run_only(self):
        out = self.launch("new", [{"status": "awaiting_labels"}], ACQUISITION_PROFILE="carla_scene_graph")
        self.assertEqual(out.returncode, 0, out.stdout + out.stderr)
        argv = self.loops()[0]["argv"]
        self.assertEqual(argv[argv.index("--acquisition_profile") + 1], "carla_scene_graph")
        refused = self.launch("resume", [{"status": "complete"}], ACQUISITION_PROFILE="carla_scene_graph")
        self.assertEqual(refused.returncode, 2)
        self.assertIn("ACQUISITION_PROFILE is given to `new` only", refused.stderr)
        self.assertEqual(len(self.loops()), 1)                                   # refused before any loop

    def test_a_resume_inherits_the_saved_budgets_models_and_efforts(self):
        chosen = {"CLAUDE_BUDGET": "12.5", "OPENAI_BUDGET": "0.75", "LABEL_REPAIR_ATTEMPTS": "1", "LABEL_REPAIR_BUDGET": "1",
                  "MODEL": "claude-test-model", "JUDGE_EFFORT": "low", "SESSION_CAP": "3", "WORKERS": "2"}
        out = self.launch("new", [{"status": "awaiting_labels"}], **chosen)
        self.assertEqual(out.returncode, 0, out.stdout + out.stderr)
        first = self.loops()[0]["effective"]
        self.assertNotIn("--acquisition_profile", self.loops()[0]["argv"])      # unset: none passed, no default
        ds = self.t / "ds"; ds.mkdir()
        out = self.launch("resume", [{"status": "awaiting_generation"}], STAGE="labels", LABEL_DATASET=str(ds))
        self.assertEqual(out.returncode, 0, out.stdout + out.stderr)
        resumed = self.loops()[1]
        for flag in ("--claude_budget_usd", "--openai_budget_usd", "--total_budget_usd", "--label_repair_attempts", "--label_repair_budget",
                     "--model", "--judge_effort", "--plan_effort", "--session_budget_usd", "--workers", "--feedback"):
            self.assertNotIn(flag, resumed["argv"])                       # nothing passed that this invocation did not set
        self.assertIn("--label_stage", resumed["argv"])
        self.assertEqual(resumed["argv"][resumed["argv"].index("--label_dataset") + 1], str(ds))
        eff = resumed["effective"]
        self.assertEqual({k: eff[k] for k in ("claude_budget_usd", "openai_budget_usd", "total_budget_usd", "label_repair_attempts",
                                              "label_repair_budget", "model", "judge_effort", "session_budget_usd", "workers")},
                         {"claude_budget_usd": "12.5", "openai_budget_usd": "0.75", "total_budget_usd": "13.25", "label_repair_attempts": "1",
                          "label_repair_budget": "1", "model": "claude-test-model", "judge_effort": "low", "session_budget_usd": "3", "workers": "2"})
        per_launch = ("run_id", "max_iterations", "label_deferred", "label_stage", "label_dataset")
        self.assertEqual({k: v for k, v in eff.items() if k not in per_launch}, {k: v for k, v in first.items() if k not in per_launch})

        # raising a budget on resume is explicit, the total with it
        refused = self.launch("resume", [{"status": "complete"}], CLAUDE_BUDGET="40")
        self.assertEqual(refused.returncode, 2)
        self.assertIn("TOTAL_BUDGET", refused.stderr)
        self.assertEqual(len(self.loops()), 2)
        out = self.launch("resume", [{"status": "complete"}], CLAUDE_BUDGET="40", TOTAL_BUDGET="40.75")
        self.assertEqual(out.returncode, 0, out.stdout + out.stderr)
        eff = self.loops()[2]["effective"]
        self.assertEqual((eff["claude_budget_usd"], eff["total_budget_usd"], eff["openai_budget_usd"], eff["model"]),
                         ("40", "40.75", "0.75", "claude-test-model"))

        # the real `Cli.loop` given the launcher's own arguments: a resume keeps every saved cap, model and effort
        from unittest import mock
        from harness.__main__ import Cli
        from harness.store import paths
        import dataclasses
        seen = []

        def run_loop(opts):
            seen.append(opts)
            d = paths.run_dir(opts.run_id); d.mkdir(parents=True, exist_ok=True)
            (d / "options.json").write_text(json.dumps({k: (str(v) if isinstance(v, Path) else v) for k, v in dataclasses.asdict(opts).items()}))
            return {"status": "awaiting_labels"}

        def fire_args(argv):
            kw, i = {}, 1
            while i < len(argv):
                k = argv[i][2:]
                if i + 1 < len(argv) and not argv[i + 1].startswith("--"):
                    v = argv[i + 1]
                    for cast in (int, float):
                        try:
                            v = cast(v); break
                        except ValueError:
                            pass
                    kw[k], i = v, i + 2
                else:
                    kw[k], i = True, i + 1
            return kw
        with mock.patch.object(paths, "RESULTS", self.t / "real-results"), mock.patch("harness.loop.run_loop", run_loop):
            new_kw, res_kw = fire_args(self.loops()[0]["argv"]), fire_args(resumed["argv"])
            Cli().loop(new_kw.pop("run_id"), **new_kw)
            Cli().loop(res_kw.pop("run_id"), **res_kw)
        a, b = seen
        for k in ("claude_budget_usd", "openai_budget_usd", "total_budget_usd", "session_budget_usd", "repair_budget_usd", "judge_budget_usd",
                  "aggregate_verifier_budget_usd", "label_repair_attempts", "label_repair_budget", "model", "reviewer_model",
                  "aggregate_verifier_model", "plan_effort", "code_effort", "review_effort", "judge_effort", "aggregate_verifier_effort", "workers"):
            self.assertEqual(getattr(b, k), getattr(a, k), k)
        self.assertEqual((a.claude_budget_usd, a.label_repair_attempts, a.model, a.judge_effort), (12.5, 1, "claude-test-model", "low"))
        self.assertTrue(b.label_stage and not b.label_deferred)

    def test_a_linked_worktree_and_a_normal_clone(self):
        """A run launched from a linked worktree (its git directory has no `info/`), then resumed from a
        normal clone of the run branch alone, which holds only the tracked code and the committed checkpoint."""
        wt = self.t / "linked"
        git(self.work, "worktree", "add", "-q", "--detach", str(wt), "HEAD")
        self.assertFalse((Path(git(wt, "rev-parse", "--git-dir").stdout.strip()) / "info").exists())
        agent = wt / "pipeline" / "agent"
        out = self.launch("new", [{"status": "incomplete", "stop": "iteration_limit",
                                   "files": {"library/TrafficSpec/Rules/X/X_1.lean": "-- rule\n"}},
                                  {"status": "awaiting_labels"}], cwd=agent, CLAUDE_BUDGET="7.5", REPAIR_CAP="1.25")
        self.assertEqual(out.returncode, 0, out.stdout + out.stderr)
        self.assertEqual(len(self.loops()), 2)
        self.assertTrue((agent / ".runtime" / "t1" / "launcher.log").is_file())
        self.assertNotIn(".runtime", git(wt, "status", "--porcelain", "--untracked-files=all").stdout)   # the logs stay out of git
        self.assertIn("pipeline/agent/library/TrafficSpec/Rules/X/X_1.lean", self.remote_files())
        clone = self.t / "clone"
        git(self.t, "clone", "-q", "--branch", "runs/t1", str(self.remote), str(clone))
        for k, v in (("user.name", "L"), ("user.email", "l@example.org")):
            git(clone, "config", k, v)
        ds = self.t / "ds"; ds.mkdir()
        out = self.launch("resume", [{"status": "awaiting_generation"}], cwd=clone / "pipeline" / "agent", STAGE="labels", LABEL_DATASET=str(ds))
        self.assertEqual(out.returncode, 0, out.stdout + out.stderr)
        eff = self.loops()[-1]["effective"]
        self.assertEqual((eff["claude_budget_usd"], eff["total_budget_usd"], eff["repair_budget_usd"]), ("7.5", "32.5", "1.25"))
        self.assertNotIn("--claude_budget_usd", self.loops()[-1]["argv"])

    def test_a_checkout_without_the_doctor_tools_is_refused_before_any_loop(self):
        git(self.work, "rm", "-q", "-r", "pipeline/ontology_provenance")
        git(self.work, "commit", "-q", "-m", "the agent directory alone")
        git(self.work, "push", "-q", "-f", "origin", "HEAD:refs/heads/remote/full-train-generation")   # as the baseline
        out = self.launch("new", [{"status": "complete"}], PYTHONPATH="")
        self.assertEqual(out.returncode, 2)
        self.assertIn("nrs_tools", out.stderr)
        self.assertIn("whole WorldModelSpec repository", out.stderr)
        self.assertEqual(self.loops(), [])

    def test_runs_branch_from_the_code_baseline_and_never_take_a_merge(self):
        (self.agent / "dev.txt").write_text("development\n")
        git(self.work, "add", "-A"); git(self.work, "commit", "-q", "-m", "development past the baseline")
        out = self.launch("new", [{"status": "awaiting_labels"}])
        self.assertEqual(out.returncode, 2)
        self.assertIn("tip of the code baseline", out.stderr)
        git(self.work, "reset", "-q", "--hard", self.base)
        self.assertEqual(self.launch("new", [{"status": "awaiting_labels"}]).returncode, 0)
        dev = git(self.work, "commit-tree", "-p", self.base, "-m", "development", git(self.work, "rev-parse", f"{self.base}^{{tree}}").stdout.strip()).stdout.strip()
        git(self.work, "merge", "-q", "--no-ff", "-m", "merge development into the run", dev)
        out = self.launch("resume", [{"status": "complete"}])
        self.assertEqual(out.returncode, 2)
        self.assertIn("merge commit", out.stderr)
        self.assertEqual(len(self.loops()), 1)

    def test_amounts_are_checked_as_decimals(self):
        out = self.launch("new", [{"status": "complete"}], CLAUDE_BUDGET="12.5", OPENAI_BUDGET="0.75")
        self.assertEqual(out.returncode, 0, out.stdout + out.stderr)
        self.assertEqual(self.loops()[0]["total"], "13.25")
        bad = self.launch("resume", [{"status": "complete"}], SESSION_CAP="lots")
        self.assertEqual(bad.returncode, 2)


if __name__ == "__main__":
    unittest.main()
