"""Evidence admission, the second pass: a satisfied concept obligation moves to the version that met
it and is found by every later version of the lineage; continuity compares traces in their
normalized form, so a measured relation Core cannot compute stays evidence; the containers of a
concept divergence have their shapes before anything runs; a structural finding's identity is its
lineage's root and the occurrence of its words; a trace key the decoder does not read is never an
executed fact."""
import copy
import json
import re
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from harness.lean import lean
from harness.model.blueprint import ConceptRecord
from harness.phases import review
from harness.store import paths
from harness.store.state import Options, Run
from scripts.tests.test_review_routing import FakeRun, scripted_reviewer, submit

NO_GEOMETRY = {"scenes": [{"t": 0, "users": [{"track": 1}, {"track": 2}], "relations": [{"a": 1, "b": 2, "same_direction": True}]}]}


def body(track: int, x: int) -> dict:
    return {"track": track, "kin": {"position": [x, 0], "heading": [1, 0], "velocity": [5, 0], "speed": 5, "extent": [2, 1, 1]}}


GEOMETRY = {"scenes": [{"t": 0, "users": [body(1, 0), body(2, 30)], "relations": [{"a": 1, "b": 2, "same_direction": True}]}]}


def concept(cid: str, supersedes: str | None = None, formals=("u",)) -> ConceptRecord:
    return ConceptRecord({"concept_id": cid, "kind": "formula", "contract": "c holds", "params": [],
                          "args": [{"name": f, "sort": "track"} for f in formals], **({"supersedes": supersedes} if supersedes else {})})


def upheld(subject: str, grounding: dict, trace=None, case_id: str = "k1") -> dict:
    return {"key": f"concept:{subject}", "schema": review.CONCEPT_CASE_SCHEMA, "ruling": "upheld", "obligation": "open",
            "subject": subject, "iteration": 1, "case_id": case_id, "kind": "holds_wrongly", "contract_verdict": "fails",
            "contract_words": "c holds", "situation": "s", "instance": {"literals": {}, "params": {}}, "grounding": grounding,
            "trace": trace or {"scenes": [{"t": 0}]}, "at": 0, "contract_digest": review.contract_digest(concept(subject))}


class Stubs:
    """`concept_blocks`, the reviewer, the execution and the adjudication replaced; what execution
    returns is set per test, and what it was given is kept."""
    def stub(self):
        self.saved = (review.concept_blocks, review.session.run_tools, review.execute_concept_divergences, review.adjudicate_concept)
        review.concept_blocks = lambda *a, **k: ({k: "" for k in review.PLACEHOLDERS_REVIEW_CONCEPT}, "", "c holds")
        self.result, self.given, self.rulings = ([], [], [], []), [], "upheld"

        def execute(rec, answer, *_a, **_k):
            self.given.append(copy.deepcopy(answer.get("divergences") or []))
            return self.result
        review.execute_concept_divergences = execute
        review.adjudicate_concept = lambda _run, _rec, _b, items, *a, **k: [(i, self.rulings, "r") for i in items]

    def unstub(self):
        review.concept_blocks, review.session.run_tools, review.execute_concept_divergences, review.adjudicate_concept = self.saved

    def review(self, run, rec, divs, where: Path):
        answer = {"verdict": "return" if divs else "accept", "divergences": divs, "not_general": [], "advisories": []}
        review.session.run_tools = scripted_reviewer([submit(answer)] * 3)
        return review.review_concept(run, rec, {"reads": [], "body_json": {}}, where)


def effective(run, case_id="k1"):
    return [r for r in review.effective_rows(review._all_rows(run)) if r.get("case_id") == case_id]


