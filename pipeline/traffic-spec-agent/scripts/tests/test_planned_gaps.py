"""A record that carries a gap is never coded or accepted.

The real loop (`test_recovery`'s scripted world): a validated record with a gap is not coded, each
of its gaps is filed in the gap ledger on the occurrence of its words, and its law is blocked on
them once the law's other nodes of the iteration are integrated; a node of the same law without a gap
is coded as usual; a node repair's record with a gap goes the same way; a gap matching one the
operator already decided is not filed again, and the law goes back to its planner with the decision;
the coder's two declarations of an unstatable span still file their gap. A candidate change whose
record carries a gap is refused. A record that withdraws a gap of the ledger (carries its words
without it) names the operator's decision in `gap_resolutions`, else it is returned.

A law composing a record that carries a pending gap waits on that gap's id from the iteration it is
filed in, rooted at the provider law, never on a `decision:` token and never as a missing provider;
a chain of such laws waits on the root's gap; a node composing its own law's gap-carrying record is
not coded, whatever the order; a law composing only the provider's clean node waits while the
provider is blocked; a partial decision still waits; after the decision the pin and missing rules
apply; a stop at any point, and a snapshot without the per-node record, end as the uninterrupted run."""
import collections
import copy
import json
import tempfile
import unittest
from pathlib import Path
from unittest import mock

from harness import loop
from harness.checks import gate, validate_a
from harness.model import corpus
from harness.model.blueprint import Node
from harness.model.mapping import MappingIndex
from harness.model.reading import Reading
from harness.phases import candidate as cand, review as review_phase, validate as validate_phase
from harness.store import paths
from harness.store.gaps import GapLedger
from scripts.tests import test_recovery as rec
from scripts.tests.test_candidate import Base, Txn, files, node_rec, standard, world, NN, CB
from scripts.tests.test_review_routing import ONTO

TEXT = "shall stop. shall yield."
GAP = {"span": "s1", "kind": "atom", "proposal": "| `ru.disabled_test` | a vehicle that cannot move |", "nearest": ["kin.speed"]}


def gapped(nid: str, law: str, text: str = "shall stop.") -> dict:
    n = rec.node(nid, text, law)
    n["gaps"] = [copy.deepcopy(GAP)]
    return n


def pair(law: str) -> tuple[dict, dict]:
    """Two nodes of one law: o1 carries a gap on its obligation, o2 carries none."""
    o1, o2 = rec.node(f"{law.replace('-', '_')}_o1", TEXT, law), rec.node(f"{law.replace('-', '_')}_o2", TEXT, law)
    o1["segmentation"] = [{"id": "s1", "role": "obligation", "text": "shall stop."}, {"id": "s2", "role": "sibling", "text": "shall yield."}]
    o2["segmentation"] = [{"id": "s1", "role": "sibling", "text": "shall stop."}, {"id": "s2", "role": "obligation", "text": "shall yield."}]
    o2["elements"] = [{"span": "s2", "atoms": ["kin.speed"], "derived": [], "justification": "j"}]
    o1["gaps"] = [copy.deepcopy(GAP)]
    return o1, o2


def occurrence(law: str, text: str, start: int, end: int) -> str:
    return f"{law}@{review_phase.law_digest(text)}:{start}-{end}"


def planned_gap() -> rec.World:
    """L-20's only node carries a gap."""
    w = rec.World({"L-20": "shall stop."})
    w.plans = {"L-20": [gapped("L_20", "L-20")]}
    return w


def sibling_without_gap() -> rec.World:
    """L-21's o1 carries a gap, its o2 none."""
    w = rec.World({"L-21": TEXT})
    w.plans = {"L-21": list(pair("L-21"))}
    return w


def repaired_with_gap() -> rec.World:
    """L-22's node is returned by its gate; its repair hands back a record that carries a gap."""
    w = rec.World({"L-22": "shall stop."})
    w.plans = {"L-22": [rec.node("L_22", "shall stop.", "L-22")]}
    w.gate[("L_22", 1)] = "CHECK_FAIL"
    w.node_repair[("L_22", 2)] = gapped("L_22", "L-22")
    return w


def gaps_of(f) -> list[dict]:
    return GapLedger(paths.GAPS_DIR).rows


