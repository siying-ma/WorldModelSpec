"""Development regression tests for records, scheduling and accounting: one charge per law per
iteration with every outcome recorded, a returned or malformed record never used as a key, a
dependency report no one could judge never charged, concepts claimed anywhere in a record as its
dependencies, waits closed over the reference chain, a figure after a conjunction read, and the
accepted nodes a re-plan leaves out registered with their law."""
import copy
import json
import tempfile
import unittest
from contextlib import ExitStack
from pathlib import Path
from types import SimpleNamespace as NS
from unittest import mock

from harness import loop
from harness.checks import validate_a
from harness.model.blueprint import Node, ConceptRecord
from harness.model.corpus import Law
from harness.model.units import stated_figures, unsupported_figures
from harness.phases import candidate as cand, plan as plan_phase, review as review_phase, validate as validate_phase
from harness.agents import session
from harness.store import paths
from harness.store.ledger import Ledger, ConceptLedger, NodeLedger
from harness.store.state import Options, Run
from scripts.tests import test_recovery as rec
from scripts.tests.test_candidate import Base, Txn, node_rec, world


class OneChargePerIteration(unittest.TestCase):
    def ledger(self, attempts=2):
        tmp = tempfile.TemporaryDirectory(); self.addCleanup(tmp.cleanup)
        led = Ledger(Path(tmp.name) / "ledger.jsonl", ["L"], attempts)
        led.attempt = 2
        led.mark_planned("L", ["old"], 1)
        return led

    def test_a_withdrawal_then_a_returned_new_plan_is_one_attempt_and_returned(self):
        led = self.ledger()
        led.return_law("L", ["repair withdrew"], 2)
        led.mark_planned("L", ["new"], 2)
        led.return_law("L", ["new plan invalid"], 2)
        e = led.entries["L"]
        self.assertEqual((e.state, e.attempts, e.reasons), ("returned", 1, ["repair withdrew", "new plan invalid"]))
        self.assertEqual([x.law for x in led.plannable()], ["L"])
        led.attempt = 3
        self.assertTrue(led.mark_planned("L", ["next"], 3))

    def test_a_terminal_outcome_of_the_iteration_is_never_lowered(self):
        for terminal in ("fail", "block"):
            for order in ("terminal first", "return first"):
                led = self.ledger()
                led.return_law("L", ["repair withdrew"], 2)
                led.mark_planned("L", ["new"], 2)
                act = (lambda: led.fail("L", ["closed"])) if terminal == "fail" else (lambda: led.block("L", ["g1"], ["blocked"]))
                if order == "terminal first":
                    act(); led.return_law("L", ["sibling returned"], 2)
                else:
                    led.return_law("L", ["sibling returned"], 2); act()
                self.assertEqual(led.entries["L"].state, "failed" if terminal == "fail" else "blocked", (terminal, order))
                self.assertEqual(led.entries["L"].attempts, 1, (terminal, order))

    def test_the_budget_still_closes_the_law_in_a_later_iteration(self):
        led = self.ledger()
        led.return_law("L", ["first"], 2)
        led.attempt = 3; led.mark_planned("L", ["n"], 3)
        led.return_law("L", ["second"], 3)
        self.assertEqual((led.entries["L"].state, led.entries["L"].attempts), ("failed", 2))


