"""The heading change since an onset (`Term.headingSince`, JSON `heading_since`) on the harness's
surfaces: the renderer, the case language, case renaming and units, the gate's variable
connectivity, and Explain, which reports every occurrence of the term in a comparison with its path,
binding, step bound and onset, locates only those reached through arithmetic and selections, shows
the observations around the onset, tells the absences of the subject apart, and gives the window
diagnosis no eligible piece for the term. The Lean-backed tests are skipped only where Lake is not
installed or the working library is not built."""
import json
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path

from harness.checks import gate
from harness.lean import render_formula, surface
from harness.phases import label_check, review
from harness.store import paths
from recorded import projection, scoring
from scripts.tests.test_monitor_segments import WORKING, own_library

STEP = {"param": "p.step"}


def at(a, *args):
    return {"atom": a, "args": [{"var": x} for x in args], "params": []}


def hs(subject, onset, step=STEP):
    return {"heading_since": subject, "max_step": step, "onset": onset}


class Surfaces(unittest.TestCase):
    def test_the_renderer_says_what_the_term_is(self):
        text = render_formula.term(hs("x", "tt"), {})
        self.assertIn("heading change of `x` since", text)
        self.assertIn("last became true", text)
        self.assertIn("`p.step`", text)

    def test_the_formula_language_shows_the_constructor_and_its_restriction(self):
        t = surface.formula_language()
        self.assertIn("| headingSince (subject : String) (maxStep : Term) (ψ : Formula)", t)
        self.assertIn("- `Term.headingSince`:", t)
        self.assertIn("a heading change's or a sampled duration's step bound that is not a literal or a reading parameter", t)

    def test_a_concept_body_renames_the_subject_like_a_distance(self):
        a = render_formula.canonical({"cmp": "ge", "lhs": hs("x", at("ru_motor_vehicle", "x"), {"param": "s"}), "rhs": {"lit": 0}}, ["x"], ["s"])
        b = render_formula.canonical({"cmp": "ge", "lhs": hs("y", at("ru_motor_vehicle", "y"), {"param": "t"}), "rhs": {"lit": 0}}, ["y"], ["t"])
        self.assertEqual(a, b)
        self.assertIn('"heading_since":"$a0"', a)

    def test_a_case_term_is_in_degrees(self):
        class Rec:
            def params(self):
                return [{"name": "s", "unit": "s"}]
        self.assertEqual(review.body_dim(Rec(), hs("x", "tt", {"param": "s"})), (0, 0, 1, 0))


LEAN_BUILT = shutil.which("lake") and (WORKING / ".lake" / "build" / "lib" / "lean" / "TrafficSpec" / "Core").is_dir()


@unittest.skipUnless(LEAN_BUILT, "Lake is not installed or the working library is not built")
class GateConnectivity(unittest.TestCase):
    def test_the_onset_ties_a_quantified_road_user_to_the_binder(self):
        src = f"""import TrafficSpec.Core
{gate._OCC_DEFS}
open TrafficSpec
def g : Term := .headingSince "x" (.param "p.step") (.atom "rel_ahead_in_lane" [.var "u", .var "x"] [])
#eval IO.println (String.intercalate ";" ((occF (.existsUser "u" (.cmp g .ge (.lit (Q.ofInt 90) .degree)))).map (String.intercalate ",")))
"""
        with tempfile.TemporaryDirectory() as d:
            f = Path(d) / "Occ.lean"
            f.write_text(src)
            p = subprocess.run(["lake", "env", "lean", str(f)], cwd=WORKING, capture_output=True, text=True)
        self.assertEqual(p.returncode, 0, p.stdout + p.stderr)
        groups = [g.split(",") for g in p.stdout.strip().splitlines()[-1].split(";")]
        self.assertIn(["x"], groups)
        self.assertIn(["u", "x"], groups)
        self.assertEqual(gate.unanchored_variables(groups, ["x"]), [])