class Registration(rec.Interruptions, unittest.TestCase):
    """The loop: a record with a gap is filed and blocks its law, at every stop and resume."""

    def test_a_planned_gap_is_filed_and_blocks_the_law_and_nothing_is_coded(self):
        ref, _n = self.interrupt_everywhere(planned_gap, never=[("code", "L_20", 1), ("code", "L_20", 2), ("code", "L_20", 3)])
        led = {e["law"]: e for e in ref["ledger"]}
        self.assertEqual((led["L-20"]["state"], led["L-20"]["gaps"]), ("blocked", ["G1"]))
        self.assertEqual(ref["accepted_nodes"], {})
        self.assertEqual(ref["library"], [])
        row = json.loads(ref["gaps"][0])
        self.assertEqual((row["id"], row["kind"], row["span"], row["law_refs"], row["node_id"]), ("G1", "atom", "shall stop.", ["L-20"], "L_20"))
        self.assertEqual(row["occurrence"], occurrence("L-20", "shall stop.", 0, 11))
        self.assertTrue(any("G1" in l and "`L-20`" in l for l in ref["to_user"]))
        self.assertFalse(any("no gap is filed" in l for l in ref["to_user"]))

    def test_a_sibling_without_a_gap_is_coded_and_accepted(self):
        ref, _n = self.interrupt_everywhere(sibling_without_gap, never=[("code", "L_21_o1", 1)])
        led = {e["law"]: e for e in ref["ledger"]}
        self.assertEqual((led["L-21"]["state"], led["L-21"]["gaps"]), ("blocked", ["G1"]))
        self.assertEqual(sorted(ref["accepted_nodes"]), ["L_21_o2"])
        self.assertEqual([json.loads(g)["occurrence"] for g in ref["gaps"]], [occurrence("L-21", TEXT, 0, 11)])

    def test_a_node_repair_record_with_a_gap_is_filed_and_blocks_the_law(self):
        ref, _n = self.interrupt_everywhere(repaired_with_gap, never=[("code", "L_22", 2), ("code", "L_22", 3)])
        led = {e["law"]: e for e in ref["ledger"]}
        self.assertEqual((led["L-22"]["state"], led["L-22"]["gaps"]), ("blocked", ["G1"]))
        self.assertEqual(ref["accepted_nodes"], {})
        self.assertEqual(json.loads(ref["gaps"][0])["occurrence"], occurrence("L-22", "shall stop.", 0, 11))

    def test_a_gap_the_operator_decided_is_not_filed_again_and_the_law_goes_back_with_the_decision(self):
        w = planned_gap()
        w.plans = {("L-20", 1): [gapped("L_20", "L-20")], ("L-20", 2): [gapped("L_20", "L-20")],
                   ("L-20", 3): [rec.node("L_20", "shall stop.", "L-20")]}
        with rec.Fixture(w) as f:
            f.drive()
            self.assertEqual([r["id"] for r in gaps_of(f)], ["G1"])
            GapLedger(paths.GAPS_DIR).decide("G1", "rejected", "read the words through the halt", resolved_by="particular")
            f.drive(max_iterations=2)
            back = next(e for e in f.state()["ledger"] if e["law"] == "L-20")
            f.drive(max_iterations=5)
            st = f.state()
            rows = gaps_of(f)
        self.assertEqual([r["id"] for r in rows], ["G1"])                       # the plan's repeat is not filed again
        self.assertEqual((w.calls[("code", "L_20", 1)], w.calls[("code", "L_20", 2)], w.calls[("code", "L_20", 3)]), (0, 0, 1))
        law = next(e for e in st["ledger"] if e["law"] == "L-20")
        self.assertEqual(law["state"], "accepted")
        self.assertIn("L_20", st["accepted_nodes"])
        self.assertEqual((back["state"], back["gaps"]), ("returned", []))
        self.assertTrue(any("gap G1" in r and "which the operator rejected: read the words through the halt" in r for r in back["reasons"]),
                        back["reasons"])

    def test_two_declarations_of_an_unstatable_span_still_file_its_gap(self):
        w = rec.World({"L-23": "shall stop."})
        w.plans = {"L-23": [rec.node("L_23", "shall stop.", "L-23")]}
        unexpressed = gate.Verdict("UNEXPRESSED", ["scripted UNEXPRESSED"],
                                   extras={"unexpressed": [{"span": "s1", "kind": "no_atom", "why": "no atom carries the words"}]})
        with rec.Fixture(w) as f:
            prev = gate.run_gate

            def run_gate(n, reading, baseline, d, *a, **k):
                return unexpressed if "admission" not in Path(d).parts else prev(n, reading, baseline, d, *a, **k)
            f.stack.enter_context(mock.patch.object(gate, "run_gate", run_gate))
            f.drive()
            st = f.state()
        law = next(e for e in st["ledger"] if e["law"] == "L-23")
        self.assertEqual((law["state"], law["gaps"]), ("blocked", ["G1"]))
        row = json.loads(st["gaps"][0])
        self.assertEqual((row["kind"], row["proposal"], row["occurrence"]),
                         ("atom", "no atom carries the words", occurrence("L-23", "shall stop.", 0, 11)))
        self.assertEqual((w.calls[("code", "L_23", 1)], w.calls[("code", "L_23", 2)]), (1, 1))
        self.assertTrue(any("two coding sessions declared the span cannot be stated" in l for l in st["to_user"]))