def _iteration_world(t: str, st: ExitStack):
    """A run at its `planned` stage, its plan holding one node of `L`, with the loop's other seams
    stubbed."""
    root = Path(t)
    st.enter_context(mock.patch.object(paths, "RESULTS", root / "results"))
    st.enter_context(mock.patch.object(paths, "LIBRARY", root / "library"))
    paths.LIBRARY.mkdir()
    opts = Options("probe", root / "laws.jsonl", root / "onto.md", root / "base.json", dry_run=True)
    run = Run(opts, iteration=1)
    run.dir.mkdir(parents=True)
    run.reading_file.write_text('{"params":[],"aggregates":[]}')
    plan = run.iter / "plan"; plan.mkdir(parents=True)
    n = Node({"node_id": "N_1", "law_refs": ["L"], "elements": [], "compositions": []})
    bad = {"concept_id": ["drv.motion.probe"]}
    (plan / "blueprint.jsonl").write_text(json.dumps(n.raw) + "\n" + json.dumps(bad) + "\n")
    plan_phase.record_origins(plan, [(plan, ["L"])])
    law = Law("L", "", "The driver shall stop.", "")
    led = Ledger(run.ledger_file, ["L"], 2); led.attempt = 1; led.mark_planned("L", ["N_1"], 1)
    prog = loop.new_progress(run)
    prog.update(stage="planned", repairs_applied=True, repair_results={"nodes": [], "concepts": []}, plan_dir=str(plan), batch_laws=["L"],
                registered=True, aggregates_merged=True, contexts_rechecked=True, aggregates_prepared=True)
    st.enter_context(mock.patch.object(loop.aggregate_phase, "check_admissions", return_value=([], [])))
    st.enter_context(mock.patch.object(loop.index_sync, "write_index"))
    st.enter_context(mock.patch.object(loop.feedback_phase, "write_feedback"))
    return run, opts, prog, led, ConceptLedger(run.concept_ledger_file, 3), NodeLedger(run.node_ledger_file, 2), law, n, bad


class Stop(BaseException):
    pass


class ReturnedRecords(unittest.TestCase):
    def test_a_malformed_concept_record_is_returned_to_its_batch_never_keyed(self):
        with tempfile.TemporaryDirectory() as t, ExitStack() as st:
            run, opts, prog, led, cl, nl, law, n, bad = _iteration_world(t, st)
            outcomes = validate_a.validate_concepts([ConceptRecord(bad)], [], NS(), {}, [])
            self.assertEqual(outcomes[0].kind, "return")
            st.enter_context(mock.patch.object(loop.validate_phase, "run_validate",
                                               return_value=([validate_phase.NodeVerdict(n, "return", ["scripted node defect"])], outcomes)))

            def persist():
                if prog["stage"] == "validated":
                    raise Stop()
            with self.assertRaises(Stop):
                loop._iteration(run, opts, prog, persist, led, cl, nl, None, {"L": law}, [law], [], NS(), [])
            e = led.entries["L"]
            self.assertEqual((e.state, e.attempts), ("returned", 1))
            self.assertTrue(any("a concept record of plan (record 2)" in r for r in e.reasons), e.reasons)
            self.assertEqual(cl.entries, {})                         # no ledger entry keyed by the malformed id

    def test_the_origin_survives_merging_and_deduplication(self):
        with tempfile.TemporaryDirectory() as t:
            a, b, merged = Path(t) / "batch-01", Path(t) / "batch-02", Path(t) / "plan"
            for d, rows in ((a, [{"node_id": "A_1", "law_refs": ["A"]}]), (b, [{"concept_id": 7}, {"node_id": "B_1", "law_refs": ["B"]}])):
                d.mkdir(); (d / "blueprint.jsonl").write_text("".join(json.dumps(r) + "\n" for r in rows))
            merged.mkdir()
            plan_phase.record_origins(merged, [(a, ["A"]), (b, ["B"])])
            self.assertEqual(plan_phase.origin_of(merged, {"concept_id": 7}), {"batch": "batch-02", "position": 1, "laws": ["B"]})
            self.assertIsNone(plan_phase.origin_of(merged, {"concept_id": 8}))


