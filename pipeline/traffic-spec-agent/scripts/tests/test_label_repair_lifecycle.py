"""The life of a label repair, at its failure boundaries: each repair has its own session and
directory (a second repair is asked again, a re-ask is read alone, a stopped part is taken up without
a new session); a shared repair routes every law it checks again from its new outcome, an operator's
hold kept, and the law's own new route committed with the candidate; every way out of a repair closes
its candidate; a change of what a record composes is the coder's; a change request is filed once; a
report on a concept whose ruling is not finished, the repair's or a coder's, publishes nothing and is
judged again without a new session or coding, in a later iteration too, while what the repair was
asked on is unchanged; a coder that did not run charges nothing; the next repair is shown what a
rolled-back candidate failed; and a plan session inside a candidate validates against the candidate.

Stand-in sessions write what a session writes, including its completion record; the monitor is the
label check's stand-in; the candidate, the hooks, the ledger and the routing are the real ones."""
import json
import os
import unittest
from pathlib import Path
from unittest import mock

from harness import loop
from harness.agents import session
from harness.phases import candidate as cand
from harness.phases import code as code_phase
from harness.phases import label_repair as lr
from harness.phases import plan, review
from harness.store import jsonl, paths
from harness.store.gaps import GapLedger
from harness.store.ledger import ConceptLedger, Ledger, NodeLedger
from harness.store.state import Run, RUN_VERSION, commit_state
from scripts.tests.test_candidate import Base, concept_rec, files, node_rec
from scripts.tests.test_label_repair import L, N, RECS
from scripts.tests.test_label_repair_session import DIFF5, REQUEST, repair, repairing, set_verdict

CA = "drv.motion.cand_a"


def done(d: Path, label: str) -> None:
    """The completion record a session leaves when it ran to its end."""
    (d / f"{label}_result.json").write_text(json.dumps({"result": {}, "code": 0}))


class Responder:
    """A model session: each call writes what `answers` gives for it, and its completion record."""

    def __init__(self, *answers):
        self.answers, self.calls = list(answers), []

    def __call__(self, prompt, cwd=None, label="session", **_k):
        d = Path(cwd)
        if "label_repair" not in d.parts:
            return
        self.calls.append((d.name, label))
        for name, text in (self.answers[min(len(self.calls), len(self.answers)) - 1] or {}).items():
            (d / name).write_text(text)
        done(d, label)


REC5 = json.dumps({k: v for k, v in node_rec(N[5]).items() if k != "segmentation"})


def run_repairs(run, ledger, training, by_id, to_user=None):
    return lr.run_repairs(run, ledger, training, by_id, [], lr.ontology.load(run.opts.ontology),
                          GapLedger.for_run(lr.paths.GAPS_DIR, run), [], to_user if to_user is not None else [])


def reloaded(run, ledger, iteration: int):
    """The run and its ledger, persisted, as a later process loads them from the committed snapshot."""
    commit_state(run, ledger, ConceptLedger(run.concept_ledger_file, 3), NodeLedger(run.node_ledger_file, 2))
    fresh = Run(run.opts)
    fresh.restore_state()
    fresh.load_accepted()
    fresh.iteration = iteration
    ledger = Ledger(run.ledger_file, list(L.values()), 2)
    ledger.attempt = iteration
    return fresh, ledger


