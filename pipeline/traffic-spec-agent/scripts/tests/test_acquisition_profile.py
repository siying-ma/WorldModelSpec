"""One reviewed step parameter per acquisition profile for `heading_since`. The operator's profiles file
names, per profile, the reading parameter that bounds the term's integration step; a run names its
profile. The node gate holds every step bound of a rule, its concept calls expanded, to exactly that
parameter, reviewed in the reading; a concept takes it through a formal parameter; validation refuses
any proposal of a parameter a profile names, on the plan path and on a label repair's candidate; the
loop does not start under a profile that does not resolve to a reviewed value; and the run's semantic
inputs carry the profile. The real-gate tests run on real Lean and are skipped, and so not verified,
where the toolchain or the built Core is absent."""
import copy
import json
import tempfile
import unittest
from pathlib import Path
from unittest import mock

from harness.checks import gate, validate_a
from harness.model import acquisition, nodeid
from harness.model.blueprint import ConceptRecord, Node
from harness.model.reading import Reading
from harness.store import paths
from scripts.tests import test_gate_phases as G
from scripts.tests import test_precondition_continuity as P

PROFILE = "carla_scene_graph"
STEP = "p.heading_since_step_carla_scene_graph"
REVIEWED = {"name": STEP, "value": 0.2, "unit": "s", "convention": "operator-reviewed sampling standard of the profile"}
LIT_STEP = {"lit": {"num": "1", "den": "1"}, "unit": "second"}
ONSET = {"cmp": "gt", "lhs": {"measure": "kin_speed", "args": [{"var": "v"}]}, "rhs": {"lit": {"num": "0", "den": "1"}, "unit": "metre_per_second"}}


def rule_json(step) -> dict:
    """A rule's obligation comparing the heading change since an onset with zero, its step bound `step`."""
    return {"obligation": {"cmp": "ge", "lhs": {"abs": {"heading_since": "v", "max_step": step, "onset": ONSET}},
                           "rhs": {"lit": {"num": "0", "den": "1"}, "unit": "degree"}}}


def reading_of(*params: dict):
    return type("R", (), {"data": {"params": list(params), "aggregates": []}})()


def profiles_file(t: str, data) -> Path:
    f = Path(t) / "acquisition_profiles.json"
    f.write_text(json.dumps(data) if not isinstance(data, str) else data)
    return f


