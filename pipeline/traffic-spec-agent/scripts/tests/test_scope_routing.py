"""A coding session's scope violation is the coder's defect, not the plan's or the contract's.

- The record is coded again as it is: no node repair, concept repair or plan session sees it, and no
  plan, node or concept attempt is counted; the violations of one record are counted apart
  (`SCOPE_BOUND`), and the bound reached holds the law for the operator (`scope_budget`), never a
  return to the planner.
- A session that changed a file outside its own leaves the library dirty (its own rollback restores only
  its two files): no coding session starts while a file it named is not back at the digest its task's
  `baseline.json` recorded; the run stops `awaiting_operator`, every later launch stops the same way
  without a session, and once the operator has restored the file the same record is coded again.

The loop, ledgers and scheduling are the real ones on the scripted world of `test_recovery`."""
import json
import unittest
from pathlib import Path
from unittest import mock

from harness.checks import gate
from harness.model import nodeid
from harness.phases import code as code_phase
from harness.store import paths
from scripts.tests.test_recovery import Fixture, World, _iteration_of, concept, node

OTHER = "TrafficSpec/Rules/Other.lean"


def two_laws() -> World:
    w = World({"L-20": "shall slow.", "L-21": "shall stop."})
    w.plans = {"L-20": [node("L_20", "shall slow.", "L-20")], "L-21": [node("L_21", "shall stop.", "L-21")]}
    return w


def one_concept() -> World:
    w = World({"L-25": "shall creep."})
    w.plans = {"L-25": [concept("drv.motion.creep", users=["L_25"]), node("L_25", "shall creep.", "L-25", derived=["drv.motion.creep"])]}
    return w


def ledger(f) -> dict:
    return {e["law"]: e for e in f.state()["ledger"]}


def calls(w, kind) -> list:
    return sorted((i, it) for (k, i, it), n in w.calls.items() if k == kind for _ in range(n))


class Dirty:
    """The scripted gate, except that the coding sessions of `at` ((id, iteration)) overwrite a file
    outside their own (`OTHER`), which the real scope check then names."""

    def __init__(self, at):
        self.at = set(at)

    def __enter__(self):
        scripted = gate.run_gate

        def run_gate(n, reading, baseline, d, budget_used=0, budget=0, accepted_concepts=None, acquisition=None):
            if (n.id, _iteration_of(Path(d))) in self.at:
                (paths.LIBRARY / OTHER).write_text("-- overwritten by another node's session\n")
                own = {gate.lib_rel(nodeid.rule_path(n.id)), gate.lib_rel(nodeid.witness_path(n.id))}
                stray = gate.scope_stray(baseline, own, Path(d))
                return gate.Verdict("SCOPE_VIOLATION", [f"changed outside the node's files: {stray}"], extras={"stray": stray})
            return scripted(n, reading, baseline, d, budget_used, budget, accepted_concepts)
        self.patch = mock.patch.object(gate, "run_gate", run_gate)
        self.patch.__enter__()
        return self

    def __exit__(self, *exc):
        return self.patch.__exit__(*exc)


class GateNamesEveryStrayFile(unittest.TestCase):
    def test_the_verdict_carries_the_whole_list_beyond_the_details(self):
        import tempfile
        from harness.model.blueprint import ConceptRecord, Node
        stray = [f"library/TrafficSpec/Rules/X{i}.lean" for i in range(10)]
        with tempfile.TemporaryDirectory() as t, mock.patch.object(gate, "scope_stray", lambda *a: list(stray)), \
                mock.patch.object(gate, "reading_input_defects", lambda r: None):
            for v in (gate.run_gate(Node(node("L_20", "shall slow.", "L-20")), None, {}, Path(t) / "n", 0, 5),
                      gate.run_concept_gate(ConceptRecord(concept("drv.motion.creep")), None, {}, Path(t) / "c", 0, 5)):
                self.assertEqual((v.verdict, v.extras.get("stray")), ("SCOPE_VIOLATION", stray))
                self.assertIn("… and 2 more", v.details)


