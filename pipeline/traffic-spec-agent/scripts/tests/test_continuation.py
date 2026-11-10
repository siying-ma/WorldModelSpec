"""Development regression tests for continuation boundaries: a record with no recorded context is
checked, never assumed sound; an inherited node's law is read from its base chain's corpus; a saved
challenge that no longer fits the schema is accounted for; the rulings of every generation of the
chain are inherited; a candidate whose provider is fenced after it was coded waits; one admission
gate registers only its record and what it uses; the base chain's aggregate admissions are restored
before any record is gated; a fence holds only the version it names; and a base run's committed
snapshot, not its projections, is what a continuation inherits."""
import collections
import contextlib
import json
import shutil
import sys
import tempfile
import unittest
from pathlib import Path
from unittest import mock

sys.path.insert(0, str(Path(__file__).resolve().parent))

from harness import loop
from harness.checks import gate
from harness.lean import index_sync, lean
from harness.model import nodeid
from harness.model.blueprint import ConceptRecord, Node
from harness.model.reading import Reading
from harness.phases import aggregate as aggregate_phase, integrate, review
from harness.store import jsonl, paths
from harness.store.state import Options, Run, base_view, fence_applies, record_digest

import test_recovery as R
from test_library_compatibility import Results, N, C

def active(run) -> set[str]:
    """The effective records the operational library is built from: every one not fenced."""
    return (set(run.all_nodes()) | set(run.all_concepts())) - set(run.fenced)


CID = "drv.motion.creep"


def _structural(subject, rid="s1"):
    return {"subject": subject, "ruling_id": rid, "ruling": "upheld", "obligation": "open",
            "schema": review.CONCEPT_STRUCTURAL_SCHEMA, "iteration": 1}


# ---------------------------------------------------------------------------------------------
# A record with no recorded context is checked like one whose context changed
# ---------------------------------------------------------------------------------------------
class MissingContext(unittest.TestCase):

    def test_an_inherited_record_with_no_context_and_an_open_finding_is_fenced(self):
        with Results() as r:
            r.run("A", concepts={CID: C(CID)}, rulings=[_structural(CID)])
            run = r.load("B", "A", ["L-2"])
            ok, failing, unresolved = integrate.recheck_contexts(run, Reading(r.tmp / "none.json"), {"core": "c"}, {})
            self.assertIn(CID, run.fenced)
            self.assertEqual(run.fenced[CID]["reason"], "context")
            self.assertNotIn(CID, run.rechecked)                # no context recorded for a record that failed
            self.assertNotIn(CID, ok)
            self.assertTrue(failing)

    def test_a_record_with_no_obligation_has_its_context_recorded_once(self):
        with Results() as r:
            r.run("A", concepts={CID: C(CID)})
            run = r.load("B", "A", ["L-2"])
            ok, failing, _u = integrate.recheck_contexts(run, Reading(r.tmp / "none.json"), {"core": "c"}, {})
            self.assertEqual((ok, failing, run.fenced), ([CID], [], {}))
            self.assertIn(CID, run.rechecked)
            ok2, _f, _u = integrate.recheck_contexts(run, Reading(r.tmp / "none.json"), {"core": "c"}, {})
            self.assertEqual(ok2, [])                            # unchanged: not checked again

    def test_own_legacy_records(self):
        with Results() as r:
            run = Run(Options("O", r.tmp / "l.jsonl", r.tmp / "o.md", r.tmp / "r.json"),
                      accepted_concepts={CID: C(CID), "drv.motion.halt": C("drv.motion.halt")})
            run.dir.mkdir(parents=True)
            (run.dir / "rulings.jsonl").write_text(json.dumps(_structural(CID)) + "\n")
            integrate.recheck_contexts(run, Reading(r.tmp / "none.json"), {"core": "c"}, {})
            self.assertIn(CID, run.fenced)
            self.assertNotIn("context", run.accepted_concepts[CID])
            self.assertIn("context", run.accepted_concepts["drv.motion.halt"])

    def test_resume_keeps_a_recorded_context(self):
        with Results() as r:
            r.run("A", concepts={CID: C(CID)})
            run = r.load("B", "A", ["L-2"])
            run.dir.mkdir(parents=True, exist_ok=True)
            integrate.recheck_contexts(run, Reading(r.tmp / "none.json"), {"core": "c"}, {})
            from harness.store.ledger import Ledger, ConceptLedger, NodeLedger
            from harness.store.state import commit_state
            commit_state(run, Ledger(run.ledger_file, [], 2), ConceptLedger(run.concept_ledger_file, 3), NodeLedger(run.node_ledger_file, 2))
            again = Run(run.opts)
            again.restore_state(); again.load_accepted()
            self.assertEqual(again.rechecked, run.rechecked)
            ok, _f, _u = integrate.recheck_contexts(again, Reading(r.tmp / "none.json"), {"core": "c"}, {})
            self.assertEqual(ok, [])


