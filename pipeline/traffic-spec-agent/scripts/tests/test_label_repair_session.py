"""The label repair of a law (`--label_repair`): the session's five output shapes, a Lean change
applied only where the change is local (else the coder's, in the same candidate), the one same-id
rule by a concept's state, a law planned again inside the candidate keeping its repair count, a
repair that fixes one of two mismatches kept while the law stays in disagreement, judgment calls
that never open a session, and the review path's evidence block unchanged.

Every session is a stand-in that writes the files a session would; the monitor and Explain are the
label check's stand-in programs over a synthetic dataset; the gate's toolchain step, the
whole-library build and the validator are stood in for. The candidate, the hooks, the snapshot, the
ledger and the readers are the real ones."""
import json
import re
import unittest
from contextlib import contextmanager
from pathlib import Path
from unittest import mock

from harness import loop
from harness.agents import render, session
from harness.checks import gate
from harness.lean import lean
from harness.model import corpus, nodeid
from harness.phases import candidate as cand
from harness.phases import integrate, label_check, label_repair, plan
from harness.store import jsonl
from harness.store.gaps import GapLedger
from scripts.tests.test_candidate import (CA, CB, CD, NN, Base, Gates, Txn, concept_rec, files, node_rec, passing, standard,
                                          world)
from scripts.tests.test_label_check import make_dataset
from scripts.tests.test_label_repair import L, N, RECS, RECS_V2, setting

RULE5 = nodeid.rule_path(N[5])
DIFF5 = f"--- {RULE5}\n+++ {RULE5}\n@@ -3 +3 @@\n--- v1\n+-- v2\n"


def stub_session(outputs: dict[str, str] | None = None, calls: list | None = None):
    """A session that writes `outputs` into its working directory (a coding session writes nothing)."""
    def run(prompt, cwd=None, out_dir=None, label="session", **_k):
        if calls is not None:
            calls.append((Path(cwd).name, label))
        if outputs and "label_repair" in Path(cwd).parts:
            for name, text in outputs.items():
                (Path(cwd) / name).write_text(text, encoding="utf-8")
    return run


def set_verdict(training, rid: str, rule: str, verdict: str) -> None:
    """The stand-in monitor's verdict for a rule on a recording: what the repaired rule now computes."""
    f = training.dataset.path / "recordings" / rid / "fake.json"
    spec = json.loads(f.read_text())
    spec[rule] = [[verdict, {"x": 1}]]
    f.write_text(json.dumps(spec))


@contextmanager
def repairing(recs=RECS, outputs=None, calls=None, concepts=None, uses=None):
    """`setting` with the laws in the run's corpus, the laws routed once, and every stand-in in place."""
    with setting(recs, concepts, uses) as (run, ledger, training, t):
        laws = Path(run.opts.laws)
        laws.write_text("".join(json.dumps({"id": L[k], "title": f"law {k}", "text": "A driver shall proceed slowly.", "source": "test"}) + "\n"
                                for k in L))
        laws.with_name("definitions.jsonl").write_text("")
        loop.label_route(run, ledger, training, [])
        with mock.patch.object(session, "run", stub_session(outputs, calls)), mock.patch.object(gate, "_toolchain", Gates()), \
                mock.patch.object(integrate, "verify_library", lambda *a, **k: ("verified", [], set())), \
                mock.patch.object(lean, "lake_build", lambda *a, **k: (0, "")), mock.patch.object(cand, "validate_records", passing):
            yield run, ledger, training, {l.id: l for l in corpus.load_laws(laws)}


def repair(run, ledger, training, by_id, to_user=None):
    return label_repair.repair_law(run, ledger, training, by_id[L[5]], [], label_repair.ontology.load(run.opts.ontology),
                                   GapLedger.for_run(label_repair.paths.GAPS_DIR, run), [], to_user if to_user is not None else [])


REQUEST = {"type": "semantic", "object": "core", "target": "a primitive", "words": "not applicable", "evidence": "r5a: the derivation"}


