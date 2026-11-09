"""A training run split between a generating machine and a label-checking machine.

- The remote stage (`--label_deferred`) reads no training recording: every training-data entry point
  raises if called, the concept review, the aggregate selection and the gate still run, a law whose
  nodes all pass the gate is kept `awaiting_labels`, and generation pauses when nothing runnable is
  left. A node of another law that composes a node of a law not yet formally accepted waits,
  uncharged, until that law is accepted; siblings inside a law are built in order; sharing an
  accepted concept makes no law wait; a cycle of such waits is held for the operator.
- The local stage (`--label_stage`) plans and codes nothing new; its label work keeps the loop going.
- Generation → labels → generation with the real work enumeration, waits and pause routing: a held
  node whose provider is blocked or failed is no work on either side and the run stops for the
  operator naming it (with an active repair's uncommitted wait); the run-wide repair count pauses on
  the budget, one law's spent attempts hold it for the operator; a second start runs nothing.
- A checkpoint exported at one root continues at another with the old root gone; a run is pinned to
  the code that decides its results; a repair through the real candidate transaction continues after
  the clone with its counts and comparison set.
- Without the split options the loop takes the path it took before.

The loop, ledgers, snapshot and scheduling are the real ones on the scripted world of
`test_recovery`; the label route is stood in for there (its real path is exercised by the clone of a
`test_label_repair_session` world)."""
import itertools
import json
import os
import shutil
import stat
import tempfile
import unittest
from contextlib import contextmanager
from pathlib import Path
from unittest import mock

from harness import loop
from harness.phases import label_check
from harness.phases import label_repair as lr
from harness.store import jsonl, paths
from harness.store.state import Options, Run
from harness.tools import handoff
from scripts.tests.test_recovery import PATH_NAMES, Fixture, World, concept, node

A, B, C = "L-20", "L-21", "L-22"
SPLIT = dict(label_repair=True, max_iterations=1)
TOOLCHAIN = {"python": "3", "lean": "stand-in", "distributions": "d"}


def split_world() -> World:
    """A has two independent siblings; B's node composes A's first; C is unrelated and shares the
    concept A's second sibling calls."""
    w = World({A: "shall slow. shall stop.", B: "shall wait.", C: "shall keep right."})
    a1, a2 = node("L_20_o1", "shall slow. shall stop.", A), node("L_20_o2", "shall slow. shall stop.", A, derived=["drv.motion.slow"])
    w.plans = {A: [concept("drv.motion.slow", users=["L_20_o2", "L_22"]), a1, a2],
               B: [node("L_21", "shall wait.", B, compositions=["L_20_o1"])],
               C: [node("L_22", "shall keep right.", C, derived=["drv.motion.slow"])]}
    return w


def accept_by_labels(laws):
    """The label route's stand-in on the label stage: each ready law in `laws` is accepted."""
    seen = []

    def route(run, ledger, training, to_user):
        ready = loop.label_ready(run, ledger)
        seen.append(sorted(ready))
        for law, nodes in ready.items():
            if law in laws:
                ledger.accept(law, nodes)
                run.label_states[law] = {"state": "accepted", "outcome": "aligned", "nodes": nodes, "repairs": 0}
        return {}
    return route, seen


def calls(w, kind):
    return sorted((i, it) for (k, i, it), n in w.calls.items() if k == kind for _ in range(n))


@contextmanager
def label_stage_stand_ins(laws):
    route, seen = accept_by_labels(laws)
    repairs = []
    with mock.patch.object(loop, "label_route", route), \
            mock.patch.object(label_check, "training_context", lambda *a, **k: object()), \
            mock.patch.object(lr, "run_repairs", lambda run, ledger, *a, **k: repairs.append(lr.awaiting(run, ledger)) or {}):
        yield seen, repairs


class Remote(unittest.TestCase):

    def test_remote_generation_waits_on_formal_acceptance_and_resumes_after_it(self):
        for batch in (8, 1):                                 # the same plan session, and separate ones
            with self.subTest(plan_batch=batch):
                w = split_world()
                with Fixture(w, plan_batch=batch, **SPLIT) as f:
                    self.assertEqual(f.drive(1, label_deferred=True), ["awaiting_labels"])
                    st = f.state()
                    ledger = {e["law"]: e for e in st["ledger"]}
                    self.assertEqual({k: ledger[k]["state"] for k in (A, B, C)}, {A: "planned", B: "planned", C: "planned"})
                    self.assertEqual(sorted(st["accepted_nodes"]), ["L_20_o1", "L_20_o2", "L_22"])   # siblings and C built
                    self.assertNotIn(("L_21", 1), calls(w, "code"))                                   # B waits on A's acceptance
                    self.assertEqual(ledger[B]["attempts"], 0)
                    self.assertEqual([d["node_id"] for d in st["deferred_nodes"]], ["L_21"])
                    self.assertIn(("drv.motion.slow", 1), calls(w, "review"))                         # the concept review ran
                    self.assertIn(("-", 1), calls(w, "aggregate_prepare"))                            # the aggregate selection ran
                    snap = json.loads((paths.RESULTS / "r" / "state.json").read_text())
                    self.assertEqual({k: v["state"] for k, v in snap["label_states"].items()}, {A: "awaiting_labels", C: "awaiting_labels"})
                    summary = json.loads((paths.RESULTS / "r" / "summary.json").read_text())
                    self.assertEqual(summary["pending"]["awaiting_labels"], [A, C])
                    self.assertEqual(summary["pending"]["generating"], [B])
                    self.assertEqual(snap["iteration"], 1)                                            # the pause spent no iteration

                    # the remote stage again before any label check: nothing runnable, no iteration, no session
                    before = dict(w.calls)
                    self.assertEqual(f.drive(1, label_deferred=True, max_iterations=5), ["awaiting_labels"])
                    self.assertEqual(dict(w.calls), before)
                    self.assertEqual(f.state()["iterations_allocated"], ["iter-001"])

                    # the local stage: A and C checked and accepted; B is not planned or coded there
                    with label_stage_stand_ins({A, C}) as (seen, _repairs):
                        self.assertEqual(f.drive(1, label_stage=True, label_dataset="ds", max_iterations=2), ["awaiting_generation"])
                    self.assertEqual(seen[0], [A, C])
                    self.assertEqual(dict(w.calls), before)

                    # back on the remote stage: B's held node is coded now, in a later iteration, never re-planned
                    self.assertEqual(f.drive(1, label_deferred=True, max_iterations=3), ["awaiting_labels"])
                    self.assertEqual([c for c in calls(w, "code") if c[0] == "L_21"], [("L_21", 3)])
                    self.assertEqual([c for c in calls(w, "plan")], [c for c in calls(w, "plan") if c[1] == 1])
                    ledger = {e["law"]: e for e in f.state()["ledger"]}
                    self.assertEqual((ledger[B]["state"], ledger[B]["attempts"]), ("planned", 0))   # the wait charged nothing
                    self.assertEqual(json.loads((paths.RESULTS / "r" / "state.json").read_text())["label_states"][B]["state"],
                                     "awaiting_labels")

    def test_training_entry_points_raise_while_deferred(self):
        def calls_training(*a, **k):
            label_check.training_context(Path("."), [], Path("."))
        w = split_world()
        with Fixture(w, **SPLIT) as f, mock.patch.object(loop, "defer_labels", calls_training):
            with self.assertRaises(label_check.LabelsDeferred):         # at the accept entry
                loop.run_loop(f.options(label_deferred=True))
        repairs = []
        w = split_world()
        with Fixture(w, **SPLIT) as f, mock.patch.object(lr, "run_repairs", lambda *a, **k: repairs.append(1)):
            f.drive(1, label_deferred=True)
        self.assertEqual(repairs, [])                                   # the end-of-iteration repair entry is not reached
        with label_check.deferred("test"):
            for fn, args in ((label_check.training_context, (Path("."), [], Path("."))),
                             (label_check.run_rule, (Path("m"), {}, "r", Path("x"), label_check.Limits())),
                             (label_check.run_explain, (Path("e"), {}, "r", {}, Path("x"), label_check.Limits())),
                             (label_check.check_law, ("l", [], {}, None, Path("m"), None, Path("x"))),
                             (label_check.check_in_candidate, (None, None, {}, {}, Path("o")))):
                with self.assertRaises(label_check.LabelsDeferred, msg=fn.__name__):
                    fn(*args)

    def test_options_of_a_split_stage(self):
        base = dict(run_id="r", laws=Path("l"), ontology=Path("o"), reading=Path("x"), label_repair=True)
        for over, msg in (({"label_deferred": True, "label_dataset": "d"}, "reads no training recording"),
                          ({"label_deferred": True, "base_run": "b"}, "base_run"),
                          ({"label_stage": True, "label_dataset": "d", "budget_peers": ["p"]}, "budget_peers"),
                          ({"label_stage": True, "label_deferred": True}, "give one"),
                          ({"label_deferred": True, "label_repair": False}, "with --label_repair")):
            with self.subTest(over=over), self.assertRaisesRegex(SystemExit, msg):
                loop.check_options(Options(**{**base, **over}))
        loop.check_options(Options(**base, label_deferred=True))           # no dataset needed

    def test_an_acceptance_cycle_is_held_for_the_operator(self):
        w = World({"L-30": "a. b.", "L-31": "c. d."})
        w.plans = {"L-30": [node("L_30_o1", "a. b.", "L-30"), node("L_30_o2", "a. b.", "L-30", compositions=["L_31_o1"])],
                   "L-31": [node("L_31_o1", "c. d.", "L-31"), node("L_31_o2", "c. d.", "L-31", compositions=["L_30_o1"])]}
        with Fixture(w, **SPLIT) as f:
            status = f.drive(1, label_deferred=True, max_iterations=4)
            st = f.state()
            ledger = {e["law"]: e for e in st["ledger"]}
            self.assertEqual({k: (v["state"], v["gaps"], v["attempts"]) for k, v in ledger.items()},
                             {"L-30": ("blocked", ["decision:L-30"], 0), "L-31": ("blocked", ["decision:L-31"], 0)})
            self.assertEqual(st["iterations_allocated"], ["iter-001"])               # nothing retried
            self.assertEqual(status, ["complete"])                                    # every law is terminal: held for the operator
            self.assertTrue(any("acceptance cycle" in x for x in json.loads((paths.RESULTS / "r" / "state.json").read_text())["pending_notices"]))

    def test_a_text_reference_keeps_the_conservative_wait(self):
        """B's text names A. B's first plan is returned; while A awaits its labels B is not planned again."""
        w = World({A: "shall slow.", B: f"as in {A}, shall wait."})
        w.plans = {A: [node("L_20", "shall slow.", A)], B: [node("L_21", f"as in {A}, shall wait.", B)]}
        w.validate[("L_21", 1)] = ("return", ["scripted plan defect"])
        with Fixture(w, **SPLIT) as f, mock.patch("harness.model.corpus.references",
                                                  lambda law, ids: {A} if law.id == B else set()):
            self.assertEqual(f.drive(1, label_deferred=True, max_iterations=4), ["awaiting_labels"])
            self.assertEqual(calls(w, "plan"), [(f"{A},{B}", 1)])                    # not planned again while A awaits labels
            ledger = {e["law"]: e for e in f.state()["ledger"]}
            self.assertEqual((ledger[B]["state"], ledger[B]["attempts"]), ("returned", 1))
            self.assertEqual(f.state()["iterations_allocated"], ["iter-001"])


class Unsplit(unittest.TestCase):

    def test_without_the_split_a_composed_node_is_used_on_its_acceptance(self):
        w = split_world()
        with Fixture(w, max_iterations=3) as f:
            self.assertEqual(f.drive(1), ["complete"])
            self.assertIn(("L_21", 1), calls(w, "code"))
            self.assertEqual({e["law"]: e["state"] for e in f.state()["ledger"]}, {A: "accepted", B: "accepted", C: "accepted"})

    def test_the_usable_nodes_rule(self):
        w = split_world()
        with Fixture(w, **SPLIT) as f:
            f.drive(1, label_deferred=True)
            run = Run(f.options(label_deferred=True))
            run.restore_state(); run.load_accepted()
            self.assertEqual(sorted(run.usable_nodes(A)), ["L_20_o1", "L_20_o2"])     # its own law's only: C awaits its labels too
            self.assertEqual(sorted(run.usable_nodes(B)), [])
            unsplit = Run(f.options(label_repair=False))
            unsplit.restore_state(); unsplit.load_accepted()
            self.assertEqual(sorted(unsplit.usable_nodes(B)), ["L_20_o1", "L_20_o2", "L_22"])


