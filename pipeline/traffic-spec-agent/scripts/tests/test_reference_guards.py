"""A law's words that name another law in brackets, read from the posted text, not from the plan's
roles:

- an unambiguous normative reference ("in compliance with", "as provided in", "except as otherwise
  provided in", "as required by", then a bracketed law id in the same clause) is a `reference` span
  carried by execution compositions (or by one residue where the named law is outside the corpus),
  never by atoms of this node and never downgraded to a `definition` reference;
- a `reference` span is carried by compositions or one residue, never by an element;
- an execution composition on a span naming laws targets a node of a named law;
- a `definition` reference that borrows a law's words states why that law's rule need not hold;
- a composition of a fenced (reversioned) node is refused;
- a candidate's changed node may not compose, directly or through other nodes, a node not usable
  for building (`Run.provider_code`).

Every case runs through the full validator (`validate_a.validate`) with the training ontology, a
real reading and mapping index; the candidate case through `candidate.validate_records` and
`candidate.unavailable_compositions`."""
from __future__ import annotations
import copy
import json
import tempfile
import unittest
from pathlib import Path
from types import SimpleNamespace as NS
from unittest import mock

from harness.checks import validate_a
from harness.model import corpus, ontology
from harness.model.blueprint import Node
from harness.model.mapping import MappingIndex
from harness.model.reading import Reading

ONTO = ontology.load(Path("ontology/ATOMS_train.md"))
L, A, C = "STA-900A-100-1", "STA-900A-200-2", "STA-900A-300-1"
A_TEXT = "A vehicle approaching the line must stop before the line."
C_TEXT = "A vehicle must keep right."
COMPLY = "In compliance with subsection 2 [STA-900A-200-2],"
SCENARIOS = [{"name": k, "expected": v} for k, v in (("forbid", "violated"), ("permit", "compliant"), ("idle", "not_applicable"), ("blind", "unknown"))]
SCENARIOS[3]["masked"] = ["kin.speed"]


def laws_with(text: str) -> dict[str, corpus.Law]:
    return {L: corpus.Law(L, "duty", text, "STA 900A.100"), A: corpus.Law(A, "source", A_TEXT, "STA 900A.200"),
            C: corpus.Law(C, "other", C_TEXT, "STA 900A.300")}


def record(ref_text: str = COMPLY, ref_role: str = "reference", **over) -> dict:
    r = {"node_id": "STA_900A_100_1", "law_refs": [L],
         "segmentation": [{"id": "r1", "text": ref_text, "role": ref_role},
                          {"id": "s1", "text": "the driver", "role": "subject"},
                          {"id": "o1", "text": "shall stop.", "role": "obligation"}],
         "elements": [{"span": "s1", "atoms": ["ru.subject"]}, {"span": "o1", "atoms": ["kin.speed"]}],
         "compositions": [{"span": "r1", "as": "compliance", "rule": "STA_900A_200_2", "map": {"veh": "veh"}}],
         "binders": [{"name": "veh"}], "applicability": "a", "obligation": "o", "scenarios": copy.deepcopy(SCENARIOS)}
    r.update(over)
    return r


def accepted(fenced: dict | None = None) -> dict[str, Node]:
    a = {"node_id": "STA_900A_200_2", "law_refs": [A], "binders": [{"name": "veh"}]}
    if fenced:
        a["fenced"] = fenced
    return {"STA_900A_200_2": Node(a), "STA_900A_300_1": Node({"node_id": "STA_900A_300_1", "law_refs": [C], "binders": [{"name": "veh"}]})}


def validate(raw: dict, text: str | None = None, known: dict | None = None) -> validate_a.Outcome:
    text = text if text is not None else f"{raw['segmentation'][0]['text']} the driver shall stop."
    laws = laws_with(text)
    with tempfile.TemporaryDirectory() as t:
        (Path(t) / "reading.json").write_text('{"params":[],"aggregates":[]}')
        return validate_a.validate([Node(json.loads(json.dumps(raw)))], laws, ONTO, Reading(Path(t) / "reading.json"),
                                   MappingIndex(Path(t) / "none.json"), accepted() if known is None else known,
                                   sources={i: l.text for i, l in laws.items()})[0]


