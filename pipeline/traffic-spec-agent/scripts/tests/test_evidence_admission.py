"""Evidence admission and replay: the schema boundary of a concept review and a dependency report,
a hand-written trace that supplies no relation Core computes, an extension that must continue the
evidence it extends, the executed facts a concept adjudicator decides on, structural items checked
before judgment, and structural concept findings kept as obligations."""
import copy
import json
import re
import tempfile
import unittest
from pathlib import Path
from types import SimpleNamespace

from harness.lean import lean, relations, render_formula
from harness.model.blueprint import ConceptRecord
from harness.phases import review
from harness.store import paths
from scripts.tests.test_review_routing import FakeRun, scripted_reviewer, submit


def two_users(rel: str = "", heading2=(1, 0), extra_scene: dict | None = None) -> dict:
    users = [{"track": 1, "classes": ["motor_vehicle"], "kin": {"heading": [1, 0]}},
             {"track": 2, "classes": ["motor_vehicle"], "kin": {"heading": list(heading2)}}]
    sc = {"t": 0, "users": users, **({"relations": [json.loads(rel)]} if rel else {}), **(extra_scene or {})}
    return {"scenes": [sc]}


def lint(traces: dict[str, dict]) -> list[str]:
    """The RELCHECK lines of the relation check on each trace, by name."""
    with tempfile.TemporaryDirectory() as t:
        lst = []
        for k, tr in traces.items():
            f = Path(t) / f"{k}.json"; f.write_text(json.dumps(tr)); lst.append(f'("{k}", {json.dumps(str(f))})')
        prog = Path(t) / "lint.lean"
        prog.write_text(f'''import TrafficSpec
open TrafficSpec Lean
{relations.lean_defs()}
def items : List (String × String) := [{", ".join(lst)}]
def main : IO Unit := do
  for (k, f) in items do
    match Decode.parse Decode.trace (← IO.FS.readFile f) with
    | .ok τ => RelCheck.run k τ
    | .error e => IO.println s!"DECODE\\t{{k}}\\t{{e}}"
''')
        code, out = lean.lean_run(paths.LIBRARY, prog)
        assert code == 0, out[-600:]
        return [l for l in out.splitlines() if l.startswith(("RELCHECK", "DECODE"))]


