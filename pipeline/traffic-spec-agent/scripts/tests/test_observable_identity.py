"""Development regression tests for observable readings carried by road-user identity classes: the
validator returns a reading of a purpose, a perception, an intention or a status whose span only
identity classes (`ru.`, aggregates included) carry, with the ontology's own words for what the
category is read through; an agency reading so carried passes (the subject's class names the vehicle
whose controlled motion the ontology reads "the driver" through) and is listed; a reading carried by
conduct, a feature or a concept passes; a reading carried by identity classes and other
ids passes and is listed for the operator, as is a record that names a duty, a role or a status
with identity classes only and declares no reading, and every reading on a trigger, subject,
condition or exception span is listed under its role. The list is a run record like `TO_USER.md`.
Every check is static; no model is called."""
import copy
import json
import re
import tempfile
import unittest
from pathlib import Path
from types import SimpleNamespace
from unittest import mock

from harness.agents import session
from harness.checks import gate, validate_a
from harness.model.blueprint import Node
from harness.phases import feedback, observable_view
from harness.store import paths
from harness.store.ledger import Ledger
from harness.tools import handoff

#: The record smoke31 planned for the exception "(d) In the performance of official duties;": a
#: purpose read through the vehicle's official or emergency class, its subject "the driver" an agency
#: reading carried by the motor-vehicle aggregate alone.
FIXTURE = Path(__file__).parent / "fixtures" / "observable_identity_270_3_o2.json"


def fixture() -> dict:
    return json.loads(FIXTURE.read_text(encoding="utf-8"))


def node(carriers: dict[str, list[str]], readings: dict[str, str], *, ops: dict[str, list[str]] | None = None,
         words: dict[str, str] | None = None, gaps: list[dict] | None = None) -> Node:
    """A record whose span s1 is the subject, s2 the duty and s3 an exception; `carriers` maps a span
    to its element's ids (concepts under `derived`), `readings` a span to its observable reading's
    category, `ops` a span to an operationalization's concepts."""
    text = {"s1": "The driver of a vehicle", "s2": "shall not stop", "s3": "except when on duty", **(words or {})}
    roles = {"s1": "subject", "s2": "obligation", "s3": "exception"}
    return Node({"node_id": "L_9_o1", "law_refs": ["L-9"],
                 "segmentation": [{"id": s, "role": roles[s], "text": text[s]} for s in ("s1", "s2", "s3")],
                 "elements": [{"span": s, "atoms": [i for i in ids if not i.startswith("drv.")],
                               "derived": [i for i in ids if i.startswith("drv.")]} for s, ids in carriers.items()],
                 "operationalizations": [{"span": s, "concepts": cs, "params": ["p.x"]} for s, cs in (ops or {}).items()],
                 "narrowings": [{"span": s, "kind": "observable_reading", "category": c, "why": "w"} for s, c in readings.items()],
                 "gaps": gaps or []})


def identity_errors(n: Node) -> list[str]:
    return [e for e in validate_a.check_narrowings(n, None, "") if "identity classes" in e]


class IdentityOnlyIsReturned(unittest.TestCase):

    def test_the_smoke31_exception_is_returned_with_the_ontology_words(self):
        errs = identity_errors(Node(fixture()))
        s14 = [e for e in errs if "span s14 (purpose)" in e]
        self.assertEqual(len(s14), 1, errs)
        self.assertIn("ru.official_vehicle, ru.emergency_vehicle", s14[0])
        self.assertIn("a purpose by the conduct it explains", s14[0])

    def test_an_agency_reading_carried_by_an_aggregate_alone_passes_and_is_listed(self):
        errs = identity_errors(Node(fixture()))
        self.assertEqual([e for e in errs if "span s8" in e], [], errs)
        synthetic = node({"s1": ["ru.aggregate=DEF-X::vehicle"], "s2": ["kin.speed"]}, {"s1": "agency"})
        self.assertEqual(identity_errors(synthetic), [])
        listed = observable_view.entries({"L_9_o1": ("x", synthetic.raw)})["a"]
        self.assertEqual([(e["span"], e["words"], e["category"], e["carriers"], e["refused"]) for e in listed],
                         [("s1", "The driver of a vehicle", "agency", ["ru.aggregate=DEF-X::vehicle"], False)])

    def test_every_category_but_agency_is_returned(self):
        self.assertEqual(set(validate_a.OBSERVABLE_THROUGH), validate_a.OBSERVABLE_CATEGORIES - {"agency"})
        for cat in sorted(validate_a.OBSERVABLE_THROUGH):
            n = node({"s2": ["kin.speed"], "s3": ["ru.official_vehicle"]}, {"s3": cat})
            errs = identity_errors(n)
            self.assertEqual(len(errs), 1, cat)
            self.assertIn(validate_a.OBSERVABLE_THROUGH[cat].split(" [...] ")[-1], errs[0], cat)

    def test_the_quoted_words_are_the_ontology_own(self):
        text = re.sub(r"\s+", " ", (paths.REPO / "ontology" / "ATOMS.md").read_text(encoding="utf-8"))
        for cat, quote in validate_a.OBSERVABLE_THROUGH.items():
            for part in quote.split(" [...] "):
                self.assertIn(part, text, cat)


