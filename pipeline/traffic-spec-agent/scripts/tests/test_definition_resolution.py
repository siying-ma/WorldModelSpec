"""Development regression tests for definition resolution: what counts as a definition and as a use, and the declared precedence,
on a synthetic corpus whose ids follow the configured grammar and name no real law."""
import unittest
from pathlib import Path

from harness.model import corpus, definitions as D

CONFIG = {"codes": {"STA": {"chapter_segments": 1, "general": "900A"},
                    "MUNI": {"chapter_segments": 2, "general": "77.02", "fallback": "STA"}},
          "steps": ["inline_or_section", "own_chapter", "general_chapter", "fallback_code"]}


def d(i, text):
    return {"id": i, "title": "", "text": text, "source": ""}


DEFS = [
    d("DEF-STA-900A-010", "“Wagon” means every device upon which a person may be carried."),
    d("DEF-STA-900A-020", "“Motor wagon” means a wagon that is self-propelled."),
    d("DEF-STA-900A-030", "“Halt,” when required, means complete cessation from movement."),
    d("DEF-STA-900A-031", "“Halt” or “halting” means, when prohibited, any halting of a wagon."),
    d("DEF-STA-900A-040", "“Tricar” has the meaning ascribed to it in STA 900B.050."),
    d("DEF-STA-900B-050", "“Tricar” means a wagon on three wheels."),
    d("DEF-STA-900B-060", "“Lane” means a strip of the way."),
    d("DEF-STA-900A-060", "“Lane” means any marked strip."),
    d("DEF-STA-900C-070", "“Sled” means a wagon on runners."),
    d("DEF-STA-900B-080-1", "As used in this section, “courier” means a person who carries parcels."),
    d("DEF-STA-900A-090", "“Loop” has the meaning ascribed to it in STA 900A.091."),
    d("DEF-STA-900A-091", "“Ring” has the meaning ascribed to it in STA 900A.090."),
    d("DEF-STA-900A-095", "“Gadget” has the meaning ascribed to it in STA 999.001."),
    d("DEF-STA-900A-100", "“Operator” means a person who controls a wagon."),
    d("DEF-STA-900A-110", "“Traffic” means wagons using a lane for travel."),
    d("DEF-STA-900A-120", "“Pair” means every twin travelling in a pair."),
    d("DEF-STA-900A-121", "“Twin” means a member of a pair."),
    d("DEF-MUNI-77-02-010", "\"Wagon\" means a city wagon."),
    d("DEF-MUNI-77-40-185-A", "Unless otherwise posted, a \"wagon\" or a \"sled\" may be operated on a path."),
]


def law(i, text):
    return corpus.Law(i, "", text, "")


def rows(law_obj, defs=DEFS):
    return {r["term"]: r for r in D.resolve_table([law_obj], defs, CONFIG)["laws"][law_obj.id]}


class Extraction(unittest.TestCase):
    def test_definition_versus_provision(self):
        ids = {c.definition for c in D.extract(DEFS, CONFIG)}
        self.assertIn("DEF-MUNI-77-02-010", ids)
        self.assertNotIn("DEF-MUNI-77-40-185-A", ids)        # it regulates; it defines nothing

    def test_several_terms_and_a_qualifier(self):
        terms = {(c.definition, c.term) for c in D.extract(DEFS, CONFIG)}
        self.assertIn(("DEF-STA-900A-030", "halt"), terms)
        self.assertIn(("DEF-STA-900A-031", "halting"), terms)

    def test_section_only(self):
        c = next(c for c in D.extract(DEFS, CONFIG) if c.definition == "DEF-STA-900B-080-1")
        self.assertTrue(c.section_only)


class Uses(unittest.TestCase):
    def test_token_boundaries_and_plurals(self):
        self.assertEqual(D.uses("Two wagons and a wagonload.", ["wagon"]), ["wagon"])
        self.assertEqual(D.uses("The wagonload is heavy.", ["wagon"]), [])

    def test_longest_first(self):
        self.assertEqual(D.uses("A motor wagon passes a wagon.", ["wagon", "motor wagon"]), ["motor wagon", "wagon"])
        self.assertEqual(D.uses("A motor wagon passes.", ["wagon", "motor wagon"]), ["motor wagon"])

    def test_an_inline_citation_is_not_a_word(self):
        self.assertEqual(D.uses("As defined in [DEF-STA-900A-010], it applies.", ["wagon"]), [])


