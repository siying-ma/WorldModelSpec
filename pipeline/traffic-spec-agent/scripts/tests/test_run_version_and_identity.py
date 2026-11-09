"""The harness has no feedback mode: a gated node is accepted on its gate, its law by the label check
when `label_repair` is on, and the acceptance policy is `label_repair` alone, held whole. A run is
read only by the run version that started it: an ordinary resume, `Run.load` (every command that
loads a run), `verify`, a handoff's export, verification and import, and a `--base_run` chain refuse
another version's run, or one that records none, on its raw saved options, before anything of it is
recovered, restored or written. The review settings each record context and each concept review
identity depend on are those the concept review uses, and `verify` states the checks it covers."""
import io
import json
import sys
import tempfile
import unittest
from pathlib import Path
from types import SimpleNamespace
from unittest import mock

sys.path.insert(0, str(Path(__file__).resolve().parent))

from harness import loop
from harness.phases import candidate, integrate, review
from harness.store import owner, paths
from harness.store.state import (Options, Run, RUN_VERSION, acceptance_by_law, acceptance_policy, chain_version_refusal, policy_defects,
                                 run_version_refusal, saved_version_refusal)
from test_library_compatibility import Results, N


def opts(**kw):
    return Options(run_id="t", laws=Path("l"), ontology=Path("o"), reading=Path("r"), **kw)


def tree(root: Path) -> dict:
    return {str(f.relative_to(root)): f.read_bytes() for f in sorted(root.rglob("*")) if f.is_file()}


def version(name: str, v) -> None:
    """The run `name` (written by `Results.run`) marked as started by run version `v` (None: no version
    recorded); a version-2 run also records the feedback mode it ran under."""
    f = paths.RESULTS / name / "options.json"
    o = json.loads(f.read_text())
    o["semantic"] = {"core": "c"} if v is None else {"core": "c", "run_version": v}
    o["label_repair"] = True
    if v == 2:
        o["feedback"] = "labels"
    f.write_text(json.dumps(o))


class NoFeedbackOption(unittest.TestCase):
    def test_the_option_is_gone(self):
        self.assertNotIn("feedback", Options.__dataclass_fields__)
        with Results(), mock.patch.object(loop, "run_loop", lambda o: self.fail("the loop ran")):
            from harness.__main__ import Cli
            with self.assertRaisesRegex(SystemExit, "unknown option"):
                Cli().loop("new", feedback="labels")
            self.assertFalse((paths.RESULTS / "new").exists())         # nothing written for the refused launch

    def test_a_new_run_names_no_mode(self):
        seen = []
        with Results(), mock.patch.object(loop, "run_loop", lambda o: seen.append(o) or {"status": "complete"}):
            from harness.__main__ import Cli
            Cli().loop("new", label_repair=True)
        self.assertEqual([o.label_repair for o in seen], [True])

    def test_the_policy_is_label_repair_held_whole(self):
        self.assertEqual(acceptance_policy(opts(label_repair=True)), {"label_repair": True})
        self.assertEqual(policy_defects({"label_repair": False}), [])
        for saved in ({}, {"feedback": "labels"}, {"label_repair": 1}, {"label_repair": "true"}, {"label_repair": None}, None):
            with self.subTest(saved=saved):
                self.assertTrue(policy_defects(saved))             # never completed by a default
        self.assertTrue(acceptance_by_law(opts(label_repair=True)))
        self.assertFalse(acceptance_by_law(opts(label_repair=False)))


class RecordContext(unittest.TestCase):
    SEM = {"core": "c", "ontology": "o"}

    def test_the_concept_review_settings(self):
        o = opts(reviewer_model="gpt", review_effort="high", judge_effort="medium")
        self.assertEqual(loop.context_base(o, self.SEM), {"core": "c", "ontology": "o", "review": ["gpt", "high", "medium"]})
        for k, a, b in (("judge_effort", "low", "high"), ("reviewer_model", "gpt-a", "gpt-b"), ("review_effort", "low", "high")):
            with self.subTest(setting=k):
                self.assertNotEqual(loop.context_base(opts(**{k: a}), self.SEM), loop.context_base(opts(**{k: b}), self.SEM))


