"""The gate's scope check (`gate.scope_stray`) beside a concurrent coding session's atomic write.

Claude Code's Edit and Write tools write a file through a sibling `<file>.tmp.<pid>.<12 hex>` and
rename it over the file. While one task's session edits its own file, that sibling exists for a
moment beside it; a gate of another task that digests the tree at that moment sees it. The check
tolerates such a sibling only when its target is a file the checking task may see change: its own
files and the files its task directory lists (`concurrent.json`), or, inside a candidate
transaction, the candidate's declared write set alone. Every other changed file is still out of
scope. No model and no Lean toolchain is used."""
import json
import tempfile
import threading
import unittest
from pathlib import Path
from unittest import mock

from harness.checks import gate
from harness.store import paths

LIB = "library/TrafficSpec/Concepts/position"
A_RULE, A_WIT = f"{LIB}/reverse_travel.lean", f"{LIB}/reverse_travel_witness.lean"
B_RULE = f"{LIB}/direction_component.lean"
OTHER = f"{LIB}/unlisted.lean"
TMP = ".tmp.871211.c48d135072e5"           # the name observed on a run


class Tree:
    """A repository of four library files and a task directory for task A."""

    def __init__(self, t: str):
        self.root = Path(t) / "repo"
        self.work = Path(t) / "work"
        self.work.mkdir()
        for rel in (A_RULE, A_WIT, B_RULE, OTHER):
            (self.root / rel).parent.mkdir(parents=True, exist_ok=True)
            (self.root / rel).write_text("x")

    def put(self, rel: str, text: str = "partial") -> None:
        (self.root / rel).parent.mkdir(parents=True, exist_ok=True)
        (self.root / rel).write_text(text)

    def layout(self):
        return mock.patch.multiple(paths, REPO=self.root, **paths.library_layout(self.root / "library"))


