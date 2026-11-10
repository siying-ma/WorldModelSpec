"""Regression tests for a returned node's fields, the closure of plan waits and failures, a takeover
that trusts no recorded group number, and settlements of one request made at once."""
import itertools
import json
import subprocess
import sys
import tempfile
import threading
import time
import unittest
from contextlib import ExitStack
from pathlib import Path
from types import SimpleNamespace as NS
from unittest import mock

from harness import loop
from harness.checks import validate_a
from harness.model.blueprint import ConceptRecord, Node
from harness.model.corpus import Law
from harness.phases import validate as validate_phase
from harness.store import budget, jsonl, owner
from harness.store.ledger import Ledger
from scripts.tests.test_operations import alive, clean_env, py
from scripts.tests.test_records_and_scheduling import Stop, _iteration_world
from scripts.tests.test_review_routing import ONTO


def _to_validated(run, opts, prog, led, cl, nl, law, verdicts, concept_verdicts):
    """Run the iteration until its validation is committed."""
    def persist():
        if prog["stage"] == "validated":
            raise Stop()
    with mock.patch.object(loop.validate_phase, "run_validate", return_value=(verdicts, concept_verdicts)):
        try:
            loop._iteration(run, opts, prog, persist, led, cl, nl, None, {law.id: law}, [law], [], ONTO, [])
        except Stop:
            pass


class ReturnedNodes(unittest.TestCase):
    """A node the validator returned is used only through its law and its reasons."""

    def test_a_malformed_returned_node_returns_its_law_and_never_crashes(self):
        """A returned node whose `derived` entry is a list is routed back by its law; the loop does not traverse it."""
        with tempfile.TemporaryDirectory() as t, ExitStack() as st:
            run, opts, prog, led, cl, nl, law, n, _bad = _iteration_world(t, st)
            n.raw["elements"] = [{"span": "s1", "derived": [["drv.motion.creep"]]}]
            outcomes = validate_a.validate([n], {law.id: law}, ONTO, NS(), NS(), {})
            self.assertEqual(outcomes[0].kind, "return")
            _to_validated(run, opts, prog, led, cl, nl, law, outcomes, [])
            e = led.entries["L"]
            self.assertEqual((e.state, e.attempts), ("returned", 1))
            self.assertTrue(e.reasons)
            self.assertEqual(list(cl.entries), [])

    def test_no_concept_is_coded_for_a_returned_node_alone(self):
        with tempfile.TemporaryDirectory() as t, ExitStack() as st:
            run, opts, prog, led, cl, nl, law, n, _bad = _iteration_world(t, st)
            n.raw["elements"] = [{"span": "s1", "atoms": ["kin.speed"], "derived": ["drv.motion.creep"]}]
            creep = ConceptRecord({"concept_id": "drv.motion.creep", "kind": "predicate", "contract": "creeps",
                                   "args": [{"name": "v", "sort": "track"}], "elements": [{"atoms": ["kin.speed"]}]})
            _to_validated(run, opts, prog, led, cl, nl, law, [validate_phase.NodeVerdict(n, "return", ["scripted node defect"])],
                          [NS(concept=creep, kind="accept", reasons=[])])
            self.assertNotIn("drv.motion.creep", cl.entries)
            self.assertTrue(any("drv.motion.creep" in x and "not coded" in x for x in prog["notes"]))

    def test_claimed_atoms_reads_only_string_ids(self):
        n = Node({"node_id": "N_1", "law_refs": ["L"],
                  "elements": [{"atoms": ["kin.speed", ["x"], {"y": 1}], "derived": [["drv.motion.creep"], "drv.motion.halt"]}, "junk"],
                  "operationalizations": [{"concepts": "drv.motion.go"}, {"concept": ["z"]}, 7],
                  "occasion": {"under_way": {"derived": [None, "drv.motion.turn"]}}})
        self.assertEqual(n.claimed_atoms(), {"kin.speed", "drv.motion.halt", "drv.motion.turn"})


def _clean_record(comp: dict) -> dict:
    """A caller record whose one defect the real validator can find is its composition's target."""
    from scripts.tests.test_definition_references import record
    raw = record(compositions=[comp])
    raw["elements"][0].pop("source_spans")
    raw["elements"][0]["atoms"] = ["st.turn_lane", "rel.occupies"]
    raw["scenarios"] = [{"name": k, "expected": v} for k, v in (("forbid", "violated"), ("permit", "compliant"), ("idle", "not_applicable"), ("blind", "unknown"))]
    raw["scenarios"][3]["masked"] = ["st.turn_lane"]
    return raw


