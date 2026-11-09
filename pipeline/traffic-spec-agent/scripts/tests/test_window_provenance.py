"""Explain's truncated windows on the real Core, with a library of the test's own (the working Core,
Explain and monitor, a registry of rules and concepts written here) and a synthetic trace: two
vehicles, fast from the first observation, so every window behind is truncated until it fits.

Each window is traced to where it is written: two calls of one concept are two pieces told apart by
their call sites and parameters; a parameter passed through a concept's own formal shows both calls;
a quantifier's variable keeps its renamed name in the binding; a window inside another is met at an
earlier observation than the one scored; a window in a branch that does not decide the verdict is
not reported; `since`, a literal length, a primitive's window, a look-ahead window and a composed rule
are reported as what they are. On the real monitor's report of the whole recording (a label judges
the whole recording) the label check's window diagnosis then makes eligible exactly the parameter
windows whose own truncation the ego's unknown carries, wherever in the recording it lies, and no
window whose truncation the Core reads but does not propagate. Skipped only where Lake is not
installed or the working library is not built."""
import json
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path

from harness.phases import label_check
from harness.store import paths
from recorded import projection, scoring
from scripts.tests.test_monitor_segments import WORKING, own_library

INDEX = """import TrafficSpec.Core
namespace TrafficSpec
def wV : Arg := .var "v"
def wFast (a : Arg) : Formula := .cmp (.measure "kin_speed" [a]) .gt (.lit (Units.metresPerSecond 1) .metrePerSecond)
def wCls : List Binder := [{ name := "v", cls := .atom "ru_motor_vehicle" [wV] [] }]
def wKept : Concept :=
  { id := "drv.t.kept", contract := "x moves at every observation of the window behind", args := [("x", .track)],
    params := [{ name := "d", unit := .second }], body := .formula (.holdsFor .time (.param "d") "x" (wFast (.var "x"))) }
def wOuter : Concept :=
  { id := "drv.t.outer", contract := "y kept moving", args := [("y", .track)], params := [{ name := "w", unit := .second }],
    body := .formula (.derived "drv_t_kept" [.var "y"] [.param "w"]) }
def wOther : Concept :=
  { id := "drv.t.other", contract := "another road user moves at every observation of the window behind", args := [("x", .track)],
    params := [{ name := "d", unit := .second }],
    body := .formula (.existsUser "u" (.and (.not (.same (.var "x") (.var "u"))) (.holdsFor .time (.param "d") "u" (wFast (.var "u"))))) }
def wRule (id : String) (obl : Formula) : Rule := { id, laws := [], binders := wCls, applicability := .tt, obligation := obl }
def allRules : List Rule := [
  wRule "t/twin" (.and (.derived "drv_t_kept" [wV] [.param "p.a"]) (.derived "drv_t_kept" [wV] [.param "p.b"])),
  wRule "t/nest" (.derived "drv_t_outer" [wV] [.param "p.c"]),
  wRule "t/other" (.derived "drv_t_other" [wV] [.param "p.a"]),
  wRule "t/since" (.since (wFast wV) (.not (wFast wV))),
  wRule "t/lit" (.holdsFor .time (.lit (Units.seconds 3) .second) "v" (wFast wV)),
  wRule "t/ahead" (.within .time (.param "p.e") "v" (.not (wFast wV))),
  wRule "t/ahead_end" (.within .time (.param "p.e") "v" (.cmp (.measure "kin_position" [wV, .lit "x"]) .lt (.lit (Units.metres 60) .metre))),
  wRule "t/branch" (.and (.holdsFor .time (.param "p.b") "v" (wFast wV)) (.or (wFast wV) (.holdsFor .time (.param "p.a") "v" (wFast wV)))),
  wRule "t/comp" (.rule "t/twin" [("v", "v")]),
  wRule "t/inner" (.holdsFor .time (.param "p.b") "v" (.holdsFor .time (.param "p.a") "v" (wFast wV))),
  wRule "t/prim" (.cmp (.quantity "prim_heading_change" [wV] [.param "p.a"]) .lt (.lit (Units.degrees 90) .degree)),
  wRule "t/unit" (.holdsFor .time (.param "p.m") "v" (wFast wV)),
  wRule "audit/guard" (.definedWhen (.holdsFor .time (.lit (Units.seconds 20) .second) "v" (wFast wV))
    (.holdsFor .time (.param "p.b") "v" (wFast wV))),
  wRule "audit/guard_control" (.definedWhen (.holdsFor .time (.lit (Units.seconds 20) .second) "v" (wFast wV)) .tt),
  wRule "audit/until" (.untilWithin .time (.param "p.e") "v" .ff (.untilWithin .time (.lit (Units.seconds 20) .second) "v" .tt .ff)),
  wRule "audit/until_control" (.untilWithin .time (.lit (Units.seconds 1) .second) "v" .ff
    (.untilWithin .time (.lit (Units.seconds 20) .second) "v" .tt .ff)),
  wRule "audit/coverage" (.holdsFor .time (.lit (Units.seconds 1) .second) "v"
    (.or (.and (.cmp (.measure "kin_position" [wV, .lit "x"]) .lt (.lit (Units.metres 25) .metre))
               (.holdsFor .time (.param "p.e") "v" (wFast wV)))
         (.and (.not (.cmp (.measure "kin_position" [wV, .lit "x"]) .lt (.lit (Units.metres 25) .metre)))
               (.holdsFor .time (.param "p.b") "v" (wFast wV)))))]
def allConcepts : List Concept := [wKept, wOuter, wOther]
end TrafficSpec
"""

