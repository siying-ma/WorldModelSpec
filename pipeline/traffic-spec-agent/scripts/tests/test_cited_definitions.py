"""A posted definition a law names in brackets reaches every planning and repair prompt with its
text, even when it defines no term the law's words use; a definition the definitions block already
shows is not shown twice; and the order of the laws still reads only the law ids a text names."""
from __future__ import annotations
import json
import tempfile
import unittest
from pathlib import Path
from types import SimpleNamespace as NS

from harness.model import corpus, definitions
from harness.model.blueprint import ConceptRecord
from harness.phases import plan as plan_phase

LAW_ONLY_DEF, LAW_BOTH, LAW_USES, SRC_ID = "STA-900A-100-1", "STA-900A-110-1", "STA-900A-120-1", "STA-900A-200-1"
USED_DEF, CITED_DEF = "DEF-STA-900A-010", "DEF-STA-900A-020"
USED_TEXT = "“Turn lane” means a lane marked for turning movements only."
CITED_TEXT = "A portion of a highway may be reserved for the exclusive use of bicycles by markings and signs."    # no term defined
SRC_TEXT = "A vehicle shall keep to the right half of the highway."
LAWS = [corpus.Law(LAW_ONLY_DEF, "Only a definition", f"A driver shall yield to a bicycle in it [{CITED_DEF}].", "STA 900A.100"),
        corpus.Law(LAW_BOTH, "Both", f"Except as provided in [{SRC_ID}] and [{CITED_DEF}], a driver shall keep right.", "STA 900A.110"),
        corpus.Law(LAW_USES, "A used term", f"A driver in a turn lane [{USED_DEF}] shall turn.", "STA 900A.120"),
        corpus.Law(SRC_ID, "The source", SRC_TEXT, "STA 900A.200")]
DEFS = [{"id": USED_DEF, "title": "Turn lane defined", "text": USED_TEXT, "source": "STA 900A.010"},
        {"id": CITED_DEF, "title": "Reserved portions", "text": CITED_TEXT, "source": "STA 900A.020"}]
BY_ID = {l.id: l for l in LAWS}


def corpus_run(tmp: Path):
    """A run's active corpus on disk: the laws, the two posted definitions and the resolution table."""
    (tmp / "laws.jsonl").write_text("".join(json.dumps({"id": l.id, "title": l.title, "text": l.text, "source": l.source}) + "\n"
                                            for l in LAWS), encoding="utf-8")
    (tmp / "definitions.jsonl").write_text("".join(json.dumps(d) + "\n" for d in DEFS), encoding="utf-8")
    (tmp / "precedence.json").write_text(json.dumps({"codes": {"STA": {"chapter_segments": 1, "general": "900A"}},
                                                     "steps": ["inline_or_section", "own_chapter", "general_chapter"]}), encoding="utf-8")
    run = NS(dir=tmp, iter=tmp / "iter", iteration=1, base_chain=[], fenced={},
             opts=NS(laws=tmp / "laws.jsonl", definition_precedence=str(tmp / "precedence.json"), run_id="r", dry_run=True,
                     plan_turns=1, plan_effort="low", ontology=tmp / "o.md", base_run=None, gate_budget=1),
             all_nodes=lambda: {}, all_concepts=lambda: {}, mapping_file=tmp / "mapping.json", reading_file=tmp / "reading.json",
             read_notes=lambda: "", read_hints=lambda: "")
    definitions.write_table(run, LAWS, DEFS)
    return run


