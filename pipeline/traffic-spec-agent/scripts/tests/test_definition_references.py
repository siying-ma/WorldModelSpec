"""A `definition` reference borrows another text's words: it is validated against the posted
source, it is no execution dependency (nothing waits on, is ordered by or is fenced with the
source), its source text joins the node's dependency context, and every role that reads the
record is shown that text whole."""
from __future__ import annotations
import copy
import json
import tempfile
import unittest
from pathlib import Path
from types import SimpleNamespace as NS
from unittest import mock

from harness import loop
from harness.checks import validate_a
from harness.model import corpus, definitions
from harness.model.blueprint import Node
from harness.phases import code as code_phase, integrate, plan as plan_phase, review
from harness.store.ledger import Ledger

LAW_ID, SRC_ID, DEF_ID = "STA-900A-100-1", "STA-900A-200-2", "DEF-STA-900A-010"
LAW_TEXT = "If the highway has a turn lane as described in subsection 2 [STA-900A-200-2], the driver shall stop."
SRC_TEXT = "If a highway provides a turn lane to be used only for turning, a vehicle must stop before turning."
DEF_TEXT = "“Turn lane” means a lane marked for turning movements only."
QUOTE = "a turn lane to be used only for turning"
WHY = "borrows what a turn lane is; the source's stop duty need not hold for this condition"
LAW = corpus.Law(LAW_ID, "A duty", LAW_TEXT, "STA 900A.100")
SRC = corpus.Law(SRC_ID, "The source", SRC_TEXT, "STA 900A.200")
SOURCES = {LAW_ID: LAW_TEXT, SRC_ID: SRC_TEXT, DEF_ID: DEF_TEXT}


def record(**over) -> dict:
    r = {"node_id": "STA_900A_100_1", "law_refs": [LAW_ID],
         "segmentation": [{"id": "c1", "text": "If the highway has a turn lane", "role": "condition"},
                          {"id": "r1", "text": "as described in subsection 2 [STA-900A-200-2]", "role": "reference"},
                          {"id": "s1", "text": "the driver", "role": "subject"},
                          {"id": "o1", "text": "shall stop.", "role": "obligation"}],
         "elements": [{"span": "c1", "atoms": ["st.turn_lane"], "source_spans": ["r1"],
                       "justification": f"the lane the source describes: \"{QUOTE}\""},
                      {"span": "s1", "atoms": ["ru.subject"]}, {"span": "o1", "atoms": ["kin.speed"]}],
         "compositions": [{"span": "r1", "as": "definition", "source": SRC_ID, "quote": QUOTE, "why": WHY}],
         "binders": [{"name": "veh"}], "applicability": "a", "obligation": "o",
         "scenarios": [{"name": "forbid", "expected": "violated"}]}
    r.update(over)
    return r


def errs(raw: dict, known: dict | None = None) -> list[str]:
    n = Node(copy.deepcopy(raw))
    return validate_a.check_compositions(n, known or {}, SOURCES) + validate_a.check_source_spans(n) + validate_a.check_accounting(n, {LAW_ID, SRC_ID})


def with_comp(**c) -> dict:
    return record(compositions=[{"span": "r1", "as": "definition", "source": SRC_ID, "quote": QUOTE, "why": WHY, **c}])