READING = {"params": [{"name": "p.a", "value": 2, "unit": "s"}, {"name": "p.b", "value": 4, "unit": "s"},
                      {"name": "p.c", "value": 3, "unit": "s"}, {"name": "p.e", "value": 6, "unit": "s"},
                      {"name": "p.m", "value": 2, "unit": "m"}]}


def user(track: int, x: float) -> dict:
    return {"track": track, "classes": ["motor_vehicle"],
            "kin": {"position": [x, 3.0 * track], "heading": [1, 0], "velocity": [10, 0], "speed": 10, "yaw_rate": 0,
                    "extent": [2, 0.9, 0.75]}}


#: observations every 500 ms over 10 s; both vehicles at 10 m/s throughout
TRACE = {"scenes": [{"t": t, "subject": 1, "occupancy_observed": True, "env": {"wet_road": False, "ice_or_snow": False},
                     "users": [user(1, t / 100), user(2, 50 + t / 100)]} for t in range(0, 10001, 500)]}


@unittest.skipUnless(shutil.which("lake") and (WORKING / ".lake" / "build" / "lib" / "lean" / "TrafficSpec" / "Core").is_dir(),
                     "Lake is not installed or the working library is not built")
class WindowProvenance(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.tmp = tempfile.TemporaryDirectory()
        root = Path(cls.tmp.name)
        cls.monitor = own_library(root, INDEX)
        cls.explain = cls.monitor.with_name("explain")
        cls.trace, cls.manifest, cls.reading = root / "trace.json", root / "manifest.json", root / "reading.json"
        cls.reading.write_text(json.dumps(READING))
        cls.trace.write_text(json.dumps(TRACE))
        ids = projection.atom_ids(paths.CORE / "Vocab" / "Ontology" / "Ids.lean")
        cls.manifest.write_text(json.dumps({"source": "test", "reid_gap": 0, "atoms": {a: "exact" for a in ids}}))
        cls.cache = {}

    @classmethod
    def tearDownClass(cls):
        cls.tmp.cleanup()

    def windows(self, rule: str) -> dict:
        """Explain's truncated windows of the rule's grounding over the whole trace."""
        if rule not in self.cache:
            p = subprocess.run([str(self.explain), "--manifest", str(self.manifest), "--reading", str(self.reading), "--rule", rule,
                                "--bind", "v=1", "--scan", "--json", str(self.trace)], capture_output=True, text=True)
            self.assertEqual(p.returncode, 0, p.stderr)
            self.cache[rule] = json.loads(p.stdout)["groundings"][0]["windows"]
        return self.cache[rule]

    def diagnosed(self, rule: str) -> scoring.Scored:
        """The rule's recording scored on the real monitor's report, and diagnosed on Explain's."""
        p = subprocess.run([str(self.monitor), "--manifest", str(self.manifest), "--reading", str(self.reading), "--rules", rule,
                            "--json", "--segments", str(self.trace)], capture_output=True, text=True)
        self.assertEqual(p.returncode, 0, p.stderr)
        s = scoring.score("rec", "L", "compliant", scoring.rule_results(p.stdout.splitlines()), {rule: "L"})
        scoring.diagnose_windows(s, [{"rule": rule, "binding": {"v": 1}, "ok": True, "windows": self.windows(rule),
                                      "current": True, "error": ""}], label_check.reading_params(self.reading))
        return s

    def assert_same_verdict(self, a: scoring.Scored, b: scoring.Scored, ra: str, rb: str):
        ga, gb = a.rules[ra]["judged"][0], b.rules[rb]["judged"][0]
        self.assertEqual((a.status, ga["reasons"], ga["segments"]), (b.status, gb["reasons"], gb["segments"]))

    def test_a_definedWhen_body_its_guard_masks_gives_no_eligibility(self):
        # the body's window p.b is truncated before 4 s too, but the guard is unknown throughout and the Core takes its reasons only
        main, control = self.diagnosed("audit/guard"), self.diagnosed("audit/guard_control")
        self.assert_same_verdict(main, control, "audit/guard", "audit/guard_control")
        self.assertEqual(main.rules["audit/guard"]["judged"][0]["reasons"], ["window_truncated:holdsFor"])
        self.assertEqual((scoring.library_actionable(main), scoring.library_actionable(control)), (False, False))
        self.assertEqual([p["expanded_path"] for p in main.windows["pieces"]], ["obligation.0"])     # the guard's window only
        self.assertNotIn("p.b", json.dumps(main.windows["pieces"]))

    def test_an_untilWithin_whose_remainder_is_already_false_is_not_its_own_source(self):
        # the outer window p.e is truncated from 4.5 s on, but its remainder is false there: the inner window decides
        main, control = self.diagnosed("audit/until"), self.diagnosed("audit/until_control")
        self.assert_same_verdict(main, control, "audit/until", "audit/until_control")
        self.assertEqual((scoring.library_actionable(main), scoring.library_actionable(control)), (False, False))
        self.assertEqual([p["expanded_path"] for p in main.windows["pieces"]], ["obligation.1"])     # the inner literal window
        self.assertNotIn("p.e", json.dumps(main.windows["pieces"]))

    def test_a_missed_contributing_source_marks_the_search_partial(self):
        w = self.windows("audit/coverage")
        self.assertEqual((w["unknown_instants"], w["with_located_source"], w["search_complete"]), (10, 10, 3))
        self.assertTrue(any(c.startswith("unexamined:") for c in w["cut"]), w["cut"])
        s = self.diagnosed("audit/coverage")
        self.assertTrue(s.windows["partial"])
        self.assertEqual(s.windows["coverage"]["search_complete"], 3)
        text = "\n".join(label_check.window_block(s))
        self.assertIn("the cause search was complete at 3", text)
        self.assertIn("Partial:", text)

    def test_a_truncation_anywhere_in_the_recording_that_reaches_the_ego_is_eligible(self):
        # mid-recording: the window p.b met from 3.5 s, evaluated from 2.5 s
        s = self.diagnosed("audit/coverage")
        b = next(p for p in s.windows["pieces"] if (p["length"] or {}).get("param") == "p.b")
        self.assertEqual((b["scoring"]["first_ms"], b["evaluated"]["first_ms"], b["eligible"]), (3500, 2500, True))
        self.assertTrue(scoring.library_actionable(s))
        # at the end: a window ahead truncated by the trace's end, the rule compliant before it
        s = self.diagnosed("t/ahead_end")
        g = s.rules["t/ahead_end"]["judged"][0]
        self.assertEqual([(x["from"], x["to"], x["verdict"]) for x in g["segments"]], [(0, 5500, "compliant"), (6000, 10000, "unknown")])
        (p,) = s.windows["pieces"]
        self.assertEqual((p["op"], p["direction"], p["length"]["param"], p["scoring"]["first_ms"], p["scoring"]["last_ms"], p["eligible"]),
                         ("within", "look-ahead", "p.e", 6000, 10000, True))
        self.assertTrue(scoring.library_actionable(s))

    def test_two_calls_of_one_concept_are_two_pieces(self):
        w = self.windows("t/twin")
        self.assertEqual((w["source_map"], w["from_ms"], w["to_ms"], w["unknown_instants"], w["with_located_source"], w["search_complete"],
                          w["cut"]), ("ok", 0, 10000, 8, 8, 8, []))
        a, b = w["pieces"]
        for p, call, tag, param, n in ((a, "obligation.0", "0", "p.a", 4), (b, "obligation.1", "1", "p.b", 8)):
            self.assertEqual((p["op"], p["located"], p["direction"], p["measure"]), ("holdsFor", True, "look-back", "time"))
            self.assertEqual(p["source"]["owner"], "concept drv.t.kept")
            self.assertEqual(p["source"]["path"], "body")
            self.assertEqual([(c["concept"], c["owner"], c["path"], c["tag"], c["params"]) for c in p["calls"]],
                             [("drv.t.kept", "rule t/twin", call, tag, {"d": param})])
            self.assertEqual((p["length"]["written"], p["length"]["substituted"], p["length"]["param"], p["length"]["unit"]),
                             ("d", param, param, "second"))
            self.assertEqual((p["scoring"]["first_ms"], p["scoring"]["instants"]), (0, n))
            self.assertFalse(p["example"]["observed"]["covered"])
        self.assertEqual(a["example"]["requested"], {"from": {"num": -2, "den": 1}, "to": {"num": 0, "den": 1}, "unit": "s"})
        self.assertEqual((a["example"]["observed"]["from_ms"], a["example"]["observed"]["to_ms"]), (0, 0))

    def test_a_parameter_passed_through_a_formal_keeps_both_calls(self):
        (p,) = self.windows("t/nest")["pieces"]
        self.assertEqual([(c["concept"], c["owner"], c["path"], c["params"]) for c in p["calls"]],
                         [("drv.t.outer", "rule t/nest", "obligation", {"w": "p.c"}),
                          ("drv.t.kept", "concept drv.t.outer", "body", {"d": "p.c"})])
        self.assertEqual((p["length"]["written"], p["length"]["param"]), ("d", "p.c"))

    def test_a_renamed_variable_keeps_its_binding(self):
        (p,) = self.windows("t/other")["pieces"]
        renamed = {k: v for k, v in p["binding"].items() if k.startswith("u#")}
        self.assertEqual(list(renamed.values()), ["track 2"])
        self.assertEqual(p["binding"]["v"], "track 1")
        self.assertEqual((p["subject"]["written"], p["subject"]["evaluated"]), ("u", next(iter(renamed))))
        self.assertEqual(p["source"]["path"], "body.0.1")

    def test_a_nested_window_is_met_at_an_earlier_observation(self):
        pieces = self.windows("t/inner")["pieces"]
        inner = next(p for p in pieces if p["length"]["param"] == "p.a")
        outer = next(p for p in pieces if p["length"]["param"] == "p.b")
        self.assertEqual((inner["expanded_path"], inner["source"]["path"]), ("obligation.0", "obligation.0"))
        self.assertEqual((inner["scoring"]["first_ms"], inner["evaluated"]["first_ms"]), (4000, 0))
        self.assertLess(inner["evaluated"]["last_ms"], inner["scoring"]["last_ms"])
        self.assertEqual(outer["scoring"]["first_ms"], outer["evaluated"]["first_ms"])

    def test_a_window_in_a_branch_that_does_not_decide_is_not_reported(self):
        w = self.windows("t/branch")
        self.assertEqual([p["length"]["param"] for p in w["pieces"]], ["p.b"])
        self.assertEqual(w["pieces"][0]["source"]["path"], "obligation.0")

    def test_other_windows_are_reported_as_what_they_are(self):
        (since,) = self.windows("t/since")["pieces"]
        self.assertEqual((since["op"], since["located"], since["direction"], since["length"]), ("since", True, "look-back", {"param": None}))
        (lit,) = self.windows("t/lit")["pieces"]
        self.assertEqual((lit["op"], lit["length"]["param"], lit["length"]["written"]), ("holdsFor", None, "3.000"))
        (ahead,) = self.windows("t/ahead")["pieces"]
        self.assertEqual((ahead["op"], ahead["direction"], ahead["length"]["param"], ahead["scoring"]["first_ms"]),
                         ("within", "look-ahead", "p.e", 4500))
        (prim,) = self.windows("t/prim")["pieces"]
        self.assertEqual((prim["op"], prim["located"]), ("quantity prim_heading_change", True))
        comp = self.windows("t/comp")["pieces"]
        self.assertTrue(comp and all(not p["located"] for p in comp))
        self.assertIn("composed rule t/twin", comp[0]["not_located"])
        self.assertEqual((self.windows("t/comp")["with_located_source"], self.windows("t/comp")["search_complete"]), (0, 0))

    def test_the_label_check_diagnoses_the_real_reports(self):
        want = {"t/twin": True, "t/nest": True, "t/other": True, "t/inner": True, "t/ahead_end": True, "t/since": False,
                "t/lit": False, "t/prim": False, "t/comp": False, "t/unit": False}
        for rule, eligible in want.items():
            with self.subTest(rule=rule):
                s = self.diagnosed(rule)
                self.assertEqual(s.status, "unknown")
                self.assertEqual(scoring.library_actionable(s), eligible, s.windows)
        # violated before its window ahead is truncated: the whole recording is decided, nothing to diagnose
        s = self.diagnosed("t/ahead")
        self.assertEqual((s.verdict, s.status, s.windows, scoring.library_actionable(s)), ("violated", "mismatch", None, False))


if __name__ == "__main__":
    unittest.main()