class Shapes(unittest.TestCase):
    """The reader of a label repair's output, on its five shapes."""

    def read(self, outputs: dict[str, str]) -> label_repair.Output:
        import tempfile
        with tempfile.TemporaryDirectory() as t:
            for name, text in outputs.items():
                (Path(t) / name).write_text(text)
            return label_repair.read_output(Path(t), {N[5]: node_rec(N[5])})

    def test_the_five_shapes(self):
        only_request = self.read({"change_request.json": json.dumps([REQUEST])})
        self.assertEqual((only_request.errors, only_request.requests), ([], [REQUEST]))
        only_withdrawal = self.read({"record.jsonl": json.dumps({"node_id": N[5], "withdraw": {"kind": "plan", "missing": "a new cut"}})})
        self.assertEqual((only_withdrawal.errors, only_withdrawal.withdrawals[0]["withdraw"]["kind"]), ([], "plan"))
        rec = {k: v for k, v in node_rec(N[5]).items() if k != "segmentation"}
        record_diff = self.read({"record.jsonl": json.dumps(rec), "lean.diff": DIFF5})
        self.assertEqual((record_diff.errors, record_diff.diff, record_diff.records[0].raw["segmentation"]),
                         ([], DIFF5, node_rec(N[5])["segmentation"]))          # the harness keeps the segmentation
        record_request = self.read({"record.jsonl": json.dumps(rec), "change_request.json": json.dumps([{**REQUEST, "object": "label"}])})
        self.assertEqual((record_request.errors, len(record_request.records), len(record_request.requests)), ([], 1, 1))
        empty = self.read({})
        self.assertIn("is refused", empty.errors[0])

    def test_malformed_outputs(self):
        bad = self.read({"change_request.json": json.dumps([{**REQUEST, "object": "law", "words": ""}])})
        self.assertEqual(len(bad.errors), 2)
        stranger = self.read({"record.jsonl": json.dumps(node_rec("TEST_OTHER_1"))})
        self.assertIn("withdraw with kind `plan`", stranger.errors[0])


