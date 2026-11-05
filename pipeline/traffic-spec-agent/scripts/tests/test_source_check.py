"""The source report (`recorded.source_check`) on small synthetic traces: each kind of finding, the
three cases kept apart, refinements read through Core's kind hierarchy, geometry reported as facts
only, no status or evidence changed by it, and the same report for the same files."""
import contextlib
import copy
import io
import json
import tempfile
import unittest
from pathlib import Path
from unittest import mock

from harness.phases import label_check
from recorded import source_check as sc
from scripts.tests.test_label_check import FAKE_EXPLAIN, FAKE_MONITOR, make_dataset, write_exe

KINDS = sc.Kinds.from_library()
SQ = lambda x0, y0, x1, y1: [[x0, y0], [x1, y0], [x1, y1], [x0, y1]]


def scene(i=0, structures=(), devices=(), users=None, **kw):
    users = users if users is not None else [{"track": 1, "classes": [], "kin": {"position": [0, 0]},
                                              "sig": {"turn_indicator": "off"}}]
    return {"t": 50 * (i + 1), "subject": 1, "users": users, "structures": list(structures), "devices": list(devices),
            "occupancy_observed": True, "env": {}, **kw}


def lane(sid, kind="lane", **lane_fields):
    fields = {"direction": [1, 0], "ordinal": 1, "count": 1, "marking_left": ["solid", "white"],
              "marking_right": ["broken", "white"], "width": 3.5, "leads_to": []}
    fields.update(lane_fields)
    return {"id": sid, "kind": kind, "boundary": SQ(0, 0, 10, 3), "lane": {k: v for k, v in fields.items() if v is not None}}


def findings(rep, case=None, atom=None):
    return [f for f in rep["findings"] if (case is None or f["case"] == case) and (atom is None or f["atom"] == atom)]


def one(rep, atom, check=None):
    fs = [f for f in rep["findings"] if f["atom"] == atom and (check is None or f["check"] == check)]
    assert len(fs) == 1, fs
    return fs[0]


