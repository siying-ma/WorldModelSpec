"""The candidate transaction's own ledger.

A transaction holds a copy of the law ledger and the label states from its opening (`txn.ledger`),
bound to its view, so every availability, registry, validator and label check inside it sees the
plans its changes make, and production's ledger does not change before the commit. What a check
rests on (each law's state, plan, tokens and waits; the admission evidence; the plans given to the
label hook) is part of the versions results are bound to; the route a commit carries is recomputed
from the verified results (`Candidate.route`) and must be exactly it; the commit merges the routed
semantic fields onto the live ledger and label states, every counter taken as it stands then."""
import copy
import json
import unittest
from dataclasses import asdict

from harness.phases import candidate as cand
from harness.store.ledger import Ledger
from harness.store.state import MISSING, SUPERSEDED, USABLE
from scripts.tests.test_candidate import Base, Txn, admit, files, node_rec, world

A1, A2, B1 = "TEST_TX_1_o1", "TEST_TX_1_o2", "TEST_TX_2"
LA, LB = "TEST-TX-1", "TEST-TX-2"


def comp(nid, *rules):
    return node_rec(nid, compositions=[{"span": "o1", "rule": r, "as": "condition"} for r in rules])


def snapshot(run, led) -> str:
    return json.dumps({"ledger": [asdict(e) for e in led.entries.values()], "label_states": run.label_states,
                       "file": (run.dir / "state.json").read_text()}, sort_keys=True)