class Precedence(unittest.TestCase):
    def test_general_chapter(self):
        r = rows(law("STA-900B-100", "No wagon shall pass."))["wagon"]
        self.assertEqual((r["status"], r["definition"], r["step"]), ("resolved", "DEF-STA-900A-010", "general_chapter"))

    def test_own_chapter_first(self):
        self.assertEqual(rows(law("STA-900B-100", "Keep in the lane."))["lane"]["definition"], "DEF-STA-900B-060")
        self.assertEqual(rows(law("STA-900A-200", "Keep in the lane."))["lane"]["definition"], "DEF-STA-900A-060")

    def test_inline_citation_decides(self):
        r = rows(law("STA-900B-100", "Keep in the lane [DEF-STA-900A-060]."))["lane"]
        self.assertEqual((r["definition"], r["step"]), ("DEF-STA-900A-060", "inline_or_section"))

    def test_section_only_definition_stays_in_its_section(self):
        self.assertEqual(rows(law("STA-900B-080-2", "A courier shall yield."))["courier"]["definition"], "DEF-STA-900B-080-1")
        self.assertEqual(rows(law("STA-900B-081", "A courier shall yield."))["courier"]["status"], "unresolved")

    def test_fallback_code(self):
        r = rows(law("MUNI-77-40-010", "A tricar shall yield."))["tricar"]
        self.assertEqual((r["step"], r["definition"]), ("fallback_code", "DEF-STA-900A-040"))
        self.assertEqual(rows(law("MUNI-77-40-010", "A wagon shall yield."))["wagon"]["definition"], "DEF-MUNI-77-02-010")

    def test_another_chapter_of_the_same_code_is_never_reached(self):
        self.assertEqual(rows(law("STA-900B-100", "No sled shall pass."))["sled"]["status"], "unresolved")

    def test_cross_reference_followed(self):
        r = rows(law("STA-900B-100", "No tricar shall pass."))["tricar"]
        self.assertEqual(r["definition"], "DEF-STA-900B-050")      # own chapter decides first here
        r = rows(law("STA-900C-100", "No tricar shall pass."))["tricar"]
        self.assertEqual((r["definition"], r["chain"]), ("DEF-STA-900A-040", ["DEF-STA-900A-040", "DEF-STA-900B-050"]))

    def test_cycle_and_unposted_citation(self):
        self.assertIn("cycle", rows(law("STA-900C-100", "Round the loop."))["loop"]["why"])
        self.assertIn("not posted", rows(law("STA-900C-100", "A gadget fails."))["gadget"]["why"])

    def test_duplicate_candidates_are_ambiguous(self):
        r = rows(law("STA-900B-100", "The wagon shall halt."))["halt"]
        self.assertEqual((r["status"], r["candidates"]), ("ambiguous", ["DEF-STA-900A-030", "DEF-STA-900A-031"]))