# ---------------------------------------------------------------------------------------------
# An inherited node's law is read from its base chain's corpus
# ---------------------------------------------------------------------------------------------
class InheritedLaw(unittest.TestCase):

    def check(self, r, laws_of_A):
        r.run("A", laws=laws_of_A, nodes={"L_1": {**N("L_1", "L-1"), "binders": [], "context": "old"}})
        r.run("B", base="A", laws=["L-2"])
        run = r.load("C", "B", ["L-3"])
        return run, integrate.recheck_contexts(run, Reading(r.tmp / "none.json"), {"core": "c"}, loop.effective_laws(run, {}))

    def test_three_generations_the_inherited_node_is_checked(self):
        with Results() as r:
            run, (ok, failing, unresolved) = self.check(r, ["L-1"])
            self.assertEqual((ok, failing, unresolved), (["L_1"], [], []))
            self.assertIn("L_1", run.rechecked)

    def test_a_law_in_no_corpus_is_diagnosed_not_read_as_checked(self):
        with Results() as r:
            run, (ok, failing, unresolved) = self.check(r, ["L-9"])
            self.assertEqual((ok, failing), ([], []))
            self.assertTrue(unresolved and "L-1" in unresolved[0])
            self.assertNotIn("L_1", run.fenced)
            self.assertNotIn("L_1", run.rechecked)

    def test_the_corpus_of_every_generation_is_read(self):
        with Results() as r:
            r.run("A", laws=["L-1"])
            r.run("B", base="A", laws=["L-2"])
            run = r.load("C", "B", ["L-3"])
            self.assertEqual(sorted(loop.effective_laws(run, {"L-3": object()})), ["L-1", "L-2", "L-3"])


# ---------------------------------------------------------------------------------------------
# A saved challenge that fails today's schema is accounted for, never dropped
# ---------------------------------------------------------------------------------------------
class UnrunnableChallenge(unittest.TestCase):

    BAD = {"ruling_id": "k1", "ruling": "upheld", "obligation": "open", "kind": "too_broad", "iteration": 1,
           "grounding": {}, "instance": {}, "trace": {"scenes": []}, "at": 0}

    def test_an_all_invalid_saved_challenge_fences_and_records_no_context(self):
        with Results() as r:
            rec = {**R.concept(CID), "context": "old"}
            row = {**self.BAD, "subject": CID, "schema": review.CONCEPT_CASE_SCHEMA}
            r.run("A", concepts={CID: rec}, rulings=[row])
            run = r.load("B", "A", ["L-2"])
            with mock.patch.object(lean, "lean_run", side_effect=AssertionError("an invalid case must not reach Lean")):
                execution = review.execute_concept_divergences(ConceptRecord(rec), {"divergences": [row]}, r.tmp / "exec",
                                                              reading=Reading(r.tmp / "none.json"), saved=True)
                ok, failing, _u = integrate.recheck_contexts(run, Reading(r.tmp / "none.json"), {"core": "c"}, {})
            self.assertEqual(execution[:3], ([], [], []))
            self.assertEqual(len(execution[3]), 1)
            self.assertIn("cannot be run as recorded", execution[3][0])
            self.assertIn(CID, run.fenced)
            self.assertNotIn(CID, ok)
            self.assertNotIn(CID, run.rechecked)

    def test_mixed_valid_and_invalid_each_is_accounted_for(self):
        with tempfile.TemporaryDirectory() as t:
            rec = ConceptRecord(R.concept(CID))
            good = {"kind": "fails_wrongly", "contract_words": f"{CID} holds", "contract_verdict": "holds",
                    "grounding": {"v": 1}, "instance": {}, "at": 0,
                    "trace": {"scenes": [{"t": 0, "users": [{"track": 1}]}]}}
            self.assertEqual(review.concept_divergence_defects(1, good, rec, f"{CID} holds", None, True), [])
            with mock.patch.object(lean, "lean_run", return_value=(0, "")), \
                    mock.patch.object(review, "computed_relation_fields", return_value={}, create=True):
                conf, agree, errors, incomplete = review.execute_concept_divergences(
                    rec, {"divergences": [good, self.BAD]}, Path(t), reading=None, saved=True)
            heads = [x.split(":")[0] for x in errors + incomplete] + [x["line"].split(":")[0] for x in conf] + [x.split(":")[0] for x in agree]
            self.assertIn("divergence 2", heads)                # the invalid one, with its defects
            self.assertIn("divergence 1", heads)                # the valid one, run
            self.assertEqual(len(heads), 2)