class CrossLawRepair(unittest.TestCase):
    """A local label repair is held to the availability rule a remote generation follows: a change
    that composes a node of a law not yet formally accepted waits, uncharged and with no coder, until
    that law is accepted; the candidate's own checks refuse such a change however it was written."""

    @contextmanager
    def split_repairing(self, rec, calls=None):
        from dataclasses import replace
        from scripts.tests.test_label_repair_session import repairing
        from harness.phases import candidate as cand
        from scripts.tests.test_label_repair import L, N
        L3, N3 = L[3], N[3]
        cand._OPEN.clear()
        from harness.agents import session
        from scripts.tests.test_label_repair_session import stub_session
        stub = stub_session({"record.jsonl": json.dumps(rec)}, calls)

        def recorded(prompt, cwd=None, out_dir=None, label="session", **k):     # a session that records its launch, as the real one does
            stub(prompt, cwd=cwd, out_dir=out_dir, label=label, **k)
            (Path(out_dir or cwd) / f"{label}_result.json").write_text("{}")
        with repairing(outputs={"record.jsonl": json.dumps(rec)}, calls=calls) as (run, ledger, training, by_id), \
                mock.patch.object(session, "run", recorded):
            run.opts = replace(run.opts, label_repair=True)
            run.law_entries = ledger.entries
            ledger.entries[L3].state = "planned"                      # generated remotely, awaiting its labels
            run.label_states[L3] = {"state": "awaiting_labels", "nodes": [N3], "repairs": 0}
            yield run, ledger, training, by_id
        cand._OPEN.clear()

    def test_remote_waits_then_a_local_repair_composes_a_law_not_yet_accepted(self):
        from scripts.tests.test_candidate import node_rec
        from scripts.tests.test_label_repair import L, N
        from scripts.tests.test_label_repair_session import repair
        rec = {k: v for k, v in node_rec(N[5]).items() if k != "segmentation"}
        rec["compositions"] = [{"span": "o1", "rule": N[3], "as": "condition"}]          # L-3 is generated, its law still planned
        coded, calls = [], []
        with self.split_repairing(rec, calls) as (run, ledger, training, by_id), \
                mock.patch.object(lr, "code_in_candidate", lambda txn, recs, law=None, earlier=None: coded.append(recs) or {}):
            self.assertEqual(ledger.entries[L[3]].state, "planned")
            self.assertNotIn(N[3], run.usable_nodes(L[5]))
            to_user = []
            self.assertEqual(repair(run, ledger, training, by_id, to_user), "waiting")
            st = run.label_states[L[5]]
            self.assertEqual(coded, [])                                                   # no coder
            self.assertEqual((st.get("repairs", 0), st.get("sessions", 0)), (0, 0))      # nothing charged
            self.assertEqual(st["active"]["waits"], [L[3]])
            self.assertTrue(any("waits" in x and L[3] in x for x in to_user), to_user)
            self.assertNotIn(L[5], loop.label_work(run, run.opts, ledger))               # no work while it waits
            self.assertNotIn(L[5], lr.awaiting(run, ledger))
            asked = [c for c in calls if c[1].startswith("session")]
            self.assertEqual(lr.wait_states(run, ledger, L[5]), {L[3]: "planned"})          # an ordinary pending law
            ledger.block(L[3], [f"decision:{L[3]}"], ["held for the operator"])
            self.assertEqual(lr.wait_states(run, ledger, L[5]), {L[3]: "blocked"})          # told apart, for the operator
            self.assertEqual(lr.waits_on(run, ledger, L[5]), [L[3]])                        # still a wait
            ledger.entries[L[3]].state = "planned"
            ledger.accept(L[3], [N[3]])                                                   # the law it composes is accepted
            self.assertIn(L[5], loop.label_work(run, run.opts, ledger))
            self.assertNotEqual(repair(run, ledger, training, by_id), "waiting")
            self.assertEqual(coded, [[("node", N[5])]])                                   # coded now
            self.assertEqual([c for c in calls if c[1].startswith("session")], asked)    # on the same session's answer

    def test_the_candidate_refuses_a_cross_law_composition_written_directly(self):
        from harness.phases import candidate as cand
        from scripts.tests.test_candidate import Txn, files, node_rec
        from scripts.tests.test_label_repair import L, N
        for target, refused in ((N[3], True), (N[1], False)):                          # L-3 planned; L-1 accepted
            with self.subTest(composes=target):
                rec = {**node_rec(N[5]), "compositions": [{"span": "o1", "rule": target, "as": "condition"}]}
                with self.split_repairing(rec) as (run, ledger, _training, _by_id):
                    self.assertEqual(ledger.entries[L[1]].state, "accepted")
                    with Txn(run) as txn:
                        txn.apply([cand.Change("node", N[5], rec, files("node", N[5], "v2"))])     # Lean written directly, no coder
                        results = txn.verify()
                        avail = [r for r in results if r.check == "availability"]
                        if refused:
                            self.assertEqual([(r.subject, r.status) for r in avail], [(N[5], "fail")])
                            self.assertIn(N[3], avail[0].details[0])
                            self.assertFalse(any(r.check == "gate" and r.subject == N[5] and r.status == "pass" for r in results))
                        else:
                            self.assertEqual(avail, [])
                        txn.rollback("test")


class TwoStage(unittest.TestCase):
    """Generation → labels → generation on a temporary run, with the real work enumeration
    (`runnable_work`, `label_work`), the real wait computation (`Run.usable_nodes`, `label_repair.awaiting`,
    `wait_states`), the real repair scheduling (`label_repair.run_repairs`) and the real pause routing
    (`pause_reason`). Stood in for: the model sessions and gate (the scripted world), the label check's
    monitor run (`label_route` routes each ready law as scripted, through the ledger's own operations)
    and the inside of one repair (`label_repair.repair_law`: what its session, candidate and coder leave).
    A provider not accepted keeps its dependents waiting; a planned provider hands the run to the stage
    that has its work; a blocked or failed one leaves its dependents no work on either side, and the run
    stops for the operator naming them; a second start from the same pause runs nothing."""

    D = "L-23"

    def world(self, independent: bool = False) -> World:
        w = split_world()
        if independent:                                   # D composes C's node: independent of A
            w.laws[self.D] = "shall yield."
            w.plans[self.D] = [node("L_23", "shall yield.", self.D, compositions=["L_22"])]
        return w

    @staticmethod
    def route(outcomes: dict):
        """Each ready law routed as `outcomes` says: accepted, failed (closed), blocked (held for the
        operator) or `("mismatch", repairs)` (awaiting its label repair, that many already spent)."""
        def route(run, ledger, training, to_user):
            for law, nodes in loop.label_ready(run, ledger).items():
                o = outcomes.get(law)
                if o is None:
                    continue
                kind, repairs = o if isinstance(o, tuple) else (o, 0)
                st = {"nodes": nodes, "repairs": repairs}
                if kind == "accepted":
                    ledger.accept(law, nodes); st.update(state="accepted", outcome="aligned")
                elif kind == "failed":
                    ledger.fail(law, ["scripted: closed"]); st.update(state="failed", outcome="failed")
                elif kind == "blocked":
                    ledger.block(law, [f"decision:{law}"], ["scripted: held"]); st.update(state="failed", outcome="failed")
                else:
                    ledger.hold(law, run.iteration); st.update(state="awaiting_label_repair", outcome="mismatch")
                run.label_states[law] = st
            return {}
        return route

    @contextmanager
    def label_stage(self, outcomes: dict, repair=None):
        sessions = []

        def repair_law(run, ledger, training, law, *a, **k):
            sessions.append(law.id)
            return (repair or (lambda run, ledger, law: "unavailable"))(run, ledger, law.id)
        with mock.patch.object(loop, "label_route", self.route(outcomes)), \
                mock.patch.object(label_check, "training_context", lambda *a, **k: object()), \
                mock.patch.object(lr, "repair_law", repair_law):
            yield sessions

    def stage(self, f, label: bool, k: int, **over) -> tuple[str, str]:
        mode = dict(label_stage=True, label_dataset="ds") if label else dict(label_deferred=True)
        out = f.drive(1, max_iterations=k, **mode, **over)
        s = json.loads((paths.RESULTS / "r" / "summary.json").read_text())
        self.assertEqual(out, [s["status"]])
        return s["status"], s["stop_reason"]

    def assert_paused_again(self, f, w, sessions, status: str, k: int, **over):
        """The same paused checkpoint started again, on both stages: the same status, no session, no
        attempt, no iteration."""
        before = (dict(w.calls), list(sessions), f.state()["iterations_allocated"], [(e["law"], e["attempts"]) for e in f.state()["ledger"]])
        for label in (True, False):
            self.assertEqual(self.stage(f, label, k + 3, **over)[0], status)
        after = (dict(w.calls), list(sessions), f.state()["iterations_allocated"], [(e["law"], e["attempts"]) for e in f.state()["ledger"]])
        self.assertEqual(after, before)

    def generated(self, f, w):
        self.assertEqual(self.stage(f, False, 1)[0], "awaiting_labels")
        self.assertEqual([d["node_id"] for d in f.state()["deferred_nodes"]], ["L_21"])     # B waits on A, planned
        self.assertEqual(self.stage(f, False, 4)[0], "awaiting_labels")                    # a provider awaiting labels: hand over
        self.assertEqual(f.state()["iterations_allocated"], ["iter-001"])

    def test_normal_release(self):
        w = self.world()
        with Fixture(w, **SPLIT) as f:
            self.generated(f, w)
            with self.label_stage({A: "accepted", C: "accepted"}):
                self.assertEqual(self.stage(f, True, 2)[0], "awaiting_generation")
            self.assertEqual(self.stage(f, False, 3)[0], "awaiting_labels")
            self.assertEqual([c for c in calls(w, "code") if c[0] == "L_21"], [("L_21", 3)])
            with self.label_stage({B: "accepted"}):
                self.assertEqual(self.stage(f, True, 4)[0], "complete")

    def test_a_failed_or_blocked_provider_awaits_the_operator(self):
        for closed in ("failed", "blocked"):
            with self.subTest(provider=closed):
                w = self.world()
                with Fixture(w, **SPLIT) as f:
                    self.generated(f, w)
                    with self.label_stage({A: closed, C: "accepted"}) as sessions:
                        status, reason = self.stage(f, True, 2)
                        self.assertEqual(status, "awaiting_operator", reason)
                        self.assertIn(f"`{B}` waits on `{A}` ({closed})", reason)
                        status, reason = self.stage(f, False, 3)
                        self.assertEqual(status, "awaiting_operator", reason)
                        self.assertIn(f"`{B}` waits on `{A}` ({closed})", reason)
                        self.assert_paused_again(f, w, sessions, "awaiting_operator", 3)
                    ledger = {e["law"]: e for e in f.state()["ledger"]}
                    self.assertEqual((ledger[B]["state"], ledger[B]["attempts"]), ("planned", 0))   # the wait is not released
                    self.assertNotIn("L_21", [c[0] for c in calls(w, "code")])

    def test_the_run_wide_repair_count_spent_pauses_on_the_budget(self):
        w = self.world()
        opts = dict(label_repair_budget=1, label_repair_attempts=2)
        with Fixture(w, **SPLIT) as f:
            self.generated(f, w)
            with self.label_stage({A: ("mismatch", 1), C: "accepted"}) as sessions:
                for label in (True, False):
                    status, reason = self.stage(f, label, 2, **opts)
                    self.assertEqual(status, "paused_budget", reason)
                    for words in ("--label_repair_budget", "used 1 of its limit 1", f"['{A}']"):
                        self.assertIn(words, reason)
                self.assertEqual(sessions, [])                                  # no repair session
                self.assert_paused_again(f, w, sessions, "paused_budget", 2, **opts)
            ledger = {e["law"]: e["state"] for e in f.state()["ledger"]}
            self.assertEqual(ledger[A], "planned")

    def test_one_laws_attempts_spent_is_held_for_the_operator_never_a_budget_pause(self):
        w = self.world()
        opts = dict(label_repair_budget=10, label_repair_attempts=2)
        with Fixture(w, **SPLIT) as f:
            self.generated(f, w)
            with self.label_stage({A: ("mismatch", 2), C: "accepted"}) as sessions:
                status, reason = self.stage(f, True, 2, **opts)
                self.assertEqual(status, "awaiting_operator", reason)
                self.assertIn(f"`{B}` waits on `{A}` (blocked)", reason)
                self.assertEqual(sessions, [])                                  # no session for a law whose attempts are spent
                st = json.loads((paths.RESULTS / "r" / "state.json").read_text())
                ledger = {e["law"]: e for e in st["ledger"]}
                self.assertEqual((ledger[A]["state"], ledger[A]["gaps"]), ("blocked", [f"decision:{A}"]))
                self.assertNotEqual(st["label_states"][A].get("outcome"), "aligned")
                self.assertEqual(st["label_states"][A]["repairs"], 2)            # no limit raised, nothing charged
                self.assertEqual(self.stage(f, False, 3, **opts)[0], "awaiting_operator")
                self.assert_paused_again(f, w, sessions, "awaiting_operator", 3, **opts)

    def test_a_pending_repair_is_taken_up_by_the_next_launch(self):
        w = self.world()
        seen = []

        def repair(run, ledger, law):
            st = run.label_states[law]
            seen.append(dict(st.get("active") or {}))
            if not st.get("active"):                     # the session answered, the toolchain did not: kept, uncharged
                st["active"] = {"stage": "coding", "candidate": "iter-002/candidate/c1"}
                return "unavailable"
            st.pop("active")                              # taken up from the same answer: committed and aligned
            ledger.accept(law, st["nodes"])
            st.update(state="accepted", outcome="aligned", repairs=int(st.get("repairs", 0)) + 1)
            return "committed"
        with Fixture(w, **SPLIT) as f:
            self.generated(f, w)
            with self.label_stage({A: ("mismatch", 0), C: "accepted"}, repair) as sessions:
                status, _reason = self.stage(f, True, 2)
                self.assertEqual(status, "incomplete")           # its iteration bound, work left: the next launch takes it up
                self.assertEqual(json.loads((paths.RESULTS / "r" / "summary.json").read_text())["stop"], "iteration_limit")
                self.assertEqual(self.stage(f, True, 3)[0], "awaiting_generation")
            self.assertEqual(seen, [{}, {"stage": "coding", "candidate": "iter-002/candidate/c1"}])
            st = json.loads((paths.RESULTS / "r" / "state.json").read_text())["label_states"][A]
            self.assertEqual((st["state"], st["repairs"]), ("accepted", 1))
            self.assertEqual(self.stage(f, False, 4)[0], "awaiting_labels")
            self.assertIn(("L_21", 4), calls(w, "code"))

    def test_a_lost_hints_snapshot_stops_either_stage_without_a_session(self):
        w = self.world()
        with Fixture(w, **SPLIT) as f:
            self.generated(f, w)
            (paths.RESULTS / "r" / "user_hints.json").unlink()
            before = dict(w.calls)
            with self.label_stage({A: "accepted", C: "accepted"}) as sessions:
                for label in (True, False):
                    status, reason = self.stage(f, label, 2)
                    self.assertEqual(status, "data_integrity_failure")
                    self.assertIn("user_hints.json", reason)
            self.assertEqual((dict(w.calls), sessions, f.state()["iterations_allocated"]), (before, [], ["iter-001"]))

    def test_a_failed_dependency_leaves_an_independent_law_running(self):
        w = self.world(independent=True)
        with Fixture(w, **SPLIT) as f:
            self.assertEqual(self.stage(f, False, 1)[0], "awaiting_labels")
            self.assertEqual(sorted(d["node_id"] for d in f.state()["deferred_nodes"]), ["L_21", "L_23"])
            with self.label_stage({A: "failed", C: "accepted"}):
                status, reason = self.stage(f, True, 2)
                self.assertEqual(status, "awaiting_generation", reason)
                self.assertIn("L_23", reason)
                self.assertNotIn("L_21", reason)                                  # B's held node is no work
            self.assertEqual(self.stage(f, False, 3)[0], "awaiting_labels")
            coded = [c for c in calls(w, "code") if c[0] in ("L_21", "L_23")]
            self.assertEqual(coded, [("L_23", 3)])                               # D coded; B never
            ledger = {e["law"]: e for e in f.state()["ledger"]}
            # the iteration D ran met B's held node and kept it, uncoded and uncharged, with B planned
            self.assertEqual((ledger[B]["state"], ledger[B]["gaps"], ledger[B]["attempts"]), ("planned", [], 0))
            self.assertIn("L_21", [d["node_id"] for d in f.state()["deferred_nodes"]])
            with self.label_stage({self.D: "accepted"}):
                status, reason = self.stage(f, True, 4)
            self.assertEqual(status, "awaiting_operator", reason)
            self.assertIn(f"`{B}` waits on `{A}` (failed)", reason)
            self.assertNotIn("L_21", [c[0] for c in calls(w, "code")])

    def test_an_uncommitted_dependency_of_an_active_repair_is_in_the_stop_reason(self):
        """C's repair candidate composed a node of A (never committed: no record of C composes A). A is then
        closed: C's repair keeps waiting, and the stop names C's wait with A's state."""
        w = self.world()

        def repair(run, ledger, law):                     # what `repair_law` leaves on `Waiting`: no coder, nothing charged
            run.label_states[law]["active"] = {"stage": "session", "waits": [A]}
            return "waiting"
        with Fixture(w, **SPLIT) as f:
            self.generated(f, w)
            with self.label_stage({A: "failed", C: ("mismatch", 0)}, repair) as sessions:
                status, reason = self.stage(f, True, 2)
                self.assertEqual(status, "awaiting_operator", reason)
                self.assertIn(f"`{C}` waits on `{A}` (failed)", reason)
                self.assertIn(f"`{B}` waits on `{A}` (failed)", reason)
                self.assertEqual(sessions, [C])
                st = json.loads((paths.RESULTS / "r" / "state.json").read_text())
                self.assertFalse(any("L_20" in str(c.get("rule")) for r in st["accepted_nodes"].values() if r["law_refs"] == [C]
                                     for c in r.get("compositions", [])))
                self.assertEqual(st["label_states"][C].get("repairs", 0), 0)
                self.assert_paused_again(f, w, sessions, "awaiting_operator", 2)


