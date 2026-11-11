"""One parameter name, one proposal: within an iteration a proposal enters the reading only when its
node is coded, so every node that uses a parameter the reading lacks proposes it in its own
`param_proposals`; a later proposal of a name an earlier node of the plan proposed carries the same
value, unit and convention (whitespace aside), or the later node is returned naming both. The
`source` is not compared. A proposal of a parameter the reading holds, with its value and unit
under another convention, is returned, reviewed or not, and the reading refuses to enter one. The
planner's table of earlier batches' proposals states the rule and shows each convention in full,
escaped for its cell only."""
import json
import re
import tempfile
import unittest
from pathlib import Path
from unittest import mock

from harness.checks import validate_a
from harness.model.blueprint import Node
from harness.model.reading import Reading
from harness.phases import plan as plan_phase

CONV = "Standstill gap of queued vehicles: the clearance between a vehicle halted in a queue and the one ahead of it; car-follow"


def proposal(**kw) -> dict:
    return {"name": "p.gap", "value": 4.0, "unit": "m", "convention": CONV, "source": "car-following practice", **kw}


def node(nid: str, *proposals: dict) -> Node:
    from harness.model.nodeid import law_of
    return Node({"node_id": nid, "law_refs": [law_of(nid)[0]], "params": ["p.gap"],
                 "param_proposals": list(proposals)})


class ProposalIdentity(unittest.TestCase):
    def test_same_proposal_again_passes(self):
        out = validate_a.proposal_conflicts_of([node("A_1", proposal()), node("B_1", proposal(convention="  " + CONV.replace(" ", "\n ") + " "))])
        self.assertEqual(out, {})

    def test_other_value_or_unit_conflicts(self):
        for other in (proposal(value=5.0), proposal(unit="ft")):
            out = validate_a.proposal_conflicts_of([node("A_1", proposal()), node("B_1", other)])
            self.assertEqual(list(out), ["B_1"])
            self.assertIn("node A_1 proposed it as 4.0 m", out["B_1"][0])

    def test_other_convention_conflicts(self):
        out = validate_a.proposal_conflicts_of([node("A_1", proposal()), node("B_1", proposal(convention="the gap kept to a halted vehicle ahead"))])
        self.assertEqual(list(out), ["B_1"])
        msg = out["B_1"][0]
        self.assertIn("node A_1", msg)
        self.assertIn("the gap kept to a halted vehicle ahead", msg)
        self.assertIn("propose the same convention, or use another name for a different meaning", msg)

    def test_other_source_is_no_conflict(self):
        out = validate_a.proposal_conflicts_of([node("A_1", proposal()), node("B_1", proposal(source="another handbook"))])
        self.assertEqual(out, {})


class NamedOnly(unittest.TestCase):
    def test_named_only_is_returned_and_the_table_says_so(self):
        with tempfile.TemporaryDirectory() as t:
            f = Path(t) / "reading.json"
            f.write_text(json.dumps({"params": [], "aggregates": []}))
            errs, _ = validate_a.check_standards(node("B_1"), Reading(f))
        self.assertTrue(any("`p.gap` is in no catalogue and the node proposes none: add it to `param_proposals`" in e for e in errs), errs)
        table = plan_phase.pending_proposals_table([node("A_1", proposal()).raw])
        self.assertIn("proposes it again in its own `param_proposals`, with the same name, value, unit and convention", table)


class Table(unittest.TestCase):
    def test_rule_stated_and_old_wording_gone(self):
        table = plan_phase.pending_proposals_table([node("A_1", proposal()).raw])
        doc = " ".join(plan_phase.pending_proposals_table.__doc__.split())
        self.assertNotIn("name them", table)
        self.assertNotIn("names them instead of proposing again", doc)
        self.assertIn("proposes it again in its own `param_proposals`, under the same name with the same value, unit and convention", doc)

    def test_full_convention_shown(self):
        long_conv = CONV + "; " + "measured bumper to bumper along the lane centre line " * 4
        table = plan_phase.pending_proposals_table([node("A_1", proposal(convention=long_conv)).raw])
        self.assertIn(" ".join(long_conv.split()), table)


