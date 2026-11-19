"""A map whose class lists name no class in common is a note for the operator, never a return
(`validate_a.role_class_notes`): one road user may carry several classes, as Core's membership of a
road user carrying both shows, and the ontology states no two classes exclusive. A shared class, a
covered class, a quantified variable and an undecided pair give no note. The Lean part runs only
when the library is built."""
import json
import tempfile
import unittest
from pathlib import Path

from harness.checks import validate_a
from harness.model import ontology
from harness.model.blueprint import Node
from harness.model.reading import Reading
from scripts.tests.test_aggregate_covered import LEAN_BUILT, lean_membership, user

ONTO = ontology.load(Path(__file__).resolve().parents[2] / "ontology" / "ATOMS.md")
ON_FOOT, WHEELED, MOTORED = "DEF-TEST-1::on_foot", "DEF-TEST-2::wheeled", "DEF-TEST-3::motored"
AGGREGATES = [
    {"id": ON_FOOT, "included": ["ru.pedestrian", "ru.child"], "unresolved": [],
     "covered": [{"class": "ru.electric_scooter", "covered_by": ["ru.pedestrian"]}]},
    {"id": WHEELED, "included": ["ru.motor_vehicle", "ru.bus", "ru.bicycle"], "unresolved": ["ru.electric_scooter"],
     "covered": [{"class": "ru.taxicab", "covered_by": ["ru.motor_vehicle"]}]},
    {"id": MOTORED, "included": ["ru.motor_vehicle", "ru.bus"], "unresolved": []},
]


def agg(aid):
    return f"ru.aggregate={aid}"


def node(nid, binders, compositions=()):
    return Node({"node_id": nid, "law_refs": ["TEST-RC-1"], "segmentation": [],
                 "binders": [{"name": n, "class_elements": ce} for n, ce in binders],
                 "compositions": list(compositions)})


def composes(nid, binders, target, mapping, as_="exception"):
    return node(nid, binders, [{"span": "r", "rule": target, "map": mapping, "as": as_}])


class RoleClasses(unittest.TestCase):

    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        path = Path(self.tmp.name) / "reading.json"
        path.write_text(json.dumps({"params": [], "aggregates": AGGREGATES}))
        self.reading = Reading(path)
        self.known = {"T_WHEELED": node("T_WHEELED", [("subject", [agg(WHEELED)])]),
                      "T_TAXI": node("T_TAXI", [("subject", ["ru.taxicab"])]),
                      "T_BOTH": node("T_BOTH", [("subject", [agg(ON_FOOT), agg(WHEELED)])]),
                      "T_PENDING": node("T_PENDING", [("subject", [agg("DEF-TEST-9::unknown")])])}

    def tearDown(self):
        self.tmp.cleanup()

    def notes(self, n):
        return validate_a.role_class_notes(n, self.known, self.reading, ONTO)

    def test_disjoint_class_lists_are_noted_for_the_operator(self):
        # the source covers scooters, the target leaves them unresolved: a class the source only covers
        # admits no road user to it, so no road user is of both
        got = self.notes(composes("SRC", [("subject", [agg(ON_FOOT)])], "T_WHEELED", {"subject": "subject"}))
        self.assertEqual(len(got), 1, got)
        self.assertIn("`T_WHEELED`", got[0])

    def test_shared_classes_pass(self):
        self.assertEqual(self.notes(composes("SRC", [("subject", [agg(MOTORED)])], "T_WHEELED", {"subject": "subject"})), [])
        self.assertEqual(self.notes(composes("SRC", [("subject", [agg(ON_FOOT)])], "T_BOTH", {"subject": "subject"})), [])
        self.assertEqual(self.notes(composes("SRC", [("subject", ["ru.bicycle"])], "T_WHEELED", {"subject": "subject"})), [])

    def test_a_class_the_target_covers_passes(self):
        self.assertEqual(self.notes(composes("SRC", [("subject", ["ru.taxicab"])], "T_WHEELED", {"subject": "subject"})), [])

    def test_a_class_atom_target_reads_the_source_aggregates_classes(self):
        self.assertEqual(self.notes(composes("SRC", [("subject", [agg(WHEELED)])], "T_TAXI", {"subject": "subject"})), [])
        self.assertTrue(self.notes(composes("SRC", [("subject", [agg(ON_FOOT)])], "T_TAXI", {"subject": "subject"})))

    def test_undecided_pairs_and_quantified_variables_pass(self):
        # two different class atoms: no class hierarchy is declared, so the pair is not decided
        self.assertEqual(self.notes(composes("SRC", [("subject", ["ru.truck"])], "T_TAXI", {"subject": "subject"})), [])
        # an aggregate the reading has not admitted
        self.assertEqual(self.notes(composes("SRC", [("subject", [agg(ON_FOOT)])], "T_PENDING", {"subject": "subject"})), [])
        # the mapped name is no binder of this node: the coder quantifies over it
        self.assertEqual(self.notes(composes("SRC", [("subject", [agg(ON_FOOT)])], "T_WHEELED", {"subject": "p"})), [])

    def test_every_execution_kind_is_checked(self):
        for kind in ("condition", "compliance", "unless"):
            n = composes("SRC", [("subject", [agg(ON_FOOT)])], "T_WHEELED", {"subject": "subject"}, kind)
            self.assertTrue(self.notes(n), kind)


class NotesNeverReturn(unittest.TestCase):

    def test_the_ontology_states_no_exclusive_classes(self):
        # the note's premise: were the ontology to state two classes that cannot be carried together, the
        # check would have a ground to return a map, and this test names the words to look for
        text = ONTO.text.lower()
        for words in ("mutually exclusive", "cannot be carried together", "never carried together"):
            self.assertNotIn(words, text)

    @unittest.skipUnless(LEAN_BUILT, "the library is not built (run `lake build` in library/)")
    def test_one_road_user_carrying_both_classes_is_a_member_of_both(self):
        both = user(["ru.pedestrian", "ru.motor_vehicle"])
        self.assertEqual(lean_membership(AGGREGATES, [(ON_FOOT, both), (WHEELED, both)]), ["T", "T"])


if __name__ == "__main__":
    unittest.main()