class Sessions(Base):

    def test_each_repair_has_its_own_session(self):
        with repairing() as (run, ledger, training, by_id):
            resp = Responder({"record.jsonl": REC5, "lean.diff": DIFF5}, {"record.jsonl": REC5})
            with mock.patch.object(session, "run", resp):
                set_verdict(training, "r5a", N[5], "compliant")
                first = repair(run, ledger, training, by_id)
                set_verdict(training, "r5b", N[5], "violated")      # the second repair fixes r5b
                second = repair(run, ledger, training, by_id)
            self.assertEqual([c[0] for c in resp.calls], ["repair-01", "repair-02"])     # asked again, in its own directory
            self.assertEqual((first, second), ("committed", "committed"))
            self.assertEqual(run.label_states[L[5]]["repairs"], 2)

    def test_a_reask_is_read_alone(self):
        with repairing() as (run, ledger, training, by_id):
            resp = Responder({"record.jsonl": "not JSON", "lean.diff": DIFF5}, {"change_request.json": json.dumps([REQUEST])})
            with mock.patch.object(session, "run", resp), cand.SCHEDULING.pause():
                with cand.Candidate.open(run, hooks=()) as txn:
                    d, out = lr.run_session(run, txn, by_id[L[5]], [], lr.ontology.load(run.opts.ontology), 0)
            self.assertEqual([c[1] for c in resp.calls], ["session", "session_again"])
            self.assertEqual((out.errors, out.diff, len(out.requests)), ([], "", 1))     # the first answer's diff is not the second's
            self.assertEqual((d / "first" / "lean.diff").read_text(), DIFF5)              # kept whole beside it

    def test_a_part_that_did_not_run_charges_nothing_and_is_taken_up_without_a_new_session(self):
        withdraw = {"node_id": N[5], "withdraw": {"kind": "plan", "missing": "two duties"}}
        with repairing() as (run, ledger, training, by_id):
            resp = Responder({"record.jsonl": json.dumps(withdraw)})
            with mock.patch.object(session, "run", resp), \
                    mock.patch.object(plan, "run_plan", side_effect=session.SessionUnavailable("synthetic API failure")):
                self.assertEqual(repair(run, ledger, training, by_id), "unavailable")
                self.assertNotIn(run.opts.run_id, cand._OPEN)
                statuses = [jsonl.read_json(p, {}).get("status") for p in run.dir.glob("iter-*/candidate/*/status.json")]
                self.assertNotIn("open", statuses)
                self.assertEqual(run.label_states[L[5]].get("repairs", 0), 0)
                self.assertEqual(repair(run, ledger, training, by_id), "unavailable")
            self.assertEqual(len(resp.calls), 1)                     # its answer was taken up again, not asked for again

    def test_a_coder_that_did_not_run_charges_nothing(self):
        rec = json.loads(REC5)
        rec["elements"] = [{"span": "o1", "atoms": ["kin.speed", "rel.occupies"], "derived": []}]
        with repairing(outputs={"record.jsonl": json.dumps(rec)}) as (run, ledger, training, by_id), \
                mock.patch.object(lr, "code_in_candidate", lambda txn, recs, law=None, earlier=None: {i: {"verdict": code_phase.SESSION_FAILED} for _k, i in recs}):
            self.assertEqual(repair(run, ledger, training, by_id), "unavailable")
            self.assertEqual(run.label_states[L[5]].get("repairs", 0), 0)