class DependencyWaitOutcome(unittest.TestCase):
    """In a split run, a law whose held node composes a node of a blocked or failed law waits the same
    way whether or not other laws have work: it stays planned with its held node and its attempts, the
    run stops `awaiting_operator` naming the wait, and reopening the provider plans and codes the same
    work. Without the split, the dependent is held for the operator on its provider, and the loop ends."""

    B2 = "L-24"                                           # composes B's node: a second level

    def world(self, independent: bool, chain: bool) -> World:
        w = TwoStage().world(independent=independent)
        if chain:
            w.laws[self.B2] = "shall pause."
            w.plans[self.B2] = [node("L_24", "shall pause.", self.B2, compositions=["L_21"])]
        return w

    def run_to_pause(self, closed: str, independent: bool, chain: bool) -> dict:
        t = TwoStage()
        w = self.world(independent, chain)
        with Fixture(w, **SPLIT) as f, mock.patch("harness.store.owner.acquire_for_command", lambda name: None):
            self.assertEqual(t.stage(f, False, 1)[0], "awaiting_labels")
            with t.label_stage({A: closed, C: "accepted", TwoStage.D: "accepted"}):
                k, label = 2, True
                while True:                                # each stage while the other hands it work
                    status, reason = t.stage(f, label, k)
                    if status not in ("awaiting_labels", "awaiting_generation"):
                        break
                    k, label = k + 1, not label
                    self.assertLess(k, 8)
            st = f.state()
            ledger = {e["law"]: e for e in st["ledger"]}
            dependents = [B] + ([self.B2] if chain else [])
            out = {"status": status, "reason": reason,
                   "dependents": {l: (ledger[l]["state"], ledger[l]["attempts"], ledger[l]["gaps"]) for l in dependents},
                   "held": sorted(d["node_id"] for d in st["deferred_nodes"])}
            self.assertEqual(t.stage(f, not label, k + 1)[0], status)       # the other stage stops the same way
            from harness.__main__ import Cli
            Cli().reopen("r", laws=A)
            first = {it for _i, it in calls(w, "plan")} | {it for _i, it in calls(w, "code")}
            t.stage(f, False, k + 2)
            out["after_reopen"] = {"plan": sorted(i for i, it in calls(w, "plan") if it not in first),
                                   "code": sorted(i for i, it in calls(w, "code") if it not in first),
                                   "dependents": {l: {e["law"]: e for e in f.state()["ledger"]}[l]["state"] for l in dependents},
                                   "held": sorted(d["node_id"] for d in f.state()["deferred_nodes"])}
            out["dependents_coded"] = [c for c in calls(w, "code") if c[0] in ("L_21", "L_24")]
        return out

    def test_the_same_wait_with_and_without_independent_work(self):
        for closed in ("failed", "blocked"):
            for chain in (False, True):
                with self.subTest(provider=closed, chain=chain):
                    alone, beside = self.run_to_pause(closed, False, chain), self.run_to_pause(closed, True, chain)
                    self.assertEqual(alone["status"], "awaiting_operator", alone["reason"])
                    self.assertIn(f"`{B}` waits on `{A}` ({closed})", alone["reason"])
                    if chain:
                        self.assertIn(f"`{self.B2}` waits on `{B}` (planned)", alone["reason"])
                    self.assertEqual(alone["dependents"], {l: ("planned", 0, []) for l in alone["dependents"]})
                    self.assertEqual(alone["held"], ["L_21"] + (["L_24"] if chain else []))
                    self.assertEqual(alone["dependents_coded"], [])
                    for k in ("status", "reason", "dependents", "held", "after_reopen", "dependents_coded"):
                        self.assertEqual(beside[k], alone[k], k)
                    self.assertEqual(alone["after_reopen"]["plan"], [A])                # the provider alone is planned again
                    self.assertEqual(alone["after_reopen"]["held"], alone["held"])      # the dependents keep their plans

    def test_without_the_split_the_dependent_is_held_for_the_operator_and_the_loop_ends(self):
        for closed in ("failed", "blocked"):
            with self.subTest(provider=closed):
                w = self.world(False, True)
                with Fixture(w, label_repair=True, max_iterations=8) as f, \
                        mock.patch.object(loop, "label_route", TwoStage.route({A: closed, C: "accepted"})), \
                        mock.patch.object(label_check, "training_context", lambda *a, **k: object()):
                    self.assertEqual(f.drive(1, label_dataset="ds"), ["complete"])
                    ledger = {e["law"]: e for e in f.state()["ledger"]}
                    self.assertEqual((ledger[B]["state"], ledger[B]["attempts"]), ("blocked", 0))
                    self.assertEqual(ledger[self.B2]["state"], "blocked")
                    self.assertLessEqual(len(f.state()["iterations_allocated"]), 3)      # no iteration spent waiting
                    self.assertFalse([c for c in calls(w, "code") if c[0] in ("L_21", "L_24")])


class RunMetadata(unittest.TestCase):
    """A run id is new only when `results/<run>` is absent or holds no entry at all. An existing run is
    resumed only on readable, whole options (its contract) and a readable snapshot, which may be missing
    only while nothing past its initialisation was written. Otherwise the launch is refused at
    `run_loop` (so through the CLI too) before anything is written, and the run is never initialised
    again over what it left."""

    def tree(self) -> dict:
        rd = paths.RESULTS / "r"
        return {str(p.relative_to(rd)): p.read_bytes() for p in sorted(rd.rglob("*")) if p.is_file()}

    def refused(self, f, w, words: str):
        from harness.__main__ import Cli
        before = (self.tree(), dict(w.calls))
        for launch in (lambda: loop.run_loop(f.options(max_iterations=3, label_repair=False)),
                       lambda: Cli().loop("r", max_iterations=3, label_repair=False, laws=str(f.root / "corpus" / "laws.jsonl"),
                                          ontology_file=str(f.root / "ontology.md"), reading=str(f.root / "reading.json"),
                                          model="claude-test", reviewer_model="gpt-test", aggregate_verifier_model="gpt-test",
                                          workers=1, definition_precedence=str(f.root / "precedence.json")),
                       lambda: loop.run_loop(f.options(label_deferred=True, max_iterations=3))):
            with self.assertRaises(SystemExit) as e:
                launch()
            self.assertIn(words, str(e.exception))
            self.assertIn("nothing of this run was rewritten", str(e.exception))
            self.assertEqual((self.tree(), dict(w.calls)), before)

    def started(self, f, handed=False):
        self.assertEqual(f.drive(1, label_deferred=True), ["awaiting_labels"])
        if handed:
            handoff.export("r", source_baseline="c0ffee")

    def test_missing_options_is_refused_with_and_without_a_handoff(self):
        for handed in (False, True):
            with self.subTest(handoff=handed):
                w = split_world()
                with Fixture(w, **SPLIT) as f, mock.patch.object(handoff, "toolchain", lambda: TOOLCHAIN), \
                        mock.patch("harness.store.owner.acquire_for_command", lambda name: None):
                    self.started(f, handed)
                    (paths.RESULTS / "r" / "options.json").unlink()
                    self.refused(f, w, "options.json")
                    self.assertTrue(all(e["state"] == "planned" for e in f.state()["ledger"]))

    def test_unreadable_or_incomplete_options_is_refused(self):
        for text in ("{not json", json.dumps({"run_id": "r"})):
            with self.subTest(options=text[:12]):
                w = split_world()
                with Fixture(w, **SPLIT) as f:
                    self.started(f)
                    (paths.RESULTS / "r" / "options.json").write_text(text)
                    self.refused(f, w, "options.json")

    def test_missing_snapshot_is_refused(self):
        w = split_world()
        with Fixture(w, **SPLIT) as f:
            self.started(f)
            (paths.RESULTS / "r" / "state.json").unlink()
            self.refused(f, w, "state.json is missing")

    def test_both_missing_with_other_run_files_is_refused(self):
        w = split_world()
        with Fixture(w, **SPLIT) as f:
            self.started(f)
            (paths.RESULTS / "r" / "state.json").unlink()
            (paths.RESULTS / "r" / "options.json").unlink()
            self.refused(f, w, "options.json")

    def test_the_boundary_of_a_new_run(self):
        """An empty directory, or one holding only the law subset (`laws/laws.jsonl`,
        `laws/definitions.jsonl`), is a new run; one holding anything else is not, whatever it is."""
        from scripts.subset_laws import subset
        for extra in (None, "notes.txt", "laws/notes.txt"):
            for with_subset in (False, True):
                with self.subTest(extra=extra, subset=with_subset):
                    w = split_world()
                    with Fixture(w, **SPLIT) as f:
                        (paths.RESULTS / "r").mkdir(parents=True)
                        if with_subset:
                            f.opt["laws"] = subset("r", f.root / "corpus" / "laws.jsonl", [A, B, C])
                        if extra is None:
                            self.assertEqual(f.drive(1, label_deferred=True), ["awaiting_labels"])
                        else:
                            (paths.RESULTS / "r" / extra).parent.mkdir(parents=True, exist_ok=True)
                            (paths.RESULTS / "r" / extra).write_text("x")
                            self.refused(f, w, "options.json")

    def test_a_launch_cut_short_before_its_first_snapshot_is_taken_up_under_its_contract(self):
        w = split_world()
        with Fixture(w, **SPLIT) as f:
            with mock.patch.object(loop, "doctor_ok", mock.Mock(side_effect=SystemExit("doctor down"))), self.assertRaises(SystemExit):
                loop.run_loop(f.options(label_deferred=True))
            self.assertTrue((paths.RESULTS / "r" / "options.json").exists())
            self.assertFalse((paths.RESULTS / "r" / "state.json").exists())
            before = self.tree()
            with self.assertRaises(SystemExit) as e:                    # never with another policy
                loop.run_loop(f.options(label_repair=False))
            self.assertEqual(self.tree(), before)
            self.assertIn("acceptance policy is fixed", str(e.exception))
            self.assertEqual(f.drive(1, label_deferred=True), ["awaiting_labels"])


