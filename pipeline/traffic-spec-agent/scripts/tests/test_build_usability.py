"""Build usability: when one node may be used to build another, apart from any law's formal acceptance.

`Run.provider_code` decides it from the run's state alone (the owner law's ledger state, the fence,
the plan's membership, the publication, the admission evidence, then the whole closure), the same
way for every consumer: planning, scheduling, the registry, integration, the label readiness and
acceptance, the candidate transaction. The loop scenarios run the real loop, ledgers, admission
recheck and availability on the scripted world of `test_recovery`; sessions and gate verdicts alone
are scripted."""
import json
import unittest
from unittest import mock

from harness import loop
from harness.store import paths
from harness.store.ledger import Ledger
from harness.store.state import (Availability, FENCED, MISSING, OPERATOR, REPLANNING, SUPERSEDED, UNJUDGED, UNPUBLISHED, USABLE,
                                 Run)
from scripts.tests.test_candidate import admit, concept_rec, node_rec, world
from scripts.tests.test_recovery import Fixture, World, node
from scripts.tests.test_split_handoff import SPLIT, calls, label_stage_stand_ins

A1, A2, A3, B1, X1, G1 = "TEST_AV_1_o1", "TEST_AV_1_o2", "TEST_AV_1_o3", "TEST_AV_2", "TEST_AV_3", "TEST_AV_9"
LA, LB, LX = "TEST-AV-1", "TEST-AV-2", "TEST-AV-3"
CF = "drv.motion.cand_f"


def comp(nid, *rules, concepts=()):
    return node_rec(nid, concepts, compositions=[{"span": "o1", "rule": r, "as": "condition"} for r in rules])


