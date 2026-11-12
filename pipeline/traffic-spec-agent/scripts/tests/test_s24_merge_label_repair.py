"""A label repair in a run with a stage record: what it records names what it checked, and it keeps to
the active stage's scope.

- A committed repair records, for the law it repaired and for every law it checked again, the label
  key of the candidate the check ran on: right after the commit that is `loop.label_key` on the run,
  and `loop.stale_labels` names none of them. A later, unchecked change to a record or rule file in a
  law's composition closure makes the recorded key differ from the current one, and the law is named.
- A stage limited to some laws repairs none outside them (`label_repair.awaiting`), and a candidate
  never moves an out-of-scope law it checked again into `accepted`, while a check that got worse still
  demotes it. A run without a stage record keeps both as they were.

The candidate, the hooks, the snapshot, the ledger and the label check are the real ones on the world of
`test_label_repair_session` (its stand-in sessions, monitor, gate toolchain and whole-library build); here
L-1's node composes L-5's, so a repair of L-5 checks L-1 again."""
import json
import tempfile
import unittest
from contextlib import contextmanager
from pathlib import Path
from types import SimpleNamespace
from unittest import mock

from harness import loop
from harness.agents import session
from harness.checks import gate
from harness.lean import lean
from harness.model import corpus, nodeid
from harness.phases import candidate as cand
from harness.phases import integrate, label_check
from harness.phases import label_repair as lr
from harness.store import paths
from harness.store.ledger import Ledger
from scripts.tests.test_candidate import Base, Gates, Txn, node_rec, passing, world
from scripts.tests.test_label_check import FAKE_EXPLAIN, FAKE_MONITOR, make_dataset, write_exe
from scripts.tests.test_label_repair import L, N, RECS
from scripts.tests.test_label_repair_session import DIFF5, RULE5, repair, set_verdict, stub_session
from scripts.tests.test_s24_c_label_key_scope import write_stage

RULE1 = nodeid.rule_path(N[1])
STATES = ("accepted", "planned")


@contextmanager
def repairing(stage, outputs=None):
    """Five laws of one node each, L-1's node composing L-5's, all planned; the stage record written
    (`stage`: "all", a set of laws, or None for none) before the laws are routed once; every stand-in
    of a repair in place."""
    nodes = {N[k]: node_rec(N[k]) for k in N}
    nodes[N[1]]["compositions"] = [{"span": "o1", "rule": N[5], "as": "condition"}]
    with world({}, nodes) as (run, _lib), tempfile.TemporaryDirectory() as t:
        t = Path(t)
        ds = make_dataset(t / "ds", RECS)
        mon, exp = write_exe(t / "monitor", FAKE_MONITOR), write_exe(t / "explain", FAKE_EXPLAIN)
        ledger = Ledger(run.ledger_file, list(L.values()), 2)
        ledger.attempt = 1
        for k in N:
            ledger.mark_planned(L[k], [N[k]], 1)
        run.law_entries = ledger.entries
        training = label_check.training_context(run.dir, list(L.values()), ds.path,
                                                label_check.Limits(deadline_s=5, memory_gb=4, explain_s=5, jobs=2))
        laws = Path(run.opts.laws)
        laws.write_text("".join(json.dumps({"id": L[k], "title": f"law {k}", "text": "A driver shall proceed slowly.", "source": "test"}) + "\n"
                                for k in L))
        laws.with_name("definitions.jsonl").write_text("")
        run.opts.label_repair = True
        if stage is not None:
            write_stage(stage)
        with mock.patch.object(label_check, "build_tools", lambda lib_: (mon, exp)):
            loop.label_route(run, ledger, training, [])
            with mock.patch.object(session, "run", stub_session(outputs)), mock.patch.object(gate, "_toolchain", Gates()), \
                    mock.patch.object(integrate, "verify_library", lambda *a, **k: ("verified", [], set())), \
                    mock.patch.object(lean, "lake_build", lambda *a, **k: (0, "")), mock.patch.object(cand, "validate_records", passing):
                yield run, ledger, training, {l.id: l for l in corpus.load_laws(laws)}


def committed(test, run, ledger, training, by_id) -> dict[str, str]:
    """L-5 repaired to aligned through a real commit that changes its rule file; the keys each law
    had before it."""
    test.assertEqual(run.label_states[L[5]]["outcome"], "mismatch")
    test.assertEqual(run.label_states[L[1]]["outcome"], "aligned")
    before = {law: loop.label_key(run, law, list(ledger.entries[law].nodes)) for law in (L[1], L[5])}
    set_verdict(training, "r5a", N[5], "compliant")
    set_verdict(training, "r5b", N[5], "violated")
    test.assertEqual(repair(run, ledger, training, by_id), "committed")
    test.assertIn("-- v2", (paths.LIBRARY / RULE5).read_text())
    return before


