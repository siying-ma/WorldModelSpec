"""A stage transition on the real handoff export and snapshot, in the synthetic repository of
`test_split_handoff.Pinning` with a staged run at its G0 checkpoint.

- The transition exports as the owner it is: `handoff.export` takes the library only when this
  process does not own it already, and a real `stage enter` holds the library's lock from its start
  to its end (the same lock, never given up on the way); no harness module reaches into the owner
  module's private descriptor.
- A transition whose new code changes `library/Explain.lean` passes the checkpoint check: with no
  comparison set fixed the file is classed `scoring`, the stage is entered and exported, and exported
  again once confirmed (the run's freeze still holds the closing stage's Explain); with the run's
  `comparison_set.json` it is refused as a forbidden change by its classification, not as freeze
  drift. A changed run artifact in the freeze (a rule file) is still refused by the checkpoint."""
import fcntl
import json
import os
import unittest
from contextlib import contextmanager
from pathlib import Path
from unittest import mock

from harness.phases import label_check
from harness.store import owner, paths, snapshot, stages
from harness.tools import handoff, stage
from scripts.tests import s24_helpers
from scripts.tests import test_split_handoff as split_handoff

REAL_ACQUIRE = owner.acquire_for_command
REAL_ACQUIRE_TRANSITION = owner.acquire_for_transition
HARNESS = Path(__file__).resolve().parents[2] / "harness"
RULE = "TrafficSpec/Rules/R1.lean"


@contextmanager
def staged_checkpoint(comparison: bool = False):
    """The run `r` in its first stage G0 (a whole open row on this tree), with one rule in its library
    and, when `comparison`, a fixed comparison set; frozen and exported as G0."""
    with split_handoff.Pinning("test_artifact_only_checkpoints_pass_and_code_changes_refuse").repo() as (root, rd):
        (paths.LIBRARY / RULE).parent.mkdir(parents=True, exist_ok=True)
        (paths.LIBRARY / RULE).write_text("-- rule v0\n")
        if comparison:
            (rd / "comparison_set.json").write_text(json.dumps({"data_version": "dv", "scoring": label_check.scoring_version(),
                                                                "laws": {}, "cases": {}}))
        from harness.lean import index_sync
        index_sync.write_index()                         # the registries as every commit leaves them, before the freeze
        label_check.freeze(rd)
        s24_helpers.write_stages(rd, s24_helpers.open_row("G0", transition="init-r"))
        m = handoff.export("r", source_baseline="c0ffee")
        assert m["stage_id"] == "G0"
        # the synthetic repository is no git checkout: the baseline commit's own check
        # (test_s24_a2_stage.BaselineCommit) is stood in for, and the new stage records a named commit
        with mock.patch.object(stage, "baseline_refusal", lambda root, commit, files: None), \
                mock.patch.object(stage, "_head", lambda root: "next-stage-commit"), \
                mock.patch.object(owner, "acquire_for_transition",                 # the takeover's check, without the lock
                                  lambda run_id, transition: owner.transitions_refusal((run_id, transition))):
            yield root, rd


@contextmanager
def real_owner():
    """The real `owner.acquire_for_command` in force; afterwards this process gives the library up."""
    env = {k: os.environ.get(k) for k in (owner.ENV, owner.LIB_ENV)}
    try:
        with mock.patch.object(owner, "acquire_for_command", REAL_ACQUIRE), \
                mock.patch.object(owner, "acquire_for_transition", REAL_ACQUIRE_TRANSITION):
            yield
    finally:
        if owner._FD is not None:
            owner._FD.close()
        owner._FD, owner._RECORD = None, {}
        for k, v in env.items():
            os.environ.pop(k, None) if v is None else os.environ.__setitem__(k, v)