class NoPlannerNoContract(unittest.TestCase):
    def test_a_node_violation_is_coded_again_as_it_is_uncharged(self):
        w = two_laws()
        w.gate[("L_20", 1)] = "SCOPE_VIOLATION"
        with Fixture(w) as f:
            self.assertEqual(f.drive(1), ["complete"])
            self.assertEqual(calls(w, "plan"), [("L-20,L-21", 1)])
            self.assertEqual(calls(w, "node_repair"), [])
            led = ledger(f)
            self.assertEqual((led["L-20"]["state"], led["L-20"]["attempts"], led["L-20"].get("scope_violations")), ("accepted", 0, {"L_20": 1}))
            self.assertEqual(w.calls[("code", "L_20", 2)], 1)
            self.assertEqual(f.state()["node_ledger"], [])
            d1, d2 = (paths.RESULTS / "r" / f"iter-00{i}" / "code" / "L_20" / "node.json" for i in (1, 2))
            self.assertEqual(json.loads(d1.read_text()), json.loads(d2.read_text()))     # the same record

    def test_a_concept_violation_never_reaches_a_repair_or_its_contract(self):
        w = one_concept()
        w.gate[("drv.motion.creep", 1)] = "SCOPE_VIOLATION"
        with Fixture(w) as f:
            self.assertEqual(f.drive(1), ["complete"])
            self.assertEqual(calls(w, "concept_repair"), [])
            c = {x["concept"]: x for x in f.state()["concept_ledger"]}["drv.motion.creep"]
            self.assertEqual((c["state"], c["attempts"], c.get("scope_violations")), ("accepted", 0, 1))
            self.assertEqual(calls(w, "plan"), [("L-25", 1)])
            self.assertEqual(w.calls[("code", "drv.motion.creep", 2)], 1)
            name = code_phase.concept_dirname("drv.motion.creep")
            d1, d2 = (paths.RESULTS / "r" / f"iter-00{i}" / "code" / name / "concept.json" for i in (1, 2))
            self.assertEqual(json.loads(d1.read_text())["contract"], json.loads(d2.read_text())["contract"])
            self.assertEqual(ledger(f)["L-25"]["attempts"], 0)


class DirtyLibraryPauses(unittest.TestCase):
    def test_no_session_starts_until_the_file_is_restored_then_the_same_record_is_coded(self):
        w = two_laws()
        with Fixture(w, workers=1) as f, Dirty({("L_20", 1)}):
            (paths.LIBRARY / OTHER).parent.mkdir(parents=True, exist_ok=True)
            (paths.LIBRARY / OTHER).write_text("-- other\n")
            self.assertEqual(f.drive(1), ["awaiting_operator"])
            order = [e[2] for e in w.log if e[:2] == ("call", "code")]
            self.assertEqual(order[-1], "L_20")                           # nothing coded after the violation
            self.assertEqual(w.calls[("code", "L_21", 1)], 0)
            summary = json.loads((paths.RESULTS / "r" / "summary.json").read_text())
            self.assertIn("library/" + OTHER, summary["stop_reason"])
            led = ledger(f)
            self.assertEqual({k: (e["state"], e["attempts"]) for k, e in led.items()}, {"L-20": ("planned", 0), "L-21": ("planned", 0)})
            before = dict(w.calls)
            self.assertEqual(f.drive(1), ["awaiting_operator"])           # still dirty: no session of any kind
            self.assertEqual(dict(w.calls), before)
            (paths.LIBRARY / OTHER).write_text("-- other\n")             # the operator restores the one file
            self.assertEqual(f.drive(1), ["complete"])
            self.assertEqual((w.calls[("code", "L_20", 2)], w.calls[("code", "L_21", 2)]), (1, 1))
            self.assertEqual(calls(w, "plan"), [("L-20,L-21", 1)])
            self.assertTrue((paths.RESULTS / "r" / "iter-001" / "code" / "L_20" / code_phase.SCOPE_RESTORED).exists())
            self.assertEqual({k: (e["state"], e["attempts"]) for k, e in ledger(f).items()}, {"L-20": ("accepted", 0), "L-21": ("accepted", 0)})

    def test_a_restored_file_changed_later_pauses_nothing(self):
        w = two_laws()
        with Fixture(w, workers=1) as f, Dirty({("L_20", 1)}):
            (paths.LIBRARY / OTHER).parent.mkdir(parents=True, exist_ok=True)
            (paths.LIBRARY / OTHER).write_text("-- other\n")
            self.assertEqual(f.drive(1), ["awaiting_operator"])
            (paths.LIBRARY / OTHER).write_text("-- other\n")
            from harness.store.state import Run
            run = Run(f.options())
            self.assertEqual(code_phase.scope_unrestored(run), {})
            (paths.LIBRARY / OTHER).write_text("-- a later change of its own\n")
            self.assertEqual(code_phase.scope_unrestored(run), {})