REC5 = {k: v for k, v in node_rec(N[5]).items() if k != "segmentation"}
OUTPUTS = {"record.jsonl": json.dumps(REC5), "lean.diff": DIFF5}


class KeyOfWhatWasChecked(Base):

    def test_a_committed_repair_records_the_key_of_the_candidate_it_checked(self):
        with repairing("all", OUTPUTS) as (run, ledger, training, by_id):
            before = committed(self, run, ledger, training, by_id)
            st5, st1 = run.label_states[L[5]], run.label_states[L[1]]
            self.assertEqual((st5["state"], ledger.entries[L[5]].state), ("accepted", "accepted"))
            self.assertEqual(st1["candidate"], st5["candidate"])                        # L-1 was checked again by the repair
            for law in (L[1], L[5]):
                now = loop.label_key(run, law, list(ledger.entries[law].nodes))
                self.assertNotEqual(now, before[law])                                    # the commit changed what the law reaches
                self.assertEqual(run.label_states[law]["key"], now, law)
            stale = loop.stale_labels(run, ledger, STATES)
            self.assertFalse({L[1], L[5]} & set(stale), stale)

    def test_without_a_stage_record_no_key_is_recorded(self):
        with repairing(None, OUTPUTS) as (run, ledger, training, by_id):
            committed(self, run, ledger, training, by_id)
            self.assertTrue(all("key" not in run.label_states[law] for law in (L[1], L[5])))
            self.assertEqual(loop.stale_labels(run, ledger, STATES), {})


class PublishedNotChecked(Base):
    """A change after the commit, which no check saw, makes the recorded key stale."""

    def check(self, rel: str, named: set[str]):
        with repairing("all", OUTPUTS) as (run, ledger, training, by_id):
            committed(self, run, ledger, training, by_id)
            self.assertFalse({L[1], L[5]} & set(loop.stale_labels(run, ledger, STATES)))
            p = paths.LIBRARY / rel
            p.write_text(p.read_text() + "-- a later edit no label check saw\n")
            stale = loop.stale_labels(run, ledger, STATES)
            self.assertEqual({L[1], L[5]} & set(stale), named, stale)
            for law in named:
                recorded, current = stale[law]
                self.assertEqual(recorded, run.label_states[law]["key"])
                self.assertNotEqual(recorded, current)
                self.assertEqual(current, loop.label_key(run, law, list(ledger.entries[law].nodes)))

    def test_a_rule_both_laws_reach(self):
        self.check(RULE5, {L[1], L[5]})

    def test_a_rule_only_the_composing_law_reaches(self):
        self.check(RULE1, {L[1]})


def staged_now(stage) -> None:
    """The stage record written after the laws were routed once (a stage opened on a run that has its
    label states already), or none."""
    if stage is not None:
        write_stage(stage)


class StageScope(Base):
    """A stage of scope {L-1, L-2} in a run of five laws, opened after every law was routed once."""

    SCOPE = {L[1], L[2]}

    def test_awaiting_keeps_to_the_scope(self):
        for stage, want in ((self.SCOPE, [L[1]]), ("all", [L[1], L[5]]), (None, [L[1], L[5]])):
            with self.subTest(stage=stage), repairing(None) as (run, ledger, _training, _by_id):
                staged_now(stage)
                self.assertEqual(run.label_states[L[5]]["state"], "awaiting_label_repair")
                ledger.entries[L[1]].state = "planned"
                run.label_states[L[1]] = {**run.label_states[L[1]], "state": "awaiting_label_repair", "outcome": "mismatch"}
                self.assertEqual(lr.awaiting(run, ledger), want)

    def test_route_never_accepts_out_of_scope_and_still_demotes(self):
        aligned, mismatch = (SimpleNamespace(outcome=o) for o in ("aligned", "mismatch"))
        for stage, accepted in ((self.SCOPE, False), (None, True)):
            with self.subTest(stage=stage), repairing(None) as (run, ledger, _training, _by_id):
                staged_now(stage)
                ledger.entries[L[3]].state = "planned"                                  # out of scope, checked again: aligned
                self.assertEqual(ledger.entries[L[4]].state, "blocked")
                self.assertEqual(ledger.entries[L[1]].state, "accepted")
                ledger.entries[L[4]].state = "accepted"                                 # out of scope, accepted, checked again: worse
                with Txn(run) as txn:
                    txn.label_checks = {L[3]: aligned, L[4]: mismatch}
                    routed = txn.route(None, [])
                    txn.rollback("test")
                self.assertEqual(routed.entries[L[3]].state, "accepted" if accepted else "planned")
                self.assertEqual(routed.entries[L[4]].state, "planned")


if __name__ == "__main__":
    unittest.main()