class SuppliedRelations(unittest.TestCase):
    """A relation Core computes from the scene is never supplied in a hand-written trace."""
    def test_the_check_in_lean(self):
        out = lint({"contradicts": two_users('{"a": 1, "b": 2, "same_direction": false}'),
                    "agrees": two_users('{"a": 1, "b": 2, "same_direction": true}'),
                    "visible": two_users('{"a": 1, "b": 2, "visible": true}'),
                    "no_geometry": {"scenes": [{"t": 0, "users": [{"track": 1}, {"track": 3}],
                                                "relations": [{"a": 1, "b": 3, "same_direction": True, "centre_distance": 4}]}]},
                    "other_pair": {"scenes": [{"t": 0, "users": [{"track": 7, "kin": {"heading": [1, 0]}}, {"track": 8, "kin": {"heading": [0, 1]}}],
                                               "relations": [{"a": 7, "b": 8, "same_direction": True}]}]}})
        names = [l.split("\t")[1] for l in out]
        self.assertIn("contradicts", names)          # Core computes `same_direction` from the headings
        self.assertIn("agrees", names)               # a value Core computes is never supplied, whatever it says
        self.assertIn("other_pair", names)           # every pair of every scene, no grounded-track filter
        self.assertNotIn("visible", names)           # Core never computes visibility
        self.assertNotIn("no_geometry", names)       # nothing to compute it from: it may be supplied

    def test_a_surface_gap_is_checked_against_both_footprints(self):
        """Core computes the gap between two bodies from both footprints: a supplied gap is a defect
        where both bodies' position, heading and extent are in the scene, and may be supplied where
        the other body's heading is not."""
        def body(track, x, heading):
            return {"track": track, "kin": {"position": [x, 0], "extent": [2, 1, 0.5], **({"heading": heading} if heading else {})}}
        gap = [{"a": 1, "b": 2, "surface_gap": [7, 0]}]
        out = lint({"both": {"scenes": [{"t": 0, "users": [body(1, 0, [1, 0]), body(2, 10, [0, 1])], "relations": gap}]},
                    "no_heading_b": {"scenes": [{"t": 0, "users": [body(1, 0, [1, 0]), body(2, 10, None)], "relations": gap}]}})
        names = [l.split("\t")[1] for l in out]
        self.assertIn("both", names)
        self.assertNotIn("no_heading_b", names)

    def test_every_computed_field_is_covered(self):
        """Every field of a measured relation is either one Core computes (checked) or `visible`: a
        relation Core later learns to compute fails this test until the check covers it."""
        world = (paths.CORE / "Vocab" / "World.lean").read_text(encoding="utf-8")
        fields = re.findall(r"^\s+(\w+) : Option", world.split("structure MeasuredRelation where", 1)[1].split("structure", 1)[0], re.M)
        covered = {f for _a, _n, _k, f in relations.computable()}
        self.assertEqual(set(fields) - covered, {"visible"})
        self.assertEqual(relations.json_key("aAheadOfB"), "a_ahead_of_b")

    def test_the_gates_and_the_certificate_check_every_scene(self):
        from harness.checks import gate
        src = Path(gate.__file__).read_text(encoding="utf-8") + Path(review.__file__).read_text(encoding="utf-8")
        self.assertNotIn("RelCheck.occurrences", src)
        self.assertEqual(src.count("RelCheck.run sc.name τ"), 2)                  # both gates
        self.assertIn("RelCheck.run (toString k) τ", src)                         # the certificate and the concept program

    def test_a_saved_trace_is_stripped(self):
        tr = {"scenes": [{"t": 0, "relations": [{"a": 1, "b": 2, "same_direction": False, "visible": True}]},
                         {"t": 5, "relations": [{"a": 1, "b": 2, "contact": True}]}]}
        out = review.strip_computed_relations(tr, [["0", "1-2", "rel_same_direction"], ["5", "1-2", "rel_contact"]])
        self.assertEqual(out["scenes"][0]["relations"], [{"a": 1, "b": 2, "visible": True}])
        self.assertEqual(out["scenes"][1]["relations"], [])
        self.assertEqual(tr["scenes"][1]["relations"][0]["contact"], True)       # the saved record is untouched


