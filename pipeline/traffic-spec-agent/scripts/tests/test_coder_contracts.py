"""The node coder is shown the ontology contract of every atom and primitive its record claims and
of every atom those primitives read, through the gloss path the reviewer's contracts come from, and
no contract of an atom the record neither claims nor reads through a claimed primitive."""
import json
import re
import tempfile
import unittest
from pathlib import Path
from unittest import mock

from harness.checks import gate
from harness.lean import surface
from harness.model import ontology
from harness.model.blueprint import Node
from harness.model.reading import Reading
from harness.phases import code as code_phase
from harness.phases import validate as validate_phase
from harness.store import paths
from harness.store.state import Options, Run

ONTO_FILE = paths.REPO / "ontology" / "ATOMS_train.md"
PRIM = "prim.region_offset_along"
CLAIMED = ["kin.speed", PRIM]


def node() -> Node:
    return Node({"node_id": "L_1", "law_refs": ["L-1"], "binders": [{"name": "v", "class_elements": []}],
                 "subject": {"binder": "v", "class_elements": []},
                 "segmentation": [{"id": "s1", "role": "obligation", "text": "stop short of the place"}],
                 "elements": [{"span": "s1", "atoms": CLAIMED}], "applicability": "a", "obligation": "o", "params": [],
                 "scenarios": [{"name": "forbid", "expected": "violated"}, {"name": "permit", "expected": "compliant"},
                               {"name": "idle", "expected": "not_applicable"},
                               {"name": "blind", "expected": "unknown", "masked": ["kin.speed"]}]})


class CoderContracts(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        root = Path(self.tmp.name)
        for sub in ("results", "gaps", "library"):
            (root / sub).mkdir()
        (root / "laws.jsonl").write_text(json.dumps({"id": "L-1", "title": "t", "text": "stop short of the place", "source": "s"}) + "\n")
        (root / "definitions.jsonl").write_text("")
        (root / "reading.json").write_text(json.dumps({"params": [], "aggregates": [], "declarations": []}))
        self.patches = [mock.patch.object(paths, "RESULTS", root / "results"), mock.patch.object(paths, "GAPS_DIR", root / "gaps"),
                        mock.patch.object(paths, "LIBRARY", root / "library"),
                        mock.patch.object(gate, "run_gate", lambda *a, **k: gate.Verdict("OK", [])),
                        mock.patch.object(code_phase, "_save_verdict", lambda *a, **k: None)]
        for p in self.patches:
            p.start()
        opts = Options(run_id="r", laws=root / "laws.jsonl", ontology=ONTO_FILE, reading=root / "reading.json", model="m", dry_run=True)
        self.run_ = Run(opts)
        self.run_.iteration = 1
        self.run_.dir.mkdir(parents=True)
        (self.run_.dir / "reading.json").write_text((root / "reading.json").read_text())

    def tearDown(self):
        for p in reversed(self.patches):
            p.stop()
        self.tmp.cleanup()

    def rows(self) -> dict[str, str]:
        """The contracts block of the rendered node coder prompt, by id."""
        n = node()
        code_phase.run_code(self.run_, n, Reading(self.run_.reading_file))
        prompt = (code_phase.node_dir(self.run_, n.id) / "prompt.md").read_text(encoding="utf-8")
        block = prompt.split("### Contracts\n\n", 1)[1]
        lines = block.splitlines()
        table = lines[:next(i for i, l in enumerate(lines) if not l.startswith("|"))]
        return {m.group(1): m.group(2) for m in (re.match(r"^\| `([^`]+)` \| (.*) \|$", l) for l in table[2:]) if m}

    def test_claimed_ids_and_what_a_claimed_primitive_reads(self):
        onto = ontology.load(ONTO_FILE)
        reads = {surface.atom_id_of(x, onto.atom_ids) for x in surface.primitive_reads()[PRIM.replace(".", "_")]}
        self.assertTrue(reads - set(CLAIMED), "the primitive reads atoms the record does not claim")
        rows = self.rows()
        self.assertEqual(set(rows), set(CLAIMED) | reads)
        for i in rows:
            self.assertEqual(rows[i], onto.contract(i))
        self.assertEqual(rows, validate_phase.glosses_for(node(), onto, self.run_))
        self.assertNotIn("rel.occupies", rows)


if __name__ == "__main__":
    unittest.main()
