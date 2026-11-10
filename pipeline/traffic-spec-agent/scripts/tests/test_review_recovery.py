"""Development regression tests for a concept review stopped at any point and resumed: the outcome,
its inputs and its rulings are saved before the rulings are recorded, so a resumed review on the same
inputs gives the same outcome, asks no adjudicator or reviewer again and records each ruling once; a
dependency report is adjudicated once. A saved outcome is read back strictly, and reused only on the
same inputs. Every session is stubbed."""
import json
import tempfile
import unittest
from dataclasses import asdict
from pathlib import Path

from harness.phases import review
from harness.store import jsonl
from scripts.tests.test_review_routing import FakeRun


class Crash(BaseException):
    """A stop of the process at the point injected."""


def inject_stop(real, point: str) -> None:
    """A stop of the process at `point` in a review's record keeping, `real` being the module's own
    `(_write_outcome, append_ruling, record_rows)`: before the final outcome is saved
    (`before_save`), between two recorded rulings (`between_appends`), or after every ruling is
    recorded (`after_appends`); any other point injects nothing."""
    real_write, real_append, real_record = real
    if point == "before_save":
        def write(out_dir, data):
            if "outcome" in data:
                raise Crash()
            real_write(out_dir, data)
        review._write_outcome = write
    elif point == "between_appends":
        count = [0]

        def append(run, row, supersedes=None, ruling_id=None):
            if ruling_id:
                count[0] += 1
                if count[0] == 2:
                    raise Crash()
            return real_append(run, row, supersedes, ruling_id)
        review.append_ruling = append
    elif point == "after_appends":
        def record(run, saved):
            real_record(run, saved)
            raise Crash()
        review.record_rows = record


if __name__ == "__main__":
    unittest.main()


class ConceptRecovery(unittest.TestCase):
    """A concept's review stopped at any point and resumed on the same inputs gives the same
    outcome, runs no recheck, adjudication or reviewer again and records each ruling once."""
    def setUp(self):
        from scripts.tests import test_concept_recheck as cr
        self.cr = cr
        self.saved = (review.execute_concept_divergences, review.validate_phase._session, review.concept_blocks, review.session.run_tools,
                      review._concept_context, review._write_outcome, review.append_ruling, review.record_rows)
        review.concept_blocks = lambda _run, rec, _extras: ({**{x: "" for x in review.PLACEHOLDERS_REVIEW_CONCEPT},
                                                             "contract": review.contract_block(rec), "rendered": "RENDERING_MARKER"},
                                                            "RENDERING_MARKER", review._ws(rec.get("contract")))
        review._concept_context = lambda *_a: "the body and its gate's context"
        self.tmps = []

    def tearDown(self):
        (review.execute_concept_divergences, review.validate_phase._session, review.concept_blocks, review.session.run_tools,
         review._concept_context, review._write_outcome, review.append_ruling, review.record_rows) = self.saved
        for t in self.tmps:
            t.cleanup()

    def start(self, case: str):
        """A run seeded with two challenges decided under an earlier contract; `case` names what the
        review of the current contract does with them."""
        cr = self.cr
        tmp = tempfile.TemporaryDirectory()
        self.tmps.append(tmp)
        run = FakeRun(Path(tmp.name))
        body, sessions = cr.Body(), cr.Sessions()
        asked = []
        answers = {}

        def session(run_, out_dir, label, prompt, check=None, **kw):          # a judgment kept by its prompt, as `validate._session` keeps it
            if (label, prompt) not in answers:
                asked.append(label)
                answers[(label, prompt)] = sessions(run_, out_dir, label, prompt, check, **kw)
            return answers[(label, prompt)]
        review.execute_concept_divergences, review.validate_phase._session = body, session
        if case == "satisfied":                        # the body gives the current contract's answer: two satisfied rows
            body.tag, sessions.answer = "violated", {"verdict": "fails", "reason": "r", "quote": cr.WORDS2}
        else:                                          # the body departs from it: two adjudicated rows
            body.tag, sessions.ruling = "violated", case
        for t in (0, 1):
            review.append_ruling(run, cr.challenge(cr.V1, trace={"scenes": [{"t": 0, "users": [{"track": 1, "kin": {"speed": t}}]}]}))
        reviewed = []

        def run_tools(*a, **kw):
            reviewed.append(1)
            return cr.scripted_reviewer([cr.submit({"verdict": "accept", "divergences": [], "not_general": [], "advisories": []})])(*a, **kw)
        review.session.run_tools = run_tools
        go = lambda: review.review_concept(run, cr.formula(cr.V2), {"reads": [], "body_json": {}}, run.dir / "review")
        rows = lambda: [json.loads(x) for x in (run.dir / "rulings.jsonl").read_text().splitlines()]
        return go, rows, asked, reviewed, run

    def test_a_stop_at_any_point_resumes_to_the_same_outcome(self):
        for case, status in (("upheld", "returned"), ("dismissed", "accepted"), ("satisfied", "accepted")):
            go, rows, _asked, _reviewed, _run = self.start(case)
            expected = asdict(go())
            self.assertEqual(expected["status"], status)
            reference = rows()
            self.assertEqual(len(reference), 4, case)
            for point in ("before_save", "between_appends", "after_appends", "before_loop_commit"):
                with self.subTest(case=case, point=point):
                    go, rows, asked, reviewed, _run = self.start(case)
                    inject_stop(self.saved[5:], point)
                    if point == "before_loop_commit":
                        go()
                    else:
                        with self.assertRaises(Crash):
                            go()
                    review._write_outcome, review.append_ruling, review.record_rows = self.saved[5:]
                    asked.clear(); reviewed.clear()
                    self.assertEqual(asdict(go()), expected)
                    self.assertEqual(asked, [])                # every judgment kept: none is asked again
                    # a concept's reviewer keeps no answer: stopped before its outcome was saved, it is asked again
                    self.assertEqual(reviewed, [1] if point == "before_save" and status == "accepted" else [])
                    self.assertEqual(rows(), reference)

    def test_a_reported_defect_is_adjudicated_once(self):
        cr = self.cr
        for point in ("before_save", "before_loop_commit"):
            with self.subTest(point=point):
                _go, rows, asked, _reviewed, run = self.start("upheld")
                acc = {**cr.formula(cr.V1).raw, "body_json": {}, "reads": []}
                run.all_concepts = lambda: {cr.CID: acc}
                task = run.dir / "task"
                task.mkdir()
                (task / "dependency_defect.json").write_text("{}")
                d = {k: v for k, v in cr.challenge(cr.V1, trace={"scenes": [{"t": 0, "users": [{"track": 1}]}]}).items()
                     if k in review.CONCEPT_CASE_FIELDS}
                saved_form = review.report_form
                review.report_form = lambda *_a: ({**d, "concept_id": cr.CID}, [])
                try:
                    before = rows()
                    if point == "before_save":
                        inject_stop(self.saved[5:], point)
                        with self.assertRaises(Crash):
                            review.dependency_report(run, task, {cr.CID})
                        review._write_outcome = self.saved[5]
                        self.assertEqual(rows(), before)
                    first = review.dependency_report(run, task, {cr.CID})
                    asked.clear()
                    again = review.dependency_report(run, task, {cr.CID})      # the loop stopped before committing what it decided
                finally:
                    review.report_form = saved_form
                self.assertEqual((first.status, asdict(again), asked), ("upheld", asdict(first), []))
                self.assertEqual(len(rows()), len(before) + 1)


