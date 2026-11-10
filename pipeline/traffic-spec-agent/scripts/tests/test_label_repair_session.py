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
from scripts.tests.test_label_repair import L, N, RECS, setting

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

        def fake_plan(view, laws, defs, tag="", pending=None, label_repair=False):
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


class CandidateScope(Base):
    """A coder's SCOPE_VIOLATION inside a label repair's candidate is the coder's, not the repair's: no
    report of it is judged, the candidate is rolled back unpublished, no label repair is counted, the
    record's scope count is kept in the law's ledger entry once per candidate, and the pass ends; a
    later pass codes the same repair output again without a repair session, and the second violation
    holds the law (`scope_budget`). A production file the session changed pauses the run as dirty."""

    @contextmanager
    def scoped(self, prod_file: str | None = None, legacy: bool = False, verdict: str = "SCOPE_VIOLATION", once: bool = False):
        from harness.phases import code as code_phase, review as review_phase
        rec = {k: v for k, v in node_rec(N[5]).items() if k != "segmentation"}
        rec["elements"] = [{"span": "o1", "atoms": ["kin.speed", "rel.occupies"], "derived": []}]
        self.judged, self.coded, self.calls = [], [], []
        outputs = {"record.jsonl": json.dumps(rec), "lean.diff": DIFF5}
        inner = stub_session(outputs, self.calls)

        def repair_session(prompt, cwd=None, out_dir=None, label="session", **k):     # a finished launch leaves its record
            inner(prompt, cwd=cwd, out_dir=out_dir, label=label, **k)
            (Path(cwd) / f"{label}_result.json").write_text(json.dumps({"cost_usd": 0.5}))
        with repairing(outputs=outputs) as (run, ledger, training, by_id), mock.patch.object(session, "run", repair_session):
            prod = label_repair.paths.LIBRARY

            def coding(view, n, reading, registry=None, saved=None):
                task = code_phase.node_dir(view, n.id)
                task.mkdir(parents=True, exist_ok=True)
                (task / "dependency_defect.json").write_text("{}")
                (task / "session_result.json").write_text(json.dumps({"cost_usd": 1.25}))
                with open(run.dir / "usage.jsonl", "a") as fh:
                    fh.write(json.dumps({"label": f"code {n.id}", "cost_usd": 1.25}) + "\n")
                if legacy:                                            # a candidate opened with no per-file digest kept
                    (task.parents[2] / getattr(cand, "PRODUCTION_DIGEST", "production_digest.json")).unlink(missing_ok=True)
                if prod_file and not (once and self.coded):           # relative to the tree that holds the library
                    (prod.parent / prod_file).parent.mkdir(parents=True, exist_ok=True)
                    (prod.parent / prod_file).write_text("-- written into production\n")
                self.coded.append((n.id, task))
                if verdict == "OK":                                   # legal candidate files: the candidate's gate passes
                    for rel, text in files("node", n.id).items():
                        (label_repair.paths.LIBRARY / rel).write_text(text)
                    return gate.Verdict("OK", [])
                return gate.Verdict("SCOPE_VIOLATION", ["changed outside the node's files: ['library/x.lean']"],
                                    extras={"stray": ["library/x.lean"]})
            with mock.patch.object(code_phase, "run_code", coding), \
                    mock.patch.object(loop, "report_of", lambda *a, **k: self.judged.append(a) or review_phase.DependencyReport("none")):
                self.run_, self.ledger, self.prod = run, ledger, prod
                self.args = (training, by_id, [], label_repair.ontology.load(run.opts.ontology),
                             GapLedger.for_run(label_repair.paths.GAPS_DIR, run), [], [])
                yield run, ledger

    def published(self):
        run, ledger = self.run_, self.ledger
        rulings = run.dir / "rulings.jsonl"
        st = run.label_states[L[5]]
        return (tree(self.prod), rulings.read_bytes() if rulings.exists() else None, sorted(run.accepted_nodes), ledger.entries[L[5]].nodes,
                st.get("state"), st.get("reports"), st.get("outcome"))

    def repairs(self):
        return label_repair.run_repairs(self.run_, self.ledger, *self.args)

    def test_a_first_violation_charges_no_repair_keeps_the_spend_and_leaves_the_loop(self):
        with self.scoped() as (run, ledger):
            before, counted = self.published(), int(run.label_states[L[5]].get("repairs", 0))
            self.assertEqual(self.repairs(), {L[5]: ["scope"]})
            self.assertEqual(len(self.calls), 1)                                  # one repair session, no other pass
            self.assertEqual([i for i, _t in self.coded], [N[5]])
            self.assertEqual(self.judged, [])
            self.assertEqual(int(run.label_states[L[5]].get("repairs", 0)), counted)
            self.assertEqual(ledger.entries[L[5]].scope_violations, {L[5]: 1})
            self.assertEqual(ledger.entries[L[5]].state, "planned")
            self.assertTrue(run.label_states[L[5]].get("active"))
            self.assertEqual([json.loads(x)["label"] for x in (run.dir / "usage.jsonl").read_text().splitlines()], [f"code {N[5]}"])
            self.assertTrue((self.coded[0][1] / "session_result.json").exists())
            self.assertEqual(self.published(), before)

    def test_the_same_output_is_coded_again_and_the_bound_holds_the_law(self):
        with self.scoped() as (run, ledger):
            before, counted = self.published(), int(run.label_states[L[5]].get("repairs", 0))
            self.assertEqual(self.repairs(), {L[5]: ["scope"]})
            first = (run.dir / run.label_states[L[5]]["active"]["dir"] / "record.jsonl").read_text()
            self.assertEqual(self.repairs(), {L[5]: ["scope_budget"]})
            self.assertEqual(len(self.calls), 1)                                  # the second coding took up the same output
            self.assertEqual([i for i, _t in self.coded], [N[5], N[5]])
            self.assertNotEqual(self.coded[0][1], self.coded[1][1])               # coded again, in a new candidate
            e = ledger.entries[L[5]]
            self.assertEqual((e.state, e.gaps, e.scope_violations), ("blocked", [f"decision:{L[5]}"], {L[5]: 2}))
            self.assertTrue(e.reasons[0].startswith("scope_budget:"), e.reasons)
            self.assertEqual(int(run.label_states[L[5]].get("repairs", 0)), counted)
            self.assertEqual(self.repairs(), {})                                  # held: no further session
            self.assertEqual((len(self.calls), len(self.coded)), (1, 2))
            self.assertEqual(self.published(), before)
            self.assertTrue(first)

    def test_a_restart_neither_loses_nor_repeats_the_count(self):
        from types import SimpleNamespace
        from harness.store.ledger import Ledger
        with self.scoped() as (run, ledger):
            self.assertEqual(self.repairs(), {L[5]: ["scope"]})
            ledger.save()
            again = Ledger(run.ledger_file, list(L.values()), 2)                  # the ledger as a restart reads it
            self.assertEqual(again.entries[L[5]].scope_violations, {L[5]: 1})
            counted = SimpleNamespace(id=run.label_states[L[5]]["active"]["scope_candidate"],
                                      baseline=cand.production_baseline(run), scope_baseline={})
            self.assertEqual(label_repair.scope_failure(run, again, L[5], counted, [N[5]], []), "scope")
            self.assertEqual(again.entries[L[5]].scope_violations, {L[5]: 1})

    def test_a_production_change_pauses_the_run_until_it_is_restored(self):
        from harness.phases import code as code_phase
        for rel in ("library/TrafficSpec/Rules/Prod.lean", "harness/phases/stray.py", "prompts/stray.md"):
            with self.subTest(rel=rel), self.scoped(prod_file=rel) as (run, ledger):
                self.assertEqual(self.repairs(), {L[5]: ["scope"]})
                self.assertEqual(sorted(f for fs in code_phase.scope_unrestored(run).values() for f in fs), [rel])
                (self.prod.parent / rel).unlink()                                 # the operator restores the one file
                self.assertEqual(code_phase.scope_unrestored(run), {})

    def test_a_production_only_change_behind_a_passing_gate_stops_the_candidate(self):
        """The candidate's files are legal and its gate passes, but the session changed a production
        prompt: no report is judged and nothing more is coded, the candidate is rolled back, no label
        repair is counted, the spend is kept, and the run pauses naming the file; once it is restored the
        repair goes on."""
        from harness.phases import code as code_phase
        rel = "prompts/stray.md"
        with self.scoped(prod_file=rel, verdict="OK", once=True) as (run, ledger):
            before, counted = self.published(), int(run.label_states[L[5]].get("repairs", 0))
            self.assertEqual(self.repairs(), {L[5]: ["scope"]})
            self.assertEqual(self.judged, [])
            self.assertEqual([i for i, _t in self.coded], [N[5]])
            self.assertEqual(int(run.label_states[L[5]].get("repairs", 0)), counted)
            self.assertEqual(ledger.entries[L[5]].scope_violations, {L[5]: 1})
            self.assertEqual([json.loads(x)["label"] for x in (run.dir / "usage.jsonl").read_text().splitlines()], [f"code {N[5]}"])
            self.assertEqual(self.published(), before)
            self.assertEqual([f for fs in code_phase.scope_unrestored(run).values() for f in fs], [rel])
            self.assertEqual(self.repairs(), {})                                  # paused: no repair starts on the dirty tree
            (self.prod.parent / rel).unlink()                                     # until the operator restores the file
            self.assertEqual(code_phase.scope_unrestored(run), {})
            self.assertNotIn("scope", self.repairs().get(L[5], []))              # the repair goes on: coded again, its report judged
            self.assertGreaterEqual(len(self.coded), 2)
            self.assertTrue(self.judged)

    def test_a_production_change_found_only_at_the_commit_still_pauses(self):
        """No coder runs (the repair's change is local) and no session moves production, but the tree
        moves before the commit (here, during the candidate's verification): the commit refuses it as
        before, and the outcome is a scope outcome: no label repair counted, the law's scope count 1,
        and the run pauses naming the file until it is restored."""
        from harness.phases import code as code_phase
        rec = {k: v for k, v in node_rec(N[5]).items() if k != "segmentation"}
        rel = "prompts/stray.md"
        with repairing(outputs={"record.jsonl": json.dumps(rec), "lean.diff": DIFF5}) as (run, ledger, training, by_id):
            prod = label_repair.paths.LIBRARY.parent
            real_verify = cand.Candidate.verify

            def verify(txn, *a, **k):
                results = real_verify(txn, *a, **k)
                (prod / rel).parent.mkdir(parents=True, exist_ok=True)
                (prod / rel).write_text("-- written into production\n")
                return results
            set_verdict(training, "r5a", N[5], "compliant")
            counted = int(run.label_states[L[5]].get("repairs", 0))
            to_user = []
            with mock.patch.object(cand.Candidate, "verify", verify):
                self.assertEqual(repair(run, ledger, training, by_id, to_user), "scope")
            self.assertTrue(any("production baseline moved" in x for x in to_user), to_user)
            self.assertEqual(int(run.label_states[L[5]].get("repairs", 0)), counted)
            self.assertEqual(ledger.entries[L[5]].scope_violations, {L[5]: 1})
            self.assertEqual([f for fs in code_phase.scope_unrestored(run).values() for f in fs], [rel])
            (prod / rel).unlink()
            self.assertEqual(code_phase.scope_unrestored(run), {})

    def test_a_moved_tree_that_cannot_be_named_still_pauses(self):
        """A candidate that kept no per-file digest (opened before it was kept): the moved tree is
        recorded whole and pauses until the whole tree is back at the hash the candidate opened on."""
        from harness.phases import code as code_phase
        rel = "harness/phases/stray.py"
        with self.scoped(prod_file=rel, legacy=True) as (run, ledger):
            self.assertEqual(self.repairs(), {L[5]: ["scope"]})
            self.assertTrue(code_phase.scope_unrestored(run))
            self.assertEqual([f for fs in code_phase.scope_unrestored(run).values() for f in fs], [code_phase.WHOLE_TREE])
            (self.prod.parent / rel).unlink()                                     # the tree restored to its recorded hash
            self.assertEqual(code_phase.scope_unrestored(run), {})