class ConcurrentAtomicWrite(unittest.TestCase):

    def test_a_concurrent_edit_during_the_digest_is_not_a_violation(self):
        """Task B's session writes its atomic-write sibling and holds it there until task A's gate
        has digested the tree, then renames it over its file, as the Edit tool does."""
        with tempfile.TemporaryDirectory() as t:
            tree = Tree(t)
            (tree.work / "concurrent.json").write_text(json.dumps([B_RULE]))
            with tree.layout():
                baseline = gate.repo_digest()
                tree.put(A_RULE, "a's rule")
                written, digested = threading.Barrier(2, timeout=30), threading.Barrier(2, timeout=30)
                result: dict = {}

                def task_b():
                    tree.put(B_RULE + TMP, "b's edit")
                    written.wait()
                    digested.wait()
                    (tree.root / (B_RULE + TMP)).replace(tree.root / B_RULE)

                def task_a_gate():
                    written.wait()
                    result["stray"] = gate.scope_stray(baseline, {A_RULE, A_WIT}, tree.work)
                    result["sibling_seen"] = (tree.root / (B_RULE + TMP)).exists()
                    digested.wait()

                threads = [threading.Thread(target=task_b), threading.Thread(target=task_a_gate)]
                for th in threads:
                    th.start()
                for th in threads:
                    th.join(60)
                self.assertTrue(result["sibling_seen"])
                self.assertEqual(result["stray"], [])
                self.assertEqual(gate.scope_stray(baseline, {A_RULE, A_WIT}, tree.work), [])
                self.assertFalse((tree.root / (B_RULE + TMP)).exists())

    def test_the_task_own_files_sibling_is_tolerated(self):
        with tempfile.TemporaryDirectory() as t:
            tree = Tree(t)
            with tree.layout():
                baseline = gate.repo_digest()
                tree.put(A_RULE + TMP)
                self.assertEqual(gate.scope_stray(baseline, {A_RULE, A_WIT}, tree.work), [])

    def test_a_sibling_present_at_the_baseline_and_gone_is_tolerated(self):
        with tempfile.TemporaryDirectory() as t:
            tree = Tree(t)
            (tree.work / "concurrent.json").write_text(json.dumps([B_RULE]))
            with tree.layout():
                tree.put(B_RULE + TMP)
                baseline = gate.repo_digest()
                (tree.root / (B_RULE + TMP)).replace(tree.root / B_RULE)
                self.assertEqual(gate.scope_stray(baseline, {A_RULE, A_WIT}, tree.work), [])

    def test_malformed_names_are_violations(self):
        bad = [B_RULE + s for s in (".tmp.871211.c48d135072e",       # 11 hex digits
                                    ".tmp.871211.c48d135072e5f",     # 13 hex digits
                                    ".tmp.871211.C48D135072E5",      # upper case
                                    ".tmp.0871211.c48d135072e5",     # a leading zero
                                    ".tmp.pid.c48d135072e5",
                                    ".tmp..c48d135072e5",
                                    ".tmp.871211",
                                    ".tmp-871211-c48d135072e5",
                                    ".bak")]
        bad.append(f"{LIB}/.direction_component.lean{TMP}")
        with tempfile.TemporaryDirectory() as t:
            tree = Tree(t)
            (tree.work / "concurrent.json").write_text(json.dumps([B_RULE]))
            with tree.layout():
                baseline = gate.repo_digest()
                for rel in bad:
                    tree.put(rel)
                self.assertEqual(gate.scope_stray(baseline, {A_RULE, A_WIT}, tree.work), sorted(bad))

    def test_a_sibling_of_a_file_no_task_lists_is_a_violation(self):
        with tempfile.TemporaryDirectory() as t:
            tree = Tree(t)
            (tree.work / "concurrent.json").write_text(json.dumps([B_RULE]))
            with tree.layout():
                baseline = gate.repo_digest()
                elsewhere = "library/TrafficSpec/Concepts/motion/direction_component.lean" + TMP   # same name, other directory
                tree.put(OTHER + TMP)
                tree.put(elsewhere)
                self.assertEqual(gate.scope_stray(baseline, {A_RULE, A_WIT}, tree.work), sorted([OTHER + TMP, elsewhere]))

    def test_an_ordinary_stray_file_is_still_a_violation(self):
        """A tolerated sibling does not tolerate anything else: a changed file of no listed task is
        reported beside it."""
        with tempfile.TemporaryDirectory() as t:
            tree = Tree(t)
            (tree.work / "concurrent.json").write_text(json.dumps([B_RULE]))
            with tree.layout():
                baseline = gate.repo_digest()
                tree.put(B_RULE + TMP)
                tree.put(OTHER, "changed")
                self.assertEqual(gate.scope_stray(baseline, {A_RULE, A_WIT}, tree.work), [OTHER])

    def test_inside_a_candidate_only_the_write_set_counts(self):
        """In a candidate a sibling is tolerated only when its target is in the declared write set;
        neither the task's own files nor its task directory's list are consulted."""
        with tempfile.TemporaryDirectory() as t:
            tree = Tree(t)
            (tree.work / "concurrent.json").write_text(json.dumps([B_RULE]))
            baseline = gate.repo_digest(tree.root)
            for rel in (A_RULE + TMP, B_RULE + TMP, OTHER + TMP):
                tree.put(rel)
            with mock.patch.multiple(paths, **paths.library_layout(tree.root / "library")), \
                    gate.candidate_scope(gate.CandidateScope(tree.root, frozenset({OTHER}))):
                self.assertEqual(gate.scope_stray(baseline, {A_RULE, A_WIT}, tree.work), sorted([A_RULE + TMP, B_RULE + TMP]))

    def test_no_sibling_is_removed(self):
        with tempfile.TemporaryDirectory() as t:
            tree = Tree(t)
            (tree.work / "concurrent.json").write_text(json.dumps([B_RULE]))
            with tree.layout():
                baseline = gate.repo_digest()
                tree.put(B_RULE + TMP)
                gate.scope_stray(baseline, {A_RULE, A_WIT}, tree.work)
                self.assertTrue((tree.root / (B_RULE + TMP)).exists())


if __name__ == "__main__":
    unittest.main()
