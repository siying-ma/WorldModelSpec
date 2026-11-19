"""The behaviour review's parts held to one contract, without a model: the adoption gate's property
set carries every field the no-behaviour exemption reads, and an answer invalid as a whole gives
neither an exemption nor a credential, end to end; every adoption records what it was asked on; the
adoption gate's digest binds the implementation digest and the spec key, so a change to it makes a
credential stale; the review repair's prompt shows the prompt's review section and the law's label
results as non-regression context; `review_decide reconcile` settles an unknown call."""
import contextlib
import io
import json
import tempfile
import unittest
from pathlib import Path
from unittest import mock

from harness.__main__ import Cli
from harness.phases import behaviour_review as br
from harness.phases import candidate as cand
from harness.phases import label_repair
from harness.phases import review_schema as rs
from harness.store import jsonl
from scripts.tests import test_behaviour_review_stage as stage
from scripts.tests.test_review_schema import CTX, candidate, draft, item, no_behaviour_rounds, raw, screen, slow_no_behaviour, slow_rounds

L = stage.L


class GateFields(unittest.TestCase):
    """What `exemption_refusal` reads is what the adoption gate writes."""

    def test_a_no_behaviour_set_carries_every_field_the_exemption_reads(self):
        out = rs.adopt_answer(no_behaviour_rounds(), CTX)
        z = out["zero_adopted"]
        self.assertEqual((out["state"], out["records"], out["candidates"], out["rejected"]), ("ok", [], [], []))
        self.assertEqual((z["codes"], z["causes"], z["signals"]["N"]), (["no_checkable_behaviour"], [], True))
        self.assertIsNone(br.exemption_refusal(out))
        self.assertEqual(br.zero_adopted({**out, "spec_key": "k"}, final=True)[0], br.NO_BEHAVIOUR)

    def test_a_written_or_refused_candidate_or_a_limit_of_the_review_refuses_the_exemption(self):
        gap = candidate("P1", gaps=[{"words": "school zone", "distinction": "place", "why_no_atom": "no atom"}])
        out = rs.adopt_answer([{"draft": draft(gap), "screen": screen(item("P1", item_cause="not_expressible", conclusion_ok="yes"))}], CTX)
        self.assertEqual((out["records"], out["candidates"], [r["id"] for r in out["rejected"]]), ([], ["P1"], ["P1"]))
        self.assertTrue({"missing_atom", "not_expressible"} <= set(out["zero_adopted"]["causes"]))
        self.assertIsNotNone(br.exemption_refusal(out))
        rounds = no_behaviour_rounds()
        rounds[0]["screen"]["law_behaviour"] = {"assessment": "cannot_tell", "reason": "r"}
        out = rs.adopt_answer(rounds, CTX)
        self.assertEqual(out["zero_adopted"]["causes"], ["cannot_tell"])
        self.assertIn("cannot_tell", br.exemption_refusal(out))

    def test_every_cause_the_gate_names_is_one_the_stage_refuses(self):
        cases = [[{"draft": draft(candidate("P1", gaps=[{"words": "w", "distinction": "action", "why_no_atom": "w"}])), "screen": screen(item("P1"))}],
                 [{"draft": draft(candidate("P1")), "screen": screen(item("P1", item_cause="cannot_tell", conclusion_ok="cannot_tell"))}],
                 [{"draft": draft(candidate("P1", observations=["kin.velocity"])), "screen": screen(item("P1"))}]]
        named = set()
        for rounds in cases:
            out = rs.adopt_answer(rounds, CTX)
            self.assertEqual(out["state"], "ok")
            named |= set(out["zero_adopted"]["causes"])
        self.assertEqual(named, {"missing_atom", "not_expressible", "cannot_tell"})
        self.assertTrue(named <= set(br.NOT_THE_LAWS))

    def test_a_schema_invalid_answer_gives_no_exemption_and_no_credential(self):
        bad = slow_no_behaviour(); bad[0]["screen"]["law_behaviour"]["extra"] = "x"
        out = rs.adopt_answer(bad, CTX)
        self.assertEqual((out["state"], out["records"], out.get("zero_adopted")), ("failed", [], None))
        self.assertEqual(br.exemption_refusal(out), "the answer was not valid")
        for attempts in (1, 2):
            with self.subTest(property_attempts=attempts), stage.rworld(kind="labels", property_attempts=attempts) as (run, ledger, fake, persist):
                stage.script(fake, L[1], *[raw(copy) for copy in [bad, bad][:attempts]])
                got = [stage.review(run, ledger, L[1], persist) for _ in range(attempts)]
                self.assertEqual(got, ["failed"] * attempts)
                self.assertEqual(stage.review(run, ledger, L[1], persist), "held")       # no ask left: nothing judged again
                st = run.review_states[L[1]]
                pset = br.load_set(run, L[1], st["active_set"]["set_id"])
                self.assertEqual((pset["state"], pset["records"], pset.get("zero_adopted")), ("failed", [], None))
                self.assertIsNotNone(br.exemption_refusal(pset))
                self.assertNotIn("certificate", st)
                self.assertNotIn("basis", st)
                self.assertFalse(br.own_status(run, ledger, L[1])["ok"])
                self.assertFalse(br.status(run, ledger, L[1])["ok"])
                self.assertNotIn(L[1], br.counts(run, ledger).get("no_checkable_behaviour", []))
                rows = list(br.read_rows(br.evidence_file(run)).values())
                self.assertFalse([r for r in rows if r.get("kind") in ("basis", "exempt")])

    def test_a_valid_no_behaviour_answer_gives_the_basis_and_the_credential(self):
        with stage.rworld(kind="labels", property_attempts=1) as (run, ledger, fake, persist):
            stage.script(fake, L[1], raw(slow_no_behaviour()))
            self.assertEqual(stage.review(run, ledger, L[1], persist), br.NO_BEHAVIOUR)
            st = run.review_states[L[1]]
            self.assertTrue(st.get("basis") and st.get("certificate"))
            self.assertTrue(br.own_status(run, ledger, L[1])["ok"])