class CandidateSessionsWatched(Base):
    """Every session a label repair's candidate runs (the repair session and its re-ask, a re-plan, a
    concept repair) is followed by the production tree check: a session that changed a production file
    stops the candidate at once (no further session, judgement or coding), rolls it back, counts no
    label repair, keeps its spend, counts the law's scope once, and pauses the run naming the file; once
    it is restored, the repair goes on."""

    REL = "prompts/stray.md"

    @contextmanager
    def watched(self, outputs: dict, writes, concepts=None, coder_out=None):
        """`writes(cwd, label)` says which session writes the production file (once); `coder_out(n)` what
        the n-th coding (from 1) returns."""
        self.calls, self.coded, self.wrote, self.drained = [], [], [], []
        inner = stub_session(outputs)
        with repairing(outputs={}, concepts=concepts) as (run, ledger, training, by_id):
            prod = label_repair.paths.LIBRARY.parent

            def any_session(prompt, cwd=None, out_dir=None, label="session", **k):
                inner(prompt, cwd=cwd, out_dir=out_dir, label=label, **k)
                (Path(cwd) / f"{label}_result.json").write_text(json.dumps({"cost_usd": 0.5}))
                with open(run.dir / "usage.jsonl", "a") as fh:
                    fh.write(json.dumps({"label": f"{Path(cwd).name} {label}", "cost_usd": 0.5}) + "\n")
                self.calls.append((Path(cwd).name, label))
                self.drained.append(cand.SCHEDULING.drained())
                if not self.wrote and writes(Path(cwd), label):
                    self.wrote.append(label)
                    (prod / self.REL).parent.mkdir(parents=True, exist_ok=True)
                    (prod / self.REL).write_text("-- written into production\n")

            def coder(txn, recs, law=None, earlier=None):
                self.coded.append(recs)
                return coder_out(len(self.coded), recs) if coder_out else {}
            with mock.patch.object(session, "run", any_session), mock.patch.object(label_repair, "code_in_candidate", coder):
                self.prod = prod
                yield run, ledger, training, by_id

    def stopped(self, run, ledger, outcome, counted):
        from harness.phases import code as code_phase
        self.assertEqual(outcome, "scope")
        self.assertEqual(int(run.label_states[L[5]].get("repairs", 0)), counted)
        self.assertEqual(ledger.entries[L[5]].scope_violations, {L[5]: 1})
        self.assertEqual(len((run.dir / "usage.jsonl").read_text().splitlines()), len(self.calls))   # every session's spend kept
        self.assertEqual([f for fs in code_phase.scope_unrestored(run).values() for f in fs], [self.REL])
        (self.prod / self.REL).unlink()
        self.assertEqual(code_phase.scope_unrestored(run), {})

    def test_a_planner_that_changes_production_stops_the_candidate(self):
        withdraw = {"node_id": N[5], "withdraw": {"kind": "plan", "missing": "the law carries two duties"}}

        def fake_plan(view, laws, defs, tag="", pending=None, label_repair=False):
            d = view.iter / "plan" / tag
            d.mkdir(parents=True, exist_ok=True)
            session.run("plan", cwd=d, out_dir=d, label="session")
            (d / "blueprint.jsonl").write_text(json.dumps(node_rec(f"{N[5]}_o1") | {"law_refs": [L[5]]}) + "\n")
            return d
        with self.watched({"record.jsonl": json.dumps(withdraw)}, lambda cwd, label: "plan" in cwd.parts) as (run, ledger, training, by_id), \
                mock.patch.object(plan, "run_plan", fake_plan):
            counted = int(run.label_states[L[5]].get("repairs", 0))
            r = repair(run, ledger, training, by_id)
            self.assertEqual(self.coded, [])                                      # nothing coded after the planner
            self.assertEqual([c[1] for c in self.calls], ["session", "session"])   # the repair session, then the plan
            self.stopped(run, ledger, r, counted)
            self.assertNotEqual(repair(run, ledger, training, by_id), "scope")    # restored: the repair goes on
            self.assertTrue(self.coded)

    def test_a_concept_repair_that_changes_production_stops_the_candidate(self):
        from harness.phases import review as review_phase
        report = {"node_id": N[5], "withdraw": {"kind": "concept", "missing": "the concept computes what its contract excludes"}}

        def fake_repair(view, rec, reasons, last_task, defs, users):
            d = view.iter / "repair" / ("concept__" + rec.id)
            d.mkdir(parents=True, exist_ok=True)
            session.run("repair", cwd=d, out_dir=d, label="session")
            return d
        judged = []
        with self.watched({"record.jsonl": json.dumps(report), "dependency_defect.json": "{}"},
                          lambda cwd, label: cwd.name.startswith("concept__"), concepts={CA: concept_rec(CA)}) as (run, ledger, training, by_id), \
                mock.patch.object(plan, "run_repair", fake_repair), \
                mock.patch.object(label_repair, "judge_report",
                                  lambda *a, **k: judged.append(a) or review_phase.DependencyReport("upheld", concept=CA, line="scripted")):
            counted = int(run.label_states[L[5]].get("repairs", 0))
            r = repair(run, ledger, training, by_id)
            self.assertEqual(self.coded, [])
            self.assertEqual(len(judged), 1)                                      # the one before the concept repair
            self.stopped(run, ledger, r, counted)

    def test_a_repair_session_re_asked_that_changes_production_stops_the_candidate_and_is_asked_anew(self):
        with self.watched({}, lambda cwd, label: label == "session_again") as (run, ledger, training, by_id):
            counted = int(run.label_states[L[5]].get("repairs", 0))
            r = repair(run, ledger, training, by_id)
            self.assertEqual([c[1] for c in self.calls], ["session", "session_again"])
            self.assertEqual(self.coded, [])
            self.stopped(run, ledger, r, counted)
            # restored: the out-of-scope answer is kept on disk, never read again; a new session is asked in a new directory
            old = run.dir / "iter-001" / "label_repair" / L[5] / "repair-01"
            self.assertTrue((old / "session_again_result.json").exists())
            self.assertEqual(repair(run, ledger, training, by_id), "refused")
            self.assertEqual(self.calls[2:], [("repair-02", "session"), ("repair-02", "session_again")])
            self.assertEqual(self.drained, [[]] * len(self.calls))                 # every session ran while scheduling was drained

    def test_the_answer_of_a_repair_session_that_went_out_of_scope_is_never_read(self):
        rec = {k: v for k, v in node_rec(N[5]).items() if k != "segmentation"}
        rec["elements"] = [{"span": "o1", "atoms": ["kin.speed", "rel.occupies"], "derived": []}]
        with self.watched({"record.jsonl": json.dumps(rec), "lean.diff": DIFF5},
                          lambda cwd, label: label == "session") as (run, ledger, training, by_id):
            counted = int(run.label_states[L[5]].get("repairs", 0))
            r = repair(run, ledger, training, by_id)
            self.assertEqual(self.coded, [])                                      # its answer was not read
            self.stopped(run, ledger, r, counted)
            self.assertFalse(run.label_states[L[5]].get("active"))
            repair(run, ledger, training, by_id)
            self.assertEqual([c for c in self.calls if c[1] == "session"], [("repair-01", "session"), ("repair-02", "session")])
            self.assertEqual(self.coded, [[("node", N[5])]])                       # the new answer is the one coded

    def test_one_scope_count_per_law_a_coder_then_a_planner_reach_the_bound(self):
        withdraw = {"node_id": N[5], "withdraw": {"kind": "plan", "missing": "the law carries two duties"}}
        plans = []

        def fake_plan(view, laws, defs, tag="", pending=None, label_repair=False):
            d = view.iter / "plan" / tag
            d.mkdir(parents=True, exist_ok=True)
            plans.append(d)
            session.run("plan", cwd=d, out_dir=d, label="session")
            (d / "blueprint.jsonl").write_text(json.dumps(node_rec(f"{N[5]}_o1") | {"law_refs": [L[5]]}) + "\n")
            return d
        with self.watched({"record.jsonl": json.dumps(withdraw)}, lambda cwd, label: "plan" in cwd.parts and len(plans) == 2,
                          coder_out=lambda n, recs: {i: {"verdict": "SCOPE_VIOLATION"} for _k, i in recs} if n == 1 else {}) \
                as (run, ledger, training, by_id), mock.patch.object(plan, "run_plan", fake_plan):
            self.assertEqual(repair(run, ledger, training, by_id), "scope")       # the coder went out of scope
            self.assertEqual(ledger.entries[L[5]].scope_violations, {L[5]: 1})
            self.assertEqual(repair(run, ledger, training, by_id), "scope_budget")   # then the planner: the law's second
            e = ledger.entries[L[5]]
            self.assertEqual((e.state, e.gaps, e.scope_violations), ("blocked", [f"decision:{L[5]}"], {L[5]: 2}))
            self.assertEqual([c for c in self.calls if c[1] == "session" and c[0].startswith("repair-")], [("repair-01", "session")])

    def test_a_trusted_repair_answer_is_coded_again_after_a_coder_went_out_of_scope(self):
        rec = {k: v for k, v in node_rec(N[5]).items() if k != "segmentation"}
        rec["elements"] = [{"span": "o1", "atoms": ["kin.speed", "rel.occupies"], "derived": []}]
        with self.watched({"record.jsonl": json.dumps(rec), "lean.diff": DIFF5}, lambda cwd, label: False,
                          coder_out=lambda n, recs: {i: {"verdict": "SCOPE_VIOLATION"} for _k, i in recs} if n == 1 else {}) \
                as (run, ledger, training, by_id):
            self.assertEqual(repair(run, ledger, training, by_id), "scope")
            self.assertTrue(run.label_states[L[5]].get("active"))
            repair(run, ledger, training, by_id)
            self.assertEqual(self.calls, [("repair-01", "session")])               # no new repair session
            self.assertEqual(self.coded, [[("node", N[5])], [("node", N[5])]])     # the same answer coded again

    def test_a_candidate_that_went_out_of_scope_files_no_change_request_or_gap(self):
        rec = {k: v for k, v in node_rec(N[5]).items() if k != "segmentation"}
        rec["elements"] = [{"span": "o1", "atoms": ["kin.speed", "rel.occupies"], "derived": []}]
        outputs = {"record.jsonl": json.dumps(rec), "lean.diff": DIFF5, "change_request.json": json.dumps([REQUEST])}
        with self.watched(outputs, lambda cwd, label: False,
                          coder_out=lambda n, recs: {i: {"verdict": "SCOPE_VIOLATION"} for _k, i in recs}) as (run, ledger, training, by_id):
            self.assertEqual(repair(run, ledger, training, by_id), "scope")
            self.assertFalse((run.dir / label_repair.OUTER_FILE).exists())
            self.assertFalse((run.dir / label_repair.OPERATOR_FILE).exists())
            self.assertEqual(ledger.entries[L[5]].state, "planned")


