"""A gate that judged only the candidate's evaluation (`GATE_TIMEOUT`: the deadline reached while its
scenarios were evaluated, or a resource failure or a panic that recurred in isolation) never accepts
and never counts a plan, node or concept attempt. After a cost failure the saved candidate is gated
again once at the same deadline, without a session, when its context is unchanged (coded again when
it changed); a second failure holds the record for the operator; a panic holds it at once as a Core
defect. A held concept pauses every law reaching it, directly or through other concepts, each once,
at every iteration, resume or restart, and its counts are released once none of the laws it paused is
still paused, by one group reopen or one law at a time on the command line; a user blocked or failed
for another reason is never paused by it and never keeps it held. A semantic gate failure is
charged as before. The counts survive every stop and a restart, are reported in `summary.json` and
`TO_USER.md`, and a ledger written before them loads unchanged."""
import json
import sys
import tempfile
import unittest
from dataclasses import asdict
from pathlib import Path
from unittest import mock

sys.path.insert(0, str(Path(__file__).resolve().parent))
import test_recovery as R                                  # noqa: E402

from harness.store import paths                             # noqa: E402
from harness.store.ledger import GATE_COST_BOUND, ConceptLedger, Ledger, NodeLedger   # noqa: E402


def one_node(law: str, nid: str, text: str, gates: dict, derived=()) -> R.World:
    w = R.World({law: text})
    w.plans = {law: [R.node(nid, text, law, derived=derived)]}
    for (ident, it), v in gates.items():
        w.gate[(ident, it)] = v
    return w


def cost_once() -> R.World:
    """L-20's gate reaches the deadline once; the node is coded again and accepted."""
    return one_node("L-20", "L_20", "shall stop.", {("L_20", 1): "GATE_TIMEOUT"})


def cost_twice() -> R.World:
    """L-21's gate reaches the deadline at both codings: the node is held for the operator."""
    return one_node("L-21", "L_21", "shall yield.", {("L_21", 1): "GATE_TIMEOUT", ("L_21", 2): "GATE_TIMEOUT"})


def panic() -> R.World:
    """L-22's gate evaluation panics in isolation: a Core defect, held at once."""
    return one_node("L-22", "L_22", "shall halt.", {("L_22", 1): "PANIC"})


def semantic() -> R.World:
    """L-23's coder writes outside its node (coded again as it is, uncharged); L-24's gate fails a check
    at both of its node's codings (repaired once uncharged, then charged)."""
    w = R.World({"L-23": "shall wait.", "L-24": "shall merge."})
    w.plans = {"L-23": [R.node("L_23", "shall wait.", "L-23")], "L-24": [R.node("L_24", "shall merge.", "L-24")]}
    w.gate[("L_23", 1)] = "SCOPE_VIOLATION"
    w.gate[("L_24", 1)] = w.gate[("L_24", 2)] = "CHECK_FAIL"
    return w


def concept_cost(times: int):
    def build() -> R.World:
        w = R.World({"L-25": "shall creep."})
        w.plans = {"L-25": [R.concept("drv.motion.creep", users=["L_25"]), R.node("L_25", "shall creep.", "L-25", derived=["drv.motion.creep"])]}
        for it in range(1, times + 1):
            w.gate[("drv.motion.creep", it)] = "GATE_TIMEOUT"
        return w
    build.__doc__ = f"L-25's concept's gate reaches the deadline at {times} coding(s)."
    return build


def summary() -> dict:
    return json.loads((paths.RESULTS / "r" / "summary.json").read_text())


class Interrupted(R.Interruptions):
    """Each scenario run to its end, then stopped at every point and resumed: the ledgers, with the
    counts, end as in the uninterrupted run."""

    def interrupt_everywhere(self, build, points=None, never=()):
        """The interruption check with the run's status compared without its stop reason: a stop after
        the last commit of an iteration that left every law terminal resumes to the same status
        under the loop's other wording, as it does without these counts."""
        state = R.Fixture.state
        with mock.patch.object(R.Fixture, "state", lambda f: {**(st := state(f)), "status": st["status"][0]}):
            return super().interrupt_everywhere(build, points, never)