class Repair(Base):

    def test_a_repair_that_fixes_one_of_two_mismatches_is_kept_and_the_law_still_disagrees(self):
        rec = {k: v for k, v in node_rec(N[5]).items() if k != "segmentation"}
        with repairing(outputs={"record.jsonl": json.dumps(rec), "lean.diff": DIFF5}) as (run, ledger, training, by_id):
            self.assertEqual(run.label_states[L[5]]["outcome"], "mismatch")
            set_verdict(training, "r5a", N[5], "compliant")              # the repaired rule now agrees on r5a; r5b still disagrees
            to_user = []
            self.assertEqual(repair(run, ledger, training, by_id, to_user), "committed")
            st = run.label_states[L[5]]
            self.assertEqual((st["state"], st["outcome"], st["repairs"]), ("awaiting_label_repair", "mismatch", 1))
            self.assertEqual(st["coverage"], {"eligible": 3, "matched": 2})
            self.assertEqual(ledger.entries[L[5]].state, "planned")
            self.assertIn("-- v2", (label_repair.paths.LIBRARY / RULE5).read_text())
            snap = jsonl.read_json(run.state_file, {})
            self.assertEqual(snap["label_states"][L[5]]["repairs"], 1)
            self.assertTrue(any("label repair kept (goal met); the law is mismatch" in x for x in to_user))

    def test_a_repair_that_meets_no_goal_is_rolled_back_and_counted(self):
        rec = {k: v for k, v in node_rec(N[5]).items() if k != "segmentation"}
        with repairing(outputs={"record.jsonl": json.dumps(rec), "lean.diff": DIFF5}) as (run, ledger, training, by_id):
            before = (label_repair.paths.LIBRARY / RULE5).read_text()
            self.assertEqual(repair(run, ledger, training, by_id), "rolled_back")
            st = run.label_states[L[5]]
            self.assertEqual((st["state"], st["repairs"]), ("awaiting_label_repair", 1))
            self.assertIn("not met", st["last_repair"]["outcome"])
            self.assertEqual((label_repair.paths.LIBRARY / RULE5).read_text(), before)

    def test_an_empty_output_is_refused_after_one_reask(self):
        calls = []
        with repairing(outputs={}, calls=calls) as (run, ledger, training, by_id):
            self.assertEqual(repair(run, ledger, training, by_id), "refused")
            self.assertEqual([c[1] for c in calls], ["session", "session_again"])
            self.assertEqual(run.label_states[L[5]]["repairs"], 1)

    def test_only_a_request_files_it_and_holds_the_law(self):
        reqs = [REQUEST, {**REQUEST, "object": "parameter", "target": "p.window"}]
        with repairing(outputs={"change_request.json": json.dumps(reqs)}) as (run, ledger, training, by_id):
            before = tree(label_repair.paths.LIBRARY)
            self.assertEqual(repair(run, ledger, training, by_id), "requested")
            self.assertEqual(tree(label_repair.paths.LIBRARY), before)
            self.assertEqual([r["target"] for r in jsonl.read_strict(run.dir / label_repair.OUTER_FILE)], ["a primitive"])
            self.assertEqual([r["target"] for r in jsonl.read_strict(run.dir / label_repair.OPERATOR_FILE)], ["p.window"])
            self.assertEqual(ledger.entries[L[5]].state, "blocked")

    def test_a_non_local_change_goes_to_the_coder_in_the_candidate(self):
        rec = {k: v for k, v in node_rec(N[5]).items() if k != "segmentation"}
        rec["elements"] = [{"span": "o1", "atoms": ["kin.speed", "rel.occupies"], "derived": []}]
        coded = []
        with repairing(outputs={"record.jsonl": json.dumps(rec), "lean.diff": DIFF5}) as (run, ledger, training, by_id), \
                mock.patch.object(label_repair, "code_in_candidate", lambda txn, recs, law=None, earlier=None: coded.append((recs, (txn.library / RULE5).read_text())) or {}):
            set_verdict(training, "r5a", N[5], "compliant")
            self.assertEqual(repair(run, ledger, training, by_id), "committed")
            self.assertEqual(coded[0][0], [("node", N[5])])
            self.assertNotIn("-- v2", coded[0][1])                          # the repair's Lean was not applied

    def test_a_diff_outside_the_files_shown_is_refused(self):
        other = nodeid.rule_path(N[1])
        diff = f"--- {other}\n+++ {other}\n@@ -3 +3 @@\n--- v1\n+-- v2\n"
        with repairing(outputs={"lean.diff": diff}) as (run, ledger, training, by_id):
            self.assertEqual(repair(run, ledger, training, by_id), "rolled_back")
            self.assertIn("not among the files shown", run.label_states[L[5]]["last_repair"]["outcome"])

    def test_a_law_planned_again_in_the_candidate_keeps_its_repair_count(self):
        new = [f"{N[5]}_o1", f"{N[5]}_o2"]

        def fake_plan(view, laws, defs, tag="", pending=None):
            d = view.iter / "plan" / tag
            d.mkdir(parents=True, exist_ok=True)
            (d / "blueprint.jsonl").write_text("".join(json.dumps(node_rec(i) | {"law_refs": [L[5]]}) + "\n" for i in new))
            return d

        def coder(txn, recs, law=None, earlier=None):
            with txn.inside():
                for kind, ident in recs:
                    for rel, text in files(kind, ident).items():
                        (txn.library / rel).parent.mkdir(parents=True, exist_ok=True)
                        (txn.library / rel).write_text(text)
            return {}
        withdraw = {"node_id": N[5], "withdraw": {"kind": "plan", "missing": "the law carries two duties"}}
        with repairing(outputs={"record.jsonl": json.dumps(withdraw)}) as (run, ledger, training, by_id), \
                mock.patch.object(plan, "run_plan", fake_plan), mock.patch.object(label_repair, "code_in_candidate", coder):
            run.label_states[L[5]]["repairs"] = 1                         # one repair already spent on the law
            for rid, v in (("r5a", "compliant"), ("r5b", "violated"), ("r5c", "compliant")):
                for i in new:
                    set_verdict(training, rid, i, v if i.endswith("o1") else "not_applicable")
            self.assertEqual(repair(run, ledger, training, by_id), "committed")
            self.assertEqual(ledger.entries[L[5]].nodes, new)
            self.assertEqual(run.label_states[L[5]]["repairs"], 2)        # not reset by the new cut
            self.assertEqual(run.label_states[L[5]]["state"], "accepted")
            self.assertEqual(ledger.entries[L[5]].state, "accepted")
            self.assertNotIn(N[5], run.accepted_nodes)
            self.assertEqual(sorted(i for i in run.accepted_nodes if i.startswith(N[5])), new)

    def test_a_concept_report_waits_and_a_gap_blocks(self):
        report = {"node_id": N[5], "withdraw": {"kind": "concept", "missing": "the concept computes what its contract excludes"}}
        with repairing(outputs={"record.jsonl": json.dumps(report), "dependency_defect.json": "{}"}) as (run, ledger, training, by_id):
            self.assertEqual(repair(run, ledger, training, by_id), "dependency_report")
            self.assertEqual(run.label_states[L[5]].get("repairs", 0), 1)              # a malformed report is a decided repair
            rows = run.label_states[L[5]]["reports"]
            self.assertEqual([(r["status"], r["execution"], r["ruling"]) for r in rows], [("protocol", "not_run", "refused")])
            shown = label_repair.reports_block(rows)
            self.assertIn("report refused, no ruling; the concept takes no obligation from it", shown)
            self.assertNotIn("not finished", shown)
        gap = {"node_id": N[5], "withdraw": {"kind": "atom", "span": "o1", "missing": "a lamp state", "nearest": []}}
        with repairing(outputs={"record.jsonl": json.dumps(gap)}) as (run, ledger, training, by_id):
            self.assertEqual(repair(run, ledger, training, by_id), "gap")
            e = ledger.entries[L[5]]
            self.assertEqual(e.state, "blocked")
            self.assertTrue(e.gaps and not e.gaps[0].startswith("decision:"))

    def test_the_budgets(self):
        with repairing(outputs={}) as (run, ledger, training, by_id):
            run.opts.label_repair_attempts = 1
            out = label_repair.run_repairs(run, ledger, training, by_id, [], label_repair.ontology.load(run.opts.ontology),
                                           GapLedger.for_run(label_repair.paths.GAPS_DIR, run), [], [])
            self.assertEqual(out, {L[5]: ["refused"]})
            self.assertEqual(ledger.entries[L[5]].state, "blocked")
        with repairing(outputs={}) as (run, ledger, training, by_id):
            run.opts.label_repair_budget = 0
            calls = []
            with mock.patch.object(session, "run", stub_session({}, calls)):
                self.assertEqual(label_repair.run_repairs(run, ledger, training, by_id, [], None, None, [], []), {})
            self.assertEqual(calls, [])