class ConceptReviewIdentity(unittest.TestCase):
    def run_(self, tmp: Path, **kw):
        (tmp / "reading.json").write_text(json.dumps({"params": []}))
        return SimpleNamespace(opts=opts(**kw), iteration=1, reading_file=tmp / "reading.json")

    def concept_id(self, tmp: Path, **kw):
        rec = SimpleNamespace(raw={"concept_id": "c.x"}, id="c.x")
        with mock.patch.object(review, "_concept_context", lambda *a: "ctx"), \
             mock.patch.object(review, "concept_lineage", lambda *a: ["c.x"]):
            return review.concept_inputs(self.run_(tmp, **kw), rec, {"body_json": {}}, {"b": "shown"}, [])

    def test_the_identity_keeps_every_setting_the_concept_review_uses(self):
        with tempfile.TemporaryDirectory() as t:
            tmp = Path(t)
            ref = self.concept_id(tmp)
            for k, v in (("model", "claude-other"), ("judge_effort", "max"), ("reviewer_model", "gpt-other"),
                         ("review_effort", "low"), ("review_checks", 2), ("review_submissions", 1)):
                self.assertNotEqual(ref, self.concept_id(tmp, **{k: v}), k)


class RunVersion(unittest.TestCase):
    def test_only_this_version_is_read(self):
        self.assertEqual(RUN_VERSION, 3)
        self.assertIs(loop.RUN_VERSION, RUN_VERSION)
        self.assertIsNone(run_version_refusal({"run_version": RUN_VERSION}))
        for saved in (None, {}, {"core": "c"}, {"run_version": 2}, {"run_version": "3"}, {"run_version": 4}, "3"):
            with self.subTest(saved=saved):
                why = run_version_refusal(saved)
                self.assertIn(f"version {RUN_VERSION}", why)
                self.assertIn("start a new run id", why)

    def test_unreadable_or_missing_options_are_refused(self):
        with tempfile.TemporaryDirectory() as t:
            d = Path(t)
            self.assertIn("missing", saved_version_refusal(d))
            (d / "options.json").write_text("not json")
            self.assertIn("cannot be read", saved_version_refusal(d))
            (d / "options.json").write_text(json.dumps({"semantic": {"run_version": RUN_VERSION}}))
            self.assertIsNone(saved_version_refusal(d))

    def test_a_resume_of_another_version_is_refused_before_anything_is_touched(self):
        from test_recovery import Fixture, life_cycle
        for v in (None, 2):
            with self.subTest(version=v):
                w = life_cycle()
                w.crash_at = 60
                with Fixture(w) as f:
                    self.assertEqual(f.drive(launches=1), ["crash"])
                    saved_f = paths.run_dir("r") / "options.json"
                    saved = json.loads(saved_f.read_text())
                    self.assertEqual(saved["semantic"]["run_version"], RUN_VERSION)
                    if v is None:
                        del saved["semantic"]["run_version"]                   # a run recorded before run versions
                    else:
                        saved["semantic"]["run_version"], saved["feedback"] = v, "labels"   # a version-2 labels run
                    saved_f.write_text(json.dumps(saved))
                    before = tree(paths.RESULTS)
                    with mock.patch.object(loop, "metadata_refusal", lambda run: self.fail("the run was read whole")), \
                            mock.patch.object(candidate, "recover", lambda run: self.fail("a pending transaction was recovered")):
                        with self.assertRaises(SystemExit) as cm:
                            loop.run_loop(f.options())
                    self.assertIn("cannot be resumed", str(cm.exception))
                    self.assertIn("recorded before run versions" if v is None else "run version 2", str(cm.exception))
                    self.assertEqual(tree(paths.RESULTS), before)

    def test_run_load_refuses_before_a_pending_transaction_is_recovered(self):
        with Results() as r, tempfile.TemporaryDirectory() as lib:
            r.run("old", laws=["L-1"])
            version("old", 2)
            pointer = Path(lib) / owner.PENDING_FILE
            pointer.write_text(json.dumps({"journal": str(Path(lib) / "journal.json")}))
            (Path(lib) / "journal.json").write_text(json.dumps({"status": "committed"}))
            before = (tree(paths.RESULTS), tree(Path(lib)))
            with mock.patch.object(paths, "LIBRARY", Path(lib)), \
                    mock.patch.object(candidate, "recover_pending", lambda: self.fail("a pending transaction was recovered")):
                with self.assertRaisesRegex(SystemExit, "run version 2"):
                    Run.load("old")
            self.assertEqual((tree(paths.RESULTS), tree(Path(lib))), before)

    def test_a_base_chain_holding_another_version_is_refused(self):
        with Results() as r:
            r.run("A", laws=["L-1"], nodes={"L_1": N("L_1", "L-1")})
            r.run("B", base="A", laws=["L-2"])
            r.run("C", base="B", laws=["L-3"])
            version("A", 2); version("B", RUN_VERSION); version("C", RUN_VERSION)
            for base in ("A", "B", "C"):                                     # the old run anywhere down the chain
                with self.subTest(base=base):
                    self.assertIn("names `A`", chain_version_refusal(base, "new"))
            version("A", RUN_VERSION)
            self.assertIsNone(chain_version_refusal("C", "new"))
            version("A", None)
            self.assertIn("names `A`", chain_version_refusal("C", "new"))
            before = tree(paths.RESULTS)
            with self.assertRaisesRegex(SystemExit, "names `A`"):          # a new run on it, before anything is written
                loop.run_loop(Options(run_id="D", laws=Path("l"), ontology=Path("o"), reading=Path("r"), base_run="C"))
            with self.assertRaisesRegex(SystemExit, "names `A`"):          # a command loading a run on it
                Run.load("C")
            self.assertEqual(tree(paths.RESULTS), before)

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
            o = json.loads((rd / "options.json").read_text())             # the saved options of a version-2 run, the manifest's too
            o["semantic"]["run_version"], m["semantic"]["run_version"] = 2, 2
            (rd / "options.json").write_text(json.dumps(o)); mf.write_text(json.dumps(m))
            refusals, _w = handoff.verify("r", artifacts=False)
            self.assertTrue(any("saved options are of another run version" in x for x in refusals), refusals)
            before = tree(rd)
            with mock.patch("harness.store.owner.acquire_for_command", lambda name: self.fail("the library was taken")):
                with self.assertRaisesRegex(SystemExit, "cannot be exported"):
                    handoff.export("r", source_baseline="c0ffee")
            self.assertEqual(tree(rd), before)