class DefinitionDependencies(unittest.TestCase):
    def test_a_defined_term_inside_a_definition_resolves_from_that_definitions_place(self):
        table = D.resolve_table([law("STA-900B-100", "The operator shall halt.")], DEFS, CONFIG)
        r = table["laws"]["STA-900B-100"][0]
        wagon = next(x for x in table["dependencies"][r["definition"]] if x["term"] == "wagon")
        self.assertEqual((wagon["from"], wagon["status"], wagon["definition"], wagon["step"]),
                         ("DEF-STA-900A-100", "resolved", "DEF-STA-900A-010", "own_chapter"))
        self.assertEqual(D.source_ids(table, "DEF-STA-900A-100"),
                         ["DEF-STA-900A-100", "DEF-STA-900A-010"])

    def test_nested_resolution_does_not_reach_an_unrelated_same_code_chapter(self):
        defs = DEFS + [d("DEF-STA-900A-130", "“Convoy” means sleds travelling together.")]
        table = D.resolve_table([law("STA-900B-100", "A convoy shall halt.")], defs, CONFIG)
        r = table["laws"]["STA-900B-100"][0]
        sled = next(x for x in table["dependencies"][r["definition"]] if x["term"] == "sled")
        self.assertEqual((sled["status"], sled["definition"]), ("unresolved", None))
        self.assertEqual(sled["candidates"], ["DEF-STA-900C-070"])

    def test_a_dependency_cycle_is_recorded_once_and_terminates(self):
        table = D.resolve_table([law("STA-900B-100", "A pair shall halt.")], DEFS, CONFIG)
        r = table["laws"]["STA-900B-100"][0]
        deps = table["dependencies"][r["definition"]]
        self.assertLess(len(deps), 10)
        self.assertTrue(any(x["term"] == "pair" and x.get("cycle") for x in deps), deps)

    def test_source_ids_include_resolved_nested_definitions(self):
        table = D.resolve_table([law("STA-900B-100", "The operator shall halt.")], DEFS, CONFIG)
        r = table["laws"]["STA-900B-100"][0]
        self.assertIn("DEF-STA-900A-010", D.source_ids(table, r["definition"]))

    def test_a_shared_definition_has_one_persisted_dependency_graph(self):
        table = D.resolve_table([law("STA-900B-100", "The operator shall halt."),
                                 law("STA-900C-100", "The operator shall yield.")], DEFS, CONFIG)
        self.assertIn("DEF-STA-900A-100", table["dependencies"])
        self.assertNotIn("dependencies", table["laws"]["STA-900B-100"][0])
        self.assertNotIn("dependencies", table["laws"]["STA-900C-100"][0])


SPLIT_DEFS = DEFS + [
    d("DEF-STA-900A-140", "“Two-way lane” means an undivided lane on which wagons travel both ways."),
    d("DEF-STA-900B-140", "“Two-way lane” means a lane of this chapter on which wagons travel both ways."),
    d("DEF-STA-900A-150", "“Paved two-way lane” means a two-way lane with a hard surface."),
]
SPLIT_TERMS = sorted({c.term for c in D.extract(SPLIT_DEFS, CONFIG)})


def split_of(text):
    return [(t, w) for t, how, w in D.matches(text, SPLIT_TERMS) if how == "split"]


