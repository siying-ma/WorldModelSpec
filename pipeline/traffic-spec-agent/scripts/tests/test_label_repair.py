"""The label check inside the loop (`--label_repair`): a law whose plan is gated is checked on a
candidate library and routed by its outcome; the comparison set is fixed at the run's start; the
candidate transaction's label hook keeps every match and decided recording and measures a repair's
goal apart from the law's alignment; and without the option the loop takes the path it took before.

The library, the snapshot, the ledger and the candidate are the real ones; the monitor and Explain
are the stand-in programs of the label check's own tests, reading each recording's verdicts from a
synthetic dataset; the gate's toolchain step and the whole-library build are stood in for."""
import json
import tempfile
import unittest
from contextlib import contextmanager
from pathlib import Path
from unittest import mock

from harness import loop
from harness.phases import candidate as cand
from harness.phases import label_check
from harness.store import jsonl
from harness.store.ledger import Ledger
from harness.store.state import Options, commit_state
from scripts.tests.test_candidate import Base, Txn, files, node_rec, passing, world
from scripts.tests.test_label_check import FAKE_EXPLAIN, FAKE_MONITOR, IV, label_v2, make_dataset, make_v2_dataset, write_exe

N = {k: f"TEST_LREP_{k}" for k in range(1, 6)}
L = {k: f"TEST-LREP-{k}" for k in range(1, 6)}


def spec(nid: str, verdict: str) -> dict:
    return {nid: [[verdict, {"x": 1}]]}


RECS = [("r1a", L[1], "compliant", False, spec(N[1], "compliant")),
        ("r1j", L[1], "violation", True, spec(N[1], "compliant")),            # a judgment call the rule disagrees with
        ("r1u", L[1], "", False, {"fail": "crash"}),                           # unlabelled, and its run failed
        ("r3a", L[3], "compliant", False, spec(N[3], "compliant")),
        ("r4a", L[4], "compliant", False, {"fail": "crash"}),
        ("r5a", L[5], "compliant", False, spec(N[5], "violated")),
        ("r5b", L[5], "violation", False, spec(N[5], "compliant")),
        ("r5c", L[5], "compliant", False, spec(N[5], "compliant"))]


#: The plain labels of `RECS` under label contract v2, each with its confirmed scoring interval.
RECS_V2 = [(rid, label_v2(law, label, jc), sp) for rid, law, label, jc, sp in RECS if label and not jc]


@contextmanager
def setting(recs=RECS, concepts: dict | None = None, calls: dict | None = None):
    """The world of the candidate's tests with five laws of one node each, all planned and accepted
    (each node calling the concepts `calls` names for it, among `concepts`), a synthetic dataset (under
    label contract v2 when `recs` are `RECS_V2`-shaped: id, label, spec), the stand-in tools, and the
    run's training context."""
    nodes = {N[k]: node_rec(N[k], (calls or {}).get(N[k], ())) for k in N}
    with world(concepts or {}, nodes) as (run, lib), tempfile.TemporaryDirectory() as t:
        t = Path(t)
        ds = make_v2_dataset(t / "ds", recs) if recs and len(recs[0]) == 3 else make_dataset(t / "ds", recs)
        mon, exp = write_exe(t / "monitor", FAKE_MONITOR), write_exe(t / "explain", FAKE_EXPLAIN)
        ledger = Ledger(run.ledger_file, list(L.values()), 2)
        ledger.attempt = 1
        for k in N:
            ledger.mark_planned(L[k], [N[k]], 1)
        training = label_check.training_context(run.dir, list(L.values()), ds.path,
                                                label_check.Limits(deadline_s=5, memory_gb=4, explain_s=5, jobs=2))
        with mock.patch.object(label_check, "build_tools", lambda lib_: (mon, exp)):
            yield run, ledger, training, t