class Profiles(unittest.TestCase):
    """The operator's file, resolved and refused by name."""

    def test_the_shipped_profile_names_its_parameter(self):
        self.assertEqual(acquisition.step_parameter(PROFILE), STEP)
        self.assertEqual(acquisition.reserved_parameters(), {STEP: [PROFILE]})

    def test_a_missing_file_is_a_clear_refusal(self):
        with tempfile.TemporaryDirectory() as t:
            with self.assertRaisesRegex(acquisition.ProfileError, "acquisition profiles file .* does not exist"):
                acquisition.step_parameter(PROFILE, Path(t) / "absent.json")
            self.assertEqual(acquisition.reserved_parameters(Path(t) / "absent.json"), {})

    def test_an_unknown_profile_is_refused_naming_the_known_ones(self):
        with self.assertRaisesRegex(acquisition.ProfileError, rf"acquisition profile `lidar_10hz` is not in .*\(profiles: {PROFILE}\)"):
            acquisition.step_parameter("lidar_10hz")

    def test_no_profile_is_refused(self):
        with self.assertRaisesRegex(acquisition.ProfileError, "the run names no acquisition profile"):
            acquisition.step_parameter(None)

    def test_malformed_entries_are_refused(self):
        with tempfile.TemporaryDirectory() as t:
            for data, why in (({"profiles": {}}, "`profiles` is not a non-empty object"),
                              ({"profiles": {"a": {"covers": "x", "heading_since_step": "step"}}}, "not a reading parameter"),
                              ({"profiles": {"a": {"heading_since_step": "p.s"}}}, "states no `covers`"),
                              ({"profiles": {"A b": {"covers": "x", "heading_since_step": "p.s"}}}, "not lower snake case"),
                              ("{not json", "cannot be read")):
                with self.assertRaisesRegex(acquisition.ProfileError, why):
                    acquisition.step_parameter("a", profiles_file(t, data))

    def test_review_defects(self):
        self.assertEqual(acquisition.review_defects(STEP, {"params": [REVIEWED]}), [])
        self.assertEqual(acquisition.review_defects(STEP, {"params": []}), [f"the reading has no `{STEP}`: the operator enters its reviewed value"])
        self.assertRegex(acquisition.review_defects(STEP, {"params": [{**REVIEWED, "proposed": "r/iter-001 N"}]})[0], "only as a proposal")
        self.assertRegex(acquisition.review_defects(STEP, {"params": [{**REVIEWED, "unit": "m"}]})[0], "not a unit of time")
        for v in (0, -0.2, 0.0, None, "0.2", True, float("nan")):
            self.assertEqual(acquisition.review_defects(STEP, {"params": [{**REVIEWED, "value": v}]}),
                             [f"the reading gives `{STEP}` the value {v!r}: a step bound is a positive time"], v)

    def test_sessions_are_shown_the_standard(self):
        self.assertIn(f'Every `headingSince` step bound in a rule is exactly `.param "{STEP}"`', acquisition.standard_note(PROFILE))
        self.assertIn("no rule of this run may read `headingSince`", acquisition.standard_note(None))
        code_md = (paths.REPO / "prompts" / "code.md").read_text(encoding="utf-8")
        self.assertIn("a rule\n   uses exactly the reviewed step parameter named by the run's acquisition profile", code_md)
        self.assertNotIn(PROFILE, code_md)
        concept_md = (paths.REPO / "prompts" / "code_concept.md").read_text(encoding="utf-8")
        self.assertIn("For `headingSince`, use a declared time formal directly as the step bound", concept_md)
        self.assertNotIn(PROFILE, concept_md)
        self.assertNotIn(STEP, concept_md)

    def test_the_semantic_inputs_carry_the_profile_and_its_parameter(self):
        from harness.loop import semantic_inputs
        from harness.store.state import Options
        from scripts.tests.test_review_routing import ONTO
        with tempfile.TemporaryDirectory() as t:
            reading = Path(t) / "reading.json"
            reading.write_text(json.dumps({"params": [REVIEWED], "aggregates": []}))
            opts = lambda profile: Options(run_id="r", laws=Path(t) / "laws.jsonl", ontology=ONTO.path, reading=reading, model="m",
                                           acquisition_profile=profile)
            self.assertNotIn("acquisition", semantic_inputs(opts(None)))      # a run without a profile reads no `heading_since`
            named = semantic_inputs(opts(PROFILE))["acquisition"]
            self.assertNotEqual(semantic_inputs(opts("lidar_10hz"))["acquisition"], named)
            other = profiles_file(t, {"profiles": {PROFILE: {"covers": "x", "heading_since_step": "p.other_step"}}})
            with mock.patch.object(acquisition, "PROFILES", other):
                self.assertNotEqual(semantic_inputs(opts(PROFILE))["acquisition"], named)