class Refused(unittest.TestCase):
    """The four records the operator's review reproduced as accepted, and a reversioned target."""

    def assertReturned(self, out, words: str):
        self.assertEqual(out.kind, validate_a.RETURN, out.reasons)
        self.assertTrue(any(words in r for r in out.reasons), out.reasons)

    def test_a_reference_span_carried_by_an_element(self):
        r = record(compositions=[])
        r["elements"].append({"span": "r1", "atoms": ["kin.speed"]})
        self.assertReturned(validate(r), "reference span r1 is carried by compositions")

    def test_a_reference_relabelled_condition_and_carried_by_atoms(self):
        r = record(ref_role="condition", compositions=[])
        r["elements"].append({"span": "r1", "atoms": ["kin.speed"]})
        self.assertReturned(validate(r), "normative reference")

    def test_a_compliance_reference_downgraded_to_definition_with_a_true_full_quote(self):
        r = record(compositions=[{"span": "r1", "as": "definition", "source": A, "quote": A_TEXT, "why": "it borrows the words"}])
        r["elements"][1].update({"source_spans": ["r1"], "justification": f"the source's rule: \"{A_TEXT}\""})
        out = validate(r)
        self.assertReturned(out, "cannot be carried by a `definition` reference")

    def test_a_reference_to_one_law_composing_another(self):
        r = record(compositions=[{"span": "r1", "as": "compliance", "rule": "STA_900A_300_1", "map": {"veh": "veh"}}])
        self.assertReturned(validate(r), f"names {[A]}")

    def test_a_reference_to_a_reversioned_target(self):
        out = validate(record(), known=accepted(fenced={"reason": "gate", "evidence": "planned again"}))
        self.assertReturned(out, "its law is planned again, compose its new node")


class Admitted(unittest.TestCase):

    def test_a_correct_cross_law_composition(self):
        out = validate(record())
        self.assertEqual((out.kind, out.reasons), (validate_a.ACCEPT, []))
        self.assertEqual([c["rule"] for c in out.node.dependencies()], ["STA_900A_200_2"])

    def test_an_exception_reference_composing_two_nodes_of_the_named_law(self):
        known = accepted()
        known["STA_900A_200_2_o2"] = Node({"node_id": "STA_900A_200_2_o2", "law_refs": [A], "binders": [{"name": "veh"}]})
        r = record("Except as otherwise provided in subsection 2 [STA-900A-200-2],",
                   compositions=[{"span": "r1", "as": "exception", "rule": i, "map": {"veh": "veh"}} for i in ("STA_900A_200_2", "STA_900A_200_2_o2")])
        out = validate(r, known=known)
        self.assertEqual((out.kind, out.reasons), (validate_a.ACCEPT, []))

    def test_legitimate_borrowing_of_a_law_states_why(self):
        text = "If the lane is a turn lane as described in subsection 2 [STA-900A-200-2], the driver shall stop."
        quote = "approaching the line"
        r = {"node_id": "STA_900A_100_1", "law_refs": [L],
             "segmentation": [{"id": "c1", "text": "If the lane is a turn lane", "role": "condition"},
                              {"id": "r1", "text": "as described in subsection 2 [STA-900A-200-2],", "role": "reference"},
                              {"id": "s1", "text": "the driver", "role": "subject"},
                              {"id": "o1", "text": "shall stop.", "role": "obligation"}],
             "elements": [{"span": "c1", "atoms": ["st.turn_lane", "rel.occupies"], "source_spans": ["r1"], "justification": f"\"{quote}\""},
                          {"span": "s1", "atoms": ["ru.subject"]}, {"span": "o1", "atoms": ["kin.speed"]}],
             "compositions": [{"span": "r1", "as": "definition", "source": A, "quote": quote,
                               "why": "borrows the qualifier 'approaching the line'; the lane is described, the source's stop duty is not required"}],
             "binders": [{"name": "veh"}], "applicability": "a", "obligation": "o", "scenarios": copy.deepcopy(SCENARIOS)}
        out = validate(r, text)
        self.assertEqual((out.kind, out.reasons), (validate_a.ACCEPT, []))
        self.assertEqual(out.node.dependencies(), [])
        r["compositions"][0].pop("why")                     # borrowing a law's words without saying why its rule need not hold
        out = validate(r, text)
        self.assertEqual(out.kind, validate_a.RETURN)
        self.assertTrue(any("states no `why`" in x for x in out.reasons), out.reasons)

    def test_a_word_naming_a_law_outside_a_normative_phrase_is_no_execution_reference(self):
        """A bracketed id without a normative phrase is not forced into a composition: a condition the
        node's own atoms carry, which only mentions the law, passes."""
        text = "Where the line of subsection 2 [STA-900A-200-2] is marked the driver shall stop."
        r = record("Where the line of subsection 2 [STA-900A-200-2] is marked", "condition", compositions=[])
        r["elements"].append({"span": "r1", "atoms": ["st.stop_line", "rel.occupies"], "justification": "the marked line"})
        out = validate(r, text)
        self.assertEqual((out.kind, out.reasons), (validate_a.ACCEPT, []))

    def test_the_real_250_2_exception_reference_to_250_4(self):
        """smoke28's accepted record of the corpus's one exception reference among the laws it ran
        (the fixture holds the record and both laws' posted texts): "Except as otherwise provided in
        subsection 4 [<the referenced law>]," carried by `unless` compositions of both of that law's
        nodes."""
        fx = json.loads((Path(__file__).parent / "fixtures" / "reference_250_2.json").read_text())
        law = corpus.Law(**{k: fx["laws"][0][k] for k in corpus.POSTED})
        n = Node(copy.deepcopy(fx["record"]))
        known = {k: Node(v) for k, v in fx["targets"].items()}
        known[n.id] = n
        ids = {l["id"] for l in fx["laws"]}
        self.assertEqual(validate_a.check_accounting(n, ids), [])
        self.assertEqual(validate_a.check_reference_positions(n, law), [])
        self.assertEqual(validate_a.check_compositions(n, known, {l["id"]: l["text"] for l in fx["laws"]}), [])
        moved = copy.deepcopy(fx["record"])                 # the same reference composing a node of another law is refused
        target = next(iter(fx["targets"].values()))
        moved["compositions"][0]["rule"] = "STA_900A_300_1"
        known["STA_900A_300_1"] = Node({"node_id": "STA_900A_300_1", "law_refs": [C], "binders": target["binders"]})
        self.assertTrue(any(f"names {[fx['laws'][1]['id']]}" in e for e in validate_a.check_compositions(Node(moved), known, {})))