class SchemaBoundary(unittest.TestCase):
    """Every value a concept review or a dependency report states is typed before it is used."""
    REC = ConceptRecord({"concept_id": "drv.motion.audit", "kind": "formula", "contract": "Movement holds.",
                         "args": [{"name": "v", "sort": "track"}, {"name": "side", "sort": "literal", "values": ["left", "right"]},
                                  {"name": "n", "sort": "nat"}],
                         "params": [{"name": "window", "unit": "s"}]})
    BASE = {"kind": "fails_wrongly", "contract_words": "Movement", "contract_verdict": "holds",
            "instance": {"params": {"window": [1, "s"]}, "literals": {"side": "left"}, "nats": {"n": 1}},
            "grounding": {"v": 1}, "trace": {"scenes": [{"t": 0}]}, "at": 0}
    PATHS = [("kind",), ("contract_verdict",), ("contract_words",), ("instance", "params", "window", 1), ("instance", "params", "window", 0),
             ("instance", "params", "window"), ("instance", "literals", "side"), ("instance", "nats", "n"), ("grounding", "v"),
             ("trace", "scenes", 0, "t"), ("at",), ("trace", "scenes", 0), ("trace", "scenes"), ("trace",), ("instance",)]
    BAD = [[], {}, True, float("nan"), "zz", None]

    def mutations(self):
        for p in self.PATHS:
            for b in self.BAD:
                d = copy.deepcopy(self.BASE); o = d
                for x in p[:-1]:
                    o = o[x]
                o[p[-1]] = b
                yield p, b, d

    def test_the_base_is_clean(self):
        self.assertEqual(review.concept_divergence_defects(1, self.BASE, self.REC, "Movement holds."), [])

    def test_the_review_tool_returns_defects(self):
        with tempfile.TemporaryDirectory() as t:
            tools = review.ConceptTools(self.REC, "Movement holds.", "", None, Path(t), 1, 1)
            for p, b, d in self.mutations():
                with self.subTest(path=p, value=b):
                    out = tools._check(d, Path(t) / "c")
                    self.assertEqual(out["status"], "schema defects")

    def test_an_interval_and_the_answer(self):
        q = ConceptRecord({"concept_id": "drv.motion.q", "kind": "quantity", "contract": "value", "args": [{"name": "v", "sort": "track"}]})
        for lo in ([1, []], [True, "m"], [float("inf"), "m"], "x", [1]):
            d = {"kind": "value_wrongly", "contract_words": "value", "contract_value": {"lo": lo, "hi": [2, "m"]}, "grounding": {"v": 1},
                 "trace": {"scenes": [{"t": 0}]}, "at": 0, "instance": {}}
            self.assertTrue(review.concept_divergence_defects(1, d, q, "value"))
        for verdict in ([], {}, None):
            self.assertTrue(review.concept_review_defects({"verdict": verdict, "divergences": [], "not_general": []}, self.REC, "Movement holds.", ""))

    def test_a_dependency_report(self):
        with tempfile.TemporaryDirectory() as t:
            acc = {**self.REC.raw, "body_json": {"tt": True}}
            run = SimpleNamespace(all_concepts=lambda: {"drv.motion.audit": acc})
            for p, b, d in self.mutations():
                with self.subTest(path=p, value=b):
                    (Path(t) / "dependency_defect.json").write_text(json.dumps({"concept_id": "drv.motion.audit", **d}, allow_nan=True))
                    _d, bad = review.report_form(run, Path(t), {"drv.motion.audit"})
                    self.assertTrue(bad)


class Continuity(unittest.TestCase):
    """An extension counts only where it continues the recorded evidence."""
    PRIOR = {"scenes": [{"t": 0, "users": [{"track": 1, "kin": {"heading": [1, 0]}}]}]}

    def test_a_continuation_is_admitted(self):
        longer = {"scenes": [{"t": -500, "users": [{"track": 1}]}] + copy.deepcopy(self.PRIOR["scenes"])}
        self.assertEqual(review.trace_extension_defects(self.PRIOR, longer), [])            # an earlier scene added
        filled = copy.deepcopy(self.PRIOR); filled["scenes"][0]["users"][0]["kin"]["speed"] = 3
        self.assertEqual(review.trace_extension_defects(self.PRIOR, filled), [])            # an unobserved field filled
        body = lambda t, x: {"track": t, "kin": {"position": [x, 0], "heading": [1, 0], "velocity": [5, 0], "speed": 5, "extent": [2, 1, 1]}}
        geo = {"scenes": [{"t": 0, "users": [body(1, 0), body(2, 30)]}]}
        rel = copy.deepcopy(geo); rel["scenes"][0]["relations"] = [{"a": 1, "b": 2, "contact": True}]
        self.assertEqual(review.trace_extension_defects(rel, geo), [])                     # a relation field Core computes is left to Core
        measured = copy.deepcopy(self.PRIOR); measured["scenes"][0]["relations"] = [{"a": 1, "b": 2, "contact": True}]
        self.assertTrue(review.trace_extension_defects(measured, self.PRIOR))               # one it cannot compute is evidence, kept

    def test_changed_evidence_is_refused(self):
        turned = copy.deepcopy(self.PRIOR); turned["scenes"][0]["users"][0]["kin"]["heading"] = [-1, 0]
        self.assertTrue(review.trace_extension_defects(self.PRIOR, turned))                 # an old heading changed
        self.assertTrue(review.trace_extension_defects(self.PRIOR, {"scenes": [{"t": 0, "users": [{"track": 9}]}]}))   # an unrelated trace

    def test_concept_formals(self):
        rec = ConceptRecord({"concept_id": "drv.motion.x_v2", "contract": "c", "kind": "formula",
                             "args": [{"name": "driver", "sort": "track"}, {"name": "other", "sort": "track"}], "params": []})
        old = {"trace": {"scenes": [{"t": 0}]}, "grounding": {"v": 1}, "at": 0, "contract_words": "c", "contract_verdict": "fails",
               "instance": {}}
        new = lambda **kw: {**old, "grounding": {"driver": 1, "other": 2}, **kw}
        self.assertEqual(review.concept_extension_defects(old, new(), rec), [])                       # renamed, its value kept
        self.assertTrue(review.concept_extension_defects(old, new(grounding={"driver": 3, "other": 2}), rec))   # the value lost
        self.assertTrue(review.concept_extension_defects(old, new(grounding={"driver": 1, "other": 1}), rec))   # ambiguous
        self.assertTrue(review.concept_extension_defects(old, new(contract_verdict="holds"), rec))   # another claim