class SuccessorSatisfaction(Stubs, unittest.TestCase):
    """A challenge a version meets is recorded on that version, with the evidence it was met on, and
    every later version of the lineage runs it again."""
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.run = FakeRun(Path(self.tmp.name))
        self.run.all_concepts = lambda: {}
        self.stub()

    def tearDown(self):
        self.unstub()
        self.tmp.cleanup()

    def where(self, name):
        return Path(self.tmp.name) / name

    def test_an_extension_is_satisfied_on_the_successor_and_a_third_version_that_regresses_is_returned(self):
        review.append_ruling(self.run, upheld("drv.motion.x", {"u": 1}))
        v2 = concept("drv.motion.x_v2", "drv.motion.x", ("u", "w"))
        ext = {**{k: upheld("drv.motion.x", {"u": 1})[k] for k in review.CONCEPT_CASE_FIELDS if k in upheld("drv.motion.x", {"u": 1})},
               "grounding": {"u": 1, "w": 2}, "extends": "k1"}
        self.result = ([], ["divergence 1 (holds_wrongly): the body agrees"], [], [])
        self.assertEqual(self.review(self.run, v2, [ext], self.where("v2")).status, "accepted")
        [row] = effective(self.run)
        self.assertEqual((row["subject"], row["key"], row["grounding"], row["obligation"], row["predecessor"]),
                         ("drv.motion.x_v2", "concept:drv.motion.x_v2", {"u": 1, "w": 2}, "satisfied", "drv.motion.x"))
        v3 = concept("drv.motion.x_v3", "drv.motion.x_v2", ("u", "w"))
        item = {"line": "divergence 1 (holds_wrongly): it confirms", "div": ext, "rule": "holds", "verdict": "compliant"}
        self.result = ([item], [], [], [])
        out = self.review(self.run, v3, [], self.where("v3"))
        self.assertEqual(out.status, "returned")                                    # the regression is caught
        self.assertEqual(self.given[-1][0]["grounding"], {"u": 1, "w": 2})          # on the evidence the challenge was met on

    def test_an_ordinary_replay_is_satisfied_on_the_version_that_ran_it(self):
        review.append_ruling(self.run, upheld("drv.motion.x", {"u": 1}))
        self.result = ([], ["divergence 1 (holds_wrongly): the body agrees"], [], [])
        review.replay_concept(self.run, concept("drv.motion.x_v2", "drv.motion.x"), self.where("v2"), None, "b2")
        [row] = effective(self.run)
        self.assertEqual((row["subject"], row["obligation"], row["predecessor"]), ("drv.motion.x_v2", "satisfied", "drv.motion.x"))
        self.result = ([{"line": "divergence 1 (holds_wrongly): it confirms", "div": {}, "rule": "holds", "verdict": "compliant"}], [], [], [])
        rep = review.replay_concept(self.run, concept("drv.motion.x_v3", "drv.motion.x_v2"), self.where("v3"), None, "b3")
        self.assertEqual([i.get("replay_of") for i in rep.items], ["k1"])

    def test_the_lineage_follows_records_and_rulings(self):
        self.run.all_concepts = lambda: {"drv.motion.x_v2": {"concept_id": "drv.motion.x_v2", "supersedes": "drv.motion.x"}}
        review.append_ruling(self.run, {**upheld("drv.motion.x_v3", {"u": 1}, case_id="k9"), "predecessor": "drv.motion.x_v2"})
        self.assertEqual(review.concept_lineage(self.run, concept("drv.motion.x_v4", "drv.motion.x_v3")),
                         ["drv.motion.x_v4", "drv.motion.x_v3", "drv.motion.x_v2", "drv.motion.x"])

    def test_a_stop_before_the_ruling_is_written_leaves_the_obligation_where_it_was(self):
        review.append_ruling(self.run, upheld("drv.motion.x", {"u": 1}))
        self.result = ([], ["divergence 1 (holds_wrongly): the body agrees"], [], [])
        v2 = concept("drv.motion.x_v2", "drv.motion.x")
        real = review.append_ruling

        class Stop(BaseException):
            pass

        def stop(*_a, **_k):
            raise Stop()
        review.append_ruling = stop
        try:
            with self.assertRaises(Stop):
                review.replay_concept(self.run, v2, self.where("v2"), None, "b2")
        finally:
            review.append_ruling = real
        [row] = effective(self.run)
        self.assertEqual((row["subject"], row["obligation"]), ("drv.motion.x", "open"))
        review.replay_concept(self.run, v2, self.where("v2b"), None, "b2")      # resumed: run again, then recorded
        [row] = effective(self.run)
        self.assertEqual((row["subject"], row["obligation"]), ("drv.motion.x_v2", "satisfied"))