class AskedOn(unittest.TestCase):
    """Both callers of `adopt` record what the adopted set was asked on."""

    def test_the_review_and_the_reconcile_record_it(self):
        with stage.rworld(kind="labels") as (run, ledger, fake, persist):
            stage.script(fake, L[1], raw(slow_rounds()))
            self.assertEqual(stage.review(run, ledger, L[1], persist), "reviewed")
            st = run.review_states[L[1]]
            words = br.words_digest(run, L[1], br_base(run))
            self.assertEqual(st["asked_on"], {st["active_set"]["set_id"]: words})
        with stage.rworld(kind="labels") as (run, ledger, fake, persist):
            stage.script(fake, L[1], br.ReviewerUnavailable("timed out after sending", executed=None))
            self.assertEqual(stage.review(run, ledger, L[1], persist), "unavailable")
            self.assertEqual(br.reconcile(run, L[1], executed=True, answer=raw(slow_rounds())), "adopted")
            st = run.review_states[L[1]]
            self.assertEqual(st["asked_on"], {st["active_set"]["set_id"]: br.words_digest(run, L[1], br_base(run))})
            persist()
            self.assertEqual(stage.review(run, ledger, L[1], persist), "reviewed")     # the reconciled set is used, no new call
            self.assertEqual(len(fake.property_calls), 1)


def br_base(run):
    from harness.loop import context_base, semantic_inputs
    return context_base(run.opts, semantic_inputs(run.opts))


class GateDigest(unittest.TestCase):
    """A change to the adoption gate (its schemas, limits, templates, language or source) makes the
    run's reviewer another implementation and its credentials stale."""

    def test_a_gate_change_invalidates_the_credential(self):
        with stage.rworld(kind="labels") as (run, ledger, fake, persist):
            stage.script(fake, L[1], raw(slow_rounds()))
            self.assertEqual(stage.review(run, ledger, L[1], persist), "reviewed")
            impl, spec = br.implementation_digest(fake_reviewer_name()), br.spec_of(fake, run, L[1])
            self.assertTrue(br.own_status(run, ledger, L[1])["ok"])
            real = Path.read_bytes
            for name in (rs.LIMITS_FILE, rs.FILES["screen"], rs.PROPERTY_LANGUAGE):
                with self.subTest(changed=name), \
                        mock.patch.object(Path, "read_bytes", lambda p, n=name: real(p) + (b" " if p.name == n else b"")):
                    self.assertNotEqual(br.implementation_digest(fake_reviewer_name()), impl)
                    self.assertNotEqual(br.spec_of(fake, run, L[1]), spec)
                    s = br.own_status(run, ledger, L[1])
                    self.assertFalse(s["ok"])
                    self.assertIn("another implementation", s["why"])
                    self.assertFalse(br.status(run, ledger, L[1])["ok"])
            self.assertTrue(br.own_status(run, ledger, L[1])["ok"])                     # the gate restored: the credential holds
            row = br.read_rows(br.evidence_file(run))[run.review_states[L[1]]["certificate"]["row"]]
            self.assertEqual(row["impl"], impl)
            self.assertEqual(br.load_set(run, L[1], run.review_states[L[1]]["active_set"]["set_id"])["spec_key"], spec)