class SavedPolicyWhole(unittest.TestCase):
    """A run's saved options hold its whole acceptance policy explicitly, with legal values: a field
    missing, of the wrong type or not legal refuses the launch (through `run_loop` and the CLI) before
    anything is written; it is never filled by a default. A handoff's recorded policy is held to the same."""

    tree, started = RunMetadata.tree, RunMetadata.started

    def refused(self, f, w, words: str):
        """Refused through `run_loop` (with the metadata refusal) and through the CLI, nothing written."""
        from harness.__main__ import Cli
        before = (self.tree(), dict(w.calls))
        with self.assertRaises(SystemExit) as e:
            loop.run_loop(f.options(max_iterations=3, label_repair=False))
        self.assertIn("no whole acceptance policy", str(e.exception))
        self.assertIn("nothing of this run was rewritten", str(e.exception))
        with self.assertRaises(SystemExit):
            Cli().loop("r", max_iterations=3, label_repair=False)
        self.assertEqual((self.tree(), dict(w.calls)), before)

    def test_a_saved_policy_field_missing_or_not_legal_is_refused(self):
        for change in ({"drop": "label_repair"}, {"label_repair": "true"}, {"label_repair": 1}, {"label_repair": None}):
            with self.subTest(change=change):
                w = split_world()
                with Fixture(w, **SPLIT) as f:
                    self.started(f)
                    o = paths.RESULTS / "r" / "options.json"
                    d = json.loads(o.read_text())
                    if "drop" in change:
                        d.pop(change["drop"])
                    else:
                        d.update(change)
                    o.write_text(json.dumps(d))
                    self.refused(f, w, "")
                    self.assertTrue(all(e["state"] == "planned" for e in f.state()["ledger"]))

    def test_a_handoff_anchor_not_whole_is_refused(self):
        w = split_world()
        with Fixture(w, **SPLIT) as f, mock.patch.object(handoff, "toolchain", lambda: TOOLCHAIN), \
                mock.patch("harness.store.owner.acquire_for_command", lambda name: None):
            self.started(f, handed=True)
            mf = paths.RESULTS / "r" / "handoff" / "manifest.json"
            m = json.loads(mf.read_text())
            for anchor in ({"feedback": "labels"}, {"label_repair": "yes"}):   # a version-2 anchor without label_repair, a wrong type
                with self.subTest(anchor=anchor):
                    mf.write_text(json.dumps({**m, "acceptance_policy": anchor}))
                    self.assertTrue(any("acceptance policy is not whole" in x for x in handoff.verify("r")[0]))


class SnapshotWhole(unittest.TestCase):
    """A resume restores a snapshot only when it holds every field a resume reads, with its type, the
    run's schema and the run's own id: an empty or partial one refuses before anything is written,
    never read as empty state. A complete snapshot whose collections are empty (a run's first commit)
    is whole and resumes."""

    tree, refused, started = RunMetadata.tree, RunMetadata.refused, RunMetadata.started

    @staticmethod
    def empty(run_id: str = "r") -> dict:
        from harness.store.state import SNAPSHOT_FIELDS
        out = {k: t() for k, t in SNAPSHOT_FIELDS.items()}
        out.update(schema=1, run_id=run_id, iteration=0)
        return out

    def test_a_partial_snapshot_is_refused(self):
        full = self.empty()
        for name, snap in (("empty object", {}), ("no ledger", {k: v for k, v in full.items() if k != "ledger"}),
                           ("ledger not a list", {**full, "ledger": {}}), ("iteration not a number", {**full, "iteration": "1"}),
                           ("another run's", {**full, "run_id": "q"}), ("another schema", {**full, "schema": 2}),
                           ("prog not an object", {**full, "prog": []})):
            with self.subTest(snapshot=name):
                w = split_world()
                with Fixture(w, **SPLIT) as f:
                    self.started(f)
                    (paths.RESULTS / "r" / "state.json").write_text(json.dumps(snap))
                    self.refused(f, w, "state.json is not whole")

    def test_a_complete_initial_snapshot_resumes(self):
        w = split_world()
        with Fixture(w, **SPLIT) as f:
            with mock.patch.object(loop, "doctor_ok", mock.Mock(side_effect=SystemExit("doctor down"))), self.assertRaises(SystemExit):
                loop.run_loop(f.options(label_deferred=True))
            (paths.RESULTS / "r" / "state.json").write_text(json.dumps(self.empty()))
            from harness.store.state import Run
            self.assertIsNone(loop.metadata_refusal(Run(f.options(label_deferred=True))))
            self.assertEqual(f.drive(1, label_deferred=True), ["awaiting_labels"])


class ContractBeforeFirstSnapshot(unittest.TestCase):
    """A launch cut short before the run's first snapshot is taken up only under the contract it
    saved: its semantic inputs are compared whether or not a snapshot exists, and the run's own reading
    copy must hold the reviewed values those inputs fixed. A value still marked `proposed` is the run's
    state, not its contract."""

    tree = RunMetadata.tree
    STEP = {"name": "p.audit_step", "value": 50, "unit": "ms", "convention": "c"}
    DECL = {"id": "asm.signal_working", "meaning": "the signal shows its lights"}

    @contextmanager
    def cut_short(self):
        w = split_world()
        with Fixture(w, **SPLIT) as f:
            (f.root / "reading.json").write_text(json.dumps({"params": [self.STEP], "declarations": [self.DECL]}))
            with mock.patch.object(loop, "doctor_ok", mock.Mock(side_effect=SystemExit("doctor down"))), self.assertRaises(SystemExit):
                loop.run_loop(f.options(label_deferred=True))
            rd = paths.RESULTS / "r"
            self.assertTrue((rd / "options.json").exists() and (rd / "reading.json").exists())
            self.assertFalse((rd / "state.json").exists())
            yield f, w, rd

    def refused(self, f, w, words: str):
        before = (self.tree(), dict(w.calls))
        with self.assertRaises(SystemExit) as e:
            loop.run_loop(f.options(label_deferred=True))
        self.assertIn(words, str(e.exception))
        self.assertIn("nothing of this run was rewritten", str(e.exception))
        self.assertEqual((self.tree(), dict(w.calls)), before)

    def test_a_reviewed_base_value_changed_after_the_cut_is_refused(self):
        with self.cut_short() as (f, w, rd):
            (f.root / "reading.json").write_text(json.dumps({"params": [{**self.STEP, "value": 100}], "declarations": [self.DECL]}))
            self.refused(f, w, "base_reading changed")
            self.assertEqual(json.loads((rd / "reading.json").read_text())["params"][0]["value"], 50)

    def test_a_reviewed_value_changed_in_the_runs_reading_copy_is_refused(self):
        with self.cut_short() as (f, w, rd):
            (rd / "reading.json").write_text(json.dumps({"params": [{**self.STEP, "value": 100}], "declarations": [self.DECL]}))
            self.refused(f, w, "holds reviewed values other than")

    def test_a_reviewed_declaration_changed_in_the_runs_reading_copy_is_refused(self):
        for decls in ([{**self.DECL, "meaning": "the signal is dark"}], [], [self.DECL, {"id": "asm.other", "meaning": "m"}]):
            with self.subTest(declarations=decls), self.cut_short() as (f, w, rd):
                (rd / "reading.json").write_text(json.dumps({"params": [self.STEP], "declarations": decls}))
                self.refused(f, w, "holds reviewed values other than")

    def test_the_same_contract_with_the_runs_own_state_resumes(self):
        """A proposal the run entered, and an aggregate it admitted into its own reading, are its state."""
        proposal = {"name": "p.run_own", "value": 3, "unit": "s", "convention": "c", "proposed": {"run": "r", "iteration": 1}}
        declared = {"id": "asm.run_own", "meaning": "m", "proposed": {"run": "r", "iteration": 1}}
        admitted = {"id": "DEF-1::vehicle", "included": ["ru.motor_vehicle"]}
        for copy in ({"params": [self.STEP, proposal], "declarations": [self.DECL]},
                     {"params": [self.STEP], "declarations": [self.DECL, declared]},
                     {"params": [self.STEP], "declarations": [self.DECL], "aggregates": [admitted]}):
            with self.subTest(copy=sorted(copy)), self.cut_short() as (f, w, rd):
                (rd / "reading.json").write_text(json.dumps(copy))
                self.assertEqual(f.drive(1, label_deferred=True), ["awaiting_labels"])


class BudgetTooSmallForOneSession(unittest.TestCase):
    """A run whose session cap does not fit its Claude budget (a rehearsal budget left at the default
    caps) pauses on the budget at its first session, before any session is launched: the real session
    entry reserves the cap first. It stops `paused_budget` (the launcher's exit 4), never as an
    iteration limit the launcher would continue."""

    def test_the_first_session_pauses_on_the_budget_and_nothing_is_launched(self):
        from harness.agents import runner, session
        real_run = session.run                                  # the real entry, before the fixture stands in for sessions
        launched = []
        w = split_world()
        with Fixture(w, **SPLIT) as f:
            f.stack.enter_context(mock.patch.object(session, "run", real_run))
            f.stack.enter_context(mock.patch.object(runner, "run_claude", lambda *a, **k: launched.append(1) or (0, {}, False)))
            out = f.drive(1, label_deferred=True, claude_budget_usd=12.0, openai_budget_usd=3.0, total_budget_usd=15.0,
                          session_budget_usd=20.0, repair_budget_usd=5.0, judge_budget_usd=1.0)
            s = json.loads((paths.RESULTS / "r" / "summary.json").read_text())
        self.assertEqual(out, ["paused_budget"], s.get("stop_reason"))
        self.assertEqual(launched, [])
        self.assertEqual(s.get("stop") or "", "")
        self.assertTrue(s["stop_reason"], s)


