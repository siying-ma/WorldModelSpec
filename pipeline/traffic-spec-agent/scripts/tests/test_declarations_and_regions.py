"""Declared facts and region formals, in the harness: one catalogue of declared-fact ids with one
meaning each, checked at validation in record order, entered into the readings at the wave, checked
on inheritance, archived by a fresh start, shown to the judges, and required of a case; a concept's
region formals carried by its challenges through the form check, the case's identity, the record,
the replay, an extension and the executed facts."""
import copy
import json
import tempfile
import unittest
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import patch

from harness.checks import gate, validate_a
from harness.lean import render_formula, skeleton
from harness.model import blueprint
from harness.model.blueprint import ConceptRecord, Node
from harness.model.reading import Reading, reading_defects
from harness.phases import review, validate as validate_phase
from harness.store.jsonl import DataIntegrityError
from harness.store.state import Run
from scripts.tests.test_review_routing import FakeRun, ONTO

MEANING = "the road user's current plan is to turn left at the region"
PREMISE = "the way the road user travels on lies in a district the source names"
INT_T, ASM_D = {"id": "int.t", "kind": "int"}, {"id": "asm.d", "kind": "asm"}


def node(intentions=(), assumptions=(), narrowings=(), role="trigger") -> Node:
    return Node({"node_id": "L_1", "law_refs": ["L-1"], "binders": [{"name": "v"}],
                 "segmentation": [{"id": "s1", "role": role, "text": "intends to turn"}, {"id": "s2", "role": "obligation", "text": "yield"}],
                 "elements": [{"span": "s2", "atoms": ["kin.speed"]}], "intentions": [dict(d) for d in intentions],
                 "assumptions": [dict(d) for d in assumptions], "narrowings": list(narrowings)})


class Catalogue(unittest.TestCase):
    """One catalogue for `asm.*` and `int.*`: a new id with a meaning joins it, a reuse is written its
    meaning, a different meaning or a meaning-less unknown id is returned, in record order."""
    def test_both_prefixes(self):
        for key, cid in (("intentions", "int.turn_left"), ("assumptions", "asm.district")):
            cat: dict[str, str] = {}
            first = node(**{key: [{"span": "s1", "id": cid, "meaning": MEANING}]})
            self.assertEqual(validate_a.check_declarations(first, cat), [])
            self.assertEqual(cat, {cid: MEANING})                                    # a new id joins the catalogue
            reuse = node(**{key: [{"span": "s1", "id": cid}]})
            self.assertEqual(validate_a.check_declarations(reuse, cat), [])
            self.assertEqual(reuse.get(key)[0]["meaning"], MEANING)                  # the catalogue's meaning is written in
            other = node(**{key: [{"span": "s1", "id": cid, "meaning": "something else"}]})
            self.assertTrue(any("reuse the id without a meaning" in e for e in validate_a.check_declarations(other, cat)))
            unknown = node(**{key: [{"span": "s1", "id": cid.split(".")[0] + ".unseen"}]})
            self.assertTrue(any("gives no meaning" in e for e in validate_a.check_declarations(unknown, cat)))

    def test_record_order(self):
        cat: dict[str, str] = {}
        reuse_first = node(intentions=[{"span": "s1", "id": "int.turn_left"}])
        proposer = node(intentions=[{"span": "s1", "id": "int.turn_left", "meaning": MEANING}])
        reuse_after = node(intentions=[{"span": "s1", "id": "int.turn_left"}])
        self.assertTrue(validate_a.check_declarations(reuse_first, cat))           # before the proposing node: returned
        self.assertEqual(validate_a.check_declarations(proposer, cat), [])
        self.assertEqual(validate_a.check_declarations(reuse_after, cat), [])       # after it: accepted

    def test_prefix_role_and_no_dual_reading(self):
        self.assertTrue(validate_a.check_declarations(node(intentions=[{"span": "s1", "id": "asm.x", "meaning": "m"}]), {}))
        self.assertTrue(any("trigger, subject, condition or exception" in e for e in
                            validate_a.check_declarations(node(intentions=[{"span": "s1", "id": "int.t", "meaning": "m"}], role="obligation"), {})))
        dual = node(intentions=[{"span": "s1", "id": "int.t", "meaning": "m"}],
                    narrowings=[{"span": "s1", "kind": "observable_reading", "category": "intention", "why": "w"}])
        self.assertTrue(any("not both" in e for e in validate_a.check_declarations(dual, {})))

    def test_a_meaning_that_cites_is_refused_new_or_reused(self):
        fx = json.loads((Path(__file__).parent / "declaration_meaning_citations.json").read_text(encoding="utf-8"))
        for words in fx["citing"]:
            cited = node(assumptions=[{"span": "s1", "id": "asm.x", "meaning": f"the way lies outside a city ({words})"}])
            cat: dict[str, str] = {}
            self.assertTrue(any("cites" in e for e in validate_a.check_declarations(cited, cat)), words)
            self.assertEqual(cat, {}, words)                                         # a citing meaning joins no catalogue
        for words in fx["fact_only"]:
            self.assertEqual(validate_a.check_declarations(node(assumptions=[{"span": "s1", "id": "asm.x", "meaning": words}]), {}), [], words)
        real = {d["id"]: d["meaning"] for d in fx["declarations"]}
        # the recorded meaning, proposed by a new record
        new = node(assumptions=[{"span": "s1", "id": "asm.outside_city_limits", "meaning": real["asm.outside_city_limits"]}])
        self.assertTrue(any("cites NRS 484A.215" in e for e in validate_a.check_declarations(new, {})))
        # the recorded meaning, reached by a record that reuses the id from the run's reading
        with tempfile.TemporaryDirectory() as t:
            path = Path(t) / "reading.json"
            path.write_text(json.dumps({"params": [], "aggregates": [], "declarations": fx["declarations"]}), encoding="utf-8")
            cat = {i: d["meaning"] for i, d in Reading(path).declarations().items()}
        reuse = node(assumptions=[{"span": "s1", "id": "asm.outside_city_limits"}])
        errs = validate_a.check_declarations(reuse, cat)
        self.assertTrue(any("catalogue's meaning of `asm.outside_city_limits` cites NRS 484A.215" in e for e in errs), errs)
        for cid in ("int.turn", "int.turn_left"):                                    # the run's fact-only meanings stay usable
            self.assertEqual(validate_a.check_declarations(node(intentions=[{"span": "s1", "id": cid}]), cat), [], cid)

    def test_accounting_counts_intentions(self):
        self.assertFalse([e for e in validate_a.check_accounting(node(intentions=[{"span": "s1", "id": "int.t", "meaning": "m"}]))
                          if "s1" in e])
        self.assertEqual(validate_a.schema_errors("L_1", {**json.loads(json.dumps(node().raw)), "intentions": [{"span": "s1", "id": "int.t"}]},
                                                  {"intentions?": validate_a.NODE_SCHEMA["intentions?"]}), [])