class UnavailableProvider(unittest.TestCase):
    """A plan that composes a node of a law waiting for the operator (blocked, failed, or held only on
    such laws) is not coded and not charged: its record, the composition and its map stand, and the
    law is blocked on what the provider waits on — a blocked provider's gaps, `decision:<law>` for a
    failed one — and reopens with it. The caller's own defects are still charged."""

    COMPLIANCE = {"span": "r1", "as": "compliance", "rule": "STA_900A_200_2", "map": {"veh": "veh"}}

    def world(self, t, st, provider_state: str, comp: dict | None = None, extra: list[str] | None = None, real: bool = True):
        from harness.store.ledger import Entry
        from harness.model.reading import Reading
        from harness.model.mapping import MappingIndex
        from harness.model import ontology
        from scripts.tests.test_definition_references import LAW, SRC, SRC_ID, SOURCES
        raw = _clean_record(comp or dict(self.COMPLIANCE))
        if real:                                       # the real validator, with no record of the provider anywhere
            onto = ontology.load(Path("ontology/ATOMS_train.md"))
            (Path(t) / "reading.json").write_text('{"params":[],"aggregates":[]}')
            outcomes = validate_a.validate([Node(json.loads(json.dumps(raw)))], {LAW.id: LAW, SRC_ID: SRC}, onto,
                                           Reading(Path(t) / "reading.json"), MappingIndex(Path(t) / "none.json"), {}, sources=SOURCES)
            verdicts = [validate_phase.NodeVerdict(o.node, o.kind, o.reasons + (extra or [])) for o in outcomes]
        else:
            verdicts = [validate_phase.NodeVerdict(Node(raw), "return", validate_a.check_compositions(Node(json.loads(json.dumps(raw))), {}, SOURCES) + (extra or []))]
        run, opts, prog, led, cl, nl, _law, _n, _bad = _iteration_world(t, st)
        led.entries = run.law_entries = {LAW.id: Entry(LAW.id), SRC_ID: Entry(SRC_ID)}
        led.mark_planned(LAW.id, ["STA_900A_100_1"], 1)
        if provider_state == "blocked":
            led.block(SRC_ID, ["g1"], ["gap g1"])
        elif provider_state == "failed":
            led.fail(SRC_ID, ["closed"])
        (run.iter / "plan" / "blueprint.jsonl").write_text(json.dumps(raw) + "\n"); prog["batch_laws"] = [LAW.id]
        return run, opts, prog, led, cl, nl, LAW, raw, verdicts

    def route(self, provider_state: str, comp: dict | None = None, extra: list[str] | None = None, real: bool = True):
        with tempfile.TemporaryDirectory() as t, ExitStack() as st:
            run, opts, prog, led, cl, nl, law, raw, verdicts = self.world(t, st, provider_state, comp, extra, real)
            _to_validated(run, opts, prog, led, cl, nl, law, verdicts, [])
            return led, law.id, raw, verdicts, prog

    def test_the_real_validator_finds_only_the_unknown_target(self):
        _led, _l, _raw, verdicts, _p = self.route("failed")
        self.assertEqual([(v.kind, v.reasons) for v in verdicts],
                         [("return", ["STA_900A_100_1: composes `STA_900A_200_2`, which is neither accepted nor in this plan"])])

    def test_a_blocked_provider_holds_the_law_uncharged_and_keeps_the_dependency(self):
        led, law, raw, verdicts, _p = self.route("blocked")
        e = led.entries[law]
        self.assertEqual((e.state, e.attempts, e.gaps), ("blocked", 0, ["g1"]))
        self.assertEqual(Node(raw).dependencies(), [self.COMPLIANCE])          # dependency and map as planned
        self.assertEqual(verdicts[0].node.dependencies(), [self.COMPLIANCE])
        self.assertEqual(Node(raw).definition_references(), [])

    def test_a_failed_provider_holds_the_law_on_its_decision_uncharged(self):
        led, law, raw, _v, prog = self.route("failed")
        e = led.entries[law]
        self.assertEqual((e.state, e.attempts, e.gaps), ("blocked", 0, ["decision:STA-900A-200-2"]))
        self.assertEqual(Node(raw).dependencies(), [self.COMPLIANCE])
        self.assertFalse(any("state in full" in r or "another rule" in r for r in e.reasons), e.reasons)
        self.assertTrue(any("reopen" in x and "STA-900A-200-2" in x for x in prog["to_user"]), prog["to_user"])

    def test_the_provider_recovers_and_the_caller_resumes(self):
        led, law, _raw, _v, _p = self.route("failed")
        self.assertEqual(sorted(led.reopen(["STA-900A-200-2"])), sorted([law, "STA-900A-200-2"]))
        self.assertEqual((led.entries[law].state, led.entries[law].attempts), ("open", 0))
        led, law, _raw, _v, _p = self.route("blocked")
        self.assertEqual(sorted(l for l, _ in led.reopen_for_gaps({"g1": ("retired", "")})), sorted([law, "STA-900A-200-2"]))
        self.assertEqual([e.law for e in led.plannable()], [law, "STA-900A-200-2"])

    def test_the_callers_own_defect_is_charged_and_the_dependency_stays(self):
        own = "STA_900A_100_1: composition of `STA_900A_200_2` maps ['x'], its binders are ['veh']"
        led, law, _raw, _v, _p = self.route("failed", extra=[own])
        e = led.entries[law]
        self.assertEqual((e.state, e.attempts), ("returned", 1))
        self.assertIn(own, e.reasons)
        self.assertFalse(any("neither accepted nor in this plan" in r for r in e.reasons), e.reasons)
        self.assertTrue(any("that composition stands" in r for r in e.reasons), e.reasons)

    def test_a_target_of_an_available_law_is_the_callers_error(self):
        led, law, _raw, _v, _p = self.route("open")
        self.assertEqual((led.entries[law].state, led.entries[law].attempts), ("returned", 1))

    def test_a_composition_naming_no_rule_is_returned(self):
        led, law, _raw, verdicts, _p = self.route("blocked", {"span": "r1", "as": "compliance", "map": {"veh": "veh"}}, real=False)
        self.assertTrue(any("names no `rule`" in r for r in verdicts[0].reasons))
        self.assertEqual((led.entries[law].state, led.entries[law].attempts), ("returned", 1))

    def test_coding_readiness_holds_a_node_whose_provider_failed_since_planning(self):
        """The validator accepted the composition (the provider's node was planned beside it); the
        provider failed before the caller was coded."""
        from scripts.tests.test_definition_references import LAW
        with tempfile.TemporaryDirectory() as t, ExitStack() as st:
            run, opts, prog, led, cl, nl, law, raw, _v = self.world(t, st, "failed", real=False)
            n = Node(raw)

            def persist():
                if n.id in prog.get("nodes", {}):
                    raise Stop()
            with mock.patch.object(loop.validate_phase, "run_validate", return_value=([validate_phase.NodeVerdict(n, "accept", [])], [])):
                try:
                    loop._iteration(run, opts, prog, persist, led, cl, nl, None, {LAW.id: LAW}, [LAW], [], ONTO, [])
                except Stop:
                    pass
            e = led.entries[LAW.id]
            self.assertEqual((e.state, e.attempts, e.gaps), ("blocked", 0, ["decision:STA-900A-200-2"]))
            self.assertEqual(prog["nodes"][n.id], "HELD")

    def test_a_repair_composing_an_unavailable_provider_waits(self):
        from harness.store.ledger import Ledger as L
        with tempfile.TemporaryDirectory() as t:
            led = L(Path(t) / "l", ["STA-900A-100-1", "STA-900A-200-2"], 3); led.fail("STA-900A-200-2", ["closed"])
            run = NS(all_nodes=lambda: {}, usable_nodes=lambda law: {})
            rec = Node(_clean_record(dict(self.COMPLIANCE)))
            msg = validate_a.unknown_target(rec.id, "STA_900A_200_2")
            self.assertEqual(loop._repair_waits(run, led, [], NS(records=[rec], validation=[msg])), {"STA_900A_200_2": {"STA-900A-200-2"}})
            self.assertEqual(loop._repair_waits(run, led, [], NS(records=[rec], validation=[msg, "STA_900A_100_1: scenario `idle` missing"])), {})
            led.reopen(["STA-900A-200-2"])
            self.assertEqual(loop._repair_waits(run, led, [], NS(records=[rec], validation=[msg])), {})


