"""The gap lifecycle: a gap is resolved only with a named resolution; a new round refuses while one
is open; resolved gaps leave the library for the results of the run that proposed them, written and
read back before the live rows go, idempotently; a record still reads a rejected gap it cites from
its run's archive; a gap that comes back is new; and a run's measurement is fixed as filed."""
import json
import tempfile
import unittest
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import patch

from harness.store import jsonl, paths
from harness.store.gaps import GapLedger, OpenGaps


def proposal(span="the words", law="L-1"):
    return {"kind": "atom", "span": span, "law_refs": [law], "node_id": "L_1", "proposal": "an atom"}


class Lifecycle(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name)
        self.gaps, self.results = self.root / "Gaps", self.root / "results"
        (self.results / "r1").mkdir(parents=True)
        self.patches = [patch.object(paths, "RESULTS", self.results)]
        for p in self.patches:
            p.start()
        self.ledger = GapLedger(self.gaps)

    def tearDown(self):
        for p in self.patches:
            p.stop()
        self.tmp.cleanup()

    def test_a_resolution_must_be_named(self):
        g = self.ledger.add(proposal(), "r1", 1)
        with self.assertRaises(SystemExit):
            self.ledger.decide(g, "retired", "carried now")
        with self.assertRaises(SystemExit):
            self.ledger.decide(g, "rejected", "not a gap")
        self.ledger.decide(g, "rejected", "not a gap", resolved_by="particular")
        self.assertEqual(self.ledger.rows[0]["resolved_by"], "particular")

    def test_a_new_round_refuses_an_open_gap(self):
        g = self.ledger.add(proposal(), "r1", 1)
        with self.assertRaises(OpenGaps):
            self.ledger.start_round(self.results)
        self.ledger.decide(g, "accepted", "a real gap")              # agreed, not yet carried: still open
        with self.assertRaises(OpenGaps):
            self.ledger.start_round(self.results)
        self.assertEqual(len(self.ledger.rows), 1)

    def test_resolved_gaps_leave_for_their_runs_results(self):
        a = self.ledger.add(proposal("a"), "r1", 1)
        b = self.ledger.add(proposal("b"), "r1", 2)
        self.ledger.decide(a, "accepted", "real")
        self.ledger.decide(a, "retired", "carried", retired_by="the ontology change that carries it")
        self.ledger.decide(b, "rejected", "carried as it is", resolved_by="the ontology's not-an-atom section")
        moved = self.ledger.start_round(self.results)
        self.assertEqual(sorted(moved), [(a, "r1"), (b, "r1")])
        self.assertEqual(self.ledger.rows, [])
        archived = {r["id"]: r for r in jsonl.read_strict(self.results / "r1" / "gaps.jsonl")}
        self.assertEqual([d["state"] for d in archived[a]["decisions"]], ["accepted", "retired"])   # the whole history
        self.assertEqual(archived[b]["resolved_by"], "the ontology's not-an-atom section")
        self.assertEqual(self.ledger.next_id(), "G3")                # ids are never reused

    def test_a_retried_round_writes_nothing_twice(self):
        a = self.ledger.add(proposal(), "r1", 1)
        self.ledger.decide(a, "retired", "carried", retired_by="the ontology change that carries it")
        row = {**self.ledger.rows[0], "decisions": jsonl.read_strict(self.ledger.decisions_file)}
        jsonl.append_atomic(self.results / "r1" / "gaps.jsonl", row)      # a crash after the archive, before the live rows went
        self.ledger.start_round(self.results)
        self.assertEqual(len(jsonl.read_strict(self.results / "r1" / "gaps.jsonl")), 1)
        self.assertEqual(self.ledger.rows, [])

    def test_an_archive_with_other_content_stops_the_round_untouched(self):
        a = self.ledger.add(proposal(), "r1", 1)
        self.ledger.decide(a, "retired", "carried", retired_by="the ontology change that carries it")
        jsonl.append_atomic(self.results / "r1" / "gaps.jsonl", {"id": a, "span": "something else"})
        with self.assertRaises(OpenGaps):
            self.ledger.start_round(self.results)
        self.assertEqual(len(self.ledger.rows), 1)

    def test_a_row_without_a_run_needs_a_manifest(self):
        jsonl.append_atomic(self.ledger.proposals_file, {"id": "G5", "kind": "atom", "span": "s", "law_refs": ["L-1"],
                                                         "proposed_in": "operator, from the plan of an earlier run"})
        jsonl.append_atomic(self.ledger.decisions_file, {"id": "G5", "state": "retired", "decision": "d", "retired_by": "x"})
        with self.assertRaises(OpenGaps) as e:
            self.ledger.start_round(self.results)
        self.assertIn("G5", str(e.exception))
        self.assertEqual(self.ledger.start_round(self.results, {"G5": "r1"}), [("G5", "r1")])

    def test_a_gap_that_comes_back_after_its_round_is_new(self):
        a = self.ledger.add(proposal(), "r1", 1)
        self.ledger.decide(a, "retired", "carried", retired_by="the ontology change that carries it")
        self.ledger.start_round(self.results)
        (self.results / "r2").mkdir()
        b = self.ledger.add(proposal(), "r2", 1)
        self.assertNotEqual(a, b)
        self.assertEqual(self.ledger.decision(b), None)

    def test_a_record_still_reads_the_rejected_gap_it_cites(self):
        a = self.ledger.add(proposal(), "r1", 1)
        self.ledger.decide(a, "rejected", "carried by the stop-line convention", resolved_by="ontology")
        record = {"narrowings": [{"span": "s1", "gap": a}]}
        self.ledger.start_round(self.results)
        later = GapLedger.for_run(self.gaps, SimpleNamespace(opts=SimpleNamespace(run_id="r2"), base_chain=["r1"]))
        self.assertIn(a, later.rejected())
        self.assertIn("carried by the stop-line convention", later.cited_block(record))
        fresh = GapLedger.for_run(self.gaps, SimpleNamespace(opts=SimpleNamespace(run_id="r3"), base_chain=[]))
        self.assertNotIn(a, fresh.rejected())                         # a fresh run is not shown old runs' catalogues
        self.assertEqual(fresh.render(), "(no gaps recorded)\n")

    def test_a_runs_measurement_is_fixed_as_filed(self):
        from harness.tools import score_split
        a = self.ledger.add({**proposal("reversing lamps"), "proposal": "sig.reverse_lamp"}, "r1", 1)
        split = self.root / "split_atoms.json"
        split.write_text(json.dumps({"test_only_atoms": ["sig.reverse_lamp"], "test_only_values": []}))
        with patch.object(paths, "GAPS_DIR", self.gaps):
            before = score_split.score("r1", split)
            self.ledger.decide(a, "retired", "restored", retired_by="the full split")
            self.ledger.start_round(self.results)
            after = score_split.score("r1", split)
        self.assertEqual([g["id"] for g in jsonl.read_strict(self.results / "r1" / "gaps_measured.jsonl")], [a])
        self.assertEqual(before, after)


    def score(self, run="r1"):
        from harness.tools import score_split
        split = self.root / "split_atoms.json"
        split.write_text(json.dumps({"test_only_atoms": ["sig.reverse_lamp"], "test_only_values": []}))
        with patch.object(paths, "GAPS_DIR", self.gaps):
            return score_split.score(run, split)

    def test_a_gap_filed_before_measurements_keeps_its_score_after_the_archive(self):
        jsonl.append_atomic(self.ledger.proposals_file, {"id": "G1", "kind": "atom", "span": "reversing lamps", "law_refs": ["L-1"],
                                                         "proposal": "sig.reverse_lamp", "proposed_in": "r1/iter-001"})
        jsonl.write_atomic(self.ledger.counter, "2\n")
        before = self.score()
        self.ledger.decide("G1", "retired", "restored", retired_by="the full split")
        self.ledger.start_round(self.results)
        self.assertEqual(self.score(), before)
        self.assertEqual(before["gaps_proposed"], 1)

    def test_a_filing_cut_off_before_its_measurement_is_completed_on_retry(self):
        p = {**proposal("reversing lamps"), "proposal": "sig.reverse_lamp"}
        with patch.object(GapLedger, "_measure", staticmethod(lambda row, run: (_ for _ in ()).throw(OSError("cut off")))):
            with self.assertRaises(OSError):
                self.ledger.add(p, "r1", 1)
        self.assertFalse((self.results / "r1" / "gaps_measured.jsonl").exists())
        gid = self.ledger.add(p, "r1", 1)                            # the retry finds the proposal and measures it
        self.assertEqual([g["id"] for g in jsonl.read_strict(self.results / "r1" / "gaps_measured.jsonl")], [gid])
        before = self.score()
        self.ledger.decide(gid, "retired", "restored", retired_by="the full split")
        self.ledger.start_round(self.results)
        self.assertEqual(self.score(), before)
        self.assertEqual(len(jsonl.read_strict(self.results / "r1" / "gaps_measured.jsonl")), 1)   # measured once


if __name__ == "__main__":
    unittest.main()
