"""Admission evidence of the accepted records, and the fences an admission recheck writes and lifts.

- An entry of the admission file is read by its kind: a verdict (`OK` under the record's current
  admission key is evidence), a timeout count (never evidence: the gate runs again below the bound,
  is paused at it, and starts from zero under another key), or another shape (no evidence).
- A gate rejection fences the record under the key it was rejected on; a later key (a replaced
  concept, another reading value, another gate implementation) gates the current version again.
- A dependency fence is evaluated again from the record's current providers once a fence lifts:
  it stays, naming the provider that still blocks it, until all are usable; then the record is held to
  its own recheck. Operator tokens are never touched.

The real loop, ledgers, admission recheck, fence closure and availability run on the scripted world
of `test_recovery`; only sessions and gate verdicts are scripted."""
import collections
import json
import unittest
from contextlib import ExitStack
from unittest import mock

from harness import loop
from harness.model.reading import Reading
from harness.phases import integrate
from harness.store import paths
from harness.store.ledger import ConceptLedger, Ledger, NodeLedger
from harness.store.state import Availability, Run, USABLE, UNJUDGED, commit_state
from scripts.tests.test_recovery import Fixture, World, node

A, B, C, D = "L-40", "L-41", "L-42", "L-43"


def chain_world(second_provider: bool = False) -> World:
    """A ← B ← C: B composes A's node, C composes B's; with `second_provider`, B composes D's too."""
    w = World({A: "shall a.", B: "shall b.", C: "shall c.", D: "shall d."})
    w.plans = {A: [node("L_40", "shall a.", A)],
               B: [node("L_41", "shall b.", B, compositions=["L_40"] + (["L_43"] if second_provider else []))],
               C: [node("L_42", "shall c.", C, compositions=["L_41"])],
               D: [node("L_43", "shall d.", D)]}
    return w


def options(f):
    """The fixture's options at the root the repository is at now (after a cold clone, the new one)."""
    from scripts.tests.test_split_handoff import options_at
    return options_at(f, f.root_now) if getattr(f, "root_now", None) else f.options()


def loaded(f) -> tuple[Run, Ledger]:
    run = Run(options(f))
    run.restore_state(); run.load_accepted()
    led = Ledger(run.ledger_file, [], 2)
    run.law_entries = led.entries
    return run, led


def recheck(f) -> dict:
    """One launch's admission recheck on the run as it stands, its fences committed."""
    run, led = loaded(f)
    sem = loop.semantic_inputs(options(f))
    unjudged, notes = [], []
    failed = integrate.admission_recheck(run, Reading(run.reading_file), {"core": sem["core"], "ontology": sem["ontology"]}, unjudged, notes)
    commit_state(run, led, ConceptLedger(run.concept_ledger_file, 3), NodeLedger(run.node_ledger_file, 2))
    return {"failed": failed, "unjudged": unjudged, "notes": notes, "run": run, "ledger": led}


def admission() -> dict:
    return json.loads((paths.RESULTS / "r" / "admission.json").read_text())


def change_gate(f, text: str) -> None:
    """A real change of the gate's implementation: a module under the gate's sources."""
    d = f.root / "harness" / "checks"
    d.mkdir(parents=True, exist_ok=True)
    (d / "changed.py").write_text(text)


def codes(run, ids) -> dict:
    av = Availability(run)
    return {i: av.code(i, None) for i in ids}