class ExecutedFacts(unittest.TestCase):
    """The concept adjudicator reads what was executed, not only the reviewer's prose."""
    def facts(self, trace, read=("users[].kin.speed",)):
        return render_formula.trace_facts(trace, {"v": 1, "u": 2}, 0, {"params": {"tol": [15, "deg"]}}, list(read), {0: ["1-10"]})

    def test_each_fact_as_executed(self):
        f = self.facts(two_users(heading2=(-1, 0)))
        self.assertIn("track 2: classes [\"motor_vehicle\"]; kin.heading [-1, 0]; not observed: kin.speed", f)
        self.assertIn("`tol` = 15 deg", f)
        self.assertIn("t = 0 ms (the observation judged)", f)
        self.assertIn("occupancy derived from the geometry before running: 1-10", f)

    def test_environment_and_visibility_differences_show(self):
        a, b = self.facts(two_users(extra_scene={"env": {"darkness": True}})), self.facts(two_users(extra_scene={"env": {"darkness": False}}))
        self.assertNotEqual(a, b); self.assertIn("darkness true", a); self.assertIn("darkness false", b)
        v1, v2 = self.facts(two_users('{"a": 1, "b": 2, "visible": true}')), self.facts(two_users('{"a": 1, "b": 2, "visible": false}'))
        self.assertIn("supplied relation 1-2: visible true", v1); self.assertIn("visible false", v2)

    def test_the_adjudicator_prompt_shows_the_executed_heading(self):
        """The same prose with one heading reversed gives two prompts, each showing its own heading."""
        prompts = []
        saved = (review.validate_phase._session, review.precedent_rows, review.append_ruling)
        review.validate_phase._session = lambda *a, **k: (prompts.append(a[3]) or ({"rulings": [{"item": 1, "ruling": "dismissed", "reason": "r",
                                                                                                    "quote": "Aligned"}]}, []))
        review.precedent_rows = lambda *a, **k: []
        review.append_ruling = lambda *a, **k: None
        try:
            rec = ConceptRecord({"concept_id": "drv.motion.audit", "contract": "Aligned movement holds."})
            blocks = {"contract": "Aligned movement holds.", "record": "{}", "rendered": "body", "contracts": "contracts"}
            for h in ((1, 0), (-1, 0)):
                tr = two_users(heading2=h)
                item = {"line": "l", "rule": "fails", "verdict": "violated",
                        "facts": render_formula.trace_facts(tr, {"v": 1, "u": 2}, 0, {}, [], None),
                        "div": {"kind": "holds_wrongly", "situation": "Two aligned road users.", "contract_words": "Aligned",
                                "contract_verdict": "holds", "at": 0, "grounding": {"v": 1, "u": 2}, "instance": {}, "trace": tr}}
                with tempfile.TemporaryDirectory() as t:
                    review.adjudicate_concept(SimpleNamespace(iteration=1), rec, blocks, [item], Path(t))
        finally:
            review.validate_phase._session, review.precedent_rows, review.append_ruling = saved
        self.assertNotEqual(prompts[0], prompts[1])
        self.assertIn("track 2: classes [\"motor_vehicle\"]; kin.heading [1, 0]", prompts[0])
        self.assertIn("track 2: classes [\"motor_vehicle\"]; kin.heading [-1, 0]", prompts[1])