class PlanWaits(unittest.TestCase):
    """Waiting closes over the reference chain; a named law closed as failed stops nothing: the law
    naming it is planned and reported, and its plan answers for what it composes."""

    def batches(self, laws: dict[str, str], states: dict[str, str]):
        with tempfile.TemporaryDirectory() as t:
            by_id = {k: Law(k, "", v, "") for k, v in laws.items()}
            led = Ledger(Path(t) / "l", list(laws), 3)
            for k, s in states.items():
                if s == "planned":
                    led.mark_planned(k, [k.replace("-", "_")], 1)
                elif s == "failed":
                    led.fail(k, ["failed provider"])
                elif s == "accepted":
                    led.mark_planned(k, [k.replace("-", "_")], 1); led.accept(k, [k.replace("-", "_")])
            b, waiting, failed = loop.plan_batches(led.plannable(), led, by_id, 8)
            return [[x.id for x in xs] for xs in b], waiting, failed

    def test_the_audit_mixed_branch(self):
        """`mixed_wait_and_failure`: S-1 names S-2 (which names a failed law) and a pending P-1."""
        laws = {"S-1": "[S-2] and [P-1]", "S-2": "[F-1]", "P-1": "", "F-1": ""}
        for order in itertools.permutations(laws):
            b, waiting, failed = self.batches({k: laws[k] for k in order}, {"P-1": "planned", "F-1": "failed"})
            self.assertEqual(failed, {"S-2": ["F-1"]}, order)
            self.assertEqual(waiting, {}, order)                      # a planned law named is no wait: its usable nodes are composed
            self.assertEqual(b, [["S-2", "S-1"]])

    def test_a_failed_law_reached_through_a_waiting_law(self):
        laws = {"A-1": "[A-2]", "A-2": "[A-3] and [P-1]", "A-3": "[F-1]", "P-1": "", "F-1": ""}
        b, waiting, failed = self.batches(laws, {"P-1": "planned", "F-1": "failed"})
        self.assertEqual(failed, {"A-3": ["F-1"]})
        self.assertEqual(waiting, {})
        self.assertEqual(b, [["A-3", "A-2", "A-1"]])

    def test_controls(self):
        laws = {"C-1": "[C-2]", "C-2": "[P-1]", "P-1": "", "D-1": "[E-1]", "E-1": ""}
        b, waiting, failed = self.batches(laws, {"P-1": "planned", "E-1": "accepted"})
        self.assertEqual(waiting, {})
        self.assertEqual(failed, {})
        self.assertEqual(b, [["C-2", "C-1", "D-1"]])


