"""The behaviour-property review's answer schemas, its adoption gate and its prompts, without a model:
the schema files load, are closed and agree with the gate and the renderer; each bound holds at its
limit and refuses one beyond it (an answer as a whole, or a candidate by the gate, recorded and never
truncated); an answer invalid as a whole publishes no property set and no exemption, while a valid
answer is decided candidate by candidate; the cross-field checks of the gate; the property identity
a withdrawal binds; the prompt templates render through the prompt renderer and pass the doctor."""
import copy
import itertools
import json
import re
import tempfile
import unittest
from contextlib import contextmanager
from fractions import Fraction
from pathlib import Path
from unittest import mock

from harness.agents import render
from harness.model import units
from harness.phases import behaviour_review as br
from harness.phases import review_schema as rs
from harness.store import paths

LAW = ("A driver shall not drive faster than 15 miles per hour in a school zone. "
       "A driver shall yield to a pedestrian unless directed otherwise by an officer. "
       "A driver shall yield to a pedestrian.")
CONVENTIONS = "The colour of a sign is read through the device that shows it."
ONTO_TEXT = (paths.REPO / "ontology" / "ATOMS_train.md").read_text(encoding="utf-8")
CTX = rs.context(LAW, [], ONTO_TEXT, CONVENTIONS)
MPH15 = units.to_core(15, "mph")[1]


def lit(v: Fraction, unit: str = "metre_per_second") -> dict:
    return {"lit": {"num": v.numerator, "den": v.denominator}, "unit": unit}


def speed(var: str = "v") -> dict:
    return {"measure": "kin_speed", "args": [{"var": var}]}


def car(var: str = "v", atom: str = "ru_motor_vehicle") -> dict:
    return {"atom": atom, "args": [{"var": var}], "params": []}


def candidate(pid: str, category: str = "must_detect", op: str = "gt", clause: str = "C1", antecedent=None, cls=None, **over) -> dict:
    c = {"id": pid, "clause": clause, "span_quote": "shall not drive faster than 15 miles per hour", "category": category,
         "binders": [{"name": "v", "cls": cls or car(), "subject": True}],
         "conditions": [{"text": "its speed is above the figure", "quote": "faster than 15 miles per hour"}],
         "exceptions": [], "observations": ["kin.speed"], "open_questions": [],
         "antecedent": antecedent or {"cmp": op, "lhs": speed(), "rhs": lit(MPH15)},
         "expected": "violated" if category == "must_detect" else "not_violated", "gaps": []}
    c.update(over)
    return c


def draft(*cands, clauses=None) -> dict:
    return {"clauses": clauses if clauses is not None else [
                {"id": "C1", "quote": "A driver shall not drive faster than 15 miles per hour in a school zone."},
                {"id": "C2", "quote": "A driver shall yield to a pedestrian unless directed otherwise by an officer.",
                 "no_property": [{"category": "must_detect", "reason": "r"}, {"category": "must_not_flag", "reason": "r"}]}],
            "candidates": list(cands),
            "distinctions": {"action": [c["id"] for c in cands][:1] or {"not_applicable": "none"},
                             **{d: {"not_applicable": "it does not turn on it"} for d in rs.DISTINCTIONS[1:]}}}


def item(pid: str, **over) -> dict:
    i = {"id": pid, "conditions": [
            {"condition_quote": "faster than 15 miles per hour", "kind": "premise",
             "terms": [{"term": "faster", "atom": "kin.speed", "grounding": "the contract of kin.speed", "status": "grounded"}],
             "antecedent_path": "antecedent.lhs", "rating": "full_match", "reason": "the same comparison"},
            {"condition_quote": "shall not drive", "kind": "conclusion", "terms": [], "antecedent_path": None,
             "rating": "full_match", "reason": "the verdict the words require"}],
         "conclusion_ok": "yes", "item_cause": "adoptable"}
    i.update(over)
    return i


def assess(clause: str, category: str, assessment: str, quote: str = "A driver shall not drive") -> dict:
    return {"clause": clause, "category": category, "assessment": assessment, "quote": quote, "reason": "the words bear it out"}


def screen(*items, assessments=None, missed=(), uncovered=(), behaviour=None) -> dict:
    return {"items": list(items),
            "clause_assessments": assessments if assessments is not None else [
                assess("C1", "must_detect", "properties_given"), assess("C1", "must_not_flag", "properties_given"),
                assess("C2", "must_detect", "reason_confirmed", "unless directed otherwise by an officer"),
                assess("C2", "must_not_flag", "reason_confirmed", "unless directed otherwise by an officer")],
            "missed_obligations": list(missed), "uncovered_situations": list(uncovered),
            "law_behaviour": behaviour or {"assessment": "checkable", "reason": "it decides a speed"}}


def good() -> list[dict]:
    return [{"draft": draft(candidate("P1"), candidate("P2", "must_not_flag", "le")), "screen": screen(item("P1"), item("P2"))}]


def adopted(out) -> list[str]:
    return [r["id"] for r in out["records"]]


def reasons_of(out, pid) -> list[str]:
    return next(a["adoption"]["reasons"] for a in out["adoption"] if a["property"] == pid)


@contextmanager
def patched_schemas(edit=None, lim=None):
    """The schema files (and limits) as `edit` / `lim` change copies of them, the caches cleared."""
    s, l = copy.deepcopy(rs.schemas()), copy.deepcopy(rs.limits())
    if edit:
        edit(s)
    if lim:
        lim(l)
    caches = (rs.schemas, rs.limits, rs._validator, rs._checked)
    for c in caches:
        c.cache_clear()
    with mock.patch.object(rs, "schemas", lambda: s), mock.patch.object(rs, "limits", lambda: l), \
            mock.patch.object(rs, "_validator", rs._validator.__wrapped__):
        try:
            yield
        finally:
            for c in caches:
                c.cache_clear()