class Verify(unittest.TestCase):
    def setUp(self):
        from harness.lean import index_sync
        self.patches = [mock.patch("harness.store.owner.acquire_for_command", lambda name: None),
                        mock.patch.object(integrate, "admission_recheck", lambda *a, **k: {}),
                        mock.patch.object(integrate, "verify_library", lambda *a, **k: ("verified", [], set())),
                        mock.patch.object(loop, "semantic_inputs", lambda opts: {"core": "c", "ontology": "o"}),
                        mock.patch.object(index_sync, "set_inactive", lambda ids, run_id: True)]

    def verify(self, r, name: str, unchanged: bool = False) -> tuple[int, str]:
        """`verify` on the run `name`; with `unchanged`, the results tree is the same after it."""
        from harness.__main__ import Cli
        from harness.model import nodeid
        o = json.loads((paths.RESULTS / name / "options.json").read_text())
        o.update({"ontology": str(r.tmp / "o.md"), "reading": str(r.tmp / "r.json")})
        (paths.RESULTS / name / "options.json").write_text(json.dumps(o))
        (paths.RESULTS / name / "reading.json").write_text(json.dumps({"params": []}))
        lib = r.tmp / "library"
        (lib / nodeid.rule_path("L_1")).parent.mkdir(parents=True, exist_ok=True)
        (lib / nodeid.rule_path("L_1")).write_text("rule")
        out = io.StringIO()
        before = tree(paths.RESULTS)
        with mock.patch.object(paths, "LIBRARY", lib), mock.patch("sys.stdout", out):
            for p in self.patches:
                p.start()
            try:
                code = Cli().verify(name)
            finally:
                for p in self.patches:
                    p.stop()
        if unchanged:
            self.assertEqual(tree(paths.RESULTS), before)
        return code, out.getvalue()

    def test_an_older_run_is_refused_and_nothing_is_certified(self):
        with Results() as r:
            r.run("A", laws=["L-1"], nodes={"L_1": N("L_1", "L-1")},
                  rulings=[{"subject": "L_1", "ruling": "upheld", "iteration": 1, "stage_a": {"verdict": "violated"}}])
            version("A", 2)
            with mock.patch.object(integrate, "recheck_contexts", lambda *a, **k: self.fail("a record was checked again")), \
                    mock.patch.object(Run, "load", lambda *a, **k: self.fail("the run was loaded")):
                code, text = self.verify(r, "A", unchanged=True)
        self.assertEqual(code, 1)
        self.assertIn("unsupported run version; certification not executed", text)
        self.assertNotIn("OK", text)

    def test_unreadable_options_are_named_apart(self):
        with Results() as r:
            r.run("A", laws=["L-1"])
            (paths.RESULTS / "A" / "options.json").write_text("{not json")
            from harness.__main__ import Cli
            out = io.StringIO()
            with mock.patch("harness.store.owner.acquire_for_command", lambda name: self.fail("the library was taken")), \
                    mock.patch("sys.stdout", out):
                code = Cli().verify("A")
        self.assertEqual(code, 1)
        self.assertIn("the run's saved options cannot be read; certification not executed", out.getvalue())

    def test_this_version_states_what_it_covers(self):
        with Results() as r:
            r.run("A", laws=["L-1"], nodes={"L_1": N("L_1", "L-1")})
            version("A", RUN_VERSION)
            code, text = self.verify(r, "A")
        self.assertEqual(code, 0, text)
        self.assertIn("OK", text)
        self.assertIn("checks covered: the gate of every accepted record (admission), the witnesses", text)
        self.assertIn("concept review", text)
        self.assertIn("no node semantic review exists in this harness, and none is certified", text)