class Routing(Base):

    def test_each_outcome_is_routed(self):
        with setting() as (run, ledger, training, _t):
            run.fenced[N[3]] = {"kind": "node", "reason": "gate", "run": "r"}
            to_user = []
            routed = loop.label_route(run, ledger, training, to_user)
            self.assertEqual(routed, {L[1]: "accepted", L[2]: "accepted", L[3]: "waiting", L[4]: "failed", L[5]: "awaiting_label_repair"})
            st = {k: ledger.entries[L[k]].state for k in L}
            self.assertEqual(st, {1: "accepted", 2: "accepted", 3: "planned", 4: "blocked", 5: "planned"})
            self.assertEqual([run.label_states[L[k]]["outcome"] for k in (1, 2)], ["aligned", "unverified"])
            self.assertEqual(run.label_states[L[1]]["coverage"], {"eligible": 1, "matched": 1})     # the judgment call and the unlabelled failure apart
            self.assertEqual(ledger.entries[L[3]].attempts, 0)                                      # waits uncharged
            self.assertEqual(ledger.entries[L[4]].gaps, [f"decision:{L[4]}"])
            self.assertEqual(ledger.entries[L[5]].attempts, 0)                                      # no re-plan from labels
            evidence = (run.dir / run.label_states[L[5]]["evidence"]).read_text()
            self.assertIn("## Label mismatches", evidence)
            self.assertIn("r5a", evidence)
            self.assertNotIn("r1j", (run.dir / run.label_states[L[1]]["evidence"]).read_text())
            check = json.loads((run.dir / run.label_states[L[5]]["check"]).read_text())
            self.assertEqual(check["versions"]["data"], "v1")
            self.assertEqual(check["versions"]["scoring"], training.fixed["scoring"])
            self.assertTrue(any("awaiting its label repair" in x for x in to_user))
            self.assertEqual(label_check.committed_checks(run.dir, run.label_states)[L[5]]["outcome"], "mismatch")
            again = loop.label_route(run, ledger, training, [])
            self.assertEqual(again, {L[3]: "waiting"})                                             # the law awaiting repair is not checked again

    def test_the_routed_states_are_committed_with_the_snapshot(self):
        with setting() as (run, ledger, training, _t):
            loop.label_route(run, ledger, training, [])
            from harness.store.ledger import ConceptLedger, NodeLedger
            commit_state(run, ledger, ConceptLedger(run.concept_ledger_file, 3), NodeLedger(run.node_ledger_file, 2))
            fresh = type(run)(run.opts)
            fresh.restore_state()
            self.assertEqual(fresh.label_states, run.label_states)


class FixedSet(unittest.TestCase):

    def test_a_resume_on_another_data_version_or_set_is_refused(self):
        with tempfile.TemporaryDirectory() as t:
            t = Path(t)
            ds = make_dataset(t / "ds", RECS)
            run_dir = t / "run"
            run_dir.mkdir()
            first = label_check.training_context(run_dir, list(L.values()), ds.path)
            self.assertEqual(first.fixed["laws"][L[5]]["eligible"], ["r5a", "r5b", "r5c"])
            self.assertEqual(first.fixed["laws"][L[1]], {"recordings": ["r1a", "r1j", "r1u"], "eligible": ["r1a"], "judgment_calls": ["r1j"]})
            saved = (run_dir / "comparison_set.json").read_bytes()
            label_check.training_context(run_dir, list(L.values()), ds.path)                   # the same inputs resume
            (ds.path / "DATASET.json").write_text(json.dumps({"data_version": "v2"}))
            with self.assertRaisesRegex(SystemExit, "data_version"):
                label_check.training_context(run_dir, list(L.values()), ds.path)
            (ds.path / "DATASET.json").write_text(json.dumps({"data_version": "v1"}))
            (ds.path / "recordings" / "r5c" / "label.json").write_text(json.dumps({"law_id": L[5], "recorded_label": "violation",
                                                                                    "judgment_call": True}))
            with self.assertRaisesRegex(SystemExit, "laws"):
                label_check.training_context(run_dir, list(L.values()), ds.path)
            self.assertEqual((run_dir / "comparison_set.json").read_bytes(), saved)


def prior(statuses: dict[str, str], outcome: str = "mismatch") -> dict:
    return {"outcome": outcome, "scored": [{"recording_id": r, "label": "compliant", "judgment_call": False, "status": s}
                                           for r, s in statuses.items()]}


class Compare(unittest.TestCase):

    def test_a_lost_match_and_a_decided_recording_made_undecided_are_refused(self):
        lost = label_check.compare(prior({"a": "match", "b": "mismatch"}), prior({"a": "mismatch", "b": "match"}), "labelled semantic")
        self.assertFalse(lost["ok"])
        self.assertEqual(lost["lost"], ["a"])
        undecided = label_check.compare(prior({"a": "match", "b": "mismatch"}), prior({"a": "match", "b": "unknown"}))
        self.assertFalse(undecided["ok"])
        self.assertEqual(undecided["undecided"], ["b"])

    def test_a_partial_fix_is_progress_while_the_law_stays_mismatch(self):
        cmp = label_check.compare(prior({"a": "mismatch", "b": "mismatch", "c": "match"}),
                                  prior({"a": "match", "b": "mismatch", "c": "match"}, "mismatch"), "labelled semantic")
        self.assertTrue(cmp["ok"])
        self.assertTrue(cmp["goal_met"])
        self.assertEqual(cmp["outcome"], "mismatch")
        self.assertEqual(cmp["coverage"], {"eligible": 3, "matched": 2})
        none = label_check.compare(prior({"a": "mismatch"}), prior({"a": "mismatch"}), "labelled semantic")
        self.assertFalse(none["ok"])

    def test_other_goals(self):
        perf = label_check.progress("performance", {"a": "deadline", "b": "match"}, {"a": "mismatch", "b": "match"})
        self.assertTrue(perf[0])
        cov = label_check.progress("coverage", {"a": "unknown", "b": "match"}, {"a": "mismatch", "b": "match"})
        self.assertTrue(cov[0])
        self.assertFalse(label_check.progress("coverage", {"a": "unknown", "b": "match"}, {"a": "match", "b": "mismatch"})[0])
        self.assertFalse(label_check.progress("sweep", {}, {})[0])