class ClosedDependencyStop(unittest.TestCase):
    """A law blocked only because its plan or its node repair composes a node of a law that waits for
    the operator stays blocked, with no attempt counted for the wait. In a split run the run then stops
    `awaiting_operator` naming the law, its provider and the provider's state, never `complete`, and a
    second start stops the same way. Without the split the run ends `complete` as before."""

    A, B = "L-30", "L-31"
    UNKNOWN = "L_31: composes `L_30`, which is neither accepted nor in this plan"

    def world(self, closed: str, route: str) -> World:
        w = World({self.A: "shall slow.", self.B: "shall wait."})
        w.plans = {self.A: [node("L_30", "shall slow.", self.A)], self.B: [node("L_31", "shall wait.", self.B, compositions=["L_30"])]}
        if closed == "failed":
            w.validate[("L_30", 1)] = ("fail", ["scripted: the plan cannot be carried"])    # closed, never coded
        else:
            w.gate[("L_30", 1)] = "PANIC"                                                     # held for the operator, never accepted
        if route == "plan":
            w.validate[("L_31", 1)] = ("return", ["scripted plan defect"])     # B returned on its own defect first (one attempt)
            w.validate[("L_31", 2)] = ("return", [self.UNKNOWN])               # then its only defect is the closed provider
        else:
            w.plans[self.B] = [node("L_31", "shall wait.", self.B)]
            w.gate[("L_31", 1)] = "CHECK_FAIL"                                  # B's node goes to its repair
        return w

    @contextmanager
    def repairing(self, w: World):
        from harness.phases import plan as plan_phase

        def repair(run, nrec, reasons, last_task, law, defs, siblings, reading, onto):    # the revised record composes A's node
            d = run.iter / "repair" / nrec.id
            d.mkdir(parents=True, exist_ok=True)
            (d / "planned.json").write_text(json.dumps(nrec.raw))
            (d / "record.jsonl").write_text(json.dumps({**nrec.raw, "compositions": [{"span": "s1", "rule": "L_30", "as": "condition"}]}) + "\n")
            (d / "validation.txt").write_text(self.UNKNOWN)
            w.call("node_repair", nrec.id, run.iteration)
            return d
        with mock.patch.object(plan_phase, "run_node_repair", repair):
            yield

    def test_split_a_plan_or_a_repair_blocked_on_a_closed_provider_awaits_the_operator(self):
        for route in ("plan", "repair"):
            for closed in ("failed", "blocked"):
                with self.subTest(route=route, provider=closed):
                    w = self.world(closed, route)
                    with Fixture(w, **SPLIT) as f:
                        f.stack.enter_context(self.repairing(w))
                        out = f.drive(1, label_deferred=True, max_iterations=3)
                        s = json.loads((paths.RESULTS / "r" / "summary.json").read_text())
                        self.assertEqual(out, ["awaiting_operator"], s["stop_reason"])
                        self.assertIn(f"`{self.B}` waits on `{self.A}` ({closed})", s["stop_reason"])
                        ledger = {e["law"]: e for e in f.state()["ledger"]}
                        self.assertEqual(ledger[self.A]["state"], closed)
                        self.assertEqual((ledger[self.B]["state"], ledger[self.B]["gaps"]), ("blocked", [f"decision:{self.A}"]))
                        self.assertEqual(ledger[self.B]["attempts"], 1 if route == "plan" else 0)   # no attempt for the wait
                        before = (dict(w.calls), f.state()["iterations_allocated"])
                        with label_stage_stand_ins(set()):
                            self.assertEqual(f.drive(1, label_stage=True, label_dataset="ds", max_iterations=6), ["awaiting_operator"])
                        self.assertEqual(f.drive(1, label_deferred=True, max_iterations=6), ["awaiting_operator"])
                        self.assertEqual((dict(w.calls), f.state()["iterations_allocated"]), before)

    def test_without_the_split_the_run_ends_complete_as_before(self):
        for opts in ({}, {"label_repair": True}):
            for route in ("plan", "repair"):
                for closed in ("failed", "blocked"):
                    with self.subTest(route=route, provider=closed, **opts):
                        w = self.world(closed, route)
                        with Fixture(w, max_iterations=6, **opts) as f, \
                                mock.patch.object(label_check, "training_context", lambda *a, **k: object()):
                            f.stack.enter_context(self.repairing(w))
                            self.assertEqual(f.drive(1, **({"label_dataset": "ds"} if opts.get("label_repair") else {})), ["complete"])
                            ledger = {e["law"]: e for e in f.state()["ledger"]}
                            self.assertEqual((ledger[self.B]["state"], ledger[self.B]["attempts"]),
                                             ("blocked", 1 if route == "plan" else 0))
                            self.assertLessEqual(len(f.state()["iterations_allocated"]), 3)


class BatchOrder(unittest.TestCase):
    """The laws of one plan batch, or the repairs of one pass, are decided as a whole: a dependent
    whose only defect composes a node of a provider closed in the same batch (failed, blocked, or
    spending its last attempt) is held, uncharged, whatever order the verdicts or repairs come in. The
    same verdicts in any order give the same ledger, attempts, waits, stop reason and sessions; a
    dependent's own defect is charged as before; without the split the run still ends `complete`."""

    P, D, E = "L-30", "L-31", "L-32"
    UNKNOWN_P = "L_31: composes `L_30`, which is neither accepted nor in this plan"
    UNKNOWN_D = "L_32: composes `L_31`, which is neither accepted nor in this plan"

    def world(self, provider: str = "fail", chain: bool = False, own: bool = False) -> World:
        laws = {self.P: "shall slow.", self.D: "shall wait."} | ({self.E: "shall yield."} if chain else {})
        w = World(laws)
        w.plans = {self.P: [node("L_30", "shall slow.", self.P)], self.D: [node("L_31", "shall wait.", self.D, compositions=["L_30"])]}
        if chain:
            w.plans[self.E] = [node("L_32", "shall yield.", self.E, compositions=["L_31"])]
            w.validate[("L_32", 1)] = ("return", [self.UNKNOWN_D])
        if provider == "fail":
            w.validate[("L_30", 1)] = ("fail", ["scripted: the plan cannot be carried"])
        else:                                                   # the provider's own defect spends its last attempt
            w.validate[("L_30", 1)] = ("return", ["scripted provider defect"])
        w.validate[("L_31", 1)] = ("return", [self.UNKNOWN_P] + (["scripted dependent defect"] if own else []))
        return w

    def outcome(self, w: World, order, opts: dict, **drive) -> dict:
        """One run with the batch's verdicts in `order` (node ids): what it decided and what it ran."""
        with Fixture(w, **opts) as f, mock.patch.object(label_check, "training_context", lambda *a, **k: object()):
            validate = loop.validate_phase.run_validate         # the fixture's scripted validator, its verdicts reordered

            def ordered(*a, **k):
                vs, cs = validate(*a, **k)
                return sorted(vs, key=lambda v: order.index(v.node.id) if v.node.id in order else len(order)), cs
            f.stack.enter_context(mock.patch.object(loop.validate_phase, "run_validate", ordered))
            status = f.drive(1, **drive)
            s = json.loads((paths.RESULTS / "r" / "summary.json").read_text())
            return {"status": status, "stop_reason": s.get("stop_reason"),
                    "ledger": {e["law"]: {k: e[k] for k in ("state", "attempts", "waits_on", "gaps", "reasons")} for e in f.state()["ledger"]},
                    "calls": sorted(w.calls.items())}

    def same_in_every_order(self, make, ids, opts, **drive) -> dict:
        outs = {order: self.outcome(make(), list(order), opts, **drive) for order in itertools.permutations(ids)}
        first = outs[tuple(ids)]
        for order, out in outs.items():
            with self.subTest(order=order):
                self.assertEqual(out, first)
        return first

    def test_the_audit_reproduction_in_both_orders(self):
        for attempts in (1, 2):
            with self.subTest(plan_attempts=attempts):
                out = self.same_in_every_order(self.world, ["L_30", "L_31"], dict(SPLIT, plan_attempts=attempts),
                                               label_deferred=True, max_iterations=4)
                self.assertEqual(out["status"], ["awaiting_operator"])
                self.assertIn(f"`{self.D}` waits on `{self.P}` (failed)", out["stop_reason"])
                d = out["ledger"][self.D]
                self.assertEqual((d["state"], d["attempts"], d["waits_on"], d["gaps"]), ("blocked", 0, [self.P], [f"decision:{self.P}"]))
                self.assertEqual([c for c in out["calls"] if c[0][0] == "plan"], [(("plan", f"{self.P},{self.D}", 1), 1)])

    def test_a_transitive_chain_in_every_order(self):
        for provider in ("fail", "last_attempt"):
            with self.subTest(provider=provider):
                out = self.same_in_every_order(lambda: self.world(provider, chain=True), ["L_30", "L_31", "L_32"],
                                               dict(SPLIT, plan_attempts=1), label_deferred=True, max_iterations=4)
                self.assertEqual(out["status"], ["awaiting_operator"])
                led = out["ledger"]
                self.assertEqual(led[self.P]["state"], "failed")
                self.assertEqual(led[self.P]["attempts"], 0 if provider == "fail" else 1)
                for law, waits in ((self.D, [self.P]), (self.E, [self.D])):    # each waits on its provider, closed or held
                    self.assertEqual((led[law]["state"], led[law]["attempts"], led[law]["waits_on"], led[law]["gaps"]),
                                     ("blocked", 0, waits, [f"decision:{self.P}"]))
                self.assertEqual([c for c in out["calls"] if c[0][0] == "plan"], [(("plan", f"{self.P},{self.D},{self.E}", 1), 1)])

    def test_a_provider_failed_or_blocked_in_the_same_batch(self):
        # failed: by its validation, or by a return spending its last attempt; blocked: held on a provider of its own
        for provider, ids, make in (("fail", ["L_30", "L_31"], lambda: self.world("fail")),
                                    ("last_attempt", ["L_30", "L_31"], lambda: self.world("last_attempt")),
                                    ("blocked", ["L_30", "L_31", "L_32"], lambda: self.world("fail", chain=True))):
            with self.subTest(provider=provider):
                out = self.same_in_every_order(make, ids, dict(SPLIT, plan_attempts=1), label_deferred=True, max_iterations=4)
                self.assertEqual(out["status"], ["awaiting_operator"])
                dep = self.E if provider == "blocked" else self.D
                self.assertEqual(out["ledger"][self.D if provider == "blocked" else self.P]["state"],
                                 "blocked" if provider == "blocked" else "failed")
                self.assertEqual((out["ledger"][dep]["state"], out["ledger"][dep]["attempts"]), ("blocked", 0))
                self.assertNotIn("failed", [out["ledger"][l]["state"] for l in (self.D, self.E) if l in out["ledger"]])

    def test_a_dependent_with_its_own_defect_is_charged_as_before(self):
        for attempts in (1, 2):
            with self.subTest(plan_attempts=attempts):
                out = self.same_in_every_order(lambda: self.world(own=True), ["L_30", "L_31"], dict(SPLIT, plan_attempts=attempts),
                                               label_deferred=True, max_iterations=1)
                d = out["ledger"][self.D]
                self.assertEqual((d["state"], d["attempts"]), ("failed" if attempts == 1 else "returned", 1))
                self.assertIn("scripted dependent defect", d["reasons"])
                self.assertTrue(any(r.startswith("composes ['L_30'], whose law waits for the operator") for r in d["reasons"]), d["reasons"])

    def test_without_the_split_the_run_ends_complete_in_every_order(self):
        out = self.same_in_every_order(self.world, ["L_30", "L_31"], dict(plan_attempts=1, max_iterations=4))
        self.assertEqual(out["status"], ["complete"])
        d = out["ledger"][self.D]
        self.assertEqual((d["state"], d["attempts"], d["gaps"]), ("blocked", 0, [f"decision:{self.P}"]))

    def test_repairs_of_one_pass_in_both_orders(self):
        """The provider's repair keeps a defect and spends its last attempt; the dependent's revised record
        composes the provider's node and has no other defect: held, uncharged, in either order."""
        from harness.phases import plan as plan_phase

        def make():
            w = World({self.P: "shall slow.", self.D: "shall wait."})
            w.plans = {self.P: [node("L_30", "shall slow.", self.P)], self.D: [node("L_31", "shall wait.", self.D)]}
            w.gate[("L_30", 1)] = w.gate[("L_31", 1)] = "CHECK_FAIL"
            return w

        def outcome(reverse: bool) -> dict:
            w = make()

            def repair(run, nrec, reasons, last_task, law, defs, siblings, reading, onto):
                d = run.iter / "repair" / nrec.id
                d.mkdir(parents=True, exist_ok=True)
                (d / "planned.json").write_text(json.dumps(nrec.raw))
                raw = nrec.raw if nrec.id == "L_30" else {**nrec.raw, "compositions": [{"span": "s1", "rule": "L_30", "as": "condition"}]}
                (d / "record.jsonl").write_text(json.dumps(raw) + "\n")
                (d / "validation.txt").write_text("scripted kept defect" if nrec.id == "L_30" else self.UNKNOWN_P)
                w.call("node_repair", nrec.id, run.iteration)
                return d
            apply = loop._apply_repairs

            def ordered(run, opts, prog, *a, **k):
                reps = prog.get("node_repairs", {})
                prog["node_repairs"] = dict(sorted(reps.items(), reverse=reverse))
                return apply(run, opts, prog, *a, **k)
            with Fixture(w, **SPLIT, plan_attempts=1) as f, mock.patch.object(plan_phase, "run_node_repair", repair), \
                    mock.patch.object(loop, "_apply_repairs", ordered):
                status = f.drive(1, label_deferred=True, max_iterations=4)
                s = json.loads((paths.RESULTS / "r" / "summary.json").read_text())
                return {"status": status, "stop_reason": s.get("stop_reason"),
                        "ledger": {e["law"]: {k: e[k] for k in ("state", "attempts", "waits_on", "gaps")} for e in f.state()["ledger"]},
                        "calls": sorted(w.calls.items())}
        first, second = outcome(False), outcome(True)
        self.assertEqual(second, first)
        self.assertEqual(first["status"], ["awaiting_operator"])
        self.assertEqual(first["ledger"][self.P]["state"], "failed")
        d = first["ledger"][self.D]
        self.assertEqual((d["state"], d["attempts"], d["waits_on"]), ("blocked", 0, [self.P]))
        self.assertIn((("node_repair", "L_31", 2), 1), first["calls"])           # both repairs ran, in one pass


