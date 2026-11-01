"""The concept replay with the real Lean execution, two saved challenges in one replay: the challenge
smoke24 upheld on drv.motion.proceeds_through_region (its effective row, satisfied) and one derived
from it with the opposite claim. Only the recheck, the adjudicator and the reviewer sessions are
stubbed. Each run shows no exception, one row per challenge, and every earlier row unchanged. Runs
only when the library holds that concept's module, built; skipped otherwise."""
import json
import re
import tempfile
import unittest
from pathlib import Path

from harness.model.blueprint import ConceptRecord
from harness.phases import review
from harness.phases import validate as validate_phase
from harness.store import paths
from scripts.tests.test_review_routing import FakeRun, scripted_reviewer, submit

FIXTURE = Path(__file__).with_name("concept_recheck_proceeds.json")
MODULE = paths.LIBRARY / ".lake" / "build" / "lib" / "lean" / "TrafficSpec" / "Concepts" / "motion" / "proceeds_through_region.olean"
QUOTE = "it is in motion — its speed exceeds the motion floor"
FORCED = "0" * 64


@unittest.skipUnless(MODULE.exists() and (paths.LIBRARY / "TrafficSpec" / "Concepts" / "motion" / "proceeds_through_region.lean").exists(),
                     "the concept's module is not built in this library")
class TwoChallengesOneReplay(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.saved = (validate_phase._session, review.session.run_tools)

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
