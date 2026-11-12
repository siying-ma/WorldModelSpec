"""A term a corpus text takes from a cited NRS section is a definition of the corpus, verbatim."""
import json
from pathlib import Path
import re
import unittest

from test_version_note import SOURCES, load_make_laws

TOOLS = Path(__file__).resolve().parent
DEFINITIONS = TOOLS.parents[1] / "traffic-spec-agent" / "laws" / "full_list" / "definitions.jsonl"


def words(text):
    """The words of a section, without its paragraph labels and the definition ids marked in it."""
    text = re.sub(r"\s*\[DEF-[\w-]+\]", "", text)
    text = re.sub(r"(?:^|(?<=\s))(?:\(\w{1,4}\)|\d+\.)(?=\s)", " ", text)
    return text.split()


class IncorporatedDefinitions(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.ml = load_make_laws()
        from references import INCORPORATED
        cls.incorporated = INCORPORATED

    def test_a_citation_of_a_section_outside_the_corpus_is_reported(self):
        texts = [{"id": "DEF-X", "text": "a person on a device as defined in NRS 482.029."},
                 {"id": "DEF-Y", "text": "“Home” has the meaning ascribed to it in NRS 489.113."},
                 {"id": "L-1", "text": "an agency, as that term is defined in NRS 239C.065, in the course of duty"},
                 {"id": "DEF-Z", "text": "excluding a bicycle as defined in NRS 484B.017"},
                 {"id": "DEF-W", "text": "a disability, as that term is defined in subsection 1 or 2 of NRS 482.0962."},
                 {"id": "DEF-V", "text": "has the meaning ascribed to it in SAE J3016."}]
        self.assertEqual(self.ml.missing_incorporations(texts, {"DEF-NRS-484B-017"}),
                         [("DEF-X", "NRS 482.029"), ("DEF-Y", "NRS 489.113"), ("L-1", "NRS 239C.065"), ("DEF-W", "NRS 482.0962")])
        self.assertEqual(self.ml.missing_incorporations(texts, {"DEF-NRS-484B-017", "DEF-NRS-482-029", "DEF-NRS-489-113",
                                                                "DEF-NRS-239C-065", "DEF-NRS-482-0962"}), [])

    def test_every_incorporated_section_is_in_the_corpus_verbatim(self):
        defs = {d["id"]: d for d in map(json.loads, DEFINITIONS.read_text(encoding="utf-8").splitlines())}
        for ch, sec in self.incorporated:
            src = json.loads((SOURCES / f"{ch}.json").read_text(encoding="utf-8"))[sec]
            d = defs[f"DEF-NRS-{ch}-{sec}"]
            self.assertEqual(d["source"], f"NRS {ch}.{sec}")
            body = [l for l in src["text"].split("\n") if not l.startswith("(Added")]
            self.assertEqual(words(d["text"]), words(" ".join(body)), (ch, sec))

    def test_no_corpus_text_takes_a_term_from_a_missing_section(self):
        defs = [json.loads(l) for l in DEFINITIONS.read_text(encoding="utf-8").splitlines()]
        self.assertEqual(self.ml.missing_incorporations(defs, {d["id"] for d in defs}), [])


if __name__ == "__main__":
    unittest.main()
