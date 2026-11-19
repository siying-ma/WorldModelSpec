"""The operator's decisions on the behaviour review's deterministic part, with the scripted reviewer
(no model, no solver):

- the run-wide send gate in the usage file and `review_decide acknowledge`: one persisted stop
  confirmed at a time, bound to its record, idempotent, refused while a call's outcome is unknown or
  kept evidence is lost, changing nothing else, followed by the launch checks;
- the exemption of a law without checkable behaviour in two layers: a classification basis on the
  words, reused when only the rules change, and a current credential on the rules, made again on the
  library in force; never for a review's own limit or failure;
- a reached exemption carries no review condition, is listed per reader, and invalidates the reader
  when it no longer holds;
- a finding is repaired before the labels, with the label results as context only, and a shown
  conflict between the two goes to the operator at once;
- the Core digest names Core's files by their fixed logical names, so every copy of one Core keys alike."""
import hashlib
import json
import shutil
import tempfile
import threading
import time
from dataclasses import replace
from pathlib import Path
from unittest import mock

from harness import loop
from harness.__main__ import Cli
from harness.model import nodeid
from harness.phases import behaviour_review as br
from harness.phases import candidate as cand
from harness.phases import label_repair
from harness.store import budget, jsonl, paths
from harness.store.budget import AcknowledgeRefused, BudgetPaused, RunStopped
from harness.tools import handoff
from scripts.tests import fake_reviewer
from scripts.tests.fake_reviewer import cell, prop, pset
from scripts.tests.test_behaviour_review_stage import (CODE, COMPOSES_5, both, finds, fix5, labelled, label_repair_of, live_rows,
                                                       on_mark, persist_of, reload, review, rworld, script, stage)
from scripts.tests.test_candidate import Base, files, node_rec
from scripts.tests.test_label_repair import L, N
from scripts.tests.test_label_repair_session import set_verdict


def usage(run) -> Path:
    return run.dir / "usage.jsonl"


def usage_bytes(run) -> bytes:
    return usage(run).read_bytes() if usage(run).exists() else b""


def record(tmp: Path, run, stop_id: str, **over) -> Path:
    f = tmp / f"ack-{stop_id}-{len(list(tmp.iterdir()))}.json"
    f.write_text(json.dumps({"run_id": run.opts.run_id, "stop": stop_id, "decision": "acknowledge",
                             "reason": "the run's reviewer configuration and the call's spend were checked", **over}))
    return f


def a_budget(run, **limits) -> budget.Budget:
    """Another holder of the run's budget (another process's, as far as the run's lock is concerned)."""
    return budget.Budget(usage(run), limits.get("openai"), {"m": {"input_usd_per_million": 1.0, "cached_input_usd_per_million": 0.0,
                                                                  "output_usd_per_million": 1.0}},
                         claude_limit_usd=limits.get("claude"), total_limit_usd=limits.get("total"))


def zero(tag: str, **z) -> dict:
    """A set that adopted nothing, classified as a law without checkable behaviour by the screen."""
    return {**pset(tag=tag), "zero_adopted": {"codes": ["no_checkable_behaviour"], "screen_confirms": True,
                                              "basis": "the law states a purpose only", **z}}


def no_behaviour(fake, run, ledger, law, persist, tag="nb"):
    """Make `law` a law without checkable behaviour: two asks that adopt nothing."""
    run.review_states.pop(law, None)
    persist()
    script(fake, law, zero(tag + "1"), zero(tag + "2"))
    assert review(run, ledger, law, persist) == "no_properties"
    assert review(run, ledger, law, persist) == br.NO_BEHAVIOUR, br.own_status(run, ledger, law)