def fake_reviewer_name():
    from scripts.tests import fake_reviewer
    return fake_reviewer.NAME


class Coverage(unittest.TestCase):
    """The holes the adoption gate records reach the check's row."""

    def test_a_refused_candidate_is_a_hole_of_the_check(self):
        rounds = slow_rounds()
        extra = dict(rounds[0]["draft"]["candidates"][0], id="P3", observations=["kin.velocity"])     # refused by the language check
        rounds[0]["draft"]["candidates"].append(extra)
        with stage.rworld(kind="labels") as (run, ledger, fake, persist):
            stage.script(fake, L[1], raw(rounds))
            self.assertEqual(stage.review(run, ledger, L[1], persist), "operator")     # strict: P1 and P2 cover C1, the refusal is a hole
            row = br.read_rows(br.evidence_file(run))[run.review_states[L[1]]["last"]["row"]]
            self.assertEqual([h["kind"] for h in row["holes"]], ["rejected"])
            self.assertIn("P3", row["holes"][0]["detail"])
        with stage.rworld(kind="labels", coverage="bounded") as (run, ledger, fake, persist):
            stage.script(fake, L[1], raw(rounds))
            self.assertEqual(stage.review(run, ledger, L[1], persist), "review_unverified")
            self.assertEqual([h["kind"] for h in run.review_states[L[1]]["certificate"]["holes"]], ["rejected"])
        with stage.rworld(kind="labels") as (run, ledger, fake, persist):
            stage.script(fake, L[1], raw(slow_rounds()))
            self.assertEqual(stage.review(run, ledger, L[1], persist), "reviewed")     # no refusal: no hole


class RepairPrompt(unittest.TestCase):
    """The review repair's prompt: the review section shown with the finding evidence, the law's label
    results as non-regression context; the label repair's prompt without the section."""

    def test_the_review_section_and_the_label_context(self):
        from scripts.tests.test_label_repair_session import repairing
        with repairing() as (run, ledger, training, by_id):
            law = L[5]
            labels = br.label_context(run, law)
            self.assertTrue(labels and labels.get("check"))
            run.review_states[law] = {"last_repair": {"failed": [{"check": "label_non_regression", "subject": law, "status": "fail",
                                                                  "details": ["r5a: a match became a mismatch"]}]}}
            labels = br.label_context(run, law)
            row = {"findings": [{"property": "P1", "category": "must_detect", "detail": "scene s1: the law's verdict is compliant"}],
                   "holes": [{"kind": "rejected", "detail": "P3: refused"}], "policy": "strict"}
            onto = label_repair.ontology.load(run.opts.ontology)
            with cand.SCHEDULING.pause():
                txn = cand.Candidate.open(run, hooks=())
                try:
                    with_labels = br.repair_prompt(run, txn, by_id[law], br.render_findings(row, labels), onto)
                    without = br.repair_prompt(run, txn, by_id[law], br.render_findings(row, None), onto)
                    label_prompt = label_repair.prompt_for(run, txn, by_id[law], [], onto, 0)
                finally:
                    txn.close("test")
            section = "These rules apply only to a law-level review repair"
            evidence_rule = "Existing label-check results\n  may also be supplied during a review repair as non-regression context"
            for p in (with_labels, without, label_prompt):
                self.assertNotRegex(p, r"\{(law|node|verdict|evidence|final_files|ontology)\}")
                self.assertNotRegex(p, r"<!-- /?section:")
            for p in (with_labels, without):
                self.assertIn(section, p)
                self.assertIn(evidence_rule, p)
                self.assertIn('"property": "P1"', p)
                self.assertIn("P3: refused", p)
                self.assertIn("Coverage policy: strict.", p)
            self.assertIn("### Existing label-check results (non-regression context)", with_labels)
            self.assertIn(f"Label check: {labels['outcome']}", with_labels)
            self.assertIn("#### Label mismatches", with_labels)                      # the label evidence, its headings below the section's
            self.assertNotIn("\n## Label mismatches", with_labels)
            self.assertIn("label_non_regression `L-5`: fail; r5a: a match became a mismatch", with_labels.replace(law, "L-5"))
            self.assertNotIn("Existing label-check results (non-regression context)", without)
            self.assertNotIn(section, label_prompt)                                # the label repair's prompt: the section removed
            self.assertIn(evidence_rule, label_prompt)
            self.assertIn("## Label mismatches", label_prompt)