class Files(unittest.TestCase):
    """The schema files load, are closed and agree with the gate and the renderer."""

    def test_the_tree_is_consistent(self):
        self.assertEqual(rs.startup_defects(), [])
        rs.startup_check()

    def test_every_object_schema_is_closed(self):
        self.assertEqual([k for k in rs.FILES if rs._open_objects(k)], [])
        def opened(s):
            s["screen"]["$defs"]["condition"].pop("additionalProperties")
        with patched_schemas(opened):
            self.assertTrue(any("not closed" in d for d in rs.startup_defects()))
            with self.assertRaises(rs.SchemaConfigError):
                rs.adopt_answer(good(), CTX)

    def test_an_enumeration_or_bound_that_drifts_from_the_gate_is_a_defect(self):
        def drift(s):
            s["draft"]["$defs"]["candidate"]["properties"]["category"]["enum"].append("invariance")
        with patched_schemas(drift):
            self.assertTrue(any("candidate categories" in d for d in rs.startup_defects()))
        def bound(s):
            s["screen"]["properties"]["clause_assessments"]["maxItems"] = 47
        with patched_schemas(bound):
            self.assertTrue(any("clause_assessments" in d for d in rs.startup_defects()))
        with patched_schemas(lim=lambda l: l["bytes"].pop("antecedent")):
            self.assertTrue(any("byte bounds" in d for d in rs.startup_defects()))

    def test_a_template_whose_placeholders_differ_from_its_renderer_is_a_defect(self):
        with mock.patch.object(rs, "TEMPLATES", {"bp_draft.md": ("draft", rs.PLACEHOLDERS_BP_DRAFT[:-1]), "bp_screen.md": rs.TEMPLATES["bp_screen.md"]}):
            self.assertTrue(any("bp_draft.md: placeholders" in d for d in rs._renderer_defects()))

    def test_the_gate_digest_binds_the_files(self):
        d = rs.gate_digest()
        self.assertEqual(d, rs.gate_digest())
        real = Path.read_bytes
        with mock.patch.object(Path, "read_bytes", lambda p: real(p) + (b" " if p.name == rs.LIMITS_FILE else b"")):
            self.assertNotEqual(rs.gate_digest(), d)

    def test_bounds_are_read_from_one_place(self):
        self.assertEqual((rs.bound("draft", "clauses"), rs.bound("draft", "candidates"), rs.bound("screen", "missed_obligations"),
                          rs.bound("screen", "uncovered_situations"), rs.bound("screen", "clause_assessments")), (24, 48, 12, 24, 48))
        self.assertEqual((rs.limits()["per_clause_candidates"], rs.limits()["bytes"]["antecedent"], rs.limits()["bytes"]["binder_class"]), (6, 6000, 1000))


class Answers(unittest.TestCase):
    """Each bound of the answer schemas at its limit and one beyond it."""

    def ok(self, kind, value):
        self.assertEqual(rs.answer_errors(kind, value), [])

    def bad(self, kind, value, why=""):
        errs = rs.answer_errors(kind, value)
        self.assertTrue(errs, value if not isinstance(value, dict) else list(value))
        if why:
            self.assertTrue(any(why in e for e in errs), errs)

    def test_clauses_and_candidates_at_and_beyond_their_bounds(self):
        cl = [{"id": f"C{i}", "quote": "A driver shall yield to a pedestrian."} for i in range(1, 25)]
        self.ok("draft", draft(clauses=cl))
        self.bad("draft", draft(clauses=cl + [{"id": "C25", "quote": "x"}]))
        cands = [candidate(f"P{i}") for i in range(1, 49)]
        self.ok("draft", draft(*cands))
        self.bad("draft", draft(*cands, candidate("P49")))

    def test_field_lengths_and_closed_objects(self):
        self.ok("draft", draft(candidate("P1", span_quote="x" * 400)))
        self.bad("draft", draft(candidate("P1", span_quote="x" * 401)), "span_quote")
        self.bad("draft", draft(candidate("P1", law_id="L")), "law_id")
        self.bad("draft", draft(candidate("P1", binders=[{"name": "v", "cls": car()}] * 4)), "binders")
        self.ok("draft", draft(candidate("P1", conditions=[{"text": "", "quote": "q"}] * 6)))
        self.bad("draft", draft(candidate("P1", conditions=[{"text": "", "quote": "q"}] * 7)), "conditions")

    def test_category_fixes_expected_and_exception_polarity(self):
        self.bad("draft", draft(candidate("P1", expected="not_violated")))
        self.bad("draft", draft(candidate("P1", exceptions=[{"text": "", "quote": "q", "use": "premise"}])))
        self.ok("draft", draft(candidate("P1", "must_not_flag", exceptions=[{"text": "", "quote": "q", "use": "premise"}])))
        self.bad("draft", draft(candidate("P1", category="invariance")))

    def test_screen_bounds(self):
        m = {"quote": "q", "reason": "r"}
        u = {"clause": "C1", "category": "must_detect", "situation": "s", "quote": "q"}
        self.ok("screen", screen(missed=[m] * 12, uncovered=[u] * 24))
        self.bad("screen", screen(missed=[m] * 13), "missed_obligations")
        self.bad("screen", screen(uncovered=[u] * 25), "uncovered_situations")
        a = assess("C1", "must_detect", "properties_given")
        self.ok("screen", screen(assessments=[a] * 48))
        self.bad("screen", screen(assessments=[a] * 49), "clause_assessments")

    def test_screen_conditionals(self):
        major = item("P1"); major["conditions"][0].update(rating="major_deviation")
        self.bad("screen", screen(major), "distinction_changed")
        minor = item("P1"); minor["conditions"][0].update(rating="minor_deviation")
        self.bad("screen", screen(minor), "approved_abstraction")
        exc = item("P1"); exc["conditions"][0].update(kind="exception")
        self.bad("screen", screen(exc), "exception_use")
        self.bad("screen", screen(behaviour={"assessment": "checkable", "kind": "other", "reason": "r"}))
        self.bad("screen", screen(behaviour={"assessment": "no_checkable_behaviour", "reason": "r"}))
        self.ok("screen", screen(behaviour={"assessment": "no_checkable_behaviour", "kind": "other", "quote": "q", "reason": "r"}))

    def test_the_byte_bound_of_a_whole_answer(self):
        a = draft(candidate("P1"))
        n = rs.compact_bytes(a)
        with patched_schemas(lim=lambda l: l["bytes"].update(draft_answer=n)):
            self.ok("draft", a)
        with patched_schemas(lim=lambda l: l["bytes"].update(draft_answer=n - 1)):
            self.bad("draft", a, "beyond the bound")