class Gate(Base):
    """The send gate is the usage file's, under the run's lock, for every role."""

    def test_a_wrong_model_stops_every_role_until_acknowledged(self):
        with rworld(kind="review") as (run, ledger, fake, persist):
            script(fake, L[1], br.WrongChannel("answered by another model", "wrong_model"))
            self.assertEqual(review(run, ledger, L[1], persist), "stopped")
            stops = br.run_stops(run)
            self.assertEqual([(s["reason"], s["law"]) for s in stops], [("wrong_model", L[1])])
            st = run.review_states[L[1]]
            self.assertEqual((st.get("pending_call"), st["property_asks"], st["unusable_calls"][0]["stop"]), (None, 0, stops[0]["stop"]))
            b = a_budget(run)
            for label in ("iter-001/plan/batch:L1", "iter-001/code/node:L1", "/aggregates/verify_x:L1", "/review/bp_A:L1"):
                with self.subTest(role=label), self.assertRaisesRegex(RunStopped, stops[0]["stop"]):
                    b.reserve_session("m", 1.0, label)
            with self.assertRaises(RunStopped):
                b.reserve("m", 30, 10, "/review/bp_B:L1")
            self.assertTrue(issubclass(RunStopped, budget.RunPaused))         # the run pauses, as at a spent limit,
            self.assertFalse(issubclass(RunStopped, BudgetPaused))           # and is never reported as one
            self.assertEqual(budget.fold(jsonl.read_strict(usage(run)))[0], {"openai": 0.0, "anthropic": 0.0})   # a stop is no spend

    def test_a_settlement_and_its_stop_are_one_step_for_every_other_holder(self):
        with rworld(kind="review") as (run, ledger, fake, persist):
            mine, other = a_budget(run), a_budget(run)
            token = mine.reserve_session("m", 1.0, "/review/bp_A:L1")
            real = jsonl.append_atomic
            wrote, seen = threading.Event(), {}

            def slow(path, row):
                real(path, row)
                if row.get("state") == "settled":
                    wrote.set()
                    time.sleep(0.4)                                     # the stop row comes after, inside the same hold

            def reserve_meanwhile():
                wrote.wait(5)
                try:
                    other.reserve_session("m", 1.0, "iter-001/plan/batch:L1")
                    seen["got"] = "reserved"
                except RunStopped:
                    seen["got"] = "stopped"
            t = threading.Thread(target=reserve_meanwhile)
            t.start()
            with mock.patch.object(budget.jsonl, "append_atomic", slow):
                mine.settle(token, budget.usage_row("/review/bp_A:L1", "anthropic", "m", None, {}, 0.5),
                            stop=budget.stop_row("wrong_channel", "the session ran on another channel", law=L[1]))
            t.join(5)
            self.assertEqual(seen.get("got"), "stopped")
            rows = jsonl.read_strict(usage(run))
            self.assertEqual([r["state"] for r in rows], ["pending", "settled", "stop"])