class Declarations(unittest.TestCase):

    def test_a_kind_listed_unobserved_while_declared_observed_is_case_iii(self):
        st = [{"id": 1, "kind": "sidewalk", "boundary": SQ(0, 0, 1, 1), "unobserved_kinds": ["crosswalk"]},
              {"id": 2, "kind": "crosswalk", "boundary": SQ(2, 0, 3, 1)}]
        rep = sc.check([scene(0, st)], {"atoms": {"st.crosswalk": "estimate:x", "st.sidewalk": "exact"}}, KINDS)
        f = one(rep, "st.crosswalk", "listed_unobserved_but_declared_observed")
        self.assertEqual((f["case"], f["family"], f["entity"], f["entities"]), ("iii", "declaration", "structure", 1))
        self.assertEqual(f["examples"][0]["structure"], 1)

    def test_a_kind_present_but_declared_absent_is_case_iii_and_absent_with_none_present_is_case_ii(self):
        st = [{"id": 1, "kind": "median_or_divider", "boundary": SQ(0, 0, 1, 1)}]
        rep = sc.check([scene(0, st)], {"atoms": {}}, KINDS)
        self.assertEqual(one(rep, "st.median_or_divider")["check"], "labelled_but_declared_absent")
        self.assertEqual(one(rep, "st.median_or_divider")["case"], "iii")
        self.assertEqual(one(rep, "st.sidewalk")["case"], "ii")

    def test_refinements_follow_the_kind_hierarchy(self):
        st = [{"id": 1, "kind": "one_way_roadway", "boundary": SQ(0, 0, 10, 4), "curvature": 0, "grade": 0, "sight_distance": 99},
              lane(2, "turn_lane", direction=None), lane(3, "centre_turn_lane", direction=None)]
        atoms = {"st.roadway": "exact", "st.lane": "exact", "st.turn_lane": "exact", "st.centre_turn_lane": "exact",
                 "st.lane_direction": "exact", "st.curvature": "exact"}
        rep = sc.check([scene(0, st)], {"atoms": atoms}, KINDS)
        # a one-way roadway is a roadway: st.roadway is not legally empty here
        self.assertFalse([f for f in findings(rep, "i", "st.roadway")])
        # the direction is required of a turn lane (a lane) but not of a centre turn lane
        f = one(rep, "st.lane_direction")
        self.assertEqual((f["case"], f["entities"], f["checked_entities"], f["examples"][0]["structure"]), ("iii", 1, 1, 2))
        # curvature is read on the one-way roadway, a roadway by refinement
        self.assertFalse(findings(rep, "iii", "st.curvature"))
        self.assertEqual(one(rep, "st.one_way_roadway")["check"], "labelled_but_declared_absent")
        # a roadway labelled while st.roadway is absent contradicts it; a refinement absent with only its parent present does not
        rep2 = sc.check([scene(0, [{"id": 1, "kind": "one_way_roadway", "boundary": SQ(0, 0, 1, 1)}])],
                        {"atoms": {"st.one_way_roadway": "exact"}}, KINDS)
        self.assertEqual(one(rep2, "st.roadway")["case"], "iii")
        rep3 = sc.check([scene(0, [{"id": 1, "kind": "roadway", "boundary": SQ(0, 0, 1, 1)}])], {"atoms": {"st.roadway": "exact"}}, KINDS)
        self.assertEqual(one(rep3, "st.one_way_roadway")["case"], "ii")

    def test_an_unobserved_listing_counts_only_where_core_applies_it(self):
        st = [lane(1, unobserved_kinds=None), {"id": 2, "kind": "roadway", "boundary": SQ(0, 0, 1, 1)}]
        st[0]["unobserved_kinds"] = ["one_way_roadway"]             # a lane is known to be no roadway
        rep = sc.check([scene(0, st)], {"atoms": {"st.one_way_roadway": "exact", "st.roadway": "exact", "st.lane": "exact"}}, KINDS)
        self.assertFalse(findings(rep, "iii", "st.one_way_roadway"))
        st[1]["unobserved_kinds"] = ["one_way_roadway"]             # on a roadway the listing leaves one-way open
        rep = sc.check([scene(0, st)], {"atoms": {"st.one_way_roadway": "exact", "st.roadway": "exact", "st.lane": "exact"}}, KINDS)
        self.assertEqual(one(rep, "st.one_way_roadway", "listed_unobserved_but_declared_observed")["examples"][0]["structure"], 2)

    def test_fields_declared_observed_but_missing(self):
        users = [{"track": 1, "classes": ["motor_vehicle"], "kin": {}, "sig": {"brake_lamp": False}},
                 {"track": 2, "classes": ["motor_vehicle"], "kin": {}, "sig": {}},
                 {"track": 3, "classes": ["pedestrian"], "kin": {}, "sig": {}}]
        devs = [{"id": 7, "kind": "traffic_signal", "governs": [1], "indications": ["circular_red"]},
                {"id": 8, "kind": "traffic_signal", "governs": [1]}]
        atoms = {"sig.turn_indicator": "exact", "sig.brake_lamp": "exact", "kin.steer_angle": "subject", "dev.traffic_signal": "exact",
                 "dev.governs": "exact", "st.lane": "exact", "st.lane_direction": "exact"}
        rep = sc.check([scene(i, [lane(1, direction=None)], devs, users) for i in range(3)], {"atoms": atoms}, KINDS)
        ti = {f["entity"]: f for f in findings(rep, "iii", "sig.turn_indicator")}
        self.assertEqual(ti["subject"]["observations"], 3)
        self.assertEqual(ti["other road user"]["entities"], 1)             # the pedestrian carries no indicator
        bl = findings(rep, "iii", "sig.brake_lamp")
        self.assertEqual([f["entity"] for f in bl], ["other road user"])
        steer = findings(rep, "iii", "kin.steer_angle")
        self.assertEqual([f["entity"] for f in steer], ["subject"])        # a subject capability: nobody else is asked
        sigs = one(rep, "dev.traffic_signal", "indications_missing")
        self.assertEqual((sigs["entities"], sigs["observations"], sigs["checked"]), (1, 3, 6))
        self.assertEqual(one(rep, "st.lane_direction")["case"], "iii")

    def test_a_field_present_while_declared_absent_is_no_finding(self):
        rep = sc.check([scene(0, [lane(1)])], {"atoms": {"st.lane": "exact"}}, KINDS)
        self.assertEqual(one(rep, "st.lane_direction")["case"], "ii")
        self.assertEqual(one(rep, "st.lane_direction")["check"], "declared_absent")


