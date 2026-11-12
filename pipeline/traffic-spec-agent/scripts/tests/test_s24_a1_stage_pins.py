"""A run with a stage record is pinned to its active stage; a run without one keeps its first export's pins.

- Without `stages.jsonl`, export, verify and the launch check behave as before: the manifest carries no
  stage fields, and a code change is refused against the first export's baseline.
- With one, the export carries the active stage's baseline, `stage_id` and `stages_sha256`; the run
  continues on the stage's code and refuses another, and refuses other semantic inputs or a policy
  that is not the stage's (`review` only "none").
- A manifest of another stage, or exported with another stage record, is refused; so is a manifest
  that names a stage on a run without a record; a run never handed over is held to its stage's code.
- A transition begun and not `done` refuses export, verify and the launch check; the transition's own
  export proceeds once it is `applied`.
- `verify(for_transition=True)` leaves out the comparisons with this tree but keeps the checkpoint's."""
import json
import unittest
from unittest import mock

from harness.store import stages
from harness.store.state import DEPENDENCY_POLICY, READABLE_RUN_VERSIONS, RUN_VERSION, run_version_refusal
from harness.tools import handoff
from scripts.tests import test_split_handoff

POLICY = {"label_repair": False, "dependency": DEPENDENCY_POLICY, "review": "none"}


def open_row(sid, code, semantic, prev=None, transition="t0", **over):
    return {"event": "open", "run_id": "r", "stage_id": sid, "stage_kind": "generation", "launch_kinds": ["generation"],
            "previous_stage_id": prev, "transition_id": transition, "input_checkpoint": None,
            "code_baseline": {"source_commit": f"commit-{sid}", "code": code}, "state_schema": RUN_VERSION,
            "semantic": semantic, "acceptance_policy": dict(POLICY), "scope": "all", "changed_files": [],
            "opened_at": "2026-11-11T00:00:00", **over}


def close_row(sid, transition):
    return {"event": "close", "stage_id": sid, "transition_id": transition, "output_checkpoint": None, "closed_at": "2026-11-11T00:00:01"}


def write_stages(rd, *rows):
    (rd / stages.STAGES_FILE).write_text("".join(json.dumps(r) + "\n" for r in rows))


def options_semantic(rd):
    return json.loads((rd / "options.json").read_text())["semantic"]


class Repo(unittest.TestCase):
    """The synthetic repository and run of `test_split_handoff.Pinning`, without its tests."""
    repo = test_split_handoff.Pinning.repo


def launch(rd):
    return mock.Mock(dir=rd, opts=mock.Mock(run_id="r"))


class RunVersion(unittest.TestCase):

    def test_the_readable_set_decides_and_the_text_is_unchanged(self):
        self.assertEqual(READABLE_RUN_VERSIONS, frozenset({3}))
        self.assertIsNone(run_version_refusal({"run_version": 3}))
        for was in (2, 4, None, True):
            self.assertIn("this harness is version 3", run_version_refusal({"run_version": was}))


class LegacyRun(Repo):
    """A run without a stage record: the pins of its first export, as before."""

    def test_no_stage_fields_and_the_first_baseline_pins(self):
        with self.repo() as (root, rd):
            m = handoff.export("r", source_baseline="c0ffee")
            self.assertNotIn("stage_id", m)
            self.assertNotIn("stages_sha256", m)
            self.assertEqual(handoff.verify("r")[0], [])
            handoff.check_on_launch(launch(rd))
            (root / "prompts" / "plan.md").write_text("plan, changed\n")
            refusals, _w = handoff.verify("r", artifacts=False)
            self.assertTrue(any("differs from its baseline" in r and "c0ffee" in r for r in refusals), refusals)
            self.assertFalse(any("stage" in r for r in refusals), refusals)