class Acknowledge(Base):
    """`review_decide acknowledge` confirms one persisted stop, and nothing else."""

    def setUp(self):
        super().setUp()
        self.tmp = Path(tempfile.mkdtemp())
        self.addCleanup(shutil.rmtree, self.tmp)
        p = mock.patch.object(handoff, "code_digest", lambda: CODE["code"])
        p.start()
        self.addCleanup(p.stop)

    def stopped(self, run, ledger, fake, persist, law=L[1]):
        """A property call of `law` answered by another model (its answer kept in the call's directory)."""
        script(fake, law, both())
        real = fake.properties

        def answered_elsewhere(run_, law_, workdir):
            fake.properties = real
            fake.property_calls.append((law_,))
            Path(workdir).mkdir(parents=True, exist_ok=True)
            (Path(workdir) / "response.json").write_text(json.dumps({"model": "another-model"}))
            raise br.WrongChannel("answered by another model", "wrong_model")
        fake.properties = answered_elsewhere
        self.assertEqual(review(run, ledger, law, persist), "stopped")
        return br.run_stops(run)[-1]["stop"]

    def test_the_record_binds_the_run_the_stop_and_the_decision(self):
        with rworld(kind="review") as (run, ledger, fake, persist):
            sid = self.stopped(run, ledger, fake, persist)
            before = usage_bytes(run)
            for over in ({"run_id": "another"}, {"stop": "stop-other"}, {"decision": "redraft"}, {"reason": ""}):
                with self.subTest(over), self.assertRaisesRegex(AcknowledgeRefused, "does not bind"):
                    br.acknowledge(run, sid, record(self.tmp, run, sid, **over))
            with self.assertRaisesRegex(AcknowledgeRefused, "holds no stop"):
                br.acknowledge(run, "stop-nonesuch", record(self.tmp, run, "stop-nonesuch"))
            bad = self.tmp / "bad.json"; bad.write_text("[1]")
            with self.assertRaisesRegex(ValueError, "not a JSON object"):
                br.acknowledge(run, sid, bad)
            self.assertEqual(usage_bytes(run), before)                       # nothing written

    def test_idempotent_on_its_record_and_refused_on_another(self):
        with rworld(kind="review") as (run, ledger, fake, persist):
            sid = self.stopped(run, ledger, fake, persist)
            rec = record(self.tmp, run, sid)
            first = br.acknowledge(run, sid, rec)
            self.assertEqual((first["again"], first["open"]), (False, []))
            after = usage_bytes(run)
            again = br.acknowledge(run, sid, rec)
            self.assertTrue(again["again"])
            self.assertEqual(usage_bytes(run), after)                        # the same record changes nothing
            with self.assertRaisesRegex(AcknowledgeRefused, "another record"):
                br.acknowledge(run, sid, record(self.tmp, run, sid, reason="a different account of it"))
            self.assertEqual(usage_bytes(run), after)
            rows = jsonl.read_strict(usage(run))
            self.assertEqual([r["state"] for r in rows if r.get("stop") == sid], ["stop", "acknowledged"])   # the stop is kept

    def test_an_unknown_outcome_is_reconciled_first(self):
        with rworld(kind="review") as (run, ledger, fake, persist):
            sid = self.stopped(run, ledger, fake, persist)
            run.review_states[L[2]] = {"pending_call": {"spec_key": "k", "workdir": "review/x/calls/call-01"}, "property_asks": 1}
            persist()
            before = usage_bytes(run)
            with self.assertRaisesRegex(AcknowledgeRefused, "reconcile first"):
                br.acknowledge(run, sid, record(self.tmp, run, sid))
            self.assertEqual((usage_bytes(run), run.review_states[L[2]]["property_asks"]), (before, 1))   # nothing released or known
            jsonl.append_atomic(usage(run), {"request": "q1", "state": "pending", "label": "/review/bp_A:L1", "vendor": "anthropic",
                                             "model": "m", "reserved_usd": 1.0})
            self.assertEqual(br.reconcile(run, L[2], executed=False), "not_executed")
            persist()
            with self.assertRaisesRegex(AcknowledgeRefused, r"request q1 .*no known outcome"):
                br.acknowledge(run, sid, record(self.tmp, run, sid))
            jsonl.append_atomic(usage(run), {"request": "q1", "state": "settled", "label": "/review/bp_A:L1", "vendor": "anthropic",
                                             "cost_usd": 0.4})
            self.assertFalse(br.acknowledge(run, sid, record(self.tmp, run, sid))["again"])

    def test_one_stop_at_a_time_and_nothing_else_changes(self):
        with rworld(kind="review") as (run, ledger, fake, persist):
            first = self.stopped(run, ledger, fake, persist, L[1])
            second = br.stop_run(run, L[2], "a cost beyond its reservation", "bound_violated")["stop"]
            st_before = json.dumps(run.review_states, sort_keys=True)
            spend = budget.fold(jsonl.read_strict(usage(run)))[0]
            cfg = br.config(run)
            out = br.acknowledge(run, first, record(self.tmp, run, first))
            self.assertEqual(out["open"], [second])
            self.assertTrue(any(second in c for c in out["checks"]))         # the other stop is reported, and still stops
            with self.assertRaisesRegex(RunStopped, second):
                a_budget(run).reserve_session("m", 1.0, "iter-001/plan/batch:L1")
            self.assertEqual(review(run, ledger, L[1], persist), "stopped")
            self.assertEqual((json.dumps(run.review_states, sort_keys=True), budget.fold(jsonl.read_strict(usage(run)))[0], br.config(run)),
                             (st_before, spend, cfg))                        # no count, spend, limit, model or reviewer changed
            br.acknowledge(run, second, record(self.tmp, run, second))
            a_budget(run).reserve_session("m", 1.0, "iter-001/plan/batch:L1")
            unusable = run.review_states[L[1]]["unusable_calls"][0]
            self.assertEqual(review(run, ledger, L[1], persist), "reviewed")  # a new logical call, never the stopped one again
            self.assertEqual((len(fake.property_calls), run.review_states[L[1]]["calls_made"]), (2, 2))
            self.assertEqual(br.kept_files(run.dir / unusable["workdir"]), unusable["kept"])   # its answer kept, settled, unused
            self.assertTrue(unusable["kept"])

    def test_a_wrong_model_answer_is_never_adopted_by_a_reconcile(self):
        with rworld(kind="review") as (run, ledger, fake, persist):
            script(fake, L[1], br.ReviewerUnavailable("timed out after sending", executed=None))
            review(run, ledger, L[1], persist)
            pending = run.review_states[L[1]]["pending_call"]
            br.stop_run(run, L[1], "its answer reports another model", "wrong_model", call=pending["workdir"])
            with self.assertRaisesRegex(ValueError, "never adopted"):
                br.reconcile(run, L[1], executed=True, answer=both())

    def test_a_lost_answer_needs_a_real_recovery(self):
        with rworld(kind="review") as (run, ledger, fake, persist):
            sid = self.stopped(run, ledger, fake, persist)
            kept = run.dir / run.review_states[L[1]]["unusable_calls"][0]["workdir"] / "response.json"
            saved = kept.read_bytes()
            kept.unlink()
            with self.assertRaisesRegex(AcknowledgeRefused, "real recovery"):
                br.acknowledge(run, sid, record(self.tmp, run, sid))
            kept.write_bytes(saved)
            br.acknowledge(run, sid, record(self.tmp, run, sid))
        with rworld(kind="review") as (run, ledger, fake, persist):
            f = run.dir / "review" / "answer.json"; f.parent.mkdir(parents=True, exist_ok=True); f.write_text("{}")
            sha = hashlib.sha256(b"{}").hexdigest()
            f.write_text("{\"changed\": 1}")
            sid = br.stop_run(run, L[1], "its kept answer does not match its digest", "response_missing",
                              response="review/answer.json", response_sha=sha)["stop"]
            with self.assertRaisesRegex(AcknowledgeRefused, "not the one recorded"):
                br.acknowledge(run, sid, record(self.tmp, run, sid))
            f.write_text("{}")
            self.assertEqual(br.acknowledge(run, sid, record(self.tmp, run, sid))["checks"], [])

    def test_the_launch_checks_run_again_and_a_spent_limit_stays_spent(self):
        with rworld(kind="review") as (run, ledger, fake, persist):
            sid = self.stopped(run, ledger, fake, persist)
            jsonl.append_atomic(usage(run), {"label": "iter-001/plan/batch:L1", "vendor": "anthropic", "state": "settled", "cost_usd": 5.0})
            run.opts = replace(run.opts, total_budget_usd=5.0)
            fake_reviewer.install("fake-v2")                                 # another implementation than the run fixed
            out = br.acknowledge(run, sid, record(self.tmp, run, sid))
            self.assertTrue(any("raises no limit" in c for c in out["checks"]), out["checks"])
            self.assertTrue(any(c.startswith("reviewer:") and "another implementation" in c for c in out["checks"]))
            with self.assertRaises(BudgetPaused) as e:
                a_budget(run, total=5.0).reserve_session("m", 1.0, "iter-001/plan/batch:L1")
            self.assertNotIsInstance(e.exception, RunStopped)               # the stop is confirmed; the limit is not raised

    def test_the_acknowledgement_reports_every_other_stop_still_active(self):
        with rworld(kind="review") as (run, ledger, fake, persist):
            sid = self.stopped(run, ledger, fake, persist)
            pauses = run.dir / "shared_failure_pauses.jsonl"
            jsonl.append_atomic(pauses, {"iteration": 1, "signatures": ["<node>: a check failed"], "occurrences": {}, "spent_usd": {}})
            before = pauses.read_bytes()
            out = br.acknowledge(run, sid, record(self.tmp, run, sid))
            self.assertEqual(out["open"], [])                                # its own stop is confirmed
            self.assertTrue(any(c.startswith("stop `defect-1` (paused_defect) is still active") for c in out["checks"]), out["checks"])
            self.assertEqual(pauses.read_bytes(), before)                    # the pause is not answered by it

    def test_a_transition_waits_for_the_acknowledgement(self):
        with rworld(kind="review") as (run, ledger, fake, persist):
            sid = self.stopped(run, ledger, fake, persist)
            self.assertTrue(any(sid in x for x in br.transition_refusals({}, run.dir)))
            br.acknowledge(run, sid, record(self.tmp, run, sid))
            self.assertEqual(br.transition_refusals({}, run.dir), [])

    def test_the_command_refuses_what_it_does_not_decide(self):
        self.assertEqual(Cli().review_decide("r", "-", "limits", stop="s", record="f"), 1)
        self.assertEqual(Cli().review_decide("r", "L-1", "acknowledge", stop="s", record="f"), 1)
        self.assertEqual(Cli().review_decide("r", "-", "acknowledge", stop="", record="f"), 1)