class PolicyAnchor(unittest.TestCase):
    """Every export records the run's acceptance policy; a manifest without it is still read, and its
    policy is reported `policy anchor missing: not verified`, never verified."""

    def test_the_anchor_is_written_and_its_absence_reported(self):
        from harness.__main__ import Cli
        import contextlib, io
        w = split_world()
        with Fixture(w, **SPLIT) as f, mock.patch.object(handoff, "toolchain", lambda: TOOLCHAIN), \
                mock.patch("harness.store.owner.acquire_for_command", lambda name: None):
            self.assertEqual(f.drive(1, label_deferred=True), ["awaiting_labels"])
            m = handoff.export("r", source_baseline="c0ffee")
            self.assertEqual(m["acceptance_policy"], {"label_repair": True})
            self.assertFalse(any("policy anchor" in x for x in handoff.verify("r")[1]))
            mf = paths.RESULTS / "r" / "handoff" / "manifest.json"
            mf.write_text(json.dumps({k: v for k, v in json.loads(mf.read_text()).items() if k != "acceptance_policy"}))
            refusals, warnings = handoff.verify("r")
            self.assertEqual(refusals, [])
            self.assertTrue(any(x.startswith("policy anchor missing: not verified") for x in warnings), warnings)
            out = io.StringIO()
            with contextlib.redirect_stdout(out):
                Cli().handoff("verify", "r")
            self.assertNotIn("\nverified\n", "\n" + out.getvalue())
            self.assertIn("policy anchor missing: not verified", out.getvalue())
            out = io.StringIO()
            with contextlib.redirect_stdout(out):                                  # the launch says it too
                f.drive(1, label_deferred=True, max_iterations=3)
            self.assertIn("handoff: policy anchor missing: not verified", out.getvalue())


class OperatorReading(unittest.TestCase):
    """The operator-reviewed base reading names the carla_scene_graph step parameter: a run that names
    that profile passes the start check on it."""

    def test_a_run_with_the_profile_starts_on_the_reading(self):
        real = Path(__file__).resolve().parents[2] / "library" / "TrafficSpec" / "Readings" / "lasvegas.json"
        from harness.model import acquisition
        from harness.model.reading import reading_defects
        data = json.loads(real.read_text())
        self.assertEqual(reading_defects(data), [])
        self.assertEqual(acquisition.review_defects(acquisition.step_parameter("carla_scene_graph"), data), [])
        w = split_world()
        with Fixture(w, **SPLIT) as f:
            shutil.copy2(real, f.root / "reading.json")
            self.assertEqual(f.drive(1, label_deferred=True, acquisition_profile="carla_scene_graph"), ["awaiting_labels"])


def clone(f: Fixture, stack) -> Path:
    """Copy the fixture's repository to another root, make the old root unreachable, and point the
    harness at the copy. Returns the new root."""
    new = f.tmp / "elsewhere" / "repo"
    shutil.copytree(f.root, new, symlinks=True)
    gone = f.tmp / "gone"
    f.root.rename(gone)
    os.chmod(gone, 0)
    stack.callback(lambda: (os.chmod(gone, stat.S_IRWXU), gone.rename(f.root)))
    rel = {k: new / Path(v).relative_to(f.root) for k, v in f.dirs.items()}
    for k in PATH_NAMES:
        stack.enter_context(mock.patch.object(paths, k, rel[k]))
    f.root_now = new
    return new


def options_at(f: Fixture, root: Path, **over) -> Options:
    o = f.options(**over)
    return Options(**{**o.__dict__, "laws": root / "corpus" / "laws.jsonl", "ontology": root / "ontology.md",
                      "reading": root / "reading.json", "definition_precedence": root / "precedence.json"})


class ColdClone(unittest.TestCase):

    def test_a_checkpoint_continues_at_another_root_with_the_old_one_gone(self):
        from contextlib import ExitStack
        w = split_world()
        w.gate[("L_22", 1)] = "CHECK_FAIL"                    # a node repair pending across the handoff
        seen_tasks = []
        with Fixture(w, **SPLIT) as f, ExitStack() as stack, mock.patch.object(handoff, "toolchain", lambda: TOOLCHAIN):
            self.assertEqual(f.drive(1, label_deferred=True), ["incomplete"])
            rd = paths.RESULTS / "r"
            self.assertEqual(json.loads((rd / "summary.json").read_text())["stop"], "iteration_limit")
            snap = json.loads((rd / "state.json").read_text())
            self.assertFalse(os.path.isabs(snap["prog"]["plan_dir"]))                 # saved relative to the repository
            last = {e["node"]: e["last_task"] for e in snap["node_ledger"]}["L_22"]
            self.assertFalse(os.path.isabs(last))
            m = handoff.export("r", source_baseline="abc")
            self.assertTrue(m["artifacts"] and all(not k.endswith((".lock", ".run.owner.json")) for k in m["artifacts"]))
            self.assertIn("results/r/state.json", m["artifacts"])
            listed = (rd / "handoff" / "files.txt").read_text().split()
            self.assertIn("results/r/handoff/manifest.json", listed)
            old_root = str(f.root)

            new = clone(f, stack)
            self.assertFalse(os.access(old_root, os.R_OK))
            real = loop.plan_phase.run_node_repair
            def run_node_repair(run, nrec, reasons, last_task, *a):
                seen_tasks.append(Path(last_task))
                return real(run, nrec, reasons, last_task, *a)
            with mock.patch.object(loop.plan_phase, "run_node_repair", run_node_repair):
                res = loop.run_loop(options_at(f, new, label_deferred=True, max_iterations=2))
            self.assertEqual(res["status"], "awaiting_labels")
            self.assertTrue(seen_tasks and all(p.is_dir() and p.is_relative_to(new) for p in seen_tasks), seen_tasks)
            self.assertTrue((paths.RESULTS / "r" / "handoff" / "imported.json").exists())
            self.assertFalse([c for c in calls(w, "plan") if c[1] > 1])                    # nothing re-planned
            self.assertFalse([c for c in calls(w, "code") if c[1] > 1 and c[0] != "L_22"])  # nothing generated coded again
            self.assertIn(("L_22", 2), calls(w, "code"))                                   # its repair, then its coding

            # the local stage on a run whose iteration bound is spent: told, never silently idle
            with label_stage_stand_ins({A, C}) as (seen, _r):
                res = loop.run_loop(options_at(f, new, label_stage=True, label_dataset="ds", max_iterations=2))
                self.assertEqual((res["status"], res["stop"]), ("incomplete", "iteration_limit"))
                self.assertEqual(seen, [])
                res = loop.run_loop(options_at(f, new, label_stage=True, label_dataset="ds", max_iterations=3))
            self.assertEqual(res["status"], "awaiting_generation")
            self.assertEqual(seen, [[A, C]])

    def test_a_checkpoint_continues_at_another_root_with_the_old_one_still_there(self):
        """Saved paths under a recorded root are this checkout's, even while the old checkout is still
        readable and holds other content; a path outside every recorded root keeps its meaning."""
        w = split_world()
        with Fixture(w, **SPLIT) as f, mock.patch.object(handoff, "toolchain", lambda: TOOLCHAIN), \
                mock.patch.object(paths, "FOREIGN_ROOTS", []):
            f.drive(1, label_deferred=True)
            handoff.export("r", source_baseline="abc")
            new = f.tmp / "elsewhere" / "repo"
            shutil.copytree(f.root, new, symlinks=True)
            for rel in ("corpus/laws.jsonl", "ontology.md", "precedence.json"):        # the old checkout moved on
                with open(f.root / rel, "a") as fh:
                    fh.write("\n" if rel.endswith(".jsonl") else " ")
            outside = f.tmp / "outside.json"
            outside.write_text("{}")
            rel = {k: new / Path(v).relative_to(f.root) for k, v in f.dirs.items()}
            with mock.patch.multiple(paths, **{k: rel[k] for k in PATH_NAMES}):
                self.assertEqual(handoff.verify("r"), ([], []))
                self.assertEqual(paths.local(str(f.root / "corpus" / "laws.jsonl")), new / "corpus" / "laws.jsonl")
                self.assertEqual(paths.local(str(outside)), outside)
                self.assertEqual(paths.local(str(new / "ontology.md")), new / "ontology.md")
                res = loop.run_loop(options_at(f, new, label_deferred=True, max_iterations=2))
                self.assertEqual(res["status"], "awaiting_labels")

    def test_an_import_refuses_files_not_as_exported(self):
        w = split_world()
        with Fixture(w, **SPLIT) as f, mock.patch.object(handoff, "toolchain", lambda: TOOLCHAIN):
            f.drive(1, label_deferred=True)
            handoff.export("r")
            (paths.RESULTS / "r" / "summary.json").write_text("{}\n")
            with self.assertRaisesRegex(SystemExit, "not as exported"):
                loop.run_loop(f.options(label_deferred=True, max_iterations=2))

    def test_an_export_refuses_a_run_short_of_a_checkpoint(self):
        w = split_world()
        with Fixture(w, **SPLIT) as f, mock.patch.object(handoff, "toolchain", lambda: TOOLCHAIN):
            f.drive(1, label_deferred=True)
            rd = paths.RESULTS / "r"
            snap = json.loads((rd / "state.json").read_text())
            snap["prog"]["stage"] = "nodes"
            (rd / "state.json").write_text(json.dumps(snap))
            with self.assertRaisesRegex(SystemExit, "short of `done`"):
                handoff.export("r")
            with mock.patch("harness.store.owner.acquire_for_command", side_effect=SystemExit("another process owns the library")):
                with self.assertRaisesRegex(SystemExit, "owns the library"):
                    handoff.export("r")


class Pinning(unittest.TestCase):
    """A run continues only on the code it started on; a checkpoint that only adds run files passes."""

    @contextmanager
    def repo(self):
        with tempfile.TemporaryDirectory() as t:
            root = Path(t) / "repo"
            lib = root / "library"
            for rel, text in {"harness/phases/label_check.py": "# check\n", "harness/phases/label_repair.py": "# repair\n",
                              "recorded/scoring.py": "# score\n", "prompts/plan.md": "plan\n", "ontology/ATOMS.md": "# atoms\n",
                              "config/x.json": "{}", "library/Explain.lean": "-- explain\n", "library/TrafficSpec/Core/Core.lean": "-- core\n",
                              "laws.jsonl": "", "definitions.jsonl": "", "reading.json": "{\"params\": []}", "precedence.json": "{}",
                              "pyproject.toml": "[project]\n", "scripts/run-generation.sh": "# launcher\n",
                              "scripts/diagnostics/doctor.py": "# doctor\n", "scripts/diagnostics/library_v2.py": "# doctor checks\n"}.items():
                (root / rel).parent.mkdir(parents=True, exist_ok=True)
                (root / rel).write_text(text)
            layout = {**paths.library_layout(lib), "REPO": root, "RESULTS": root / "results"}
            with mock.patch.multiple(paths, **layout), mock.patch.object(handoff, "toolchain", lambda: TOOLCHAIN), \
                    mock.patch("harness.store.owner.acquire_for_command", lambda name: None):
                opts = Options(run_id="r", laws=root / "laws.jsonl", ontology=root / "ontology" / "ATOMS.md",
                               reading=root / "reading.json", definition_precedence=root / "precedence.json")
                rd = paths.run_dir("r")
                rd.mkdir(parents=True)
                (rd / "options.json").write_text(json.dumps({**{k: v if isinstance(v, (bool, int, float)) else str(v)
                                                                 for k, v in opts.__dict__.items() if v is not None},
                                                             "base_reading": str(opts.reading), "semantic": loop.semantic_inputs(opts),
                                                             "base_run": None, "budget_peers": []}))
                (rd / "state.json").write_text(json.dumps({"iteration": 1, "prog": {"stage": "done"}, "ledger": [], "concept_ledger": [],
                                                           "node_ledger": [], "accepted_nodes": {}, "accepted_concepts": {}}))
                for name in ("ledger.jsonl", "concept_ledger.jsonl", "node_ledger.jsonl", "accepted_nodes.jsonl", "accepted_concepts.jsonl"):
                    (rd / name).write_text("")
                label_check.freeze(rd)
                yield root, rd

    def test_artifact_only_checkpoints_pass_and_code_changes_refuse(self):
        with self.repo() as (root, rd):
            first = handoff.export("r", source_baseline="c0ffee")
            (rd / "iter-001").mkdir()
            (rd / "iter-001" / "notes.txt").write_text("a new run artifact\n")       # an artifact-only checkpoint
            self.assertEqual(handoff.verify("r", artifacts=False)[0], [])
            second = handoff.export("r", source_baseline="later")
            self.assertEqual(second["baseline"], first["baseline"])                  # the run's baseline is kept
            self.assertEqual(second["baseline"]["source_commit"], "c0ffee")
            self.assertEqual(handoff.verify("r")[0], [])
            for rel in ("harness/phases/label_check.py", "harness/phases/label_repair.py", "prompts/plan.md", "pyproject.toml",
                        "scripts/run-generation.sh", "scripts/diagnostics/doctor.py", "scripts/diagnostics/library_v2.py"):
                with self.subTest(changed=rel):
                    f = root / rel
                    was = f.read_text()
                    f.write_text(was + "# changed after the run started\n")
                    refusals, _w = handoff.verify("r", artifacts=False)
                    self.assertTrue(any(rel in r and "start a new run" in r and "c0ffee" in r for r in refusals), refusals)
                    with self.assertRaisesRegex(SystemExit, "differs from its baseline"):
                        handoff.export("r")
                    run = mock.Mock(dir=rd, opts=mock.Mock(run_id="r"))
                    with self.assertRaisesRegex(SystemExit, "cannot continue here"):
                        handoff.check_on_launch(run)
                    f.write_text(was)
            self.assertEqual(handoff.verify("r")[0], [])