class StructuralItems(unittest.TestCase):
    """A structural item is checked before judgment; an upheld one is an obligation re-adjudicated
    on every later body, and an older untyped one is replayed, never filtered out."""
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.run = FakeRun(Path(self.tmp.name))
        self.run.all_concepts = lambda: {}
        self.rec = ConceptRecord({"concept_id": "drv.motion.test", "kind": "formula", "args": [], "contract": "Movement holds."})
        self.judged, self.ruling = [], "upheld"
        self.saved = (review.concept_blocks, review.session.run_tools, review.validate_phase._session, review.precedent_rows)
        review.concept_blocks = lambda *a, **k: ({k: "" for k in review.PLACEHOLDERS_REVIEW_CONCEPT}, "", "Movement holds.")
        review.precedent_rows = lambda *a, **k: []

        def session(_run, _out, label, prompt, check=None, **_k):
            n = len(re.findall(r"^\d+\. \(not_general\)", prompt, re.M))
            self.judged.append((label, n))
            return {"rulings": [{"item": i, "ruling": self.ruling, "reason": "r", "quote": "Movement"} for i in range(1, n + 1)]}, []
        review.validate_phase._session = session

    def tearDown(self):
        review.concept_blocks, review.session.run_tools, review.validate_phase._session, review.precedent_rows = self.saved
        self.tmp.cleanup()

    def review(self, not_general):
        answer = {"verdict": "return" if not_general else "accept", "divergences": [], "not_general": not_general, "advisories": []}
        review.session.run_tools = scripted_reviewer([submit(answer)] * 3)
        return review.review_concept(self.run, self.rec, {"reads": [], "body_json": {"tt": True}}, Path(self.tmp.name) / f"r{len(self.judged)}")

    def rows(self):
        return review.effective_rows(review._all_rows(self.run))

    def test_an_invalid_item_never_reaches_the_judge(self):
        out = self.review([{"words": "THIS IS FABRICATED", "why": "bad"}])
        self.assertEqual(self.judged, [])
        self.assertEqual(out.status, "deferred")
        self.review([{"words": "THIS IS FABRICATED", "why": "bad"}, {"words": "Movement", "why": "good"}])
        self.assertEqual(self.judged[-1], ("adjudicate", 1))                 # the valid one alone

    def test_an_upheld_finding_is_an_obligation(self):
        self.assertEqual(self.review([{"words": "Movement", "why": "tuned"}]).status, "returned")
        rows = [r for r in self.rows() if r.get("schema") == review.CONCEPT_STRUCTURAL_SCHEMA]
        self.assertEqual((len(rows), rows[0]["obligation"]), (1, "open"))
        out = self.review([])                                                # a new body, an empty review: the finding is decided again
        self.assertEqual(out.status, "returned")
        self.assertEqual(self.judged[-1][0], "adjudicate_replay")
        self.ruling = "dismissed"
        self.assertEqual(self.review([]).status, "accepted")                 # a ruling that discharges it
        self.assertEqual(self.review([]).status, "accepted")                 # and it is not replayed again
        self.assertEqual(sum(1 for lab, _n in self.judged if lab == "adjudicate_replay"), 2)

    def test_an_older_untyped_row_is_replayed(self):
        review.append_ruling(self.run, {"key": "concept:drv.motion.test", "subject": "drv.motion.test", "iteration": 1,
                                        "item": 'not general: "Movement" — tuned to one use', "ruling": "upheld", "reason": "r"})
        review.append_ruling(self.run, {"key": "concept:drv.motion.test", "subject": "drv.motion.test", "iteration": 1,
                                        "item": "a finding recorded in a form now unknown", "ruling": "upheld", "reason": "r"})
        self.assertEqual(self.review([]).status, "returned")
        self.assertEqual(self.judged[-1], ("adjudicate_replay", 2))
        self.ruling = "dismissed"
        self.review([])
        self.assertEqual(self.review([]).status, "accepted")
        self.assertEqual(sum(1 for lab, _n in self.judged if lab == "adjudicate_replay"), 2)   # migrated, then gone


