"""Harness fixes after the full221 run: the scope digest leaves the launcher's local logs out; a law
whose only defect is a composed rule of a law waiting for the operator is held on that law, its
reference counted as carried; an obligation that only a law outside the corpus fills is filed by
the harness as a scope gap, which blocks its law while the law's other nodes are coded and kept; an
admitted aggregate replaced by a class atom goes back to the planner;
a live gap whose span contains a carried-over pending gap's (or lies within it) is reported as a
candidate link; and the operator's view groups the run's gaps by the name they propose and lists
the phrases the run carries in more than one way."""
import json
import tempfile
import unittest
from pathlib import Path
from types import SimpleNamespace
from unittest import mock

from harness import loop
from harness.checks import gate, validate_a
from harness.model import nodeid
from harness.model.blueprint import GAP_KINDS, SCOPE_GAP, Node
from harness.model.corpus import Law
from harness.phases import observable_view
from harness.store import deferred_gaps, paths
from harness.store.ledger import Ledger
from scripts.tests import test_recovery as rec


class RuntimeLogsAreNotTheTree(unittest.TestCase):
    def test_a_task_writing_only_under_runtime_is_in_scope_and_a_library_change_is_not(self):
        with tempfile.TemporaryDirectory() as t:
            root = Path(t)
            (root / "library" / "TrafficSpec").mkdir(parents=True)
            (root / "library" / "TrafficSpec" / "A.lean").write_text("a")
            work = root / "results" / "r" / "iter-001" / "code" / "N"
            work.mkdir(parents=True)
            with mock.patch.object(paths, "REPO", root):
                baseline = gate.repo_digest()
                (root / ".runtime" / "tmp" / "claude-1").mkdir(parents=True)
                (root / ".runtime" / "tmp" / "claude-1" / "task.output").write_text("stream")
                self.assertEqual(gate.scope_stray(baseline, set(), work), [])
                (root / "library" / "TrafficSpec" / "A.lean").write_text("changed")
                self.assertEqual(gate.scope_stray(baseline, set(), work), ["library/TrafficSpec/A.lean"])


EXCEPT = Law("X-1-a", "t", "Except as otherwise provided in paragraph (b) [X-1-b], a driver shall stop.", "s")


def excepting_node(rule: str) -> Node:
    return Node({"node_id": "X_1_a", "law_refs": ["X-1-a"],
                 "segmentation": [{"id": "s1", "text": "Except as otherwise provided in paragraph (b) [X-1-b],", "role": "reference"},
                                  {"id": "s2", "text": "a driver", "role": "subject"},
                                  {"id": "s3", "text": "shall stop.", "role": "obligation"}],
                 "compositions": [{"span": "s1", "rule": rule, "map": {"subject": "subject"}, "as": "exception"}]})


class HeldOnAnUnavailableProvider(unittest.TestCase):
    def test_an_unknown_rule_of_the_named_law_is_its_own_defect_and_carries_the_reference(self):
        n = excepting_node("X_1_b")
        self.assertEqual(validate_a.check_reference_positions(n, EXCEPT, {"X-1-a", "X-1-b"}, {}, [n]), [])
        self.assertEqual(validate_a.check_compositions(n, {}), [validate_a.unknown_target("X_1_a", "X_1_b")])

    def test_a_composition_of_another_law_still_leaves_the_reference_uncarried(self):
        n = excepting_node("Y_2")
        errs = validate_a.check_reference_positions(n, EXCEPT, {"X-1-a", "X-1-b", "Y-2"}, {}, [n])
        self.assertTrue(errs and "names X-1-b" in errs[0], errs)

    def test_the_law_is_blocked_on_the_provider_gaps_and_waits_on_it(self):
        with tempfile.TemporaryDirectory() as t:
            led = Ledger(Path(t) / "ledger.jsonl", ["X-1-a", "X-1-b"], 2)
            led.attempt = 3
            led.block("X-1-b", ["G7"], ["withdrawn as a gap"])
            n = excepting_node("X_1_b")
            reasons = validate_a.check_compositions(n, {}) + validate_a.check_reference_positions(n, EXCEPT, {"X-1-a", "X-1-b"}, {}, [n])
            unavail = loop.unavailable_rules([n], led, lambda i: nodeid.law_of(i)[0], {}, set())
            self.assertEqual(unavail, {"X_1_b": {"X-1-b"}})
            self.assertEqual([r for r in reasons if not ((m := validate_a.UNKNOWN_TARGET.match(r)) and m["rule"] in unavail)], [])
            loop.hold_on_unavailable(led, "X-1-a", unavail, [], "X-1-a", [], [], "run")
            e = led.entries["X-1-a"]
            self.assertEqual((e.state, e.gaps, e.waits_on, e.attempts), ("blocked", ["G7"], ["X-1-b"], 0))


