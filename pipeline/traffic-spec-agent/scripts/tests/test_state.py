"""Development regression tests for a run's state: the law life cycle and within-attempt severity, the
snapshot and its projections, the per-node judge counts, decided gaps, and integration's attribution."""
import json
import tempfile
import unittest
from pathlib import Path

from harness.store import paths
from harness.store.gaps import GapLedger
from harness.store.ledger import ConceptLedger, Ledger, NodeLedger
from harness.store.state import Options, Run, RUN_VERSION, commit_state
_RESULTS = {}


def setUpModule():
    """Every gap these tests file is measured under a temporary results tree, never the run's."""
    _RESULTS["tmp"] = tempfile.TemporaryDirectory()
    _RESULTS["saved"] = paths.RESULTS
    paths.RESULTS = Path(_RESULTS["tmp"].name)


def tearDownModule():
    paths.RESULTS = _RESULTS["saved"]
    _RESULTS["tmp"].cleanup()


ONTO = Path(__file__).resolve().parents[2] / "ontology" / "ATOMS_train.md"


class LifeCycle(unittest.TestCase):
    def ledger(self, attempts=2):
        tmp = tempfile.TemporaryDirectory(); self.addCleanup(tmp.cleanup)
        led = Ledger(Path(tmp.name) / "ledger.jsonl", ["L"], attempts)
        led.attempt = 1
        led.mark_planned("L", ["n1", "n2"], 1)
        return led

    def test_sibling_outcomes_combine_by_severity_in_either_order(self):
        a = self.ledger(); a.return_law("L", ["n1 returned"], 1); a.fail("L", ["n2 failed"])
        b = self.ledger(); b.fail("L", ["n2 failed"]); b.return_law("L", ["n1 returned"], 1)
        self.assertEqual((a.entries["L"].state, b.entries["L"].state), ("failed", "failed"))
        c = self.ledger(); c.block("L", ["g1"], ["n1 blocked"]); c.return_law("L", ["n2 returned"], 1)
        d = self.ledger(); d.return_law("L", ["n2 returned"], 1); d.block("L", ["g1"], ["n1 blocked"])
        self.assertEqual((c.entries["L"].state, d.entries["L"].state), ("blocked", "blocked"))

    def test_a_terminal_state_of_an_earlier_attempt_stands(self):
        led = self.ledger(); led.fail("L", ["spent"])
        led.attempt = 2
        self.assertFalse(led.mark_planned("L", ["n1"], 2))
        led.return_law("L", ["late"], 2); led.hold("L", 2); led.defer("L", ["outage"])
        self.assertEqual(led.entries["L"].state, "failed")

    def test_acceptance_only_from_planned_and_one_charge_per_attempt(self):
        led = self.ledger(attempts=3)
        led.return_law("L", ["a"], 1); led.return_law("L", ["b"], 1)
        self.assertEqual((led.entries["L"].state, led.entries["L"].attempts), ("returned", 1))
        led.accept("L", ["n1"])
        self.assertEqual(led.entries["L"].state, "returned")

    def test_an_outage_keeps_the_plan(self):
        led = self.ledger(); led.defer("L", ["sessions down"])
        self.assertEqual((led.entries["L"].state, led.entries["L"].attempts), ("planned", 0))


