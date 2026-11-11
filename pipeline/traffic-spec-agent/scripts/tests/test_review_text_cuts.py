"""The concept review keeps a ruling's texts whole and cuts only what it shows.
- A ruling (an adjudicated divergence, a rechecked case) stores its item and reason whole, and they
  read back whole from the run's rulings.
- A summary of a long text (the precedents, the carried challenges, an item's line in a note) ends at
  a word boundary with an ellipsis.
- A ruling's id is a digest of its whole content: two rulings alike in their first 600 characters
  have their own ids. A recorded ruling keeps its id: a ruling of smoke30
  (`drv.lane.facing_against_direction`, iteration 1) recorded again from its saved review appends
  nothing; decided again, it gets the same case id and a new ruling that supersedes the old once, as
  a review deferred and decided again does. An id recorded with other content is refused.
- The rendered adjudication and review prompts stay bounded however long the stored texts are, and
  show a ruling stored at its old length exactly as before."""
import copy
import json
import re
import tempfile
import unittest
from pathlib import Path

from harness.model.blueprint import ConceptRecord
from harness.lean import surface
from harness.phases import review
from harness.phases import validate as validate_phase
from scripts.tests.test_concept_recheck import Base, challenge, formula, V1
from scripts.tests.test_review_routing import FakeRun

# smoke30-1110-0136, iter-001/code/concept__drv_lane_facing_against_direction/review: the saved review's
# inputs and row (review_outcome.json), the adjudicator's answer (adjudicate_answer.json) and the
# accepted contract (accepted_concepts.jsonl).
S30_CONCEPT = "drv.lane.facing_against_direction"
S30_CONTRACT = ("A road user points against the designated direction of travel of a carrier at the observation: the cosine of the angle "
                "between its heading (kin.heading) and the carrier's designated direction (st.lane_direction), read as the dot product of "
                "the two normalised vectors, is below minus `cos_tol`, the cosine of the largest angle off exactly opposed that still counts "
                "as against. Not denoted: occupancy of the carrier, which the caller states; the direction of motion, since a vehicle "
                "pointing against the direction points against it whether it moves forwards or backs; travel across the carrier, with "
                "headings near perpendicular to it; a carrier with no designated direction, for which the concept is unknown.")
S30_INPUTS = "b2570e9f40dfe0798e439285c897493e2ec700aef4a4b6ee449f7cfc2ea9648f"
S30_BODY_DIGEST = "68be7808f8dedb549fe0b3dc67de8875bec5cc7d1229a8ac300851458720491d"
S30_RULING_ID = "a72fcb0f87274fe320c9"
S30_CASE_ID = "7902860edfab10ef2dc196d2d063cbaf5cfe62da22f6d9e82cf441f047a85cad"
S30_DIV = {"kind": "holds_wrongly",
           "situation": "The heading is [-7,-1] and the carrier direction is [1,1], so their exact cosine is -8/sqrt(50·2) = -0.8. With "
                        "cos_tol = 0.8 the strict comparison must fail, but the formula's truncated vector lengths inflate the negative dot "
                        "product past the threshold.",
           "contract_words": "the cosine of the angle between its heading (kin.heading) and the carrier's designated direction "
                             "(st.lane_direction), read as the dot product of the two normalised vectors, is below minus `cos_tol`",
           "contract_verdict": "fails", "contract_value": None, "instance": {"literals": {}, "nats": {}, "params": {"cos_tol": [0.8, "ratio"]}},
           "grounding": {"x": 1}, "regions": {"c": 1},
           "trace": {"scenes": [{"t": 0, "users": [{"track": 1, "kin": {"heading": [-7, -1]}}],
                                 "structures": [{"id": 1, "kind": "lane", "lane": {"direction": [1, 1]}}]}]}, "at": 0}
S30_REASON = ("The contract's normalised vectors are its two atoms, and each atom's contract defines its normalised reading as the unit vector "
              "times a factor of at least 1 and below 1 + 2·10⁻⁶. At an exact cosine of -0.8 that factor puts the dot product just below "
              "-0.8, so the body's verdict follows from a reasonable reading of the contract's words; it also turns only on cos_tol sitting "
              "exactly at the boundary, a value the caller sets.")
S30_QUOTE = ("a formula reads it normalised: divided by its larger absolute component, then by its length taken to a micrometre, so the "
             "vector read is the unit vector times a factor of at least 1 and below 1 + 2·10⁻⁶")