class LabelSetV2(Base):
    """A label repair under label contract v2 binds its candidate to the run's label set, and a
    candidate that cannot be bound is a part that did not run, never a charged attempt."""

    def test_a_v2_label_repair_binds_and_commits_its_label_set(self):
        rec = {k: v for k, v in node_rec(N[5]).items() if k != "segmentation"}
        with repairing(RECS_V2, outputs={"record.jsonl": json.dumps(rec), "lean.diff": DIFF5}) as (run, ledger, training, by_id):
            self.assertEqual(run.label_states[L[5]]["outcome"], "mismatch")
            set_verdict(training, "r5a", N[5], "compliant")
            self.assertEqual(repair(run, ledger, training, by_id), "committed")
            want = training.versions()["label_set"]
            st = run.label_states[L[5]]
            self.assertEqual((st["repairs"], st["versions"]["label_set"]), (1, want))
            self.assertEqual(json.loads((run.dir / st["check"]).read_text())["versions"]["label_set"], want)
            self.assertEqual(jsonl.read_json(run.state_file, {})["label_states"][L[5]]["versions"]["label_set"], want)

    def test_a_candidate_that_cannot_be_bound_is_never_charged(self):
        rec = {k: v for k, v in node_rec(N[5]).items() if k != "segmentation"}
        calls = []
        with repairing(RECS_V2, outputs={"record.jsonl": json.dumps(rec), "lean.diff": DIFF5}, calls=calls) as (run, ledger, training, by_id):
            before = dict(run.label_states[L[5]])
            to_user = []
            with mock.patch.object(cand, "EXTERNAL_VERSIONS", ("data", "label_contract", "scoring", "limits")):
                self.assertEqual(repair(run, ledger, training, by_id, to_user), "unavailable")
            st = run.label_states[L[5]]
            self.assertEqual((st.get("repairs", 0), st.get("sessions", 0)), (before.get("repairs", 0), before.get("sessions", 0)))
            self.assertNotIn("last_repair", st)
            self.assertEqual(calls, [])                                  # no session was asked
            self.assertEqual(ledger.entries[L[5]].state, "planned")
            self.assertTrue(any("nothing charged" in x for x in to_user))