class DependencyReturns(unittest.TestCase):
    """A concept's failure returns the laws whose nodes use it without spending their plan attempts:
    it counts a dependency return, once per failed concept and at most once per iteration, and a law
    fails on its dependencies only when those returns exceed the plan attempts."""
    CALLERS = ["L1", "L2", "L3", "L4", "L5", "L6"]

    def ledger(self, laws=None, attempts=2):
        tmp = tempfile.TemporaryDirectory(); self.addCleanup(tmp.cleanup)
        led = Ledger(Path(tmp.name) / "ledger.jsonl", laws or self.CALLERS, attempts)
        return led

    def iteration(self, led, n, laws=None):
        led.attempt = n
        for law in laws or self.CALLERS:
            led.mark_planned(law, [law + "_n"], n)

    def test_one_concept_failure_with_six_callers_spends_no_attempt(self):
        led = self.ledger(); self.iteration(led, 1)
        for law in self.CALLERS:
            led.return_for_concepts(law, ["drv.c1"], ["uses drv.c1, failed"], 1)
        for law in self.CALLERS:
            e = led.entries[law]
            self.assertEqual((e.state, e.attempts, e.dependency_returns), ("returned", 0, 1))

    def test_distinct_failed_concepts_count_until_the_budget_is_exceeded(self):
        led = self.ledger(["L"]); self.iteration(led, 1, ["L"])
        led.return_for_concepts("L", ["drv.c1"], ["c1 failed"], 1)
        self.iteration(led, 2, ["L"])
        led.return_for_concepts("L", ["drv.c2"], ["c2 failed"], 2)
        e = led.entries["L"]
        self.assertEqual((e.state, e.attempts, e.dependency_returns), ("returned", 0, 2))
        self.iteration(led, 3, ["L"])
        led.return_for_concepts("L", ["drv.c3"], ["c3 failed"], 3)
        self.assertEqual((e.state, e.attempts, e.dependency_returns), ("failed", 0, 3))
        self.assertEqual(e.reasons[0], "dependency budget (2) spent: drv.c1, drv.c2, drv.c3")

    def test_own_attempts_and_dependency_returns_are_apart(self):
        led = self.ledger(["L"]); self.iteration(led, 1, ["L"])
        led.return_law("L", ["its own node returned"], 1)
        self.iteration(led, 2, ["L"])
        led.return_for_concepts("L", ["drv.c1"], ["c1 failed"], 2)
        self.iteration(led, 3, ["L"])
        led.return_for_concepts("L", ["drv.c2"], ["c2 failed"], 3)
        e = led.entries["L"]
        self.assertEqual((e.state, e.attempts, e.dependency_returns), ("returned", 1, 2))

    def test_the_same_concept_or_the_same_iteration_counts_once(self):
        led = self.ledger(["L"]); self.iteration(led, 1, ["L"])
        led.return_for_concepts("L", ["drv.c1"], ["c1 failed"], 1)
        led.return_for_concepts("L", ["drv.c2"], ["c2 failed in the same iteration"], 1)
        self.iteration(led, 2, ["L"])
        led.return_for_concepts("L", ["drv.c1"], ["c1 still failed"], 2)
        e = led.entries["L"]
        self.assertEqual((e.state, e.attempts, e.dependency_returns), ("returned", 0, 1))
        self.assertEqual(e.charged_concepts, ["drv.c1", "drv.c2"])

    def test_the_boundary_two_dependency_returns_re_plan_the_third_closes(self):
        led = self.ledger(["L"], attempts=2)
        for n, c in ((1, "drv.c1"), (2, "drv.c2")):
            self.iteration(led, n, ["L"]); led.return_for_concepts("L", [c], [c + " failed"], n)
            self.assertEqual(led.entries["L"].state, "returned")                  # re-planned
        self.assertTrue(led.mark_planned("L", ["L_n"], 3))
        led.attempt = 3; led.return_for_concepts("L", ["drv.c3"], ["c3 failed"], 3)
        self.assertEqual((led.entries["L"].state, led.entries["L"].dependency_returns), ("failed", 3))

    def test_only_the_dependencies_that_cause_the_return_are_registered(self):
        from harness.loop import dependency_causes
        # A failed, B pending (returned with a repair to come): the return is A's alone
        states, repairable = {"drv.a": "failed", "drv.b": "returned"}, {"drv.b"}
        self.assertEqual(dependency_causes(states, repairable), ["drv.a"])
        self.assertEqual(dependency_causes({"drv.b": "planned"}, set()), [])            # waiting or under repair: no cause
        self.assertEqual(dependency_causes({"drv.c": "not proposed", "drv.d": "returned"}, set()), ["drv.c", "drv.d"])
        tmp = tempfile.TemporaryDirectory(); self.addCleanup(tmp.cleanup)
        path = Path(tmp.name) / "ledger.jsonl"
        led = Ledger(path, ["L"], 2); self.iteration(led, 1, ["L"])
        led.return_for_concepts("L", dependency_causes(states, repairable), ["uses drv.a, failed"], 1)
        e = led.entries["L"]
        self.assertEqual((e.dependency_returns, e.charged_concepts, e.attempts), (1, ["drv.a"], 0))
        led.save()
        led = Ledger(path, ["L"], 2)                                                     # a restart between the iterations
        self.assertEqual((led.entries["L"].dependency_returns, led.entries["L"].charged_concepts), (1, ["drv.a"]))
        self.iteration(led, 2, ["L"])                                                    # B fails at the next iteration
        states = {"drv.a": "failed", "drv.b": "failed"}
        led.return_for_concepts("L", dependency_causes(states, set()), ["uses drv.b, failed"], 2)
        e = led.entries["L"]
        self.assertEqual((e.state, e.dependency_returns, e.charged_concepts, e.attempts), ("returned", 2, ["drv.a", "drv.b"], 0))

    def test_reopen_resets_both_counters(self):
        led = self.ledger(["L"]); self.iteration(led, 1, ["L"])
        led.return_law("L", ["own"], 1)
        for n, c in ((2, "drv.c1"), (3, "drv.c2"), (4, "drv.c3")):
            self.iteration(led, n, ["L"]); led.return_for_concepts("L", [c], [c + " failed"], n)
        e = led.entries["L"]
        self.assertEqual(e.state, "failed")
        self.assertEqual(led.reopen(["L"]), ["L"])
        self.assertEqual((e.state, e.attempts, e.dependency_returns, e.dependency_iteration, e.charged_concepts),
                         ("open", 0, 0, 0, []))

    def test_a_ledger_written_before_the_counter_loads_with_zero(self):
        with tempfile.TemporaryDirectory() as t:
            path = Path(t) / "ledger.jsonl"
            path.write_text(json.dumps({"law": "L", "state": "returned", "attempts": 1, "reasons": ["r"], "nodes": [],
                                        "gaps": [], "iteration": 1, "charged_iteration": 1,
                                        "charged_concepts": ["drv.c1"], "repeats": {}, "selection_corrections": 0,
                                        "outcome_iteration": 1}) + "\n", encoding="utf-8")
            e = Ledger(path, ["L"], 2).entries["L"]
            self.assertEqual((e.attempts, e.dependency_returns, e.dependency_iteration, e.charged_concepts),
                             (1, 0, 0, ["drv.c1"]))