class LabelRepairAcrossTheClone(unittest.TestCase):
    """A mismatch routed and repaired through the real candidate transaction; the run cloned to
    another root with the old one gone and the dataset moved; the next repair is scheduled there,
    with its count, the comparison set and the other laws' outcomes carried on."""

    def test_a_repair_continues_after_a_cold_clone(self):
        from harness.store.ledger import ConceptLedger, Ledger, NodeLedger
        from harness.store.state import commit_state
        from harness.store.gaps import GapLedger
        from harness.model import corpus
        from scripts.tests.test_candidate import cand, node_rec
        from scripts.tests.test_label_repair import L, N
        from scripts.tests.test_label_repair_session import DIFF5, RULE5, repair, repairing, set_verdict, stub_session
        from harness.agents import session
        cand._OPEN.clear()
        rec = {k: v for k, v in node_rec(N[5]).items() if k != "segmentation"}
        with repairing(outputs={"record.jsonl": json.dumps(rec), "lean.diff": DIFF5}) as (run, ledger, training, by_id):
            states_before = {L[k]: ledger.entries[L[k]].state for k in (1, 2, 3, 4)}
            set_verdict(training, "r5a", N[5], "compliant")
            self.assertEqual(repair(run, ledger, training, by_id), "committed")
            self.assertEqual(run.label_states[L[5]]["repairs"], 1)
            commit_state(run, ledger, ConceptLedger(run.concept_ledger_file, 3), NodeLedger(run.node_ledger_file, 2))
            world_dir = paths.RESULTS.parent
            fixed = (run.dir / "comparison_set.json").read_bytes()
            new_root = Path(tempfile.mkdtemp(prefix="clone-"))
            try:
                shutil.copytree(world_dir, new_root / "w", symlinks=True)
                new_ds = new_root / "ds"
                shutil.copytree(training.dataset.path, new_ds)
                gone = world_dir.with_name(world_dir.name + "-gone")
                world_dir.rename(gone); os.chmod(gone, 0)
                try:
                    lib = new_root / "w" / "library"
                    with mock.patch.multiple(paths, **{**paths.library_layout(lib), "RESULTS": new_root / "w" / "results"}):
                        opts = Options(**{**run.opts.__dict__, "laws": new_root / "w" / "laws.jsonl",
                                          "label_repair": True, "label_stage": True, "label_dataset": str(new_ds),
                                          "reading": lib / "TrafficSpec" / "Readings" / "base_test.json"})
                        fresh = Run(opts)
                        fresh.restore_state(); fresh.load_accepted(); fresh.iteration = 2
                        led = Ledger(fresh.ledger_file, list(L.values()), 2); led.attempt = 2
                        fresh.law_entries = led.entries
                        t2 = label_check.training_context(fresh.dir, list(L.values()), new_ds, training.limits)
                        self.assertEqual((fresh.dir / "comparison_set.json").read_bytes(), fixed)    # the binding holds, unchanged
                        self.assertEqual(loop.label_work(fresh, fresh.opts, led), [L[5]])            # the next repair is scheduled
                        set_verdict(t2, "r5b", N[5], "violated")                                     # the second repair aligns it
                        by2 = {l.id: l for l in corpus.load_laws(opts.laws)}
                        diff_v3 = f"--- {RULE5}\n+++ {RULE5}\n@@ -3 +3 @@\n--- v2\n+-- v3\n"
                        with mock.patch.object(session, "run", stub_session({"record.jsonl": json.dumps(rec), "lean.diff": diff_v3})):
                            out = lr.run_repairs(fresh, led, t2, by2, [], lr.ontology.load(fresh.opts.ontology),
                                                 GapLedger.for_run(paths.GAPS_DIR, fresh), [], [])
                        self.assertEqual(out[L[5]], ["committed"])
                        self.assertIn("-- v3", (paths.LIBRARY / RULE5).read_text())
                        st = fresh.label_states[L[5]]
                        self.assertEqual((st["state"], st["outcome"], st["repairs"]), ("accepted", "aligned", 2))
                        self.assertEqual(led.entries[L[5]].state, "accepted")
                        self.assertEqual({L[k]: led.entries[L[k]].state for k in (1, 2, 3, 4)}, states_before)   # no other law moved
                        checks = [json.loads(x) for p in fresh.dir.glob("iter-002/candidate/*/checks.jsonl")
                                  for x in p.read_text().splitlines() if x.strip()]
                        self.assertTrue(any(c.get("check") == "label_non_regression" and c.get("status") == "pass" for c in checks), checks[:3])
                        self.assertEqual(loop.label_work(fresh, fresh.opts, led), [])
                finally:
                    os.chmod(gone, stat.S_IRWXU); gone.rename(world_dir)
            finally:
                shutil.rmtree(new_root, ignore_errors=True)



class PendingRepairAcrossARealFileList(unittest.TestCase):
    """A label repair left pending after its coder's gate passed is handed over with nothing but the
    code a checkout of the run's baseline holds (the files the code digest covers, and the corpus) and
    the files the export lists, with the old checkout still in place and holding other content: the
    next machine reuses the finished verdict (`code._finished_verdict`) and codes nothing again."""

    def test_a_pending_repair_is_taken_up_from_the_exported_files_only(self):
        self.pending_handoff([])

    def test_a_new_concept_and_a_new_node_are_taken_up(self):
        """Records the repair adds, whose files lie in directories the library does not hold yet: the
        restore creates them, and the finished verdicts are reused."""
        from scripts.tests.test_candidate import concept_rec
        from scripts.tests.test_label_repair import N
        with self.subTest(new="concept"):
            self.pending_handoff([concept_rec("drv.env.brand_new")])
        with self.subTest(new="nodes"):                                        # a new cut of the law: the planner's, in the candidate
            self.pending_handoff([], plan_nodes=[f"{N[5]}_o1", f"{N[5]}_o2"])

    def test_a_failed_restore_is_coded_again_never_half_taken_up(self):
        from scripts.tests.test_candidate import concept_rec
        self.pending_handoff([concept_rec("drv.env.brand_new")], fail_restore=True)

    def pending_handoff(self, extra: list[dict], plan_nodes: list[str] | None = None, fail_restore: bool = False):
        from dataclasses import asdict, replace
        from harness.agents import session
        from harness.model import corpus
        from harness.phases import candidate as cand, code as code_phase, integrate
        from harness.store.gaps import GapLedger
        from harness.store.ledger import ConceptLedger, Ledger, NodeLedger
        from harness.store.state import commit_state
        from scripts.tests.test_candidate import node_rec
        from scripts.tests.test_label_repair import L, N
        from scripts.tests.test_label_repair_session import repairing, set_verdict, stub_session
        cand._OPEN.clear()
        rec = {k: v for k, v in node_rec(N[5]).items() if k != "segmentation"}
        rec["elements"] = [{"span": "o1", "atoms": ["kin.speed", "rel.occupies"], "derived": []}]    # not local: the coder's
        outputs = {"record.jsonl": "".join(json.dumps(r) + "\n" for r in [rec, *extra])}
        names = sorted([N[5]] + [code_phase.concept_dirname(r["concept_id"]) if "concept_id" in r else r["node_id"] for r in extra])
        if plan_nodes:
            outputs = {"record.jsonl": json.dumps({"node_id": N[5], "withdraw": {"kind": "plan", "missing": "the law carries two duties"}})}
            names = sorted(plan_nodes)
        from harness.phases import plan as plan_mod

        def fake_plan(view, laws, defs, tag="", pending=None, label_repair=False):
            d = view.iter / "plan" / tag
            d.mkdir(parents=True, exist_ok=True)
            (d / "blueprint.jsonl").write_text("".join(json.dumps(node_rec(i) | {"law_refs": [L[5]]}) + "\n" for i in plan_nodes or []))
            return d
        coded, reviewed = [], []

        def concept_review(txn, aff):                                          # the concept review's stand-in: it runs, and passes
            reviewed.append(sorted(i for i, k in aff.closure.items() if k == "concept"))
            return [cand.CheckResult("concept_review", i, "pass") for i, k in aff.closure.items() if k == "concept"]

        def recorded(stub):
            def run(prompt, cwd=None, out_dir=None, label="session", **k):        # records its launch, as the real one does
                if "label_repair" not in Path(cwd).parts:
                    coded.append(Path(cwd).name)
                stub(prompt, cwd=cwd, out_dir=out_dir, label=label, **k)
                (Path(out_dir or cwd) / f"{label}_result.json").write_text("{}")
            return run
        with repairing(outputs=outputs) as (run, ledger, training, by_id), \
                mock.patch.object(session, "run", recorded(stub_session(outputs))), \
                mock.patch.object(handoff, "toolchain", lambda: TOOLCHAIN), \
                mock.patch("harness.store.owner.acquire_for_command", lambda name: None), \
                mock.patch.object(paths, "FOREIGN_ROOTS", []), mock.patch.object(plan_mod, "run_plan", fake_plan), \
                mock.patch.object(cand, "concept_review", concept_review):
            world = paths.RESULTS.parent
            run.opts = replace(run.opts, label_repair=True, label_dataset=str(training.dataset.path))
            run.law_entries = ledger.entries
            with mock.patch.object(paths, "REPO", world):
                code_set = {p.relative_to(world).as_posix() for p in handoff.code_files()} | {"laws.jsonl", "definitions.jsonl"}
                # the first attempt: the coder's gate passes, then the whole-library check cannot run: pending, uncharged
                with mock.patch.object(integrate, "verify_library", lambda *a, **k: ("unavailable", ["toolchain down"], set())):
                    self.assertEqual(lr.repair_law(run, ledger, training, by_id[L[5]], [], lr.ontology.load(run.opts.ontology),
                                                   GapLedger.for_run(paths.GAPS_DIR, run), [], []), "unavailable")
                self.assertEqual(sorted(coded), names)
                act = run.label_states[L[5]]["active"]
                self.assertEqual(act["stage"], "coding")
                first = run.dir / act["candidate"]
                for name in names:
                    task = next(first.glob(f"**/code/{name}"))
                    self.assertEqual(json.loads((task / "verdict.json").read_text())["verdict"], "OK")
                # a checkpoint: the snapshot, the options, the freeze, the export
                run.iteration = 1
                commit_state(run, ledger, ConceptLedger(run.concept_ledger_file, 3), NodeLedger(run.node_ledger_file, 2), prog={"stage": "done"})
                (run.dir / "options.json").write_text(json.dumps({**{k: (str(v) if isinstance(v, Path) else v) for k, v in asdict(run.opts).items()},
                                                                  "base_reading": str(run.opts.reading), "reading": str(run.reading_file),
                                                                  "semantic": loop.semantic_inputs(run.opts), "repo_roots": [str(world)]}))
                label_check.freeze(run.dir)
                handoff.export("r", source_baseline="c0ffee")
                listed = (run.dir / "handoff" / "files.txt").read_text().split()
            self.assertFalse(any("/tree/" in f for f in listed))                          # no candidate library copy is handed over

            new_root = Path(tempfile.mkdtemp(prefix="realfiles-"))
            try:
                new = new_root / "w"
                for rel in sorted(code_set | set(listed)):                              # a checkout of the baseline, then the handed files
                    (new / rel).parent.mkdir(parents=True, exist_ok=True)
                    shutil.copy2(world / rel, new / rel)
                (world / "laws.jsonl").write_text((world / "laws.jsonl").read_text() + "\n")   # the old checkout, still there, moved on
                lib = new / "library"
                with mock.patch.multiple(paths, **{**paths.library_layout(lib), "RESULTS": new / "results", "REPO": new}):
                    opts = Options(**{**run.opts.__dict__, "laws": new / "laws.jsonl", "label_stage": True,
                                      "reading": lib / "TrafficSpec" / "Readings" / "base_test.json"})
                    self.assertEqual(handoff.verify("r")[0], [])
                    fresh = Run(opts)
                    fresh.restore_state(); fresh.load_accepted(); fresh.iteration = 2
                    led = Ledger(fresh.ledger_file, list(L.values()), 2); led.attempt = 2
                    fresh.law_entries = led.entries
                    t2 = label_check.training_context(fresh.dir, list(L.values()), training.dataset.path, training.limits)
                    for i in plan_nodes or [N[5]]:                                      # what the repaired rules compute: aligned
                        for rid, verdict in (("r5a", "compliant"), ("r5b", "violated"), ("r5c", "compliant")):
                            set_verdict(t2, rid, i, verdict if i in (N[5], f"{N[5]}_o1") else "not_applicable")
                    reused, real = [], code_phase._finished_verdict

                    def finished(d, rels, context=None):
                        v = real(d, rels, context)
                        if v is not None:
                            reused.append((Path(d).name, v.verdict))
                        return v
                    real_copy, left = shutil.copytree, []

                    def copytree(src, dst, *a, **k):                                   # the restore stops part-way
                        real_copy(src, dst, *a, **k)
                        if fail_restore:
                            left.append(Path(dst))
                            raise OSError("disk full")
                    with mock.patch.object(code_phase, "_finished_verdict", finished), mock.patch.object(lr.shutil, "copytree", copytree):
                        out = lr.run_repairs(fresh, led, t2, {l.id: l for l in corpus.load_laws(opts.laws)}, [],
                                             lr.ontology.load(fresh.opts.ontology), GapLedger.for_run(paths.GAPS_DIR, fresh), [], [])
                    self.assertEqual(out[L[5]], ["committed"], fresh.label_states[L[5]].get("last_repair"))
                    if fail_restore:
                        self.assertTrue(left and not any(d.exists() and (d / "verdict.json").exists() and not (d / "session_result.json").exists()
                                                          for d in left))
                        self.assertEqual(sorted(coded), sorted(names + names))           # each record coded again, none half taken up
                        self.assertEqual(out[L[5]], ["committed"])                       # the final gate and checks ran
                        self.assertIn(["drv.env.brand_new"], reviewed)
                        return
                    for name in names:
                        self.assertIn((name, "OK"), reused)                              # the finished verdict, reused
                    self.assertEqual(sorted(coded), names)                               # no coding session again
                    if extra:
                        self.assertIn(["drv.env.brand_new"], reviewed)                   # the candidate's checks still ran
                    self.assertEqual(fresh.label_states[L[5]]["repairs"], 1)
            finally:
                shutil.rmtree(new_root, ignore_errors=True)