class Associations(unittest.TestCase):

    def test_relations_declared_observed_but_missing(self):
        st = [lane(1, enters_intersection=5), lane(2), {"id": 5, "kind": "intersection", "boundary": SQ(10, 0, 20, 10)},
              {"id": 6, "kind": "intersection", "boundary": SQ(30, 0, 40, 10)},
              {"id": 3, "kind": "stop_line", "boundary": SQ(9, 0, 9.2, 3), "entrance_of": [1]},
              {"id": 4, "kind": "stop_line", "boundary": SQ(9, 3, 9.2, 6)}]
        devs = [{"id": 7, "kind": "stop_sign"}]
        atoms = {"st.lane": "exact", "st.intersection": "exact", "st.stop_line": "exact", "st.entrance_of": "exact",
                 "st.lane_enters": "exact", "dev.stop_sign": "exact", "dev.governs": "exact"}
        rep = sc.check([scene(0, st, devs)], {"atoms": atoms}, KINDS)
        for atom, check, ent in (("st.entrance_of", "relation_missing", 4), ("st.lane_enters", "intersection_not_entered", 6)):
            f = one(rep, atom)
            self.assertEqual((f["case"], f["family"], check, f["examples"][0]["structure"]), ("iii", "association", f["check"], ent))
        g = one(rep, "dev.governs")
        self.assertEqual((g["case"], g["family"], g["examples"][0]["device"]), ("iii", "association", 7))

    def test_on_way_is_read_from_the_trace_never_inferred(self):
        hw = {"id": 9, "kind": "highway", "boundary": SQ(-1, -1, 50, 20)}
        road = {"id": 1, "kind": "roadway", "boundary": SQ(0, 0, 10, 4)}
        rep = sc.check([scene(0, [hw, road])], {"atoms": {"st.highway": "exact", "st.roadway": "exact"}}, KINDS)
        self.assertEqual(one(rep, "st.on_way")["case"], "ii")                       # declared absent: not observed
        self.assertEqual(rep["facts"]["highway"]["structures_naming_ways"], 0)       # containment names no way
        rep = sc.check([scene(0, [hw, road])], {"atoms": {"st.highway": "exact", "st.roadway": "exact", "st.on_way": "exact"}}, KINDS)
        self.assertEqual(one(rep, "st.on_way")["case"], "iii")                       # inside a highway, yet no way named
        rep = sc.check([scene(0, [hw, dict(road, ways=[9])])], {"atoms": {"st.highway": "exact", "st.roadway": "exact",
                                                                          "st.on_way": "exact"}}, KINDS)
        self.assertFalse(findings(rep, "iii", "st.on_way"))
        self.assertEqual(rep["facts"]["highway"]["ways_not_a_highway"], 0)