class ScopeAndCoverage(unittest.TestCase):
    """The extent of an unambiguous reference, and that it carries every law it names."""

    def test_a_borrowing_after_a_compliance_reference_stays_a_borrowing(self):
        text = "In compliance with subsection 2 [STA-900A-200-2], the driver as described in [STA-900A-300-1] shall stop."
        r = record(segmentation=[{"id": "r1", "text": COMPLY, "role": "reference"},
                                 {"id": "s1", "text": "the driver", "role": "subject"},
                                 {"id": "r2", "text": "as described in [STA-900A-300-1]", "role": "reference"},
                                 {"id": "o1", "text": "shall stop.", "role": "obligation"}])
        r["elements"][0].update({"source_spans": ["r2"], "justification": "the driver of \"A vehicle\""})
        r["compositions"].append({"span": "r2", "as": "definition", "source": C, "quote": "A vehicle",
                                  "why": "borrows which road user is meant; the keep-right duty of the source need not hold"})
        out = validate(r, text)
        self.assertEqual((out.kind, out.reasons), (validate_a.ACCEPT, []))

    def test_a_qualified_noun_is_no_execution_target(self):
        text = "The driver shall stop as required by a sign installed under [STA-900A-200-2]."
        r = record(segmentation=[{"id": "s1", "text": "The driver", "role": "subject"},
                                 {"id": "o1", "text": "shall stop", "role": "obligation"},
                                 {"id": "c1", "text": "as required by a sign installed under [STA-900A-200-2].", "role": "condition"}],
                   compositions=[])
        r["elements"].append({"span": "c1", "atoms": ["st.stop_line", "rel.occupies"], "justification": "the line the sign governs"})
        out = validate(r, text)
        self.assertEqual((out.kind, out.reasons), (validate_a.ACCEPT, []))

    def test_a_reference_followed_by_a_condition(self):
        text = f"{COMPLY} the driver at the line shall stop."
        r = record(segmentation=[{"id": "r1", "text": COMPLY, "role": "reference"},
                                 {"id": "s1", "text": "the driver", "role": "subject"},
                                 {"id": "c1", "text": "at the line", "role": "condition"},
                                 {"id": "o1", "text": "shall stop.", "role": "obligation"}])
        r["elements"].append({"span": "c1", "atoms": ["st.stop_line", "rel.occupies"], "justification": "at the line"})
        out = validate(r, text)
        self.assertEqual((out.kind, out.reasons), (validate_a.ACCEPT, []))

    LIST = "In compliance with subsections 2 [STA-900A-200-2] and 3 [STA-900A-300-1],"

    def test_a_list_reference_composing_one_of_its_laws_is_refused(self):
        out = validate(record(self.LIST))
        self.assertEqual(out.kind, validate_a.RETURN, out.reasons)
        self.assertTrue(any(C in x and "no composition" in x for x in out.reasons), out.reasons)

    def test_a_list_reference_composing_each_law_passes(self):
        both = [{"span": "r1", "as": "compliance", "rule": i, "map": {"veh": "veh"}} for i in ("STA_900A_200_2", "STA_900A_300_1")]
        out = validate(record(self.LIST, compositions=both))
        self.assertEqual((out.kind, out.reasons), (validate_a.ACCEPT, []))
        either = [{"span": "r1", "as": "exception", "rule": i, "map": {"veh": "veh"}} for i in ("STA_900A_200_2", "STA_900A_300_1")]
        out = validate(record("Except as otherwise provided in subsection 2 [STA-900A-200-2] or 3 [STA-900A-300-1],", compositions=either))
        self.assertEqual((out.kind, out.reasons), (validate_a.ACCEPT, []))

    def test_an_out_of_corpus_target_carried_by_a_residue(self):
        r = record("In compliance with subsection 9 [STA-999Z-9-1],", compositions=[],
                   residues=[{"span": "r1", "why": "the named law is outside this corpus"}])
        out = validate(r)
        self.assertEqual((out.kind, out.reasons), (validate_a.ACCEPT, []))


