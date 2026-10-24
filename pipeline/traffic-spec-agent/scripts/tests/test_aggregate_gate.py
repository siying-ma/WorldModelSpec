"""Development regression tests for aggregate selection and gating: structural checks, the verifier's three verdicts, the one
planner retry, the fail-closed downgrades and a launch failure that admits nothing — sessions stubbed."""
import json
import tempfile
import unittest
from pathlib import Path
from types import SimpleNamespace

from harness import loop
from harness.agents import session
from harness.checks import aggregates as checks
from harness.model import corpus, ontology
from harness.model.reading import Reading
from harness.phases import aggregate
from harness.phases import validate as validate_phase
from harness.store import paths
from harness.store.state import Options
from harness.store import jsonl
from harness.store.ledger import Ledger

ONTO = ontology.load(paths.REPO / "ontology" / "ATOMS_train.md")
CLASSES = checks.road_user_classes(ONTO)
DEF = {"id": "DEF-TST-900A-010", "title": "", "text": "“Wagon” means every device upon which a person may be carried, except devices moved by human power.", "source": ""}
TABLE = {"laws": {"TST-900B-100": [{"term": "wagon", "status": "resolved", "definition": DEF["id"], "step": "general_chapter",
                                    "chain": [DEF["id"]], "candidates": [DEF["id"]]}]}}
SOURCES = {DEF["id"]: DEF["text"]}
AID = "DEF-TST-900A-010::wagon"


def record(status="included", aid=AID):
    q = [{"definition": DEF["id"], "words": "every device upon which a person may be carried"}]
    return {"aggregate_id": aid, "term": "wagon", "definition": DEF["id"],
            "classifications": [{"class": c, "status": status, "quotes": q, "reason": "the words decide neither" if status == "unresolved" else ""} for c in CLASSES]}


class FakeRun:
    def __init__(self, d: Path):
        self.dir, self.iteration = d, 1
        self.aggregate_failures = {}
        self.opts = Options(run_id="t", laws=d / "laws.jsonl", ontology=ONTO.path, reading=d / "reading.json",
                            model="m", reviewer_model="gpt-x")
        (d / "reading.json").write_text(json.dumps({"params": [], "aggregates": []}))

    @property
    def reading_file(self):
        return self.dir / "reading.json"