class Validation(unittest.TestCase):
    def test_a_well_formed_definition_reference_validates(self):
        self.assertEqual(errs(record()), [])
        self.assertEqual(validate_a.schema_errors("x", record(), validate_a.NODE_SCHEMA), [])

    def test_a_posted_definition_may_be_the_source(self):
        r = with_comp(source=DEF_ID, quote="a lane marked for turning")
        r["elements"][0]["justification"] = "\"a lane marked for turning\""
        self.assertTrue(any("does not name" in e for e in errs(r)))         # the span names a law, not this definition
        r["segmentation"][1]["text"] = "as described in subsection 2"      # a span that names no id in brackets
        self.assertEqual(errs(r), [])

    def test_a_source_outside_the_active_corpus_is_rejected(self):
        r = with_comp(source="STA-999Z-1")
        r["segmentation"][1]["text"] = "as described in subsection 2"
        self.assertTrue(any("no law or posted definition of this run's corpus" in e for e in errs(r)))

    def test_a_quote_not_in_the_source_is_rejected(self):
        r = with_comp(quote="a lane for buses only")
        r["elements"][0]["justification"] = "\"a lane for buses only\""
        self.assertTrue(any("does not occur verbatim" in e for e in errs(r)))
        self.assertTrue(any("quotes nothing" in e for e in errs(with_comp(quote=""))))
        self.assertTrue(any("names no `source`" in e for e in errs(with_comp(source=None))))

    def test_a_source_the_span_does_not_name_is_rejected(self):
        self.assertTrue(any("which the span does not name" in e for e in errs(with_comp(source=DEF_ID, quote="a lane marked for turning"))))

    def test_relabelling_a_dependency_as_definition_is_rejected(self):
        e = errs(with_comp(rule="STA_900A_200_2", map={"veh": "veh"}))
        self.assertTrue(any("has `rule`" in x for x in e) and any("has `map`" in x for x in e), e)
        self.assertTrue(any("no law or posted definition" in x for x in errs(with_comp(source="STA_900A_200_2"))))  # a node is no source
        r = record()
        r["segmentation"][1]["role"] = "condition"
        self.assertTrue(any("carried on a `reference` span" in x for x in errs(r)))

    def test_an_execution_dependency_still_names_its_rule(self):
        r = record(compositions=[{"span": "r1", "as": "compliance", "map": {"veh": "veh"}}])
        r["elements"][0].pop("source_spans")
        self.assertTrue(any("names no `rule`" in x for x in errs(r)))

    def test_the_pairing_with_elements(self):
        r = record(); r["elements"][0]["source_spans"] = ["s1"]
        self.assertTrue(any("not carried by a `definition` reference" in x for x in errs(r)))
        r = record(); r["elements"][0]["source_spans"] = ["zz"]
        self.assertTrue(any("no span of this record" in x for x in errs(r)))
        r = record(); r["elements"][0]["source_spans"] = []
        self.assertTrue(any("empty `source_spans`" in x for x in errs(r)))
        r = record(); r["elements"][0].pop("source_spans")
        self.assertTrue(any("used by no element" in x for x in errs(r)))
        r = record(); r["elements"][0]["justification"] = "a turn lane"
        self.assertTrue(any("does not quote the borrowed words" in x for x in errs(r)))
        r = record(); r["elements"][1]["source_spans"] = ["r1"]; r["elements"][1]["justification"] = f"“{QUOTE}”"
        self.assertEqual(errs(r), [])                                   # any element may borrow, several may share a source
        bad = record(); bad["elements"][0]["source_spans"] = "r1"
        self.assertTrue(validate_a.schema_errors("x", bad, validate_a.NODE_SCHEMA))


def comp_node(nid: str, law: str, rule: str, as_: str = "compliance") -> Node:
    return Node({"node_id": nid, "law_refs": [law], "compositions": [{"span": "r", "rule": rule, "as": as_, "map": {}}]})


BORROWER = Node(record())
SOURCE_NODE = "STA_900A_200_2"