class StepRule(unittest.TestCase):
    """The gate's rule on the exported rule and concept body."""

    def test_the_profile_parameter_passes(self):
        self.assertEqual(gate.rule_step_defects("N", rule_json({"param": STEP}), PROFILE, reading_of(REVIEWED)), [])

    def test_an_alias_is_refused(self):
        out = gate.rule_step_defects("N", rule_json({"param": "p.my_step"}), PROFILE, reading_of(REVIEWED))
        self.assertEqual(len(out), 1)
        self.assertIn('a `heading_since` step bound is {"param": "p.my_step"}; under the run\'s acquisition profile '
                      f'`{PROFILE}` it is the operator-reviewed parameter `{STEP}`', out[0])

    def test_a_literal_and_an_expression_are_refused(self):
        for step in (LIT_STEP, {"mul": [{"lit": {"num": "2", "den": "1"}, "unit": "ratio"}, {"param": STEP}]}):
            out = gate.rule_step_defects("N", rule_json(step), PROFILE, reading_of(REVIEWED))
            self.assertEqual(len(out), 1, out)
            self.assertIn("no literal, no other parameter, no expression", out[0])

    def test_a_missing_mapping_is_a_clear_refusal(self):
        self.assertEqual(gate.rule_step_defects("N", rule_json({"param": STEP}), None, reading_of(REVIEWED)),
                         ["N: the rule reads `heading_since`, and the run names no acquisition profile (`--acquisition_profile`), so no "
                          "reviewed parameter bounds the step of `heading_since`; until the operator names a profile with a reviewed "
                          "parameter, no rule of this run may read `heading_since`"])
        out = gate.rule_step_defects("N", rule_json({"param": STEP}), "lidar_10hz", reading_of(REVIEWED))
        self.assertRegex(out[0], "acquisition profile `lidar_10hz` is not in")
        with tempfile.TemporaryDirectory() as t, mock.patch.object(acquisition, "PROFILES", Path(t) / "absent.json"):
            self.assertRegex(gate.rule_step_defects("N", rule_json({"param": STEP}), PROFILE, reading_of(REVIEWED))[0], "does not exist")

    def test_an_unreviewed_parameter_is_refused(self):
        out = gate.rule_step_defects("N", rule_json({"param": STEP}), PROFILE, reading_of({**REVIEWED, "proposed": "r/iter-001 N"}))
        self.assertEqual(out, [f"N: the reading holds `{STEP}` only as a proposal (r/iter-001 N): the operator reviews its value"])
        self.assertEqual(gate.rule_step_defects("N", rule_json({"param": STEP}), PROFILE, reading_of()),
                         [f"N: the reading has no `{STEP}`: the operator enters its reviewed value"])

    def test_a_zero_or_negative_reviewed_step_is_refused(self):
        for v in (0, -0.2):
            self.assertEqual(gate.rule_step_defects("N", rule_json({"param": STEP}), PROFILE, reading_of({**REVIEWED, "value": v})),
                             [f"N: the reading gives `{STEP}` the value {v!r}: a step bound is a positive time"])

    def test_no_nesting_hides_a_step_bound(self):
        rule = rule_json({"param": "p.my_step"})
        for _ in range(5000):
            rule = {"not": rule}
        out = gate.rule_step_defects("N", rule, PROFILE, reading_of(REVIEWED))
        self.assertEqual(len(out), 1, out)
        self.assertIn('step bound is {"param": "p.my_step"}', out[0])
        body = rule_json(LIT_STEP)
        for _ in range(5000):
            body = {"not": body}
        self.assertEqual(len(gate.concept_step_defects("drv.x.y", body, ["tol", "step"])), 1)

    def test_a_formula_too_deep_to_read_is_refused(self):
        n = 100000                                     # past what Python's JSON parser reads
        text = '{"not":' * n + json.dumps(rule_json({"param": STEP})) + "}" * n
        self.assertEqual(gate.deep_checks(lambda: gate.rule_step_defects("N", json.loads(text), PROFILE, reading_of(REVIEWED))),
                         [gate.TOO_DEEP])
        self.assertEqual(gate.deep_checks(lambda: []), [])

    def test_a_rule_without_the_term_needs_no_profile(self):
        self.assertEqual(gate.rule_step_defects("N", {"obligation": ONSET}, None, reading_of()), [])

    def test_a_concept_takes_its_step_through_a_formal(self):
        self.assertEqual(gate.concept_step_defects("drv.x.y", rule_json({"param": "step"}), ["tol", "step"]), [])
        out = gate.concept_step_defects("drv.x.y", rule_json(LIT_STEP), ["tol", "step"])
        self.assertEqual(len(out), 1)
        self.assertIn("a shared concept takes it from its caller as one of its formal parameters (`tol`, `step`)", out[0])


