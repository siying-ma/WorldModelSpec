"""The concept replay with the real Lean execution, two saved challenges in one replay: the challenge
smoke24 upheld on drv.motion.proceeds_through_region (its effective row, satisfied) and one derived
from it with the opposite claim. Only the recheck, the adjudicator and the reviewer sessions are
stubbed. Each run shows no exception, one row per challenge, and every earlier row unchanged. The
replay runs on a library of the test's own, in a temporary directory: the current Core and the
concept's module as the fixture recorded it, built there, so the result does not depend on which
concepts the working library holds. Skipped only where Lake is not installed."""
import json
import re
import shutil
import tempfile
import unittest
from pathlib import Path
from unittest import mock

from harness.lean import lean
from harness.model import nodeid
from harness.model.blueprint import ConceptRecord
from harness.phases import review
from harness.phases import validate as validate_phase
from harness.store import paths
from scripts.tests.test_review_routing import FakeRun, scripted_reviewer, submit

FIXTURE = Path(__file__).with_name("concept_recheck_proceeds.json")
WORKING = paths.LIBRARY
QUOTE = "it is in motion — its speed exceeds the motion floor"
FORCED = "0" * 64


def own_library(root: Path, cid: str, source: str) -> dict[str, Path]:
    """A Lake project under `root` with the working library's project files, its current Core, and
    `source` as the module of concept `cid`, built. Core's build outputs are copied from the working
    library where it has them, so only the concept is compiled; Lake rebuilds any Core module whose
    trace does not match its source. Returns the `paths` attributes that point the harness at the project."""
    lib = root / "library"
    (lib / "TrafficSpec").mkdir(parents=True)
    for f in ("lakefile.lean", "lean-toolchain", "lake-manifest.json"):
        shutil.copy2(WORKING / f, lib / f)
    shutil.copytree(paths.CORE, lib / "TrafficSpec" / "Core")
    shutil.copy2(paths.CORE.with_suffix(".lean"), lib / "TrafficSpec" / "Core.lean")
    for tree in (Path("lib") / "lean", Path("ir")):        # a module's trace names its olean, ilean and C outputs
        built = WORKING / ".lake" / "build" / tree / "TrafficSpec"
        if (built / "Core").is_dir():
            dest = lib / ".lake" / "build" / tree / "TrafficSpec"
            shutil.copytree(built / "Core", dest / "Core")
            for f in built.glob("Core.*"):
                shutil.copy2(f, dest / f.name)
    module = lib / nodeid.concept_path(cid)
    module.parent.mkdir(parents=True)
    module.write_text(source, encoding="utf-8")
    code, out = lean.lake_build(lib, [nodeid.concept_module(cid)])
    if code != 0:
        raise AssertionError(f"the test's own library did not build: {out[-1500:]}")
    ts, w = lib / "TrafficSpec", lib / "TrafficSpecWitness"
    return {"LIBRARY": lib, "CORE": ts / "Core", "RULES_DIR": ts / "Rules", "CONCEPTS_DIR": ts / "Concepts",
            "WITNESS_DIR": w, "CONCEPT_WITNESS_DIR": w / "Concepts", "INDEX_FILE": ts / "Index.lean",
            "WITNESS_ROOT_FILE": lib / "TrafficSpecWitness.lean", "READINGS": ts / "Readings", "GAPS_DIR": ts / "Gaps"}


