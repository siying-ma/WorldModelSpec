"""The concept catalogue's caller column is computed from the run's records each time it is shown,
never kept on a concept record: the planner's `used_by` lists only the nodes of its own batch, so an
accepted record keeps none, and a candidate or a label repair carries none over. The column counts
the accepted nodes, the run's own and its base run's, that call the concept directly and are in
their law's current plan, not fenced; a fenced node and one its law's plan no longer lists are not
counted."""
import json
import unittest
from types import SimpleNamespace as NS
from unittest import mock

from harness.lean import surface
from harness.model import nodeid
from harness.phases import candidate as cand, label_repair, plan as plan_phase
from harness.store import paths
from harness.store.ledger import Entry
from harness.store.state import Run
from scripts.tests import test_recovery as rec
from scripts.tests.test_candidate import Base, Txn, concept_rec, node_rec, world

C = "drv.motion.reused"


def row(table: str, cid: str) -> list[str]:
    """The cells of the catalogue's row of `cid`."""
    line = next(l for l in table.splitlines() if l.startswith(f"| `{cid}` |"))
    return [c.strip() for c in line.strip().strip("|").split(" | ")]


def caller_cell(text: str, cid: str) -> str:
    """The caller cell of `cid` in the concept catalogue of `text` (a table, or a whole prompt)."""
    table = text[text.index("### Concept catalogue"):]
    header = next(l for l in table.splitlines() if l.startswith("| id |"))
    cols = [c.strip() for c in header.strip().strip("|").split(" | ")]
    return row(table, cid)[cols.index(surface.CALLERS_COLUMN)]


def catalogue(run) -> str:
    return surface.concepts_table(run.all_concepts(), surface.current_callers(run))


class LoopRuns(unittest.TestCase):
    """The real loop over scripted sessions and gates (`test_recovery`)."""

    def finish(self, w):
        with rec.Fixture(w) as f:
            self.assertEqual(f.drive()[-1], "complete")
            run = Run.load("r")
            return run.accepted_concepts[C], catalogue(run), sorted(run.accepted_nodes)

    def test_reuse_across_batches(self):
        """One plan proposes the concept with its own node as user; another law's node reuses it by
        id without proposing it again."""
        w = rec.World({"L-1": "shall stop.", "L-2": "shall yield."})
        w.plans = {"L-1": [rec.concept(C, users=["L_1"]), rec.node("L_1", "shall stop.", "L-1", derived=[C])],
                   "L-2": [rec.node("L_2", "shall yield.", "L-2", derived=[C])]}
        record, table, nodes = self.finish(w)
        self.assertEqual(nodes, ["L_1", "L_2"])
        self.assertNotIn("used_by", record)
        self.assertEqual(caller_cell(table, C), "2")

    def test_a_caller_accepted_in_a_later_iteration(self):
        w = rec.World({"L-1": "shall stop.", "L-2": "shall yield."})
        w.plans = {"L-1": [rec.concept(C, users=["L_1"]), rec.node("L_1", "shall stop.", "L-1", derived=[C])],
                   "L-2": [rec.node("L_2", "shall yield.", "L-2", derived=[C])]}
        w.validate[("L_2", 1)] = ("return", ["scripted plan defect"])
        record, table, nodes = self.finish(w)
        self.assertEqual(nodes, ["L_1", "L_2"])
        self.assertEqual(record["accepted_in"], "r/iter-001")
        self.assertNotIn("used_by", record)
        self.assertEqual(caller_cell(table, C), "2")