class ContinuationSatisfaction(Stubs, unittest.TestCase):
    """A continuation that supersedes an inherited version finds the obligation that version met."""
    def test_a_satisfied_inherited_obligation_is_run_by_the_successor(self):
        with tempfile.TemporaryDirectory() as t, patch.object(paths, "RESULTS", Path(t) / "results"):
            root = Path(t)
            laws = root / "laws.jsonl"; laws.write_text(json.dumps({"id": "L", "title": "L", "text": "A duty.", "source": "x"}) + "\n")
            other = root / "other.jsonl"; other.write_text(json.dumps({"id": "M", "title": "M", "text": "Another.", "source": "x"}) + "\n")
            reading = root / "reading.json"; reading.write_text('{"params": [], "aggregates": []}')

            def make(name, base, lawf):
                r = Run(Options(name, lawf, root / "ontology", reading, base_run=base))
                r.dir.mkdir(parents=True, exist_ok=True)
                (r.dir / "options.json").write_text(json.dumps({"run_id": name, "base_run": base, "laws": str(lawf)}))
                r.reading_file.write_text('{"params": [], "aggregates": []}')
                return r
            a = make("A", None, laws)
            a.accepted_concepts = {"drv.motion.x_v2": {"concept_id": "drv.motion.x_v2", "supersedes": "drv.motion.x", "contract": "c holds"}}
            a.save_accepted()
            row = {**upheld("drv.motion.x_v2", {"u": 1}), "obligation": "satisfied", "predecessor": "drv.motion.x"}
            review.append_ruling(a, row)
            b = make("B", "A", other); b.load_accepted()
            self.stub()
            try:
                self.result = ([{"line": "divergence 1 (holds_wrongly): it confirms", "div": {}, "rule": "holds", "verdict": "compliant"}], [], [], [])
                rep = review.replay_concept(b, concept("drv.motion.x_v3", "drv.motion.x_v2"), root / "replay", None, "b3")
            finally:
                self.unstub()
            self.assertEqual([i.get("replay_of") for i in rep.items], ["k1"])


class MeasuredRelations(Stubs, unittest.TestCase):
    """Continuity leaves to Core only the relation fields Core computes from that scene; a measured
    relation Core cannot compute is evidence an extension must keep."""
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.run = FakeRun(Path(self.tmp.name))
        self.run.all_concepts = lambda: {}
        self.stub()

    def tearDown(self):
        self.unstub()
        self.tmp.cleanup()

    def extend(self, old_trace, new_trace):
        self.run = FakeRun(Path(tempfile.mkdtemp(dir=self.tmp.name)))
        self.run.all_concepts = lambda: {}
        review.append_ruling(self.run, upheld("drv.motion.x", {"u": 1}, trace=old_trace))
        ext = {**{k: v for k, v in upheld("drv.motion.x", {"u": 1}, trace=new_trace).items() if k in review.CONCEPT_CASE_FIELDS},
               "grounding": {"u": 1, "w": 2}, "extends": "k1"}
        self.result = ([], ["divergence 1 (holds_wrongly): the body agrees"], [], [])
        return self.review(self.run, concept("drv.motion.x_v2", "drv.motion.x", ("u", "w")), [ext], Path(self.run.dir) / "r")

    def test_a_measured_relation_may_not_change(self):
        changed = copy.deepcopy(NO_GEOMETRY); changed["scenes"][0]["relations"][0]["same_direction"] = False
        self.assertEqual(self.extend(NO_GEOMETRY, changed).status, "deferred")
        self.assertEqual(self.extend(NO_GEOMETRY, copy.deepcopy(NO_GEOMETRY)).status, "accepted")

    def test_a_computable_relation_is_left_to_core(self):
        stripped = copy.deepcopy(GEOMETRY); del stripped["scenes"][0]["relations"]
        self.assertEqual(self.extend(GEOMETRY, stripped).status, "accepted")


