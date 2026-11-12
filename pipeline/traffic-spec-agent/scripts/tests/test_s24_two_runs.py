"""One transition at a time in a repository: while run `o`'s transition is begun and not done, no stage
command of another run (`enter`, `adopt`, `confirm`) and no loop launch of any run goes past taking the
library: each is refused before it completes a journal or writes anything, the whole repository byte
for byte unchanged; the same run's same transition still goes on, and once it is done the other run's
transition runs. A test run made before stages existed resumes as before but is no base run of a new
training or test run.

Run `o`'s transition is a real `stage enter` stopped after every one of its write points."""
import io
import json
import unittest
from contextlib import redirect_stdout

from harness import loop
from harness.phases import candidate
from harness.store import owner, paths, stages
from harness.tools import stage
from scripts.subset_laws import subset
from scripts.tests import test_s24_a2_stage as a2
from scripts.tests.test_recovery import Fixture, World, node
from scripts.tests.s24_helpers import real_ownership, released

REAL_RUN_LOOP = loop._run_loop                                    # the production path, which the legacy fixture wraps


class OneTransitionAtATime(unittest.TestCase):

    def test_another_runs_stage_commands_wait_for_an_unfinished_transition(self):
        k, finished, seen = 0, False, set()
        while not finished and k < 30:
            k += 1
            with self.subTest(stop_after=k), a2.world() as w:
                a2.make_run(w.root, "o")
                a2.first_stage("o")
                w.change("scripts/run-generation.sh")
                pw, pr, _n = a2.StoppedTransition.counting(k)
                try:
                    with real_ownership(), pw, pr:                     # o's transition takes the library for real
                        stage.enter("o", "generation", "G0", "t-o")
                    finished = True
                except a2.Crash:
                    pass
                if finished:
                    break
                st = stages.transition_state(paths.run_dir("o"))
                if st is None or st.get("status") == "done":
                    continue
                seen.add(st["status"])
                pending = candidate.pending()                       # a journal of o's the library may still wait on
                before = a2.tree_bytes(w.root)
                with real_ownership():                                  # each command as its own process, the real takeover
                    for name, run in (("enter", lambda: stage.enter("r", "generation", "G0", "t-r")),
                                      ("confirm", lambda: stage.confirm("r", "t-r", "0" * 40)),
                                      ("adopt", lambda: stage.adopt("r", str(w.t / "elsewhere"), "t-r"))):
                        with self.subTest(stop_after=k, command=name), redirect_stdout(io.StringIO()):
                            with self.assertRaisesRegex(SystemExit, "run `o`: the stage transition `t-o` stopped at"):
                                run()
                            self.assertFalse(owner.holds(), name)            # refused before the library was taken
                            released()
                            self.assertEqual(a2.tree_bytes(w.root), before, name)     # pointer, journal, library, runs
                            self.assertEqual(candidate.pending(), pending)
                    rec = stage.enter("o", "generation", "G0", "t-o")          # o's own transition goes on
                    released()
                    self.assertEqual(rec["status"], "exported")
                    stage.confirm("o", "t-o", w.push(), branch="runs/r")     # the fixture pushes to one branch
                    released()
                    stage.enter("r", "generation", "G0", "t-r")              # then r's runs
                    self.assertEqual(stages.active_stage(paths.run_dir("r"))["stage_id"], "G1")
        self.assertTrue(finished)
        self.assertTrue({"prepared", "applied"} <= seen, seen)

    def test_a_loop_launch_of_another_run_waits_too(self):
        w = World({"L-1": "shall stop."})
        w.plans = {"L-1": [node("L_1", "shall stop.", "L-1")]}
        with Fixture(w, staged=True) as f:
            other = paths.run_dir("o")
            other.mkdir(parents=True)
            (other / stages.TRANSITION_FILE).write_text(json.dumps({"transition_id": "t-o", "status": "applied"}))
            # a library once owned has its (empty) lock file; the takeover opens it to take the lock and checks with it held
            owner.lock_path().parent.mkdir(parents=True, exist_ok=True)
            owner.lock_path().touch()
            before = {p: p.read_bytes() for p in f.root.rglob("*") if p.is_file()}
            with real_ownership(), self.assertRaisesRegex(SystemExit, "run `o`: the stage transition `t-o` stopped at `applied`"):
                loop.run_loop(f.options(run_id="r", label_repair=True, label_deferred=True))
            self.assertFalse(owner.holds())
            self.assertEqual({p: p.read_bytes() for p in f.root.rglob("*") if p.is_file()}, before)   # no file of r, no owner record


class LegacyTestRunIsNoBase(unittest.TestCase):

    def test_a_legacy_test_run_resumes_but_is_no_base(self):
        w = World({"L-1": "shall stop.", "L-2": "shall yield."})
        w.plans = {"L-1": [node("L_1", "shall stop.", "L-1")], "L-2": [node("L_2", "shall yield.", "L-2")]}
        corpus = lambda f, rid, ids: subset(rid, f.root / "corpus" / "laws.jsonl", ids)
        with Fixture(w) as f:                                     # runs made as before stages existed
            f.drive(1, run_id="A", laws=corpus(f, "A", ["L-1"]))
            f.drive(1, run_id="T", laws=corpus(f, "T", ["L-2"]), mode="test", base_run="A", max_iterations=1)
            f.drive(1, run_id="T", laws=corpus(f, "T", ["L-2"]), mode="test", base_run="A", max_iterations=3)   # resumes as before
            self.assertFalse((paths.run_dir("T") / stages.STAGES_FILE).exists())
        with Fixture(w) as f:
            f.drive(1, run_id="A", laws=corpus(f, "A", ["L-1"]))
            f.drive(1, run_id="T", laws=corpus(f, "T", ["L-2"]), mode="test", base_run="A")
            for opts in (dict(run_id="U", laws=corpus(f, "U", ["L-1"]), label_repair=True, label_deferred=True, base_run="T"),
                         dict(run_id="V", laws=corpus(f, "V", ["L-2"]), mode="test", base_run="T")):
                with self.subTest(run=opts["run_id"]):
                    with self.assertRaisesRegex(SystemExit, "`T` is a test run: .*no training evidence"):
                        REAL_RUN_LOOP(f.options(**opts))          # a new run, as production creates it
                    self.assertFalse((paths.run_dir(opts["run_id"]) / "options.json").exists())


if __name__ == "__main__":
    unittest.main()
