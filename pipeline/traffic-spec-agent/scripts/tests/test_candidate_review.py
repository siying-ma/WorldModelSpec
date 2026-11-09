"""The concept review inside a candidate transaction: a changed concept is reviewed on the candidate
before it commits (an upheld challenge refuses the commit); the rulings it makes are the candidate's,
published with its commit and never after a rollback; a changed body has its callers' obligations
certified again on the candidate, and a context or a review whose inputs did not change is reused;
a report that a concept computes what its contract excludes is judged on the candidate (form,
execution, concept adjudication) and routed by its ruling; the roles of the training path hold; and
a concept's repair is shown the concept's state.

The reviewer and the adjudicator are stand-ins that keep the review's own record-keeping
(`resume_review`, `finish_review`, the rulings); the gate's toolchain, the whole-library build and the
validator are stood in for; the candidate, the context check and the rulings files are the real ones."""
import json
import unittest
from pathlib import Path
from unittest import mock

from harness.phases import candidate as cand
from harness.phases import integrate, label_repair, plan, review
from harness.loop import context_base, semantic_inputs
from harness.model.reading import Reading
from harness.store import jsonl
from scripts.tests.test_candidate import CA, CB, CD, NN, Base, Txn, concept_rec, files, node_rec, standard, world
from scripts.tests.test_label_repair import L, N, RECS
from scripts.tests.test_label_repair_session import repair, repairing, set_verdict


class Reviewer:
    """The concept review as a stand-in: it keeps the review's saved outcome and its rulings as the
    real one does, asks its `answer` only when no saved outcome has the same inputs, and records one
    ruling per review."""

    def __init__(self, status="accepted"):
        self.status, self.asked, self.libraries = status, 0, []

    def __call__(self, run, rec, extras, out_dir):
        from harness.store import paths
        self.libraries.append((str(paths.LIBRARY), str(review._rulings_file(run))))
        out_dir.mkdir(parents=True, exist_ok=True)
        rulings, decided = review.resume_review(run, out_dir, lambda rows: review._inputs_digest({"record": rec.raw, "files": extras.get("files")}))
        if decided is not None:
            return review.outcome_of(decided)
        self.asked += 1
        rulings.add({"subject": rec.id, "key": f"concept:{rec.id}", "schema": review.CONCEPT_CASE_SCHEMA, "case_id": f"c-{self.asked}",
                     "ruling": "upheld" if self.status == "returned" else "dismissed", "obligation": "open" if self.status == "returned" else None})
        return review.finish_review(run, out_dir, rulings, {}, review.ReviewOutcome(self.status, reasons=["stand-in"]), True)


def rows_of(run) -> list[dict]:
    return jsonl.read_strict(run.dir / "rulings.jsonl")


