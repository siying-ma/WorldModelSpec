"""The coder's worked example is a node its law's acceptance named, from a law the ledger holds
`accepted`, and unfenced: a node that only passed its gate, a node of a law still pending, failed
or re-planned, or a fenced version is never shown; with none left, the skeletons are the pattern.
The concept coder's example is a concept a review accepted: never a fenced version, never the
concept being coded, and inside a candidate never a version the candidate adds or changes."""
import tempfile
import unittest
from pathlib import Path
from types import SimpleNamespace as NS
from unittest import mock

from harness.model import nodeid
from harness.phases import code as code_phase
from harness.store import paths
from harness.store.ledger import Entry
from scripts.tests import test_candidate as tc


def rec(nid: str, law: str) -> dict:
    return {"node_id": nid, "law_refs": [law]}


class WorkedExample(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.lib = Path(self.tmp.name)
        self.addCleanup(self.tmp.cleanup)
        p = mock.patch.object(paths, "LIBRARY", self.lib)
        p.start()
        self.addCleanup(p.stop)
        for nid in ("A_1", "B_1", "C_1", "D_1"):
            for rel in (nodeid.rule_path(nid), nodeid.witness_path(nid)):
                f = self.lib / rel
                f.parent.mkdir(parents=True, exist_ok=True)
                f.write_text(f"-- {nid}\n", encoding="utf-8")

    def run_with(self, entries: dict, fenced=None):
        nodes = {n: rec(n, law) for n, law in (("A_1", "A-1"), ("B_1", "B-1"), ("C_1", "C-1"), ("D_1", "D-1"))}
        return NS(law_entries=entries, ledger_file=self.lib / "none.jsonl", accepted_nodes=nodes, fenced=fenced or {})

    def test_only_a_node_of_an_accepted_law(self):
        entries = {"A-1": Entry(law="A-1", state="accepted", nodes=["A_1"]),
                   "B-1": Entry(law="B-1", state="planned", nodes=["B_1"]),        # gate passed, law pending
                   "C-1": Entry(law="C-1", state="accepted", nodes=["C_2"]),       # accepted another version
                   "D-1": Entry(law="D-1", state="failed", nodes=["D_1"])}
        text = code_phase.worked_example(self.run_with(entries))
        self.assertIn("`A_1`", text)
        for other in ("B_1", "C_1", "D_1"):
            self.assertNotIn(other, text)

    def test_fenced_or_none_falls_back_to_skeletons(self):
        entries = {"A-1": Entry(law="A-1", state="accepted", nodes=["A_1"])}
        text = code_phase.worked_example(self.run_with(entries, fenced={"A_1": {"kind": "node"}}))
        self.assertIn("no node accepted yet", text)
        self.assertIn("no node accepted yet", code_phase.worked_example(self.run_with({})))

    def test_the_ledger_file_when_no_live_ledger_is_bound(self):
        run = self.run_with(None)
        run.ledger_file.write_text('{"law": "B-1", "state": "accepted", "nodes": ["B_1"]}\n', encoding="utf-8")
        self.assertIn("`B_1`", code_phase.worked_example(run))


class ConceptExample(tc.Base):
    def test_fenced_target_and_fallback(self):
        lib = Path(tempfile.mkdtemp()); self.addCleanup(lambda: __import__("shutil").rmtree(lib))
        with mock.patch.object(paths, "LIBRARY", lib):
            for cid in (tc.CA, tc.CB):
                for rel, text in tc.files("concept", cid).items():
                    (lib / rel).parent.mkdir(parents=True, exist_ok=True); (lib / rel).write_text(text, encoding="utf-8")
            run = NS(all_concepts=lambda: {tc.CA: tc.concept_rec(tc.CA), tc.CB: {**tc.concept_rec(tc.CB), "fenced": {"kind": "concept"}}})
            self.assertIn(f"`{tc.CA}`", code_phase.concept_example(run))                   # the fenced B is passed over
            self.assertIn("no concept accepted yet", code_phase.concept_example(run, tc.CA))   # A is the one being coded

    def test_a_candidates_unverified_versions_are_never_shown(self):
        concepts, nodes = tc.standard()
        with tc.world(concepts, nodes) as (run, lib):
            for cid in concepts:
                for rel, text in tc.files("concept", cid).items():
                    (lib / rel).parent.mkdir(parents=True, exist_ok=True); (lib / rel).write_text(text, encoding="utf-8")
            new = "drv.motion.cand_new"
            with tc.Txn(run) as txn:
                txn.apply([tc.cand.Change("concept", tc.CE, concepts[tc.CE], tc.files("concept", tc.CE, "v2")),   # its files only
                           tc.cand.Change("concept", new, tc.concept_rec(new), tc.files("concept", new))])
                with txn.inside():
                    shown = code_phase.concept_example(txn.view)
                self.assertIn(f"`{tc.CD}`", shown)                    # the latest version a review accepted before the candidate
                self.assertNotIn(tc.CE, shown)
                self.assertNotIn(new, shown)


if __name__ == "__main__":
    unittest.main()