class UnjudgedReports(unittest.TestCase):
    def test_each_failure_of_the_report_is_a_wait_never_a_verdict(self):
        cases = [(review_phase.Deferred("concept_adjudication", "invalid twice"), "deferred"),
                 (session.SessionUnavailable("down"), "unavailable"),
                 (review_phase.HarnessFailure("no program"), "unavailable")]
        for exc, status in cases:
            with mock.patch.object(review_phase, "dependency_report", side_effect=exc):
                dep = loop.report_of(None, Path("."), set())
            self.assertEqual(dep.status, status, type(exc).__name__)
            self.assertTrue(dep.reasons)

    def test_through_the_loop_the_node_waits_uncharged_then_is_accepted(self):
        for exc in (review_phase.Deferred("concept_adjudication", "invalid twice"), session.SessionUnavailable("down"),
                    review_phase.HarnessFailure("no program")):
            w = rec.World({"L-20": "shall halt."})
            w.plans = {"L-20": [rec.node("L_20", "shall halt.", "L-20")]}
            real = review_phase.dependency_report

            def report(run, task, reached, _exc=exc):
                if Path(task).name == "L_20" and run.iteration == 1:
                    raise _exc
                return real(run, task, reached)
            with rec.Fixture(w) as f, mock.patch.object(review_phase, "dependency_report", side_effect=report):
                f.drive()
                st = f.state()
            led = {e["law"]: e for e in st["ledger"]}
            self.assertEqual((led["L-20"]["state"], led["L-20"]["attempts"]), ("accepted", 0), type(exc).__name__)
            self.assertTrue(any("dependency-defect report could not be judged" in l for l in st["to_user"]), type(exc).__name__)


class ClaimedAnywhere(unittest.TestCase):
    def test_an_occasion_concept_is_a_dependency(self):
        n = Node({"node_id": "N_1", "law_refs": ["L"], "occasion": {"under_way": {"derived": ["drv.motion.turn"]}}})
        self.assertEqual(loop.concept_deps(n), {"drv.motion.turn"})
        self.assertIn("drv.motion.turn", n.claimed_atoms())

    def test_an_occasion_only_concept_is_coded_waited_for_and_reached(self):
        w = rec.World({"L-21": "shall turn."})
        n = rec.node("L_21", "shall turn.", "L-21")
        n["occasion"] = {"under_way": {"atoms": [], "derived": ["drv.motion.turning"]}}
        w.plans = {"L-21": [rec.concept("drv.motion.turning", users=["L_21"]), n]}
        w.review[("drv.motion.turning", 1)] = "returned"
        with rec.Fixture(w) as f:
            f.drive()
            st = f.state()
            run = Run(f.options()); run.load_accepted()
            self.assertEqual(loop.reached_concepts(run, loop.concept_deps(Node(n))), {"drv.motion.turning"})
        self.assertEqual(sorted(st["accepted_concepts"]), ["drv.motion.turning"])
        self.assertEqual(sorted(st["accepted_nodes"]), ["L_21"])
        self.assertEqual([e["attempts"] for e in st["ledger"]], [0])
        self.assertEqual(w.calls[("code", "drv.motion.turning", 1)], 1)
        self.assertEqual(w.calls[("code", "L_21", 1)], 0)            # the node waited for its concept's repair

    def test_the_validator_reads_occasion_concepts(self):
        from harness.model.blueprint import ConceptRecord as C
        n = Node({"node_id": "N_1", "law_refs": ["L"], "occasion": {"under_way": {"derived": ["drv.motion.turn"]}}})
        self.assertEqual(n.claimed_concepts(), {"drv.motion.turn"})
        self.assertTrue(C({"concept_id": "drv.motion.turn", "used_by": ["N_1"]}).used_by())


class HeldNodeFeedback(unittest.TestCase):
    """A held node is described by the state it is held in, not as waiting on the run."""

    def test_a_held_node_is_named_by_its_state(self):
        w = rec.World({"L-1": "shall stop."})
        w.plans = {"L-1": [rec.node("L_1", "shall stop.", "L-1")]}
        w.gate[("L_1", 1)] = "GATE_TIMEOUT"
        with rec.Fixture(w, max_iterations=1) as f:
            f.drive(launches=1)
            notes = (paths.RESULTS / "r" / "AUTO_NOTES.md").read_text(encoding="utf-8")
        self.assertIn("- `L_1` held: its gate's evaluation ended on its cost; its saved candidate is gated again", notes)
        self.assertNotIn("waits on the run", notes)


