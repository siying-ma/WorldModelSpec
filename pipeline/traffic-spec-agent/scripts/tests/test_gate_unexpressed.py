"""The gate tells words the coder reports it cannot state (`no_atom` / `no_operator`, the coder
stopped) from a narrowing it chose on a span that decides when the rule applies. A real scope
narrowing is `SCOPE_NARROWED`, the unstatable words listed beside it; with none, unstatable words
are `UNEXPRESSED`, carried in its extras for the gap route, on a scope span as on an obligation
span. An observable reading the plan declared on a scope span is the plan's, never a narrowing.
The candidate runs on real Lean; the tests are skipped, and so not verified, where the toolchain
or the built Core is absent."""
import unittest

from scripts.tests import test_gate_phases as G
from scripts.tests import test_precondition_continuity as P

TAIL = "    obligation := obligation }"
NO_ATOM_C1 = ("c1", "no_atom", "no atom states a sign that governs the stretch")
READING_C1 = ("c1", "reading", "read as a full halt only")
NO_ATOM_O1 = ("o1", "no_atom", "no atom states the manner of proceeding")
OBS_C1 = ("c1", "observable_reading", "read as the measured speed at zero")


def rule_with(*narrowings: tuple[str, str, str]) -> str:
    """The fixture rule declaring `narrowings`, each ⟨span, kind, why⟩."""
    assert P.RULE.count(TAIL) == 1
    items = ", ".join(f'{{ span := "{s}", why := "{w}", kind := "{k}" }}' for s, k, w in narrowings)
    return P.RULE.replace(TAIL, f"    obligation := obligation\n    narrowings := [{items}] }}")


def line(n: tuple[str, str, str]) -> str:
    return f"{n[0]} ({n[1]}): {n[2]}"


@unittest.skipUnless(P.TOOLCHAIN, P.SKIP)
class UnstatableWords(unittest.TestCase):

    def gate(self, *narrowings, edit=None):
        v, _out, _phases = G.node_gate(rule=rule_with(*narrowings), edit=edit)
        return v

    def test_a_condition_span_the_coder_cannot_state_is_unexpressed(self):
        v = self.gate(NO_ATOM_C1)
        self.assertEqual(v.verdict, "UNEXPRESSED", v.details)
        self.assertIn(line(NO_ATOM_C1), v.details)
        self.assertEqual([(u["span"], u["kind"]) for u in v.extras["unexpressed"]], [("c1", "no_atom")])

    def test_a_condition_span_the_coder_narrows_is_scope_narrowed(self):
        v = self.gate(READING_C1)
        self.assertEqual(v.verdict, "SCOPE_NARROWED", v.details)
        self.assertIn(f"narrowing on c1 (condition): {READING_C1[2]}", v.details)
        self.assertEqual(v.extras, {})

    def test_unstatable_words_do_not_mask_a_scope_narrowing_beside_them(self):
        v = self.gate(NO_ATOM_C1, READING_C1)
        self.assertEqual(v.verdict, "SCOPE_NARROWED", v.details)
        self.assertIn(f"narrowing on c1 (condition): {READING_C1[2]}", v.details)
        self.assertIn("also reported as not statable: " + line(NO_ATOM_C1), v.details)
        self.assertNotIn(f"narrowing on c1 (condition): {NO_ATOM_C1[2]}", v.details)   # reported, not counted as a narrowing

    def test_unstatable_words_left_alone_after_the_narrowing_is_removed_reach_the_gap_route(self):
        first = self.gate(NO_ATOM_C1, READING_C1)
        self.assertEqual(first.verdict, "SCOPE_NARROWED", first.details)
        self.assertIn(f"narrowing on c1 (condition): {READING_C1[2]}", first.details)
        self.assertIn("also reported as not statable: " + line(NO_ATOM_C1), first.details)
        second = self.gate(NO_ATOM_C1)                    # the repair drops the narrowing, the no_atom kept as it was
        self.assertEqual(second.verdict, "UNEXPRESSED", second.details)
        self.assertEqual([(u["span"], u["kind"], u["why"]) for u in second.extras["unexpressed"]], [NO_ATOM_C1])

    def test_an_obligation_span_the_coder_cannot_state_is_unexpressed(self):
        v = self.gate(NO_ATOM_O1)
        self.assertEqual(v.verdict, "UNEXPRESSED", v.details)
        self.assertIn(line(NO_ATOM_O1), v.details)
        self.assertEqual([(u["span"], u["kind"]) for u in v.extras["unexpressed"]], [("o1", "no_atom")])

    def test_unstatable_obligation_words_are_listed_beside_a_scope_narrowing(self):
        v = self.gate(NO_ATOM_O1, READING_C1)
        self.assertEqual(v.verdict, "SCOPE_NARROWED", v.details)
        self.assertIn(f"narrowing on c1 (condition): {READING_C1[2]}", v.details)
        self.assertIn("also reported as not statable: " + line(NO_ATOM_O1), v.details)

    def plan_reads_c1(self, rec):
        rec["narrowings"] = [{"span": "c1", "kind": "observable_reading", "why": "read as the measured speed"}]

    def test_a_planned_observable_reading_on_a_scope_span_is_no_narrowing(self):
        v = self.gate(OBS_C1, edit=self.plan_reads_c1)
        self.assertEqual(v.verdict, "OK", v.details)

    def test_a_planned_observable_reading_beside_unstatable_words_is_unexpressed(self):
        v = self.gate(OBS_C1, NO_ATOM_C1, edit=self.plan_reads_c1)
        self.assertEqual(v.verdict, "UNEXPRESSED", v.details)
        self.assertEqual([(u["span"], u["kind"]) for u in v.extras["unexpressed"]], [("c1", "no_atom")])

    def test_an_unplanned_observable_reading_on_a_scope_span_is_scope_narrowed(self):
        v = self.gate(OBS_C1)
        self.assertEqual(v.verdict, "SCOPE_NARROWED", v.details)


if __name__ == "__main__":
    unittest.main()
