"""Development regression tests for library compatibility: a continuation's effective base view
and its fences, the obligations of inherited records, the admission recheck and its fence closure,
the operational selection every registry build reads, the subset continuation run as printed, the
inputs of a record's context and of the caches keyed on it, and integration's dependency-ordered
fallback."""
import collections
import contextlib
import json
import re
import shutil
import sys
import tempfile
import unittest
from pathlib import Path
from types import SimpleNamespace
from unittest import mock

sys.path.insert(0, str(Path(__file__).resolve().parent))

from harness import loop
from harness.checks import gate, validate_a
from harness.lean import index_sync, lean
from harness.model import nodeid
from harness.model.blueprint import ConceptRecord, Node
from harness.model.reading import Reading
from harness.phases import code as code_phase, integrate, plan as plan_phase, review
from harness.store import jsonl, paths
from harness.store.state import Options, Run, base_view

import test_recovery as R

def active(run) -> set[str]:
    """The effective records the operational library is built from: every one not fenced."""
    return (set(run.all_nodes()) | set(run.all_concepts())) - set(run.fenced)



def _laws(path: Path, ids: list[str]) -> Path:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("".join(json.dumps({"id": i, "title": i, "text": f"{i} text", "source": "s"}) + "\n" for i in ids))
    return path


class Results:
    """A temporary results directory holding runs written directly."""

    def __init__(self):
        self.tmp = Path(tempfile.mkdtemp(prefix="compat-"))
        self.patch = mock.patch.object(paths, "RESULTS", self.tmp / "results")

    def __enter__(self):
        self.patch.start()
        paths.RESULTS.mkdir(parents=True)
        return self

    def __exit__(self, *exc):
        self.patch.stop()
        return False

    def run(self, name: str, *, base: str | None = None, laws: list[str] = (), nodes: dict | None = None,
            concepts: dict | None = None, state: dict | None = None, rulings: list[dict] | None = None) -> Path:
        d = paths.RESULTS / name
        d.mkdir(parents=True)
        lf = _laws(d / "laws" / "laws.jsonl", list(laws))
        (d / "options.json").write_text(json.dumps({"run_id": name, "base_run": base, "laws": str(lf)}))
        (d / "accepted_nodes.jsonl").write_text("".join(json.dumps(v) + "\n" for v in (nodes or {}).values()))
        (d / "accepted_concepts.jsonl").write_text("".join(json.dumps(v) + "\n" for v in (concepts or {}).values()))
        if state is not None:
            (d / "state.json").write_text(json.dumps(state))
        if rulings is not None:
            (d / "rulings.jsonl").write_text("".join(json.dumps(r) + "\n" for r in rulings))
        return lf

    def load(self, name: str, base: str, laws: list[str]) -> Run:
        lf = _laws(self.tmp / f"{name}_laws.jsonl", laws)
        run = Run(Options(name, lf, self.tmp / "o.md", self.tmp / "r.json", base_run=base))
        run.load_accepted()
        return run


def N(nid: str, law: str, derived=(), composes=()) -> dict:
    return {"node_id": nid, "law_refs": [law], "elements": [{"span": "s1", "derived": list(derived)}],
            "compositions": [{"rule": r} for r in composes]}


def C(cid: str, calls=()) -> dict:
    return {"concept_id": cid, "contract": f"{cid} holds", "elements": [{"concepts": list(calls)}]}


