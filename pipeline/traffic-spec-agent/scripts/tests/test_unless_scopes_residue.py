"""An `unless` composition suspends the span it scopes where the composed rule applies; a span a
residue carries adds no restriction, so suspending it changes nothing and the composition is refused
(`validate_a.check_compositions`). An `unless` scoping a span an element carries, or one carrying a
`permits` case, passes."""
import unittest

from harness.checks import validate_a
from harness.model.blueprint import Node

TARGET = Node({"node_id": "T_OTHER", "law_refs": ["T-OTHER"], "binders": [{"name": "subject"}]})


def record(carrier: str) -> Node:
    """A node whose reference span r1 suspends its condition span c1 where `T_OTHER` applies; c1 is
    carried by `carrier` (a residue, an element, or an element with a `permits` case on it)."""
    raw = {"node_id": "N_SRC", "law_refs": ["N-SRC"], "binders": [{"name": "subject"}],
           "segmentation": [{"id": "o1", "role": "obligation", "text": "a driver shall keep clear"},
                            {"id": "c1", "role": "condition", "text": "but may pass a cyclist"},
                            {"id": "r1", "role": "reference", "text": "except as otherwise provided"}],
           "compositions": [{"span": "r1", "rule": "T_OTHER", "map": {"subject": "subject"}, "as": "unless", "scopes": "c1"}],
           "elements": [{"span": "o1", "atoms": ["kin.speed"]}], "residues": []}
    if carrier == "residue":
        raw["residues"].append({"span": "c1", "why": "it relaxes other rules and leaves this duty unchanged", "scope": "none"})
    else:
        raw["elements"].append({"span": "c1", "atoms": ["rel.longitudinal_overlap"]})
    if carrier == "permits":
        raw["cases"] = [{"name": "passing", "kind": "permits", "span": "c1", "situation": "passing a cyclist"}]
    return Node(raw)


def errors(n: Node) -> list[str]:
    return validate_a.check_compositions(n, {"T_OTHER": TARGET, "N_SRC": n})


class UnlessScopingAResidue(unittest.TestCase):
    def test_an_unless_scoping_a_residue_is_refused(self):
        got = errors(record("residue"))
        self.assertEqual(len(got), 1, got)
        self.assertIn("which a residue carries", got[0])
        self.assertIn("suspending it changes nothing", got[0])

    def test_an_unless_scoping_a_carried_span_passes(self):
        self.assertEqual(errors(record("element")), [])

    def test_an_unless_scoping_a_span_with_a_permits_case_passes(self):
        self.assertEqual(errors(record("permits")), [])


if __name__ == "__main__":
    unittest.main()