# ---------------------------------------------------------------------------------------------
# The rulings of every generation of the chain are inherited
# ---------------------------------------------------------------------------------------------
class ChainRulings(unittest.TestCase):

    def test_a_report_one_generation_after_acceptance_reaches_the_next(self):
        with Results() as r:
            r.run("A", concepts={CID: C(CID)})
            r.run("B", base="A", laws=["L-2"], rulings=[{"subject": CID, "key": f"concept:{CID}", "schema": review.CONCEPT_CASE_SCHEMA,
                                                         "case_id": "k1", "ruling_id": "b1", "ruling": "upheld", "obligation": "open",
                                                         "iteration": 1}])
            run_c = r.load("C", "B", ["L-3"])
            rows = [x for x in review.effective_rows(review._all_rows(run_c)) if x.get("subject") == CID]
            self.assertEqual(len(rows), 1)
            self.assertEqual((rows[0]["inherited_from"], rows[0]["ruling_id"]), ("B", "B/b1"))
            self.assertEqual(run_c.provenance[CID], "A")          # the acceptance stays A's

    def test_a_successor_two_generations_later_after_a_satisfaction(self):
        with Results() as r:
            v2 = "drv.motion.creep_v2"
            r.run("A", concepts={CID: C(CID)})
            r.run("B", base="A", laws=["L-2"], rulings=[{"subject": CID, "schema": review.CONCEPT_CASE_SCHEMA, "case_id": "k1",
                                                         "ruling_id": "b1", "ruling": "upheld", "obligation": "open", "iteration": 1}])
            r.run("C", base="B", laws=["L-3"], concepts={v2: {**C(v2), "supersedes": CID}},
                  rulings=[{"subject": v2, "schema": review.CONCEPT_CASE_SCHEMA, "case_id": "k1", "ruling_id": "c1",
                            "supersedes": "B/b1", "ruling": "upheld", "obligation": "satisfied", "iteration": 1}])
            run_d = r.load("D", "C", ["L-4"])
            rows = [x for x in review.effective_rows(review._all_rows(run_d)) if x.get("case_id") == "k1"]
            self.assertEqual([(x["subject"], x["obligation"], x["inherited_from"]) for x in rows], [(v2, "satisfied", "C")])

    def test_a_law_a_generation_replans_carries_no_earlier_ruling(self):
        with Results() as r:
            old, new = N("L_1", "L-1"), {**N("L_1", "L-1"), "applicability": "repaired"}
            r.run("A", laws=["L-1"], nodes={"L_1": old},
                  rulings=[{"subject": "L_1", "ruling_id": "a1", "ruling": "upheld", "obligation": "open", "iteration": 1}])
            r.run("B", base="A", laws=["L-1"], nodes={"L_1": new})
            run_c = r.load("C", "B", ["L-3"])
            self.assertEqual(run_c.provenance["L_1"], "B")
            self.assertEqual([x for x in review._all_rows(run_c) if x.get("subject") == "L_1"], [])


# ---------------------------------------------------------------------------------------------
# A candidate whose provider is fenced after it was coded waits
# ---------------------------------------------------------------------------------------------
V2 = "drv.motion.creep_v2"


def _successor_plans(w: R.World, law: str, text: str, nid: str, **extra) -> None:
    """Iteration 1 plans the concept and its caller; a later plan (the law returned because the
    concept was fenced) proposes its successor, with no counterexample, and calls that."""
    w.plans[(law, 1)] = [R.concept(CID, users=[nid]), R.node(nid, text, law, derived=[CID], **extra)]
    for it in (2, 3):
        w.plans[(law, it)] = [{**R.concept(V2, users=[nid]), "supersedes": CID, "contract": f"{CID} holds"},
                              R.node(nid, text, law, derived=[V2], **extra)]


def late_fence() -> R.World:
    """A concept and the node calling it are coded and reviewed; the context check before
    integration then fences the concept: the node is not accepted on it, its law goes back to the
    planner uncharged, and the successor the next plan proposes is coded and accepted."""
    w = R.World({"L-1": "shall creep."})
    _successor_plans(w, "L-1", "shall creep.", "L_1")
    w.late_fence = {CID}
    return w


def late_fence_composed() -> R.World:
    """As `late_fence`, with a second law whose node composes the node that waits."""
    w = R.World({"L-1": "shall creep.", "L-2": "shall wait."})
    _successor_plans(w, "L-1", "shall creep.", "L_1")
    w.plans["L-2"] = [R.node("L_2", "shall wait.", "L-2", compositions=["L_1"])]
    w.late_fence = {CID}
    return w


class LateFence(R.Interruptions, unittest.TestCase):

    def assert_no_use_of_a_fence(self, ref):
        for nid, rec in ref["accepted_nodes"].items():
            uses = set(rec["elements"][0]["derived"]) | {c["rule"] for c in rec.get("compositions", [])}
            self.assertFalse(uses & set(ref["fenced"]), nid)

    def test_a_late_provider_fence_returns_the_caller_and_its_successor_is_accepted(self):
        ref, n = self.interrupt_everywhere(late_fence)
        self.assertIn(CID, ref["fenced"])
        self.assertEqual(ref["accepted_nodes"]["L_1"]["elements"][0]["derived"], [V2])
        self.assertIn(V2, ref["accepted_concepts"])
        self.assert_no_use_of_a_fence(ref)
        self.assertEqual({e["law"]: e["attempts"] for e in ref["ledger"]}, {"L-1": 0})   # a fence after the plan charges nothing

    def test_a_composed_pending_caller_waits_too(self):
        ref, _log, _calls, _st = R.reference(late_fence_composed)
        self.assertIn(CID, ref["fenced"])
        self.assert_no_use_of_a_fence(ref)
        self.assertEqual(ref["accepted_nodes"]["L_1"]["elements"][0]["derived"], [V2])
        self.assertIn("L_2", ref["accepted_nodes"])            # it composes the replacement, accepted after it
        for e in ref["ledger"]:
            self.assertEqual(e["attempts"], 0, e)

    def test_unavailable_candidates_follow_pending_compositions(self):
        run = Run(Options("r", Path("l"), Path("o"), Path("r")))
        run.fenced[CID] = {"kind": "concept", "reason": "context"}
        a = Node(R.node("L_1", "x", "L-1", derived=[CID]))
        b = Node(R.node("L_2", "y", "L-2", compositions=["L_1"]))
        c = Node(R.node("L_3", "z", "L-3"))
        run.law_entries = {}
        out = loop.integration_holds(run, [a, b, c], [], {"drv.motion.other": {CID}})
        self.assertEqual(sorted(out), ["L_1", "L_2", "drv.motion.other"])