INDEX = """import TrafficSpec.Core
namespace TrafficSpec
def hV : Arg := .var "v"
def hOn : Formula := .asm "asm.onset"
def hTurn (ψ : Formula := hOn) : Term := .headingSince "v" (.param "p.step") ψ
def hDeg (n : Int) : Term := .lit (Units.degrees n) .degree
def hRule (id : String) (obl : Formula) : Rule :=
  { id, laws := [], binders := [{ name := "v", cls := .atom "ru_motor_vehicle" [hV] [] }], applicability := .tt,
    obligation := obl, assumptions := ["asm.onset"] }
def hTurnC : Concept :=
  { id := "drv.t.turn", contract := "the heading change of x since the onset", args := [("x", .track)],
    params := [{ name := "s", unit := .second }], body := .quantity (.headingSince "x" (.param "s") (.asm "asm.onset")) }
def allRules : List Rule := [
  hRule "h/direct" (.cmp (hTurn) .le (hDeg 1000)),
  hRule "h/abs" (.cmp (.abs (hTurn)) .ge (hDeg 0)),
  hRule "h/nested" (.cmp (hTurn (.cmp (hTurn) .ge (hDeg 2))) .le (hDeg 1000)),
  hRule "h/concept" (.cmp (.quantity "drv_t_turn" [hV] [.param "p.step"]) .le (hDeg 1000))]
def allConcepts : List Concept := [hTurnC]
end TrafficSpec
"""

READING = {"params": [{"name": "p.step", "value": 1, "unit": "s"}]}


def scene(t, on=True, yaw=10.0, track=1, present=True, links=()):
    s = {"t": t, "subject": track, "occupancy_observed": True,
         "users": [{"track": track, "classes": ["motor_vehicle"], "kin": {"speed": 5, "yaw_rate": yaw}}] if present else [],
         "assumptions": [["asm.onset", on]] if on is not None else []}
    if links:
        s["links"] = [list(l) for l in links]
    return s