class InvalidAnswers(unittest.TestCase):
    """An answer invalid as a whole publishes nothing; a valid one is decided candidate by candidate."""

    def test_a_valid_answer_is_adopted(self):
        out = rs.adopt_answer(good(), CTX)
        self.assertEqual((out["state"], adopted(out)), ("ok", ["P1", "P2"]))
        self.assertNotIn("zero_adopted", out)
        rows = rs.record_rows("L", out, "a" * 32, "b" * 64)
        self.assertEqual([e for r in rows for e in rs.errors("record", r)], [])
        self.assertEqual(out["screen_assessments"], [{"clause": "C2", "category": c, "agrees_no_property": True,
                                                      "basis": "unless directed otherwise by an officer"} for c in rs.CATEGORIES])

    def test_an_invalid_draft_or_screen_publishes_no_set(self):
        for kind, bad in (("draft", {**good()[0]["draft"], "extra": 1}), ("screen", {**good()[0]["screen"], "items": "none"})):
            rounds = good(); rounds[0][kind] = bad
            out = rs.adopt_answer(rounds, CTX)
            self.assertEqual((out["state"], out["records"], out.get("zero_adopted")), ("failed", [], None), kind)
            self.assertTrue(any("invalid as a whole" in r for r in out["reasons"]))
        rounds = good(); rounds[0]["draft"]["candidates"][1]["span_quote"] = "x" * 401
        out = rs.adopt_answer(rounds, CTX)
        self.assertEqual(out["state"], "failed")
        self.assertEqual([d["id"] for d in out["diagnostics"][0]["candidates"]], ["P1", "P2"])   # kept as diagnostics only
        self.assertEqual(out["diagnostics"][0]["candidates"][0]["reasons"], [])

    def test_one_or_two_rounds(self):
        self.assertEqual(rs.adopt_answer([], CTX)["state"], "failed")
        self.assertEqual(rs.adopt_answer(good() * 2, CTX)["state"], "ok")
        self.assertEqual(rs.adopt_answer(good() * 3, CTX)["state"], "failed")
        two = good() * 2; two[0] = {**two[0], "screen": None}
        self.assertEqual(rs.adopt_answer(two, CTX)["state"], "ok")              # round one's screen may be absent
        two = good() * 2; two[1] = {**two[1], "screen": None}
        self.assertEqual(rs.adopt_answer(two, CTX)["state"], "failed")          # the last round's never

    def test_an_invalid_answer_that_would_confirm_no_checkable_behaviour_gives_no_exemption(self):
        rounds = no_behaviour_rounds()
        self.assertEqual(rs.adopt_answer(rounds, CTX)["zero_adopted"]["codes"], ["no_checkable_behaviour"])
        rounds[0]["screen"]["law_behaviour"]["extra"] = "x"
        out = rs.adopt_answer(rounds, CTX)
        self.assertEqual((out["state"], out.get("zero_adopted")), ("failed", None))
        self.assertEqual(br.classify({**out, "spec_key": "k"}, [], [], [], "strict", final=True)["disposition"], "failed")

    def test_a_valid_answer_with_refused_candidates_keeps_the_rest_and_records_holes(self):
        cands = [candidate(f"P{i}") for i in range(1, 8)]                   # seven pass the static checks in C1
        rounds = [{"draft": draft(*cands), "screen": screen(*[item(c["id"]) for c in cands[:6]],
                                                            assessments=[assess("C1", "must_detect", "properties_given")])}]
        out = rs.adopt_answer(rounds, CTX)
        self.assertEqual((out["state"], adopted(out)), ("ok", [f"P{i}" for i in range(1, 7)]))
        self.assertTrue(any(r.startswith("count_or_size_refused") for r in reasons_of(out, "P7")))
        self.assertIn("count_or_size_refused", [h["kind"] for h in out["holes"]])
        big = candidate("P1", antecedent={"and": [{"cmp": "gt", "lhs": speed(), "rhs": lit(MPH15)}] * 60})
        out = rs.adopt_answer([{"draft": draft(big, candidate("P2", "must_not_flag", "le")), "screen": screen(item("P2"))}], CTX)
        self.assertEqual((out["state"], adopted(out)), ("ok", ["P2"]))
        self.assertEqual(next(a for a in out["adoption"] if a["property"] == "P1")["not_executable"], "count_or_size")

    def test_six_candidates_of_a_clause_are_within_the_bound(self):
        cands = [candidate(f"P{i}") for i in range(1, 7)]
        out = rs.adopt_answer([{"draft": draft(*cands), "screen": screen(*[item(c["id"]) for c in cands])}], CTX)
        self.assertEqual(len(adopted(out)), 6)


def no_behaviour_rounds(kind: str = "definition_or_scope") -> list[dict]:
    d = draft(clauses=[{"id": "C1", "quote": "A driver shall not drive faster than 15 miles per hour in a school zone.",
                        "no_property": [{"category": c, "reason": "r"} for c in rs.CATEGORIES]}])
    s = screen(assessments=[assess("C1", c, "reason_confirmed") for c in rs.CATEGORIES],
               behaviour={"assessment": "no_checkable_behaviour", "kind": kind, "quote": "in a school zone", "reason": "it defines a scope"})
    return [{"draft": d, "screen": s}]