class ExecutionPaths(unittest.TestCase):
    def test_dependencies_leave_definitions_out(self):
        self.assertEqual(BORROWER.dependencies(), [])
        self.assertEqual(len(BORROWER.compositions()), 1)
        self.assertEqual(BORROWER.definition_sources(), [SRC_ID])
        src = Node({"node_id": SOURCE_NODE, "law_refs": [SRC_ID]})
        self.assertEqual([n.id for n in loop.topological([BORROWER, src])], [BORROWER.id, SOURCE_NODE])
        caller = comp_node("STA_900A_300", "STA-900A-300", SOURCE_NODE)
        self.assertEqual([n.id for n in loop.topological([caller, src])], [SOURCE_NODE, caller.id])

    def test_a_fenced_or_failed_source_does_not_hold_the_borrower_but_holds_a_real_dependency(self):
        caller = comp_node("STA_900A_300", "STA-900A-300", SOURCE_NODE)
        run = NS(fenced={SOURCE_NODE: {"reason": "gate"}})
        self.assertEqual(integrate.unavailable_candidates(run, [BORROWER, caller], {}), {caller.id: f"uses the fenced `{SOURCE_NODE}`"})

    def test_fence_closure_and_admission_follow_dependencies_only(self):
        caller = comp_node("STA_900A_300", "STA-900A-300", SOURCE_NODE)
        nodes = {BORROWER.id: BORROWER.raw, caller.id: caller.raw, SOURCE_NODE: {"node_id": SOURCE_NODE, "law_refs": [SRC_ID]}}
        fenced = {SOURCE_NODE: {"reason": "gate"}}
        run = NS(fenced=fenced, all_concepts=lambda: {}, all_nodes=lambda: nodes,
                 fence=lambda i, *_a, **_k: fenced.setdefault(i, {"reason": "dependency"}))
        self.assertEqual(integrate.fence_closure(run), [caller.id])
        self.assertEqual(integrate.admission_selection(run, "node", BORROWER.id)["nodes"], [BORROWER.id])
        self.assertEqual(integrate.admission_selection(run, "node", caller.id)["nodes"], sorted([caller.id, SOURCE_NODE]))
        self.assertEqual(validate_a.acyclic({BORROWER.id: BORROWER, caller.id: caller}), [])

    def test_a_replan_does_not_wait_on_a_law_it_only_borrows_from(self):
        with tempfile.TemporaryDirectory() as t:
            led = Ledger(Path(t) / "l.jsonl", [LAW_ID, SRC_ID], 3)
            led.mark_planned(SRC_ID, [SOURCE_NODE], 1)                  # the source is planned, held: not accepted
            led.return_law(LAW_ID, ["r"], 1)
            by_id = {LAW_ID: LAW, SRC_ID: SRC}
            _b, waiting, _d = loop.plan_batches(led.plannable(), led, by_id, 8)
            self.assertEqual(waiting, {LAW_ID: [SRC_ID]})
            for latest, expected in (([record()], {LAW_ID: {SRC_ID}}),
                                     ([record(), comp_node("STA_900A_100_1_o2", LAW_ID, SOURCE_NODE).raw], {})):
                entries = [NS(versions=[("as planned", r)]) for r in latest]
                with mock.patch.object(plan_phase, "law_history", lambda _run, _law: (1, entries, [])):
                    borrowed, unrecorded = loop.reference_records(NS(), [LAW_ID], by_id)
                self.assertEqual((borrowed, unrecorded), (expected, set()))
            batches, waiting, _d = loop.plan_batches(led.plannable(), led, by_id, 8, {LAW_ID: {SRC_ID}})
            self.assertEqual(([[l.id for l in b] for b in batches], waiting), ([[LAW_ID]], {}))


class Fixture:
    """A run's active corpus on disk: the borrowing law, its source and one posted definition that
    applies to the source's words, with the run's resolution table."""

    def __init__(self, tmp: Path, src_text: str = SRC_TEXT):
        self.tmp = tmp
        laws = [LAW, corpus.Law(SRC_ID, SRC.title, src_text, SRC.source)]
        (tmp / "laws.jsonl").write_text("".join(json.dumps({"id": l.id, "title": l.title, "text": l.text, "source": l.source}) + "\n"
                                                for l in laws), encoding="utf-8")
        defs = [{"id": DEF_ID, "title": "Turn lane defined", "text": DEF_TEXT, "source": "STA 900A.010"}]
        (tmp / "definitions.jsonl").write_text("".join(json.dumps(d) + "\n" for d in defs), encoding="utf-8")
        self.run = NS(dir=tmp, iter=tmp / "iter", iteration=1, base_chain=[], fenced={},
                      opts=NS(laws=tmp / "laws.jsonl", definition_precedence=None, run_id="r", dry_run=True,
                              plan_turns=1, plan_effort="low", ontology=tmp / "o.md", base_run=None, gate_budget=1),
                      all_nodes=lambda: {}, all_concepts=lambda: {}, mapping_file=tmp / "mapping.json", reading_file=tmp / "reading.json",
                      read_notes=lambda: "", read_hints=lambda: "")
        (tmp / "precedence.json").write_text(json.dumps({"codes": {"STA": {"chapter_segments": 1, "general": "900A"}},
                                                         "steps": ["inline_or_section", "own_chapter", "general_chapter"]}), encoding="utf-8")
        self.run.opts.definition_precedence = str(tmp / "precedence.json")
        definitions.write_table(self.run, laws, defs)