class CodeTable(unittest.TestCase):
    """T0: each code once, with the closure's prefix, and `usable_nodes` without the unusable."""

    def table(self):
        nodes = {A1: comp(A1), A2: comp(A2, A1), B1: comp(B1, A1), X1: comp(X1, B1), G1: comp(G1),
                 "TEST_AV_4": comp("TEST_AV_4", concepts=[CF])}
        return world({CF: concept_rec(CF)}, nodes)

    def ledger(self, run) -> Ledger:
        led = Ledger(run.ledger_file, [LA, LB, LX, "TEST-AV-4"], 2)
        led.mark_planned(LA, [A1, A2], 1); led.mark_planned(LB, [B1], 1); led.mark_planned(LX, [X1], 1)
        led.mark_planned("TEST-AV-4", ["TEST_AV_4"], 1)
        run.law_entries = led.entries
        return led

    def test_each_code(self):
        with self.table() as (run, _lib):
            led = self.ledger(run)
            av = lambda: Availability(run)
            self.assertEqual({i: av().code(i, LX) for i in (A1, A2, B1, X1, G1)}, dict.fromkeys((A1, A2, B1, X1, G1), USABLE))
            self.assertEqual(av().code(G1, None), USABLE)                                  # a law outside the ledger, admitted
            led.entries[LA].nodes = [A2]                                                    # A1 no longer in A's plan
            self.assertEqual((av().code(A1, LA), av().code(B1, LB), av().code(X1, LX)),
                             (SUPERSEDED, f"via:{A1}:{SUPERSEDED}", f"via:{B1}:via:{A1}:{SUPERSEDED}"))
            self.assertNotIn(A1, run.usable_nodes(LB))
            led.entries[LA].nodes = [A1, A2, A3]
            self.assertEqual((av().code(A3, LA), av().code("TEST_AV_1_o9", LA)), (UNPUBLISHED, MISSING))
            led.entries[LA].state = "returned"
            self.assertEqual((av().code(A1, LA), av().code(B1, LB)), (REPLANNING, f"via:{A1}:{REPLANNING}"))
            for closed in ("blocked", "failed"):
                led.entries[LA].state = closed
                self.assertEqual((av().code(A1, LA), av().code(X1, LX)), (OPERATOR, f"via:{B1}:via:{A1}:{OPERATOR}"))
            led.entries[LA].state = "planned"
            run.fence(A1, "node", "gate", evidence="scripted")
            self.assertEqual((av().code(A1, LA), av().code(B1, LB)), (FENCED, f"via:{A1}:{FENCED}"))
            self.assertNotIn(A1, run.usable_nodes(LA))
            run.fenced.clear()
            run.fence(CF, "concept", "context", evidence="scripted")
            self.assertEqual(av().code("TEST_AV_4", "TEST-AV-4"), f"via:{CF}:{FENCED}")
            run.fenced.clear()
            run.fence(G1, "node", "gate", evidence="scripted")
            self.assertEqual(av().code(G1, None), FENCED)
            run.fenced.clear()
            (run.dir / "admission.json").write_text(json.dumps({k: v for k, v in json.loads((run.dir / "admission.json").read_text()).items()
                                                                if k != G1}))
            self.assertEqual(av().code(G1, None), UNJUDGED)                                 # no evidence: never taken as admitted
            admit(run, {G1})
            self.assertEqual(av().code(G1, None), USABLE)

    def test_the_iteration_view_and_no_cache_across_changes(self):
        """T21: a gated sibling of the current iteration is usable for its own law's node and
        unpublished for another law's; each query reads the state as it is now: after a fence, a
        change of the plan, or a sibling published, the next answer follows."""
        with self.table() as (run, _lib):
            led = self.ledger(run)
            led.entries[LA].nodes = [A1, A2, A3]
            sib = {A3: comp(A3, A1)}
            av = Availability(run, siblings=sib)
            self.assertEqual((av.code(A3, LA), av.code(A3, LB)), (USABLE, UNPUBLISHED))
            self.assertEqual(Availability(run).code(A3, LA), UNPUBLISHED)                  # the published view has no sibling
            run.fence(A1, "node", "gate", evidence="scripted")
            self.assertEqual(Availability(run, siblings=sib).code(A3, LA), f"via:{A1}:{FENCED}")   # no caller is exempt from the closure
            self.assertEqual(av.code(A3, LA), USABLE)                                      # one computation keeps its own answers
            run.fenced.clear()
            run.accepted_nodes[A3] = sib[A3]; admit(run, {A3})
            self.assertEqual(Availability(run).code(A3, LB), USABLE)                       # published: usable across laws


def chain_world() -> World:
    """L-40 ← L-41 ← L-42 (each composes the one before)."""
    w = World({"L-40": "a.", "L-41": "b.", "L-42": "c."})
    w.plans = {"L-40": [node("L_40", "a.", "L-40")], "L-41": [node("L_41", "b.", "L-41", compositions=["L_40"])],
               "L-42": [node("L_42", "c.", "L-42", compositions=["L_41"])]}
    return w


class Generation(unittest.TestCase):

    def test_a_chain_is_generated_on_the_remote_stage_alone(self):
        """T1: L-40 ← L-41 ← L-42, remote only, five iterations allowed: three iterations generate all
        three, no attempt counted, and every coder's registry held only usable nodes."""
        w = chain_world()
        registries = []
        real = loop.code_phase.run_code

        def run_code(run, n, reading, registry, saved=None, catalogue=None):
            registries.append((n.id, list(registry["nodes"])))
            return real(run, n, reading, registry, saved=saved, catalogue=catalogue)
        with Fixture(w, **SPLIT) as f, mock.patch.object(loop.code_phase, "run_code", run_code):
            self.assertEqual(f.drive(1, label_deferred=True, max_iterations=5), ["awaiting_labels"])
            st = f.state()
        self.assertEqual(sorted(calls(w, "code")), [("L_40", 1), ("L_41", 2), ("L_42", 3)])
        self.assertEqual({e["law"]: (e["state"], e["attempts"]) for e in st["ledger"]}, dict.fromkeys(("L-40", "L-41", "L-42"), ("planned", 0)))
        self.assertEqual(dict(registries), {"L_40": [], "L_41": ["L_40"], "L_42": ["L_40", "L_41"]})

    def test_an_integration_return_holds_the_dependent_until_the_successor_is_published(self):
        """T5: A1 fails integration in iteration 1 and is returned; B is not coded on it; once A1 is
        coded again and published, B is coded on the remote stage, its law never charged."""
        w = World({"L-20": "a.", "L-21": "b."})
        w.plans = {"L-20": [node("L_20_o1", "a.", "L-20")], "L-21": [node("L_21", "b.", "L-21", compositions=["L_20_o1"])]}
        w.integration_fail[1] = {"L_20_o1"}
        with Fixture(w, **SPLIT) as f:
            self.assertEqual(f.drive(1, label_deferred=True, max_iterations=5), ["awaiting_labels"])
            ledger = {e["law"]: e for e in f.state()["ledger"]}
        coded = calls(w, "code")
        self.assertEqual([c for c in coded if c[0] == "L_21"], [("L_21", 3)])
        self.assertEqual(ledger["L-21"]["attempts"], 0)