class AcceptancePolicyPinned(unittest.TestCase):
    """A run's acceptance policy (`label_repair`) is part of its fixed inputs: a resume that
    changes it, through the CLI or `run_loop`, with or without a handoff, is refused before any recovery,
    rewrite or session, and leaves the run as it was. Which stage runs, and the dataset, are not fixed;
    nor is a budget. A fixed input the run started with and the resume lacks is a change too."""

    def frozen(self, f, w) -> tuple:
        rd = paths.RESULTS / "r"
        return ((rd / "state.json").read_bytes(), (rd / "options.json").read_bytes(), f.state()["iterations_allocated"],
                dict(w.calls), sorted(p.name for p in rd.rglob("*") if p.is_file()))

    def refused(self, f, w, launch, words: str):
        before = self.frozen(f, w)
        with self.assertRaises(SystemExit) as e:
            launch()
        self.assertIn(words, str(e.exception))
        self.assertIn("nothing of this run was rewritten", str(e.exception))
        self.assertEqual(self.frozen(f, w), before)

    def test_a_policy_change_is_refused_with_and_without_a_handoff(self):
        from harness.__main__ import Cli
        for handed in (False, True):
            for change in (dict(label_repair=False),):
                with self.subTest(handoff=handed, change=change):
                    w = split_world()
                    with Fixture(w, **SPLIT) as f, mock.patch.object(handoff, "toolchain", lambda: TOOLCHAIN), \
                            mock.patch("harness.store.owner.acquire_for_command", lambda name: None):
                        self.assertEqual(f.drive(1, label_deferred=True), ["awaiting_labels"])
                        if handed:
                            handoff.export("r", source_baseline="c0ffee")
                            self.assertEqual(handoff.verify("r")[0], [])
                        self.refused(f, w, lambda: Cli().loop("r", max_iterations=3, **change), "acceptance policy is fixed")
                        self.refused(f, w, lambda: loop.run_loop(f.options(label_deferred=True, max_iterations=3, **change)),
                                     "acceptance policy is fixed")
                        self.assertTrue(all(e["state"] == "planned" for e in f.state()["ledger"]))
                        if handed:                              # saved options edited after the export: the handoff refuses them
                            o = paths.RESULTS / "r" / "options.json"
                            o.write_text(json.dumps({**json.loads(o.read_text()), **change}))
                            self.assertTrue(any("acceptance policy is fixed" in x for x in handoff.verify("r")[0]))

    def test_the_stage_switch_and_a_budget_raise_are_not_policy_changes(self):
        w = split_world()
        with Fixture(w, **SPLIT) as f:
            self.assertEqual(f.drive(1, label_deferred=True), ["awaiting_labels"])
            with label_stage_stand_ins({A, C}):
                self.assertEqual(f.drive(1, label_stage=True, label_dataset="ds", max_iterations=2, claude_budget_usd=50.0,
                                         total_budget_usd=60.0, session_budget_usd=5.0, repair_budget_usd=5.0, judge_budget_usd=1.0),
                                 ["awaiting_generation"])
            self.assertEqual(f.drive(1, label_deferred=True, max_iterations=3), ["awaiting_labels"])
            self.assertIn(("L_21", 3), calls(w, "code"))

    def test_a_fixed_input_the_resume_lacks_is_refused(self):
        w = split_world()
        with Fixture(w, **SPLIT) as f, mock.patch.object(loop.acquisition, "step_parameter", lambda *a, **k: "step"), \
                mock.patch.object(loop.acquisition, "review_defects", lambda *a, **k: []):
            self.assertEqual(f.drive(1, label_deferred=True, acquisition_profile="p"), ["awaiting_labels"])
            self.assertIn("acquisition", json.loads((paths.RESULTS / "r" / "options.json").read_text())["semantic"])
            self.refused(f, w, lambda: loop.run_loop(f.options(label_deferred=True, max_iterations=3)), "acquisition")


class PinnedHints(unittest.TestCase):
    """The operator's hints a planning session reads are the run's: recorded with their digest at the
    run's start (an absent file recorded as absent), read from that record afterwards whatever the file
    becomes, refused when the record does not match its digest, and handed over with the run."""

    def test_the_hints_are_pinned_at_the_run_start(self):
        for start in (None, "prefer the stop line\n"):
            with self.subTest(start=start):
                w = split_world()
                with Fixture(w, **SPLIT) as f, mock.patch.object(handoff, "toolchain", lambda: TOOLCHAIN):
                    if start is not None:
                        paths.USER_HINTS.write_text(start)
                    f.drive(1, label_deferred=True)
                    run = Run(f.options(label_deferred=True))
                    pinned = json.loads(run.hints_file.read_text())
                    self.assertEqual(pinned["present"], start is not None)
                    self.assertEqual(run.read_hints(), start or "(none)\n")
                    paths.USER_HINTS.write_text("a later edit\n")                          # the file changes after the start
                    self.assertEqual(run.read_hints(), start or "(none)\n")
                    self.assertIn("results/r/user_hints.json", handoff.export("r")["artifacts"])
                    run.hints_file.write_text(json.dumps({**pinned, "text": "tampered"}))
                    with self.assertRaises(jsonl.DataIntegrityError):
                        run.read_hints()


    def test_a_lost_record_is_refused_never_rebuilt(self):
        """A run whose hints record is lost stops on it: it is never rebuilt, neither from the file as it
        stands now nor as absent."""
        for start in ("prefer the stop line\n", None):
            with self.subTest(start=start):
                w = split_world()
                with Fixture(w, **SPLIT) as f, mock.patch.object(handoff, "toolchain", lambda: TOOLCHAIN):
                    if start is not None:
                        paths.USER_HINTS.write_text(start)
                    f.drive(1, label_deferred=True)
                    run = Run(f.options(label_deferred=True))
                    paths.USER_HINTS.write_text("edited after the start\n")
                    run.hints_file.unlink()
                    before = dict(w.calls)
                    res = loop.run_loop(f.options(label_deferred=True, max_iterations=3))
                    self.assertEqual(res["status"], "data_integrity_failure")
                    self.assertIn("user_hints.json", res["stop_reason"])
                    self.assertFalse(run.hints_file.exists())                       # not rebuilt
                    self.assertEqual(dict(w.calls), before)                         # no session ran on other hints
                    with self.assertRaises(jsonl.DataIntegrityError):
                        run.read_hints()
                    self.assertFalse(run.hints_file.exists())


class DoctorTools(unittest.TestCase):
    """The doctor's split tool lies outside the agent directory: it is found beside it (the
    WorldModelSpec layout a run's checkout has) before PYTHONPATH, pinned in the code digest, and its
    absence fails the doctor's check with a message that says where it belongs."""

    def test_where_the_tool_is_found_and_what_its_absence_does(self):
        from scripts.diagnostics.library_v2 import LibraryV2Checks
        from scripts.diagnostics.doctor_result import FAIL
        with tempfile.TemporaryDirectory() as t:
            t = Path(t)
            beside, elsewhere = t / "ontology_provenance", t / "elsewhere"
            for d in (beside, elsewhere):
                (d / "nrs_tools").mkdir(parents=True)
                (d / "nrs_tools" / "atoms_train.py").write_text(f"# {d.name}\n")
            with mock.patch.object(paths, "ONTOLOGY_TOOLS", beside), mock.patch("sys.path", [str(elsewhere)]):
                self.assertEqual(paths.ontology_tool("atoms_train"), (beside / "nrs_tools" / "atoms_train.py").resolve())
                self.assertIsNotNone(handoff.code_digest()["files"][handoff.DOCTOR_TOOL])
            with mock.patch.object(paths, "ONTOLOGY_TOOLS", t / "absent"), mock.patch("sys.path", [str(elsewhere)]):
                self.assertEqual(paths.ontology_tool("atoms_train"), (elsewhere / "nrs_tools" / "atoms_train.py").resolve())
            with mock.patch.object(paths, "ONTOLOGY_TOOLS", t / "absent"), mock.patch("sys.path", []):
                self.assertIsNone(paths.ontology_tool("atoms_train"))
                self.assertIsNone(handoff.code_digest()["files"][handoff.DOCTOR_TOOL])
        with mock.patch.object(paths, "ontology_tool", lambda name: None):
            r = LibraryV2Checks(paths.REPO, paths.LIBRARY).training_split_in_sync()
        self.assertEqual(r.status, FAIL)
        self.assertIn("whole WorldModelSpec repository", r.detail)


class CodeDigestCoverage(unittest.TestCase):
    """The baseline digest covers, by pattern, every tracked file whose content decides a run's results:
    the harness and the recorded-data code, Core with its root module, the monitor and Explain, the
    prompts, the ontology, the configuration, the Lean build files and the region-kind exporter the
    harness runs; tests, documentation and derived run records are not code."""

    def test_the_patterns_cover_the_result_deciding_files_of_this_tree(self):
        import subprocess
        tracked = subprocess.run(["git", "ls-files"], cwd=paths.REPO, capture_output=True, text=True, check=True).stdout.split()
        if not tracked:
            self.skipTest("not a git checkout")
        covered = {p.relative_to(paths.REPO).as_posix() for p in handoff.code_files()}
        deciding = [f for f in tracked
                    if (f.startswith(("harness/", "recorded/")) and f.endswith(".py"))
                    or (f.startswith("library/TrafficSpec/Core") and f.endswith(".lean"))
                    or f.startswith(("prompts/", "ontology/", "config/"))
                    or f in ("library/Explain.lean", "library/Main.lean", "library/lean-toolchain", "library/lakefile.lean",
                             "library/lake-manifest.json", "scripts/RegionKinds.lean", "scripts/run-generation.sh", "pyproject.toml",
                             "scripts/gen_ontology.py", "scripts/__init__.py")
                    or (f.startswith("scripts/diagnostics/") and f.endswith(".py"))]
        self.assertEqual(sorted(f for f in deciding if (paths.REPO / f).is_file() and f not in covered), [])
        for f in ("library/TrafficSpec/Core.lean", "library/TrafficSpec/Core/Foundations/Accumulate.lean",
                  "library/TrafficSpec/Core/Language/Formula.lean", "scripts/RegionKinds.lean", "harness/checks/gate.py",
                  "harness/phases/candidate.py", "harness/tools/handoff.py", "prompts/code.md", "scripts/diagnostics/doctor.py",
                  "scripts/diagnostics/library_v2.py", "scripts/diagnostics/doctor_result.py", "scripts/run-generation.sh",
                  "pyproject.toml"):
            self.assertIn(f, covered)
        for f in ("scripts/tests/test_act_declarations.py", "library/TrafficSpec/Tests/HeadingSince.lean", "README.md"):
            self.assertNotIn(f, covered)

if __name__ == "__main__":
    unittest.main()
