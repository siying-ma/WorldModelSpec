"""The loop's launch on a run with a stage record: the launch kind must be one the active stage allows,
the semantic inputs and the policy the stage's, and no transition may be in progress; each refusal
comes before anything of the run is written. The saved options keep the semantic inputs the run first
recorded. The real loop on the scripted world of `test_recovery`."""
import json
import unittest
from contextlib import contextmanager
from unittest import mock

from harness import loop
from harness.store import paths, stages
from harness.store.state import DEPENDENCY_POLICY, RUN_VERSION
from harness.tools import handoff
from scripts.tests.test_recovery import Fixture
from scripts.tests.test_split_handoff import SPLIT, TOOLCHAIN, label_stage_stand_ins, split_world


def stage_row(rd, **over):
    return {"event": "open", "run_id": "r", "stage_id": "G0", "stage_kind": "generation", "launch_kinds": ["generation"],
            "previous_stage_id": None, "transition_id": "t0", "input_checkpoint": None,
            "code_baseline": {"source_commit": "commit-G0", "code": handoff.code_digest()}, "state_schema": RUN_VERSION,
            "semantic": json.loads((rd / "options.json").read_text())["semantic"],
            "acceptance_policy": {"label_repair": True, "dependency": DEPENDENCY_POLICY, "review": "none"},
            "scope": "all", "changed_files": [], "opened_at": "2026-11-11T00:00:00", **over}


class StageLaunch(unittest.TestCase):

    @contextmanager
    def staged(self, **over):
        """A split run after its first generation launch, registered as the stage G0 and exported."""
        w = split_world()
        with Fixture(w, staged=True, **SPLIT) as f, mock.patch.object(handoff, "toolchain", lambda: TOOLCHAIN), \
                mock.patch("harness.store.owner.acquire_for_command", lambda name: None):
            self.assertEqual(f.drive(1, label_deferred=True), ["awaiting_labels"])
            rd = paths.RESULTS / "r"
            (rd / stages.STAGES_FILE).write_text(json.dumps(stage_row(rd, **over)) + "\n")
            handoff.export("r")
            yield f, w, rd

    def frozen(self, f, w, rd) -> tuple:
        return (sorted((p.relative_to(rd).as_posix(), p.read_bytes()) for p in rd.rglob("*") if p.is_file()), dict(w.calls))

    def refused(self, f, w, rd, words: str, **opts):
        before = self.frozen(f, w, rd)
        with self.assertRaises(SystemExit) as e:
            loop.run_loop(f.options(max_iterations=3, **opts))
        self.assertIn(words, str(e.exception))
        self.assertIn("nothing of this run was rewritten", str(e.exception))
        self.assertEqual(self.frozen(f, w, rd), before)

    def test_a_launch_kind_the_stage_does_not_allow_is_refused(self):
        with self.staged() as (f, w, rd):
            self.refused(f, w, rd, "allows the launch kinds ['generation'], and this is a `labels` launch",
                         label_stage=True, label_dataset="ds")

    def test_an_unsplit_launch_is_refused_in_a_staged_run(self):
        with self.staged() as (f, w, rd):
            self.refused(f, w, rd, stages.UNSPLIT_REFUSAL, label_dataset="ds")
            self.refused(f, w, rd, stages.UNSPLIT_REFUSAL, label_repair=False)

    def test_a_labels_stage_admits_a_labels_launch_and_refuses_generation(self):
        with self.staged(stage_kind="labels", launch_kinds=["labels"]) as (f, w, rd):
            self.refused(f, w, rd, "allows the launch kinds ['labels'], and this is a `generation` launch", label_deferred=True)
            saved = json.loads((rd / "options.json").read_text())["semantic"]
            with label_stage_stand_ins({"L-20", "L-21", "L-22"}):
                self.assertEqual(f.drive(1, label_stage=True, label_dataset="ds", max_iterations=3), ["complete"])
            self.assertEqual(json.loads((rd / "options.json").read_text())["semantic"], saved)

    def test_a_launch_on_the_stage_continues(self):
        with self.staged() as (f, w, rd):
            self.assertEqual(f.drive(1, label_deferred=True, max_iterations=3), ["awaiting_labels"])

    def test_inputs_or_policy_other_than_the_stage_are_refused(self):
        for over, words in (({"semantic": {"corpus": "other"}}, "other inputs than its active stage `G0`"),
                            ({"acceptance_policy": {"label_repair": True, "dependency": DEPENDENCY_POLICY, "review": "semantic"}},
                             "`review` is 'semantic'"),
                            ({"acceptance_policy": {"label_repair": False, "dependency": DEPENDENCY_POLICY, "review": "none"}},
                             "in the active stage `G0`, the run's acceptance policy is fixed")):
            with self.subTest(over=over), self.staged() as (f, w, rd):
                row = stage_row(rd)
                row.update({k: ({**row[k], **v} if k == "semantic" else v) for k, v in over.items()})
                (rd / stages.STAGES_FILE).write_text(json.dumps(row) + "\n")
                self.refused(f, w, rd, words, label_deferred=True)

    def test_an_unfinished_transition_refuses_the_launch(self):
        with self.staged() as (f, w, rd):
            (rd / stages.TRANSITION_FILE).write_text(json.dumps({"transition_id": "t1", "status": "applied"}))
            self.refused(f, w, rd, "stopped at `applied`", label_deferred=True)

    def test_a_stage_record_not_read_whole_refuses_the_launch(self):
        with self.staged() as (f, w, rd):
            row = json.dumps(stage_row(rd))
            (rd / stages.STAGES_FILE).write_text(row + "\n" + row + "\n")
            self.refused(f, w, rd, "stage record cannot be read whole", label_deferred=True)


if __name__ == "__main__":
    unittest.main()
