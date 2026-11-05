"""The monitor refuses a trace the admission refuses: a recorded trace runs (exit 0), the same trace
with two intent records for one vehicle and region is not admitted (exit 2, the admission's
reason). It needs no rule and imports no review module."""
import json
import subprocess
import tempfile
import unittest
from pathlib import Path

from harness.store import paths

FIXTURE = Path(__file__).resolve().parent / "fixtures" / "admission_refusal" / "trace.json"
DOUBLED = {"vehicle": 1, "target": 101, "source": "test", "values": [["int.turn_left", True]]}


class MonitorRefusesAnUnadmittedTrace(unittest.TestCase):
    def test_the_monitor_exits_2(self):
        exe = paths.LIBRARY / ".lake/build/bin/monitor"
        if not exe.exists():
            self.skipTest("the monitor is not built (`lake build monitor`)")
        trace = json.loads(FIXTURE.read_text())                             # a missing fixture fails
        refused = json.loads(json.dumps(trace))
        refused["scenes"][0]["intents"] = [DOUBLED, dict(DOUBLED)]
        with tempfile.TemporaryDirectory() as td:
            m, t, r = Path(td) / "m.json", Path(td) / "t.json", Path(td) / "r.json"
            m.write_text(json.dumps({"source": "test", "atoms": {}}))
            t.write_text(json.dumps(trace))
            r.write_text(json.dumps(refused))
            run = lambda p: subprocess.run([str(exe), "--manifest", str(m), str(p)], capture_output=True, text=True)
            ok, bad = run(t), run(r)
        self.assertEqual(ok.returncode, 0, ok.stderr)
        self.assertEqual(bad.returncode, 2)
        self.assertIn("is not admitted", bad.stderr)
        self.assertIn("more than one intent record", bad.stderr)

    def test_no_review_module_is_imported(self):
        import sys
        probe = ("import sys, scripts.tests.test_admission_refusal_monitor; "
                 "print(sorted(m for m in sys.modules if m.endswith('phases.review')))")
        out = subprocess.run([sys.executable, "-c", probe], capture_output=True, text=True,
                             cwd=Path(__file__).resolve().parents[2])
        self.assertEqual(out.returncode, 0, out.stderr)
        self.assertEqual(out.stdout.strip(), "[]")


if __name__ == "__main__":
    unittest.main()