class JudgeCounts(unittest.TestCase):

    def test_concept_judge_failure_closes_only_for_judge_stages(self):
        with tempfile.TemporaryDirectory() as t:
            cl = ConceptLedger(Path(t) / "c.jsonl", 3)
            cl.planned("c", ["n"], 1)
            self.assertFalse(cl.defer_judge("c", "reviewer", ["unusable"]))
            self.assertTrue(cl.defer_judge("c", "reviewer", ["unusable"]))      # the caller pauses its users
            self.assertNotEqual(cl.entries["c"].state, "failed")
            self.assertFalse(cl.defer_judge("c", "concept_adjudication", ["invalid"]))
            self.assertTrue(cl.defer_judge("c", "concept_adjudication", ["invalid"]))
            self.assertEqual(cl.entries["c"].state, "failed")


class Snapshot(unittest.TestCase):
    def test_projections_are_rebuilt_from_the_snapshot(self):
        with tempfile.TemporaryDirectory() as t:
            saved = paths.RESULTS
            paths.RESULTS = Path(t)
            try:
                opts = Options(run_id="r", laws=Path(t) / "laws.jsonl", ontology=ONTO, reading=Path(t) / "reading.json")
                run = Run(opts); run.dir.mkdir(parents=True)
                (run.dir / "options.json").write_text(json.dumps({"run_id": "r", "laws": str(opts.laws), "ontology": str(ONTO),
                                                                  "reading": str(opts.reading), "label_repair": False,
                                                                  "dependency": "build_usable_v1", "semantic": {"run_version": RUN_VERSION}}))
                run.iteration = 3
                led = Ledger(run.ledger_file, ["L"], 2); led.attempt = 3; led.mark_planned("L", ["n"], 3)
                cl, nl = ConceptLedger(run.concept_ledger_file, 3), NodeLedger(run.node_ledger_file, 2)
                run.accepted_nodes = {"n": {"node_id": "n"}}
                commit_state(run, led, cl, nl, {"stage": "nodes"})
                run.ledger_file.write_text("")                   # a commit cut short after the snapshot
                run.accepted_file.unlink()
                again = Run.load("r")
                self.assertEqual(again.iteration, 3)
                self.assertEqual(Ledger(again.ledger_file, [], 2).entries["L"].state, "planned")
                self.assertIn("n", again.accepted_nodes)
                self.assertEqual(again.load_state()["prog"]["stage"], "nodes")
            finally:
                paths.RESULTS = saved


