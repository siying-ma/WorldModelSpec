"""Development regression tests for the concept review's routing: the effective-ruling reducer, the
bounded judge deferral of the ledgers, fail-closed concept adjudication, the reviewer's tool state
and the run's status — with every session stubbed."""
import json
import tempfile
import unittest
from pathlib import Path
from types import SimpleNamespace

from harness.model import corpus, ontology
from harness.model.blueprint import Node
from harness.phases import feedback, review
from harness.phases import validate as validate_phase
from harness.store import paths
from harness.store.state import Options
from harness.store.ledger import ConceptLedger, Ledger

ONTO = ontology.load(paths.REPO / "ontology" / "ATOMS_train.md")
LAW = corpus.Law("L-1", "A duty", "The driver of a vehicle shall stop before the line.", "")


class FakeRun:
    def __init__(self, d: Path):
        self.dir = d
        self.iteration = 1
        self.opts = Options(run_id="t", laws=d / "laws.jsonl", ontology=ONTO.path, reading=d / "reading.json",
                            model="m", reviewer_model="gpt-x")
        self.reading_file = d / "reading.json"
        if not self.reading_file.exists():
            self.reading_file.write_text(json.dumps({"params": [], "aggregates": []}))

    @property
    def iter(self):
        return self.dir / f"iter-{self.iteration:03d}"

    def all_nodes(self):
        return {}

    def all_concepts(self):
        return {}


def node() -> Node:
    return Node({"node_id": "L_1_o1", "law_refs": ["L-1"], "binders": [{"name": "v"}],
                 "segmentation": [{"id": "s1", "role": "obligation", "text": "shall stop before the line"}]})


class ReviewerRequired(unittest.TestCase):
    def test_missing_reviewer_can_only_accept_in_a_dry_run(self):
        with tempfile.TemporaryDirectory() as d:
            run = FakeRun(Path(d))
            run.opts.reviewer_model = None
            call = lambda: review.review_concept(run, None, None, Path(d))
            with self.assertRaisesRegex(RuntimeError, "reviewer_model is required"):
                call()
            run.opts.dry_run = True
            self.assertEqual(call().status, "accepted")


def div(**kw):
    d = {"kind": "rule_permits_unlawful", "situation": "s", "law_words": "shall stop", "lawful_verdict": "violated",
         "grounding": {"v": 1}, "trace": {"scenes": [{"t": 0}]}, "case": "tt", "entities": {}, "at": 0}
    d.update(kw)
    return d


def scripted_reviewer(calls, seen=None):
    """A stub for `session.run_tools`: the reviewer's tool calls, in order, until a submission is
    accepted; `seen` collects each tool result."""
    def run_tools(prompt, out_dir, opts, tools, **_kw):
        tools.reset()
        for name, args in calls:
            if tools.done:
                break
            out = tools.call(name, args)
            if seen is not None:
                seen.append(json.loads(out))
        return {"code": 0, "result": {"submitted": tools.done}}
    return run_tools


def submit(answer):
    return ("submit_review", {"answer": answer})


