"""Projection, scoring and decidability of recorded data, on synthetic inputs.

Projection keeps every active atom's state and the trace, drops held-out ids with a record, refuses
to drop an observed unknown capability, and handles retired classes as before. Scoring keeps a
fixed denominator: undecidable recordings are not matches, and a recording is scored once.
Decidability reads Core's support from the monitor's report on a probe trace."""
import hashlib
import io
import json
import os
import stat
import tempfile
import unittest
from pathlib import Path

from recorded import decidability, projection, scoring

ACTIVE = ["kin.speed", "ru.subject", "st.lane"]
FULL = ACTIVE + ["sig.reverse_lamp", "dev.school_bus_signal"]


class ProjectionTests(unittest.TestCase):
    def test_held_out_ids_are_dropped_and_recorded(self):
        m = {"source": "s", "atoms": {"kin.speed": "exact", "sig.reverse_lamp": "exact", "dev.school_bus_signal": "absent"}}
        out, rec = projection.project_manifest(m, ACTIVE, FULL, "train")
        self.assertEqual(out["atoms"], {"kin.speed": "exact", "ru.subject": "absent", "st.lane": "absent"})
        self.assertEqual(rec.excluded, {"sig.reverse_lamp": "exact", "dev.school_bus_signal": "absent"})
        self.assertEqual(set(rec.excluded_kind.values()), {"held_out"})
        self.assertEqual(rec.added_absent, ["ru.subject", "st.lane"])
        self.assertEqual(out["source"], "s")

    def test_active_states_are_never_rewritten(self):
        m = {"atoms": {"kin.speed": "estimate:kalman", "ru.subject": "subject", "st.lane": "absent"}}
        out, _ = projection.project_manifest(m, ACTIVE, FULL, "train")
        self.assertEqual(out["atoms"], m["atoms"])

    def test_an_observed_unknown_capability_is_not_dropped(self):
        with self.assertRaises(projection.ProjectionError):
            projection.project_manifest({"atoms": {"st.turnout": "exact"}}, ACTIVE, FULL, "train")
        out, rec = projection.project_manifest({"atoms": {"st.turnout": "absent"}}, ACTIVE, FULL, "train")
        self.assertEqual(rec.excluded_kind, {"st.turnout": "retired"})
        with self.assertRaises(projection.ProjectionError):
            projection.project_manifest({"atoms": {"x.unknown": "absent"}}, ACTIVE, FULL, "train")

    def test_trace_copied_with_retired_unobserved_classes_dropped(self):
        scenes = [{"t": 0, "users": [{"track": 1, "classes": ["motor_vehicle"], "unobserved_classes": ["low_speed_vehicle", "bicycle"],
                                      "kin": {"speed": 1.5}, "label": "é"}]},
                  {"t": 50, "users": []}]
        raw = json.dumps({"scenes": scenes}).encode("utf-8")
        with tempfile.TemporaryDirectory() as t:
            rec = projection.project_trace(io.BytesIO(raw), Path(t) / "trace.json")
            got = json.loads((Path(t) / "trace.json").read_text())
            self.assertEqual(rec.scenes, 2)
            self.assertEqual(rec.retired_unobserved_classes_dropped, 1)
            self.assertEqual(got["scenes"][0]["users"][0]["unobserved_classes"], ["bicycle"])
            self.assertEqual(got["scenes"][0]["users"][0]["kin"], {"speed": 1.5})
            self.assertEqual(got["scenes"][1], scenes[1])
            self.assertEqual(rec.input_sha256, hashlib.sha256(raw).hexdigest())
            self.assertEqual(rec.output_sha256, hashlib.sha256((Path(t) / "trace.json").read_bytes()).hexdigest())
            mbytes = json.dumps({"atoms": {"kin.speed": "exact"}}).encode()
            m = projection.write_manifest(mbytes, Path(t) / "src", ACTIVE, FULL, "train")
            saved = json.loads((Path(t) / "src" / "projection.json").read_text())
            self.assertEqual((saved["split"], saved["input_sha256"]), ("train", hashlib.sha256(mbytes).hexdigest()))
            self.assertEqual(m.output_sha256, hashlib.sha256((Path(t) / "src" / "manifest.json").read_bytes()).hexdigest())

    def test_a_positive_retired_class_is_refused(self):
        raw = json.dumps({"scenes": [{"t": 0, "users": [{"track": 1, "classes": ["vending_vehicle"]}]}]}).encode()
        with tempfile.TemporaryDirectory() as t:
            with self.assertRaises(projection.ProjectionError):
                projection.project_trace(io.BytesIO(raw), Path(t) / "trace.json")

    def test_scenes_stream_across_small_chunks(self):
        scenes = [{"t": i, "users": [{"track": 1, "name": "ü" * 7}]} for i in range(20)]
        raw = json.dumps({"scenes": scenes}).encode("utf-8")
        got = list(projection.iter_scenes(io.BytesIO(raw), chunk_size=5))
        self.assertEqual(got, scenes)

    def test_atom_ids_read_from_ids_lean(self):
        with tempfile.TemporaryDirectory() as t:
            p = Path(t) / "Ids.lean"
            p.write_text('def x := 1\ndef atomIds : List String := [\n  "kin.speed", "st.lane"]\n')
            self.assertEqual(projection.atom_ids(p), ["kin.speed", "st.lane"])