class Collateral(Base):

    def _scenario(self, lock: bool):
        recs = [(rid, law, label, jc, {N[1]: [["unknown", {"x": 1}]]} if rid == "r1a" else spec) for rid, law, label, jc, spec in RECS]
        return repairing(recs=recs, outputs={"record.jsonl": REC5, "lean.diff": DIFF5})

    def test_another_law_the_repair_reaches_is_routed_from_its_new_check(self):
        with self._scenario(False) as (run, ledger, training, by_id):
            run.accepted_nodes[N[1]]["compositions"] = [{"span": "o1", "rule": N[5], "map": {"v": "v"}, "as": "condition"}]
            self.assertEqual((run.label_states[L[1]]["outcome"], ledger.entries[L[1]].state), ("unverified", "accepted"))
            set_verdict(training, "r5a", N[5], "compliant")
            set_verdict(training, "r1a", N[1], "violated")
            self.assertEqual(repair(run, ledger, training, by_id), "committed")
            st = run.label_states[L[1]]
            self.assertEqual((st["outcome"], st["state"], ledger.entries[L[1]].state), ("mismatch", "awaiting_label_repair", "planned"))
            self.assertIn(L[1], lr.awaiting(run, ledger))
            snap = jsonl.read_json(run.state_file, {})
            self.assertEqual({e["law"]: e["state"] for e in snap["ledger"]}[L[1]], "planned")     # committed with the candidate

    def test_a_committed_repair_ends_its_session_and_another_law_keeps_its_own(self):
        """T34: the commit ends the target's session (no `active` left, `sessions` and `repairs` up by
        exactly one), so its next repair opens a new session; a law checked again by the same
        commit keeps its own active session."""
        with self._scenario(False) as (run, ledger, training, by_id):
            run.accepted_nodes[N[1]]["compositions"] = [{"span": "o1", "rule": N[5], "map": {"v": "v"}, "as": "condition"}]
            run.label_states[L[1]]["active"] = {"dir": "its/own", "input": "k", "stage": "session"}
            before = {k: int(run.label_states[L[5]].get(k, 0)) for k in ("sessions", "repairs")}
            set_verdict(training, "r5a", N[5], "compliant")
            set_verdict(training, "r1a", N[1], "violated")
            self.assertEqual(repair(run, ledger, training, by_id), "committed")
            st = run.label_states[L[5]]
            self.assertNotIn("active", st)
            self.assertEqual({k: int(st.get(k, 0)) for k in ("sessions", "repairs")}, {k: v + 1 for k, v in before.items()})
            self.assertEqual(run.label_states[L[1]]["active"], {"dir": "its/own", "input": "k", "stage": "session"})
            self.assertTrue(str(lr.repair_dir(run, L[5])).endswith(f"repair-{before['sessions'] + 2:02d}"))   # a new session next
            snap = jsonl.read_json(run.state_file, {})
            self.assertNotIn("active", snap["label_states"][L[5]])
            self.assertEqual(snap["label_states"][L[1]]["active"]["dir"], "its/own")

    def test_an_operators_hold_is_kept(self):
        with self._scenario(True) as (run, ledger, training, by_id):
            run.accepted_nodes[N[1]]["compositions"] = [{"span": "o1", "rule": N[5], "map": {"v": "v"}, "as": "condition"}]
            ledger.entries[L[1]].state, ledger.entries[L[1]].gaps = "blocked", [f"decision:{L[1]}"]
            run.label_states[L[1]]["repairs"] = 2
            set_verdict(training, "r5a", N[5], "compliant")
            set_verdict(training, "r1a", N[1], "violated")
            self.assertEqual(repair(run, ledger, training, by_id), "committed")
            self.assertEqual(ledger.entries[L[1]].state, "blocked")
            self.assertEqual((run.label_states[L[1]]["outcome"], run.label_states[L[1]]["repairs"]), ("mismatch", 2))


class Locality(unittest.TestCase):

    def test_a_change_of_what_a_record_composes_is_not_local(self):
        old = node_rec(N[5], compositions=[{"span": "o1", "rule": N[1], "map": {"v": "v"}, "as": "condition"}])
        for comp in ({"span": "o1", "rule": N[2], "map": {"v": "v"}, "as": "condition"},
                     {"span": "o1", "rule": N[1], "map": {"v": "v"}, "as": "exception"},
                     {"span": "o1", "rule": N[1], "map": {"v": "w"}, "as": "condition"}):
            self.assertIn("its compositions changed", lr.not_local("node", old, {**old, "compositions": [comp]}))
        prose = {**old, "compositions": [{**old["compositions"][0], "justification": "reworded"}]}
        self.assertEqual(lr.not_local("node", old, prose), [])


