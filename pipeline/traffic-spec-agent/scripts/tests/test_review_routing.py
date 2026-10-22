"""Development regression tests for routing a certified divergence through the two judges, the effective-ruling reducer, the
bounded judge deferral of the ledgers, fail-closed concept adjudication and the run's status —
with every session stubbed."""
import json
import tempfile
import unittest
from pathlib import Path
from types import SimpleNamespace

from harness.model import corpus, ontology
from harness.model.blueprint import Node
from harness.phases import feedback, review
from harness.phases import validate as validate_phase
from harness.store import paths
from harness.store.state import Options
from harness.store.ledger import ConceptLedger, Ledger

ONTO = ontology.load(paths.REPO / "ontology" / "ATOMS_train.md")
LAW = corpus.Law("L-1", "A duty", "The driver of a vehicle shall stop before the line.", "")


class FakeRun:
    def __init__(self, d: Path):
        self.dir = d
        self.iteration = 1
        self.opts = Options(run_id="t", laws=d / "laws.jsonl", ontology=ONTO.path, reading=d / "reading.json",
                            model="m", reviewer_model="gpt-x", review_passes=1)


def node() -> Node:
    return Node({"node_id": "L_1_o1", "law_refs": ["L-1"], "binders": [{"name": "v"}],
                 "segmentation": [{"id": "s1", "role": "obligation", "text": "shall stop before the line"}]})


class ReviewerRequired(unittest.TestCase):
    def test_missing_reviewer_can_only_accept_in_a_dry_run(self):
        with tempfile.TemporaryDirectory() as d:
            run = FakeRun(Path(d))
            run.opts.reviewer_model = None
            reviews = (
                lambda: review.review_behaviour(run, node(), LAW, ONTO, None, None, [], Path(d)),
                lambda: review.review_concept(run, None, None, Path(d)),
            )
            for call in reviews:
                with self.subTest(review=call):
                    with self.assertRaisesRegex(RuntimeError, "reviewer_model is required"):
                        call()
                    run.opts.dry_run = True
                    self.assertEqual(call().status, "accepted")
                    run.opts.dry_run = False


def ctx(params=None, aggregates=None) -> review.Context:
    return review.Context(LAW, "- `s1` (obligation): shall stop before the line", [], {"node_id": "L_1_o1"}, "the rendering",
                          {}, params or [], aggregates or [], "p")


def div(**kw):
    d = {"kind": "rule_permits_unlawful", "situation": "s", "law_words": "shall stop", "lawful_verdict": "violated",
         "grounding": {"v": 1}, "trace": {"scenes": [{"t": 0}]}, "case": "tt", "entities": {}, "at": 0}
    d.update(kw)
    return d


def cert(rule="compliant", reasons=(), overrides=()):
    return {"schema": review.CERT_SCHEMA, "canonical_case": "tt", "case_atoms": [],
            "rule_result": {"verdict": rule, "unknown_reasons": list(reasons)}, "sensitivity_overrides": list(overrides)}


class Scripted:
    """A stub for `validate._session`: the answer scripted for the label's judge, checked by the
    caller's own check, so a scripted invalid answer stays invalid."""
    def __init__(self, answers: dict):
        self.answers, self.calls = answers, []

    def __call__(self, run, out_dir, label, prompt, check=None, model=None, effort=None, **_kw):
        self.calls.append(label)
        key = "a" if label.endswith("stage_a") else "b"
        ans = self.answers[key]
        return ans, (list(check(ans)) if check else [])


A_VIOLATED = {"verdict": "violated", "decisive": True, "law_words": "shall stop before the line", "reason": "r"}
B = lambda outcome: {"outcome": outcome, "law_words": "shall stop", "reason": "r"}


def scripted_reviewer(calls, seen=None):
    """A stub for `session.run_tools`: the reviewer's tool calls, in order, until a submission is
    accepted; `seen` collects each tool result."""
    def run_tools(prompt, out_dir, opts, tools, **_kw):
        tools.reset()
        for name, args in calls:
            if tools.done:
                break
            out = tools.call(name, args)
            if seen is not None:
                seen.append(json.loads(out))
        return {"code": 0, "result": {"submitted": tools.done}}
    return run_tools


def submit(answer):
    return ("submit_review", {"answer": answer})