class ReviewInTheCandidate(Base):

    def test_a_changed_concept_is_reviewed_on_the_candidate_and_an_upheld_item_refuses_the_commit(self):
        concepts, nodes = standard()
        with world(concepts, nodes) as (run, lib):
            rev = Reviewer("returned")
            with mock.patch.object(review, "review_concept", rev), Txn(run, hooks=(cand.concept_review,)) as txn:
                txn.apply([cand.Change("concept", CA, concepts[CA], files("concept", CA, "v2"))])
                results = txn.verify()
                self.assertEqual([(r.check, r.subject, r.status) for r in results if r.check == "concept_review"], [("concept_review", CA, "fail")])
                self.assertEqual(rev.libraries, [(str(txn.library), str(txn.area / "rulings.jsonl"))])
                with self.assertRaisesRegex(cand.CommitRefused, "concept_review"):
                    txn.commit()
                txn.rollback("upheld")
            self.assertEqual(rows_of(run), [])                                   # no ruling of the rolled-back candidate is published
            self.assertEqual(review.effective_rows(review._all_rows(run)), [])
            self.assertEqual(len(jsonl.read_strict(txn.area / "rulings.jsonl")), 1)    # kept as its diagnostics

    def test_a_commit_publishes_the_candidates_rulings_after_the_runs(self):
        concepts, nodes = standard()
        with world(concepts, nodes) as (run, lib):
            review.append_ruling(run, {"subject": CD, "key": f"concept:{CD}", "ruling": "dismissed"})
            before = rows_of(run)
            with mock.patch.object(review, "review_concept", Reviewer()), Txn(run, hooks=(cand.concept_review,)) as txn:
                txn.apply([cand.Change("concept", CA, concepts[CA], files("concept", CA, "v2"))])
                self.assertTrue(all(r.status == "pass" for r in txn.verify()))
                txn.commit()
            after = rows_of(run)
            self.assertEqual(after[:1], before)                                  # append-only: the run's rows first, unchanged
            self.assertEqual([r["subject"] for r in after[1:]], [CA])

    def test_a_review_whose_inputs_did_not_change_is_reused(self):
        concepts, nodes = standard()
        with world(concepts, nodes) as (run, lib):
            rev = Reviewer()
            with mock.patch.object(review, "review_concept", rev), Txn(run, hooks=(cand.concept_review,)) as txn:
                txn.apply([cand.Change("concept", CA, concepts[CA], files("concept", CA, "v2"))])
                txn.verify()
                txn.verify()
                self.assertEqual(rev.asked, 1)
                self.assertEqual(len(jsonl.read_strict(txn.area / "rulings.jsonl")), 1)   # recorded once

    def test_a_changed_body_has_its_callers_obligations_certified_again(self):
        concepts, nodes = standard()
        with world(concepts, nodes) as (run, lib):
            base = context_base(run.opts, semantic_inputs(run.opts))
            reading = Reading(run.reading_file)
            for c in (CB,):                                                      # the caller's context, as the run last checked it
                run.accepted_concepts[c]["context"] = integrate.context_version(run, "concept", c, reading, base, semantic=True)
            review.append_ruling(run, {"subject": CB, "key": f"concept:{CB}", "schema": review.CONCEPT_CASE_SCHEMA, "ruling": "upheld",
                                       "obligation": "satisfied", "case_id": "cb-1", "kind": "holds_wrongly", "situation": "s",
                                       "contract_words": "w", "contract_verdict": "fails"})
            calls = []
            confirm = lambda rec, answer, out, dim, rd, saved=False, registry=None: calls.append(rec.id) or ([{"line": "it holds again"}], [], [], [])
            with mock.patch.object(review, "review_concept", Reviewer()), mock.patch.object(review, "execute_concept_divergences", confirm), \
                    Txn(run, hooks=(cand.concept_review,)) as txn:
                txn.apply([cand.Change("concept", CA, concepts[CA], files("concept", CA, "v2"))])
                results = {(r.check, r.subject): r for r in txn.verify()}
                self.assertEqual(calls, [CB])
                self.assertEqual(results[("context", CB)].status, "fail")
                self.assertIn("contradicts its contract again", results[("context", CB)].details[0])
                self.assertNotIn(CB, txn.view.fenced)                               # a candidate fences nothing
                with self.assertRaises(cand.CommitRefused):
                    txn.commit()

    def test_a_certified_context_is_published_and_reused(self):
        concepts, nodes = standard()
        with world(concepts, nodes) as (run, lib):
            with mock.patch.object(review, "review_concept", Reviewer()), Txn(run, hooks=(cand.concept_review,)) as txn:
                txn.apply([cand.Change("concept", CA, concepts[CA], files("concept", CA, "v2"))])
                first = {(r.check, r.subject): r.details[0] for r in txn.verify() if r.check == "context"}
                self.assertEqual(first[("context", CB)], "certified again")
                second = {(r.check, r.subject): r.details[0] for r in txn.verify() if r.check == "context"}
                self.assertEqual(second[("context", CB)], "context unchanged: reused")
                txn.commit()
            self.assertTrue(jsonl.read_json(run.state_file, {})["accepted_concepts"][CB].get("context"))

    def test_an_inherited_callers_certification_survives_the_next_persist(self):
        from harness.store.ledger import ConceptLedger, Ledger, NodeLedger
        from harness.store.state import Run, commit_state
        concepts, nodes = standard()
        with world(concepts, nodes) as (run, lib):
            run.base_concepts[CB] = run.accepted_concepts.pop(CB)          # CB, a caller of CA, is inherited
            snap = run.load_state()
            snap["accepted_concepts"] = run.accepted_concepts
            jsonl.write_atomic(run.state_file, json.dumps(snap))
            with mock.patch.object(review, "review_concept", Reviewer()), Txn(run, hooks=(cand.concept_review,)) as txn:
                txn.apply([cand.Change("concept", CA, concepts[CA], files("concept", CA, "v2"))])
                self.assertTrue(all(r.status == "pass" for r in txn.verify()))
                txn.commit()
            commit_state(run, Ledger(run.ledger_file, [], 2), ConceptLedger(run.concept_ledger_file, 3), NodeLedger(run.node_ledger_file, 2))
            fresh = Run(run.opts)
            fresh.restore_state()
            self.assertIn(CB, fresh.rechecked)


