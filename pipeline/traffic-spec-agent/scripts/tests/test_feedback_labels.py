"""`--feedback labels`: a gated node is accepted without the node behaviour review (its Stage A/B
never run), the concept review is untouched, the aggregate verifier has its own model, effort and
budget, and `--feedback review` behaves as before."""
import json
import tempfile
import unittest
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import patch

from harness import loop
from harness.phases import aggregate, review
from harness.store import budget
from harness.store.state import Options


def opts(**kw):
    return Options(run_id="t", laws=Path("l"), ontology=Path("o"), reading=Path("r"), **kw)


def run_with(**kw):
    return SimpleNamespace(opts=opts(**kw))


class NodeReviewUnderFeedback(unittest.TestCase):
    def test_labels_accept_a_gated_node_without_the_behaviour_review(self):
        def forbidden(*_a, **_k):
            raise AssertionError("the node behaviour review was called under feedback labels")
        with patch.object(review, "review_behaviour", forbidden):
            out = loop.node_review(run_with(feedback="labels"), None, None, None, None, SimpleNamespace(extras={}), Path("."))
        self.assertEqual(out.status, "accepted")
        self.assertIn("suspended", out.advisories[0])

    def test_review_still_runs_the_behaviour_review(self):
        called = []
        with patch.object(review, "review_behaviour", lambda *a, **k: called.append(a) or review.ReviewOutcome("returned")):
            out = loop.node_review(run_with(feedback="review"), "n", "law", "onto", "reading",
                                   SimpleNamespace(extras={"rule_json": {}, "narrowings_added": []}), Path("."))
        self.assertEqual((out.status, len(called)), ("returned", 1))

    def test_the_concept_review_is_not_touched_by_feedback(self):
        # the loop's concept path calls review.review_concept directly, whatever the feedback
        src = Path(loop.__file__).read_text()
        self.assertIn("review_phase.review_concept(", src)
        self.assertNotIn("feedback", src[src.index("review_phase.review_concept("):][:200])


class AggregateVerifier(unittest.TestCase):
    def test_its_own_model_and_effort(self):
        o = opts(reviewer_model="gpt-r", review_effort="high", aggregate_verifier_model="gpt-a",
                    aggregate_verifier_effort="medium")
        self.assertEqual(aggregate.verifier_of(o), ("gpt-a", "medium"))

    def test_the_reviewers_when_not_given(self):
        o = opts(reviewer_model="gpt-r", review_effort="high")
        self.assertEqual(aggregate.verifier_of(o), ("gpt-r", "high"))

    def test_its_budget_caps_only_its_requests(self):
        with tempfile.TemporaryDirectory() as td:
            prices = {"m": {"input_usd_per_million": 0, "cached_input_usd_per_million": 0, "output_usd_per_million": 1_000_000}}
            b = budget.Budget(Path(td) / "usage.jsonl", 100.0, prices, role_limits={budget.ROLE_AGGREGATE: 2.5})
            t1 = b.reserve("m", 0, 1, label="iter-001/aggregates/verify_x")            # $1
            b.settle(t1, {"label": "iter-001/aggregates/verify_x", "vendor": "openai", "model": "m", "cost_usd": 1.0})
            b.reserve("m", 0, 1, label="iter-001/aggregates/verify_y")                 # $1, in flight: $2 held
            with self.assertRaises(budget.BudgetPaused):
                b.reserve("m", 0, 1, label="iter-001/aggregates/verify_z")             # would be $3
            b.reserve("m", 0, 1, label="iter-001/code/concept_review")                 # another role is not capped


if __name__ == "__main__":
    unittest.main()


# ---------------------------------------------------------------------------------------------
# No other path reaches a node review, a node ruling or a node obligation under `labels`
# ---------------------------------------------------------------------------------------------
def _forbid(*names):
    """Patch every named review function to fail the test when called."""
    from contextlib import ExitStack
    stack = ExitStack()
    for name in names:
        def boom(*_a, _n=name, **_k):
            raise AssertionError(f"review.{_n} was called under feedback labels")
        stack.enter_context(patch.object(review, name, boom))
    return stack


NODE_REVIEW = ("review_behaviour", "obligations_of", "certify", "upheld_rows", "upheld_block", "replay_obligations")


class NoNodeReviewPath(unittest.TestCase):
    def test_admission_does_not_certify_node_obligations(self):
        import sys
        sys.path.insert(0, str(Path(__file__).resolve().parent))
        from harness.model.reading import Reading
        from harness.phases import integrate
        from test_library_compatibility import Results, N
        with Results() as r:
            r.run("A", laws=["L-1"], nodes={"L_1": {**N("L_1", "L-1"), "binders": []}},
                  rulings=[{"subject": "L_1", "ruling": "upheld", "iteration": 1, "stage_a": {"verdict": "violated"}}])
            run = r.load("B", "A", ["L-2"])
            run.opts.feedback = "labels"
            laws = loop.effective_laws(run, {})
            with _forbid(*NODE_REVIEW):
                ok, failing, unresolved = integrate.recheck_contexts(run, Reading(r.tmp / "none.json"), {"core": "c"}, laws)
            self.assertIn("L_1", ok)
            self.assertEqual((failing, unresolved), ([], []))

    def test_plan_and_repair_prompts_get_no_node_upheld_block(self):
        from harness.phases import plan
        with _forbid(*NODE_REVIEW):
            block = plan.node_upheld_block(run_with(feedback="labels"), {"L-1"})
        self.assertIn("(none)", block)
        with patch.object(review, "upheld_block", lambda *_a, **_k: "upheld here"):
            self.assertEqual(plan.node_upheld_block(run_with(feedback="review"), {"L-1"}), "upheld here")
        src = Path(plan.__file__).read_text()
        self.assertEqual(src.count("review_phase.upheld_block("), 1)          # only inside the guarded wrapper

    def test_the_plan_registration_looks_up_no_node_obligation(self):
        src = Path(loop.__file__).read_text()
        i = src.index("review_phase.upheld_rows(run, {law})")
        self.assertIn("if node_reviews(opts) else []", src[i:i + 200])
        self.assertEqual(src.count("review_phase.review_behaviour("), 1)      # only inside `node_review`


class StartupChecks(unittest.TestCase):
    def test_a_budget_must_be_finite_and_non_negative(self):
        for bad in (float("nan"), float("inf"), -1.0, True):
            with self.subTest(bad=bad), self.assertRaises(SystemExit):
                loop.check_options(opts(aggregate_verifier_budget_usd=bad))
        loop.check_options(opts(aggregate_verifier_budget_usd=5.0, claude_budget_usd=200))

    def test_the_aggregate_verifier_is_a_second_vendor_with_its_key(self):
        with self.assertRaises(SystemExit):
            loop.check_options(opts(model="claude-x", aggregate_verifier_model="claude-y"))
        from harness.agents import openai_runner
        with patch.object(openai_runner, "available", lambda: False), self.assertRaises(SystemExit):
            loop.check_options(opts(model="claude-x", aggregate_verifier_model="gpt-5"))
        with patch.object(openai_runner, "available", lambda: True):
            loop.check_options(opts(model="claude-x", aggregate_verifier_model="gpt-5"))
