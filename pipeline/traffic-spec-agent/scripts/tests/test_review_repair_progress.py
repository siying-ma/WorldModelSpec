"""The review repair of a labels stage driven by the label repairs' own pass (`label_repair.run_repairs`
with the loop's progress and its commit), law by law: a finding's review repair first, then, once the
review allows the law, its label repair. A kept review repair commits the loop's progress (the
operator's lines and the gaps filed so far) in its candidate's snapshot, so a stop past its commit
point resumes with no line, gap, spend or committed result lost and nothing said or asked twice.

The world is the review stage's tests' (`test_behaviour_review_stage.labelled`, with a second law
awaiting its label repair): the library, the candidate, the snapshot, the journal, the ledger, the
routing, the label check and the gap ledger are the real ones; the reviewer is the scripted stand-in,
and the review and label repair sessions are scripted."""
import json
import re
import unittest
from contextlib import contextmanager
from pathlib import Path
from unittest import mock

from harness.agents import session
from harness.phases import behaviour_review as br
from harness.phases import candidate as cand
from harness.phases import label_repair
from harness.store import budget, jsonl, paths
from harness.store.gaps import GapLedger
from harness.store.ledger import ConceptLedger, Ledger, NodeLedger
from harness.store.state import Run, commit_state, prog_paths
from scripts.tests import fake_reviewer
from scripts.tests.test_behaviour_review_stage import Crash, both, files, finds, on_mark, passes, rec5, review, script, stage
from scripts.tests.test_candidate import Base, node_rec
from scripts.tests.test_label_repair import L, N, RECS, spec
from scripts.tests.test_label_repair_session import RULE5, repairing

#: L-3 disagrees with one of its labels as well: it awaits its label repair beside L-5.
RECS3 = RECS + [("r3b", L[3], "violation", False, spec(N[3], "compliant"))]
#: L-3's label repair withdraws a span for want of an atom: a gap is filed and the law blocked, nothing committed.
#: L-5's label repair answers on the rule as its review repair left it (mark v2).
DIFF5_V3 = f"--- {RULE5}\n+++ {RULE5}\n@@ -3 +3 @@\n--- v2\n+-- v3\n"
GAP3 = json.dumps({"node_id": N[3], "withdraw": {"kind": "atom", "span": "o1", "missing": "a lamp state", "nearest": []}})
REPAIR_LABEL = "/review/repair"
CAND_ID = re.compile(r"\d{8}-\d{6}-[0-9a-f]{6}")


def label_sessions(run, label=None, cwd=None, out_dir=None, **_k):
    """Each label repair session's answer, by its law: L-3 withdraws a span, L-5 rewrites its rule."""
    parts = Path(cwd).parts
    if "label_repair" not in parts:
        return
    out = {"record.jsonl": GAP3} if L[3] in parts else {"record.jsonl": rec5(), "lean.diff": DIFF5_V3}
    for name, text in out.items():
        (Path(cwd) / name).write_text(text, encoding="utf-8")


def paid_fix5(run_, txn, law, evidence):
    """The review repair session: its spend recorded as any session's, then L-5's rule rewritten."""
    jsonl.append_atomic(br.usage_file(run_), budget.usage_row(f"{run_.opts.run_id}{REPAIR_LABEL}/{law}", "anthropic", "claude-test",
                                                              None, {"input_tokens": 10, "output_tokens": 5}, 0.25))
    return [cand.Change("node", N[5], node_rec(N[5]), files("node", N[5], "v2"))]


def asked_again(*a, **k):
    raise AssertionError("the review repair session was asked again")


def repair_spend(run) -> list[float]:
    return [r["cost_usd"] for r in jsonl.read_strict(br.usage_file(run)) if REPAIR_LABEL in str(r.get("label", ""))]


def normal(lines: list[str]) -> list[str]:
    return [CAND_ID.sub("<candidate>", x) for x in lines]


@contextmanager
def two_repairs():
    """L-3 awaiting its label repair (reviewed), L-5 with a finding and a label mismatch; the loop's
    progress and its commit as the labels stage has them."""
    fake = fake_reviewer.install()
    with repairing(recs=RECS3) as (run, ledger, training, by_id):
        stage(run, "labels")
        prog = {"to_user": ["`earlier`: a line the iteration said before its repairs"], "gaps_filed": [], "notes": []}
        persist = lambda: commit_state(run, ledger, ConceptLedger(run.concept_ledger_file, 3), NodeLedger(run.node_ledger_file, 2), prog)
        for law in (L[1], L[2], L[3], L[5]):
            script(fake, law, both())
            assert review(run, ledger, law, persist) == "reviewed", law
        fake.cells[L[5]] = on_mark(N[5], finds, passes)
        assert review(run, ledger, L[5], persist) == "finding"
        with mock.patch.object(session, "run", label_sessions):
            yield run, ledger, training, by_id, prog, persist


def repairs(run, ledger, training, by_id, prog, persist):
    return label_repair.run_repairs(run, ledger, training, by_id, [], label_repair.ontology.load(run.opts.ontology),
                                    GapLedger.for_run(paths.GAPS_DIR, run), prog["gaps_filed"], prog["to_user"], prog, persist=persist)