class Containers(unittest.TestCase):
    """A container of the wrong shape is a schema defect, through the tool and the submission alike,
    with or without `extends`; nothing runs on it and nothing raises."""
    MUTATIONS = {
        "instance_list": ("instance", ["malformed"]),
        "literals_list": ("instance", {"literals": ["x"]}),
        "nats_list": ("instance", {"nats": [1]}),
        "params_list": ("instance", {"params": [["v", "m"]]}),
        "trace_list": ("trace", ["malformed"]),
        "scenes_string": ("trace", {"scenes": "x"}),
        "scene_number": ("trace", {"scenes": [1]}),
        "grounding_list": ("grounding", ["malformed"]),
        "grounding_value_list": ("grounding", {"u": [1], "w": 2}),
    }

    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.old = upheld("drv.motion.x", {"u": 1})
        self.rec = concept("drv.motion.x_v2", "drv.motion.x", ("u", "w"))
        self.base = {**{k: self.old[k] for k in review.CONCEPT_CASE_FIELDS if k in self.old}, "grounding": {"u": 1, "w": 2}}

    def tearDown(self):
        self.tmp.cleanup()

    def tools(self, name):
        return review.ConceptTools(self.rec, "c holds", "", None, Path(self.tmp.name) / name, 3, 3, carry={"k1": self.old})

    def test_the_matrix(self):
        with patch.object(review.lean, "lean_run", side_effect=AssertionError("nothing may run")):
            for name, (key, value) in self.MUTATIONS.items():
                for extends in (False, True):
                    d = {**copy.deepcopy(self.base), key: copy.deepcopy(value), **({"extends": "k1"} if extends else {})}
                    with self.subTest(name=name, extends=extends):
                        self.assertTrue(review.concept_divergence_defects(1, d, self.rec, "c holds"))
                        t = self.tools(f"{name}_{extends}")
                        got = json.loads(t.call("run_instance", {"divergence": d}))
                        self.assertEqual(got["status"], "schema defects")
                        sub = json.loads(t.call("submit_review", {"answer": {"verdict": "return", "divergences": [d],
                                                                             "not_general": [], "advisories": []}}))
                        self.assertTrue(sub.get("defects"))

    def test_a_valid_item_beside_a_malformed_one_still_runs(self):
        good = {**copy.deepcopy(self.base), "extends": "k1"}
        bad = {**copy.deepcopy(self.base), "instance": ["malformed"], "extends": "k1"}
        ran = []
        with patch.object(review, "execute_concept_divergences", side_effect=lambda rec, a, *x, **k: ran.append(len(a["divergences"])) or ([], [], [], [])):
            t = self.tools("mixed")
            sub = json.loads(t.call("submit_review", {"answer": {"verdict": "return", "divergences": [good, bad],
                                                                 "not_general": [], "advisories": []}}))
        self.assertTrue(any("divergence 2" in x for x in sub["defects"]))
        self.assertFalse(any("divergence 1" in x for x in sub["defects"]))


