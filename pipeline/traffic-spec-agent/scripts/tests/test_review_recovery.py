"""Development regression tests for a review stopped at any point and resumed: the outcome, its
inputs and its rulings are saved before the rulings are recorded, so a resumed review on the same
inputs gives the same outcome, asks no judge or reviewer again and records each ruling once; a
paused or deferred review keeps what it decided and asks only what it had not; changed inputs are
judged again. Every session is stubbed."""
import copy
import json
import tempfile
import unittest
from dataclasses import asdict
from pathlib import Path
from types import SimpleNamespace

from harness.phases import review
from harness.store.budget import BudgetPaused
from scripts.tests.test_review_routing import A_VIOLATED, B, FakeRun, LAW, ONTO, cert, ctx, div, node


def _trace(same_direction: bool) -> dict:
    return {"scenes": [{"t": 0, "users": [{"track": 1}, {"track": 2}], "relations": [{"a": 1, "b": 2, "same_direction": same_direction}]}]}


ONE, OTHER = _trace(True), _trace(False)
PRIOR_TRACE = {"scenes": [{"t": 0, "users": [{"track": 1, "kin": {"heading": [1, 0]}}]}]}
PRIOR = {"schema": review.CASE_SCHEMA, "key": "law:L-1", "subject": "L_1_o1", "iteration": 0, "case_id": "c1", "lineage": "c1",
         "ruling": "upheld", "route": "upheld", "obligation": "open", "outcome": "case:c1", "item": "an earlier case", "reason": "r",
         "trace": PRIOR_TRACE, "case": "tt", "entities": {}, "grounding": {"user1": 1}, "at": 0, "stage_a": {"verdict": "violated"}}
PARAM = [{"name": "p.gap", "unit": "m", "value": 1, "proposed": True}]


class Crash(BaseException):
    """A stop of the process at the point injected."""


class Scenario:
    """One review: its divergences, its judges' answers, its seeded rulings and its reading."""
    def __init__(self, divs, b=None, params=None, seed=(), evidence=False):
        self.divs, self.b, self.params, self.seed, self.evidence = divs, b or {}, params or [], list(seed), evidence


SCENARIOS = {
    "all_dismissed": lambda: Scenario([div(trace=ONE), div(trace=OTHER)]),
    "mixed": lambda: Scenario([div(trace=ONE), div(trace=OTHER)], b={"divergence_2_stage_b": "upheld"}),
    "parameter_question": lambda: Scenario([div(trace=ONE), div(trace=OTHER)], b={"divergence_1_stage_b": "parameter_question"},
                                           params=PARAM),
    "evidence_extension": lambda: Scenario([div(extends="c1", trace=copy.deepcopy(PRIOR_TRACE))], seed=[PRIOR], evidence=True),
}
EXPECTED = {"all_dismissed": "accepted", "mixed": "returned", "parameter_question": "proceed_with_question", "evidence_extension": "accepted"}


class Harness:
    """A run in a temporary directory with the review's sessions stubbed: `asked` the judges'
    labels, `reviewed` the reviewer passes, `pause` the judge labels that pause the budget once,
    `invalid` those that answer outside the schema."""
    def __init__(self, sc: Scenario):
        self.tmp = tempfile.TemporaryDirectory()
        self.run = FakeRun(Path(self.tmp.name))
        self.run.opts.max_divergences, self.run.opts.review_passes = 3, 2
        self.sc, self.asked, self.reviewed, self.pause, self.invalid = sc, [], [], set(), set()
        for row in sc.seed:
            review.append_ruling(self.run, row)

    def reading(self):
        return SimpleNamespace(data={"params": self.sc.params})

    def judge(self, prompt, cwd, out_dir, opts, *, label, **_kw):
        if label in self.pause:
            self.pause.discard(label)
            raise BudgetPaused("no budget left")
        self.asked.append(label)
        if label.split("_again")[0] in self.invalid:
            return {"result": {"result": json.dumps({"outcome": "not an outcome"})}}
        ans = A_VIOLATED if "stage_a" in label else B(self.sc.b.get(label.split("_again")[0], "dismissed_permitted_reading"))
        return {"result": {"result": json.dumps(ans)}}

    def run_tools(self, prompt, out_dir, opts, tools, label, **_kw):
        self.reviewed.append(label)
        tools.reset()
        divs = self.sc.divs if label == "review_behaviour_p1" else []
        tools.call("submit_review", {"answer": {"verdict": "return" if divs else "accept", "divergences": divs, "advisories": [],
                                                "gap_candidates": []}})
        return {"code": 0, "result": {"submitted": tools.done}}

    def review(self):
        return review.review_behaviour(self.run, node(), LAW, ONTO, self.reading(), {}, [], Path(self.tmp.name) / "review")

    def rows(self) -> list[dict]:
        f = self.run.dir / "rulings.jsonl"
        return [json.loads(x) for x in f.read_text().splitlines()] if f.exists() else []