class Supersession(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.run = FakeRun(Path(self.tmp.name))

    def tearDown(self):
        self.tmp.cleanup()

    def row(self, ruling):
        return {"schema": review.CONCEPT_CASE_SCHEMA, "key": "concept:drv.test.c", "subject": "drv.test.c", "case_id": "c1", "ruling": ruling}

    def test_repeated_replay_chains(self):
        for _ in range(3):
            review.append_ruling(self.run, self.row("upheld"))
        self.assertEqual(len(review.effective_rows(review._all_rows(self.run))), 1)

    def test_malformed_supersession_fails_closed(self):
        f = self.run.dir / "rulings.jsonl"
        f.write_text(json.dumps({"ruling_id": "b", "supersedes": "missing", "ruling": "upheld"}) + "\n")
        with self.assertRaises(review.RulingsError):
            review.effective_rows(review._all_rows(self.run))
        f.write_text("".join(json.dumps(r) + "\n" for r in [{"ruling_id": "a"}, {"ruling_id": "b", "supersedes": "a"}, {"ruling_id": "c", "supersedes": "a"}]))
        with self.assertRaises(review.RulingsError):
            review.effective_rows(review._all_rows(self.run))
        f.write_text("".join(json.dumps(r) + "\n" for r in [{"ruling_id": "a", "supersedes": "b"}, {"ruling_id": "b", "supersedes": "a"}]))
        with self.assertRaises(review.RulingsError):
            review.effective_rows(review._all_rows(self.run))


class Deferral(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.d = Path(self.tmp.name)

    def tearDown(self):
        self.tmp.cleanup()


    def test_concept_deferral(self):
        cl = ConceptLedger(self.d / "c.jsonl", 3)
        cl.planned("drv.motion.halt", ["L_1_o1"], 1)
        self.assertFalse(cl.defer_judge("drv.motion.halt", "concept_adjudication", ["x"]))
        e = cl.entries["drv.motion.halt"]
        self.assertEqual((e.state, e.attempts, e.used_by), ("planned", 0, ["L_1_o1"]))
        self.assertTrue(cl.defer_judge("drv.motion.halt", "concept_adjudication", ["x"]))
        self.assertEqual(cl.entries["drv.motion.halt"].state, "failed")

    def test_selection_correction_once(self):
        led = Ledger(self.d / "l.jsonl", ["L-1"], 2)
        self.assertFalse(led.selection_correction("L-1"))
        self.assertTrue(led.selection_correction("L-1"))


class ConceptAdjudication(unittest.TestCase):
    def test_an_unruled_item_defers_never_upholds(self):
        tmp = tempfile.TemporaryDirectory()
        run = FakeRun(Path(tmp.name))
        saved = validate_phase._session
        validate_phase._session = lambda *a, **k: ({"rulings": []}, ["item 1 has no ruling"])
        try:
            rec = SimpleNamespace(id="drv.motion.halt", raw={})
            blocks = {k: "" for k in ("contract", "record", "rendered", "contracts")}
            item = {"line": "x", "div": {"kind": "holds_wrongly"}, "rule": "holds"}
            with self.assertRaises(review.Deferred) as e:
                review.adjudicate_concept(run, rec, blocks, [item], Path(tmp.name))
            self.assertEqual(e.exception.stage, "concept_adjudication")
        finally:
            validate_phase._session = saved
            tmp.cleanup()


class RunStatus(unittest.TestCase):
    def test_status_is_recorded(self):
        tmp = tempfile.TemporaryDirectory()
        run = FakeRun(Path(tmp.name))
        led = Ledger(Path(tmp.name) / "l.jsonl", ["L-1"], 2)
        feedback.write_status(run, led, "infrastructure_failure", "a session could not be launched")
        s = json.loads((Path(tmp.name) / "summary.json").read_text())
        self.assertEqual((s["status"], s["stop_reason"]), ("infrastructure_failure", "a session could not be launched"))
        tmp.cleanup()

    def test_laws_never_planned_are_listed(self):
        """A law still open that no plan was registered or returned for is named; a law planned once
        and reopened, or returned, is not."""
        with tempfile.TemporaryDirectory() as t:
            run = FakeRun(Path(t))
            led = Ledger(Path(t) / "l.jsonl", ["L-1", "L-2", "L-3", "L-4"], 2)
            led.mark_planned("L-2", ["L_2"], 1); led.fail("L-2", ["closed"]); led.reopen(["L-2"])
            led.mark_planned("L-3", ["L_3"], 1); led.return_law("L-3", ["r"], 1)
            led.block("L-4", ["g1"], ["gap"])
            s = feedback.write_status(run, led, "incomplete", "the iteration bound (1) was reached")
            self.assertEqual(s["never_planned"], ["L-1"])
            self.assertEqual(led.entries["L-2"].state, "open")


class TwoAnswers(unittest.TestCase):
    """A session gives an answer and one correction, never a third."""
    def test_the_second_answer_stands(self):
        from harness.agents import session
        saved, calls = session.run, []

        def fake(prompt, **kw):
            calls.append(kw.get("label"))
            return {"result": {"result": json.dumps({})}}
        session.run = fake
        try:
            tmp = tempfile.TemporaryDirectory()
            run = FakeRun(Path(tmp.name))
            _ans, errs = validate_phase._session(run, Path(tmp.name), "r", "p", check=lambda a: ["bad"])
            tmp.cleanup()
        finally:
            session.run = saved
        self.assertEqual((errs, calls), (["bad"], ["r", "r_again"]))


class ConceptFailClosed(unittest.TestCase):
    """A concept review routes like a node review: upheld returns; an unusable challenge defers; a
    trace on which the body gives the contract's verdict is an advisory."""
    def setUp(self):
        from harness.lean import render_formula
        from harness.model.blueprint import ConceptRecord
        self.tmp = tempfile.TemporaryDirectory()
        self.run = FakeRun(Path(self.tmp.name))
        self.run.opts.ontology = paths.REPO / "ontology" / "ATOMS_train.md"
        self.run.all_concepts = lambda: {}
        self.rec = ConceptRecord({"concept_id": "drv.test.c", "contract": "c holds", "kind": "formula", "args": [{"name": "u", "sort": "track"}],
                                  "params": [], "elements": []})
        self.saved = (render_formula.render_concept, review.session.run_tools, review.execute_concept_divergences, review.adjudicate_concept)
        render_formula.render_concept = lambda *_a, **_kw: "the rendering"
        self.result, self.rulings = ([], [], [], []), []
        review.execute_concept_divergences = lambda _rec, _a, _out, *_r, **_k: self.result
        review.adjudicate_concept = lambda *_a, **_kw: self.rulings

    def tearDown(self):
        from harness.lean import render_formula
        (render_formula.render_concept, review.session.run_tools, review.execute_concept_divergences, review.adjudicate_concept) = self.saved
        self.tmp.cleanup()

    def review(self, answer):
        review.session.run_tools = scripted_reviewer([submit(answer)] * 3)
        return review.review_concept(self.run, self.rec, {"reads": [], "body_json": {}}, Path(self.tmp.name))

    def good(self):
        return {"kind": "holds_wrongly", "contract_verdict": "fails", "contract_words": "c holds", "situation": "s",
                "instance": {"literals": {}, "params": {}}, "grounding": {"u": 1}, "trace": {"scenes": [{"t": 0}]}, "at": 0}

    def test_a_malformed_return_defers(self):
        bad = {**self.good(), "instance": {"literals": {"2": "2"}, "params": {}}}
        out = self.review({"verdict": "return", "divergences": [bad], "not_general": [], "advisories": []})
        self.assertEqual((out.status, out.defer_stage), ("deferred", "reviewer"))

    def test_a_harness_error_defers(self):
        self.result = ([], [], ["divergence 1: the trace does not decode: x"], [])
        out = self.review({"verdict": "return", "divergences": [self.good()], "not_general": [], "advisories": []})
        self.assertEqual((out.status, out.defer_stage), ("deferred", "reviewer"))

    def test_an_agreeing_trace_accepts(self):
        self.result = ([], ["divergence 1: the body gives the contract's verdict"], [], [])
        out = self.review({"verdict": "return", "divergences": [self.good()], "not_general": [], "advisories": []})
        self.assertEqual(out.status, "accepted")
        self.assertTrue(any("refuted by execution" in a for a in out.advisories))


class QuantityDivergence(unittest.TestCase):
    """A quantity concept's divergence states the interval the contract's words give its value: one
    dimension, the value's; never a verdict."""
    def setUp(self):
        from harness.model.blueprint import ConceptRecord
        self.rec = ConceptRecord({"concept_id": "drv.test.q", "kind": "quantity", "contract": "the distance it covers",
                                  "args": [{"name": "u", "sort": "track"}], "params": [{"name": "t", "unit": "s"}]})
        self.body = {"mul": [{"measure": "kin_speed", "args": [{"var": "u"}]}, {"param": "t"}]}

    def div(self, **kw):
        d = {"kind": "value_wrongly", "situation": "s", "contract_words": "the distance it covers",
             "contract_value": {"lo": [10, "m"], "hi": [12, "m"]}, "instance": {"literals": {}, "params": {"t": [1, "s"]}},
             "grounding": {"u": 1}, "trace": {"scenes": [{"t": 0}]}, "at": 0}
        d.update(kw)
        return d

    def defects(self, d):
        return review.concept_divergence_defects(1, d, self.rec, "the distance it covers", review.body_dim(self.rec, self.body))

    def test_the_body_is_in_metres(self):
        self.assertEqual(review.body_dim(self.rec, self.body), (1, 0, 0))

    def test_an_interval_in_metres_is_admitted(self):
        self.assertEqual(self.defects(self.div()), [])

    def test_an_interval_of_another_dimension(self):
        self.assertTrue(any("the value is in m" in e for e in self.defects(self.div(contract_value={"lo": [1, "s"], "hi": [2, "s"]}))))

    def test_a_verdict_is_not_a_value(self):
        self.assertTrue(any("never `contract_verdict`" in e for e in self.defects(self.div(contract_verdict="fails"))))

    def test_lo_above_hi(self):
        self.assertTrue(any("exceeds" in e for e in self.defects(self.div(contract_value={"lo": [12, "m"], "hi": [10, "m"]}))))


class TruncationRemedy(unittest.TestCase):
    """A trace whose look-back is cut short is returned with the history the verdict reads."""

    def test_the_truncation_message_states_the_history(self):
        msg = review._trace_remedy("window_truncated:prim_heading_change", "", "the verdict at `at` reads up to 12 s before the observation before `at`")
        self.assertIn("observation before `at`", msg)


class RegionPlaces(unittest.TestCase):
    """A record claims, for every region argument of each atom it claims, a kind that can bind it:
    one whose regions include a kind Core admits there, or any kind where Core admits any. How the
    region is tied to the road user is the formula's, which the gate checks."""
    def test_a_property_without_its_kind_returns(self):
        from harness.checks import validate_a
        self.assertIn("st.crest", validate_a.region_kinds(ONTO))                   # a kind: claiming it names the place
        errs = validate_a.check_region_places("N", {"st.curvature", "st.sight_distance", "st.region_geometry"}, ONTO)
        self.assertTrue(errs and "kind of region" in errs[0] and "st.curvature" in errs[0])

    def test_a_property_with_its_kind_passes_without_occupancy(self):
        from harness.checks import validate_a
        self.assertEqual(validate_a.check_region_places("N", {"st.curvature", "st.roadway", "st.sight_distance"}, ONTO), [])

    def test_no_property_no_demand(self):
        from harness.checks import validate_a
        self.assertEqual(validate_a.check_region_places("N", {"st.crest", "st.region_geometry", "kin.speed"}, ONTO), [])

    def test_core_states_the_carriers(self):
        from harness.lean import surface
        kinds = surface.region_argument_kinds(ONTO)
        carriers = kinds["st_lane_enters"][1][0][0]
        self.assertTrue({"lane", "turn_lane", "roadway", "shoulder", "bicycle_lane_or_path"} <= carriers)
        self.assertNotIn("intersection", carriers)
        self.assertIsNone(kinds["st_lane_enters"][1][0][1])                       # the intersection it enters: any kind
        self.assertEqual(kinds["st_entrance_of"][1][0], [frozenset({"stop_line", "crosswalk"}), carriers])
        self.assertNotIn("highway", kinds["dev_governs"][1][0][0])
        self.assertEqual(kinds["st_sight_along_way"][1][0], [frozenset({"highway"})])
        # a direction carrier: the primitive reads it through `st_lane_direction`, as the atom does
        self.assertEqual(kinds["prim_region_offset_along"][1][0], [None, kinds["st_lane_direction"][1][0][0]])
        self.assertNotIn("centre_turn_lane", kinds["st_lane_direction"][1][0][0])
        self.assertEqual(kinds["st_curvature"][1], [[None]])
        self.assertEqual(kinds["st_lane"][1], [[None]])                           # a class atom reads the label: any

    def test_the_constraints_read_no_trace_check_text(self):
        """The constraints come from running Core, never from TraceLint's messages: with the trace
        check's source unreadable, the reader still gives them."""
        from harness.lean import surface
        surface.region_argument_kinds(ONTO)                                       # the export exists
        saved, cached = surface._read, dict(surface._ARGUMENT_KINDS)
        surface._ARGUMENT_KINDS.clear(); surface._REGION_KINDS.clear()

        def read(name):
            if "TraceLint" in name:
                raise AssertionError("the trace check's source was read")
            return saved(name)
        surface._read = read
        try:
            self.assertIn("st_lane_enters", surface.region_argument_kinds(ONTO))
        finally:
            surface._read = saved
            surface._ARGUMENT_KINDS.update(cached)

    def _with_table(self, edit):
        """A library whose cached export is Core's table changed by `edit` (entries → entries)."""
        from harness.lean import surface
        _key, _inputs, cache = surface.region_kinds_cache()
        surface.region_kinds_export()
        data = json.loads(cache.read_text())
        data["entries"] = edit(data["entries"])
        tmp = tempfile.TemporaryDirectory()
        lib = Path(tmp.name)
        (lib / ".lake" / "region_kinds").mkdir(parents=True)
        (lib / ".lake" / "region_kinds" / cache.name).write_text(json.dumps(data))
        return tmp, lib

    def _without(self, name, position=None):
        return self._with_table(lambda es: [x for x in es if not (x["name"] == name and position in (None, x["position"]))])

    def _in_library(self, lib, body):
        from harness.lean import surface
        saved = (paths.LIBRARY, dict(surface._ARGUMENT_KINDS), dict(surface._REGION_KINDS))
        paths.LIBRARY = lib
        surface._ARGUMENT_KINDS.clear(); surface._REGION_KINDS.clear()
        try:
            body()
        finally:
            paths.LIBRARY = saved[0]
            surface._ARGUMENT_KINDS.clear(); surface._ARGUMENT_KINDS.update(saved[1])
            surface._REGION_KINDS.clear(); surface._REGION_KINDS.update(saved[2])

    def _concept(self, atom):
        from harness.checks import validate_a
        from harness.model.blueprint import ConceptRecord
        rec = ConceptRecord({"concept_id": "drv.test.c", "contract": "c holds", "kind": "formula",
                             "args": [{"name": "u", "sort": "track"}], "params": [], "scenarios": [],
                             "elements": [{"span": "c holds", "atoms": [atom]}]})
        self.assertEqual(validate_a.schema_errors("c", rec.raw, validate_a.CONCEPT_SCHEMA), [])
        return rec

    def _faults(self, lib, atom, name):
        from harness.checks import validate_a
        rec = self._concept(atom)

        def body():
            with self.assertRaises(validate_a.ValidatorFault) as e:
                validate_a.validate_concepts([rec], [], ONTO, {}, [])
            self.assertIn(name, e.exception.trace)
            self.assertIn("RegionKindsUnavailable", e.exception.trace)
        self._in_library(lib, body)

    def test_a_deleted_entry_is_a_validator_fault(self):
        tmp, lib = self._without("st_lane_enters")
        with tmp:
            self._faults(lib, "st.lane_enters", "st_lane_enters")

    def test_one_missing_argument_is_a_validator_fault(self):
        """The entry of the first region argument does not stand for the second."""
        tmp, lib = self._without("st_lane_enters", 1)
        with tmp:
            self._faults(lib, "st.lane_enters", "argument 1 of st_lane_enters")

    def test_explicit_any_is_not_a_missing_entry(self):
        """`any` declares that any kind may stand there: the check asks for some kind, and runs; the
        same argument with no entry stops the validator."""
        from harness.checks import validate_a
        tmp, lib = self._with_table(lambda es: es)

        def body():
            errs = validate_a.check_region_places("N", {"st.curvature"}, ONTO)
            self.assertTrue(errs and "any kind of region" in errs[0])
            self.assertEqual(validate_a.check_region_places("N", {"st.curvature", "st.crest"}, ONTO), [])
        with tmp:
            self._in_library(lib, body)
        tmp, lib = self._without("st_curvature", 0)
        with tmp:
            self._faults(lib, "st.curvature", "st_curvature")

    def test_the_table_is_read_as_declared(self):
        """A kind list in the table is the constraint: narrowed there, the check narrows with it."""
        from harness.checks import validate_a
        from harness.lean import surface

        def narrow(es):
            return [{**x, "admitted": ["roadway"]} if (x["name"], x["position"]) == ("st_lane_direction", 0) else x for x in es]
        tmp, lib = self._with_table(narrow)

        def body():
            self.assertEqual(surface.region_argument_kinds(ONTO)["st_lane_direction"][1], [[frozenset({"roadway"})]])
            self.assertTrue(validate_a.check_region_places("N", {"st.lane_direction", "st.lane"}, ONTO))
        with tmp:
            self._in_library(lib, body)
        self.assertEqual(validate_a.check_region_places("N", {"st.lane_direction", "st.lane"}, ONTO), [])

    def test_a_failed_export_is_a_validator_fault(self):
        from harness.checks import validate_a
        from harness.lean import lean
        with tempfile.TemporaryDirectory() as t:
            saved = lean.lean_run
            lean.lean_run = lambda *_a, **_k: (1, "error: the exporter did not elaborate")

            def body():
                with self.assertRaises(validate_a.ValidatorFault) as e:
                    validate_a._guarded("N", validate_a.check_region_places, "N", {"st.lane_enters"}, ONTO)
                self.assertIn("did not elaborate", e.exception.trace)
            try:
                self._in_library(Path(t), body)
            finally:
                lean.lean_run = saved

    def test_every_region_argument_needs_a_kind_that_binds_it(self):
        from harness.checks import validate_a
        # the carrier of an entry relation is no intersection
        errs = validate_a.check_region_places("N", {"st.lane_enters", "st.intersection", "rel.occupies"}, ONTO)
        self.assertTrue(errs and "`st.lane_enters` (region argument 1)" in errs[0] and "`st.travel_region`" in errs[0]
                        and "`st.intersection`" not in errs[0].split("claim, on")[1])
        # an abstract kind binds it through the kinds refining it, a lane-family kind directly
        for carrier in ("st.travel_region", "st.lane", "st.turn_lane", "st.roadway"):
            self.assertEqual(validate_a.check_region_places("N", {"st.lane_enters", "st.intersection", carrier}, ONTO), [], carrier)
        # every argument at once: the mark and the carrier of an entrance
        errs = validate_a.check_region_places("N", {"st.entrance_of", "st.intersection"}, ONTO)
        self.assertEqual(len(errs), 1)
        self.assertIn("(region argument 1)", errs[0]); self.assertIn("(region argument 2)", errs[0])
        self.assertEqual(validate_a.check_region_places("N", {"st.entrance_of", "st.stop_line", "st.lane"}, ONTO), [])
        # a device governs no highway
        self.assertTrue(validate_a.check_region_places("N", {"dev.governs", "dev.speed_limit_sign", "st.highway"}, ONTO))
        self.assertEqual(validate_a.check_region_places("N", {"dev.governs", "dev.speed_limit_sign", "st.highway", "st.travel_region"}, ONTO), [])


def _trace(same_direction: bool) -> dict:
    return {"scenes": [{"t": 0, "users": [{"track": 1}, {"track": 2}], "relations": [{"a": 1, "b": 2, "same_direction": same_direction}]}]}


class RegionKindsProbe(unittest.TestCase):
    """Core's declared region-argument kinds against a probe of Core over admitted traces
    (`scripts/tests/region_kinds_probe.lean`). The probe only refutes: a kind read at an argument
    outside its list (the table too narrow), or a listed kind on which the trace check rejects every
    field the name reads there, set alone (too broad). A kind the probe does not read is never
    removed. The probe is no proof that the table and every evaluation path agree."""
    PROBE = paths.REPO / "scripts" / "tests" / "region_kinds_probe.lean"
    probe: dict = {}

    @classmethod
    def setUpClass(cls):
        from harness.lean import lean, surface
        sigs = [{"name": n, "args": a} for n, _aid, a in surface._region_signatures(ONTO)]
        with tempfile.TemporaryDirectory() as t:
            inp = Path(t) / "signatures.json"
            inp.write_text(json.dumps({"signatures": sigs}))
            code, out = lean.lean_run(paths.LIBRARY, cls.PROBE, args=(str(inp),))
        assert code == 0, out[-2000:]
        cls.probe = json.loads(out.strip().splitlines()[-1])

    @staticmethod
    def table():
        from harness.lean import surface
        return {(e["name"], e["position"]): e["admitted"] for e in surface.region_kinds_export()}

    def refute(self, table):
        """(outside, rejected, unexercised, unshown): (name, position, kind) read outside the list;
        listed but rejected on every target field; listed, neither read nor rejected; a label kind
        left out of the list that no target field's rejection shows."""
        labels = set(self.probe["labels"])
        outside, rejected, unexercised, unshown = set(), set(), set(), set()
        for e in self.probe["entries"]:
            for r in e["regions"]:
                key = (e["name"], r["position"])
                self.assertIn(key, table, f"the table has no entry for a probed argument {key}")
                ks = table[key]
                if ks == "any":
                    continue
                ks, read = set(ks), set(r["read"])
                rej = {x["kind"] for x in r["rejected"]}
                outside |= {(*key, k) for k in read - ks}
                rejected |= {(*key, k) for k in ks & rej}
                unexercised |= {(*key, k) for k in ks - read - rej}
                unshown |= {(*key, k) for k in labels - ks - rej}
        return outside, rejected, unexercised, unshown

    def region(self, name, position):
        return next(r for e in self.probe["entries"] if e["name"] == name for r in e["regions"] if r["position"] == position)

    def test_the_declared_table_survives_the_probe(self):
        outside, rejected, unexercised, unshown = self.refute(self.table())
        self.assertEqual(outside, set())
        self.assertEqual(rejected, set())
        self.assertEqual(unexercised, set(), "the probe no longer exercises a listed kind")
        self.assertEqual(unshown, set(), "a kind left out of a list is not rejected by the field read there")

    def test_a_narrowed_list_is_refuted(self):
        t = self.table()
        t[("st_lane_direction", 0)] = [k for k in t[("st_lane_direction", 0)] if k != "shoulder"]
        self.assertIn(("st_lane_direction", 0, "shoulder"), self.refute(t)[0])

    def test_a_widened_list_is_refuted_on_the_field_read_there(self):
        t = self.table()
        t[("st_lane_direction", 0)] = t[("st_lane_direction", 0)] + ["centre_turn_lane"]
        t[("dev_governs", 1)] = t[("dev_governs", 1)] + ["highway"]
        t[("prim_region_offset_along", 2)] = t[("prim_region_offset_along", 2)] + ["centre_turn_lane"]
        rejected = self.refute(t)[1]
        self.assertEqual(rejected, {("st_lane_direction", 0, "centre_turn_lane"), ("dev_governs", 1, "highway"),
                                    ("prim_region_offset_along", 2, "centre_turn_lane")})
        self.assertEqual(self.region("st_lane_direction", 0)["targets"], ["region 1 lane.direction"])
        self.assertEqual(self.region("dev_governs", 1)["targets"], ["device governs region 1"])
        self.assertEqual(self.region("prim_region_offset_along", 2)["targets"], ["region 2 lane.direction"])

    def test_an_unrestricted_argument_is_not_refuted(self):
        """The region the offset is measured to reads only geometry: no field is rejected there, so a
        list would show every label kind as unexercised or read, never as rejected."""
        r = self.region("prim_region_offset_along", 1)
        self.assertEqual(set(r["read"]), set(self.probe["labels"]))
        self.assertEqual(r["rejected"], [])


class IntegrityStop(unittest.TestCase):
    """A damaged audit file read by any phase ends the run as `data_integrity_failure`."""
    def test_the_run_stops(self):
        from harness import loop
        from harness.store import jsonl
        from harness.store.state import Options
        run_id = "_test_integrity_stop"
        saved = loop._run_loop
        loop._run_loop = lambda opts: (_ for _ in ()).throw(jsonl.DataIntegrityError(Path("aggregate_certificates.jsonl"), 3, "not JSON"))
        try:
            out = loop.run_loop(Options(run_id=run_id, laws=Path("laws.jsonl"), ontology=Path("o.md"), reading=Path("r.json")))
            self.assertEqual(out["status"], "data_integrity_failure")
            s = json.loads((paths.run_dir(run_id) / "summary.json").read_text())
            self.assertEqual(s["status"], "data_integrity_failure")
            self.assertIn("aggregate_certificates.jsonl:3", s["stop_reason"])
        finally:
            loop._run_loop = saved
            import shutil
            shutil.rmtree(paths.run_dir(run_id), ignore_errors=True)


class ConceptLiteralsMessage(unittest.TestCase):
    """With no literal formal, the defect names the extra keys and the empty map it wants."""

    def test_no_literal_formal(self):
        from harness.model.blueprint import ConceptRecord
        rec = ConceptRecord({"concept_id": "drv.test.c", "args": [{"name": "u", "sort": "track"}], "params": []})
        d = {"kind": "holds_wrongly", "contract_verdict": "fails", "contract_words": "c", "instance": {"literals": {"2": "2"}, "params": {}},
             "grounding": {"u": 1}, "trace": {"scenes": [{"t": 0}]}}
        errs = review.concept_divergence_defects(1, d, rec, "c")
        self.assertTrue(any("['2'] are not literal formals" in e and "`{}`" in e for e in errs), errs)

    def test_the_record_names_no_literal_formal(self):
        from harness.model.blueprint import ConceptRecord
        line = review.literal_formals_line(ConceptRecord({"concept_id": "drv.test.c", "args": [{"name": "u", "sort": "track"}]}))
        self.assertIn("`instance.literals` is `{}`", line)


class SubsetRun(unittest.TestCase):
    """A subset run plans its listed laws again, even where its base run accepted them."""

    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.saved = paths.RESULTS
        paths.RESULTS = Path(self.tmp.name)
        base = paths.run_dir("base"); base.mkdir()
        (base / "options.json").write_text(json.dumps({"run_id": "base"}))
        rows =[{"node_id": "L_1", "law_refs": ["L-1"]}, {"node_id": "L_2", "law_refs": ["L-2"]}]
        (base / "accepted_nodes.jsonl").write_text("".join(json.dumps(r) + "\n" for r in rows))
        self.corpus = Path(self.tmp.name) / "corpus" / "laws.jsonl"; self.corpus.parent.mkdir()
        self.corpus.write_text("".join(json.dumps({"id": i, "title": "", "text": "t", "source": ""}) + "\n" for i in ("L-1", "L-2", "L-3")))
        (self.corpus.parent / "definitions.jsonl").write_text('{"id": "DEF-1"}\n')

    def tearDown(self):
        paths.RESULTS = self.saved
        self.tmp.cleanup()

    def run_of(self, laws: Path):
        from harness.store.state import Options, Run
        run = Run(Options(run_id="sub", laws=laws, ontology=Path("o.md"), reading=Path("r.json"), base_run="base"))
        run.load_accepted()
        return run

    def test_listed_law_is_not_taken_from_the_base(self):
        from scripts.subset_laws import subset
        laws = subset("sub", self.corpus, ["L-1"])
        self.assertEqual([json.loads(l)["id"] for l in laws.read_text().splitlines()], ["L-1"])
        self.assertTrue((laws.parent / "definitions.jsonl").exists())
        self.assertEqual(sorted(self.run_of(laws).base_nodes), ["L_2"])

    def test_a_base_node_composing_a_dropped_one_stops(self):
        from scripts.subset_laws import subset
        f = paths.run_dir("base") / "accepted_nodes.jsonl"
        f.write_text(f.read_text().replace('"law_refs": ["L-2"]}', '"law_refs": ["L-2"], "compositions": [{"rule": "L_1"}]}'))
        with self.assertRaisesRegex(SystemExit, "compose a node of a law this run plans again"):
            self.run_of(subset("sub", self.corpus, ["L-1"]))

    def test_a_stray_goes_to_the_base_run_first(self):
        from harness.loop import _owner_run
        other = paths.run_dir("a_older"); other.mkdir()
        (other / "accepted_nodes.jsonl").write_text(json.dumps({"node_id": "L_1", "law_refs": ["L-1"]}) + "\n")
        self.assertEqual(_owner_run("L_1"), "a_older")
        self.assertEqual(_owner_run("L_1", "base"), "base")

    def test_isolation_moves_the_dropped_node_to_the_base_run(self):
        from harness import loop
        from harness.lean import index_sync
        from harness.model import nodeid
        from scripts.subset_laws import subset
        old = paths.LIBRARY
        saved = {k: v for k, v in vars(paths).items() if isinstance(v, Path) and (v == old or old in v.parents)}
        lib = Path(self.tmp.name) / "library"
        try:
            for k, v in saved.items():
                setattr(paths, k, lib / v.relative_to(old))
            for nid in ("L_1", "L_2"):
                for rel in (nodeid.rule_path(nid), nodeid.witness_path(nid)):
                    (lib / rel).parent.mkdir(parents=True, exist_ok=True); (lib / rel).write_text(f"-- {nid}\n")
            saved_index, index_sync.write_index = index_sync.write_index, lambda *a, **k: None
            try:
                loop.check_library_isolation(self.run_of(subset("sub", self.corpus, ["L-1"])))
            finally:
                index_sync.write_index = saved_index
            self.assertFalse((lib / nodeid.rule_path("L_1")).exists())
            self.assertTrue((paths.run_dir("base") / "library_snapshot" / nodeid.rule_path("L_1")).exists())
            self.assertTrue((lib / nodeid.rule_path("L_2")).exists())             # the base node stays
        finally:
            for k, v in saved.items():
                setattr(paths, k, v)

    def test_subset_is_written_once_and_names_known_laws(self):
        from scripts.subset_laws import subset
        with self.assertRaises(SystemExit):
            subset("sub", self.corpus, ["L-9"])
        subset("sub", self.corpus, ["L-1"])
        subset("sub", self.corpus, ["L-1"])                                    # the same contents: allowed
        with self.assertRaises(SystemExit):
            subset("sub", self.corpus, ["L-2"])


class ToolChoice(unittest.TestCase):
    """The reviewer's tool state, counted apart for checks and submissions: once its checks are spent
    the next call it may make is a submission and a further check is refused; the last submission
    stands with its defects."""
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()

    def tearDown(self):
        self.tmp.cleanup()

    def tools(self, checks: int, submissions: int):
        from harness.model.blueprint import ConceptRecord
        rec = ConceptRecord({"concept_id": "drv.test.c", "contract": "c holds", "kind": "formula", "args": [{"name": "u", "sort": "track"}],
                             "params": [], "elements": []})
        return review.ConceptTools(rec, "c holds", "the rendering", None, Path(self.tmp.name), checks, submissions)

    def test_the_tool_choice_names_the_submission_once_checks_are_spent(self):
        t = review.ReviewTools(Path(self.tmp.name), 1, 2)
        self.assertEqual(t.choice(), "required")
        t.used_checks = 1
        self.assertEqual(t.choice(), {"type": "function", "name": "submit_review"})

    def test_a_check_past_the_last_is_refused(self):
        t = self.tools(1, 2)
        first = json.loads(t.call("run_instance", {"divergence": {}}))          # a schema defect: nothing is run
        self.assertEqual(first["status"], "schema defects")
        second = json.loads(t.call("run_instance", {"divergence": {}}))
        self.assertEqual(second["status"], "checks spent")
        self.assertEqual(t.used_checks, 1)

    def test_the_last_submission_stands_with_its_defects(self):
        t = self.tools(1, 2)
        bad = {"verdict": "neither", "divergences": [], "not_general": [], "advisories": []}
        first = json.loads(t.call("submit_review", {"answer": bad}))
        self.assertEqual((first["accepted"], first["submissions_left"]), (False, 1))
        self.assertFalse(t.done)
        last = json.loads(t.call("submit_review", {"answer": bad}))
        self.assertEqual((last["accepted"], last["final"]), (True, True))
        self.assertTrue(last["defects"])
        self.assertEqual((t.done, t.answer), (True, bad))


class ToolSession(unittest.TestCase):
    """`session.run_tools`: every request reserved and recorded on its own, the conversation sent
    back whole, a pause propagated with the earlier usage kept, a failed request relaunched."""
    def setUp(self):
        from harness.agents import openai_runner, session
        from harness.store import budget
        self.session, self.budget, self.oai = session, budget, openai_runner
        self.tmp = tempfile.TemporaryDirectory()
        self.d = Path(self.tmp.name)
        self.saved = (paths.RESULTS, openai_runner.request, dict(budget._BUDGETS))
        paths.RESULTS = self.d
        (self.d / "t").mkdir()
        prices = self.d / "prices.json"
        prices.write_text(json.dumps({"gpt-x": {"input_usd_per_million": 1, "cached_input_usd_per_million": 0.1, "output_usd_per_million": 2}}))
        self.opts = Options(run_id="t", laws=self.d / "laws.jsonl", ontology=ONTO.path, reading=self.d / "reading.json",
                            model="gpt-x", reviewer_max_output_tokens=1000, session_timeout=60, session_retries=1,
                                    retry_wait=0, model_prices=prices, openai_budget_usd=None)
        budget._BUDGETS.clear()
        self.requests = []

    def tearDown(self):
        paths.RESULTS, self.oai.request, b = self.saved
        self.budget._BUDGETS.clear(); self.budget._BUDGETS.update(b)
        self.tmp.cleanup()

    class Tools:
        specs = [{"type": "function", "name": "check_divergence"}, {"type": "function", "name": "submit_review"}]
        max_requests = 5

        def reset(self):
            self.done, self.calls = False, []

        def choice(self):
            return "required"

        def call(self, name, args):
            self.calls.append(name)
            self.done = name == "submit_review"
            return json.dumps({"ok": name})

    def reply(self, name, n):
        return 0, {"output": [{"type": "reasoning", "id": f"rs{n}", "encrypted_content": "e"},
                              {"type": "function_call", "call_id": f"c{n}", "name": name, "arguments": "{}"}],
                   "usage": {"input_tokens": 10, "output_tokens": 5}, "status": "completed"}, False

    def usage(self):
        """The settled rows: one per request that returned."""
        f = self.d / "t" / "usage.jsonl"
        return [r for r in (json.loads(l) for l in f.read_text().splitlines()) if r.get("state") == "settled"] if f.exists() else []

    def test_each_request_is_recorded_and_the_conversation_sent_back(self):
        script = ["check_divergence", "submit_review"]

        def request(items, **kw):
            self.requests.append(json.loads(json.dumps(items)))
            return self.reply(script[len(self.requests) - 1], len(self.requests))
        self.oai.request = request
        tools = self.Tools()
        rec = self.session.run_tools("p", self.d, self.opts, tools, label="review_concept", effort="high", model="gpt-x")
        self.assertEqual((rec["result"], tools.calls), ({"requests": 2, "submitted": True}, script))
        second = self.requests[1]
        self.assertEqual([i.get("type") for i in second[1:]], ["reasoning", "function_call", "function_call_output"])
        self.assertEqual(second[3]["call_id"], "c1")
        self.assertEqual([r["label"] for r in self.usage()], ["review_concept:L1.r1", "review_concept:L1.r2"])

    def test_a_pause_after_earlier_requests_keeps_their_usage(self):
        self.oai.request = lambda items, **kw: self.reply("check_divergence", 1)
        b = self.budget.for_run(self.opts, self.d / "t")
        saved, calls = b.reserve, []

        def reserve(*a):
            calls.append(1)
            if len(calls) == 2:
                raise self.budget.BudgetPaused("over the limit")
            return saved(*a)
        b.reserve = reserve
        with self.assertRaises(self.budget.BudgetPaused):
            self.session.run_tools("p", self.d, self.opts, self.Tools(), label="review_concept", effort="high", model="gpt-x")
        self.assertEqual(len(self.usage()), 1)

    def test_a_failed_request_relaunches_then_the_session_is_unavailable(self):
        self.oai.request = lambda items, **kw: (1, None, False)
        with self.assertRaises(self.session.SessionUnavailable):
            self.session.run_tools("p", self.d, self.opts, self.Tools(), label="review_concept", effort="high", model="gpt-x")
        self.assertEqual(len(self.usage()), 2)                              # one per launch, each recorded

    def test_only_function_tools_are_admitted(self):
        with self.assertRaises(ValueError):
            self.saved[1]([], model="gpt-x", tools=[{"type": "web_search"}], tool_choice="auto", effort=None, timeout_seconds=1)


class AtomParameters(unittest.TestCase):
    """The catalogue shows the parameters Core requires of an atom, and the extent's contract states
    what a formula reads."""
    def test_rows(self):
        from harness.lean import surface
        rows = {r["name"]: r for r in surface.case_catalogue(ONTO)}
        for name in ("rel_same_direction", "rel_oncoming"):
            self.assertIn("params [cosine tolerance: 1 (no unit)]", " ".join(rows[name]["signatures"]))
        self.assertNotIn("params [", " ".join(rows["kin_speed"]["signatures"]))
        self.assertIn("a formula reads the full length", rows["kin_extent"]["contract"])


class ConceptHarnessFailure(unittest.TestCase):
    """A concept review whose program does not run defers at `certificate`, never decides."""
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.d = Path(self.tmp.name)
        self.run = FakeRun(self.d)

    def tearDown(self):
        self.tmp.cleanup()

    def test_a_concept_harness_failure_defers_at_certificate(self):
        from harness.lean import render_formula
        from harness.model.blueprint import ConceptRecord
        self.run.opts.ontology = paths.REPO / "ontology" / "ATOMS_train.md"
        self.run.all_concepts = lambda: {}
        rec = ConceptRecord({"concept_id": "drv.test.c", "contract": "c holds", "kind": "formula", "args": [{"name": "u", "sort": "track"}],
                             "params": [], "elements": []})
        saved = (render_formula.render_concept, review.session.run_tools, review.execute_concept_divergences)
        render_formula.render_concept = lambda *_a, **_kw: "the rendering"

        def broken(*_a, **_kw):
            raise review.HarnessFailure("the concept review harness did not run")
        review.execute_concept_divergences = broken
        good = {"kind": "holds_wrongly", "contract_verdict": "fails", "contract_words": "c holds", "situation": "s",
                "instance": {"literals": {}, "params": {}}, "grounding": {"u": 1}, "trace": {"scenes": [{"t": 0}]}, "at": 0}
        review.session.run_tools = scripted_reviewer([submit({"verdict": "return", "divergences": [good], "not_general": [], "advisories": []})])
        try:
            out = review.review_concept(self.run, rec, {"reads": [], "body_json": {}}, self.d)
        finally:
            render_formula.render_concept, review.session.run_tools, review.execute_concept_divergences = saved
        self.assertEqual((out.status, out.defer_stage), ("deferred", "certificate"))


class SessionRecords(ToolSession):
    """The usage rows of a tool session name the subject and the launch; a refused request keeps
    its reason; a quantity skeleton's closing brace is never commented out."""
    test_each_request_is_recorded_and_the_conversation_sent_back = None
    test_a_pause_after_earlier_requests_keeps_their_usage = None
    test_a_failed_request_relaunches_then_the_session_is_unavailable = None
    test_only_function_tools_are_admitted = None

    def test_labels_and_reasons(self):
        self.oai.request = lambda items, **kw: (1, {"error": "APIError: overloaded"}, False)
        with self.assertRaises(self.session.SessionUnavailable) as e:
            self.session.run_tools("p", self.d, self.opts, self.Tools(), label="review_concept", effort="high", model="gpt-x",
                                   subject="L_1_o1")
        self.assertIn("overloaded", str(e.exception))
        self.assertEqual([r["label"] for r in self.usage()], ["review_concept:L_1_o1:L1.r1", "review_concept:L_1_o1:L2.r1"])
        stream = (self.d / "review_concept.jsonl").read_text()
        self.assertIn('"type": "error"', stream)

    def test_a_key_is_masked(self):
        self.assertNotIn("abcdef123456", self.oai.sanitized(RuntimeError("bad key sk-abcdef123456 given")))

    def test_quantity_skeleton_brace(self):
        from harness.lean import skeleton
        from harness.model.blueprint import ConceptRecord
        rec = ConceptRecord({"concept_id": "drv.motion.test_quantity", "contract": "q", "kind": "quantity", "args": [{"name": "u", "sort": "track"}],
                             "params": [], "elements": []})
        lines = skeleton.concept_witness_skeleton(rec).splitlines()
        i = next(i for i, l in enumerate(lines) if "bounds :=" in l)
        self.assertEqual(lines[i + 1].strip(), "}")


class UnitTables(unittest.TestCase):
    """The pipeline's units are Core's: every spelling decodes in Lean to exactly the unit and factor
    the harness reads from Core, every unit's exported tag decodes back to it, and every unit's
    skeleton literal elaborates."""
    def test_the_harness_reads_what_lean_decodes(self):
        import shutil, subprocess
        from harness.model import units
        from harness.store import paths
        if not shutil.which("lake"):
            self.skipTest("the Lean toolchain is not installed")
        lines = ["import TrafficSpec", "open TrafficSpec Lean"]
        for spelling, (core, k) in sorted(units.FACTORS.items()):
            lines.append(f'#guard ((Decode.unit "u" (Json.str {json.dumps(spelling)})).toOption.map fun (u, q) => '
                         f"decide (u = {units.lean_unit(core)}) && Q.eq q (Q.mk' {k.numerator} {k.denominator})) == some true")
        for core in units.CORE_UNITS:
            lines.append(f"example : TrafficSpec.Term := .lit (Q.ofInt 0) {units.lean_unit(core)}")
            lines.append(f'#guard (Decode.literalUnit "u" (Json.str {json.dumps(units.json_tag(core))})).toOption == some {units.lean_unit(core)}')
        with tempfile.TemporaryDirectory() as t:
            f = Path(t) / "units_drift.lean"
            f.write_text("\n".join(lines) + "\n")
            out = subprocess.run(["lake", "env", "lean", str(f)], cwd=paths.LIBRARY, capture_output=True, text=True, timeout=600)
        self.assertEqual(out.returncode, 0, out.stdout[-2000:] + out.stderr[-2000:])
        self.assertEqual(sorted(units.DIMS), sorted(units.CORE_UNITS))

    def test_a_concept_with_a_per_metre_formal_gets_a_skeleton(self):
        from harness.lean import skeleton
        from harness.model.blueprint import ConceptRecord
        rec = ConceptRecord({"concept_id": "drv.road.test_curve", "contract": "c", "kind": "formula", "args": [{"name": "u", "sort": "track"}],
                             "params": [{"name": "tol", "unit": "1/m"}], "elements": []})
        self.assertIn(".perMetre", skeleton.concept_skeleton(rec))
        self.assertIn(".lit (Q.ofInt 0) .perMetre", skeleton.concept_witness_skeleton(rec))


class FieldTypes(unittest.TestCase):
    """Every record field the code generator writes into Lean is type-checked by the
    validator, so a planner's wrong type is returned with a message instead of stopping the run."""
    NODE = {"node_id": "L_1_o1", "law_refs": ["L-1"], "subject": {"binder": "v", "class_elements": ["ru.motor_vehicle"]},
            "binders": [{"name": "v", "class_elements": ["ru.motor_vehicle"]}],
            "segmentation": [{"id": "s1", "role": "obligation", "text": "shall stop before the line"}],
            "elements": [{"span": "s1", "atoms": ["kin.speed"], "derived": [], "justification": "j"}],
            "operationalizations": [{"span": "s1", "standard": "safe", "concepts": [], "params": ["p.x"], "convention": "c", "surrogate": False}],
            "assumptions": [{"span": "s1", "id": "asm.a", "meaning": "m"}], "residues": [{"span": "s1", "why": "w", "scope": "none"}],
            "compositions": [], "narrowings": [], "params": ["p.x"], "applicability": "a", "obligation": "o",
            "scenarios": [{"name": "forbid", "expected": "violated", "narrative": "n"}]}
    CONCEPT = {"concept_id": "drv.motion.test_concept", "contract": "c holds", "kind": "formula", "definition": "d",
               "args": [{"name": "u", "sort": "track"}, {"name": "k", "sort": "literal", "values": ["left", "right"]}],
               "params": [{"name": "tol", "unit": "1/m"}], "elements": [], "residues": [], "literals": [],
               "scenarios": [{"name": "holds", "expected": "compliant", "narrative": "n"}]}

    @staticmethod
    def leaves(x, path=()):
        if isinstance(x, dict):
            for k, v in x.items():
                yield from FieldTypes.leaves(v, path + (k,))
        elif isinstance(x, list):
            if x and all(isinstance(y, str) for y in x):
                yield path
            for i, v in enumerate(x):
                yield from FieldTypes.leaves(v, path + (i,))
        elif isinstance(x, str):
            yield path

    @staticmethod
    def mutate(rec, path):
        import copy
        r = copy.deepcopy(rec); o = r
        for k in path[:-1]:
            o = o[k]
        o[path[-1]] = {"x": 1}
        return r

    def test_the_class_elements_case_is_returned_with_its_path(self):
        from harness.checks import validate_a
        bad = self.mutate(self.NODE, ("binders", 0, "class_elements", 0))
        errs = validate_a.schema_errors("L_1_o1", bad, validate_a.NODE_SCHEMA)
        self.assertEqual(errs, ["L_1_o1: `binders[0].class_elements[0]` must be a string, not dict"])
        import copy
        self.assertEqual(validate_a.schema_errors("L_1_o1", copy.deepcopy(self.NODE), validate_a.NODE_SCHEMA), [])

    def test_no_unchecked_field_can_stop_the_rule_generator(self):
        from harness.checks import validate_a
        from harness.lean import skeleton
        for path in set(self.leaves(self.NODE)):
            if path[0] == "node_id":
                continue                                                     # the identity, checked when the id is derived
            bad = self.mutate(self.NODE, path)
            if validate_a.schema_errors("L_1_o1", bad, validate_a.NODE_SCHEMA):
                continue
            try:
                skeleton.rule_skeleton(Node(bad)); skeleton.witness_skeleton(Node(bad))
            except (TypeError, AttributeError, KeyError) as e:
                self.fail(f"{path}: an unchecked field stops the generator: {e!r}")

    def test_no_unchecked_field_can_stop_the_concept_generator(self):
        from harness.checks import validate_a
        from harness.lean import skeleton
        from harness.model.blueprint import ConceptRecord
        for path in set(self.leaves(self.CONCEPT)):
            if path[0] in ("concept_id", "kind"):
                continue                                                     # the identity and the kind, checked before
            bad = self.mutate(self.CONCEPT, path)
            if validate_a.schema_errors("c", bad, validate_a.CONCEPT_SCHEMA):
                continue
            try:
                skeleton.concept_skeleton(ConceptRecord(bad)); skeleton.concept_witness_skeleton(ConceptRecord(bad))
            except (TypeError, AttributeError, KeyError) as e:
                self.fail(f"{path}: an unchecked field stops the generator: {e!r}")

if __name__ == "__main__":
    unittest.main()