class Routing(Interrupted, unittest.TestCase):

    def test_a_timeout_neither_charges_an_attempt_nor_closes_the_law(self):
        """…and, the context unchanged, the saved candidate is gated again with no session; it passes
        and is accepted as any candidate is."""
        w = cost_once()
        with R.Fixture(w) as f:
            f.drive()
            ref = f.state()
            rerun = (paths.RESULTS / "r" / "iter-002" / "code" / "L_20" / "rerun_of.txt").read_text()
            lib = (f.dirs["LIBRARY"] / R.nodeid.rule_path("L_20")).read_text()
        e = {x["law"]: x for x in ref["ledger"]}["L-20"]
        self.assertEqual((e["state"], e["attempts"], e["cost_failures"], e["core_panics"]), ("accepted", 0, {"L_20": 1}, []))
        self.assertEqual((w.calls[("plan", "L-20", 1)], w.calls[("code", "L_20", 1)], w.calls[("code", "L_20", 2)]), (1, 1, 0))
        self.assertTrue(rerun.endswith("iter-001/code/L_20"))
        self.assertEqual(lib, "coded L_20 1\n")                 # the candidate the first session wrote is the one accepted
        self.assertEqual(ref["node_ledger"], [])                  # no node coding counted
        self.interrupt_everywhere(cost_once)

    def test_a_changed_context_codes_the_record_again(self):
        from harness.phases import integrate
        w = cost_once()
        with R.Fixture(w) as f:
            f.drive(launches=1, max_iterations=1)
            with mock.patch.object(integrate, "gate_digest", lambda: "another gate"):   # the gate's implementation changed
                f.drive(max_iterations=3)
            ref = f.state()
            rerun = (paths.RESULTS / "r" / "iter-002" / "code" / "L_20" / "rerun_of.txt").exists()
        e = {x["law"]: x for x in ref["ledger"]}["L-20"]
        self.assertEqual((e["state"], e["attempts"], w.calls[("code", "L_20", 2)], rerun), ("accepted", 0, 1, False))

    def test_a_second_timeout_on_the_same_node_holds_it_for_the_operator(self):
        w = cost_twice()
        with R.Fixture(w) as f:
            f.drive()
            ref, s = f.state(), summary()
        e = {x["law"]: x for x in ref["ledger"]}["L-21"]
        self.assertEqual((e["state"], e["gaps"], e["attempts"], e["cost_failures"]), ("blocked", ["decision:L-21"], 0, {"L_21": GATE_COST_BOUND}))
        self.assertTrue(e["reasons"][0].startswith("gate_cost:"))
        self.assertEqual(w.calls[("plan", "L-21", 2)] + w.calls[("plan", "L-21", 3)], 0)   # never re-planned
        self.assertEqual((w.calls[("code", "L_21", 1)], w.calls[("code", "L_21", 2)]), (1, 0))   # the second gate ran on the saved candidate
        self.assertEqual(ref["iterations_allocated"], ["iter-001", "iter-002"])
        self.assertEqual(s["gate_costs"], {"cost_failures": 2, "core_panics": 0, "held_for_operator": ["L_21"]})
        self.assertTrue(any("`L-21` held for you, no attempt counted: gate_cost:" in l and "final/" in l for l in ref["to_user"]))
        self.assertTrue(any("2 ended on the evaluation's cost, 0 panicked" in l and "`L_21`" in l for l in ref["to_user"]))
        self.interrupt_everywhere(cost_twice)

    def test_a_panic_is_routed_as_a_core_defect(self):
        w = panic()
        with R.Fixture(w) as f:
            f.drive()
            ref, s = f.state(), summary()
        e = {x["law"]: x for x in ref["ledger"]}["L-22"]
        self.assertEqual((e["state"], e["gaps"], e["attempts"], e["core_panics"], e["cost_failures"]),
                         ("blocked", ["decision:L-22"], 0, ["L_22"], {}))
        self.assertTrue(e["reasons"][0].startswith("core_defect:"))
        self.assertEqual(sum(c for k, c in w.calls.items() if k[0] in ("plan", "code") and k[2] > 1), 0)   # neither re-planned nor re-coded
        self.assertEqual(s["gate_costs"], {"cost_failures": 0, "core_panics": 1, "held_for_operator": ["L_22"]})
        self.assertTrue(any("core_defect" in l and "PANIC at scripted" in l and "gate_harness.lean" in l for l in ref["to_user"]))
        self.interrupt_everywhere(panic)

    def test_semantic_gate_failures_charge_and_a_scope_violation_does_not(self):
        ref, log, calls, _ = R.reference(semantic)
        led = {x["law"]: x for x in ref["ledger"]}
        self.assertEqual({k: (e["state"], e["attempts"]) for k, e in led.items()}, {"L-23": ("accepted", 0), "L-24": ("accepted", 1)})
        self.assertEqual(led["L-23"]["scope_violations"], {"L_23": 1})
        self.assertEqual((calls[("plan", "L-23", 2)], calls[("node_repair", "L_23", 2)], calls[("code", "L_23", 2)]), (0, 0, 1))
        self.assertEqual((calls[("node_repair", "L_24", 2)], calls[("plan", "L-24", 3)]), (1, 1))

    def test_a_concept_timeout_charges_no_concept_attempt(self):
        ref, log, calls, _ = R.reference(concept_cost(1))
        c = {x["concept"]: x for x in ref["concept_ledger"]}["drv.motion.creep"]
        e = {x["law"]: x for x in ref["ledger"]}["L-25"]
        self.assertEqual((c["state"], c["attempts"], c["cost_failures"]), ("accepted", 0, 1))
        self.assertEqual((e["state"], e["attempts"], e["dependency_returns"]), ("accepted", 0, 0))
        self.assertEqual((calls[("code", "drv.motion.creep", 1)], calls[("code", "drv.motion.creep", 2)]), (1, 0))   # gated again, not coded
        self.interrupt_everywhere(concept_cost(1))

    def test_a_second_concept_timeout_holds_its_users_for_the_operator(self):
        ref, log, calls, _ = R.reference(concept_cost(2))
        c = {x["concept"]: x for x in ref["concept_ledger"]}["drv.motion.creep"]
        e = {x["law"]: x for x in ref["ledger"]}["L-25"]
        self.assertEqual((c["state"], c["attempts"], c["cost_failures"], c["held_laws"]), ("planned", 0, 2, ["L-25"]))
        self.assertEqual((calls[("code", "drv.motion.creep", 1)], calls[("code", "drv.motion.creep", 2)]), (1, 0))
        self.assertEqual((e["state"], e["gaps"], e["attempts"], e["dependency_returns"]), ("blocked", ["decision:L-25"], 0, 0))
        self.assertEqual(calls[("concept_repair", "drv.motion.creep", 2)] + calls[("concept_repair", "drv.motion.creep", 3)], 0)

    def test_a_restart_keeps_the_counts(self):
        """A stop at any point, then launches with `--restart` (the interrupted iteration discarded):
        the counts committed before the stop stand, and the law is held, never charged."""
        def build():
            return one_node("L-21", "L_21", "shall yield.", {("L_21", i): "GATE_TIMEOUT" for i in range(1, 6)})
        _ref, log, _calls, _ = R.reference(build)
        for k in range(1, len(log) + 1):
            w = build()
            w.crash_at = k
            with R.Fixture(w, max_iterations=5) as f:
                statuses = f.drive(launches=6, restart=True)
                st = f.state()
            e = {x["law"]: x for x in st["ledger"]}["L-21"]
            where = f"a stop at tick {k}/{len(log)} {log[k - 1]}"
            self.assertIn("crash", statuses, where)
            self.assertEqual((e["state"], e["attempts"], e["cost_failures"]), ("blocked", 0, {"L_21": GATE_COST_BOUND}), where)


