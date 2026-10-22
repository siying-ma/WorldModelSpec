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


class PostedInputOnly(unittest.TestCase):
    def test_the_resolver_reads_no_sidecar(self):
        src = (Path(D.__file__)).read_text(encoding="utf-8")
        self.assertNotIn("audit_and_scripts", src)
        self.assertNotIn("_meta", src)


if __name__ == "__main__":
    unittest.main()
