"""The fence a context recheck writes keeps its evidence readable: an upheld challenge the body
confirms again is named by its line as notes show it, the verdict part included, and a challenge
that cannot be run is named by a summary cut at a word boundary."""
import sys
import unittest
from pathlib import Path
from unittest import mock

sys.path.insert(0, str(Path(__file__).resolve().parent))

from harness.model.reading import Reading
from harness.lean import surface
from harness.phases import integrate, review

import test_recovery as R
from test_library_compatibility import Results

CID = "drv.motion.creep"
LONG = " ".join(f"word{n:03d}" for n in range(60))           # 479 characters
ROW = {"subject": CID, "ruling_id": "k1", "ruling": "upheld", "obligation": "open", "schema": review.CONCEPT_CASE_SCHEMA,
       "kind": "fails_wrongly", "situation": LONG, "contract_words": "the words", "contract_verdict": "holds", "iteration": 1,
       "grounding": {"u": 1}, "instance": {}, "trace": {"scenes": [{"t": 0}]}, "at": 0}


def confirmed(d: dict) -> dict:
    lines = {f: review.divergence_lines(1, d, False, "fails", None, "", cut)[1] for f, cut in review.LINE_FORMS.items()}
    return {**lines, "div": d, "rule": "fails", "key": d["kind"], "verdict": "violated", "value": None, "facts": "F"}


class FenceEvidence(unittest.TestCase):
    def fence(self, execution) -> str:
        with Results() as r:
            r.run("A", concepts={CID: {**R.concept(CID), "context": "old"}}, rulings=[ROW])
            run = r.load("B", "A", ["L-2"])
            with mock.patch.object(review, "execute_concept_divergences", return_value=execution), \
                 mock.patch.object(review, "_registry", return_value=None):
                integrate.recheck_contexts(run, Reading(r.tmp / "none.json"), {"core": "c"}, {})
            self.assertEqual(run.fenced[CID]["reason"], "context")
            return run.fenced[CID]["evidence"]

    def test_a_confirmed_challenge_keeps_its_verdict(self):
        ev = self.fence(([confirmed(ROW)], [], [], []))
        self.assertIn("— contract: holds, body: fails; contract: \"the words\"", ev)
        situation = ev.split(" ms: ", 1)[1].split(" — contract:", 1)[0]
        self.assertTrue(situation.endswith(" …"))
        self.assertTrue(LONG.startswith(situation[:-2]) and LONG[len(situation) - 2] == " ")

    def test_an_unrunnable_challenge_is_cut_at_a_word(self):
        ev = self.fence(([], [], [], [f"divergence 1: {LONG}"]))
        shown = ev.split("cannot be run on it: ", 1)[1]
        self.assertTrue(shown.endswith(" …"))
        whole = f"divergence 1: {LONG}"
        self.assertTrue(whole.startswith(shown[:-2]) and whole[len(shown) - 2] == " ")

    def test_three_long_problems_are_cut_at_a_word(self):
        ev = self.fence(([], [], [f"divergence {k}: {LONG}" for k in (1, 2, 3)], []))
        self.assertTrue(ev.endswith(" …"))
        self.assertLessEqual(len(ev), 602)
        for k in (1, 2, 3):
            self.assertIn(f"an upheld challenge cannot be run on it: divergence {k}: word000 word001", ev)
        whole = "; ".join(f"an upheld challenge cannot be run on it: {surface.shorten(f'divergence {k}: {LONG}', 200)}" for k in (1, 2, 3))
        self.assertTrue(whole.startswith(ev[:-2]) and whole[len(ev) - 2] == " ")


if __name__ == "__main__":
    unittest.main()