class Hook(Base):

    def _verify(self, run, training, prior_checks, bind=True):
        hook = label_check.label_hook(training, prior_checks, {L[5]: [N[5]]}, target=L[5], goal="labelled semantic")
        t = Txn(run, hooks=(hook,))
        with t as txn:
            if bind:
                training.bind(txn)
            txn.apply([cand.Change("node", N[5], node_rec(N[5]), files("node", N[5], "v2"))])
            results = [r for r in txn.verify() if r.check == "label_non_regression"]
            if all(r.status == "pass" for r in results):
                txn.commit()
            else:
                with self.assertRaises(cand.CommitRefused):
                    txn.commit()
            return results, txn

    def test_a_repair_that_fixes_one_of_two_mismatches_is_kept(self):
        with setting() as (run, ledger, training, _t):
            # the committed check had all three in disagreement; on the candidate r5c matches, r5a and r5b still do not
            results, txn = self._verify(run, training, {L[5]: prior({"r5a": "mismatch", "r5b": "mismatch", "r5c": "mismatch"})})
            self.assertEqual([(r.subject, r.status) for r in results], [(L[5], "pass")])
            self.assertIn("goal `labelled semantic`: 1 mismatch(es) now match: r5c", results[0].details)
            self.assertTrue(any(d.startswith("outcome mismatch") for d in results[0].details))
            self.assertEqual(txn.status, "committed")
            self.assertEqual(txn.label_checks[L[5]].outcome, "mismatch")

    def test_a_repair_that_loses_a_match_is_refused(self):
        with setting() as (run, ledger, training, _t):
            results, txn = self._verify(run, training, {L[5]: prior({"r5a": "match", "r5b": "mismatch", "r5c": "mismatch"})})
            self.assertEqual(results[0].status, "fail")
            self.assertIn("match lost: r5a", results[0].details)
            self.assertEqual(txn.status, "rolled_back")

    def test_an_unbound_candidate_is_not_judged(self):
        with setting() as (run, ledger, training, _t):
            results, txn = self._verify(run, training, {L[5]: prior({"r5a": "mismatch"})}, bind=False)
            self.assertEqual(results[0].status, "unavailable")