class SourceAndDigest(unittest.TestCase):
    def test_the_fetched_source_is_the_whole_text_with_its_definitions(self):
        with tempfile.TemporaryDirectory() as t:
            f = Fixture(Path(t))
            rec = definitions.source_record(f.run, SRC_ID)
            self.assertEqual((rec["kind"], rec["text"], [d["id"] for d in rec["definitions"]]), ("law", SRC_TEXT, [DEF_ID]))
            self.assertEqual(definitions.source_record(f.run, DEF_ID)["text"], DEF_TEXT)
            self.assertIsNone(definitions.source_record(f.run, "STA-999Z-1"))
            self.assertEqual(set(definitions.source_texts(f.run)), {LAW_ID, SRC_ID, DEF_ID})

    def context(self, src_text: str, raw: dict) -> dict:
        with tempfile.TemporaryDirectory() as t:
            f = Fixture(Path(t), src_text)
            with mock.patch.object(integrate, "_files_digest", lambda _f: "files"):
                return integrate.context_parts(f.run, "node", raw["node_id"], NS(params={}, aggregate=lambda _a: None), {"core": "c"},
                                               record=raw, catalogue={"nodes": {}, "concepts": {}})

    def test_the_source_text_joins_the_context_and_its_change_changes_it(self):
        a, b = self.context(SRC_TEXT, record()), self.context(SRC_TEXT.replace("must stop", "shall stop"), record())
        self.assertIn(SRC_ID, a["sources"])
        self.assertNotEqual(a["sources"], b["sources"])
        plain = record(compositions=[]); plain["elements"][0].pop("source_spans")
        self.assertNotIn("sources", self.context(SRC_TEXT, plain))     # a node that borrows nothing keeps its context as it was

    def test_a_source_that_no_longer_holds_the_words_is_a_defect(self):
        for text, why in ((SRC_TEXT, None), (SRC_TEXT.replace("only for turning", "for turning"), "no longer holds the quoted words")):
            with tempfile.TemporaryDirectory() as t:
                f = Fixture(Path(t), text)
                got = integrate.borrowed_words_defects(f.run, BORROWER)
            self.assertEqual(bool(got), bool(why), got)
            if why:
                self.assertIn(why, got[0])
        with tempfile.TemporaryDirectory() as t:
            f = Fixture(Path(t))
            n = Node(with_comp(source="STA-999Z-1"))
            self.assertIn("no longer in the run's corpus", integrate.borrowed_words_defects(f.run, n)[0])


class Stop(Exception):
    pass


def capture(store: dict):
    def render(_name, values, **_k):
        store.update(values)
        raise Stop
    return render