@unittest.skipUnless(shutil.which("lake"), "Lake is not installed")
class TwoChallengesOneReplay(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.library = tempfile.TemporaryDirectory()
        try:
            fx = json.loads(FIXTURE.read_text(encoding="utf-8"))
            cls.dirs = own_library(Path(cls.library.name), fx["concept"]["concept_id"], fx["lean"])
        except BaseException:
            cls.library.cleanup()
            raise

    @classmethod
    def tearDownClass(cls):
        cls.library.cleanup()

    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.saved = (validate_phase._session, review.session.run_tools)
        on_own = mock.patch.multiple(paths, **self.dirs)
        on_own.start()
        self.addCleanup(on_own.stop)

    def tearDown(self):
        validate_phase._session, review.session.run_tools = self.saved
        self.tmp.cleanup()

    def review(self, forced: bool, verdict: str):
        fx = json.loads(FIXTURE.read_text())
        acc = fx["concept"]
        rec = ConceptRecord(acc)
        current = review.contract_digest(rec)
        lines = fx["rows"] if not forced else [json.dumps({**json.loads(l), "contract_digest": FORCED}, ensure_ascii=False) for l in fx["rows"]]
        real = json.loads(lines[-1])
        derived = {k: v for k, v in real.items() if k not in ("ruling_id", "supersedes", "lineage", "predecessor")}
        derived.update({"contract_verdict": "holds", "kind": "fails_wrongly", "obligation": "open", "situation": "derived: the opposite claim",
                        "contract_digest": FORCED if forced else current})
        derived["case_id"] = review.concept_case_id(rec.id, derived)
        run = self._run = FakeRun(Path(tempfile.mkdtemp(dir=self.tmp.name)))
        run.iteration = 5
        run.all_concepts = lambda: {rec.id: acc}
        f = run.dir / "rulings.jsonl"
        f.write_text("".join(l + "\n" for l in lines), encoding="utf-8")
        review.append_ruling(run, derived)
        before = f.read_bytes()
        calls = {"recheck": 0, "adjudicate": 0}

        def session(_run, out_dir, label, prompt, check=None, **_k):
            if label.startswith("adjudicate"):
                calls["adjudicate"] += 1
                items = re.findall(r"^(\d+)\. \(", prompt.split("### Items", 1)[1], re.M)
                a = {"rulings": [{"item": int(k), "ruling": "upheld", "reason": "stubbed", "quote": QUOTE} for k in items]}
            else:
                calls["recheck"] += 1
                a = {"verdict": verdict, "reason": "stubbed", "quote": QUOTE}
            return a, list(check(a)) if check else []
        validate_phase._session = session
        review.session.run_tools = scripted_reviewer([submit({"verdict": "accept", "divergences": [], "not_general": [],
                                                              "advisories": []})] * 3)
        out = review.review_concept(run, rec, acc, run.dir / "review")
        harness = (run.dir / "review" / "replay" / "review_harness.out").read_text()
        self.assertEqual(re.findall(r"^DIS\t(\d)\t(\w+)", harness, re.M), [("1", "violated"), ("2", "violated")])   # both ran, in one program
        after = f.read_bytes()
        self.assertTrue(after.startswith(before))
        rows = [json.loads(l) for l in after[len(before):].decode().splitlines()]
        self.assertEqual(sorted(r.get("lineage") or r["case_id"] for r in rows), sorted([real["case_id"], derived["case_id"]]))
        self.assertTrue(all(r["contract_digest"] == current for r in rows))
        return out, rows, calls, real, derived

    def test_one_r2_and_one_r1(self):
        out, rows, calls, real, derived = self.review(False, "fails")
        self.assertEqual((out.status, calls), ("returned", {"recheck": 1, "adjudicate": 1}))
        by = {r.get("lineage") if r.get("recheck") else r["case_id"]: r for r in rows}
        self.assertEqual((by[real["case_id"]]["case_id"], by[real["case_id"]]["obligation"]), (real["case_id"], "satisfied"))   # R2, met
        self.assertEqual((by[derived["case_id"]]["case_id"], by[derived["case_id"]]["obligation"]), (derived["case_id"], "open"))  # R1, upheld

    def test_two_r2_met(self):
        out, rows, calls, real, derived = self.review(True, "fails")
        # the derived challenge has the recorded one's facts, and a recheck is never shown a claim: the same
        # question, so the second takes the run's kept answer without a session
        self.assertEqual((out.status, calls), ("accepted", {"recheck": 1, "adjudicate": 0}))
        self.assertEqual(len(review.recheck_cache_file(self._run).read_text().splitlines()), 1)
        self.assertEqual([r["obligation"] for r in rows], ["satisfied", "satisfied"])
        self.assertEqual([r["case_id"] == r["lineage"] for r in rows], [True, False])     # the same id; a renewed one

    def test_two_r2_renewed_to_one_adjudication(self):
        out, rows, calls, real, derived = self.review(True, "holds")
        self.assertEqual((out.status, calls), ("returned", {"recheck": 1, "adjudicate": 1}))
        self.assertEqual([(r["ruling"], r["obligation"], r["contract_verdict"]) for r in rows], [("upheld", "open", "holds")] * 2)
        self.assertTrue(all(r["case_id"] != r["lineage"] for r in rows))


if __name__ == "__main__":
    unittest.main()