def proposing_node(*proposals: dict, params=(STEP,)) -> Node:
    rec = copy.deepcopy(P.RECORD)
    rec["params"] = rec["params"] + list(params)
    rec["param_proposals"] = list(proposals)
    return Node(rec)


class Proposals(unittest.TestCase):
    """No plan or repair proposes a parameter a profile names, nor a value for it."""

    def check(self, node: Node, *params: dict) -> list[str]:
        with tempfile.TemporaryDirectory() as t:
            f = Path(t) / "reading.json"
            f.write_text(json.dumps({"params": [{"name": "p.halt_window", "value": 3, "unit": "s", "convention": "c"},
                                                {"name": "p.crawl", "value": 3, "unit": "m/s", "convention": "c"}] + list(params),
                                     "aggregates": []}))
            errs, proposals = validate_a.check_standards(node, Reading(f))
        self.assertEqual(proposals, [])
        return errs

    def test_proposing_the_parameter_is_refused(self):
        errs = self.check(proposing_node({"name": STEP, "value": 0.1, "unit": "s", "convention": "c", "source": "s"}))
        self.assertIn(f"{P.NODE_ID}: `{STEP}` is the `heading_since` step parameter of acquisition profile(s) {PROFILE}: the operator "
                      "enters and reviews its value; no plan or repair proposes it or a value for it — name it as it is", errs)

    def test_changing_its_reviewed_value_is_refused(self):
        errs = self.check(proposing_node({"name": STEP, "value": 0.5, "unit": "s", "convention": "c", "source": "s"}), REVIEWED)
        self.assertTrue(any(f"`{STEP}` is the `heading_since` step parameter" in e for e in errs), errs)

    def test_naming_it_unentered_says_whose_it_is(self):
        self.assertIn(f"{P.NODE_ID}: `{STEP}` is the `heading_since` step parameter of acquisition profile(s) {PROFILE} and the reading "
                      "lacks it: the operator enters its reviewed value", self.check(proposing_node()))

    def test_naming_it_reviewed_is_fine(self):
        self.assertFalse([e for e in self.check(proposing_node(), REVIEWED) if STEP in e])


class LabelRepairCandidate(unittest.TestCase):
    """A label repair's change set is validated in its candidate by the plan validator: a node record
    proposing the profile's parameter, or another value for it, fails validation and cannot commit."""

    def setUp(self):
        from harness.phases import candidate as cand
        cand._OPEN.clear()
        self.addCleanup(cand._OPEN.clear)

    def attempt(self, proposal: dict, reading: dict):
        from harness.phases import candidate as cand
        from scripts.tests import test_candidate as C
        concepts, nodes = C.standard()
        # the region-kind table is exported by Lean from a built library, which this small world lacks;
        # no record here claims a region atom
        with C.world(concepts, nodes, reading=reading) as (run, _lib), \
                mock.patch("harness.lean.surface.region_argument_kinds", lambda onto: {}):
            before = (run.reading_file.read_text(), Path(run.opts.reading).read_text())
            new_n = C.node_rec(C.NN, [C.CB], params=[STEP], param_proposals=[proposal], applicability="a", obligation="o",
                               scenarios=[{"name": "forbid", "expected": "violated"}, {"name": "permit", "expected": "compliant"}])
            with C.Txn(run, validator=cand.validate_records) as txn:
                txn.apply([cand.Change("node", C.NN, new_n, C.files("node", C.NN, "v2"))])
                results = txn.verify()
                with self.assertRaises(cand.CommitRefused):
                    txn.commit()
            self.assertEqual((run.reading_file.read_text(), Path(run.opts.reading).read_text()), before)
            return next(r for r in results if r.check == "validate" and r.subject == C.NN)

    def test_a_repair_proposing_the_parameter_is_refused(self):
        r = self.attempt({"name": STEP, "value": 0.1, "unit": "s", "convention": "c", "source": "s"}, {"params": [], "aggregates": []})
        self.assertEqual(r.status, "fail")
        self.assertTrue(any(f"`{STEP}` is the `heading_since` step parameter" in d for d in r.details), r.details)

    def test_a_repair_changing_its_value_is_refused(self):
        r = self.attempt({"name": STEP, "value": 0.5, "unit": "s", "convention": "c", "source": "s"}, {"params": [REVIEWED], "aggregates": []})
        self.assertEqual(r.status, "fail")
        self.assertTrue(any(f"`{STEP}` is the `heading_since` step parameter" in d for d in r.details), r.details)