class Language(unittest.TestCase):
    """The property language's static checks, each on both sides of its line."""

    def refused(self, ante, why, **over):
        errs, ne = rs.static_check(candidate("P1", antecedent=ante, **over), CTX)
        self.assertEqual(ne, "outside_language", errs)
        self.assertTrue(any(why in e for e in errs), errs)

    def passes(self, ante, **over):
        self.assertEqual(rs.static_check(candidate("P1", antecedent=ante, **over), CTX), ([], None))

    def comp(self, m, c, var="v"):
        return {"measure": m, "args": [{"var": var}, {"lit": c}]}

    def test_a_world_component_alone_is_refused_and_a_dot_product_passes(self):
        obs = {"observations": ["kin.velocity", "st.lane_direction"]}
        bind = {"binders": [{"name": "v", "cls": car(), "subject": True},
                            {"name": "r", "cls": {"atom": "st_lane", "args": [{"var": "r"}], "params": []}}]}
        zero = lit(Fraction(0))
        self.refused({"cmp": "gt", "lhs": self.comp("kin_velocity", "x"), "rhs": zero}, "is fixed", **obs, **bind)
        dot = {"add": [{"mul": [self.comp("kin_velocity", "x"), self.comp("st_lane_direction", "x", "r")]},
                       {"mul": [self.comp("kin_velocity", "y"), self.comp("st_lane_direction", "y", "r")]}]}
        self.passes({"cmp": "lt", "lhs": dot, "rhs": zero}, **obs, **bind)
        cross = {"sub": [{"mul": [self.comp("kin_velocity", "x"), self.comp("st_lane_direction", "y", "r")]},
                         {"mul": [self.comp("kin_velocity", "y"), self.comp("st_lane_direction", "x", "r")]}]}
        self.passes({"cmp": "eq", "lhs": cross, "rhs": zero}, **obs, **bind)
        mixed = {"add": [{"mul": [self.comp("kin_velocity", "x"), self.comp("st_lane_direction", "y", "r")]},
                         {"mul": [self.comp("kin_velocity", "y"), self.comp("st_lane_direction", "y", "r")]}]}
        self.refused({"cmp": "lt", "lhs": mixed, "rhs": zero}, "is fixed", **obs, **bind)

    def test_positions_only_through_differences(self):
        obs = {"observations": ["kin.position"]}
        bind = {"binders": [{"name": "v", "cls": car(), "subject": True}, {"name": "w", "cls": car("w")}]}
        def d(c):
            return {"sub": [self.comp("kin_position", c), self.comp("kin_position", c, "w")]}
        sq = {"add": [{"mul": [d("x"), d("x")]}, {"mul": [d("y"), d("y")]}]}
        self.refused({"cmp": "lt", "lhs": sq, "rhs": lit(Fraction(0), "metre")}, "units", **obs, **bind)   # m² against m
        dot_pos = {"add": [{"mul": [self.comp("kin_position", "x"), self.comp("kin_position", "x", "w")]},
                           {"mul": [self.comp("kin_position", "y"), self.comp("kin_position", "y", "w")]}]}
        self.refused({"cmp": "gt", "lhs": dot_pos, "rhs": {"mul": [lit(Fraction(0), "metre"), lit(Fraction(0), "metre")]}}, "is fixed", **obs, **bind)

    def test_frames(self):
        bind = {"binders": [{"name": "v", "cls": car(), "subject": True}, {"name": "w", "cls": car("w")}]}
        bearing = {"measure": "rel_bearing", "args": [{"var": "v"}, {"var": "w"}, {"lit": "x"}]}
        self.passes({"cmp": "gt", "lhs": bearing, "rhs": lit(Fraction(0), "metre")}, observations=["rel.bearing"], **bind)
        other = {"measure": "rel_bearing", "args": [{"var": "w"}, {"var": "v"}, {"lit": "x"}]}
        self.refused({"cmp": "gt", "lhs": {"add": [bearing, other]}, "rhs": lit(Fraction(0), "metre")}, "different frames",
                     observations=["rel.bearing"], **bind)

    def test_constants(self):
        self.passes({"cmp": "gt", "lhs": speed(), "rhs": lit(MPH15)})
        self.refused({"cmp": "gt", "lhs": speed(), "rhs": lit(MPH15 + 1)}, "not a figure")
        self.passes({"cmp": "gt", "lhs": speed(), "rhs": lit(Fraction(0))})
        self.refused({"cmp": "gt", "lhs": {"add": [speed(), lit(Fraction(0))]}, "rhs": lit(MPH15)}, "literal 0 inside")
        self.refused({"cmp": "gt", "lhs": speed(), "rhs": {"add": [lit(MPH15), lit(MPH15)]}}, "literals alone")
        self.refused({"cmp": "gt", "lhs": lit(MPH15), "rhs": lit(Fraction(0))}, "none of whose sides reads a measure")

    def test_units_vocabulary_grammar_variables_and_observations(self):
        self.refused({"cmp": "gt", "lhs": speed(), "rhs": lit(Fraction(0), "metre")}, "units")
        self.refused({"cmp": "gt", "lhs": {"measure": "kin_flux", "args": [{"var": "v"}]}, "rhs": lit(Fraction(0))}, "not a measure")
        self.refused({"and": [{"atom": "kin_teleports", "args": [{"var": "v"}], "params": []}, {"cmp": "gt", "lhs": speed(), "rhs": lit(Fraction(0))}]},
                     "not an atom")
        self.refused({"cmp": "gt", "lhs": speed(), "rhs": {"param": "p.limit"}}, "outside_language")
        self.refused({"cmp": "gt", "lhs": {"div": [speed(), speed()]}, "rhs": lit(Fraction(0))}, "outside_language")
        self.refused({"always": {"cmp": "gt", "lhs": speed(), "rhs": lit(Fraction(0))}}, "outside_language")
        self.refused({"cmp": "gt", "lhs": speed("u"), "rhs": lit(Fraction(0))}, "bound by no binder")
        self.refused({"cmp": "gt", "lhs": speed(), "rhs": lit(Fraction(0))}, "observations omit", observations=["kin.velocity"])
        self.refused({"cmp": "gt", "lhs": speed(), "rhs": lit(Fraction(0))}, "neither the antecedent", observations=["kin.speed", "kin.velocity"])
        self.passes({"cmp": "gt", "lhs": speed(), "rhs": lit(Fraction(0))}, observations=["kin.speed", "ru.motor_vehicle"])

    def test_byte_bounds_of_a_class_and_an_antecedent(self):
        a = {"cmp": "gt", "lhs": speed(), "rhs": lit(Fraction(0))}
        n = rs.compact_bytes(a)
        with patched_schemas(lim=lambda l: l["bytes"].update(antecedent=n)):
            self.passes(a)
        with patched_schemas(lim=lambda l: l["bytes"].update(antecedent=n - 1)):
            self.assertEqual(rs.static_check(candidate("P1", antecedent=a), CTX)[1], "count_or_size")
        m = rs.compact_bytes(car())
        with patched_schemas(lim=lambda l: l["bytes"].update(binder_class=m - 1)):
            self.assertEqual(rs.static_check(candidate("P1", antecedent=a), CTX)[1], "count_or_size")