OUTER, INNER, A1, A2 = "drv.motion.outer", "drv.motion.inner", "drv.motion.left", "drv.motion.right"


def chain(inner_gates: dict) -> "callable":
    """L-31's node calls OUTER, which calls INNER, which no node calls directly; L-34 is unrelated."""
    def build() -> R.World:
        w = R.World({"L-31": "shall creep.", "L-34": "shall stop."})
        w.plans = {"L-31": [R.concept(OUTER, calls=[INNER], users=["L_31"]), R.concept(INNER),
                            R.node("L_31", "shall creep.", "L-31", derived=[OUTER])],
                   "L-34": [R.node("L_34", "shall stop.", "L-34")]}
        for it, v in inner_gates.items():
            w.gate[(INNER, it)] = v
        return w
    return build


def diamond_and_both() -> R.World:
    """L-35's node calls A1 and A2, which both call INNER; L-36's node calls INNER directly and through
    A1. INNER's gate reaches the deadline twice."""
    w = R.World({"L-35": "shall creep.", "L-36": "shall halt."})
    w.plans = {"L-35": [R.concept(A1, calls=[INNER]), R.concept(A2, calls=[INNER]), R.concept(INNER),
                        R.node("L_35", "shall creep.", "L-35", derived=[A1, A2])],
               "L-36": [R.node("L_36", "shall halt.", "L-36", derived=[INNER, A1])]}
    w.gate[(INNER, 1)] = w.gate[(INNER, 2)] = "GATE_TIMEOUT"
    return w


def later_user() -> R.World:
    """INNER is held at iteration 2 through L-31; L-38's plan is returned twice and its third plan calls
    OUTER: it is paused at once, and neither concept is coded again."""
    w = chain({1: "GATE_TIMEOUT", 2: "GATE_TIMEOUT"})()
    w.laws["L-38"] = "shall wait."
    w.plans[("L-38", 3)] = [R.node("L_38", "shall wait.", "L-38", derived=[OUTER])]
    w.plans[("L-38", 1)] = w.plans[("L-38", 2)] = [R.node("L_38", "shall wait.", "L-38")]
    w.validate[("L_38", 1)] = w.validate[("L_38", 2)] = ("return", ["scripted plan defect"])
    return w