class BaseChain(unittest.TestCase):
    """One effective view over the base chain, its fences inherited, and the obligations of inherited records."""

    def test_three_generations(self):
        with Results() as r:
            r.run("A", laws=["L-1", "L-2"], nodes={"L_1": N("L_1", "L-1")}, concepts={"drv.motion.creep": C("drv.motion.creep")})
            r.run("B", base="A", laws=["L-2"])
            run = r.load("C", "B", ["L-3"])
            self.assertIn("L_1", run.all_nodes())
            self.assertIn("drv.motion.creep", run.all_concepts())
            self.assertEqual(run.provenance["L_1"], "A")
            self.assertEqual(run.base_chain, ["A", "B"])

    def test_a_law_a_generation_replanned_stays_out_downstream(self):
        with Results() as r:
            r.run("A", laws=["L-1", "L-2"], nodes={"L_1": N("L_1", "L-1"), "L_2": N("L_2", "L-2")})
            r.run("B", base="A", laws=["L-1"])                      # B re-planned L-1 and did not replace it
            run = r.load("C", "B", ["L-3"])                         # C lists another law
            self.assertNotIn("L_1", run.all_nodes())
            self.assertIn("L_2", run.all_nodes())

    def test_fences_are_inherited_and_a_successor_is_usable(self):
        with Results() as r:
            r.run("A", laws=["L-1"], concepts={"drv.motion.creep": C("drv.motion.creep")},
                  state={"defective_concepts": {"drv.motion.creep": {"evidence": "a reported counterexample"}}})   # the older snapshot form
            r.run("B", base="A", concepts={"drv.motion.creep_v2": {**C("drv.motion.creep_v2"), "supersedes": "drv.motion.creep"}})
            run = r.load("C", "B", ["L-2"])
            self.assertEqual(run.all_concepts()["drv.motion.creep"]["fenced"]["reason"], "dependency_defect")
            self.assertNotIn("fenced", run.all_concepts()["drv.motion.creep_v2"])
            self.assertNotIn("drv.motion.creep", active(run))
            self.assertIn("drv.motion.creep_v2", active(run))

    def test_a_cycle_in_the_chain_stops(self):
        with Results() as r:
            r.run("A", base="B")
            r.run("B", base="A")
            with self.assertRaises(SystemExit):
                base_view("A")

    def test_a_chain_member_without_options_stops(self):
        with Results() as r:
            r.run("A", laws=["L-1"], nodes={"L_1": N("L_1", "L-1")})
            r.run("B", base="A")
            shutil.rmtree(paths.RESULTS / "A")                      # an ancestor not copied along
            with self.assertRaises(SystemExit) as e:
                base_view("B")
            self.assertIn("holds no options.json", str(e.exception))

    def test_inherited_obligations_are_read_only_and_qualified(self):
        rows_a = [{"ruling_id": "r1", "key": "concept:drv.motion.creep", "subject": "drv.motion.creep", "schema": review.CONCEPT_CASE_SCHEMA,
                   "case_id": "k1", "ruling": "upheld", "obligation": "satisfied"},
                  {"ruling_id": "r2", "key": "law:L-1", "subject": "L_1", "schema": review.CASE_SCHEMA, "case_id": "k2", "duty": "d",
                   "ruling": "upheld", "obligation": "open"}]
        with Results() as r:
            r.run("A", laws=["L-1"], nodes={"L_1": N("L_1", "L-1")}, concepts={"drv.motion.creep": C("drv.motion.creep")}, rulings=rows_a)
            run = r.load("B", "A", ["L-1"])                         # L-1 is planned again: its rulings stay behind
            rows = review._all_rows(run)
            self.assertEqual([(x["ruling_id"], x["inherited_from"]) for x in rows], [("A/r1", "A")])
            # a ruling of this run on the same identity supersedes the inherited one, once
            new = review.append_ruling(run, {"key": "concept:drv.motion.creep_v2", "subject": "drv.motion.creep_v2",
                                             "schema": review.CONCEPT_CASE_SCHEMA, "case_id": "k1", "ruling": "upheld", "obligation": "satisfied"})
            self.assertEqual(new["supersedes"], "A/r1")
            eff = review.effective_rows(review._all_rows(run))
            self.assertEqual([x["ruling_id"] for x in eff], [new["ruling_id"]])

    def test_a_change_to_the_base_chain_changes_the_semantic_inputs(self):
        with Results() as r:
            r.run("A", laws=["L-1"], concepts={"drv.motion.creep": C("drv.motion.creep")})
            opts = Options("B", r.tmp / "x.jsonl", r.tmp / "o.md", r.tmp / "r.json", base_run="A")
            _laws(opts.laws, ["L-2"])
            for f in ("o.md", "r.json"):
                (r.tmp / f).write_text("{}")
            before = loop.semantic_inputs(opts)["base_run"]
            (paths.RESULTS / "A" / "state.json").write_text(json.dumps({"fenced": {"drv.motion.creep": {"reason": "gate"}}}))
            self.assertNotEqual(loop.semantic_inputs(opts)["base_run"], before)


class Closure(unittest.TestCase):
    """What calls a fenced record is fenced too, concepts and nodes alike."""

    def run_with(self, nodes, concepts, fenced):
        run = Run(Options("r", Path("l"), Path("o"), Path("r")), accepted_nodes=nodes, accepted_concepts=concepts)
        run.fenced = {k: {"reason": "gate"} for k in fenced}
        return run, integrate.fence_closure(run)

    def test_a_chain(self):
        run, added = self.run_with({"L_1": N("L_1", "L-1", derived=["drv.motion.halt"])},
                                   {"drv.motion.creep": C("drv.motion.creep"), "drv.motion.halt": C("drv.motion.halt", calls=["drv.motion.creep"])},
                                   ["drv.motion.creep"])
        self.assertEqual(set(added), {"drv.motion.halt", "L_1"})
        self.assertEqual(run.fenced["drv.motion.halt"]["provider"], "drv.motion.creep")

    def test_a_shared_provider_and_a_composition(self):
        run, added = self.run_with({"L_1": N("L_1", "L-1", derived=["drv.motion.halt"]), "L_2": N("L_2", "L-2", derived=["drv.motion.slow"]),
                                    "L_3": N("L_3", "L-3", composes=["L_1"]), "L_4": N("L_4", "L-4")},
                                   {"drv.motion.creep": C("drv.motion.creep"), "drv.motion.halt": C("drv.motion.halt", calls=["drv.motion.creep"]),
                                    "drv.motion.slow": C("drv.motion.slow", calls=["drv.motion.creep"])}, ["drv.motion.creep"])
        self.assertEqual(set(added), {"drv.motion.halt", "drv.motion.slow", "L_1", "L_2", "L_3"})


