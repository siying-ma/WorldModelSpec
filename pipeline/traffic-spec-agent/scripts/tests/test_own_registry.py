"""A Lean program run beside other sessions' gates reads no generated registry: the gate harnesses
and the concept review's programs import Core and the modules of their own registry, which selects
the same ids a build of that registry would, and a concept review registers what its subject's gate
registered."""
import contextlib
import json
import re
import tempfile
import unittest
from pathlib import Path
from types import SimpleNamespace
from unittest import mock

from harness.checks import gate
from harness.lean import index_sync, lean
from harness.model import nodeid
from harness.phases import review
from harness.store import paths

GENERATED = {"TrafficSpec", "TrafficSpec.Index", "TrafficSpecWitness"}


def imports(src: str) -> list[str]:
    return re.findall(r"^import (\S+)", src, re.M)


def registered_in(src: str) -> tuple[list[str], list[str]]:
    """The rule and concept modules a program or the generated registry lists, in order."""
    mods = imports(src)
    return [m for m in mods if m.startswith("TrafficSpec.Rules.")], [m for m in mods if m.startswith("TrafficSpec.Concepts.")]


class Library(unittest.TestCase):
    def setUp(self):
        self.tmp = Path(tempfile.mkdtemp(prefix="registry-"))
        lib = self.tmp / "library"
        names = {"LIBRARY": lib, "RULES_DIR": lib / "TrafficSpec" / "Rules", "CONCEPTS_DIR": lib / "TrafficSpec" / "Concepts",
                 "WITNESS_DIR": lib / "TrafficSpecWitness", "CONCEPT_WITNESS_DIR": lib / "TrafficSpecWitness" / "Concepts",
                 "INDEX_FILE": lib / "TrafficSpec" / "Index.lean", "WITNESS_ROOT_FILE": lib / "TrafficSpecWitness.lean"}
        self.stack = contextlib.ExitStack()
        for k, v in names.items():
            self.stack.enter_context(mock.patch.object(paths, k, v))
        (lib / "TrafficSpec").mkdir(parents=True)
        for n in ("L_1", "L_2", "L_3"):
            self.write(nodeid.rule_path(n)); self.write(nodeid.witness_path(n))
        for c in ("drv.motion.halted_a", "drv.motion.halted_b"):
            self.write(nodeid.concept_path(c)); self.write(nodeid.concept_witness_path(c))
        index_sync.set_inactive({"L_3", "drv.motion.halted_b"}, "r")

    def tearDown(self):
        self.stack.close()

    def write(self, rel):
        p = paths.LIBRARY / rel
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_text("ok")


class SameSelection(Library):

    def test_the_own_registry_selects_what_the_build_registers(self):
        for args in ({}, {"only_nodes": ["L_1"], "only_concepts": ["drv.motion.halted_a"]},
                     {"only_nodes": ["L_1", "L_3"], "only_concepts": [], "keep": {"L_3"}}):
            with self.subTest(**{k: str(v) for k, v in args.items()}):
                index_sync.write_index(**args)
                built = registered_in(paths.INDEX_FILE.read_text())
                imports_text, defs = index_sync.registry_source(**args)
                self.assertEqual(registered_in(imports_text), built)
                self.assertIn("def allRules", defs)
                self.assertIn("def allConcepts", defs)

    def test_an_inactive_record_enters_neither_unless_kept(self):
        rules, concepts = registered_in(index_sync.registry_source()[0])
        self.assertNotIn(nodeid.rule_module("L_3"), rules)
        self.assertNotIn(nodeid.concept_module("drv.motion.halted_b"), concepts)
        rules, _c = registered_in(index_sync.registry_source(keep={"L_3"})[0])
        self.assertIn(nodeid.rule_module("L_3"), rules)


class NoGeneratedImport(Library):

    def test_the_gate_harnesses_import_no_generated_registry(self):
        reg = index_sync.registry_source(["L_1"], ["drv.motion.halted_a"])
        for src in (gate._harness_source("L_1", Path("/r.json"), reg),
                    gate._concept_harness_source("drv.motion.halted_a", Path("/r.json"), reg),
                    review._concept_review_harness_source("drv.motion.halted_a", [], None, reg)):
            self.assertFalse(set(imports(src)) & GENERATED, imports(src))
            self.assertIn("def allRules", src)

    def test_the_relation_check_imports_core_only(self):
        seen = {}

        def capture(lib, prog):
            seen["src"] = Path(prog).read_text()
            return 0, ""
        tr = {"scenes": [{"t": 0, "relations": [{"atom": "rel_contact", "args": [1, 2]}]}]}
        with mock.patch.object(lean, "lean_run", capture):
            review._COMPUTED_CACHE.clear()
            review.computed_relation_fields([tr])
        self.assertEqual(imports(seen["src"]), ["TrafficSpec.Core"])


class ReviewRegistersWhatItsGateRegistered(Library):
    """A concept review's program registers what the concept's gate registered: the registry the
    review passes to its program (`_registry` over the concept's coding task, as `review_concept`
    calls it), with the concept itself registered."""
    CID = "drv.motion.halted_c"

    def run_(self):
        d = self.tmp / "results" / "r"
        d.mkdir(parents=True, exist_ok=True)
        (d / "reading.json").write_text(json.dumps({"params": [], "aggregates": []}))
        return SimpleNamespace(dir=d, iteration=1, iter=d / "iter-001", reading_file=d / "reading.json",
                               all_nodes=lambda: {"L_1": {}, "L_2": {}}, all_concepts=lambda: {"drv.motion.halted_a": {}})

    def program(self, run) -> str:
        from harness.phases.code import concept_dir
        task = concept_dir(run, self.CID) if run is not None else None
        return review._concept_review_harness_source(self.CID, [], None, review._registry(run, self.CID, task))

    def test_a_program_registers_its_gates_registry_and_its_subject(self):
        self.write(nodeid.concept_path(self.CID))
        run = self.run_()
        from harness.phases.code import concept_dir
        task = concept_dir(run, self.CID); task.mkdir(parents=True)
        (task / "registry.json").write_text(json.dumps({"nodes": ["L_1"], "concepts": ["drv.motion.halted_a"]}))
        rules, concepts = registered_in(self.program(run))
        self.assertEqual(rules, [nodeid.rule_module("L_1")])
        self.assertEqual(sorted(set(concepts)), sorted({nodeid.concept_module("drv.motion.halted_a"), nodeid.concept_module(self.CID)}))
        self.assertFalse(set(imports(self.program(run))) & GENERATED)

    def test_with_no_run_it_registers_every_active_record(self):
        self.write(nodeid.concept_path(self.CID))
        rules, concepts = registered_in(self.program(None))
        self.assertEqual(sorted(set(rules)), sorted({nodeid.rule_module(i) for i in ("L_1", "L_2")}))          # L_3 is inactive
        self.assertEqual(sorted(set(concepts)), sorted({nodeid.concept_module(c) for c in ("drv.motion.halted_a", self.CID)}))

    def test_without_a_coding_task_it_registers_the_runs_accepted_records(self):
        self.write(nodeid.concept_path(self.CID))
        rules, concepts = registered_in(self.program(self.run_()))
        self.assertEqual(sorted(set(rules)), sorted({nodeid.rule_module(i) for i in ("L_1", "L_2")}))
        self.assertEqual(sorted(set(concepts)), sorted({nodeid.concept_module(c) for c in ("drv.motion.halted_a", self.CID)}))


if __name__ == "__main__":
    unittest.main()