later_user.opts = {"plan_attempts": 3, "max_iterations": 4}


class Transitive(Interrupted, unittest.TestCase):
    """A held concept pauses every law that reaches it, however deep, each once."""

    def check_chain(self, ref, calls, cost: int, panics: int):
        led = {x["law"]: x for x in ref["ledger"]}
        con = {x["concept"]: x for x in ref["concept_ledger"]}
        self.assertEqual((led["L-31"]["state"], led["L-31"]["gaps"], led["L-31"]["attempts"]), ("blocked", ["decision:L-31"], 0))
        self.assertEqual((led["L-34"]["state"], led["L-34"]["attempts"]), ("accepted", 0))       # an unrelated law goes on
        self.assertEqual((con[INNER]["cost_failures"], con[INNER]["core_panics"], con[INNER]["held_laws"], con[INNER]["attempts"]),
                         (cost, panics, ["L-31"], 0))
        self.assertEqual(sum(c for k, c in calls.items() if k[0] == "code" and k[1] == OUTER), 0)   # its caller waits with it, uncoded
        self.assertEqual((ref["status"][0], ref["deferred_concepts"], ref["deferred_nodes"]), ("complete", [], []))
        self.assertEqual(sum(1 for l in ref["to_user"] if "`L-31` paused:" in l and "--laws L-31)" in l and "python -m harness reopen r" in l), 1)

    def test_a_chain_cost_bound_pauses_the_law_two_concepts_up(self):
        build = chain({1: "GATE_TIMEOUT", 2: "GATE_TIMEOUT"})
        ref, log, calls, _ = R.reference(build)
        self.check_chain(ref, calls, 2, 0)
        self.assertEqual(ref["iterations_allocated"], ["iter-001", "iter-002"])
        self.interrupt_everywhere(build)

    def test_a_chain_panic_pauses_the_law_at_once(self):
        build = chain({1: "PANIC"})
        ref, log, calls, _ = R.reference(build)
        self.check_chain(ref, calls, 0, 1)
        self.assertEqual(ref["iterations_allocated"], ["iter-001"])
        self.interrupt_everywhere(build)

    def test_a_diamond_and_a_direct_and_indirect_user_are_each_paused_once(self):
        ref, log, calls, _ = R.reference(diamond_and_both)
        led = {x["law"]: x for x in ref["ledger"]}
        self.assertEqual({k: (e["state"], e["gaps"], e["attempts"]) for k, e in led.items()},
                         {"L-35": ("blocked", ["decision:L-35"], 0), "L-36": ("blocked", ["decision:L-36"], 0)})
        self.assertEqual(sum(c for k, c in calls.items() if k[0] == "code" and k[1] in (A1, A2)), 0)
        lines = [l for l in ref["to_user"] if " paused: gate_cost:" in l]
        self.assertEqual(len(lines), 1)                           # one notice, each law named once, one command for both
        self.assertEqual((lines[0].count("`L-35`"), lines[0].count("`L-36`")), (1, 1))
        self.assertIn("python -m harness reopen r --laws L-35,L-36)", lines[0])
        self.assertEqual({x["concept"]: x for x in ref["concept_ledger"]}[INNER]["held_laws"], ["L-35", "L-36"])
        self.interrupt_everywhere(diamond_and_both)

    def test_a_held_concept_pauses_a_later_user_without_coding(self):
        ref, log, calls, _ = R.reference(later_user)
        led = {x["law"]: x for x in ref["ledger"]}
        self.assertEqual((led["L-38"]["state"], led["L-38"]["gaps"], led["L-38"]["attempts"]), ("blocked", ["decision:L-38"], 2))
        self.assertEqual(sum(c for k, c in calls.items() if k[0] == "code" and k[1] in (OUTER, INNER) and k[2] >= 3), 0)
        self.assertEqual(calls[("code", "L_38", 3)], 0)
        self.assertEqual({x["concept"]: x for x in ref["concept_ledger"]}[INNER]["held_laws"], ["L-31", "L-38"])

    def test_a_restart_keeps_a_transitive_hold(self):
        build = chain({i: "GATE_TIMEOUT" for i in range(1, 6)})
        _ref, log, _calls, _ = R.reference(build)
        for k in range(1, len(log) + 1):
            w = build()
            w.crash_at = k
            with R.Fixture(w, max_iterations=5) as f:
                statuses = f.drive(launches=6, restart=True)
                st = f.state()
            where = f"a stop at tick {k}/{len(log)} {log[k - 1]}"
            led = {x["law"]: x for x in st["ledger"]}
            inner = {x["concept"]: x for x in st["concept_ledger"]}[INNER]
            self.assertIn("crash", statuses, where)
            self.assertEqual((led["L-31"]["state"], led["L-31"]["attempts"], inner["cost_failures"], inner["held_laws"]),
                             ("blocked", 0, GATE_COST_BOUND, ["L-31"]), where)
            self.assertEqual(st["deferred_concepts"], [], where)