class Recovery(unittest.TestCase):
    def setUp(self):
        self.saved = (review.build_context, review.replay_obligations, review.certify, review._pass_context, review.session.run_tools,
                      review.session.run, review._write_outcome, review.append_ruling, review.record_rows)

        def context(run, n, law, onto, reading, rule_json, narrowings, rows=None):
            return review.Context(**{**ctx(params=reading.data["params"]).__dict__,
                                     "precedents": review.precedent_rows(run, "law:L-1", None, rows)})
        review.build_context = context
        review.certify = lambda _run, _n, divs, _reading, _out, **_k: {k: cert(rule="compliant") for k in divs}
        review._pass_context = lambda *_a, **_kw: "the rule and its gate's context"
        self.harnesses = []

    def tearDown(self):
        (review.build_context, review.replay_obligations, review.certify, review._pass_context, review.session.run_tools,
         review.session.run, review._write_outcome, review.append_ruling, review.record_rows) = self.saved
        for h in self.harnesses:
            h.tmp.cleanup()

    def harness(self, name: str) -> Harness:
        h = Harness(SCENARIOS[name]())
        self.harnesses.append(h)
        review.session.run, review.session.run_tools = h.judge, h.run_tools
        if h.sc.evidence:
            review.replay_obligations = lambda *_a, **_kw: review.Replayed(
                evidence=[{"case_id": "c1", "case_rendered": "x", "trace": PRIOR_TRACE, "remedy": "earlier scenes"}])
        else:
            review.replay_obligations = self.saved[1]
        return h

    def reference(self, name: str):
        """The review run once without a stop: its outcome and its rulings."""
        h = self.harness(name)
        out = h.review()
        self.assertEqual(out.status, EXPECTED[name])
        return asdict(out), h.rows()

    def inject(self, point: str):
        """A stop at `point`: before the final outcome is saved, between two recorded rulings, or
        after every ruling is recorded."""
        real_write, real_append, real_record = self.saved[6], self.saved[7], self.saved[8]
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

    def heal(self):
        review._write_outcome, review.append_ruling, review.record_rows = self.saved[6], self.saved[7], self.saved[8]

    def test_a_stop_at_any_point_resumes_to_the_same_outcome(self):
        for name in SCENARIOS:
            expected, rows = self.reference(name)
            self.assertGreaterEqual(len(rows) - len(SCENARIOS[name]().seed), 2, name)     # two rulings: a stop between them is possible
            for point in ("before_save", "between_appends", "after_appends", "before_loop_commit"):
                with self.subTest(scenario=name, point=point):
                    h = self.harness(name)
                    self.inject(point)
                    if point == "before_loop_commit":              # the review returned; the loop stopped before committing its state
                        h.review()
                    else:
                        with self.assertRaises(Crash):
                            h.review()
                    self.heal()
                    h.asked, h.reviewed = [], []
                    out = h.review()                               # resumed
                    self.assertEqual(asdict(out), expected)
                    self.assertEqual((h.asked, h.reviewed), ([], []))
                    self.assertEqual(h.rows(), rows)               # each ruling once, as the uninterrupted review recorded it
                    again = h.review()                              # resumed once more: nothing changes
                    self.assertEqual((asdict(again), h.rows(), h.asked), (expected, rows, []))

    def test_a_pause_keeps_what_was_decided_and_asks_only_the_rest(self):
        expected, rows = self.reference("mixed")
        h = self.harness("mixed")
        h.pause = {"divergence_2_stage_b"}
        with self.assertRaises(BudgetPaused):
            h.review()
        self.assertEqual(h.rows(), [])                             # nothing is recorded before the outcome
        self.assertEqual(h.asked, ["divergence_1_stage_a", "divergence_1_stage_b"])
        other = {"schema": review.CASE_SCHEMA, "key": "law:L-1", "subject": "L_1_o2", "case_id": "c9", "ruling": "dismissed_permitted_reading",
                 "item": "another review's ruling", "reason": "r", "iteration": 1}
        review.append_ruling(h.run, other)                        # another review records a precedent meanwhile
        h.asked, h.reviewed = [], []
        out = h.review()
        self.assertEqual(asdict(out), expected)
        self.assertEqual(h.asked, ["divergence_2_stage_b"])        # the judgments given are taken back: the rulings it began from are pinned
        self.assertEqual(h.rows()[1:], rows)

    def test_a_deferred_review_is_decided_again_and_keeps_its_rulings(self):
        expected, rows = self.reference("mixed")
        h = self.harness("mixed")
        h.invalid = {"divergence_2_stage_b"}
        first = h.review()
        self.assertEqual((first.status, first.defer_stage), ("deferred", "stage_b"))
        self.assertEqual([r["case_id"] for r in h.rows()], [rows[0]["case_id"]])     # what was decided stands
        h.invalid, h.asked, h.reviewed = set(), [], []
        out = h.review()                                          # the loop had not committed the deferral: the review goes on
        self.assertEqual(asdict(out), expected)
        self.assertEqual((h.asked, h.reviewed), (["divergence_2_stage_b"], []))
        self.assertEqual(h.rows(), rows)

    def test_changed_inputs_are_judged_again(self):
        _expected, rows = self.reference("all_dismissed")
        h = self.harness("all_dismissed")
        h.review()
        h.asked, h.reviewed = [], []
        h.sc.params = PARAM                                       # the reading changed: another stage B question
        h.sc.b = {"divergence_1_stage_b": "upheld"}
        out = h.review()
        self.assertEqual(out.status, "returned")
        self.assertIn("divergence_1_stage_b", h.asked)
        self.assertEqual(h.rows()[:len(rows)], rows)               # the first review's rulings are kept, never rewritten

    def test_another_reviews_record_is_completed_not_reused(self):
        h = self.harness("mixed")
        self.inject("between_appends")
        with self.assertRaises(Crash):
            h.review()
        self.heal()
        saved = json.loads((Path(h.tmp.name) / "review" / "review_outcome.json").read_text())
        h.sc.params = PARAM                                       # resumed on changed inputs
        h.asked = []
        h.review()
        ids = [r["ruling_id"] for r in h.rows()]
        self.assertTrue({x["id"] for x in saved["rows"]} <= set(ids))   # the decided rulings stand, each once
        self.assertEqual(len(ids), len(set(ids)))
        self.assertTrue(h.asked)                                  # and the new inputs are judged


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
                    Recovery.inject(SimpleNamespace(saved=(None,) * 6 + self.saved[5:]), point)
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
                        Recovery.inject(SimpleNamespace(saved=(None,) * 6 + self.saved[5:]), point)
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