# ---------------------------------------------------------------------------------------------
# One admission gate registers its record and what it uses, nothing else
# ---------------------------------------------------------------------------------------------
class AdmissionSelection(unittest.TestCase):

    def setUp(self):
        self.r = Results().__enter__()
        self.addCleanup(self.r.__exit__)
        (self.r.tmp / "library").mkdir()
        p = mock.patch.object(paths, "LIBRARY", self.r.tmp / "library"); p.start(); self.addCleanup(p.stop)
        p = mock.patch.object(integrate, "_files_digest", lambda rels: "files"); p.start(); self.addCleanup(p.stop)

    def test_the_selection_is_the_record_and_its_providers(self):
        self.r.run("A", laws=["L-1", "L-2"],
                   nodes={"L_1": N("L_1", "L-1", derived=["drv.motion.alpha"]), "L_2": N("L_2", "L-2", composes=["L_1"])},
                   concepts={"drv.motion.alpha": C("drv.motion.alpha", calls=["drv.motion.beta"]), "drv.motion.beta": C("drv.motion.beta"),
                             "drv.motion.zz_broken": C("drv.motion.zz_broken")})
        run = self.r.load("B", "A", ["L-3"])
        self.assertEqual(integrate.admission_selection(run, "node", "L_2"),
                         {"nodes": ["L_1", "L_2"], "concepts": ["drv.motion.alpha", "drv.motion.beta"], "keep": ["L_2"], "missing": []})
        self.assertEqual(integrate.admission_selection(run, "concept", "drv.motion.alpha"),
                         {"nodes": [], "concepts": ["drv.motion.alpha", "drv.motion.beta"], "keep": ["drv.motion.alpha"], "missing": []})

    def test_a_missing_provider_is_named_never_dropped(self):
        """T15 (missing): a target the view holds no record of, directly or through a node it
        composes, is named in `missing`; the availability rule gives the dependency's code."""
        self.r.run("A", laws=["L-1", "L-2", "L-3"], nodes={"L_1": N("L_1", "L-1", composes=["L_9"]), "L_2": N("L_2", "L-2", composes=["L_1"])})
        run = self.r.load("B", "A", ["L-4"])
        run.law_entries = {}
        self.assertEqual(integrate.admission_selection(run, "node", "L_2")["missing"], ["L_9"])
        self.assertEqual(integrate.admission_selection(run, "node", "L_1")["missing"], ["L_9"])
        self.assertEqual(run.provider_code("L_2", None), "via:L_1:via:L_9:missing")

    def scripted(self, broken):
        """Gates whose build fails when the registry they are given carries the broken record (as a
        real build fails on an unrelated module that does not compile)."""
        seen = []

        def build(ident, work):
            sel = gate.task_registry(work)
            registered = set(sel[0] or []) | set(sel[1] or []) | {ident} if sel != (None, None) else {"<every file on disk>"}
            seen.append((ident, registered))
            if ident == broken:
                return gate.Verdict("BUILD_FAIL", ["its own file does not compile"])
            if broken in registered or "<every file on disk>" in registered:
                return gate.Verdict(gate.INFRA, ["the build failed outside the candidate's files"])
            return gate.Verdict("OK", [])
        return seen, (lambda n, reading, baseline, work, used, budget, accepted_concepts=None, acquisition=None: build(n.id, work)), \
            (lambda rec, reading, baseline, work, used, budget, mode="train", accepted=None: build(rec.id, work))

    def run_admission(self, broken, extra_concepts):
        concepts = {"drv.motion.good": C("drv.motion.good"), broken: C(broken), **extra_concepts}
        self.r.run("A", laws=["L-1"], nodes={"L_1": N("L_1", "L-1", derived=["drv.motion.good"])}, concepts=concepts)
        run = self.r.load("B", "A", ["L-3"])
        run.dir.mkdir(parents=True, exist_ok=True)
        seen, ng, cg = self.scripted(broken)
        with mock.patch.object(gate, "run_gate", ng), mock.patch.object(gate, "run_concept_gate", cg), \
                mock.patch.object(gate, "repo_digest", lambda: {}):
            failed = integrate.admission_recheck(run, Reading(self.r.tmp / "none.json"), {"core": "c"})
        return run, failed, seen

    def test_a_broken_source_after_the_healthy_record(self):
        run, failed, seen = self.run_admission("drv.motion.zz_broken", {})
        self.assertEqual(set(failed), {"drv.motion.zz_broken"})
        self.assertNotIn("drv.motion.good", run.fenced)
        self.assertNotIn("L_1", run.fenced)
        self.assertEqual(index_sync.inactive(), {"drv.motion.zz_broken"})

    def test_a_broken_source_before_the_healthy_record(self):
        run, failed, seen = self.run_admission("drv.motion.aa_broken", {})
        self.assertEqual(set(failed), {"drv.motion.aa_broken"})
        self.assertNotIn("drv.motion.good", run.fenced)

    def test_a_broken_source_behind_a_provider_chain(self):
        run, failed, seen = self.run_admission("drv.motion.aa_broken", {"drv.motion.mid": C("drv.motion.mid", calls=["drv.motion.aa_broken"]),
                                                                        "drv.motion.top": C("drv.motion.top", calls=["drv.motion.mid"])})
        self.assertEqual(set(failed), {"drv.motion.aa_broken"})
        self.assertEqual(run.fenced["drv.motion.mid"]["reason"], "dependency")
        self.assertEqual(run.fenced["drv.motion.top"]["reason"], "dependency")
        self.assertNotIn("drv.motion.mid", [i for i, _reg in seen])      # fenced by its provider, never gated
        self.assertNotIn("drv.motion.good", run.fenced)

    def test_a_repeated_launch_needs_no_manual_retry(self):
        run, failed, seen = self.run_admission("drv.motion.zz_broken", {})
        run2 = self.r.load("B", "A", ["L-3"])
        seen2, ng, cg = self.scripted("drv.motion.zz_broken")
        with mock.patch.object(gate, "run_gate", ng), mock.patch.object(gate, "run_concept_gate", cg), \
                mock.patch.object(gate, "repo_digest", lambda: {}):
            integrate.admission_recheck(run2, Reading(self.r.tmp / "none.json"), {"core": "c"})
        self.assertEqual(seen2, [])                              # every verdict a cache hit
        self.assertIn("drv.motion.zz_broken", run2.fenced)