class Requests(Base):

    def test_a_request_is_filed_once(self):
        with repairing(outputs={"change_request.json": json.dumps([REQUEST])}) as (run, ledger, training, by_id):
            self.assertEqual(repair(run, ledger, training, by_id), "requested")
            lr.file_requests(run, L[5], [{**REQUEST, "evidence": "r5b: another derivation"}], [])
            rows = jsonl.read_strict(run.dir / lr.OUTER_FILE)
            self.assertEqual(len(rows), 1)
            self.assertEqual([x["evidence"] for x in rows[0]["seen"]], [REQUEST["evidence"], "r5b: another derivation"])


class PendingReport(Base):

    def test_a_report_without_a_ruling_is_judged_again_without_a_new_session(self):
        report = {"node_id": N[5], "withdraw": {"kind": "concept", "missing": "it holds where its contract excludes"}}
        resp = Responder({"record.jsonl": json.dumps(report), "dependency_defect.json": "{}"})
        judged = []

        def judge(*a, **k):
            judged.append(1)
            return review.DependencyReport("deferred", CA, ["the adjudicator's answer stayed invalid"])
        with repairing(concepts={CA: concept_rec(CA)}, uses={N[5]: [CA]}) as (run, ledger, training, by_id), \
                mock.patch.object(session, "run", resp), mock.patch.object(review, "dependency_report", judge):
            for it in (1, 2):
                run.iteration = it
                run_repairs(run, ledger, training, by_id)
            self.assertEqual((len(resp.calls), len(judged)), (1, 2))
            self.assertEqual(lr.used(run), 0)
            active = run.label_states[L[5]]["active"]
            self.assertEqual((active["stage"], active["dir"]), ("report", f"iter-001/label_repair/{L[5]}/repair-01"))
            self.assertTrue((run.dir / active["dir"] / "dependency_defect.json").is_file())

    def test_an_unfinished_repair_is_taken_up_in_a_later_iteration_from_the_snapshot(self):
        report = {"node_id": N[5], "withdraw": {"kind": "concept", "missing": "it holds where its contract excludes"}}
        resp = Responder({"record.jsonl": json.dumps(report), "dependency_defect.json": "{}"})
        judged = []

        def judge(*a, **k):
            judged.append(1)
            return review.DependencyReport("deferred", CA, ["the adjudicator's answer stayed invalid"])
        with repairing(concepts={CA: concept_rec(CA)}, uses={N[5]: [CA]}) as (run, ledger, training, by_id), \
                mock.patch.object(session, "run", resp), mock.patch.object(review, "dependency_report", judge):
            run_repairs(run, ledger, training, by_id)
            fresh, ledger2 = reloaded(run, ledger, 2)
            self.assertEqual(run_repairs(fresh, ledger2, training, by_id), {L[5]: ["dependency_report"]})
            self.assertEqual((len(resp.calls), len(judged), lr.used(fresh)), (1, 2, 0))
            self.assertEqual(fresh.label_states[L[5]]["active"]["dir"], f"iter-001/label_repair/{L[5]}/repair-01")
            st = fresh.label_states[L[5]]
            self.assertEqual((len(st["reports"]), len(st["report_history"])), (1, 2))   # one current report, both judgments kept
        withdraw = {"node_id": N[5], "withdraw": {"kind": "plan", "missing": "two duties"}}
        resp = Responder({"record.jsonl": json.dumps(withdraw)})
        with repairing() as (run, ledger, training, by_id), mock.patch.object(session, "run", resp), \
                mock.patch.object(plan, "run_plan", side_effect=session.SessionUnavailable("planner unavailable")):
            run_repairs(run, ledger, training, by_id)
            fresh, ledger2 = reloaded(run, ledger, 2)
            self.assertEqual(run_repairs(fresh, ledger2, training, by_id), {L[5]: ["unavailable"]})
            self.assertEqual((len(resp.calls), lr.used(fresh)), (1, 0))

    def test_an_unfinished_repair_asked_on_what_a_commit_changed_is_asked_again(self):
        report = {"node_id": N[5], "withdraw": {"kind": "concept", "missing": "it holds where its contract excludes"}}
        resp = Responder({"record.jsonl": json.dumps(report), "dependency_defect.json": "{}"})
        deferred = review.DependencyReport("deferred", CA, ["the adjudicator's answer stayed invalid"])
        with repairing(concepts={CA: concept_rec(CA)}, uses={N[5]: [CA]}) as (run, ledger, training, by_id), \
                mock.patch.object(session, "run", resp), mock.patch.object(review, "dependency_report", lambda *a, **k: deferred):
            run_repairs(run, ledger, training, by_id)
            rule = paths.LIBRARY / cand.own_files("node", N[5])[0]
            rule.write_text(rule.read_text() + "-- another commit\n")           # the Lean the repair was shown changed
            fresh, ledger2 = reloaded(run, ledger, 2)
            to_user = []
            run_repairs(fresh, ledger2, training, by_id, to_user)
            self.assertEqual([c[0] for c in resp.calls], ["repair-01", "repair-02"])
            self.assertEqual(fresh.label_states[L[5]]["active"]["dir"], f"iter-002/label_repair/{L[5]}/repair-02")
            self.assertTrue(any("its answer is not taken up" in x for x in to_user))
            self.assertEqual(lr.used(fresh), 0)

    def test_a_concept_withdrawal_without_its_report_is_refused(self):
        report = {"node_id": N[5], "withdraw": {"kind": "concept", "missing": "it holds where its contract excludes"}}
        out = lr.Output()
        import tempfile
        with tempfile.TemporaryDirectory() as t:
            (Path(t) / "record.jsonl").write_text(json.dumps(report))
            out = lr.read_output(Path(t), {N[5]: node_rec(N[5])})
        self.assertIn("comes with its `dependency_defect.json`", out.errors[0])