class TimeoutEntries(unittest.TestCase):

    def test_a_timeout_entry_is_read_by_its_kind_and_counted_to_its_bound(self):
        """T36: a timeout-only entry under the current key raises nothing and lets the gate run; two
        timeouts under one key pause the recheck (no gate, the record unjudged); another root after
        a cold clone reads the same count; a later pass writes a verdict with the history."""
        from scripts.tests.test_split_handoff import clone
        w = chain_world()
        with Fixture(w) as f, ExitStack() as stack:
            self.assertEqual(f.drive(1), ["complete"])
            key = admission()["L_40"]["key"]
            cache = admission()
            cache["L_40"] = {"key": key, "timeouts": 1, "timeout_seconds": 900.0}       # the probe's entry
            (paths.RESULTS / "r" / "admission.json").write_text(json.dumps(cache))
            w.admission["L_40"] = "GATE_TIMEOUT"
            out = recheck(f)                                                            # no KeyError: below the bound, gated
            self.assertEqual(w.admitted["L_40"], 1)
            e = admission()["L_40"]
            self.assertEqual((e["key"], e["timeouts"], "verdict" in e), (key, 2, False))
            self.assertGreaterEqual(e["timeout_seconds"], 900.0)
            self.assertNotIn("L_40", out["run"].fenced)
            self.assertTrue(any("timeout 2 of 2" in x for x in out["unjudged"]), out["unjudged"])
            self.assertEqual(codes(out["run"], ["L_40", "L_41"]), {"L_40": UNJUDGED, "L_41": f"via:L_40:{UNJUDGED}"})
            out = recheck(f)                                                            # at the bound: paused, no gate
            self.assertEqual(w.admitted["L_40"], 1)
            self.assertTrue(any("operational pause" in x for x in out["unjudged"]), out["unjudged"])
            self.assertEqual(admission()["L_40"]["timeouts"], 2)
            clone(f, stack)                                                             # the count travels with the run
            out = recheck(f)
            self.assertEqual((w.admitted["L_40"], admission()["L_40"]["timeouts"]), (1, 2))
            self.assertEqual(codes(out["run"], ["L_40"]), {"L_40": UNJUDGED})

    def test_a_pass_after_a_timeout_writes_a_verdict_with_the_history(self):
        w = chain_world()
        with Fixture(w) as f:
            self.assertEqual(f.drive(1), ["complete"])
            cache = admission(); cache.pop("L_40"); (paths.RESULTS / "r" / "admission.json").write_text(json.dumps(cache))
            w.admission["L_40"] = "GATE_TIMEOUT"
            self.assertEqual(admission().get("L_40"), None)
            recheck(f)
            self.assertEqual(admission()["L_40"]["timeouts"], 1)
            w.admission["L_40"] = "OK"
            out = recheck(f)
            e = admission()["L_40"]
            self.assertEqual((e["verdict"], e["timeout_history"]["timeouts"]), ("OK", 1))
            self.assertNotIn("timeouts", e)
            self.assertEqual(codes(out["run"], ["L_40", "L_41", "L_42"]), {"L_40": USABLE, "L_41": USABLE, "L_42": USABLE})

    def test_two_keys_are_counted_apart_and_a_panic_is_not_a_timeout(self):
        """T38: one record times out once under one key and once under another (the gate's
        implementation changed between): each count is 1, none at the bound. A panic in isolation is
        reported as a Core defect and counted nowhere."""
        w = chain_world()
        with Fixture(w) as f:
            self.assertEqual(f.drive(1), ["complete"])
            w.admission["L_40"] = "GATE_TIMEOUT"
            change_gate(f, "# one\n")
            recheck(f)
            first = admission()["L_40"]
            change_gate(f, "# two\n")
            recheck(f)
            second = admission()["L_40"]
            self.assertNotEqual(first["key"], second["key"])
            self.assertEqual((first["timeouts"], second["timeouts"]), (1, 1))
            w.admission["L_42"] = "PANIC"
            change_gate(f, "# three\n")
            out = recheck(f)
            self.assertTrue(any("panicked in isolation" in x and "L_42" in x for x in out["unjudged"]), out["unjudged"])
            self.assertNotIn("timeouts", admission().get("L_42") or {})
            self.assertNotIn("L_42", out["run"].fenced)

    def test_an_entry_of_no_known_shape_is_no_evidence_and_is_replaced(self):
        w = chain_world()
        with Fixture(w) as f:
            self.assertEqual(f.drive(1), ["complete"])
            cache = admission(); cache["L_40"] = {"key": cache["L_40"]["key"], "state": "?"}
            (paths.RESULTS / "r" / "admission.json").write_text(json.dumps(cache))
            run, _led = loaded(f)
            self.assertEqual(codes(run, ["L_40"]), {"L_40": UNJUDGED})
            out = recheck(f)
            self.assertTrue(any("no known shape" in x for x in out["notes"]), out["notes"])
            self.assertEqual(admission()["L_40"]["verdict"], "OK")