class ConductOrFeaturePasses(unittest.TestCase):

    def test_a_status_read_through_a_device_or_a_marking(self):
        for ids in (["dev.human_direction", "dev.governs"], ["st.stop_line"], ["dev.stop_sign"]):
            self.assertEqual(identity_errors(node({"s2": ["kin.speed"], "s3": ids}, {"s3": "status"})), [], ids)

    def test_an_agency_reading_through_motion_or_a_concept(self):
        self.assertEqual(identity_errors(node({"s1": ["kin.speed"], "s2": ["kin.speed"]}, {"s1": "agency"})), [])
        self.assertEqual(identity_errors(node({"s1": ["drv.motion.moving"], "s2": ["kin.speed"]}, {"s1": "agency"})), [])

    def test_a_concept_of_an_operationalization_carries_too(self):
        self.assertEqual(identity_errors(node({"s2": ["kin.speed"]}, {"s3": "purpose"},
                                              ops={"s3": ["drv.motion.halted"]})), [])

    def test_a_mixed_carrier_passes(self):
        self.assertEqual(identity_errors(node({"s1": ["ru.aggregate=DEF-X::vehicle", "kin.speed"], "s2": ["kin.speed"]},
                                              {"s1": "agency"})), [])


class OperatorControl(unittest.TestCase):
    """The operator's control: the class stays and only the duty changes, or the duty is performed in
    another class. No trace tells a duty performed from one not performed, so a reading of a purpose
    or a status that rests on the class alone decides both cases alike and is returned in every variant; what passes is a
    reading through conduct or a feature, or the nearest atoms with a gap (no reading), which the
    operator's list shows."""

    def exception(self, ids: list[str], reading: str | None, gaps=None) -> Node:
        return node({"s1": ["ru.aggregate=DEF-X::vehicle", "kin.speed"], "s2": ["kin.speed"], "s3": ids},
                    {"s3": reading} if reading else {}, words={"s3": "except in the performance of official duties"}, gaps=gaps)

    def test_a_class_never_reads_a_duty(self):
        for cls in (["ru.official_vehicle"], ["ru.emergency_vehicle"], ["ru.official_vehicle", "ru.emergency_vehicle"],
                    ["ru.aggregate=DEF-X::authorized_emergency_vehicle"], ["ru.motor_vehicle"]):
            for cat in ("purpose", "status"):
                self.assertEqual(len(identity_errors(self.exception(cls, cat))), 1, (cls, cat))

    def test_what_remains_is_conduct_or_a_gap(self):
        conduct = self.exception(["ru.emergency_vehicle", "sig.warning_lamp", "sig.siren"], "purpose")
        self.assertEqual(identity_errors(conduct), [])
        self.assertEqual([e["span"] for e in observable_view.entries({"L_9_o1": ("x", conduct.raw)})["b"]], ["s3"])
        gap = self.exception(["ru.official_vehicle"], None,
                             gaps=[{"span": "s3", "kind": "atom", "proposal": "p", "nearest": ["ru.official_vehicle"]}])
        self.assertEqual(validate_a.check_narrowings(gap, None, ""), [])
        self.assertEqual(validate_a.check_accounting(gap), [])
        self.assertEqual([e["span"] for e in observable_view.entries({"L_9_o1": ("x", gap.raw)})["c"]], ["s3"])