@unittest.skipUnless(LEAN_BUILT, "Lake is not installed or the working library is not built")
class ExplainHeadingSince(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.tmp = tempfile.TemporaryDirectory()
        root = Path(cls.tmp.name)
        cls.monitor = own_library(root, INDEX)
        cls.explain = cls.monitor.with_name("explain")
        cls.root = root
        cls.reading = root / "reading.json"
        cls.reading.write_text(json.dumps(READING))
        ids = projection.atom_ids(paths.CORE / "Vocab" / "Ontology" / "Ids.lean")
        cls.manifest = root / "manifest.json"
        cls.manifest.write_text(json.dumps({"source": "test", "reid_gap": 1, "atoms": {a: "exact" for a in ids}}))

    @classmethod
    def tearDownClass(cls):
        cls.tmp.cleanup()

    def trace(self, name, scenes) -> Path:
        p = self.root / f"{name}.json"
        p.write_text(json.dumps({"scenes": scenes}))
        return p

    def at(self, rule, trace, t, bind="v=1") -> dict:
        p = subprocess.run([str(self.explain), "--manifest", str(self.manifest), "--reading", str(self.reading), "--rule", rule,
                            "--bind", bind, "--at", str(t), "--json", str(trace)], capture_output=True, text=True)
        self.assertEqual(p.returncode, 0, p.stderr)
        return json.loads(p.stdout)["groundings"][0]["explanations"][0]["obligation"]["cmp"]

    #: a left turn at 10°/s, sampled at 100 ms, the onset rising at 200 ms
    TURN = [scene(t, on=t >= 200) for t in range(0, 1001, 100)]

    def test_a_direct_occurrence_shows_its_start_and_the_observations_around_it(self):
        cmp = self.at("h/direct", self.trace("turn", self.TURN), 700)
        (h,) = cmp["heading_since"]
        self.assertEqual(cmp["heading_since_coverage"], "complete")
        self.assertEqual((h["path"], h["subject"], h["track"], h["located"]), ("lhs", "v", 1, True))
        self.assertEqual((h["before_ms"], h["anchor_ms"], h["after_ms"]), (100, 200, 300))
        self.assertEqual(h["exact"], {"num": 5, "den": 1})
        self.assertEqual(h["step"]["param"], "p.step")
        self.assertEqual(h["step"]["value"], {"num": 1, "den": 1})
        self.assertIn("asm.onset", h["onset"]["written"])
        self.assertIn("decided", h["how"])

    def test_an_occurrence_inside_arithmetic_is_located(self):
        cmp = self.at("h/abs", self.trace("turn", self.TURN), 700)
        (h,) = cmp["heading_since"]
        self.assertEqual((h["path"], h["located"], h["anchor_ms"]), ("lhs.0", True, 200))

    def test_an_occurrence_inside_an_onset_keeps_the_coverage_partial(self):
        cmp = self.at("h/nested", self.trace("turn", self.TURN), 700)
        paths_ = {h["path"]: h for h in cmp["heading_since"]}
        self.assertEqual(set(paths_), {"lhs", "lhs.1.lhs"})
        self.assertTrue(paths_["lhs"]["located"])
        self.assertFalse(paths_["lhs.1.lhs"]["located"])
        self.assertIn("onset", paths_["lhs.1.lhs"]["not_located"])
        self.assertEqual(cmp["heading_since_coverage"], "partial")

    def test_a_concept_call_is_reported_where_the_expansion_put_it(self):
        cmp = self.at("h/concept", self.trace("turn", self.TURN), 700)
        (h,) = cmp["heading_since"]
        self.assertEqual((h["path"], h["exact"]), ("lhs", {"num": 5, "den": 1}))

    def test_a_long_bracket_is_a_sampling_gap_and_names_its_interval(self):
        cmp = self.at("h/direct", self.trace("gap", [scene(0, on=False), scene(100000), scene(100100)]), 100100)
        (h,) = cmp["heading_since"]
        self.assertEqual(h["unknown"], "sampling_gap:heading_since")
        self.assertEqual((h["before_ms"], h["anchor_ms"]), (0, 100000))
        self.assertIn("t=0…100000 ms", h["how"])
        self.assertIn("the bracket of the onset", h["how"])

    def test_absences_are_told_apart(self):
        missing = [scene(t, on=t >= 100, yaw=None if t == 300 else 10.0) for t in range(0, 501, 100)]
        h = self.at("h/direct", self.trace("missing", missing), 400)["heading_since"][0]
        self.assertEqual(h["unknown"], "absent_atom:kin_yaw_rate")
        self.assertIn("missing at t=300 ms, the track present", h["how"])
        late = [scene(t, on=t >= 100, present=t >= 300) for t in range(0, 501, 100)]
        h = self.at("h/direct", self.trace("late", late), 400)["heading_since"][0]
        self.assertIn("before its first sighting", h["how"])
        self.assertNotIn("identity", h["how"])
        gone = [scene(t, on=t >= 100, present=t != 300) for t in range(0, 501, 100)]
        h = self.at("h/direct", self.trace("gone", gone), 400)["heading_since"][0]
        self.assertIn("between two of its sightings", h["how"])

    def test_an_accepted_link_with_adjacent_sightings_continues_decided(self):
        joined = [scene(t, on=t >= 100, track=1 if t <= 300 else 5, links=[(1, 5)] if t == 400 else ()) for t in range(0, 701, 100)]
        h = self.at("h/direct", self.trace("joined", joined), 700)["heading_since"][0]
        self.assertEqual(h["exact"], {"num": 6, "den": 1})
        self.assertEqual(h["track"], 1)

    def test_the_window_diagnosis_gets_no_eligible_piece(self):
        trace = self.trace("open", [scene(t, on=True) for t in range(0, 1001, 100)])
        p = subprocess.run([str(self.explain), "--manifest", str(self.manifest), "--reading", str(self.reading), "--rule", "h/direct",
                            "--bind", "v=1", "--scan", "--json", str(trace)], capture_output=True, text=True)
        self.assertEqual(p.returncode, 0, p.stderr)
        w = json.loads(p.stdout)["groundings"][0]["windows"]
        self.assertTrue(w["pieces"])
        piece = w["pieces"][0]
        self.assertEqual((piece["op"], piece["located"]), ("quantity heading_since", True))
        self.assertEqual(piece["heading_since"]["path"], "lhs")
        m = subprocess.run([str(self.monitor), "--manifest", str(self.manifest), "--reading", str(self.reading), "--rules", "h/direct",
                            "--json", "--segments", str(trace)], capture_output=True, text=True)
        self.assertEqual(m.returncode, 0, m.stderr)
        s = scoring.score("rec", "L", "compliant", scoring.rule_results(m.stdout.splitlines()), {"h/direct": "L"})
        scoring.diagnose_windows(s, [{"rule": "h/direct", "binding": {"v": 1}, "ok": True, "windows": w, "current": True, "error": ""}],
                                 label_check.reading_params(self.reading))
        self.assertTrue(s.windows["pieces"])
        self.assertFalse(any(p["eligible"] for p in s.windows["pieces"]))
        self.assertTrue(s.windows["partial"])
        self.assertIn("no metric window", s.windows["pieces"][0]["not_eligible"])


if __name__ == "__main__":
    unittest.main()
