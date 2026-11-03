"""The `covered` mapping status: its schema on the proposal, its second check on the final admitted
statuses (a covered class whose covering class is not finally included becomes unresolved), its
persistence through the certificate, the reading and a resume, its digests, the definition-scoped
and law-local paths alike, the rendering every role is shown, and, with the real Lean decoder and
evaluator, that the reading's executable projection keeps Core's membership semantics. Sessions are
stubbed; the Lean part runs only when the library is built."""
import json
import subprocess
import tempfile
import unittest
from pathlib import Path

from harness.checks import aggregates as checks
from harness.model import corpus
from harness.model.reading import Reading
from harness.phases import aggregate
from harness.phases import review
from harness.phases import validate as validate_phase
from harness.store import jsonl, paths
from scripts.tests.test_aggregate_gate import CLASSES, ONTO, FakeRun

DEF = {"id": "DEF-TST-900A-030", "title": "", "source": "",
       "text": "“Lorry” means every motor vehicle used to carry goods, with a body built for that purpose."}
TABLE = {"laws": {"TST-900B-100": [{"term": "lorry", "status": "resolved", "definition": DEF["id"], "step": "general_chapter",
                                    "chain": [DEF["id"]], "candidates": [DEF["id"]]}]}}
SOURCES = {DEF["id"]: DEF["text"]}
AID = "DEF-TST-900A-030::lorry"
LOCAL = "TST-900B-100:s1::lorry"
LAW = corpus.Law("TST-900B-100", "", DEF["text"], "")
GENERIC, SPECIFIC, OPEN = "ru.motor_vehicle", "ru.truck", "ru.trailer_or_combination"
WORDS = "every motor vehicle used to carry goods"


def contract_words(c: str) -> str:
    """The first words of a class's contract, verbatim, whatever the ontology's wording."""
    return " ".join(ONTO.contract(c).split()[:5])


def mapping(aid=AID, src=DEF["id"], **cover) -> dict:
    """SPECIFIC included, GENERIC covered by it, OPEN unresolved, every other class excluded; `cover`
    replaces fields of GENERIC's classification (None removes one)."""
    q = [{"definition": src, "words": WORDS}]
    cls = []
    for c in CLASSES:
        if c == SPECIFIC:
            cls.append({"class": c, "status": "included", "quotes": q})
        elif c == GENERIC:
            g = {"class": c, "status": "covered", "quotes": q, "covered_by": [SPECIFIC],
                 "basis": [{"class": SPECIFIC, "words": contract_words(SPECIFIC)}],
                 "reason": "the words admit a motor vehicle only as one built to carry goods, which the specific class is"}
            for k, v in cover.items():
                if v is None:
                    g.pop(k, None)
                else:
                    g[k] = v
            cls.append(g)
        elif c == OPEN:
            cls.append({"class": c, "status": "unresolved", "quotes": q, "reason": "the words do not decide a drawn unit"})
        else:
            cls.append({"class": c, "status": "excluded", "quotes": q})
    return {"aggregate_id": aid, "term": "lorry", "definition": src if src.startswith("DEF-") else None, "classifications": cls}


def three_status() -> dict:
    """The same mapping with GENERIC unresolved, as a three-status record writes it."""
    rec = mapping()
    g = next(c for c in rec["classifications"] if c["class"] == GENERIC)
    for k in ("covered_by", "basis"):
        g.pop(k)
    g["status"] = "unresolved"
    return rec


def set_status(rec: dict, cls: str, status: str) -> dict:
    for c in rec["classifications"]:
        if c["class"] == cls:
            c["status"] = status
            if status == "unresolved":
                c["reason"] = "r"
    return rec


class Verifier:
    """`validate._session` for the verifier: scripted verdicts per call, `*` for every other class."""
    def __init__(self, *rounds):
        self.rounds, self.prompts = list(rounds), []

    def __call__(self, run, out_dir, label, prompt, check=None, model=None, effort=None, **_k):
        self.prompts.append(prompt)
        r = self.rounds.pop(0)
        aid = json.loads(prompt.split("```json\n", 1)[1].split("\n```", 1)[0])["aggregate_id"]
        ans = {"aggregate_id": aid, "classifications": [{"class": c, "verdict": r.get(c, r.get("*")), "reason": "r"} for c in CLASSES]}
        return ans, (list(check(ans)) if check else [])