class NoBehaviour(Base):
    """A classification basis on the words; a current credential on the rules."""

    def test_T55_basis_unchanged_credential_key_changed_labels_and_reader_rechecked(self):
        with labelled() as (run, ledger, training, by_id, fake, persist):
            run.accepted_nodes[N[1]]["compositions"] = COMPOSES_5                # L-1 reads L-5's rule
            persist()
            self.assertEqual(review(run, ledger, L[1], persist), "reviewed")
            no_behaviour(fake, run, ledger, L[5], persist)
            st = run.review_states[L[5]]
            basis, cred = dict(st["basis"]), dict(st["certificate"])
            calls = len(fake.property_calls)
            reader_checks = sum(1 for c in fake.check_calls if c[0] == L[1])
            label_before = dict(run.label_states[L[5]])
            set_verdict(training, "r5a", N[5], "compliant"); set_verdict(training, "r5b", N[5], "violated")
            self.assertEqual(label_repair_of(run, ledger, training, by_id), "committed")     # the rule changes (v1 → v2)
            st = run.review_states[L[5]]
            self.assertEqual(st["basis"], basis)                                   # the classification is reused as it is
            self.assertNotEqual(st["certificate"]["check_key"], cred["check_key"])  # the credential is the candidate's
            self.assertIn("candidate", st["certificate"]["where"])
            row = live_rows(run)[st["certificate"]["row"]]
            self.assertEqual((row["kind"], row["disposition"], row["coverage"]), ("exempt", br.NO_BEHAVIOUR,
                                                                                  {"adopted": 0, "executed": 0, "passed": 0}))
            self.assertEqual(len(fake.property_calls), calls)                     # no new property call
            self.assertNotEqual(run.label_states[L[5]]["candidate"], label_before["candidate"])   # its labels checked again
            self.assertEqual(ledger.entries[L[5]].state, "accepted")              # routed with the credential, in one commit
            self.assertEqual(sum(1 for c in fake.check_calls if c[0] == L[1]), reader_checks + 1)   # the reader checked again on it
            r1 = br.own_status(run, ledger, L[1])
            self.assertTrue(r1["ok"])
            self.assertIn("candidate", r1["row"]["where"])
            self.assertEqual([d["law"] for d in br.status(run, ledger, L[1])["exemption_dependencies"]], [L[5]])

    def test_a_rule_change_outside_a_candidate_asks_nothing_again(self):
        with rworld(kind="review") as (run, ledger, fake, persist):
            no_behaviour(fake, run, ledger, L[1], persist)
            basis, key = run.review_states[L[1]]["basis"], run.review_states[L[1]]["certificate"]["check_key"]
            rel = nodeid.rule_path(N[1])
            (paths.LIBRARY / rel).write_text(files("node", N[1], "v2")[rel])
            s = br.own_status(run, ledger, L[1])
            self.assertEqual(s["class"], "stale")
            self.assertIn("what the check depends on changed", s["why"])          # the rules, not the basis
            self.assertEqual(review(run, ledger, L[1], persist), br.NO_BEHAVIOUR)
            self.assertEqual(len(fake.property_calls), 2)
            st = run.review_states[L[1]]
            self.assertEqual(st["basis"], basis)
            self.assertNotEqual(st["certificate"]["check_key"], key)
            self.assertTrue(br.status(run, ledger, L[1])["ok"])
            self.assertEqual(sum(1 for r in live_rows(run).values() if r["kind"] == "basis"), 1)

    def test_the_words_or_the_property_spec_changed_invalidate_the_basis(self):
        with rworld(kind="review") as (run, ledger, fake, persist):
            no_behaviour(fake, run, ledger, L[1], persist)
            laws = Path(run.opts.laws)
            text = laws.read_text()
            laws.write_text(text.replace("shall proceed slowly", "shall proceed slowly and stop", 1))
            s = br.own_status(run, ledger, L[1])
            self.assertEqual(s["class"], "stale")
            self.assertIn("classification basis no longer holds", s["why"])
            self.assertIn(L[1], br.work(run, ledger)["review"])
            self.assertEqual(review(run, ledger, L[1], persist), "held")              # the old answers are not reused: a new ask
            self.assertEqual(len(fake.property_calls), 2)                              # is needed, and none is left
            self.assertFalse(br.status(run, ledger, L[1])["ok"])
            laws.write_text(text)
            self.assertTrue(br.status(run, ledger, L[1])["ok"])                        # the words restored: the basis holds again
        with rworld(kind="review") as (run, ledger, fake, persist):
            no_behaviour(fake, run, ledger, L[1], persist)
            with mock.patch.object(fake_reviewer.Fake, "spec_key", lambda self, run, law: "another-spec"):
                s = br.own_status(run, ledger, L[1])
            self.assertEqual((s["class"], "classification basis" in s["why"]), ("stale", True))

    def test_never_for_a_limit_or_failure_of_the_review(self):
        cases = {"time it cannot express": zero("t", causes=["unsupported_time"]),
                 "an atom missing": zero("a", causes=["missing_atom"]),
                 "words it cannot express": zero("x", not_expressible=True),
                 "undecidable": zero("u", causes=["undecidable"]),
                 "signals beside no-behaviour": zero("s", signals={"N": True, "E": True}),
                 "a candidate written and refused": {**zero("r"), "rejected": [{"id": "p", "why": "temporal operator"}]}}
        for why, answer in cases.items():
            with self.subTest(why):
                self.assertIsNotNone(br.exemption_refusal(answer))
                self.assertEqual(br.zero_adopted(answer, True)[0], "operator")
        self.assertIsNotNone(br.exemption_refusal({**zero("i"), "state": "failed"}))
        self.assertIsNone(br.exemption_refusal(zero("ok", signals={"N": True})))
        with rworld(kind="review") as (run, ledger, fake, persist):
            script(fake, L[1], zero("t1", causes=["unsupported_time"]), zero("t2", causes=["unsupported_time"]))
            review(run, ledger, L[1], persist)
            self.assertEqual(review(run, ledger, L[1], persist), "operator")
            self.assertFalse(br.status(run, ledger, L[1])["ok"])
            self.assertNotIn("basis", run.review_states[L[1]])