class Gate(unittest.TestCase):
    """The cross-field checks that JSON Schema cannot state."""

    def run_(self, d, s, withdrawn=frozenset()):
        return rs.adopt_answer([{"draft": d, "screen": s}], CTX, withdrawn)

    def test_g2_duplicate_ids_refuse_all_of_them(self):
        out = self.run_(draft(candidate("P1"), candidate("P1", "must_not_flag", "le")), screen(item("P1")))
        self.assertEqual(adopted(out), [])
        self.assertTrue(all(any("more than once" in r for r in a["adoption"]["reasons"]) for a in out["adoption"]))

    def test_g3_a_quote_that_occurs_twice_needs_its_occurrence(self):
        twice = {"id": "C1", "quote": "A driver shall yield to a pedestrian"}
        c = candidate("P1", span_quote="shall yield to a pedestrian", conditions=[{"text": "", "quote": "yield to a pedestrian"}],
                      antecedent={"cmp": "gt", "lhs": speed(), "rhs": lit(Fraction(0))})
        it = item("P1"); it["conditions"][0]["condition_quote"] = "yield to a pedestrian"
        out = self.run_(draft(c, clauses=[twice]), screen(it, assessments=[assess("C1", "must_detect", "properties_given")]))
        self.assertEqual(adopted(out), [])
        self.assertTrue(any("occurs 2 times" in r for r in reasons_of(out, "P1")))
        for occ in (1, 2):
            out = self.run_(draft(c, clauses=[{**twice, "occurrence": occ}]), screen(it, assessments=[assess("C1", "must_detect", "properties_given")]))
            self.assertEqual(adopted(out), ["P1"], occ)
        k1, k2 = (rs.clause_key(LAW, twice["quote"], n, "author") for n in (1, 2))
        self.assertNotEqual(k1, k2)
        out = self.run_(draft(c, clauses=[{**twice, "occurrence": 3}]), screen(it))
        self.assertTrue(any("does not exist" in r for r in reasons_of(out, "P1")))

    def test_g4_the_span_lies_inside_its_clause(self):
        out = self.run_(draft(candidate("P1", span_quote="shall yield to a pedestrian unless")), screen(item("P1")))
        self.assertTrue(any("inside its clause" in r for r in reasons_of(out, "P1")))

    def test_g7_quotes_come_from_the_law_a_definition_or_the_conventions(self):
        out = self.run_(draft(candidate("P1", conditions=[{"text": "", "quote": "faster than twenty miles"}])), screen(item("P1")))
        self.assertTrue(any("neither the law" in r for r in reasons_of(out, "P1")))
        out = self.run_(draft(candidate("P1", conditions=[{"text": "", "quote": "faster than 15 ... hour"}])), screen(item("P1")))
        self.assertTrue(any("ellipsis" in r for r in reasons_of(out, "P1")))

    def test_g8_a_gap_passes_the_static_checks_but_is_not_executable(self):
        g = candidate("P1", gaps=[{"words": "school zone", "distinction": "place", "why_no_atom": "no zone atom"}])
        out = self.run_(draft(g), screen(item("P1")))
        rec = next(a for a in out["adoption"] if a["property"] == "P1")
        self.assertEqual((rec["static"]["ok"], rec["not_executable"], rec["adoption"]["adopted"]), (True, "gap", False))
        self.assertIn("expression_gap", [h["kind"] for h in out["holes"]])

    def test_g10_a_missing_or_doubled_item_is_a_rejection(self):
        out = self.run_(draft(candidate("P1"), candidate("P2", "must_not_flag", "le")), screen(item("P1"), item("P1")))
        self.assertEqual(adopted(out), [])
        self.assertTrue(any("more than one item" in r for r in reasons_of(out, "P1")))
        self.assertTrue(any("no item" in r for r in reasons_of(out, "P2")))

    def test_g11_g13_exemptions_need_an_explicit_consistent_confirmation(self):
        d = draft(candidate("P1"), candidate("P2", "must_not_flag", "le"))
        out = self.run_(d, screen(item("P1"), item("P2")))
        self.assertEqual({(a["clause"], a["category"]) for a in out["screen_assessments"]}, {("C2", c) for c in rs.CATEGORIES})
        for assessments in ([assess("C1", "must_detect", "properties_given"), assess("C1", "must_not_flag", "properties_given"),
                             assess("C2", "must_detect", "reason_rejected", "unless directed otherwise by an officer")],
                            [assess("C1", "must_detect", "properties_given"), assess("C1", "must_not_flag", "properties_given"),
                             assess("C2", "must_detect", "reason_confirmed", "unless directed otherwise by an officer"),
                             assess("C2", "must_detect", "reason_confirmed", "unless directed otherwise by an officer")],
                            [assess("C1", "must_detect", "properties_given"), assess("C1", "must_not_flag", "properties_given"),
                             assess("C2", "must_detect", "reason_confirmed", "A driver shall not drive")]):
            out = self.run_(d, screen(item("P1"), item("P2"), assessments=assessments))
            self.assertNotIn(("C2", "must_detect"), {(a["clause"], a["category"]) for a in out["screen_assessments"]})
            self.assertIn(("exemption_not_confirmed", "C2", "must_detect"), {(h["kind"], h["clause"], h["category"]) for h in out["holes"]})

    def test_g12_the_adoption_rule(self):
        d = draft(candidate("P1"))
        minor = item("P1"); minor["conditions"][0].update(rating="minor_deviation", approved_abstraction={"section": "9", "quote": "not in the conventions"})
        self.assertTrue(any("approved abstraction" in r for r in reasons_of(self.run_(d, screen(minor)), "P1")))
        minor["conditions"][0]["approved_abstraction"]["quote"] = "read through the device that shows it"
        self.assertEqual(adopted(self.run_(d, screen(minor))), ["P1"])
        path = item("P1"); path["conditions"][0]["antecedent_path"] = "antecedent.lhs.nowhere"
        self.assertTrue(any("does not resolve" in r for r in reasons_of(self.run_(d, screen(path)), "P1")))
        term = item("P1"); term["conditions"][0]["terms"][0]["status"] = "ungrounded"
        self.assertEqual(adopted(self.run_(d, screen(term))), [])
        concl = item("P1", conclusion_ok="cannot_tell")
        self.assertEqual(adopted(self.run_(d, screen(concl))), [])
        unrated = candidate("P1", conditions=[{"text": "", "quote": "faster than 15 miles per hour"}, {"text": "", "quote": "in a school zone"}])
        self.assertTrue(any("not rated" in r for r in reasons_of(self.run_(draft(unrated), screen(item("P1"))), "P1")))
        exc = candidate("P1", "must_not_flag", "le", exceptions=[{"text": "", "quote": "in a school zone", "use": "premise"}])
        it = item("P1"); it["conditions"].append({"condition_quote": "in a school zone", "kind": "exception", "exception_use": "excluded",
                                                   "terms": [], "antecedent_path": "antecedent", "rating": "full_match", "reason": "r"})
        self.assertTrue(any("is rated as excluded" in r for r in reasons_of(self.run_(draft(exc), screen(it)), "P1")))
        it["conditions"][-1]["exception_use"] = "premise"
        self.assertEqual(adopted(self.run_(draft(exc), screen(it))), ["P1"])
        unc = {"clause": "C1", "category": "must_detect", "situation": "s", "quote": "faster than 15 miles"}
        self.assertTrue(any("uncovered" in r for r in reasons_of(self.run_(d, screen(item("P1"), uncovered=[unc])), "P1")))
        self.assertEqual(adopted(self.run_(d, screen(item("P1"), uncovered=[{**unc, "category": "must_not_flag"}]))), ["P1"])

    def test_g14_round_two_and_withdrawn_identities(self):
        r1 = good()[0]
        moved = candidate("P2", "must_not_flag", "le", clause="C2", span_quote="shall yield to a pedestrian unless")
        r2 = {"draft": draft(candidate("P1"), moved), "screen": screen(item("P1"), item("P2"))}
        out = rs.adopt_answer([r1, r2], CTX)
        self.assertTrue(any("changed its clause" in r for r in reasons_of(out, "P2")))
        r2 = {"draft": draft(candidate("P1")), "screen": screen(item("P1"), assessments=[assess("C1", "must_detect", "properties_given")])}
        out = rs.adopt_answer([r1, r2], CTX)
        self.assertEqual(next(a["adoption"]["state"] for a in out["adoption"] if a["property"] == "P2"), "dropped_in_round_two")
        gone = rs.identity(candidate("P1"))
        out = rs.adopt_answer(good(), CTX, frozenset({gone}))
        self.assertEqual(adopted(out), ["P2"])                              # same antecedent, the other category: kept
        self.assertTrue(any(r.startswith("withdrawn") for r in reasons_of(out, "P1")))
        renamed = rs.adopt_answer([{"draft": draft(candidate("P9")), "screen": screen(item("P9"))}], CTX, frozenset({gone}))
        self.assertEqual(adopted(renamed), [])                              # another display id, the same identity

    def test_g15_g16_and_the_zero_adoption_causes(self):
        out = rs.adopt_answer(no_behaviour_rounds(), CTX)
        z = out["zero_adopted"]
        self.assertEqual((z["cause"], z["codes"], z["screen_confirms"]), ("no_checkable_behaviour", ["no_checkable_behaviour"], True))
        self.assertEqual(br.zero_adopted({**out, "spec_key": "k"}, final=True)[0], br.NO_BEHAVIOUR)
        self.assertEqual(rs.adopt_answer(no_behaviour_rounds("other"), CTX)["zero_adopted"]["cause"], "unclear")
        rounds = no_behaviour_rounds(); rounds[0]["screen"]["clause_assessments"].pop()
        self.assertNotEqual(rs.adopt_answer(rounds, CTX)["zero_adopted"]["cause"], "no_checkable_behaviour")
        rounds = no_behaviour_rounds(); rounds[0]["screen"]["law_behaviour"]["quote"] = "words the law lacks"
        self.assertEqual(rs.adopt_answer(rounds, CTX)["zero_adopted"]["cause"], "unclear")
        rounds = no_behaviour_rounds(); rounds[0]["screen"]["missed_obligations"] = [{"quote": "not the law's words", "reason": "r"}]
        out = rs.adopt_answer(rounds, CTX)
        self.assertEqual(out["zero_adopted"]["cause"], "mixed")                 # N with M
        self.assertIn("missed_obligation", [h["kind"] for h in out["holes"]])
        rounds = no_behaviour_rounds(); rounds[0]["screen"]["law_behaviour"] = {"assessment": "checkable", "reason": "it decides a speed"}
        self.assertEqual(rs.adopt_answer(rounds, CTX)["zero_adopted"]["cause"], "meaning_dispute")
        self.assertEqual(br.zero_adopted({**rs.adopt_answer(rounds, CTX), "spec_key": "k"}, final=True)[0], "dispute")
        self.assertIn("(not words of the law)", next(h["detail"] for h in out["holes"] if h["kind"] == "missed_obligation"))
        bad = item("P1", item_cause="adoptable"); bad["conditions"][0].update(rating="major_deviation", distinction_changed="action")
        out = self.run_(draft(candidate("P1")), screen(bad))
        self.assertIn("P1: item_cause adoptable disagrees with its ratings", out["zero_adopted"]["signals"]["U"])
        minor = item("P1", item_cause="adoptable"); minor["conditions"][0].update(rating="minor_deviation",
                                                                                   approved_abstraction={"section": "9", "quote": "not in the conventions"})
        out = self.run_(draft(candidate("P1")), screen(minor))
        self.assertIn("P1: minor_deviation", out["zero_adopted"]["signals"]["M"])         # an abstraction the conventions lack is none
        nx = item("P1", item_cause="not_expressible", conclusion_ok="no")
        out = self.run_(draft(candidate("P1")), screen(nx))
        self.assertTrue(out["zero_adopted"]["signals"]["U"])