class Selection(unittest.TestCase):
    """An inactive record enters no registry, and integration does not blame the baseline for it."""

    def setUp(self):
        self.tmp = Path(tempfile.mkdtemp(prefix="selection-"))
        lib = self.tmp / "library"
        names = {"LIBRARY": lib, "RULES_DIR": lib / "TrafficSpec" / "Rules", "CONCEPTS_DIR": lib / "TrafficSpec" / "Concepts",
                 "WITNESS_DIR": lib / "TrafficSpecWitness", "CONCEPT_WITNESS_DIR": lib / "TrafficSpecWitness" / "Concepts",
                 "INDEX_FILE": lib / "TrafficSpec" / "Index.lean", "WITNESS_ROOT_FILE": lib / "TrafficSpecWitness.lean",
                 "RESULTS": self.tmp / "results"}
        self.stack = contextlib.ExitStack()
        for k, v in names.items():
            self.stack.enter_context(mock.patch.object(paths, k, v))
        (lib / "TrafficSpec").mkdir(parents=True)

    def tearDown(self):
        self.stack.close()

    def write(self, kind, ident, text="ok", witness="ok"):
        rels = (nodeid.concept_path(ident), nodeid.concept_witness_path(ident)) if kind == "concept" else (nodeid.rule_path(ident), nodeid.witness_path(ident))
        for rel, t in zip(rels, (text, witness)):
            p = paths.LIBRARY / rel
            p.parent.mkdir(parents=True, exist_ok=True)
            p.write_text(t)

    def registered(self) -> str:
        return paths.INDEX_FILE.read_text() + paths.WITNESS_ROOT_FILE.read_text()

    def test_no_build_registers_an_inactive_record_but_a_gate_keeps_its_subject(self):
        self.write("concept", "drv.motion.creep"); self.write("concept", "drv.motion.creep_v2"); self.write("node", "L_1")
        index_sync.set_inactive({"drv.motion.creep"}, "r")
        index_sync.write_index()
        self.assertNotIn(nodeid.concept_module("drv.motion.creep") + "\n", self.registered())
        self.assertIn(nodeid.concept_module("drv.motion.creep_v2"), self.registered())
        index_sync.write_index(only_concepts=["drv.motion.creep", "drv.motion.creep_v2"])      # an explicit list too
        self.assertNotIn(nodeid.concept_module("drv.motion.creep") + "\n", self.registered())
        index_sync.write_index(keep={"drv.motion.creep"})
        self.assertIn(nodeid.concept_module("drv.motion.creep") + "\n", self.registered())

    def fake_toolchain(self):
        """A build that fails on any registered file reading `BROKEN`, and a witness run that fails
        every registered witness reading `FAILING`: the toolchain's answers, from the registries."""
        def lake_build(lib, targets=None):
            bad = [m for m in re.findall(r"^import (\S+)", paths.INDEX_FILE.read_text(), re.M)
                   if m.startswith("TrafficSpec.") and (paths.LIBRARY / (m.replace(".", "/") + ".lean")).exists()
                   and "BROKEN" in (paths.LIBRARY / (m.replace(".", "/") + ".lean")).read_text()]
            return (1, "".join(f"{m.replace('.', '/')}.lean:1:0: error: unknown\n" for m in bad)) if bad else (0, "")

        def lean_run(lib, h):
            out = []
            for m in re.findall(r"^import (\S+)", paths.WITNESS_ROOT_FILE.read_text(), re.M):
                f = paths.LIBRARY / (m.replace(".", "/") + ".lean")
                if m.startswith("TrafficSpecWitness.") and f.exists() and "FAILING" in f.read_text():
                    ident = nodeid.concept_id_of_path(str(f.relative_to(paths.LIBRARY)).replace("TrafficSpecWitness/Concepts/", "TrafficSpec/Concepts/")) \
                        if "/Concepts/" in str(f) else f.stem
                    out.append(f"FAIL\t{ident}\tscenario")
            return 0, "\n".join(out + ["DONE"])
        self.stack.enter_context(mock.patch.object(lean, "lake_build", lake_build))
        self.stack.enter_context(mock.patch.object(lean, "lean_run", lean_run))
        self.stack.enter_context(mock.patch.object(lean, "library_lock", lambda *a, **k: contextlib.nullcontext()))
        self.stack.enter_context(mock.patch.object(lean, "errors", lambda out: [l for l in out.splitlines() if "error" in l]))

    def integrate_successor(self, broken_old: dict) -> dict:
        self.fake_toolchain()
        self.write("concept", "drv.motion.creep", **broken_old)
        self.write("concept", "drv.motion.creep_v2"); self.write("node", "L_1")
        run = Run(Options("r", Path("l"), Path("o"), Path("r")))
        run.iteration = 1
        run.iter.mkdir(parents=True)
        node = Node(N("L_1", "L-1", derived=["drv.motion.creep_v2"]))
        return integrate.run_integrate(run, [node], Reading(self.tmp / "none.json"), {}, ["drv.motion.creep_v2"], {}, {"drv.motion.creep_v2": set()})

    def test_a_fenced_version_with_a_failing_witness(self):
        index_sync.set_inactive({"drv.motion.creep"}, "r")
        res = self.integrate_successor({"witness": "FAILING"})
        self.assertEqual((res["status"], res["kept"], res["kept_concepts"]), ("verified", ["L_1"], ["drv.motion.creep_v2"]))

    def test_a_fenced_version_that_does_not_compile(self):
        index_sync.set_inactive({"drv.motion.creep"}, "r")
        res = self.integrate_successor({"text": "BROKEN"})
        self.assertEqual((res["status"], res["kept"], res["kept_concepts"]), ("verified", ["L_1"], ["drv.motion.creep_v2"]))

    def test_control_without_the_selection_the_baseline_is_broken(self):
        res = self.integrate_successor({"witness": "FAILING"})
        self.assertEqual(res["status"], "baseline_broken")