# ---------------------------------------------------------------------------------------------
# Laws that compose a node carrying a gap wait on that gap
# ---------------------------------------------------------------------------------------------
A_GAP, A_CLEAN, A_DEP = "L_40_o1", "L_40_o2", "L_40_o3"
THREE = "shall stop. shall yield. shall wait."


def provider() -> list[dict]:
    """The provider law L-40's two nodes: o1 carries a gap, o2 carries none."""
    return list(pair("L-40"))


def composing(nid: str, law: str, text: str, *targets: str) -> dict:
    return rec.node(nid, text, law, compositions=list(targets))


def dependent(*, clean_only: bool = False) -> rec.World:
    """L-40's o1 carries a gap and its o2 none; L-41's node composes o1 (or, `clean_only`, o2)."""
    w = rec.World({"L-40": TEXT, "L-41": "shall wait."})
    w.plans = {"L-40": provider(), "L-41": [composing("L_41", "L-41", "shall wait.", A_CLEAN if clean_only else A_GAP)]}
    return w


def chain(order: str = "root_first") -> rec.World:
    """L-41's node composes L-40's gap-carrying o1, and L-42's node composes L-41's; `order` lists the
    plan's records root first or the last dependent first."""
    w = rec.World({"L-40": TEXT, "L-41": "shall wait.", "L-42": "shall merge."})
    plans = {"L-40": provider(), "L-41": [composing("L_41", "L-41", "shall wait.", A_GAP)],
             "L-42": [composing("L_42", "L-42", "shall merge.", "L_41")]}
    w.plans = plans if order == "root_first" else dict(reversed(list(plans.items())))
    return w


chain.opts = {"max_iterations": 1}


def in_law(order: str) -> rec.World:
    """L-43's o1 carries a gap, o2 carries none, o3 composes o1; the plan lists them in `order`."""
    o1, o2 = rec.node("L_43_o1", THREE, "L-43"), rec.node("L_43_o2", THREE, "L-43", span="s2")
    o3 = rec.node("L_43_o3", THREE, "L-43", compositions=["L_43_o1"], span="s3")
    o1["gaps"] = [copy.deepcopy(GAP)]
    seg = [("s1", "shall stop."), ("s2", "shall yield."), ("s3", "shall wait.")]
    for n, mine in ((o1, "s1"), (o2, "s2"), (o3, "s3")):
        n["segmentation"] = [{"id": i, "role": "obligation" if i == mine else "sibling", "text": t} for i, t in seg]
    by = {"o1": o1, "o2": o2, "o3": o3}
    w = rec.World({"L-43": THREE})
    w.plans = {"L-43": [by[k] for k in order.split(",")]}
    return w


def two_gaps() -> rec.World:
    """L-46's only node carries two gaps (G1, G2); L-47's node composes it."""
    n = rec.node("L_46", TEXT, "L-46")
    n["segmentation"] = [{"id": "s1", "role": "obligation", "text": "shall stop."}, {"id": "s2", "role": "obligation", "text": "shall yield."}]
    n["gaps"] = [copy.deepcopy(GAP), {**copy.deepcopy(GAP), "span": "s2"}]
    w = rec.World({"L-46": TEXT, "L-47": "shall wait."})
    w.plans = {("L-46", 1): [n], ("L-47", 1): [composing("L_47", "L-47", "shall wait.", "L_46")]}
    return w


def laws(st: dict) -> dict:
    return {e["law"]: e for e in st["ledger"]}


def snapshot(f) -> dict:
    return json.loads((paths.RESULTS / "r" / "state.json").read_text())


def planned_in(w: rec.World, law: str) -> list[int]:
    return sorted(it for (k, ident, it) in w.calls if k == "plan" and law in ident.split(","))


def coded(w: rec.World) -> collections.Counter:
    return collections.Counter({(i, it): c for (k, i, it), c in w.calls.items() if k == "code"})