class Identity(unittest.TestCase):
    """A property's identity: binders with class and subject, antecedent, category, expected; never its id."""

    def test_identity_parts(self):
        p = candidate("P1")
        self.assertEqual(rs.identity(p), rs.identity({**p, "id": "P7", "clause": "C2", "span_quote": "other"}))
        self.assertNotEqual(rs.identity(p), rs.identity(candidate("P1", "must_not_flag", "gt")))
        self.assertNotEqual(rs.identity(p), rs.identity(candidate("P1", cls=car(atom="ru_bicycle"))))
        self.assertNotEqual(rs.identity(p), rs.identity({**p, "binders": [{**p["binders"][0], "subject": False}]}))
        self.assertEqual(rs.antecedent_sha(p), rs.antecedent_sha(candidate("P1", "must_not_flag", "gt")))
        self.assertEqual(rs.identity(p), rs.identity(json.loads(json.dumps(p, ensure_ascii=True))))

    def test_active_set_record_validates(self):
        w = {"identity": "a" * 64, "antecedent_sha": "b" * 64, "property": "P1", "decision_sha": "c" * 64, "date": "2026-11-18T00:00:00"}
        rec = rs.active_set_record("L", {"set_id": "d" * 32, "supersedes": None, "version": 2, "withdrawals": [w]}, "e" * 32)
        self.assertEqual(rs.errors("active_set", rec), [])
        self.assertTrue(rs.errors("active_set", {**rec, "withdrawals": [{k: v for k, v in w.items() if k != "identity"}]}))
        cov = {"schema": "bp_coverage/1", "clauses": [{"clause_key": "a" * 64, "display_id": "C1", "source": "author",
                                                      "categories": {"must_detect": "covered", "must_not_flag": "hole"}}],
               "holes": [{"hole_key": "b" * 64, "kind": "no_adopted_property", "clause_key": "a" * 64, "category": "must_not_flag",
                          "antecedent_sha": None, "detail": ""}], "counts": {"adopted": 1, "executed": 1, "passed": 1}, "policy": "strict"}
        self.assertEqual(rs.errors("coverage", cov), [])
        self.assertTrue(rs.errors("coverage", {**cov, "holes": [{**cov["holes"][0], "kind": "lost"}]}))


class Prompts(unittest.TestCase):
    """The templates render through the prompt renderer, carry the schemas, and pass the doctor."""

    def values(self, ph, kind):
        return {p: f"<{p}>" for p in ph} | {"output_schema": rs.schema_text(kind), "property_language": rs.property_language()}

    def test_the_two_templates_render_with_their_schema_and_the_language(self):
        for tmpl, (kind, ph) in rs.TEMPLATES.items():
            text = render.render(tmpl, self.values(ph, kind))
            self.assertIn(rs.schema_text(kind), text)
            self.assertIn(rs.property_language(), text)
            self.assertNotRegex(text, r"\{(?:" + "|".join(ph) + r")\}")              # the final request: no placeholder left
            with self.assertRaises(KeyError):
                render.render(tmpl, {k: v for k, v in self.values(ph, kind).items() if k != "law"})

    def test_the_property_language_states_only_the_two_categories(self):
        text = rs.property_language()
        for word in ("invariance", "no_false_certainty", "pilot"):
            self.assertNotIn(word, text)
        self.assertEqual(text.splitlines()[0], "# Property language")
        self.assertIn("neither a pass nor a violation of the property", text)

    def test_the_review_findings_section_shows_only_when_asked(self):
        raw = (paths.PROMPTS / "node_repair.md").read_text(encoding="utf-8")
        values = {k: f"<{k}>" for k in set(re.findall(r"\{([a-z_]+)\}", raw))}
        without = render.render("node_repair.md", values)
        with_ = render.render("node_repair.md", values, {"review_findings": True})
        self.assertEqual(render.render("node_repair.md", values, {"review_findings": False}), without)
        self.assertNotIn("## Review findings", without)
        self.assertNotIn("<!--", without + with_)
        self.assertIn("## Review findings", with_)
        self.assertIn("## Output", without)
        self.assertNotIn("\n\n\n## Output", without + with_)
        self.assertEqual(len(with_) - len(without), len(raw) - len(without) - len("<!-- section:review_findings -->\n<!-- /section:review_findings -->\n\n"))
        self.assertIn("Existing label-check results\n  may also be supplied during a review repair", raw)
        self.assertNotIn("no label evidence is\n  supplied", raw)

    def test_every_combination_of_the_repair_sections_renders_whole(self):
        """Each conditional block of the repair prompt, alone or with the others (a review repair under
        a frozen parameter set opens two), is shown exactly when asked, leaves no marker and no
        placeholder in the request, and closing it gives the template with its block deleted."""
        raw = (paths.PROMPTS / "node_repair.md").read_text(encoding="utf-8")
        names = re.findall(r"<!-- section:([a-z_]+) -->", raw)
        self.assertIn("review_findings", names)
        blocks = {n: re.search(r"<!-- section:" + n + r" -->\n(.*?)<!-- /section:" + n + r" -->\n\n?", raw, re.S) for n in names}
        values = {k: f"<{k}>" for k in set(re.findall(r"\{([a-z_]+)\}", raw))}
        for bits in itertools.product((False, True), repeat=len(names)):
            shown = dict(zip(names, bits))
            with self.subTest(sections=shown):
                text = render.render("node_repair.md", values, shown)
                self.assertNotRegex(text, r"<!-- /?section:")
                self.assertNotRegex(text, r"\{[a-z_]+\}")
                self.assertNotIn("\n\n\n", text)
                expected = raw
                for n, m in blocks.items():
                    expected = expected.replace(m.group(0), m.group(1) if shown[n] else "")
                for k, v in values.items():
                    expected = expected.replace("{" + k + "}", v)
                self.assertEqual(text, expected)

    def test_the_doctor_passes_the_prompt_and_schema_checks(self):
        import sys
        sys.path.insert(0, str(paths.REPO))
        from scripts.diagnostics import doctor
        doc = doctor.Doctor(paths.REPO, paths.LIBRARY)
        for check in (doc.prompts_are_law_free, doc.prompts_are_vocabulary_free, doc.placeholders_supplied, doc.review_schemas_consistent):
            r = check()
            self.assertEqual(r.status, doctor.OK, r)

    def test_the_doctor_refuses_a_stale_name_in_the_language_and_a_defined_word(self):
        import sys
        sys.path.insert(0, str(paths.REPO))
        from scripts.diagnostics import doctor
        doc = doctor.Doctor(paths.REPO, paths.LIBRARY)
        with tempfile.TemporaryDirectory() as t:
            lang = Path(t) / rs.PROPERTY_LANGUAGE
            lang.write_text(rs.property_language().replace("`kin_heading`", "`kin_bearing_world`"))
            doc.prompts = [lang]
            r = doc.prompts_are_vocabulary_free()
            self.assertEqual(r.status, doctor.FAIL)
            self.assertIn("kin_bearing_world", r.detail)
            other = Path(t) / "other.md"
            other.write_text("A component in a road\nuser's frame.")
            doc.prompts = [other]
            self.assertEqual(doc.prompts_are_vocabulary_free().status, doctor.OK)
            other.write_text("the kin_velocity of a road")
            self.assertEqual(doc.prompts_are_vocabulary_free().status, doctor.FAIL)


