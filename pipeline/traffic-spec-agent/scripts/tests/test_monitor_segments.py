"""The real monitor's `--segments` export, whole-recording scoring on its output, and Explain's
`--from`/`--to` observation choice and window report, on a library of the test's own (the working
Core, one rule registered by the test, the working `Main.lean`), built in a temporary directory so
the result does not depend on the rules the working library holds.

The rule looks back (`since`): on a vehicle that is fast from the trace's start it is unknown, the
window truncated at the start, until the vehicle is slow, then compliant, and violated at the end.
The segments carry those reasons; every other line is byte-identical with and without the flag; the
whole recording is violated and its scored record keeps the ego's segments; Explain, given an
interval, explains observations inside it only, and reports the truncated windows of the whole
trace, or of the interval it is given. Skipped only where Lake is not installed or the working
library is not built."""
import json
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path

from harness.lean import lean
from harness.store import paths
from recorded import projection, scoring

WORKING = paths.LIBRARY
INDEX = """import TrafficSpec.Core
namespace TrafficSpec
def segV : Arg := .var "v"
def segFast : Formula := .cmp (.measure "kin_speed" [segV]) .gt (.lit (Units.metresPerSecond 1) .metrePerSecond)
def segEast : Formula := .cmp (.measure "kin_position" [segV, .lit "x"]) .gt (.lit (Units.metres 5) .metre)
/-- slow at some observation since last at or west of x = 5 m; violated where it is at or west of
    it while fast. -/
def segRule : Rule :=
  { id := "t/slow_once", laws := [], binders := [{ name := "v", cls := .atom "ru_motor_vehicle" [segV] [] }]
    applicability := .tt, obligation := .or (.since segEast (.not segFast)) (.and (.not segEast) (.not segFast)) }
def allRules : List Rule := [segRule]
def allConcepts : List Concept := []
end TrafficSpec
"""


def scene(t: int, x: float, speed: float) -> dict:
    return {"t": t, "subject": 1, "occupancy_observed": True, "env": {"wet_road": False, "ice_or_snow": False},
            "users": [{"track": 1, "classes": ["motor_vehicle"],
                       "kin": {"position": [x, 0], "heading": [1, 0], "velocity": [speed, 0], "speed": speed,
                               "extent": [2, 0.9, 0.75]}}]}


#: fast from x = 10 (unknown: the search reaches the trace start), slow at 2 s (compliant from
#: then), back at x = 0 and fast at 5 s (violated)
TRACE = {"scenes": [scene(0, 10, 10), scene(1000, 20, 10), scene(2000, 30, 0.5), scene(3000, 31, 10),
                    scene(4000, 41, 10), scene(5000, 0, 10)]}


def own_library(root: Path, index: str = INDEX) -> Path:
    """The working Core and tools built in `root` with `index` as the registry; returns the monitor."""
    lib = root / "library"
    (lib / "TrafficSpec").mkdir(parents=True)
    for f in ("lakefile.lean", "lean-toolchain", "lake-manifest.json", "Main.lean", "Explain.lean", "TrafficSpec.lean"):
        shutil.copy2(WORKING / f, lib / f)
    shutil.copytree(paths.CORE, lib / "TrafficSpec" / "Core")
    shutil.copy2(paths.CORE.with_suffix(".lean"), lib / "TrafficSpec" / "Core.lean")
    for tree in (Path("lib") / "lean", Path("ir")):
        built = WORKING / ".lake" / "build" / tree / "TrafficSpec"
        dest = lib / ".lake" / "build" / tree / "TrafficSpec"
        shutil.copytree(built / "Core", dest / "Core")
        for f in built.glob("Core.*"):
            shutil.copy2(f, dest / f.name)
    (lib / "TrafficSpec" / "Index.lean").write_text(index, encoding="utf-8")
    code, out = lean.lake_build(lib, ["monitor", "explain"])
    if code != 0:
        raise AssertionError(f"the test's own monitor did not build: {out[-1500:]}")
    return lib / ".lake" / "build" / "bin" / "monitor"


@unittest.skipUnless(shutil.which("lake") and (WORKING / ".lake" / "build" / "lib" / "lean" / "TrafficSpec" / "Core").is_dir(),
                     "Lake is not installed or the working library is not built")
