"""`harness reopen --admission`: the one way to let an admission recheck paused at its timeout bound be
timed again, without planning anything again.

It checks the run's integrity as a launch does (a handed-over run against its manifest, a local one
only on its version and policy anchor), refuses while what the law reaches holds an operator's root,
and otherwise resets only the paused records' counts, keeping their seconds and recording the reset:
no ledger, plan, held node, node or concept ledger, label state or spend changes. A plain reopen of
a law whose only wait is such a pause is refused with the command to use. The real loop, admission
recheck, ledgers, handoff and command run on the scripted world of `test_recovery`."""
import contextlib
import io
import json
import unittest
from unittest import mock

from harness.store import paths
from scripts.tests.test_admission_evidence import admission, chain_world, recheck
from scripts.tests.test_recovery import Fixture
from scripts.tests.test_split_handoff import SPLIT, TOOLCHAIN

FROZEN = ("state.json", "ledger.jsonl", "node_ledger.jsonl", "concept_ledger.jsonl", "accepted_nodes.jsonl", "options.json")


def cli(*args, **kw) -> tuple[int, str]:
    from harness.__main__ import Cli
    out = io.StringIO()
    with contextlib.redirect_stdout(out), mock.patch("harness.store.owner.acquire_for_command", lambda name: None):
        code = Cli().reopen(*args, **kw)
    return code, out.getvalue()


def frozen() -> dict:
    rd = paths.RESULTS / "r"
    return {n: (rd / n).read_bytes() for n in FROZEN if (rd / n).exists()}


class AdmissionReopen(unittest.TestCase):

    def paused(self, f, w):
        """L-40's node times out twice under its key: its recheck is paused; L-41 and L-42 compose it."""
        self.assertEqual(f.drive(1, label_deferred=True, max_iterations=4), ["awaiting_labels"])
        cache = admission(); cache.pop("L_40"); (paths.RESULTS / "r" / "admission.json").write_text(json.dumps(cache))
        w.admission["L_40"] = "GATE_TIMEOUT"
        recheck(f); recheck(f)
        self.assertEqual(admission()["L_40"]["timeouts"], 2)

    def test_the_admission_path_resets_the_paused_record_and_nothing_else(self):
        """T37 (a), T41: on a local run that was never handed over, `reopen --admission` for L-41 resets
        only L_40's count (its seconds kept, the reset recorded), names L-42 waiting on it too, and
        leaves every ledger, plan, held node and label state as it was; the next recheck times it again."""
        w = chain_world()
        with Fixture(w, **SPLIT) as f:
            self.paused(f, w)
            self.assertFalse((paths.RESULTS / "r" / "handoff" / "manifest.json").exists())
            seconds = admission()["L_40"]["timeout_seconds"]
            before = frozen()
            code, out = cli("r", laws="L-41", admission=True)
            self.assertEqual(code, 0, out)
            e = admission()["L_40"]
            self.assertEqual((e["timeouts"], e["timeout_seconds"], [r["via_law"] for r in e["resets"]]), (0, seconds, ["L-41"]))
            self.assertIn("L-42", out)
            self.assertEqual(frozen(), before)
            runs = w.admitted["L_40"]
            w.admission["L_40"] = "OK"
            recheck(f)
            self.assertEqual(w.admitted["L_40"], runs + 1)
            self.assertEqual(admission()["L_40"]["verdict"], "OK")

    def test_a_root_in_the_closure_refuses_the_admission_path(self):
        """T37 (b), T40 (iii): with L-40 held for the operator, the admission path for L-41 is refused
        naming the root, and changes nothing (its token included)."""
        w = chain_world()
        with Fixture(w, **SPLIT) as f:
            self.paused(f, w)
            st = json.loads((paths.RESULTS / "r" / "state.json").read_text())
            for e in st["ledger"]:
                if e["law"] == "L-40":
                    e.update(state="blocked", gaps=["decision:L-40"], own_gaps=["decision:L-40"])
            (paths.RESULTS / "r" / "state.json").write_text(json.dumps(st))
            from harness.store.state import Run
            Run(f.options()).restore_state()                  # the projections of the edited snapshot
            before, adm = frozen(), admission()
            code, out = cli("r", laws="L-41", admission=True)
            self.assertNotEqual(code, 0)
            self.assertIn("L-40", out)
            self.assertEqual((frozen(), admission()), (before, adm))

    def test_a_plain_reopen_of_a_law_waiting_only_on_the_pause_is_refused(self):
        """T37 (c): a plain reopen of L-41 would plan it again and drop its work: refused, naming
        `--admission`, nothing changed."""
        w = chain_world()
        with Fixture(w, **SPLIT) as f:
            self.paused(f, w)
            before = frozen()
            code, out = cli("r", laws="L-41")
            self.assertNotEqual(code, 0)
            self.assertIn("--admission", out)
            self.assertEqual(frozen(), before)

    def test_a_handed_over_run_whose_manifest_was_tampered_with_is_refused(self):
        """T41 (control): the same run after a handoff, one file digest of its manifest changed: the
        admission path is refused and changes nothing."""
        from harness.tools import handoff
        w = chain_world()
        with Fixture(w, **SPLIT) as f, mock.patch.object(handoff, "toolchain", lambda: TOOLCHAIN), \
                mock.patch("harness.store.owner.acquire_for_command", lambda name: None):
            self.paused(f, w)
            handoff.export("r", source_baseline="c0ffee")
            mf = paths.RESULTS / "r" / "handoff" / "manifest.json"
            m = json.loads(mf.read_text())
            k = sorted(m["artifacts"])[0]
            m["artifacts"][k] = "0" * 64
            mf.write_text(json.dumps(m))
            before, adm = frozen(), admission()
            code, out = cli("r", laws="L-41", admission=True)
            self.assertNotEqual(code, 0)
            self.assertIn("not as exported", out)
            self.assertEqual((frozen(), admission()), (before, adm))