class Sections(unittest.TestCase):
    """The prompt renderer's conditional blocks, on small templates: shown only where the caller names
    them true, a placeholder only a closed block holds need not be supplied, a malformed or unknown
    block is refused, and a template whose lines were joined renders the same blocks."""

    @contextmanager
    def templates(self, **files):
        with tempfile.TemporaryDirectory() as t:
            for name, text in files.items():
                (Path(t) / f"{name}.md").write_text(text, encoding="utf-8")
            with mock.patch.object(paths, "PROMPTS", Path(t)):
                yield

    T = "Head {a}.\n\n<!-- section:extra -->\nOnly with {b}.\n\n<!-- /section:extra -->\n\nTail.\n"

    def test_a_block_is_shown_only_when_named_true(self):
        with self.templates(t=self.T):
            closed = "Head 1.\n\nTail.\n"
            self.assertEqual(render.render("t.md", {"a": "1"}), closed)
            self.assertEqual(render.render("t.md", {"a": "1"}, None), closed)
            self.assertEqual(render.render("t.md", {"a": "1"}, {"extra": False}), closed)
            self.assertEqual(render.render("t.md", {"a": "1", "b": "2"}, {"extra": True}), "Head 1.\n\nOnly with 2.\n\nTail.\n")

    def test_a_placeholder_of_an_open_block_must_be_supplied(self):
        with self.templates(t=self.T):
            with self.assertRaises(KeyError):
                render.render("t.md", {"a": "1"}, {"extra": True})
            with self.assertRaises(KeyError):
                render.render("t.md", {"b": "2"})

    def test_a_malformed_or_unknown_block_or_a_malformed_selection_is_refused(self):
        unpaired = self.T.replace("<!-- /section:extra -->\n", "")
        nested = self.T.replace("Only with", "<!-- section:inner -->\nx\n<!-- /section:inner -->\nOnly with")
        with self.templates(unpaired=unpaired, nested=nested, t=self.T):
            for name in ("unpaired", "nested"):
                for shown in (None, {"extra": True}):
                    with self.subTest(template=name, sections=shown), self.assertRaises(ValueError):
                        render.render(f"{name}.md", {"a": "1", "b": "2"}, shown)
            with self.assertRaises(KeyError):
                render.render("t.md", {"a": "1"}, {"no_such": False})
            for bad in (("extra",), {"extra": "yes"}, {"extra": 1}):
                with self.subTest(sections=bad), self.assertRaises(TypeError):
                    render.render("t.md", {"a": "1", "b": "2"}, bad)

    def test_a_template_whose_lines_were_joined_renders_the_same_blocks(self):
        with self.templates(t=" ".join(self.T.split())):
            self.assertEqual(" ".join(render.render("t.md", {"a": "1"}).split()), "Head 1. Tail.")
            self.assertEqual(" ".join(render.render("t.md", {"a": "1", "b": "2"}, {"extra": True}).split()), "Head 1. Only with 2. Tail.")


if __name__ == "__main__":
    unittest.main()


SLOW = "A driver shall proceed slowly."


def slow_rounds(screen_extra=None) -> list[dict]:
    zero = {"lit": {"num": 0, "den": 1}, "unit": "metre_per_second"}
    def cand(pid, cat, op):
        return {"id": pid, "clause": "C1", "span_quote": "shall proceed slowly", "category": cat,
                "binders": [{"name": "v", "cls": car(), "subject": True}],
                "conditions": [{"text": "", "quote": "proceed slowly"}], "exceptions": [], "observations": ["kin.speed"],
                "open_questions": [], "antecedent": {"cmp": op, "lhs": speed(), "rhs": zero},
                "expected": "violated" if cat == "must_detect" else "not_violated", "gaps": []}
    def it(pid):
        i = item(pid); i["conditions"][0]["condition_quote"] = "proceed slowly"
        i["conditions"][1]["condition_quote"] = "shall proceed"
        return i
    d = {"clauses": [{"id": "C1", "quote": SLOW}], "candidates": [cand("P1", "must_detect", "gt"), cand("P2", "must_not_flag", "le")],
         "distinctions": {"action": ["P1"], **{k: {"not_applicable": "n"} for k in rs.DISTINCTIONS[1:]}}}
    s = screen(it("P1"), it("P2"), assessments=[assess("C1", c, "properties_given", "shall proceed slowly") for c in rs.CATEGORIES])
    s.update(screen_extra or {})
    return [{"draft": d, "screen": s}]


def slow_no_behaviour() -> list[dict]:
    d = {"clauses": [{"id": "C1", "quote": SLOW, "no_property": [{"category": c, "reason": "r"} for c in rs.CATEGORIES]}],
         "candidates": [], "distinctions": {k: {"not_applicable": "n"} for k in rs.DISTINCTIONS}}
    s = screen(assessments=[assess("C1", c, "reason_confirmed", "shall proceed slowly") for c in rs.CATEGORIES],
               behaviour={"assessment": "no_checkable_behaviour", "kind": "purpose_or_policy", "quote": "proceed slowly", "reason": "r"})
    return [{"draft": d, "screen": s}]