def shared() -> R.World:
    """Two laws share a concept whose gate reaches the deadline twice: both are paused together."""
    w = R.World({"L-32": "shall creep.", "L-33": "shall halt."})
    w.plans = {"L-32": [R.concept("drv.motion.creep"), R.node("L_32", "shall creep.", "L-32", derived=["drv.motion.creep"])],
               "L-33": [R.node("L_33", "shall halt.", "L-33", derived=["drv.motion.creep"])]}
    w.gate[("drv.motion.creep", 1)] = w.gate[("drv.motion.creep", 2)] = "GATE_TIMEOUT"
    return w


class SharedReopen(unittest.TestCase):
    """The command line, as `python -m harness reopen` runs it, on a scratch run."""

    def cli(self, f, *args):
        import subprocess
        dirs = {k: str(v) for k, v in f.dirs.items()}
        code = ("import json, runpy, sys\nfrom pathlib import Path\nfrom harness.store import paths\n"
                "import harness.model.units  # reads Core when imported, before the paths move\n"
                "for k, v in json.loads(sys.argv[1]).items(): setattr(paths, k, Path(v))\n"
                "sys.argv = ['harness'] + sys.argv[2:]\nrunpy.run_module('harness', run_name='__main__', alter_sys=True)\n")
        r = subprocess.run([sys.executable, "-c", code, json.dumps(dirs), *args], cwd=Path(__file__).resolve().parents[2], capture_output=True, text=True, timeout=120)
        self.assertEqual(r.returncode, 0, r.stdout + r.stderr)
        return r.stdout

    def ledgers(self):
        rd = paths.RESULTS / "r"
        laws = {json.loads(l)["law"]: json.loads(l) for l in (rd / "ledger.jsonl").read_text().splitlines() if l.strip()}
        cons = {json.loads(l)["concept"]: json.loads(l) for l in (rd / "concept_ledger.jsonl").read_text().splitlines() if l.strip()}
        return laws, cons

    def held_run(self, f):
        f.drive()
        laws, cons = self.ledgers()
        self.assertEqual((laws["L-32"]["state"], laws["L-33"]["state"]), ("blocked", "blocked"))
        self.assertEqual((cons["drv.motion.creep"]["cost_failures"], cons["drv.motion.creep"]["held_laws"]), (2, ["L-32", "L-33"]))
        line = next(l for l in (paths.RESULTS / "r" / "TO_USER.md").read_text().splitlines() if " paused: gate_cost:" in l)
        return line[line.index("(python -m harness ") + len("(python -m harness "):-1].split()

    def test_one_law_at_a_time_releases_the_concept_after_the_last(self):
        with R.Fixture(shared()) as f:
            self.held_run(f)
            first = self.cli(f, "reopen", "r", "--laws", "L-32")
            laws, cons = self.ledgers()
            self.assertEqual((laws["L-32"]["state"], laws["L-33"]["state"], cons["drv.motion.creep"]["cost_failures"]), ("open", "blocked", 2))
            self.assertIn("concept drv.motion.creep stays held: the laws its hold paused still wait (L-33)", first)
            self.assertIn("(python -m harness reopen r --laws L-33)", first)
            out = self.cli(f, "reopen", "r", "--laws", "L-33")
            laws, cons = self.ledgers()
        self.assertEqual((laws["L-33"]["state"], cons["drv.motion.creep"]["cost_failures"], cons["drv.motion.creep"]["held_laws"]), ("open", 0, []))
        self.assertIn("released from their gate-cost hold: drv.motion.creep", out)

    def test_the_printed_command_reopens_the_group_and_the_run_finishes(self):
        w = shared()
        with R.Fixture(w) as f:
            cmd = self.held_run(f)
            self.assertEqual(cmd, ["reopen", "r", "--laws", "L-32,L-33"])
            self.cli(f, *cmd)
            laws, cons = self.ledgers()
            self.assertEqual((laws["L-32"]["state"], laws["L-33"]["state"], cons["drv.motion.creep"]["cost_failures"]), ("open", "open", 0))
            self.assertEqual(f.drive(max_iterations=4)[-1], "complete")       # re-planned; the concept's gate passes now
            laws, cons = self.ledgers()
        self.assertEqual((laws["L-32"]["state"], laws["L-33"]["state"], cons["drv.motion.creep"]["state"]), ("accepted", "accepted", "accepted"))

    def test_a_list_the_command_line_parses_as_a_tuple_is_accepted(self):
        with R.Fixture(shared()) as f:
            self.held_run(f)
            out = self.cli(f, "reopen", "r", "--laws", "L_x,L_y")          # bare names: the command line gives a tuple
        self.assertIn("reopened 0", out)

    def test_an_unrelated_reopen_releases_nothing(self):
        w = shared()
        w.laws["L-39"] = "shall go."
        w.plans["L-39"] = [R.node("L_39", "shall go.", "L-39")]
        w.validate[("L_39", 1)] = (R.validate_a.FAIL, ["scripted: not expressible"])
        with R.Fixture(w) as f:
            self.held_run(f)
            self.cli(f, "reopen", "r", "--laws", "L-39")
            laws, cons = self.ledgers()
        self.assertEqual((laws["L-39"]["state"], cons["drv.motion.creep"]["cost_failures"]), ("open", 2))


    def test_a_co_user_failed_before_the_hold_is_not_paused_and_never_keeps_it(self):
        """L-33's other node fails validation, closing L-33, in the iteration the shared concept's gate
        panics: only L-32 is paused, and reopening L-32 alone releases the concept."""
        w = R.World({"L-32": "shall creep.", "L-33": "shall halt."})
        w.plans = {"L-32": [R.concept("drv.motion.creep"), R.node("L_32", "shall creep.", "L-32", derived=["drv.motion.creep"])],
                   "L-33": [R.node("L_33_o1", "shall halt.", "L-33", derived=["drv.motion.creep"]),
                            R.node("L_33_o2", "shall halt.", "L-33", span="s2")]}
        w.gate[("drv.motion.creep", 1)] = "PANIC"
        w.validate[("L_33_o2", 1)] = (R.validate_a.FAIL, ["scripted: not expressible"])
        with R.Fixture(w) as f:
            f.drive()
            laws, cons = self.ledgers()
            self.assertEqual((laws["L-32"]["gaps"], laws["L-33"]["state"]), (["decision:L-32"], "failed"))
            self.assertEqual((cons["drv.motion.creep"]["used_by"], cons["drv.motion.creep"]["held_laws"]), (["L_32", "L_33_o1"], ["L-32"]))
            out = self.cli(f, "reopen", "r", "--laws", "L-32")
            laws, cons = self.ledgers()
        self.assertEqual((laws["L-32"]["state"], laws["L-33"]["state"]), ("open", "failed"))
        self.assertEqual((cons["drv.motion.creep"]["core_panics"], cons["drv.motion.creep"]["held_laws"]), (0, []))
        self.assertIn("released from their gate-cost hold: drv.motion.creep", out)