class CarryOver(unittest.TestCase):
    """An upheld concept challenge that cannot be run on a new body is carried over to the reviewer;
    left unextended it keeps the review open."""
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.run = FakeRun(Path(self.tmp.name))
        self.run.all_concepts = lambda: {}
        self.rec = ConceptRecord({"concept_id": "drv.motion.x_v2", "supersedes": "drv.motion.x", "kind": "formula", "contract": "c holds",
                                  "args": [{"name": "u", "sort": "track"}, {"name": "w", "sort": "track"}], "params": []})
        self.old = {"key": "concept:drv.motion.x", "schema": review.CONCEPT_CASE_SCHEMA, "ruling": "upheld", "obligation": "open",
                    "subject": "drv.motion.x", "iteration": 1, "case_id": "k1", "kind": "holds_wrongly", "contract_verdict": "fails",
                    "contract_words": "c holds", "situation": "s", "instance": {"literals": {}, "params": {}}, "grounding": {"u": 1},
                    "trace": {"scenes": [{"t": 0}]}, "at": 0}
        review.append_ruling(self.run, self.old)
        self.saved = (review.concept_blocks, review.session.run_tools, review.execute_concept_divergences, review.adjudicate_concept)
        review.concept_blocks = lambda *a, **k: ({k: "" for k in review.PLACEHOLDERS_REVIEW_CONCEPT}, "", "c holds")
        review.adjudicate_concept = lambda *a, **k: []
        self.result = ([], [], [], [])
        review.execute_concept_divergences = lambda *_a, **_k: self.result

    def tearDown(self):
        review.concept_blocks, review.session.run_tools, review.execute_concept_divergences, review.adjudicate_concept = self.saved
        self.tmp.cleanup()

    def review(self, divs):
        answer = {"verdict": "return" if divs else "accept", "divergences": divs, "not_general": [], "advisories": []}
        prompts = []
        def run_tools(prompt, out_dir, opts, tools, **kw):
            prompts.append(prompt)
            return scripted_reviewer([submit(answer)] * 3)(prompt, out_dir, opts, tools, **kw)
        review.session.run_tools = run_tools
        out = review.review_concept(self.run, self.rec, {"reads": [], "body_json": {}}, Path(self.tmp.name) / "r")
        return out, prompts

    def test_an_unextended_challenge_defers_at_evidence(self):
        out, prompts = self.review([])
        self.assertEqual((out.status, out.defer_stage), ("deferred", "evidence"))
        self.assertIn("Challenges to carry over", prompts[0])
        self.assertIn("`k1`", prompts[0])

    def test_a_valid_extension_the_body_meets_satisfies_it(self):
        ext = {**{k: self.old[k] for k in review.CONCEPT_CASE_FIELDS if k in self.old}, "grounding": {"u": 1, "w": 2}, "extends": "k1"}
        self.result = ([], ["divergence 1 (holds_wrongly): the body agrees"], [], [])
        out, _p = self.review([ext])
        self.assertEqual(out.status, "accepted")
        rows = [r for r in review.effective_rows(review._all_rows(self.run)) if r.get("case_id") == "k1"]
        self.assertEqual(rows[-1]["obligation"], "satisfied")

    def test_a_ruling_on_an_extension_supersedes_the_predecessor_s(self):
        ext = {**{k: self.old[k] for k in review.CONCEPT_CASE_FIELDS if k in self.old}, "grounding": {"u": 1, "w": 2}, "extends": "k1"}
        item = {"line": "divergence 1 (holds_wrongly): it confirms", "div": ext, "rule": "holds", "verdict": "compliant"}
        self.result = ([item], [], [], [])
        saved = review.adjudicate_concept
        review.adjudicate_concept = self.saved[3]
        sess = review.validate_phase._session
        review.validate_phase._session = lambda *a, **k: ({"rulings": [{"item": 1, "ruling": "dismissed", "reason": "r", "quote": "c holds"}]}, [])
        try:
            out, _p = self.review([ext])
        finally:
            review.adjudicate_concept, review.validate_phase._session = saved, sess
        rows = [r for r in review.effective_rows(review._all_rows(self.run)) if r.get("case_id") == "k1"]
        self.assertEqual((len(rows), rows[0]["ruling"], rows[0]["subject"]), (1, "dismissed", "drv.motion.x_v2"))
        self.assertEqual(out.status, "accepted")

    def test_an_extension_that_does_not_continue_is_refused(self):
        bad = {**{k: self.old[k] for k in review.CONCEPT_CASE_FIELDS if k in self.old}, "grounding": {"u": 5, "w": 2}, "extends": "k1"}
        self.result = ([], ["divergence 1 (holds_wrongly): the body agrees"], [], [])
        out, _p = self.review([bad])
        self.assertEqual(out.status, "deferred")
        rows = [r for r in review.effective_rows(review._all_rows(self.run)) if r.get("case_id") == "k1"]
        self.assertEqual(rows[-1]["obligation"], "open")