class OnlyUnjudged(unittest.TestCase):

    def test_records_left_unjudged_are_no_work_and_their_counts_are_kept(self):
        """T24, T28, T32: after generation, every admission gate times out. A record without evidence
        is not usable (nor anything on it), is not fenced, and is no work: the remote stage stops
        without `iteration_limit` and runs no session; each launch times each record once, the counts
        sum in the admission file to the bound and then stop; attempts are never touched; a child
        process reloading the run reads the same codes."""
        w = chain_world()
        with Fixture(w, **SPLIT) as f:
            self.assertEqual(f.drive(1, label_deferred=True, max_iterations=5), ["awaiting_labels"])
            adm = paths.RESULTS / "r" / "admission.json"
            adm.write_text("{}")
            w.admission.update(dict.fromkeys(("L_40", "L_41", "L_42"), "GATE_TIMEOUT"))
            before = dict(w.calls)
            seen = []
            for launch in range(3):
                res = loop.run_loop(f.options(label_deferred=True, max_iterations=9))
                summary = json.loads((paths.RESULTS / "r" / "summary.json").read_text())
                seen.append((res["status"], summary.get("stop"), {k: v.get("timeouts") for k, v in json.loads(adm.read_text()).items()}))
            self.assertEqual(dict(w.calls), before)                                          # no session
            self.assertEqual([s[1] for s in seen], ["", "", ""])
            self.assertEqual([s[2] for s in seen], [dict.fromkeys(("L_40", "L_41", "L_42"), 1), dict.fromkeys(("L_40", "L_41", "L_42"), 2),
                                                    dict.fromkeys(("L_40", "L_41", "L_42"), 2)])
            self.assertEqual(w.admitted["L_40"], 2)                                          # at the bound: no more timing
            st = f.state()
            self.assertEqual(st["fenced"], {})
            self.assertEqual({e["law"]: e["attempts"] for e in st["ledger"]}, dict.fromkeys(("L-40", "L-41", "L-42"), 0))
            reloaded = Run.load("r")
            reloaded.law_entries = Ledger(reloaded.ledger_file, [], 2).entries
            self.assertEqual({i: reloaded.provider_code(i, None) for i in ("L_40", "L_41")},
                             {"L_40": UNJUDGED, "L_41": f"via:L_40:{UNJUDGED}"})
            self.assertEqual(loop.label_ready(reloaded, Ledger(reloaded.ledger_file, [], 2)), {})