if __name__ == "__main__":
    unittest.main()


class DependentLawRecovery(unittest.TestCase):
    """The operator's narrow exception to R6-5: a dependent law whose node holds a dependency fence,
    every final cause of which is only an admission gate not yet judged under its current key, may
    run `reopen --admission` itself. It resets only the matching timeout counts along its closure,
    removes no fence or token, re-plans nothing; the dependency fence is evaluated again by the
    recheck's own rule once the provider passes. Any independent block refuses the whole request."""

    def unjudged_provider(self, f, w, provider="L_40"):
        """`provider` rejected (its dependents fenced on it), then a changed gate under which it times
        out twice: it is unjudged at the bound, the dependents still fenced on it."""
        from scripts.tests.test_admission_evidence import KeyedGateFence, change_gate
        cache = admission(); cache.pop(provider, None); (paths.RESULTS / "r" / "admission.json").write_text(json.dumps(cache))
        w.admission[provider] = "CHECK_FAIL"
        recheck(f)
        change_gate(f, "# changed\n")
        w.admission[provider] = "GATE_TIMEOUT"
        recheck(f); recheck(f)
        out = recheck(f)
        self.assertNotIn(provider, out["run"].fenced)
        self.assertEqual(admission()[provider]["timeouts"], 2)
        self.assertEqual(out["run"].fenced["L_41"]["reason"], "dependency")
        return out

    def edit_ledger(self, f, **states):
        from harness.store.state import Run
        st = json.loads((paths.RESULTS / "r" / "state.json").read_text())
        for e in st["ledger"]:
            if e["law"] in states:
                e.update(states[e["law"]])
        (paths.RESULTS / "r" / "state.json").write_text(json.dumps(st))
        Run(f.options()).restore_state()

    def test_a_dependent_law_recovers_a_timed_out_provider(self):
        """1: accepted on L-41; L_40's count reset; every fence and token stays; after a passing
        recheck the dependency fences are lifted by the recheck's own rule."""
        w = chain_world()
        with Fixture(w) as f:
            self.assertEqual(f.drive(1), ["complete"])
            self.unjudged_provider(f, w)
            fenced_before = json.loads((paths.RESULTS / "r" / "state.json").read_text())["fenced"]
            code, out = cli("r", laws="L-41", admission=True)
            self.assertEqual(code, 0, out)
            self.assertEqual((admission()["L_40"]["timeouts"], [r["via_law"] for r in admission()["L_40"]["resets"]]), (0, ["L-41"]))
            self.assertEqual(json.loads((paths.RESULTS / "r" / "state.json").read_text())["fenced"], fenced_before)   # nothing lifted by it
            w.admission["L_40"] = "OK"
            after = recheck(f)
            self.assertEqual(sorted(after["run"].fenced), [])

    def test_an_independent_block_refuses_it(self):
        """2: the same chain with a gap, an operator token, or a definite gate rejection of a second
        provider: refused, nothing reset."""
        for block in ("gap", "token", "failed", "gate", "context", "dependency_defect"):
            with self.subTest(block=block):
                w = chain_world(second_provider=block in ("gate", "context", "dependency_defect"))
                with Fixture(w) as f:
                    self.assertEqual(f.drive(1), ["complete"])
                    if block == "gate":
                        cache = admission(); cache.pop("L_43"); (paths.RESULTS / "r" / "admission.json").write_text(json.dumps(cache))
                        w.admission["L_43"] = "CHECK_FAIL"
                    self.unjudged_provider(f, w)
                    if block == "gap":
                        self.edit_ledger(f, **{"L-42": dict(state="blocked", gaps=["G7"], own_gaps=["G7"])})
                        law = "L-42"
                    elif block == "token":
                        self.edit_ledger(f, **{"L-40": dict(state="blocked", gaps=["decision:L-40"], own_gaps=["decision:L-40"])})
                        law = "L-41"
                    elif block == "failed":                                     # the provider's owner law closed as failed
                        self.edit_ledger(f, **{"L-40": dict(state="failed", gaps=[], own_gaps=[])})
                        law = "L-41"
                    elif block in ("context", "dependency_defect"):            # a second provider fenced for its own reason
                        from harness.store.state import Run
                        st = json.loads((paths.RESULTS / "r" / "state.json").read_text())
                        st["fenced"]["L_43"] = {"kind": "node", "reason": block, "run": "r", "evidence": "scripted"}
                        (paths.RESULTS / "r" / "state.json").write_text(json.dumps(st))
                        Run(f.options()).restore_state()
                        law = "L-41"
                    else:
                        law = "L-41"
                    before, adm = frozen(), admission()
                    code, out = cli("r", laws=law, admission=True)
                    self.assertNotEqual(code, 0, out)
                    self.assertEqual((frozen(), admission()), (before, adm))

    def test_a_batch_with_one_disqualified_law_is_refused_whole(self):
        """4: L-41 qualifies, L-43 is blocked on an operator token: refused whole, nothing reset."""
        w = chain_world(second_provider=False)
        with Fixture(w) as f:
            self.assertEqual(f.drive(1), ["complete"])
            self.unjudged_provider(f, w)
            self.edit_ledger(f, **{"L-43": dict(state="blocked", gaps=["decision:L-43"], own_gaps=["decision:L-43"])})
            before, adm = frozen(), admission()
            code, out = cli("r", laws="L-41,L-43", admission=True)
            self.assertNotEqual(code, 0, out)
            self.assertIn("L-43", out)
            self.assertEqual((frozen(), admission()), (before, adm))

    def test_an_inherited_provider_is_recovered_from_the_dependent_law(self):
        """3: L_40 is inherited from a base run (its law has no entry in this run's ledger); the
        dependent law's `--admission` resets it."""
        from harness import loop as loop_
        from scripts.subset_laws import subset
        w = chain_world()
        with Fixture(w) as f:
            loop_.run_loop(f.options(run_id="A", max_iterations=3))
            f.opt.update(laws=subset("r", f.root / "corpus" / "laws.jsonl", ["L-41", "L-42"]), base_run="A")
            self.assertEqual(f.drive(1, max_iterations=3), ["complete"])
            from harness.store.ledger import Ledger
            self.assertNotIn("L-40", Ledger(paths.RESULTS / "r" / "ledger.jsonl", [], 2).entries)
            self.unjudged_provider(f, w)
            code, out = cli("r", laws="L-41", admission=True)
            self.assertEqual(code, 0, out)
            self.assertEqual(admission()["L_40"]["timeouts"], 0)


