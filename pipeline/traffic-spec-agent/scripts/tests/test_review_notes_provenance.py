"""A concept review's notes keep their provenance, and the concept catalogue a plan reads shows as a
deviation from the contract's words only what the review confirmed. A dismissed ruling, a challenge
execution refuted, an upheld challenge the body now meets and the reviewer's own advisories are
review notes; a record written before notes carried provenance (`approximations`) is shown among
them, never dropped. No note is cut inside a word."""
import json
import re
import tempfile
import unittest
from pathlib import Path
from types import SimpleNamespace as NS
from unittest import mock

from harness.lean import surface
from harness.phases import candidate, review as review_phase

DEVIATION = "**As built, more narrowly or broadly than these words:**"
NEUTRAL = "**Review notes (not confirmed differences):**"
SMOKE30 = Path("/local-scratch2/sma407/smoke30-run/pipeline/traffic-spec-agent/results/smoke30-1110-0136/accepted_concepts.jsonl")

DISMISSED = ("dismissed: divergence 1 (holds_wrongly) at t=0 ms: the road user points along [5,12] — contract: fails, "
             "body: holds — the factor the atom's contract discloses puts the component just below the tolerance")
REFUTED = "refuted by execution: divergence 2 (fails_wrongly) at t=40 ms: the body gives the contract's verdict"
REPLAY = "an upheld challenge is met by this body; it stays an obligation: divergence 1 at t=0 ms"
ADVISORY = "A fully observed crossing with zero heading change was recognized at exit, agreeing with the contract."


def concept(**more) -> dict:
    return {"concept_id": "drv.test.c", "kind": "formula", "contract": "A road user is in motion at the observation.",
            "args": [{"name": "x", "sort": "track"}], "params": [], "reads": ["kin.speed"], "refs": [], **more}


def split(row: str) -> tuple[str, str]:
    """The catalogue's contract cell, cut into what its deviation heading and its neutral heading carry."""
    cell = row.split(" | ")[2]
    dev = cell.split(DEVIATION, 1)[1].split(NEUTRAL, 1)[0] if DEVIATION in cell else ""
    neutral = cell.split(NEUTRAL, 1)[1] if NEUTRAL in cell else ""
    return dev, neutral


def row_of(table: str, cid: str) -> str:
    return next(l for l in table.splitlines() if l.startswith(f"| `{cid}` |"))


class CatalogueHeadings(unittest.TestCase):
    def test_upheld_divergence_is_a_deviation(self):
        note = {"text": "divergence 1 — upheld: the body also holds at rest", "source": "adjudication", "standing": "upheld",
                "review": "r/iter-001"}
        dev, neutral = split(row_of(surface.concepts_table({"drv.test.c": concept(review_notes=[note])}), "drv.test.c"))
        self.assertIn("the body also holds at rest", dev)
        self.assertNotIn("the body also holds at rest", neutral)

    def test_advisory_and_dismissed_are_review_notes(self):
        notes = surface.review_notes([DISMISSED, ADVISORY, REFUTED, REPLAY], "r/iter-001")
        table = surface.concepts_table({"drv.test.c": concept(review_notes=notes)})
        dev, neutral = split(row_of(table, "drv.test.c"))
        self.assertNotIn(DEVIATION, table)
        self.assertEqual(dev, "")
        for text in (DISMISSED, ADVISORY, REFUTED, REPLAY):
            self.assertIn(text, neutral)

    def test_old_format_record_still_renders_as_review_notes(self):
        table = surface.concepts_table({"drv.test.c": concept(approximations=[ADVISORY])})
        dev, neutral = split(row_of(table, "drv.test.c"))
        self.assertIn(ADVISORY, neutral)
        self.assertEqual(dev, "")

    def test_no_notes_no_heading(self):
        table = surface.concepts_table({"drv.test.c": concept()})
        self.assertNotIn(DEVIATION, table)
        self.assertNotIn(NEUTRAL, table)

    @unittest.skipUnless(SMOKE30.exists(), "smoke30's run records are not on this machine")
    def test_smoke30_catalogue_shows_no_agreement_as_a_deviation(self):
        accepted = {}
        with SMOKE30.open(encoding="utf-8") as f:                 # read only
            for line in f:
                rec = json.loads(line)
                accepted[rec["concept_id"]] = rec
        noted = [cid for cid, r in accepted.items() if r.get("approximations")]
        self.assertIn("drv.motion.straight_through_region", noted)
        table = surface.concepts_table(accepted)
        self.assertNotIn(DEVIATION, table)
        for cid in noted:                                       # every note still shown, under the neutral heading
            dev, neutral = split(row_of(table, cid))
            self.assertEqual(dev, "")
            for a in accepted[cid]["approximations"]:
                self.assertIn(" ".join(a.split()), neutral)