class Structure(unittest.TestCase):
    def row(self, **kw):
        r = {"definition": DEF["id"], "term": "wagon", "representation": "aggregate", "target": AID,
             "quote": "every device upon which a person may be carried", "reason": "it names road users"}
        r.update(kw)
        return r

    def test_one_row_per_pair(self):
        sel, errs = checks.validate_selection([self.row()], TABLE, {DEF["id"]: DEF})
        self.assertEqual((len(sel), errs), (1, []))
        _sel, errs = checks.validate_selection([self.row(), self.row()], TABLE, {DEF["id"]: DEF})
        self.assertTrue(any("twice" in e for e in errs))
        self.assertEqual(checks.missing_pairs({}, TABLE), [(DEF["id"], "wagon")])

    def test_malformed_rows(self):
        for bad, frag in ((self.row(target="DEF-x::y"), "target"), (self.row(representation="direct"), "representation"),
                          (self.row(quote="words that are not there"), "not verbatim"),
                          (self.row(representation="not_aggregate"), "null")):
            _sel, errs = checks.validate_selection([bad], TABLE, {DEF["id"]: DEF})
            self.assertTrue(any(frag in e for e in errs), (frag, errs))

    def test_a_one_class_definition_is_still_an_aggregate(self):
        self.assertEqual(checks.validate_selection([self.row()], TABLE, {DEF["id"]: DEF})[1], [])

    def test_record_completeness_and_provenance(self):
        self.assertEqual(checks.record_defects(record(), ONTO, SOURCES), [])
        r = record(); r["classifications"] = r["classifications"][1:]
        self.assertTrue(any("missing" in e for e in checks.record_defects(r, ONTO, SOURCES)))
        r = record(); r["classifications"].append({"class": "DEF-TST-900A-020::cart", "status": "included", "quotes": []})
        self.assertTrue(any("never another aggregate" in e for e in checks.record_defects(r, ONTO, SOURCES)))
        r = record(); r["classifications"][0]["quotes"] = [{"definition": DEF["id"], "words": "invented words"}]
        self.assertTrue(any("not verbatim" in e for e in checks.record_defects(r, ONTO, SOURCES)))
        r = record("unresolved"); r["classifications"][0]["reason"] = ""
        self.assertTrue(any("explains" in e for e in checks.record_defects(r, ONTO, SOURCES)))

    def test_only_aggregate_rows_are_derived(self):
        answer = {"selection": [self.row(representation="not_aggregate", target=None)], "aggregates": [record()]}
        errs = aggregate._answer_defects(answer, {}, TABLE, {DEF["id"]: DEF}, ONTO, {(DEF["id"], "wagon")})
        self.assertTrue(any("no selection row makes it an aggregate" in e for e in errs))

    def test_a_relational_role_is_validly_not_an_aggregate(self):
        row = self.row(representation="not_aggregate", target=None,
                       reason="who controls a wagon is a relational role")
        sel, errs = checks.validate_selection([row], TABLE, {DEF["id"]: DEF})
        self.assertEqual((sel[(DEF["id"], "wagon")]["representation"], errs), ("not_aggregate", []))

    def test_nested_definition_words_are_valid_mapping_evidence(self):
        nested = {"id": "DEF-TST-900A-020", "text": "“Cart” means a wagon with four wheels."}
        table = {"laws": {"TST-900B-100": [{"term": "cart", "status": "resolved", "definition": nested["id"],
                                              "step": "general_chapter", "chain": [nested["id"]],
                                              "candidates": [nested["id"]],
                                              "dependencies": [{"from": nested["id"], "term": "wagon",
                                                                "status": "resolved", "definition": DEF["id"],
                                                                "step": "own_chapter", "chain": [DEF["id"]],
                                                                "candidates": [DEF["id"]]}]}]}}
        sources = aggregate._sources(table, {DEF["id"]: DEF, nested["id"]: nested}, nested["id"])
        self.assertEqual(set(sources), {nested["id"], DEF["id"]})
        rec = record(aid="DEF-TST-900A-020::cart")
        rec["definition"], rec["term"] = nested["id"], "cart"
        self.assertEqual(checks.record_defects(rec, ONTO, sources), [])


class Verifier:
    """A stub for `validate._session` answering the verifier with scripted verdicts per call."""
    def __init__(self, *rounds):
        self.rounds, self.calls = list(rounds), 0

    def __call__(self, run, out_dir, label, prompt, check=None, model=None, effort=None):
        self.calls += 1
        r = self.rounds.pop(0)
        if r == "raise":
            raise session.SessionUnavailable("down")
        if r == "malformed":
            return {"x": 1}, ["malformed"]
        ans = {"aggregate_id": AID, "classifications": [{"class": c, "verdict": r.get(c, r.get("*")), "reason": "r"} for c in CLASSES]}
        return ans, (list(check(ans)) if check else [])