class AdmissionRecheck(unittest.TestCase):
    """Today's gates on the accepted records, cached, fencing a failure and its closure."""

    def setUp(self):
        self.r = Results().__enter__()
        self.addCleanup(self.r.__exit__)
        (self.r.tmp / "library").mkdir()
        p = mock.patch.object(paths, "LIBRARY", self.r.tmp / "library"); p.start(); self.addCleanup(p.stop)
        self.r.run("A", laws=["L-1", "L-2"], nodes={"L_1": N("L_1", "L-1", derived=["drv.motion.creep"]), "L_2": N("L_2", "L-2")},
                   concepts={"drv.motion.creep": C("drv.motion.creep")})
        self.runs = collections.Counter()
        self.verdict = {}

        def run_gate(n, reading, baseline, work, used, budget, accepted_concepts=None):
            self.runs[n.id] += 1
            return gate.Verdict(self.verdict.get(n.id, "OK"), ["scripted"])

        def run_concept_gate(rec, reading, baseline, work, used, budget, mode="train", accepted=None):
            self.runs[rec.id] += 1
            self.assertNotIn(rec.id, accepted)                     # the record is no duplicate of itself
            return gate.Verdict(self.verdict.get(rec.id, "OK"), ["scripted"])
        for k, v in (("run_gate", run_gate), ("run_concept_gate", run_concept_gate), ("repo_digest", lambda: {})):
            p = mock.patch.object(gate, k, v); p.start(); self.addCleanup(p.stop)
        p = mock.patch.object(integrate, "_files_digest", lambda rels: "files"); p.start(); self.addCleanup(p.stop)

    def test_a_failure_is_fenced_with_its_callers_and_the_verdict_cached(self):
        run = self.r.load("B", "A", ["L-3"])
        run.dir.mkdir(parents=True, exist_ok=True)
        self.verdict["drv.motion.creep"] = "WITNESS_FAIL"
        failed = integrate.admission_recheck(run, Reading(self.r.tmp / "none.json"), {"core": "c"})
        self.assertEqual(set(failed), {"drv.motion.creep"})
        self.assertEqual(run.fenced["L_1"]["reason"], "dependency")
        self.assertEqual(self.runs["L_1"], 0)                      # fenced by its provider, never gated
        run2 = self.r.load("B", "A", ["L-3"])
        integrate.admission_recheck(run2, Reading(self.r.tmp / "none.json"), {"core": "c"})
        self.assertEqual(self.runs["drv.motion.creep"], 1)          # a cache hit is not run again
        self.assertIn("drv.motion.creep", run2.fenced)

    def test_a_gate_that_does_not_judge_fences_nothing(self):
        run = self.r.load("B", "A", ["L-3"])
        run.dir.mkdir(parents=True, exist_ok=True)
        self.verdict["drv.motion.creep"] = gate.INFRA
        with self.assertRaises(integrate.AdmissionUnavailable):
            integrate.admission_recheck(run, Reading(self.r.tmp / "none.json"), {"core": "c"})
        self.assertNotIn("drv.motion.creep", run.fenced)


# ---------------------------------------------------------------------------------------------
# End to end, run as printed: a continuation that stops, then the printed continuation
# ---------------------------------------------------------------------------------------------
def _printed(msg: str) -> tuple[str, Path, list[str], str]:
    m = re.search(r"python -m scripts\.subset_laws (\S+) (\S+) ([^&]+?) && python -m harness loop --run_id \S+ --laws (\S+) --base_run (\S+)", msg)
    assert m, msg
    return m.group(1), Path(m.group(2)), m.group(3).split(), m.group(5)