class Provenance(unittest.TestCase):
    def test_each_form_keeps_its_text_source_and_standing(self):
        notes = surface.review_notes([DISMISSED, REFUTED, REPLAY, ADVISORY, "reviewer off"], "run/iter-002")
        self.assertEqual([(n["source"], n["standing"]) for n in notes],
                         [("adjudication", "dismissed"), ("execution", "advisory"), ("replay", "advisory"), ("reviewer", "advisory")])
        self.assertEqual([n["text"] for n in notes], [DISMISSED, REFUTED, REPLAY, ADVISORY])
        self.assertTrue(all(n["review"] == "run/iter-002" for n in notes))

    def test_reviewer_text_never_claims_a_confirmed_difference(self):
        notes = surface.review_notes(["upheld: the body is narrower", "divergence 1 — upheld: x"], "r/iter-001")
        self.assertTrue(all(n["standing"] == "advisory" for n in notes))

    def test_candidate_review_records_notes_with_provenance(self):
        rec = concept()
        with tempfile.TemporaryDirectory() as d:
            view = NS(accepted_concepts={"drv.test.c": rec}, opts=NS(run_id="run"), iteration=3)
            txn = NS(view=view, area=Path(d), extras={}, id="c7")
            aff = NS(changed={"drv.test.c": "concept"}, removed=set(), closure=["drv.test.c"])
            outcome = review_phase.ReviewOutcome("accepted", advisories=[DISMISSED, ADVISORY])
            with mock.patch.object(review_phase, "review_concept", lambda *_a: outcome):
                results = candidate.concept_review(txn, aff)
        self.assertEqual([r.status for r in results], ["pass"])
        notes = txn.extras["drv.test.c"]["review_notes"]
        self.assertEqual([(n["text"], n["standing"]) for n in notes], [(DISMISSED, "dismissed"), (ADVISORY, "advisory")])
        self.assertEqual({n["review"] for n in notes}, {"run/iter-003/candidate-c7"})
        self.assertNotIn("approximations", txn.extras["drv.test.c"])


class Shorten(unittest.TestCase):
    def test_never_inside_a_word(self):
        text = DISMISSED * 3
        for limit in range(5, len(text) + 5, 7):
            short = surface.shorten(text, limit)
            if short == " ".join(text.split()):
                continue
            self.assertTrue(short.endswith(" …"), short)
            kept = short[:-2]
            self.assertLessEqual(len(kept), limit)
            self.assertTrue(" ".join(text.split()).startswith(kept))
            if " " not in " ".join(text.split())[:limit + 1]:                  # one word longer than the limit: cut at it
                self.assertEqual(len(kept), limit)
                continue
            following = " ".join(text.split())[len(kept):]
            self.assertTrue(following == "" or following[0] == " " or re.match(r"[ ,;:]", following), (limit, kept, following[:10]))

    def test_short_text_is_whole(self):
        self.assertEqual(surface.shorten("  a  b ", 10), "a b")

    def test_one_long_word_is_cut_at_the_limit(self):
        self.assertEqual(surface.shorten("abcdefghij klm", 4), "abcd …")


if __name__ == "__main__":
    unittest.main()
