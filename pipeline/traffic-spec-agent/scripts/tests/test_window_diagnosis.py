"""The window diagnosis, on synthetic recordings with the stand-in monitor and Explain (a label judges
the whole recording): a truncated window Explain locates as carried by the ego's unknown, wherever
in the recording, gives its blocker a `window_diagnosis` eligibility, which routes the law to the
budgeted coverage repair while the blocker keeps its attribution (`history`, `time_contract`); a
recording decided elsewhere, a truncation the ego's unknown does not carry, an Explain that failed
or is stale, a window with no reading parameter for its length, a look-ahead window said to look
back, a primitive's own window, a piece whose source is not located and a piece the recording's own
segments do not show give none. The evidence block states the located facts, the coverage, a
partial coverage and, for an eligible window, that a window should be anchored to the event. The
harness's own limits stay: a changed contract is refused, and an unknown turned mismatch is kept,
routed to a semantic repair, never aligned by it, its count of repairs not reset."""
import itertools
import json
import shutil
import tempfile
import unittest
from fractions import Fraction
from pathlib import Path
from unittest import mock

from harness import loop
from harness.agents import session
from harness.phases import candidate as cand
from harness.phases import label_check
from harness.store import paths
from recorded import scoring
from scripts.tests.test_candidate import Base, CA, Txn, concept_rec, standard, world
from scripts.tests.test_label_check import LAW_OF, TIMES, _Fixture, make_dataset, sg
from scripts.tests.test_label_repair import L, N, RECS
from scripts.tests.test_label_repair_lifecycle import REC5, Responder
from scripts.tests.test_label_repair_session import DIFF5, repair, repairing, set_verdict

H = "window_truncated:holdsFor"
READING = {"params": [{"name": "p.turn", "value": 20, "unit": "s"}, {"name": "p.gap", "value": 5, "unit": "m"},
                      {"name": "p.ahead", "value": 8, "unit": "s"}]}