DUTY = Law("X-2-b", "t", "If the vehicle stops, the driver shall proceed as required pursuant to NRS 9.9 [OUT-9-1a, OUT-9-1b].", "s")


def duty_node(reference_role: str = "reference", residue: bool = True) -> Node:
    return Node({"node_id": "X_2_b_o2", "law_refs": ["X-2-b"],
                 "segmentation": [{"id": "s1", "text": "If the vehicle stops,", "role": "condition"},
                                  {"id": "s2", "text": "the driver shall", "role": "subject"},
                                  {"id": "s3", "text": "proceed", "role": "obligation"},
                                  {"id": "s4", "text": "as required pursuant to NRS 9.9 [OUT-9-1a, OUT-9-1b].", "role": reference_role}],
                 "elements": [{"span": "s3", "atoms": ["kin.speed"]}],
                 "residues": [{"span": "s4", "why": "outside the corpus"}] if residue else []})


class DutyOnlyALawOutsideTheCorpusFills(unittest.TestCase):
    def test_the_harness_files_a_scope_gap_on_the_obligation(self):
        gaps = validate_a.outside_duty_gaps(duty_node(), DUTY, {"X-2-b"})
        self.assertEqual([(g["span"], g["kind"]) for g in gaps], [("s3", SCOPE_GAP)])
        self.assertIn("OUT-9-1a", gaps[0]["proposal"]); self.assertIn("scope decision", gaps[0]["proposal"])

    def test_a_named_law_in_the_corpus_or_no_residue_reference_files_none(self):
        self.assertEqual(validate_a.outside_duty_gaps(duty_node(), DUTY, {"X-2-b", "OUT-9-1a"}), [])
        self.assertEqual(validate_a.outside_duty_gaps(duty_node(residue=False), DUTY, {"X-2-b"}), [])

    def test_an_obligation_of_its_own_beside_the_reference_files_none(self):
        law = Law("X-3", "t", "The driver shall stop and proceed as required pursuant to NRS 9.9 [OUT-9-1a].", "s")
        n = Node({"node_id": "X_3", "law_refs": ["X-3"],
                  "segmentation": [{"id": "s1", "text": "The driver shall", "role": "subject"},
                                   {"id": "s2", "text": "stop", "role": "obligation"},
                                   {"id": "s3", "text": "and proceed", "role": "obligation"},
                                   {"id": "s4", "text": "as required pursuant to NRS 9.9 [OUT-9-1a].", "role": "reference"}],
                  "residues": [{"span": "s4", "why": "outside the corpus"}]})
        self.assertEqual(validate_a.outside_duty_gaps(n, law, {"X-3"}), [])

    def test_a_plan_cannot_propose_a_scope_gap_itself(self):
        self.assertNotIn(SCOPE_GAP, GAP_KINDS)


SCOPE_TEXT = "shall stop. shall proceed as required pursuant to NRS 9.9 [OUT-9-1a]."


def scope_world() -> rec.World:
    """L-31's o1 states its own duty; its o2's duty is given only by a law outside the corpus, for which
    the validator files a scope gap."""
    w = rec.World({"L-31": SCOPE_TEXT})
    o1, o2 = rec.node("L_31_o1", SCOPE_TEXT, "L-31"), rec.node("L_31_o2", SCOPE_TEXT, "L-31")
    o1["segmentation"] = [{"id": "s1", "role": "obligation", "text": "shall stop."},
                          {"id": "s2", "role": "sibling", "text": "shall proceed"},
                          {"id": "s3", "role": "sibling", "text": "as required pursuant to NRS 9.9 [OUT-9-1a]."}]
    o2["segmentation"] = [{"id": "s1", "role": "sibling", "text": "shall stop."},
                          {"id": "s2", "role": "obligation", "text": "shall proceed"},
                          {"id": "s3", "role": "reference", "text": "as required pursuant to NRS 9.9 [OUT-9-1a]."}]
    o2["elements"] = [{"span": "s2", "atoms": ["kin.speed"], "derived": [], "justification": "j"}]
    o2["residues"] = [{"span": "s3", "why": "outside the corpus"}]
    w.plans = {"L-31": [o1, o2]}
    law = Law("L-31", "L-31", SCOPE_TEXT, "s")
    w.filed["L_31_o2"] = validate_a.outside_duty_gaps(Node(o2), law, {"L-31"})
    assert w.filed["L_31_o2"], "the scripted record must be one the validator files a scope gap for"
    return w