class OtherCommands(unittest.TestCase):
    """`gate`, `score_split`, `label_check` and `reopen` read a stored run's raw version (and its base
    chain's) before they take the library or read anything else of it: a version-2 run is refused, and
    neither the run directory nor the library changes."""

    def check(self, call):
        with Results() as r, tempfile.TemporaryDirectory() as lib:
            r.run("A", laws=["L-1"], nodes={"L_1": N("L_1", "L-1")})
            r.run("B", base="A", laws=["L-2"])
            version("A", 2)
            (Path(lib) / "x.lean").write_text("kept")
            for run_id in ("A", "B"):                                       # the old run itself, and a run over it
                with self.subTest(run=run_id):
                    before = (tree(paths.RESULTS), tree(Path(lib)))
                    with mock.patch.object(paths, "LIBRARY", Path(lib)), \
                            mock.patch("harness.store.owner.acquire_for_command", lambda name: self.fail("the library was taken")), \
                            mock.patch("harness.store.owner.acquire", lambda *a, **k: self.fail("the library was taken")), \
                            mock.patch.object(Run, "load", lambda *a, **k: self.fail("the run was loaded")):
                        with self.assertRaisesRegex(SystemExit, "run version 2"):
                            call(run_id)
                    self.assertEqual((tree(paths.RESULTS), tree(Path(lib))), before)

    def test_gate(self):
        from harness.__main__ import Cli
        from harness.phases import code as code_phase
        with mock.patch.dict("os.environ", {}, clear=False) as env:
            env.pop("TRAFFIC_SPEC_OWNER", None)
            self.check(lambda rid: Cli().gate(rid, "L_1"))
            self.check(lambda rid: code_phase.gate_from_cli(rid, "L_1"))

    def test_score_split(self):
        from harness.tools import score_split
        with tempfile.TemporaryDirectory() as t:
            split = Path(t) / "split.json"
            split.write_text(json.dumps({"test_only_atoms": [], "test_only_values": []}))
            self.check(lambda rid: score_split.score(rid, split))

    def test_label_check(self):
        from harness.__main__ import Cli
        self.check(lambda rid: Cli().label_check(rid))

    def test_reopen(self):
        from harness.__main__ import Cli
        self.check(lambda rid: Cli().reopen(rid))


if __name__ == "__main__":
    unittest.main()
