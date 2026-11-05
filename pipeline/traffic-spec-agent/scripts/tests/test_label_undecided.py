"""An unknown the library could decide reaches a repair: a law whose plain-labelled recording is
unknown with a blocker that points at the library is `undecided` and awaits a coverage repair; an
unknown that only data, the time contract or the harness can remove leaves the law unverified; a
judgment call never makes a law undecided; a failure keeps the law `failed` and still counts the
recording the library could decide; a coverage repair that turns the unknown into a mismatch has met
its goal, and the law then awaits a semantic repair, never aligned by it.

The candidate, the hooks, the ledger and the routing are the real ones; the monitor is the label
check's stand-in, whose groundings carry the reasons given here."""
import json
import unittest
from contextlib import contextmanager
from unittest import mock

from harness import loop
from harness.agents import session
from harness.phases import label_check
from harness.phases import label_repair as lr
from harness.phases import review
from scripts.tests.test_candidate import CA, Base, concept_rec
from scripts.tests.test_label_repair import L, N, RECS, setting
from scripts.tests.test_label_repair_lifecycle import REC5, Responder, reloaded, run_repairs
from scripts.tests.test_label_repair_session import DIFF5, repair, repairing, set_verdict

#: The one reason whose tag alone points at the library: a rule's own division by a term that is zero.
LIBRARY_REASON = ["division_by_zero:div"]


def with_r5a(verdict: str, reasons: list[str], jc: bool = False, label: str = "compliant"):
    """The scenario's recordings with r5a's verdict and reasons replaced, and r5b, r5c dropped."""
    out = []
    for rid, law, lab, j, spec in RECS:
        if rid in ("r5b", "r5c"):
            continue
        if rid == "r5a":
            lab, j, spec = label, jc, {N[5]: [[verdict, {"x": 1}, reasons]]}
        out.append((rid, law, lab, j, spec))
    return out


class Outcome(Base):

    def route(self, recs):
        with setting(recs) as (run, ledger, training, _t):
            loop.label_route(run, ledger, training, [])
            st = run.label_states[L[5]]
            st = {**st, "actionable": json.loads((run.dir / st["check"]).read_text())["summary"]["library_actionable"]}
            return st, (run.dir / st["evidence"]).read_text()

    def test_an_unknown_the_library_could_decide_awaits_a_coverage_repair(self):
        st, evidence = self.route(with_r5a("unknown", LIBRARY_REASON))
        self.assertEqual((st["outcome"], st["state"], st["actionable"]),
                         ("undecided", "awaiting_label_repair", 1))
        self.assertIn("Repair goal: coverage", evidence)
        self.assertIn("rule_semantic, library", evidence)

    def test_an_unknown_only_data_or_a_window_can_remove_leaves_the_law_unverified(self):
        for reasons in (["absent_atom:st_highway"], ["window_truncated:holdsFor"], ["parameter_missing:p.x"],
                        ["undefined:prim_region_offset_along"], []):
            with self.subTest(reasons=reasons):
                st, evidence = self.route(with_r5a("unknown", reasons))
                self.assertEqual((st["outcome"], st["state"]), ("unverified", "accepted"))

    def test_mixed_reasons_go_to_the_repair_and_keep_their_data_side(self):
        st, evidence = self.route(with_r5a("unknown", LIBRARY_REASON + ["window_truncated:holdsFor"]))
        self.assertEqual(st["outcome"], "undecided")
        self.assertIn("history, time_contract", evidence)

    def test_a_judgment_call_never_makes_a_law_undecided(self):
        st, _ = self.route(with_r5a("unknown", LIBRARY_REASON, jc=True, label="violation"))
        self.assertNotEqual(st["outcome"], "undecided")

    def test_a_failure_keeps_the_law_failed_and_counts_what_the_library_could_decide(self):
        recs = with_r5a("unknown", LIBRARY_REASON) + [("r5f", L[5], "compliant", False, {"fail": "crash"})]
        st, _ = self.route(recs)
        self.assertEqual((st["outcome"], st["actionable"]), ("failed", 1))


