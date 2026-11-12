"""A law's label result is evidence only for the inputs it was computed on, and a stage limited to a
scope checks, accepts and reports only the laws in it.

- `loop.label_key` changes when a node a law's plan composes changes its dependency context, when a
  recording of the law changes its label digest in the run's `comparison_set.json`, and when the
  set's scoring changes; a law that composes nothing that changed keeps its key.
- In a run with a stage record, an accepted law whose recorded key differs from the current one (or
  that has none) is label work, loses its acceptance through the revocation path (`waiting`, the
  stale key named) and is checked again; a law awaiting its label repair on a stale key is checked
  again too. A run without a stage record keeps its label results as they are, and its label states
  hold no key.
- A stage of scope {A, B} in a run of {A, B, C} never checks or accepts C; `summary.json`, `TO_USER.md`
  and `generation_report` say `2/3`, list C with its state, and a `complete` is the scope's only.

The loop, ledgers and scheduling are the real ones on the scripted world of `test_recovery`; the label
check's monitor run is stood in for (`label_route`), recording what it was asked to check."""
import json
import unittest
from contextlib import contextmanager
from types import SimpleNamespace
from unittest import mock

from harness import loop
from harness.model import nodeid
from harness.phases import feedback, label_check
from harness.phases import label_repair as lr
from harness.store import paths, stages
from harness.store.ledger import Ledger
from harness.store.state import Run
from scripts.tests import s24_helpers
from scripts.tests.test_recovery import Fixture
from scripts.tests.test_split_handoff import A, B, C, SPLIT, split_world

RECORDINGS = {A: ["r-a1", "r-a2"], B: ["r-b1"], C: ["r-c1"]}


def comparison_set() -> dict:
    cases = {r: {"law": law, "verdict": "violated", "judgment_call": False, "label": f"label-{r}", "trace": f"trace-{r}",
                 "manifest": f"manifest-{r}"} for law, rs in RECORDINGS.items() for r in rs}
    return {"data_version": "dv", "dataset": "/elsewhere", "label_contract": "lc", "scoring": "sc", "index": "ix", "split": None,
            "library_split": None, "limits": {"deadline_s": 60, "memory_gb": 2},
            "laws": {law: {"recordings": rs, "eligible": rs, "judgment_calls": []} for law, rs in RECORDINGS.items()}, "cases": cases}


def open_row(scope="all", stage_id="L0") -> dict:
    """A labels stage of the run on this tree, whole (`s24_helpers.open_row`), limited to `scope`."""
    return s24_helpers.open_row(stage_id, scope=scope, transition="t-0", source_commit="0" * 40)


def write_stage(scope="all") -> None:
    (paths.RESULTS / "r" / stages.STAGES_FILE).write_text(json.dumps(open_row(scope)) + "\n")


def write_set(fixed: dict) -> None:
    (paths.RESULTS / "r" / "comparison_set.json").write_text(json.dumps(fixed, indent=1))


def generated(f) -> None:
    """The generation stage generates every law of the split world; nothing is accepted."""
    assert f.drive(1, label_deferred=True, max_iterations=3) == ["awaiting_labels"]


def loaded(f) -> tuple[Run, Ledger]:
    run = Run(f.options(label_stage=True, label_dataset="ds"))
    run.restore_state(); run.load_accepted()
    led = Ledger(run.ledger_file, [], 2)
    run.law_entries = led.entries
    return run, led


def keyed_route(accept: set[str]):
    """The label route's stand-in: each ready law in `accept` is accepted with the label state a real
    check records (its key included, from the real `label_state`)."""
    seen = []

    def route(run, ledger, training, to_user):
        ready = loop.label_ready(run, ledger)
        seen.append(sorted(ready))
        chk = SimpleNamespace(outcome="aligned", coverage={"matched": 1, "eligible": 1}, versions={})
        for law, nodes in ready.items():
            if law in accept:
                ledger.accept(law, nodes)
                run.label_states[law] = loop.label_state(run, law, chk, nodes, run.iter / "label", "c-1")
        return {}
    return route, seen


@contextmanager
def label_stand_ins(accept: set[str]):
    route, seen = keyed_route(accept)
    repairs = []
    with mock.patch.object(loop, "label_route", route), \
            mock.patch.object(label_check, "training_context", lambda *a, **k: object()), \
            mock.patch.object(lr, "run_repairs", lambda run, ledger, *a, **k: repairs.append(lr.awaiting(run, ledger)) or {}):
        yield seen, repairs


