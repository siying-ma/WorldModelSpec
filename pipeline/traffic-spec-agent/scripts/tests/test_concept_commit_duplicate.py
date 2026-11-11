"""Concepts are coded side by side, and each gate compares a concept's body only with the concepts
accepted when it ran. The commit, on the loop's one thread, compares the gate's canonical body again
with every accepted concept, those committed earlier in the same iteration included: a concept with
the same body is not accepted and goes back with the gate's `DUPLICATE_CONCEPT` verdict naming the
concept accepted first. Only same-body duplicates are caught; concepts with different bodies are both
accepted, and a supersession is never a duplicate of the version it supersedes.

The real loop runs over scripted sessions (`test_recovery`); the gate is scripted to pass every
concept with the canonical body the scenario gives it, whatever was accepted when it ran."""
import json
import threading
import time
import unittest
from unittest import mock

from harness.checks import gate
from harness.store import paths
from scripts.tests import test_recovery as R

A, B = "drv.motion.left_turn", "drv.motion.turning_left"


def world(bodies: dict[str, str], extra: dict | None = None) -> R.World:
    """L-1 calls concept A and L-2 calls concept B, each proposed by its own law's plan."""
    w = R.World({"L-1": "shall turn.", "L-2": "shall signal."})
    w.plans = {"L-1": [R.concept(A, users=["L_1"]), R.node("L_1", "shall turn.", "L-1", derived=[A])],
               "L-2": [R.concept(B, users=["L_2"]), R.node("L_2", "shall signal.", "L-2", derived=[B])]}
    w.bodies = bodies
    w.order = None
    for k, v in (extra or {}).items():
        setattr(w, k, v)
    return w


class BodyFixture(R.Fixture):
    """The scripted world, its concept gate passing with the canonical body the world gives each
    concept. With `order` (first, second), the second concept's gate ends only once the first is
    accepted: both gates ran side by side, the second never seeing the first."""

    def __enter__(self):
        super().__enter__()
        w = self.w

        def run_concept_gate(rec, reading, baseline, d, budget_used=0, budget=0, mode="train", accepted=None):
            if "admission" in R.Path(d).parts:            # an admission recheck at a loop start, as the scripted world runs it
                w.admitted[rec.id] += 1
                w.tick("admission", rec.id)
                it, v = None, w.admission.get(rec.id, "OK")
            else:
                it = R._iteration_of(R.Path(d))
                v = w.gate.get((rec.id, it), "OK")
            if v != "OK":
                return gate.Verdict(v, [f"scripted {v}"])
            if w.order and rec.id == w.order[1] and it == 1:
                deadline = time.time() + 60
                state = paths.RESULTS / "r" / "state.json"
                while time.time() < deadline:
                    if w.dead:
                        raise R.Crash("dead")
                    try:
                        if w.order[0] in json.loads(state.read_text()).get("accepted_concepts", {}):
                            break
                    except (OSError, ValueError):
                        pass
                    time.sleep(0.01)
            return gate.Verdict("OK", [], extras={"reads": ["kin.speed"], "refs": sorted(rec.refs()), "body_json": {"c": rec.id},
                                                  "canonical_body": w.bodies[rec.id]})
        self.stack.enter_context(mock.patch.object(gate, "run_concept_gate", run_concept_gate))
        return self


def outcome(f) -> tuple[dict, dict]:
    st = json.loads((paths.RESULTS / "r" / "state.json").read_text())
    return st["accepted_concepts"], {e["concept"]: e for e in st["concept_ledger"]}


class CommitTimeDuplicate(unittest.TestCase):
    def run_order(self, first: str, second: str):
        w = world({A: "same", B: "same"}, {"order": (first, second)})
        with BodyFixture(w, workers=2, max_iterations=1) as f:
            f.drive()
            accepted, ledger = outcome(f)
            library = sorted(str(p.relative_to(paths.LIBRARY)) for p in paths.CONCEPTS_DIR.rglob("*.lean")) if paths.CONCEPTS_DIR.exists() else []
        return accepted, ledger, library

    def test_both_completion_orders(self):
        for first, second in ((A, B), (B, A)):
            accepted, ledger, library = self.run_order(first, second)
            self.assertEqual(sorted(accepted), [first], (first, second))
            self.assertEqual(ledger[second]["state"], "returned", (first, second))
            self.assertEqual(ledger[second]["reasons"][0], "gate DUPLICATE_CONCEPT")
            self.assertIn(f"alpha-equivalent to accepted `{first}`: call it instead", ledger[second]["reasons"][1])
            self.assertFalse(any(second.split(".")[-1] in p for p in library), library)     # its files rolled back

    def test_different_bodies_are_both_accepted(self):
        w = world({A: "left turn: heading change in the band", B: "turning left: heading rate leftward"})
        with BodyFixture(w, workers=2, max_iterations=1) as f:
            f.drive()
            accepted, _ = outcome(f)
        self.assertEqual(sorted(accepted), [A, B])

    def test_a_supersession_is_not_a_duplicate_of_the_version_it_supersedes(self):
        w = R.World({"L-1": "shall turn.", "L-2": "shall signal."})
        v2 = {**R.concept(A + "_v2", users=["L_2"]), "supersedes": A, "contract": f"{A} holds"}
        w.plans = {"L-1": [R.concept(A, users=["L_1"]), R.node("L_1", "shall turn.", "L-1", derived=[A])],
                   ("L-2", 1): [R.node("L_2", "shall signal.", "L-2")],
                   ("L-2", 2): [v2, R.node("L_2", "shall signal.", "L-2", derived=[A + "_v2"])]}
        w.validate[("L_2", 1)] = ("return", ["scripted plan defect"])
        w.bodies, w.order = {A: "same", A + "_v2": "same"}, None
        with BodyFixture(w, max_iterations=2) as f:
            f.drive()
            accepted, ledger = outcome(f)
        self.assertIn(A + "_v2", accepted)
        self.assertEqual(ledger[A + "_v2"]["state"], "accepted")


def sequential() -> R.World:
    """One task at a time: A is committed, then B, whose gate (scripted) did not compare it with A."""
    return world({A: "same", B: "same"})


sequential.opts = {"max_iterations": 1}


class AfterARestart(R.Interruptions, unittest.TestCase):
    """A stop at any point, the one between the two commits included, resumed, ends as the
    uninterrupted run: one concept accepted, the other returned as a duplicate of it."""

    def test_every_stop(self):
        with mock.patch.object(R, "Fixture", BodyFixture):
            ref, n = self.interrupt_everywhere(sequential)
        self.assertEqual(sorted(ref["accepted_concepts"]), [A])
        e = next(x for x in ref["concept_ledger"] if x["concept"] == B)
        self.assertEqual((e["state"], e["reasons"][0]), ("returned", "gate DUPLICATE_CONCEPT"))
        self.assertIn(f"accepted `{A}`", e["reasons"][1])


if __name__ == "__main__":
    unittest.main()
