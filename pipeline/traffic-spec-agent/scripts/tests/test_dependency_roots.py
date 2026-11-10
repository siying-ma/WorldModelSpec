"""Who holds a blocked law, and what an operator's reopen may release.

A token a law is blocked on itself is recorded as its own (`own_gaps`), apart from the tokens it
inherits from the laws it waits on; a law's roots are the laws whose own tokens hold it. A plain
reopen decides only the decision tokens of the laws it names, never a gap; it is checked whole
before anything changes, and refused, with every reason, when a law named is blocked on a gap not
yet decided or waits on a root not named with it. A gap is released for every law that holds it by
its decision alone. The real `Ledger`, `hold_on_unavailable`, `GapLedger` and `harness reopen` run."""
import json
import tempfile
import unittest
from pathlib import Path
from unittest import mock

from harness import loop
from harness.store import paths
from harness.store.gaps import GapLedger
from harness.store.ledger import Ledger, ReopenRefused


def ledger(*laws: str) -> Ledger:
    t = tempfile.mkdtemp()
    return Ledger(Path(t) / "ledger.jsonl", list(laws), 2)


def hold(led: Ledger, law: str, on: list[str]) -> None:
    """`law` composes a node of each law of `on`, which waits for the operator (the real helper)."""
    roots = loop.unavailable_roots(led, {})
    loop.hold_on_unavailable(led, law, {f"{l}_n": set(roots.get(l, {l})) for l in on}, [], law, [], [], "r")


def view(led: Ledger) -> dict:
    return {l: (e.state, sorted(e.gaps), sorted(e.own_gaps), sorted(e.waits_on)) for l, e in led.entries.items()}


def invariant(test, led: Ledger) -> None:
    for e in led.entries.values():
        test.assertTrue(set(e.own_gaps) <= set(e.gaps), (e.law, e.own_gaps, e.gaps))


class Roots(unittest.TestCase):

    def test_two_laws_that_wait_on_each_other_are_both_roots(self):
        """T30: A and B blocked on their own decisions, each also holding the other's through a
        dependency wait: both are roots, a reopen of one alone is refused naming the other, the two
        together reopen."""
        led = ledger("A", "B")
        led.block("A", ["decision:A"], ["own"]); led.block("B", ["decision:B"], ["own"])
        hold(led, "A", ["B"]); hold(led, "B", ["A"])
        self.assertEqual(view(led)["A"], ("blocked", ["decision:A", "decision:B"], ["decision:A"], ["B"]))
        self.assertEqual((led.roots("A"), led.roots("B")), ({"A", "B"}, {"A", "B"}))
        before = view(led)
        with self.assertRaises(ReopenRefused) as e:
            led.reopen(["A"])
        self.assertIn("['B']", str(e.exception))
        self.assertEqual(view(led), before)
        self.assertEqual(sorted(led.reopen(["A", "B"])), ["A", "B"])
        self.assertEqual({l: v[0] for l, v in view(led).items()}, {"A": "open", "B": "open"})

    def test_a_dependent_cannot_release_another_laws_root(self):
        """T25: D waits on A and B, each blocked on its own decision. D alone is refused, naming A
        and B, nothing changed; A, B and D together reopen; A alone leaves D held by B's decision."""
        def built() -> Ledger:
            led = ledger("A", "B", "D")
            led.block("A", ["decision:A"], ["own"]); led.block("B", ["decision:B"], ["own"])
            hold(led, "D", ["A", "B"])
            return led
        led = built()
        self.assertEqual(view(led)["D"], ("blocked", ["decision:A", "decision:B"], [], ["A", "B"]))
        self.assertEqual(led.roots("D"), {"A", "B"})
        before = view(led)
        with self.assertRaises(ReopenRefused) as e:
            led.reopen(["D"])
        self.assertIn("['A', 'B']", str(e.exception))
        self.assertEqual(view(led), before)
        self.assertEqual(sorted(built().reopen(["A", "B", "D"])), ["A", "B", "D"])
        led = built()
        self.assertEqual(led.reopen(["A"]), ["A"])
        self.assertEqual(view(led)["D"][:2], ("blocked", ["decision:B"]))
        invariant(self, led)

    def test_a_law_blocked_on_its_own_and_on_a_dependency_stays_a_root(self):
        """T26: A blocked on its own decision; B on its own and, composing A, on A's; C composes B.
        B is a root, C's root is B (and A while A holds it), never C itself. A reopened, B and C stay
        held by B's decision."""
        led = ledger("A", "B", "C")
        led.block("A", ["decision:A"], ["own"]); led.block("B", ["decision:B"], ["own"])
        hold(led, "B", ["A"]); hold(led, "C", ["B"])
        self.assertEqual(view(led)["C"], ("blocked", ["decision:A", "decision:B"], [], ["A", "B"]))   # it waits on its roots
        self.assertEqual((led.roots("B"), led.roots("C")), ({"A", "B"}, {"A", "B"}))
        roots = loop.unavailable_roots(led, {})
        self.assertEqual((roots["B"], roots["C"]), ({"A", "B"}, {"A", "B"}))
        with self.assertRaises(ReopenRefused):
            led.reopen(["C"])
        led.reopen(["A"])
        self.assertEqual({l: v[:2] for l, v in view(led).items() if l != "A"},
                         {"B": ("blocked", ["decision:B"]), "C": ("blocked", ["decision:B"])})
        self.assertEqual(led.roots("C"), {"B"})
        invariant(self, led)

    def test_a_duplicate_gap_filed_by_a_dependent_is_its_own(self):
        """T31: B files a gap whose proposal duplicates the one A filed (`GapLedger.add` returns A's
        id, its `law_refs` naming A only), and B also waits on A: the gap is B's own, B is a root."""
        with tempfile.TemporaryDirectory() as t, mock.patch.object(paths, "RESULTS", Path(t) / "results"):
            gaps = GapLedger(Path(t) / "gaps")
            prop = {"span": "s1", "kind": "atom", "proposal": "a missing atom", "span_text": "words", "law_refs": ["A"], "node_id": "A_1",
                    "occurrence": "B@d:0-5"}
            gid = gaps.add(prop, "r", 1)
            self.assertEqual(gaps.add({**prop, "law_refs": ["B"], "node_id": "B_1"}, "r", 1), gid)
            self.assertEqual(next(r for r in gaps.rows if r["id"] == gid)["law_refs"], ["A"])
        led = ledger("A", "B")
        led.block("A", [gid], ["own gap"])
        hold(led, "B", ["A"])
        led.block("B", [gid], ["its own coding confirmed the same gap"])
        self.assertIn(gid, led.entries["B"].own_gaps)
        self.assertIn("B", led.roots("B"))