class LoopStart(unittest.TestCase):
    """A run that names a profile starts only when it resolves to a reviewed value in the base reading."""

    def start(self, profile: str, reading: dict) -> str:
        from harness import loop
        from harness.store.state import Options
        from scripts.tests.test_review_routing import ONTO
        with tempfile.TemporaryDirectory() as t:
            base = Path(t) / "reading.json"
            base.write_text(json.dumps(reading))
            (Path(t) / "laws.jsonl").write_text("")
            (Path(t) / "definitions.jsonl").write_text("")
            opts = Options(run_id="acq_start", laws=Path(t) / "laws.jsonl", ontology=ONTO.path, reading=base, model="m",
                           acquisition_profile=profile, dry_run=True)      # no reviewer or verifier named: their checks pass
            layout = {**paths.library_layout(paths.LIBRARY), "RESULTS": Path(t) / "results"}
            with mock.patch.multiple(paths, **layout), mock.patch("harness.store.owner.acquire", lambda *a, **k: None), \
                    mock.patch("harness.tools.handoff.check_on_launch", lambda run: None), \
                    mock.patch("harness.phases.candidate.recover", lambda run: None), \
                    mock.patch.object(loop, "gap_gate", lambda run, opts: None), \
                    mock.patch.object(loop, "doctor_ok", lambda: (_ for _ in ()).throw(AssertionError("started"))):
                try:
                    loop._run_loop(opts)
                except SystemExit as e:
                    return str(e)
                except AssertionError as e:
                    return str(e)
        return "returned"

    def test_an_unknown_profile_stops_the_launch(self):
        self.assertRegex(self.start("lidar_10hz", {"params": [REVIEWED], "aggregates": []}),
                         r"^\[loop\] acquisition profile `lidar_10hz` is not in")

    def test_an_unreviewed_parameter_stops_the_launch(self):
        self.assertEqual(self.start(PROFILE, {"params": [{**REVIEWED, "proposed": "x/iter-001 N"}], "aggregates": []}),
                         f"[loop] acquisition profile `{PROFILE}`: the reading holds `{STEP}` only as a proposal (x/iter-001 N): "
                         "the operator reviews its value")
        self.assertEqual(self.start(PROFILE, {"params": [], "aggregates": []}),
                         f"[loop] acquisition profile `{PROFILE}`: the reading has no `{STEP}`: the operator enters its reviewed value")

    def test_a_zero_or_negative_step_stops_the_launch(self):
        for v in (0, -0.2):
            self.assertEqual(self.start(PROFILE, {"params": [{**REVIEWED, "value": v}], "aggregates": []}),
                             f"[loop] acquisition profile `{PROFILE}`: the reading gives `{STEP}` the value {v!r}: a step bound is a positive time")

    def test_a_reviewed_parameter_lets_the_launch_go_on(self):
        self.assertEqual(self.start(PROFILE, {"params": [REVIEWED], "aggregates": []}), "started")
        self.assertEqual(self.start(None, {"params": [], "aggregates": []}), "started")


