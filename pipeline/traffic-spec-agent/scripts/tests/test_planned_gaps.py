"""A record that carries a gap is never coded or accepted.

The real loop (`test_recovery`'s scripted world): a validated record with a gap is not coded, each
of its gaps is filed in the gap ledger on the occurrence of its words, and its law is blocked on
them once the law's other nodes of the iteration are integrated; a node of the same law without a gap
is coded as usual; a node repair's record with a gap goes the same way; a gap matching one the
operator already decided is not filed again, and the law goes back to its planner with the decision;
the coder's two declarations of an unstatable span still file their gap. A candidate change whose
record carries a gap is refused. A record that withdraws a gap of the ledger (carries its words
without it) names the operator's decision in `gap_resolutions`, else it is returned."""
import copy
import json
import tempfile
import unittest
from pathlib import Path
from unittest import mock

from harness.checks import gate, validate_a
from harness.model import corpus
from harness.model.blueprint import Node
from harness.model.mapping import MappingIndex
from harness.model.reading import Reading
from harness.phases import candidate as cand, review as review_phase, validate as validate_phase
from harness.store import paths
from harness.store.gaps import GapLedger
from scripts.tests import test_recovery as rec
from scripts.tests.test_candidate import Base, Txn, files, node_rec, standard, world, NN, CB
from scripts.tests.test_review_routing import ONTO

TEXT = "shall stop. shall yield."
GAP = {"span": "s1", "kind": "atom", "proposal": "| `ru.disabled_test` | a vehicle that cannot move |", "nearest": ["kin.speed"]}


def gapped(nid: str, law: str, text: str = "shall stop.") -> dict:
    n = rec.node(nid, text, law)
    n["gaps"] = [copy.deepcopy(GAP)]
    return n


def pair(law: str) -> tuple[dict, dict]:
    """Two nodes of one law: o1 carries a gap on its obligation, o2 carries none."""
    o1, o2 = rec.node(f"{law.replace('-', '_')}_o1", TEXT, law), rec.node(f"{law.replace('-', '_')}_o2", TEXT, law)
    o1["segmentation"] = [{"id": "s1", "role": "obligation", "text": "shall stop."}, {"id": "s2", "role": "sibling", "text": "shall yield."}]
    o2["segmentation"] = [{"id": "s1", "role": "sibling", "text": "shall stop."}, {"id": "s2", "role": "obligation", "text": "shall yield."}]
    o2["elements"] = [{"span": "s2", "atoms": ["kin.speed"], "derived": [], "justification": "j"}]
    o1["gaps"] = [copy.deepcopy(GAP)]
    return o1, o2


def occurrence(law: str, text: str, start: int, end: int) -> str:
    return f"{law}@{review_phase.law_digest(text)}:{start}-{end}"


def planned_gap() -> rec.World:
    """L-20's only node carries a gap."""
    w = rec.World({"L-20": "shall stop."})
    w.plans = {"L-20": [gapped("L_20", "L-20")]}
    return w


def sibling_without_gap() -> rec.World:
    """L-21's o1 carries a gap, its o2 none."""
    w = rec.World({"L-21": TEXT})
    w.plans = {"L-21": list(pair("L-21"))}
    return w


def repaired_with_gap() -> rec.World:
    """L-22's node is returned by its gate; its repair hands back a record that carries a gap."""
    w = rec.World({"L-22": "shall stop."})
    w.plans = {"L-22": [rec.node("L_22", "shall stop.", "L-22")]}
    w.gate[("L_22", 1)] = "CHECK_FAIL"
    w.node_repair[("L_22", 2)] = gapped("L_22", "L-22")
    return w


def gaps_of(f) -> list[dict]:
    return GapLedger(paths.GAPS_DIR).rows