class SplitFence(unittest.TestCase):

    def fenced_after_generation(self, split: bool):
        """A1 (L-20) accepted and kept; B (L-21) composes it; C (L-22) independent. At the next launch
        A1 is rejected by its admission gate under a changed gate implementation."""
        w = World({"L-20": "a.", "L-21": "b.", "L-22": "c."})
        w.plans = {"L-20": [node("L_20_o1", "a.", "L-20")], "L-21": [node("L_21", "b.", "L-21", compositions=["L_20_o1"])],
                   "L-22": [node("L_22", "c.", "L-22")]}
        f = Fixture(w, **(SPLIT if split else {}))
        return w, f

    def test_split_hands_the_fenced_laws_to_the_operator_and_goes_on(self):
        """T17 (split), T16 (b): A1 rejected: no stop and no `--base_run` advice; A is held on
        `decision:A`, B (accepted on A1 before) loses its acceptance and is held on A's token, waiting on
        A, its label state `waiting` with the reason; C goes on; no attempt counted."""
        w, f = self.fenced_after_generation(split=True)
        with f:
            self.assertEqual(f.drive(1, label_deferred=True, max_iterations=3), ["awaiting_labels"])
            with label_stage_stand_ins({"L-20", "L-21", "L-22"}):
                self.assertEqual(f.drive(1, label_stage=True, label_dataset="ds", max_iterations=3), ["complete"])
            (f.root / "harness" / "checks").mkdir(parents=True, exist_ok=True)
            (f.root / "harness" / "checks" / "changed.py").write_text("# changed\n")
            w.admission["L_20_o1"] = "CHECK_FAIL"
            out = f.drive(1, label_deferred=True, max_iterations=4)
            st = f.state()
            snap = json.loads((paths.RESULTS / "r" / "state.json").read_text())
        self.assertNotEqual(out, ["crash"])
        ledger = {e["law"]: e for e in st["ledger"]}
        self.assertEqual((ledger["L-20"]["state"], ledger["L-20"]["gaps"]), ("blocked", ["decision:L-20"]))
        self.assertEqual((ledger["L-21"]["state"], ledger["L-21"]["gaps"], ledger["L-21"]["waits_on"]), ("blocked", ["decision:L-20"], ["L-20"]))
        self.assertEqual(ledger["L-22"]["state"], "accepted")
        self.assertEqual({k: v["attempts"] for k, v in ledger.items()}, dict.fromkeys(ledger, 0))
        self.assertEqual(snap["label_states"]["L-21"]["state"], "waiting")
        self.assertIn("revoked", snap["label_states"]["L-21"]["revoked_reason"]["reason"])
        self.assertFalse(any("--base_run" in x for x in st["to_user"]))

    def test_without_the_split_the_run_stops_with_the_subset_continuation(self):
        """T17 (not split): as before, the run stops before any spend with the subset continuation."""
        w, f = self.fenced_after_generation(split=False)
        with f:
            self.assertEqual(f.drive(1, max_iterations=3), ["complete"])
            (f.root / "harness" / "checks").mkdir(parents=True, exist_ok=True)
            (f.root / "harness" / "checks" / "changed.py").write_text("# changed\n")
            w.admission["L_20_o1"] = "CHECK_FAIL"
            with self.assertRaises(SystemExit) as e:
                loop.run_loop(f.options(max_iterations=4))
        self.assertIn("--base_run", str(e.exception))