class AdjacentDesignators(unittest.TestCase):
    """A designator whose further levels in parentheses are written against it ("2(a)", "(2)(a)",
    "484B.287(1)(b)") is part of the citation: the reference keeps its guards, its targets and its end."""

    REFS = ("In compliance with subsection 2(a) [STA-900A-200-2],", "As required by subsection (2)(a) [STA-900A-200-2],",
            "In compliance with STA 900A.200(2)(a) [STA-900A-200-2],")

    def test_carried_by_atoms_as_a_condition_it_is_refused(self):
        for ref in self.REFS:
            with self.subTest(ref=ref):
                r = record(ref, ref_role="condition", compositions=[])
                r["elements"].append({"span": "r1", "atoms": ["kin.speed"]})
                out = validate(r)
                self.assertEqual(out.kind, validate_a.RETURN, out.reasons)
                self.assertTrue(any("normative reference" in x for x in out.reasons), out.reasons)

    def test_a_composition_of_the_named_law_passes(self):
        for ref in self.REFS:
            with self.subTest(ref=ref):
                out = validate(record(ref))
                self.assertEqual((out.kind, out.reasons), (validate_a.ACCEPT, []))

    def test_a_list_of_such_designators_misses_no_target(self):
        ref = "In compliance with subsections 2(a) [STA-900A-200-2] and (3)(b) [STA-900A-300-1],"
        out = validate(record(ref))
        self.assertEqual(out.kind, validate_a.RETURN, out.reasons)
        self.assertTrue(any(C in x and "no composition" in x for x in out.reasons), out.reasons)
        both = [{"span": "r1", "as": "compliance", "rule": i, "map": {"veh": "veh"}} for i in ("STA_900A_200_2", "STA_900A_300_1")]
        self.assertEqual((lambda o: (o.kind, o.reasons))(validate(record(ref, compositions=both))), (validate_a.ACCEPT, []))

    def test_a_borrowing_after_it_stays_a_borrowing(self):
        ref = "In compliance with subsection 2(a) [STA-900A-200-2],"
        text = f"{ref} the driver as described in [STA-900A-300-1] shall stop."
        r = record(ref, segmentation=[{"id": "r1", "text": ref, "role": "reference"},
                                      {"id": "s1", "text": "the driver", "role": "subject"},
                                      {"id": "r2", "text": "as described in [STA-900A-300-1]", "role": "reference"},
                                      {"id": "o1", "text": "shall stop.", "role": "obligation"}])
        r["elements"][0].update({"source_spans": ["r2"], "justification": "the driver of \"A vehicle\""})
        r["compositions"].append({"span": "r2", "as": "definition", "source": C, "quote": "A vehicle",
                                  "why": "borrows which road user is meant; the keep-right duty of the source need not hold"})
        out = validate(r, text)
        self.assertEqual((out.kind, out.reasons), (validate_a.ACCEPT, []))

    def test_the_positions(self):
        pos = lambda t: [(t[a:b], ids) for a, b, ids in validate_a.normative_references(t, "")]
        self.assertEqual(pos("as provided in 484B.287(1)(b) [STA-1-2] and 2(c) [STA-1-3], a driver as described in [STA-1-4]"),
                         [("as provided in 484B.287(1)(b) [STA-1-2] and 2(c) [STA-1-3]", ["STA-1-2", "STA-1-3"])])
        self.assertEqual(pos("The driver shall stop as required by a sign installed under [STA-1-2]."), [])
        self.assertEqual(pos("The driver shall stop as required by a sign installed under (2)(a) [STA-1-2]."), [])