def lock_contended() -> bool:
    """Whether the library's lock is held (taken from a separate open file description)."""
    with open(owner.lock_path(), "a+") as fd:
        try:
            fcntl.flock(fd.fileno(), fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            return True
        fcntl.flock(fd.fileno(), fcntl.LOCK_UN)
        return False


def change(root: Path, rel: str, text: str = "# changed by the next stage\n") -> None:
    f = root / rel
    f.write_text(f.read_text() + text)


class OwnerThroughout(unittest.TestCase):

    def test_export_takes_the_library_only_when_this_process_does_not_own_it(self):
        with staged_checkpoint():
            with mock.patch.object(owner, "holds", return_value=True), \
                    mock.patch.object(owner, "acquire_for_command", side_effect=AssertionError("taken a second time")):
                m = handoff.export("r")
            self.assertEqual(m["stage_id"], "G0")
            taken = []
            with mock.patch.object(owner, "holds", return_value=False), \
                    mock.patch.object(owner, "acquire_for_command", side_effect=taken.append):
                handoff.export("r")
            self.assertEqual(taken, ["handoff"])

    def test_a_real_stage_enter_holds_the_lock_from_start_to_end(self):
        with staged_checkpoint() as (root, rd), real_owner():
            change(root, "scripts/diagnostics/doctor.py")
            seen, fds = [], []

            def watch(name, fn):
                def run(*a, **k):
                    seen.append((name, "in", owner.holds(), lock_contended()))
                    fds.append(owner._FD)
                    out = fn(*a, **k)
                    seen.append((name, "out", owner.holds(), lock_contended()))
                    fds.append(owner._FD)
                    return out
                return run
            with mock.patch.object(handoff, "export", watch("export", handoff.export)), \
                    mock.patch.object(handoff, "verify", watch("verify", handoff.verify)), \
                    mock.patch.object(snapshot, "write", watch("snapshot", snapshot.write)), \
                    mock.patch.object(stage, "_commit", watch("commit", stage._commit)):
                rec = stage.enter("r", "generation", "G0", "t1")
            self.assertEqual((rec["status"], rec["to"]), ("exported", "G1"))
            self.assertEqual({n for n, *_ in seen}, {"export", "verify", "snapshot", "commit"})
            self.assertTrue(all(held and locked for _n, _w, held, locked in seen), seen)
            self.assertTrue(owner.holds() and lock_contended())
            self.assertTrue(fds and all(fd is fds[0] and not fd.closed for fd in fds))      # one lock, never given up
            self.assertFalse(fds[0].closed)
            m = json.loads((rd / "handoff" / "manifest.json").read_text())
            self.assertEqual((m["stage_id"], m["stages_sha256"]), ("G1", stages.stages_sha256(rd)))

    def test_no_harness_module_reaches_into_the_owner_descriptor(self):
        users = sorted(str(p.relative_to(HARNESS)) for p in HARNESS.rglob("*.py")
                       if p.name != "owner.py" and "owner._FD" in p.read_text(encoding="utf-8"))
        self.assertEqual(users, [])


class LibraryCode(unittest.TestCase):

    def test_explain_is_scoring_without_a_comparison_set(self):
        with staged_checkpoint() as (root, rd):
            change(root, "library/Explain.lean", "-- explain, corrected\n")
            rec = stage.enter("r", "generation", "G0", "t1")
            self.assertEqual(rec["status"], "exported")
            g1 = stages.active_stage(rd)
            self.assertEqual(g1["changed_files"], [{"path": "library/Explain.lean", "class": "scoring"}])
            self.assertNotEqual(g1["effects"]["scoring"], stages.read_stages(rd)[0]["effects"]["scoring"])
            m = json.loads((rd / "handoff" / "manifest.json").read_text())
            self.assertEqual((m["stage_id"], m["baseline"]["code"]), ("G1", handoff.code_digest()))
            stage._set_status(rd, stages.transition_state(rd), "done", commit="c1")      # as `confirm` leaves it
            self.assertEqual(handoff.export("r")["stage_id"], "G1")                     # the confirmation's export again
            self.assertEqual(handoff.verify("r")[0], [])

    def test_explain_is_forbidden_by_its_class_with_a_comparison_set(self):
        with staged_checkpoint(comparison=True) as (root, rd):
            change(root, "library/Explain.lean", "-- explain, corrected\n")
            before = sorted(p.relative_to(root).as_posix() for p in root.rglob("*") if p.is_file())
            with self.assertRaises(SystemExit) as e:
                stage.enter("r", "generation", "G0", "t1")
            why = str(e.exception)
            self.assertIn("no transition may change: library/Explain.lean", why)
            self.assertNotIn("freeze", why)
            self.assertIn("nothing was written", why)
            self.assertEqual(sorted(p.relative_to(root).as_posix() for p in root.rglob("*") if p.is_file()), before)
            self.assertIsNone(stages.transition_state(rd))
            self.assertEqual([r["stage_id"] for r in stages.read_stages(rd)], ["G0"])

    def test_a_changed_rule_is_still_refused_by_the_checkpoint(self):
        for with_code in (False, True):
            with self.subTest(explain_changed=with_code), staged_checkpoint() as (root, rd):
                if with_code:
                    change(root, "library/Explain.lean", "-- explain, corrected\n")
                (paths.LIBRARY / RULE).write_text("-- rule edited after the export\n")
                with self.assertRaises(SystemExit) as e:
                    stage.enter("r", "generation", "G0", "t1")
                self.assertRegex(str(e.exception), r"freeze: [^;]*" + RULE.replace(".", r"\."))     # refused as before 9b8eb1b too
                self.assertIsNone(stages.transition_state(rd))
                self.assertFalse((rd / stages.STAGES_DIR).exists())


if __name__ == "__main__":
    unittest.main()