class AgainstTheReading(unittest.TestCase):
    """A name the reading holds keeps its one meaning, across iterations."""

    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.path = Path(self.tmp.name) / "reading.json"

    def tearDown(self):
        self.tmp.cleanup()

    def reading(self, **entry) -> Reading:
        self.path.write_text(json.dumps({"params": [{"name": "p.gap", "value": 4, "unit": "m", "convention": "bumper clearance", **entry}],
                                         "aggregates": []}))
        return Reading(self.path)

    def errs(self, n: Node, reading: Reading) -> list[str]:
        return validate_a.check_standards(n, reading)[0]

    def test_other_convention_unreviewed_is_returned(self):
        errs = self.errs(node("B_1", proposal(value=4, convention="time headway")), self.reading(proposed="r/iter-001 A_1"))
        hit = [e for e in errs if "with the convention 'bumper clearance'" in e]
        self.assertEqual(len(hit), 1, errs)
        self.assertIn("name the catalogued parameter as it is, without proposing it, or use another name for a different meaning", hit[0])

    def test_other_convention_own_law_unreviewed_is_returned(self):
        errs = self.errs(node("B_1", proposal(value=4, convention="time headway")), self.reading(proposed="r/iter-001 B_1"))
        self.assertTrue(any("one parameter has one meaning" in e for e in errs), errs)

    def test_other_convention_reviewed_is_returned(self):
        errs = self.errs(node("B_1", proposal(value=4, convention="time headway")), self.reading())
        self.assertTrue(any("one parameter has one meaning" in e for e in errs), errs)

    def test_named_without_proposal_passes(self):
        errs = self.errs(node("B_1"), self.reading())
        self.assertEqual([e for e in errs if "p.gap" in e], [])

    def test_same_proposal_again_passes(self):
        errs = self.errs(node("B_1", proposal(value=4, convention=" bumper\n clearance ")), self.reading())
        self.assertEqual([e for e in errs if "p.gap" in e], [])

    def test_own_value_change_still_allowed(self):
        errs = self.errs(node("B_1", proposal(value=5, convention="bumper clearance")), self.reading(proposed="r/iter-001 B_1_o2"))
        self.assertEqual([e for e in errs if "p.gap" in e], [])

    def test_add_proposals_refuses_another_convention(self):
        self.reading(proposed="r/iter-001 A_1")
        with self.assertRaises(ValueError):
            Reading.add_proposals(self.path, [proposal(value=4, convention="time headway")], "r/iter-002 B_1")
        self.assertEqual(Reading(self.path).params["p.gap"]["convention"], "bumper clearance")
        self.assertEqual(Reading.add_proposals(self.path, [proposal(value=4, convention="bumper  clearance")], "r/iter-002 B_1"), [])

    def test_across_iterations(self):
        self.path.write_text(json.dumps({"params": [], "aggregates": []}))
        Reading.add_proposals(self.path, [proposal(value=4, convention="convention A")], "r/iter-001 A_1")
        errs = self.errs(node("B_1", proposal(value=4, convention="convention B")), Reading(self.path))
        self.assertTrue(any("with the convention 'convention A'" in e and "one parameter has one meaning" in e for e in errs), errs)


class ValueChangeKeepsMeaning(unittest.TestCase):
    """A node of the same law may change its own unreviewed value only under the same convention."""

    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.path = Path(self.tmp.name) / "reading.json"
        self.path.write_text(json.dumps({"params": [{"name": "p.gap", "value": 4, "unit": "m", "convention": "bumper clearance",
                                                     "source": "s", "proposed": "r/iter-001 B_1_o1"}], "aggregates": []}))

    def tearDown(self):
        self.tmp.cleanup()

    def test_new_value_with_new_convention_is_refused(self):
        before = self.path.read_bytes()
        errs = validate_a.check_standards(node("B_1_o2", proposal(value=5, convention="time headway")), Reading(self.path))[0]
        self.assertTrue(any("one parameter has one meaning" in e for e in errs), errs)
        with self.assertRaises(ValueError):
            Reading.add_proposals(self.path, [proposal(value=5, convention="time headway")], "r/iter-002 B_1_o2")
        self.assertEqual(self.path.read_bytes(), before)

    def test_new_value_with_same_convention_is_allowed(self):
        errs = validate_a.check_standards(node("B_1_o2", proposal(value=5, convention="bumper clearance")), Reading(self.path))[0]
        self.assertEqual([e for e in errs if "p.gap" in e], [])
        added = Reading.add_proposals(self.path, [proposal(value=5, convention="bumper clearance")], "r/iter-002 B_1_o2")
        self.assertEqual([a["value"] for a in added], [5])
        self.assertEqual(Reading(self.path).params["p.gap"]["value"], 5)


