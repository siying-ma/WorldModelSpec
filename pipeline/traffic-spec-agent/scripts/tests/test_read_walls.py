"""What a session cannot read, and what the gate refuses before it compiles: every session's deny
rules carry the held-out laws, the files that carry them or their withheld vocabulary, the driving
data and every other run's results; no allow-list grants a shell command but the one the prompt
gives; and a candidate with a forbidden construct is refused before the toolchain runs, because the
compiler runs what a file elaborates."""
import json
import tempfile
import unittest
from pathlib import Path
from types import SimpleNamespace
from unittest import mock

from harness.agents import session
from harness.checks import gate
from harness.model import nodeid
from harness.store import paths


class DenyRules(unittest.TestCase):
    def test_every_session_is_denied_the_held_out_files_and_other_runs(self):
        with tempfile.TemporaryDirectory() as t:
            results = Path(t)
            for name in ("mine", "other", "older"):
                (results / name).mkdir()
            with mock.patch.object(paths, "RESULTS", results):
                for kind in ("plan", "code"):
                    rules = session.deny_rules(kind, "mine")
                    reads = [r for r in rules if r.startswith("Read(")]
                    for rel in session.UNREADABLE:
                        self.assertTrue(any(rel in r for r in reads), (kind, rel))
                    self.assertTrue(any("pipeline/datasets" in r for r in reads))
                    self.assertTrue(any(str((results / "other").resolve()).lstrip("/") in r for r in reads))
                    self.assertFalse(any(str((results / "mine").resolve()).lstrip("/") in r for r in reads))

    def test_no_allow_list_grants_a_free_shell(self):
        with tempfile.TemporaryDirectory() as t:
            d = Path(t)
            plan = session.plan_allow(d, "python -m harness validate --run_id r --blueprint_file x")
            code = session.code_allow([d / "A.lean"], d, "python -m harness gate --run_id r --node_id N")
            shells = [r for r in plan + code if r.startswith("Bash(")]
            self.assertEqual(shells, ["Bash(python -m harness validate --run_id r --blueprint_file x)",
                                      "Bash(python -m harness gate --run_id r --node_id N)"])


class RefusedBeforeCompiling(unittest.TestCase):
    def test_a_forbidden_construct_never_reaches_the_toolchain(self):
        with tempfile.TemporaryDirectory() as t:
            lib = Path(t) / "library"
            node = SimpleNamespace(id="L_1_o1", raw={})
            rule, wit = lib / nodeid.rule_path(node.id), lib / nodeid.witness_path(node.id)
            rule.parent.mkdir(parents=True); wit.parent.mkdir(parents=True)
            rule.write_text(f"import TrafficSpec.Core.Language.Rule\nnamespace {nodeid.rule_namespace(node.id)}\n"
                            f"#eval IO.FS.readFile \"/etc/hostname\"\nend {nodeid.rule_namespace(node.id)}\n")
            wit.write_text(f"import {nodeid.rule_module(node.id)}\nnamespace {nodeid.witness_namespace(node.id)}\n"
                           f"end {nodeid.witness_namespace(node.id)}\n")
            ran = []
            with mock.patch.object(paths, "LIBRARY", lib), mock.patch.object(gate, "repo_digest", lambda *a, **k: {}), \
                    mock.patch.object(gate, "reading_input_defects", lambda r: None), \
                    mock.patch.object(gate, "_toolchain", lambda *a, **k: ran.append(1)):
                v = gate.run_gate(node, SimpleNamespace(lean_json=lambda: json.dumps({})), {}, Path(t) / "work", 0, 5)
            self.assertEqual(ran, [])
            self.assertEqual(v.verdict, "UNSOUND")
            self.assertTrue(any("#eval" in d for d in v.details), v.details)


if __name__ == "__main__":
    unittest.main()