class ReviewThenLabel(Base):

    def reference(self) -> tuple[dict, list[str], list[dict], list[float], dict]:
        """The pass uninterrupted: what it returns, says, files and spends, and the snapshot it leaves."""
        with two_repairs() as (run, ledger, training, by_id, prog, persist), mock.patch.object(br, "REPAIR_SESSION", paid_fix5):
            self.assertEqual(br.work(run, ledger)["repair"], [L[5]])
            self.assertEqual(label_repair.awaiting(run, ledger), [L[3]])          # L-5's label repair waits for its review
            out = repairs(run, ledger, training, by_id, prog, persist)
            persist()
            return out, list(prog["to_user"]), list(prog["gaps_filed"]), repair_spend(run), jsonl.read_json(run.state_file, {})

    def test_per_law_review_repair_first_then_its_label_repair(self):
        out, said, gaps, spend, snap = self.reference()
        self.assertEqual(out[L[3]], ["gap"])
        self.assertEqual(out[L[5]][0], "review:committed")                           # its review first ...
        labels = out[L[5]][1:]                                                       # ... then its label repairs, in the same pass
        self.assertTrue(labels and not any(x.startswith("review:") for x in labels))
        self.assertEqual(snap["review_states"][L[5]]["repairs"], 1)                  # each repair on its own counter
        self.assertEqual(snap["label_states"][L[5]]["repairs"], len(labels))
        self.assertEqual(len(gaps), 1)
        self.assertEqual(spend, [0.25])
        self.assertEqual(said.count(f"`{L[5]}`: review repair committed"), 1)
        self.assertLess(said.index(f"`{L[5]}`: review repair committed"),
                        min(i for i, x in enumerate(said) if x.startswith(f"`{L[5]}`: label repair")))

    def test_without_persist_no_review_repair_starts(self):
        with two_repairs() as (run, ledger, training, by_id, prog, persist), mock.patch.object(br, "REPAIR_SESSION", asked_again):
            out = label_repair.run_repairs(run, ledger, training, by_id, [], label_repair.ontology.load(run.opts.ontology),
                                           GapLedger.for_run(paths.GAPS_DIR, run), prog["gaps_filed"], prog["to_user"], prog)
            self.assertEqual(list(out), [L[3]])
            self.assertEqual(br.own_status(run, ledger, L[5])["class"], "finding")

    def test_a_stop_past_the_review_repairs_commit_point_loses_nothing(self):
        """L-3's label repair files a gap (in memory: no commit of its own), then L-5's review repair
        commits and the process stops past the commit point, before anything else is persisted. The
        next owner completes the commit; the snapshot holds every line said so far, the gap, the
        review repair's count and credential; resumed, the pass asks no session again, runs L-5's
        label repair, and ends with exactly the lines, gaps and spend of the uninterrupted pass."""
        ref_out, ref_said, ref_gaps, ref_spend, ref_snap = self.reference()
        commit_line = f"`{L[5]}`: review repair committed"
        with two_repairs() as (run, ledger, training, by_id, prog, persist):
            real, seen = cand._apply, {"n": 0}

            def stop_once(journal, f, run_=None):
                if run_ is not None and seen["n"] == 0:
                    seen["n"] += 1
                    raise Crash()
                return real(journal, f, run_)
            with mock.patch.object(br, "REPAIR_SESSION", paid_fix5), mock.patch.object(cand, "_apply", stop_once):
                with self.assertRaises(Crash):
                    repairs(run, ledger, training, by_id, prog, persist)
            cand._OPEN.clear()
            self.assertIsNotNone(cand.recover_pending())                              # the next owner completes the commit

            fresh = Run(run.opts); snap = fresh.restore_state(); fresh.load_accepted()
            led = Ledger(run.ledger_file, list(L.values()), 2)
            fresh.law_entries = led.entries
            saved = prog_paths(snap["prog"], paths.local)
            cut = ref_said.index(commit_line) + 1
            self.assertEqual(normal(saved["to_user"]), normal(ref_said[:cut]))       # every line said up to the commit
            self.assertEqual(saved["gaps_filed"], ref_gaps)                           # L-3's gap, filed before the commit
            self.assertEqual(led.entries[L[3]].state, "blocked")
            st = snap["review_states"][L[5]]
            self.assertEqual((st["repairs"], st.get("active_repair")), (1, None))
            s = br.own_status(fresh, led, L[5])
            self.assertEqual((s["ok"], s["class"]), (True, "reviewed"))
            self.assertEqual(st["certificate"]["row"], br.row_sha(s["row"]))
            self.assertEqual(repair_spend(fresh), [0.25])                             # its spend kept, once

            resumed = {"to_user": saved["to_user"], "gaps_filed": saved["gaps_filed"], "notes": saved.get("notes", [])}
            persist2 = lambda: commit_state(fresh, led, ConceptLedger(fresh.concept_ledger_file, 3),
                                            NodeLedger(fresh.node_ledger_file, 2), resumed)
            with mock.patch.object(br, "REPAIR_SESSION", asked_again):
                out = repairs(fresh, led, training, by_id, resumed, persist2)
            persist2()
            self.assertEqual(list(out), [L[5]])                                       # no review repair again, L-3 not again
            self.assertEqual(out[L[5]], ref_out[L[5]][1:])                            # the label repair that followed it
            self.assertEqual(normal(resumed["to_user"]), normal(ref_said))            # line for line, none twice
            self.assertEqual(resumed["gaps_filed"], ref_gaps)
            self.assertEqual(repair_spend(fresh), ref_spend)
            end = jsonl.read_json(fresh.state_file, {})
            self.assertEqual(end["review_states"][L[5]]["repairs"], ref_snap["review_states"][L[5]]["repairs"])
            self.assertEqual(end["label_states"][L[5]]["repairs"], ref_snap["label_states"][L[5]]["repairs"])
            self.assertEqual({l: e["state"] for l, e in ((d["law"], d) for d in end["ledger"])},
                             {l: e["state"] for l, e in ((d["law"], d) for d in ref_snap["ledger"])})


if __name__ == "__main__":
    unittest.main()