def piece(rule="R1", op="holdsFor", param="p.turn", value=20, unit="second", measure="time", direction=None, located=True,
          first=3000, last=5000, call="obligation.0", tag="0", covered=False, why="") -> dict:
    """One piece of window evidence as Explain reports it."""
    direction = direction or scoring.WINDOW_OPS.get(op, "look-back")
    p = {"rule": rule, "op": op, "located": located, "expanded_path": call,
         "source": {"owner": "concept drv.t.kept", "path": "body", "written": "throughout the window behind (time)"},
         "calls": [{"concept": "drv.t.kept", "owner": f"rule {rule}", "path": call, "tag": tag, "args": {"x": "x"},
                    "params": {"d": param or "3.000"}}],
         "binding": {"x": "track 1"}, "scoring": {"first_ms": first, "last_ms": last, "instants": 3},
         "evaluated": {"first_ms": first, "last_ms": last}}
    if not located:
        p["not_located"] = why or "a window of the composed rule R9: its source is not traced"
    if op in scoring.WINDOW_OPS:
        p |= {"measure": measure, "direction": direction, "subject": {"written": "x", "evaluated": "x"},
              "length": {"written": "d", "substituted": param or "3.000", "param": param,
                         **({"value": {"num": value, "den": 1}, "unit": unit} if param else {})},
              "example": {"scoring_ms": first, "evaluated_ms": first,
                          "requested": {"from": {"num": first // 1000 - value, "den": 1}, "to": {"num": first // 1000, "den": 1}, "unit": "s"},
                          "observed": {"from": {"num": 0, "den": 1}, "to": {"num": first // 1000, "den": 1}, "from_ms": 0,
                                       "to_ms": first, "covered": covered, "adequate": True}}}
    else:
        p |= {"length": {"param": None}}
    return p


def section(pieces, unknown=4, explained=4, cut=(), source_map="ok", located=None) -> dict:
    return {"from_ms": TIMES[0], "to_ms": TIMES[-1], "source_map": source_map, "unknown_instants": unknown,
            "walked": unknown, "with_located_source": explained if located is None else located,
            "search_complete": explained, "cut": list(cut), "pieces": pieces}


def unknown_r1(reasons=(H,), windows=None, **more) -> dict:
    """R1 unknown until 6 s for `reasons`, then compliant, R2 not applicable; Explain reports `windows` for R1."""
    return {"R1": [["", {"x": 1}, [], [sg(0, 6000, "unknown", reasons), sg(7000, 9000, "compliant")]]],
            "R2": [["", {"x": 1}, [], [sg(0, 9000, "not_applicable")]]],
            **({"windows": {"R1": windows}} if windows is not None else {}), **more}


class _Windows(_Fixture):
    def setUp(self):
        super().setUp()
        self.reading.write_text(json.dumps(READING))

    def check2(self, spec, label="compliant"):
        shutil.rmtree(self.root / "ds", ignore_errors=True)
        self.ds = make_dataset(self.root / "ds", [("a", "L", label, False, spec)])
        c = label_check.check_law("L", ["R1", "R2"], LAW_OF, self.ds, self.mon, self.exp, self.reading, self.lim)
        return c, c.scored[0]

    def blocker(self, s, reason=H):
        return next(b for b in s.blockers if b["reason"] == reason)


class Eligibility(_Windows):

    def test_a_located_window_routes_to_the_coverage_repair_and_keeps_its_attribution(self):
        c, s = self.check2(unknown_r1(windows=section([piece()])))
        b = self.blocker(s)
        self.assertEqual((b["class"], b["handling"]), ("history", "time_contract"))
        self.assertEqual(b["window_diagnosis"], {"eligible": True, "pieces": [0]})
        self.assertTrue(scoring.library_actionable(s))
        self.assertEqual((c.outcome, label_check.goal_for(c.outcome)), ("undecided", "coverage"))
        text = label_check.render_evidence(c)
        self.assertIn("Window diagnosis", text)
        self.assertIn("R1: `holdsFor` (look-back, time) at concept drv.t.kept body", text)
        self.assertIn("after substitution `p.turn` = 20 second", text)
        self.assertIn("eligible for diagnosis", text)
        self.assertIn("type `coverage`, object `parameter`", text)
        anchor = ("A window should be anchored to the event itself, for example by looking back to the start of the action, "
                  "not depend on history from before the recording began.")
        self.assertIn(anchor, text)
        self.assertLess(text.index("Window diagnosis eligible for"), text.index(anchor))
        self.assertLess(text.index(anchor), text.index("type `coverage`"))
        self.assertNotIn("residue", text)
        self.assertIn("Window diagnosis eligible for: R1 `window_truncated:holdsFor`", text)
        self.assertNotIn("Partial:", text)
        self.assertNotIn('"windows"', json.dumps([e.report for e in c.evidence]))     # the facts are rendered once, as facts
        self.assertEqual(c.to_dict()["scored"][0]["blockers"][0]["handling"], "time_contract")

    def test_a_recording_decided_elsewhere_gives_nothing(self):
        spec = {"R1": [["", {"x": 1}, [], [sg(0, 2000, "unknown", [H]), sg(3000, 3000, "violated"), sg(4000, 9000, "compliant")]]],
                "R2": [["", {"x": 1}, [], [sg(0, 9000, "not_applicable")]]], "windows": {"R1": section([piece(first=0, last=2000)])}}
        c, s = self.check2(spec, label="violation")
        self.assertEqual((s.status, s.windows, s.blockers, c.outcome), ("match", None, [], "aligned"))

    def test_a_truncation_anywhere_that_the_egos_unknown_carries_is_eligible(self):
        W = "window_truncated:within"
        cases = {"at the start": ([sg(0, 1000, "unknown", [H]), sg(2000, 9000, "compliant")], H, piece(first=0, last=1000)),
                 "in the middle": ([sg(0, 3000, "compliant"), sg(4000, 5000, "unknown", [H]), sg(6000, 9000, "compliant")], H,
                                   piece(first=4000, last=5000)),
                 "at the end": ([sg(0, 7000, "compliant"), sg(8000, 9000, "unknown", [W])], W,
                                piece(op="within", param="p.ahead", value=8, first=8000, last=9000))}
        for where, (segs, reason, p) in cases.items():
            with self.subTest(where=where):
                spec = {"R1": [["", {"x": 1}, [], segs]], "R2": [["", {"x": 1}, [], [sg(0, 9000, "not_applicable")]]],
                        "windows": {"R1": section([p], unknown=2, explained=2)}}
                c, s = self.check2(spec)
                self.assertEqual(s.status, "unknown")
                self.assertEqual(self.blocker(s, reason)["window_diagnosis"], {"eligible": True, "pieces": [0]})
                self.assertEqual((scoring.library_actionable(s), c.outcome), (True, "undecided"))

    def test_a_truncation_the_egos_unknown_does_not_carry_is_not_eligible(self):
        segs = [sg(0, 2000, "unknown", ["sampling_gap:once"]), sg(3000, 5000, "unknown", [H]), sg(6000, 9000, "compliant")]
        cases = {"where the ego's grounding is compliant": piece(first=7000, last=8000),
                 "where its unknown has another reason": piece(first=1000, last=2000)}
        for why, p in cases.items():
            with self.subTest(why=why):
                spec = {"R1": [["", {"x": 1}, [], segs]], "R2": [["", {"x": 1}, [], [sg(0, 9000, "not_applicable")]]],
                        "windows": {"R1": section([p])}}
                c, s = self.check2(spec)
                self.assertEqual(s.status, "unknown")
                self.assertIn("not unknown with this window's reason", s.windows["pieces"][0]["not_eligible"])
                self.assertFalse(self.blocker(s)["window_diagnosis"]["eligible"])
                self.assertEqual((scoring.library_actionable(s), c.outcome), (False, "unverified"))
        # another road user's grounding, unknown with the same reason: the label does not judge it
        spec = {"R1": [["", {"x": 1}, [], segs], ["", {"x": 2}, [], [sg(0, 9000, "unknown", [H])]]],
                "R2": [["", {"x": 1}, [], [sg(0, 9000, "not_applicable")]]]}
        c, s = self.check2(spec)
        scoring.diagnose_windows(s, [{"rule": "R1", "binding": {"x": 2}, "ok": True, "windows": section([piece()]),
                                      "current": True, "error": ""}], label_check.reading_params(self.reading))
        self.assertIn("not unknown with this window's reason", s.windows["pieces"][0]["not_eligible"])
        self.assertFalse(scoring.library_actionable(s))

    def test_two_windows_of_one_rule_are_told_apart_by_their_calls(self):
        twin = section([piece(), piece(param="p.gap", value=5, unit="metre", call="obligation.1", tag="1")], unknown=4, explained=4)
        c, s = self.check2(unknown_r1(windows=twin))
        a, b = s.windows["pieces"]
        self.assertEqual(([x["path"] for x in a["calls"]], [x["path"] for x in b["calls"]]), (["obligation.0"], ["obligation.1"]))
        self.assertEqual((a["calls"][0]["concept"], b["calls"][0]["concept"]), ("drv.t.kept", "drv.t.kept"))
        self.assertEqual((a["eligible"], b["eligible"]), (True, False))
        self.assertIn("in metre, not the second a time window reads", b["not_eligible"])
        self.assertEqual(self.blocker(s)["window_diagnosis"], {"eligible": True, "pieces": [0]})
        text = label_check.render_evidence(c)
        self.assertIn("called at rule R1 obligation.0, tag 0", text)
        self.assertIn("called at rule R1 obligation.1, tag 1", text)

    def test_parameterless_look_ahead_and_primitive_windows_are_not_shortenable_look_back_parameters(self):
        W, S, P = "window_truncated:within", "window_truncated:since", "window_truncated:prim_heading_change"
        pieces = [piece(param=None), piece(op="within", param="p.ahead", value=8), piece(op="within", param="p.ahead", value=8, direction="look-back"),
                  piece(op="since", param=None), piece(op="quantity prim_heading_change", param=None)]
        c, s = self.check2(unknown_r1(reasons=(H, W, S, P), windows=section(pieces)))
        got = [(p["op"], p.get("direction"), p["eligible"]) for p in s.windows["pieces"]]
        self.assertEqual(got, [("holdsFor", "look-back", False), ("within", "look-ahead", True), ("within", "look-back", False),
                               ("since", None, False), ("quantity prim_heading_change", None, False)])
        self.assertIn("not a reading parameter", s.windows["pieces"][0]["not_eligible"])
        self.assertIn("`within` reads look-ahead", s.windows["pieces"][2]["not_eligible"])
        self.assertIn("no metric window", s.windows["pieces"][3]["not_eligible"])
        self.assertIn("no metric window", s.windows["pieces"][4]["not_eligible"])
        self.assertEqual({b["reason"]: b["window_diagnosis"]["eligible"] for b in s.blockers}, {H: False, W: True, S: False, P: False})
        self.assertIn("`within` (look-ahead, time)", label_check.render_evidence(c))

    def test_mixed_blockers_keep_their_attribution(self):
        c, s = self.check2(unknown_r1(reasons=("division_by_zero:div", H), windows=section([piece()])))
        self.assertEqual({b["reason"]: (b["class"], b["handling"]) for b in s.blockers},
                         {"division_by_zero:div": ("rule_semantic", "library"), H: ("history", "time_contract")})
        self.assertNotIn("window_diagnosis", self.blocker(s, "division_by_zero:div"))
        self.assertTrue(self.blocker(s)["window_diagnosis"]["eligible"])
        self.assertEqual(c.outcome, "undecided")

    def test_an_explain_failure_or_a_stale_report_creates_no_attribution(self):
        c, s = self.check2(unknown_r1(windows=section([piece()]), explain_fail=["R1"]))
        self.assertFalse(self.blocker(s)["window_diagnosis"]["eligible"])
        self.assertEqual((s.windows["pieces"], c.outcome), ([], "unverified"))
        self.assertTrue(any("Explain failed" in n for n in s.windows["notes"]))
        calls = itertools.count()
        with mock.patch.object(label_check, "explain_inputs", lambda *a: {"explain": next(calls), "reading": "r"}):   # the source changed meanwhile
            c, s = self.check2(unknown_r1(windows=section([piece()])))
        self.assertEqual((s.windows["pieces"], c.outcome), ([], "unverified"))
        self.assertTrue(any("not made on the current library and reading" in n for n in s.windows["notes"]))

    def test_one_complete_and_one_incomplete_piece_in_one_report(self):
        c, s = self.check2(unknown_r1(windows=section([piece(), piece(located=False)], unknown=6, explained=4, located=6)))
        a, b = s.windows["pieces"]
        self.assertEqual((a["eligible"], b["eligible"]), (True, False))
        self.assertIn("source not located", b["not_eligible"])
        self.assertTrue(self.blocker(s)["window_diagnosis"]["eligible"])
        self.assertEqual(s.windows["coverage"], {"unknown_observations": 6, "with_located_source": 6, "search_complete": 4,
                                                   "groundings_not_explained": 0})
        self.assertTrue(s.windows["partial"])
        text = label_check.render_evidence(c)
        self.assertIn("Coverage: of 6 unknown observation(s) with a truncated window, 6 have at least one located source and the "
                      "cause search was complete at 4", text)
        self.assertIn("Partial: this evidence does not cover every unknown observation", text)
        self.assertEqual(c.outcome, "undecided")

    def test_a_source_map_that_failed_gives_no_piece_eligibility(self):
        c, s = self.check2(unknown_r1(windows=section([piece()], source_map="the source map's expansion of obligation is not the library's")))
        self.assertFalse(s.windows["pieces"][0]["eligible"])
        self.assertEqual(c.outcome, "unverified")

    def test_the_reading_and_the_recordings_own_segments_are_checked(self):
        cases = {"differs from the current reading": piece(value=30),
                 "not shown truncated": piece(covered=True),
                 "not unknown with this window's reason": piece(first=7000, last=7000)}
        spec = unknown_r1()
        for why, p in cases.items():
            with self.subTest(why=why):
                c, s = self.check2({**spec, "windows": {"R1": section([p])}})
                self.assertIn(why, s.windows["pieces"][0]["not_eligible"])
                self.assertFalse(self.blocker(s)["window_diagnosis"]["eligible"])


class DoctorPattern(unittest.TestCase):

    def test_only_the_generic_approval_compound_passes(self):
        import re
        from scripts.diagnostics.doctor import LAW_FREE_PATTERNS
        rx = re.compile(LAW_FREE_PATTERNS["named rule family"])
        self.assertIsNone(rx.search("the existing reading proposal and operator-approval rules for parameter values"))
        for named in ("right-of-way rules", "speed-limit rules", "operator-approval-speed-limit rules"):
            with self.subTest(named=named):
                self.assertIsNotNone(rx.search(f"follow the {named} here"))


class VersionBinding(unittest.TestCase):

    def test_the_explain_source_is_part_of_the_scoring_version(self):
        with tempfile.TemporaryDirectory() as t:
            lib = Path(t)
            with mock.patch.object(paths, "LIBRARY", lib):
                (lib / "Explain.lean").write_text("-- one")
                one = label_check.scoring_version()
                (lib / "Explain.lean").write_text("-- two")
                self.assertNotEqual(one, label_check.scoring_version())

    def test_the_reading_and_the_explain_source_bind_a_report(self):
        with tempfile.TemporaryDirectory() as t:
            t = Path(t)
            exe = t / "lib" / ".lake" / "build" / "bin" / "explain"
            exe.parent.mkdir(parents=True)
            exe.write_text("")
            (t / "lib" / "Explain.lean").write_text("-- one")
            reading = t / "r.json"
            reading.write_text(json.dumps(READING))
            was = label_check.explain_inputs(exe, reading)
            (t / "lib" / "Explain.lean").write_text("-- two")
            self.assertNotEqual(was, label_check.explain_inputs(exe, reading))
            self.assertEqual(label_check.reading_params(reading)["p.gap"], ("metre", Fraction(5)))


def law5_unknown():
    """The recordings of the other laws, and law 5 with r5a alone, unknown for a truncated window Explain locates."""
    out = [r for r in RECS if r[1] != L[5]]
    w = section([piece(rule=N[5], first=TIMES[0], last=TIMES[-1])])
    return out + [("r5a", L[5], "compliant", False, {N[5]: [["unknown", {"x": 1}, [H]]], "windows": {N[5]: w}})]


PARAMS = {"p.turn": ("second", Fraction(20))}


class Routing(Base):

    def test_a_window_diagnosis_awaits_its_budgeted_coverage_repair_and_its_progress_is_kept_without_resetting_the_count(self):
        with mock.patch.object(label_check, "reading_params", lambda r: PARAMS), \
                repairing(recs=law5_unknown()) as (run, ledger, training, by_id):
            st = run.label_states[L[5]]
            self.assertEqual((st["outcome"], st["state"], st.get("repairs", 0)), ("undecided", "awaiting_label_repair", 0))
            self.assertIn("Window diagnosis eligible for", (run.dir / st["evidence"]).read_text())
            resp = Responder({"record.jsonl": REC5, "lean.diff": DIFF5}, {"record.jsonl": REC5})
            with mock.patch.object(session, "run", resp):
                set_verdict(training, "r5a", N[5], "violated")              # decided now, against its label
                first = repair(run, ledger, training, by_id)
                st = dict(run.label_states[L[5]])
                prompt = next(run.dir.glob("iter-*/label_repair/*/repair-01/prompt.md")).read_text()
                set_verdict(training, "r5a", N[5], "compliant")
                second = repair(run, ledger, training, by_id)
            self.assertIn("Repair goal: coverage", prompt)
            self.assertIn("Window-diagnosis evidence", prompt)
            self.assertIn("Window diagnosis eligible for", prompt)
            self.assertEqual((first, st["outcome"], st["state"], st["repairs"]), ("committed", "mismatch", "awaiting_label_repair", 1))
            self.assertEqual((second, run.label_states[L[5]]["outcome"], run.label_states[L[5]]["repairs"]), ("committed", "aligned", 2))

    def test_a_changed_contract_is_refused(self):
        concepts, nodes = standard()
        with world(concepts, nodes) as (run, _lib), Txn(run) as txn:
            with self.assertRaisesRegex(cand.ChangeRefused, "contract"):
                txn.apply([cand.Change("concept", CA, {**concepts[CA], "contract": concepts[CA]["contract"] + " Over a shorter window."})])


if __name__ == "__main__":
    unittest.main()