class GapDecision(unittest.TestCase):
    """A law reopened by the operator's gap decision starts its gate-cost counts again, as after `reopen`:
    its nodes' counts, and the counts of a concept its nodes use once no law that concept's hold paused
    is still paused."""

    def test_the_decision_clears_the_counts_of_a_concept_the_law_uses(self):
        """L-33's concept ends on its cost once; L-33 is blocked on a gap in the next iteration. After
        the decision, a further cost failure is the concept's first again: gated once more, never held."""
        w = R.World({"L-33": "shall halt."})
        w.plans = {"L-33": [R.concept("drv.motion.creep"), R.node("L_33_o1", "shall halt.", "L-33", derived=["drv.motion.creep"]),
                            R.node("L_33_o2", "shall halt.", "L-33", span="s2")]}
        w.gate[("drv.motion.creep", 1)] = w.gate[("drv.motion.creep", 3)] = "GATE_TIMEOUT"
        w.gate[("L_33_o2", 1)] = "CHECK_FAIL"
        w.node_repair[("L_33_o2", 2)] = {"withdraw": {"span": "s2", "kind": "atom", "missing": "an atom"}}
        with R.Fixture(w) as f:
            f.drive(max_iterations=2)
            st = f.state()
            self.assertEqual(({x["law"]: x for x in st["ledger"]}["L-33"]["gaps"], st["concept_ledger"][0]["cost_failures"]), (["G1"], 1))
            from harness.store.gaps import GapLedger
            GapLedger(paths.GAPS_DIR).decide("G1", "rejected", "carried as it is", resolved_by="particular")
            f.drive(max_iterations=5)
            st = f.state()
        law, con = {x["law"]: x for x in st["ledger"]}["L-33"], st["concept_ledger"][0]
        self.assertEqual((law["state"], con["state"], con["cost_failures"], con["held_laws"]), ("accepted", "accepted", 1, []))

    def test_the_decision_clears_the_counts_of_the_laws_nodes(self):
        with tempfile.TemporaryDirectory() as t:
            led = Ledger(Path(t) / "l.jsonl", ["L"], 2)
            led.attempt = 1
            led.mark_planned("L", ["n1", "n2"], 1)
            led.gate_cost("L", "n1", panic=False); led.gate_cost("L", "n2", panic=True)
            led.block("L", ["G-1"], ["gap G-1"])
            self.assertEqual([law for law, _ in led.reopen_for_gaps({"G-1": ("rejected", "d")})], ["L"])
            e = led.entries["L"]
            self.assertEqual((e.state, e.cost_failures, e.core_panics), ("open", {}, []))