class ScopeGapRouting(rec.Interruptions, unittest.TestCase):
    """The loop: the out-of-corpus duty is filed as a scope gap and blocks its law; the law's other
    node is coded and kept; nothing is planned again; the law is reported partially generated."""

    def test_o1_is_kept_o2_never_coded_and_the_law_blocked_at_every_stop(self):
        ref, _n = self.interrupt_everywhere(scope_world, never=[("code", "L_31_o2", k) for k in (1, 2, 3)])
        led = {e["law"]: e for e in ref["ledger"]}
        self.assertEqual((led["L-31"]["state"], led["L-31"]["gaps"]), ("blocked", ["G1"]))
        self.assertEqual(sorted(ref["accepted_nodes"]), ["L_31_o1"])                          # (i) kept
        self.assertNotIn("L_31_o2", ref["accepted_nodes"])                                    # (ii) never accepted
        row = json.loads(ref["gaps"][0])
        self.assertEqual((row["kind"], row["span"], row["node_id"]), (SCOPE_GAP, "shall proceed", "L_31_o2"))

    def test_resumes_plan_it_once_and_report_it_partial_until_decided(self):
        w = scope_world()
        with rec.Fixture(w) as f:
            f.drive()
            f.drive(max_iterations=4)                                                         # (iii) a resume plans nothing again
            plans = [k for k, c in w.calls.items() if k[0] == "plan" and "L-31" in k[1] and c]
            summary = json.loads((paths.RESULTS / "r" / "summary.json").read_text())
        self.assertEqual([k[2] for k in plans], [1])
        gen = summary["generation"]                                                           # (iv) partial, not complete
        self.assertFalse(gen["complete"])
        self.assertEqual((gen["laws"]["blocked"], gen["laws"]["partial"]), ({"L-31": ["G1"]}, {"L-31": ["L_31_o1"]}))
        self.assertNotIn("L-31", gen["laws"]["generated"])


class AdmittedAggregateIsClaimed(unittest.TestCase):
    READING = SimpleNamespace(data={"aggregates": [{"id": "DEF-A-1::electric_scooter", "definition": "DEF-A-1", "term": "electric scooter"},
                                                   {"id": "DEF-A-2::vehicle", "definition": "DEF-A-2", "term": "vehicle"},
                                                   {"id": "DEF-A-3::taxicab", "definition": "DEF-A-3", "term": "taxicab"}]})
    ROWS = [{"term": "electric scooter", "status": "resolved", "definition": "DEF-A-1"},
            {"term": "vehicle", "status": "resolved", "definition": "DEF-A-2"}]

    def node(self, words: str, atoms: list[str]) -> Node:
        return Node({"node_id": "X_4", "law_refs": ["X-4"], "segmentation": [{"id": "s1", "text": words, "role": "subject"}],
                     "elements": [{"span": "s1", "atoms": atoms}]})

    def test_a_class_atom_in_place_of_the_admitted_aggregate_is_returned(self):
        errs = validate_a.check_admitted_aggregates(self.node("an electric scooter", ["ru.electric_scooter"]), self.ROWS, self.READING)
        self.assertEqual(len(errs), 1)
        self.assertIn("DEF-A-1::electric_scooter", errs[0])

    def test_the_claimed_aggregate_a_compound_or_no_resolved_term_passes(self):
        ok = [self.node("an electric scooter", ["ru.aggregate=DEF-A-1::electric_scooter"]),
              self.node("or an official vehicle of an agency", ["ru.official_vehicle"]),
              self.node("other than a City vehicle", ["ru.official_vehicle"]),
              self.node("A traffic incident management vehicle;", ["ru.official_vehicle"]),
              self.node("Any cab,", ["ru.taxicab"])]          # a taxicab aggregate is admitted, but no definition resolves "cab" for the law
        for n in ok:
            self.assertEqual(validate_a.check_admitted_aggregates(n, self.ROWS, self.READING), [], n.spans())
        self.assertEqual(validate_a.check_admitted_aggregates(self.node("an electric scooter", ["ru.electric_scooter"]), [], self.READING), [])

    def test_a_term_is_standalone_between_a_determiner_and_the_end_of_its_phrase(self):
        terms = ["vehicle", "motor vehicle"]
        self.assertEqual(validate_a.standalone_terms("a vehicle which has a permit", terms), {"vehicle"})
        self.assertEqual(validate_a.standalone_terms("any motor vehicle", terms), {"motor vehicle"})
        self.assertEqual(validate_a.standalone_terms("a City vehicle", terms), set())