def monitor_lines(rules: dict[str, tuple[str, list[str], list]], ego=(1,), binder: str | None = "x") -> list[str]:
    """rule -> (support, absent, groundings); a grounding is a verdict (binding x=ego) or (verdict, binding)."""
    out = [json.dumps({"kind": "source"})]
    for r, (sup, absent, eps) in rules.items():
        out.append(json.dumps({"kind": "rule", "rule": r, "support": sup, "absent": absent}))
        for e in eps:
            v, b = (e, {"x": ego[0] if ego else 0}) if isinstance(e, str) else e
            out.append(json.dumps({"kind": "grounding", "rule": r, "grounding": b, "episode": {"verdict": v, "reasons": []}}))
    out.append(json.dumps({"kind": "subject", "ego": list(ego), "binders": {r: binder for r in rules} if binder else {}}))
    return out


class ScoringTests(unittest.TestCase):
    LAW_OF = {"R1": "L1", "R2": "L1", "R3": "L2"}

    def test_joins(self):
        res = scoring.rule_results(monitor_lines({"R1": ("supported", [], ["compliant", "violated"]),
                                                  "R2": ("unsupported", ["kin.speed"], []),
                                                  "R3": ("supported", [], [])}))
        self.assertEqual((res["R1"].verdict, res["R2"].verdict, res["R3"].verdict), ("violated", "unknown", "not_applicable"))
        self.assertEqual(scoring.join(["compliant", "unknown", "not_applicable"]), "unknown")

    def test_statuses(self):
        res = scoring.rule_results(monitor_lines({"R1": ("supported", [], ["compliant"]), "R2": ("supported", [], []),
                                                  "R3": ("partial", ["st.lane"], ["unknown"])}))
        self.assertEqual(scoring.score("a", "L1", "compliant", res, self.LAW_OF).status, "match")
        self.assertEqual(scoring.score("b", "L1", "violated", res, self.LAW_OF).status, "mismatch")
        c = scoring.score("c", "L2", "violated", res, self.LAW_OF)
        self.assertEqual(c.status, "unknown")              # an absent atom the rule reads is no cause by itself
        self.assertEqual([b["class"] for b in c.blockers], ["unexplained"])
        self.assertEqual(scoring.score("d", "L9", "violated", res, self.LAW_OF).status, "no_rule")
        self.assertEqual(scoring.score("e", "L1", None, res, self.LAW_OF).status, "unlabelled")
        self.assertEqual(scoring.score("e2", "L1", None, res, self.LAW_OF).verdict, "compliant")
        self.assertEqual(scoring.score("f", "L1", "compliant", None, self.LAW_OF, failure="deadline").status, "deadline")
        res2 = scoring.rule_results(monitor_lines({"R1": ("supported", [], ["unknown"]), "R2": ("supported", [], [])}))
        self.assertEqual(scoring.score("g", "L1", "compliant", res2, self.LAW_OF).status, "unknown")

    def test_only_the_groundings_that_judge_the_subject_are_joined(self):
        # driver=ego complied, driver=B (with ego in the other role) violated: the ego's label is compliant
        lines = monitor_lines({"R1": ("supported", [], [("compliant", {"x": 1, "other": 2}), ("violated", {"x": 2, "other": 1})]),
                               "R2": ("supported", [], [])})
        res = scoring.rule_results(lines)
        self.assertEqual(res["R1"].verdict, "compliant")
        self.assertEqual((len(res["R1"].judged), len(res["R1"].others)), (1, 1))
        self.assertEqual(res["R1"].others[0].verdict, "violated")
        self.assertEqual(scoring.score("a", "L1", "compliant", res, self.LAW_OF).status, "match")
        # the subject is the canonical track the report names, nothing else
        res = scoring.rule_results(monitor_lines({"R1": ("supported", [], [("violated", {"x": 7})])}, ego=(7,)))
        self.assertEqual(res["R1"].verdict, "violated")

    def test_a_subject_the_report_does_not_fix_is_a_contract_failure(self):
        for ego, binder in (((), "x"), ((1, 2), "x"), ((1,), None)):
            res = scoring.rule_results(monitor_lines({"R1": ("supported", [], ["violated"]), "R2": ("supported", [], [])},
                                                     ego=ego, binder=binder))
            s = scoring.score("a", "L1", "violated", res, self.LAW_OF)
            self.assertEqual(s.status, "contract_failed", (ego, binder))
        no_subject_line = [l for l in monitor_lines({"R1": ("supported", [], ["violated"])}) if '"subject"' not in l]
        self.assertEqual(scoring.rule_results(no_subject_line)["R1"].verdict, "contract_failed")

    def test_a_missing_sibling_rule_is_never_a_match(self):
        res = scoring.rule_results(monitor_lines({"R1": ("supported", [], ["compliant"])}))
        s = scoring.score("a", "L1", "compliant", res, self.LAW_OF)
        self.assertEqual(s.status, "incomplete")
        self.assertIn("R2", s.note)

    def test_an_unlabelled_failure_stays_out_of_the_label_denominator(self):
        res = scoring.rule_results(monitor_lines({"R1": ("supported", [], ["compliant"]), "R2": ("supported", [], [])}))
        a = scoring.score("a", "L1", "compliant", res, self.LAW_OF)
        b = scoring.score("b", "L1", None, None, self.LAW_OF, failure="deadline")
        self.assertEqual((b.status, b.failure), ("unlabelled", "deadline"))
        s = scoring.summary([a, b])
        self.assertEqual((s["labelled"], s["matched"], s["agreement"]), (1, 1, 1.0))
        self.assertEqual(s["unlabelled_failures"], 1)
        # a labelled deadline stays in the denominator
        c = scoring.score("c", "L1", "violated", None, self.LAW_OF, failure="crash")
        self.assertEqual(scoring.summary([a, c])["labelled"], 2)

    def test_a_failed_rule_keeps_the_finished_ones_and_decides_nothing(self):
        res = scoring.rule_results(monitor_lines({"R1": ("supported", [], ["violated"])}))
        a = scoring.score("a", "L1", "compliant", scoring.rule_results(monitor_lines(
            {"R1": ("supported", [], ["compliant"]), "R2": ("supported", [], [])})), self.LAW_OF)
        for kinds, status in (({"R2": "deadline"}, "deadline"), ({"R2": "crash"}, "crash")):
            for label in ("violated", "compliant", None):
                with self.subTest(kinds=kinds, label=label):
                    s = scoring.score("b", "L1", label, res, self.LAW_OF, failed=kinds)
                    want = status if label is not None else "unlabelled"
                    self.assertEqual((s.status, s.verdict, s.failure, s.partial), (want, None, status, True))
                    self.assertEqual(s.failed, [{"node": "R2", "failure": status}])
                    self.assertEqual((sorted(s.rules), s.rules["R1"]["verdict"]), (["R1"], "violated"))
                    self.assertEqual(s.found_violation, {"nodes": ["R1"], "complete": False, "status": want})
                    summ = scoring.summary([a, s])
                    self.assertEqual((summ["labelled"], summ["matched"]), (1 + (label is not None), 1))
                    self.assertEqual((summ["partial"], summ["found_violation"]), (1, 1))
        both = scoring.score("c", "L1", "violated", {}, self.LAW_OF, failed={"R1": "crash", "R2": "deadline"})
        self.assertEqual((both.status, both.partial, both.found_violation, both.rules), ("deadline", False, None, {}))

    def test_judgment_calls_are_counted_apart(self):
        res = scoring.rule_results(monitor_lines({"R1": ("supported", [], ["compliant"]), "R2": ("supported", [], [])}))
        a = scoring.score("a", "L1", "compliant", res, self.LAW_OF)
        j = scoring.score("j", "L1", "violated", res, self.LAW_OF, judgment_call=True)
        s = scoring.summary([a, j])
        self.assertEqual((s["labelled"], s["agreement"]), (1, 1.0))
        self.assertEqual(s["judgment_call"], {"labelled": 1, "matched": 0, "agreement": 0.0})

    def test_the_scored_set_must_be_the_fixed_set(self):
        res = scoring.rule_results(monitor_lines({"R1": ("supported", [], ["compliant"]), "R2": ("supported", [], [])}))
        a = scoring.score("a", "L1", "compliant", res, self.LAW_OF)
        self.assertEqual(scoring.summary([a], expected=["a"])["labelled"], 1)
        with self.assertRaises(ValueError):
            scoring.summary([a], expected=["a", "b"])

    def test_an_undecidable_recording_is_never_an_improvement(self):
        before = [scoring.Scored(str(i), "L1", "compliant", "compliant", "match") for i in range(8)] + \
                 [scoring.Scored(str(i), "L1", "compliant", "violated", "mismatch") for i in (8, 9)]
        after = before[:8] + [scoring.Scored(str(i), "L1", "compliant", "unknown", "unknown") for i in (8, 9)]
        b, a = scoring.summary(before), scoring.summary(after)
        self.assertEqual((b["labelled"], a["labelled"]), (10, 10))
        self.assertEqual(a["matched"], b["matched"])
        self.assertEqual(a["counts"]["mismatch"], 0)

    def test_a_recording_scored_twice_is_refused(self):
        with self.assertRaises(ValueError):
            scoring.summary([scoring.Scored("x", "L1", None, None, "unlabelled")] * 2)