class GapWaits(unittest.TestCase):
    """A law composing a node whose record carries a pending gap waits on that gap's id, from the
    iteration the gap is filed in, rooted at the provider law; the provider law's clean nodes are
    coded."""

    def assertWaitsOnGap(self, e: dict, gaps: list[str], root: str):
        self.assertEqual((e["state"], e["gaps"], e["own_gaps"], e["waits_on"], e["attempts"]), ("blocked", gaps, [], [root], 0), e)
        self.assertFalse([r for r in e["reasons"] if "re-plan" in r or "(missing)" in r], e["reasons"])
        self.assertFalse([g for g in e["gaps"] if g.startswith("decision:")], e["gaps"])

    def test_a_dependent_waits_on_the_real_gap_in_the_first_iteration(self):
        w = dependent()
        with rec.Fixture(w) as f:
            f.drive(max_iterations=1)
            first = laws(f.state())
            f.drive(max_iterations=3)
            st = f.state()
        self.assertWaitsOnGap(first["L-41"], ["G1"], "L-40")
        self.assertEqual((first["L-40"]["state"], first["L-40"]["gaps"], first["L-40"]["own_gaps"]), ("blocked", ["G1"], ["G1"]))
        self.assertWaitsOnGap(laws(st)["L-41"], ["G1"], "L-40")
        self.assertEqual(planned_in(w, "L-41"), [1])                        # never sent back to the planner
        self.assertEqual(coded(w), collections.Counter({(A_CLEAN, 1): 1}))
        self.assertEqual(sorted(st["accepted_nodes"]), [A_CLEAN])           # the clean sibling is coded and accepted

    def test_a_chain_waits_on_the_roots_gap_whatever_the_plan_order(self):
        for order in ("root_first", "dependent_first"):
            with self.subTest(order=order):
                w = chain(order)
                with rec.Fixture(w) as f:
                    f.drive(max_iterations=1)
                    st = f.state()
                led = laws(st)
                self.assertWaitsOnGap(led["L-41"], ["G1"], "L-40")
                self.assertWaitsOnGap(led["L-42"], ["G1"], "L-40")
                self.assertEqual(led["L-40"]["own_gaps"], ["G1"])
                self.assertEqual(coded(w), collections.Counter({(A_CLEAN, 1): 1}))

    def test_a_dependent_of_only_the_clean_sibling_keeps_the_law_level_wait(self):
        """The clean sibling is coded and published; the law composing it waits while its law is blocked."""
        w = dependent(clean_only=True)
        with rec.Fixture(w) as f:
            f.drive(max_iterations=1)
            first = laws(f.state())
            f.drive(max_iterations=3)
            st = f.state()
        self.assertWaitsOnGap(first["L-41"], ["G1"], "L-40")
        self.assertWaitsOnGap(laws(st)["L-41"], ["G1"], "L-40")
        self.assertEqual(sorted(st["accepted_nodes"]), [A_CLEAN])
        self.assertEqual(coded(w), collections.Counter({(A_CLEAN, 1): 1}))

    def test_a_node_composing_its_gap_carrying_sibling_is_not_coded_whatever_the_order(self):
        for order in ("o1,o2,o3", "o3,o2,o1", "o2,o3,o1"):
            with self.subTest(order=order):
                w = in_law(order)
                with rec.Fixture(w) as f:
                    f.drive(max_iterations=1)
                    st = f.state()
                    prog = snapshot(f)["prog"]
                e = laws(st)["L-43"]
                self.assertEqual((e["state"], e["gaps"], e["own_gaps"]), ("blocked", ["G1"], ["G1"]))
                self.assertEqual(coded(w), collections.Counter({("L_43_o2", 1): 1}))
                self.assertEqual(sorted(st["accepted_nodes"]), ["L_43_o2"])
                self.assertEqual(prog["gap_routes"]["L-43"]["waits"], {"L_43_o1": ["G1"]})
                self.assertTrue(any("`L_43_o3`" in r and "L_43_o1" in r for r in e["reasons"]), e["reasons"])

    def test_the_association_is_recorded_per_node_with_its_law_and_pending_gaps(self):
        w = two_gaps()
        with rec.Fixture(w) as f:
            f.drive(max_iterations=1)
            prog = snapshot(f)["prog"]
            st = f.state()
        self.assertEqual(prog["gap_routes"], {"L-46": {"nodes": ["L_46"], "gaps": ["G1", "G2"], "routed": [], "waits": {"L_46": ["G1", "G2"]}}})
        self.assertWaitsOnGap(laws(st)["L-47"], ["G1", "G2"], "L-46")

    def test_a_partial_decision_still_waits_and_the_last_one_releases(self):
        w = two_gaps()
        w.plans[("L-46", 2)] = [rec.node("L_46", TEXT, "L-46")]
        w.plans[("L-47", 2)] = [composing("L_47", "L-47", "shall wait.", "L_46")]
        with rec.Fixture(w) as f:
            f.drive(max_iterations=1)
            GapLedger(paths.GAPS_DIR).decide("G1", "rejected", "read the words through the halt", resolved_by="particular")
            f.drive(max_iterations=1)
            part = laws(f.state())
            GapLedger(paths.GAPS_DIR).decide("G2", "rejected", "read the words through the yield", resolved_by="particular")
            f.drive(max_iterations=4)
            st = f.state()
        self.assertEqual((part["L-46"]["state"], part["L-46"]["gaps"]), ("blocked", ["G2"]))
        self.assertWaitsOnGap(part["L-47"], ["G2"], "L-46")
        led = laws(st)
        self.assertEqual((led["L-46"]["state"], led["L-47"]["state"]), ("accepted", "accepted"))
        self.assertEqual(sorted(st["accepted_nodes"]), ["L_46", "L_47"])
        self.assertEqual(led["L-47"]["attempts"], 0)

    def test_after_the_decision_the_dependent_follows_the_pin_and_missing_rules(self):
        """The provider's new plan keeps its node, changes it, or withdraws it: the dependent's new plan
        is pinned on what it was validated beside, or goes back to the planner for a missing target;
        no pin is refreshed."""
        kept = rec.node(A_GAP, "shall stop.", "L-40")
        changed = dict(kept, obligation="o, rewritten")
        withdrawn = rec.node("L_40_o4", "shall stop.", "L-40")
        for name, second in (("kept", kept), ("changed", changed), ("withdrawn", withdrawn)):
            with self.subTest(provider=name):
                w = dependent()
                w.plans = {("L-40", 1): provider(), ("L-41", 1): w.plans["L-41"],
                           ("L-40", 2): [second], ("L-41", 2): w.plans["L-41"], ("L-41", 3): [composing("L_41", "L-41", "shall wait.", "L_40_o4")]}
                with rec.Fixture(w) as f:
                    f.drive(max_iterations=1)
                    GapLedger(paths.GAPS_DIR).decide("G1", "rejected", "read the words through the halt", resolved_by="particular")
                    f.drive(max_iterations=2)
                    mid = laws(f.state())
                    f.drive(max_iterations=4)
                    st = f.state()
                b = laws(st)["L-41"]
                if name == "withdrawn":
                    self.assertEqual((mid["L-41"]["state"], mid["L-41"]["attempts"]), ("returned", 0))
                    self.assertTrue(any(f"`{A_GAP}` (pin_mismatch)" in r for r in mid["L-41"]["reasons"]), mid["L-41"]["reasons"])
                    self.assertEqual(planned_in(w, "L-41"), [1, 2, 3])
                    self.assertEqual(st["accepted_nodes"]["L_41"]["planned_on"], {"L_40_o4": loop.pin_digest(st["accepted_nodes"]["L_40_o4"])})
                else:
                    self.assertEqual(planned_in(w, "L-41"), [1, 2])
                    self.assertEqual(st["accepted_nodes"]["L_41"]["planned_on"], {A_GAP: loop.pin_digest(st["accepted_nodes"][A_GAP])})
                self.assertEqual((b["state"], b["attempts"]), ("accepted", 0))

    def test_a_decision_between_validate_and_integrate_clears_the_association(self):
        """The operator decides the gap while the run is stopped after its filing: the resume strikes it
        from the association, the provider law goes back to its planner with the decision, and the
        dependent follows the missing rule; the record that carried the gap is never coded."""
        stop = validated_commit(dependent)
        w = dependent()
        with rec.Fixture(w) as f:
            w.crash_at = stop
            f.drive(launches=1, max_iterations=1)
            GapLedger(paths.GAPS_DIR).decide("G1", "rejected", "read the words through the halt", resolved_by="particular")
            f.drive(max_iterations=1)
            prog = snapshot(f)["prog"]
            led = laws(f.state())
        self.assertEqual((led["L-40"]["state"], led["L-40"]["gaps"]), ("returned", []))
        self.assertTrue(any("G1" in r and "rejected" in r for r in led["L-40"]["reasons"]), led["L-40"]["reasons"])
        self.assertEqual((led["L-41"]["state"], led["L-41"]["gaps"], led["L-41"]["attempts"]), ("returned", [], 0))
        self.assertTrue(any(f"`{A_GAP}` (missing)" in r for r in led["L-41"]["reasons"]), led["L-41"]["reasons"])
        self.assertEqual(prog["gap_routes"]["L-40"]["waits"], {A_GAP: []})
        self.assertEqual(coded(w)[(A_GAP, 1)], 0)

    def test_a_provider_that_does_not_exist_keeps_its_route(self):
        w = rec.World({"L-41": "shall wait."})
        w.plans = {("L-41", 1): [composing("L_41", "L-41", "shall wait.", "L_99")]}
        with rec.Fixture(w) as f:
            f.drive(max_iterations=1)
            e = laws(f.state())["L-41"]
        self.assertEqual((e["state"], e["attempts"]), ("returned", 0))
        self.assertTrue(any("`L_99` (pin_mismatch)" in r and "re-plan" in r for r in e["reasons"]), e["reasons"])