class CoUsers(unittest.TestCase):
    """A hold records only the laws it paused: a co-user blocked on a gap or failed on its own budget
    before the hold is neither paused nor recorded, and never keeps the hold once the laws it paused
    are reopened."""

    def ledgers(self, t: str) -> tuple[Ledger, ConceptLedger]:
        led, cl = Ledger(Path(t) / "l.jsonl", ["NRS-1", "NRS-2"], 2), ConceptLedger(Path(t) / "c.jsonl", 2)
        cl.planned("c.x", ["NRS_1", "NRS_2"], 1)
        led.attempt = 1
        return led, cl

    def hold_and_reopen(self, led: Ledger, cl: ConceptLedger, panic: bool):
        from harness import loop
        to_user: list[str] = []
        held = cl.gate_cost("c.x", panic) or cl.gate_cost("c.x", panic)
        self.assertTrue(held)
        paused = loop._pause_users(led, cl, "c.x", ["NRS-1", "NRS-2"], "held", to_user, "r")
        self.assertEqual((paused, cl.entries["c.x"].held_laws), (["NRS-1"], ["NRS-1"]))
        out = led.reopen(["NRS-1"])
        self.assertEqual(out, ["NRS-1"])
        return cl.release(out, led.paused())

    def test_a_co_user_blocked_on_a_gap(self):
        with tempfile.TemporaryDirectory() as t:
            led, cl = self.ledgers(t)
            led.block("NRS-2", ["G-7"], ["gap G-7"])
            released, waiting = self.hold_and_reopen(led, cl, panic=False)
            self.assertEqual((released, waiting, cl.held("c.x"), led.entries["NRS-2"].state), (["c.x"], {}, False, "blocked"))

    def test_a_co_user_failed_on_its_own_budget(self):
        with tempfile.TemporaryDirectory() as t:
            led, cl = self.ledgers(t)
            led.fail("NRS-2", ["attempt budget (2) spent"])
            released, waiting = self.hold_and_reopen(led, cl, panic=True)
            self.assertEqual((released, waiting, cl.held("c.x"), led.entries["NRS-2"].state), (["c.x"], {}, False, "failed"))

    def test_a_reopen_that_leaves_a_paused_law_names_it(self):
        from harness import loop
        with tempfile.TemporaryDirectory() as t:
            led, cl = self.ledgers(t)
            cl.gate_cost("c.x", True)
            loop._pause_users(led, cl, "c.x", ["NRS-1", "NRS-2"], "held", [], "r")
            released, waiting = cl.release(led.reopen(["NRS-1"]), led.paused())
            self.assertEqual((released, waiting, cl.held("c.x")), ([], {"c.x": ["NRS-2"]}, True))
            released, waiting = cl.release(led.reopen(["NRS-2"]), led.paused())
            self.assertEqual((released, waiting, cl.held("c.x"), cl.entries["c.x"].held_laws), (["c.x"], {}, False, []))


class AcceptedRecord(unittest.TestCase):
    def test_a_panic_rechecking_an_accepted_record_is_named_a_core_defect(self):
        from harness.phases import integrate
        w = R.World({"L-1": "shall creep."})
        w.plans["L-1"] = [R.node("L_1", "shall creep.", "L-1")]
        with R.Fixture(w, max_iterations=1) as f:
            f.drive(launches=1)
            w.admission["L_1"] = "PANIC"
            with mock.patch.object(integrate, "gate_digest", lambda: "another gate"):
                f.drive(launches=1, max_iterations=2)
            snap = json.loads((paths.RESULTS / "r" / "state.json").read_text())
            notes = (paths.RESULTS / "r" / "TO_USER.md").read_text()
        self.assertIn("L_1", snap["accepted_nodes"])
        self.assertIn("its evaluation panicked in isolation (a Core defect)", notes + json.dumps(snap.get("pending_notices", [])))