class FindingIdentity(unittest.TestCase):
    """A structural finding is identified by its lineage's root and the occurrence of its words."""
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.run = FakeRun(Path(self.tmp.name))
        self.run.all_concepts = lambda: {}
        self.blocks = {"contract": "Movement holds.", "record": "{}", "rendered": "body", "contracts": "contracts"}

    def tearDown(self):
        self.tmp.cleanup()

    def adjudicate(self, rec, ruling, words="Movement", **item_extra):
        item = {"line": f'not general: "{words}" — scope', "div": {"kind": "not_general", "words": words, "why": "scope"}, **item_extra}
        answer = {"rulings": [{"item": 1, "ruling": ruling, "reason": "scope", "quote": words}]}
        with patch.object(review.validate_phase, "_session", return_value=(answer, [])), patch.object(review, "precedent_rows", return_value=[]):
            review.adjudicate_concept(self.run, rec, self.blocks, [item], Path(self.tmp.name) / rec.id)

    def test_two_concepts_with_the_same_wording(self):
        a = ConceptRecord({"concept_id": "drv.motion.a", "contract": "Movement holds.", "args": [{"name": "v", "sort": "track"}]})
        b = ConceptRecord({"concept_id": "drv.motion.b", "contract": "Movement holds.",
                           "args": [{"name": "v", "sort": "track"}, {"name": "w", "sort": "track"}]})
        self.adjudicate(a, "upheld")
        self.adjudicate(b, "dismissed")
        rows = review.effective_rows(review._all_rows(self.run))
        self.assertEqual(sorted((r["subject"], r["ruling"]) for r in rows), [("drv.motion.a", "upheld"), ("drv.motion.b", "dismissed")])
        with patch.object(review, "execute_concept_divergences", return_value=([], [], [], [])):
            rep = review.replay_concept(self.run, a, Path(self.tmp.name) / "ra", None, "body")
        self.assertEqual(len(rep.items), 1)

    def test_words_and_their_occurrence(self):
        rec = ConceptRecord({"concept_id": "drv.motion.s", "contract": "the stop line and the stop"})
        self.assertEqual(review.concept_finding_id("drv.motion.s", rec, "stop"), review.concept_finding_id("drv.motion.s", rec, "stop"))
        self.assertNotEqual(review.concept_finding_id("drv.motion.s", rec, "stop"), review.concept_finding_id("drv.motion.s", rec, "the stop"))
        self.assertNotEqual(review.concept_finding_id("drv.motion.s", rec, "stop"), review.concept_finding_id("drv.motion.t", rec, "stop"))

    def test_a_successor_keeps_its_finding(self):
        x = ConceptRecord({"concept_id": "drv.motion.x", "contract": "Movement holds.", "args": []})
        self.adjudicate(x, "upheld")
        [first] = review.effective_rows(review._all_rows(self.run))
        x2 = ConceptRecord({"concept_id": "drv.motion.x_v2", "supersedes": "drv.motion.x", "contract": "Movement holds.", "args": []})
        with patch.object(review, "execute_concept_divergences", return_value=([], [], [], [])):
            rep = review.replay_concept(self.run, x2, Path(self.tmp.name) / "rx2", None, "body")
        [item] = rep.items
        self.assertEqual((item["replay_of"], item["finding_root"]), (first["finding_id"], "drv.motion.x"))
        self.adjudicate(x2, "upheld", replay_of=item["replay_of"], finding_root=item["finding_root"])
        [row] = review.effective_rows(review._all_rows(self.run))
        self.assertEqual((row["subject"], row["finding_id"], row["finding_root"]), ("drv.motion.x_v2", first["finding_id"], "drv.motion.x"))

    def test_rows_written_before_findings_had_a_root(self):
        for subject in ("drv.motion.a", "drv.motion.b"):
            review.append_ruling(self.run, {"key": f"concept:{subject}", "subject": subject, "iteration": 1, "schema": review.CONCEPT_STRUCTURAL_SCHEMA,
                                            "finding_id": "unrooted", "words": "Movement", "why": "scope", "ruling": "upheld", "obligation": "open"})
        self.assertEqual(len(review.effective_rows(review._all_rows(self.run))), 2)           # no cross-concept supersession
        a = ConceptRecord({"concept_id": "drv.motion.a", "contract": "Movement holds.", "args": []})
        with patch.object(review, "execute_concept_divergences", return_value=([], [], [], [])):
            [item] = review.replay_concept(self.run, a, Path(self.tmp.name) / "m1", None, "body").items
        self.assertIn("legacy_of", item)
        self.adjudicate(a, "upheld", legacy_of=item["legacy_of"])
        with patch.object(review, "execute_concept_divergences", return_value=([], [], [], [])):
            items = review.replay_concept(self.run, a, Path(self.tmp.name) / "m2", None, "body").items
        self.assertEqual([("replay_of" in i, "legacy_of" in i) for i in items], [(True, False)])   # the migrated row only