S30_ITEM = ("divergence 1 (holds_wrongly) at t=0 ms: The heading is [-7,-1] and the carrier direction is [1,1], so their exact cosine is "
            "-8/sqrt(50·2) = -0.8. With cos_tol = 0.8 the strict comparison must fail, bu — contract: fails, body: holds; contract: \"the "
            "cosine of the angle between its heading (kin.heading) and the carrier's designated direction (st.lane_direction), re\"")
S30_STORED_REASON = S30_REASON + " — \"" + S30_QUOTE[:160] + "\""

LONG = " ".join(f"word{n:03d}" for n in range(400))          # 3199 characters, no word longer than seven


def confirmed_item(d: dict, body: str = "holds", verdict: str = "compliant") -> dict:
    """A confirmed divergence as the run of a reviewer's divergence gives it to the adjudicator."""
    lines = {f: review.divergence_lines(1, d, False, body, None, "", cut)[1] for f, cut in review.LINE_FORMS.items()}
    return {**lines, "div": d, "rule": body, "key": d["kind"], "verdict": verdict, "value": None, "facts": "F"}


def concept(cid: str = S30_CONCEPT, contract: str = S30_CONTRACT) -> ConceptRecord:
    return ConceptRecord({"concept_id": cid, "kind": "formula", "contract": contract, "args": [{"name": "x", "sort": "track"}],
                          "params": [{"name": "cos_tol", "unit": "ratio", "meaning": "m"}], "elements": []})


BLOCKS = {"contract": "C", "record": "R", "rendered": "N", "contracts": "K"}


class Judged(unittest.TestCase):
    """The adjudicator's session stubbed with `answer`; its prompts kept in `prompts`."""
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.run = FakeRun(Path(self.tmp.name))
        self.saved = validate_phase._session
        self.answer, self.prompts = None, []
        validate_phase._session = lambda run, out_dir, label, prompt, **kw: (self.prompts.append(prompt), (copy.deepcopy(self.answer), []))[1]

    def tearDown(self):
        validate_phase._session = self.saved
        self.tmp.cleanup()

    def adjudicate(self, rec, items, rulings=None, body_digest=S30_BODY_DIGEST):
        return review.adjudicate_concept(self.run, rec, BLOCKS, items, self.run.dir / "adj", body_digest, "adjudicate", rulings)


S30_ROW = {"key": f"concept:{S30_CONCEPT}", "subject": S30_CONCEPT, "iteration": 1, "item": S30_ITEM, "ruling": "dismissed",
           "reason": S30_STORED_REASON, "schema": review.CONCEPT_CASE_SCHEMA, "case_id": S30_CASE_ID, **S30_DIV,
           "verdict": "compliant", "value": None, "contract_digest": review.contract_digest(concept()), "body_digest": S30_BODY_DIGEST,
           "obligation": None, "ruling_id": S30_RULING_ID, "supersedes": None}
#: Two adjudicator reasons alike in their first 600 characters, different after.
REASON_A, REASON_B = LONG[:700] + " so it is dismissed.", LONG[:700] + " so it is upheld."