class Counts(unittest.TestCase):
    def ledger(self) -> Ledger:
        tmp = tempfile.TemporaryDirectory(); self.addCleanup(tmp.cleanup)
        led = Ledger(Path(tmp.name) / "ledger.jsonl", ["L"], 2)
        led.attempt = 1
        led.mark_planned("L", ["n1", "n2"], 1)
        return led

    def test_the_bound_is_per_node_and_a_panic_holds_at_once(self):
        led = self.ledger()
        self.assertFalse(led.gate_cost("L", "n1", panic=False))
        self.assertFalse(led.gate_cost("L", "n2", panic=False))       # a sibling's count is its own
        self.assertTrue(led.gate_cost("L", "n1", panic=False))
        self.assertTrue(led.gate_cost("L", "n2", panic=True))
        e = led.entries["L"]
        self.assertEqual((e.state, e.attempts, e.cost_failures, e.core_panics), ("planned", 0, {"n1": 2, "n2": 1}, ["n2"]))

    def test_the_operators_reopen_starts_the_counts_again(self):
        led = self.ledger()
        led.gate_cost("L", "n1", panic=False); led.gate_cost("L", "n1", panic=True)
        led.block("L", ["decision:L"], ["held"])
        self.assertEqual(led.reopen(["L"]), ["L"])
        e = led.entries["L"]
        self.assertEqual((e.state, e.cost_failures, e.core_panics), ("open", {}, []))

    def test_a_concept_keeps_its_state_users_and_attempts(self):
        with tempfile.TemporaryDirectory() as t:
            cl = ConceptLedger(Path(t) / "c.jsonl", 3)
            cl.planned("c", ["n"], 1)
            self.assertFalse(cl.gate_cost("c", panic=False))
            self.assertTrue(cl.gate_cost("c", panic=False))
            self.assertTrue(cl.gate_cost("c", panic=True))
            e = cl.entries["c"]
            self.assertEqual((e.state, e.used_by, e.attempts, e.cost_failures, e.core_panics), ("planned", ["n"], 0, 2, 1))
            self.assertTrue(cl.held("c"))

    def test_a_ledger_written_before_the_counts_loads_unchanged(self):
        law = {"law": "L", "state": "returned", "attempts": 1, "reasons": ["r"], "nodes": ["L_1"], "gaps": [], "iteration": 2,
               "charged_iteration": 2, "charged_concepts": ["drv.c"], "dependency_returns": 1, "dependency_iteration": 1,
               "repeats": {"behaviour:k": 1}, "selection_corrections": 0, "outcome_iteration": 2}
        con = {"concept": "drv.c", "state": "returned", "attempts": 1, "reasons": ["gate CHECK_FAIL"], "used_by": ["L_1"],
               "iteration": 1, "last_task": "t", "judge_failures": {}, "waiting": []}
        nod = {"node": "L_1", "law": "L", "state": "returned", "attempts": 1, "reasons": ["gate CHECK_FAIL"], "last_task": "t",
               "iteration": 1, "judge_failures": {"stage_a": 1}}
        with tempfile.TemporaryDirectory() as t:
            retired = {"node_ledger.jsonl": {"judge_failures"}}             # a node review's count, read and dropped
            for name, row, cls in (("ledger.jsonl", law, lambda p: Ledger(p, ["L"], 2)), ("concept_ledger.jsonl", con, lambda p: ConceptLedger(p, 3)),
                                   ("node_ledger.jsonl", nod, lambda p: NodeLedger(p, 2))):
                p = Path(t) / name
                p.write_text(json.dumps(row) + "\n", encoding="utf-8")
                led = cls(p)
                (entry,) = led.entries.values()
                got = asdict(entry)
                kept = {k: v for k, v in row.items() if k not in retired.get(name, set())}
                self.assertEqual({k: got[k] for k in kept}, kept, name)          # every recorded field it keeps, as written
                self.assertFalse(retired.get(name, set()) & set(got), name)
                self.assertEqual({k: v for k, v in got.items() if k not in kept},
                                 {"ledger.jsonl": {"cost_failures": {}, "core_panics": [], "waits_on": [], "scope_violations": {}, "own_gaps": []},
                                  "concept_ledger.jsonl": {"cost_failures": 0, "core_panics": 0, "held_laws": [], "scope_violations": 0},
                                  "node_ledger.jsonl": {}}[name], name)           # the new counts start at zero
                led.save()
                again = asdict(next(iter(cls(p).entries.values())))
                self.assertEqual(again, got, name)


if __name__ == "__main__":
    unittest.main()