@unittest.skipUnless(shutil.which("lake"), "needs the toolchain")
class AdmissionSelectionLean(unittest.TestCase):
    """The real gates in a disposable copy of the library: an unrelated concept that does not compile
    is never in a healthy record's admission build."""

    def test_real_gates_isolate_an_unrelated_broken_source(self):
        fx = json.loads((Path(__file__).parent / "admission_isolation_fixture.json").read_text(encoding="utf-8"))
        good = fx["record"]["concept_id"]
        concepts = {good: fx["record"]}
        with tempfile.TemporaryDirectory(prefix="admission-isolation-") as td, contextlib.ExitStack() as st:
            tmp = Path(td); lib = tmp / "library"
            shutil.copytree(paths.LIBRARY, lib, ignore=shutil.ignore_patterns(".run.lock", ".run.owner.json", ".inactive.json", ".build.lock"))
            for rel, text in ((nodeid.concept_path(good), fx["source"]), (nodeid.concept_witness_path(good), fx["witness"])):
                (lib / rel).parent.mkdir(parents=True, exist_ok=True); (lib / rel).write_text(text, encoding="utf-8")
            (tmp / "reading.json").write_text(json.dumps(fx["reading"]), encoding="utf-8")
            reading = Reading(tmp / "reading.json")
            mapping = {"LIBRARY": lib, "CORE": lib / "TrafficSpec/Core", "RULES_DIR": lib / "TrafficSpec/Rules",
                       "CONCEPTS_DIR": lib / "TrafficSpec/Concepts", "WITNESS_DIR": lib / "TrafficSpecWitness",
                       "CONCEPT_WITNESS_DIR": lib / "TrafficSpecWitness/Concepts", "INDEX_FILE": lib / "TrafficSpec/Index.lean",
                       "WITNESS_ROOT_FILE": lib / "TrafficSpecWitness.lean", "RESULTS": tmp / "results"}
            for key, value in mapping.items():
                st.enter_context(mock.patch.object(paths, key, value))
            verdicts = {}
            for bad in ("drv.motion.aa_audit_bad", "drv.motion.zz_audit_bad"):        # before and after the healthy record
                cf, wf = lib / nodeid.concept_path(bad), lib / nodeid.concept_witness_path(bad)
                cf.parent.mkdir(parents=True, exist_ok=True); wf.parent.mkdir(parents=True, exist_ok=True)
                cf.write_text(f"import TrafficSpec.Core.Language.Rule\nnamespace {nodeid.concept_namespace(bad)}\n"
                              f"def concept := unknown_audit_identifier\nend {nodeid.concept_namespace(bad)}\n")
                wf.write_text(f"import {nodeid.concept_module(bad)}\nnamespace {nodeid.concept_witness_namespace(bad)}\n"
                              f"end {nodeid.concept_witness_namespace(bad)}\n")
                other = {**concepts[good], "concept_id": bad, "contract": "an unrelated record whose file does not compile",
                         "body_json": {"unrelated": bad}, "canonical_body": bad}   # not a duplicate of the healthy record's body
                run = Run(Options(f"fixture_{bad[-12:]}", tmp / "laws.jsonl", paths.REPO / "ontology/ATOMS_train.md", reading.path),
                          accepted_concepts={good: concepts[good], bad: other})
                run.dir.mkdir(parents=True)
                index_sync.set_inactive(set(), run.opts.run_id)
                failed = integrate.admission_recheck(run, reading, {"core": "current", "ontology": "current"})
                verdicts[bad] = (sorted(failed), sorted(run.fenced))
                cf.unlink(); wf.unlink()
            for bad, (failed, fenced) in verdicts.items():
                self.assertEqual(failed, [bad], verdicts)
                self.assertEqual(fenced, [bad], verdicts)