class UnreadKeys(unittest.TestCase):
    """What the decoder does not read is never an executed fact."""
    TRACE = {"scenes": [{"t": 0, "users": [{"track": 1, "kin": {"speed": 0, "certified_stopped": False}}]}]}

    def test_the_same_decoded_scene_gives_the_same_facts(self):
        plain = copy.deepcopy(self.TRACE); del plain["scenes"][0]["users"][0]["kin"]["certified_stopped"]
        with tempfile.TemporaryDirectory() as t:
            a, b = Path(t) / "a.json", Path(t) / "b.json"
            a.write_text(json.dumps(self.TRACE)); b.write_text(json.dumps(plain))
            prog = Path(t) / "decode.lean"
            prog.write_text("import TrafficSpec\nopen TrafficSpec Lean\ndef main : IO Unit := do\n"
                            f"  let x := Decode.parse Decode.trace (← IO.FS.readFile {json.dumps(str(a))})\n"
                            f"  let y := Decode.parse Decode.trace (← IO.FS.readFile {json.dumps(str(b))})\n"
                            "  match x, y with\n  | .ok p, .ok q => IO.println s!\"SAME\\t{reprStr p == reprStr q}\"\n  | _, _ => IO.println \"ERR\"\n")
            code, out = lean.lean_run(paths.LIBRARY, prog)
        self.assertIn("SAME\ttrue", out)                                            # Core reads them alike
        facts = lambda tr: review.executed_facts({"trace": tr, "grounding": {"v": 1}, "at": 0}).split("\n\nUnverified annotations")[0].strip()
        self.assertEqual(facts(self.TRACE), facts(plain))
        self.assertNotIn("certified_stopped", facts(self.TRACE))
        self.assertIn("`scenes[t=0].users[1].kin.certified_stopped`", review.executed_facts({"trace": self.TRACE, "grounding": {}, "at": 0}))

    def test_a_fresh_trace_is_refused_and_a_saved_one_runs(self):
        rec = concept("drv.motion.y")
        d = {**{k: v for k, v in upheld("drv.motion.y", {"u": 1}, trace=self.TRACE).items() if k in review.CONCEPT_CASE_FIELDS}}
        fresh = review.concept_divergence_defects(1, d, rec, "c holds")
        self.assertTrue(any("certified_stopped" in e for e in fresh))
        self.assertEqual(review.concept_divergence_defects(1, d, rec, "c holds", saved=True), [])
        t = review.ConceptTools(rec, "c holds", "", None, Path(tempfile.mkdtemp()), 2, 2)
        self.assertEqual(json.loads(t.call("run_instance", {"divergence": d}))["status"], "schema defects")
        run = FakeRun(Path(tempfile.mkdtemp()))
        run.all_concepts = lambda: {}
        review.append_ruling(run, upheld("drv.motion.y", {"u": 1}, trace=self.TRACE))
        given = []
        with patch.object(review, "execute_concept_divergences", side_effect=lambda r, a, *x, **k: given.append(a) or ([], [], [], [])):
            rep = review.replay_concept(run, rec, Path(tempfile.mkdtemp()), None, "body")
        self.assertEqual((len(given[0]["divergences"]), rep.carry), (1, []))         # the saved trace runs; its annotation is not evidence


if __name__ == "__main__":
    unittest.main()