class KeyedGateFence(unittest.TestCase):

    def rejected(self, f, w):
        """L_40 rejected at a recheck: fenced under its key, with B and C fenced on it."""
        cache = admission(); cache.pop("L_40"); (paths.RESULTS / "r" / "admission.json").write_text(json.dumps(cache))
        w.admission["L_40"] = "CHECK_FAIL"
        out = recheck(f)
        fenced = out["run"].fenced
        self.assertEqual((fenced["L_40"]["reason"], fenced["L_41"]["reason"], fenced["L_42"]["reason"]), ("gate", "dependency", "dependency"))
        self.assertEqual((fenced["L_41"]["provider"], fenced["L_42"]["provider"]), ("L_40", "L_41"))
        self.assertEqual(fenced["L_40"]["key"], admission()["L_40"]["key"])
        return out

    def test_a_rejection_under_an_older_key_does_not_fence_the_current_version(self):
        """T40 and its extension (i): A is rejected and B, C fenced on it. The same key keeps the fence
        and runs no gate; a real change of the key (the gate's implementation) gates A again: it passes,
        its fence goes to history, B's and C's dependency fences are lifted, and each is held to its own
        gate under its current key before it is usable."""
        w = chain_world()
        with Fixture(w) as f:
            self.assertEqual(f.drive(1), ["complete"])
            self.rejected(f, w)
            runs = collections.Counter(w.admitted)
            w.admission["L_40"] = "OK"
            out = recheck(f)                                                     # the key unchanged: the rejection stands
            self.assertEqual(w.admitted, runs)
            self.assertIn("L_40", out["run"].fenced)
            change_gate(f, "# changed\n")
            w.admission["L_41"] = "GATE_TIMEOUT"                                 # B's own gate does not judge it at once
            out = recheck(f)
            run = out["run"]
            self.assertEqual(sorted(run.fenced), ["L_42"])                      # B is not usable yet: C keeps its fence on B
            self.assertEqual(run.fenced["L_42"]["provider"], "L_41")
            lifted = {h["id"]: h for h in run.fence_history if h.get("lifted")}
            self.assertEqual(set(lifted), {"L_40", "L_41"})
            self.assertEqual(admission()["L_40"]["verdict"], "OK")
            self.assertEqual(admission()["L_41"]["timeouts"], 1)                 # B regated under its own key: not judged
            self.assertEqual(codes(run, ["L_40", "L_41", "L_42"]), {"L_40": USABLE, "L_41": UNJUDGED, "L_42": f"via:L_41:{UNJUDGED}"})   # its fence names its provider
            w.admission["L_41"] = "OK"
            out = recheck(f)
            self.assertEqual(sorted(out["run"].fenced), [])
            self.assertEqual(codes(out["run"], ["L_40", "L_41", "L_42"]), {"L_40": USABLE, "L_41": USABLE, "L_42": USABLE})

    def test_rejected_again_under_the_new_key_is_fenced_under_it(self):
        w = chain_world()
        with Fixture(w) as f:
            self.assertEqual(f.drive(1), ["complete"])
            self.rejected(f, w)
            old = admission()["L_40"]["key"]
            change_gate(f, "# changed\n")
            out = recheck(f)
            self.assertNotEqual(out["run"].fenced["L_40"]["key"], old)
            self.assertEqual(out["run"].fenced["L_40"]["key"], admission()["L_40"]["key"])
            self.assertEqual(sorted(out["run"].fenced), ["L_40", "L_41", "L_42"])

    def test_a_second_blocking_provider_keeps_the_dependency_fence(self):
        """T40 (ii): B also composes D, rejected under every key; once A passes, B stays fenced with D
        as its provider, and C stays fenced. Variant: B's own context fails its recheck: B is fenced
        for its context."""
        w = chain_world(second_provider=True)
        with Fixture(w) as f:
            self.assertEqual(f.drive(1), ["complete"])
            cache = admission(); cache.pop("L_43"); (paths.RESULTS / "r" / "admission.json").write_text(json.dumps(cache))
            w.admission["L_43"] = "CHECK_FAIL"
            recheck(f)
            self.rejected(f, w)
            change_gate(f, "# changed\n")
            w.admission["L_40"] = "OK"
            out = recheck(f)
            fenced = out["run"].fenced
            self.assertNotIn("L_40", fenced)
            self.assertEqual((fenced["L_41"]["reason"], fenced["L_41"]["provider"]), ("dependency", "L_43"))
            self.assertEqual((fenced["L_42"]["reason"], fenced["L_42"]["provider"]), ("dependency", "L_41"))
        w = chain_world()
        with Fixture(w) as f:
            self.assertEqual(f.drive(1), ["complete"])
            self.rejected(f, w)
            change_gate(f, "# changed\n")
            w.admission["L_40"] = "OK"
            run, _led = loaded(f)
            sem = loop.semantic_inputs(options(f))
            integrate.admission_recheck(run, Reading(run.reading_file), {"core": sem["core"], "ontology": sem["ontology"]}, [], [])

            def own_context(run, reading, base, laws, only=None):        # B's own context check fails at its recheck
                if "L_41" not in run.fenced:
                    run.fence("L_41", "node", "context", evidence="scripted: its context no longer meets its obligations")
                return [], ["`L_41`: scripted"], []
            with mock.patch.object(integrate, "recheck_contexts", own_context):
                integrate.recheck_contexts(run, None, None, {})
            integrate.fence_closure(run)
            self.assertEqual(run.fenced["L_41"]["reason"], "context")
            self.assertEqual((run.fenced["L_42"]["reason"], run.fenced["L_42"]["provider"]), ("dependency", "L_41"))

    def test_operator_tokens_are_never_touched_by_the_recheck(self):
        """T40 (iii): B's law is blocked on `decision:<A's law>`; the automatic re-evaluation lifts the
        fences and leaves the token, and B's law, as they were."""
        w = chain_world()
        with Fixture(w) as f:
            self.assertEqual(f.drive(1), ["complete"])
            self.rejected(f, w)
            st = json.loads((paths.RESULTS / "r" / "state.json").read_text())
            for e in st["ledger"]:
                if e["law"] == B:
                    e.update(state="blocked", gaps=[f"decision:{A}"], own_gaps=[], waits_on=[A])
            (paths.RESULTS / "r" / "state.json").write_text(json.dumps(st))
            change_gate(f, "# changed\n")
            w.admission["L_40"] = "OK"
            out = recheck(f)
            self.assertNotIn("L_41", out["run"].fenced)
            e = out["ledger"].entries[B]
            self.assertEqual((e.state, e.gaps, e.waits_on), ("blocked", [f"decision:{A}"], [A]))
            self.assertTrue(codes(out["run"], ["L_41"])["L_41"].startswith("operator"))


