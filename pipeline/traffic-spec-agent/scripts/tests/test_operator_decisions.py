"""Development regression tests for the operator's decisions a record follows, and for what every
role is shown of them: a narrowing that cites a rejected gap is checked against the gap's law and
words, the decision reaches the repair, the coder, the reviewer and Stage B in the operator's
words, the ontology's section on what is not an atom reaches the judges, and a law planned again
sees the records it was last coded from."""
import json
import tempfile
import unittest
from pathlib import Path
from types import SimpleNamespace
from unittest import mock

from harness.checks import validate_a
from harness.model import corpus, ontology
from harness.model.blueprint import Node
from harness.phases import plan as plan_phase, review
from harness.store import paths
from harness.store.gaps import GapLedger
from scripts.tests.test_review_routing import FakeRun, LAW as ONE_LAW, ONTO, ctx, scripted_reviewer, submit

_RESULTS = {}


def setUpModule():
    """Every gap these tests file is measured under a temporary results tree, never the run's."""
    _RESULTS["tmp"] = tempfile.TemporaryDirectory()
    _RESULTS["saved"] = paths.RESULTS
    paths.RESULTS = Path(_RESULTS["tmp"].name)


def tearDownModule():
    paths.RESULTS = _RESULTS["saved"]
    _RESULTS["tmp"].cleanup()

TEXT = "The driver shall stop at a clearly marked line. The driver shall yield to traffic."
LAW = corpus.Law("L-9", "A duty", TEXT, "")
LINE = (TEXT.index("shall stop"), TEXT.index("line.") + len("line"))


def record(narrowing: dict) -> Node:
    return Node({"node_id": "L_9_o1", "law_refs": ["L-9"],
                 "segmentation": [{"id": "s1", "role": "subject", "text": "The driver"},
                                  {"id": "s2", "role": "obligation", "text": "shall stop at a clearly marked line"},
                                  {"id": "s3", "role": "sibling", "text": "The driver shall yield to traffic"}],
                 "elements": [{"span": "s1", "atoms": ["ru.motor_vehicle"]}, {"span": "s2", "atoms": ["st.stop_line"]}],
                 "narrowings": [narrowing]})


def gap_errors(node: Node, rejected: dict) -> list[str]:
    return [e for e in validate_a.check_narrowings(node, rejected, TEXT) if "names gap" in e]


def ledger_with(root: Path, *, occurrence: str | None, law: str = "L-9") -> GapLedger:
    g = GapLedger(root)
    root.mkdir(parents=True, exist_ok=True)
    gid = g.add({"kind": "atom", "span": "shall stop at a clearly marked line", "law_refs": [law], "proposal": "p",
                 **({"occurrence": occurrence} if occurrence else {})}, "r", 1)
    g.decide(gid, "rejected", "A represented line is the clearly marked one; paint clarity is not assessed.", resolved_by="particular")
    return g


class CitedGap(unittest.TestCase):

    def rejected(self, **kw) -> dict:
        with tempfile.TemporaryDirectory() as t:
            return ledger_with(Path(t), **kw).rejected()

    def test_a_reading_on_the_words_the_gap_was_filed_on(self):
        rej = self.rejected(occurrence=f"L-9@d:{LINE[0]}-{LINE[1]}")
        self.assertEqual(gap_errors(record({"span": "s2", "why": "w", "gap": "G1"}), rej), [])

    def test_a_decision_settles_only_its_own_words(self):
        rej = self.rejected(occurrence=f"L-9@d:{TEXT.index('yield')}-{len(TEXT)}")
        errs = gap_errors(record({"span": "s2", "why": "w", "gap": "G1"}), rej)
        self.assertTrue(errs and "other words of the law" in errs[0])

    def test_a_decision_on_another_law(self):
        rej = self.rejected(occurrence=None, law="L-8")
        self.assertTrue(gap_errors(record({"span": "s2", "why": "w", "gap": "G1"}), rej))

    def test_an_observable_reading_citing_a_gap_is_checked_too(self):
        n = record({"span": "s2", "why": "w", "kind": "observable_reading", "category": "status", "gap": "G7"})
        errs = gap_errors(n, self.rejected(occurrence=None))
        self.assertTrue(errs and "no rejected gap" in errs[0])

    def test_a_gap_recorded_without_an_occurrence_is_checked_for_its_law_only(self):
        self.assertEqual(gap_errors(record({"span": "s2", "why": "w", "gap": "G1"}), self.rejected(occurrence=None)), [])