def commits(build) -> list[tuple[int, dict]]:
    """Each snapshot commit of an uninterrupted run of `build`, with the snapshot it wrote."""
    w = build()
    out = []
    real = w.tick

    def tick(*label):
        real(*label)
        if label == ("commit",):
            out.append((w.ticks, json.loads((paths.RESULTS / "r" / "state.json").read_text())))
    w.tick = tick
    with rec.Fixture(w, **getattr(build, "opts", {})) as f:
        rec.prepare(build, w, f)
        f.drive()
    return out


def validated_commit(build) -> int:
    """The tick of the first commit whose iteration is past its validated stage with its gaps filed."""
    return next(k for k, s in commits(build) if (s.get("prog") or {}).get("gap_routes"))


class GapWaitInterruptions(rec.Interruptions, unittest.TestCase):
    """Stopped after the gaps are filed, before the provider law is blocked, or after it, and resumed:
    the ledgers, the association, the pins and the coding calls are those of the uninterrupted run."""

    def outcome(self, build, crash_at=None, edit=None) -> tuple[dict, dict, dict, collections.Counter]:
        w = build()
        with rec.Fixture(w, **getattr(build, "opts", {})) as f:
            if crash_at is not None:
                w.crash_at = crash_at
                f.drive(launches=1)
                if edit is not None:
                    snap = snapshot(f)
                    edit(snap)
                    (paths.RESULTS / "r" / "state.json").write_text(json.dumps(snap))
            f.drive(launches=6)
            st, prog = f.state(), snapshot(f)["prog"]
        return st, prog.get("gap_routes"), prog.get("pins"), coded(w)

    def test_three_stops_end_as_the_uninterrupted_run(self):
        ref = self.outcome(chain)
        self.assertEqual(ref[1]["L-40"]["waits"], {A_GAP: ["G1"]})
        self.assertWaitsOnGapLedger(ref[0])
        seen = commits(chain)
        filed = next(k for k, s in seen if (s.get("prog") or {}).get("gap_routes"))
        before = max(k for k, s in seen if (s.get("prog") or {}).get("gap_routes") and laws(s)["L-40"]["state"] == "planned"
                     and laws(s)["L-41"]["state"] == "blocked")
        after = next(k for k, s in seen if (s.get("prog") or {}).get("gap_routes") and laws(s)["L-40"]["state"] == "blocked")
        self.assertLess(filed, after)
        for name, k in (("after filing", filed), ("before the provider is blocked", before), ("after it is blocked", after)):
            with self.subTest(stop=name):
                got = self.outcome(chain, crash_at=k)
                for key in ref[0]:
                    if key != "to_user":
                        self.assertEqual(got[0][key], ref[0][key], f"{key} differs after a stop {name}")
                self.assertEqual(got[1:], ref[1:], f"the association, pins or coding calls differ after a stop {name}")

    def test_every_stop_ends_as_the_uninterrupted_run(self):
        self.interrupt_everywhere(chain, never=[("code", "L_41", 1), ("code", "L_42", 1), ("code", A_GAP, 1)])

    def test_an_old_snapshot_without_the_per_node_record_keeps_every_wait(self):
        """A snapshot written before the per-node record (`waits`) exists: each node the route names
        waits on every gap the route filed for its law, so no wait is dropped."""
        ref = self.outcome(chain)

        def strip(snap):
            for r in snap["prog"]["gap_routes"].values():
                r.pop("waits")
        got = self.outcome(chain, crash_at=validated_commit(chain), edit=strip)
        for key in ref[0]:
            if key != "to_user":
                self.assertEqual(got[0][key], ref[0][key], key)
        self.assertEqual(got[2:], ref[2:])
        self.assertWaitsOnGapLedger(got[0])

    def assertWaitsOnGapLedger(self, st: dict):
        led = laws(st)
        for law in ("L-41", "L-42"):
            self.assertEqual((led[law]["state"], led[law]["gaps"], led[law]["own_gaps"], led[law]["waits_on"]), ("blocked", ["G1"], [], ["L-40"]))


