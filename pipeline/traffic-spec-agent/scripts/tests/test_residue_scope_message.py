"""A residue on a span that decides when the rule applies is rejected unless it is marked
`scope: none`, and the rejection names each way such a span is carried: an assumption only for a
legal region class or a calendar or clock condition, a declared intention or an observable reading
only where their rules allow, the nearest atoms with a gap, and the `scope: "none"` exception."""
import unittest

from harness.checks.validate_a import check_residue_scope
from harness.model.blueprint import Node


def node(residue: dict) -> Node:
    return Node({"node_id": "N_X", "law_refs": ["X"],
                 "segmentation": [{"id": "s1", "role": "condition", "text": "w"},
                                  {"id": "s2", "role": "obligation", "text": "v"}],
                 "residues": [residue]})


class ResidueScopeMessage(unittest.TestCase):
    def test_condition_residue_without_scope_none_is_rejected_with_the_carriers(self):
        errs = check_residue_scope(node({"span": "s1", "why": "w"}))
        self.assertEqual(len(errs), 1)
        msg = errs[0]
        self.assertIn("N_X: residue on span s1 (condition)", msg)
        self.assertIn("carried by an assumption only for a legal region class or a calendar or clock condition", msg)
        self.assertIn("by a declared intention or an observable reading only where their rules allow", msg)
        self.assertIn("mapped to its nearest atoms with a gap", msg)
        self.assertIn('carries `"scope": "none"` with a `why` saying why', msg)
        self.assertIn("adds no restriction (the duty is the same whether or not its words hold)", msg)
        self.assertNotIn("an assumption the trace declares", msg)

    def test_scope_none_and_obligation_residues_pass(self):
        self.assertEqual(check_residue_scope(node({"span": "s1", "scope": "none", "why": "w"})), [])
        self.assertEqual(check_residue_scope(node({"span": "s2", "why": "w"})), [])


if __name__ == "__main__":
    unittest.main()