class SavedOutcomeFormat(ConceptRecovery):
    """A concept review's saved outcome is read back strictly: the four fields an outcome of run
    version 2 carried (`keys`, `questions`, `satisfied`, `param_notes`) are ignored, any other field
    is a format error. Reading it is not reusing it: a saved outcome is reused only when its inputs
    digest is the review's own."""

    def saved_with(self, case: str, **outcome):
        go, rows, asked, reviewed, run = self.start(case)
        expected = asdict(go())
        f = run.dir / "review" / "review_outcome.json"
        saved = json.loads(f.read_text())
        saved["outcome"].update(outcome)
        return go, asked, reviewed, f, saved, expected

    OLD = {"keys": ["case:c1"], "questions": [], "satisfied": [], "param_notes": [["p.x", "a note"]]}

    def test_the_old_fields_are_read_and_ignored(self):
        go, asked, reviewed, f, saved, expected = self.saved_with("satisfied", **self.OLD)
        f.write_text(json.dumps(saved))
        asked.clear(); reviewed.clear()
        self.assertEqual(asdict(go()), expected)
        self.assertEqual((asked, reviewed), ([], []))                    # the same inputs: reused, nothing asked

    def test_an_old_outcome_on_other_inputs_is_not_reused(self):
        go, asked, reviewed, f, saved, expected = self.saved_with("satisfied", **self.OLD)
        saved["inputs"] = "the inputs of another review"
        f.write_text(json.dumps(saved))
        reviewed.clear()
        self.assertEqual(go().status, expected["status"])
        self.assertEqual(reviewed, [1])                                   # reviewed again: readable is not reusable
        self.assertNotIn("keys", json.loads(f.read_text())["outcome"])

    def test_any_other_field_is_a_format_error(self):
        for extra in ({"verdict": "accept"}, {"status": None, "obligations": []}):
            with self.subTest(extra=extra):
                go, _asked, _reviewed, f, saved, _expected = self.saved_with("satisfied", **extra)
                if extra.get("status", "") is None:
                    del saved["outcome"]["status"]
                f.write_text(json.dumps(saved))
                with self.assertRaises(jsonl.DataIntegrityError):
                    go()