class SubsetAsPrinted(unittest.TestCase):
    """A base whose concept today's gates reject: a continuation that keeps a node using it stops
    with a subset command; that command, run as printed, starts, plans successors and integrates
    them, and nothing new calls a fenced version."""

    def scenario(self, base_plans: dict, fail: str, first: list[str], fix_plans: dict, verdict: str = "WITNESS_FAIL"):
        from scripts.subset_laws import subset
        w = R.World({l: f"{l} text" for l in ("L-1", "L-2", "L-3")})
        with R.Fixture(w) as f:
            corpus = f.root / "corpus" / "laws.jsonl"
            w.plans = base_plans
            loop.run_loop(f.options(run_id="A"))
            w.broken = {fail}
            w.admission[fail] = verdict
            w.plans = {}
            with self.assertRaises(SystemExit) as stop:
                loop.run_loop(f.options(run_id="B", laws=subset("B", corpus, first), base_run="A"))
            new, corpus_printed, laws, base = _printed(str(stop.exception))
            self.assertEqual(base, "A")
            w.plans = fix_plans
            res = loop.run_loop(f.options(run_id=new, laws=subset(new, corpus_printed, laws), base_run=base))
            st = json.loads((paths.RESULTS / new / "state.json").read_text())
            inactive = index_sync.inactive()
        return res, st, inactive, laws

    def test_a_node_calling_a_fenced_concept(self):
        res, st, inactive, laws = self.scenario(
            {"L-1": [R.concept("drv.motion.creep", users=["L_1"]), R.node("L_1", "L-1 text", "L-1", derived=["drv.motion.creep"])],
             "L-2": [R.node("L_2", "L-2 text", "L-2")]},
            "drv.motion.creep", ["L-3"],
            {"L-1": [{**R.concept("drv.motion.creep_v2", users=["L_1"]), "supersedes": "drv.motion.creep", "contract": "drv.motion.creep holds"},
                     R.node("L_1", "L-1 text", "L-1", derived=["drv.motion.creep_v2"])]})
        self.assertEqual(laws, ["L-1", "L-3"])
        self.assertIn("drv.motion.creep_v2", st["accepted_concepts"])
        self.assertEqual(st["accepted_nodes"]["L_1"]["elements"][0]["derived"], ["drv.motion.creep_v2"])
        self.assertIn("drv.motion.creep", inactive)

    def test_a_fenced_version_that_does_not_compile(self):
        res, st, inactive, _laws = self.scenario(
            {"L-1": [R.concept("drv.motion.creep", users=["L_1"]), R.node("L_1", "L-1 text", "L-1", derived=["drv.motion.creep"])]},
            "drv.motion.creep", ["L-2"],
            {"L-1": [{**R.concept("drv.motion.creep_v2", users=["L_1"]), "supersedes": "drv.motion.creep", "contract": "drv.motion.creep holds"},
                     R.node("L_1", "L-1 text", "L-1", derived=["drv.motion.creep_v2"])]}, verdict="BUILD_FAIL")
        self.assertIn("drv.motion.creep_v2", st["accepted_concepts"])
        self.assertEqual(st["fenced"]["drv.motion.creep"]["verdict"], "BUILD_FAIL")

    def test_a_chain_node_b_fenced_a(self):
        res, st, inactive, laws = self.scenario(
            {"L-1": [R.concept("drv.motion.creep", users=["L_1"]), R.concept("drv.motion.halt", calls=["drv.motion.creep"], users=["L_1"]),
                     R.node("L_1", "L-1 text", "L-1", derived=["drv.motion.halt"])]},
            "drv.motion.creep", ["L-2"],
            {"L-1": [{**R.concept("drv.motion.creep_v2", users=["L_1"]), "supersedes": "drv.motion.creep", "contract": "drv.motion.creep holds"},
                     {**R.concept("drv.motion.halt_v2", calls=["drv.motion.creep_v2"], users=["L_1"]), "supersedes": "drv.motion.halt",
                      "contract": "drv.motion.halt holds"},
                     R.node("L_1", "L-1 text", "L-1", derived=["drv.motion.halt_v2"])]})
        self.assertEqual(st["fenced"]["drv.motion.halt"]["reason"], "dependency")
        self.assertEqual(sorted(st["accepted_concepts"]), ["drv.motion.creep_v2", "drv.motion.halt_v2"])
        self.assertTrue({"drv.motion.creep", "drv.motion.halt"} <= inactive)

    def test_a_longer_chain_sharing_one_provider(self):
        res, st, inactive, laws = self.scenario(
            {"L-1": [R.concept("drv.motion.creep", users=["L_1", "L_2"]), R.concept("drv.motion.halt", calls=["drv.motion.creep"], users=["L_1"]),
                     R.node("L_1", "L-1 text", "L-1", derived=["drv.motion.halt"])],
             "L-2": [R.concept("drv.motion.slow", calls=["drv.motion.creep"], users=["L_2"]), R.node("L_2", "L-2 text", "L-2", derived=["drv.motion.slow"])],
             "L-3": [R.node("L_3", "L-3 text", "L-3")]},
            "drv.motion.creep", ["L-3"],
            {"L-1": [{**R.concept("drv.motion.creep_v2", users=["L_1", "L_2"]), "supersedes": "drv.motion.creep", "contract": "drv.motion.creep holds"},
                     {**R.concept("drv.motion.halt_v2", calls=["drv.motion.creep_v2"], users=["L_1"]), "supersedes": "drv.motion.halt",
                      "contract": "drv.motion.halt holds"},
                     R.node("L_1", "L-1 text", "L-1", derived=["drv.motion.halt_v2"])],
             "L-2": [{**R.concept("drv.motion.slow_v2", calls=["drv.motion.creep_v2"], users=["L_2"]), "supersedes": "drv.motion.slow",
                      "contract": "drv.motion.slow holds"},
                     R.node("L_2", "L-2 text", "L-2", derived=["drv.motion.slow_v2"])],
             "L-3": [R.node("L_3", "L-3 text", "L-3")]})
        self.assertEqual(laws, ["L-1", "L-2", "L-3"])
        self.assertEqual(sorted(st["accepted_concepts"]), ["drv.motion.creep_v2", "drv.motion.halt_v2", "drv.motion.slow_v2"])
        self.assertEqual(sorted(st["accepted_nodes"]), ["L_1", "L_2", "L_3"])
        for rec in list(st["accepted_nodes"].values()) + list(st["accepted_concepts"].values()):     # nothing new calls a fenced version
            used = {c for e in rec.get("elements", []) for c in e.get("derived", []) + e.get("concepts", [])}
            self.assertFalse(used & set(st["fenced"]), rec)