class BothReadingsOrNeither(unittest.TestCase):
    """A refused item leaves the run's reading and the base reading byte for byte as they were."""

    def setUp(self):
        from types import SimpleNamespace
        self.tmp = tempfile.TemporaryDirectory()
        d = Path(self.tmp.name)
        self.run_file, self.base_file = d / "run_reading.json", d / "base_reading.json"
        self.run_file.write_text(json.dumps({"params": [], "aggregates": [], "declarations": []}))
        self.base_file.write_text(json.dumps({"params": [{"name": "p.gap", "value": 4, "unit": "m", "convention": "bumper clearance"}],
                                              "aggregates": [], "declarations": [{"id": "asm.lit", "meaning": "the street lamps are lit"}]}))
        self.run = SimpleNamespace(reading_file=self.run_file, iteration=2)
        self.opts = SimpleNamespace(run_id="r", reading=self.base_file)

    def tearDown(self):
        self.tmp.cleanup()

    def enter(self, n: Node):
        from harness.loop import enter_proposed
        before = (self.run_file.read_bytes(), self.base_file.read_bytes())
        with self.assertRaises(ValueError):
            enter_proposed(self.run, self.opts, n)
        self.assertEqual((self.run_file.read_bytes(), self.base_file.read_bytes()), before)

    def test_parameter_refused_by_the_base_copy(self):
        self.enter(node("B_1_o1", proposal(value=4, convention="time headway")))

    def test_declaration_refused_by_the_base_copy(self):
        n = node("B_1_o1", proposal(value=7, convention="a new bound", name="p.other"))
        n.raw["assumptions"] = [{"id": "asm.lit", "meaning": "the road is closed to through traffic"}]
        self.enter(n)

    def test_accepted_items_reach_both(self):
        from harness.loop import enter_proposed
        enter_proposed(self.run, self.opts, node("B_1_o1", proposal(value=4, convention="bumper clearance")))
        self.assertEqual(Reading(self.run_file).params["p.gap"]["convention"], "bumper clearance")


class CandidateRefusals(unittest.TestCase):
    """A label repair's candidate refuses, before it applies anything, a node record proposing a
    name a candidate reading holds under another convention."""

    def setUp(self):
        from harness.phases import candidate as cand
        cand._OPEN.clear()
        self.addCleanup(cand._OPEN.clear)

    def apply(self, convention: str, value: float, stub_inside: bool = True):
        """Opens a candidate on a reading whose `p.gap` is 4 m "bumper clearance", the same law's
        unreviewed proposal, and applies a node record proposing `p.gap` = value under `convention`.
        Returns the refusal (None when not refused), whether apply went past its refusals (with
        `stub_inside` it stops there), and both candidate readings' `p.gap` before and after."""
        from harness.phases import candidate as cand
        from scripts.tests import test_candidate as C
        concepts, nodes = C.standard()
        reading = {"params": [{"name": "p.gap", "value": 4, "unit": "m", "convention": "bumper clearance", "source": "s",
                               "proposed": f"r/iter-001 {C.NN}"}], "aggregates": []}
        with C.world(concepts, nodes, reading=reading) as (run, _lib):
            new_n = C.node_rec(C.NN, [C.CB], params=["p.gap"], applicability="a", obligation="o",
                               param_proposals=[{"name": "p.gap", "value": value, "unit": "m", "convention": convention, "source": "s"}])
            with C.Txn(run) as txn:
                files = (Path(txn.view.reading_file), Path(txn.view.opts.reading))
                before = [f.read_bytes() for f in files]
                stop = mock.patch.object(cand.Candidate, "inside", side_effect=AssertionError("past the refusals")) if stub_inside else mock.MagicMock()
                with stop as inside:
                    refused, reached = None, not stub_inside
                    try:
                        txn.apply([cand.Change("node", C.NN, new_n, C.files("node", C.NN, "v2"))])
                    except cand.ChangeRefused as e:
                        refused = str(e)
                    except AssertionError:
                        pass
                    reached = reached or inside.called
                return refused, reached, before, [f.read_bytes() for f in files]

    def test_other_convention_is_refused_before_apply(self):
        refused, reached, before, after = self.apply("time headway", 4)
        self.assertIsNotNone(refused)
        self.assertIn("with the convention 'bumper clearance'", refused)
        self.assertIn("with the convention 'time headway'", refused)
        self.assertIn("one parameter has one meaning", refused)
        self.assertFalse(reached)
        self.assertEqual(after, before)

    def test_own_value_change_under_the_same_convention_is_applied(self):
        refused, _reached, _before, after = self.apply(" bumper  clearance", 5, stub_inside=False)
        self.assertIsNone(refused)
        for raw in after:
            gap = next(p for p in json.loads(raw)["params"] if p["name"] == "p.gap")
            self.assertEqual((gap["value"], gap["convention"]), (5, " bumper  clearance"))


class TableCell(unittest.TestCase):
    def test_pipe_is_escaped_for_display_only(self):
        conv = "gap | headway \\ either"
        table = plan_phase.pending_proposals_table([node("A_1", proposal(convention=conv)).raw])
        row = next(line for line in table.splitlines() if line.startswith("| `p.gap`"))
        cells = re.split(r"(?<!\\)\|", row)[1:-1]
        self.assertEqual(len(cells), 5, row)
        self.assertEqual(cells[3].strip(), "gap \\| headway \\\\ either")
        # the comparison uses the raw text: the same raw convention is no conflict, the escaped one is
        self.assertEqual(validate_a.proposal_conflicts_of([node("A_1", proposal(convention=conv)), node("B_1", proposal(convention=conv))]), {})
        self.assertIn("B_1", validate_a.proposal_conflicts_of([node("A_1", proposal(convention=conv)), node("B_1", proposal(convention=cells[3].strip()))]))


if __name__ == "__main__":
    unittest.main()