class LabelKey(unittest.TestCase):
    """The key covers the composed nodes' contexts, the law's recordings in the fixed set, and the set's versions."""

    def test_key_inputs(self):
        with Fixture(split_world(), **SPLIT) as f:
            generated(f)
            write_set(comparison_set())
            run, led = loaded(f)
            key = lambda law: loop.label_key(run, law, list(led.entries[law].nodes))
            before = {law: key(law) for law in (A, B, C)}
            self.assertEqual(len(set(before.values())), 3)
            self.assertEqual(before, {law: key(law) for law in (A, B, C)})              # read again: the same

            # B composes A's first node: that node's dependency context changes, so does B's key; C's does not
            (paths.LIBRARY / nodeid.rule_path("L_20_o1")).write_text("theorem changed : True := trivial\n")
            self.assertNotEqual(key(B), before[B])
            self.assertNotEqual(key(A), before[A])
            self.assertEqual(key(C), before[C])

            # a recording's label digest in the fixed set: only the key of its law changes
            now = {law: key(law) for law in (A, B, C)}
            fixed = comparison_set()
            fixed["cases"]["r-b1"]["label"] = "label-r-b1-relabelled"
            write_set(fixed)
            self.assertNotEqual(key(B), now[B])
            self.assertEqual((key(A), key(C)), (now[A], now[C]))

            # the set's scoring: every law's key changes
            now = {law: key(law) for law in (A, B, C)}
            fixed["scoring"] = "sc-2"
            write_set(fixed)
            self.assertTrue(all(key(law) != now[law] for law in (A, B, C)))


class StaleKey(unittest.TestCase):
    """In a run with a stage record, a label result on other inputs is not evidence."""

    def accepted_world(self, f, stage: bool):
        generated(f)
        write_set(comparison_set())
        if stage:
            write_stage()
        run, led = loaded(f)
        route, _seen = keyed_route({A, B, C})
        route(run, led, None, [])
        self.assertEqual({law: e.state for law, e in led.entries.items()}, {A: "accepted", B: "accepted", C: "accepted"})
        return run, led

    def test_stale_or_missing_key_revokes_and_rechecks(self):
        with Fixture(split_world(), **SPLIT) as f:
            run, led = self.accepted_world(f, stage=True)
            self.assertTrue(all(run.label_states[law].get("key") for law in (A, B, C)))
            self.assertEqual(loop.label_work(run, run.opts, led), [])                    # every key current: no work
            old_b = run.label_states[B]["key"]
            fixed = comparison_set()
            fixed["cases"]["r-b1"]["label"] = "label-r-b1-relabelled"                    # B's evidence is on other labels
            write_set(fixed)
            run.label_states[C].pop("key")                                               # a result recorded with no key
            self.assertEqual(loop.label_work(run, run.opts, led), [B, C])

            route, seen = keyed_route({A, B, C})
            to_user = []
            with mock.patch.object(loop, "label_route", route):
                loop.accept_ready(run, run.opts, led, None, to_user)
            self.assertEqual(seen, [[B, C]])                                             # each checked again, A not
            self.assertTrue(any(f"`{B}`: acceptance revoked" in x and old_b in x for x in to_user), to_user)
            self.assertEqual({law: e.state for law, e in led.entries.items()}, {A: "accepted", B: "accepted", C: "accepted"})
            self.assertEqual(loop.label_work(run, run.opts, led), [])

    def test_revoked_state_names_the_stale_key(self):
        with Fixture(split_world(), **SPLIT) as f:
            run, led = self.accepted_world(f, stage=True)
            was = run.label_states[B]["key"]
            fixed = comparison_set()
            fixed["cases"]["r-b1"]["trace"] = "trace-other"
            write_set(fixed)
            revoked = loop.revoke_stale_labels(run, led, [])
            self.assertEqual(revoked, [B])
            st = run.label_states[B]
            self.assertEqual((led.entries[B].state, st["state"], st["revoked_reason"]["cause"]), ("planned", "waiting", "stale_label_key"))
            self.assertEqual(st["revoked_reason"]["label_key"], {"recorded": was, "current": loop.label_key(run, B, list(led.entries[B].nodes))})
            self.assertIn(B, loop.label_ready(run, led))                                 # the next label check takes it up

    def test_awaiting_repair_on_a_stale_key_is_checked_again(self):
        with Fixture(split_world(), **SPLIT) as f:
            generated(f)
            write_set(comparison_set())
            write_stage()
            run, led = loaded(f)
            nodes = list(led.entries[C].nodes)
            run.label_states[C] = {"state": "awaiting_label_repair", "outcome": "mismatch", "nodes": nodes, "repairs": 0,
                                   "key": loop.label_key(run, C, nodes)}
            self.assertNotIn(C, loop.label_ready(run, led))                              # its repair checks it
            run.label_states[C]["key"] = "other"
            self.assertIn(C, loop.label_ready(run, led))

    def test_without_a_stage_record_results_stand(self):
        with Fixture(split_world(), **SPLIT) as f:
            run, led = self.accepted_world(f, stage=False)
            self.assertTrue(all("key" not in run.label_states[law] for law in (A, B, C)))   # no key is recorded
            fixed = comparison_set()
            fixed["cases"]["r-b1"]["label"] = "label-r-b1-relabelled"
            write_set(fixed)
            self.assertEqual(loop.label_work(run, run.opts, led), [])
            to_user = []
            route, seen = keyed_route({A, B, C})
            with mock.patch.object(loop, "label_route", route):
                loop.accept_ready(run, run.opts, led, None, to_user)
            self.assertEqual({law: e.state for law, e in led.entries.items()}, {A: "accepted", B: "accepted", C: "accepted"})
            self.assertFalse(any("revoked" in x for x in to_user), to_user)
            self.assertEqual(seen, [[]])                                                 # nothing checked again
            self.assertEqual(feedback.generation_report(run, led)["scope"], "all")