class Adjudicated(Judged):
    def ruled(self, reason: str, rulings=None, ruling: str = "dismissed"):
        self.answer = {"rulings": [{"item": 1, "ruling": ruling, "reason": reason, "quote": S30_QUOTE}]}
        return self.adjudicate(concept(), [confirmed_item(S30_DIV)], rulings)

    def test_a_long_ruling_reads_back_whole(self):
        d = {**S30_DIV, "situation": LONG, "contract_words": S30_DIV["contract_words"]}
        self.answer = {"rulings": [{"item": 1, "ruling": "upheld", "reason": LONG, "quote": S30_QUOTE}]}
        out = self.adjudicate(concept(), [confirmed_item(d, "holds")])
        [row] = review._all_rows(self.run)
        self.assertIn(LONG, row["item"])
        self.assertTrue(row["item"].endswith(f'contract: "{S30_DIV["contract_words"]}"'))
        self.assertEqual(row["reason"], LONG + " — \"" + S30_QUOTE + "\"")
        self.assertEqual(out[0][2], row["reason"])

    def test_rulings_alike_in_600_characters_have_their_own_ids(self):
        """One review decided twice (the same inputs and rulings), its reason different only past
        the 600th character: two ids, each row whole."""
        a, b = review.ReviewRulings("I", 0, []), review.ReviewRulings("I", 0, [])
        self.ruled(REASON_A, a)
        self.ruled(REASON_B, b)
        [x], [y] = a.saved(), b.saved()
        self.assertNotEqual(x["id"], y["id"])
        self.assertEqual((x["row"]["reason"], y["row"]["reason"]), (f'{REASON_A} — "{S30_QUOTE}"', f'{REASON_B} — "{S30_QUOTE}"'))

    def test_the_same_decision_has_one_id(self):
        a, b = review.ReviewRulings("I", 0, []), review.ReviewRulings("I", 0, [])
        self.ruled(REASON_A, a)
        self.ruled(REASON_A, b)
        self.assertEqual(a.saved()[0]["id"], b.saved()[0]["id"])

    def test_a_smoke30_ruling_keeps_its_recorded_id(self):
        """Its saved review recorded again appends nothing; decided again, the new ruling supersedes it once."""
        saved = {"inputs": S30_INPUTS, "rulings_at": 0, "final": True, "rows": [{"id": S30_RULING_ID, "row": S30_ROW, "supersedes": None}]}
        review.record_rows(self.run, saved)
        review.record_rows(self.run, saved)
        [row] = review._all_rows(self.run)
        self.assertEqual((row["ruling_id"], row), (S30_RULING_ID, S30_ROW))
        before = (self.run.dir / "rulings.jsonl").read_bytes()
        again = review.ReviewRulings(S30_INPUTS, 0, [])
        self.ruled(S30_REASON, again)
        review.record_rows(self.run, {"rows": again.saved()})
        after = (self.run.dir / "rulings.jsonl").read_bytes()
        self.assertTrue(after.startswith(before))
        old, new = review._all_rows(self.run)
        self.assertEqual(old, S30_ROW)
        self.assertNotEqual(new["ruling_id"], S30_RULING_ID)
        self.assertEqual((new["case_id"], new["supersedes"], new["reason"]), (S30_CASE_ID, S30_RULING_ID, f'{S30_REASON} — "{S30_QUOTE}"'))
        self.assertEqual([r["ruling_id"] for r in review.effective_rows(review._all_rows(self.run))], [new["ruling_id"]])

    def test_deferred_then_decided_again_supersedes_once(self):
        prior = review.append_ruling(self.run, {**{k: v for k, v in S30_ROW.items() if k not in ("ruling_id", "supersedes")}, "ruling": "upheld"})
        out = self.run.dir / "review"
        out.mkdir()
        rulings, decided = review.resume_review(self.run, out, lambda rows: "I")
        self.ruled(REASON_A, rulings)
        review.finish_review(self.run, out, rulings, {}, review.ReviewOutcome("deferred", reasons=["d"]), False)
        rulings, decided = review.resume_review(self.run, out, lambda rows: "I")
        self.assertIsNone(decided)
        self.ruled(REASON_B, rulings)
        review.finish_review(self.run, out, rulings, {}, review.ReviewOutcome("returned", reasons=["u"]), True)
        rows = review._all_rows(self.run)
        p, first, second = rows
        self.assertEqual(p, prior)
        self.assertEqual((first["supersedes"], second["supersedes"]), (prior["ruling_id"], first["ruling_id"]))
        self.assertEqual((first["reason"], second["reason"]), (f'{REASON_A} — "{S30_QUOTE}"', f'{REASON_B} — "{S30_QUOTE}"'))
        self.assertEqual(review.effective_rows(rows), [second])
        review.record_rows(self.run, review.saved_review(out))   # recorded again: nothing appended
        self.assertEqual(review._all_rows(self.run), rows)


class Recorded(unittest.TestCase):
    def test_an_id_recorded_with_other_content_is_refused(self):
        with tempfile.TemporaryDirectory() as d:
            run = FakeRun(Path(d))
            review.append_ruling(run, S30_ROW, ruling_id=S30_RULING_ID)
            before = (run.dir / "rulings.jsonl").read_bytes()
            with self.assertRaises(review.RulingsError):
                review.append_ruling(run, {**S30_ROW, "reason": S30_REASON + " — a different conclusion"}, ruling_id=S30_RULING_ID)
            self.assertEqual((run.dir / "rulings.jsonl").read_bytes(), before)
            self.assertEqual(review.append_ruling(run, {**S30_ROW, "supersedes": "x"}, ruling_id=S30_RULING_ID), S30_ROW)


class Rechecked(Base):
    """A rechecked case stores the recheck's reason and quote whole."""
    def test_a_long_recheck_reason_is_kept_whole(self):
        contract = "The first road user moves at the observation: " + LONG
        quote = " ".join(LONG.split()[:60])                          # 479 characters, verbatim from the contract
        self.recheck.answer = {"verdict": "holds", "reason": LONG, "quote": quote}
        [old] = self.seed(challenge(V1))
        before = self.bytes()
        self.replay(formula(contract))
        [row] = self.appended(before)
        self.assertEqual(row["case_id"], old["case_id"])
        self.assertIn(LONG, row["reason"])
        self.assertIn(f"\"{quote}\"", row["reason"])
        self.assertEqual(row["recheck"]["quote"], quote)


