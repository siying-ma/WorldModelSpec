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


class PlanWaits(unittest.TestCase):
    """Failure closes over every law first and takes precedence; waiting closes over what is left."""

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
            self.assertEqual(set(failed), {"S-1", "S-2"}, order)
            self.assertNotIn("S-1", waiting)
            self.assertEqual(b, [])

    def test_a_failure_reached_through_a_waiting_law(self):
        laws = {"A-1": "[A-2]", "A-2": "[A-3] and [P-1]", "A-3": "[F-1]", "P-1": "", "F-1": ""}
        b, waiting, failed = self.batches(laws, {"P-1": "planned", "F-1": "failed"})
        self.assertEqual(set(failed), {"A-1", "A-2", "A-3"})
        self.assertEqual(waiting, {})

    def test_controls(self):
        laws = {"C-1": "[C-2]", "C-2": "[P-1]", "P-1": "", "D-1": "[E-1]", "E-1": ""}
        b, waiting, failed = self.batches(laws, {"P-1": "planned", "E-1": "accepted"})
        self.assertEqual(set(waiting), {"C-1", "C-2"})
        self.assertEqual(failed, {})
        self.assertEqual(b, [["D-1"]])


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