class RepairReask(unittest.TestCase):
    """A node repair whose first record the validator returns keeps both attempts (records, verdicts,
    the re-ask's prompt), and a resume during the re-ask continues from it: the first session is not
    launched again."""

    def test_both_attempts_are_kept_and_a_resume_continues_from_the_reask(self):
        from scripts.tests.test_operator_decisions import record, LAW, ONTO
        n = record({"span": "s2", "why": "w"})
        tmp = tempfile.TemporaryDirectory(); self.addCleanup(tmp.cleanup)
        d0 = Path(tmp.name) / "run"
        run = NS(iter=d0, dir=d0, iteration=2, mapping_file=d0 / "mapping.json",
                 opts=NS(dry_run=False, plan_turns=1, plan_effort="low", run_id="t", laws=d0 / "laws.jsonl"),
                 all_nodes=lambda: {}, all_concepts=lambda: {})
        last = d0 / "last"; last.mkdir(parents=True)
        launched: list[tuple[str, str]] = []
        crash = {"again": True}

        class Stop(BaseException):
            pass

        def session_run(prompt, cwd=None, out_dir=None, label="session", **_k):
            launched.append((label, prompt))
            if label == "session_again" and crash["again"]:
                crash["again"] = False
                raise Stop()                               # the process ends during the re-ask
            body = {k: v for k, v in n.raw.items() if k not in ("node_id", "law_refs", "segmentation")}
            (Path(cwd) / "record.jsonl").write_text(json.dumps({**body, "obligation": label}))
            (Path(out_dir) / f"{label}_result.json").write_text(json.dumps({"attempt": 1, "result": {}, "failure": None, "stopped": False}))
            return {}

        def validate(nodes, *a, **k):
            first = nodes[0].get("obligation") == "session"
            return [NS(node=nodes[0], reasons=["L_9_o1: scripted defect"] if first else [])]
        patches = [mock.patch.object(plan_phase.session, "run", session_run), mock.patch.object(validate_a, "validate", validate),
                   mock.patch.object(plan_phase.render, "render", lambda _name, b, **_k: "prompt"),
                   mock.patch.object(plan_phase, "definitions_for", lambda _run, _laws: [])]
        reading = NS(data={"params": []}, params=[], pending_aggregates=False)
        with ExitStack() as st:
            for p_ in patches:
                st.enter_context(p_)
            with self.assertRaises(Stop):
                plan_phase.run_node_repair(run, n, ["r"], last, LAW, [], [], reading, ONTO)
            d = plan_phase.run_node_repair(run, n, ["r"], last, LAW, [], [], reading, ONTO)
        self.assertEqual([l for l, _ in launched], ["session", "session_again", "session_again"])
        reask = (d / "prompt_again.md").read_text()
        self.assertIn("scripted defect", reask)
        self.assertEqual(launched[2][1], reask)
        self.assertEqual((d / "validation_first.txt").read_text(), "L_9_o1: scripted defect")
        self.assertEqual(json.loads((d / "record_first.jsonl").read_text())["obligation"], "session")
        self.assertEqual((d / "validation.txt").read_text(), "accept")
        self.assertTrue(plan_phase.read_repair(d, concept=False).accepted)

    def test_a_finished_first_session_is_validated_not_launched_again(self):
        from scripts.tests.test_operator_decisions import record, LAW, ONTO
        n = record({"span": "s2", "why": "w"})
        tmp = tempfile.TemporaryDirectory(); self.addCleanup(tmp.cleanup)
        d0 = Path(tmp.name) / "run"
        run = NS(iter=d0, dir=d0, iteration=2, mapping_file=d0 / "mapping.json",
                 opts=NS(dry_run=False, plan_turns=1, plan_effort="low", run_id="t", laws=d0 / "laws.jsonl"),
                 all_nodes=lambda: {}, all_concepts=lambda: {})
        last = d0 / "last"; last.mkdir(parents=True)
        d = d0 / "repair" / n.id; d.mkdir(parents=True)
        body = {k: v for k, v in n.raw.items() if k not in ("node_id", "law_refs", "segmentation")}
        (d / "record.jsonl").write_text(json.dumps(body))
        (d / "session_result.json").write_text(json.dumps({"attempt": 1, "result": {}, "failure": None, "stopped": False}))
        launched = []
        with mock.patch.object(plan_phase.session, "run", lambda *a, **k: launched.append(k.get("label"))), \
                mock.patch.object(validate_a, "validate", lambda nodes, *a, **k: [NS(node=nodes[0], reasons=[])]), \
                mock.patch.object(plan_phase.render, "render", lambda _name, b, **_k: "prompt"), \
                mock.patch.object(plan_phase, "definitions_for", lambda _run, _laws: []):
            plan_phase.run_node_repair(run, n, ["r"], last, LAW, [], [], NS(data={"params": []}, params=[], pending_aggregates=False), ONTO)
        self.assertEqual(launched, [])
        self.assertEqual((d / "validation.txt").read_text(), "accept")