class Supersession(unittest.TestCase):
    """A fenced version is superseded without a counterexample, and the catalogue says so."""

    def test_the_validator_takes_the_fence_for_the_counterexample(self):
        old = {**C("drv.motion.creep"), "fenced": {"reason": "gate", "evidence": "WITNESS_FAIL"}}
        new = ConceptRecord({**C("drv.motion.creep_v2"), "supersedes": "drv.motion.creep", "contract": "drv.motion.creep holds"})
        errs = validate_a.check_concept(new, {}, SimpleNamespace(knows=lambda i: True, contract=lambda i: "a contract", primitive_ids=set(), atom_ids=set()),
                                        {"drv.motion.creep": old}, set(), {}, {}, "train")
        self.assertFalse([e for e in errs if "counterexample" in e], errs)
        unfenced = {**C("drv.motion.creep")}
        errs = validate_a.check_concept(new, {}, SimpleNamespace(knows=lambda i: True, contract=lambda i: "a contract", primitive_ids=set(), atom_ids=set()),
                                        {"drv.motion.creep": unfenced}, set(), {}, {}, "train")
        self.assertTrue([e for e in errs if "counterexample" in e])

    def test_the_catalogue_lists_fenced_versions(self):
        run = Run(Options("r", Path("l"), Path("o"), Path("r")), accepted_concepts={"drv.motion.creep": C("drv.motion.creep")})
        run.fenced = {"drv.motion.creep": {"reason": "gate", "evidence": "WITNESS_FAIL: x"}}
        with mock.patch.object(plan_phase.surface, "concepts_table", lambda c: f"table {sorted(c)}\n"):
            text = plan_phase.concept_catalogue(run)
        self.assertIn("table []", text)
        self.assertIn("without a counterexample", text)
        self.assertIn("WITNESS_FAIL: x", text)


class FencedSuccessorSkeleton(unittest.TestCase):
    """A successor of a fenced version without a counterexample gets no counterexample scenario;
    one with a counterexample keeps it."""

    def test_the_counterexample_scenario_follows_the_record(self):
        from harness.lean import skeleton
        base = {**C("drv.motion.creep_v2"), "kind": "predicate", "args": [{"name": "v", "sort": "track"}], "params": [],
                "supersedes": "drv.motion.creep", "scenarios": [{"name": k, "expected": v} for k, v in
                                                              (("holds", "compliant"), ("fails", "violated"), ("blind", "unknown"))]}
        self.assertNotIn("counterexample", skeleton.concept_witness_skeleton(ConceptRecord(base)))
        with_ce = {**base, "counterexample": {"narrative": "n", "expected": "violated"}}
        self.assertIn("counterexample", skeleton.concept_witness_skeleton(ConceptRecord(with_ce)))


class VerifyCommand(unittest.TestCase):
    """`verify` reports the active selection's result and each fenced record's recorded failure
    apart, and passes only when the active selection verifies and nothing is fenced."""

    def go(self, fenced: dict) -> tuple[int, str]:
        import io
        from harness.__main__ import Cli
        with Results() as r:
            lf = r.run("A", laws=["L-1"], nodes={"L_1": N("L_1", "L-1")})
            opts = json.loads((paths.RESULTS / "A" / "options.json").read_text())
            opts.update({"ontology": str(r.tmp / "o.md"), "reading": str(r.tmp / "r.json")})
            (paths.RESULTS / "A" / "options.json").write_text(json.dumps(opts))
            (paths.RESULTS / "A" / "reading.json").write_text(json.dumps({"params": []}))
            seen = {}

            def recheck(run, reading, base):
                run.fenced.update(fenced)
                return {}

            def verify(work, reading, only_nodes=None, only_concepts=None):
                seen["nodes"] = list(only_nodes or [])
                return "verified", [], set()
            out = io.StringIO()
            lib = r.tmp / "library"
            (lib / nodeid.rule_path("L_1")).parent.mkdir(parents=True, exist_ok=True)
            (lib / nodeid.rule_path("L_1")).write_text("rule")
            with mock.patch.object(paths, "LIBRARY", lib), \
                 mock.patch("harness.store.owner.acquire_for_command", lambda name: None), \
                 mock.patch.object(integrate, "admission_recheck", recheck), \
                 mock.patch.object(integrate, "verify_library", verify), \
                 mock.patch.object(integrate, "recheck_contexts", lambda *a, **k: ([], [], [])), \
                 mock.patch.object(loop, "semantic_inputs", lambda opts: {"core": "c", "ontology": "o"}), \
                 mock.patch.object(index_sync, "set_inactive", lambda ids, run_id: True), \
                 mock.patch("sys.stdout", out):
                code = Cli().verify("A")
            return code, out.getvalue(), seen

    def test_nothing_fenced_passes(self):
        code, text, seen = self.go({})
        self.assertEqual(code, 0)
        self.assertEqual(seen["nodes"], ["L_1"])

    def test_a_fenced_record_is_reported_apart_and_fails(self):
        code, text, seen = self.go({"L_1": {"kind": "node", "reason": "gate", "evidence": "WITNESS_FAIL: scripted"}})
        self.assertEqual(code, 1)
        self.assertEqual(seen["nodes"], [])                       # the active selection leaves it out
        self.assertIn("active selection (0 node(s), 0 concept(s)): OK", text)
        self.assertIn("`L_1` (node, gate): WITNESS_FAIL: scripted", text)