class LeftOutFencedNode(unittest.TestCase):
    """A re-plan that leaves an accepted node out keeps it its law's (registration); once fenced, that
    node is never coded again, composed or taken as its law's acceptance, and is never dropped so
    that the law's other nodes stand for the whole law: the law is not label-ready, and is handed to
    the operator."""

    def test_a_left_out_fenced_node_keeps_its_law_from_acceptance(self):
        from scripts.tests.test_records_and_scheduling import accepted_sibling_left_out
        build = accepted_sibling_left_out("left_out")
        w = build()
        w.laws["L-23"] = "shall go."
        w.plans["L-23"] = [node("L_23", "shall go.", "L-23", compositions=["L_20_o1"])]
        with Fixture(w, **{**build.opts, "max_iterations": 4}) as f:
            self.assertEqual(f.drive(1, label_deferred=True), ["awaiting_labels"])
            st = f.state()
            ledger = {e["law"]: e for e in st["ledger"]}
            self.assertEqual(ledger["L-20"]["nodes"], ["L_20_o1", "L_20_o2"])        # registered with its law
            coded_before = calls(w, "code")
            (f.root / "harness" / "checks").mkdir(parents=True, exist_ok=True)
            (f.root / "harness" / "checks" / "changed.py").write_text("# changed\n")
            w.admission["L_20_o1"] = "CHECK_FAIL"
            ready = []
            real = loop.label_ready
            with label_stage_stand_ins({"L-20", "L-21", "L-23"}), \
                    mock.patch.object(loop, "label_ready", lambda run, ledger: ready.append(real(run, ledger)) or ready[-1]):
                f.drive(1, label_stage=True, label_dataset="ds", max_iterations=5)
            st = f.state()
            run = Run(f.options()); run.restore_state(); run.load_accepted()
            led = Ledger(run.ledger_file, [], 2); run.law_entries = led.entries
        ledger = {e["law"]: e for e in st["ledger"]}
        self.assertEqual(ledger["L-20"]["nodes"], ["L_20_o1", "L_20_o2"])            # never filtered out of its law
        self.assertNotEqual(ledger["L-20"]["state"], "accepted")                      # never accepted on L_20_o2 alone
        self.assertEqual((ledger["L-20"]["state"], ledger["L-20"]["gaps"]), ("blocked", ["decision:L-20"]))
        self.assertTrue(all("L-20" not in r for r in ready), ready)                   # never label-ready
        self.assertNotEqual(ledger["L-23"]["state"], "accepted")                      # never composed for an acceptance
        self.assertEqual((ledger["L-23"]["gaps"], ledger["L-23"]["waits_on"]), (["decision:L-20"], ["L-20"]))
        self.assertEqual(calls(w, "code"), coded_before)                              # never coded again
        self.assertEqual(run.provider_code("L_20_o1", "L-23"), OPERATOR)
        self.assertNotIn("L_20_o1", run.usable_nodes("L-20"))
        self.assertIn("L_20_o1", st["fenced"])


if __name__ == "__main__":
    unittest.main()


class GenerationReport(unittest.TestCase):
    """T9: `summary.json` carries `generation`, computed again at every exit."""

    def summary(self) -> dict:
        return json.loads((paths.RESULTS / "r" / "summary.json").read_text())

    def test_complete_incomplete_and_unknown(self):
        w = chain_world()
        with Fixture(w, **SPLIT) as f:
            self.assertEqual(f.drive(1, label_deferred=True, max_iterations=1), ["incomplete"])        # (iii) the bound, work left
            g = self.summary()["generation"]
            self.assertEqual((g["complete"], g["stop"]["iteration_limit"]), (False, True))
            self.assertEqual(g["laws"]["generated"], ["L-40"])
            self.assertEqual(g["laws"]["generating"], ["L-41", "L-42"])                              # their own nodes come next
            self.assertEqual(f.drive(1, label_deferred=True, max_iterations=5), ["awaiting_labels"])  # (i) every law generated
            self.assertTrue(self.summary()["generation"]["complete"])
            with label_stage_stand_ins({"L-41", "L-42"}), mock.patch.object(loop, "label_route", lambda run, ledger, training, to_user:
                                                                              (ledger.fail("L-40", ["scripted: closed"]), {})[1]):
                status = f.drive(1, label_stage=True, label_dataset="ds", max_iterations=6)
            g = self.summary()["generation"]                                                         # (ii), (iv)
            self.assertEqual(status, ["awaiting_operator"])                                          # never `complete`
            self.assertFalse(g["complete"])
            self.assertEqual((g["laws"]["failed"], sorted(g["laws"]["blocked"])), (["L-40"], ["L-41", "L-42"]))
            self.assertEqual(g["provider_failures"], {"L-41": ["L-40"], "L-42": ["L-40"]})
            from harness.phases import feedback
            run = Run(f.options()); run.restore_state(); run.load_accepted()
            self.assertEqual(feedback.generation_report(run, Ledger(run.ledger_file, [], 2), "data_integrity_failure")["complete"], None)   # (v)

    def test_codes_are_the_same_on_a_cold_clone(self):
        """T8: every (node, law) code is the same at another root after a handoff."""
        from contextlib import ExitStack
        from harness.tools import handoff
        from scripts.tests.test_split_handoff import TOOLCHAIN, clone, options_at
        w = chain_world()
        with Fixture(w, **SPLIT) as f, ExitStack() as stack, mock.patch.object(handoff, "toolchain", lambda: TOOLCHAIN):
            self.assertEqual(f.drive(1, label_deferred=True, max_iterations=2), ["incomplete"])

            def codes(opts):
                run = Run(opts); run.restore_state(); run.load_accepted()
                run.law_entries = Ledger(run.ledger_file, [], 2).entries
                return {(n, l): run.provider_code(n, l) for n in ("L_40", "L_41", "L_42") for l in ("L-40", "L-41", "L-42")}
            before = codes(f.options())
            handoff.export("r", source_baseline="abc")
            new = clone(f, stack)
            self.assertEqual(codes(options_at(f, new)), before)
            self.assertIn(USABLE, before.values())