class Dependencies(Base):
    """A reached exemption carries no condition and is listed; it holds its reader when it lapses."""

    def nodes(self):
        on = lambda *ks: [{"span": f"o{k}", "rule": N[k], "map": {"v": "v"}, "as": "condition"} for k in ks]
        return {N[1]: node_rec(N[1]), N[2]: node_rec(N[2], permission=True), N[3]: node_rec(N[3]),
                N[4]: node_rec(N[4], compositions=on(1, 2, 3)), N[5]: node_rec(N[5], compositions=on(1, 2))}

    def test_no_condition_listed_per_reader_and_real_conditions_still_carried(self):
        with rworld(self.nodes(), kind="review", coverage="bounded") as (run, ledger, fake, persist):
            no_behaviour(fake, run, ledger, L[1], persist)
            br.exempt_law(run, ledger, L[2], fake, persist, [])
            script(fake, L[3], pset(prop("p")))                                 # one category only: review_unverified
            self.assertEqual(review(run, ledger, L[3], persist), "review_unverified")
            for k in (4, 5):
                script(fake, L[k], both())
                self.assertEqual(review(run, ledger, L[k], persist), "reviewed")
            s4, s5 = br.status(run, ledger, L[4]), br.status(run, ledger, L[5])
            self.assertEqual((s4["ok"], s4["strict"], s4["inherited_from"]), (True, False, [L[3]]))     # the real condition carried
            self.assertEqual((s5["ok"], s5["strict"], s5["inherited_from"]), (True, True, []))         # no condition from exemptions
            want = {(L[1], br.NO_BEHAVIOUR, run.review_states[L[1]]["certificate"]["row"]),
                    (L[2], "not_applicable_permission", run.review_states[L[2]]["certificate"]["row"])}
            for s in (s4, s5):
                self.assertEqual({(d["law"], d["type"], d["credential"]) for d in s["exemption_dependencies"]}, want)
            loop.accept_ready(run, replace(run.opts, label_repair=False), ledger, None, [])
            self.assertNotIn("review_condition", run.review_states[L[5]])
            self.assertEqual(run.review_states[L[4]]["review_condition"], {"inherited_from": [L[3]]})
            closure = br.own_status(run, ledger, L[5])["row"]["closure"]
            self.assertTrue({N[1], N[2]} <= set(closure))                         # the composed rules are in its own check

    def test_a_lapsed_exemption_holds_its_reader(self):
        with rworld(self.nodes(), kind="review") as (run, ledger, fake, persist):
            no_behaviour(fake, run, ledger, L[1], persist)
            br.exempt_law(run, ledger, L[2], fake, persist, [])
            script(fake, L[5], both())
            review(run, ledger, L[5], persist)
            self.assertTrue(br.status(run, ledger, L[5])["ok"])
            rel = nodeid.rule_path(N[1])
            (paths.LIBRARY / rel).write_text(files("node", N[1], "v2")[rel])        # the exempt law's rule changes
            s = br.status(run, ledger, L[5])
            self.assertEqual((s["ok"], s["class"]), (False, "stale"))             # its own key reads that rule
            s1 = br.own_status(run, ledger, L[1])
            self.assertEqual(s1["class"], "stale")
            self.assertEqual(review(run, ledger, L[5], persist), "reviewed")       # its own check made again
            s = br.status(run, ledger, L[5])
            self.assertEqual((s["ok"], s["class"], s["waits"]), (False, "dependency_unreviewed", L[1]))