class Gate(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.run = FakeRun(Path(self.tmp.name))
        self.saved = validate_phase._session
        self.digests = {"definition_digest": "d"}

    def tearDown(self):
        validate_phase._session = self.saved
        self.tmp.cleanup()

    def gate(self, verifier, rec=None, retry=None):
        validate_phase._session = verifier
        self.retries = []

        def r(old, feedback):
            self.retries.append(feedback)
            return retry
        return aggregate.gate(self.run, rec or record(), SOURCES, ONTO, Path(self.tmp.name), r, self.digests)

    def test_supported_is_admitted_as_proposed(self):
        entry, cert = self.gate(Verifier({"*": "supported"}))
        self.assertEqual(sorted(entry["included"]), CLASSES)
        self.assertEqual(cert["downgrades"], [])

    def test_underdetermined_is_downgraded(self):
        entry, cert = self.gate(Verifier({"*": "supported", CLASSES[0]: "underdetermined"}))
        self.assertEqual(entry["unresolved"], [CLASSES[0]])
        self.assertEqual(cert["downgrades"][0]["why"], "underdetermined")

    def test_contradiction_goes_back_to_the_planner_once(self):
        entry, cert = self.gate(Verifier({"*": "supported", CLASSES[0]: "contradicted"}, {"*": "supported", CLASSES[0]: "contradicted"}),
                                retry=record())
        self.assertEqual(len(self.retries), 1)
        self.assertIn(CLASSES[0], self.retries[0])
        self.assertEqual(entry["unresolved"], [CLASSES[0]])
        self.assertEqual(cert["downgrades"][0]["why"], "gate_contradiction")
        self.assertIsNotNone(cert["retry"])

    def test_a_retry_the_gate_supports_is_admitted(self):
        new = record(); new["classifications"][0]["status"] = "excluded"
        entry, _cert = self.gate(Verifier({"*": "supported", CLASSES[0]: "contradicted"}, {"*": "supported"}), retry=new)
        self.assertNotIn(CLASSES[0], entry["included"] + entry["unresolved"])

    def test_a_malformed_answer_admits_nothing(self):
        with self.assertRaises(session.SessionUnavailable):
            self.gate(Verifier("malformed"))

    def test_a_launch_failure_admits_nothing(self):
        validate_phase._session = Verifier("raise")
        with self.assertRaises(session.SessionUnavailable):
            aggregate.admit(self.run, [record()], TABLE, [DEF], ONTO, Path(self.tmp.name))
        self.assertFalse(aggregate.certificates_file(self.run).exists())
        self.assertEqual(json.loads(self.run.reading_file.read_text())["aggregates"], [])

    def test_admitted_once_and_never_replaced(self):
        validate_phase._session = Verifier({"*": "supported"})
        entries, _n, _u = aggregate.admit(self.run, [record()], TABLE, [DEF], ONTO, Path(self.tmp.name))
        self.assertEqual(len(entries), 1)
        validate_phase._session = Verifier()                         # a second admission would call the verifier
        entries, _n, _u = aggregate.admit(self.run, [record("excluded")], TABLE, [DEF], ONTO, Path(self.tmp.name))
        self.assertEqual(entries, [])

    def test_a_digest_change_is_a_different_certificate(self):
        e1, _ = self.gate(Verifier({"*": "supported"}))
        self.digests = {"definition_digest": "other"}
        e2, _ = self.gate(Verifier({"*": "supported"}))
        self.assertNotEqual(e1["certificate"], e2["certificate"])


class Preparation(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.run = FakeRun(Path(self.tmp.name))
        (self.run.dir / "definition_resolution.json").write_text(json.dumps(TABLE))
        self.row = {"definition": DEF["id"], "term": "wagon", "representation": "aggregate", "target": AID,
                    "quote": "every device upon which a person may be carried", "reason": "it names road users"}
        aggregate.save_selection(self.run, {(DEF["id"], "wagon"): self.row})
        self.select = aggregate.select_and_derive
        self.admit = aggregate.admit

    def tearDown(self):
        aggregate.select_and_derive = self.select
        aggregate.admit = self.admit
        self.tmp.cleanup()

    def test_a_selection_without_an_admission_is_derived_again(self):
        calls = []

        def select(_run, _table, _defs, _onto, want, _out_dir, **_kw):
            calls.append(want)
            return {(DEF["id"], "wagon"): self.row}, [record()], []

        aggregate.select_and_derive = select
        aggregate.admit = lambda *_a, **_kw: ([], [], [])
        aggregate.prepare(self.run, [], [DEF], ONTO, self.run.dir / "out")
        self.assertEqual(calls, [{(DEF["id"], "wagon")}])

    def test_certificate_digests_are_strict_and_follow_invalidations(self):
        f = aggregate.certificates_file(self.run)
        f.write_text('{"aggregate_id":')
        with self.assertRaises(jsonl.DataIntegrityError):
            aggregate.certificate_digests(self.run)
        f.write_text("".join(json.dumps(r) + "\n" for r in [
            {"aggregate_id": AID, "admitted": {"certificate": "c"}, "gate_input_digest": "g"},
            {"aggregate_id": AID, "invalidates": "c"},
        ]))
        self.assertEqual(aggregate.certificate_digests(self.run), {})

    def test_a_resumed_plan_is_an_aggregate_claimant(self):
        plan_dir = self.run.dir / "iter-001" / "plan"
        jsonl.write_rows(plan_dir / "blueprint.jsonl", [{
            "node_id": "TST_900B_100_o1", "law_refs": ["TST-900B-100"],
            "elements": [{"atoms": [f"ru.aggregate={AID}"]}],
        }])
        run = SimpleNamespace(all_nodes=lambda: {}, deferred_nodes=[])
        claimants = loop.aggregate_claimants(run, SimpleNamespace(entries={}), {"plan_dir": str(plan_dir)})
        self.assertEqual(claimants, {AID: ["TST_900B_100_o1"]})


class Correction(unittest.TestCase):
    def test_a_second_unselected_claim_closes_the_law(self):
        tmp = tempfile.TemporaryDirectory()
        run = FakeRun(Path(tmp.name))
        led = Ledger(Path(tmp.name) / "l.jsonl", ["TST-900B-100"], 2)
        saved = aggregate.select_and_derive
        aggregate.select_and_derive = lambda *a, **k: ({}, [], [])
        try:
            (Path(tmp.name) / "definition_resolution.json").write_text(json.dumps(TABLE))
            _n, close = aggregate.correct_claims(run, {"TST-900B-100": {AID}}, [DEF], ONTO, led, Path(tmp.name))
            self.assertEqual(close, {})
            _n, close = aggregate.correct_claims(run, {"TST-900B-100": {AID}}, [DEF], ONTO, led, Path(tmp.name))
            self.assertIn("planning_protocol_failure", close["TST-900B-100"])
        finally:
            aggregate.select_and_derive = saved
            tmp.cleanup()

    def test_an_unavailable_correction_session_does_not_spend_the_correction(self):
        tmp = tempfile.TemporaryDirectory()
        run = FakeRun(Path(tmp.name))
        led = Ledger(Path(tmp.name) / "l.jsonl", ["TST-900B-100"], 2)
        saved = aggregate.select_and_derive
        aggregate.select_and_derive = lambda *a, **k: (_ for _ in ()).throw(session.SessionUnavailable("down"))
        try:
            (Path(tmp.name) / "definition_resolution.json").write_text(json.dumps(TABLE))
            with self.assertRaises(session.SessionUnavailable):
                aggregate.correct_claims(run, {"TST-900B-100": {AID}}, [DEF], ONTO, led, Path(tmp.name))
            self.assertEqual(led.entries["TST-900B-100"].selection_corrections, 0)
        finally:
            aggregate.select_and_derive = saved
            tmp.cleanup()




class Admissions(unittest.TestCase):
    """The manifest: an unchanged admission is reused, one whose reading entry was lost is restored,
    a stale one is invalidated and derived again, or stops the run when a node claims it."""
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.run = FakeRun(Path(self.tmp.name))
        (Path(self.tmp.name) / "definition_resolution.json").write_text(json.dumps(TABLE))
        aggregate.save_selection(self.run, {(DEF["id"], "wagon"): {"definition": DEF["id"], "term": "wagon", "representation": "aggregate",
                                                                  "target": AID, "quote": "x", "reason": "y"}})
        self.saved = validate_phase._session
        validate_phase._session = Verifier({"*": "supported"})
        aggregate.admit(self.run, [record()], TABLE, [DEF], ONTO, Path(self.tmp.name))

    def tearDown(self):
        validate_phase._session = self.saved
        self.tmp.cleanup()

    def reading(self):
        return json.loads(self.run.reading_file.read_text())["aggregates"]

    def test_unchanged_is_reused(self):
        notes, stop = aggregate.check_admissions(self.run, {}, [DEF], ONTO, {})
        self.assertEqual((notes, stop), ([], []))
        self.assertEqual(len(self.reading()), 1)

    def test_a_lost_reading_entry_is_restored_from_its_certificate(self):
        self.run.reading_file.write_text(json.dumps({"params": [], "aggregates": []}))
        notes, _stop = aggregate.check_admissions(self.run, {}, [DEF], ONTO, {})
        self.assertTrue(any("restored" in n for n in notes))
        self.assertEqual([a["id"] for a in self.reading()], [AID])

    def test_a_lost_manifest_entry_is_restored_from_its_certificate(self):
        aggregate.manifest_file(self.run).write_text(json.dumps({"aggregates": {}}))
        notes, stop = aggregate.check_admissions(self.run, {}, [DEF], ONTO, {})
        self.assertEqual(stop, [])
        self.assertTrue(any("manifest" in n for n in notes))
        self.assertEqual([a["id"] for a in self.reading()], [AID])
        self.assertIn(AID, json.loads(aggregate.manifest_file(self.run).read_text())["aggregates"])

    def test_stale_without_nodes_is_invalidated_and_derived_again(self):
        changed = {**DEF, "text": DEF["text"].replace("human power", "human or animal power")}
        notes, stop = aggregate.check_admissions(self.run, {}, [changed], ONTO, {})
        self.assertEqual(stop, [])
        self.assertTrue(any("stale" in n for n in notes))
        self.assertEqual(self.reading(), [])
        self.assertEqual(aggregate.load_selection(self.run), {})               # the pair is selected again
        rows = jsonl.read_strict(aggregate.certificates_file(self.run))
        self.assertTrue(rows[0].get("admitted") and rows[-1].get("invalidates"))  # the certificate stays

    def test_stale_under_a_node_stops_the_run(self):
        self.run.opts.reviewer_model = "gpt-y"                                 # the verifier changed
        _notes, stop = aggregate.check_admissions(self.run, {}, [DEF], ONTO, {AID: ["L_1_o1"]})
        self.assertTrue(stop and "models" in stop[0])


class BaseRunAdmission(unittest.TestCase):
    """A run on a base run takes the base's unchanged admission with the selection row it rests on,
    though its own selection is still empty."""
    setUp, tearDown = Admissions.setUp, Admissions.tearDown

    def test_taken_with_its_selection_row(self):
        from harness.store import paths
        new = tempfile.TemporaryDirectory()
        saved = paths.RESULTS
        try:
            paths.RESULTS = Path(self.tmp.name).parent
            run = FakeRun(Path(new.name)); run.opts.base_run = Path(self.tmp.name).name
            (Path(new.name) / "definition_resolution.json").write_text(json.dumps(TABLE))
            notes, stop = aggregate.check_admissions(run, {}, [DEF], ONTO, {AID: ["L_1_o1"]})
            self.assertEqual(stop, [])
            self.assertTrue(any("taken from base run" in n for n in notes), notes)
            self.assertEqual([r["target"] for r in aggregate.load_selection(run).values()], [AID])
            self.assertEqual(aggregate.check_admissions(run, {}, [DEF], ONTO, {AID: ["L_1_o1"]}), ([], []))   # and kept
        finally:
            paths.RESULTS = saved
            new.cleanup()


class OutageThenResume(unittest.TestCase):
    """A verifier that cannot be launched after the selection was saved leaves the selected aggregate
    uncertified; the resumed preparation gates it instead of taking the selection as done."""
    def test_outage_then_resume(self):
        tmp = tempfile.TemporaryDirectory()
        run = FakeRun(Path(tmp.name))
        (run.dir / "definition_resolution.json").write_text(json.dumps(TABLE))
        row = {"definition": DEF["id"], "term": "wagon", "representation": "aggregate", "target": AID,
               "quote": "every device upon which a person may be carried", "reason": "it names road users"}
        saved_select, saved_session = aggregate.select_and_derive, validate_phase._session
        aggregate.select_and_derive = lambda *a, **k: ({(DEF["id"], "wagon"): row}, [record()], [])
        try:
            validate_phase._session = Verifier("raise")
            with self.assertRaises(session.SessionUnavailable):
                aggregate.prepare(run, [], [DEF], ONTO, run.dir / "out")
            self.assertIn((DEF["id"], "wagon"), aggregate.load_selection(run))        # selected …
            self.assertIsNone(aggregate.Reading(run.reading_file).aggregate(AID))      # … but not admitted
            self.assertFalse(aggregate.certificates_file(run).exists())
            validate_phase._session = Verifier({"*": "supported"})
            aggregate.prepare(run, [], [DEF], ONTO, run.dir / "out")                    # the resume
            self.assertIsNotNone(aggregate.Reading(run.reading_file).aggregate(AID))
            self.assertEqual(len(jsonl.read_strict(aggregate.certificates_file(run))), 1)
            validate_phase._session = Verifier()                                        # nothing left: no further call
            aggregate.prepare(run, [], [DEF], ONTO, run.dir / "out")
        finally:
            aggregate.select_and_derive, validate_phase._session = saved_select, saved_session
            tmp.cleanup()


class ElisionAndUnderived(unittest.TestCase):
    def test_an_elided_quote_is_verbatim_fragment_by_fragment(self):
        self.assertTrue(checks._verbatim("every device … may be carried", DEF["text"]))
        self.assertFalse(checks._verbatim("may be carried … every device", DEF["text"]))      # out of order
        self.assertFalse(checks._verbatim("every … carried", DEF["text"]))                     # too few words

    def test_a_selected_aggregate_left_underived_holds_its_laws_then_stops_the_run(self):
        tmp = tempfile.TemporaryDirectory()
        run = FakeRun(Path(tmp.name))
        (run.dir / "definition_resolution.json").write_text(json.dumps(TABLE))
        row = {"definition": DEF["id"], "term": "wagon", "representation": "aggregate", "target": AID, "quote": "x", "reason": "y"}
        saved = aggregate.select_and_derive
        aggregate.select_and_derive = lambda *a, **k: ({(DEF["id"], "wagon"): row}, [], ["aggregate: a quote is not verbatim"])
        try:
            _n, _u, hold, stop = aggregate.prepare(run, [], [DEF], ONTO, run.dir / "out")
            self.assertIn("the mapping of", hold["TST-900B-100"])
            self.assertEqual(stop, "")
            (run.dir / "aggregate_selection.jsonl").unlink(missing_ok=True)      # asked again next iteration
            _n, _u, hold, stop = aggregate.prepare(run, [], [DEF], ONTO, run.dir / "out")
            self.assertIn("the mapping of", stop)
        finally:
            aggregate.select_and_derive = saved
            tmp.cleanup()


class LawLocalBinding(unittest.TestCase):
    """A law-local admission is bound to its record: the same id with another mapping is gated again."""
    def test_another_mapping_under_the_same_id_is_gated_again(self):
        tmp = tempfile.TemporaryDirectory()
        run = FakeRun(Path(tmp.name))
        (run.dir / "definition_resolution.json").write_text(json.dumps(TABLE))
        aid = "TST-900B-100:s1::wagon"
        calls = []

        def gate(run_, rec, sources, onto, out_dir, retry, digests):
            calls.append(rec)
            return aggregate._finish({"aggregate_id": aid, "proposal": rec, "retry": None, "exchanges": [], "downgrades": [], **digests},
                                     rec, {c["class"]: c["status"] for c in rec["classifications"]}, digests)
        saved = aggregate.gate
        aggregate.gate = gate
        try:
            law = corpus.Law("TST-900B-100", "", "every device upon which a person may be carried", "")
            one, two = record(aid=aid), record(status="unresolved", aid=aid)
            aggregate.admit(run, [one], TABLE, [DEF], ONTO, run.dir / "out", laws={law.id: law})
            aggregate.admit(run, [one], TABLE, [DEF], ONTO, run.dir / "out", laws={law.id: law})
            self.assertEqual(len(calls), 1)                                    # the same record: reused
            aggregate.admit(run, [two], TABLE, [DEF], ONTO, run.dir / "out", laws={law.id: law})
            self.assertEqual(len(calls), 2)
            self.assertEqual(Reading(run.reading_file).aggregate(aid)["included"], [])
        finally:
            aggregate.gate = saved
            tmp.cleanup()


class BareAggregateClaim(unittest.TestCase):
    """A bare `ru.aggregate` returns the plan wherever the record claims it, an operationalization's concepts included."""

    def test_bare_claim_in_operationalization(self):
        from harness.checks import validate_a
        from harness.model.blueprint import Node
        from harness.model.reading import Reading
        tmp = tempfile.TemporaryDirectory()
        try:
            run = FakeRun(Path(tmp.name))
            node = Node({"node_id": "TST_900B_100", "law_refs": ["TST-900B-100"], "segmentation": [{"id": "s1", "text": "w", "role": "subject"}],
                         "elements": [{"span": "s1", "atoms": [f"ru.aggregate={AID}"], "derived": []}],
                         "operationalizations": [{"span": "s1", "concepts": ["ru.aggregate", "kin.speed"], "params": []}], "params": []})
            errs, _p = validate_a.check_standards(node, Reading(run.dir / "reading.json"))
            self.assertTrue(any("bare `ru.aggregate`" in e for e in errs), errs)
        finally:
            tmp.cleanup()

if __name__ == "__main__":
    unittest.main()