class SiblingCarrying(unittest.TestCase):
    """A node that marks a reference `sibling` relies on the law's other nodes: each law the reference
    names must be composed, through a usable node, by a node that segments the reference itself."""

    TEXT = "{ref} the driver shall stop and shall wait."

    def pair(self, ref: str, comps: list[dict], o2_ref_role: str = "sibling", o2_comps: list[dict] | None = None):
        o1 = record(ref, node_id="STA_900A_100_1_o1",
                    segmentation=[{"id": "r1", "text": ref, "role": "reference"}, {"id": "s1", "text": "the driver", "role": "subject"},
                                  {"id": "o1", "text": "shall stop", "role": "obligation"}, {"id": "x1", "text": "and shall wait.", "role": "sibling"}],
                    compositions=comps)
        o2 = record(ref, node_id="STA_900A_100_1_o2",
                    segmentation=[{"id": "r1", "text": ref, "role": o2_ref_role}, {"id": "s1", "text": "the driver", "role": "subject"},
                                  {"id": "x1", "text": "shall stop", "role": "sibling"}, {"id": "o1", "text": "and shall wait.", "role": "obligation"}],
                    compositions=o2_comps or [])
        return o1, o2

    def run_pair(self, o1, o2, ref, known=None):
        text = self.TEXT.format(ref=ref)
        laws = laws_with(text)
        with tempfile.TemporaryDirectory() as t:
            (Path(t) / "reading.json").write_text('{"params":[],"aggregates":[]}')
            out = validate_a.validate([Node(json.loads(json.dumps(o1))), Node(json.loads(json.dumps(o2)))], laws, ONTO,
                                      Reading(Path(t) / "reading.json"), MappingIndex(Path(t) / "none.json"),
                                      accepted() if known is None else known, sources={i: l.text for i, l in laws.items()})
        return {o.node.id: o for o in out}

    def comp(self, rule: str) -> dict:
        return {"span": "r1", "as": "compliance", "rule": rule, "map": {"veh": "veh"}}

    def test_a_sibling_carried_by_the_composing_node_passes(self):
        o1, o2 = self.pair(COMPLY, [self.comp("STA_900A_200_2")])
        out = self.run_pair(o1, o2, COMPLY)
        self.assertEqual({k: (v.kind, v.reasons) for k, v in out.items()},
                         {"STA_900A_100_1_o1": (validate_a.ACCEPT, []), "STA_900A_100_1_o2": (validate_a.ACCEPT, [])})

    def test_siblings_pointing_at_each_other_are_refused(self):
        o1, o2 = self.pair(COMPLY, [])
        o1["segmentation"][0]["role"] = "sibling"
        out = self.run_pair(o1, o2, COMPLY)
        for k in out:
            self.assertEqual(out[k].kind, validate_a.RETURN, out[k].reasons)
            self.assertTrue(any("is no other node's span" in r for r in out[k].reasons), out[k].reasons)   # check_decomposition

    def test_a_sibling_partly_carried_is_refused(self):
        ref = "In compliance with subsections 2 [STA-900A-200-2] and 3 [STA-900A-300-1],"
        o1, o2 = self.pair(ref, [self.comp("STA_900A_200_2")])
        out = self.run_pair(o1, o2, ref)
        self.assertTrue(any(C in r and "compose no usable node" in r for r in out["STA_900A_100_1_o2"].reasons), out["STA_900A_100_1_o2"].reasons)
        self.assertTrue(any(C in r and "no composition" in r for r in out["STA_900A_100_1_o1"].reasons), out["STA_900A_100_1_o1"].reasons)

    def test_a_sibling_whose_carrier_composes_a_fenced_node_is_refused(self):
        o1, o2 = self.pair(COMPLY, [self.comp("STA_900A_200_2")])
        out = self.run_pair(o1, o2, COMPLY, known=accepted(fenced={"reason": "gate", "evidence": "planned again"}))
        self.assertTrue(any("compose no usable node" in r for r in out["STA_900A_100_1_o2"].reasons), out["STA_900A_100_1_o2"].reasons)
        self.assertTrue(any("planned again" in r for r in out["STA_900A_100_1_o1"].reasons), out["STA_900A_100_1_o1"].reasons)