class SplitUses(unittest.TestCase):
    """A term of several words used in the bounded copular form `<head> is|are [not] <modifiers>`."""

    def test_copular_form(self):
        self.assertEqual(split_of("Both crossing lanes are two-way."), [("two-way lane", "lanes are two-way")])
        self.assertEqual(split_of("The lane is two-way."), [("two-way lane", "lane is two-way")])
        self.assertEqual(split_of("Halt where the lane which is two-way ends."), [])          # the predicate goes on: "ends"
        self.assertEqual(split_of("A lane which is two-way, the sign says."), [("two-way lane", "lane which is two-way")])

    def test_plural_head(self):
        self.assertEqual(D.uses("Where both lanes are two-way: keep right.", ["lane", "two-way lane"]), ["lane", "two-way lane"])
        self.assertEqual(split_of("If the lanes are two-way and the wagon turns, yield."), [("two-way lane", "lanes are two-way")])

    def test_negation_still_uses_the_term(self):
        self.assertEqual(split_of("If the lane is not two-way, keep right."), [("two-way lane", "lane is not two-way")])
        self.assertEqual(split_of("Where the lanes are not two-way, keep right."), [("two-way lane", "lanes are not two-way")])

    def test_longest_term_first(self):
        self.assertEqual(split_of("The lanes are paved two-way."), [("paved two-way lane", "lanes are paved two-way")])

    def test_a_modifier_that_qualifies_another_noun_is_no_use(self):
        self.assertEqual(split_of("The lane is straight and the side road is two-way."), [])
        self.assertEqual(split_of("The lanes are two-way roads."), [])                       # it qualifies "roads"
        self.assertEqual(split_of("The road beside the lane is two-way."), [])               # "lane" is not the subject
        self.assertEqual(split_of("A two-way flag marks the lane."), [])                     # co-occurrence only

    def test_no_match_across_a_sentence_or_clause(self):
        self.assertEqual(split_of("The wagon passes two lanes is two-way."), [("two-way lane", "lanes is two-way")])   # control
        self.assertEqual(split_of("The wagon passes two lanes. Is two-way."), [])
        self.assertEqual(split_of("The wagon passes two lanes; is two-way."), [])
        self.assertEqual(split_of("The wagon passes two lanes, is two-way."), [])

    def test_a_contiguous_use_is_never_displaced(self):
        found = D.matches("A two-way lane ends. Both lanes are two-way.", SPLIT_TERMS)
        self.assertEqual([(t, how) for t, how, _ in found], [("two-way lane", "contiguous"), ("lane", "contiguous")])
        found = D.matches("Both lanes are two-way.", SPLIT_TERMS)
        self.assertEqual([(t, how) for t, how, _ in found], [("lane", "contiguous"), ("two-way lane", "split")])

    def test_precedence_and_the_recorded_row(self):
        r = rows(law("STA-900B-200", "Where both lanes are two-way, keep right."), SPLIT_DEFS)
        self.assertEqual({k: r["two-way lane"][k] for k in ("status", "definition", "step", "match", "words")},
                         {"status": "resolved", "definition": "DEF-STA-900B-140", "step": "own_chapter",
                          "match": "split", "words": "lanes are two-way"})
        self.assertNotIn("match", r["lane"])
        r = rows(law("STA-900C-200", "Where both lanes are two-way, keep right."), SPLIT_DEFS)["two-way lane"]
        self.assertEqual((r["definition"], r["step"]), ("DEF-STA-900A-140", "general_chapter"))
        r = rows(law("STA-900B-200", "Where both lanes are two-way [DEF-STA-900A-140], keep right."), SPLIT_DEFS)["two-way lane"]
        self.assertEqual((r["definition"], r["step"]), ("DEF-STA-900A-140", "inline_or_section"))
        self.assertNotIn("match", r)                                                         # found by its citation
        r = rows(law("STA-900B-200", "A two-way lane ends where both lanes are two-way."), SPLIT_DEFS)["two-way lane"]
        self.assertNotIn("match", r)

    def test_a_split_use_inside_a_definition_is_marked_too(self):
        defs = SPLIT_DEFS + [d("DEF-STA-900A-160", "“Crossing” means a place where two lanes are two-way.")]
        table = D.resolve_table([law("STA-900C-100", "Halt at the crossing.")], defs, CONFIG)
        dep = next(x for x in table["dependencies"]["DEF-STA-900A-160"] if x["term"] == "two-way lane")
        self.assertEqual((dep["definition"], dep["match"], dep["words"]), ("DEF-STA-900A-140", "split", "lanes are two-way"))

    def test_the_sessions_are_shown_the_split_words(self):
        import json, tempfile
        from types import SimpleNamespace
        from harness.checks import aggregates
        from harness.phases import review
        with tempfile.TemporaryDirectory() as tmp:
            tmp = Path(tmp)
            (tmp / "laws.jsonl").write_text("", encoding="utf-8")
            (tmp / "definitions.jsonl").write_text("".join(json.dumps(x) + "\n" for x in SPLIT_DEFS), encoding="utf-8")
            (tmp / "precedence.json").write_text(json.dumps(CONFIG), encoding="utf-8")
            run = SimpleNamespace(dir=tmp, opts=SimpleNamespace(laws=tmp / "laws.jsonl", definition_precedence=str(tmp / "precedence.json")))
            the_law = law("STA-900B-200", "Where both lanes are two-way, keep right.")
            D.write_table(run, [the_law], SPLIT_DEFS)
            shown = D.applicable(run, the_law.id)
            self.assertEqual([(x["id"], x.get("split")) for x in shown if x["id"] in ("DEF-STA-900B-140", "DEF-STA-900B-060")],
                             [("DEF-STA-900B-060", None), ("DEF-STA-900B-140", "lanes are two-way")])
            note = 'the law\'s words "lanes are two-way" use this defined term in the copular form'
            self.assertIn(note, review.definitions_block(shown))
            self.assertIn(note, corpus.render_definitions(shown))
            self.assertIn('| STA-900B-200 | two-way lane (found split: "lanes are two-way") | `DEF-STA-900B-140` |',
                          aggregates.render(None, {the_law.id: D.rows_for(run, the_law.id)}, {}))


class PostedInputOnly(unittest.TestCase):
    def test_the_resolver_reads_no_sidecar(self):
        src = (Path(D.__file__)).read_text(encoding="utf-8")
        self.assertNotIn("audit_and_scripts", src)
        self.assertNotIn("_meta", src)


if __name__ == "__main__":
    unittest.main()
