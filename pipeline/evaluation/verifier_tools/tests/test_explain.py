"""The explain program and its use by the verifier, on recorded cases.

    PKG=<built package copy> CASES=<recorded cases dir> python3 -m unittest -v tests/test_explain.py

`run_tests.sh` builds a copy of the delivered package and passes it as PKG; the delivered package
(`DELIVERED`, default ../../verifier/smoke25) is only read.

Each test names the behaviour it checks. A case directory holds `trace.json`, `manifest.json` and
`label.json`; a test whose case is missing is skipped, never passed. The package's own `monitor`
is the reference for verdicts and groundings, so every check compares the explainer with the
program whose verdict it explains.
"""
from __future__ import annotations

import json
import os
import shutil
import subprocess
import sys
import tempfile
import unittest
from fractions import Fraction
from pathlib import Path

HERE = Path(__file__).resolve().parent
TOOLS = HERE.parent
DELIVERED = Path(os.environ.get("DELIVERED", TOOLS.parent / "verifier" / "smoke25")).resolve()
PKG = Path(os.environ.get("PKG", DELIVERED)).resolve()
BIN = PKG / "lean" / ".lake" / "build" / "bin"
EXPLAIN, MONITOR = BIN / "explain", BIN / "monitor"
READING = PKG / "data" / "reading.json"
CASES = Path(os.environ.get("CASES", "/local-scratch2/sma407/scratch_recorded/data"))
RULE = "NRS_484B_600_1e"
ABOVE, BELOW = "C230222-focused-600-1e-80-above", "C230222-focused-600-1e-80-below"
ALL_ABSENT = "C329610-600-1e-80-above"          # its manifest declares every atom absent


def case(name: str) -> Path:
    d = CASES / name
    if not (d / "trace.json").exists():
        raise unittest.SkipTest(f"recorded case {name} is not under {CASES}")
    return d


def run(*args, timeout=600) -> subprocess.CompletedProcess:
    return subprocess.run([str(a) for a in args], capture_output=True, text=True, timeout=timeout)


def explain(c: Path, *args, rule=RULE) -> subprocess.CompletedProcess:
    return run(EXPLAIN, "--manifest", c / "manifest.json", "--reading", READING, "--rule", rule, *args, c / "trace.json")


def monitor_groundings(c: Path, rule=RULE) -> list[dict]:
    p = run(MONITOR, "--manifest", c / "manifest.json", "--reading", READING, "--rules", rule, "--json", c / "trace.json")
    rows = [json.loads(x) for x in p.stdout.splitlines() if x.strip()]
    return [r for r in rows if r.get("kind") == "grounding" and r.get("rule") == rule]


def groundings(p: subprocess.CompletedProcess) -> list[dict]:
    return json.loads(p.stdout)["groundings"]


def binds(binding: dict) -> list[str]:
    return [a for n, t in binding.items() for a in ("--bind", f"{n}={t}")]


class SingleSource(unittest.TestCase):
    def test_builder_and_package_use_one_explain_file(self):
        src = TOOLS / "lean_src" / "Explain.lean"
        self.assertTrue(src.is_symlink(), "lean_src/Explain.lean should point at the delivered package's copy")
        self.assertEqual(src.resolve(), (DELIVERED / "lean" / "Explain.lean").resolve())
        self.assertIn('HERE / "lean_src" / "Explain.lean"', (TOOLS / "make_package.py").read_text())
        with tempfile.TemporaryDirectory() as t:                 # the builder's copy is a regular file
            out = Path(t) / "Explain.lean"
            shutil.copy2(src, out)
            self.assertFalse(out.is_symlink())
            self.assertEqual(out.read_bytes(), src.resolve().read_bytes())

    def test_lakefiles_declare_the_second_executable(self):
        for f in (DELIVERED / "lean" / "lakefile.lean", TOOLS / "make_package.py"):
            self.assertIn("lean_exe «explain»", f.read_text(), f)


    def test_the_delivered_package_holds_no_build_output(self):
        for junk in ("lean/.lake", "traffic_verifier/__pycache__"):
            self.assertFalse((DELIVERED / junk).exists(), f"{DELIVERED / junk} should not be delivered")

    def test_the_template_matches_the_delivered_package(self):
        template = TOOLS.parent / "verifier" / "template"
        for f in ("README.md", "install.sh", "verify", "traffic_verifier/core.py", "traffic_verifier/cli.py",
                  "traffic_verifier/normalize.py", "traffic_verifier/__init__.py", "traffic_verifier/__main__.py"):
            self.assertEqual((template / f).read_bytes(), (DELIVERED / f).read_bytes(), f)


