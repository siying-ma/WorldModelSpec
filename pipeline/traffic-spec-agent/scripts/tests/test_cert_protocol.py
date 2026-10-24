"""Development regression tests for `certificate-run/1`: what the harness accepts from the certificate program, and what
it tells the reviewer about a record whose prerequisites failed."""
import json
import unittest

from harness.phases import review


def line(k, **fields):
    rec = {"schema": review.CERT_SCHEMA, "divergence": k, "trace_decode_errors": [], "case_decode_errors": [],
           "canonical_case": "tt", "case_atoms": [], "lint_errors": [], "witness_errors": [], "case_check_errors": [],
           "case_value": {"value": "true", "unknown_reasons": []},
           "rule_result": {"verdict": "violated", "unknown_reasons": []}, "sensitivity_overrides": []}
    rec.update(fields)
    return "CERT\t" + json.dumps(rec)


class ParseCert(unittest.TestCase):
    def test_well_formed(self):
        got = review.parse_cert("noise\n" + line(1) + "\n" + line(2) + "\n", {1, 2})
        self.assertEqual(sorted(got), [1, 2])

    def test_missing(self):
        with self.assertRaises(review.HarnessFailure):
            review.parse_cert(line(1), {1, 2})

    def test_duplicate(self):
        with self.assertRaises(review.HarnessFailure):
            review.parse_cert(line(1) + "\n" + line(1), {1})

    def test_unexpected_number(self):
        with self.assertRaises(review.HarnessFailure):
            review.parse_cert(line(3), {1})

    def test_malformed(self):
        with self.assertRaises(review.HarnessFailure):
            review.parse_cert("CERT\t{not json", {1})

    def test_unknown_schema(self):
        with self.assertRaises(review.HarnessFailure):
            review.parse_cert(line(1).replace(review.CERT_SCHEMA, "certificate-run/0"), {1})

    def test_no_output_is_not_no_divergence(self):
        with self.assertRaises(review.HarnessFailure):
            review.parse_cert("", {1})


class Defects(unittest.TestCase):
    d = {"kind": "rule_permits_unlawful", "lawful_verdict": "violated"}

    def rec(self, **fields):
        return json.loads(line(1, **fields).split("\t", 1)[1])

    def test_trace_did_not_decode(self):
        c = self.rec(trace_decode_errors=["trace.scenes: empty"], lint_errors=None, witness_errors=None, case_value=None,
                     rule_result=None, sensitivity_overrides=None)
        errs = (review.cert_unusable(1, self.d, c) + review.cert_refutations(1, self.d, c))
        self.assertTrue(any("does not decode" in e for e in errs))

    def test_null_prerequisites_report_only_what_ran(self):
        c = self.rec(case_decode_errors=["case: required"], canonical_case=None, witness_errors=None, case_check_errors=None,
                     case_value=None, rule_result=None, sensitivity_overrides=None)
        errs = (review.cert_unusable(1, self.d, c) + review.cert_refutations(1, self.d, c))
        self.assertEqual(len(errs), 1)
        self.assertIn("the case does not decode", errs[0])

    def test_case_not_true(self):
        c = self.rec(case_value={"value": "false", "unknown_reasons": []}, rule_result=None)
        self.assertTrue(any("the case is false" in e for e in (review.cert_unusable(1, self.d, c) + review.cert_refutations(1, self.d, c))))

    def test_rule_unknown_for_the_trace(self):
        c = self.rec(rule_result={"verdict": "unknown", "unknown_reasons": ["absent_atom:kin_speed"]})
        self.assertTrue(any("incomplete" in e for e in (review.cert_unusable(1, self.d, c) + review.cert_refutations(1, self.d, c))))

    def test_unresolved_aggregate_is_not_a_trace_defect(self):
        c = self.rec(rule_result={"verdict": "unknown", "unknown_reasons": ["aggregate_unresolved:D-1::vehicle"]})
        self.assertEqual((review.cert_unusable(1, self.d, c) + review.cert_refutations(1, self.d, c)), [])

    def test_rule_gives_the_claimed_verdict(self):
        c = self.rec(rule_result={"verdict": "violated", "unknown_reasons": []})
        self.assertTrue(any("very verdict you claim" in e for e in (review.cert_unusable(1, self.d, c) + review.cert_refutations(1, self.d, c))))
        self.assertEqual(review.cert_unusable(1, self.d, c), [])              # evaluated, and refuted
        self.assertTrue(review.cert_refutations(1, self.d, c))

    def test_an_unevaluated_case_is_not_a_refutation(self):
        c = self.rec(lint_errors=["scene t=0: x"], rule_result={"verdict": "compliant", "unknown_reasons": []})
        self.assertTrue(review.cert_unusable(1, self.d, c))
        self.assertEqual(review.cert_refutations(1, self.d, c), [])


if __name__ == "__main__":
    unittest.main()