class Registration(rec.Interruptions, unittest.TestCase):
    """The loop: a record with a gap is filed and blocks its law, at every stop and resume."""

    def test_a_planned_gap_is_filed_and_blocks_the_law_and_nothing_is_coded(self):
        ref, _n = self.interrupt_everywhere(planned_gap, never=[("code", "L_20", 1), ("code", "L_20", 2), ("code", "L_20", 3)])
        led = {e["law"]: e for e in ref["ledger"]}
        self.assertEqual((led["L-20"]["state"], led["L-20"]["gaps"]), ("blocked", ["G1"]))
        self.assertEqual(ref["accepted_nodes"], {})
        self.assertEqual(ref["library"], [])
        row = json.loads(ref["gaps"][0])
        self.assertEqual((row["id"], row["kind"], row["span"], row["law_refs"], row["node_id"]), ("G1", "atom", "shall stop.", ["L-20"], "L_20"))
        self.assertEqual(row["occurrence"], occurrence("L-20", "shall stop.", 0, 11))
        self.assertTrue(any("G1" in l and "`L-20`" in l for l in ref["to_user"]))
        self.assertFalse(any("no gap is filed" in l for l in ref["to_user"]))

    def test_a_sibling_without_a_gap_is_coded_and_accepted(self):
        ref, _n = self.interrupt_everywhere(sibling_without_gap, never=[("code", "L_21_o1", 1)])
        led = {e["law"]: e for e in ref["ledger"]}
        self.assertEqual((led["L-21"]["state"], led["L-21"]["gaps"]), ("blocked", ["G1"]))
        self.assertEqual(sorted(ref["accepted_nodes"]), ["L_21_o2"])
        self.assertEqual([json.loads(g)["occurrence"] for g in ref["gaps"]], [occurrence("L-21", TEXT, 0, 11)])

    def test_a_node_repair_record_with_a_gap_is_filed_and_blocks_the_law(self):
        ref, _n = self.interrupt_everywhere(repaired_with_gap, never=[("code", "L_22", 2), ("code", "L_22", 3)])
        led = {e["law"]: e for e in ref["ledger"]}
        self.assertEqual((led["L-22"]["state"], led["L-22"]["gaps"]), ("blocked", ["G1"]))
        self.assertEqual(ref["accepted_nodes"], {})
        self.assertEqual(json.loads(ref["gaps"][0])["occurrence"], occurrence("L-22", "shall stop.", 0, 11))

    def test_a_gap_the_operator_decided_is_not_filed_again_and_the_law_goes_back_with_the_decision(self):
        w = planned_gap()
        w.plans = {("L-20", 1): [gapped("L_20", "L-20")], ("L-20", 2): [gapped("L_20", "L-20")],
                   ("L-20", 3): [rec.node("L_20", "shall stop.", "L-20")]}
        with rec.Fixture(w) as f:
            f.drive()
            self.assertEqual([r["id"] for r in gaps_of(f)], ["G1"])
            GapLedger(paths.GAPS_DIR).decide("G1", "rejected", "read the words through the halt", resolved_by="particular")
            f.drive(max_iterations=2)
            back = next(e for e in f.state()["ledger"] if e["law"] == "L-20")
            f.drive(max_iterations=5)
            st = f.state()
            rows = gaps_of(f)
        self.assertEqual([r["id"] for r in rows], ["G1"])                       # the plan's repeat is not filed again
        self.assertEqual((w.calls[("code", "L_20", 1)], w.calls[("code", "L_20", 2)], w.calls[("code", "L_20", 3)]), (0, 0, 1))
        law = next(e for e in st["ledger"] if e["law"] == "L-20")
        self.assertEqual(law["state"], "accepted")
        self.assertIn("L_20", st["accepted_nodes"])
        self.assertEqual((back["state"], back["gaps"]), ("returned", []))
        self.assertTrue(any("gap G1" in r and "which the operator rejected: read the words through the halt" in r for r in back["reasons"]),
                        back["reasons"])

    def test_two_declarations_of_an_unstatable_span_still_file_its_gap(self):
        w = rec.World({"L-23": "shall stop."})
        w.plans = {"L-23": [rec.node("L_23", "shall stop.", "L-23")]}
        unexpressed = gate.Verdict("UNEXPRESSED", ["scripted UNEXPRESSED"],
                                   extras={"unexpressed": [{"span": "s1", "kind": "no_atom", "why": "no atom carries the words"}]})
        with rec.Fixture(w) as f:
            prev = gate.run_gate

            def run_gate(n, reading, baseline, d, *a, **k):
                return unexpressed if "admission" not in Path(d).parts else prev(n, reading, baseline, d, *a, **k)
            f.stack.enter_context(mock.patch.object(gate, "run_gate", run_gate))
            f.drive()
            st = f.state()
        law = next(e for e in st["ledger"] if e["law"] == "L-23")
        self.assertEqual((law["state"], law["gaps"]), ("blocked", ["G1"]))
        row = json.loads(st["gaps"][0])
        self.assertEqual((row["kind"], row["proposal"], row["occurrence"]),
                         ("atom", "no atom carries the words", occurrence("L-23", "shall stop.", 0, 11)))
        self.assertEqual((w.calls[("code", "L_23", 1)], w.calls[("code", "L_23", 2)]), (1, 1))
        self.assertTrue(any("two coding sessions declared the span cannot be stated" in l for l in st["to_user"]))