class Readings(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.path = Path(self.tmp.name) / "reading.json"
        self.path.write_text(json.dumps({"params": [], "aggregates": []}))

    def tearDown(self):
        self.tmp.cleanup()

    def test_entered_proposed_once_and_never_with_another_meaning(self):
        self.assertEqual(len(Reading.add_declarations(self.path, [{"id": "int.t", "meaning": MEANING}], "r/iter-001 L_1")), 1)
        self.assertEqual(Reading.add_declarations(self.path, [{"id": "int.t", "meaning": "  " + MEANING}], "r/iter-002 L_2"), [])
        self.assertEqual(Reading(self.path).declarations()["int.t"]["proposed"], "r/iter-001 L_1")
        with self.assertRaises(ValueError):
            Reading.add_declarations(self.path, [{"id": "int.t", "meaning": "other"}], "r/iter-002 L_3")

    def test_defects(self):
        self.assertEqual(reading_defects({"declarations": [{"id": "int.t", "meaning": "m"}]}), [])
        self.assertEqual(len(reading_defects({"declarations": [{"id": "int.T", "meaning": "m"}, {"id": "int.t", "meaning": ""},
                                                               {"id": "int.u", "meaning": "m"}, {"id": "int.u", "meaning": "m"}]})), 3)

    def test_resume_digest_ignores_proposed_declarations(self):
        from harness import loop
        base = {"params": [], "aggregates": [], "declarations": []}
        def digest(data):
            self.path.write_text(json.dumps(data))
            opts = SimpleNamespace(laws=str(self.path), definition_precedence=None, ontology=str(ONTO.path), reading=str(self.path), base_run=None)
            return loop.semantic_inputs(opts)["base_reading"]
        plain = digest(base)
        self.assertEqual(plain, digest({**base, "declarations": [{"id": "int.t", "meaning": "m", "proposed": "r/iter-001 L_1"}]}))
        self.assertNotEqual(plain, digest({**base, "declarations": [{"id": "int.t", "meaning": "m"}]}))

    def test_fresh_start_archives_unreviewed_declarations(self):
        from harness import __main__ as cli
        from harness.store import paths
        readings, results = Path(self.tmp.name) / "readings", Path(self.tmp.name) / "results"
        readings.mkdir()
        (readings / "x.json").write_text(json.dumps({"params": [], "declarations": [{"id": "int.t", "meaning": "m", "proposed": "o"},
                                                                                    {"id": "asm.d", "meaning": "n"}]}))
        with patch.object(paths, "READINGS", readings), patch.object(paths, "RESULTS", results):
            self.assertEqual(cli.archive_proposals("snap"), {"x.json": 1})
            kept = json.loads((readings / "x.json").read_text())["declarations"]
            archived = json.loads((results / cli.moved_name("snap") / "reading_proposals.json").read_text())
        self.assertEqual([d["id"] for d in kept], ["asm.d"])
        self.assertEqual([d["id"] for d in archived["x.json#declarations"]], ["int.t"])


class Inheritance(unittest.TestCase):
    """An inherited node's declared ids: entered as inherited when absent (only at the loop's start),
    a run stopped on a conflict or a missing meaning."""
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.path = Path(self.tmp.name) / "reading.json"
        self.path.write_text(json.dumps({"params": [], "aggregates": [], "declarations": [{"id": "int.t", "meaning": MEANING}]}))

    def tearDown(self):
        self.tmp.cleanup()

    def run_with(self, *ids):
        nodes = {f"N_{k}": {"intentions": [{"span": "s", "id": i, **({"meaning": m} if m else {})}]} for k, (i, m) in enumerate(ids)}
        return SimpleNamespace(base_nodes=nodes, reading_file=self.path, opts=SimpleNamespace(base_run="B", reading=None))

    def test_absent_id_entered_as_inherited_only_when_entering(self):
        r = self.run_with(("int.u", "another meaning"))
        Run.inherit_declarations(r, enter=False)
        self.assertNotIn("int.u", Reading(self.path).declarations())
        Run.inherit_declarations(r)
        self.assertEqual(Reading(self.path).declarations()["int.u"]["proposed"], "inherited B N_0")

    def test_conflict_or_no_meaning_stops(self):
        with self.assertRaises(SystemExit):
            Run.inherit_declarations(self.run_with(("int.t", "other")), enter=False)
        with self.assertRaises(SystemExit):
            Run.inherit_declarations(self.run_with(("int.u", None)), enter=False)
        Run.inherit_declarations(self.run_with(("int.t", "  " + MEANING)), enter=False)


class JudgesAndCases(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.run = FakeRun(Path(self.tmp.name))
        self.run.all_concepts = lambda: {}
        self.run.reading_file.write_text(json.dumps({"params": [], "aggregates": [], "declarations": [{"id": "int.t", "meaning": MEANING}]}))

    def tearDown(self):
        self.tmp.cleanup()

    def test_glosses_carry_the_meaning_or_stop(self):
        self.assertEqual(validate_phase.glosses_of(["int.t"], ONTO, self.run), {"int.t": MEANING})
        with self.assertRaises(DataIntegrityError):
            validate_phase.glosses_of(["int.u"], ONTO, self.run)

    def test_a_case_naming_an_uncatalogued_intention_is_not_admitted(self):
        recs = {1: {"case_declarations": [INT_T]}, 2: {"case_declarations": [{"id": "int.u", "kind": "int"}]}}
        review.undeclared_case_errors(recs, Reading(self.run.reading_file).declarations())
        self.assertNotIn("case_check_errors", recs[1])
        self.assertEqual(review.admission({}, recs[2], None)[0], "invalid")

    def test_a_case_naming_an_uncatalogued_assumption_is_not_admitted(self):
        self.run.reading_file.write_text(json.dumps({"params": [], "aggregates": [], "declarations": [
            {"id": "int.t", "meaning": MEANING}, {"id": "asm.d", "meaning": PREMISE}]}))
        cat = Reading(self.run.reading_file).declarations()
        recs = {1: {"case_declarations": [ASM_D, INT_T]}, 2: {"case_declarations": [{"id": "asm.u", "kind": "asm"}]},
                3: {"case_declarations": [{"id": "int.t", "kind": "asm"}]}}            # an intention's id written as an assumption
        review.undeclared_case_errors(recs, cat)
        self.assertNotIn("case_check_errors", recs[1])
        self.assertEqual(recs[2]["case_check_errors"], ["the case names the assumption `asm.u`, which is in no catalogue of the run: "
                                                        "a case states only assumptions the run's declarations give a meaning"])
        self.assertTrue(any("assumption `int.t`" in e for e in recs[3]["case_check_errors"]))
        for k in (2, 3):
            self.assertEqual(review.admission({}, recs[k], None)[0], "invalid")

    def test_a_case_the_trace_contradicts_is_not_judged(self):
        """The trace declares the assumption false and the case states it true: the certificate gives
        the case false at `at`, which is returned to the reviewer, never judged."""
        rec = {"case_declarations": [ASM_D], "case_value": {"value": "false", "unknown_reasons": []}, "rule_result": None}
        review.undeclared_case_errors({1: rec}, {"asm.d": {"id": "asm.d", "meaning": PREMISE}})
        self.assertEqual(review.admission({}, rec, None)[0], "invalid")
        self.assertTrue(any("the case is false at `at`" in x for x in review.cert_unusable(1, {}, rec)))

    def test_an_assumption_is_glossed_as_the_source_declaration(self):
        self.run.reading_file.write_text(json.dumps({"params": [], "aggregates": [], "declarations": [
            {"id": "int.t", "meaning": MEANING}, {"id": "asm.d", "meaning": PREMISE}, {"id": "asm.e", "meaning": "another premise"}]}))
        g = review._case_glosses(ONTO, [], self.run, [ASM_D, INT_T])
        self.assertEqual(g, {"asm.d": f"declared by the source: {PREMISE}", "int.t": MEANING})   # asm.e is not stated: not shown

    def test_the_leaf_in_prose(self):
        f = {"int": "int.t", "args": [{"var": "v"}, {"var": "j"}]}
        self.assertEqual(render_formula.formula(f, {}), "road user `v` is declared to intend `int.t` at region `j`")


class Skeletons(unittest.TestCase):
    def test_rule_skeleton_declares_intentions(self):
        n = Node({"node_id": "L_1", "law_refs": ["L-1"], "binders": [{"name": "v", "class_elements": []}], "segmentation": [],
                  "elements": [], "scenarios": [], "intentions": [{"span": "s1", "id": "int.t"}, {"span": "s2", "id": "int.t"}]})
        self.assertIn('    intentions := ["int.t"]', skeleton.rule_skeleton(n).splitlines())

    def test_concept_skeletons_carry_regions(self):
        c = ConceptRecord({"concept_id": "drv.position.on_region", "contract": "c", "kind": "formula", "params": [],
                           "args": [{"name": "x", "sort": "track"}, {"name": "j", "sort": "region"}],
                           "scenarios": [{"name": "holds", "expected": "compliant"}, {"name": "fails", "expected": "violated"},
                                         {"name": "blind", "expected": "unknown", "masked": ["rel.occupies"]}]})
        self.assertIn('    args := [("x", .track), ("j", .region)]', skeleton.concept_skeleton(c).splitlines())
        self.assertIn('    regions := [("j", 100)]', skeleton.concept_witness_skeleton(c).splitlines())
        self.assertIn("region", blueprint.ARG_SORTS)

    def test_a_region_formal_anchors(self):
        self.assertEqual(gate.unanchored_variables([["?l"], ["l", "j"]], ["x", "j"]), [])
        self.assertEqual(gate.unanchored_variables([["?l"], ["l", "j"]], ["x"]), ["l"])


def region_concept() -> ConceptRecord:
    return ConceptRecord({"concept_id": "drv.position.on_region", "kind": "formula", "contract": "c holds", "params": [],
                          "args": [{"name": "x", "sort": "track"}, {"name": "j", "sort": "region"}]})


def challenge(j=7, **extra) -> dict:
    return {"kind": "holds_wrongly", "situation": "s", "contract_words": "c holds", "contract_verdict": "fails",
            "instance": {"literals": {}, "nats": {}, "params": {}}, "grounding": {"x": 1}, "regions": {"j": j},
            "trace": {"scenes": [{"t": 0, "users": [{"track": 1}], "structures": [{"id": 7, "kind": "lane"}]}]}, "at": 0, **extra}


class RegionForm(unittest.TestCase):
    def errs(self, regions):
        d = challenge()
        d["regions"] = regions
        return [e for e in review.concept_divergence_defects(1, d, region_concept(), "c holds", None, saved=True) if "regions" in e]

    def test_ids_are_natural_numbers_naming_exactly_the_region_formals(self):
        self.assertEqual(self.errs({"j": 7}), [])
        self.assertEqual(self.errs({"j": 0}), [])
        for bad in ({"j": -1}, {"j": True}, {"j": 1.5}, {}, {"j": 7, "k": 8}, {"k": 7}):
            self.assertTrue(self.errs(bad), bad)

    def test_identity(self):
        self.assertNotEqual(review.concept_case_id("drv.position.on_region", challenge(7)),
                            review.concept_case_id("drv.position.on_region", challenge(8)))
        row = json.loads((Path(__file__).parent / "legacy_concept_case.json").read_text())
        self.assertEqual(review.concept_case_id(row["subject"], row), row["case_id"])     # a row recorded before regions keeps its id
        self.assertEqual(row["case_id"][:8], "e23caaa4")

    def test_an_extension_keeps_its_regions(self):
        old = challenge(7)
        self.assertEqual(review.concept_extension_defects(old, challenge(7), region_concept()), [])
        self.assertTrue(any("`j`" in e for e in review.concept_extension_defects(old, challenge(8), region_concept())))

    def test_the_facts_name_the_regions(self):
        facts = render_formula.trace_facts(challenge()["trace"], {"x": 1}, 0, {}, None, None, {"j": 7})
        self.assertIn("- regions: `j` = region 7 (lane)", facts)


class RegionFormalPlaces(unittest.TestCase):
    """A concept that reads a property of a region it takes as a formal claims no kind of region:
    its caller's quantifier names the kind. One that finds the region itself still claims it. The
    record is the one a plan session drafted and the validator returned."""

    def setUp(self):
        from harness.model import ontology
        from harness.store import paths
        self.onto = ontology.load(paths.REPO / "ontology" / "ATOMS_train.md")
        self.rec = json.loads((Path(__file__).parent / "region_formal_concept.json").read_text())

    def reasons(self, raw):
        return validate_a.validate_concepts([ConceptRecord(raw)], [], self.onto, {}, [])[0].reasons

    def test_a_region_formal_needs_no_kind(self):
        self.assertEqual(self.reasons(self.rec), [])

    def test_a_region_found_by_the_body_still_needs_its_kind(self):
        found = {**self.rec, "args": [a for a in self.rec["args"] if a["sort"] != "region"]}
        self.assertTrue(any("a region quantifier names its kind" in r and "`st.lane_direction` (region argument 1)" in r
                            for r in self.reasons(found)), self.reasons(found))


class RegionPersistence(unittest.TestCase):
    """An upheld challenge with a region, through the real record: written by the adjudication, read
    back from the rulings, and replayed on the next body with its region."""
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.run = FakeRun(Path(self.tmp.name))
        self.run.all_concepts = lambda: {}
        self.given = []

    def tearDown(self):
        self.tmp.cleanup()

    def test_write_read_replay(self):
        rec = region_concept()
        item = {"line": "divergence 1 (holds_wrongly): it confirms", "div": challenge(7), "rule": "holds", "verdict": "compliant"}
        answer = {"rulings": [{"item": 1, "ruling": "upheld", "reason": "r", "quote": "c holds"}]}
        blocks = {"contract": "c holds", "record": "{}", "rendered": "body", "contracts": "contracts"}
        with patch.object(review.validate_phase, "_session", return_value=(answer, [])), patch.object(review, "precedent_rows", return_value=[]):
            review.adjudicate_concept(self.run, rec, blocks, [item], Path(self.tmp.name) / "adj")
        [row] = [r for r in review.effective_rows(review._all_rows(self.run)) if r.get("schema") == review.CONCEPT_CASE_SCHEMA]
        self.assertEqual(row["regions"], {"j": 7})
        self.assertEqual(row["case_id"], review.concept_case_id(rec.id, challenge(7)))

        def execute(_rec, answer, *_a, **_k):
            self.given.append(copy.deepcopy(answer["divergences"]))
            return [], ["divergence 1 (holds_wrongly): the body agrees"], [], []
        with patch.object(review, "execute_concept_divergences", execute), patch.object(review, "_registry", return_value=("", "")):
            rep = review.replay_concept(self.run, rec, Path(self.tmp.name) / "replay", None, "b2")
        self.assertEqual(rep.carry, [])                                                     # its formals correspond: it runs
        self.assertEqual(self.given[0][0]["regions"], {"j": 7})


class JudgesSeeTheMeaning(unittest.TestCase):
    """D8 end to end: a case stating a declared intention reaches Stage A and Stage B with the id's
    meaning in their contracts, through `judge_divergence`, stopped at the model call; a changed
    meaning changes Stage A's digest, so no earlier verdict is reused for it."""
    def setUp(self):
        from scripts.tests.test_review_routing import A_VIOLATED, B
        self.tmp = tempfile.TemporaryDirectory()
        self.run = FakeRun(Path(self.tmp.name))
        self.run.all_concepts = lambda: {}
        self.answers = {"a": A_VIOLATED, "b": B("upheld")}
        self.prompts = []

    def tearDown(self):
        self.tmp.cleanup()

    def declare(self, meaning, premise=PREMISE):
        self.run.reading_file.write_text(json.dumps({"params": [], "aggregates": [], "declarations": [
            {"id": "int.t", "meaning": meaning}, {"id": "asm.d", "meaning": premise}, {"id": "asm.e", "meaning": "another premise"}]}))

    def judge(self, case=None, declared=(INT_T,), rule_glosses=None):
        from scripts.tests.test_review_routing import ctx, div, node
        def session(run, out_dir, label, prompt, check=None, **_kw):
            self.prompts.append((label, prompt))
            ans = self.answers["a" if label.endswith("stage_a") else "b"]
            return ans, (list(check(ans)) if check else [])
        case = case or {"int": "int.t", "args": [{"var": "v"}, {"var": "j"}]}
        c = {"schema": review.CERT_SCHEMA, "canonical_case": case, "case_atoms": [], "case_declarations": list(declared),
             "rule_result": {"verdict": "compliant", "unknown_reasons": []}, "sensitivity_overrides": []}
        d = div(case=case, entities={"j": {"kind": "region", "id": 20}})
        cx = ctx()
        cx.rule_glosses = rule_glosses or {}
        with patch.object(validate_phase, "_session", session):
            return review.judge_divergence(self.run, node(), cx, ONTO, d, c, Path(self.tmp.name), "d1")

    def test_stage_a_is_shown_a_stated_premise_as_the_source_declaration(self):
        """A case stating the assumption `asm.d` (true, or negated): Stage A sees the leaf and the
        catalogue meaning marked as the source's declaration; never the rule's rendering, its other
        assumption `asm.e`, its reading or its verdict. Stage B sees the same declaration."""
        self.declare(MEANING)
        rule_glosses = {"asm.d": PREMISE, "asm.e": "another premise"}
        for case, leaf in (({"asm": "asm.d"}, "the assumption `asm.d` is declared true"),
                           ({"not": {"asm": "asm.d"}}, f"the source declares the assumption `asm.d` [{PREMISE}] false")):
            with self.subTest(case=case):
                self.prompts.clear()
                self.judge(case, (ASM_D,), rule_glosses)
                [(_, a)] = [x for x in self.prompts if x[0].endswith("stage_a")]
                [(_, b)] = [x for x in self.prompts if x[0].endswith("stage_b")]
                self.assertIn(leaf, a)
                self.assertIn(f"| `asm.d` | declared by the source: {PREMISE} |", a)
                shown = a[a.index("### The law"):a.index("## Deciding")]                # what is injected: the template aside
                for absent in ("asm.e", "another premise", "the rendering", "compliant", "narrowing"):
                    self.assertNotIn(absent, shown)
                self.assertIn(f"declared by the source: {PREMISE}", b)

    def test_a_negated_premise_inside_a_disjunction_stays_inside_it(self):
        """`not(asm) OR true` on a trace that declares no assumption: Lean certifies it (the
        disjunction is true whatever the premise), so the judges are shown the disjunction as one
        fact, and no line of the prompt states on its own that the premise was declared false."""
        self.declare(MEANING)
        case = {"or": [{"not": {"asm": "asm.d"}}, "tt"]}
        self.judge(case, (ASM_D,))
        [(_, a)] = [x for x in self.prompts if x[0].endswith("stage_a")]
        branch = f"the source declares the assumption `asm.d` [{PREMISE}] false"
        self.assertIn(f"(\n  {branch}\n  OR\n  true\n)", a)                       # the statement, structurally
        self.assertIn("  - (\n  the source declares the assumption `asm.d` false\n  OR\n  true\n)", a)   # the time-ordered facts: one fact
        alone = [ln for ln in a.splitlines() if "the source declares" in ln and not ln.startswith("  the source declares")]
        self.assertEqual(alone, [])                                                 # only ever a branch line, never a fact line of its own
        self.assertNotIn("is declared false", a)

    def test_a_changed_premise_meaning_changes_the_stage_a_digest(self):
        self.declare(MEANING)
        first = self.judge({"asm": "asm.d"}, (ASM_D,)).row["stageA_digest"]
        self.declare(MEANING, premise="the way the road user travels on lies in another district the source names")
        self.assertNotEqual(self.judge({"asm": "asm.d"}, (ASM_D,)).row["stageA_digest"], first)
        self.declare(MEANING)
        self.assertEqual(self.judge({"asm": "asm.d"}, (ASM_D,)).row["stageA_digest"], first)

    def test_both_judges_are_shown_the_meaning(self):
        self.declare(MEANING)
        j = self.judge()
        [(_, a)] = [x for x in self.prompts if x[0].endswith("stage_a")]
        [(_, b)] = [x for x in self.prompts if x[0].endswith("stage_b")]
        self.assertIn("is declared to intend `int.t` at region", a)
        self.assertIn(MEANING, a)
        self.assertIn(MEANING, b)
        first = j.row["stageA_digest"]
        self.declare("the road user's current plan is to turn right at the region")
        self.prompts.clear()
        self.assertNotEqual(self.judge().row["stageA_digest"], first)

    def test_an_uncatalogued_intention_never_reaches_a_judge(self):
        self.declare(MEANING)
        from scripts.tests.test_review_routing import div
        recs = {1: {"case_declarations": [{"id": "int.unseen", "kind": "int"}], "case_value": {"value": "true"}, "rule_result": {"verdict": "compliant"}}}
        review.undeclared_case_errors(recs, Reading(self.run.reading_file).declarations())
        out = review.cert_unusable(1, div(), recs[1])
        self.assertTrue(any("in no catalogue" in x for x in out))                  # returned to the reviewer, not judged


def _saved(rel: str) -> Path:
    from harness.store import paths
    return paths.RESULTS / "smoke22" / rel


RECHECK = "iter-000/recheck/NRS_484B_127_1"
DOUBLED = {"vehicle": 1, "target": 101, "source": "test", "values": [["int.turn_left", True]]}


def _admitted_and_refused() -> tuple[dict, dict]:
    """A recorded trace (one highway, two cars) as it was, and with two intent records for the
    same vehicle and region: a trace the admission refuses."""
    trace = json.loads(_saved(f"{RECHECK}/trace_1.json").read_text())
    refused = copy.deepcopy(trace)
    refused["scenes"][0]["intents"] = [DOUBLED, dict(DOUBLED)]
    return trace, refused


def _have_saved() -> bool:
    import shutil
    return bool(shutil.which("lake")) and _saved(f"{RECHECK}/trace_1.json").exists() and _saved("accepted_concepts.jsonl").exists()


@unittest.skipUnless(_have_saved(), "needs the toolchain and smoke22's records")
class AdmissionRefusesBeforeAnyVerdict(unittest.TestCase):
    """A trace the admission refuses reaches no verdict on any route, with the real Lean: the node
    review's certificate, the concept review's harness and the monitor."""

    def test_the_certificate_returns_it_to_the_reviewer(self):
        case = json.loads(_saved(f"{RECHECK}/case_1.json").read_text())
        trace, refused = _admitted_and_refused()
        divs = {k: {"trace": t, "case": case["case"], "entities": case["entities"], "at": case["at"], "grounding": {"v": 1}}
                for k, t in ((1, trace), (2, refused))}
        with tempfile.TemporaryDirectory() as td:
            recs = review.certify(None, SimpleNamespace(id="NRS_484B_127_1"), divs, Reading(_saved("reading.json")), Path(td))
        self.assertEqual(review.admission(divs[1], recs[1], review._Need())[0], "judge")
        self.assertTrue(any("more than one intent record" in e for e in recs[2]["lint_errors"]), recs[2].get("lint_errors"))
        cls, why = review.admission(divs[2], recs[2], review._Need())
        self.assertEqual(cls, "invalid")
        self.assertTrue(review.cert_unusable(2, divs[2], recs[2]))                 # unusable: no Stage A is asked

    def test_the_concept_review_counts_it_incomplete(self):
        cid = "drv.control.intersection_signal_inoperative"
        rows = [json.loads(line) for line in _saved("accepted_concepts.jsonl").read_text().splitlines() if line.strip()]
        rec = ConceptRecord(next(r for r in rows if r["concept_id"] == cid))
        trace, refused = _admitted_and_refused()
        words = "there is a signal head whose faces are not covered"
        div = lambda t: {"kind": "fails_wrongly", "situation": "a car on a highway", "contract_words": words, "contract_verdict": "fails",
                         "instance": {}, "grounding": {"u": 1}, "trace": t, "at": 0}
        with tempfile.TemporaryDirectory() as td:
            confirmed, unconfirmed, errors, incomplete = review.execute_concept_divergences(
                rec, {"divergences": [div(trace), div(refused)]}, Path(td))
            out = (Path(td) / "review_harness.out").read_text()
        self.assertIn("DIS\t2\tlint", out)
        self.assertNotIn("DIS\t1\tlint", out)
        self.assertEqual(errors, [])
        self.assertEqual([x for x in incomplete if x.startswith("divergence 2:")], [x for x in incomplete if "more than one intent record" in x])
        self.assertTrue(any(x.startswith("divergence 2: trace check:") for x in incomplete), incomplete)
        self.assertFalse(any("divergence 2 " in (c["line"] if isinstance(c, dict) else c) for c in confirmed + unconfirmed))

    def routed(self, review_call, answer):
        """A review run end to end with the real Lean behind it: the reviewer scripted, every judge's
        session (Stage A, Stage B, the adjudicator) recorded instead of asked."""
        from harness.store.state import base_view
        from scripts.tests.test_review_routing import FakeRun, scripted_reviewer, submit
        view = base_view("smoke22")
        asked = []
        with tempfile.TemporaryDirectory() as td:
            run = FakeRun(Path(td))
            run.opts.max_divergences = 3
            run.opts.ontology = ONTO.path
            run.all_nodes = lambda: {k: v for k, v in view["nodes"].items() if k not in view["fenced"]}
            run.all_concepts = lambda: {k: v for k, v in view["concepts"].items() if k not in view["fenced"]}
            with patch.object(review.session, "run_tools", scripted_reviewer([submit(answer)] * 3)), \
                    patch.object(validate_phase, "_session", lambda *a, **_k: asked.append(a[2]) or ({}, ["no model here"])), \
                    patch.object(review, "append_ruling", lambda *_a, **_k: None):
                out = review_call(run, Path(td))
        return out, asked

    def test_a_node_review_asks_no_judge(self):
        from scripts.tests.test_review_routing import LAW, ctx
        case = json.loads(_saved(f"{RECHECK}/case_1.json").read_text())
        _trace, refused = _admitted_and_refused()
        d = {"kind": "rule_permits_unlawful", "situation": "s", "law_words": "shall stop", "lawful_verdict": "violated",
             "grounding": {"v": 1}, "trace": refused, "case": case["case"], "entities": case["entities"], "at": case["at"]}
        n = Node({"node_id": "NRS_484B_127_1", "law_refs": ["L-1"], "binders": [{"name": "v"}],
                  "segmentation": [{"id": "s1", "role": "obligation", "text": "shall stop before the line"}]})
        with patch.object(review, "build_context", lambda *_a, **_k: ctx()), \
                patch.object(review, "replay_obligations", lambda *_a, **_k: review.Replayed()):
            out, asked = self.routed(lambda run, td: review.review_behaviour(run, n, LAW, ONTO, Reading(_saved("reading.json")), {}, [], td),
                                     {"verdict": "return", "divergences": [d], "advisories": [], "gap_candidates": []})
        self.assertEqual(asked, [])
        self.assertEqual((out.status, out.defer_stage), ("deferred", "reviewer"))
        self.assertIn("more than one intent record", out.reasons[0])

    def test_a_concept_review_asks_no_adjudicator(self):
        from harness.lean import render_formula as rf
        cid = "drv.control.intersection_signal_inoperative"
        rows = [json.loads(line) for line in _saved("accepted_concepts.jsonl").read_text().splitlines() if line.strip()]
        rec = ConceptRecord(next(r for r in rows if r["concept_id"] == cid))
        _trace, refused = _admitted_and_refused()
        # the body fails on this highway, so the claim "holds" would reach the adjudicator if the trace were admitted
        d = {"kind": "fails_wrongly", "situation": "a car on a highway", "contract_words": "there is a signal head whose faces are not covered",
             "contract_verdict": "holds", "instance": {}, "grounding": {"u": 1}, "trace": refused, "at": 0}
        with patch.object(rf, "render_concept", lambda *_a, **_k: "the rendering"):
            out, asked = self.routed(lambda run, td: review.review_concept(run, rec, {"reads": [], "body_json": {}}, td),
                                     {"verdict": "return", "divergences": [d], "not_general": [], "advisories": []})
        self.assertEqual(asked, [])
        self.assertEqual((out.status, out.defer_stage), ("deferred", "reviewer"))
        self.assertIn("more than one intent record", out.reasons[0])

    def test_the_monitor_exits_2(self):
        import subprocess
        from harness.store import paths
        exe = paths.LIBRARY / ".lake/build/bin/monitor"
        if not exe.exists():
            self.skipTest("the monitor is not built (`lake build monitor`)")
        trace, refused = _admitted_and_refused()
        with tempfile.TemporaryDirectory() as td:
            m, t, r = Path(td) / "m.json", Path(td) / "t.json", Path(td) / "r.json"
            m.write_text(json.dumps({"source": "test", "atoms": {}}))
            t.write_text(json.dumps(trace)); r.write_text(json.dumps(refused))
            run = lambda p: subprocess.run([str(exe), "--manifest", str(m), "--rules", "NRS_484B_127_1", str(p)], capture_output=True, text=True)
            ok, bad = run(t), run(r)
        self.assertEqual(ok.returncode, 0, ok.stderr)
        self.assertEqual(bad.returncode, 2)
        self.assertIn("is not admitted", bad.stderr)
        self.assertIn("more than one intent record", bad.stderr)


if __name__ == "__main__":
    unittest.main()