if __name__ == "__main__":
    unittest.main()


class OldRejectionNewTimeout(unittest.TestCase):
    """F2: a gate rejection stands only for the key it was given under. Once the key changed, it is
    retired whatever the new key's gate says: a timeout (and, at the bound, the paused recheck) leaves
    the record unjudged, never fenced; its dependents stay unusable until it passes; an operator's
    token is never touched."""

    def test_old_rejection_new_timeout_restart_bound_reopen_then_pass(self):
        from scripts.tests.test_admission_reopen import cli
        w = chain_world()
        with Fixture(w) as f:
            self.assertEqual(f.drive(1), ["complete"])
            KeyedGateFence().rejected(f, w)
            st = json.loads((paths.RESULTS / "r" / "state.json").read_text())
            for e in st["ledger"]:                                              # an operator's token on a dependent's law
                if e["law"] == C:
                    e.update(state="blocked", gaps=[f"decision:{C}"], own_gaps=[f"decision:{C}"])
            (paths.RESULTS / "r" / "state.json").write_text(json.dumps(st))
            Run(options(f)).restore_state()
            change_gate(f, "# changed\n")
            w.admission["L_40"] = "GATE_TIMEOUT"
            out = recheck(f)                                                     # the new key's gate does not judge it
            self.assertNotIn("L_40", out["run"].fenced)
            self.assertEqual((admission()["L_40"]["timeouts"], "verdict" in admission()["L_40"]), (1, False))
            self.assertTrue(any(h["id"] == "L_40" and h.get("lifted") for h in out["run"].fence_history))
            self.assertEqual(codes(out["run"], ["L_40"]), {"L_40": UNJUDGED})
            self.assertNotEqual(codes(out["run"], ["L_41"])["L_41"], USABLE)
            out = recheck(f)                                                     # a restart: timed again, to the bound
            self.assertEqual(admission()["L_40"]["timeouts"], 2)
            out = recheck(f)                                                     # at the bound: paused, still unjudged, not fenced
            self.assertTrue(any("operational pause" in x for x in out["unjudged"]), out["unjudged"])
            self.assertNotIn("L_40", out["run"].fenced)
            self.assertEqual(codes(out["run"], ["L_40"]), {"L_40": UNJUDGED})
            code, text = cli("r", laws=A, admission=True)
            self.assertEqual(code, 0, text)
            self.assertEqual(admission()["L_40"]["timeouts"], 0)
            w.admission["L_40"] = "OK"
            out = recheck(f)
            self.assertEqual(codes(out["run"], ["L_40", "L_41"]), {"L_40": USABLE, "L_41": USABLE})
            self.assertEqual(sorted(out["run"].fenced), [])
            e = out["ledger"].entries[C]
            self.assertEqual((e.state, e.gaps), ("blocked", [f"decision:{C}"]))   # the operator's token kept

    def test_a_new_panic_also_retires_the_old_rejection(self):
        w = chain_world()
        with Fixture(w) as f:
            self.assertEqual(f.drive(1), ["complete"])
            KeyedGateFence().rejected(f, w)
            change_gate(f, "# changed\n")
            w.admission["L_40"] = "PANIC"
            out = recheck(f)
            self.assertNotIn("L_40", out["run"].fenced)
            self.assertEqual(codes(out["run"], ["L_40"]), {"L_40": UNJUDGED})