class StagePins(Repo):

    def stage_on_current_code(self, rd, **over):
        write_stages(rd, open_row("G0", handoff.code_digest(), options_semantic(rd), **over))

    def test_the_export_carries_the_active_stage(self):
        with self.repo() as (root, rd):
            self.stage_on_current_code(rd)
            m = handoff.export("r", source_baseline="ignored")
            self.assertEqual(m["stage_id"], "G0")
            self.assertEqual(m["stages_sha256"], stages.stages_sha256(rd))
            self.assertEqual(m["baseline"], stages.active_stage(rd)["code_baseline"])      # the stage records its commit
            self.assertEqual(m["acceptance_policy"], POLICY)
            self.assertEqual(handoff.verify("r"), ([], []))
            handoff.check_on_launch(launch(rd))

    def test_the_run_continues_on_the_stage_code_and_refuses_another(self):
        with self.repo() as (root, rd):
            first = handoff.export("r", source_baseline="c0ffee")             # a run made before stages, on code A
            code_a = handoff.code_digest()
            plan = root / "prompts" / "plan.md"
            plan.write_text("plan, the next stage\n")                         # code B
            self.assertTrue(handoff.verify("r", artifacts=False)[0])           # without a record: refused on code B
            write_stages(rd, open_row("G0", code_a, first["semantic"]), close_row("G0", "t1"),
                         open_row("G1", handoff.code_digest(), _current_semantic(rd), prev="G0", transition="t1"))
            m = handoff.export("r")
            self.assertEqual((m["stage_id"], m["baseline"]["source_commit"]), ("G1", "commit-G1"))
            self.assertEqual(handoff.verify("r"), ([], []))
            handoff.check_on_launch(launch(rd))
            plan.write_text("plan\n")                                         # back on code A, the closed stage's
            refusals, _w = handoff.verify("r", artifacts=False)
            self.assertTrue(any("active stage `G1`" in r and "prompts/plan.md" in r for r in refusals), refusals)
            with self.assertRaisesRegex(SystemExit, "baseline of its active stage `G1`"):
                handoff.export("r")
            with self.assertRaisesRegex(SystemExit, "cannot continue here"):
                handoff.check_on_launch(launch(rd))

    def test_other_semantic_inputs_or_policy_than_the_stage_are_refused(self):
        for field, value, words in (("semantic", {"corpus": "other"}, "active stage `G0` (corpus)"),
                                    ("acceptance_policy", dict(POLICY, review="semantic"), "`review` is 'semantic'"),
                                    ("acceptance_policy", {k: v for k, v in POLICY.items() if k != "review"}, "`review` is missing"),
                                    ("acceptance_policy", dict(POLICY, label_repair=True), "label_repair: True → False")):
            with self.subTest(field=field, value=value), self.repo() as (root, rd):
                self.stage_on_current_code(rd)
                handoff.export("r")
                row = stages.active_stage(rd)
                row[field] = {**row[field], **value} if field == "semantic" else value
                write_stages(rd, row)
                refusals, _w = handoff.verify("r", artifacts=False)
                self.assertTrue(any(words in r for r in refusals), refusals)
                if field == "acceptance_policy":
                    with self.assertRaisesRegex(SystemExit, "cannot be handed over"):
                        handoff.export("r")

    def test_an_unreadable_state_schema_is_refused(self):
        with self.repo() as (root, rd):
            self.stage_on_current_code(rd, state_schema=99)
            with self.assertRaisesRegex(SystemExit, "state schema 99"):
                handoff.export("r")

    def test_a_manifest_of_another_stage_or_record_is_refused(self):
        with self.repo() as (root, rd):
            self.stage_on_current_code(rd)
            handoff.export("r")
            g0 = stages.active_stage(rd)
            write_stages(rd, g0, close_row("G0", "t1"), open_row("G1", g0["code_baseline"]["code"], g0["semantic"], prev="G0",
                                                                    transition="t1"))
            refusals, _w = handoff.verify("r", artifacts=False)
            self.assertTrue(any("checkpoint of stage 'G0', not of the active stage `G1`" in r for r in refusals), refusals)
            self.assertTrue(any("another stage record" in r for r in refusals), refusals)
            with self.assertRaisesRegex(SystemExit, "cannot continue here"):
                handoff.check_on_launch(launch(rd))
            write_stages(rd, dict(g0, opened_at="another time"))              # the same active stage, another record
            refusals, _w = handoff.verify("r", artifacts=False)
            self.assertFalse(any("not of the active stage" in r for r in refusals), refusals)
            self.assertTrue(any("another stage record" in r for r in refusals), refusals)
            (rd / stages.STAGES_FILE).unlink()                                 # the record gone, the manifest still names a stage
            refusals, _w = handoff.verify("r", artifacts=False)
            self.assertTrue(any("checkpoint of stage `G0`, and the run has no stage record" in r for r in refusals), refusals)

    def test_a_stage_record_without_a_manifest_is_held_to_the_stage_code(self):
        with self.repo() as (root, rd):
            self.stage_on_current_code(rd)
            handoff.check_on_launch(launch(rd))
            (root / "prompts" / "plan.md").write_text("plan, changed\n")
            with self.assertRaisesRegex(SystemExit, "baseline of its active stage `G0`"):
                handoff.check_on_launch(launch(rd))