class Reconcile(unittest.TestCase):
    """`review_decide <run> <law> reconcile --record <file>` settles the law's unknown call."""

    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)

    def record(self, run, of, **over) -> str:
        pending = run.review_states[of]["pending_call"]
        f = Path(self.tmp.name) / f"rec-{len(list(Path(self.tmp.name).iterdir()))}.json"
        f.write_text(json.dumps({"run_id": run.opts.run_id, "law": of, "decision": "reconcile", "call": pending["workdir"],
                                 "executed": False, "reason": "the provider shows no request", **over}))
        return str(f)

    def cli(self, *args, world=None, **kw) -> tuple[int, str]:
        """The command, on the run of `world` (`(run, ledger)`) as `Run.load` would give it from its
        committed snapshot; the test world keeps no `options.json`, so the stored-run refusal is stood in for."""
        out = io.StringIO()
        with contextlib.ExitStack() as s:
            s.enter_context(contextlib.redirect_stdout(out))
            s.enter_context(mock.patch("harness.store.owner.acquire_for_command", lambda name: None))
            if world is not None:
                s.enter_context(mock.patch("harness.__main__._refuse_stored_run", lambda run_id, what: None))
                s.enter_context(mock.patch("harness.store.state.Run.load", lambda run_id: stage.reload(*world)))
            code = Cli().review_decide(*args, **kw)
        return code, out.getvalue()

    def test_the_command_settles_the_call_and_commits_it(self):
        with stage.rworld(kind="labels") as (run, ledger, fake, persist):
            stage.script(fake, L[1], br.ReviewerUnavailable("timed out after sending", executed=None), raw(slow_rounds()))
            self.assertEqual(stage.review(run, ledger, L[1], persist), "unavailable")
            rid = run.opts.run_id
            for over, why in (({"call": "review/other"}, "`call`"), ({"law": L[2]}, "`law`"), ({"executed": "no"}, "`executed`"),
                              ({"reason": ""}, "`reason`"), ({"answer": "x.json"}, "not recorded as executed")):
                with self.subTest(refused=why):
                    code, text = self.cli(rid, L[1], "reconcile", world=(run, ledger), record=self.record(run, L[1], **over))
                    self.assertEqual(code, 1)
                    self.assertIn(why, text)
            d = run.dir / run.review_states[L[1]]["pending_call"]["workdir"]
            d.mkdir(parents=True, exist_ok=True)
            (d / "response.json").write_text("{}")
            code, text = self.cli(rid, L[1], "reconcile", world=(run, ledger), record=self.record(run, L[1]))
            self.assertEqual((code, "cannot be recorded as not executed" in text), (1, True))
            (d / "response.json").unlink()
            self.assertIn("pending_call", jsonl.read_json(run.state_file, {})["review_states"][L[1]])
            code, text = self.cli(rid, L[1], "reconcile", world=(run, ledger), record=self.record(run, L[1]))
            self.assertEqual(code, 0, text)
            self.assertIn("not_executed", text)
            st = jsonl.read_json(run.state_file, {})["review_states"][L[1]]
            self.assertEqual((st.get("pending_call"), st["property_asks"]), (None, 0))   # committed: the ask given back
            fresh = stage.reload(run, ledger)
            self.assertEqual(stage.review(fresh, ledger, L[1], stage.persist_of(fresh, ledger)), "reviewed")

    def test_an_executed_call_with_its_answer_is_adopted_through_the_gate(self):
        with stage.rworld(kind="labels") as (run, ledger, fake, persist):
            stage.script(fake, L[1], br.ReviewerUnavailable("timed out after sending", executed=None))
            stage.review(run, ledger, L[1], persist)
            answer = Path(self.tmp.name) / "answer.json"
            answer.write_text(json.dumps(raw(slow_rounds())))
            code, text = self.cli(run.opts.run_id, L[1], "reconcile", world=(run, ledger), record=self.record(run, L[1], executed=True, answer=str(answer)))
            self.assertEqual(code, 0, text)
            fresh = stage.reload(run, ledger)
            st = fresh.review_states[L[1]]
            pset = br.load_set(fresh, L[1], st["active_set"]["set_id"])
            self.assertEqual(([r["id"] for r in pset["records"]], "pending_call" in st), (["P1", "P2"], False))
            self.assertIn(st["active_set"]["set_id"], st["asked_on"])
            self.assertEqual(stage.review(fresh, ledger, L[1], stage.persist_of(fresh, ledger)), "reviewed")
            self.assertEqual(len(fake.property_calls), 1)

    def test_the_decisions_not_implemented_are_refused(self):
        for decision in ("finding", "redraft", "limits", ""):
            with self.subTest(decision=decision):
                code, text = self.cli("r", "L-1", decision, record="f")
                self.assertEqual(code, 1)
                self.assertIn("unknown or unimplemented decision", text)


if __name__ == "__main__":
    unittest.main()