class CandidateRefusal(Base):
    def test_a_node_change_whose_record_carries_a_gap_is_refused(self):
        concepts, nodes = standard()
        with world(concepts, nodes) as (run, _lib):
            with Txn(run) as txn:
                with self.assertRaisesRegex(cand.ChangeRefused, r"carries a gap on span\(s\) \['o1'\]"):
                    txn.apply([cand.Change("node", NN, node_rec(NN, [CB], gaps=[{"span": "o1", "kind": "atom", "proposal": "x",
                                                                                   "nearest": ["kin.speed"]}]), files("node", NN, "v2"))])
                txn.apply([cand.Change("node", NN, node_rec(NN, [CB]), files("node", NN, "v2"))])    # without the gap it is applied


LAW = corpus.Law(id="L-30", title="L-30", text="A disabled vehicle shall stop.", source="s")
DISABLED = (2, 18)        # "disabled vehicle"


def withdrawing(**over) -> dict:
    """A record of L-30 that carries the words of the gap filed on characters 2–18 with an atom."""
    r = {"node_id": "L_30", "law_refs": ["L-30"], "subject": {"binder": "v", "class_elements": ["ru.motor_vehicle"]},
         "binders": [{"name": "v", "class_elements": ["ru.motor_vehicle"]}],
         "segmentation": [{"id": "s0", "role": "boilerplate", "text": "A "}, {"id": "s1", "role": "subject", "text": "disabled vehicle"},
                          {"id": "s2", "role": "obligation", "text": " shall stop."}],
         "elements": [{"span": "s1", "atoms": ["kin.speed"], "derived": [], "justification": "j"},
                      {"span": "s2", "atoms": ["kin.speed"], "derived": [], "justification": "j"}],
         "applicability": "a", "obligation": "o", "params": [], "scenarios": [{"name": "forbid", "expected": "violated", "narrative": "n"}]}
    r.update(over)
    return r


