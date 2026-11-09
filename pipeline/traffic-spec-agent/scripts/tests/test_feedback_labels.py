"""A gated node is decided by its gate: no path of the loop, the planner or the context check reaches
a node review, a node ruling or a node obligation; the aggregate verifier has its own model, effort
and budget; the startup checks refuse an unusable budget or verifier."""
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
# No path reaches a node review, a node ruling or a node obligation
# ---------------------------------------------------------------------------------------------
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
            laws = loop.effective_laws(run, {})
            ok, failing, unresolved = integrate.recheck_contexts(run, Reading(r.tmp / "none.json"), {"core": "c"}, laws)
            self.assertIn("L_1", ok)                            # a node's ruling row is no obligation: nothing certifies it
            self.assertEqual((failing, unresolved), ([], []))

    def test_the_node_review_is_gone(self):
        from harness.phases import integrate, plan
        for name in NODE_REVIEW:
            self.assertFalse(hasattr(review, name), name)
        for mod in (loop, plan, integrate):
            src = Path(mod.__file__).read_text()
            for name in NODE_REVIEW:
                self.assertNotIn(f"review_phase.{name}(", src, (mod.__name__, name))


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
