"""Development regression tests for the second vendor's budget and strict, crash-safe audit files."""
import json
import tempfile
import threading
import unittest
from pathlib import Path

from harness.store import jsonl
from harness.store.budget import Budget, BudgetPaused, usage_row

PRICES = {"gpt-x": {"input_usd_per_million": 1.0, "cached_input_usd_per_million": 0.1, "output_usd_per_million": 10.0}}


class Reservation(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.f = Path(self.tmp.name) / "usage.jsonl"

    def tearDown(self):
        self.tmp.cleanup()

    def test_a_call_that_does_not_fit_is_refused(self):
        b = Budget(self.f, 1.0, PRICES)                  # worst case of one call: 3000 chars ≈ 1000 tokens + 64k output ≈ $0.641
        b.reserve("gpt-x", 3000, 64000)
        with self.assertRaises(BudgetPaused):
            b.reserve("gpt-x", 3000, 64000)

    def test_settling_releases_the_reservation_and_records_the_cost(self):
        b = Budget(self.f, 1.0, PRICES)
        t = b.reserve("gpt-x", 3000, 64000)
        usage = {"input_tokens": 1000, "input_tokens_details": {"cached_tokens": 0}, "output_tokens": 1000}
        b.settle(t, usage_row("r", "openai", "gpt-x", "high", usage, b.cost("gpt-x", usage)))
        self.assertAlmostEqual(b.spent, 0.011)
        b.reserve("gpt-x", 3000, 64000)                  # fits again
        self.assertEqual([r["state"] for r in jsonl.read_strict(self.f)], ["pending", "settled", "pending"])

    def test_spending_survives_a_restart(self):
        b = Budget(self.f, 1.0, PRICES)
        b.settle(None, usage_row("r", "openai", "gpt-x", "high", {}, 0.5))
        self.assertAlmostEqual(Budget(self.f, 1.0, PRICES).spent, 0.5)

    def test_an_unsettled_request_counts_at_its_reservation(self):
        b = Budget(self.f, 10.0, PRICES)
        b.reserve("gpt-x", 3000, 64000)                  # the process ends during the call
        again = Budget(self.f, 10.0, PRICES)
        self.assertAlmostEqual(again.spent, 0.641, places=3)
        self.assertEqual(len(again.unresolved), 1)

    def test_a_failed_settlement_write_counts_nothing(self):
        b = Budget(self.f, 10.0, PRICES)
        t = b.reserve("gpt-x", 3000, 64000)
        saved = jsonl.append_atomic
        jsonl.append_atomic = lambda *a: (_ for _ in ()).throw(OSError("disk full"))
        try:
            with self.assertRaises(OSError):
                b.settle(t, usage_row("r", "openai", "gpt-x", "high", {}, 0.5))
        finally:
            jsonl.append_atomic = saved
        self.assertEqual(b.spent, 0)                     # and the pending row still counts it on recovery
        self.assertAlmostEqual(Budget(self.f, 10.0, PRICES).spent, 0.641, places=3)

    def test_workers_cannot_all_cross_the_remainder(self):
        b = Budget(self.f, 2.0, PRICES)                  # three worst cases fit, the fourth does not
        got, refused = [], []

        def worker():
            try:
                got.append(b.reserve("gpt-x", 3000, 64000))
            except BudgetPaused:
                refused.append(1)
        ts = [threading.Thread(target=worker) for _ in range(8)]
        for t in ts:
            t.start()
        for t in ts:
            t.join()
        self.assertEqual((len(got), len(refused)), (3, 5))

    def test_no_price_no_call(self):
        with self.assertRaises(BudgetPaused):
            Budget(self.f, None, {}).reserve("gpt-x", 10, 10)

    def test_claude_costs_count_under_claude_not_against_the_openai_limit(self):
        b = Budget(self.f, 0.0, PRICES)
        b.settle(None, usage_row("s", "anthropic", "claude", "high", {"input_tokens": 5}, 3.0))
        self.assertEqual((b.by_vendor["openai"], b.by_vendor["anthropic"]), (0.0, 3.0))


class StrictFiles(unittest.TestCase):
    def test_a_malformed_line_is_named(self):
        with tempfile.TemporaryDirectory() as d:
            f = Path(d) / "rulings.jsonl"
            f.write_text(json.dumps({"a": 1}) + "\n" + '{"truncated": \n')
            with self.assertRaises(jsonl.DataIntegrityError) as e:
                jsonl.read_strict(f)
            self.assertEqual(e.exception.line, 2)
            with self.assertRaises(jsonl.DataIntegrityError):     # a damaged file is never extended
                jsonl.append_atomic(f, {"b": 2})
            self.assertIn("truncated", f.read_text())             # and left as it was

    def test_append_is_whole(self):
        with tempfile.TemporaryDirectory() as d:
            f = Path(d) / "x.jsonl"
            for i in range(3):
                jsonl.append_atomic(f, {"i": i})
            self.assertEqual([r["i"] for r in jsonl.read_strict(f)], [0, 1, 2])
            self.assertEqual(sorted(p.name for p in Path(d).iterdir()), ["x.jsonl"])




class ScopeDigest(unittest.TestCase):
    """The files the harness writes while a coding session runs (usage, rulings, aggregates, and the
    temporary files of crash-safe writes) are outside the scope check's digest; a file of the run that
    is not the harness's stays in it."""
    def test_harness_files_are_skipped(self):
        from harness.checks import gate
        with tempfile.TemporaryDirectory() as d:
            run = Path(d) / "results" / "r"
            run.mkdir(parents=True)
            for name in ("usage.jsonl", "rulings.jsonl", "aggregate_certificates.jsonl", ".usage.jsonl.tmp-1-2", "stray.json"):
                (run / name).write_text("x")
            got = sorted(k for k in gate.repo_digest(Path(d)) if k.startswith("results/"))
            self.assertEqual(got, ["results/r/stray.json"])

    def test_offline_scratch_is_skipped_without_exempting_other_runs(self):
        from harness.checks import gate
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            for name in ("_verify", "_discarded", "_candidate", "r"):
                work = root / "results" / name
                work.mkdir(parents=True)
                (work / "witness_harness.lean").write_text("before")
            before = gate.repo_digest(root)
            for name in ("_verify", "_discarded"):
                (root / "results" / name / "witness_harness.lean").write_text("after")
            self.assertEqual(gate.repo_digest(root), before)
            for name in ("_candidate", "r"):
                self.assertIn(f"results/{name}/witness_harness.lean", before)
            (root / "results" / "r" / "witness_harness.lean").write_text("after")
            self.assertNotEqual(gate.repo_digest(root), before)

if __name__ == "__main__":
    unittest.main()