class FirstPlanWaits(unittest.TestCase):
    """A law with no record yet waits on a named law that progresses by itself, never on one waiting
    for the operator (blocked, failed, or waiting only on such laws, directly or through a chain); a
    law with a record waits on both. Chain closure and order are otherwise unchanged."""

    def batches(self, laws: dict[str, str], states: dict[str, str], unrecorded: set[str] | None,
                held: dict[str, set[str]] | None = None, borrowed: dict | None = None):
        with tempfile.TemporaryDirectory() as t:
            by_id = {k: Law(k, "", v, "") for k, v in laws.items()}
            led = Ledger(Path(t) / "l", list(laws), 3)
            for k, s in states.items():
                if s == "planned":
                    led.mark_planned(k, [k.replace("-", "_")], 1)
                elif s == "returned":
                    led.mark_planned(k, [k.replace("-", "_")], 1); led.return_law(k, ["r"], 1)
                elif s == "blocked":
                    led.block(k, ["g1"], ["gap"])
                elif s == "paused":
                    led.block(k, [f"decision:{k}"], ["held for the operator"])
                elif s == "failed":
                    led.fail(k, ["closed"])
            b, waiting, unavailable = loop.plan_batches(led.plannable(), led, by_id, 8, borrowed or {}, unrecorded, held)
            return [[x.id for x in xs] for xs in b], waiting, unavailable

    def test_the_operator_probe_states(self):
        """Provider blocked, caller with no record: one batch, nothing waits."""
        laws = {"C-1": "Duty under [P-1].", "P-1": "Duty."}
        self.assertEqual(self.batches(laws, {"P-1": "blocked"}, None), ([], {"C-1": ["P-1"]}, {}))
        for state in ("blocked", "paused", "failed"):
            self.assertEqual(self.batches(laws, {"P-1": state}, {"C-1"}), ([["C-1"]], {}, {"C-1": ["P-1"]}), state)

    def test_a_text_only_source_blocked_or_failed_never_stops_the_first_plan(self):
        laws = {"C-1": "As described in [P-1].", "P-1": "Duty."}
        for state in ("blocked", "failed"):
            self.assertEqual(self.batches(laws, {"P-1": state}, {"C-1"})[0], [["C-1"]], state)
            self.assertEqual(self.batches(laws, {"P-1": state}, set(), borrowed={"C-1": {"P-1"}})[0], [["C-1"]], state)

    def test_a_planned_provider_makes_no_plan_wait(self):
        laws = {"C-1": "Duty under [P-1].", "P-1": "Duty."}
        for unrecorded in ({"C-1"}, set()):
            self.assertEqual(self.batches(laws, {"P-1": "planned"}, unrecorded), ([["C-1"]], {}, {}))

    def test_a_provider_held_only_on_a_blocked_law_is_passed_by_a_first_plan(self):
        laws = {"C-1": "Duty under [P-1].", "P-1": "Duty.", "Q-1": "Duty."}
        for q in ("blocked", "failed"):                  # a planned provider is no wait: which of its nodes waits is decided per node
            self.assertEqual(self.batches(laws, {"P-1": "planned", "Q-1": q}, {"C-1"}, {"P-1": {"Q-1"}}), ([["C-1"]], {}, {}), q)
            self.assertEqual(self.batches(laws, {"P-1": "planned", "Q-1": q}, set(), {"P-1": {"Q-1"}}), ([["C-1"]], {}, {}), q)
        laws["R-1"] = "Duty."
        self.assertEqual(self.batches(laws, {"P-1": "planned", "Q-1": "blocked", "R-1": "planned"}, {"C-1"}, {"P-1": {"Q-1", "R-1"}})[1], {})

    def test_a_returned_provider_waiting_only_on_a_blocked_law_is_passed_by_a_first_plan(self):
        laws = {"C-1": "Duty under [P-1].", "P-1": "Duty under [Q-1].", "Q-1": "Duty."}
        self.assertEqual(self.batches(laws, {"P-1": "returned", "Q-1": "blocked"}, {"C-1"}), ([["C-1"]], {"P-1": ["Q-1"]}, {"C-1": ["P-1"]}))
        self.assertEqual(self.batches(laws, {"P-1": "returned", "Q-1": "blocked"}, set()), ([], {"P-1": ["Q-1"], "C-1": ["P-1"]}, {}))
        self.assertEqual(self.batches(laws, {"P-1": "returned", "Q-1": "planned"}, {"C-1"}), ([["P-1", "C-1"]], {}, {}))

    def test_an_ordinary_provider_awaiting_repair_advances_by_itself(self):
        """A planned provider whose held node waits on no other law (a repair, a concept) is no
        unavailable law, and no wait either: a caller is planned at once, before and after its acceptance."""
        carried = [Node({"node_id": "P_1", "law_refs": ["P-1"], "compositions": []})]
        with tempfile.TemporaryDirectory() as t:
            led = Ledger(Path(t) / "l", ["C-1", "P-1"], 3); led.mark_planned("P-1", ["P_1"], 1)
            held = loop.held_waits(carried, led, set())
            self.assertEqual((held, loop.unavailable_roots(led, held)), ({}, {}))
            by_id = {"C-1": Law("C-1", "", "Duty under [P-1].", ""), "P-1": Law("P-1", "", "Duty.", "")}
            self.assertEqual(loop.plan_batches(led.plannable(), led, by_id, 8, {}, {"C-1"}, held)[1], {})
            led.accept("P-1", ["P_1"])
            self.assertEqual([[l.id for l in b] for b in loop.plan_batches(led.plannable(), led, by_id, 8, {}, {"C-1"}, held)[0]], [["C-1"]])

    def test_held_waits_reads_the_held_nodes(self):
        with tempfile.TemporaryDirectory() as t:
            led = Ledger(Path(t) / "l", ["P-1", "Q-1"], 3); led.mark_planned("P-1", ["P_1_o1", "P_1_o2"], 1)
            on_q = Node({"node_id": "P_1_o1", "law_refs": ["P-1"], "compositions": [{"span": "r", "as": "compliance", "rule": "Q_1", "map": {}}]})
            free = Node({"node_id": "P_1_o2", "law_refs": ["P-1"], "compositions": []})
            self.assertEqual(loop.held_waits([on_q], led, set()), {"P-1": {"Q-1"}})
            self.assertEqual(loop.held_waits([on_q, free], led, set()), {})
            self.assertEqual(loop.held_waits([on_q], led, {"Q_1"}), {})

    def test_the_chain_through_a_first_plan(self):
        laws = {"S-1": "[S-2]", "S-2": "[S-3]", "S-3": ""}
        self.assertEqual(self.batches(laws, {"S-3": "blocked"}, {"S-2"}), ([["S-2", "S-1"]], {}, {"S-2": ["S-3"]}))
        self.assertEqual(self.batches(laws, {"S-3": "blocked"}, {"S-1"}), ([["S-1"]], {"S-2": ["S-3"]}, {"S-1": ["S-2"]}))
        self.assertEqual(self.batches(laws, {"S-3": "blocked"}, set()), ([], {"S-2": ["S-3"], "S-1": ["S-2"]}, {}))
        self.assertEqual(self.batches(laws, {"S-3": "planned"}, {"S-1", "S-2"}), ([["S-2", "S-1"]], {}, {}))

    def test_a_first_plan_naming_a_blocked_and_a_planned_law_is_planned(self):
        laws = {"C-1": "[B-1] and [P-1]", "B-1": "", "P-1": ""}
        self.assertEqual(self.batches(laws, {"B-1": "blocked", "P-1": "planned"}, {"C-1"}), ([["C-1"]], {}, {"C-1": ["B-1"]}))

    def test_a_cycle_of_waits_reaching_no_root_is_no_unavailable_law(self):
        with tempfile.TemporaryDirectory() as t:
            led = Ledger(Path(t) / "l", ["A-1", "B-1", "Q-1"], 3)
            self.assertEqual(loop.unavailable_roots(led, {"A-1": {"B-1"}, "B-1": {"A-1"}}), {})
            led.block("Q-1", ["g1"], ["gap"])
            self.assertEqual(loop.unavailable_roots(led, {"A-1": {"B-1", "Q-1"}, "B-1": {"Q-1"}}),
                             {"Q-1": {"Q-1"}, "B-1": {"Q-1"}, "A-1": {"Q-1"}})

    def test_reference_records_marks_a_law_without_records(self):
        from harness.phases import plan as plan_phase
        laws = {"C-1": Law("C-1", "", "Duty under [P-1].", ""), "P-1": Law("P-1", "", "Duty.", ""), "D-1": Law("D-1", "", "Duty.", "")}
        for history, expected in (((None, [], []), {"C-1"}), ((None, [], ["the plan of iteration 1 could not be read"]), set()),
                                  ((1, [NS(versions=[("as planned", {"node_id": "C_1", "law_refs": ["C-1"]})])], []), set())):
            with mock.patch.object(plan_phase, "law_history", lambda _r, _l, h=history: h):
                self.assertEqual(loop.reference_records(NS(), list(laws), laws), ({}, expected))