class ReportIdentity(unittest.TestCase):
    """The law's current reports hold one row per report; every judgment stays in its history."""

    def test_a_report_judged_again_replaces_its_row_and_another_counterexample_keeps_its_own(self):
        import contextlib
        import tempfile
        from types import SimpleNamespace
        run = SimpleNamespace(label_states={L[5]: {"active": {"dir": "iter-001/label_repair/x/repair-01"}}})
        deferred = review.DependencyReport("deferred", CA, ["no ruling yet"])
        with tempfile.TemporaryDirectory() as t:
            def judged(candidate, content, rep=deferred):
                task = Path(t) / candidate / "task"
                task.mkdir(parents=True, exist_ok=True)
                (task / "dependency_defect.json").write_text(json.dumps(content))
                txn = SimpleNamespace(view=SimpleNamespace(all_concepts=lambda: {}), run=run, id=candidate, inside=contextlib.nullcontext)
                lr.record_report(txn, L[5], rep, task)
            judged("cand-1", {"concept_id": CA, "at": 0})
            judged("cand-2", {"concept_id": CA, "at": 0})                        # the same report, in a later candidate
            judged("cand-2", {"concept_id": CA, "at": 100})                      # another counterexample on the same concept
            judged("cand-3", {"concept_id": CA, "at": 0}, review.DependencyReport("dismissed", CA, ["kept"]))
        st = run.label_states[L[5]]
        self.assertEqual([(r["candidate"], r["ruling"]) for r in st["reports"]], [("cand-3", "dismissed"), ("cand-2", "not finished")])
        self.assertEqual(len(st["report_history"]), 4)