class DecidabilityTests(unittest.TestCase):
    def fake_monitor(self, d: Path, lines: list[str]) -> Path:
        f = d / "monitor"
        payload = "\\n".join(lines)
        f.write_text(f"#!/bin/sh\nprintf '%b\\n' '{payload}'\n")
        f.chmod(f.stat().st_mode | stat.S_IEXEC)
        return f

    def test_support_from_the_monitor_and_the_adapter_list(self):
        with tempfile.TemporaryDirectory() as t:
            d = Path(t)
            (d / "m.json").write_text("{}")
            mon = self.fake_monitor(d, monitor_lines({"R1": ("unsupported", ["kin.speed", "ru.subject"], []),
                                                      "R2": ("partial", ["kin.speed"], [])}))
            sup = decidability.rule_support(mon, d / "m.json")
            self.assertEqual(sup["R1"].support, "unsupported")
            rep = decidability.Report()
            rep.add("rec1", sup)
            rep.add("rec2", {"R2": decidability.Support("R2", "supported", [])})
            self.assertEqual(rep.must_be_unknown(), {"R1": ["rec1"]})
            self.assertEqual(rep.adapter_changes()[0], ("kin.speed", 1, ["R1", "R2"]))
            with self.assertRaises(ValueError):
                rep.add("rec1", {})