class ContextKeys(unittest.TestCase):
    """What a record's context and the caches keyed on it rest on."""

    def setUp(self):
        self.tmp = Path(tempfile.mkdtemp(prefix="context-"))
        self.rf = self.tmp / "reading.json"
        self.rf.write_text(json.dumps({"params": [{"name": "p.window", "unit": "s", "value": 1, "proposed": "r iteration 1 L_1"}]}))
        self.rec = {"node_id": "L_1", "law_refs": ["L-1"], "params": ["p.window"], "elements": [{"span": "s1", "atoms": ["kin.speed"]}],
                    "compositions": []}
        self.run = Run(Options("r", Path("l"), Path("o"), self.rf), accepted_nodes={"L_1": self.rec})
        p = mock.patch.object(integrate, "_files_digest", lambda rels: "files"); p.start(); self.addCleanup(p.stop)

    def v(self, **kw):
        return integrate.context_version(self.run, "node", "L_1", Reading(self.rf), {"core": "c"}, **kw)

    def test_the_record_itself(self):
        before = self.v()
        self.rec["elements"][0]["atoms"] = ["kin.acceleration"]
        self.assertNotEqual(self.v(), before)

    def test_a_proposal_reviewed(self):
        before = self.v()
        d = json.loads(self.rf.read_text()); del d["params"][0]["proposed"]; self.rf.write_text(json.dumps(d))
        self.assertNotEqual(self.v(), before)

    def test_a_fence_on_what_it_calls(self):
        self.rec["elements"][0]["derived"] = ["drv.motion.creep"]
        self.run.accepted_concepts = {"drv.motion.creep": C("drv.motion.creep")}
        before = self.v()
        self.run.fenced = {"drv.motion.creep": {"reason": "gate"}}
        self.assertNotEqual(self.v(), before)

    def test_its_obligations_in_the_semantic_key_only(self):
        with mock.patch.object(integrate, "obligations_version", lambda run, ident: "one"):
            a, sa = self.v(), self.v(semantic=True)
        with mock.patch.object(integrate, "obligations_version", lambda run, ident: "two"):
            self.assertEqual(self.v(), a)
            self.assertNotEqual(self.v(semantic=True), sa)

    def test_the_fields_others_write_change_nothing(self):
        before = self.v()
        self.rec["callers"] = ["L_9"]; self.rec["context"] = "x"
        self.assertEqual(self.v(), before)

    def test_unchanged_is_unchanged(self):
        self.assertEqual(self.v(), self.v())

    def test_a_pending_candidate_is_versioned(self):
        cand = {"node_id": "L_2", "law_refs": ["L-2"], "elements": [], "compositions": []}
        v = integrate.context_version(self.run, "node", "L_2", Reading(self.rf), {"core": "c"}, record=cand,
                                      catalogue={"nodes": self.run.all_nodes(), "concepts": {}})
        self.assertTrue(v)

    def test_a_change_to_a_gate_helper_changes_the_admission_key(self):
        repo = self.tmp / "repo"
        (repo / "harness" / "checks").mkdir(parents=True)
        (repo / "harness" / "checks" / "gate.py").write_text("x = 1\n")
        (repo / "harness" / "model").mkdir(parents=True)
        (repo / "harness" / "model" / "units.py").write_text("u = 1\n")
        with mock.patch.object(paths, "REPO", repo):
            before = integrate.admission_key(self.run, "node", "L_1", Reading(self.rf), {"core": "c"})
            (repo / "harness" / "model" / "units.py").write_text("u = 2\n")         # a helper, not gate.py
            self.assertNotEqual(integrate.admission_key(self.run, "node", "L_1", Reading(self.rf), {"core": "c"}), before)

    def test_a_saved_verdict_is_reused_only_on_its_context(self):
        d = self.tmp / "task"
        d.mkdir()
        code_phase._save_verdict(d, gate.Verdict("UNCLAIMED_ATOM", ["x"]), ("a", "b"), "ctx1")
        self.assertIsNotNone(code_phase._finished_verdict(d, ("a", "b"), "ctx1"))
        self.assertIsNone(code_phase._finished_verdict(d, ("a", "b"), "ctx2"))

    def test_a_reading_write_killed_midway_leaves_the_previous_reading(self):
        before = self.rf.read_text()
        with mock.patch.object(jsonl.os, "replace", side_effect=OSError("killed")):
            with self.assertRaises(OSError):
                Reading.add_proposals(self.rf, [{"name": "p.gap", "unit": "m", "value": 3, "convention": "c", "source": "s"}], "r/iter-001 L_2")
        self.assertEqual(self.rf.read_text(), before)


class FallbackOrder(unittest.TestCase):
    """Integration's fallback restores in dependency order from the verified baseline."""

    def outcome(self, order: list[str]) -> dict:
        tmp = Path(tempfile.mkdtemp(prefix="fallback-"))
        lib = tmp / "lib"; lib.mkdir()
        nodes = {"A_1": Node({"node_id": "A_1", "law_refs": ["A-1"], "compositions": [{"rule": "Z_1"}]}),
                 "Z_1": Node({"node_id": "Z_1", "law_refs": ["Z-1"], "compositions": []})}
        with mock.patch.object(paths, "LIBRARY", lib):
            for n in nodes.values():
                for rel in integrate._files("node", n.id):
                    f = lib / rel; f.parent.mkdir(parents=True, exist_ok=True); f.write_text(n.id)

            def remove(nid, *a):
                for rel in integrate._files("node", nid):
                    (lib / rel).unlink(missing_ok=True)
            calls = [0]

            def verify(*a, **k):
                calls[0] += 1
                if calls[0] == 1:
                    return "failed", ["a generated registry error"], set()
                have = {i for i in nodes if (lib / nodeid.rule_path(i)).exists()}
                if "Z_1" in have:
                    return "failed", ["Z_1 has the wrong type"], set()
                if have == {"A_1"}:
                    return "failed", ["A_1 imports a missing Z_1"], set()
                return "verified", [], set()
            with mock.patch.object(integrate, "rollback", side_effect=remove), mock.patch.object(integrate, "verify_library", side_effect=verify):
                return integrate.run_integrate(SimpleNamespace(iter=tmp / "iter", accepted_nodes={}), [nodes[i] for i in order], None, {})

    def test_both_input_orders(self):
        for order in (["A_1", "Z_1"], ["Z_1", "A_1"]):
            out = self.outcome(order)
            self.assertEqual(set(out["rejected"]), {"Z_1"}, order)
            self.assertEqual(set(out["waiting"]), {"A_1"}, order)