def ledger_row(gid="G7", state="rejected", law="L-30", at=DISABLED) -> dict:
    return {"id": gid, "kind": "atom", "span": "disabled vehicle", "law_refs": [law], "state": state,
            "occurrence": f"{law}@{review_phase.law_digest(LAW.text)}:{at[0]}-{at[1]}"}


RESOLVED = [{"gap": "G7", "span": "s1", "basis": "the operator's reading: a vehicle that cannot move under its own power"}]


class Withdrawal(unittest.TestCase):
    def check(self, raw, rows):
        return validate_a.check_gap_resolutions(Node(raw), LAW.text, rows)

    def test_a_decided_gap_named_in_gap_resolutions_is_withdrawn(self):
        self.assertEqual(self.check(withdrawing(gap_resolutions=RESOLVED), [ledger_row()]), [])
        self.assertEqual(self.check(withdrawing(gap_resolutions=RESOLVED), [ledger_row(state="retired")]), [])

    def test_the_whole_validator_accepts_it(self):
        with tempfile.TemporaryDirectory() as t:
            (Path(t) / "reading.json").write_text('{"params":[],"aggregates":[]}')
            args = ([Node(withdrawing(gap_resolutions=RESOLVED))], {LAW.id: LAW}, ONTO, Reading(Path(t) / "reading.json"),
                    MappingIndex(Path(t) / "none.json"), {})
            ok = validate_a.validate(*args, ledger_gaps=[ledger_row()])[0]
            args = (([Node(withdrawing())],) + args[1:])
            missing = validate_a.validate(*args, ledger_gaps=[ledger_row()])[0]
        self.assertFalse([r for r in ok.reasons if "gap" in r], ok.reasons)
        self.assertEqual(missing.kind, validate_a.RETURN)
        self.assertTrue(any("gap_resolutions" in r and "G7" in r for r in missing.reasons), missing.reasons)

    def test_a_withdrawal_without_its_entry_is_returned(self):
        errs = self.check(withdrawing(), [ledger_row()])
        self.assertEqual(len(errs), 1)
        self.assertIn("G7", errs[0]); self.assertIn("gap_resolutions", errs[0]); self.assertIn("['s1']", errs[0])
        self.assertTrue(self.check(withdrawing(gap_resolutions=[{**RESOLVED[0], "basis": " "}]), [ledger_row()]))
        self.assertTrue(self.check(withdrawing(gap_resolutions=[{**RESOLVED[0], "span": "s2"}]), [ledger_row()]))

    def test_an_undecided_gap_cannot_be_withdrawn(self):
        for state in ("proposed", "accepted"):
            errs = self.check(withdrawing(), [ledger_row(state=state)])
            self.assertTrue(errs and "not decided" in errs[0], errs)
            errs = self.check(withdrawing(gap_resolutions=RESOLVED), [ledger_row(state=state)])
            self.assertTrue(any("has not decided" in e for e in errs), errs)

    def test_an_entry_naming_an_unknown_gap_or_another_laws_gap_is_returned(self):
        errs = self.check(withdrawing(gap_resolutions=[{**RESOLVED[0], "gap": "G99"}]), [ledger_row()])
        self.assertTrue(any("G99" in e and "no gap of the ledger" in e for e in errs), errs)
        errs = self.check(withdrawing(gap_resolutions=RESOLVED), [ledger_row(law="L-31")])
        self.assertTrue(any("not on this law" in e for e in errs), errs)

    def test_a_record_that_keeps_the_gap_or_does_not_carry_the_words_asks_nothing(self):
        keeps = withdrawing(gaps=[{"span": "s1", "kind": "atom", "proposal": "p", "nearest": ["kin.speed"]}])
        self.assertEqual(self.check(keeps, [ledger_row()]), [])
        sibling = withdrawing(segmentation=[{"id": "s0", "role": "boilerplate", "text": "A "},
                                            {"id": "s1", "role": "sibling", "text": "disabled vehicle"},
                                            {"id": "s2", "role": "obligation", "text": " shall stop."}],
                              elements=[{"span": "s2", "atoms": ["kin.speed"], "derived": [], "justification": "j"}])
        self.assertEqual(self.check(sibling, [ledger_row()]), [])
        self.assertEqual(self.check(withdrawing(), [ledger_row(at=(0, 2))]), [])            # words the record does not carry

    def test_a_fresh_run_asks_nothing(self):
        self.assertEqual(self.check(withdrawing(), []), [])

    def test_the_run_validator_reads_the_ledger_rows(self):
        seen = {}

        def validate(*a, **k):
            seen["rows"] = k.get("ledger_gaps")
            return []
        with tempfile.TemporaryDirectory() as t, mock.patch.object(paths, "GAPS_DIR", Path(t) / "gaps"), \
                mock.patch.object(validate_a, "validate", validate), mock.patch.object(validate_a, "validate_concepts", lambda *a, **k: []):
            led = GapLedger(Path(t) / "gaps")
            (Path(t) / "gaps").mkdir()
            with mock.patch.object(GapLedger, "_measure", staticmethod(lambda row, run: None)):
                gid = led.add({"span": "s1", "kind": "atom", "span_text": "w", "law_refs": ["L-30"]}, "earlier", 1)
            (Path(t) / "blueprint.jsonl").write_text("")
            validate_phase.validate_a_for_run(None, Path(t), {}, None, [], onto=ONTO)
        self.assertEqual([r["id"] for r in seen["rows"]], [gid])

    def test_the_schema_reads_gap_resolutions(self):
        self.assertEqual(validate_a.schema_errors("L_30", withdrawing(gap_resolutions=RESOLVED), validate_a.NODE_SCHEMA), [])
        self.assertTrue(validate_a.schema_errors("L_30", withdrawing(gap_resolutions=[{"gap": "G7"}]), validate_a.NODE_SCHEMA))