def cut_cleanly(test: unittest.TestCase, shown: str, whole: str, limit: int):
    test.assertTrue(shown.endswith(" …"), shown[-20:])
    kept = shown[:-2]
    test.assertLessEqual(len(kept), limit)
    test.assertTrue(whole.startswith(kept))
    test.assertEqual(whole[len(kept)], " ")                        # the cut falls between two words


class Shown(unittest.TestCase):
    def test_shorten(self):
        self.assertEqual(surface.shorten("short text", 400), "short text")
        cut_cleanly(self, surface.shorten(LONG, 400), LONG, 400)
        self.assertEqual(surface.shorten("x" * 50, 20), "x" * 20 + " …")

    def test_the_precedents_cut_at_a_word(self):
        row = {"iteration": 1, "subject": "drv.x", "item": LONG, "ruling": "upheld", "reason": LONG}
        line = review.precedents_block([row]).splitlines()[2]
        m = re.match(r"- iteration 1, `drv\.x`: (.*) — \*\*upheld\*\*: (.*)$", line)
        cut_cleanly(self, m.group(1), LONG, review.PRECEDENT_ITEM)
        cut_cleanly(self, m.group(2), LONG, review.PRECEDENT_REASON)

    def test_a_carried_challenge_cuts_at_a_word(self):
        block = review.carry_over_block([{"case_id": "c1", "row": {"item": LONG, "situation": "s"}, "reason": "formals", "why": "w"}])
        [shown] = [l for l in block.splitlines() if l.startswith("word000")]
        cut_cleanly(self, shown, LONG, 400)

    def test_an_items_line_in_a_note_cuts_at_a_word(self):
        item = confirmed_item({**S30_DIV, "situation": LONG})
        shown = review._shown(item)
        sit = re.match(r"divergence 1 \(holds_wrongly\) at t=0 ms: (.*?) — contract: fails, body: holds;", shown).group(1)
        cut_cleanly(self, sit, LONG, 160)
        self.assertIn(LONG, item["line"])

    def test_a_ruling_at_its_old_length_is_shown_as_before(self):
        row = {"iteration": 1, "subject": S30_CONCEPT, "item": S30_ITEM, "ruling": "dismissed", "reason": S30_STORED_REASON}
        self.assertEqual(review.precedents_block([row]),
                         f"### Earlier rulings (most recent first)\n\n- iteration 1, `{S30_CONCEPT}`: {S30_ITEM} — **dismissed**: {S30_STORED_REASON}\n")


class PromptLength(Judged):
    def test_the_adjudication_prompt_is_bounded(self):
        rows = [{"key": f"concept:{S30_CONCEPT}", "subject": S30_CONCEPT, "iteration": 1, "item": LONG, "ruling": "dismissed",
                 "reason": LONG, "ruling_id": f"r{n}", "supersedes": None} for n in range(40)]
        with (self.run.dir / "rulings.jsonl").open("w") as f:
            f.writelines(json.dumps(r) + "\n" for r in rows)
        self.answer = {"rulings": [{"item": 1, "ruling": "dismissed", "reason": "r", "quote": S30_QUOTE}]}
        self.adjudicate(concept(), [confirmed_item(S30_DIV)])
        shown = [l for l in self.prompts[0].splitlines() if l.startswith("- iteration 1, ")]
        self.assertEqual(len(shown), 30)
        self.assertTrue(all(len(l) <= review.PRECEDENT_ITEM + review.PRECEDENT_REASON + 100 for l in shown))
        self.assertLess(len(self.prompts[0]), 30 * (review.PRECEDENT_ITEM + review.PRECEDENT_REASON + 100) + 20000)

    def test_the_carry_over_block_is_bounded(self):
        rows = [{"case_id": f"c{n}", "row": {"item": LONG, "situation": LONG, "trace": {"scenes": [{"t": 0, "note": LONG * 3}]}},
                 "reason": "formals", "why": "w"} for n in range(3)]
        block = review.carry_over_block(rows)
        head = len(review.carry_over_block([]) or "") + 2000
        self.assertLessEqual(len(block), head + 3 * (400 + 6000 + 300))


if __name__ == "__main__":
    unittest.main()
