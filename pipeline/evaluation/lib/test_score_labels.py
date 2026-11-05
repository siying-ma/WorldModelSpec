"""Offline checks for joining the monitor's verdicts and scoring them against labels."""
import contextlib
import io
import json
from pathlib import Path
import tempfile
import unittest

from score_labels import join, main, rule_verdicts


def report(rules, rows):
    lines = [{"kind": "source"}] + [{"kind": "rule", "rule": r, "support": s, "surrogate": r.endswith("o2")} for r, s in rules] + \
            [{"kind": "grounding", "rule": r, "episode": {"verdict": v, "reasons": []}} for r, v in rows]
    return "\n".join(json.dumps(l) for l in lines) + "\n"


class ScoreTests(unittest.TestCase):
    def test_join_order(self):
        self.assertEqual(join(["compliant", "violated", "unknown"]), "violated")
        self.assertEqual(join(["compliant", "unknown", "not_applicable"]), "unknown")
        self.assertEqual(join(["not_applicable", "compliant"]), "compliant")
        self.assertEqual(join([]), "not_applicable")

    def test_rule_verdicts(self):
        with tempfile.TemporaryDirectory() as tmp:
            p = Path(tmp) / "r.jsonl"
            p.write_text(report([("A", "supported"), ("B", "partial"), ("C", "unsupported")],
                                [("A", "compliant"), ("A", "violated"), ("B", "compliant")]))
            self.assertEqual(rule_verdicts(p), {"A": ("violated", False), "B": ("compliant", False), "C": ("unknown", False)})

    def test_law_joins_its_rules_and_labels_map(self):
        with tempfile.TemporaryDirectory() as tmp:
            tmp = Path(tmp)
            (tmp / "reports").mkdir()
            (tmp / "cases.csv").write_text("case_id,law_id,expected_label\n"
                                           "c1,L1,non_compliant\nc2,L1,compliant\nc3,L2,compliant\nc4,L1,unlabeled_judgment\n")
            (tmp / "registered.json").write_text(json.dumps({"rules": {"L1_o1": {"law": "L1"}, "L1_o2": {"law": "L1"}}}))
            (tmp / "reports/c1.jsonl").write_text(report([("L1_o1", "supported"), ("L1_o2", "supported")],
                                                         [("L1_o1", "compliant"), ("L1_o2", "violated")]))
            (tmp / "reports/c2.jsonl").write_text(report([("L1_o1", "supported"), ("L1_o2", "supported")],
                                                         [("L1_o1", "compliant")]))
            (tmp / "reports/c3.jsonl").write_text(report([("L1_o1", "supported")], [("L1_o1", "compliant")]))
            out = io.StringIO()
            with contextlib.redirect_stdout(out):
                main(tmp / "cases.csv", tmp / "reports", tmp / "registered.json")
            text = out.getvalue()
            self.assertIn("c1\tL1\tnon_compliant\tviolated\tyes\tyes", text)   # L1_o2 is a surrogate
            self.assertIn("c2\tL1\tcompliant\tcompliant\tyes", text)       # o2 has no grounding: not applicable
            self.assertIn("c3: no rule for L2", text)
            self.assertIn("c4: no report", text)
            self.assertIn("all\t2 / 2", text)


if __name__ == "__main__":
    unittest.main()