class TransactionLedger(Base):

    def built(self):
        return world({}, {A1: comp(A1), B1: comp(B1, A1)})

    def ledger(self, run) -> Ledger:
        led = Ledger(run.ledger_file, [LA, LB], 2)
        led.mark_planned(LA, [A1], 1); led.accept(LA, [A1]); led.mark_planned(LB, [B1], 1)
        run.law_entries = led.entries
        run.label_states = {LB: {"state": "awaiting_label_repair", "nodes": [B1], "repairs": 1, "sessions": 1}}
        return led

    def test_a_replan_in_the_transaction_is_seen_inside_it_and_published_by_its_commit(self):
        """T19, T12 (a): a re-plan replaces A1 by A2 (`Change(A1, None)`), and B composes A2 in the same
        change set: inside the transaction A2 is usable for B (its plan is the transaction's) and B
        passes the availability check; A1, withdrawn, is `missing` there. Production's ledger keeps
        A1 until the commit, which publishes A's plan [A2]."""
        with self.built() as (run, _lib):
            led = self.ledger(run)
            with Txn(run) as txn:
                txn.apply([cand.Change("node", A1, None), cand.Change("node", A2, comp(A2), files("node", A2)),
                           cand.Change("node", B1, comp(B1, A2), files("node", B1, "v2"))], plans={LA: [A2]})
                self.assertEqual(txn.ledger.entries[LA].nodes, [A2])
                self.assertEqual(led.entries[LA].nodes, [A1])                              # production untouched
                self.assertEqual(txn.view.provider_code(A2, LB, gated=set(txn.changed)), USABLE)
                self.assertEqual(txn.view.provider_code(A1, LB), MISSING)
                results = txn.verify()
                self.assertEqual([r for r in results if r.check == "availability"], [])
                self.assertTrue(all(r.status == "pass" for r in results), results)
                txn.commit()
            self.assertEqual(led.entries[LA].nodes, [A2])

    def test_a_node_left_in_the_view_out_of_its_laws_plan_is_superseded(self):
        """T12 (b): A1 stays published, A's plan in the transaction no longer lists it."""
        with self.built() as (run, _lib):
            self.ledger(run)
            with Txn(run) as txn:
                txn.ledger.entries[LA].nodes = [A2]
                self.assertEqual(txn.view.provider_code(A1, LB), SUPERSEDED)
                self.assertNotIn(A1, txn.view.usable_nodes(LB))
                txn.rollback("test")

    def test_production_is_unchanged_until_the_commit_and_after_a_rollback(self):
        """T20: the production ledger entries and label states are byte for byte the same after the
        open, the apply, the verify, and the rollback."""
        with self.built() as (run, _lib):
            led = self.ledger(run)
            before = snapshot(run, led)
            with Txn(run) as txn:
                self.assertEqual(snapshot(run, led), before)
                txn.apply([cand.Change("node", A1, None), cand.Change("node", A2, comp(A2), files("node", A2))], plans={LA: [A2]})
                txn.ledger.entries[LB].state = "accepted"
                txn.label_states[LB]["state"] = "accepted"
                self.assertEqual(snapshot(run, led), before)
                txn.verify()
                self.assertEqual(snapshot(run, led), before)
                txn.rollback("test")
            self.assertEqual(snapshot(run, led), before)

    def test_a_change_of_what_the_results_rest_on_after_verify_is_refused(self):
        """T27, T29 (c): after verify, A's plan changed in the transaction's input ledger refuses the
        commit as stale; a bookkeeping count changed does not."""
        for change, refused in (("nodes", True), ("count", False)):
            with self.subTest(change=change), self.built() as (run, _lib):
                self.ledger(run)
                with Txn(run) as txn:
                    txn.apply([cand.Change("node", B1, comp(B1, A1), files("node", B1, "v2"))])
                    txn.verify()
                    if change == "nodes":
                        txn.ledger.entries[LA].nodes = [A1, A2]
                    else:
                        txn.ledger.entries[LA].attempts += 1
                        txn.ledger.entries[LA].repeats = {"k": 3}
                    if refused:
                        with self.assertRaises(cand.CommitRefused) as e:
                            txn.commit()
                        self.assertIn("dependency", str(e.exception))
                        txn.rollback("test")
                    else:
                        txn.commit()

    def test_a_route_not_derived_from_the_verified_results_is_refused(self):
        """T29 (d): the routed copy a commit carries must be exactly the one the verified results give
        (`Candidate.route`): one that also accepts another law is refused; the derived one commits."""
        with self.built() as (run, _lib):
            led = self.ledger(run)
            with Txn(run) as txn:
                txn.apply([cand.Change("node", B1, comp(B1, A1), files("node", B1, "v2"))])
                txn.verify()
                routed = txn.route(None, [])
                smuggled = copy.deepcopy(routed)
                smuggled.entries[LB].state = "accepted"
                with self.assertRaises(cand.CommitRefused) as e:
                    txn.commit(routed=smuggled)
                self.assertIn("route", str(e.exception))
                txn.commit(routed=routed)
            self.assertEqual(led.entries[LB].state, "planned")

    def test_counters_are_taken_as_they_stand_at_the_commit(self):
        """T33: counts that grew after the transaction opened (a session's `sessions` and `active`, a
        law's attempts) are the live values at the commit, with no rollback to the opening's; an
        admission file changed outside the transaction refuses the commit."""
        with self.built() as (run, _lib):
            led = self.ledger(run)
            with Txn(run) as txn:
                txn.apply([cand.Change("node", B1, comp(B1, A1), files("node", B1, "v2"))])
                txn.verify()
                run.label_states[LB]["sessions"] = 2
                run.label_states[LB]["active"] = {"dir": "x"}
                led.entries[LB].attempts = 1
                txn.commit(routed=txn.route(None, []))
            self.assertEqual((run.label_states[LB]["sessions"], run.label_states[LB]["active"], led.entries[LB].attempts),
                             (2, {"dir": "x"}, 1))
            snap = json.loads((run.dir / "state.json").read_text())
            self.assertEqual({e["law"]: e["attempts"] for e in snap["ledger"]}[LB], 1)
        with self.built() as (run, _lib):
            self.ledger(run)
            with Txn(run) as txn:
                txn.apply([cand.Change("node", B1, comp(B1, A1), files("node", B1, "v2"))])
                txn.verify()
                admit(run)
                (run.dir / "admission.json").write_text((run.dir / "admission.json").read_text() + " ")
                with self.assertRaises(cand.CommitRefused):
                    txn.commit()
                txn.rollback("test")


if __name__ == "__main__":
    unittest.main()