class CandidateRefusal(Base):
    def test_a_node_change_whose_record_carries_a_gap_is_refused(self):
        concepts, nodes = standard()
        with world(concepts, nodes) as (run, _lib):
            with Txn(run) as txn:
                with self.assertRaisesRegex(cand.ChangeRefused, r"carries a gap on span\(s\) \['o1'\]"):
                    txn.apply([cand.Change("node", NN, node_rec(NN, [CB], gaps=[{"span": "o1", "kind": "atom", "proposal": "x",
                                                                                   "nearest": ["kin.speed"]}]), files("node", NN, "v2"))])
                txn.apply([cand.Change("node", NN, node_rec(NN, [CB]), files("node", NN, "v2"))])    # without the gap it is applied


LAW = corpus.Law(id="L-30", title="L-30", text="A disabled vehicle shall stop.", source="s")
DISABLED = (2, 18)        # "disabled vehicle"


def withdrawing(**over) -> dict:
    """A record of L-30 that carries the words of the gap filed on characters 2–18 with an atom."""
    r = {"node_id": "L_30", "law_refs": ["L-30"], "subject": {"binder": "v", "class_elements": ["ru.motor_vehicle"]},
         "binders": [{"name": "v", "class_elements": ["ru.motor_vehicle"]}],
         "segmentation": [{"id": "s0", "role": "boilerplate", "text": "A "}, {"id": "s1", "role": "subject", "text": "disabled vehicle"},
                          {"id": "s2", "role": "obligation", "text": " shall stop."}],
         "elements": [{"span": "s1", "atoms": ["kin.speed"], "derived": [], "justification": "j"},
                      {"span": "s2", "atoms": ["kin.speed"], "derived": [], "justification": "j"}],
         "applicability": "a", "obligation": "o", "params": [], "scenarios": [{"name": "forbid", "expected": "violated", "narrative": "n"}]}
    r.update(over)
    return r


def ledger_row(gid="G7", state="rejected", law="L-30", at=DISABLED) -> dict:
    return {"id": gid, "kind": "atom", "span": "disabled vehicle", "law_refs": [law], "state": state,
            "occurrence": f"{law}@{review_phase.law_digest(LAW.text)}:{at[0]}-{at[1]}"}


RESOLVED = [{"gap": "G7", "span": "s1", "basis": "the operator's reading: a vehicle that cannot move under its own power"}]


