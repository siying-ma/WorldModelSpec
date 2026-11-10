"""Development regression tests for the review's identities: a duty as an occurrence in the law, a
ruling's identity, a concept challenge's replay through its formals, dependency reports, and
outcome counts."""
import json
import tempfile
import unittest
from pathlib import Path
from types import SimpleNamespace

from harness.model import corpus
from harness.model.blueprint import Node
from harness.phases import review
from harness.store.ledger import Ledger

TWO = corpus.Law("L-2", "", "At a red marker the driver shall stop. At a blue marker the driver shall stop.", "")


def two_nodes():
    seg = lambda first: [{"id": "s1", "role": "condition" if first else "sibling", "text": "At a red marker"},
                         {"id": "s2", "role": "subject" if first else "sibling", "text": "the driver"},
                         {"id": "s3", "role": "obligation" if first else "sibling", "text": "shall stop."},
                         {"id": "s4", "role": "sibling" if first else "condition", "text": "At a blue marker"},
                         {"id": "s5", "role": "sibling" if first else "subject", "text": "the driver"},
                         {"id": "s6", "role": "sibling" if first else "obligation", "text": "shall stop."}]
    return (Node({"node_id": "L_2_o1", "law_refs": ["L-2"], "segmentation": seg(True), "binders": [{"name": "v"}]}),
            Node({"node_id": "L_2_o2", "law_refs": ["L-2"], "segmentation": seg(False), "binders": [{"name": "v"}]}))


class Duty(unittest.TestCase):
    def test_identical_words_are_two_duties(self):
        a, b = two_nodes()
        da, db = review.duty_of(a, TWO), review.duty_of(b, TWO)
        self.assertNotEqual(da["id"], db["id"])
        self.assertEqual(da["words"], db["words"])
        self.assertIn("red marker", da["context"])
        self.assertIn("blue marker", db["context"])


class Identity(unittest.TestCase):
    def test_a_ruling_is_a_concept_challenge_or_finding(self):
        row = lambda **kw: {"key": "concept:drv.x", "subject": "drv.x", **kw}
        self.assertEqual(review.ruling_identity(row(case_id="c")), review.ruling_identity({**row(case_id="c"), "subject": "drv.x_v2"}))
        self.assertEqual(review.ruling_identity(row(finding_id="f", finding_root="r")), ("concept_finding", "f"))
        self.assertIsNone(review.ruling_identity({"key": "law:L-1", "case_id": "c", "duty": "d1"}))   # a row of no concept supersedes nothing


class Streak(unittest.TestCase):
    def test_an_outcome_counts_up_to_its_limit(self):
        with tempfile.TemporaryDirectory() as t:
            led = Ledger(Path(t) / "l.jsonl", ["L"], 2)
            self.assertEqual(led.record_outcomes("L", ["gate:UNEXPRESSED:L@d:1-2"], limit=2), [])
            self.assertEqual(led.record_outcomes("L", ["gate:UNEXPRESSED:L@d:1-2", "gate:UNEXPRESSED:L@d:3-4"], limit=2),
                             ["gate:UNEXPRESSED:L@d:1-2 ×2"])
            with self.assertRaises(TypeError):
                led.record_outcomes("L", ["k"])                               # the limit is always the caller's


class ConceptChallenges(unittest.TestCase):
    """A concept challenge is read at `at`; nat formals are instantiated; upheld challenges are
    replayed through a typed formal correspondence."""
    def rec(self, **kw):
        from harness.model.blueprint import ConceptRecord
        return ConceptRecord({"concept_id": "drv.motion.x_v2", "kind": "formula", "contract": "c holds",
                              "args": [{"name": "u", "sort": "track"}, {"name": "n", "sort": "nat"}], "params": [], **kw})

    def div(self, **kw):
        return {"kind": "holds_wrongly", "contract_verdict": "fails", "contract_words": "c holds", "situation": "s",
                "instance": {"literals": {}, "nats": {"n": 2}, "params": {}}, "grounding": {"u": 1},
                "trace": {"scenes": [{"t": 0}, {"t": 100}]}, "at": 100, **kw}

    def test_at_must_be_an_observation_and_nats_are_filled(self):
        rec = self.rec()
        self.assertEqual(review.concept_divergence_defects(1, self.div(), rec, "c holds"), [])
        self.assertTrue(review.concept_divergence_defects(1, self.div(at=50), rec, "c holds"))
        self.assertTrue(review.concept_divergence_defects(1, self.div(instance={"literals": {}, "params": {}}), rec, "c holds"))

    def test_a_superseded_concepts_challenge_is_replayed_only_through_its_formals(self):
        with tempfile.TemporaryDirectory() as t:
            run = SimpleNamespace(dir=Path(t), iteration=2, iter=Path(t) / "iter-002", reading_file=Path(t) / "reading.json",
                                  all_nodes=lambda: {}, all_concepts=lambda: {})
            run.reading_file.write_text(json.dumps({"params": [], "aggregates": []}))
            old = {"key": "concept:drv.motion.x", "schema": review.CONCEPT_CASE_SCHEMA, "ruling": "upheld", "obligation": "open",
                   "subject": "drv.motion.x", "iteration": 1, "case_id": "k1", **{f: v for f, v in self.div().items()}}
            review.append_ruling(run, old)
            review.append_ruling(run, {**old, "case_id": "k2", "grounding": {"w": 1}})            # an argument the new concept lacks
            ran = []
            saved = review.execute_concept_divergences
            review.execute_concept_divergences = lambda rec, a, out, dim, reading=None, **_k: (ran.extend(a["divergences"]) or ([], [], [], []))
            try:
                rep = review.replay_concept(run, self.rec(supersedes="drv.motion.x"), Path(t) / "r", None, "b")
            finally:
                review.execute_concept_divergences = saved
            self.assertEqual(len(ran), 1)                                   # the corresponding one is run
            self.assertEqual([c["case_id"] for c in rep.carry], ["k2"])     # the other is an obligation to carry over
            self.assertIn("do not correspond", rep.carry[0]["why"])


