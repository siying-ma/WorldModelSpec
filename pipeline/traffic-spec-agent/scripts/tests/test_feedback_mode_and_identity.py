"""A new run names its feedback mode; a saved run that names none keeps the `review` meaning; the
review settings each record context and each review identity depend on follow the reviews the run
actually runs; a run another run version started is never resumed; and `verify` reports a check it
could not make as incomplete, never OK."""
import io
import json
import sys
import unittest
from pathlib import Path
from types import SimpleNamespace
from unittest import mock

sys.path.insert(0, str(Path(__file__).resolve().parent))

from harness import loop
from harness.phases import integrate, review
from harness.store import paths
from harness.store.state import FEEDBACK_MODES, Options, Run
from test_library_compatibility import Results, N


def opts(**kw):
    return Options(run_id="t", laws=Path("l"), ontology=Path("o"), reading=Path("r"), **kw)


class NewRunNamesItsFeedback(unittest.TestCase):
    def launch(self, run_id: str, **given):
        from harness.__main__ import Cli
        seen = []
        with mock.patch.object(loop, "run_loop", lambda o: seen.append(o) or {"status": "complete"}):
            Cli().loop(run_id, **given)
        return seen

    def test_a_new_run_without_feedback_is_refused_before_the_loop(self):
        with Results(), mock.patch.object(loop, "run_loop", lambda o: self.fail("the loop ran without a feedback mode")):
            from harness.__main__ import Cli
            with self.assertRaises(SystemExit) as cm:
                Cli().loop("new")
            for mode in FEEDBACK_MODES:
                self.assertIn(mode, str(cm.exception))
            self.assertIn("--feedback", str(cm.exception))
            with self.assertRaises(SystemExit) as cm:
                Cli().loop("new", feedback="none")
            self.assertIn("--feedback must be one of", str(cm.exception))
            self.assertFalse((paths.RESULTS / "new").exists())         # nothing written for the refused run

    def test_an_unknown_mode_is_refused_on_every_path(self):
        with Results() as r:
            r.run("odd", laws=["L-1"])
            o = json.loads((paths.RESULTS / "odd" / "options.json").read_text())
            (paths.RESULTS / "odd" / "options.json").write_text(json.dumps({**o, "feedback": "semantic"}))
            with mock.patch.object(loop, "run_loop", lambda o: self.fail("the loop ran on an unknown feedback mode")):
                from harness.__main__ import Cli
                with self.assertRaisesRegex(SystemExit, "must be one of review [|] labels"):
                    Cli().loop("odd")                                   # a saved unknown mode
                with self.assertRaisesRegex(SystemExit, "must be one of"):
                    Cli().loop("odd", feedback="")                      # a given unknown mode
            with mock.patch.object(loop, "Run", lambda *a: self.fail("the loop touched the run")):
                with self.assertRaisesRegex(SystemExit, "must be one of"):
                    loop._run_loop(opts(feedback="semantic"))           # the loop itself, before anything

    def test_a_new_run_naming_a_mode_reaches_the_loop(self):
        with Results():
            for mode in FEEDBACK_MODES:
                with self.subTest(mode=mode):
                    self.assertEqual([o.feedback for o in self.launch(f"new-{mode}", feedback=mode)], [mode])

    def test_a_saved_run_without_the_field_keeps_the_review_meaning(self):
        self.assertEqual(Options.__dataclass_fields__["feedback"].default, "review")
        with Results() as r:
            r.run("old", laws=["L-1"])                                 # options.json names no feedback mode
            self.assertNotIn("feedback", json.loads((paths.RESULTS / "old" / "options.json").read_text()))
            self.assertEqual([o.feedback for o in self.launch("old")], ["review"])
            o = json.loads((paths.RESULTS / "old" / "options.json").read_text())
            o.update({"ontology": str(r.tmp / "o.md"), "reading": str(r.tmp / "r.json")})
            (paths.RESULTS / "old" / "options.json").write_text(json.dumps(o))
            run = Run.load("old")
            self.assertEqual(run.opts.feedback, "review")