class WithdrawalAcceptance(unittest.TestCase):
    """The operator's acceptance cases for withdrawing a gap, each through the whole validator: a
    returned record is never accepted. `gap_resolutions` proves only the link between the operator's
    decision and the record, never that the new formula is semantically right: the validator checks
    no semantics, and the same record with the same atoms passes or is returned on its links alone."""

    def outcome(self, raw, rows):
        with tempfile.TemporaryDirectory() as t:
            (Path(t) / "reading.json").write_text('{"params":[],"aggregates":[]}')
            return validate_a.validate([Node(raw)], {LAW.id: LAW}, ONTO, Reading(Path(t) / "reading.json"),
                                       MappingIndex(Path(t) / "none.json"), {}, ledger_gaps=rows)[0]

    def assertReturned(self, raw, rows, words):
        out = self.outcome(raw, rows)
        self.assertEqual(out.kind, validate_a.RETURN, out.reasons)
        self.assertTrue(any(words in r for r in out.reasons), out.reasons)

    def assertPasses(self, raw, rows):
        out = self.outcome(raw, rows)
        self.assertFalse([r for r in out.reasons if "gap" in r], out.reasons)

    def test_1_an_undecided_gap_dropped_with_or_without_an_entry_is_returned(self):
        for state in ("proposed", "accepted"):
            self.assertReturned(withdrawing(), [ledger_row(state=state)], "has not decided it")
            self.assertReturned(withdrawing(gap_resolutions=RESOLVED), [ledger_row(state=state)], "has not decided")

    def test_2_only_the_entry_naming_the_gap_on_those_words_passes(self):
        for state in ("retired", "rejected"):
            here = ledger_row(state=state)
            other_law = ledger_row("G8", state=state, law="L-31")
            other_place = ledger_row("G9", state=state, at=(19, 30))         # " shall stop.", carried by s2
            rows = [here, other_law]
            self.assertReturned(withdrawing(gap_resolutions=[{**RESOLVED[0], "gap": "G8"}]), rows, "not on this law")
            self.assertReturned(withdrawing(gap_resolutions=[{**RESOLVED[0], "gap": "G9"}]), [here, ledger_row("G9", state=state, at=(0, 2))],
                                "does not hold the words the gap was filed on")
            self.assertReturned(withdrawing(gap_resolutions=[{**RESOLVED[0], "gap": "G9"}]), [here, ledger_row("G9", state=state, at=(0, 2))],
                                "name it in `gap_resolutions`")
            self.assertReturned(withdrawing(), rows, "name it in `gap_resolutions`")
            self.assertReturned(withdrawing(gap_resolutions=[{**RESOLVED[0], "basis": ""}]), rows, "states no `basis`")
            self.assertPasses(withdrawing(gap_resolutions=RESOLVED), rows)
            both = [RESOLVED[0], {"gap": "G9", "span": "s2", "basis": "the operator's reading"}]
            self.assertPasses(withdrawing(gap_resolutions=both), [here, other_place])
            self.assertReturned(withdrawing(gap_resolutions=[RESOLVED[0], {"gap": "G9", "span": "s1", "basis": "b"}]), [here, other_place],
                                "does not hold the words the gap was filed on")


if __name__ == "__main__":
    unittest.main()