class DependencyReports(unittest.TestCase):
    """A coder's report that a concept it reaches is wrong is adjudicated before anyone is charged."""
    CONCEPT = {"concept_id": "drv.motion.x", "kind": "formula", "contract": "c holds", "args": [{"name": "u", "sort": "track"}],
               "params": [], "body_json": {"tt": True}}

    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        d = Path(self.tmp.name)
        self.run = SimpleNamespace(dir=d, iteration=3, iter=d / "iter-003", reading_file=d / "reading.json", all_nodes=lambda: {},
                                   all_concepts=lambda: {"drv.motion.x": self.CONCEPT})
        self.run.reading_file.write_text(json.dumps({"params": [], "aggregates": []}))
        self.saved = (review.execute_concept_divergences, review.adjudicate_concept, review.concept_blocks)
        review.concept_blocks = lambda run, rec, extras: ({}, "", "")

    def tearDown(self):
        review.execute_concept_divergences, review.adjudicate_concept, review.concept_blocks = self.saved
        self.tmp.cleanup()

    def report(self, **kw):
        d = {"concept_id": "drv.motion.x", "kind": "holds_wrongly", "contract_verdict": "fails", "contract_words": "c holds", "situation": "s",
             "instance": {"literals": {}, "params": {}}, "grounding": {"u": 1}, "trace": {"scenes": [{"t": 0}]}, "at": 0, **kw}
        (Path(self.tmp.name) / "dependency_defect.json").write_text(json.dumps(d))

    def judge(self, reached={"drv.motion.x"}):
        return review.dependency_report(self.run, Path(self.tmp.name), reached)

    def test_no_report_unreached_and_agreeing(self):
        self.assertEqual(self.judge().status, "none")
        self.report()
        self.assertEqual(self.judge(reached=set()).status, "protocol")
        review.execute_concept_divergences = lambda *a, **k: ([], ["divergence 1: the body agrees"], [], [])
        self.assertEqual(self.judge().status, "protocol")

    def test_upheld_and_dismissed(self):
        self.report()
        item = {"line": "the case", "div": {}}
        review.execute_concept_divergences = lambda *a, **k: ([item], [], [], [])
        review.adjudicate_concept = lambda *a, **k: [(item, "upheld", "the contract excludes it")]
        self.assertEqual(self.judge().status, "upheld")
        review.adjudicate_concept = lambda *a, **k: [(item, "dismissed", "the contract admits it")]
        self.assertEqual(self.judge().status, "dismissed")

    def test_a_defective_version_is_refused_and_charged_once(self):
        from harness.checks import validate_a
        from harness.store.ledger import Ledger
        from harness.model.blueprint import Node
        n = Node({"node_id": "L_1", "law_refs": ["L-1"], "elements": [{"span": "s1", "derived": ["drv.motion.x"]}], "operationalizations": []})
        onto = SimpleNamespace(knows=lambda i: False, primitive_ids=set(), atom_ids=set())
        errs, _g = validate_a.check_closed_set(n, onto, {"drv.motion.x"}, {"drv.motion.x": {"kind": "concept", "reason": "dependency_defect"}})
        self.assertTrue(any("found defective" in e for e in errs))
        led = Ledger(Path(self.tmp.name) / "l.jsonl", ["L-1"], 3); led.attempt = 1
        led.mark_planned("L-1", ["L_1"], 1)
        led.return_for_concepts("L-1", ["drv.motion.x"], ["defective"], 1)
        led.attempt = 2; led.mark_planned("L-1", ["L_1"], 2)
        led.return_for_concepts("L-1", ["drv.motion.x"], ["defective again"], 2)
        self.assertEqual((led.entries["L-1"].attempts, led.entries["L-1"].dependency_returns), (0, 1))


def at(a, *args):
    return {"atom": a, "args": [{"var": x} for x in args], "params": []}


if __name__ == "__main__":
    unittest.main()