class JudgmentCalls(Base):

    def test_a_judgment_call_disagreement_opens_no_session(self):
        recs = [r for r in RECS if r[1] != L[5]] + [("r5j", L[5], "violation", True, {N[5]: [["compliant", {"x": 1}]]}),
                                                     ("r5c", L[5], "compliant", False, {N[5]: [["compliant", {"x": 1}]]})]
        calls = []
        with repairing(recs=recs, calls=calls) as (run, ledger, training, by_id):
            self.assertEqual(run.label_states[L[5]]["outcome"], "aligned")
            self.assertEqual(label_repair.awaiting(run, ledger), [])
            label_repair.run_repairs(run, ledger, training, by_id, [], None, None, [], [])
            self.assertEqual(calls, [])


class SameId(Base):

    def test_accepted_concepts_are_strict(self):
        concepts, nodes = standard()
        concepts[CD] = concept_rec(CD, values=["left"])
        with world(concepts, nodes) as (run, _lib), Txn(run) as txn:
            words = concepts[CA]["contract"].replace("measured", "observed")
            with self.assertRaisesRegex(cand.ChangeRefused, "contract"):
                txn.apply([cand.Change("concept", CA, {**concepts[CA], "contract": words})])
            with self.assertRaisesRegex(cand.ChangeRefused, "args"):
                txn.apply([cand.Change("concept", CD, concept_rec(CD, values=["left", "right"]))])

    def test_an_unaccepted_concept_changes_its_interface_only_with_every_caller(self):
        concepts, nodes = standard()
        X, Y = "drv.motion.cand_x", "drv.motion.cand_y"
        with world(concepts, nodes) as (run, _lib), Txn(run) as txn:
            txn.apply([cand.Change("concept", X, concept_rec(X), files("concept", X)),
                       cand.Change("concept", Y, concept_rec(Y, [X]), files("concept", Y)),
                       cand.Change("node", NN, node_rec(NN, [CB, Y]), files("node", NN))])
            wider = concept_rec(X, values=["left", "right"])
            with self.assertRaisesRegex(cand.ChangeRefused, f"`{NN}`, which calls it"):
                txn.apply([cand.Change("concept", X, wider), cand.Change("concept", Y, concept_rec(Y, [X]))])
            txn.apply([cand.Change("concept", X, wider), cand.Change("concept", Y, concept_rec(Y, [X])),
                       cand.Change("node", NN, node_rec(NN, [CB, Y]))])
            self.assertEqual(txn.view.accepted_concepts[X]["args"][1]["values"], ["left", "right"])

    def test_a_held_caller_cannot_be_updated_in_a_candidate(self):
        concepts, nodes = standard()
        X = "drv.motion.cand_x"
        with world(concepts, nodes) as (run, _lib):
            run.deferred_concepts = [concept_rec(X)]
            run.deferred_nodes = [node_rec("TEST_HELD_1", [X])]
            with Txn(run) as txn:
                with self.assertRaisesRegex(cand.ChangeRefused, "TEST_HELD_1"):
                    txn.apply([cand.Change("concept", X, concept_rec(X, values=["left"]), files("concept", X))])