class CasesAndGeometry(unittest.TestCase):

    def test_the_three_cases_are_kept_apart(self):
        none_here = sc.check([scene(0)], {"atoms": {"st.highway": "exact", "dev.traffic_signal": "exact"}}, KINDS)
        not_seen = sc.check([scene(0)], {"atoms": {}}, KINDS)
        missing = sc.check([scene(0, devices=[{"id": 1, "kind": "traffic_signal", "governs": []}])],
                           {"atoms": {"dev.traffic_signal": "exact", "dev.governs": "exact"}}, KINDS)
        self.assertEqual(one(none_here, "st.highway")["case"], "i")
        self.assertEqual(one(none_here, "dev.traffic_signal")["case"], "i")
        self.assertEqual(one(not_seen, "st.highway")["case"], "ii")
        self.assertEqual(one(not_seen, "dev.traffic_signal")["case"], "ii")
        self.assertEqual(one(missing, "dev.traffic_signal")["case"], "iii")
        for rep in (none_here, not_seen, missing):
            seen = {}
            for f in rep["findings"]:
                seen.setdefault((f["atom"], f["entity"]), set()).add(f["case"])
            self.assertFalse({k: v for k, v in seen.items() if len(v) > 1 and "iii" not in v}, "an atom in two of i and ii")
            self.assertTrue(all(f["case"] in sc.CASES and f["family"] in ("declaration", "association") for f in rep["findings"]))

    def test_containment_is_a_fact_with_no_verdict(self):
        hws = [{"id": 8, "kind": "highway", "boundary": SQ(0, 0, 10, 10)}, {"id": 9, "kind": "highway", "boundary": SQ(10, 0, 20, 10)}]
        st = hws + [{"id": 1, "kind": "one_way_roadway", "boundary": SQ(1, 1, 9, 9)},     # in one highway
                    {"id": 2, "kind": "roadway", "boundary": SQ(5, 1, 15, 9)},            # across two
                    {"id": 3, "kind": "roadway", "boundary": SQ(15, 1, 25, 9)},           # partly outside
                    {"id": 4, "kind": "intersection", "boundary": SQ(30, 0, 31, 1)}]      # outside
        rep = sc.check([scene(0, st)], {"atoms": {"st.highway": "exact", "st.roadway": "exact", "st.one_way_roadway": "exact",
                                                  "st.intersection": "exact"}}, KINDS)
        c = rep["facts"]["highway"]["containment"]
        self.assertEqual({k: c["roadway"][k] for k in ("checked", "in_one_highway", "every_vertex_in_some_highway", "partly", "outside")},
                         {"checked": 3, "in_one_highway": 1, "every_vertex_in_some_highway": 2, "partly": 1, "outside": 0})
        self.assertEqual(c["intersection"]["outside"], 1)
        self.assertEqual(c["roadway"]["examples"]["partly"]["id"], 3)
        self.assertFalse([f for f in rep["findings"] if f["case"] == "iii"])          # no containment finding
        self.assertIsNone(sc.check([scene(0, st[2:])], {"atoms": {}}, KINDS)["facts"]["highway"]["containment"])

    def test_a_map_repeated_in_every_scene_is_checked_once(self):
        rep = sc.check([scene(i, [lane(1, direction=None)]) for i in range(5)], {"atoms": {"st.lane": "exact", "st.lane_direction": "exact"}}, KINDS)
        self.assertEqual(one(rep, "st.lane_direction")["observations"], 1)
        self.assertEqual(rep["facts"]["structures_changed"], 0)


class Determinism(unittest.TestCase):

    def write(self, root: Path, rid: str, scenes, atoms) -> tuple[str, Path, Path]:
        d = root / rid
        d.mkdir(parents=True)
        (d / "trace.json").write_text(json.dumps({"scenes": scenes}))
        (d / "manifest.json").write_text(json.dumps({"atoms": atoms}))
        return rid, d / "trace.json", d / "manifest.json"

    def test_the_same_files_give_the_same_report(self):
        with tempfile.TemporaryDirectory() as t:
            items = [self.write(Path(t), f"r{k}", [scene(i, [lane(1, direction=None)]) for i in range(3)],
                                {"st.lane": "exact", "st.lane_direction": "exact"}) for k in range(3)]
            a = sc.run(items, jobs=1)
            b = sc.run(list(reversed(items)), jobs=3)
            self.assertEqual(json.dumps(a, sort_keys=True), json.dumps(b, sort_keys=True))
            self.assertEqual(list(a), ["r0", "r1", "r2"])
            self.assertEqual(a["r0"]["trace_sha256"], __import__("hashlib").sha256(items[0][1].read_bytes()).hexdigest())

    def test_an_unreadable_trace_is_reported_not_raised(self):
        with tempfile.TemporaryDirectory() as t:
            rid, tr, man = self.write(Path(t), "r", [], {})
            tr.write_text("not json")
            r = sc.run([(rid, tr, man)], jobs=1)["r"]
            self.assertIn("error", r)
            self.assertEqual(r["findings"], [])
            self.assertEqual(sc.summary({"r": r})["unreadable"], ["r"])