def row(gid: str, occ: str, kind: str = "atom", **extra) -> dict:
    return {"id": gid, "kind": kind, "occurrence": occ, **extra}


class CandidateLinks(unittest.TestCase):
    DECL = [{"source_run": "old", "source_id": "G21", "occurrence": "L-1@abc:558-618", "kind": "atom", "law": "L-1"},
            {"source_run": "old", "source_id": "G22", "occurrence": "L-2@abc:10-30", "kind": "operator", "law": "L-2"}]

    def test_a_contained_span_of_one_kind_and_text_is_a_candidate(self):
        live = [row("G77", "L-1@abc:562-618")]
        self.assertEqual([(r["id"], d["source_id"]) for r, d in deferred_gaps.candidate_links(live, self.DECL)], [("G77", "G21")])

    def test_other_kind_digest_overlap_or_an_existing_link_is_none(self):
        live = [row("G1", "L-1@abc:562-618", kind="operator"), row("G2", "L-1@fff:562-618"), row("G3", "L-1@abc:600-700"),
                row("G4", "L-2@abc:10-30", kind="operator", deferred_from={"source_run": "old", "source_id": "G22"}),
                row("G5", "L-2@abc:14-18", kind="operator")]
        self.assertEqual(deferred_gaps.candidate_links(live, self.DECL), [])


class GapFamiliesAndSharedPhrases(unittest.TestCase):
    def test_the_proposed_name(self):
        cases = {"`st.bicycle_rack` | a fixed stand": "st.bicycle_rack", "ru.on_official_duty | the road user": "ru.on_official_duty",
                 "`Formula.requiredByRuleSet (who : Arg)`: true": "requiredByRuleSet",
                 "`compliesWithEngaged` (Formula.compliesWithEngaged (binder map))": "compliesWithEngaged",
                 "Formula.compliesWithEngaged (who : Arg) (conduct : String)": "compliesWithEngaged",
                 "durationWithin (m : Measure) (d : Term)": "durationWithin", "lawful (who : Arg) — a Formula": "lawful",
                 "a formula form of sig.warning_lamp that reads": "sig.warning_lamp", "An observable road-user class for": ""}
        for text, name in cases.items():
            self.assertEqual(observable_view.proposed_name(text), name, text)
        fam = observable_view.gap_families([{"id": "G1", "proposal": "`x.a` | one"}, {"id": "G2", "proposal": "x.a | two"},
                                            {"id": "G3", "proposal": "A way to write it"}])
        self.assertEqual({k: [g["id"] for g in v] for k, v in fam.items()}, {"x.a": ["G1", "G2"], "": ["G3"]})

    def test_a_phrase_carried_two_ways_lists_every_holder(self):
        def rec(nid, words, gap=False):
            return ("x", {"node_id": nid, "segmentation": [{"id": "s1", "text": words, "role": "exception"},
                                                          {"id": "s2", "text": "or in compliance with law", "role": "sibling"}],
                          "gaps": [{"span": "s1"}] if gap else []})
        records = dict([("A", rec("A", "or in compliance with law", gap=True)), ("B", rec("B", "except in compliance with law,")),
                        ("C", rec("C", "unrelated words"))])
        gaps = [{"id": "G65", "node_id": "A", "span": "or in compliance with law", "proposal": "`op` | x"}]
        shared = observable_view.shared_phrases(records, gaps)
        self.assertEqual([e["phrase"] for e in shared], ["in compliance with law"])
        self.assertEqual([(h["node"], h["way"], h["gaps"]) for h in shared[0]["holders"]], [("A", "gap", ["G65"]), ("B", "atoms", [])])
        text = observable_view.render_gap_parts(observable_view.gap_families(gaps), shared)
        self.assertIn("`op`: G65", text); self.assertIn("  - atoms: `B` s1 (exception)", text)

    def test_one_way_everywhere_is_not_listed(self):
        records = {n: ("x", {"node_id": n, "segmentation": [{"id": "s1", "text": "in compliance with law", "role": "exception"}]})
                   for n in ("A", "B")}
        self.assertEqual(observable_view.shared_phrases(records, [{"id": "G1", "node_id": "A", "span": "in compliance with law"}]), [])


if __name__ == "__main__":
    unittest.main()