class Counted(Base):
    """What the column counts, on a run's records."""

    CB = "drv.motion.base_c"

    def setup(self, run, current: list[str], published: list[str] = ()):
        """The run's law ledger: each node of `current` in its law's current plan; each of
        `published` an accepted node its law's current plan does not list."""
        laws = {nodeid.law_of(i)[0]: [] for i in list(current) + list(published)}
        for i in current:
            laws[nodeid.law_of(i)[0]].append(i)
        run.law_entries = {law: Entry(law, state="accepted", nodes=ids) for law, ids in laws.items()}

    def test_a_replan_that_drops_the_call(self):
        concepts = {C: {**concept_rec(C), "used_by": ["TEST_CB_1"]}}
        with world(concepts, {"TEST_CB_1": node_rec("TEST_CB_1", [C]), "TEST_CB_2": node_rec("TEST_CB_2", [C])}) as (run, _lib):
            self.setup(run, ["TEST_CB_1", "TEST_CB_2"])
            self.assertEqual(caller_cell(catalogue(run), C), "2")
            run.accepted_nodes["TEST_CB_1"] = node_rec("TEST_CB_1", [])          # the law planned again: the node calls it no more
            self.assertEqual(caller_cell(catalogue(run), C), "1")

    def test_a_fenced_and_a_superseded_caller_are_not_counted(self):
        nodes = {i: node_rec(i, [C]) for i in ("TEST_CB_1", "TEST_CB_2", "TEST_CB_3")}
        with world({C: concept_rec(C)}, nodes) as (run, _lib):
            self.setup(run, ["TEST_CB_1", "TEST_CB_2"], ["TEST_CB_3"])       # TEST_CB_3 is published, not in its law's plan
            run.fence("TEST_CB_2", "node", "gate")
            table = catalogue(run)
            self.assertEqual(caller_cell(table, C), "1")
            self.assertIn("not fenced", surface.CALLERS_NOTE)
            self.assertIn("no longer lists", surface.CALLERS_NOTE)
            self.assertIn(surface.CALLERS_NOTE, table)

    def test_a_caller_of_a_closed_or_replanning_law_is_not_counted(self):
        """The column and the aggregates' current view read one rule: a node whose law is blocked,
        failed, open or returned is in no current plan, though the law's entry still lists it."""
        nodes = {i: node_rec(i, [C]) for i in ("TEST_CB_1", "TEST_CC_1", "TEST_CD_1", "TEST_CE_1", "TEST_CF_1")}
        with world({C: concept_rec(C)}, nodes) as (run, _lib):
            self.setup(run, list(nodes))
            for law, state in (("TEST-CC-1", "failed"), ("TEST-CD-1", "blocked"), ("TEST-CE-1", "returned"), ("TEST-CF-1", "open")):
                run.law_entries[law].state = state
            self.assertEqual(caller_cell(catalogue(run), C), "1")
            from harness.phases import aggregate
            self.assertEqual(sorted(aggregate.current_plan_nodes(run)), ["TEST_CB_1"])

    def test_a_caller_from_a_base_run(self):
        with world({C: concept_rec(C)}, {"TEST_CB_1": node_rec("TEST_CB_1", [C, self.CB])}) as (run, _lib):
            self.setup(run, ["TEST_CB_1"])
            run.base_concepts = {self.CB: {**concept_rec(self.CB), "callers": []}}
            run.base_nodes = {"TEST_CC_1": node_rec("TEST_CC_1", [C, self.CB])}    # a law this run does not plan
            table = catalogue(run)
            self.assertEqual((caller_cell(table, C), caller_cell(table, self.CB)), ("2", "2"))

    def test_no_planned_users_column(self):
        table = surface.concepts_table({C: {**concept_rec(C), "used_by": ["X_1"], "callers": ["X_1"]}})
        header = next(l for l in table.splitlines() if l.startswith("| id |"))
        self.assertNotIn("planned users", header)
        self.assertNotIn(surface.CALLERS_COLUMN, header)                     # no counts given: no caller column