class Takeover(unittest.TestCase):
    """A recorded process-group number is a hint: only a process that carries the earlier owner's
    nonce or this library's path is ended, and ended processes are waited for."""

    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.lib = Path(self.tmp.name) / "library"; self.lib.mkdir()
        (self.lib / ".run.lock").write_text("")
        self.procs: list[subprocess.Popen] = []

    def tearDown(self):
        for p in self.procs:
            if p.poll() is None:
                p.kill()
            p.wait()
        self.tmp.cleanup()

    def grouped(self, env: dict) -> subprocess.Popen:
        p = subprocess.Popen([sys.executable, "-c", "import time; time.sleep(120)"], env=env, start_new_session=True)
        self.procs.append(p)
        time.sleep(0.3)
        return p

    def record(self, nonce: str, pgids: list[int]):
        (self.lib / ".run.owner.json").write_text(json.dumps({"nonce": nonce, "pid": 99999999, "run_id": "old", "pgids": pgids,
                                                              "library": str(self.lib.resolve())}))

    def test_a_stale_record_naming_a_foreign_group_leaves_it_untouched(self):
        """A stale record of library B naming a process group of library A: B's takeover leaves A's process alone."""
        foreign = self.grouped(clean_env(**{owner.ENV: "owner-A", owner.LIB_ENV: str(Path(self.tmp.name, "A").resolve())}))
        self.record("old-B", [foreign.pid])
        for force in ("False", "True"):
            r = py(f"owner.acquire('new-B', force={force}); owner._FD.close()", self.lib, allowed=[foreign.pid])
            self.assertEqual(r.returncode, 0, r.stderr)
            self.assertTrue(alive(foreign.pid), force)
        unmarked = self.grouped(clean_env())                      # a reused number now naming a process of no owner
        self.record("old-B", [unmarked.pid])
        r = py("owner.acquire('new-B', force=True)", self.lib, allowed=[unmarked.pid])
        self.assertEqual(r.returncode, 0, r.stderr)
        self.assertTrue(alive(unmarked.pid))

    def test_a_recorded_group_whose_member_cannot_be_told_refuses(self):
        untold = self.grouped(clean_env(**{owner.ENV: "some-owner"}))
        self.record("old-B", [untold.pid])
        for force in ("False", "True"):
            r = py(f"owner.acquire('new-B', force={force})", self.lib, allowed=[untold.pid])
            self.assertNotEqual(r.returncode, 0, force)
            self.assertIn(str(untold.pid), r.stderr)
        self.assertTrue(alive(untold.pid))

    def test_the_earlier_owners_own_writer_is_refused_then_ended_and_waited_for(self):
        ours = self.grouped(clean_env(**{owner.ENV: "old-B", owner.LIB_ENV: str(self.lib.resolve())}))
        self.record("old-B", [ours.pid])
        r = py("owner.acquire('new-B')", self.lib, allowed=[ours.pid])
        self.assertNotEqual(r.returncode, 0)
        self.assertIn(str(ours.pid), r.stderr)
        r = py("owner.acquire('new-B', force=True); print('held')", self.lib, allowed=[ours.pid])
        self.assertEqual(r.returncode, 0, r.stderr)
        self.assertFalse(alive(ours.pid))                         # ended before the library was granted