class ProductionWatch(unittest.TestCase):
    """`production_watch` swaps `session.run` for the block only, restores it however the block ends,
    checks the production tree after a session that raised too, and refuses to run unless scheduling is
    drained (the assumption a merge must keep)."""

    def setUp(self):
        from types import SimpleNamespace
        self.tree = {"library/a.lean": "1"}
        self.txn = SimpleNamespace(baseline={"tree": cand._sha(dict(self.tree))}, scheduling=SimpleNamespace(drained=lambda: []))
        p = mock.patch.object(label_repair.gate, "repo_digest", lambda root=None: dict(self.tree))
        p.start()
        self.addCleanup(p.stop)

    def test_restored_on_a_normal_and_an_exceptional_exit(self):
        real = session.run
        with label_repair.production_watch(self.txn, L[5]):
            self.assertIsNot(session.run, real)
        self.assertIs(session.run, real)
        with self.assertRaises(KeyError), label_repair.production_watch(self.txn, L[5]):
            raise KeyError("stopped")
        self.assertIs(session.run, real)

    def test_a_session_that_raises_is_checked_too(self):
        def failing(*a, **k):
            self.tree["prompts/x.md"] = "2"
            raise session.SessionUnavailable("cut off")
        with mock.patch.object(session, "run", failing):
            with self.assertRaises(label_repair.OutOfScope) as e, label_repair.production_watch(self.txn, L[5]):
                session.run("p", cwd="/x/repair-01", out_dir="/x/repair-01")
            self.assertIsInstance(e.exception.__cause__, session.SessionUnavailable)
        self.tree.pop("prompts/x.md")
        with mock.patch.object(session, "run", mock.Mock(side_effect=session.SessionUnavailable("cut off"))):
            with self.assertRaises(session.SessionUnavailable), label_repair.production_watch(self.txn, L[5]):
                session.run("p")                                      # nothing moved: the session's own failure stands

    def test_it_runs_only_while_scheduling_is_drained(self):
        from types import SimpleNamespace
        real = session.run
        busy = SimpleNamespace(baseline=self.txn.baseline, scheduling=SimpleNamespace(drained=lambda: ["a coding task runs"]))
        with self.assertRaises(cand.NotDrained), label_repair.production_watch(busy, L[5]):
            pass
        self.assertIs(session.run, real)