class WithTheRun(unittest.TestCase):
    """The report is stored with the run once, bound to the fixed set's digests, and changes nothing
    a check scores, routes or renders."""

    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name)
        self.ds = make_dataset(self.root / "ds", [("ra", "L", "compliant", False, {"R1": [["compliant", {"x": 1}]]}),
                                                  ("rb", "L", "violation", False, {"R1": [["compliant", {"x": 1}]]})])
        for rid in ("ra", "rb"):
            f = self.ds.files(rid)
            f["trace"].write_text(json.dumps({"scenes": [scene(0, [{"id": 1, "kind": "sidewalk", "unobserved_kinds": ["crosswalk"]}])]}))
            f["manifest"].write_text(json.dumps({"atoms": {"st.crosswalk": "exact", "st.sidewalk": "exact"}}))
        self.run_dir = self.root / "run"
        self.run_dir.mkdir()

    def tearDown(self):
        self.tmp.cleanup()

    def test_it_is_computed_once_and_kept_with_the_run(self):
        ctx = label_check.training_context(self.run_dir, ["L"], self.ds.path)
        f = self.run_dir / "source_check.json"
        saved = f.read_bytes()
        doc = json.loads(saved)
        self.assertEqual(sorted(doc["recordings"]), ["ra", "rb"])
        self.assertEqual(doc["recordings"]["ra"]["trace_sha256"], ctx.fixed["cases"]["ra"]["trace"])
        self.assertEqual(ctx.source_summary("L")["findings"]["iii"],
                         {"declaration:st.crosswalk:listed_unobserved_but_declared_observed:structure": 2})
        with mock.patch.object(sc, "check_files", side_effect=AssertionError("computed again")):
            again = label_check.training_context(self.run_dir, ["L"], self.ds.path)
        self.assertEqual(again.sources, ctx.sources)
        self.assertEqual(f.read_bytes(), saved)

    def test_it_changes_no_status_outcome_or_evidence(self):
        mon, exp = write_exe(self.root / "monitor", FAKE_MONITOR), write_exe(self.root / "explain", FAKE_EXPLAIN)
        reading = self.root / "reading.json"
        reading.write_text("{}")
        lim = label_check.Limits(deadline_s=5, memory_gb=4, explain_s=5, jobs=1)
        chk = label_check.check_law("L", ["R1"], {"R1": "L"}, self.ds, mon, exp, reading, lim)
        plain, evidence = copy.deepcopy(chk.to_dict()), label_check.render_evidence(chk)
        ctx = label_check.training_context(self.run_dir, ["L"], self.ds.path)
        chk.source_check = ctx.source_summary("L")
        with_report = chk.to_dict()
        self.assertEqual(with_report.pop("source_check"), ctx.source_summary("L"))
        self.assertEqual(with_report, plain)
        self.assertEqual(label_check.render_evidence(chk), evidence)
        self.assertEqual(chk.outcome, "mismatch")
        self.assertEqual(label_check.outcome_of(chk.scored), "mismatch")
        self.assertEqual(label_check.eligible_statuses(chk), {"ra": "match", "rb": "mismatch"})

    def test_a_report_on_other_files_than_the_fixed_ones_says_so(self):
        reps = sc.ensure(self.root / "sc.json", self.ds, ["ra"], {"ra": {"trace": "0" * 64, "manifest": "0" * 64}}, jobs=1)
        self.assertIn("comparison set", reps["ra"]["error"])

    def test_the_command_line_writes_the_summary(self):
        out = self.root / "out" / "source_check.json"
        with contextlib.redirect_stdout(io.StringIO()) as printed:
            self.assertEqual(sc.main([str(self.ds.path), "--out", str(out), "--jobs", "1"]), 0)
        self.assertEqual(json.loads(printed.getvalue())["recordings"], 2)
        doc = json.loads(out.read_text())
        self.assertEqual(doc["summary"]["recordings_with"]["iii"], 2)
        self.assertEqual(sorted(doc["per_law"]), ["L"])
        self.assertEqual(doc["data_version"], "v1")


if __name__ == "__main__":
    unittest.main()