class Evidence(Base):

    def test_the_review_path_renders_the_upheld_block_as_before(self):
        with world(*standard()) as (run, _lib):
            laws = [corpus.Law(nodeid.law_of(NN)[0], "t", "text", "s")]
            with mock.patch.object(plan.review_phase, "upheld_block", lambda run_, laws_: "SENTINEL-UPHELD\n"):
                self.assertEqual(plan.evidence_block(run, laws), "SENTINEL-UPHELD\n")
                run.opts.feedback = "labels"                       # smoke 1: no node obligation, the empty block as before
                self.assertEqual(plan.evidence_block(run, laws), plan.node_upheld_block(run, {laws[0].id}))
                self.assertIn("(none)", plan.evidence_block(run, laws))
            values = {k: f"({k})" for k in plan.PLACEHOLDERS_NODE_REPAIR}
            values["evidence"] = "SENTINEL-UPHELD"
            text = render.render("node_repair.md", values)
            self.assertIn("\nSENTINEL-UPHELD\n", text)
            self.assertNotIn("{upheld}", text)

    def test_label_repair_shows_the_label_evidence(self):
        with repairing() as (run, ledger, training, by_id):
            run.opts.label_repair = True
            block = plan.evidence_block(run, [by_id[L[5]], by_id[L[1]]])
            self.assertTrue(block.startswith("## Label mismatches"))
            self.assertIn("r5a", block)
            self.assertNotIn("r1j", block)                              # a judgment call never enters it
            with cand.SCHEDULING.pause():
                txn = cand.Candidate.open(run, hooks=())
                try:
                    prompt = label_repair.prompt_for(run, txn, by_id[L[5]], [], label_repair.ontology.load(run.opts.ontology), 0)
                finally:
                    txn.close("test")
            self.assertIn("## Label mismatches", prompt)
            self.assertIn(f"-- {RULE5}", prompt)
            self.assertIn("Repair goal: labelled semantic", prompt)
            for k in plan.PLACEHOLDERS_NODE_REPAIR:
                self.assertNotIn("{" + k + "}", prompt)


def _finding(case, atom, check, entity):
    return {"case": case, "family": "association" if atom.startswith("st.lane") else "declaration", "atom": atom,
            "check": check, "entity": entity}


#: Stored source reports: r5a contradicts its manifest on an atom its unknown reason names and has
#: case i and ii findings; r5b's report was unreadable; r5c, a match, has a finding of its own.
SOURCES = {"r5a": {"findings": [_finding("iii", "st.lane_enters", "intersection_not_entered", "structure"),
                                _finding("iii", "sig.turn_indicator", "field_missing", "subject"),
                                _finding("i", "st.crosswalk", "declared_observed_none_present", "structure"),
                                _finding("ii", "st.highway", "declared_absent", "structure"),
                                _finding("ii", "st.on_way", "declared_absent", "")], "facts": {}},
           "r5b": {"findings": [], "facts": {}, "error": "OSError: unreadable"},
           "r5c": {"findings": [_finding("iii", "kin.speed", "field_missing", "subject")], "facts": {}}}
UNKNOWN_R5A = [(rid, law, lab, jc, {N[5]: [["unknown", {"x": 1}, ["absent_atom:st_lane_enters"]]]} if rid == "r5a" else sp)
               for rid, law, lab, jc, sp in RECS]