class ExecutionStage(Base):
    """What a report's row says of its execution is the stage the judging reached, its ruling apart."""

    def test_an_execution_that_confirmed_is_kept_when_the_ruling_is_deferred(self):
        stops = {"adjudication": (lambda *a, **k: ([{"confirmed": True}], [], [], []), review.Deferred("adjudicate", "no ruling"), "confirmed"),
                 "execution": (mock.Mock(side_effect=review.HarnessFailure("the certificate program did not run")), None, "unknown")}
        for name, (execute, adjudicate, execution) in stops.items():
            with self.subTest(stop=name), repairing(concepts={CA: concept_rec(CA)}, uses={N[5]: [CA]}) as (run, ledger, training, by_id):
                run.label_states[L[5]]["active"] = {"dir": "iter-001/label_repair/x/repair-01"}
                with cand.SCHEDULING.pause(), cand.Candidate.open(run, hooks=()) as txn:
                    task = txn.area / "execution_probe"
                    task.mkdir()
                    (task / "dependency_defect.json").write_text("{}")
                    with txn.inside(), \
                            mock.patch.object(review, "report_form", return_value=({"concept_id": CA}, [])), \
                            mock.patch.object(review, "_registry", return_value={}), \
                            mock.patch.object(review, "execute_concept_divergences", execute), \
                            mock.patch.object(review, "concept_blocks", return_value=({}, None, None)), \
                            mock.patch.object(review, "resume_review", return_value=({}, None)), \
                            mock.patch.object(review, "adjudicate_concept", side_effect=adjudicate):
                        rep = loop.report_of(txn.view, task, {CA})
                    lr.record_report(txn, L[5], rep, task)
                    row = run.label_states[L[5]]["reports"][-1]
                    self.assertEqual((row["concept"], row["status"] in review.NOT_JUDGED, row["execution"], row["ruling"]),
                                     (CA, True, execution, "not finished"))
                    self.assertTrue(row["contract"] and row["body"])


class UndecidedCoderReport(Base):
    """A coder in the repair's candidate reports a concept defect the adjudication does not decide."""

    def test_it_publishes_nothing_and_is_taken_up_without_coding_again(self):
        rec = json.loads(REC5)
        rec["elements"] = [{"span": "o1", "atoms": ["kin.speed", "rel.occupies"], "derived": [CA]}]
        for status in ("deferred", "unavailable"):
            coded = []

            def sessions(prompt, cwd=None, label="session", **_k):
                d = Path(cwd)
                if "label_repair" in d.parts:
                    (d / "record.jsonl").write_text(json.dumps(rec))
                    done(d, label)
                    return
                coded.append(d.name)                    # the coder: a new body, which the stand-in gate passes
                for rel, text in files("node", N[5], "new coder body").items():
                    (paths.LIBRARY / rel).write_text(text)
            rulings = iter([review.DependencyReport(status, CA, ["the adjudication did not decide"]),
                            review.DependencyReport("dismissed", CA, ["the concept keeps its contract"])])
            with repairing(concepts={CA: concept_rec(CA)}, uses={N[5]: [CA]}) as (run, ledger, training, by_id), \
                    mock.patch.object(session, "run", sessions), mock.patch.object(review, "dependency_report", lambda *a, **k: next(rulings)):
                set_verdict(training, "r5a", N[5], "compliant")                 # the coder's body improves the labels
                rule = paths.LIBRARY / cand.own_files("node", N[5])[0]
                before = (rule.read_text(), (run.dir / "rulings.jsonl").read_bytes() if (run.dir / "rulings.jsonl").exists() else None,
                          run.state_file.read_bytes(), ledger.entries[L[5]].state)
                self.assertEqual(repair(run, ledger, training, by_id), "dependency_report", status)
                self.assertEqual((rule.read_text(), (run.dir / "rulings.jsonl").read_bytes() if (run.dir / "rulings.jsonl").exists() else None,
                                  run.state_file.read_bytes(), ledger.entries[L[5]].state), before, status)
                st = run.label_states[L[5]]
                self.assertEqual((st.get("repairs", 0), st["reports"][-1]["ruling"], st["active"]["stage"]), (0, "not finished", "coding"), status)
                self.assertEqual(repair(run, ledger, training, by_id), "committed", status)     # its ruling given, the same repair goes on
                self.assertEqual(coded, [N[5]], status)                                       # the coder's answer taken up, not asked again
                self.assertIn("new coder body", rule.read_text())
                self.assertEqual(run.label_states[L[5]]["repairs"], 1)


