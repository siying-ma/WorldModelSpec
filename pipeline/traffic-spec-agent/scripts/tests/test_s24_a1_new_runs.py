"""A new run is a staged run: the real loop writes its first stage `G0` and the stage policy marker
before anything else of it, and its first launch is the generation launch (`--label_deferred`).

- The first launch writes G0 (a generation stage on this checkout's code, the run's semantic inputs and
  policy, no review, every law, the effect digests) and runs; a stop mid-iteration resumes in G0.
- Export carries `stage_id`; `handoff verify` passes and the run continues at another root.
- An unsplit or `--label_stage` first launch is refused with nothing written.
- A marked run whose stage record is deleted is refused, never resumed as a run made before stages.
- A run made before stages (`test_recovery.legacy_run`) resumes as before, unsplit and `--label_stage`
  launches included."""
import json
import unittest
from contextlib import ExitStack
from unittest import mock

from harness import loop
from harness.phases import integrate, label_check
from harness.store import paths, stages
from harness.store.state import DEPENDENCY_POLICY, RUN_VERSION
from harness.tools import handoff
from scripts.tests.test_recovery import Fixture, World, node
from scripts.tests.test_split_handoff import A, B, C, SPLIT, TOOLCHAIN, clone, label_stage_stand_ins, options_at, split_world


def rows(rd):
    return [json.loads(x) for x in (rd / stages.STAGES_FILE).read_text().splitlines()]


def tree(rd):
    return sorted((p.relative_to(rd).as_posix(), p.read_bytes()) for p in rd.rglob("*") if p.is_file())


