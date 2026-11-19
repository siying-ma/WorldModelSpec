"""The sampled duration (`durationWithin`) outside Lean: its step bound is held by the gate to the run's
acquisition-profile parameter exactly as `heading_since`'s is, a shared concept takes it through a
formal, the renderer says that the duration is the samples', and the `sampled_duration` mark the
monitor puts on a rule's line reaches each scored recording and is counted apart in the summary,
without moving it out of the figures it belongs to."""
import json
import unittest

from harness.checks import gate
from harness.lean import render_formula
from recorded import scoring
from harness.phases import label_check
from scripts.tests import test_label_check as T
from scripts.tests.test_acquisition_profile import PROFILE, REVIEWED, STEP, LIT_STEP, ONSET, reading_of


def dw(step, body=ONSET) -> dict:
    """A sampled duration over `body` with step bound `step`, compared by `gt`."""
    return {"duration_within": body, "length": {"param": "p.window"}, "step": step, "op": "gt", "bound": {"param": "p.bound"}}


class StepBound(unittest.TestCase):
    def test_the_profile_parameter_passes_and_an_alias_or_literal_is_refused(self):
        self.assertEqual(gate.rule_step_defects("N", {"obligation": {"not": dw({"param": STEP})}}, PROFILE, reading_of(REVIEWED)), [])
        out = gate.rule_step_defects("N", {"obligation": {"not": dw({"param": "p.my_step"})}}, PROFILE, reading_of(REVIEWED))
        self.assertEqual(len(out), 1)
        self.assertIn('a `duration_within` step bound is {"param": "p.my_step"}', out[0])
        self.assertIn("no literal, no other parameter, no expression",
                      gate.rule_step_defects("N", {"obligation": dw(LIT_STEP)}, PROFILE, reading_of(REVIEWED))[0])

    def test_without_a_profile_the_rule_is_refused_naming_the_operator(self):
        out = gate.rule_step_defects("N", {"obligation": dw({"param": STEP})}, None, reading_of(REVIEWED))
        self.assertEqual(len(out), 1)
        self.assertTrue(out[0].startswith("N: the rule reads `duration_within`, and the run names no acquisition profile"), out[0])
        self.assertTrue(out[0].endswith("no rule of this run may read `duration_within`"), out[0])

    def test_both_operators_are_collected(self):
        hs = {"heading_since": "v", "max_step": {"param": STEP}, "onset": ONSET}
        both = {"obligation": {"and": [dw({"param": STEP}), {"cmp": "ge", "lhs": hs, "rhs": hs}]}}
        self.assertEqual(sorted(op for op, _ in gate.step_bounds(both)), ["duration_within", "heading_since", "heading_since"])

    def test_a_concept_takes_the_step_through_a_formal(self):
        self.assertEqual(gate.concept_step_defects("drv.x.y", dw({"param": "s"}), ["s"]), [])
        out = gate.concept_step_defects("drv.x.y", dw(LIT_STEP), ["s"])
        self.assertEqual(len(out), 1)
        self.assertIn("a `duration_within` step bound is", out[0])


class Rendering(unittest.TestCase):
    def test_the_duration_is_the_samples(self):
        text = render_formula.formula(dw({"param": "p.step"}), {})
        self.assertIn("as the samples show it", text)
        self.assertIn("is more than `p.bound`", text)
        self.assertIn("decided only where every such count agrees", text)


def lines(sampled: bool, verdict: str = "compliant") -> list[str]:
    return [json.dumps(d) for d in (
        {"kind": "rule", "rule": "R1", "support": "supported", "absent": [], "abstractions": [], "partial_coverage": False,
         "sampled_duration": sampled},
        {"kind": "grounding", "rule": "R1", "grounding": {"x": 1}, "episode": {"verdict": verdict, "reasons": []},
         "sampled_duration": sampled},
        {"kind": "subject", "ego": [1], "binders": {"R1": "x"}})]


class Scoring(unittest.TestCase):
    def test_the_mark_is_kept_and_counted_apart(self):
        a = scoring.score("a", "L", "compliant", scoring.rule_results(lines(True)), {"R1": "L"})
        b = scoring.score("b", "M", "compliant", scoring.rule_results(lines(False)), {"R1": "M"})
        c = scoring.score("c", "L", "violated", scoring.rule_results(lines(True)), {"R1": "L"})
        self.assertEqual((a.status, a.sampled_duration), ("match", True))
        self.assertEqual((b.status, b.sampled_duration), ("match", False))
        self.assertTrue(a.to_dict()["rules"]["R1"]["sampled_duration"])
        s = scoring.summary([a, b, c])
        self.assertEqual((s["labelled"], s["matched"]), (3, 2))       # still in the figures they belong to
        self.assertEqual({k: s["sampled_duration"][k] for k in ("recordings", "labelled", "matched")},
                         {"recordings": 2, "labelled": 2, "matched": 1})
        self.assertIn("not a proof of the continuous state between frames", s["sampled_duration"]["note"])
        self.assertIn("not partial coverage", s["sampled_duration"]["note"])
        self.assertEqual(s["partial_coverage"]["labelled"], 0)        # the mark is no partial coverage

    def test_a_report_without_the_key_is_unmarked(self):
        old = [json.loads(l) for l in lines(True)]
        for d in old:
            d.pop("sampled_duration", None)
        x = scoring.score("a", "L", "compliant", scoring.rule_results(json.dumps(d) for d in old), {"R1": "L"})
        self.assertFalse(x.sampled_duration)


class LabelCheck(T._Fixture):
    def test_a_marked_law_shows_the_count_the_results_and_what_the_mark_means(self):
        spec = {**T.OK, "sampled": ["R1"]}
        c = self.check([("a", "L", "compliant", False, spec), ("b", "L", "compliant", False, spec)])
        self.assertEqual((c.outcome, c.scope, c.sampled_duration), ("aligned", "full", True))
        self.assertEqual(c.summary["labelled"], 2)                     # in the main figures
        self.assertEqual({k: c.summary["sampled_duration"][k] for k in ("recordings", "labelled", "matched")},
                         {"recordings": 2, "labelled": 2, "matched": 2})
        self.assertTrue(c.to_dict()["sampled_duration"])
        self.assertIn("not a proof of the continuous state between frames; this is not partial coverage",
                      label_check.render_evidence(c))

    def test_an_unmarked_law_lists_none(self):
        c = self.check([("a", "L", "compliant", False, T.OK)])
        self.assertFalse(c.sampled_duration)
        self.assertEqual(c.summary["sampled_duration"]["recordings"], 0)
        self.assertNotIn("durationWithin", label_check.render_evidence(c))


if __name__ == "__main__":
    unittest.main()