class JudgeRouting(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.run = FakeRun(Path(self.tmp.name))
        self._session = validate_phase._session

    def tearDown(self):
        validate_phase._session = self._session
        self.tmp.cleanup()

    def judge(self, answers, c, context=None, previous=None):
        stub = Scripted(answers)
        validate_phase._session = stub
        j = review.judge_divergence(self.run, node(), context or ctx(), ONTO, div(), c, Path(self.tmp.name), "d1", previous=previous)
        return j, stub

    def test_aggregate_unresolved_is_an_advisory_before_either_judge(self):
        j, stub = self.judge({}, cert("unknown", ["aggregate_unresolved:D-1::vehicle"]))
        self.assertEqual(j.route, "aggregate_unresolved")
        self.assertEqual(stub.calls, [])

    def test_mixed_reasons_keep_the_ordinary_route(self):
        c = cert("unknown", ["aggregate_unresolved:D-1::vehicle", "undefined:x"])
        j, _ = self.judge({"a": A_VIOLATED, "b": B("upheld")}, c)
        self.assertEqual(j.route, "upheld")

    def test_stage_a_undetermined_is_an_advisory(self):
        j, stub = self.judge({"a": {**A_VIOLATED, "verdict": "undetermined"}}, cert())
        self.assertEqual(j.route, "stage_a_undetermined")
        self.assertEqual(len(stub.calls), 1)

    def test_indecisive_case_is_an_advisory(self):
        j, _ = self.judge({"a": {**A_VIOLATED, "decisive": False}}, cert())
        self.assertEqual(j.route, "stage_a_undetermined")

    def test_rule_agrees_compliant_and_not_applicable_alike(self):
        j, stub = self.judge({"a": {**A_VIOLATED, "verdict": "not_applicable"}}, cert("compliant"))
        self.assertEqual(j.route, "rule_agrees")
        self.assertEqual(len(stub.calls), 1)

    def test_mismatch_upheld(self):
        j, _ = self.judge({"a": A_VIOLATED, "b": B("upheld")}, cert("compliant"))
        self.assertEqual(j.route, "upheld")
        self.assertTrue(j.key.startswith("rule_permits_unlawful:"))

    def test_parameter_question_needs_a_proposed_parameter(self):
        j, _ = self.judge({"a": A_VIOLATED, "b": B("parameter_question")}, cert(),
                          context=ctx(params=[{"name": "p.x", "value": 1, "unit": "m", "proposed": "run/iter-001 n"}]))
        self.assertEqual(j.route, "parameter_question")
        self.assertIn("p.x", j.question)
        with self.assertRaises(review.Deferred) as e:
            self.judge({"a": A_VIOLATED, "b": B("parameter_question")}, cert())
        self.assertEqual(e.exception.stage, "stage_b")

    def test_verified_aggregate_only_when_sensitive(self):
        agg = [{"id": "D-1::vehicle", "included": ["ru.motor_vehicle"], "unresolved": []}]
        with self.assertRaises(review.Deferred):
            self.judge({"a": A_VIOLATED, "b": B("verified_aggregate")}, cert("compliant"), context=ctx(aggregates=agg))
        flip = [{"aggregate_id": "D-1::vehicle", "track": 1, "original": "false", "override": True, "rule_verdict": "violated"}]
        j, _ = self.judge({"a": A_VIOLATED, "b": B("verified_aggregate")}, cert("compliant", overrides=flip), context=ctx(aggregates=agg))
        self.assertEqual(j.route, "verified_aggregate")

    def test_stage_a_invalid_defers(self):
        with self.assertRaises(review.Deferred) as e:
            self.judge({"a": {"verdict": "guilty"}}, cert())
        self.assertEqual(e.exception.stage, "stage_a")

    def test_stage_b_invalid_is_never_upheld(self):
        with self.assertRaises(review.Deferred) as e:
            self.judge({"a": A_VIOLATED, "b": {"outcome": "upheld"}}, cert())
        self.assertEqual(e.exception.stage, "stage_b")

    def test_an_unchanged_digest_reuses_the_judgment(self):
        j, _ = self.judge({"a": A_VIOLATED, "b": B("upheld")}, cert())
        j2, stub = self.judge({"a": {"verdict": "guilty"}, "b": {"outcome": "x"}}, cert(), previous=j.row)
        self.assertEqual(j2.route, "upheld")
        self.assertNotIn("d1_stage_a", stub.calls)

    def test_the_final_answer_cannot_exceed_the_divergence_limit(self):
        self.assertIsNone(review.divergence_limit_defect([div()], 1))
        defect = review.divergence_limit_defect([div(), div()], 1)
        self.assertIn("2 divergences", defect)
        self.assertIn("at most 1", defect)

        answer = {"verdict": "return", "divergences": [div(), div()], "advisories": [], "gap_candidates": []}
        saved_build, saved_replay = review.build_context, review.replay_upheld
        saved_judge, saved_session = review.judge_divergence, review.session.run_tools
        self.run.opts.max_divergences = 1
        self.run.all_concepts = lambda: {}
        review.build_context = lambda *_a, **_kw: ctx()
        review.replay_upheld = lambda *_a, **_kw: ([], [], [])
        review.judge_divergence = lambda *_a, **_kw: self.fail("an over-limit answer reached a judge")
        review.session.run_tools = scripted_reviewer([submit(answer)] * 3)
        try:
            outcome = review.review_behaviour(self.run, node(), LAW, ONTO, SimpleNamespace(data={"params": []}), {}, [], Path(self.tmp.name))
        finally:
            review.build_context, review.replay_upheld = saved_build, saved_replay
            review.judge_divergence, review.session.run_tools = saved_judge, saved_session
        self.assertEqual((outcome.status, outcome.defer_stage), ("deferred", "reviewer"))
        self.assertIn("at most 1", outcome.reasons[0])


class Supersession(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.run = FakeRun(Path(self.tmp.name))

    def tearDown(self):
        self.tmp.cleanup()

    def row(self, ruling):
        return {"schema": review.CASE_SCHEMA, "key": "law:L-1", "subject": "L_1_o1", "case_id": "c1", "ruling": ruling}

    def test_upheld_then_dismissed_retires_the_upheld(self):
        review.append_ruling(self.run, self.row("upheld"))
        self.assertEqual(len(review.upheld_rows(self.run, {"L-1"})), 1)
        review.append_ruling(self.run, self.row("dismissed_permitted_reading"))
        self.assertEqual(review.upheld_rows(self.run, {"L-1"}), [])
        self.assertEqual(len(review._all_rows(self.run)), 2)                 # the audit trail keeps both

    def test_dismissed_then_upheld(self):
        review.append_ruling(self.run, self.row("dismissed_permitted_reading"))
        review.append_ruling(self.run, self.row("upheld"))
        self.assertEqual(len(review.upheld_rows(self.run, {"L-1"})), 1)

    def test_repeated_replay_chains(self):
        for _ in range(3):
            review.append_ruling(self.run, self.row("upheld"))
        self.assertEqual(len(review.effective_rows(review._all_rows(self.run))), 1)

    def test_malformed_supersession_fails_closed(self):
        f = self.run.dir / "rulings.jsonl"
        f.write_text(json.dumps({"ruling_id": "b", "supersedes": "missing", "ruling": "upheld"}) + "\n")
        with self.assertRaises(review.RulingsError):
            review.effective_rows(review._all_rows(self.run))
        f.write_text("".join(json.dumps(r) + "\n" for r in [{"ruling_id": "a"}, {"ruling_id": "b", "supersedes": "a"}, {"ruling_id": "c", "supersedes": "a"}]))
        with self.assertRaises(review.RulingsError):
            review.effective_rows(review._all_rows(self.run))
        f.write_text("".join(json.dumps(r) + "\n" for r in [{"ruling_id": "a", "supersedes": "b"}, {"ruling_id": "b", "supersedes": "a"}]))
        with self.assertRaises(review.RulingsError):
            review.effective_rows(review._all_rows(self.run))

    def test_a_row_without_schema_is_never_replayed(self):
        review.append_ruling(self.run, {"key": "law:L-1", "subject": "L_1_o1", "ruling": "upheld", "trace": {"scenes": []}})
        self.assertEqual(review.upheld_rows(self.run, {"L-1"}), [])


class Deferral(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.d = Path(self.tmp.name)

    def tearDown(self):
        self.tmp.cleanup()

    def test_law_deferral_is_bounded_and_keeps_the_plan(self):
        led = Ledger(self.d / "l.jsonl", ["L-1"], 2)
        led.mark_planned("L-1", ["L_1_o1"], 1)
        self.assertFalse(led.defer_judge("L-1", "stage_b", ["x"]))
        e = led.entries["L-1"]
        self.assertEqual((e.state, e.nodes, e.attempts), ("planned", ["L_1_o1"], 0))
        self.assertTrue(led.defer_judge("L-1", "stage_b", ["x"]))
        self.assertEqual(led.entries["L-1"].state, "failed")
        self.assertIn("judge_protocol_failure", led.entries["L-1"].reasons[0])

    def test_a_valid_judgment_clears_the_count(self):
        led = Ledger(self.d / "l.jsonl", ["L-1"], 2)
        led.mark_planned("L-1", ["L_1_o1"], 1)
        led.defer_judge("L-1", "stage_a", [])
        led.clear_judge("L-1")
        self.assertFalse(led.defer_judge("L-1", "stage_a", []))

    def test_concept_deferral(self):
        cl = ConceptLedger(self.d / "c.jsonl", 3)
        cl.planned("drv.motion.halt", ["L_1_o1"], 1)
        self.assertFalse(cl.defer_judge("drv.motion.halt", "concept_adjudication", ["x"]))
        e = cl.entries["drv.motion.halt"]
        self.assertEqual((e.state, e.attempts, e.used_by), ("planned", 0, ["L_1_o1"]))
        self.assertTrue(cl.defer_judge("drv.motion.halt", "concept_adjudication", ["x"]))
        self.assertEqual(cl.entries["drv.motion.halt"].state, "failed")

    def test_selection_correction_once(self):
        led = Ledger(self.d / "l.jsonl", ["L-1"], 2)
        self.assertFalse(led.selection_correction("L-1"))
        self.assertTrue(led.selection_correction("L-1"))


class ConceptAdjudication(unittest.TestCase):
    def test_an_unruled_item_defers_never_upholds(self):
        tmp = tempfile.TemporaryDirectory()
        run = FakeRun(Path(tmp.name))
        saved = validate_phase._session
        validate_phase._session = lambda *a, **k: ({"rulings": []}, ["item 1 has no ruling"])
        try:
            rec = SimpleNamespace(id="drv.motion.halt", raw={})
            blocks = {k: "" for k in ("contract", "record", "rendered", "contracts")}
            item = {"line": "x", "div": {"kind": "holds_wrongly"}, "rule": "holds"}
            with self.assertRaises(review.Deferred) as e:
                review.adjudicate_concept(run, rec, blocks, [item], Path(tmp.name))
            self.assertEqual(e.exception.stage, "concept_adjudication")
        finally:
            validate_phase._session = saved
            tmp.cleanup()


class RunStatus(unittest.TestCase):
    def test_status_is_recorded(self):
        tmp = tempfile.TemporaryDirectory()
        run = FakeRun(Path(tmp.name))
        led = Ledger(Path(tmp.name) / "l.jsonl", ["L-1"], 2)
        feedback.write_status(run, led, "infrastructure_failure", "a session could not be launched")
        s = json.loads((Path(tmp.name) / "summary.json").read_text())
        self.assertEqual((s["status"], s["stop_reason"]), ("infrastructure_failure", "a session could not be launched"))
        tmp.cleanup()




class TwoAnswers(unittest.TestCase):
    """A session gives an answer and one correction, never a third."""
    def test_the_second_answer_stands(self):
        from harness.agents import session
        saved, calls = session.run, []

        def fake(prompt, **kw):
            calls.append(kw.get("label"))
            return {"result": {"result": json.dumps({})}}
        session.run = fake
        try:
            tmp = tempfile.TemporaryDirectory()
            run = FakeRun(Path(tmp.name))
            _ans, errs = validate_phase._session(run, Path(tmp.name), "r", "p", check=lambda a: ["bad"])
            tmp.cleanup()
        finally:
            session.run = saved
        self.assertEqual((errs, calls), (["bad"], ["r", "r_again"]))


class DivergenceCap(unittest.TestCase):
    """At most 3 divergences: a submission with 4 comes back while submissions remain; a last
    submission with 4 fails the answer, and none of its divergences is certified or judged."""
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.run = FakeRun(Path(self.tmp.name))
        self.run.opts.max_divergences = 3
        self.run.all_concepts = lambda: {}
        self.saved = (review.build_context, review.replay_upheld, review.judge_divergence, review.certify, review.session.run_tools)
        review.build_context = lambda *_a, **_kw: ctx()
        review.replay_upheld = lambda *_a, **_kw: ([], [], [])
        self.certified, self.judged = [], []
        review.certify = lambda _run, _n, divs, _reading, _out: self.certified.append(len(divs)) or {}
        review.judge_divergence = lambda *_a, **_kw: self.judged.append(1)

    def tearDown(self):
        (review.build_context, review.replay_upheld, review.judge_divergence, review.certify, review.session.run_tools) = self.saved
        self.tmp.cleanup()

    def answer(self, n):
        return {"verdict": "return", "divergences": [div(situation=f"s{i}", trace={"scenes": [{"t": i}]}, at=i) for i in range(n)],
                "advisories": [], "gap_candidates": []}

    def review(self, answers):
        review.session.run_tools = scripted_reviewer([submit(a) for a in answers])
        return review.review_behaviour(self.run, node(), LAW, ONTO, SimpleNamespace(data={"params": []}), {}, [], Path(self.tmp.name))

    def test_four_on_a_first_submission_come_back(self):
        out = self.review([self.answer(4), self.answer(3)])
        self.assertEqual(len(self.certified), 3)                        # the second submission's three, one by one
        self.assertNotIn("at most 3", " ".join(out.reasons))            # the stub certifies nothing: deferred, not for the cap

    def test_four_on_the_last_submission_fail_the_answer(self):
        out = self.review([self.answer(4)] * 3)
        self.assertEqual((out.status, out.defer_stage), ("deferred", "reviewer"))
        self.assertIn("at most 3", out.reasons[0])
        self.assertEqual((self.certified, self.judged), ([], []))


class FailClosed(unittest.TestCase):
    """The final answer of a node review routes in order: an upheld item returns the rule; else a
    challenge the harness could not evaluate defers the law at stage `reviewer`; else the rule is
    accepted, a case its execution refutes being an advisory."""
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.run = FakeRun(Path(self.tmp.name))
        self.run.opts.max_divergences = 3
        self.run.all_concepts = lambda: {}
        self.saved = (review.build_context, review.replay_upheld, review.judge_divergence, review.certify, review.append_ruling,
                      review.session.run_tools)
        review.build_context = lambda *_a, **_kw: ctx()
        review.replay_upheld = lambda *_a, **_kw: ([], [], [])
        review.append_ruling = lambda *_a, **_kw: None
        self.certs, self.route, self.judged = {}, "upheld", []          # records by situation
        review.certify = lambda _run, _n, divs, _reading, _out: {k: self.certs[d["situation"]] for k, d in divs.items() if d["situation"] in self.certs}

        def judge(*_a, **_kw):
            self.judged.append(1)
            return SimpleNamespace(route=self.route, line="the case", key="k", question="q", row={})
        review.judge_divergence = judge

    def tearDown(self):
        (review.build_context, review.replay_upheld, review.judge_divergence, review.certify, review.append_ruling,
         review.session.run_tools) = self.saved
        self.tmp.cleanup()

    def review(self, divergences):
        answer = {"verdict": "return", "divergences": divergences, "advisories": [], "gap_candidates": []}
        review.session.run_tools = scripted_reviewer([submit(answer)] * 3)
        return review.review_behaviour(self.run, node(), LAW, ONTO, SimpleNamespace(data={"params": []}), {}, [], Path(self.tmp.name))

    def test_an_uncertified_return_defers(self):
        out = self.review([div()])
        self.assertEqual((out.status, out.defer_stage, self.judged), ("deferred", "reviewer", []))

    def test_an_unusable_certificate_defers(self):
        self.certs = {"s": {**cert(), "lint_errors": ["scene t=0: occupies leaves out [1, 7]"]}}
        out = self.review([div()])
        self.assertEqual((out.status, out.defer_stage, self.judged), ("deferred", "reviewer", []))

    def test_a_refuted_case_is_an_advisory(self):
        self.certs = {"s": cert(rule="violated")}                     # the rule already gives the claimed verdict
        out = self.review([div()])
        self.assertEqual((out.status, self.judged), ("accepted", []))
        self.assertTrue(any("refuted by execution" in a for a in out.advisories))

    def test_upheld_wins_over_an_unusable_case(self):
        self.certs = {"s": cert(rule="compliant")}                    # divergence 2 is never certified
        out = self.review([div(), div(situation="t")])
        self.assertEqual(out.status, "returned")

    def test_a_dismissed_case_alone_accepts(self):
        self.certs, self.route = {"s": cert(rule="compliant")}, "dismissed_permitted_reading"
        out = self.review([div()])
        self.assertEqual((out.status, len(self.judged)), ("accepted", 1))


class ConceptFailClosed(unittest.TestCase):
    """A concept review routes like a node review: upheld returns; an unusable challenge defers; a
    trace on which the body gives the contract's verdict is an advisory."""
    def setUp(self):
        from harness.lean import render_formula
        from harness.model.blueprint import ConceptRecord
        self.tmp = tempfile.TemporaryDirectory()
        self.run = FakeRun(Path(self.tmp.name))
        self.run.opts.ontology = paths.REPO / "ontology" / "ATOMS_train.md"
        self.run.all_concepts = lambda: {}
        self.rec = ConceptRecord({"concept_id": "drv.test.c", "contract": "c holds", "kind": "formula", "args": [{"name": "u", "sort": "track"}],
                                  "params": [], "elements": []})
        self.saved = (render_formula.render_concept, review.session.run_tools, review.execute_concept_divergences, review.adjudicate_concept)
        render_formula.render_concept = lambda *_a, **_kw: "the rendering"
        self.result, self.rulings = ([], [], [], []), []
        review.execute_concept_divergences = lambda _rec, _a, _out, *_r: self.result
        review.adjudicate_concept = lambda *_a, **_kw: self.rulings

    def tearDown(self):
        from harness.lean import render_formula
        (render_formula.render_concept, review.session.run_tools, review.execute_concept_divergences, review.adjudicate_concept) = self.saved
        self.tmp.cleanup()

    def review(self, answer):
        review.session.run_tools = scripted_reviewer([submit(answer)] * 3)
        return review.review_concept(self.run, self.rec, {"reads": [], "body_json": {}}, Path(self.tmp.name))

    def good(self):
        return {"kind": "holds_wrongly", "contract_verdict": "fails", "contract_words": "c holds", "situation": "s",
                "instance": {"literals": {}, "params": {}}, "grounding": {"u": 1}, "trace": {"scenes": [{"t": 0}]}}

    def test_a_malformed_return_defers(self):
        bad = {**self.good(), "instance": {"literals": {"2": "2"}, "params": {}}}
        out = self.review({"verdict": "return", "divergences": [bad], "not_general": [], "advisories": []})
        self.assertEqual((out.status, out.defer_stage), ("deferred", "reviewer"))

    def test_a_harness_error_defers(self):
        self.result = ([], [], ["divergence 1: the trace does not decode: x"], [])
        out = self.review({"verdict": "return", "divergences": [self.good()], "not_general": [], "advisories": []})
        self.assertEqual((out.status, out.defer_stage), ("deferred", "reviewer"))

    def test_an_agreeing_trace_accepts(self):
        self.result = ([], ["divergence 1: the body gives the contract's verdict"], [], [])
        out = self.review({"verdict": "return", "divergences": [self.good()], "not_general": [], "advisories": []})
        self.assertEqual(out.status, "accepted")
        self.assertTrue(any("refuted by execution" in a for a in out.advisories))


class QuantityDivergence(unittest.TestCase):
    """A quantity concept's divergence states the interval the contract's words give its value: one
    dimension, the value's; never a verdict."""
    def setUp(self):
        from harness.model.blueprint import ConceptRecord
        self.rec = ConceptRecord({"concept_id": "drv.test.q", "kind": "quantity", "contract": "the distance it covers",
                                  "args": [{"name": "u", "sort": "track"}], "params": [{"name": "t", "unit": "s"}]})
        self.body = {"mul": [{"measure": "kin_speed", "args": [{"var": "u"}]}, {"param": "t"}]}

    def div(self, **kw):
        d = {"kind": "value_wrongly", "situation": "s", "contract_words": "the distance it covers",
             "contract_value": {"lo": [10, "m"], "hi": [12, "m"]}, "instance": {"literals": {}, "params": {"t": [1, "s"]}},
             "grounding": {"u": 1}, "trace": {"scenes": [{"t": 0}]}}
        d.update(kw)
        return d

    def defects(self, d):
        return review.concept_divergence_defects(1, d, self.rec, "the distance it covers", review.body_dim(self.rec, self.body))

    def test_the_body_is_in_metres(self):
        self.assertEqual(review.body_dim(self.rec, self.body), (1, 0, 0))

    def test_an_interval_in_metres_is_admitted(self):
        self.assertEqual(self.defects(self.div()), [])

    def test_an_interval_of_another_dimension(self):
        self.assertTrue(any("the value is in m" in e for e in self.defects(self.div(contract_value={"lo": [1, "s"], "hi": [2, "s"]}))))

    def test_a_verdict_is_not_a_value(self):
        self.assertTrue(any("never `contract_verdict`" in e for e in self.defects(self.div(contract_verdict="fails"))))

    def test_lo_above_hi(self):
        self.assertTrue(any("exceeds" in e for e in self.defects(self.div(contract_value={"lo": [12, "m"], "hi": [10, "m"]}))))


class ParameterNotes(unittest.TestCase):
    """The reviewer's words on a proposed parameter of the node, named by its id, reach the operator
    under that parameter's review line, whatever became of the divergence."""
    def test_notes_name_the_parameter(self):
        n = Node({"node_id": "L_1_o1", "law_refs": ["L-1"], "params": ["p.w"], "binders": [{"name": "v"}]})
        reading = SimpleNamespace(data={"params": [{"name": "p.w", "value": 8, "unit": "s", "proposed": True},
                                                   {"name": "p.x", "value": 1, "unit": "s"}]})
        answer = {"advisories": ["p.w = 8 s misses slow turns", "p.x is fine"],
                  "divergences": [{"situation": "a turn longer than p.w"}, {"situation": "nothing about it"}]}
        notes = review.param_notes(n, reading, answer, {1: "not evaluated, unverified"}, 2)
        self.assertEqual([name for name, _ in notes], ["p.w", "p.w"])
        self.assertIn("divergence 1, not evaluated, unverified", notes[1][1])

    def test_placed_under_the_review_line(self):
        from harness import loop
        to_user = ["parameter `p.w` = 8 s proposed by `L_1_o1` (c); review it", "other"]
        loop.param_notes_to_user(to_user, [("p.w", "a"), ("p.w", "b"), ("p.z", "c")])
        self.assertEqual(to_user[:3], ["parameter `p.w` = 8 s proposed by `L_1_o1` (c); review it", "  - a", "  - b"])
        self.assertTrue(to_user[-1].startswith("parameter `p.z` (proposed, under review)"))


class SamplingRemedy(unittest.TestCase):
    def test_the_message_names_the_windows(self):
        w = review.window_params([{"name": "p.w", "value": 8, "unit": "s"}, {"name": "p.k", "value": 150, "unit": "deg"}])
        msg = review._trace_remedy("sampling_gap:prim_heading_change", w)
        self.assertIn("at most half the window's length apart", msg)
        self.assertIn("`p.w` = 8 s", msg)
        self.assertNotIn("p.k", msg)


class VerdictHistory(unittest.TestCase):
    """The history a verdict reads: nested windows add up, a rise adds the observation before,
    siblings take the larger, a window ahead is counted ahead, and an unfixed length is not guessed."""
    def setUp(self):
        self.reading = SimpleNamespace(data={"params": [{"name": "p.w", "value": 12, "unit": "s"}]})
        self.concepts = {"drv.test.turn": {"params": [{"name": "window", "unit": "s"}],
                                           "body_json": {"cmp": "ge", "lhs": {"abs": {"quantity": "prim_heading_change", "args": [{"var": "u"}],
                                                                                       "params": [{"param": "window"}]}},
                                                         "rhs": {"lit": {"num": 150, "den": 1}, "unit": "degree"}}}}
        self.turn = {"derived": "drv_test_turn", "args": [{"var": "v"}], "params": [{"param": "p.w"}]}

    def need(self, f):
        return review.history_of([f], self.concepts, self.reading)

    def test_a_rise_of_a_windowed_concept(self):
        n = self.need({"and": [{"rises": self.turn}, {"holds_for": "time", "length": {"param": "p.w"}, "subject": "v", "body": "tt"}]})
        self.assertEqual((float(n.back), n.steps), (12.0, 1))
        self.assertIn("12 s before the observation before `at`", review.history_text(n))

    def test_nested_windows_add_up(self):
        n = self.need({"holds_for": "time", "length": {"lit": {"num": 5, "den": 1}, "unit": "second"}, "subject": "v", "body": self.turn})
        self.assertEqual(float(n.back), 17.0)

    def test_a_window_ahead(self):
        n = self.need({"within": "time", "length": {"lit": {"num": 3, "den": 1}, "unit": "second"}, "subject": "v", "body": "tt"})
        self.assertEqual((float(n.ahead), float(n.back)), (3.0, 0.0))

    def test_an_unfixed_length_is_not_guessed(self):
        n = self.need({"holds_for": "time", "length": {"param": "p.none"}, "subject": "v", "body": "tt"})
        self.assertTrue(n.unknown)
        self.assertIn("not counted", review.history_text(n))

    def test_the_truncation_message_states_the_history(self):
        msg = review._trace_remedy("window_truncated:prim_heading_change", "", "the verdict at `at` reads up to 12 s before the observation before `at`")
        self.assertIn("observation before `at`", msg)


class CaseLanguageMeanings(unittest.TestCase):
    """The case language says what each temporal form means and which way its window runs, read from
    Formula.lean, and how a fact at an earlier observation is stated."""
    def test_directions_and_recipe(self):
        from harness.lean import surface
        t = surface.case_language()
        line = lambda key: next(l for l in t.splitlines() if l.startswith(f"- formula `{key}`"))
        self.assertIn("window behind", line("holds_for"))
        self.assertIn("window ahead", line("within"))
        self.assertIn("ψ is `when`, φ is `body`", line("at_last"))
        self.assertIn("later observation", line("eventually"))
        self.assertIn("never one ahead", t)
        self.assertIn('"kin_time"', t)


class RegionPlaces(unittest.TestCase):
    """A record that reads a region's property claims the place: the region the road user occupies
    and the kind of region it is read on."""
    def test_a_property_without_its_place_returns(self):
        from harness.checks import validate_a
        errs = validate_a.check_region_places("N", {"st.curvature", "st.sight_distance", "st.crest", "st.region_geometry"}, ONTO)
        self.assertTrue(errs and "`rel.occupies`" in errs[0] and "st.curvature" in errs[0])

    def test_a_property_with_its_place_passes(self):
        from harness.checks import validate_a
        self.assertEqual(validate_a.check_region_places("N", {"st.curvature", "st.roadway", "rel.occupies", "st.sight_distance"}, ONTO), [])

    def test_no_property_no_demand(self):
        from harness.checks import validate_a
        self.assertEqual(validate_a.check_region_places("N", {"st.crest", "st.region_geometry", "kin.speed"}, ONTO), [])

    def test_a_kind_is_not_a_property(self):
        from harness.checks import validate_a
        props, kinds = validate_a.region_atoms(ONTO)
        self.assertIn("st.roadway", kinds)
        self.assertIn("st.sight_distance", props)
        self.assertNotIn("st.roadway", props)


class ParameterQuestion(unittest.TestCase):
    """A parameter question names the proposed parameters stage B's reason names, or all of them
    where it names none."""
    params = [{"name": "p.curvature_resolution", "proposed": True}, {"name": "p.reversal_window", "proposed": True},
              {"name": "p.reviewed", "proposed": False}]

    def test_the_cited_parameter_only(self):
        why = "The case's curvature lies below p.curvature_resolution = 0.0005 1/m, so the curve branch fails"
        self.assertEqual(review.questioned_parameters(self.params, why), ["p.curvature_resolution"])

    def test_no_citation_names_every_proposed_parameter(self):
        self.assertEqual(review.questioned_parameters(self.params, "the size of a tolerance decides it"),
                         ["p.curvature_resolution", "p.reversal_window"])


class IntegrityStop(unittest.TestCase):
    """A damaged audit file read by any phase ends the run as `data_integrity_failure`."""
    def test_the_run_stops(self):
        from harness import loop
        from harness.store import jsonl
        from harness.store.state import Options
        run_id = "_test_integrity_stop"
        saved = loop._run_loop
        loop._run_loop = lambda opts: (_ for _ in ()).throw(jsonl.DataIntegrityError(Path("aggregate_certificates.jsonl"), 3, "not JSON"))
        try:
            out = loop.run_loop(Options(run_id=run_id, laws=Path("laws.jsonl"), ontology=Path("o.md"), reading=Path("r.json")))
            self.assertEqual(out["status"], "data_integrity_failure")
            s = json.loads((paths.run_dir(run_id) / "summary.json").read_text())
            self.assertEqual(s["status"], "data_integrity_failure")
            self.assertIn("aggregate_certificates.jsonl:3", s["stop_reason"])
        finally:
            loop._run_loop = saved
            import shutil
            shutil.rmtree(paths.run_dir(run_id), ignore_errors=True)


class ConceptLiteralsMessage(unittest.TestCase):
    """With no literal formal, the defect names the extra keys and the empty map it wants."""

    def test_no_literal_formal(self):
        from harness.model.blueprint import ConceptRecord
        rec = ConceptRecord({"concept_id": "drv.test.c", "args": [{"name": "u", "sort": "track"}], "params": []})
        d = {"kind": "holds_wrongly", "contract_verdict": "fails", "contract_words": "c", "instance": {"literals": {"2": "2"}, "params": {}},
             "grounding": {"u": 1}, "trace": {"scenes": [{"t": 0}]}}
        errs = review.concept_divergence_defects(1, d, rec, "c")
        self.assertTrue(any("['2'] are not literal formals" in e and "`{}`" in e for e in errs), errs)

    def test_the_record_names_no_literal_formal(self):
        from harness.model.blueprint import ConceptRecord
        line = review.literal_formals_line(ConceptRecord({"concept_id": "drv.test.c", "args": [{"name": "u", "sort": "track"}]}))
        self.assertIn("`instance.literals` is `{}`", line)


class StallStop(unittest.TestCase):
    """An iteration is a stall only when no remedy waits for its first try."""

    def ledgers(self, d: Path):
        from harness.store.ledger import NodeLedger
        led = Ledger(d / "l.jsonl", ["L-1", "L-2"], 3)
        led.mark_planned("L-1", ["L_1"], 1); led.mark_planned("L-2", ["L_2"], 1)
        return led, ConceptLedger(d / "c.jsonl", 2), NodeLedger(d / "n.jsonl", 2)

    def test_pending_first_tries(self):
        from harness.loop import first_try_pending
        with tempfile.TemporaryDirectory() as t:
            d = Path(t)
            led, con, nod = self.ledgers(d)
            self.assertFalse(first_try_pending(led, con, nod))
            led.return_law("L-1", ["r"], 2)
            self.assertTrue(first_try_pending(led, con, nod))                  # a law returned once
            led.mark_planned("L-1", ["L_1"], 3)
            self.assertFalse(first_try_pending(led, con, nod))                 # planned again: tried
            led.defer_judge("L-2", "reviewer", ["no answer"])
            self.assertTrue(first_try_pending(led, con, nod))                  # deferred once
            led.clear_judge("L-2")
            nod.returned("L_2", "L-2", ["gate"], "task", 3)
            self.assertTrue(first_try_pending(led, con, nod))                  # a node returned once, its law held
            nod.repaired("L_2")
            self.assertFalse(first_try_pending(led, con, nod))
            con.planned("drv.x", ["L_2"], 3); con.returned("drv.x", ["review"], "task")
            self.assertTrue(first_try_pending(led, con, nod))                  # a concept returned once, its user open

    def test_spent_or_orphaned_remedies_do_not_count(self):
        from harness.loop import first_try_pending
        with tempfile.TemporaryDirectory() as t:
            d = Path(t)
            led, con, nod = self.ledgers(d)
            led.return_law("L-1", ["r"], 2); led.mark_planned("L-1", ["L_1"], 3); led.return_law("L-1", ["r"], 3)
            self.assertFalse(first_try_pending(led, con, nod))                 # a second return
            nod.returned("L_2", "L-2", ["gate"], "task", 3); led.fail("L-2", ["x"])
            con.planned("drv.x", ["L_2"], 3); con.returned("drv.x", ["review"], "task")
            self.assertFalse(first_try_pending(led, con, nod))                 # its law closed


class SubsetRun(unittest.TestCase):
    """A subset run plans its listed laws again, even where its base run accepted them."""

    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.saved = paths.RESULTS
        paths.RESULTS = Path(self.tmp.name)
        base = paths.run_dir("base"); base.mkdir()
        rows = [{"node_id": "L_1", "law_refs": ["L-1"]}, {"node_id": "L_2", "law_refs": ["L-2"]}]
        (base / "accepted_nodes.jsonl").write_text("".join(json.dumps(r) + "\n" for r in rows))
        self.corpus = Path(self.tmp.name) / "corpus" / "laws.jsonl"; self.corpus.parent.mkdir()
        self.corpus.write_text("".join(json.dumps({"id": i, "title": "", "text": "t", "source": ""}) + "\n" for i in ("L-1", "L-2", "L-3")))
        (self.corpus.parent / "definitions.jsonl").write_text('{"id": "DEF-1"}\n')

    def tearDown(self):
        paths.RESULTS = self.saved
        self.tmp.cleanup()

    def run_of(self, laws: Path):
        from harness.store.state import Options, Run
        run = Run(Options(run_id="sub", laws=laws, ontology=Path("o.md"), reading=Path("r.json"), base_run="base"))
        run.load_accepted()
        return run

    def test_listed_law_is_not_taken_from_the_base(self):
        from scripts.subset_laws import subset
        laws = subset("sub", self.corpus, ["L-1"])
        self.assertEqual([json.loads(l)["id"] for l in laws.read_text().splitlines()], ["L-1"])
        self.assertTrue((laws.parent / "definitions.jsonl").exists())
        self.assertEqual(sorted(self.run_of(laws).base_nodes), ["L_2"])

    def test_a_base_node_composing_a_dropped_one_stops(self):
        from scripts.subset_laws import subset
        f = paths.run_dir("base") / "accepted_nodes.jsonl"
        f.write_text(f.read_text().replace('"law_refs": ["L-2"]}', '"law_refs": ["L-2"], "compositions": [{"rule": "L_1"}]}'))
        with self.assertRaises(SystemExit):
            self.run_of(subset("sub", self.corpus, ["L-1"]))

    def test_a_stray_goes_to_the_base_run_first(self):
        from harness.loop import _owner_run
        other = paths.run_dir("a_older"); other.mkdir()
        (other / "accepted_nodes.jsonl").write_text(json.dumps({"node_id": "L_1", "law_refs": ["L-1"]}) + "\n")
        self.assertEqual(_owner_run("L_1"), "a_older")
        self.assertEqual(_owner_run("L_1", "base"), "base")

    def test_isolation_moves_the_dropped_node_to_the_base_run(self):
        from harness import loop
        from harness.lean import index_sync
        from harness.model import nodeid
        from scripts.subset_laws import subset
        old = paths.LIBRARY
        saved = {k: v for k, v in vars(paths).items() if isinstance(v, Path) and (v == old or old in v.parents)}
        lib = Path(self.tmp.name) / "library"
        try:
            for k, v in saved.items():
                setattr(paths, k, lib / v.relative_to(old))
            for nid in ("L_1", "L_2"):
                for rel in (nodeid.rule_path(nid), nodeid.witness_path(nid)):
                    (lib / rel).parent.mkdir(parents=True, exist_ok=True); (lib / rel).write_text(f"-- {nid}\n")
            saved_index, index_sync.write_index = index_sync.write_index, lambda *a, **k: None
            try:
                loop.check_library_isolation(self.run_of(subset("sub", self.corpus, ["L-1"])))
            finally:
                index_sync.write_index = saved_index
            self.assertFalse((lib / nodeid.rule_path("L_1")).exists())
            self.assertTrue((paths.run_dir("base") / "library_snapshot" / nodeid.rule_path("L_1")).exists())
            self.assertTrue((lib / nodeid.rule_path("L_2")).exists())             # the base node stays
        finally:
            for k, v in saved.items():
                setattr(paths, k, v)

    def test_subset_is_written_once_and_names_known_laws(self):
        from scripts.subset_laws import subset
        with self.assertRaises(SystemExit):
            subset("sub", self.corpus, ["L-9"])
        subset("sub", self.corpus, ["L-1"])
        subset("sub", self.corpus, ["L-1"])                                    # the same contents: allowed
        with self.assertRaises(SystemExit):
            subset("sub", self.corpus, ["L-2"])


class ReviewToolLoop(unittest.TestCase):
    """The reviewer's tool state: checks and submissions counted apart, unusable evidence keeping
    the session open, the last submission standing, and evidence run once per session."""
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.run = FakeRun(Path(self.tmp.name))
        self.run.opts.max_divergences = 3
        self.run.all_concepts = lambda: {}
        self.saved = (review.build_context, review.replay_upheld, review.judge_divergence, review.certify, review.append_ruling,
                      review.session.run_tools)
        review.build_context = lambda *_a, **_kw: ctx()
        review.replay_upheld = lambda *_a, **_kw: ([], [], [])
        review.append_ruling = lambda *_a, **_kw: None
        self.certs, self.runs = {"s": cert(rule="compliant")}, []

        def certify(_run, _n, divs, _reading, out):
            self.runs.append(Path(out).relative_to(self.tmp.name).as_posix())
            return {k: self.certs[d["situation"]] for k, d in divs.items() if d["situation"] in self.certs}
        review.certify = certify
        review.judge_divergence = lambda *_a, **_kw: SimpleNamespace(route="upheld", line="the case", key="k", question="q", row={})

    def tearDown(self):
        (review.build_context, review.replay_upheld, review.judge_divergence, review.certify, review.append_ruling,
         review.session.run_tools) = self.saved
        self.tmp.cleanup()

    def answer(self, *divs):
        return {"verdict": "return", "divergences": list(divs), "advisories": [], "gap_candidates": []}

    def review(self, calls, seen=None):
        review.session.run_tools = scripted_reviewer(calls, seen)
        return review.review_behaviour(self.run, node(), LAW, ONTO, SimpleNamespace(data={"params": []}), {}, [], Path(self.tmp.name))

    def test_a_checked_divergence_submitted_is_judged_from_the_cache(self):
        seen = []
        out = self.review([("check_divergence", {"divergence": div()}), submit(self.answer(div()))], seen)
        self.assertEqual(seen[0]["status"], "certifiable")
        self.assertEqual(out.status, "returned")
        self.assertEqual(self.runs, ["pass1/checks/L1/001"])                    # one run: the submission reused the check

    def test_an_unchecked_divergence_is_certified_at_submission(self):
        out = self.review([submit(self.answer(div()))])
        self.assertEqual(out.status, "returned")
        self.assertEqual(self.runs, ["pass1/submissions/L1/001/d1"])

    def test_unusable_evidence_comes_back_and_a_correction_is_accepted(self):
        self.certs["bad"] = {**cert(), "lint_errors": ["scene t=0: user 1 sight_along_way names region 10, which is not a highway"]}
        seen = []
        fixed = div(trace={"scenes": [{"t": 0, "users": []}]})                 # the trace corrected, so new evidence
        out = self.review([submit(self.answer(div(situation="bad"))), submit(self.answer(fixed))], seen)
        self.assertEqual((seen[0]["accepted"], seen[1]["accepted"]), (False, True))
        self.assertIn("not a highway", " ".join(seen[0]["defects"]))
        self.assertEqual(out.status, "returned")

    def test_the_last_submission_stands_with_its_defects(self):
        self.run.opts.review_submissions = 2
        self.certs["bad"] = {**cert(), "lint_errors": ["x"]}
        seen = []
        out = self.review([submit(self.answer(div(situation="bad")))] * 3, seen)
        self.assertEqual([s["accepted"] for s in seen], [False, True])     # the second is the last slot: it stands
        self.assertTrue(seen[1].get("final") and seen[1].get("defects"))   # with its defects, said
        self.assertEqual((out.status, out.defer_stage), ("deferred", "reviewer"))

    def test_a_refuted_divergence_does_not_hold_the_session_open(self):
        self.certs["r"] = cert(rule="violated")
        seen = []
        out = self.review([submit(self.answer(div(situation="r")))], seen)
        self.assertTrue(seen[0]["accepted"])
        self.assertEqual(out.status, "accepted")
        self.assertTrue(any("refuted by execution" in a for a in out.advisories))

    def test_checks_spent_then_a_submission(self):
        self.run.opts.review_checks = 1
        seen = []
        out = self.review([("check_divergence", {"divergence": div()}), ("check_divergence", {"divergence": div(situation="t")}),
                           submit(self.answer(div()))], seen)
        self.assertEqual(seen[1]["status"], "checks spent")
        self.assertEqual(out.status, "returned")

    def test_the_tool_choice_names_the_submission_once_checks_are_spent(self):
        t = review.ReviewTools(Path(self.tmp.name), 1, 2)
        self.assertEqual(t.choice(), "required")
        t.used_checks = 1
        self.assertEqual(t.choice(), {"type": "function", "name": "submit_review"})

    def test_no_submission_defers(self):
        out = self.review([("check_divergence", {"divergence": div()})])
        self.assertEqual((out.status, out.defer_stage), ("deferred", "reviewer"))

    def test_a_certificate_that_does_not_run_defers_at_its_own_stage(self):
        def broken(*_a, **_kw):
            raise review.HarnessFailure("the certificate program did not run")
        review.certify = broken
        out = self.review([("check_divergence", {"divergence": div()})])
        self.assertEqual((out.status, out.defer_stage), ("deferred", "certificate"))


class ToolSession(unittest.TestCase):
    """`session.run_tools`: every request reserved and recorded on its own, the conversation sent
    back whole, a pause propagated with the earlier usage kept, a failed request relaunched."""
    def setUp(self):
        from harness.agents import openai_runner, session
        from harness.store import budget
        self.session, self.budget, self.oai = session, budget, openai_runner
        self.tmp = tempfile.TemporaryDirectory()
        self.d = Path(self.tmp.name)
        self.saved = (paths.RESULTS, openai_runner.request, dict(budget._BUDGETS))
        paths.RESULTS = self.d
        (self.d / "t").mkdir()
        prices = self.d / "prices.json"
        prices.write_text(json.dumps({"gpt-x": {"input_usd_per_million": 1, "cached_input_usd_per_million": 0.1, "output_usd_per_million": 2}}))
        self.opts = Options(run_id="t", laws=self.d / "laws.jsonl", ontology=ONTO.path, reading=self.d / "reading.json",
                            model="gpt-x", reviewer_max_output_tokens=1000, session_timeout=60, session_retries=1,
                                    retry_wait=0, model_prices=prices, openai_budget_usd=None)
        budget._BUDGETS.clear()
        self.requests = []

    def tearDown(self):
        paths.RESULTS, self.oai.request, b = self.saved
        self.budget._BUDGETS.clear(); self.budget._BUDGETS.update(b)
        self.tmp.cleanup()

    class Tools:
        specs = [{"type": "function", "name": "check_divergence"}, {"type": "function", "name": "submit_review"}]
        max_requests = 5

        def reset(self):
            self.done, self.calls = False, []

        def choice(self):
            return "required"

        def call(self, name, args):
            self.calls.append(name)
            self.done = name == "submit_review"
            return json.dumps({"ok": name})

    def reply(self, name, n):
        return 0, {"output": [{"type": "reasoning", "id": f"rs{n}", "encrypted_content": "e"},
                              {"type": "function_call", "call_id": f"c{n}", "name": name, "arguments": "{}"}],
                   "usage": {"input_tokens": 10, "output_tokens": 5}, "status": "completed"}, False

    def usage(self):
        f = self.d / "t" / "usage.jsonl"
        return [json.loads(l) for l in f.read_text().splitlines()] if f.exists() else []

    def test_each_request_is_recorded_and_the_conversation_sent_back(self):
        script = ["check_divergence", "submit_review"]

        def request(items, **kw):
            self.requests.append(json.loads(json.dumps(items)))
            return self.reply(script[len(self.requests) - 1], len(self.requests))
        self.oai.request = request
        tools = self.Tools()
        rec = self.session.run_tools("p", self.d, self.opts, tools, label="review_behaviour", effort="high", model="gpt-x")
        self.assertEqual((rec["result"], tools.calls), ({"requests": 2, "submitted": True}, script))
        second = self.requests[1]
        self.assertEqual([i.get("type") for i in second[1:]], ["reasoning", "function_call", "function_call_output"])
        self.assertEqual(second[3]["call_id"], "c1")
        self.assertEqual([r["label"] for r in self.usage()], ["review_behaviour:L1.r1", "review_behaviour:L1.r2"])

    def test_a_pause_after_earlier_requests_keeps_their_usage(self):
        self.oai.request = lambda items, **kw: self.reply("check_divergence", 1)
        b = self.budget.for_run(self.opts, self.d / "t")
        saved, calls = b.reserve, []

        def reserve(*a):
            calls.append(1)
            if len(calls) == 2:
                raise self.budget.BudgetPaused("over the limit")
            return saved(*a)
        b.reserve = reserve
        with self.assertRaises(self.budget.BudgetPaused):
            self.session.run_tools("p", self.d, self.opts, self.Tools(), label="review_behaviour", effort="high", model="gpt-x")
        self.assertEqual(len(self.usage()), 1)

    def test_a_failed_request_relaunches_then_the_session_is_unavailable(self):
        self.oai.request = lambda items, **kw: (1, None, False)
        with self.assertRaises(self.session.SessionUnavailable):
            self.session.run_tools("p", self.d, self.opts, self.Tools(), label="review_behaviour", effort="high", model="gpt-x")
        self.assertEqual(len(self.usage()), 2)                              # one per launch, each recorded

    def test_only_function_tools_are_admitted(self):
        with self.assertRaises(ValueError):
            self.saved[1]([], model="gpt-x", tools=[{"type": "web_search"}], tool_choice="auto", effort=None, timeout_seconds=1)


class AtomParameters(unittest.TestCase):
    """The case vocabulary shows the parameters Core requires of an atom, and the extent's contract
    states what a formula reads."""
    def test_rows(self):
        from harness.lean import surface
        t = surface.case_vocabulary(ONTO)
        row = lambda aid: next(l for l in t.splitlines() if l.startswith(f"| `{aid}` |"))
        for aid in ("rel.same_direction", "rel.oncoming"):
            self.assertIn("params [cosine tolerance: 1 (no unit)]", row(aid))
        self.assertNotIn("params [", row("kin.speed"))
        self.assertIn("a formula reads the full length", row("kin.extent"))


class CaseDiagnosis(unittest.TestCase):
    """A case that is not true names its failing conjunct, and within a conjunct over every road
    user, the failing fact and the user."""
    def test_the_failing_fact_is_named(self):
        import re
        saved = review.lean.lean_run

        def lean_run(_lib, prog):
            lines = []
            for k, cpath in re.findall(r'\((\d+), "[^"]*", "([^"]*)"', Path(prog).read_text()):
                bad = "kin_extent" in Path(cpath).read_text()
                lines.append("CERT\t" + json.dumps({"schema": review.CERT_SCHEMA, "divergence": int(k),
                                                    "case_value": {"value": "false" if bad else "true", "unknown_reasons": []}}))
            return True, "\n".join(lines)
        review.lean.lean_run = lean_run
        fact = lambda m: {"cmp": "eq", "lhs": {"measure": m, "args": [{"var": "u"}]}, "rhs": {"lit": {"num": 1, "den": 1}, "unit": "metre"}}
        d = div(case={"and": [{"atom": "ru_car", "args": [{"var": "v"}], "params": []},
                              {"forall_user": "u", "body": {"and": [fact("kin_speed"), fact("kin_extent")]}}]},
                trace={"scenes": [{"t": 0, "users": [{"track": 1}, {"track": 2}]}]})
        recs = {1: {"case_value": {"value": "false", "unknown_reasons": []}}}
        with tempfile.TemporaryDirectory() as t:
            try:
                review._diagnose(SimpleNamespace(id="L_1_o1"), {1: d}, recs, Path(t) / "r.json", Path(t) / "diagnosis")
            finally:
                review.lean.lean_run = saved
        self.assertEqual([x.split(":")[0] for x in recs[1]["diagnosis"]],
                         ["conjunct 2 of 2, for `u` = track 1", "conjunct 2 of 2, for `u` = track 2"])
        self.assertTrue(all("fact 2 of 2 is false" in x for x in recs[1]["diagnosis"]))


class Obligations(unittest.TestCase):
    """An upheld case stays an obligation after its repair: open while the rule diverges from the
    law's verdict (stage A's), satisfied once it gives it, open again if a later rule regresses.
    It leaves only when invalidated (it can no longer be evaluated) or re-adjudicated."""
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.run = FakeRun(Path(self.tmp.name))
        self.saved = (review.certify, review.judge_divergence)
        self.rule, self.law, self.lint = "violated", "compliant", []
        review.certify = lambda _run, _n, divs, _rd, _out: {k: {**cert(rule=self.rule), "case_value": {"value": "true"},
                                                                 "lint_errors": list(self.lint)} for k in divs}

        def judge(_run, _n, _ctx, _onto, d, c, _out, _label, previous=None):
            verdict = c["rule_result"]["verdict"]
            sa = {"verdict": self.law, "decisive": True, "law_words": "shall stop"}
            agrees = review._equivalent(verdict, self.law)
            row = {"schema": review.CASE_SCHEMA, "key": "law:L-1", "subject": "L_1_o1", "case_id": "c1", "stage_a": sa,
                   "stageA_digest": "A", "stage_b": None if agrees else {"outcome": "upheld"}, "stageB_digest": None if agrees else "B",
                   "route": "rule_agrees" if agrees else "upheld", "ruling": "advisory" if agrees else "upheld", "rule_result": c["rule_result"]}
            return SimpleNamespace(route=row["route"], row=row, line="the case", key="k")
        review.judge_divergence = judge
        review.append_ruling(self.run, {"schema": review.CASE_SCHEMA, "key": "law:L-1", "subject": "L_1_o1", "case_id": "c1",
                                        "ruling": "upheld", "lawful_verdict": "violated", "grounding": {"v": 1},
                                        "trace": {"scenes": [{"t": 0}]}, "case": "tt", "entities": {}, "at": 0,
                                        "stage_a": {"verdict": "compliant"}, "stageA_digest": "A", "stage_b": {"outcome": "upheld"},
                                        "stageB_digest": "B", "iteration": 1})

    def tearDown(self):
        review.certify, review.judge_divergence = self.saved
        self.tmp.cleanup()

    def replay(self, run=None):
        n = Node({"node_id": "L_1_o1", "law_refs": ["L-1"], "binders": [{"name": "v"}]})
        return review.replay_upheld(run or self.run, n, None, ONTO, None, Path(self.tmp.name))

    def states(self, run=None):
        return [r.get("obligation") for r in review.upheld_rows(run or self.run, {"L-1"})]

    def test_wrong_repaired_regressed_and_resumed(self):
        reasons, _keys, _notes = self.replay()                              # wrong: the rule still diverges
        self.assertTrue(reasons)
        n0 = len(review._all_rows(self.run))
        self.assertEqual(n0, 1)                                             # unchanged state: no row added
        self.rule = "compliant"                                             # repaired
        reasons, _keys, notes = self.replay()
        self.assertEqual((reasons, self.states()), ([], ["satisfied"]))
        self.assertTrue(any("satisfied" in x for x in notes))
        self.replay()                                                       # replayed again, unchanged
        self.assertEqual(len(review._all_rows(self.run)), n0 + 1)
        resumed = FakeRun(Path(self.tmp.name))                              # a resumed run reads the same obligations
        self.assertEqual(self.states(resumed), ["satisfied"])
        self.rule = "violated"                                              # regressed
        reasons, _keys, _notes = self.replay(resumed)
        self.assertTrue(reasons)
        self.assertEqual(self.states(resumed), ["open"])

    def test_satisfaction_is_measured_against_stage_a(self):
        self.rule = "violated"                                              # the reviewer's claim, not the law's verdict
        reasons, _keys, _notes = self.replay()
        self.assertTrue(reasons)
        self.assertEqual(self.states(), [None])                             # still open, never invalidated

    def test_an_invalidated_case_leaves_and_is_reported(self):
        self.lint = ["scene t=0: structure 7 has no boundary"]
        reasons, _keys, notes = self.replay()
        self.assertEqual((reasons, self.states()), ([], []))
        self.assertTrue(any(x.startswith("obligation invalidated:") for x in notes))

    def test_a_changed_law_verdict_the_rule_now_meets_is_re_adjudicated(self):
        self.law, self.rule = "violated", "violated"                       # stage A now says violated, and the rule agrees
        reasons, _keys, notes = self.replay()
        self.assertEqual((reasons, self.states()), ([], []))
        self.assertTrue(any("re-adjudicated" in x for x in notes))


class EvidenceIntegrity(unittest.TestCase):
    """Revision 28, part 2: each launch keeps its evidence; a malformed divergence is never run; a
    diagnosis belongs to its own certificate run and never defers the review; a concept harness
    failure defers at `certificate`."""
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.d = Path(self.tmp.name)
        self.run = FakeRun(self.d)
        self.run.opts.max_divergences = 3
        self.saved = (review.certify, review.lean.lean_run)
        self.dirs = []
        review.certify = lambda _r, _n, divs, _rd, out: self.dirs.append(Path(out).relative_to(self.d).as_posix()) or \
            {k: cert(rule="compliant") for k in divs}

    def tearDown(self):
        review.certify, review.lean.lean_run = self.saved
        self.tmp.cleanup()

    def tools(self):
        return review.BehaviourTools(self.run, node(), LAW, None, ["v"], "", "", self.d, 8, 3)

    def test_a_relaunch_keeps_the_first_launchs_evidence(self):
        t = self.tools()
        t.reset()                                                            # the first launch, as `run_tools` starts it
        t.call("check_divergence", {"divergence": div()})
        t.reset()
        t.call("check_divergence", {"divergence": div(at=5, trace={"scenes": [{"t": 5}]})})
        self.assertEqual(self.dirs, ["checks/L1/001", "checks/L2/001"])

    def test_a_malformed_divergence_is_not_run(self):
        t = self.tools()
        out = json.loads(t.call("check_divergence", {"divergence": div(kind="nonsense")}))
        self.assertEqual((out["status"], self.dirs), ("schema defects", []))
        self.assertEqual(t.certs_of({"divergences": [div(kind="nonsense")]}), {})
        self.assertEqual(self.dirs, [])

    def lean_with(self, diagnosis_ok: bool, seen_traces: list):
        import re as _re
        def lean_run(_lib, prog):
            text = Path(prog).read_text()
            items = _re.findall(r'\((\d+), "([^"]*)", "([^"]*)"', text)
            if "diagnosis" in str(prog):
                seen_traces.extend(Path(t).read_text() for _k, t, _c in items)
                if not diagnosis_ok:
                    return False, "error: boom"
                return True, "\n".join("CERT\t" + json.dumps({"schema": review.CERT_SCHEMA, "divergence": int(k),
                                                                 "case_value": {"value": "false", "unknown_reasons": []}}) for k, _t, _c in items)
            return True, "\n".join("CERT\t" + json.dumps({"schema": review.CERT_SCHEMA, "divergence": int(k), "rule_result": {"verdict": "violated"},
                                                             "case_value": {"value": "false", "unknown_reasons": []}}) for k, _t, _c in items)
        return lean_run

    def test_a_diagnosis_never_reads_an_earlier_trace(self):
        review.certify = self.saved[0]
        seen = []
        review.lean.lean_run = self.lean_with(True, seen)
        reading = SimpleNamespace(lean_json=lambda: "{}")
        for t in (0, 7):
            d = div(case={"and": ["tt", "ff"]}, trace={"scenes": [{"t": t}]}, at=t)
            review.certify(self.run, node(), {1: d}, reading, self.d / "same")
        self.assertIn('"t": 7', seen[-1])

    def test_a_failed_diagnosis_keeps_the_certificate(self):
        review.certify = self.saved[0]
        review.lean.lean_run = self.lean_with(False, [])
        d = div(case={"and": ["tt", "ff"]})
        recs = review.certify(self.run, node(), {1: d}, SimpleNamespace(lean_json=lambda: "{}"), self.d / "c")
        self.assertTrue(recs[1].get("diagnosis_error"))
        self.assertIn("diagnosis did not run", " ".join(review.cert_unusable(1, d, recs[1])))

    def test_a_concept_harness_failure_defers_at_certificate(self):
        from harness.lean import render_formula
        from harness.model.blueprint import ConceptRecord
        self.run.opts.ontology = paths.REPO / "ontology" / "ATOMS_train.md"
        self.run.all_concepts = lambda: {}
        rec = ConceptRecord({"concept_id": "drv.test.c", "contract": "c holds", "kind": "formula", "args": [{"name": "u", "sort": "track"}],
                             "params": [], "elements": []})
        saved = (render_formula.render_concept, review.session.run_tools, review.execute_concept_divergences)
        render_formula.render_concept = lambda *_a, **_kw: "the rendering"

        def broken(*_a, **_kw):
            raise review.HarnessFailure("the concept review harness did not run")
        review.execute_concept_divergences = broken
        good = {"kind": "holds_wrongly", "contract_verdict": "fails", "contract_words": "c holds", "situation": "s",
                "instance": {"literals": {}, "params": {}}, "grounding": {"u": 1}, "trace": {"scenes": [{"t": 0}]}}
        review.session.run_tools = scripted_reviewer([submit({"verdict": "return", "divergences": [good], "not_general": [], "advisories": []})])
        try:
            out = review.review_concept(self.run, rec, {"reads": [], "body_json": {}}, self.d)
        finally:
            render_formula.render_concept, review.session.run_tools, review.execute_concept_divergences = saved
        self.assertEqual((out.status, out.defer_stage), ("deferred", "certificate"))


class SessionRecords(ToolSession):
    """The usage rows of a tool session name the subject and the launch; a refused request keeps
    its reason; a quantity skeleton's closing brace is never commented out."""
    test_each_request_is_recorded_and_the_conversation_sent_back = None
    test_a_pause_after_earlier_requests_keeps_their_usage = None
    test_a_failed_request_relaunches_then_the_session_is_unavailable = None
    test_only_function_tools_are_admitted = None

    def test_labels_and_reasons(self):
        self.oai.request = lambda items, **kw: (1, {"error": "APIError: overloaded"}, False)
        with self.assertRaises(self.session.SessionUnavailable) as e:
            self.session.run_tools("p", self.d, self.opts, self.Tools(), label="review_behaviour", effort="high", model="gpt-x",
                                   subject="L_1_o1")
        self.assertIn("overloaded", str(e.exception))
        self.assertEqual([r["label"] for r in self.usage()], ["review_behaviour:L_1_o1:L1.r1", "review_behaviour:L_1_o1:L2.r1"])
        stream = (self.d / "review_behaviour.jsonl").read_text()
        self.assertIn('"type": "error"', stream)

    def test_a_key_is_masked(self):
        self.assertNotIn("abcdef123456", self.oai.sanitized(RuntimeError("bad key sk-abcdef123456 given")))

    def test_quantity_skeleton_brace(self):
        from harness.lean import skeleton
        from harness.model.blueprint import ConceptRecord
        rec = ConceptRecord({"concept_id": "drv.motion.test_quantity", "contract": "q", "kind": "quantity", "args": [{"name": "u", "sort": "track"}],
                             "params": [], "elements": []})
        lines = skeleton.concept_witness_skeleton(rec).splitlines()
        i = next(i for i, l in enumerate(lines) if "bounds :=" in l)
        self.assertEqual(lines[i + 1].strip(), "}")


class CaseTimeline(unittest.TestCase):
    """Revision 28, part 3: the same case in time order, with nothing added."""
    @staticmethod
    def atom(name, *args):
        return {"atom": name, "args": [{"var": a} for a in args], "params": []}

    @staticmethod
    def sec(x):
        return {"lit": {"num": int(x * 10), "den": 10}, "unit": "second"}

    def time_is(self, op, x):
        return {"cmp": op, "lhs": {"measure": "kin_time", "args": []}, "rhs": self.sec(x)}

    def render(self, case, at=22000, times=None):
        from harness.lean import render_formula
        return render_formula.timeline(case, at, {}, times)

    def test_window_behind_and_ahead(self):
        t = self.render({"and": [{"holds_for": "time", "length": self.sec(10), "subject": "v", "body": self.atom("p", "v")},
                                 {"within": "time", "length": self.sec(5), "subject": "v", "body": self.atom("q", "v")}]})
        self.assertIn("From t = 12 s to t = 22 s:\n  - at every observation: `p`", t)
        self.assertIn("From t = 22 s to t = 27 s:\n  - at some observation of this stretch, all together: `q`", t)

    def test_a_time_test_splits_a_window(self):
        t = self.render({"holds_for": "time", "length": self.sec(15), "subject": "v",
                         "body": {"implies": [self.time_is("ge", 15), self.atom("on_straight", "v")]}})
        self.assertIn("From t = 15 s to t = 22 s:\n  - at every observation: `on_straight`", t)
        self.assertNotIn("From t = 7 s", t)

    def test_some_observation_at_an_instant(self):
        t = self.render({"not": {"holds_for": "time", "length": self.sec(15), "subject": "v",
                                 "body": {"not": {"and": [self.time_is("eq", 7.5), self.atom("on_bend", "v")]}}}})
        self.assertIn("At t = 7.5 s:\n  - at that observation: `on_bend`", t)

    def test_rises_names_the_previous_observation(self):
        t = self.render({"rises": self.atom("p", "v")}, times=[21000, 21500, 22000])
        self.assertIn("At t = 21.5 s:\n  - it is not the case that (`p`", t)
        self.assertIn("At t = 22 s (the observation judged):\n  - `p`", t)

    def test_logic_is_kept_under_a_window(self):
        t = self.render({"holds_for": "time", "length": self.sec(4), "subject": "v",
                         "body": {"and": [{"not": self.atom("p", "v")}, {"or": [self.atom("q", "v"), self.atom("r", "v")]},
                                          {"implies": [self.atom("s", "v"), self.atom("u", "v")]}]}})
        self.assertIn("at every observation: it is not the case that (`p`", t)
        self.assertIn("OR", t)
        self.assertIn("IMPLIES", t)                                       # a conditional not about time stays one

    def test_an_unplaceable_form_marks_the_section_partial(self):
        nested = {"holds_for": "time", "length": self.sec(10), "subject": "v",
                  "body": {"holds_for": "time", "length": self.sec(2), "subject": "v", "body": self.atom("p", "v")}}
        for case in (nested, {"since": [self.atom("p", "v"), self.atom("q", "v")]}):
            t = self.render(case)
            self.assertIn("full statement above is authoritative", t)
            self.assertIn("At t = 22 s (the observation judged)", t)

    def test_an_entity_keeps_its_name_in_every_interval(self):
        t = self.render({"and": [{"holds_for": "time", "length": self.sec(10), "subject": "v", "body": self.atom("occ", "v", "lane")},
                                 self.atom("occ", "v", "lane")]})
        self.assertEqual(t.count("`v`, `lane`"), 2)

    def test_nothing_is_added(self):
        import json as _json, re as _re
        rows = [_json.loads(l) for l in (paths.REPO / "results" / "smoke18" / "rulings.jsonl").read_text().splitlines()] \
            if (paths.REPO / "results" / "smoke18" / "rulings.jsonl").exists() else []
        cases = [r for r in rows if r.get("case") not in (None, "tt", "ff")]
        for r in cases:
            t = self.render(r["case"], r["at"], [s["t"] for s in r["trace"]["scenes"]])
            t = "\n".join(t.splitlines()[1:])                               # the facts, not the heading
            names = set(_re.findall(r"`([^`]+)`", t)) - {"v"}
            self.assertTrue(names <= set(_re.findall(r'"([A-Za-z_][\w.]*)"', _json.dumps(r["case"]))) | {"u", "c"},
                            names - set(_re.findall(r'"([A-Za-z_][\w.]*)"', _json.dumps(r["case"]))))


class TwoPasses(unittest.TestCase):
    """Revision 29: two independent reviewer sessions per rule review, their challenges joined."""
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.run = FakeRun(Path(self.tmp.name))
        self.run.opts.max_divergences, self.run.opts.review_passes = 3, 2
        self.run.all_concepts = lambda: {}
        self.saved = (review.build_context, review.replay_upheld, review.judge_divergence, review.certify, review.append_ruling,
                      review.session.run_tools)
        review.build_context = lambda *_a, **_kw: ctx()
        review.replay_upheld = lambda *_a, **_kw: ([], [], [])
        review.append_ruling = lambda *_a, **_kw: None
        self.certs, self.judged = {"s": cert(rule="compliant")}, []
        review.certify = lambda _r, _n, divs, _rd, _o: {k: {**self.certs[d["situation"]], "canonical_case": d["situation"]}
                                                         for k, d in divs.items() if d["situation"] in self.certs}

        def judge(_run, _n, _ctx, _onto, d, c, *_a, **_kw):
            self.judged.append(d["situation"])
            return SimpleNamespace(route="upheld", line=f"upheld {d['situation']}", key="k", question="q", row={})
        review.judge_divergence = judge

    def tearDown(self):
        (review.build_context, review.replay_upheld, review.judge_divergence, review.certify, review.append_ruling,
         review.session.run_tools) = self.saved
        self.tmp.cleanup()

    @staticmethod
    def answer(*divs, verdict=None):
        return {"verdict": verdict or ("return" if divs else "accept"), "divergences": list(divs), "advisories": [], "gap_candidates": []}

    def review(self, by_pass: dict):
        def run_tools(prompt, out_dir, opts, tools, label="", **_kw):
            k = int(label.rsplit("_p", 1)[1])
            calls = by_pass.get(k, [])
            if isinstance(calls, BaseException):
                raise calls
            tools.reset()
            for name, args in calls:
                if tools.done:
                    break
                tools.call(name, args)
            return {"code": 0}
        review.session.run_tools = run_tools
        return review.review_behaviour(self.run, node(), LAW, ONTO, SimpleNamespace(data={"params": []}), {}, [], Path(self.tmp.name))

    def test_a_find_by_either_pass_alone_returns_the_rule(self):
        for found_by in (1, 2):
            self.judged = []
            other = 3 - found_by
            out = self.review({found_by: [submit(self.answer(div()))], other: [submit(self.answer())]})
            self.assertEqual((out.status, self.judged), ("returned", ["s"]))

    def test_an_identical_divergence_is_judged_once(self):
        out = self.review({1: [submit(self.answer(div()))], 2: [submit(self.answer(div()))]})
        self.assertEqual((out.status, self.judged), ("returned", ["s"]))

    def test_distinct_divergences_of_both_passes_are_all_judged(self):
        self.certs["t"] = cert(rule="compliant")
        out = self.review({1: [submit(self.answer(div()))], 2: [submit(self.answer(div(situation="t", at=5, trace={"scenes": [{"t": 5}]})))]})
        self.assertEqual((out.status, sorted(self.judged)), ("returned", ["s", "t"]))

    def test_a_pass_with_no_answer_is_dropped(self):
        out = self.review({1: [("check_divergence", {"divergence": div()})], 2: [submit(self.answer(div()))]})
        self.assertEqual(out.status, "returned")
        self.assertTrue(any("pass 1 submitted no answer" in a for a in out.advisories))

    def test_no_pass_answering_defers(self):
        out = self.review({1: [], 2: []})
        self.assertEqual((out.status, out.defer_stage), ("deferred", "reviewer"))

    def test_the_cap_holds_per_pass_not_for_the_join(self):
        for x in ("t", "u", "w", "y", "z"):
            self.certs[x] = cert(rule="compliant")
        four = [div(situation=x, at=i, trace={"scenes": [{"t": i}]}) for i, x in enumerate(("t", "u", "w", "y"), 1)]
        two = [div(situation=x, at=i, trace={"scenes": [{"t": i}]}) for i, x in enumerate(("s", "z"), 10)]
        out = self.review({1: [submit(self.answer(*four))] * 3, 2: [submit(self.answer(*two[:2]))]})
        self.assertEqual(out.status, "returned")                            # pass 1 over the cap is dropped, pass 2 stands
        self.assertEqual(sorted(self.judged), ["s", "z"])
        three = [div(situation=x, at=i, trace={"scenes": [{"t": i}]}) for i, x in enumerate(("t", "u", "w"), 20)]
        self.judged = []
        out = self.review({1: [submit(self.answer(*three))], 2: [submit(self.answer(*two))]})
        self.assertEqual((out.status, len(self.judged)), ("returned", 5))   # a join of five does not defer

    def test_an_unusable_divergence_still_defers_unless_upheld(self):
        self.certs["bad"] = {**cert(), "lint_errors": ["x"]}
        review.judge_divergence = lambda *_a, **_kw: SimpleNamespace(route="dismissed_permitted_reading", line="d", key="k", question="", row={})
        out = self.review({1: [submit(self.answer(div(situation="bad")))] * 3, 2: [submit(self.answer(div()))]})
        self.assertEqual((out.status, out.defer_stage), ("deferred", "reviewer"))

    def test_a_budget_pause_in_one_pass_propagates(self):
        from harness.store.budget import BudgetPaused
        with self.assertRaises(BudgetPaused):
            self.review({1: [submit(self.answer())], 2: BudgetPaused("over")})

    def test_each_pass_keeps_its_own_evidence(self):
        runs = []
        review.certify = lambda _r, _n, divs, _rd, out: runs.append(Path(out).relative_to(self.tmp.name).as_posix()) or \
            {k: {**cert(rule="compliant"), "canonical_case": "x"} for k in divs}
        self.review({1: [("check_divergence", {"divergence": div()}), submit(self.answer(div()))],
                     2: [("check_divergence", {"divergence": div()}), submit(self.answer(div()))]})
        self.assertEqual(sorted(runs), ["pass1/checks/L1/001", "pass2/checks/L1/001"])


class CodeReviewFixes(unittest.TestCase):
    """The defects an independent review found in revisions 28 and 29, each pinned."""
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.run = FakeRun(Path(self.tmp.name))
        self.run.opts.max_divergences = 3
        self.run.all_concepts = lambda: {}
        self.saved = (review.build_context, review.replay_upheld, review.judge_divergence, review.certify, review.append_ruling,
                      review.session.run_tools)
        review.build_context = lambda *_a, **_kw: ctx()
        review.replay_upheld = lambda *_a, **_kw: ([], [], [])
        review.append_ruling = lambda *_a, **_kw: None
        self.certs, self.judged = {"s": cert(rule="compliant")}, []
        review.certify = lambda _r, _n, divs, _rd, _o: {k: {**self.certs[d["situation"]], "canonical_case": "same"}
                                                         for k, d in divs.items() if d["situation"] in self.certs}

        def judge(_run, _n, _ctx, _onto, d, c, *_a, **_kw):
            self.judged.append(d["situation"])
            return SimpleNamespace(route="dismissed_permitted_reading", line="d", key="k", question="", row={})
        review.judge_divergence = judge

    def tearDown(self):
        (review.build_context, review.replay_upheld, review.judge_divergence, review.certify, review.append_ruling,
         review.session.run_tools) = self.saved
        self.tmp.cleanup()

    def review(self, by_pass: dict, passes=2):
        self.run.opts.review_passes = passes
        def run_tools(prompt, out_dir, opts, tools, label="", **_kw):
            k = int(label.rsplit("_p", 1)[1])
            tools.reset()
            for name, args in by_pass.get(k, []):
                if tools.done:
                    break
                tools.call(name, args)
        review.session.run_tools = run_tools
        return review.review_behaviour(self.run, node(), LAW, ONTO, SimpleNamespace(data={"params": []}), {}, [], Path(self.tmp.name))

    @staticmethod
    def answer(*divs):
        return {"verdict": "return", "divergences": list(divs), "advisories": [], "gap_candidates": []}

    def test_an_uncertified_challenge_is_never_merged_away(self):
        unstatable = {k: v for k, v in div().items() if k not in ("case", "entities", "at")}
        unstatable["unstatable"] = "words"
        bad = div(lawful_verdict="nonsense")                                   # the same situation, a schema defect
        for passes in (1, 2):
            out = self.review({1: [submit(self.answer(unstatable, bad))] * 3, 2: [submit(self.answer(unstatable, bad))] * 3}, passes)
            self.assertEqual((out.status, out.defer_stage), ("deferred", "reviewer"), passes)

    def test_an_unusable_copy_never_hides_a_usable_challenge(self):
        self.certs["bad"] = {**cert(), "case_value": {"value": "false"}}
        out = self.review({1: [submit(self.answer(div(situation="bad")))] * 3, 2: [submit(self.answer(div()))]})
        self.assertIn("s", self.judged)                                       # pass 2's usable challenge is judged

    def test_null_lists_do_not_crash(self):
        a = {**self.answer(div()), "gap_candidates": None, "advisories": None}
        out = self.review({1: [submit(a)] * 3, 2: [submit(a)] * 3})
        self.assertIn(out.status, ("accepted", "deferred", "returned", "proceed_with_question"))

    def test_one_pass_behaves_as_before(self):
        out = self.review({1: [submit(self.answer(div()))]}, passes=1)
        self.assertEqual((out.status, self.judged), ("accepted", ["s"]))
        self.assertTrue(any("pass" not in a for a in out.advisories) or not out.advisories)


class ReplayFixes(Obligations):
    """The replay: only a case or trace reason invalidates; a rule unknown on the trace is judged;
    rows wait for the review's outcome; a parameter question keeps the case and reaches the operator."""
    test_wrong_repaired_regressed_and_resumed = None
    test_satisfaction_is_measured_against_stage_a = None
    test_an_invalidated_case_leaves_and_is_reported = None
    test_a_changed_law_verdict_the_rule_now_meets_is_re_adjudicated = None

    def test_a_rule_unknown_on_the_trace_does_not_invalidate(self):
        self.rule = "unknown"
        saved = review.certify
        review.certify = lambda _run, _n, divs, _rd, _out: {k: {**cert(rule="unknown", reasons=["absent_atom:st_sight_distance"]),
                                                                 "case_value": {"value": "true"}} for k in divs}
        try:
            reasons, _keys, notes = self.replay()
        finally:
            review.certify = saved
        self.assertFalse(any(x.startswith("obligation invalidated:") for x in notes))
        self.assertTrue(reasons)                                              # judged as a mismatch: still open

    def test_rows_wait_for_the_outcome(self):
        self.rule = "compliant"
        pending = []
        n = Node({"node_id": "L_1_o1", "law_refs": ["L-1"], "binders": [{"name": "v"}]})
        review.replay_upheld(self.run, n, None, ONTO, None, Path(self.tmp.name), pending, [])
        self.assertEqual(len(review._all_rows(self.run)), 1)                   # nothing recorded yet
        self.assertEqual([r.get("obligation") for r in pending], ["satisfied"])

    def test_a_parameter_question_keeps_the_case_and_asks(self):
        saved = review.judge_divergence
        review.judge_divergence = lambda *_a, **_kw: SimpleNamespace(route="parameter_question", line="the case", key="k", question="q?",
                                                                     row={"stage_a": {"verdict": "compliant"}})
        questions = []
        try:
            n = Node({"node_id": "L_1_o1", "law_refs": ["L-1"], "binders": [{"name": "v"}]})
            reasons, _keys, _notes = review.replay_upheld(self.run, n, None, ONTO, None, Path(self.tmp.name), None, questions)
        finally:
            review.judge_divergence = saved
        self.assertEqual((reasons, questions, self.states()), ([], ["q?"], [None]))


class StrictTimeBounds(CaseTimeline):
    """A strict time test leaves its end out, and a guard that holds at no instant states nothing."""
    test_window_behind_and_ahead = test_a_time_test_splits_a_window = test_some_observation_at_an_instant = None
    test_rises_names_the_previous_observation = test_logic_is_kept_under_a_window = None
    test_an_unplaceable_form_marks_the_section_partial = test_an_entity_keeps_its_name_in_every_interval = test_nothing_is_added = None

    def test_strict_bounds(self):
        t = self.render({"holds_for": "time", "length": self.sec(20), "subject": "v",
                         "body": {"and": [{"implies": [self.time_is("lt", 15), self.atom("on_bend", "v")]},
                                          {"implies": [self.time_is("ge", 15), self.atom("on_straight", "v")]}]}}, at=25000)
        self.assertIn("From t = 5 s to t = 15 s (not including it):\n  - at every observation: `on_bend`", t)
        self.assertIn("From t = 15 s to t = 25 s:\n  - at every observation: `on_straight`", t)

    def test_a_vacuous_guard_states_nothing(self):
        t = self.render({"holds_for": "time", "length": self.sec(10), "subject": "v",
                         "body": {"implies": [self.time_is("lt", 10), self.atom("stopped", "v")]}}, at=20000)
        self.assertNotIn("stopped", t)


class UnitTables(unittest.TestCase):
    """Every Core unit has an entry in every harness table that lists Core units (revision 31)."""
    def test_every_core_unit_is_in_every_table(self):
        from harness.model.units import FACTORS
        from harness.lean import skeleton
        from harness.checks import gate
        core = {v[0] for v in FACTORS.values()}
        for name, table in (("skeleton.PUNIT_OF_CORE", skeleton.PUNIT_OF_CORE), ("skeleton.UNITS_CTOR_OF_CORE", skeleton.UNITS_CTOR_OF_CORE),
                            ("gate.PUNIT_JSON", gate.PUNIT_JSON), ("review.UNIT_DIMS", review.UNIT_DIMS)):
            self.assertEqual(sorted(core - set(table)), [], name)

    def test_a_concept_with_a_per_metre_formal_gets_a_skeleton(self):
        from harness.lean import skeleton
        from harness.model.blueprint import ConceptRecord
        rec = ConceptRecord({"concept_id": "drv.road.test_curve", "contract": "c", "kind": "formula", "args": [{"name": "u", "sort": "track"}],
                             "params": [{"name": "tol", "unit": "1/m"}], "elements": []})
        self.assertIn(".perMetre", skeleton.concept_skeleton(rec))
        self.assertIn("Units.perMetre", skeleton.concept_witness_skeleton(rec))


class FieldTypes(unittest.TestCase):
    """Revision 32: every record field the code generator writes into Lean is type-checked by the
    validator, so a planner's wrong type is returned with a message instead of stopping the run."""
    NODE = {"node_id": "L_1_o1", "law_refs": ["L-1"], "subject": {"binder": "v", "class_elements": ["ru.motor_vehicle"]},
            "binders": [{"name": "v", "class_elements": ["ru.motor_vehicle"]}],
            "segmentation": [{"id": "s1", "role": "obligation", "text": "shall stop before the line"}],
            "elements": [{"span": "s1", "atoms": ["kin.speed"], "derived": [], "justification": "j"}],
            "operationalizations": [{"span": "s1", "standard": "safe", "concepts": [], "params": ["p.x"], "convention": "c", "surrogate": False}],
            "assumptions": [{"span": "s1", "id": "asm.a", "meaning": "m"}], "residues": [{"span": "s1", "why": "w", "scope": "none"}],
            "compositions": [], "narrowings": [], "params": ["p.x"], "applicability": "a", "obligation": "o",
            "scenarios": [{"name": "forbid", "expected": "violated", "narrative": "n"}]}
    CONCEPT = {"concept_id": "drv.motion.test_concept", "contract": "c holds", "kind": "formula", "definition": "d",
               "args": [{"name": "u", "sort": "track"}, {"name": "k", "sort": "literal", "values": ["left", "right"]}],
               "params": [{"name": "tol", "unit": "1/m"}], "elements": [], "residues": [], "literals": [],
               "scenarios": [{"name": "holds", "expected": "compliant", "narrative": "n"}]}

    @staticmethod
    def leaves(x, path=()):
        if isinstance(x, dict):
            for k, v in x.items():
                yield from FieldTypes.leaves(v, path + (k,))
        elif isinstance(x, list):
            if x and all(isinstance(y, str) for y in x):
                yield path
            for i, v in enumerate(x):
                yield from FieldTypes.leaves(v, path + (i,))
        elif isinstance(x, str):
            yield path

    @staticmethod
    def mutate(rec, path):
        import copy
        r = copy.deepcopy(rec); o = r
        for k in path[:-1]:
            o = o[k]
        o[path[-1]] = {"x": 1}
        return r

    def test_the_class_elements_case_is_returned_with_its_path(self):
        from harness.checks import validate_a
        bad = self.mutate(self.NODE, ("binders", 0, "class_elements", 0))
        errs = validate_a.field_type_errors("L_1_o1", bad, validate_a.NODE_FIELD_TYPES)
        self.assertEqual(errs, ["L_1_o1: `binders[0].class_elements` must be a list of strings, not a list holding dict"])
        self.assertEqual(validate_a.field_type_errors("L_1_o1", self.NODE, validate_a.NODE_FIELD_TYPES), [])

    def test_no_unchecked_field_can_stop_the_rule_generator(self):
        from harness.checks import validate_a
        from harness.lean import skeleton
        for path in set(self.leaves(self.NODE)):
            if path[0] == "node_id":
                continue                                                     # the identity, checked when the id is derived
            bad = self.mutate(self.NODE, path)
            if validate_a.field_type_errors("L_1_o1", bad, validate_a.NODE_FIELD_TYPES) or \
                    validate_a.shape_errors("L_1_o1", bad, ("segmentation", "elements", "operationalizations", "assumptions", "compositions",
                                                             "narrowings", "residues", "binders", "scenarios")):
                continue
            try:
                skeleton.rule_skeleton(Node(bad)); skeleton.witness_skeleton(Node(bad))
            except (TypeError, AttributeError, KeyError) as e:
                self.fail(f"{path}: an unchecked field stops the generator: {e!r}")

    def test_no_unchecked_field_can_stop_the_concept_generator(self):
        from harness.checks import validate_a
        from harness.lean import skeleton
        from harness.model.blueprint import ConceptRecord
        for path in set(self.leaves(self.CONCEPT)):
            if path[0] in ("concept_id", "kind"):
                continue                                                     # the identity and the kind, checked before
            bad = self.mutate(self.CONCEPT, path)
            if validate_a.field_type_errors("c", bad, validate_a.CONCEPT_FIELD_TYPES) or \
                    validate_a.shape_errors("c", bad, ("args", "params", "elements", "residues", "literals", "scenarios")):
                continue
            try:
                skeleton.concept_skeleton(ConceptRecord(bad)); skeleton.concept_witness_skeleton(ConceptRecord(bad))
            except (TypeError, AttributeError, KeyError) as e:
                self.fail(f"{path}: an unchecked field stops the generator: {e!r}")

if __name__ == "__main__":
    unittest.main()