class DecisionWords(unittest.TestCase):

    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.gaps = Path(self.tmp.name) / "gaps"
        ledger_with(self.gaps, occurrence=f"L-9@d:{LINE[0]}-{LINE[1]}")
        self.patch = mock.patch.object(paths, "GAPS_DIR", self.gaps)
        self.patch.start()

    def tearDown(self):
        self.patch.stop()
        self.tmp.cleanup()

    def test_the_block_shows_the_decision_and_the_words(self):
        block = GapLedger(self.gaps).cited_block({"narrowings": [{"span": "s2", "gap": "G1"}]})
        self.assertIn("paint clarity is not assessed", block)
        self.assertIn("shall stop at a clearly marked line", block)
        self.assertEqual(GapLedger(self.gaps).cited_block({"narrowings": [{"span": "s2"}]}), "")

    def test_stage_b_is_shown_the_decision_and_what_is_not_an_atom(self):
        c = ctx()
        c.record = {"node_id": "L_9_o1", "narrowings": [{"span": "s2", "gap": "G1"}]}
        c.not_atoms = ontology.not_atoms_text(ONTO)
        prompt = review.stage_b_prompt(FakeRun(Path(self.tmp.name)), c, "the item", {})
        self.assertIn("paint clarity is not assessed", prompt)
        self.assertIn("Not atoms", prompt)
        self.assertIn("Legal region classes", prompt)

    def test_the_reviewer_is_shown_the_decision_and_what_is_not_an_atom(self):
        run = FakeRun(Path(self.tmp.name))
        run.all_concepts = lambda: {}
        c = ctx()
        c.record = {"node_id": "L_1_o1", "narrowings": [{"span": "s1", "gap": "G1"}]}
        c.not_atoms = ontology.not_atoms_text(ONTO)
        seen = []
        inner = scripted_reviewer([submit({"verdict": "accept", "divergences": [], "advisories": [], "gap_candidates": []})])
        def run_tools(prompt, *a, **k):
            seen.append(prompt)
            return inner(prompt, *a, **k)
        node = Node({"node_id": "L_1_o1", "law_refs": ["L-1"], "binders": [{"name": "v"}],
                     "segmentation": [{"id": "s1", "role": "obligation", "text": "shall stop before the line"}]})
        with mock.patch.object(review, "build_context", lambda *_a, **_k: c), \
                mock.patch.object(review, "replay_obligations", lambda *_a, **_k: review.Replayed()), \
                mock.patch.object(review.session, "run_tools", run_tools):
            review.review_behaviour(run, node, ONE_LAW, ONTO, SimpleNamespace(data={"params": []}), {}, [], Path(self.tmp.name))
        self.assertTrue(seen)
        self.assertIn("paint clarity is not assessed", seen[0])
        self.assertIn("Legal region classes", seen[0])

    def test_the_node_repair_validates_against_the_rejected_gaps(self):
        seen = {}
        def validate(*a, **k):
            seen.update(k)
            return []
        n = record({"span": "s2", "why": "w", "gap": "G1"})
        d = Path(self.tmp.name) / "run"
        run = SimpleNamespace(iter=d, dir=d, iteration=2, mapping_file=d / "mapping.json",
                              opts=SimpleNamespace(dry_run=False, plan_turns=1, plan_effort="low", run_id="t", laws=d / "laws.jsonl"),
                              all_nodes=lambda: {}, all_concepts=lambda: {})
        last = d / "last"
        last.mkdir(parents=True)
        def session_run(*_a, cwd=None, **_k):
            (Path(cwd) / "record.jsonl").write_text(json.dumps({k: v for k, v in n.raw.items() if k not in ("node_id", "law_refs", "segmentation")}))
        blocks = {}
        defs = [{"id": "DEF-1", "title": "Two-directional highway", "text": "means an undivided highway", "split": "highways are two-directional"}]
        with mock.patch.object(plan_phase.session, "run", session_run), \
                mock.patch.object(validate_a, "validate", validate), \
                mock.patch.object(plan_phase.render, "render", lambda _name, b, **_k: blocks.update(b) or "prompt"), \
                mock.patch.object(plan_phase, "definitions_for", lambda _run, _laws: defs), \
                mock.patch.object(review, "upheld_block", lambda *_a, **_k: ""):
            reading = SimpleNamespace(data={"params": []}, params=[], pending_aggregates=False)
            plan_phase.run_node_repair(run, n, ["r"], last, LAW, [], [], reading, ONTO)
        self.assertIn("G1", seen.get("rejected_gaps") or {})
        # the repair is shown the definitions that apply, a term found split with its note
        self.assertIn("## Definitions that apply", blocks["definitions"])
        self.assertIn("DEF-1", blocks["definitions"])
        self.assertIn("Found split", blocks["definitions"])


class PreviousRecord(unittest.TestCase):

    def test_a_law_planned_again_sees_the_records_it_was_coded_from(self):
        with tempfile.TemporaryDirectory() as t, mock.patch.object(paths, "RESULTS", Path(t)):
            run = SimpleNamespace(iteration=3, opts=SimpleNamespace(run_id="r"))
            for it, nid, verdict in ((1, "L_9_o1", "CHECK_FAIL"), (2, "L_9_o1", "OK")):
                d = paths.iter_dir("r", it) / "code" / nid
                d.mkdir(parents=True)
                (d / "node.json").write_text(json.dumps({"node_id": nid, "law_refs": ["L-9"], "obligation": f"version {it}"}))
                (d / "verdict.json").write_text(json.dumps({"verdict": verdict, "details": [f"detail {it}"]}))
            block = plan_phase.previous_records(run, [LAW])
            self.assertIn("as coded in iteration 2", block)
            self.assertIn("version 2", block)
            self.assertNotIn("version 1", block)
            self.assertIn("gate OK", block)
            other = corpus.Law("L-7", "", "Another duty.", "")
            self.assertEqual(plan_phase.previous_records(run, [other]), "")

    def test_the_plan_prompt_has_the_section_and_its_rule(self):
        text = (paths.REPO / "prompts" / "plan.md").read_text(encoding="utf-8")
        self.assertIn("{previous_records}", text)
        self.assertIn("an upheld structural finding or another returned reason", text)


class DrivingDistinctions(unittest.TestCase):
    """The prompts that propose a gap or judge structural evidence share one closed list."""

    def test_each_prompt_states_the_list(self):
        for name in ("plan", "node_repair", "concept_repair", "review_code", "adjudicate"):
            text = " ".join((paths.REPO / "prompts" / f"{name}.md").read_text(encoding="utf-8").split())
            self.assertIn("where it is required, its time or order", text, name)
            self.assertIn("whether a plan can be carried out", text, name)

    def test_the_judges_are_given_what_is_not_an_atom(self):
        for name in ("review_code", "adjudicate"):
            self.assertIn("{not_atoms}", (paths.REPO / "prompts" / f"{name}.md").read_text(encoding="utf-8"), name)


if __name__ == "__main__":
    unittest.main()