# --- real gate ---------------------------------------------------------------------------------
GUARD = '.cmp (.measure "kin_speed" [vV]) .gt (.lit Q.zero .metrePerSecond)'


def heading_rule(step: str) -> str:
    """The fixture node whose obligation reads the heading change since the subject moved, with step
    bound `step`, in a `cond` guard whose branches agree (the fixture's verdicts, whatever the angle)."""
    return P.RULE.replace('def obligation : Formula := .cmp (.measure "kin_speed" [vV]) .le (.param "p.crawl")',
                          f'def obligation : Formula := .cmp (.cond (.cmp (.abs (.headingSince "v" ({step}) ({GUARD}))) .ge '
                          '(.lit Q.zero .degree)) (.measure "kin_speed" [vV]) (.measure "kin_speed" [vV])) .le (.param "p.crawl")')


def nested_not(name: str, formula: str, n: int = 402) -> tuple[str, str]:
    """Definitions building `formula` under `n` negations (an even count keeps its truth value), one
    definition per negation as Lean elaborates no such depth written out, and the name of the last."""
    defs = [f"def {name}_0 : Formula := {formula}"] + [f"def {name}_{i + 1} : Formula := .not {name}_{i}" for i in range(n)]
    return "\n".join(defs) + "\n\n", f"{name}_{n}"


def deep_heading_rule(step: str) -> str:
    """`heading_rule(step)` with its obligation nested under 402 negations."""
    src = heading_rule(step)
    head = "def obligation : Formula := "
    i = src.index(head)
    j = src.index("\n", i)
    defs, last = nested_not("deepObligation", src[i + len(head):j])
    return src[:i] + defs + head + last + src[j:]


def claims_yaw(*literals: dict):
    def edit(rec: dict) -> None:
        e = next(e for e in rec["elements"] if e["span"] == "o1")
        e["atoms"] = list(e["atoms"]) + ["kin.yaw_rate"]
        rec["params"] = rec["params"] + [STEP]
        rec["literals"] = list(rec.get("literals", [])) + list(literals)
    return edit


HS_CID = G.CID
HS_BODY = ('.cmp (.cond (.cmp (.abs (.headingSince "u" (STEP) (.cmp (.measure "kin_speed" [aU]) .gt (.lit Q.zero .metrePerSecond)))) .ge '
           '(.lit Q.zero .degree)) (.measure "kin_speed" [aU]) (.measure "kin_speed" [aU])) .le (.param "tol")')


def heading_concept(step: str, deep: bool = False) -> str:
    """The neutral concept with a formal parameter `step` (a time) and a heading change in its guard
    (nested under 402 negations when `deep`)."""
    body = HS_BODY.replace("STEP", step)
    src = G.concept_source("deepBody_402" if deep else body).replace('params := [⟨"tol", .metrePerSecond⟩]',
                                                                     'params := [⟨"tol", .metrePerSecond⟩, ⟨"step", .second⟩]')
    if not deep:
        return src
    defs, _last = nested_not("deepBody", body)
    i = src.index("def body : Formula := ")
    return src[:i] + defs + src[i:]