class AdmissionOnlyShapes(unittest.TestCase):
    """`admission_only` on hand-built fences: a cycle of dependency fences with no unjudged record is a
    block; a diamond whose two paths end at the same timed-out provider is not."""

    def built(self, nodes: dict, fences: dict, unjudged: set, laws: dict):
        from harness import loop as loop_
        from harness.store.ledger import Ledger
        from scripts.tests.test_candidate import admit, world
        ctx = world({}, nodes)
        run, _lib = ctx.__enter__()
        self.addCleanup(ctx.__exit__, None, None, None)
        led = Ledger(run.ledger_file, list(laws), 2)
        for law, ids in laws.items():
            led.mark_planned(law, ids, 1)
        run.law_entries = led.entries
        cache = json.loads((run.dir / "admission.json").read_text())
        for i in unjudged:
            cache.pop(i, None)
        (run.dir / "admission.json").write_text(json.dumps(cache))
        for i, p in fences.items():
            run.fence(i, "node", "dependency", provider=p, evidence="scripted")
        return loop_, run, led

    @staticmethod
    def comp(nid, *rules):
        from scripts.tests.test_candidate import node_rec
        return node_rec(nid, compositions=[{"span": "o1", "rule": r, "as": "condition", "map": {"v": "v"}} for r in rules])

    def test_a_cycle_of_dependency_fences_is_refused(self):
        A, B, C = "TEST_AO_1", "TEST_AO_2", "TEST_AO_3"
        loop_, run, led = self.built({A: self.comp(A, B), B: self.comp(B), C: self.comp(C, A)}, {A: B, B: A}, set(),
                                     {"TEST-AO-1": [A], "TEST-AO-2": [B], "TEST-AO-3": [C]})
        run.accepted_nodes[B] = self.comp(B, A)                 # the cycle closed after the records were admitted
        av = loop_.Availability(run, entries=led.entries)
        self.assertFalse(loop_.admission_only(run, led, av, "node", A))
        refusals, _lines = loop_.admission_reopen(run, led, ["TEST-AO-3"])
        self.assertTrue(refusals)
        self.assertIn(A, refusals[0])

    def test_a_diamond_to_one_unjudged_provider_is_accepted(self):
        P, B1, B2, D = "TEST_AO_4", "TEST_AO_5", "TEST_AO_6", "TEST_AO_7"
        loop_, run, led = self.built({P: self.comp(P), B1: self.comp(B1, P), B2: self.comp(B2, P), D: self.comp(D, B1, B2)},
                                     {B1: P, B2: P, D: B1}, {P},
                                     {"TEST-AO-4": [P], "TEST-AO-5": [B1], "TEST-AO-6": [B2], "TEST-AO-7": [D]})
        av = loop_.Availability(run, entries=led.entries)
        self.assertEqual(av.code(P, None), "unjudged")
        self.assertTrue(loop_.admission_only(run, led, av, "node", D))
        refusals, _lines = loop_.admission_reopen(run, led, ["TEST-AO-7"])
        self.assertEqual(refusals, [])