class Withdrawal(unittest.TestCase):
    def check(self, raw, rows):
        return validate_a.check_gap_resolutions(Node(raw), LAW.text, rows)

    def test_a_decided_gap_named_in_gap_resolutions_is_withdrawn(self):
        self.assertEqual(self.check(withdrawing(gap_resolutions=RESOLVED), [ledger_row()]), [])
        self.assertEqual(self.check(withdrawing(gap_resolutions=RESOLVED), [ledger_row(state="retired")]), [])

    def test_the_whole_validator_accepts_it(self):
        with tempfile.TemporaryDirectory() as t:
            (Path(t) / "reading.json").write_text('{"params":[],"aggregates":[]}')
            args = ([Node(withdrawing(gap_resolutions=RESOLVED))], {LAW.id: LAW}, ONTO, Reading(Path(t) / "reading.json"),
                    MappingIndex(Path(t) / "none.json"), {})
            ok = validate_a.validate(*args, ledger_gaps=[ledger_row()])[0]
            args = (([Node(withdrawing())],) + args[1:])
            missing = validate_a.validate(*args, ledger_gaps=[ledger_row()])[0]
        self.assertFalse([r for r in ok.reasons if "gap" in r], ok.reasons)
        self.assertEqual(missing.kind, validate_a.RETURN)
        self.assertTrue(any("gap_resolutions" in r and "G7" in r for r in missing.reasons), missing.reasons)

    def test_a_withdrawal_without_its_entry_is_returned(self):
        errs = self.check(withdrawing(), [ledger_row()])
        self.assertEqual(len(errs), 1)
        self.assertIn("G7", errs[0]); self.assertIn("gap_resolutions", errs[0]); self.assertIn("['s1']", errs[0])
        self.assertTrue(self.check(withdrawing(gap_resolutions=[{**RESOLVED[0], "basis": " "}]), [ledger_row()]))
        self.assertTrue(self.check(withdrawing(gap_resolutions=[{**RESOLVED[0], "span": "s2"}]), [ledger_row()]))

    def test_an_undecided_gap_cannot_be_withdrawn(self):
        for state in ("proposed", "accepted"):
            errs = self.check(withdrawing(), [ledger_row(state=state)])
            self.assertTrue(errs and "not decided" in errs[0], errs)
            errs = self.check(withdrawing(gap_resolutions=RESOLVED), [ledger_row(state=state)])
            self.assertTrue(any("has not decided" in e for e in errs), errs)

    def test_an_entry_naming_an_unknown_gap_or_another_laws_gap_is_returned(self):
        errs = self.check(withdrawing(gap_resolutions=[{**RESOLVED[0], "gap": "G99"}]), [ledger_row()])
        self.assertTrue(any("G99" in e and "no gap of the ledger" in e for e in errs), errs)
        errs = self.check(withdrawing(gap_resolutions=RESOLVED), [ledger_row(law="L-31")])
        self.assertTrue(any("not on this law" in e for e in errs), errs)

    def test_a_record_that_keeps_the_gap_or_does_not_carry_the_words_asks_nothing(self):
        keeps = withdrawing(gaps=[{"span": "s1", "kind": "atom", "proposal": "p", "nearest": ["kin.speed"]}])
        self.assertEqual(self.check(keeps, [ledger_row()]), [])
        sibling = withdrawing(segmentation=[{"id": "s0", "role": "boilerplate", "text": "A "},
                                            {"id": "s1", "role": "sibling", "text": "disabled vehicle"},
                                            {"id": "s2", "role": "obligation", "text": " shall stop."}],
                              elements=[{"span": "s2", "atoms": ["kin.speed"], "derived": [], "justification": "j"}])
        self.assertEqual(self.check(sibling, [ledger_row()]), [])
        self.assertEqual(self.check(withdrawing(), [ledger_row(at=(0, 2))]), [])            # words the record does not carry

    def test_a_fresh_run_asks_nothing(self):
        self.assertEqual(self.check(withdrawing(), []), [])

    def test_the_run_validator_reads_the_ledger_rows(self):
        seen = {}

        def validate(*a, **k):
            seen["rows"] = k.get("ledger_gaps")
            return []
        with tempfile.TemporaryDirectory() as t, mock.patch.object(paths, "GAPS_DIR", Path(t) / "gaps"), \
                mock.patch.object(validate_a, "validate", validate), mock.patch.object(validate_a, "validate_concepts", lambda *a, **k: []):
            led = GapLedger(Path(t) / "gaps")
            (Path(t) / "gaps").mkdir()
            with mock.patch.object(GapLedger, "_measure", staticmethod(lambda row, run: None)):
                gid = led.add({"span": "s1", "kind": "atom", "span_text": "w", "law_refs": ["L-30"]}, "earlier", 1)
            (Path(t) / "blueprint.jsonl").write_text("")
            validate_phase.validate_a_for_run(None, Path(t), {}, None, [], onto=ONTO)
        self.assertEqual([r["id"] for r in seen["rows"]], [gid])

    def test_the_schema_reads_gap_resolutions(self):
        self.assertEqual(validate_a.schema_errors("L_30", withdrawing(gap_resolutions=RESOLVED), validate_a.NODE_SCHEMA), [])
        self.assertTrue(validate_a.schema_errors("L_30", withdrawing(gap_resolutions=[{"gap": "G7"}]), validate_a.NODE_SCHEMA))