class UnfinishedTransition(Repo):

    def transition(self, rd, status, tid="t1"):
        (rd / stages.TRANSITION_FILE).write_text(json.dumps({"transition_id": tid, "status": status}))

    def test_every_entry_point_is_refused_until_done(self):
        for status in ("prepared", "committed", "applied", "exported"):
            with self.subTest(status=status), self.repo() as (root, rd):
                write_stages(rd, open_row("G0", handoff.code_digest(), options_semantic(rd)))
                handoff.export("r")
                self.transition(rd, status)
                with self.assertRaisesRegex(SystemExit, f"stopped at `{status}`.*nothing was written"):
                    handoff.export("r")
                refusals, _w = handoff.verify("r")
                self.assertTrue(any(f"stopped at `{status}`" in r for r in refusals), refusals)
                self.assertTrue(any(f"stopped at `{status}`" in r for r in handoff.verify("r", for_transition=True)[0]))
                with self.assertRaisesRegex(SystemExit, f"stopped at `{status}`"):
                    handoff.check_on_launch(launch(rd))
                self.transition(rd, "done")
                self.assertEqual(handoff.verify("r", artifacts=False)[0], [])

    def test_a_legacy_run_mid_adoption_is_refused_too(self):
        with self.repo() as (root, rd):
            handoff.export("r")
            self.transition(rd, "prepared")
            with self.assertRaisesRegex(SystemExit, "stopped at `prepared`"):
                handoff.check_on_launch(launch(rd))

    def test_the_transition_exports_the_stage_it_opened_once_applied(self):
        with self.repo() as (root, rd):
            write_stages(rd, open_row("G0", handoff.code_digest(), options_semantic(rd)))
            handoff.export("r")
            self.transition(rd, "committed")
            with self.assertRaisesRegex(SystemExit, "stopped at `committed`"):
                handoff.export("r", transition="t1")
            self.transition(rd, "applied")
            with self.assertRaisesRegex(SystemExit, "stopped at `applied`"):
                handoff.export("r", transition="t2")
            m = handoff.export("r", transition="t1")
            self.assertEqual(m["stage_id"], "G0")
            self.transition(rd, "done")
            with self.assertRaisesRegex(SystemExit, "no stage transition `t1` is in progress"):
                handoff.export("r", transition="t1")


class ForTransition(Repo):
    """The closing stage's checkpoint, checked from a checkout of the next stage's code."""

    def test_this_tree_is_not_compared_but_the_checkpoint_is(self):
        with self.repo() as (root, rd):
            write_stages(rd, open_row("G0", handoff.code_digest(), options_semantic(rd)))
            handoff.export("r")
            (root / "prompts" / "plan.md").write_text("plan, the next stage\n")     # the next stage's code and prompts
            self.assertTrue(any("active stage `G0`" in r for r in handoff.verify("r")[0]))
            self.assertEqual(handoff.verify("r", for_transition=True), ([], []))
            (rd / "state.json").write_text((rd / "state.json").read_text() + " ")    # a handed file not as exported
            refusals, _w = handoff.verify("r", for_transition=True)
            self.assertTrue(any("not as exported" in r and "state.json" in r for r in refusals), refusals)
            (rd / ".run.lock").write_text("")
            self.assertTrue(any("lock or owner files" in r for r in handoff.verify("r", for_transition=True)[0]))
            (rd / ".run.lock").unlink()
            g0 = stages.active_stage(rd)
            write_stages(rd, g0, close_row("G0", "t1"), open_row("G1", g0["code_baseline"]["code"], g0["semantic"], prev="G0",
                                                                    transition="t1"))
            refusals, _w = handoff.verify("r", artifacts=False, for_transition=True)
            self.assertTrue(any("not of the active stage `G1`" in r for r in refusals), refusals)
            self.assertTrue(any("another stage record" in r for r in refusals), refusals)


def _current_semantic(rd):
    """The semantic inputs of this tree for the run's saved options, as a stage opened on it records them."""
    from harness import loop
    from harness.store.state import Options
    from harness.store import paths
    d = json.loads((rd / "options.json").read_text())
    kw = {k: v for k, v in d.items() if k in Options.__dataclass_fields__}
    for k in ("laws", "ontology", "definition_precedence", "reading"):
        kw[k] = paths.local(d.get("base_reading") if k == "reading" else kw[k])
    return loop.semantic_inputs(Options(**kw))


if __name__ == "__main__":
    unittest.main()
