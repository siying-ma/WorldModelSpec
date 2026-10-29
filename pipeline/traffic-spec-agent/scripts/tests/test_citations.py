"""One reader of the ids posted text names in brackets, for the dependency order, the reference
check, the subset closure and the split's self-containment: a bracket may name several ids, mix a
definition with laws, or hold other words."""
import json
import sys
import unittest
from pathlib import Path

from harness.model import corpus

REPO = Path(__file__).resolve().parents[2]
TRAIN = REPO / "laws" / "example" / "train" / "laws.jsonl"


class Brackets(unittest.TestCase):
    def test_a_bracket_names_several_ids(self):
        self.assertEqual(corpus.cited_law_ids("as in [L-1a, L-1b] and [L-2]"), ["L-1a", "L-1b", "L-2"])

    def test_a_definition_is_not_a_law_but_is_an_id(self):
        text = "a term [DEF-X-1, L-3]"
        self.assertEqual(corpus.cited_law_ids(text), ["L-3"])
        self.assertEqual(corpus.bracketed_ids(text), ["DEF-X-1", "L-3"])

    def test_other_words_in_a_bracket_are_not_ids(self):
        self.assertEqual(corpus.cited_law_ids("[(c) is appended below, L-8d] [list appended below]"), ["L-8d"])

    def test_an_id_named_twice_is_listed_once(self):
        self.assertEqual(corpus.cited_law_ids("[L-1] then [L-1, L-2]"), ["L-1", "L-2"])

    def test_every_posted_bracket_is_read_whole(self):
        """On the training corpus: every id-shaped item of every bracket is read, and a bracket
        naming several laws exists, so the multi-id form is exercised on posted text."""
        multi = 0
        for line in TRAIN.read_text(encoding="utf-8").splitlines():
            text = json.loads(line)["text"]
            for b in corpus.BRACKET.findall(text):
                items = [x.strip() for x in b.split(",") if corpus.CITED_ID.fullmatch(x.strip())]
                laws = [x for x in items if not x.startswith("DEF-")]
                multi += len(laws) > 1
                for x in items:
                    self.assertIn(x, corpus.bracketed_ids(text))
                for x in laws:
                    self.assertIn(x, corpus.cited_law_ids(text))
        self.assertGreater(multi, 0)


class SubsetClosure(unittest.TestCase):
    def test_a_subset_closes_over_a_multi_id_bracket(self):
        sys.path.insert(0, str(REPO.parent / "ontology_provenance"))
        from nrs_tools import subset
        laws = {"L-1": {"text": "see [L-2, L-3]"}, "L-2": {"text": "none"}, "L-3": {"text": "and [DEF-L-9, L-4]"}, "L-4": {"text": ""}}
        self.assertEqual(subset.closure(["L-1"], laws), ["L-1", "L-2", "L-3", "L-4"])


if __name__ == "__main__":
    unittest.main()