class Report(unittest.TestCase):

    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.dir = Path(self.tmp.name) / "results" / "r"
        (self.dir / "iter-001" / "plan").mkdir(parents=True)

    def tearDown(self):
        self.tmp.cleanup()

    def write(self, *recs: dict, where: str = "iter-001/plan/blueprint.jsonl") -> None:
        f = self.dir / where
        f.parent.mkdir(parents=True, exist_ok=True)
        f.write_text("".join(json.dumps(r) + "\n" for r in recs), encoding="utf-8")

    def view(self, accepted=None) -> str:
        run = SimpleNamespace(dir=self.dir, iteration=1, accepted_nodes=accepted or {})
        observable_view.write_current_view(run)
        return (self.dir / observable_view.VIEW_NAME).read_text(encoding="utf-8")

    @staticmethod
    def part(text: str, p: str) -> str:
        return text.split(f"## ({p})", 1)[1].split("\n## ", 1)[0]

    def test_the_three_parts(self):
        mixed = node({"s1": ["ru.aggregate=DEF-X::vehicle", "kin.speed"], "s2": ["kin.speed"]}, {"s1": "agency"}).raw
        mixed["node_id"] = "L_9_o2"
        silent = node({"s2": ["kin.speed"], "s3": ["ru.official_vehicle"]}, {}, words={"s3": "In the performance of Official Duties;"}).raw
        silent["node_id"] = "L_9_o3"
        self.write(fixture(), mixed, silent)
        text = self.view()
        a, b, c = (self.part(text, p) for p in "abc")
        self.assertIn("`NRS_484B_270_3_o2` span s14 \"(d) In the performance of official duties;\" · `purpose` · carried by "
                      "`ru.official_vehicle`, `ru.emergency_vehicle`", a)
        self.assertIn("the validator returns this record", a)
        s8 = next(l for l in a.splitlines() if "`NRS_484B_270_3_o2` span s8 " in l)
        self.assertIn("`agency`", s8)
        self.assertNotIn("validator returns", s8)                              # an agency reading is listed, never returned
        self.assertIn("`NRS_484B_270_3_o2` span s13", a)                       # every reading, refused or not
        self.assertIn("`L_9_o2` span s1", b)
        self.assertIn("`NRS_484B_270_3_o2` span s13", b)                       # the traffic aggregate beside the conflict it reads
        self.assertNotIn("span s14", b)
        self.assertIn("`L_9_o3` span s3 \"In the performance of Official Duties;\" · matches \"official duties\", "
                      "\"performance of official\"", c)
        self.assertNotIn("NRS_484B_270_3_o2", c)                               # it declares readings: parts (a) and (b) show it

    def test_the_latest_record_of_a_node_and_the_accepted_ones(self):
        old = fixture()
        new = copy.deepcopy(old)
        new["narrowings"] = [n for n in new["narrowings"] if n["span"] != "s14"]
        self.write(old)
        self.write(new, where="iter-002/repair/NRS_484B_270_3_o2/record.jsonl")
        (self.dir / "iter-002" / "plan").mkdir(parents=True)
        text = self.view({"L_8_o1": node({"s1": ["kin.speed"], "s2": ["kin.speed"]}, {"s1": "agency"}).raw | {"node_id": "L_8_o1"}})
        self.assertNotIn("span s14", self.part(text, "a"))
        self.assertIn("from `iter-002/repair/NRS_484B_270_3_o2/record.jsonl`", text)
        self.assertIn("`L_8_o1` span s1", text)
        self.assertIn("from `accepted_nodes.jsonl`", text)

    def test_a_record_that_cannot_be_read_stops_nothing(self):
        f = self.dir / "iter-001" / "plan" / "blueprint.jsonl"
        f.write_text("not json\n" + json.dumps({"node_id": "L_9_o1", "segmentation": "bad"}) + "\n", encoding="utf-8")
        self.assertIn("## (a)", self.view())

    def test_the_wordings_are_one_constant(self):
        self.assertEqual(len(set(observable_view.DUTY_WORDINGS)), len(observable_view.DUTY_WORDINGS))
        self.assertEqual(observable_view.duty_words("ON DUTY"), ["on duty"])