class CompositionCycle(unittest.TestCase):
    """T3: D → A → B → A, and C → B, planned together. The real cycle check names exactly the
    component {A, B}; their laws are held on their own decisions, uncharged, never coded; D and C, not
    members, are held on the roots' tokens (`decision:A`, `decision:B`), uncharged. Reopening B
    releases C, not D; reopening A then releases D. Every plan order gives the same result."""

    def plan(self, order):
        recs = {"L_A": node("L_A", "a.", "L-A", compositions=["L_B"]), "L_B": node("L_B", "b.", "L-B", compositions=["L_A"]),
                "L_D": node("L_D", "d.", "L-D", compositions=["L_A"]), "L_C": node("L_C", "c.", "L-C", compositions=["L_B"])}
        from harness.checks import validate_a
        from harness.model.blueprint import Node
        cyc = validate_a.acyclic({k: Node(v) for k, v in recs.items()})
        self.assertEqual([m for _r, m in cyc], [["L_A", "L_B"]])
        w = World({l: "x." for l in ("L-A", "L-B", "L-C", "L-D")})
        w.plans = {Node(recs[k]).law: [recs[k]] for k in order}
        for reason, members in cyc:
            for m in members:
                w.validate[(m, 1)] = ("return", [reason])
        return w

    def test_members_are_held_exactly_and_dependents_wait_on_their_roots(self):
        import itertools
        results = []
        for order in itertools.permutations(["L_A", "L_B", "L_C", "L_D"]):
            w = self.plan(order)
            with Fixture(w, max_iterations=3) as f:
                f.drive(1)
                led = {e["law"]: (e["state"], e["gaps"], e["waits_on"], e["attempts"]) for e in f.state()["ledger"]}
                results.append(led)
                self.assertEqual(calls(w, "code"), [])
                if order == ("L_A", "L_B", "L_C", "L_D"):
                    run = Run(f.options()); run.restore_state()
                    ledger = Ledger(run.ledger_file, [], 2)
                    ledger.reopen(["L-B"])
                    self.assertEqual({l: ledger.entries[l].state for l in ("L-B", "L-C", "L-D")}, {"L-B": "open", "L-C": "open", "L-D": "blocked"})
                    ledger.reopen(["L-A"])
                    self.assertEqual(ledger.entries["L-D"].state, "open")
        self.assertEqual(results[0], {"L-A": ("blocked", ["decision:L-A"], [], 0), "L-B": ("blocked", ["decision:L-B"], [], 0),
                                      "L-C": ("blocked", ["decision:L-B"], ["L-B"], 0), "L-D": ("blocked", ["decision:L-A"], ["L-A"], 0)})
        self.assertTrue(all(r == results[0] for r in results))