class Positions(unittest.TestCase):
    """Where the posted text makes a reference normative."""

    def positions(self, text: str, own: str = L) -> list[tuple[str, list[str]]]:
        return [(text[a:z], named) for a, z, named in validate_a.normative_references(text, own)]

    def test_the_phrases(self):
        self.assertEqual(self.positions("Except as otherwise provided in subsection 4 [STA-1-4], it applies."),
                         [("Except as otherwise provided in subsection 4 [STA-1-4]", ["STA-1-4"])])
        self.assertEqual(self.positions("yield in compliance with a yield sign, in compliance with the manner prescribed in subsection 1 [STA-1-1], before"),
                         [("in compliance with the manner prescribed in subsection 1 [STA-1-1]", ["STA-1-1"])])
        self.assertEqual(self.positions("Except as otherwise provided in STA 2.287 [STA-2-1, STA-2-2], 2.290 [STA-3] and 2.350 [STA-4], a driver"),
                         [("Except as otherwise provided in STA 2.287 [STA-2-1, STA-2-2], 2.290 [STA-3] and 2.350 [STA-4]",
                           ["STA-2-1", "STA-2-2", "STA-3", "STA-4"])])
        self.assertEqual(self.positions("proceed as required pursuant to subsection 1 [STA-5-1]."), [("as required pursuant to subsection 1 [STA-5-1]", ["STA-5-1"])])

    def test_what_is_not_an_unambiguous_reference(self):
        self.assertEqual(self.positions("a turn lane as described in subsection 2 [STA-1-2]"), [])
        self.assertEqual(self.positions("pursuant to the criteria set forth in subsection 1 of STA 1.600 [STA-1-1]"), [])
        self.assertEqual(self.positions("Except as otherwise provided in subsection 4 [(4) appended below]"), [])      # no law id
        self.assertEqual(self.positions("as provided in [DEF-STA-1]"), [])                                            # a definition
        self.assertEqual(self.positions("except as otherwise provided in this section [STA-1-1]", own="STA-1-1"), [])  # the law itself

    def test_the_reference_ends_where_the_citation_grammar_ends(self):
        """Between the phrase and a bracket only citation words; between brackets only list connectors.
        A new clause, a subject, a borrowing phrase or a noun with its own qualifier ends it."""
        self.assertEqual(self.positions("In compliance with subsection 2 [STA-1-2], the driver as described in [STA-1-3] shall stop."),
                         [("In compliance with subsection 2 [STA-1-2]", ["STA-1-2"])])
        self.assertEqual(self.positions("The driver shall stop as required by a sign installed under [STA-1-2]."), [])
        self.assertEqual(self.positions("In compliance with subsections 2 [STA-1-2] and 3 [STA-1-3], the driver"),
                         [("In compliance with subsections 2 [STA-1-2] and 3 [STA-1-3]", ["STA-1-2", "STA-1-3"])])
        self.assertEqual(self.positions("Except as otherwise provided in subsection 2 [STA-1-2] or 3 [STA-1-3], a driver"),
                         [("Except as otherwise provided in subsection 2 [STA-1-2] or 3 [STA-1-3]", ["STA-1-2", "STA-1-3"])])
        self.assertEqual(self.positions("as provided in subparagraph (1) or (2) [STA-1-1, STA-1-2]."),
                         [("as provided in subparagraph (1) or (2) [STA-1-1, STA-1-2]", ["STA-1-1", "STA-1-2"])])
        self.assertEqual(self.positions("as provided in subsection 6 of STA 4.297 [STA-4-6]"), [("as provided in subsection 6 of STA 4.297 [STA-4-6]", ["STA-4-6"])])