class ReportIsARunRecord(unittest.TestCase):

    def test_feedback_writes_it(self):
        with tempfile.TemporaryDirectory() as t:
            d = Path(t) / "r"
            (d / "iter-001" / "plan").mkdir(parents=True)
            (d / "iter-001" / "plan" / "blueprint.jsonl").write_text(json.dumps(fixture()) + "\n", encoding="utf-8")
            run = SimpleNamespace(dir=d, iteration=1, accepted_nodes={}, accepted_concepts={}, auto_notes=d / "AUTO_NOTES.md",
                                  opts=SimpleNamespace(run_id="r"), all_nodes=lambda: {}, all_concepts=lambda: {})
            with mock.patch.object(paths, "GAPS_DIR", Path(t) / "gaps"):
                feedback.write_feedback(run, Ledger(d / "ledger.jsonl", [], 3), [], [], [])
            self.assertIn("span s14", (d / observable_view.VIEW_NAME).read_text(encoding="utf-8"))

    def test_no_session_may_write_it(self):
        for kind in ("plan", "code"):
            rules = session.deny_rules(kind, "r")
            for tool in session.WRITE_TOOLS:
                self.assertIn(f"{tool}(//{str(paths.REPO).lstrip('/')}/results/*/{observable_view.VIEW_NAME})", rules)

    def test_a_rewrite_is_no_scope_change(self):
        with tempfile.TemporaryDirectory() as t:
            root = Path(t)
            rd = root / "results" / "r"
            rd.mkdir(parents=True)
            (rd / observable_view.VIEW_NAME).write_text("before\n")
            baseline = gate.repo_digest(root)
            (rd / observable_view.VIEW_NAME).write_text("rewritten by the harness mid-run\n")
            self.assertEqual(gate.repo_digest(root), baseline)

    def test_it_is_in_the_handoff(self):
        with tempfile.TemporaryDirectory() as t:
            repo = Path(t) / "repo"
            rd = repo / "results" / "h"
            rd.mkdir(parents=True)
            (rd / "options.json").write_text(json.dumps({"run_id": "h"}))
            (rd / observable_view.VIEW_NAME).write_text("y\n")
            none = repo / "absent"
            with mock.patch.multiple(paths, REPO=repo, RESULTS=repo / "results", RULES_DIR=none, CONCEPTS_DIR=none, WITNESS_DIR=none,
                                     GAPS_DIR=none, INDEX_FILE=none / "i", WITNESS_ROOT_FILE=none / "w"):
                self.assertIn(f"results/h/{observable_view.VIEW_NAME}", handoff.artifact_files("h"))