class CliGateCatalogue(unittest.TestCase):
    """The gate a coding session runs sees the catalogue the harness's own gate is given:
    the base chain's concepts and the run's, fenced versions marked, read without writing."""

    def chain(self, r):
        r.run("A", laws=["L-1"], concepts={"drv.motion.creep": C("drv.motion.creep"), "drv.motion.old": C("drv.motion.old")},
              state={"defective_concepts": {"drv.motion.creep": {"evidence": "a reported counterexample"}}})
        r.run("B", base="A", laws=["L-2"], concepts={"drv.motion.mid": C("drv.motion.mid")})
        own = {"drv.motion.rest": C("drv.motion.rest")}
        fence = {"drv.motion.mid": {"kind": "concept", "reason": "gate", "evidence": "fails today's gates"}}
        lf = r.run("C", base="B", laws=["L-3"], concepts=own,
                   state={"accepted_concepts": own, "accepted_nodes": {}, "fenced": fence})
        run = Run(Options("C", lf, r.tmp / "o.md", r.tmp / "r.json", base_run="B"))
        run.restore_state(); run.load_accepted()
        return run

    @staticmethod
    def files(root: Path) -> dict[str, tuple[bytes, int]]:
        return {str(p): (p.read_bytes(), p.stat().st_mtime_ns) for p in sorted(root.rglob("*")) if p.is_file()}

    def test_equals_the_owners_catalogue(self):
        with Results() as r:
            owner = self.chain(r).all_concepts()
            cli = code_phase.cli_catalogue("C")
            self.assertEqual(cli, owner)
            self.assertIn("drv.motion.old", cli)                                 # two bases back
            self.assertEqual(cli["drv.motion.creep"]["fenced"]["reason"], "dependency_defect")   # inherited fence
            self.assertEqual(cli["drv.motion.mid"]["fenced"]["reason"], "gate")  # the run's own fence
            self.assertNotIn("fenced", cli["drv.motion.rest"])

    def test_the_lookup_writes_nothing(self):
        with Results() as r:
            self.chain(r)
            before = self.files(paths.RESULTS)
            code_phase.cli_catalogue("C")
            self.assertEqual(self.files(paths.RESULTS), before)

    def test_an_owner_commit_during_the_read_is_kept_and_seen_next(self):
        with Results() as r:
            self.chain(r)
            first = code_phase.cli_catalogue("C")
            state_file = paths.RESULTS / "C" / "state.json"
            snap = json.loads(state_file.read_text())
            snap["accepted_concepts"]["drv.motion.new"] = C("drv.motion.new")
            jsonl.write_atomic(state_file, json.dumps(snap))                     # the owner's next commit
            self.assertNotIn("drv.motion.new", first)
            self.assertIn("drv.motion.new", code_phase.cli_catalogue("C"))
            self.assertIn("drv.motion.new", json.loads(state_file.read_text())["accepted_concepts"])

    def test_both_branches_pass_it_and_rewrite_no_owner_state(self):
        with Results() as r:
            owner = self.chain(r).all_concepts()
            run_dir = paths.RESULTS / "C"
            opts = json.loads((run_dir / "options.json").read_text())
            opts.update({"reading": str(r.tmp / "r.json"), "gate_budget": 6, "mode": "train"})
            (run_dir / "options.json").write_text(json.dumps(opts))
            for dirname, rec_file, rec in (("NRS_X_1", "node.json", {"node_id": "NRS_X_1"}),
                                           (code_phase.concept_dirname("drv.motion.rest"), "concept.json", C("drv.motion.rest"))):
                d = run_dir / "iter-001" / "code" / dirname
                d.mkdir(parents=True)
                (d / "baseline.json").write_text("{}"); (d / "gate_runs.txt").write_text("0")
                (d / rec_file).write_text(json.dumps(rec))
            owned = {k: v for k, v in self.files(run_dir).items() if "/iter-" not in k}
            seen = {}
            ok = gate.Verdict("OK", [])
            with mock.patch.object(code_phase, "Reading", lambda p: None), \
                 mock.patch.object(code_phase, "Node", lambda d: d), \
                 mock.patch.object(code_phase, "ConceptRecord", lambda d: d), \
                 mock.patch.object(code_phase.gate, "run_gate", lambda *a, **k: seen.setdefault("node", k["accepted_concepts"]) and ok), \
                 mock.patch.object(code_phase.gate, "run_concept_gate", lambda *a, **k: seen.setdefault("concept", k["accepted"]) and ok):
                code_phase.gate_from_cli("C", "NRS_X_1")
                code_phase.gate_from_cli("C", "drv.motion.rest")
            self.assertEqual(seen, {"node": owner, "concept": owner})
            self.assertEqual({k: v for k, v in self.files(run_dir).items() if "/iter-" not in k}, owned)
            self.assertEqual((run_dir / "iter-001" / "code" / "NRS_X_1" / "gate_runs.txt").read_text(), "1")


if __name__ == "__main__":
    unittest.main()