class RecordContext(unittest.TestCase):
    SEM = {"core": "c", "ontology": "o"}

    def base(self, **kw):
        return loop.context_base(opts(**kw), self.SEM)

    def test_labels_drop_the_node_review_passes(self):
        self.assertEqual(self.base(feedback="labels", review_passes=1), self.base(feedback="labels", review_passes=5))
        self.assertEqual(self.base(feedback="labels", max_divergences=1), self.base(feedback="labels", max_divergences=9))
        for k, a, b in (("judge_effort", "low", "high"), ("reviewer_model", "gpt-a", "gpt-b"), ("review_effort", "low", "high")):
            with self.subTest(setting=k):
                self.assertNotEqual(self.base(feedback="labels", **{k: a}), self.base(feedback="labels", **{k: b}))

    def test_review_keeps_its_context_as_before(self):
        self.assertNotEqual(self.base(feedback="review", review_passes=1), self.base(feedback="review", review_passes=5))
        o = opts(feedback="review", reviewer_model="gpt", review_effort="high", judge_effort="medium", review_passes=2)
        self.assertEqual(loop.context_base(o, self.SEM)["review"], ["gpt", "high", "medium", 2])   # the saved contexts of old runs still match

    def test_every_mode_has_its_settings(self):
        self.assertEqual(set(loop.CONTEXT_REVIEW_SETTINGS), set(FEEDBACK_MODES))


class ReviewIdentity(unittest.TestCase):
    def run_(self, tmp: Path, **kw):
        (tmp / "reading.json").write_text(json.dumps({"params": []}))
        return SimpleNamespace(opts=opts(**kw), iteration=1, reading_file=tmp / "reading.json")

    def concept_id(self, tmp: Path, **kw):
        rec = SimpleNamespace(raw={"concept_id": "c.x"}, id="c.x")
        with mock.patch.object(review, "_concept_context", lambda *a: "ctx"), \
             mock.patch.object(review, "concept_lineage", lambda *a: ["c.x"]):
            return review.concept_inputs(self.run_(tmp, **kw), rec, {"body_json": {}}, {"b": "shown"}, [])

    def node_id(self, tmp: Path, **kw):
        n = SimpleNamespace(raw={"node_id": "L_1"})
        law = SimpleNamespace(id="L-1", title="t", text="shall stop.")
        ctx = SimpleNamespace(law=law, precedents=[], rulings=[], record={})
        gaps = SimpleNamespace(for_run=lambda *a: SimpleNamespace(cited_block=lambda rec: ""))
        with mock.patch.object(review, "_pass_context", lambda *a: "ctx"), mock.patch.object(review, "GapLedger", gaps):
            return review.review_inputs(self.run_(tmp, **kw), n, law, SimpleNamespace(data={}), {}, ctx, [])

    def test_the_concept_identity_ignores_the_node_review_settings(self):
        import tempfile
        with tempfile.TemporaryDirectory() as t:
            tmp = Path(t)
            for feedback in FEEDBACK_MODES:
                with self.subTest(feedback=feedback):
                    ref = self.concept_id(tmp, feedback=feedback)
                    self.assertEqual(ref, self.concept_id(tmp, feedback=feedback, review_passes=7))
                    self.assertEqual(ref, self.concept_id(tmp, feedback=feedback, max_divergences=9))
                    for k, v in (("model", "claude-other"), ("judge_effort", "max"), ("reviewer_model", "gpt-other"),
                                 ("review_effort", "low"), ("review_checks", 2), ("review_submissions", 1)):
                        self.assertNotEqual(ref, self.concept_id(tmp, feedback=feedback, **{k: v}), k)

    def test_the_node_review_identity_keeps_every_setting_it_uses(self):
        import tempfile
        with tempfile.TemporaryDirectory() as t:
            tmp = Path(t)
            ref = self.node_id(tmp, feedback="review")
            for k, v in (("review_passes", 7), ("max_divergences", 9), ("model", "claude-other"), ("judge_effort", "max"),
                         ("reviewer_model", "gpt-other"), ("review_effort", "low"), ("review_checks", 2), ("review_submissions", 1)):
                self.assertNotEqual(ref, self.node_id(tmp, feedback="review", **{k: v}), k)