class Binding(Base):
    """A candidate that cannot be bound to the run's label versions is a part that did not run, never
    a charged attempt."""

    def test_a_candidate_that_cannot_be_bound_is_never_charged(self):
        rec = {k: v for k, v in node_rec(N[5]).items() if k != "segmentation"}
        calls = []
        with repairing(RECS, outputs={"record.jsonl": json.dumps(rec), "lean.diff": DIFF5}, calls=calls) as (run, ledger, training, by_id):
            before = dict(run.label_states[L[5]])
            to_user = []
            with mock.patch.object(cand, "LABEL_VERSIONS", ("data", "label_contract", "scoring")):
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

    def test_a_session_that_is_no_label_repair_renders_the_neutral_block(self):
        with world(*standard()) as (run, _lib):
            laws = [corpus.Law(nodeid.law_of(NN)[0], "t", "text", "s")]
            self.assertEqual(plan.evidence_block(run, laws), plan.NO_LABEL_EVIDENCE)
            run.opts.label_repair = True                           # the run's option gives the session no label scope
            self.assertEqual(plan.evidence_block(run, laws), plan.NO_LABEL_EVIDENCE)
            values = {k: f"({k})" for k in plan.PLACEHOLDERS_NODE_REPAIR}
            values["evidence"] = "SENTINEL-EVIDENCE"
            text = render.render("node_repair.md", values)
            self.assertIn("\nSENTINEL-EVIDENCE\n", text)
            self.assertNotIn("{upheld}", text)

    def test_label_repair_shows_the_label_evidence(self):
        with repairing() as (run, ledger, training, by_id):
            run.opts.label_repair = True
            self.assertEqual(plan.evidence_block(run, [by_id[L[5]], by_id[L[1]]]), plan.NO_LABEL_EVIDENCE)   # the option gives no scope
            block = plan.evidence_block(run, [by_id[L[5]], by_id[L[1]]], label_repair=True)
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
            self.assertNotIn("Source diagnostics", plan.evidence_block(run, [by_id[L[5]]], label_repair=True))
            d = plan.run_plan(run, [by_id[L[5]]], [], label_repair=True)
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