class FailedCommit(Base):
    """F1: a commit that stops before its commit point publishes nothing and leaves the live ledger,
    the label states and the snapshot as they were (counts that grew meanwhile kept); one that stops
    after it is completed whole by the recovery."""

    def staged(self, run, led, txn):
        txn.apply([cand.Change("node", A1, None), cand.Change("node", A2, comp(A2), files("node", A2)),
                   cand.Change("node", B1, comp(B1, A2), files("node", B1, "v2"))], plans={LA: [A2]})
        self.assertTrue(all(r.status == "pass" for r in txn.verify()))
        led.entries[LB].attempts = 1                                       # a real count that grew while the candidate was open

    def test_a_failure_before_the_commit_point_changes_nothing(self):
        from unittest import mock
        from harness.phases import integrate
        for where in ("admission key", "staged write"):
            with self.subTest(where=where), TransactionLedger().built() as (run, _lib):
                led = TransactionLedger().ledger(run)
                state_before = (run.dir / "state.json").read_bytes()
                states_before = copy.deepcopy(run.label_states)
                with Txn(run) as txn:
                    self.staged(run, led, txn)
                    boom = RuntimeError(f"scripted failure in the {where}")
                    target = (mock.patch.object(integrate, "admission_key", mock.Mock(side_effect=boom)) if where == "admission key"
                              else mock.patch.object(cand.os, "fsync", mock.Mock(side_effect=boom)))
                    with target, self.assertRaises(RuntimeError):
                        txn.commit(routed=txn.route(None, []))
                    txn.rollback("test")
                self.assertEqual((led.entries[LA].nodes, led.entries[LB].attempts), ([A1], 1))
                self.assertEqual(run.label_states, states_before)
                self.assertEqual((run.dir / "state.json").read_bytes(), state_before)
                self.assertIsNone(cand.pending())

    def test_a_failure_after_the_commit_point_is_completed_by_the_recovery(self):
        from unittest import mock
        with TransactionLedger().built() as (run, _lib):
            led = TransactionLedger().ledger(run)
            real = cand._apply
            with Txn(run) as txn:
                self.staged(run, led, txn)
                with mock.patch.object(cand, "_apply", mock.Mock(side_effect=RuntimeError("stopped after the commit point"))), \
                        self.assertRaises(RuntimeError):
                    txn.commit(routed=txn.route(None, []))
                self.assertEqual(led.entries[LA].nodes, [A2])                # past the commit point, the run in memory is the new version
            self.assertIsNotNone(cand.pending())
            self.assertIsNotNone(cand.recover_pending())
            snap = json.loads((run.dir / "state.json").read_text())
            self.assertEqual({e["law"]: e["nodes"] for e in snap["ledger"]}[LA], [A2])
            self.assertEqual({e["law"]: e["attempts"] for e in snap["ledger"]}[LB], 1)
            self.assertIsNone(cand.pending())
            del real


class ScopeCountAcrossACommit(Base):
    """A scope count the label repair writes into the live ledger after a candidate went out of scope
    (`Ledger.scope_violation`) survives a later commit as it stands: the commit merges only the routed
    semantic fields, so it neither loses nor doubles it, in memory or in the snapshot; a candidate
    rolled back after it leaves it as written."""

    def test_the_scope_count_is_kept_once(self):
        with TransactionLedger().built() as (run, _lib):
            led = TransactionLedger().ledger(run)
            with Txn(run) as txn:
                txn.apply([cand.Change("node", B1, comp(B1, A1), files("node", B1, "v2"))])
                txn.verify()
                led.scope_violation(LB, LB)                          # an earlier candidate of LB's repair went out of scope
                txn.commit(routed=txn.route(None, []))
            snap = json.loads((run.dir / "state.json").read_text())
            self.assertEqual(led.entries[LB].scope_violations, {LB: 1})
            self.assertEqual({e["law"]: e["scope_violations"] for e in snap["ledger"]}[LB], {LB: 1})
            with Txn(run) as txn:
                txn.apply([cand.Change("node", B1, comp(B1, A1), files("node", B1, "v3"))])
                txn.verify()
                txn.rollback("out of scope")
                led.scope_violation(LB, LB)
            self.assertEqual(led.entries[LB].scope_violations, {LB: 2})