class Base(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.run = FakeRun(Path(self.tmp.name))
        (self.run.dir / "definition_resolution.json").write_text(json.dumps(TABLE))
        aggregate.save_selection(self.run, {(DEF["id"], "lorry"): {"definition": DEF["id"], "term": "lorry", "representation": "aggregate",
                                                                   "target": AID, "quote": WORDS, "reason": "it names road users"}})
        self.saved = validate_phase._session

    def tearDown(self):
        validate_phase._session = self.saved
        self.tmp.cleanup()

    def admit(self, rec, verifier, local=False, retry_record=None):
        validate_phase._session = verifier
        saved = aggregate.select_and_derive
        aggregate.select_and_derive = lambda *a, **k: ({}, [retry_record] if retry_record else [], [])
        try:
            return aggregate.admit(self.run, [rec], TABLE, [DEF], ONTO, self.run.dir / "out", laws={LAW.id: LAW} if local else None)
        finally:
            aggregate.select_and_derive = saved

    def entry(self, aid=AID):
        return Reading(self.run.reading_file).aggregate(aid)

    def cert(self, aid=AID):
        return aggregate._effective_certificates(jsonl.read_strict(aggregate.certificates_file(self.run)))[aid]


class Schema(unittest.TestCase):
    """The proposal's covered fields, on both paths (the definition-scoped sources, the law's text)."""
    def defects(self, rec, sources=SOURCES):
        return checks.record_defects(rec, ONTO, sources)

    def assertRejected(self, rec, frag):
        for r, src in ((rec, SOURCES), ({**json.loads(json.dumps(rec).replace(DEF["id"], LAW.id)), "aggregate_id": LOCAL, "definition": None},
                                         {LAW.id: LAW.text})):
            errs = self.defects(r, src)
            self.assertTrue(any(frag in e for e in errs), (frag, errs))

    def test_a_well_formed_covered_class_is_accepted_on_both_paths(self):
        self.assertEqual(self.defects(mapping()), [])
        self.assertEqual(self.defects(mapping(aid=LOCAL, src=LAW.id), {LAW.id: LAW.text}), [])

    def test_a_three_status_record_is_still_accepted(self):
        self.assertEqual(self.defects(three_status()), [])

    def test_covered_by_empty_self_unknown_or_not_included_is_rejected(self):
        self.assertRejected(mapping(covered_by=[]), "non-empty list")
        self.assertRejected(mapping(covered_by=None), "non-empty list")
        self.assertRejected(mapping(covered_by=[GENERIC]), "names the class itself")
        self.assertRejected(mapping(covered_by=["ru.lorry"]), "not a road-user class")
        self.assertRejected(mapping(covered_by=["ru.bus"]), "does not include")          # excluded
        self.assertRejected(set_status(mapping(), SPECIFIC, "unresolved"), "does not include")

    def test_no_chain_and_no_cycle(self):
        chain = mapping(covered_by=["ru.bus"])
        bus = next(c for c in chain["classifications"] if c["class"] == "ru.bus")
        bus.update({"status": "covered", "covered_by": [SPECIFIC], "basis": [{"class": SPECIFIC, "words": contract_words(SPECIFIC)}], "reason": "r"})
        errs = self.defects(chain)
        self.assertTrue(any(f"{GENERIC}: `covered_by` names `ru.bus`, which the mapping does not include (it is covered)" in e for e in errs), errs)
        bus["covered_by"] = [GENERIC]                                                 # a cycle
        errs = self.defects(chain)
        self.assertEqual(sum("does not include (it is covered)" in e for e in errs), 2, errs)

    def test_basis_must_quote_the_contracts_verbatim(self):
        self.assertRejected(mapping(basis=None), "`basis` quotes the class contracts")
        self.assertRejected(mapping(basis=[{"class": SPECIFIC, "words": "a vehicle that carries goods for hire"}]), "not verbatim in the contract")
        self.assertRejected(mapping(basis=[{"class": "ru.bus", "words": contract_words("ru.bus")}]), "neither the class nor one of its covering")
        self.assertEqual(self.defects(mapping(basis=[{"class": GENERIC, "words": contract_words(GENERIC)}])), [])

    def test_a_reason_is_required_and_cover_fields_belong_to_covered_only(self):
        self.assertRejected(mapping(reason=""), "a covered status explains")
        rec = mapping()
        next(c for c in rec["classifications"] if c["class"] == SPECIFIC)["covered_by"] = [GENERIC]
        self.assertTrue(any("only a covered class carries" in e for e in self.defects(rec)))


class Admission(Base):
    """The gate on the final statuses, through `admit` into the run's reading and certificate."""
    def test_supported_coverage_is_admitted_with_its_fields(self):
        _e, notes, _u = self.admit(mapping(), Verifier({"*": "supported"}))
        e = self.entry()
        self.assertEqual((e["included"], e["unresolved"]), ([SPECIFIC], [OPEN]))
        self.assertEqual([(c["class"], c["covered_by"]) for c in e["covered"]], [(GENERIC, [SPECIFIC])])
        self.assertEqual(e["covered"][0]["basis"], [{"class": SPECIFIC, "words": contract_words(SPECIFIC)}])
        self.assertEqual(self.cert()["downgrades"], [])
        self.assertIn("covered 1", notes[0])

    def test_a_covering_class_the_verifier_does_not_support_takes_the_covered_class_with_it(self):
        self.admit(mapping(), Verifier({"*": "supported", SPECIFIC: "underdetermined"}))
        e, cert = self.entry(), self.cert()
        self.assertEqual(e["included"], [])
        self.assertEqual(e["unresolved"], sorted([SPECIFIC, GENERIC, OPEN]))
        self.assertNotIn("covered", e)
        self.assertEqual([(d["class"], d["why"]) for d in cert["downgrades"]],
                         [(SPECIFIC, "underdetermined"), (GENERIC, "cover_target_not_admitted")])

    def test_a_covering_class_still_contradicted_after_the_retry(self):
        v = Verifier({"*": "supported", SPECIFIC: "contradicted"}, {"*": "supported", SPECIFIC: "contradicted"})
        self.admit(mapping(), v, retry_record=mapping())
        self.assertIn("another decided status", self.cert()["retry"]["feedback"])
        self.assertEqual([(d["class"], d["why"]) for d in self.cert()["downgrades"]],
                         [(SPECIFIC, "gate_contradiction"), (GENERIC, "cover_target_not_admitted")])
        self.assertIn(GENERIC, self.entry()["unresolved"])

    def test_an_unsupported_coverage_claim_becomes_unresolved(self):
        self.admit(mapping(), Verifier({"*": "supported", GENERIC: "underdetermined"}))
        self.assertEqual(self.entry()["unresolved"], sorted([GENERIC, OPEN]))
        self.assertEqual(self.entry()["included"], [SPECIFIC])
        self.assertEqual([(d["class"], d["why"]) for d in self.cert()["downgrades"]], [(GENERIC, "underdetermined")])

    def test_the_final_check_holds_without_the_schema(self):
        """A record that bypassed the proposal check: the gate itself refuses a cover that is empty,
        the class itself, a class that does not exist, or a covered class."""
        for bad in ([], [GENERIC], ["ru.lorry"], [OPEN]):
            validate_phase._session = Verifier({"*": "supported"})
            entry, cert = aggregate.gate(self.run, mapping(covered_by=bad), SOURCES, ONTO, self.run.dir, lambda *_a: None, {"d": "x"})
            self.assertIn(GENERIC, entry["unresolved"], bad)
            self.assertEqual(cert["downgrades"][-1]["why"], "cover_target_not_admitted")

    def test_the_law_local_path_admits_the_same_final_mapping(self):
        def project(e):
            return e["included"], e["unresolved"], [(c["class"], c["covered_by"]) for c in e.get("covered", [])]
        for verdicts in ({"*": "supported"}, {"*": "supported", SPECIFIC: "underdetermined"}, {"*": "supported", GENERIC: "underdetermined"}):
            self.run.reading_file.write_text(json.dumps({"params": [], "aggregates": []}))
            for rec in (mapping(), mapping(aid=LOCAL, src=LAW.id)):
                self.admit(rec, Verifier(verdicts), local=rec["aggregate_id"] == LOCAL)
            self.assertEqual(project(self.entry(AID)), project(self.entry(LOCAL)), verdicts)
            self.assertEqual([d["why"] for d in self.cert(AID)["downgrades"]], [d["why"] for d in self.cert(LOCAL)["downgrades"]])
            aggregate.certificates_file(self.run).unlink()


class PersistenceAndDigests(Base):
    def test_the_certificate_keeps_the_proposal_and_the_final_status(self):
        self.admit(mapping(), Verifier({"*": "supported"}))
        cert = self.cert()
        g = next(c for c in cert["proposal"]["classifications"] if c["class"] == GENERIC)
        self.assertEqual((g["status"], g["covered_by"]), ("covered", [SPECIFIC]))
        self.assertEqual(cert["admitted"]["covered"][0]["covered_by"], [SPECIFIC])

    def test_resume_restores_the_covered_entry_and_reuses_it(self):
        self.admit(mapping(), Verifier({"*": "supported"}))
        before = self.entry()
        self.run.reading_file.write_text(json.dumps({"params": [], "aggregates": []}))
        notes, stop = aggregate.check_admissions(self.run, {}, [DEF], ONTO, {})
        self.assertEqual(stop, [])
        self.assertTrue(any("restored" in n for n in notes))
        self.assertEqual(self.entry(), before)
        self.assertEqual(aggregate.check_admissions(self.run, {}, [DEF], ONTO, {}), ([], []))
        self.assertEqual(self.entry()["covered"], before["covered"])

    def test_a_change_of_coverage_changes_the_certificate_digest(self):
        validate_phase._session = Verifier({"*": "supported"}, {"*": "supported"}, {"*": "supported"})
        digests = {"definition_digest": "d"}
        one, _ = aggregate.gate(self.run, mapping(), SOURCES, ONTO, self.run.dir, lambda *_a: None, digests)
        basis = [{"class": GENERIC, "words": contract_words(GENERIC)}]
        two, _ = aggregate.gate(self.run, mapping(basis=basis), SOURCES, ONTO, self.run.dir, lambda *_a: None, digests)
        three, _ = aggregate.gate(self.run, three_status(), SOURCES, ONTO, self.run.dir, lambda *_a: None, digests)
        self.assertEqual(len({one["certificate"], two["certificate"], three["certificate"]}), 3)

    def test_a_law_local_record_whose_coverage_changes_is_gated_again(self):
        self.admit(mapping(aid=LOCAL, src=LAW.id), Verifier({"*": "supported"}), local=True)
        self.admit(mapping(aid=LOCAL, src=LAW.id), Verifier(), local=True)            # the same record: no call
        basis = [{"class": GENERIC, "words": contract_words(GENERIC)}]
        self.admit(mapping(aid=LOCAL, src=LAW.id, basis=basis), Verifier({"*": "supported"}), local=True)
        self.assertEqual(self.entry(LOCAL)["covered"][0]["basis"], basis)

    def test_a_three_status_mapping_is_admitted_as_before(self):
        self.admit(three_status(), Verifier({"*": "supported"}))
        e = self.entry()
        self.assertEqual(sorted(e), ["admitted", "certificate", "definition", "id", "included", "term", "unresolved"])
        self.assertEqual(e["unresolved"], sorted([GENERIC, OPEN]))


class Rendering(Base):
    """The planner, the verifier, the ontology contract and Stage B carry the same meaning."""
    PHRASE = "no membership evidence"

    def test_every_role_is_shown_the_same_meaning(self):
        captured = {}

        def planner(run, out_dir, label, prompt, check=None, **_k):
            captured["plan"] = prompt
            return None, ["stub"]
        validate_phase._session = planner
        aggregate.select_and_derive(self.run, TABLE, [DEF], ONTO, {(DEF["id"], "lorry")}, self.run.dir / "out")
        v = Verifier({"*": "supported"})
        self.admit(mapping(), v)
        plan, verify = captured["plan"], v.prompts[0]
        contract = ONTO.contract("ru.aggregate")
        stage_b = review.aggregates_block([self.entry()])
        law_local = (paths.PROMPTS / "plan.md").read_text()
        adjudicate = (paths.PROMPTS / "adjudicate.md").read_text()
        for name, text in (("plan_aggregates", plan), ("verify_aggregate", verify), ("ru.aggregate", contract), ("stage B", stage_b),
                           ("adjudicate", adjudicate)):
            self.assertIn("covered", text, name)
            self.assertIn(self.PHRASE, " ".join(text.split()), name)
        for name, text in (("plan_aggregates", plan), ("verify_aggregate", verify), ("plan.md", law_local)):
            self.assertIn("covered_by", text, name)
            self.assertIn("basis", text, name)
        self.assertIn(f"covered {GENERIC} by {SPECIFIC}", stage_b)
        self.assertIn('"covered_by"', verify)                                       # the proposal the verifier judges
        for name, text in (("plan_aggregates", plan), ("verify_aggregate", verify), ("ru.aggregate", contract)):
            self.assertRegex(" ".join(text.split()), r"leaves (it|the class) out", name)


LEAN_BUILT = (paths.LIBRARY / ".lake" / "build" / "lib" / "lean" / "TrafficSpec" / "Core" / "Runtime" / "Decode.olean").exists() and \
             (paths.LIBRARY / ".lake" / "build" / "lib" / "lean" / "TrafficSpec" / "Core" / "Language" / "Semantics.olean").exists()
PROBE = Path(__file__).with_name("aggregate_membership_probe.lean")


def lean_membership(entries: list[dict], cases: list[tuple[str, dict]]) -> list[str]:
    """Core's verdict letter per (aggregate id, road user), from the reading as the gate wrote it."""
    with tempfile.TemporaryDirectory() as d:
        r, c = Path(d) / "reading.json", Path(d) / "cases.json"
        r.write_text(json.dumps({"params": [], "aggregates": entries}))
        c.write_text(json.dumps([{"aggregate": a, "user": u} for a, u in cases]))
        out = subprocess.run(["lake", "env", "lean", "--run", str(PROBE), str(r), str(c)], cwd=paths.LIBRARY,
                             capture_output=True, text=True, timeout=600)
        if out.returncode != 0:
            raise AssertionError(out.stderr or out.stdout)
        return [l.split(" ", 1)[0] for l in out.stdout.splitlines()]


def user(classes=None, unobserved=()):
    u = {"track": 1, "unobserved_classes": [c[3:] for c in unobserved]}
    if classes is not None:
        u["classes"] = [c[3:] for c in classes]
    return u


#: The seven boundary cases, each with Core's verdict under the covered mapping, then one more: a
#: covered class unobserved is no evidence either way.
BOUNDARY = [
    ("ordinary car", user([GENERIC]), "F"),
    ("specific with generic", user([GENERIC, SPECIFIC]), "T"),
    ("specific unobserved", user([GENERIC], [SPECIFIC]), "U"),
    ("genuinely unresolved class present", user([GENERIC, OPEN]), "U"),
    ("genuinely unresolved class unobserved", user([GENERIC], [OPEN]), "U"),
    ("included with unresolved", user([GENERIC, SPECIFIC, OPEN]), "T"),
    ("all unobserved", user(None), "U"),
    ("covered class unobserved only", user(["ru.pedestrian"], [GENERIC]), "F"),
]


@unittest.skipUnless(LEAN_BUILT, "the library is not built (run `lake build` in library/)")
class CoreProjection(Base):
    """The gate's reading entry, decoded and evaluated by Core."""
    def test_the_boundary_cases_through_the_projection(self):
        self.admit(mapping(), Verifier({"*": "supported"}))
        covered = self.entry()
        old = {**self.entry(), "id": "old", "unresolved": sorted([GENERIC, OPEN])}
        old.pop("covered")
        got = lean_membership([covered, old], [(AID, u) for _n, u, _v in BOUNDARY] + [("old", u) for _n, u, _v in BOUNDARY])
        n = len(BOUNDARY)
        self.assertEqual(got[:n], [v for _n, _u, v in BOUNDARY], [b[0] for b in BOUNDARY])
        # the same mapping with the generic class unresolved: a road user that carries it, or may carry it, without the
        # specific class is unknown instead
        self.assertEqual(got[n:], ["U", "T", "U", "U", "U", "T", "U", "U"])

    def test_a_downgraded_cover_gives_unknown_again(self):
        self.admit(mapping(), Verifier({"*": "supported", SPECIFIC: "underdetermined"}))
        self.assertEqual(lean_membership([self.entry()], [(AID, user([GENERIC]))]), ["U"])


if __name__ == "__main__":
    unittest.main()