# ---------------------------------------------------------------------------------------------
# The base chain's aggregate admissions are restored before any record is gated
# ---------------------------------------------------------------------------------------------
AGG = "DEF-1::vehicle"


def aggregate_world() -> R.World:
    """A base run accepted a node that claims an admitted aggregate; a continuation re-plans another
    law. Its admission gate fails when the run's reading lacks the aggregate, as the real gate does
    (`CHECK_FAIL`: the aggregate is not declared by the reading); the base's admission is restored
    into the continuation's reading by the aggregate check."""
    w = R.World({"L-1": "shall stop.", "L-2": "shall yield."})
    w.restored = []
    return w


def _aggregate_before(f, w):
    from scripts.subset_laws import subset
    w.plans = {"L-1": [R.node("L_1", "shall stop.", "L-1")]}
    loop.run_loop(f.options(run_id="A"))
    w.plans = {"L-2": [R.node("L_2", "shall yield.", "L-2")]}
    f.opt.update(laws=subset("r", f.root / "corpus" / "laws.jsonl", ["L-2"]), base_run="A")


aggregate_world.before = _aggregate_before


class AggregateOrder(R.Interruptions, unittest.TestCase):

    def patches(self, w, *, stale=False):
        """The aggregate check restores the base's admission into the run's reading (a tick, so a stop
        can fall between it and the gates); the admission gate fails a node whose reading lacks it."""
        def check_admissions(run, laws, defs, onto, claimants):
            if stale:
                return [], [f"aggregate `{AGG}` of base run `A` has changed inputs and is claimed by ['L_1']"]
            data = jsonl.read_json(run.reading_file, {"params": []}) or {"params": []}
            if not any(a.get("id") == AGG for a in data.get("aggregates", [])) and run.opts.base_run:
                data.setdefault("aggregates", []).append({"id": AGG, "included": ["ru.motor_vehicle"]})
                jsonl.write_atomic(run.reading_file, json.dumps(data))
                w.restored.append(run.opts.run_id)
                w.tick("aggregate_restored")
            return [], []
        real = integrate.admission_recheck

        def admission_recheck(run, reading, base, unjudged=None, notes=None):
            has = any(a.get("id") == AGG for a in (jsonl.read_json(run.reading_file, {}) or {}).get("aggregates", []))
            w.admission["L_1"] = "OK" if has or not run.opts.base_run else "CHECK_FAIL"
            return real(run, reading, base)
        return [mock.patch.object(aggregate_phase, "check_admissions", check_admissions),
                mock.patch.object(integrate, "admission_recheck", admission_recheck)]

    def test_a_healthy_aggregate_node_is_not_fenced_at_startup(self):
        w = aggregate_world()
        with R.Fixture(w) as f:
            with contextlib.ExitStack() as st:
                for p in self.patches(w):
                    st.enter_context(p)
                R.prepare(aggregate_world, w, f)
                statuses = f.drive()
                state = f.state()
        self.assertEqual(statuses[-1], "complete")
        self.assertEqual(state["fenced"], {})
        self.assertIn("L_2", state["accepted_nodes"])

    def test_an_interrupted_restoration_completes_on_resume(self):
        _ref_w = aggregate_world()
        with R.Fixture(_ref_w) as f:
            with contextlib.ExitStack() as st:
                for p in self.patches(_ref_w):
                    st.enter_context(p)
                R.prepare(aggregate_world, _ref_w, f)
                f.drive()
                ref = f.state()
                n = _ref_w.ticks
        for k in range(1, n + 1):
            w = aggregate_world(); w.crash_at = k
            with R.Fixture(w) as f:
                with contextlib.ExitStack() as st:
                    for p in self.patches(w):
                        st.enter_context(p)
                    R.prepare(aggregate_world, w, f)
                    f.drive(launches=6)
                    got = f.state()
            for key in ("fenced", "accepted_nodes", "ledger"):
                self.assertEqual(got[key], ref[key], f"{key} after a stop at tick {k}")

    def test_a_changed_definition_stops_before_any_gate(self):
        w = aggregate_world()
        with R.Fixture(w) as f:
            with contextlib.ExitStack() as st:
                for p in self.patches(w, stale=True):
                    st.enter_context(p)
                R.prepare(aggregate_world, w, f)
                admitted_before = sum(w.admitted.values())
                statuses = f.drive(launches=1)
        self.assertEqual(statuses, ["stale_aggregate"])
        self.assertEqual(sum(w.admitted.values()), admitted_before)   # no record was gated on a stale mapping