class SourceDiagnostics(Base):
    """The label repair session is shown the stored source report of the law's unknown and mismatched
    recordings, its cases apart; a plan session is not, and nothing scored or routed reads it."""

    @contextmanager
    def routed(self, sources):
        with mock.patch.object(label_check.source_check, "ensure", lambda *a, **k: sources), \
                repairing(recs=UNKNOWN_R5A) as world_:
            yield world_

    def repair_prompt(self, run, by_id):
        with cand.SCHEDULING.pause():
            txn = cand.Candidate.open(run, hooks=())
            try:
                return label_repair.prompt_for(run, txn, by_id[L[5]], [], label_repair.ontology.load(run.opts.ontology), 0)
            finally:
                txn.close("test")

    def test_the_repair_prompt_shows_the_cases_apart(self):
        with self.routed(SOURCES) as (run, ledger, training, by_id):
            prompt = self.repair_prompt(run, by_id)
            block = prompt[prompt.index("## Source diagnostics"):prompt.index("## What the coder narrowed")]
            self.assertLess(prompt.index("## Label mismatches"), prompt.index("## Source diagnostics"))
            for words in ("does not show that the adapter is wrong", "no obligation on any rule to change",
                          "infer `st.on_way` from geometry"):
                self.assertIn(words, block)
            r5a = block[block.index("### Recording r5a"):block.index("### Recording r5b")]
            self.assertIn("(status unknown)", r5a)
            self.assertIn("- case iii: `association:st.lane_enters:intersection_not_entered:structure` (its atom is one this "
                          "recording's unknown reasons name;", r5a)
            self.assertIn("- case iii: `declaration:sig.turn_indicator:field_missing:subject`\n", r5a)
            self.assertIn("- case i: 1 finding(s); case ii: 2 finding(s)", r5a)
            r5b = block[block.index("### Recording r5b"):]
            self.assertIn("(status mismatch)", r5b)
            self.assertIn("- unreadable", r5b)
            self.assertNotIn("case iii", r5b)
            self.assertNotIn("r5c", block)                               # a match is not shown
            self.assertNotIn("kin.speed", block)

    def test_a_plan_session_is_never_shown_it(self):
        with self.routed(SOURCES) as (run, ledger, training, by_id):
            run.opts.label_repair, run.opts.dry_run = True, True
            self.assertNotIn("Source diagnostics", plan.evidence_block(run, [by_id[L[5]]]))
            d = plan.run_plan(run, [by_id[L[5]]], [])
            text = (d / "prompt.md").read_text()
            self.assertIn("## Label mismatches", text)
            self.assertNotIn("Source diagnostics", text)
            self.assertNotIn("intersection_not_entered", text)

    def test_no_status_outcome_or_comparison_reads_it(self):
        def outcome(sources):
            with self.routed(sources) as (run, ledger, training, by_id):
                chk = json.loads((run.dir / run.label_states[L[5]]["check"]).read_text())
                evidence = (run.dir / run.label_states[L[5]]["evidence"]).read_text()
                prompt = self.repair_prompt(run, by_id)
                return ({k: chk[k] for k in ("outcome", "coverage", "summary")}, [{k: v for k, v in x.items() if k != "evidence"}
                                                                                for x in chk["scored"]],
                        {k: (v["state"], v["outcome"], v["coverage"]) for k, v in run.label_states.items()},
                        {e.law: e.state for e in ledger.entries.values()}, evidence, prompt)
        clean = {rid: {"findings": [], "facts": {}} for rid, *_ in UNKNOWN_R5A}
        with_, without = outcome(SOURCES), outcome(clean)
        self.assertEqual(with_[:4], without[:4])
        self.assertEqual(with_[2][L[5]][:2], ("awaiting_label_repair", "mismatch"))
        strip = lambda e: re.sub(r"/tmp\S*", "", e)                    # each world lives in its own directory
        self.assertEqual(strip(with_[4]), strip(without[4]))           # the label evidence is the same
        self.assertIn("intersection_not_entered", with_[5])
        self.assertNotIn("intersection_not_entered", without[5])
        self.assertIn("- case iii: none", without[5])


def tree(root: Path) -> dict[str, bytes]:
    return {str(p): p.read_bytes() for p in sorted(root.rglob("*")) if p.is_file() and ".lake" not in p.parts
            and p.name not in ("Index.lean", "TrafficSpecWitness.lean")}


if __name__ == "__main__":
    unittest.main()