# ---------------------------------------------------------------------------------------------
# Where a trace writes what an atom reads, for the reviewer and the planner's notes
# ---------------------------------------------------------------------------------------------
class TracePlace(unittest.TestCase):

    def test_a_chain_of_projections_and_a_named_record(self):
        self.assertEqual(review.trace_place("st_lane_direction"), "`structures[].lane.direction`")
        self.assertEqual(review.trace_place("dev_governs"), "`devices[].governs`")
        self.assertEqual(review.trace_place("st_sight_along_way"), "`users[].sight_along_way`")
        self.assertEqual(review.trace_place("kin_speed"), "`users[].kin.speed`")
        self.assertIn("`structures[].boundary`", review.trace_place("rel_contact_structure"))
        self.assertIn("`users[].kin`", review.trace_place("rel_contact_structure"))
        self.assertEqual(review.trace_place("dev_governs_sidewalk"), "`devices[].governs_sidewalk`")
        self.assertEqual(review.trace_place("dev_governs_parking_space"), "`devices[].governs_parking_space`")
        self.assertEqual(review.trace_place("dev_regulatory_sign_legend_angle"), "`devices[].legend_angle`")
        self.assertEqual(review.trace_place("dev_regulatory_sign_legend_angle_stated"), "`devices[].legend_angle`")
        self.assertEqual(review.trace_place("st_parking_space_angle_marking"), "`structures[].angle_marking`")
        self.assertEqual(review.trace_place("st_parking_space_axis"), "`structures[].axis`")
        self.assertEqual(review.trace_place("ru_trimobile"), "`users[].classes`")

    def test_every_accessor_names_a_place(self):
        from harness.store import paths
        src = (paths.CORE / "Vocab" / "Atoms.lean").read_text(encoding="utf-8")
        names = re.findall(r"^def ((?:ru|kin|st|dev|sig|env|rel)_\w+) \(s : Scene\)", src, re.M)
        vague = sorted(n for n in names if review.trace_place(n) == "(see the trace format)")
        self.assertEqual(vague, ["kin_time", "ru_subject"])     # the scene's own subject and time, not an entity's field


if __name__ == "__main__":
    unittest.main()