class DecidedGaps(unittest.TestCase):
    def test_a_decided_gap_is_not_reopened_by_a_recurrence(self):
        with tempfile.TemporaryDirectory() as t:
            g = GapLedger(Path(t))
            p = {"kind": "no_atom", "span_text": "w", "law_refs": ["L"]}
            gid = g.add(p, "r", 1)
            self.assertEqual(g.add(p, "r", 2), gid)                  # undecided: the same gap
            g.decide(gid, "rejected", "carry it with the existing atom", resolved_by="particular")
            self.assertEqual(g.add(p, "r", 3), gid)                  # decided: routed back with the decision
            self.assertEqual(g.decision(gid), ("rejected", "carry it with the existing atom"))
            linked = g.add({**p, "linked_to": gid, "excluding_clause": "clause 2 excludes it"}, "r", 4)
            self.assertNotEqual(linked, gid)                         # a linked new proposal, for the operator

    def test_the_same_words_twice_are_two_gaps(self):
        with tempfile.TemporaryDirectory() as t:
            g = GapLedger(Path(t))
            p = {"kind": "atom", "span_text": "shall stop", "law_refs": ["L"]}
            a = g.add({**p, "occurrence": "L@d:10-20"}, "r", 1)
            b = g.add({**p, "occurrence": "L@d:40-50"}, "r", 1)
            self.assertNotEqual(a, b)
            self.assertEqual(g.add({**p, "occurrence": "L@d:10-20"}, "r", 2), a)


class IntegrationAttribution(unittest.TestCase):
    """A failure is charged to the candidate it names; a consumer of a rejected provider waits; a
    failure no one owns is never charged to the newest candidate."""
    def setUp(self):
        from harness.phases import integrate
        self.integrate = integrate
        self.tmp = tempfile.TemporaryDirectory()
        self.saved = (paths.LIBRARY, integrate.verify_library, integrate.rollback, integrate.rollback_concept, integrate.validate_a.acyclic)
        paths.LIBRARY = Path(self.tmp.name) / "lib"; paths.LIBRARY.mkdir()
        self.removed = []
        integrate.rollback = lambda i, b, d: self.removed.append(i)
        integrate.rollback_concept = lambda i, b, d: self.removed.append(i)
        integrate.validate_a.acyclic = lambda nodes: []

    def tearDown(self):
        (paths.LIBRARY, self.integrate.verify_library, self.integrate.rollback, self.integrate.rollback_concept,
         self.integrate.validate_a.acyclic) = self.saved
        self.tmp.cleanup()

    def run_it(self, verdicts):
        from types import SimpleNamespace
        from harness.model.blueprint import Node
        seq = list(verdicts)
        self.integrate.verify_library = lambda work, reading: seq.pop(0)
        run = SimpleNamespace(iter=Path(self.tmp.name) / "iter-001", accepted_nodes={})
        n = Node({"node_id": "N_1", "law_refs": ["L"], "compositions": []})
        n.compositions = lambda: []
        import harness.loop as loop
        saved = loop.concept_deps
        loop.concept_deps = lambda node: {"drv.motion.one"}
        try:
            return self.integrate.run_integrate(run, [n], None, {}, ["drv.motion.one"], {}, {})
        finally:
            loop.concept_deps = saved

    def test_a_named_provider_is_rejected_and_its_consumer_waits(self):
        r = self.run_it([("failed", ["c.one\tw1: bad"], {"drv.motion.one"}), ("verified", [], set())])
        self.assertEqual((r["status"], list(r["rejected"]), list(r["waiting"])), ("candidates_rejected", ["drv.motion.one"], ["N_1"]))

    def test_an_unnamed_failure_is_tried_one_candidate_at_a_time(self):
        r = self.run_it([("failed", ["?"], set()), ("verified", [], set()), ("verified", [], set()), ("failed", ["N_1\tw: bad"], set())])
        self.assertEqual((r["status"], list(r["rejected"]), r["kept_concepts"]), ("candidates_rejected", ["N_1"], ["drv.motion.one"]))

    def test_infrastructure_charges_no_one(self):
        r = self.run_it([("infrastructure", ["lake did not run"], set())])
        self.assertEqual((r["status"], r["rejected"], r["waiting"]), ("infrastructure", {}, {}))