class ReopenDecidesTokens(unittest.TestCase):
    """A law blocked on `decision:<law>` reopens when that law is reopened; a law waiting on a gap and a
    decision token reopens with the last of them, in either order."""

    def ledger(self):
        tmp = tempfile.TemporaryDirectory(); self.addCleanup(tmp.cleanup)
        led = Ledger(Path(tmp.name) / "ledger.jsonl", ["L", "F", "B"], 3)
        led.fail("F", ["closed"]); led.block("B", ["g1"], ["gap"])
        return led

    def test_reopening_the_failed_provider_reopens_its_caller(self):
        led = self.ledger()
        led.block("L", ["decision:F"], ["waits on F"])
        self.assertEqual(led.reopen(["L-other"]), [])
        self.assertEqual(sorted(led.reopen(["F"])), ["F", "L"])
        self.assertEqual((led.entries["L"].state, led.entries["L"].attempts, led.entries["L"].gaps), ("open", 0, []))

    def test_a_gap_and_a_token_in_either_order(self):
        for order in ("gap_first", "token_first"):
            led = self.ledger()
            led.block("L", ["decision:F", "g1"], ["waits on F and B"])
            if order == "gap_first":
                self.assertEqual([l for l, _ in led.reopen_for_gaps({"g1": ("rejected", "")})], ["B"])
                self.assertEqual((led.entries["L"].state, led.entries["L"].gaps), ("blocked", ["decision:F"]))
                self.assertIn("L", led.reopen(["F"]))
            else:
                self.assertEqual(led.reopen(["F"]), ["F"])
                self.assertEqual((led.entries["L"].state, led.entries["L"].gaps), ("blocked", ["g1"]))
                self.assertEqual(sorted(l for l, _ in led.reopen_for_gaps({"g1": ("retired", "")})), ["B", "L"])
            self.assertEqual(led.entries["L"].state, "open", order)


class Chains(unittest.TestCase):
    def plan(self, root_state):
        with tempfile.TemporaryDirectory() as t:
            led = Ledger(Path(t) / "l", ["S-1", "S-2", "S-3"], 2)
            if root_state == "pending":
                led.mark_planned("S-3", ["S_3"], 1)
            elif root_state == "blocked":
                led.block("S-3", ["g1"], ["blocked"])
            elif root_state == "failed":
                led.fail("S-3", ["closed"])
            elif root_state == "accepted":
                led.mark_planned("S-3", ["S_3"], 1); led.accept("S-3", ["S_3"])
            laws = {i: Law(i, "", text, "") for i, text in [("S-1", "Duty refers to [S-2]."), ("S-2", "Duty refers to [S-3]."), ("S-3", "Duty.")]}
            batches, waiting, dead = loop.plan_batches(led.plannable(), led, laws, 8)
            return [[l.id for l in b] for b in batches], waiting, dead

    def test_a_wait_closes_over_the_chain_and_a_failed_root_stops_nothing(self):
        batches, waiting, dead = self.plan("blocked")
        self.assertEqual((batches, waiting, dead), ([], {"S-2": ["S-3"], "S-1": ["S-2"]}, {}))
        batches, waiting, dead = self.plan("pending")           # a planned provider is no wait: its usable nodes are composed
        self.assertEqual((batches, waiting, dead), ([["S-2", "S-1"]], {}, {}))
        batches, waiting, dead = self.plan("failed")
        self.assertEqual((batches, waiting, dead), ([["S-2", "S-1"]], {}, {"S-2": ["S-3"]}))

    def test_providers_accepted_or_in_an_earlier_batch_are_planned(self):
        batches, waiting, dead = self.plan("accepted")
        self.assertEqual((batches, waiting, dead), ([["S-2", "S-1"]], {}, {}))
        batches, waiting, dead = self.plan("open")
        self.assertEqual((sorted(sum(batches, [])), waiting, dead), (["S-1", "S-2", "S-3"], {}, {}))
        order = sum(batches, [])
        self.assertLess(order.index("S-3"), order.index("S-2")); self.assertLess(order.index("S-2"), order.index("S-1"))