class NoReportOfAViolatingSession(unittest.TestCase):
    def test_the_report_is_kept_never_judged(self):
        """A coder that ended SCOPE_VIOLATION wrote a dependency report: it stays in the task directory,
        and no report is judged (so no judge or adjudicator runs and no ruling is written)."""
        from harness.phases import review as review_phase
        w = two_laws()
        judged = []
        with Fixture(w, workers=1) as f, Dirty({("L_20", 1)}), \
                mock.patch.object(review_phase, "dependency_report",
                                  lambda run, task, reached: judged.append(Path(task).name) or review_phase.DependencyReport("none")):
            (paths.LIBRARY / OTHER).parent.mkdir(parents=True, exist_ok=True)
            (paths.LIBRARY / OTHER).write_text("-- other\n")
            real = gate.run_gate

            def with_report(n, reading, baseline, d, *a, **k):
                (Path(d) / "dependency_defect.json").write_text("{}")
                return real(n, reading, baseline, d, *a, **k)
            with mock.patch.object(gate, "run_gate", with_report):
                self.assertEqual(f.drive(1), ["awaiting_operator"])
            self.assertNotIn("L_20", judged)
            self.assertTrue((paths.RESULTS / "r" / "iter-001" / "code" / "L_20" / "dependency_defect.json").exists())
            self.assertFalse((paths.RESULTS / "r" / "rulings.jsonl").exists())


class ReopenIsNoRestoration(unittest.TestCase):
    def test_reopen_alone_leaves_the_pause(self):
        """Reopening the law clears its ledger state and counts, not the evidence: the library is still
        dirty, no mark is written, and the next launch stops again without a session."""
        from harness.__main__ import Cli
        from harness.store.state import Run
        w = two_laws()
        with Fixture(w, workers=1) as f, Dirty({("L_20", 1)}), mock.patch("harness.store.owner.acquire_for_command", lambda name: None):
            (paths.LIBRARY / OTHER).parent.mkdir(parents=True, exist_ok=True)
            (paths.LIBRARY / OTHER).write_text("-- other\n")
            self.assertEqual(f.drive(1), ["awaiting_operator"])
            Cli().reopen("r", laws="L-20")
            self.assertEqual(ledger(f)["L-20"]["state"], "open")
            self.assertTrue(code_phase.scope_unrestored(Run(f.options())))
            self.assertFalse((paths.RESULTS / "r" / "iter-001" / "code" / "L_20" / code_phase.SCOPE_RESTORED).exists())
            before = dict(w.calls)
            self.assertEqual(f.drive(1), ["awaiting_operator"])
            self.assertEqual(dict(w.calls), before)


class ScopeBudget(unittest.TestCase):
    def test_a_node_at_the_bound_is_held_for_the_operator_never_re_planned(self):
        w = two_laws()
        w.gate[("L_20", 1)] = w.gate[("L_20", 2)] = "SCOPE_VIOLATION"
        with Fixture(w) as f:
            f.drive(1)
            self.assertEqual(calls(w, "plan"), [("L-20,L-21", 1)])
            e = ledger(f)["L-20"]
            self.assertEqual((e["state"], e["gaps"], e["attempts"], e.get("scope_violations")), ("blocked", ["decision:L-20"], 0, {"L_20": 2}))
            self.assertTrue(e["reasons"][0].startswith("scope_budget:"), e["reasons"])
            self.assertNotIn("attempt budget", " ".join(e["reasons"]))
            self.assertEqual(calls(w, "plan"), [("L-20,L-21", 1)])
            self.assertEqual(calls(w, "node_repair"), [])
            self.assertTrue(any("scope_budget" in x for x in f.state()["to_user"]))

    def test_a_concept_at_the_bound_holds_its_users_and_keeps_its_contract(self):
        w = one_concept()
        w.gate[("drv.motion.creep", 1)] = w.gate[("drv.motion.creep", 2)] = "SCOPE_VIOLATION"
        with Fixture(w) as f:
            f.drive(1)
            self.assertEqual(calls(w, "concept_repair"), [])
            c = {x["concept"]: x for x in f.state()["concept_ledger"]}["drv.motion.creep"]
            self.assertEqual((c["state"], c["attempts"], c.get("scope_violations"), c["held_laws"]), ("planned", 0, 2, ["L-25"]))
            self.assertTrue(c["reasons"][0].startswith("scope_budget:"), c["reasons"])
            e = ledger(f)["L-25"]
            self.assertEqual((e["state"], e["gaps"], e["attempts"]), ("blocked", ["decision:L-25"], 0))
            self.assertEqual(calls(w, "concept_repair"), [])
            self.assertEqual(calls(w, "plan"), [("L-25", 1)])


if __name__ == "__main__":
    unittest.main()