# ---------------------------------------------------------------------------------------------
# A fence holds only the version it names
# ---------------------------------------------------------------------------------------------
class FenceIdentity(unittest.TestCase):

    def test_a_repaired_replacement_under_the_same_id_is_active(self):
        with Results() as r:
            old, new = N("L_1", "L-1"), {**N("L_1", "L-1"), "applicability": "repaired"}
            r.run("A", laws=["L-1"], nodes={"L_1": old},
                  state={"fenced": {"L_1": {"kind": "node", "reason": "gate", "evidence": "old version failed"}}})
            r.run("B", base="A", laws=["L-1"], nodes={"L_1": new})
            run = r.load("C", "B", ["L-3"])
            self.assertEqual(run.provenance["L_1"], "B")
            self.assertNotIn("L_1", run.fenced)
            self.assertIn("L_1", active(run))
            self.assertIn("L_1", [f["id"] for f in run.fence_history])   # the old version stays fenced, as history

    def test_a_fence_naming_its_version_still_holds_that_version(self):
        with Results() as r:
            rec = N("L_1", "L-1")
            r.run("A", laws=["L-1"], nodes={"L_1": rec},
                  state={"fenced": {"L_1": {"kind": "node", "reason": "gate", "record": record_digest(rec), "run": "A"}}})
            run = r.load("C", "A", ["L-3"])
            self.assertIn("L_1", run.fenced)
            self.assertNotIn("L_1", active(run))

    def test_a_fence_written_by_a_later_run_on_an_earlier_record_holds(self):
        self.assertTrue(fence_applies({"run": "B"}, N("L_1", "L-1"), "A", ["A", "B", "C"]))
        self.assertFalse(fence_applies({"run": "A"}, N("L_1", "L-1"), "B", ["A", "B", "C"]))
        self.assertFalse(fence_applies({"record": "x"}, None, "A", ["A"]))

    def test_own_run_acceptance_of_a_new_version_retires_the_old_fence(self):
        run = Run(Options("r", Path("l"), Path("o"), Path("r")), accepted_nodes={"L_1": N("L_1", "L-1")})
        run.fence("L_1", "node", "context", evidence="old")
        self.assertEqual(run.fenced["L_1"]["record"], record_digest(N("L_1", "L-1")))
        run.accepted_nodes["L_1"] = {**N("L_1", "L-1"), "applicability": "repaired"}
        self.assertEqual(run.reconcile_fences(), ["L_1"])
        self.assertNotIn("L_1", run.fenced)

    def test_a_real_loop_repair_is_active_and_stays_active_on_resume(self):
        w = R.World({"L-1": "Do not move."})
        w.plans["L-1"] = [R.node("L_1", w.laws["L-1"], "L-1")]
        with R.Fixture(w, max_iterations=1) as f:
            f.drive(launches=1, run_id="A")
            file = paths.RESULTS / "A" / "state.json"
            snap = json.loads(file.read_text())
            snap["fenced"] = {"L_1": {"kind": "node", "reason": "context", "evidence": "old version failed"}}
            file.write_text(json.dumps(snap))
            w.plans["L-1"] = [{**R.node("L_1", w.laws["L-1"], "L-1"), "applicability": "repaired"}]
            from scripts.subset_laws import subset
            f.drive(launches=1, run_id="B", base_run="A", laws=subset("B", f.root / "corpus" / "laws.jsonl", ["L-1"]))
            b = json.loads((paths.RESULTS / "B" / "state.json").read_text())
            self.assertIn("L_1", b["accepted_nodes"])
            self.assertNotIn("L_1", b["fenced"])
            self.assertNotIn("L_1", index_sync.inactive())
            again = Run.load("B")                                  # a resume of B, and a continuation of it
            self.assertNotIn("L_1", again.fenced)
            self.assertIn("L_1", active(again))
            other = f.root / "other_laws.jsonl"
            other.write_text(json.dumps({"id": "L-9", "title": "L-9", "text": "Another.", "source": "s"}) + "\n")
            c = Run(Options("C", other, f.root / "ontology.md", f.root / "reading.json", base_run="B"))
            c.load_accepted()
            self.assertIn("L_1", active(c))