class ScopeRolePart(unittest.TestCase):
    """Part (d) lists every observable reading on a span that decides when the rule applies, by its
    role, and judges none: a mixed-carrier reading is listed like any other, and writing the report
    changes no record and no validator outcome."""

    ROLES = {"s1": "trigger", "s2": "subject", "s3": "condition", "s4": "exception", "s5": "obligation"}
    WORDS = {"s1": "when about to turn", "s2": "The driver of a vehicle", "s3": "in a caravan or motorcade",
             "s4": "except  when on\nduty", "s5": "shall allow sufficient space"}

    def record(self) -> dict:
        carriers = {"s1": ["kin.speed"], "s2": ["ru.aggregate=DEF-X::vehicle"], "s3": ["drv.interaction.column_following", "ru.motor_vehicle"],
                    "s4": ["dev.human_direction"], "s5": ["kin.speed"]}
        cats = {"s1": "intention", "s2": "agency", "s3": "purpose", "s4": "status", "s5": "purpose"}
        return {"node_id": "L_9_o1", "law_refs": ["L-9"],
                "segmentation": [{"id": s, "role": r, "text": self.WORDS[s]} for s, r in self.ROLES.items()],
                "elements": [{"span": s, "atoms": [i for i in ids if not i.startswith("drv.")],
                              "derived": [i for i in ids if i.startswith("drv.")]} for s, ids in carriers.items()],
                "narrowings": [{"span": s, "kind": "observable_reading", "category": c, "why": f"read  through {s}"} for s, c in cats.items()]
                              + [{"span": "s5", "kind": "reading", "why": "a plain reading"}]}

    def test_every_scope_role_is_a_group_and_each_reading_sits_under_its_role(self):
        d = observable_view.entries({"L_9_o1": ("iter-001/plan/blueprint.jsonl", self.record())})["d"]
        self.assertEqual(set(d), validate_a.SCOPE_ROLES)
        self.assertEqual({r: [e["span"] for e in es] for r, es in d.items()},
                         {"trigger": ["s1"], "subject": ["s2"], "condition": ["s3"], "exception": ["s4"]})

    def test_every_field_is_present(self):
        rec = self.record()
        d = observable_view.entries({"L_9_o1": ("iter-002/repair/L_9_o1/record.jsonl", rec)})["d"]
        e = d["exception"][0]
        self.assertEqual({k: e[k] for k in ("node", "span", "role", "words", "category", "carriers", "why", "source", "source_kind")},
                         {"node": "L_9_o1", "span": "s4", "role": "exception", "words": "except  when on\nduty", "category": "status",
                          "carriers": ["dev.human_direction"], "why": "read through s4", "source": "iter-002/repair/L_9_o1/record.jsonl",
                          "source_kind": "repair"})
        self.assertEqual(observable_view.source_kind("accepted_nodes.jsonl"), "accepted")
        self.assertEqual(observable_view.source_kind("iter-001/plan/blueprint.jsonl"), "plan")
        line = observable_view._scope_line(e)
        for part in ("`L_9_o1`", "span s4", "(exception)", "\"except when on duty\"", "`status`", "`dev.human_direction`",
                     "why: \"read through s4\"", "from `iter-002/repair/L_9_o1/record.jsonl` (repair)"):
            self.assertIn(part, line)

    def test_a_reading_on_the_duty_is_not_in_the_part(self):
        d = observable_view.entries({"L_9_o1": ("x", self.record())})["d"]
        self.assertNotIn("s5", [e["span"] for es in d.values() for e in es])
        self.assertIn("s5", [e["span"] for e in observable_view.entries({"L_9_o1": ("x", self.record())})["a"]])

    def test_a_mixed_carrier_reading_is_listed_and_not_refused(self):
        rec = self.record()
        self.assertEqual(validate_a.check_narrowings(Node(rec), None, ""), [])
        cond = observable_view.entries({"L_9_o1": ("x", rec)})["d"]["condition"]
        self.assertEqual([(e["span"], e["carriers"]) for e in cond], [("s3", ["ru.motor_vehicle", "drv.interaction.column_following"])])
        line = observable_view._scope_line(cond[0])
        self.assertNotIn("validator returns", line)
        self.assertNotIn("identity classes only", line)

    def test_the_rendered_part_has_one_heading_per_role(self):
        with tempfile.TemporaryDirectory() as tmp:
            rd = Path(tmp) / "r"
            (rd / "iter-001" / "plan").mkdir(parents=True)
            (rd / "iter-001" / "plan" / "blueprint.jsonl").write_text(json.dumps(self.record()) + "\n", encoding="utf-8")
            observable_view.write_current_view(SimpleNamespace(dir=rd, iteration=1, accepted_nodes={}))
            text = (rd / observable_view.VIEW_NAME).read_text(encoding="utf-8")
        part = text.split("## (d)", 1)[1]
        for role in validate_a.SCOPE_ROLES:
            self.assertIn(f"\n### {role}\n", part)
        self.assertIn("`L_9_o1` span s3 (condition) \"in a caravan or motorcade\" · `purpose`", part.split("### condition", 1)[1])

    def test_an_empty_role_says_none(self):
        text = observable_view.render(observable_view.entries({}), 1)
        self.assertEqual(text.split("## (d)", 1)[1].count("(none)"), len(validate_a.SCOPE_ROLES))

    def test_writing_the_report_changes_no_record_and_no_validator_outcome(self):
        recs = [self.record(), fixture()]
        def outcome() -> list[list[str]]:
            return [validate_a.check_narrowings(Node(r), None, "") + validate_a.check_residue_scope(Node(r)) for r in recs]
        before, snapshot = outcome(), copy.deepcopy(recs)
        with tempfile.TemporaryDirectory() as tmp:
            rd = Path(tmp) / "r"
            f = rd / "iter-001" / "plan" / "blueprint.jsonl"
            f.parent.mkdir(parents=True)
            f.write_text("".join(json.dumps(r) + "\n" for r in recs), encoding="utf-8")
            raw = f.read_bytes()
            accepted = {"L_8_o1": self.record() | {"node_id": "L_8_o1"}}
            acc_snapshot = copy.deepcopy(accepted)
            observable_view.entries({r["node_id"]: ("x", r) for r in recs})
            observable_view.write_current_view(SimpleNamespace(dir=rd, iteration=1, accepted_nodes=accepted))
            self.assertEqual(f.read_bytes(), raw)
            self.assertEqual(sorted(p.name for p in rd.iterdir()), sorted(["iter-001", observable_view.VIEW_NAME]))
        self.assertEqual(recs, snapshot)
        self.assertEqual(accepted, acc_snapshot)
        self.assertEqual(outcome(), before)


if __name__ == "__main__":
    unittest.main()