class GapsAreDecidedOnlyByTheirDecision(unittest.TestCase):

    def built(self, mixed: bool) -> Ledger:
        led = ledger("A", "B")
        led.block("A", (["decision:A"] if mixed else []) + ["G7"], ["own"])
        led.block("B", ["G7"], ["own"])
        return led

    def test_a_plain_reopen_never_decides_a_gap(self):
        """T35: A and B hold the real gap G7; (a) A holds G7 alone, (b) A holds `decision:A` and G7.
        A plain reopen of A is refused naming G7 and `gap decide`, B's G7 untouched; G7's decision
        strikes it from both, A keeping `decision:A` in (b)."""
        for mixed in (False, True):
            with self.subTest(mixed=mixed):
                led = self.built(mixed)
                before = view(led)
                with self.assertRaises(ReopenRefused) as e:
                    led.reopen(["A"])
                self.assertIn("G7", str(e.exception))
                self.assertIn("gap decide", str(e.exception))
                self.assertEqual(view(led), before)
                invariant(self, led)
                out = led.reopen_for_gaps({"G7": ("retired", "carried")})
                self.assertIn("B", [l for l, _ in out])
                self.assertEqual(view(led)["B"][:2], ("open", []))
                self.assertEqual(view(led)["A"][:3], ("blocked", ["decision:A"], ["decision:A"]) if mixed else ("open", [], []))
                invariant(self, led)

    def test_a_mixed_chain_stays_held_by_the_middle_laws_decision(self):
        """T30's chain under the rule that a plain reopen never decides a gap: A holds g1; B holds its
        own decision and composes A; C composes B. Reopening A is refused (g1); once g1 is decided, A
        reopens and B and C stay held by `decision:B`."""
        led = ledger("A", "B", "C")
        led.block("A", ["g1"], ["own"])
        led.block("B", ["decision:B"], ["own"]); hold(led, "B", ["A"]); hold(led, "C", ["B"])
        self.assertEqual((view(led)["B"][1], view(led)["C"][1]), (["decision:B", "g1"], ["decision:B", "g1"]))
        with self.assertRaises(ReopenRefused):
            led.reopen(["A"])
        led.reopen_for_gaps({"g1": ("retired", "carried")})
        self.assertEqual({l: v[:2] for l, v in view(led).items()},
                         {"A": ("open", []), "B": ("blocked", ["decision:B"]), "C": ("blocked", ["decision:B"])})
        invariant(self, led)


class BatchReopen(unittest.TestCase):
    """T39: one reopen naming A, which may reopen, and B, blocked on a gap not yet decided, is refused
    whole: a non-zero exit naming B's gap, and every ledger and held record as it was."""

    def test_a_batch_with_one_refused_law_changes_nothing(self):
        from scripts.tests import test_recovery as R
        w = R.World({"A": "shall a.", "B": "shall b."})
        w.plans = {"A": [R.node("A_1", "shall a.", "A")], "B": [R.node("B_1", "shall b.", "B")]}
        w.validate[("A_1", 1)] = (R.validate_a.FAIL, ["scripted: not expressible"])
        with R.Fixture(w) as f:
            f.drive(1)
            rd = paths.RESULTS / "r"
            st = json.loads((rd / "state.json").read_text())
            for e in st["ledger"]:
                if e["law"] == "B":
                    e.update(state="blocked", gaps=["G9"], own_gaps=["G9"])
            st["deferred_nodes"] = [R.node("B_1", "shall b.", "B")]
            (rd / "state.json").write_text(json.dumps(st))
            names = ("state.json", "ledger.jsonl", "node_ledger.jsonl", "concept_ledger.jsonl")
            from harness.store.state import Run
            Run(f.options()).restore_state()
            before = {n: (rd / n).read_bytes() for n in names}
            from harness.__main__ import Cli
            import io, contextlib
            out = io.StringIO()
            with contextlib.redirect_stdout(out), mock.patch("harness.store.owner.acquire_for_command", lambda name: None):
                code = Cli().reopen("r", laws="A,B")
            self.assertNotEqual(code, 0)
            self.assertIn("G9", out.getvalue())
            self.assertEqual({n: (rd / n).read_bytes() for n in names}, before)
            with contextlib.redirect_stdout(io.StringIO()), mock.patch("harness.store.owner.acquire_for_command", lambda name: None):
                self.assertEqual(Cli().reopen("r", laws="A"), 0)
            self.assertEqual({e["law"]: e["state"] for e in json.loads((rd / "state.json").read_text())["ledger"]},
                             {"A": "open", "B": "blocked"})


if __name__ == "__main__":
    unittest.main()