# ---------------------------------------------------------------------------------------------
# A base run's committed snapshot is what a continuation inherits
# ---------------------------------------------------------------------------------------------
class SnapshotAuthority(unittest.TestCase):

    def test_a_committed_acceptance_behind_a_stale_projection(self):
        with Results() as r:
            r.run("A", laws=["L-1"], nodes={}, concepts={},
                  state={"accepted_nodes": {"L_1": N("L_1", "L-1")}, "accepted_concepts": {CID: C(CID)}, "fenced": {}})
            run = r.load("B", "A", ["L-2"])
            self.assertIn("L_1", run.all_nodes())
            self.assertIn(CID, run.all_concepts())
            self.assertEqual((run.provenance["L_1"], run.provenance[CID]), ("A", "A"))

    def test_cuts_after_the_snapshot_and_after_each_projection(self):
        committed = {"L_1": N("L_1", "L-1"), "L_2": N("L_2", "L-2")}
        concepts = {CID: C(CID)}
        for nodes_proj, concepts_proj in (({}, {}), (committed, {}), ({"L_1": committed["L_1"]}, concepts), (committed, concepts)):
            with Results() as r:
                r.run("A", laws=["L-1", "L-2"], nodes=nodes_proj, concepts=concepts_proj,
                      state={"accepted_nodes": committed, "accepted_concepts": concepts,
                             "fenced": {CID: {"kind": "concept", "reason": "gate", "record": record_digest(C(CID))}}})
                view = base_view("A")
                self.assertEqual(sorted(view["nodes"]), ["L_1", "L_2"])
                self.assertEqual(sorted(view["concepts"]), [CID])
                self.assertEqual(sorted(view["fenced"]), [CID])

    def test_a_run_with_no_snapshot_is_read_from_its_projections(self):
        with Results() as r:
            r.run("A", laws=["L-1"], nodes={"L_1": N("L_1", "L-1")})
            self.assertEqual(sorted(base_view("A")["nodes"]), ["L_1"])

    def test_nothing_of_the_base_is_rewritten(self):
        with Results() as r:
            r.run("A", laws=["L-1"], nodes={}, state={"accepted_nodes": {"L_1": N("L_1", "L-1")}, "accepted_concepts": {}})
            before = {p.name: p.read_bytes() for p in (paths.RESULTS / "A").iterdir() if p.is_file()}
            r.load("B", "A", ["L-2"])
            after = {p.name: p.read_bytes() for p in (paths.RESULTS / "A").iterdir() if p.is_file()}
            self.assertEqual(before, after)


# ---------------------------------------------------------------------------------------------
# A context check that cannot run before integration stops the iteration; the resume makes it
# ---------------------------------------------------------------------------------------------
class LateUnavailableCheck(unittest.TestCase):

    def drive(self, outage_launches: int, launches: int = 2):
        real_recheck = integrate.recheck_contexts
        w = R.World({"L-1": "shall creep."})
        w.plans["L-1"] = [R.concept(CID, users=["L_1"]), R.node("L_1", "shall creep.", "L-1", derived=[CID])]
        seen = []
        with R.Fixture(w, max_iterations=1) as f:
            def recheck(run, reading, base, laws):
                if CID in run.all_concepts() and not any(r.get("case_id") == "kept" for r in review._all_rows(run)):
                    review.append_ruling(run, {"subject": CID, "key": f"concept:{CID}", "schema": review.CONCEPT_CASE_SCHEMA,
                        "case_id": "kept", "ruling": "upheld", "obligation": "satisfied", "iteration": 1, "kind": "fails_wrongly",
                        "contract_words": f"{CID} holds", "contract_verdict": "holds", "grounding": {"v": 1}, "instance": {},
                        "at": 0, "trace": {"scenes": [{"t": 0, "users": [{"track": 1}]}]}})
                if CID in run.all_concepts() and len([x for x in seen if x is not None]) < outage_launches:
                    with mock.patch.object(review, "execute_concept_divergences", side_effect=review.HarnessFailure("a toolchain outage")):
                        out = real_recheck(run, reading, base, laws)
                else:
                    with mock.patch.object(review, "execute_concept_divergences", return_value=([], [], [], [])):
                        out = real_recheck(run, reading, base, laws)
                seen.append(out if CID in run.all_concepts() else None)
                return out
            with mock.patch.object(integrate, "recheck_contexts", side_effect=recheck):
                statuses = f.drive(launches=launches)
            state = json.loads((paths.RESULTS / "r" / "state.json").read_text())
        return statuses, state, seen

    def test_an_unresolved_late_check_integrates_nothing(self):
        statuses, state, seen = self.drive(outage_launches=1, launches=1)
        self.assertTrue([x for x in seen if x] and [x for x in seen if x][0][2], seen)   # the check could not be made
        self.assertEqual(statuses[0], "infrastructure_failure")
        self.assertNotIn("L_1", state["accepted_nodes"])
        self.assertFalse(state["prog"].get("contexts_rechecked"))
        self.assertIsNone(state["prog"].get("integration"))
        self.assertNotIn(CID, state["fenced"])                          # an outage decides nothing about the record
        law = {e["law"]: e for e in state["ledger"]}["L-1"]
        self.assertEqual(law["attempts"], 0)

    def test_the_resume_makes_the_check_and_integrates(self):
        statuses, state, _seen = self.drive(outage_launches=1)
        self.assertEqual(statuses, ["infrastructure_failure", "complete"])
        self.assertIn("L_1", state["accepted_nodes"])
        self.assertTrue(state["prog"].get("contexts_rechecked"))


if __name__ == "__main__":
    unittest.main()