class FiguresAfterAConjunction(unittest.TestCase):
    def test_both_figures_at_their_offsets(self):
        text = "Remain twelve feet from one marker and fifteen feet from the other."
        got = [(f.words, f.start) for f in stated_figures(text)]
        self.assertEqual(got, [("twelve feet", 7), ("fifteen feet", 39)])
        self.assertEqual(text[39:51], "fifteen feet")
        self.assertEqual(unsupported_figures(text), [])

    def test_digits_and_mixed_numbers_are_unchanged(self):
        self.assertEqual([(f.words, f.start) for f in stated_figures("within 15 feet and 20 feet")], [("15 feet", 7), ("20 feet", 19)])
        self.assertEqual([f.words for f in stated_figures("one and one-half miles")], ["one and one-half miles"])
        self.assertEqual((stated_figures("and feet"), unsupported_figures("and feet")), ([], []))


# ---------------------------------------------------------------------------------------------
# An accepted node re-emitted unchanged is validated, not refused as a reused id
# ---------------------------------------------------------------------------------------------
def accepted_sibling_reemitted(reemit: bool = True):
    """L-1 has two duties. In iteration 1 the first node is accepted and the second's gate fails; in
    iteration 2 the planner re-plans the second and (with `reemit`) writes the accepted first node
    again unchanged."""
    def build():
        w = rec.World({"L-1": "shall stop; shall yield"})
        n1 = rec.node("L_1_o1", "shall stop", "L-1")
        n2 = rec.node("L_1_o2", "shall yield", "L-1")
        w.plans[("L-1", 1)] = [n1, n2]
        w.plans[("L-1", 2)] = [n1, n2] if reemit else [n2]
        w.gate[("L_1_o2", 1)] = "CHECK_FAIL"
        return w
    build.opts = {"node_attempts": 1, "plan_attempts": 2, "max_iterations": 2}
    return build