class CitedSources(unittest.TestCase):
    def cited(self, *law_ids: str) -> list[str]:
        with tempfile.TemporaryDirectory() as t:
            run = corpus_run(Path(t))
            return [r["id"] for r in definitions.cited_sources(run, [BY_ID[i] for i in law_ids])]

    def test_a_law_naming_only_a_definition_that_defines_none_of_its_words(self):
        with tempfile.TemporaryDirectory() as t:
            run = corpus_run(Path(t))
            self.assertEqual(definitions.applicable(run, LAW_ONLY_DEF), [])
            recs = definitions.cited_sources(run, [BY_ID[LAW_ONLY_DEF]])
        self.assertEqual([(r["kind"], r["id"], r["text"]) for r in recs], [("definition", CITED_DEF, CITED_TEXT)])

    def test_a_law_naming_a_law_and_a_definition(self):
        self.assertEqual(self.cited(LAW_BOTH), [SRC_ID, CITED_DEF])

    def test_a_definition_the_definitions_block_shows_is_not_shown_again(self):
        with tempfile.TemporaryDirectory() as t:
            run = corpus_run(Path(t))
            self.assertEqual([d["id"] for d in definitions.applicable(run, LAW_USES)], [USED_DEF])
            self.assertEqual(definitions.cited_sources(run, [BY_ID[LAW_USES]]), [])
            borrower = NS(definition_sources=lambda: [USED_DEF, CITED_DEF])      # a record that borrows from both
            self.assertEqual([r["id"] for r in definitions.cited_sources(run, [BY_ID[LAW_USES]], [borrower])], [CITED_DEF])

    def test_a_batch_shows_each_source_once(self):
        self.assertEqual(self.cited(LAW_ONLY_DEF, LAW_BOTH, LAW_USES), [CITED_DEF, SRC_ID])

    def test_the_law_order_reads_only_the_law_ids(self):
        self.assertEqual(corpus.cited_law_ids(BY_ID[LAW_BOTH].text), [SRC_ID])
        self.assertEqual(corpus.references(BY_ID[LAW_BOTH], set(BY_ID) | {CITED_DEF}), {SRC_ID})


class EveryInputShowsTheCitedText(unittest.TestCase):
    """The plan, the re-plan, the node repair and the law-level label repair of a law that names a
    posted definition defining none of its words each show that definition's text once; the concept
    repair, shown no law, shows the text of the definition its record is bound to."""

    def test_each_input(self):
        from scripts.tests.test_label_repair import L
        from scripts.tests.test_label_repair_session import PromptScope
        from scripts.tests.test_candidate import concept_rec
        scope = PromptScope()
        with scope.labels_run() as (run, _ledger, _training, by_id):
            laws = Path(run.opts.laws)
            rows = [json.loads(x) for x in laws.read_text(encoding="utf-8").splitlines() if x.strip()]
            for r in rows:
                if r["id"] in (L[1], L[5]):
                    r["text"] = f"A driver shall proceed slowly past a bicycle in it [{CITED_DEF}]."
                    by_id[r["id"]] = corpus.Law(r["id"], r["title"], r["text"], r["source"])
            laws.write_text("".join(json.dumps(r) + "\n" for r in rows), encoding="utf-8")
            laws.with_name("definitions.jsonl").write_text(json.dumps(DEFS[1]) + "\n", encoding="utf-8")
            rec = ConceptRecord({**concept_rec("drv.motion.cited_probe"), "definition": CITED_DEF})
            with tempfile.TemporaryDirectory() as last:
                concept_repair = (plan_phase.run_repair(run, rec, ["gate CHECK_FAIL: a witness fails"], Path(last), [DEFS[1]], [])
                                  / "prompt.md").read_text(encoding="utf-8")
            prompts = {"plan": (plan_phase.run_plan(run, [by_id[L[1]]], [], tag="plain") / "prompt.md").read_text(encoding="utf-8"),
                       "replan": (plan_phase.run_plan(run, [by_id[L[5]]], [], tag="replan", label_repair=True) / "prompt.md").read_text(encoding="utf-8"),
                       "node_repair": scope.node_repair_prompt(run, by_id), "label_repair": scope.label_repair_prompt(run, by_id),
                       "concept_repair": concept_repair}
        for name, text in prompts.items():
            self.assertEqual(text.count(CITED_TEXT), 1, name)
            if name != "concept_repair":
                self.assertIn(f"#### `{CITED_DEF}` — {DEFS[1]['title']}", text, name)


if __name__ == "__main__":
    unittest.main()