class RunVersion(unittest.TestCase):
    def test_the_semantic_inputs_carry_the_run_version(self):
        self.assertIsNone(loop.run_version_refusal({"run_version": loop.RUN_VERSION}))
        for saved in (None, {}, {"core": "c"}, {"run_version": loop.RUN_VERSION - 1}):
            with self.subTest(saved=saved):
                why = loop.run_version_refusal(saved)
                self.assertIn(f"version {loop.RUN_VERSION}", why)
                self.assertIn("start a new run id", why)

    def test_a_run_another_version_started_is_refused_before_anything_is_touched(self):
        from test_recovery import Fixture, life_cycle, tree_bytes
        w = life_cycle()
        w.crash_at = 60
        with Fixture(w) as f:
            self.assertEqual(f.drive(launches=1), ["crash"])
            saved_f = paths.run_dir("r") / "options.json"
            saved = json.loads(saved_f.read_text())
            self.assertEqual(saved["semantic"]["run_version"], loop.RUN_VERSION)
            del saved["semantic"]["run_version"]                     # a run recorded before run versions
            saved_f.write_text(json.dumps(saved))
            before = tree_bytes(paths.RESULTS)
            with self.assertRaises(SystemExit) as cm:
                loop.run_loop(f.options())
            self.assertIn("cannot be resumed", str(cm.exception))
            self.assertIn("recorded before run versions", str(cm.exception))
            self.assertEqual(tree_bytes(paths.RESULTS), before)

    def test_a_handed_over_run_of_another_version_is_refused(self):
        from harness.tools import handoff
        from test_split_handoff import Pinning
        with Pinning().repo() as (_root, rd):
            handoff.export("r", source_baseline="c0ffee")
            self.assertEqual(handoff.verify("r", artifacts=False)[0], [])
            mf = rd / "handoff" / "manifest.json"
            m = json.loads(mf.read_text())
            del m["semantic"]["run_version"]
            mf.write_text(json.dumps(m))
            refusals, _w = handoff.verify("r", artifacts=False)
            self.assertEqual(len(refusals), 1, refusals)
            self.assertIn("another run version", refusals[0])


class VerifyOnAnOldReviewRun(unittest.TestCase):
    """A saved review-mode run with an upheld node obligation whose certificate program cannot run:
    the obligation is unresolved (the record neither fenced nor given a context), and `verify`
    reports the result as incomplete with exit 1, never OK."""

    def test_an_uncertifiable_obligation_leaves_verify_incomplete(self):
        from harness.__main__ import Cli
        from harness.model import nodeid
        from harness.lean import index_sync

        def cannot(*_a, **_k):
            raise review.HarnessFailure("the certificate program is not available")
        with Results() as r:
            r.run("A", laws=["L-1"], nodes={"L_1": {**N("L_1", "L-1"), "binders": []}},
                  rulings=[{"subject": "L_1", "ruling": "upheld", "iteration": 1, "stage_a": {"verdict": "violated"}}])
            o = json.loads((paths.RESULTS / "A" / "options.json").read_text())
            o.update({"ontology": str(r.tmp / "o.md"), "reading": str(r.tmp / "r.json")})
            (paths.RESULTS / "A" / "options.json").write_text(json.dumps(o))
            (paths.RESULTS / "A" / "reading.json").write_text(json.dumps({"params": []}))
            lib = r.tmp / "library"
            (lib / nodeid.rule_path("L_1")).parent.mkdir(parents=True, exist_ok=True)
            (lib / nodeid.rule_path("L_1")).write_text("rule")
            out = io.StringIO()
            with mock.patch.object(paths, "LIBRARY", lib), \
                 mock.patch("harness.store.owner.acquire_for_command", lambda name: None), \
                 mock.patch.object(integrate, "admission_recheck", lambda *a, **k: {}), \
                 mock.patch.object(integrate, "verify_library", lambda *a, **k: ("verified", [], set())), \
                 mock.patch.object(loop, "semantic_inputs", lambda opts: {"core": "c", "ontology": "o"}), \
                 mock.patch.object(index_sync, "set_inactive", lambda ids, run_id: True), \
                 mock.patch.object(review, "obligations_of", lambda run, n, law, *a, **k: [({"iteration": 1}, True)]), \
                 mock.patch.object(review, "_to_node", lambda row, binders: ({"trace": {}}, "")), \
                 mock.patch.object(review, "certify", cannot), \
                 mock.patch("sys.stdout", out):
                code = Cli().verify("A")
            text = out.getvalue()
        self.assertEqual(code, 1)
        self.assertNotIn("OK", text)
        self.assertIn("incomplete", text)
        self.assertIn("the certificate program did not run", text)
        self.assertIn("node semantic review: the only check is the old behaviour review's upheld obligations", text)


if __name__ == "__main__":
    unittest.main()