class AcceptedReemission(rec.Interruptions, unittest.TestCase):

    def outcome(self, build):
        w = build()
        with rec.Fixture(w, **build.opts) as f:
            f.drive(launches=1)
            state = f.state()
            snap = json.loads((paths.RESULTS / "r" / "state.json").read_text())
        return w, state, snap

    def test_an_unchanged_reemission_keeps_the_law_and_is_not_coded_again(self):
        w, state, snap = self.outcome(accepted_sibling_reemitted(True))
        self.assertEqual(sorted(snap["accepted_nodes"]), ["L_1_o1", "L_1_o2"])
        law = {e["law"]: e for e in snap["ledger"]}["L-1"]
        self.assertEqual((law["state"], law["attempts"]), ("accepted", 1))
        self.assertFalse(snap["prog"].get("id_defects"))
        self.assertEqual(sum(c for (kind, ident, _it), c in w.calls.items() if kind == "code" and ident == "L_1_o1"), 1)

    def test_the_same_as_leaving_the_accepted_node_out(self):
        _w, _st, with_it = self.outcome(accepted_sibling_reemitted(True))
        _w, _st, without = self.outcome(accepted_sibling_reemitted(False))
        state = lambda snap: ({e["law"]: (e["state"], e["attempts"]) for e in snap["ledger"]}, sorted(snap["accepted_nodes"]))
        self.assertEqual(state(with_it), state(without))

    def test_at_every_stop(self):
        """Also: a node gated and reviewed `OK` before its sibling's failure returned the law is still
        integrated after a stop, whatever the law's state at the resume."""
        for reemit in (True, False):
            ref, _n = self.interrupt_everywhere(accepted_sibling_reemitted(reemit))
            self.assertEqual({e["law"]: e["state"] for e in ref["ledger"]}, {"L-1": "accepted"})
            self.assertEqual(sorted(ref["accepted_nodes"]), ["L_1_o1", "L_1_o2"])

    def test_identity_settlement_leaves_an_accepted_id_to_the_validator(self):
        with tempfile.TemporaryDirectory() as t:
            d = Path(t)
            raw = rec.node("L_1", "shall stop", "L-1")
            (d / "blueprint.jsonl").write_text(json.dumps(raw) + "\n")
            defects, _notes = plan_phase.settle_identity(d, {})       # accepted ids are not reserved
            self.assertEqual(defects, {})
            self.assertIn("L_1", (d / "blueprint.jsonl").read_text())
            self.assertEqual(validate_a.check_reemission(Node(raw), {"L_1": Node(copy.deepcopy(raw))}, "shall stop"), [])

    def test_an_altered_reemission_is_refused_by_the_validator(self):
        raw = rec.node("L_1", "shall stop", "L-1")
        altered = {**copy.deepcopy(raw), "elements": [{**raw["elements"][0], "atoms": ["kin.accel_longitudinal"]}]}
        errs = validate_a.check_reemission(Node(altered), {"L_1": Node(raw)}, "shall stop")
        self.assertTrue(errs and "already accepted" in errs[0])

    def test_a_carried_id_and_a_conflicting_duplicate_are_still_refused(self):
        with tempfile.TemporaryDirectory() as t:
            d = Path(t)
            raw = rec.node("L_1", "shall stop", "L-1")
            (d / "blueprint.jsonl").write_text(json.dumps(raw) + "\n")
            defects, _ = plan_phase.settle_identity(d, {"L_1": "a node held or repaired this iteration"})
            self.assertIn("L-1", defects)
        with tempfile.TemporaryDirectory() as t:
            d = Path(t)
            other = {**copy.deepcopy(raw), "applicability": "different"}
            (d / "blueprint.jsonl").write_text(json.dumps(raw) + "\n" + json.dumps(other) + "\n")
            defects, _ = plan_phase.settle_identity(d, {})
            self.assertTrue(any("different records under one id" in x for x in defects.get("L-1", [])))


# ---------------------------------------------------------------------------------------------
# A re-plan that leaves an accepted node out registers it with the law
# ---------------------------------------------------------------------------------------------
def accepted_sibling_left_out(second_plan: str):
    """L-20 has two duties, L-21 one. In iteration 1 L-20's first node and L-21's node pass their
    gates, L-20's second fails and returns its law; in iteration 2 the planner re-plans L-20, leaving
    the accepted first node out (`second_plan == "left_out"`) or writing both again (`"kept"`)."""
    def build():
        w = rec.World({"L-20": "shall slow. shall stop.", "L-21": "shall wait."})
        o1 = rec.node("L_20_o1", "shall slow. shall stop.", "L-20")
        o2 = rec.node("L_20_o2", "shall slow. shall stop.", "L-20", span="s2")
        w.plans[("L-20", 1)] = [o1, o2]
        w.plans[("L-20", 2)] = [o2] if second_plan == "left_out" else [o1, o2]
        w.plans["L-21"] = [rec.node("L_21", "shall wait.", "L-21")]
        w.gate[("L_20_o2", 1)] = "CHECK_FAIL"
        return w
    build.opts = {"label_repair": True, "node_attempts": 1, "plan_attempts": 2, "max_iterations": 2}
    return build