class Scope(unittest.TestCase):
    """A labels stage limited to {A, B} in a run of {A, B, C}."""

    def test_scope_two_of_three(self):
        with Fixture(split_world(), **SPLIT) as f:
            generated(f)
            write_set(comparison_set())
            write_stage(scope={A, B})
            with label_stand_ins({A, B, C}) as (seen, _repairs):
                out = f.drive(1, label_stage=True, label_dataset="ds", max_iterations=4)
            self.assertTrue(seen and all(C not in s for s in seen), seen)               # C never checked
            ledger = {e["law"]: e["state"] for e in f.state()["ledger"]}
            self.assertEqual(ledger, {A: "accepted", B: "accepted", C: "planned"})       # never accepted
            s = json.loads((paths.RESULTS / "r" / "summary.json").read_text())
            self.assertEqual(out, [s["status"]])
            self.assertEqual(s["status"], "complete")
            self.assertEqual(s["complete_for"], "scope")                                 # the scope's, not the run's
            self.assertEqual((s["scope"]["laws"], s["scope"]["of"]), (2, 3))
            self.assertEqual(list(s["scope"]["out_of_scope"]), [C])
            self.assertTrue(s["stop_reason"].startswith("scope 2/3"), s["stop_reason"])
            self.assertIn("not for the run", s["stop_reason"])
            self.assertIn(C, s["stop_reason"])
            self.assertEqual(s["generation"]["scope"], {"laws": 2, "of": 3})
            to_user = (paths.RESULTS / "r" / "TO_USER.md").read_text()
            self.assertIn("scope 2/3", to_user)
            self.assertIn(f"`{C}` (", to_user)

    def test_out_of_scope_is_no_label_work(self):
        with Fixture(split_world(), **SPLIT) as f:
            generated(f)
            write_set(comparison_set())
            write_stage(scope={A, B})
            run, led = loaded(f)
            self.assertEqual(sorted(loop.label_ready(run, led)), [A, B])
            run.label_states[C] = {"state": "awaiting_label_repair", "outcome": "mismatch", "nodes": list(led.entries[C].nodes), "repairs": 0}
            self.assertEqual(loop.label_work(run, run.opts, led), [A, B])                # no check and no repair of C
            to_user = []
            route, seen = keyed_route({A, B, C})
            with mock.patch.object(loop, "label_route", route):
                loop.accept_ready(run, run.opts, led, None, to_user)
            self.assertEqual(led.entries[C].state, "planned")
            self.assertEqual(seen, [[A, B]])

    def test_legacy_summary_has_no_scope(self):
        with Fixture(split_world(), **SPLIT) as f:
            generated(f)
            s = json.loads((paths.RESULTS / "r" / "summary.json").read_text())
            self.assertNotIn("scope", s)
            self.assertNotIn("complete_for", s)
            self.assertEqual(s["generation"]["scope"], "all")


if __name__ == "__main__":
    unittest.main()