class Order(Base):
    """Review repair first, label repair after; label results as context only."""

    def test_a_label_repair_waits_for_the_finding_to_be_repaired(self):
        with labelled() as (run, ledger, training, by_id, fake, persist), mock.patch.object(br, "REPAIR_SESSION", fix5):
            self.assertEqual(run.label_states[L[5]]["state"], "awaiting_label_repair")
            self.assertIn(L[5], label_repair.awaiting(run, ledger))
            fake.cells[L[5]] = on_mark(N[5], finds, lambda roots, recs: [cell(r["id"], {roots[0]: "violated" if r["category"] == "must_detect"
                                                                                       else "compliant"}) for r in recs])
            self.assertEqual(review(run, ledger, L[5], persist), "finding")
            self.assertNotIn(L[5], label_repair.awaiting(run, ledger))             # the finding first
            from harness.phases import feedback
            self.assertIn(L[5], feedback.pending_lists(run, ledger)["review_repair"])
            set_verdict(training, "r5a", N[5], "violated")                         # labels unchanged by the fix
            seen = {}

            def session(run_, txn, law, evidence):
                seen.update(evidence)
                return fix5(run_, txn, law, evidence)
            with mock.patch.object(br, "REPAIR_SESSION", session):
                self.assertEqual(br.repair_finding(run, ledger, L[5], training, persist, []), "committed")
            ctx = seen["label_context"]
            self.assertEqual(ctx["outcome"], "mismatch")
            self.assertTrue(ctx["mismatches"])
            self.assertTrue((run.dir / ctx["check"]).is_file())
            self.assertEqual(run.review_states[L[5]]["repairs"], 1)
            self.assertEqual(int(run.label_states[L[5]].get("repairs", 0)), 0)    # one session, one counter
            run.opts = replace(run.opts, label_repair=True)
            self.assertNotIn(L[5], loop.stale_labels(run, ledger, ("planned", "accepted")))   # its label state keyed on what it committed
            self.assertIn(L[5], label_repair.awaiting(run, ledger))                # now the labels' turn

    def test_a_law_with_no_label_state_is_repaired_and_not_accepted_by_it(self):
        with labelled() as (run, ledger, training, by_id, fake, persist):
            fake.cells[L[2]] = on_mark(N[2], finds, lambda roots, recs: [cell(r["id"], {roots[0]: "violated" if r["category"] == "must_detect"
                                                                                       else "compliant"}) for r in recs])
            self.assertEqual(review(run, ledger, L[2], persist), "finding")
            self.assertEqual(br.revoke_unreviewed(run, ledger, []), [L[2]])      # its acceptance does not survive the finding
            run.label_states.pop(L[2]); persist()                                 # as in a fresh run: no label state at all
            seen = {}

            def session(run_, txn, law, evidence):
                seen.update(evidence)
                return [cand.Change("node", N[2], node_rec(N[2]), files("node", N[2], "v2"))]
            with mock.patch.object(br, "REPAIR_SESSION", session):
                self.assertEqual(br.repair_finding(run, ledger, L[2], training, persist, []), "committed")
            self.assertNotIn("label_context", seen)
            self.assertTrue(br.own_status(run, ledger, L[2])["ok"])
            self.assertNotEqual(ledger.entries[L[2]].state, "accepted")           # its labels are still to be checked

    def conflict(self, run, ledger, training, fake, persist, cites):
        fake.cells[L[5]] = finds                                                    # `p` (must_detect) finds
        self.assertEqual(review(run, ledger, L[5], persist), "finding")

        def disputes(*a):
            raise br.Dispute("the property and the label want opposite verdicts of one behaviour", "label_conflict", cites)
        with mock.patch.object(br, "REPAIR_SESSION", disputes):
            return br.repair_finding(run, ledger, L[5], training, persist, [])

    def test_a_shown_conflict_goes_to_the_operator_at_once(self):
        with labelled() as (run, ledger, training, by_id, fake, persist):
            self.assertEqual(self.conflict(run, ledger, training, fake, persist, {"property": "p", "recording": "r5a"}), "dispute")
            st = run.review_states[L[5]]
            self.assertEqual((st["repairs"], st["dispute"]["property"], st["dispute"]["recording"]), (1, "p", "r5a"))   # one of two spent
            self.assertTrue(st["dispute"]["label"]["mismatches"])
            self.assertEqual(br.work(run, ledger)["repair"], [])
            self.assertEqual(br.route_holds(run, ledger, []), [L[5]])
            self.assertIn("opposite verdicts", run.review_states[L[5]]["held"])

    def test_an_unshown_conflict_is_an_attempt_that_changed_nothing(self):
        for cites, why in (({"property": "q", "recording": "r5a"}, "not one of the finding's"),
                           ({"property": "p", "recording": "r5c"}, "not a mismatch"),
                           ({"property": "p", "recording": "r5b"}, "same kind of verdict")):
            with self.subTest(cites), labelled() as (run, ledger, training, by_id, fake, persist):
                self.assertEqual(self.conflict(run, ledger, training, fake, persist, cites), "rolled_back")
                st = run.review_states[L[5]]
                self.assertNotIn("dispute", st)
                self.assertIn(why, st["last_repair"]["outcome"])
                self.assertEqual(st["repairs"], 1)

    def test_spent_repairs_report_both_sides(self):
        with labelled(repair_attempts=1) as (run, ledger, training, by_id, fake, persist), mock.patch.object(br, "REPAIR_SESSION", fix5):
            fake.cells[L[5]] = finds
            review(run, ledger, L[5], persist)
            self.assertEqual(br.repair_finding(run, ledger, L[5], training, persist, []), "rolled_back")
            why = br.hold_reason(run, L[5], br.own_status(run, ledger, L[5]))
            self.assertIn("the finding ['p:", why)
            self.assertIn("its labels mismatch", why)
            self.assertIn("not a proven conflict", why)