class SupersededOrClosedOnThePath(AdmissionOnlyShapes):
    """Every record a dependency fence is followed through must still be its owner law's (in the
    law's current plan, the law planned or accepted): a superseded record, or one whose law is
    blocked or failed, anywhere on the path is an independent block."""

    def chain(self, superseded=None, owner_state=None):
        P, M, D, C = "TEST_AS_1", "TEST_AS_2", "TEST_AS_3", "TEST_AS_4"
        nodes = {P: self.comp(P), M: self.comp(M, P), D: self.comp(D, M), C: self.comp(C, D)}
        laws = {"TEST-AS-1": [P], "TEST-AS-2": [M], "TEST-AS-3": [D], "TEST-AS-4": [C]}
        loop_, run, led = self.built(nodes, {M: P, D: M}, {P}, laws)
        if superseded:
            led.entries[nodes[superseded]["law_refs"][0]].nodes = []
        if owner_state:
            led.entries["TEST-AS-2"].state = owner_state
        return loop_, run, led, (P, M, D, C)

    def test_the_operators_probe_a_superseded_fenced_record_next_to_the_law(self):
        """P unjudged, D fenced on P and no longer in its law's plan, C composes D: refused on D."""
        P, D, C = "TEST_AS_5", "TEST_AS_6", "TEST_AS_7"
        loop_, run, led = self.built({P: self.comp(P), D: self.comp(D, P), C: self.comp(C, D)}, {D: P}, {P},
                                     {"TEST-AS-5": [P], "TEST-AS-6": [D], "TEST-AS-7": [C]})
        led.entries["TEST-AS-6"].nodes = []
        av = loop_.Availability(run, entries=led.entries)
        self.assertFalse(loop_.admission_only(run, led, av, "node", D))
        refusals, _lines = loop_.admission_reopen(run, led, ["TEST-AS-7"])
        self.assertTrue(refusals and D in refusals[0], refusals)

    def test_a_superseded_record_in_the_middle_of_the_chain(self):
        loop_, run, led, (P, M, D, C) = self.chain(superseded="TEST_AS_2")
        av = loop_.Availability(run, entries=led.entries)
        self.assertFalse(loop_.admission_only(run, led, av, "node", D))
        refusals, _lines = loop_.admission_reopen(run, led, ["TEST-AS-4"])
        self.assertTrue(refusals and (D in refusals[0] or M in refusals[0]), refusals)

    def test_an_owner_blocked_or_failed_in_the_middle_of_the_chain(self):
        for state in ("blocked", "failed"):
            with self.subTest(state=state):
                loop_, run, led, (P, M, D, C) = self.chain(owner_state=state)
                av = loop_.Availability(run, entries=led.entries)
                self.assertFalse(loop_.admission_only(run, led, av, "node", D))
                refusals, _lines = loop_.admission_reopen(run, led, ["TEST-AS-4"])
                self.assertTrue(refusals, refusals)

    def test_the_same_chain_with_every_record_its_laws_is_accepted(self):
        loop_, run, led, (P, M, D, C) = self.chain()
        av = loop_.Availability(run, entries=led.entries)
        self.assertTrue(loop_.admission_only(run, led, av, "node", D))
        self.assertEqual(loop_.admission_reopen(run, led, ["TEST-AS-4"])[0], [])