class ExplainProgram(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        if not EXPLAIN.exists() or not MONITOR.exists():
            raise unittest.SkipTest(f"build the package first: {PKG / 'install.sh'}")

    def test_bind_must_name_each_binder(self):
        c = case(BELOW)
        p = explain(c, "--at", "4050", "--bind", "v=35")
        self.assertEqual(p.returncode, 2)
        self.assertIn("--bind must name each binder", p.stderr)

    def test_at_and_scan_are_exclusive(self):
        c = case(BELOW)
        self.assertEqual(explain(c, "--scan", "--at", "4050").returncode, 2)
        self.assertEqual(explain(c).returncode, 2)

    def test_text_and_json_agree_at_a_violated_observation(self):
        c = case(ABOVE)
        g = next(g for g in monitor_groundings(c) if g["episode"]["verdict"] == "violated")
        at = next(t["from"] for t in g["timeline"] if t["verdict"] == "violated")
        text = explain(c, "--at", at, *binds(g["grounding"]))
        js = explain(c, "--at", at, "--json", *binds(g["grounding"]))
        self.assertEqual(text.returncode, 0, text.stderr)
        self.assertEqual(js.returncode, 0, js.stderr)
        rep = groundings(js)[0]["explanations"][0]
        self.assertIn("verdict violated", text.stdout.splitlines()[0])
        self.assertEqual(rep["verdict"], "violated")
        self.assertEqual(rep["obligation"]["value"], "false")
        self.assertEqual(rep["text"], text.stdout.splitlines())
        self.assertIn("cmp", rep["obligation"])

    def test_scan_picks_the_first_observation_of_each_violated_interval(self):
        c = case(ABOVE)
        for g in monitor_groundings(c):
            starts = [t["from"] for t in g["timeline"] if t["verdict"] == "violated"][:3]
            p = explain(c, "--scan", "--json", *binds(g["grounding"]))
            self.assertEqual(p.returncode, 0, p.stderr)
            reps = groundings(p)[0]["explanations"]
            if starts:
                self.assertEqual([r["at_ms"] for r in reps], starts)
                self.assertTrue(all(r["chosen_because"] == "first observation of a violated interval" for r in reps))
                self.assertTrue(all(r["verdict"] == "violated" for r in reps))

    def test_scan_of_a_compliant_rule_picks_the_observation_closest_to_the_bound(self):
        c = case(BELOW)
        g = monitor_groundings(c)[0]
        self.assertEqual(g["episode"]["verdict"], "compliant")
        (track,) = g["grounding"].values()
        trace = json.loads((c / "trace.json").read_text())
        speeds = {s["t"]: u["kin"]["speed"] for s in trace["scenes"] for u in s["users"] if u["track"] == track}
        p = explain(c, "--scan", "--json", *binds(g["grounding"]))
        self.assertEqual(p.returncode, 0, p.stderr)
        (rep,) = groundings(p)[0]["explanations"]
        self.assertIn("relatively closest to", rep["chosen_because"])
        self.assertEqual(rep["verdict"], "compliant")
        fastest = max(speeds.values())                         # the bound is constant: closest = fastest
        self.assertAlmostEqual(speeds[rep["at_ms"]], fastest, places=6)
        exact = rep["obligation"]["cmp"]["lhs"]["exact"]
        self.assertAlmostEqual(exact["num"] / exact["den"], fastest, places=9)

    def test_scan_without_bind_explains_the_monitors_groundings(self):
        c = case(ABOVE)
        p = explain(c, "--scan", "--json")
        self.assertEqual(p.returncode, 0, p.stderr)
        out = json.loads(p.stdout)
        got = [r["binding"] for r in out["groundings"]]
        want = [g["grounding"] for g in monitor_groundings(c)]
        self.assertEqual(out["groundings_total"], len(want))
        self.assertEqual(out["groundings_explained"], len(want))
        self.assertEqual(sorted(map(json.dumps, got)), sorted(map(json.dumps, want)))
        for r, g in zip(sorted(out["groundings"], key=lambda r: json.dumps(r["binding"])),
                        sorted(monitor_groundings(c), key=lambda g: json.dumps(g["grounding"]))):
            self.assertEqual(r["episode"], g["episode"]["verdict"])


    def test_values_are_exact_and_unpruned(self):
        c = case(BELOW)
        g = monitor_groundings(c)[0]
        (track,) = g["grounding"].values()
        trace = json.loads((c / "trace.json").read_text(), parse_float=Fraction)
        scene = trace["scenes"][80]
        speed = next(u["kin"]["speed"] for u in scene["users"] if u["track"] == track)
        p = explain(c, "--at", scene["t"], "--values", "--json", *binds(g["grounding"]))
        self.assertEqual(p.returncode, 0, p.stderr)
        vals = groundings(p)[0]["values"]
        self.assertFalse(groundings(p)[0]["truncated"])
        speeds = [v for v in vals if v["cmp"]["lhs"]["term"].startswith("kin_speed")]
        self.assertTrue(speeds, vals)
        lhs = speeds[0]["cmp"]["lhs"]["exact"]
        self.assertEqual(Fraction(lhs["num"], lhs["den"]), Fraction(speed))      # exact, not rounded

    def test_an_unsupported_rule_is_reported_and_not_explained(self):
        c = case(ALL_ABSENT)
        with tempfile.TemporaryDirectory() as t:                 # a short cut of the recording
            d = Path(t)
            trace = json.loads((c / "trace.json").read_text())
            trace["scenes"] = trace["scenes"][:40]
            (d / "trace.json").write_text(json.dumps(trace))
            shutil.copy(c / "manifest.json", d / "manifest.json")
            self.assertEqual(monitor_groundings(d), [])          # the monitor evaluates no grounding
            p = explain(d, "--scan", "--json")
            self.assertEqual(p.returncode, 0, p.stderr)
            out = json.loads(p.stdout)
            self.assertEqual(out["support"], "unsupported")
            self.assertEqual(out["groundings"], [])
            self.assertTrue(out["absent"])

    def test_the_verdict_carries_its_reasons(self):
        c = case(ABOVE)
        p = explain(c, "--scan", "--json")
        for g in groundings(p):
            for x in g["explanations"]:
                self.assertIn("verdict_reasons", x)
                self.assertEqual(x["verdict_reasons"] == [], x["verdict"] != "unknown")


class Verifier(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        if not EXPLAIN.exists() or not MONITOR.exists():
            raise unittest.SkipTest(f"build the package first: {PKG / 'install.sh'}")
        sys.path.insert(0, str(PKG))
        from traffic_verifier import verify
        cls.verify = staticmethod(verify)

    def test_explain_true_explains_violations_only(self):
        c = case(ABOVE)
        rep = self.verify(c / "trace.json", c / "manifest.json", rules=[RULE], explain=True)
        (rule,) = rep["laws"]["NRS-484B-600-1e"]["rules"]
        g = next(g for g in rule["groundings"] if g["violated_ms"])
        self.assertTrue(g["explanation"][0].startswith(f"rule {RULE} at t={g['explained_at_ms']} ms"))
        self.assertTrue(all("scan" not in g for g in rule["groundings"]))

    def test_explain_all_explains_every_grounding(self):
        c = case(BELOW)
        rep = self.verify(c / "trace.json", c / "manifest.json", rules=[RULE], explain="all")
        (rule,) = rep["laws"]["NRS-484B-600-1e"]["rules"]
        self.assertEqual(rule["verdict"], "compliant")
        for g in rule["groundings"]:
            self.assertNotIn("scan_error", g)
            self.assertTrue(g["scan"])
            for x in g["scan"]:
                self.assertTrue({"at_ms", "verdict", "chosen_because", "text", "obligation", "applicability"} <= set(x))

    def test_explain_false_explains_nothing(self):
        c = case(ABOVE)
        rep = self.verify(c / "trace.json", c / "manifest.json", rules=[RULE], explain=False)
        (rule,) = rep["laws"]["NRS-484B-600-1e"]["rules"]
        self.assertTrue(all("explanation" not in g and "scan" not in g for g in rule["groundings"]))

    def test_cli_explain_all_prints_the_chosen_observation(self):
        c = case(BELOW)
        p = run(PKG / "verify", c / "trace.json", "--manifest", c / "manifest.json", "--rule", RULE, "--explain-all")
        self.assertEqual(p.returncode, 0, p.stderr)
        self.assertIn("relatively closest to", p.stdout)
        self.assertIn("kin_speed", p.stdout)


if __name__ == "__main__":
    unittest.main()