class Settlements(unittest.TestCase):
    """The check, the durable row and the count of one request are one step."""

    PRICES = {"gpt-x": {"input_usd_per_million": 1, "cached_input_usd_per_million": 1, "output_usd_per_million": 1000}}

    def race(self, *calls):
        with tempfile.TemporaryDirectory() as t:
            f = Path(t) / "usage.jsonl"
            b = budget.Budget(f, 5, self.PRICES)
            token = b.reserve("gpt-x", 0, 1000)
            append = jsonl.append_atomic

            def slow(path, row):                           # widens the window between the check and the count
                time.sleep(0.05)
                return append(path, row)
            with mock.patch.object(jsonl, "append_atomic", side_effect=slow):
                ts = [threading.Thread(target=c, args=(b, token)) for c in calls]
                for th in ts:
                    th.start()
                for th in ts:
                    th.join(timeout=10)
            again = budget.Budget(f, 5, self.PRICES)
            rows = [r for r in jsonl.read_strict(f) if r.get("request") == token]
            return b, again, rows

    def test_a_request_settled_twice_at_once_counts_once(self):
        """Two concurrent settlements of one request count it once, live and after reload."""
        settle = lambda b, tok: b.settle(tok, {"vendor": "openai", "cost_usd": 0.2})
        b, again, rows = self.race(settle, settle)
        self.assertAlmostEqual(b.spent, 0.2)
        self.assertAlmostEqual(again.spent, 0.2)
        self.assertEqual(sum(r.get("state") == "settled" for r in rows), 1)

    def test_unknown_and_settled_at_once_agree_live_and_on_reload(self):
        settle = lambda b, tok: b.settle(tok, {"vendor": "openai", "cost_usd": 0.2})
        lost = lambda b, tok: b.unknown(tok, {"vendor": "openai"})
        for calls in ((lost, settle), (settle, lost)):
            b, again, _rows = self.race(*calls)
            self.assertAlmostEqual(b.spent, again.spent)
            self.assertAlmostEqual(again.spent, 0.2)
            self.assertEqual(b.unresolved, {})


if __name__ == "__main__":
    unittest.main()