class CoreDigest(Base):
    """Core is named by its logical names, wherever the library lies."""

    def old(self, core: Path) -> str:
        h = hashlib.sha256()
        for p in sorted(core.rglob("*.lean")):
            if p.is_file():
                h.update(str(p.relative_to(paths.REPO) if p.is_relative_to(paths.REPO) else p).encode()); h.update(p.read_bytes())
        return h.hexdigest()[:24]

    def test_production_candidate_and_moved_copies_key_alike(self):
        prod = paths.CORE
        self.assertEqual(loop.core_digest(), self.old(prod))                       # the production value is unchanged
        with tempfile.TemporaryDirectory() as t:
            cand_core = Path(t) / "results" / "r" / "iter-001" / "candidate" / "x" / "tree" / "library" / "TrafficSpec" / "Core"
            moved = Path(t) / "elsewhere" / "checkout" / "library" / "TrafficSpec" / "Core"
            for d in (cand_core, moved):
                shutil.copytree(prod, d)
            want = loop.core_digest(prod)
            self.assertNotEqual(self.old(cand_core), want)                           # the defect: the location entered the key
            self.assertEqual((loop.core_digest(cand_core), loop.core_digest(moved)), (want, want))
            with paths.at_library(cand_core.parent.parent):
                self.assertEqual(loop.core_digest(), want)
            f = sorted(moved.rglob("*.lean"))[0]
            text = f.read_bytes()
            f.write_bytes(text + b"\n-- changed\n")
            self.assertNotEqual(loop.core_digest(moved), want)                        # content
            f.write_bytes(text)
            self.assertEqual(loop.core_digest(moved), want)
            extra = moved / "Extra.lean"
            extra.write_text("-- added\n")
            self.assertNotEqual(loop.core_digest(moved), want)                        # a file added
            extra.unlink()
            self.assertEqual(loop.core_digest(moved), want)
            f.unlink()
            self.assertNotEqual(loop.core_digest(moved), want)                        # a file deleted
            f.write_bytes(text)
            renamed = f.with_name("Renamed_" + f.name)
            f.rename(renamed)
            self.assertNotEqual(loop.core_digest(moved), want)                        # a file renamed
            renamed.rename(f)
            self.assertEqual(loop.core_digest(moved), want)                           # restored: the same key

    def test_a_review_key_is_the_same_inside_a_candidate(self):
        with rworld(kind="review") as (run, ledger, fake, persist):
            script(fake, L[1], both())
            self.assertEqual(review(run, ledger, L[1], persist), "reviewed")
            want = br.own_status(run, ledger, L[1])["row"]["check_key"]
            with cand.SCHEDULING.pause(timeout=60):
                txn = cand.Candidate.open(run, hooks=())
                try:
                    self.assertFalse(hasattr(txn.view, "review_base"))
                    production = paths.CORE
                    with txn.inside():
                        self.assertNotEqual(paths.CORE, production)                  # the candidate's copy is in force
                        s = br.own_status(txn.view, txn.ledger, L[1])
                        self.assertEqual(loop.semantic_inputs(txn.view.opts)["core"], loop.semantic_inputs(run.opts)["core"])
                finally:
                    txn.close("test")
            self.assertEqual((s["ok"], s["row"]["check_key"]), (True, want))