class CandidatePath(unittest.TestCase):
    """`candidate.validate_records` runs the same validator. Whether a changed node may compose what it
    composes is one check, `candidate.unavailable_compositions` (run by `Candidate.verify` on every
    candidate, and by a label repair before any coder): the closure of its compositions, each node
    usable by its law (`Run.usable_nodes`), whatever the record composed before the candidate."""

    def run_records(self, rec: dict):
        from harness.phases import candidate as cand
        from harness.store import state
        from harness.model import definitions
        from harness.store import gaps
        laws = laws_with(f"{COMPLY} the driver shall stop.")
        nodes = {k: v.raw for k, v in accepted().items()}
        with tempfile.TemporaryDirectory() as t:
            (Path(t) / "reading.json").write_text('{"params":[],"aggregates":[]}')
            view = NS(opts=NS(ontology=Path("ontology/ATOMS_train.md"), laws=Path(t) / "absent.jsonl", mode="train"),
                      mapping_file=Path(t) / "none.json", all_nodes=lambda: {**nodes, rec["node_id"]: rec}, all_concepts=lambda: {})
            txn = NS(view=view, reading=Reading(Path(t) / "reading.json"))
            with mock.patch.object(state, "chain_laws", lambda v: laws), \
                    mock.patch.object(definitions, "source_texts", lambda v: {i: l.text for i, l in laws.items()}), \
                    mock.patch.object(gaps.GapLedger, "for_run", classmethod(lambda cls, *a: NS(rejected=lambda: {}, rows=[]))):
                return cand.validate_records(txn, [Node(copy.deepcopy(rec))], [])

    def unavailable(self, recs: list[dict], usable: set[str], changed: list[str]):
        """The candidate's availability check on a view of these records, laws outside any ledger,
        only `usable` (and the changed records, gated in the transaction) having admission evidence."""
        from harness.phases import candidate as cand
        from harness.store import state
        nodes = {**{k: v.raw for k, v in accepted().items()}, **{r["node_id"]: r for r in recs}}
        view = NS(all_nodes=lambda: nodes, all_concepts=lambda: {}, law_entries={}, fenced={})
        with mock.patch.object(state.Availability, "evidence", lambda self, kind, ident: ident in usable or ident in self.gated):
            return cand.unavailable_compositions(view, changed, gated=set(changed))

    def test_the_validator_passes_a_correct_record_and_leaves_availability_to_its_check(self):
        self.assertEqual([r.status for r in self.run_records(record())], ["pass"])        # no second message for one defect

    def test_a_dependency_without_admission_evidence_is_refused_whether_new_or_kept(self):
        self.assertEqual(self.unavailable([record()], set(), ["STA_900A_100_1"]), {"STA_900A_100_1": {"STA_900A_200_2": "unjudged"}})
        self.assertEqual(self.unavailable([record()], {"STA_900A_200_2"}, ["STA_900A_100_1"]), {})

    def test_a_dependency_reached_through_a_usable_node_is_refused_too(self):
        mid = {"node_id": "STA_900A_300_1", "law_refs": [C], "binders": [{"name": "veh"}],
               "compositions": [{"span": "r", "as": "condition", "rule": "STA_900A_200_2", "map": {}}]}
        top = record(compositions=[{"span": "r1", "as": "compliance", "rule": "STA_900A_300_1", "map": {"veh": "veh"}}])
        self.assertEqual(self.unavailable([mid, top], {"STA_900A_300_1"}, ["STA_900A_100_1"]),
                         {"STA_900A_100_1": {"STA_900A_300_1": "via:STA_900A_200_2:unjudged"}})

    def test_a_reference_carried_by_atoms_is_refused_in_a_candidate_too(self):
        r = record(ref_role="condition", compositions=[])
        r["elements"].append({"span": "r1", "atoms": ["kin.speed"]})
        res = self.run_records(r)
        self.assertEqual([x.status for x in res], ["fail"])
        self.assertTrue(any("normative reference" in x for x in res[0].details), res[0].details)

    def test_a_same_law_sibling_stays_usable(self):
        sib = {"node_id": "STA_900A_100_1_o2", "law_refs": [L], "compositions": [{"span": "r", "as": "condition", "rule": "STA_900A_100_1_o1", "map": {}}]}
        o1 = {"node_id": "STA_900A_100_1_o1", "law_refs": [L]}
        self.assertEqual(self.unavailable([o1, sib], set(), ["STA_900A_100_1_o1", "STA_900A_100_1_o2"]), {})   # changed together