class RolesSeeTheFetchedText(unittest.TestCase):
    """Each role's prompt holds the source exactly as the harness took it from the corpus, whole,
    with the definitions that apply to it."""

    def shows(self, text: str):
        self.assertIn(SRC_TEXT, text)
        self.assertIn(DEF_TEXT, text)

    def test_the_planner(self):
        with tempfile.TemporaryDirectory() as t:
            f, got = Fixture(Path(t)), {}
            stubs = {n: (lambda *_a, **_k: "") for n in ("definitions_block", "library_summary", "concept_catalogue", "parameter_catalogue",
                                                        "declaration_catalogue", "previous_records")}
            with mock.patch.multiple(plan_phase, **stubs), mock.patch.object(plan_phase.render, "render", capture(got)), \
                    mock.patch.object(plan_phase.ontology, "load", lambda _p: NS(text="")), \
                    mock.patch.object(plan_phase.ontology, "anchors_text", lambda *_a, **_k: ""), \
                    mock.patch.object(plan_phase, "MappingIndex", lambda _p: NS(render=lambda: "")), \
                    mock.patch.object(plan_phase, "Reading", lambda _p: NS()), \
                    mock.patch.object(plan_phase, "GapLedger", lambda _p: NS(render=lambda *_a: "")), \
                    mock.patch.object(plan_phase.review_phase, "upheld_block", lambda *_a, **_k: ""), \
                    mock.patch.object(plan_phase.surface, "formula_language", lambda: ""), \
                    mock.patch.object(plan_phase.surface, "concept_language", lambda: ""):
                with self.assertRaises(Stop):
                    plan_phase.run_plan(f.run, [LAW], [])
        self.shows(got["definitions"])
        self.assertIn("their own duties are not planned here", got["definitions"])

    def test_the_node_repair(self):
        with tempfile.TemporaryDirectory() as t:
            f, got = Fixture(Path(t)), {}
            last = Path(t) / "last"; last.mkdir()
            f.run.iter.mkdir()
            with mock.patch.object(plan_phase.render, "render", capture(got)), \
                    mock.patch.object(plan_phase, "definitions_for", lambda *_a: []), \
                    mock.patch.object(plan_phase, "repair_context", lambda *_a: ""), \
                    mock.patch.object(plan_phase, "GapLedger", NS(for_run=lambda *_a: NS(cited_block=lambda _r: ""))), \
                    mock.patch.object(plan_phase.review_phase, "upheld_block", lambda *_a, **_k: ""), \
                    mock.patch.object(plan_phase, "parameter_catalogue", lambda *_a: ""), \
                    mock.patch.object(plan_phase, "declaration_catalogue", lambda *_a: ""), \
                    mock.patch.object(plan_phase.ontology, "anchors_text", lambda *_a, **_k: ""):
                with self.assertRaises(Stop):
                    plan_phase.run_node_repair(f.run, BORROWER, ["r"], last, LAW, [], [BORROWER], NS(), NS(text=""))
        self.shows(got["definitions"])

    def test_the_coder(self):
        with tempfile.TemporaryDirectory() as t:
            f, got = Fixture(Path(t)), {}
            f.run.iter.mkdir()
            stubs = {"task_context": lambda *_a: None, "_task_files": lambda *_a: None, "_start": lambda *_a: {},
                     "write_skeletons": lambda _n: ("", ""), "contracts_block": lambda *_a: "", "reading_table": lambda *_a: "",
                     "worked_example": lambda *_a: "", "gate_cli": lambda *_a: "gate"}
            with mock.patch.multiple(code_phase, **stubs), mock.patch.object(code_phase.render, "render", capture(got)), \
                    mock.patch.object(code_phase, "GapLedger", NS(for_run=lambda *_a: NS(cited_block=lambda _r: ""))), \
                    mock.patch.object(code_phase.surface, "core_surface", lambda *_a, **_k: ""), \
                    mock.patch.object(code_phase.ontology, "load", lambda _p: NS()), \
                    mock.patch.object(code_phase.ontology, "anchors_text", lambda *_a, **_k: ""):
                with self.assertRaises(Stop):
                    code_phase.run_code(f.run, BORROWER, NS())
        self.shows(got["node"])

    def context(self, run) -> review.Context:
        with mock.patch.object(review.validate_phase, "glosses_for", lambda *_a: {}), \
                mock.patch.object(review.render_formula, "render_rule", lambda *_a: "the rendering"), \
                mock.patch.object(review, "duty_of", lambda *_a: {}), mock.patch.object(review, "duty_block", lambda *_a: ""), \
                mock.patch.object(review, "precedent_rows", lambda *_a: []), \
                mock.patch.object(review.ontology, "not_atoms_text", lambda _o: ""), \
                mock.patch("harness.phases.aggregate.certificate_digests", lambda _r: {}):
            return review.build_context(run, BORROWER, LAW, NS(), NS(data={"params": []}, aggregate=lambda _a: None), {}, [])

    def test_the_judges(self):
        with tempfile.TemporaryDirectory() as t:
            f = Fixture(Path(t))
            ctx = self.context(f.run)
        a = review.stage_a_prompt(ctx, "the case", {})
        self.shows(a)
        self.assertIn("its own duties are not judged here", a)
        self.assertNotIn("source_spans", a)                               # stage A sees no record
        with mock.patch.object(review, "GapLedger", NS(for_run=lambda *_a: NS(cited_block=lambda _r: ""))):
            b = review.stage_b_prompt(NS(), ctx, "the item", {})
        self.shows(b)
        ok = {"verdict": "violated", "decisive": True, "law_words": QUOTE, "reason": "r"}
        self.assertEqual(review.stage_a_defects(ok, review.context_haystack(ctx)), [])  # the source's words may be quoted

    def test_the_reviewer(self):
        with tempfile.TemporaryDirectory() as t:
            f = Fixture(Path(t))
            ctx = self.context(f.run)
            out = Path(t) / "review"
            f.run.opts.max_divergences, f.run.opts.review_passes = 3, 1
            f.run.opts.review_checks = f.run.opts.review_submissions = 1
            stubs = {"enabled": lambda _r: True, "build_context": lambda *_a: ctx, "history_of": lambda *_a: [], "history_text": lambda _n: "",
                     "replay_obligations": lambda *_a: NS(reasons=[], evidence=[], notes=[], keys=[], satisfied=[]),
                     "atoms_read_block": lambda *_a: "", "_parameters_block": lambda *_a: "", "trace_format_block": lambda: "",
                     "obligations_of": lambda *_a: [], "BehaviourTools": lambda *_a, **_k: NS(), "window_params": lambda _p: {}}
            with mock.patch.multiple(review, **stubs), \
                    mock.patch.object(review, "GapLedger", NS(for_run=lambda *_a: NS(cited_block=lambda _r: ""))), \
                    mock.patch.object(review.surface, "case_language", lambda: ""), \
                    mock.patch.object(review.surface, "case_vocabulary", lambda _o: ""):
                review.review_behaviour(f.run, BORROWER, LAW, NS(), NS(data={"params": []}), {"binders": []}, [], out)
            text = (out / "review_behaviour_prompt.md").read_text(encoding="utf-8")
        self.shows(text)


if __name__ == "__main__":
    unittest.main()