class CoverageRepair(Base):

    def test_an_unknown_turned_mismatch_meets_coverage_and_then_awaits_a_semantic_repair(self):
        with repairing(recs=with_r5a("unknown", LIBRARY_REASON)) as (run, ledger, training, by_id):
            self.assertEqual(run.label_states[L[5]]["outcome"], "undecided")
            resp = Responder({"record.jsonl": REC5, "lean.diff": DIFF5}, {"record.jsonl": REC5})
            with mock.patch.object(session, "run", resp):
                set_verdict(training, "r5a", N[5], "violated")              # decided now, but against its label
                first = repair(run, ledger, training, by_id)
                st, routed = dict(run.label_states[L[5]]), ledger.entries[L[5]].state
                prompt1 = next(run.dir.glob("iter-*/label_repair/*/repair-01/prompt.md")).read_text()
                set_verdict(training, "r5a", N[5], "compliant")
                second = repair(run, ledger, training, by_id)
            self.assertIn("Repair goal: coverage", prompt1)
            self.assertEqual(first, "committed")
            self.assertEqual((st["outcome"], st["state"], routed), ("mismatch", "awaiting_label_repair", "planned"))  # progress, never alignment
            prompt2 = next(run.dir.glob("iter-*/label_repair/*/repair-02/prompt.md")).read_text()
            self.assertIn("Repair goal: labelled semantic", prompt2)
            self.assertEqual((second, run.label_states[L[5]]["outcome"]), ("committed", "aligned"))

    def test_a_coverage_repair_that_decides_nothing_is_rolled_back(self):
        with repairing(recs=with_r5a("unknown", LIBRARY_REASON)) as (run, ledger, training, by_id):
            with mock.patch.object(session, "run", Responder({"record.jsonl": REC5, "lean.diff": DIFF5})):
                self.assertEqual(repair(run, ledger, training, by_id), "rolled_back")
            st = run.label_states[L[5]]
            self.assertEqual(st["outcome"], "undecided")
            self.assertTrue(any("repair goal `coverage` not met" in d for f in st["last_repair"]["failed"] for d in f.get("details", [])),
                            st["last_repair"])


class UndecidedLifecycle(Base):

    def test_a_pending_repair_of_an_undecided_law_is_taken_up_from_the_snapshot_with_one_session(self):
        report = {"node_id": N[5], "withdraw": {"kind": "concept", "missing": "wrong body"}}
        resp = Responder({"record.jsonl": json.dumps(report), "dependency_defect.json": "{}"})
        deferred = review.DependencyReport("deferred", CA, ["retry later"])
        with repairing(recs=with_r5a("unknown", LIBRARY_REASON), concepts={CA: concept_rec(CA)}, uses={N[5]: [CA]}) as (run, ledger, training, by_id), \
                mock.patch.object(session, "run", resp), mock.patch.object(review, "dependency_report", lambda *a, **k: deferred):
            run_repairs(run, ledger, training, by_id)
            fresh, ledger2 = reloaded(run, ledger, 2)
            run_repairs(fresh, ledger2, training, by_id)
            st = fresh.label_states[L[5]]
            self.assertEqual((len(resp.calls), st["outcome"], lr.used(fresh), st["active"]["stage"], len(st["reports"])),
                             (1, "undecided", 0, "report", 1))

    @contextmanager
    def _shared(self, r1a_was_match: bool):
        """A repair of law 5 whose node law 1 composes, after which law 1's r1a is unknown for a reason
        the library could decide; before it, r1a was a match or unknown for a reason it could not."""
        recs = [(rid, law, label, jc, spec if rid != "r1a" or r1a_was_match else {N[1]: [["unknown", {"x": 1}, []]]})
                for rid, law, label, jc, spec in RECS]
        with repairing(recs=recs, outputs={"record.jsonl": REC5, "lean.diff": DIFF5}) as (run, ledger, training, by_id):
            run.accepted_nodes[N[1]]["compositions"] = [{"span": "o1", "rule": N[5], "map": {"v": "v"}, "as": "condition"}]
            set_verdict(training, "r5a", N[5], "compliant")
            f = training.dataset.path / "recordings" / "r1a" / "fake.json"
            f.write_text(json.dumps({**json.loads(f.read_text()), N[1]: [["unknown", {"x": 1}, LIBRARY_REASON]]}))
            yield run, ledger, training, by_id

    def test_a_shared_repair_that_makes_another_law_undecided_routes_it_to_its_coverage_repair(self):
        with self._shared(False) as (run, ledger, training, by_id):
            self.assertEqual(run.label_states[L[1]]["outcome"], "unverified")
            self.assertEqual(repair(run, ledger, training, by_id), "committed")
            st = run.label_states[L[1]]
            self.assertEqual((st["outcome"], st["state"], ledger.entries[L[1]].state), ("undecided", "awaiting_label_repair", "planned"))
            self.assertIn(L[1], lr.awaiting(run, ledger))

    def test_a_shared_repair_that_turns_another_laws_match_unknown_is_rolled_back_whole(self):
        with self._shared(True) as (run, ledger, training, by_id):
            rule = lr.paths.LIBRARY / lr.candidate_phase.own_files("node", N[5])[0]
            before = rule.read_text()
            self.assertEqual(repair(run, ledger, training, by_id), "rolled_back")
            self.assertEqual((run.label_states[L[1]]["outcome"], run.label_states[L[1]]["state"], ledger.entries[L[1]].state),
                             ("aligned", "accepted", "accepted"))
            self.assertEqual(rule.read_text(), before)


if __name__ == "__main__":
    unittest.main()