class PauseReasons(unittest.TestCase):
    """A split stage with no work of its own says why: it hands the run to the other stage only when
    that stage has work, and otherwise pauses on the budget or for the operator."""

    def label_stage(self, route_states: dict, **over) -> tuple[list[str], dict]:
        from harness import loop
        from harness.phases import label_check, label_repair as lr
        from harness.store import paths
        from scripts.tests.test_recovery import Fixture
        from scripts.tests.test_split_handoff import A, C, SPLIT, split_world

        def route(run, ledger, training, to_user):
            for law, nodes in loop.label_ready(run, ledger).items():
                st = route_states.get(law, "accepted")
                if st == "accepted":
                    ledger.accept(law, nodes)
                run.label_states[law] = {"state": st, "outcome": "aligned" if st == "accepted" else "misaligned", "nodes": nodes,
                                         "repairs": over.get("repairs", 0),
                                         **({"waiting_on": [[nodes[0], "L_99", "missing"]]} if st == "waiting" else {})}
            return {}
        w = split_world()
        with Fixture(w, **SPLIT) as f:
            self.assertEqual(f.drive(1, label_deferred=True), ["awaiting_labels"])
            with mock.patch.object(loop, "label_route", route), \
                    mock.patch.object(label_check, "training_context", lambda *a, **k: object()), \
                    mock.patch.object(lr, "run_repairs", lambda *a, **k: {}):
                stage_opts = {k: v for k, v in over.items() if k != "repairs"}
                out = f.drive(1, label_stage=True, label_dataset="ds", max_iterations=3, **stage_opts)
                summary = json.loads((paths.RESULTS / "r" / "summary.json").read_text())
                again = f.drive(1, label_deferred=True, max_iterations=5, **stage_opts)   # the generation stage on the same state
                summary_g = json.loads((paths.RESULTS / "r" / "summary.json").read_text())
        return out + again, {"label": summary, "generation": summary_g}

    def test_a_repair_the_run_budget_no_longer_funds_pauses_on_the_budget(self):
        from scripts.tests.test_split_handoff import A, C
        out, s = self.label_stage({A: "awaiting_label_repair", C: "accepted"}, repairs=1, label_repair_budget=1, label_repair_attempts=2)
        self.assertEqual(out, ["paused_budget", "paused_budget"])                 # neither stage hands the run to the other
        self.assertIn("label_repair_budget", s["label"]["stop_reason"])
        self.assertIn(A, s["label"]["stop_reason"])

    def test_with_budget_left_the_repair_is_label_work(self):
        from scripts.tests.test_split_handoff import A, C
        from harness import loop
        from harness.store.state import Options
        run = NS(label_states={A: {"state": "awaiting_label_repair", "repairs": 1}})
        ledger = NS(entries={A: NS(law=A, state="planned")})
        with mock.patch.object(loop, "label_ready", lambda run, ledger: {}):
            opts = NS(label_repair=True, label_deferred=False, label_repair_budget=5, label_repair_attempts=2)
            self.assertEqual(loop.label_work(run, opts, ledger), [A])
            opts.label_repair_budget = 1
            self.assertEqual(loop.label_work(run, opts, ledger), [])

    def test_nothing_anywhere_awaits_the_operator(self):
        from scripts.tests.test_split_handoff import A, C
        out, s = self.label_stage({A: "waiting", C: "accepted"})
        self.assertEqual(out, ["awaiting_operator", "awaiting_operator"])
        self.assertIn(A, s["label"]["stop_reason"])

    def test_a_wait_on_a_failed_or_blocked_dependency_awaits_the_operator(self):
        """A law whose repair (or held node) waits on a law that later failed or was blocked: when
        neither stage has work, both stages end `awaiting_operator` naming the law and the closed
        dependencies; nothing hands the run over, and the wait is not released."""
        from harness import loop
        from harness.store.ledger import Entry
        ledger = NS(entries={"L-1": Entry("L-1"), "L-2": Entry("L-2"), "L-3": Entry("L-3")})
        ledger.entries["L-1"].state, ledger.entries["L-2"].state, ledger.entries["L-3"].state = "planned", "failed", "blocked"
        rec = {"node_id": "L_1", "law_refs": ["L-1"], "compositions": [{"span": "r", "as": "condition", "rule": "L_2", "map": {}},
                                                                       {"span": "r", "as": "exception", "rule": "L_3_o1", "map": {}}]}
        run = NS(all_nodes=lambda: {"L_1": rec}, deferred_nodes=[], label_states={"L-1": {"state": "awaiting_label_repair", "repairs": 0}})
        for stage in (dict(label_stage=True, label_deferred=False), dict(label_stage=False, label_deferred=True)):
            from harness.store.state import Options
            opts = Options(run_id="r", laws=Path("l"), ontology=Path("o"), reading=Path("r"), label_repair_attempts=2, label_repair_budget=10, **stage)
            with mock.patch.object(loop, "runnable_work", lambda *a, **k: {"labels": [], "held": []}), \
                    mock.patch.object(loop, "label_work", lambda *a, **k: []), \
                    mock.patch("harness.phases.feedback.pending_lists", lambda run, ledger: {"blocked": ["L-3"]}):
                status, reason = loop.pause_reason(run, opts, ledger, None, None, {})
            self.assertEqual(status, "awaiting_operator", reason)
            self.assertIn("`L-1` waits on `L-2` (failed), `L-3` (blocked)", reason)

    def test_a_generated_run_routed_whole_is_complete(self):
        from scripts.tests.test_split_handoff import A, C
        out, _s = self.label_stage({A: "accepted", C: "accepted"})
        self.assertEqual(out, ["complete", "complete"])                          # B was generated on A's usable node already


if __name__ == "__main__":
    unittest.main()
