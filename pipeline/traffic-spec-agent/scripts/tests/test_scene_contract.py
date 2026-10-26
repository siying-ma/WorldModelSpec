"""Development regression tests for the scene-representation contract the trace check enforces: a
designated direction on a structure a vehicle travels in, a device governing travel regions or an
intersection, and a device's control unknown where it is not written. The fixture holds
contract-encoded cases of distinctions earlier rules got wrong, and one recorded case written
outside the contract."""
import json
import tempfile
import unittest
from pathlib import Path

from harness.lean import lean
from harness.store import paths

CASES = json.loads((Path(__file__).parent / "scene_contract_cases.json").read_text())


def trace_check(traces: dict[str, dict]) -> dict[str, list[str]]:
    """The trace check's messages on each trace (after the occupancy is derived), by name."""
    with tempfile.TemporaryDirectory() as t:
        items = []
        for k, tr in traces.items():
            f = Path(t) / f"{k}.json"; f.write_text(json.dumps(tr)); items.append(f'("{k}", {json.dumps(str(f))})')
        prog = Path(t) / "check.lean"
        prog.write_text(f'''import TrafficSpec
import TrafficSpec.Core.Runtime.Decode
import TrafficSpec.Core.Evidence.TraceLint
open TrafficSpec Lean
def items : List (String × String) := [{", ".join(items)}]
def main : IO Unit := do
  for (k, f) in items do
    match Decode.parse Decode.trace (← IO.FS.readFile f) with
    | .ok τ =>
      IO.println s!"CHECKED\\t{{k}}"
      for e in TraceLint.checkTrace (TraceLint.completeOccupancy τ) do IO.println s!"LINT\\t{{k}}\\t{{e}}"
    | .error e => IO.println s!"DECODE\\t{{k}}\\t{{e}}"
''')
        code, out = lean.lean_run(paths.LIBRARY, prog)
        assert code == 0, out[-600:]
        got: dict[str, list[str]] = {k: [] for k in traces}
        for line in out.splitlines():
            parts = line.split("\t")
            if parts[0] in ("LINT", "DECODE"):
                got[parts[1]].append("\t".join(parts[2:]))
            elif parts[0] == "CHECKED":
                got.setdefault(parts[1], [])
        return got


class SceneContract(unittest.TestCase):

    @classmethod
    def setUpClass(cls):
        traces = {f"case{i}": c["trace"] for i, c in enumerate(CASES["contract_cases"])}
        traces["recorded"] = CASES["recorded_highway_governs"]["trace"]
        cls.got = trace_check(traces)

    def test_the_contract_encoded_cases_pass(self):
        for i, c in enumerate(CASES["contract_cases"]):
            self.assertEqual(self.got[f"case{i}"], [], c["name"])

    def test_a_recorded_case_governing_a_highway_is_refused(self):
        self.assertTrue(any("governs structure" in m and "(highway)" in m for m in self.got["recorded"]), self.got["recorded"])

    def test_the_cases_keep_the_distinctions_they_encode(self):
        names = [c["name"] for c in CASES["contract_cases"]]
        self.assertEqual(len(names), 5)
        expected = {c["name"]: c["expected_stage_a"] for c in CASES["contract_cases"]}
        self.assertIn("compliant", expected.values())
        self.assertIn("violated", expected.values())
        self.assertIn("not_applicable", expected.values())


if __name__ == "__main__":
    unittest.main()