class DependencyContext(unittest.TestCase):
    """An accepted candidate's context is versioned: a reading value it reads changes the version;
    a cycle is rejected."""
    def test_a_reading_value_changes_the_version_and_a_cycle_is_rejected(self):
        from types import SimpleNamespace
        from harness.phases import integrate
        from harness.model.reading import Reading
        with tempfile.TemporaryDirectory() as t:
            a = {"node_id": "A_1", "law_refs": ["A-1"], "params": ["p.x"], "compositions": [{"rule": "B_1"}]}
            b = {"node_id": "B_1", "law_refs": ["B-1"], "params": [], "compositions": []}
            run = SimpleNamespace(all_nodes=lambda: {"A_1": a, "B_1": b}, all_concepts=lambda: {})
            rf = Path(t) / "r.json"
            rf.write_text(json.dumps({"params": [{"name": "p.x", "value": 1, "unit": "s"}], "aggregates": []}))
            v1 = integrate.context_version(run, "node", "A_1", Reading(rf), {"core": "c"})
            rf.write_text(json.dumps({"params": [{"name": "p.x", "value": 10, "unit": "s"}], "aggregates": []}))
            v2 = integrate.context_version(run, "node", "A_1", Reading(rf), {"core": "c"})
            self.assertNotEqual(v1, v2)
            self.assertEqual(integrate.context_version(run, "node", "B_1", Reading(rf), {"core": "c"}),
                             integrate.context_version(run, "node", "B_1", Reading(rf), {"core": "c"}))
            b["compositions"] = [{"rule": "A_1"}]
            with self.assertRaises(ValueError):
                integrate.context_version(run, "node", "A_1", Reading(rf), {"core": "c"})

class NoRemovedNames(unittest.TestCase):
    """No code, test or doctor check names a file or a constant that a replacement removed: the
    per-iteration progress and deferral files (the run's snapshot holds them), the gap ledger's single
    file (proposals and decisions apart), the stall stop, the hand-typed unit tables (Core's units are
    read), the tool deny-lists (each session's tool set is declared), and the readers they fed."""
    REMOVED = ["progress.json", "deferred_nodes.jsonl", "deferred_concepts.jsonl", "save_deferred", "load_progress",
               "Gaps/ledger.jsonl", "stall_stop", "first_try_pending", "PUNIT_OF_CORE", "UNITS_CTOR_OF_CORE",
               "PUNIT_JSON", "UNIT_DIMS", "NO_TOOLS", "NO_SEARCH", "disallowed_tools", "replay_upheld", "cert_defects"]

    def test_no_code_names_a_removed_name(self):
        from harness.store import paths
        me = Path(__file__).resolve()
        files = [f for d in ("harness", "scripts") for f in (paths.REPO / d).rglob("*.py") if f.resolve() != me]
        files += sorted((paths.LIBRARY / "TrafficSpec" / "Core").rglob("*.lean"))
        self.assertGreater(len(files), 50)
        hits = [f"{f.relative_to(paths.REPO)}: {n}" for f in files for n in self.REMOVED
                if n in f.read_text(encoding="utf-8", errors="replace")]
        self.assertEqual(hits, [])

if __name__ == "__main__":
    unittest.main()