def concept_gate(step: str, literals: list | None = None, deep: bool = False) -> gate.Verdict:
    with tempfile.TemporaryDirectory() as t:
        lib, work, dirs = G._library(t)
        files = [nodeid.concept_path(HS_CID), nodeid.concept_witness_path(HS_CID)]
        witness = G.CONCEPT_WITNESS.replace("SCENARIOS", "\n  , ".join((G.HOLDS, G.FAILS, G.BLIND))).replace(
            'params := [("tol", .lit (Units.micrometresPerSecond 200000) .metrePerSecond)]',
            'params := [("tol", .lit (Units.micrometresPerSecond 200000) .metrePerSecond), ("step", .lit (Units.seconds 1) .second)]')
        for rel, src in zip(files, (heading_concept(step, deep), witness)):
            (lib / rel).parent.mkdir(parents=True, exist_ok=True)
            (lib / rel).write_text(src, encoding="utf-8")
        (Path(t) / "reading.json").write_text(json.dumps({"params": [], "aggregates": []}))
        record = copy.deepcopy(G.CONCEPT_RECORD)
        record["params"] = record["params"] + [{"name": "step", "unit": "s"}]
        record["elements"][0]["atoms"] += ["kin.yaw_rate"]
        record["literals"] = list(literals or [])
        ran = G.Ran(files, {f"import {nodeid.concept_module(HS_CID)}", f"import {nodeid.concept_witness_module(HS_CID)}"})
        with mock.patch.multiple(paths, **dirs), mock.patch.object(gate, "repo_digest", lambda *a, **k: {}), \
                mock.patch.object(gate, "_toolchain", ran):
            return gate.run_concept_gate(ConceptRecord(record), Reading(Path(t) / "reading.json"), {}, work, 0, 5, accepted={})


CALL_RULE = P.RULE.replace('def obligation : Formula := .cmp (.measure "kin_speed" [vV]) .le (.param "p.crawl")',
                           'def obligation : Formula := .derived "drv_motion_gate_rest_test" [vV] [.param "p.crawl", STEP]')
CALL_ACCEPTED = {HS_CID: {"reads": ["kin.speed", "kin.yaw_rate"], "params": [{"name": "tol", "unit": "m/s"}, {"name": "step", "unit": "s"}]}}


def calls_heading_concept(rec: dict) -> None:
    e = next(e for e in rec["elements"] if e["span"] == "o1")
    e["derived"] = [HS_CID]
    rec["params"] = rec["params"] + [STEP]


ONE_SECOND = {"span": "o1", "value": 1, "unit": "s", "text": "one second"}