class LabelSetV2(Base):
    """Under label contract v2 a candidate is bound to the digest of the fixed labels with their
    scoring intervals (`label_set`) through the real transaction: the loop's check binds, checks and
    keeps it in the check, its results and the committed state; a candidate whose results rest on
    another interval set is refused at the commit, and a run whose intervals changed does not resume."""

    def test_a_v2_law_is_checked_and_routed_with_its_label_set(self):
        with setting(RECS_V2) as (run, ledger, training, _t):
            want = training.versions()["label_set"]
            routed = loop.label_route(run, ledger, training, [])
            self.assertEqual((routed[L[1]], routed[L[5]]), ("accepted", "awaiting_label_repair"))
            for law in (L[1], L[5]):
                st = run.label_states[law]
                self.assertEqual(st["versions"]["label_set"], want)
                check = json.loads((run.dir / st["check"]).read_text())
                self.assertEqual((check["versions"]["label_set"], check["label_contract"]), (want, "v2"))
            from harness.store.ledger import ConceptLedger, NodeLedger
            commit_state(run, ledger, ConceptLedger(run.concept_ledger_file, 3), NodeLedger(run.node_ledger_file, 2))
            self.assertEqual(jsonl.read_json(run.state_file, {})["label_states"][L[5]]["versions"]["label_set"], want)

    def test_the_label_set_is_kept_in_the_results_and_the_commit(self):
        with setting(RECS_V2) as (run, ledger, training, _t):
            loop.label_route(run, ledger, training, [])
            prior_checks = label_check.committed_checks(run.dir, run.label_states)
            hook = label_check.label_hook(training, prior_checks, {L[5]: [N[5]]}, target=L[5], goal="labelled semantic")
            f = training.dataset.path / "recordings" / "r5a" / "fake.json"
            f.write_text(json.dumps(spec(N[5], "compliant")))           # the changed rule now agrees on r5a
            with Txn(run, hooks=(hook,)) as txn:
                training.bind(txn)
                txn.apply([cand.Change("node", N[5], node_rec(N[5]), files("node", N[5], "v2"))])
                results = txn.verify()
                self.assertTrue(all(r.status == "pass" for r in results), results)
                want = training.versions()["label_set"]
                self.assertEqual({r.versions["label_set"] for r in results}, {want})
                rows = [json.loads(x) for x in (txn.area / "checks.jsonl").read_text().splitlines()]
                self.assertEqual({r["versions"]["label_set"] for r in rows}, {want})
                self.assertEqual(txn.label_checks[L[5]].versions["label_set"], want)
                txn.commit()
            self.assertEqual(txn.status, "committed")

    def test_another_interval_set_refuses_the_commit_and_the_resumption(self):
        with setting(RECS_V2) as (run, ledger, training, t):
            with Txn(run) as txn:
                training.bind(txn)
                txn.apply([cand.Change("node", N[5], node_rec(N[5]), files("node", N[5], "v2"))])
                txn.verify()
                other = make_v2_dataset(t / "ds_other", [(rid, label_v2(lab["law_id"], lab["recorded_label"], False,
                                                                        {**IV, "end_ms": 5000}), sp) for rid, lab, sp in RECS_V2])
                (t / "run_other").mkdir()
                moved = label_check.training_context(t / "run_other", list(L.values()), other.path, training.limits)
                self.assertNotEqual(moved.versions()["label_set"], training.versions()["label_set"])
                with self.assertRaisesRegex(ValueError, "label_set"):
                    moved.bind(txn)                                      # a candidate bound to one interval set takes no other
                txn.bind(label_set=moved.versions()["label_set"])
                with self.assertRaisesRegex(cand.CommitRefused, "label_set"):
                    txn.commit()
                txn.rollback("test")
            lab = training.dataset.files("r5a")["label"]
            lab.write_text(json.dumps(label_v2(L[5], "compliant", False, {**IV, "end_ms": 5000})))
            with self.assertRaises(SystemExit):
                label_check.training_context(run.dir, list(L.values()), training.dataset.path, training.limits)


class Off(Base):
    """Without `label_repair` the loop's path is the one before: laws are accepted on their nodes,
    tasks are not counted by the candidate's scheduling, and the snapshot carries no label state."""

    def test_laws_are_accepted_without_a_label_check(self):
        with setting() as (run, ledger, training, _t):
            def forbidden(*a, **k):
                raise AssertionError("an in-loop label check ran without label_repair")
            with mock.patch.object(loop, "label_route", forbidden), mock.patch.object(label_check, "check_law", forbidden), \
                    mock.patch.object(cand.Candidate, "open", forbidden):
                loop.accept_ready(run, run.opts, ledger, None, [])
            self.assertEqual({e.state for e in ledger.entries.values()}, {"accepted"})
            self.assertEqual(run.label_states, {})
            from harness.store.ledger import ConceptLedger, NodeLedger
            commit_state(run, ledger, ConceptLedger(run.concept_ledger_file, 3), NodeLedger(run.node_ledger_file, 2))
            self.assertNotIn("label_states", jsonl.read_json(run.state_file, {}))

    def test_tasks_are_counted_only_with_label_repair(self):
        for scheduled, want in ((False, [0, 0]), (True, [1, 1])):
            seen, pending = [], ["a", "b"]
            start = lambda x: (lambda: seen.append(cand.SCHEDULING._running) or x)
            with tempfile.TemporaryDirectory() as t:
                run = lambda: loop._rolling(pending, 1, lambda running: list(pending), start, lambda x, r: None, lambda: False,
                                            lambda x: (Path(t) / x, []), scheduled=scheduled)
                if scheduled:
                    run()
                else:
                    with mock.patch.object(cand.SCHEDULING, "task", side_effect=AssertionError("counted without label_repair")):
                        run()
            self.assertEqual(seen, want)
            self.assertEqual(cand.SCHEDULING._running, 0)

    def test_label_repair_needs_labels_feedback_and_a_dataset(self):
        base = dict(run_id="t", laws=Path("l"), ontology=Path("o"), reading=Path("r"))
        with self.assertRaisesRegex(SystemExit, "label_repair"):
            loop.check_options(Options(**base, feedback="review", label_repair=True, label_dataset="d"))
        with self.assertRaisesRegex(SystemExit, "label_repair"):
            loop.check_options(Options(**base, feedback="labels", label_repair=True))
        loop.check_options(Options(**base, feedback="labels", label_repair=True, label_dataset="d"))


if __name__ == "__main__":
    unittest.main()