if __name__ == "__main__":
    unittest.main()


def grounding_lines(rule: str, sup: str, absent: list, eps: list[tuple[str, list[str], dict, list]], ego=1) -> list[str]:
    """One rule's report: each grounding of the ego as (verdict, reasons, unknowns, timeline)."""
    out = [json.dumps({"kind": "rule", "rule": rule, "support": sup, "absent": absent})]
    for v, reasons, unknowns, tl in eps:
        out.append(json.dumps({"kind": "grounding", "rule": rule, "grounding": {"x": ego},
                               "episode": {"verdict": v, "reasons": reasons}, "unknowns": unknowns, "timeline": tl}))
    out.append(json.dumps({"kind": "subject", "ego": [ego], "binders": {rule: "x"}}))
    return out


class BlockerTests(unittest.TestCase):
    """Each reason of an unknown verdict is kept as a blocker whose handling the evidence decides."""
    LAW_OF = {"R1": "L1"}
    DECLARED = {"st.highway": "absent", "st.lane_enters": "exact", "kin.yaw_rate": "subject",
                "dev.traffic_signal": "exact", "dev.governs": "exact"}
    TL = [{"from": 0, "to": 950, "verdict": "unknown"}, {"from": 1000, "to": 5000, "verdict": "not_applicable"}]

    def scored(self, reasons, label="violated", sup="partial", jc=False, eps=None):
        lines = grounding_lines("R1", sup, ["st.highway"], eps if eps is not None else
                                [("unknown", reasons, {t: 3 for t in reasons}, self.TL)])
        return scoring.score("a", "L1", label, scoring.rule_results(lines), self.LAW_OF, judgment_call=jc,
                             declared=self.DECLARED)

    def kinds(self, s):
        return sorted((b["class"], b["handling"]) for b in s.blockers)

    def test_a_rule_reason_is_the_librarys(self):
        s = self.scored(["division_by_zero:div"])
        self.assertEqual(self.kinds(s), [("rule_semantic", "library")])
        self.assertTrue(scoring.library_actionable(s))

    def test_an_undefined_value_is_investigated_never_the_librarys(self):
        # a primitive with no value may be the data's geometry (a region whose boundary is no simple
        # polygon) or a call outside its precondition: the tag does not tell which
        s = self.scored(["undefined:prim_region_offset_along"])
        self.assertEqual(self.kinds(s), [("precondition_unmet", "investigate")])
        self.assertIn("geometry", s.blockers[0]["evidence"])
        self.assertIn("precondition", s.blockers[0]["evidence"])
        self.assertFalse(scoring.library_actionable(s))

    def test_a_declared_absent_atom_is_the_datas_and_not_the_librarys(self):
        s = self.scored(["absent_atom:st_highway"])
        self.assertEqual(self.kinds(s), [("source_unobserved", "data")])
        self.assertFalse(scoring.library_actionable(s))

    def test_a_declared_atom_with_a_missing_value_and_an_accessor_suffix(self):
        # declared observed, yet a value is missing: the ontology lets some entities carry none (a whole
        # two-way roadway enters no intersection), so the tag proves no data defect
        s = self.scored(["absent_atom:dev_traffic_signal_shows", "absent_atom:st_lane_enters", "absent_atom:kin_yaw_rate"])
        self.assertEqual(self.kinds(s), [("source_subject_only", "data"), ("value_missing", "investigate"),
                                         ("value_missing", "investigate")])
        self.assertIn("dev.traffic_signal", next(b["evidence"] for b in s.blockers if b["reason"].startswith("absent_atom:dev")))
        lane = next(b["evidence"] for b in s.blockers if b["reason"] == "absent_atom:st_lane_enters")
        self.assertIn("declares st.lane_enters exact", lane)
        self.assertIn("may allow none", lane)
        self.assertFalse(scoring.library_actionable(s))

    def test_mixed_reasons_keep_both_sides(self):
        s = self.scored(["absent_atom:st_highway", "division_by_zero:div"])
        self.assertEqual({b["handling"] for b in s.blockers}, {"data", "library"})
        self.assertTrue(scoring.library_actionable(s))

    def test_a_window_is_held_by_the_time_contract(self):
        s = self.scored(["window_truncated:holdsFor"])
        (b,) = s.blockers
        self.assertEqual((b["class"], b["handling"], b["observations"]), ("history", "time_contract", 3))
        self.assertFalse(scoring.library_actionable(s))

    def test_a_blocker_claims_no_instant_the_timeline_does_not_give_it(self):
        # the start is unknown for a missing speed, the window truncates later: the timeline says
        # only when the grounding is unknown, so no reason is placed at the trace's start or end
        tl = [{"from": 0, "to": 0, "verdict": "unknown"}, {"from": 50, "to": 100, "verdict": "compliant"},
              {"from": 150, "to": 150, "verdict": "unknown"}, {"from": 200, "to": 200, "verdict": "compliant"}]
        reasons = ["absent_atom:dev_traffic_signal_shows", "window_truncated:within"]
        s = self.scored(reasons, eps=[("unknown", reasons, {t: 1 for t in reasons}, tl)])
        self.assertEqual(len(s.blockers), 2)
        for b in s.blockers:
            self.assertFalse({"at_start", "at_end"} & set(b), b)

    def test_every_reason_constructor_is_classified(self):
        for tag in ("sampling_gap:holdsFor", "identity_gap:7", "intention_missing:int.left_turn",
                    "assumption_missing:asm.x", "parameter_missing:p.x", "unbound_variable:v", "malformed:k",
                    "out_of_range", "division_by_zero:ratio", "undefined:prim_closest_approach_time", "composition_unknown:R9", "aggregate_unresolved:D::t"):
            with self.subTest(tag=tag):
                (b,) = self.scored([tag]).blockers
                self.assertNotEqual(b["class"], "unexplained")
                self.assertIn(b["handling"], scoring.HANDLINGS)

    def test_an_unknown_tag_or_atom_is_never_actionable(self):
        self.assertEqual(self.kinds(self.scored(["brand_new_reason:x"])), [("unexplained", "harness")])
        self.assertEqual(self.kinds(self.scored(["absent_atom:zz_nothing"])), [("unmapped_atom", "investigate")])

    def test_an_unknown_grounding_without_reasons_is_unexplained(self):
        s = self.scored([], eps=[("unknown", [], {}, self.TL)])
        self.assertEqual(self.kinds(s), [("unexplained", "harness")])
        self.assertFalse(scoring.library_actionable(s))

    def test_an_unsupported_rule_without_groundings_keeps_its_support_evidence(self):
        s = self.scored([], sup="unsupported", eps=[])
        self.assertEqual(self.kinds(s), [("unsupported", "data")])
        self.assertIn("st.highway", s.blockers[0]["evidence"])

    def test_a_judgment_call_is_never_library_actionable(self):
        self.assertFalse(scoring.library_actionable(self.scored(["division_by_zero:div"], jc=True)))

    def test_a_decided_recording_has_no_blockers_and_unlabelled_ones_keep_theirs(self):
        lines = grounding_lines("R1", "partial", ["st.highway"], [("violated", ["absent_atom:st_highway"], {}, self.TL)])
        self.assertEqual(scoring.score("a", "L1", "violated", scoring.rule_results(lines), self.LAW_OF,
                                       declared=self.DECLARED).blockers, [])
        s = self.scored(["division_by_zero:div"], label=None)
        self.assertEqual((s.status, len(s.blockers)), ("unlabelled", 1))
        self.assertFalse(scoring.library_actionable(s))

    def test_the_summary_counts_blockers_by_handling_and_class(self):
        sm = scoring.summary([self.scored(["absent_atom:st_highway", "division_by_zero:div"])])
        self.assertEqual((sm["blockers"]["handling"]["data"], sm["blockers"]["handling"]["library"], sm["library_actionable"]),
                         (1, 1, 1))
