"""Development regression tests for what reaches the operator: the planners' notes for the operator
(`plan.operator_notes`, `feedback.deliver_operator_notes`) in `TO_USER.md`, once per note across
batches, merged plans, resumes, rewritten sources and a label repair's re-plan; and the current view
of the aggregate downgrades (`aggregate.write_current_view`), read from the file the operator gets.
Sessions are stubbed; no model is called."""
import hashlib
import json
from dataclasses import asdict
import tempfile
import unittest
from contextlib import contextmanager
from pathlib import Path
from types import SimpleNamespace
from unittest import mock

from harness.checks import aggregates as checks
from harness.agents import session
from harness.checks import gate
from harness.phases import aggregate, feedback, label_repair, plan
from harness.store.ledger import Ledger
from harness.phases import validate as validate_phase
from harness.store import paths
from harness.store.gaps import GapLedger
from harness.store.state import RUN_VERSION
from harness.tools import handoff

from scripts.tests.test_aggregate_gate import AID, CLASSES, DEF, ONTO, TABLE, FakeRun, Verifier, record

#: The `PLAN.md` files smoke30 saved (`results/smoke30-1110-0136/iter-*/plan/`), trimmed to their
#: headings and their `## For the operator` sections: every line the note reader reads, so it reads
#: them as it read the whole files.
SMOKE30_PLANS = Path(__file__).parent / "fixtures" / "smoke30_plans"

PLAN_TEXT = """# Plan — batch 01

## Nodes

- a node, not a note

## For the operator

- **First.** One line
  continued here.
- **Second.** With items:
  - one
  - two

  A paragraph that belongs to the second.

A paragraph after the list is a note of its own.

### A subheading stays inside the section

1. A numbered item.

## Parameters proposed

- not a note
"""


def write_plan(d: Path, text: str) -> Path:
    d.mkdir(parents=True, exist_ok=True)
    (d / "PLAN.md").write_text(text, encoding="utf-8")
    return d


def note_section(*items: str) -> str:
    return "# Plan\n\n## For the operator\n\n" + "".join(f"- {x}\n" for x in items)


class Run(SimpleNamespace):
    """What the operator's report reads of a run: its directory and iteration."""
    @property
    def iter(self):
        return self.dir / f"iter-{self.iteration:03d}"


def to_user_file(run) -> str:
    f = run.dir / "TO_USER.md"
    return f.read_text(encoding="utf-8") if f.exists() else ""