class LeftOutAcceptedNode(unittest.TestCase):
    """The law's registered nodes are those the validator counts as its own: the plan's, and its
    accepted nodes the plan leaves out. Whether a left-out node may be composed by another law is a
    question of the run's availability rule, not of this registration, and is not asserted here."""

    def generate(self, second_plan: str):
        from scripts.tests.test_split_handoff import label_stage_stand_ins
        build = accepted_sibling_left_out(second_plan)
        w = build()
        with rec.Fixture(w, **build.opts) as f:
            self.assertEqual(f.drive(1, label_deferred=True), ["awaiting_labels"])
            snap = json.loads((paths.RESULTS / "r" / "state.json").read_text())
            checked = []
            real_ready = loop.label_ready
            with label_stage_stand_ins(set()), mock.patch.object(loop, "label_ready", lambda run, ledger: checked.append(
                    real_ready(run, ledger)) or checked[-1]):
                f.drive(1, label_stage=True, label_dataset="ds", max_iterations=2)
        self.assertEqual(sorted(it for (k, i, it) in w.calls if k == "plan" and "L-20" in i.split(",")), [1, 2])
        return {e["law"]: e for e in snap["ledger"]}, snap, checked

    def test_a_left_out_accepted_node_stays_the_laws(self):
        ledger, snap, checked = self.generate("left_out")
        self.assertEqual(sorted(snap["accepted_nodes"]), ["L_20_o1", "L_20_o2", "L_21"])
        self.assertEqual((ledger["L-20"]["state"], ledger["L-20"]["nodes"]), ("planned", ["L_20_o1", "L_20_o2"]))
        self.assertEqual(snap["label_states"]["L-20"]["nodes"], ["L_20_o1", "L_20_o2"])
        self.assertEqual(checked[0]["L-20"], ["L_20_o1", "L_20_o2"])        # the law's label check takes both

    def test_a_plan_that_keeps_every_node_is_registered_as_written(self):
        ledger, snap, checked = self.generate("kept")
        self.assertEqual(ledger["L-20"]["nodes"], ["L_20_o1", "L_20_o2"])
        self.assertEqual(checked[0]["L-20"], ["L_20_o1", "L_20_o2"])

    def test_another_laws_node_is_never_added(self):
        for second_plan in ("left_out", "kept"):
            with self.subTest(second_plan=second_plan):
                ledger, _snap, checked = self.generate(second_plan)
                self.assertNotIn("L_21", ledger["L-20"]["nodes"])
                self.assertEqual(ledger["L-21"]["nodes"], ["L_21"])
                self.assertEqual(checked[0]["L-21"], ["L_21"])


class WithdrawnNode(Base):

    def test_a_node_a_candidate_withdrew_is_not_registered_again(self):
        """The withdrawal a candidate re-plan writes for a node it does not keep is committed; a later
        plan of the law that writes a third node registers the first and the third only, inside the
        candidate and after it."""
        a, b, c, other = "TEST_CAND_9_o1", "TEST_CAND_9_o2", "TEST_CAND_9_o3", "TEST_CAND_8"
        with world({}, {a: node_rec(a), b: node_rec(b), other: node_rec(other)}) as (run, _lib):
            self.assertEqual(loop.registered_nodes(run, "TEST-CAND-9", [c]), [a, b, c])
            with Txn(run) as txn:
                txn.apply([cand.Change("node", b, None)])
                self.assertEqual(loop.registered_nodes(txn.view, "TEST-CAND-9", [c]), [a, c])
                self.assertTrue(all(r.status == "pass" for r in txn.verify()))
                txn.commit()
            fresh = Run(run.opts)
            fresh.restore_state()
            fresh.load_accepted()
            self.assertEqual(sorted(fresh.accepted_nodes), [other, a])
            self.assertEqual(loop.registered_nodes(fresh, "TEST-CAND-9", [c]), [a, c])


if __name__ == "__main__":
    unittest.main()