class NewRun(unittest.TestCase):

    def test_the_first_launch_writes_g0_and_generates(self):
        w = split_world()
        with Fixture(w, staged=True, **SPLIT) as f:
            self.assertEqual(f.drive(1, label_deferred=True, source_commit="c0ffee"), ["awaiting_labels"])
            rd = paths.RESULTS / "r"
            (g0,) = rows(rd)
            opts = json.loads((rd / "options.json").read_text())
            self.assertEqual(opts["stage_policy"], loop.STAGE_POLICY)
            self.assertEqual((g0["event"], g0["stage_id"], g0["stage_kind"], g0["launch_kinds"], g0["previous_stage_id"],
                              g0["transition_id"], g0["state_schema"], g0["scope"], g0["changed_files"]),
                             ("open", "G0", "generation", ["generation"], None, "init-r", RUN_VERSION, "all", []))
            self.assertEqual(g0["code_baseline"], {"source_commit": "c0ffee", "code": handoff.code_digest()})
            self.assertEqual(g0["semantic"], opts["semantic"])
            self.assertEqual(g0["acceptance_policy"], {"label_repair": True, "dependency": DEPENDENCY_POLICY, "review": "none"})
            self.assertEqual(g0["effects"], {"gate": integrate.gate_digest(), "scoring": label_check.scoring_version(),
                                             "generated_prompts": opts["semantic"]["generated_prompts"]})
            self.assertEqual(stages.active_stage(rd), g0)
            self.assertTrue(w.calls)

    def test_a_stop_mid_iteration_resumes_in_g0(self):
        w = split_world()
        w.crash_at = 40
        with Fixture(w, staged=True, **SPLIT) as f:
            statuses = f.drive(4, label_deferred=True)
            self.assertIn("crash", statuses)
            self.assertEqual(statuses[-1], "awaiting_labels")
            rd = paths.RESULTS / "r"
            self.assertEqual([r["stage_id"] for r in rows(rd)], ["G0"])
            self.assertEqual(json.loads((rd / "options.json").read_text())["stage_policy"], loop.STAGE_POLICY)

    def test_a_staged_run_is_handed_over_and_continues_at_another_root(self):
        w = split_world()
        w.gate[("L_22", 1)] = "CHECK_FAIL"                    # work left for the next launch
        with Fixture(w, staged=True, **SPLIT) as f, ExitStack() as stack, \
                mock.patch.object(handoff, "toolchain", lambda: TOOLCHAIN), \
                mock.patch("harness.store.owner.acquire_for_command", lambda name: None):
            self.assertEqual(f.drive(1, label_deferred=True, max_iterations=1), ["incomplete"])
            m = handoff.export("r", source_baseline="abc")
            rd = paths.RESULTS / "r"
            self.assertEqual((m["stage_id"], m["stages_sha256"], m["baseline"]["source_commit"]),
                             ("G0", stages.stages_sha256(rd), "abc"))
            self.assertEqual(handoff.export("r", source_baseline="later")["baseline"]["source_commit"], "abc")
            new = clone(f, stack)
            self.assertEqual(handoff.verify("r"), ([], []))
            res = loop.run_loop(options_at(f, new, label_deferred=True, max_iterations=2))
            self.assertEqual(res["status"], "awaiting_labels")
            self.assertTrue((paths.RESULTS / "r" / "handoff" / "imported.json").exists())
            self.assertEqual([r["stage_id"] for r in rows(paths.RESULTS / "r")], ["G0"])

    def test_an_unsplit_or_labels_first_launch_is_refused_with_nothing_written(self):
        for over, words in (({"label_dataset": "ds"}, stages.UNSPLIT_REFUSAL), ({"label_repair": False}, stages.UNSPLIT_REFUSAL),
                            ({"label_stage": True, "label_dataset": "ds"}, "this is a `labels` launch")):
            with self.subTest(over=over):
                w = split_world()
                with Fixture(w, staged=True, **SPLIT) as f:
                    with self.assertRaises(SystemExit) as e:
                        loop.run_loop(f.options(**over))
                    self.assertIn(words, str(e.exception))
                    self.assertIn("nothing of this run was rewritten", str(e.exception))
                    self.assertFalse((paths.RESULTS / "r").exists())
                    self.assertEqual(dict(w.calls), {})

    def test_a_marked_run_without_its_stage_record_is_refused(self):
        w = split_world()
        with Fixture(w, staged=True, **SPLIT) as f:
            f.drive(1, label_deferred=True)
            rd = paths.RESULTS / "r"
            (rd / stages.STAGES_FILE).unlink()
            before = (tree(rd), dict(w.calls))
            for launch in (dict(label_deferred=True), dict(label_stage=True, label_dataset="ds"), {}):
                with self.subTest(launch=launch):
                    with self.assertRaises(SystemExit) as e:
                        loop.run_loop(f.options(max_iterations=3, **launch))
                    self.assertIn("marks it a staged run (staged_v1) and its stage record stages.jsonl is missing", str(e.exception))
                    self.assertEqual((tree(rd), dict(w.calls)), before)


class LegacyRun(unittest.TestCase):
    """A run made before stages: no marker, no stage record, every launch as before."""

    def test_a_split_run_resumes_with_its_labels_launch(self):
        w = split_world()
        with Fixture(w, **SPLIT) as f:
            self.assertEqual(f.drive(1, label_deferred=True), ["awaiting_labels"])
            rd = paths.RESULTS / "r"
            self.assertFalse((rd / stages.STAGES_FILE).exists())
            self.assertNotIn("stage_policy", json.loads((rd / "options.json").read_text()))
            with label_stage_stand_ins({A, B, C}):
                self.assertEqual(f.drive(1, label_stage=True, label_dataset="ds", max_iterations=3), ["complete"])
            self.assertFalse((rd / stages.STAGES_FILE).exists())
            self.assertNotIn("stage_policy", json.loads((rd / "options.json").read_text()))

    def test_an_unsplit_run_starts_and_resumes(self):
        w = World({"L-1": "shall stop."})
        w.plans = {"L-1": [node("L_1", "shall stop.", "L-1")]}
        with Fixture(w) as f:
            self.assertEqual(f.drive(1, max_iterations=1), ["complete"])
            self.assertEqual(f.drive(1, max_iterations=2), ["complete"])
            self.assertFalse((paths.RESULTS / "r" / stages.STAGES_FILE).exists())


if __name__ == "__main__":
    unittest.main()