class OperatorNotes(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.run = Run(dir=Path(self.tmp.name) / "r", iteration=1)
        self.run.dir.mkdir()

    def tearDown(self):
        self.tmp.cleanup()

    def plan_dir(self, *parts: str) -> Path:
        return self.run.dir.joinpath(f"iter-{self.run.iteration:03d}", "plan", *parts)

    def test_every_note_smoke30_saved_is_found(self):
        root = SMOKE30_PLANS
        found = {d.relative_to(root).as_posix(): plan.operator_notes(d) for d in sorted(root.glob("iter-*/plan"))}
        self.assertEqual({k: len(v) for k, v in found.items()},
                         {"iter-001/plan": 19, "iter-002/plan": 0, "iter-003/plan": 1, "iter-004/plan": 0, "iter-005/plan": 2})
        self.assertEqual(sum(len(v) for v in found.values()), 22)
        # the merged iteration's notes come from its four batches, each once, never from the merge
        self.assertEqual(sorted({n["source"].name for n in found["iter-001/plan"]}), ["batch-01", "batch-02", "batch-03", "batch-04"])
        self.assertTrue(any("The witnesses here avoid the case on purpose." in n["text"] for n in found["iter-005/plan"]))

    def test_no_section_and_no_plan_have_no_note(self):
        self.assertEqual(plan.operator_notes(write_plan(self.plan_dir(), "# Plan\n\n## Nodes\n\n- x\n")), [])
        self.assertEqual(plan.operator_notes(self.plan_dir("missing")), [])
        to_user = []
        self.assertEqual(feedback.deliver_operator_notes(self.run, to_user, []), 0)
        self.assertEqual(to_user, [])

    def test_several_notes_in_order_with_their_items(self):
        notes = plan.operator_notes(write_plan(self.plan_dir(), PLAN_TEXT))
        self.assertEqual([n["ordinal"] for n in notes], [1, 2, 3, 4])
        self.assertEqual(notes[0]["text"], "**First.** One line\n  continued here.")
        self.assertEqual(notes[1]["text"], "**Second.** With items:\n  - one\n  - two\n  A paragraph that belongs to the second.")
        self.assertEqual(notes[2]["text"], "A paragraph after the list is a note of its own.")
        self.assertEqual(notes[3]["text"], "A numbered item.")
        self.assertEqual(len({n["section_digest"] for n in notes}), 1)
        feedback.deliver_operator_notes(self.run, to_user := [], notes)
        feedback.write_to_user(self.run, to_user)
        text = to_user_file(self.run)
        self.assertIn("- planner's note for the operator (iteration 1, `iter-001/plan`, note 2, section", text)
        self.assertIn("\n  - one\n  - two\n", text)                     # a note's own items stay under it
        self.assertNotIn("not a note", text)

    def test_two_batches_with_the_same_words_are_two_notes(self):
        same = note_section("The catalogue lacked the earlier batch's parameters.")
        write_plan(self.plan_dir("batch-01"), same)
        write_plan(self.plan_dir("batch-02"), same)
        plan.merge_batches(self.run, [self.plan_dir("batch-01"), self.plan_dir("batch-02")])
        to_user = []
        feedback.deliver_operator_notes(self.run, to_user, plan.operator_notes(self.plan_dir()))
        feedback.write_to_user(self.run, list(dict.fromkeys(to_user)))   # the dedup `write_feedback` applies by line
        lines = [l for l in to_user_file(self.run).splitlines() if "planner's note" in l]
        self.assertEqual(len(lines), 2)
        self.assertEqual(sorted(l.split("`")[1] for l in lines), ["iter-001/plan/batch-01", "iter-001/plan/batch-02"])

    def test_a_resume_delivers_nothing_again(self):
        write_plan(self.plan_dir("batch-01"), note_section("a", "b"))
        write_plan(self.plan_dir("batch-02"), note_section("c"))
        plan.merge_batches(self.run, [self.plan_dir("batch-01"), self.plan_dir("batch-02")])
        to_user = []
        self.assertEqual(feedback.deliver_operator_notes(self.run, to_user, plan.operator_notes(self.plan_dir())), 3)
        feedback.write_to_user(self.run, to_user)
        resumed = json.loads(json.dumps(to_user))                         # the iteration's lines as its snapshot keeps them
        self.assertEqual(feedback.deliver_operator_notes(self.run, resumed, plan.operator_notes(self.plan_dir())), 0)
        feedback.write_to_user(self.run, resumed)
        self.assertEqual(sum("planner's note" in l for l in to_user_file(self.run).splitlines()), 3)

    def test_a_rewritten_source_is_delivered_once_marked(self):
        d = write_plan(self.plan_dir(), note_section("old words"))
        to_user = []
        feedback.deliver_operator_notes(self.run, to_user, plan.operator_notes(d))
        write_plan(d, note_section("new words"))
        self.assertEqual(feedback.deliver_operator_notes(self.run, to_user, plan.operator_notes(d)), 1)
        self.assertEqual(feedback.deliver_operator_notes(self.run, to_user, plan.operator_notes(d)), 0)
        feedback.write_to_user(self.run, to_user)
        lines = [l for l in to_user_file(self.run).splitlines() if "planner's note" in l]
        self.assertEqual(len(lines), 2)
        self.assertTrue(lines[0].endswith("old words") and "source rewritten" not in lines[0])
        self.assertTrue(lines[1].endswith("new words") and "source rewritten" in lines[1])

    def test_a_label_repair_replan_delivers_its_notes(self):
        law = SimpleNamespace(id="TST-900B-100")
        area = self.run.dir / "iter-001" / "candidate" / "c1" / "iter-candidate"
        view = SimpleNamespace(iter=area, all_nodes=lambda: {}, all_concepts=lambda: {})

        @contextmanager
        def inside():
            yield

        txn = SimpleNamespace(view=view, inside=inside, write_scope=lambda: None)

        def run_plan(v, laws, defs, tag="", label_repair=False, **_kw):
            d = write_plan(v.iter / "plan" / tag, note_section("the re-plan's note"))
            (d / "blueprint.jsonl").write_text(json.dumps({"node_id": "TST_900B_100_o1", "law_refs": [law.id]}) + "\n")
            return d

        to_user = []
        with mock.patch.object(plan, "run_plan", run_plan):
            label_repair.replan(self.run, txn, law, [], to_user)
            label_repair.replan(self.run, txn, law, [], to_user)          # taken up again from the same session's answer
        self.assertEqual(len(to_user), 1)
        self.assertIn("`iter-001/candidate/c1/iter-candidate/plan/label-TST-900B-100`, note 1", to_user[0])
        self.assertTrue(to_user[0].endswith("the re-plan's note"))

    def test_an_earlier_iteration_is_marked_as_observed_then(self):
        feedback.write_to_user(self.run, ["first"])
        self.run.iteration = 2
        feedback.write_to_user(self.run, ["second"])
        feedback.write_to_user(self.run, ["second", "third"])
        text = to_user_file(self.run)
        one, two = text.split("## Iteration 2")
        self.assertEqual(one.count("_Observed during iteration 1"), 1)
        self.assertIn("- first", one)
        self.assertNotIn("_Observed", two)
        self.assertEqual(text.count("- second"), 1)


class ViewRun(FakeRun):
    """A run with accepted records, for the current view's closure."""
    def __init__(self, d: Path):
        super().__init__(d)
        self.nodes, self.concepts = {}, {}
        self.law_entries, self.fenced = {}, {}                           # the live law ledger and the fences `Availability` reads

    def all_nodes(self):
        return self.nodes

    def all_concepts(self):
        return self.concepts


class CurrentView(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.repo = Path(self.tmp.name) / "repo"
        (self.repo / "results" / "t").mkdir(parents=True)
        self.run = ViewRun(self.repo / "results" / "t")
        opts = {**asdict(self.run.opts), "semantic": {"run_version": RUN_VERSION}}
        (self.run.dir / "options.json").write_text(json.dumps(opts, default=str))
        (self.run.dir / "definition_resolution.json").write_text(json.dumps(TABLE))
        aggregate.save_selection(self.run, {(DEF["id"], "wagon"): {"definition": DEF["id"], "term": "wagon", "representation": "aggregate",
                                                                  "target": AID, "quote": "x", "reason": "y"}})
        self.saved = validate_phase._session

    def tearDown(self):
        validate_phase._session = self.saved
        self.tmp.cleanup()

    def admit(self, verdicts, rec=None, defs=None):
        validate_phase._session = Verifier(verdicts)
        return aggregate.admit(self.run, [rec or record()], TABLE, defs or [DEF], ONTO, self.run.dir / "out")

    def view(self) -> str:
        """The view as the handoff hands it over: the real export, the file it lists, checked against
        the digest its manifest records. Only the checkpoint test, the library owner, the toolchain
        and the code digest are stubbed, since this fixture has no library and no committed iteration."""
        none = self.repo / "absent"
        with mock.patch.multiple(paths, REPO=self.repo, RESULTS=self.repo / "results", RULES_DIR=none, CONCEPTS_DIR=none,
                                 WITNESS_DIR=none, GAPS_DIR=none, INDEX_FILE=none / "i", WITNESS_ROOT_FILE=none / "w"), \
                mock.patch.object(handoff, "checkpoint_problems", lambda run_id, for_transition=False: []), \
                mock.patch.object(handoff, "toolchain", lambda: {}), \
                mock.patch.object(handoff, "code_digest", lambda: {"files": {}, "digest": "d"}), \
                mock.patch("harness.store.owner.acquire_for_command", lambda name: None):
            manifest = handoff.export("t")
        rel = f"results/t/{aggregate.VIEW_NAME}"
        listed = (self.run.dir / "handoff" / "files.txt").read_text().splitlines()
        self.assertIn(rel, listed)
        data = (self.repo / rel).read_bytes()
        self.assertEqual(manifest["artifacts"][rel], hashlib.sha256(data).hexdigest())
        return data.decode("utf-8")

    def lines_of(self, cls: str) -> list[str]:
        return [l for l in self.view().splitlines() if l.startswith(f"- `{AID}` · class `{cls}`")]

    def digest(self) -> str:
        return json.loads(self.run.reading_file.read_text())["aggregates"][0]["certificate"]

    def test_a_downgrade_is_reported_with_both_fields(self):
        _e, _n, to_user = self.admit({"*": "supported", CLASSES[0]: "underdetermined"})
        self.assertEqual(len(to_user), 1)
        self.assertIn(aggregate.VIEW_NAME, to_user[0])
        [line] = self.lines_of(CLASSES[0])
        self.assertIn(f"certificate `{self.digest()}`", line)
        self.assertIn("(underdetermined); the verifier: r", line)
        self.assertIn("  - laws referencing the pair at admission: `TST-900B-100`", self.view())
        self.assertIn("  - accepted nodes in their law's current plan referencing it directly or through composition: not yet computed", self.view())

    def test_recovery_after_an_interruption_rebuilds_the_view(self):
        self.admit({"*": "supported", CLASSES[0]: "underdetermined"})
        before = self.view()
        aggregate.view_file(self.run).unlink()                            # stopped after the certificate, before its companions
        self.run.reading_file.write_text(json.dumps({"params": [], "aggregates": []}))
        notes, stop = aggregate.check_admissions(self.run, {}, [DEF], ONTO, {})
        self.assertEqual(stop, [])
        self.assertTrue(any("restored" in n for n in notes))
        self.assertEqual(self.view(), before)
        self.assertEqual(len(self.lines_of(CLASSES[0])), 1)

    def test_every_unresolved_class_is_listed_with_its_origin(self):
        """The view lists every class the admitted entry holds unresolved, not only the downgrades:
        one the mapping itself classifies unresolved carries the planner's reason, one the verifier
        downgraded carries the verifier's."""
        rec = record()
        rec["classifications"][1].update(status="unresolved", reason="the words decide neither")
        self.admit({"*": "supported", CLASSES[0]: "underdetermined"}, rec=rec)
        held = json.loads(self.run.reading_file.read_text())["aggregates"][0]["unresolved"]
        self.assertEqual(sorted(held), sorted(CLASSES[:2]))
        [down] = self.lines_of(CLASSES[0])
        [own] = self.lines_of(CLASSES[1])
        self.assertIn("downgraded to unresolved (underdetermined); the verifier: r", down)
        self.assertIn(f"certificate `{self.digest()}`: unresolved in the admitted mapping; the planner: the words decide neither", own)
        self.assertEqual(sum(1 for l in self.view().splitlines() if l.startswith(f"- `{AID}` · class ")), len(held))

    def test_a_re_verified_aggregate_leaves_its_old_downgrade(self):
        self.admit({"*": "supported", CLASSES[0]: "underdetermined"})
        old = self.digest()
        changed = {**DEF, "text": DEF["text"].replace("human power", "human power alone")}
        rec = record()
        for c in rec["classifications"]:
            c["quotes"] = [{"definition": DEF["id"], "words": "every device upon which a person may be carried"}]
        _notes, stop = aggregate.check_admissions(self.run, {}, [changed], ONTO, {})
        self.assertEqual(stop, [])
        self.assertNotIn(old, self.view())                                # invalidated: no longer current
        self.admit({"*": "supported", CLASSES[1]: "underdetermined"}, rec=rec, defs=[changed])
        new = self.digest()
        self.assertNotEqual(old, new)
        text = self.view()
        self.assertNotIn(old, text)
        self.assertEqual(self.lines_of(CLASSES[0]), [])
        self.assertEqual(len(self.lines_of(CLASSES[1])), 1)
        self.assertIn(new, self.lines_of(CLASSES[1])[0])

    def test_repeated_writes_keep_one_line_per_identity(self):
        self.admit({"*": "supported", CLASSES[0]: "underdetermined", CLASSES[1]: "underdetermined"})
        for _ in range(3):
            aggregate.write_current_view(self.run)
            aggregate.check_admissions(self.run, {}, [DEF], ONTO, {})
        self.assertEqual((len(self.lines_of(CLASSES[0])), len(self.lines_of(CLASSES[1]))), (1, 1))
        self.assertEqual(self.view().count("## Classes unresolved"), 1)

    def test_a_node_accepted_after_admission_is_in_the_field_as_of_its_iteration(self):
        self.admit({"*": "supported", CLASSES[0]: "underdetermined"})
        self.run.iteration = 2
        self.run.concepts = {"drv.user.wagon_moving": {"concept_id": "drv.user.wagon_moving", "elements": [{"atoms": [f"ru.aggregate={AID}"]}]}}
        self.run.nodes = {
            "TST_900B_100_o1": {"node_id": "TST_900B_100_o1", "law_refs": ["TST-900B-100"], "elements": [{"atoms": [f"ru.aggregate={AID}"]}]},
            "TST_900B_110_o1": {"node_id": "TST_900B_110_o1", "law_refs": ["TST-900B-110"], "elements": [{"derived": ["drv.user.wagon_moving"]}]},
            "TST_900B_120_o1": {"node_id": "TST_900B_120_o1", "law_refs": ["TST-900B-120"],
                                "compositions": [{"rule": "TST_900B_100_o1", "as": "exception", "span": "s1"}]},
            "TST_900B_130_o1": {"node_id": "TST_900B_130_o1", "law_refs": ["TST-900B-130"], "fenced": {"reason": "x"},
                                "elements": [{"atoms": [f"ru.aggregate={AID}"]}]},
        }
        self.run.fenced = {"TST_900B_130_o1": {"reason": "x"}}
        aggregate.write_current_view(self.run, closure=True)              # after integration
        field = next(l for l in self.view().splitlines() if "accepted nodes in their law's current plan referencing it" in l)
        self.assertIn("as of iteration 2:", field)
        self.assertIn("`TST_900B_100_o1` (directly)", field)
        self.assertIn("`TST_900B_110_o1` (directly)", field)               # through a concept that claims it
        self.assertIn("`TST_900B_120_o1` (composes `TST_900B_100_o1`)", field)
        self.assertNotIn("TST_900B_130_o1", field)

    def test_an_empty_aggregate_is_reported_and_files_no_gap(self):
        gaps = Path(self.tmp.name) / "gaps"
        with mock.patch.object(paths, "GAPS_DIR", gaps):
            entries, _n, to_user = self.admit({"*": "supported"}, rec=record("excluded"))
            self.assertEqual(entries[0]["included"], [])
            self.assertIn("no class included", to_user[0])
            self.assertIn(f"- `{AID}` · certificate `{self.digest()}`: includes no class", self.view())
            led = GapLedger(gaps)
            self.assertEqual(led.rows, [])
            self.assertEqual(led.start_round(Path(self.tmp.name) / "results"), [])
            self.assertEqual(GapLedger(gaps).rows, [])

    def test_a_definition_cycle_is_flagged_and_decides_nothing(self):
        table = json.loads(json.dumps(TABLE))
        table["laws"]["TST-900B-100"][0]["dependencies"] = [
            {"from": DEF["id"], "term": "cart", "status": "resolved", "definition": "DEF-TST-900A-020",
             "chain": ["DEF-TST-900A-020"], "cycle": [DEF["id"], "DEF-TST-900A-020", DEF["id"]]}]
        (self.run.dir / "definition_resolution.json").write_text(json.dumps(table))
        validate_phase._session = Verifier({"*": "supported"})
        entries, _n, to_user = aggregate.admit(self.run, [record()], table, [DEF], ONTO, self.run.dir / "out")
        self.assertEqual(len(entries), 1)
        self.assertEqual(to_user, [])
        self.assertIn(f"its nested definitions form a cycle ({DEF['id']} → DEF-TST-900A-020 → {DEF['id']}); flagged", self.view())

    def test_a_run_stopped_after_admission_hands_over_the_downgrades(self):
        """Stopped after the admission, before any plan (an interruption, a budget pause, an error):
        the handed view lists the downgrade, and its node field says it is not yet computed, even
        with an accepted node claiming the aggregate already."""
        self.run.nodes = {"TST_900B_100_o1": {"node_id": "TST_900B_100_o1", "law_refs": ["TST-900B-100"],
                                              "elements": [{"atoms": [f"ru.aggregate={AID}"]}]}}
        self.admit({"*": "supported", CLASSES[0]: "underdetermined"})
        text = self.view()
        self.assertEqual(len([l for l in text.splitlines() if l.startswith(f"- `{AID}` · class `{CLASSES[0]}`")]), 1)
        field = next(l for l in text.splitlines() if "accepted nodes in their law's current plan referencing it" in l)
        self.assertIn("not yet computed", field)
        self.assertNotIn("TST_900B_100_o1", field)
        self.assertNotIn(": none", field)

    def test_a_later_rebuild_replaces_the_mark_with_the_closure(self):
        self.admit({"*": "supported", CLASSES[0]: "underdetermined"})
        self.assertIn("not yet computed", self.view())
        self.run.iteration = 2
        self.run.nodes = {"TST_900B_100_o1": {"node_id": "TST_900B_100_o1", "law_refs": ["TST-900B-100"],
                                              "elements": [{"atoms": [f"ru.aggregate={AID}"]}]}}
        aggregate.write_current_view(self.run, closure=True)              # after the plan, or after integration
        text = self.view()
        self.assertNotIn("not yet computed", text)
        self.assertIn("  - accepted nodes in their law's current plan referencing it directly or through composition, as of iteration 2: `TST_900B_100_o1` (directly)", text)
        aggregate.check_admissions(self.run, {}, [DEF], ONTO, {})          # the next iteration's start: not yet computed again
        self.assertIn("not yet computed", self.view())

    def test_a_selection_correction_reports_its_downgrade(self):
        """A downgrade admitted through a selection correction reaches `TO_USER.md` as well as the view."""
        aggregate.save_selection(self.run, {})
        led = Ledger(self.run.dir / "ledger.jsonl", ["TST-900B-100"], 2)
        row = {"definition": DEF["id"], "term": "wagon", "representation": "aggregate", "target": AID, "quote": "x", "reason": "y"}
        validate_phase._session = Verifier({"*": "supported", CLASSES[0]: "underdetermined"})
        to_user = []
        with mock.patch.object(aggregate, "select_and_derive", lambda *a, **k: ({(DEF["id"], "wagon"): row}, [record()], [])):
            _notes, close = aggregate.correct_claims(self.run, {"TST-900B-100": {AID}}, [DEF], ONTO, led, self.run.dir / "out", to_user)
        self.assertEqual(close, {})
        feedback.write_to_user(self.run, to_user)
        text = (self.run.dir / "TO_USER.md").read_text(encoding="utf-8")
        self.assertIn(f"- aggregate `{AID}` admitted with 1 class(es) downgraded to unresolved ({CLASSES[0]} (underdetermined))", text)
        self.assertIn(aggregate.VIEW_NAME, text)
        self.assertEqual(len(self.lines_of(CLASSES[0])), 1)

    def claimant(self, nid: str, law: str = "TST-900B-100") -> dict:
        return {"node_id": nid, "law_refs": [law], "elements": [{"atoms": [f"ru.aggregate={AID}"]}]}

    def field(self) -> str:
        return next(l for l in self.view().splitlines() if "referencing it directly or through composition" in l)

    def test_a_superseded_version_is_not_counted(self):
        """A node still in the accepted records but no longer in its law's current plan is a version
        that plan replaced (`SUPERSEDED`): the field, named for what it counts, leaves it out."""
        self.admit({"*": "supported", CLASSES[0]: "underdetermined"})
        self.run.nodes = {"TST_900B_100_o1": self.claimant("TST_900B_100_o1"), "TST_900B_100_o2": self.claimant("TST_900B_100_o2")}
        self.run.law_entries = {"TST-900B-100": SimpleNamespace(state="planned", nodes=["TST_900B_100_o2"])}
        aggregate.write_current_view(self.run, closure=True)
        field = self.field()
        self.assertTrue(field.startswith("  - accepted nodes in their law's current plan referencing it directly or through composition, as of iteration 1:"))
        self.assertIn("`TST_900B_100_o2` (directly)", field)
        self.assertNotIn("TST_900B_100_o1", field)

    def repairs(self, effect):
        """`run_repairs` over one law whose repair commits (`effect` changes the run's records as its
        commit would); the view is read as handed over afterwards."""
        law = "TST-900B-100"
        self.run.label_states = {law: {"state": "awaiting_label_repair"}}
        self.run.opts = SimpleNamespace(label_repair_attempts=3, label_repair_budget=9)
        ledger = SimpleNamespace(entries={law: SimpleNamespace(state="planned", nodes=list(self.run.nodes))})

        def repair_law(run, *_a, **_k):
            effect()
            run.label_states[law]["state"] = "accepted"
            return "committed"
        with mock.patch.object(label_repair, "awaiting", lambda run, led: [law]), \
                mock.patch.object(label_repair, "repair_law", repair_law), \
                mock.patch("harness.phases.code.scope_unrestored", lambda run: {}):
            label_repair.run_repairs(self.run, ledger, None, {law: SimpleNamespace(id=law)}, [], ONTO, None, [], [])

    def test_a_repair_commit_that_adds_a_node_is_in_the_view(self):
        self.admit({"*": "supported", CLASSES[0]: "underdetermined"})
        self.assertIn("not yet computed", self.field())
        self.repairs(lambda: self.run.nodes.update({"TST_900B_100_o3": self.claimant("TST_900B_100_o3")}))
        self.assertIn("`TST_900B_100_o3` (directly)", self.field())

    def test_a_repair_commit_that_fences_or_revokes_a_node_leaves_it_out(self):
        self.admit({"*": "supported", CLASSES[0]: "underdetermined"})
        self.run.nodes = {"TST_900B_100_o1": self.claimant("TST_900B_100_o1"), "TST_900B_110_o1": self.claimant("TST_900B_110_o1", "TST-900B-110")}
        aggregate.write_current_view(self.run, closure=True)
        self.assertIn("TST_900B_100_o1", self.field())
        self.assertIn("TST_900B_110_o1", self.field())

        def commit():
            self.run.fenced["TST_900B_100_o1"] = {"reason": "label repair"}          # fenced by the commit
            del self.run.nodes["TST_900B_110_o1"]                                    # revoked by the commit
        self.repairs(commit)
        field = self.field()
        self.assertNotIn("TST_900B_100_o1", field)
        self.assertNotIn("TST_900B_110_o1", field)
        self.assertTrue(field.endswith(": none"))

    def test_a_label_only_iteration_rebuilds_the_view(self):
        from harness import loop
        self.admit({"*": "supported", CLASSES[0]: "underdetermined"})
        self.assertIn("not yet computed", self.field())
        self.run.nodes = {"TST_900B_100_o1": self.claimant("TST_900B_100_o1")}
        prog = {"notes": [], "to_user": [], "gaps_filed": [], "coder_narrowings": {}, "stage": "start"}
        opts = SimpleNamespace(label_repair=False, label_deferred=False)
        with mock.patch.object(loop, "accept_ready", lambda *a, **k: None), \
                mock.patch.object(loop.feedback_phase, "write_feedback", lambda *a, **k: None), \
                mock.patch.object(loop.code_phase, "scope_unrestored", lambda run: {}):
            self.run.deferred_nodes = []
            loop.label_iteration(self.run, opts, prog, lambda: None, SimpleNamespace(counts=lambda: {}), None, None, {}, [], ONTO, None)
        self.assertIn("as of iteration 1: `TST_900B_100_o1` (directly)", self.field())

    def test_the_view_is_in_the_handoff(self):
        repo = Path(self.tmp.name) / "repo"
        rd = repo / "results" / "h"
        rd.mkdir(parents=True)
        (rd / "options.json").write_text(json.dumps({"run_id": "h"}))
        (rd / "TO_USER.md").write_text("x\n")
        (rd / aggregate.VIEW_NAME).write_text("y\n")
        none = repo / "absent"
        with mock.patch.multiple(paths, REPO=repo, RESULTS=repo / "results", RULES_DIR=none, CONCEPTS_DIR=none, WITNESS_DIR=none,
                                 GAPS_DIR=none, INDEX_FILE=none / "i", WITNESS_ROOT_FILE=none / "w"):
            files = handoff.artifact_files("h")
        self.assertIn(f"results/h/{aggregate.VIEW_NAME}", files)
        self.assertIn("results/h/TO_USER.md", files)


class ViewIsAHarnessRecord(unittest.TestCase):
    """The view is the harness's own run record, like `TO_USER.md`: no session may write it, and the
    harness rewriting it while a coding session runs is never that session's change."""
    def test_a_coding_session_may_not_write_the_view(self):
        rules = session.deny_rules("code", "r")
        for tool in session.WRITE_TOOLS:
            self.assertIn(f"{tool}(//{str(paths.REPO).lstrip('/')}/results/*/{aggregate.VIEW_NAME})", rules)

    def test_a_rewritten_view_is_no_scope_change(self):
        with tempfile.TemporaryDirectory() as t:
            root = Path(t)
            rd = root / "results" / "r"
            rd.mkdir(parents=True)
            (rd / aggregate.VIEW_NAME).write_text("before\n")
            (root / "work").mkdir()
            baseline = gate.repo_digest(root)
            (rd / aggregate.VIEW_NAME).write_text("rewritten by the harness mid-run\n")
            self.assertEqual(gate.repo_digest(root), baseline)
            with mock.patch.object(paths, "REPO", root):
                self.assertEqual(gate.scope_stray(baseline, set(), root / "work"), [])


if __name__ == "__main__":
    unittest.main()