class WithdrawalAcceptance(unittest.TestCase):
    """The operator's acceptance cases for withdrawing a gap, each through the whole validator: a
    returned record is never accepted. `gap_resolutions` proves only the link between the operator's
    decision and the record, never that the new formula is semantically right: the validator checks
    no semantics, and the same record with the same atoms passes or is returned on its links alone."""

    def outcome(self, raw, rows):
        with tempfile.TemporaryDirectory() as t:
            (Path(t) / "reading.json").write_text('{"params":[],"aggregates":[]}')
            return validate_a.validate([Node(raw)], {LAW.id: LAW}, ONTO, Reading(Path(t) / "reading.json"),
                                       MappingIndex(Path(t) / "none.json"), {}, ledger_gaps=rows)[0]

    def assertReturned(self, raw, rows, words):
        out = self.outcome(raw, rows)
        self.assertEqual(out.kind, validate_a.RETURN, out.reasons)
        self.assertTrue(any(words in r for r in out.reasons), out.reasons)

    def assertPasses(self, raw, rows):
        out = self.outcome(raw, rows)
        self.assertFalse([r for r in out.reasons if "gap" in r], out.reasons)

    def test_1_an_undecided_gap_dropped_with_or_without_an_entry_is_returned(self):
        for state in ("proposed", "accepted"):
            self.assertReturned(withdrawing(), [ledger_row(state=state)], "has not decided it")
            self.assertReturned(withdrawing(gap_resolutions=RESOLVED), [ledger_row(state=state)], "has not decided")

    def test_2_only_the_entry_naming_the_gap_on_those_words_passes(self):
        for state in ("retired", "rejected"):
            here = ledger_row(state=state)
            other_law = ledger_row("G8", state=state, law="L-31")
            other_place = ledger_row("G9", state=state, at=(19, 30))         # " shall stop.", carried by s2
            rows = [here, other_law]
            self.assertReturned(withdrawing(gap_resolutions=[{**RESOLVED[0], "gap": "G8"}]), rows, "not on this law")
            self.assertReturned(withdrawing(gap_resolutions=[{**RESOLVED[0], "gap": "G9"}]), [here, ledger_row("G9", state=state, at=(0, 2))],
                                "does not hold the words the gap was filed on")
            self.assertReturned(withdrawing(gap_resolutions=[{**RESOLVED[0], "gap": "G9"}]), [here, ledger_row("G9", state=state, at=(0, 2))],
                                "name it in `gap_resolutions`")
            self.assertReturned(withdrawing(), rows, "name it in `gap_resolutions`")
            self.assertReturned(withdrawing(gap_resolutions=[{**RESOLVED[0], "basis": ""}]), rows, "states no `basis`")
            self.assertPasses(withdrawing(gap_resolutions=RESOLVED), rows)
            both = [RESOLVED[0], {"gap": "G9", "span": "s2", "basis": "the operator's reading"}]
            self.assertPasses(withdrawing(gap_resolutions=both), [here, other_place])
            self.assertReturned(withdrawing(gap_resolutions=[RESOLVED[0], {"gap": "G9", "span": "s1", "basis": "b"}]), [here, other_place],
                                "does not hold the words the gap was filed on")


if __name__ == "__main__":
    unittest.main()