def raw(rounds) -> dict:
    return {"state": "ok", "rounds": rounds, "calls": [{"label": "/review/bp_A", "request_sha": "q", "response_sha": "a"}]}


class Stage(unittest.TestCase):
    """The adoption path inside the review stage: raw answers through the gate, a whole-invalid answer
    publishing nothing, and withdrawals by identity."""

    def setUp(self):
        from scripts.tests import test_behaviour_review_stage as stage
        self.stage = stage

    def test_raw_answers_are_adopted_by_the_gate_and_checked(self):
        with self.stage.rworld(kind="labels") as (run, ledger, fake, persist):
            L1 = self.stage.L[1]
            self.stage.script(fake, L1, raw(slow_rounds()))
            self.assertEqual(self.stage.review(run, ledger, L1, persist), "reviewed")
            self.assertEqual(fake.check_calls[-1][3], ("P1", "P2"))
            pset = br.load_set(run, L1, run.review_states[L1]["active_set"]["set_id"])
            self.assertEqual([r["identity"] for r in pset["records"]], [rs.identity(r) for r in pset["records"]])
            rows = rs.record_rows(L1, pset, pset["set_id"], pset["generation_id"])
            self.assertEqual([e for r in rows for e in rs.errors("record", r)], [])

    def test_a_whole_invalid_answer_gives_neither_a_set_nor_an_exemption(self):
        with self.stage.rworld(kind="labels", property_attempts=1) as (run, ledger, fake, persist):
            L1, L2 = self.stage.L[1], self.stage.L[2]
            self.stage.script(fake, L1, raw(slow_no_behaviour()))
            self.assertEqual(self.stage.review(run, ledger, L1, persist), br.NO_BEHAVIOUR)
            bad = slow_no_behaviour(); bad[0]["screen"]["law_behaviour"]["extra"] = "x"
            self.stage.script(fake, L2, raw(bad))
            self.assertEqual(self.stage.review(run, ledger, L2, persist), "failed")
            st = run.review_states[L2]
            self.assertFalse(st.get("certificate"))
            pset = br.load_set(run, L2, st["active_set"]["set_id"])
            self.assertEqual((pset["state"], pset["records"]), ("failed", []))
            self.assertFalse(br.own_status(run, ledger, L2)["ok"])

    def test_a_valid_answer_with_a_refused_candidate_is_processed_per_candidate(self):
        with self.stage.rworld(kind="labels", coverage="bounded") as (run, ledger, fake, persist):
            L1 = self.stage.L[1]
            rounds = slow_rounds()
            rounds[0]["draft"]["candidates"][1]["observations"] = ["kin.velocity"]        # refused by the language check only
            self.stage.script(fake, L1, raw(rounds))
            self.assertEqual(self.stage.review(run, ledger, L1, persist), "review_unverified")
            pset = br.load_set(run, L1, run.review_states[L1]["active_set"]["set_id"])
            self.assertEqual([r["id"] for r in pset["records"]], ["P1"])
            self.assertIn("rejected", [h["kind"] for h in pset["holes"]])

    def test_a_set_adopted_by_a_production_reviewer_itself_is_refused(self):
        with self.stage.rworld(kind="labels") as (run, ledger, fake, persist):
            from scripts.tests.fake_reviewer import pset as fake_set, prop
            with mock.patch.object(br, "is_test_only", lambda name: False):
                got = br.admit(run, self.stage.L[1], {}, "k", fake_set(prop("p")))
            self.assertEqual((got["state"], got["records"]), ("failed", []))
            self.assertIn("only the harness's adoption gate adopts", got["reasons"][0])

    def test_a_withdrawal_removes_exactly_one_identity(self):
        from scripts.tests.fake_reviewer import pset as fake_set
        ante = {"cmp": "gt", "lhs": speed(), "rhs": lit(Fraction(0))}
        def rec(pid, cat, cls):
            return {"id": pid, "clause": "C1", "category": cat, "span_quote": "shall proceed slowly", "antecedent": ante,
                    "binders": [{"name": "v", "cls": cls, "subject": True}], "expected": "violated" if cat == "must_detect" else "not_violated"}
        p, q, r, p2 = rec("P1", "must_detect", car()), rec("P2", "must_not_flag", car()), rec("P3", "must_detect", car(atom="ru_bicycle")), \
            rec("P4", "must_detect", car())
        with self.stage.rworld(kind="labels") as (run, ledger, fake, persist):
            L1 = self.stage.L[1]
            self.stage.script(fake, L1, fake_set(p, q, r, p2))
            self.stage.review(run, ledger, L1, persist)
            act = run.review_states[L1]["active_set"]
            before = br.active_id(act)
            after = br.withdraw(run, L1, "P1", {"ruling": "property_wrong", "finding": "f1"})
            self.assertNotEqual(after, before)
            pset = br.load_set(run, L1, act["set_id"])
            self.assertEqual([x["id"] for x in br.active_records(pset, act)], ["P2", "P3"])     # P4 is P1 under another id
            self.assertEqual(br.withdraw(run, L1, "P4", {"ruling": "property_wrong", "finding": "f1"}), after)   # the same identity: nothing changes
            w = act["withdrawals"]
            self.assertEqual((len(w), w[0]["identity"], w[0]["antecedent_sha"]), (1, rs.identity(p), rs.antecedent_sha(q)))
            self.assertEqual(rs.errors("active_set", rs.active_set_record(L1, act, after)), [])
            self.assertEqual(br.withdraw(run, L1, "P1", {"ruling": "property_wrong", "finding": "f1"}), after)    # submitted again
            with self.assertRaises(ValueError):
                br.withdraw(run, L1, "P9", {"ruling": "property_wrong"})                 # no such property
            # a later set keeps the withdrawal; the gate drops a candidate of the withdrawn identity
            st = run.review_states[L1]
            rounds = slow_rounds()
            rounds[0]["draft"]["candidates"][0] = {**rounds[0]["draft"]["candidates"][0], "antecedent": ante,
                                                   "binders": [{"name": "v", "cls": car(), "subject": True}]}
            self.assertEqual(rs.identity(rounds[0]["draft"]["candidates"][0]), rs.identity(p))
            st["pending_call"] = {"spec_key": "k2", "ask": 2, "workdir": "review/x"}
            new = br.adopt(run, L1, st, "k2", raw(rounds), {"stage": "L1"}, "L1")
            self.assertEqual((st["active_set"]["set_id"], st["active_set"]["withdrawals"], st["active_set"]["version"]), (new, w, 2))
            got = br.load_set(run, L1, new)
            self.assertEqual([x["id"] for x in got["records"]], ["P2"])
            self.assertTrue(any(x.startswith("withdrawn") for a in got["adoption"] if a["property"] == "P1" for x in a["adoption"]["reasons"]))