class LabelRepair(Base):
    def test_a_label_repair_of_a_concept_keeps_no_users_list(self):
        """The repaired record comes back with `used_by: []` (the repair reader's empty list); the
        candidate stores none, and the catalogue still counts the callers."""
        concepts = {C: {**concept_rec(C), "used_by": ["TEST_CB_1"], "callers": ["TEST_CB_1", "TEST_CB_2"]}}
        nodes = {"TEST_CB_1": node_rec("TEST_CB_1", [C]), "TEST_CB_2": node_rec("TEST_CB_2", [C])}
        with world(concepts, nodes) as (run, _lib):
            Counted.setup(self, run, ["TEST_CB_1", "TEST_CB_2"])
            revised = {**concept_rec(C), "narrowings": [{"span": "measured speed", "why": "revised", "kind": "reading"}], "used_by": []}
            with Txn(run) as txn, \
                    mock.patch.object(plan_phase, "run_repair", lambda *a, **k: paths.RESULTS), \
                    mock.patch.object(plan_phase, "read_repair", lambda *a, **k: NS(kind="revised", records=[NS(raw=revised)])):
                txn.view.law_entries = run.law_entries
                changes, _ = label_repair.concept_fix(run, txn, NS(concept=C, line="l", reasons=[]), paths.RESULTS, [], "TEST-CB")
                txn.apply(changes)
                stored = txn.view.accepted_concepts[C]
                self.assertNotIn("used_by", stored)
                self.assertEqual(stored["callers"], ["TEST_CB_1", "TEST_CB_2"])
                self.assertEqual(caller_cell(catalogue(txn.view), C), "2")

    def test_a_candidate_change_carries_no_users_list(self):
        concepts = {C: {**concept_rec(C), "used_by": ["TEST_CB_1"]}}
        with world(concepts, {"TEST_CB_1": node_rec("TEST_CB_1", [C])}) as (run, _lib):
            with Txn(run) as txn:
                txn.apply([cand.Change("concept", C, {**concept_rec(C), "used_by": ["TEST_CB_1"], "narrowings": []})])
                self.assertNotIn("used_by", txn.view.accepted_concepts[C])


class Stop(Exception):
    pass


class RealPrompts(Base):
    """Every prompt that shows the catalogue, rendered by its phase function up to its session: the
    caller column counts a node of another batch, never a superseded or a fenced caller, whatever
    the record's planner list says."""

    def prompts(self) -> dict[str, str]:
        from harness.agents import session
        from harness.model.blueprint import ConceptRecord, Node
        from harness.model.corpus import Law
        concepts = {C: {**concept_rec(C), "used_by": ["TEST_CB_1"]}}                    # the batch that proposed it
        nodes = {i: node_rec(i, [C]) for i in ("TEST_CB_1", "TEST_CB_2", "TEST_CB_3", "TEST_CB_4")}
        got = {}

        def capture(prompt, *a, **k):
            got["prompt"] = prompt
            raise Stop()
        with world(concepts, nodes) as (run, _lib), mock.patch.object(session, "run", capture):
            Counted.setup(self, run, ["TEST_CB_1", "TEST_CB_2", "TEST_CB_4"], ["TEST_CB_3"])   # TEST_CB_3 superseded
            run.fence("TEST_CB_4", "node", "gate")                                          # TEST_CB_4 fenced
            law = Law("TEST-CB-1", "TEST-CB-1", "A driver shall proceed slowly.", "test")
            out = {}
            for name, call in (
                    ("plan", lambda: plan_phase.run_plan(run, [law], [], tag="p")),
                    ("concept repair", lambda: plan_phase.run_repair(run, ConceptRecord(run.all_concepts()[C]), ["r"], run.dir, [], [])),
                    ("node repair", lambda: plan_phase.run_node_repair(run, Node(run.all_nodes()["TEST_CB_1"]), ["r"], run.dir, law, [], [],
                                                                       plan_phase.Reading(run.reading_file), plan_phase.ontology.load(run.opts.ontology)))):
                got.clear()
                try:
                    call()
                except Stop:
                    pass
                out[name] = got.get("prompt", "")
            (run.dir / "evidence.md").write_text("## Label mismatches\n(none)\n")
            run.label_states = {law.id: {"outcome": "mismatch", "coverage": {"matched": 0, "eligible": 1}, "evidence": "evidence.md"}}
            with Txn(run) as txn:
                txn.view.law_entries = run.law_entries
                parts = label_repair.prompt_parts(run, txn, law, [], plan_phase.ontology.load(run.opts.ontology), 0)
                out["label repair"] = label_repair.render.render("node_repair.md", parts)
            return out

    def test_every_catalogue_prompt_counts_the_current_callers(self):
        for name, prompt in self.prompts().items():
            with self.subTest(prompt=name):
                self.assertIn(surface.CALLERS_NOTE, prompt)
                self.assertNotIn("planned users", prompt)
                self.assertEqual(caller_cell(prompt, C), "2")


if __name__ == "__main__":
    unittest.main()