class MonitorSegments(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.tmp = tempfile.TemporaryDirectory()
        root = Path(cls.tmp.name)
        cls.monitor = own_library(root)
        cls.trace, cls.manifest, cls.reading = root / "trace.json", root / "manifest.json", root / "reading.json"
        cls.reading.write_text("{}")
        cls.trace.write_text(json.dumps(TRACE))
        ids = projection.atom_ids(paths.CORE / "Vocab" / "Ontology" / "Ids.lean")
        cls.manifest.write_text(json.dumps({"source": "test", "reid_gap": 0, "atoms": {a: "exact" for a in ids}}))

    @classmethod
    def tearDownClass(cls):
        cls.tmp.cleanup()

    def run_monitor(self, *flags) -> subprocess.CompletedProcess:
        return subprocess.run([str(self.monitor), "--manifest", str(self.manifest), *flags, str(self.trace)],
                              capture_output=True, text=True)

    def test_segments_carry_the_reasons_and_leave_every_other_line_unchanged(self):
        plain, seg = self.run_monitor("--json"), self.run_monitor("--json", "--segments")
        self.assertEqual((plain.returncode, seg.returncode), (0, 0), plain.stderr + seg.stderr)
        extra = [l for l in seg.stdout.splitlines() if json.loads(l)["kind"] == "segments"]
        self.assertEqual([l for l in seg.stdout.splitlines() if l not in extra], plain.stdout.splitlines())
        self.assertEqual(len(extra), 1)
        d = json.loads(extra[0])
        self.assertEqual((d["rule"], d["grounding"]), ("t/slow_once", {"v": 1}))
        segs = d["segments"]
        self.assertEqual([(s["from"], s["to"], s["verdict"]) for s in segs],
                         [(0, 1000, "unknown"), (2000, 4000, "compliant"), (5000, 5000, "violated")])
        self.assertEqual(segs[0]["reasons"], ["window_truncated:since"])
        self.assertTrue(all(s["reasons"] == [] for s in segs[1:]))
        ground = next(json.loads(l) for l in plain.stdout.splitlines() if json.loads(l)["kind"] == "grounding")
        self.assertEqual([(t["from"], t["to"], t["verdict"]) for t in ground["timeline"]],
                         [(s["from"], s["to"], s["verdict"]) for s in segs])     # the same runs, with reasons
        self.assertNotEqual(self.run_monitor("--segments").returncode, 0)          # JSON only

    def test_whole_recording_scoring_on_the_real_report(self):
        out = self.run_monitor("--json", "--segments").stdout.splitlines()
        whole = scoring.rule_results(out)
        self.assertEqual(whole["t/slow_once"].verdict, "violated")       # the prefix's unknown does not hide the later violation
        s = scoring.score("rec", "L", "violated", whole, {"t/slow_once": "L"})
        self.assertEqual(s.status, "match")
        segs = s.rules["t/slow_once"]["judged"][0]["segments"]
        self.assertEqual([(x["from"], x["to"], x["verdict"], x["reasons"]) for x in segs],
                         [(0, 1000, "unknown", ["window_truncated:since"]), (2000, 4000, "compliant", []), (5000, 5000, "violated", [])])

    def test_explain_chooses_its_observations_inside_the_window(self):
        explain = self.monitor.with_name("explain")
        run = lambda *w: subprocess.run([str(explain), "--manifest", str(self.manifest), "--reading", str(self.reading),
                                         "--rule", "t/slow_once", "--bind", "v=1", *w, "--scan", "--json", str(self.trace)],
                                        capture_output=True, text=True)
        at = lambda p: [e["at_ms"] for g in json.loads(p.stdout)["groundings"] for e in g["explanations"]]
        whole, inside, prefix = run(), run("--from", "2000", "--to", "4000"), run("--from", "0", "--to", "1000")
        self.assertEqual([p.returncode for p in (whole, inside, prefix)], [0, 0, 0], whole.stderr + inside.stderr + prefix.stderr)
        self.assertEqual(at(whole), [5000])                         # the violation, outside the windows below
        self.assertTrue(at(inside) and all(2000 <= t <= 4000 for t in at(inside)), at(inside))
        self.assertEqual(at(prefix), [0])                           # the first unknown observation
        wins = lambda p: json.loads(p.stdout)["groundings"][0]["windows"]
        self.assertEqual([(wins(p)["from_ms"], wins(p)["to_ms"], wins(p)["unknown_instants"]) for p in (whole, inside, prefix)],
                         [(0, 5000, 2), (2000, 4000, 0), (0, 1000, 2)])
        self.assertNotEqual(run("--from", "2500", "--to", "2600").returncode, 0)     # no observation inside
        self.assertNotEqual(run("--from", "2000").returncode, 0)                     # --from without --to


if __name__ == "__main__":
    unittest.main()