class PromptScope(unittest.TestCase):
    """Which sessions are shown label evidence is decided by the entry point, never by the run's
    `label_repair` option: a gate-returned node repair and an ordinary plan batch of a labels run are
    shown the neutral `## Repair evidence` block; only a law-level label repair (its session and its
    re-plan) is shown `## Label mismatches`, with the label contract and the repair goal. No prompt a
    labels run renders carries the old node review's wording."""

    OLD = ("behaviour review", "upheld by the excuse judge", "Situations decided against earlier records", "Under review feedback")

    @contextmanager
    def labels_run(self):
        from dataclasses import replace
        with repairing() as (run, ledger, training, by_id):
            run.opts = replace(run.opts, label_repair=True, dry_run=True)
            run.law_entries = ledger.entries
            self.assertEqual(run.label_states[L[5]]["state"], "awaiting_label_repair")     # a law of the run awaits its repair
            yield run, ledger, training, by_id

    def node_repair_prompt(self, run, by_id) -> str:
        import tempfile
        from harness.model import ontology
        from harness.model.blueprint import Node
        from harness.model.reading import Reading
        with tempfile.TemporaryDirectory() as last:
            d = plan.run_node_repair(run, Node(run.all_nodes()[N[5]]), ["gate CHECK_FAIL: a witness fails"], Path(last), by_id[L[5]],
                                     [], [], Reading(run.reading_file), ontology.load(run.opts.ontology))
        return (d / "prompt.md").read_text(encoding="utf-8")

    def label_repair_prompt(self, run, by_id) -> str:
        with cand.SCHEDULING.pause():
            txn = cand.Candidate.open(run, hooks=())
            try:
                return (label_repair.prompt_for(run, txn, by_id[L[5]], [], label_repair.ontology.load(run.opts.ontology), 0)
                        + label_repair.where_to_write(run.dir / "x", txn))
            finally:
                txn.close("test")

    def code_prompt(self, run) -> str:
        from harness.model.blueprint import Node
        from harness.model.reading import Reading
        from harness.phases import code as code_phase
        n = Node(run.all_nodes()[N[5]])
        code_phase.run_code(run, n, Reading(run.reading_file))
        return (code_phase.node_dir(run, n.id) / "prompt.md").read_text(encoding="utf-8")

    def test_a_gate_returned_node_repair_is_shown_the_neutral_block(self):
        with self.labels_run() as (run, _ledger, _training, by_id):
            text = self.node_repair_prompt(run, by_id)
            self.assertIn("\n" + plan.NO_LABEL_EVIDENCE, text)
            self.assertNotIn("## Label mismatches", text)

    def test_a_plan_batch_with_no_awaiting_law_is_shown_the_neutral_block(self):
        with self.labels_run() as (run, _ledger, _training, by_id):
            for laws in ([by_id[L[1]]], [by_id[L[5]]]):               # a law awaiting its repair gives an ordinary batch no scope
                text = (plan.run_plan(run, laws, [], tag=f"t-{laws[0].id}") / "prompt.md").read_text(encoding="utf-8")
                self.assertIn("\n" + plan.NO_LABEL_EVIDENCE, text)
                self.assertNotIn("## Label mismatches", text)

    def test_a_law_level_label_repair_is_shown_its_label_evidence(self):
        with self.labels_run() as (run, _ledger, _training, by_id):
            for text in (self.label_repair_prompt(run, by_id),
                         (plan.run_plan(run, [by_id[L[5]]], [], tag="replan", label_repair=True) / "prompt.md").read_text(encoding="utf-8")):
                self.assertIn("## Label mismatches", text)
                self.assertIn("Label contract: a label judges", text)
                self.assertIn("Repair goal:", text)
                self.assertNotIn(plan.NO_LABEL_EVIDENCE, text)
            self.assertIn("during a law-level label repair: `record.jsonl`", self.label_repair_prompt(run, by_id))

    def test_every_planning_and_coding_prompt_carries_the_concept_interface(self):
        """What a caller can state about a concept is part of the concept language every session that
        plans, repairs or codes a record is shown, once."""
        import tempfile
        from harness.lean import surface
        from harness.model.blueprint import ConceptRecord
        from harness.model.reading import Reading
        from harness.phases import code as code_phase
        with self.labels_run() as (run, _ledger, _training, by_id):
            rec = ConceptRecord(concept_rec("drv.motion.interface_probe"))
            with tempfile.TemporaryDirectory() as last:
                concept_repair = (plan.run_repair(run, rec, ["gate CHECK_FAIL: a witness fails"], Path(last), [], []) / "prompt.md").read_text(encoding="utf-8")
            code_phase.run_code_concept(run, rec, Reading(run.reading_file))
            prompts = {"plan": (plan.run_plan(run, [by_id[L[1]]], [], tag="plain") / "prompt.md").read_text(encoding="utf-8"),
                       "replan": (plan.run_plan(run, [by_id[L[5]]], [], tag="replan", label_repair=True) / "prompt.md").read_text(encoding="utf-8"),
                       "concept_repair": concept_repair, "node_repair": self.node_repair_prompt(run, by_id),
                       "label_repair": self.label_repair_prompt(run, by_id), "code": self.code_prompt(run),
                       "code_concept": (code_phase.concept_dir(run, rec.id) / "prompt.md").read_text(encoding="utf-8")}
        for name, text in prompts.items():
            self.assertEqual(text.count(surface.CONCEPT_INTERFACE), 1, name)

    def test_the_plan_prompt_describes_the_library_summary_it_shows(self):
        """The planning prompts describe the library summary as rendered: published and planned nodes,
        with the build availability and the law state as two columns, and a row not composable."""
        with self.labels_run() as (run, _ledger, _training, by_id):
            prompts = {"plan": (plan.run_plan(run, [by_id[L[1]]], [], tag="plain") / "prompt.md").read_text(encoding="utf-8"),
                       "replan": (plan.run_plan(run, [by_id[L[5]]], [], tag="replan", label_repair=True) / "prompt.md").read_text(encoding="utf-8")}
        for name, text in prompts.items():
            self.assertEqual(text.count("**Library summary** — published and currently planned nodes"), 1, name)
            self.assertIn("“not composable” is not\n  a usable build dependency", text, name)
            self.assertNotIn("**Library summary** — accepted nodes", text, name)
            self.assertIn("| node | law | binders | atoms claimed | build | law state |", text, name)

    def test_no_prompt_of_a_labels_run_carries_the_old_node_review_wording(self):
        with self.labels_run() as (run, _ledger, _training, by_id):
            prompts = {"plan": (plan.run_plan(run, [by_id[L[1]]], [], tag="plain") / "prompt.md").read_text(encoding="utf-8"),
                       "replan": (plan.run_plan(run, [by_id[L[5]]], [], tag="replan", label_repair=True) / "prompt.md").read_text(encoding="utf-8"),
                       "code": self.code_prompt(run), "node_repair": self.node_repair_prompt(run, by_id),
                       "label_repair": self.label_repair_prompt(run, by_id)}
            for name, text in prompts.items():
                for words in self.OLD:
                    self.assertNotIn(words.lower(), text.lower(), f"{name}: {words}")


if __name__ == "__main__":
    unittest.main()