class Reports(Base):
    """A label repair's report that a concept computes what its contract excludes, routed by its ruling."""

    def _repair(self, status: str):
        report = {"node_id": N[5], "withdraw": {"kind": "concept", "missing": "the concept holds where its contract excludes"}}
        dep = review.DependencyReport(status, CA, ["stand-in adjudication"], "divergence 1: it holds")
        return repairing(outputs={"record.jsonl": json.dumps(report), "dependency_defect.json": "{}"}, concepts={CA: concept_rec(CA)},
                         uses={N[5]: [CA]}), dep

    def test_dismissed_and_not_finished_change_nothing(self):
        for status in ("dismissed", "deferred"):
            ctx, dep = self._repair(status)
            with ctx as (run, ledger, training, by_id), mock.patch.object(review, "dependency_report", lambda *a, **k: dep):
                before = (label_repair.paths.LIBRARY / cand.own_files("concept", CA)[0]).read_text()
                self.assertEqual(repair(run, ledger, training, by_id), "dependency_report")
                st = run.label_states[L[5]]
                self.assertEqual(st.get("repairs", 0), 1 if status == "dismissed" else 0)   # a ruling not finished charges nothing
                self.assertEqual(st.get("active", {}).get("stage"), "report" if status == "deferred" else None)
                row = st["reports"][-1]
                self.assertEqual((row["concept"], row["ruling"], row["execution"]),
                                 (CA, "dismissed" if status == "dismissed" else "not finished", dep.execution))
                self.assertTrue(row["contract"] and row["dependencies"])
                self.assertEqual((label_repair.paths.LIBRARY / cand.own_files("concept", CA)[0]).read_text(), before)
                with cand.SCHEDULING.pause():
                    txn = cand.Candidate.open(run, hooks=())
                    try:
                        prompt = label_repair.prompt_for(run, txn, by_id[L[5]], [], label_repair.ontology.load(run.opts.ontology), 0)
                    finally:
                        txn.close("test")
                self.assertIn("## Reports on a concept", prompt)
                self.assertIn(f"`{CA}`", prompt.split("## Reports on a concept")[1])

    def test_upheld_repairs_the_concept_in_the_same_candidate(self):
        ctx, dep = self._repair("upheld")

        def concept_session(run_, rec, reasons, last_task, defs, users):
            d = run_.iter / "repair" / rec.id.replace(".", "_")
            d.mkdir(parents=True, exist_ok=True)
            (d / "record.jsonl").write_text(json.dumps(concept_rec(CA)) + "\n")
            (d / "seen.json").write_text(json.dumps({"reasons": reasons, "library": str(label_repair.paths.LIBRARY)}))
            return d

        def coder(txn, recs, law=None, earlier=None):
            with txn.inside():
                for kind, ident in recs:
                    for rel, text in files(kind, ident, "repaired").items():
                        (txn.library / rel).write_text(text)
            return {}

        with ctx as (run, ledger, training, by_id), mock.patch.object(review, "dependency_report", lambda *a, **k: dep), \
                mock.patch.object(plan, "run_repair", concept_session), mock.patch.object(label_repair, "code_in_candidate", coder), \
                mock.patch.object(review, "review_concept", Reviewer()):
            set_verdict(training, "r5a", N[5], "compliant")
            self.assertEqual(repair(run, ledger, training, by_id), "committed")
            self.assertIn("-- repaired", (label_repair.paths.LIBRARY / cand.own_files("concept", CA)[0]).read_text())
            self.assertEqual(run.label_states[L[5]]["reports"][-1]["ruling"], "upheld")
            self.assertEqual([r["subject"] for r in rows_of(run)], [CA])             # the concept's review, published with the commit
            seen = json.loads(next((run.dir).rglob("seen.json")).read_text())
            self.assertIn("upheld: divergence 1: it holds", seen["reasons"])
            self.assertIn("candidate", seen["library"])                                # the concept's repair ran in the candidate


class UsersBlock(Base):

    def test_the_concept_repair_is_shown_the_concepts_state(self):
        concepts, nodes = standard()
        with world(concepts, nodes) as (run, lib):
            self.assertIn("accepted", plan.concept_state_line(run, CA))
            run.accepted_concepts.pop(CA)
            run.base_concepts = {}
            self.assertIn(cand.DEPENDED_ON, plan.concept_state_line(run, CA))       # CB, accepted, calls it
            self.assertIn(cand.UNBOUND, plan.concept_state_line(run, "drv.motion.cand_none"))


if __name__ == "__main__":
    unittest.main()