class Feedback(Base):

    def test_the_next_repair_is_shown_what_the_rolled_back_candidate_failed(self):
        marker = "UNIQUE-CONCEPT-REJECTION-CAUSE"
        cp = cand.own_files("concept", CA)[0]
        diff = f"--- {cp}\n+++ {cp}\n@@ -3 +3 @@\n--- v1\n+-- v2\n"
        resp = Responder({"lean.diff": diff}, {"change_request.json": json.dumps([REQUEST])})
        with repairing(concepts={CA: concept_rec(CA)}, uses={N[5]: [CA]}) as (run, ledger, training, by_id), \
                mock.patch.object(session, "run", resp), \
                mock.patch.object(review, "review_concept", lambda *a, **k: review.ReviewOutcome("returned", reasons=[marker])):
            set_verdict(training, "r5a", N[5], "compliant")
            self.assertEqual(repair(run, ledger, training, by_id), "rolled_back")
            repair(run, ledger, training, by_id)
            second = (run.dir / f"iter-001/label_repair/{L[5]}/repair-02/prompt.md").read_text()
            state = second.split("## The law's state", 1)[1].split("## Label mismatches", 1)[0]
            self.assertIn(marker, state)
            self.assertIn(f"concept_review `{CA}`: fail", state)
            self.assertIn("not rulings on the accepted library", state)
            first = (run.dir / f"iter-001/label_repair/{L[5]}/repair-01/prompt.md").read_text()
            self.assertNotIn("previous label repair", first)


class Stop(BaseException):
    """A process stopped between a commit and the loop's next persist."""


class CommittedRoute(Base):

    def test_a_stop_after_the_commit_leaves_the_law_routed(self):
        real = cand.Candidate.commit

        def commit_then_stop(txn, *a, **k):
            real(txn, *a, **k)
            raise Stop()
        with repairing(outputs={"record.jsonl": REC5, "lean.diff": DIFF5}) as (run, ledger, training, by_id), \
                mock.patch.object(cand.Candidate, "commit", commit_then_stop):
            set_verdict(training, "r5a", N[5], "compliant")
            set_verdict(training, "r5b", N[5], "violated")
            with self.assertRaises(Stop):
                repair(run, ledger, training, by_id)
            fresh = Run(run.opts)
            fresh.restore_state()
            fresh.load_accepted()
            saved = Ledger(run.ledger_file, list(L.values()), 2)
            self.assertEqual((fresh.label_states[L[5]]["outcome"], fresh.label_states[L[5]]["state"], saved.entries[L[5]].state),
                             ("aligned", "accepted", "accepted"))
            self.assertNotIn(L[5], loop.label_ready(fresh, saved))             # nothing to score again


class CandidateValidator(Base):

    def test_a_plan_session_in_a_candidate_validates_against_it(self):
        from harness.__main__ import _candidate_view
        with repairing() as (run, ledger, training, by_id):
            import dataclasses
            (run.dir / "options.json").write_text(json.dumps({**dataclasses.asdict(run.opts), "semantic": {"run_version": RUN_VERSION}},
                                                             default=str))
            with cand.SCHEDULING.pause(), cand.Candidate.open(run, hooks=()) as txn:
                txn.apply([cand.Change("node", N[1], None)])
                txn.write_scope()
                keep = {k: getattr(paths, k) for k in paths.library_layout(paths.LIBRARY)}
                with mock.patch.dict(os.environ, {cand.CANDIDATE_ENV: str(txn.area)}), mock.patch.multiple(paths, **keep):
                    from harness.store.state import Run
                    view = _candidate_view(Run.load(run.opts.run_id))
                    self.assertEqual(paths.LIBRARY, txn.library)
                self.assertNotIn(N[1], view.all_nodes())
                self.assertIn(N[1], run.all_nodes())
                self.assertEqual(view.reading_file, txn.area / "reading.json")


if __name__ == "__main__":
    unittest.main()