@unittest.skipUnless(P.TOOLCHAIN, P.SKIP)
class RealGate(unittest.TestCase):

    def test_the_profile_parameter_passes(self):
        v, _out, _ph = G.node_gate(rule=heading_rule(f'.param "{STEP}"'), edit=claims_yaw(), params=[REVIEWED], acquisition=PROFILE)
        self.assertEqual(v.verdict, "OK", v.details)

    def test_an_alias_is_refused(self):
        alias = {**REVIEWED, "name": "p.my_step"}
        v, out, _ph = G.node_gate(rule=heading_rule('.param "p.my_step"'), edit=claims_yaw(), params=[REVIEWED, alias], acquisition=PROFILE)
        self.assertIn("\nRULEXJSON\t", out)
        self.assertEqual(v.verdict, "CHECK_FAIL", v.details)
        self.assertIn(f'{P.NODE_ID}: a `heading_since` step bound is {{"param": "p.my_step"}}; under the run\'s acquisition profile '
                      f'`{PROFILE}` it is the operator-reviewed parameter `{STEP}`, written `.param "{STEP}"` in the rule or passed to the '
                      'step formal of the concept that reads it: no literal, no other parameter, no expression', v.details)

    def test_a_literal_declared_as_a_figure_is_refused(self):
        v, _out, _ph = G.node_gate(rule=heading_rule(".lit (Units.seconds 1) .second"), edit=claims_yaw(ONE_SECOND), params=[REVIEWED],
                                   acquisition=PROFILE)
        self.assertEqual(v.verdict, "CHECK_FAIL", v.details)
        self.assertTrue(any("a `heading_since` step bound is {\"lit\"" in d for d in v.details), v.details)

    def test_a_run_without_a_profile_may_not_read_the_term(self):
        v, _out, _ph = G.node_gate(rule=heading_rule(f'.param "{STEP}"'), edit=claims_yaw(), params=[REVIEWED])
        self.assertEqual(v.verdict, "CHECK_FAIL", v.details)
        self.assertTrue(any("the run names no acquisition profile" in d for d in v.details), v.details)

    def test_an_unreviewed_parameter_is_refused(self):
        v, _out, _ph = G.node_gate(rule=heading_rule(f'.param "{STEP}"'), edit=claims_yaw(),
                                   params=[{**REVIEWED, "proposed": "r/iter-001 N"}], acquisition=PROFILE)
        self.assertEqual(v.verdict, "CHECK_FAIL", v.details)
        self.assertIn(f"{P.NODE_ID}: the reading holds `{STEP}` only as a proposal (r/iter-001 N): the operator reviews its value", v.details)

    def test_an_alias_under_deep_nesting_is_refused(self):
        alias = {**REVIEWED, "name": "p.my_step"}
        v, _out, _ph = G.node_gate(rule=deep_heading_rule('.param "p.my_step"'), edit=claims_yaw(), params=[REVIEWED, alias],
                                   acquisition=PROFILE)
        self.assertEqual(v.verdict, "CHECK_FAIL", v.details)
        self.assertTrue(any('step bound is {"param": "p.my_step"}' in d for d in v.details), v.details)

    def test_a_zero_reviewed_step_is_refused(self):
        v, _out, _ph = G.node_gate(rule=heading_rule(f'.param "{STEP}"'), edit=claims_yaw(), params=[{**REVIEWED, "value": 0}],
                                   acquisition=PROFILE)
        self.assertEqual(v.verdict, "CHECK_FAIL", v.details)
        self.assertIn(f"{P.NODE_ID}: the reading gives `{STEP}` the value 0: a step bound is a positive time", v.details)

    def test_a_concept_with_a_literal_step_under_deep_nesting_is_refused(self):
        v = concept_gate(".lit (Units.seconds 1) .second", [{"span": "measured speed", "value": 1, "unit": "s"}], deep=True)
        self.assertEqual(v.verdict, "CHECK_FAIL", v.details)
        self.assertTrue(any("a shared concept takes it from its caller as one of its formal parameters (`tol`, `step`)" in d
                            for d in v.details), v.details)

    def test_the_parameter_passed_to_a_concepts_formal_passes(self):
        v, out, _ph = G.node_gate(rule=CALL_RULE.replace("STEP", f'.param "{STEP}"'), concept=heading_concept('.param "step"'),
                                  edit=calls_heading_concept, params=[REVIEWED], accepted=CALL_ACCEPTED, acquisition=PROFILE)
        self.assertIn(f'"max_step":{{"param":"{STEP}"}}', out)          # the expanded rule carries the caller's actual
        self.assertEqual(v.verdict, "OK", v.details)

    def test_an_alias_passed_to_a_concepts_formal_is_refused(self):
        alias = {**REVIEWED, "name": "p.my_step"}
        v, _out, _ph = G.node_gate(rule=CALL_RULE.replace("STEP", '.param "p.my_step"'), concept=heading_concept('.param "step"'),
                                   edit=calls_heading_concept, params=[REVIEWED, alias], accepted=CALL_ACCEPTED, acquisition=PROFILE)
        self.assertEqual(v.verdict, "CHECK_FAIL", v.details)
        self.assertTrue(any('step bound is {"param": "p.my_step"}' in d for d in v.details), v.details)

    def test_a_concept_with_a_literal_step_is_refused(self):
        v = concept_gate(".lit (Units.seconds 1) .second", [{"span": "measured speed", "value": 1, "unit": "s"}])
        self.assertEqual(v.verdict, "CHECK_FAIL", v.details)
        self.assertTrue(any("a shared concept takes it from its caller as one of its formal parameters (`tol`, `step`)" in d
                            for d in v.details), v.details)

    def test_a_concept_taking_its_step_through_a_formal_passes(self):
        v = concept_gate('.param "step"')
        self.assertEqual(v.verdict, "OK", v.details)


if __name__ == "__main__":
    unittest.main()
