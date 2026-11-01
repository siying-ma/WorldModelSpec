"""What a concept's judges are told a called primitive denotes, and how a call is named; sessions stubbed.
- The concept reviewer and the concept adjudicator are shown the ontology's contract row of every
  primitive the body calls, read from the body itself: a Boolean call, a quantity call, a call nested
  inside other operators, and the body of a saved accepted record that a dependency report reaches.
- The independent recheck is built from the contract and the record alone: a change of the body only
  leaves its prompt byte-identical.
- A primitive call is rendered "the primitive", a concept call "the concept", in a node's rendering
  and in a case's; stage A is shown the case's own names and nothing of the rule, the record or the body.
- A case's identity and a body's canonical form do not depend on the rendering."""
import json
import re
import tempfile
import unittest
from pathlib import Path

from harness.agents import render
from harness.lean import render_formula
from harness.model import corpus
from harness.model.blueprint import ConceptRecord
from harness.phases import review
from harness.phases import validate as validate_phase
from scripts.tests.test_review_routing import A_VIOLATED, ONTO, FakeRun, Scripted, cert, ctx, div, node, scripted_reviewer, submit

CID = "drv.motion.zz_close_pass"
CONTRACT = "the first road user passes close to the second one while turning, within the horizon the caller sets"
WORDS = "passes close to the second one"
TRACKS = [{"var": "s"}, {"var": "o"}]
BOOLEAN = {"derived": "prim_closest_approach_within", "args": TRACKS, "params": [{"param": "h"}]}
QUANTITY = {"cmp": "lt", "lhs": {"quantity": "prim_closest_approach_distance", "args": TRACKS, "params": [{"param": "h"}]},
            "rhs": {"lit": {"num": 2, "den": 1}, "unit": "m"}}
NESTED = {"and": ["tt", {"holds_for": "time", "length": {"param": "h"}, "subject": "s",
                         "body": {"not": {"cmp": "gt", "lhs": {"abs": {"quantity": "prim_heading_change", "args": [{"var": "s"}],
                                                                       "params": [{"param": "h"}]}},
                                          "rhs": {"lit": {"num": 30, "den": 1}, "unit": "degree"}}}}]}
BODIES = {"boolean": (BOOLEAN, "prim.closest_approach_within"), "quantity": (QUANTITY, "prim.closest_approach_distance"),
          "nested": (NESTED, "prim.heading_change")}


def record(**raw) -> dict:
    return {"concept_id": CID, "kind": "formula", "contract": CONTRACT,
            "args": [{"name": "s", "sort": "track"}, {"name": "o", "sort": "track"}],
            "params": [{"name": "h", "unit": "s", "meaning": "the horizon"}],
            "elements": [{"span": WORDS, "atoms": ["kin.speed"], "concepts": []}], **raw}


def divergence() -> dict:
    return {"kind": "holds_wrongly", "contract_verdict": "fails", "contract_words": WORDS, "situation": "s",
            "instance": {"literals": {}, "nats": {}, "params": {"h": [3, "s"]}}, "grounding": {"s": 1, "o": 2},
            "trace": {"scenes": [{"t": 0}]}, "at": 0}


def contract_row(pid: str) -> str:
    """The primitive's row as the contracts table renders it from the ontology."""
    row = validate_phase.contracts_table({pid: ONTO.contract(pid)}).splitlines()[2]
    assert ONTO.contract(pid) and row.startswith(f"| `{pid}` |"), pid
    return row


class Judges:
    """The concept adjudicator's session (`validate._session`), every prompt kept, each item dismissed
    with a quote of the contract; the body's execution confirms every divergence submitted."""
    def __init__(self):
        self.prompts: list[str] = []

    def session(self, run, out_dir, label, prompt, check=None, **_kw):
        self.prompts.append(prompt)
        items = re.findall(r"^(\d+)\. \(", prompt.split("### Items", 1)[1], re.M)
        a = {"rulings": [{"item": int(k), "ruling": "dismissed", "reason": "stubbed", "quote": WORDS} for k in items]}
        return a, (list(check(a)) if check else [])

    @staticmethod
    def execute(rec, answer, out_dir, result_dim=None, reading=None, saved=False, registry=None, runs=None):
        conf = [{"line": f"divergence {k} ({d.get('kind')}) at t=0 ms: the body violated", "div": d, "rule": "violated",
                 "key": d.get("kind"), "verdict": "violated", "value": None, "facts": "F"}
                for k, d in enumerate(answer.get("divergences") or [], 1)]
        return conf, [], [], []


class Stubbed(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.run = FakeRun(Path(self.tmp.name))
        self.judges = Judges()
        self.saved = (validate_phase._session, review.execute_concept_divergences, review.session.run_tools)
        validate_phase._session = self.judges.session
        review.execute_concept_divergences = self.judges.execute

    def tearDown(self):
        validate_phase._session, review.execute_concept_divergences, review.session.run_tools = self.saved
        self.tmp.cleanup()


class ReviewAndAdjudication(Stubbed):
    """The first review of a concept: its reviewer's prompt and its adjudicator's prompt."""
    def review(self, body) -> tuple[str, str]:
        review.session.run_tools = scripted_reviewer([submit({"verdict": "return", "divergences": [divergence()],
                                                              "not_general": [], "advisories": []})] * 3)
        out_dir = self.run.dir / "review"
        review.review_concept(self.run, ConceptRecord(record()), {"reads": ["kin.speed"], "body_json": body}, out_dir)
        [adjudication] = self.judges.prompts
        return (out_dir / "review_concept_prompt.md").read_text(encoding="utf-8"), adjudication

    def test_each_called_primitive_s_contract_reaches_both(self):
        for how, (body, pid) in BODIES.items():
            with self.subTest(call=how):
                self.judges.prompts.clear()
                prompt, adjudication = self.review(body)
                for shown in (prompt, adjudication):
                    self.assertIn(contract_row(pid), shown)
                    self.assertIn(f"the primitive `{pid.replace('.', '_')}`", shown)
                    self.assertIn(f"[{ONTO.contract(pid)}]", shown)          # glossed inline where it is called
                    self.assertNotIn("the concept `prim_", shown)

    def test_a_primitive_the_body_does_not_call_is_not_shown(self):
        prompt, adjudication = self.review(BOOLEAN)
        for shown in (prompt, adjudication):
            self.assertNotIn("`prim.heading_change`", shown)
            self.assertNotIn("`prim.closest_approach_distance`", shown)


class DependencyAdjudication(Stubbed):
    """A coder's dependency report on a saved accepted record: the adjudication reads the primitives
    from the record's saved body."""
    def test_the_saved_body_s_primitives_reach_the_adjudicator(self):
        saved = record(reads=["kin.speed"], refs=[], body_json={"and": [BOOLEAN, NESTED]}, canonical_body="c")
        self.run.all_concepts = lambda: {CID: saved}
        task = self.run.dir / "task"
        task.mkdir()
        (task / "dependency_defect.json").write_text(json.dumps({"concept_id": CID, **divergence()}))
        rep = review.dependency_report(self.run, task, {CID})
        self.assertEqual(rep.status, "dismissed")
        [adjudication] = self.judges.prompts
        for pid in ("prim.closest_approach_within", "prim.heading_change"):
            self.assertIn(contract_row(pid), adjudication)
            self.assertIn(f"the primitive `{pid.replace('.', '_')}`", adjudication)
        self.assertNotIn("`prim.closest_approach_distance`", adjudication)


class RecheckStaysIndependent(unittest.TestCase):
    """The recheck's names come from the contract and the record: a claimed primitive is shown, a
    primitive only the body calls is not, and a change of the body alone changes no byte of it."""
    def prompt(self, run, body) -> str:
        rec = ConceptRecord(record(elements=[{"span": WORDS, "atoms": ["prim.closest_approach_within"], "concepts": []}],
                                   body_json=body, canonical_body=json.dumps(body)))
        return render.render("recheck_concept.md", review.recheck_blocks(run, rec, divergence()["instance"], "### The executed facts\n\n- f\n", None))

    def test_a_body_change_leaves_the_prompt_byte_identical(self):
        with tempfile.TemporaryDirectory() as t:
            run = FakeRun(Path(t))
            one, two = self.prompt(run, BOOLEAN), self.prompt(run, {"and": [QUANTITY, NESTED]})
            self.assertEqual(one.encode(), two.encode())
            self.assertIn(contract_row("prim.closest_approach_within"), one)      # claimed by the record
            self.assertNotIn("`prim.heading_change`", one)                         # called by the body only
            self.assertNotIn("`prim.closest_approach_distance`", one)


class Labels(unittest.TestCase):
    """A primitive call is "the primitive", a concept call "the concept", glossed inline when the
    glosses carry it."""
    GLOSSES = {"prim.closest_approach_within": "PRIM_GLOSS", "prim.closest_approach_distance": "QTY_GLOSS", "drv.motion.zz_still": "DRV_GLOSS"}
    CALLS = {"and": [BOOLEAN, {"and": [QUANTITY, {"derived": "drv_motion_zz_still", "args": [{"var": "s"}], "params": []}]}]}

    def check(self, text: str):
        self.assertIn("the primitive `prim_closest_approach_within` holds of `s`, `o` with `h`", text)
        self.assertIn("[PRIM_GLOSS]", text)
        self.assertIn("the primitive `prim_closest_approach_distance` of `s`, `o`", text)
        self.assertIn("[QTY_GLOSS]", text)
        self.assertIn("the concept `drv_motion_zz_still` holds of `s` [DRV_GLOSS]", text)
        self.assertNotIn("the concept `prim_", text)

    def test_in_a_node_s_rendering(self):
        self.check(render_formula.render_rule({"binders": [{"name": "s", "cls": "tt"}], "applicability": "tt", "obligation": self.CALLS},
                                              self.GLOSSES))

    def test_in_a_case_s_rendering(self):
        self.check(review.render_case(self.CALLS, {}, 0, {"s": 1, "o": 2}, self.GLOSSES, [0]))


class StageASeesTheCaseOnly(unittest.TestCase):
    """The stage A prompt of a case that names a primitive: the primitive under its label, glossed,
    with its contract row; nothing of the rule, the record, the rule's contracts or a concept body."""
    def test_the_judge_case_prompt(self):
        with tempfile.TemporaryDirectory() as t:
            run = FakeRun(Path(t))
            run.all_concepts = lambda: {"drv.motion.zz_body": record(body_json={"atom": "BODY_JSON_MARKER"})}
            stub, prompts = Scripted({"a": {**A_VIOLATED, "verdict": "undetermined"}}), []

            def session(run, out_dir, label, prompt, **kw):
                prompts.append(prompt)
                return stub(run, out_dir, label, prompt, **kw)
            saved = validate_phase._session
            validate_phase._session = session
            case = {"and": [{"cmp": "lt", "lhs": {"quantity": "prim_region_offset_along", "args": [{"var": "v"}, {"var": "r1"}, {"var": "r2"}],
                                                  "params": []}, "rhs": {"lit": {"num": 0, "den": 1}, "unit": "m"}},
                            {"derived": "prim_closest_approach_within", "args": [{"var": "v"}, {"var": "w"}],
                             "params": [{"lit": {"num": 3, "den": 1}, "unit": "s"}]}]}
            # `case_atoms` as the certificate writes it: `Formula.atoms` of the case, a primitive call's name among them
            c = {**cert(), "canonical_case": case, "case_atoms": ["prim_region_offset_along", "prim_closest_approach_within"]}
            context = ctx()
            context.record = {"node_id": "L_1_o1", "obligation": "RECORD_MARKER"}
            context.rendering = "RULE_RENDERING_MARKER"
            context.rule_glosses = {"kin.speed": "RULE_GLOSS_MARKER"}
            try:
                review.judge_divergence(run, node(), context, ONTO, div(case=case, grounding={"v": 1, "w": 2},
                                                                        entities={"r1": {"kind": "lane", "id": 7}, "r2": {"kind": "lane", "id": 8}}),
                                        c, Path(t), "d1")
            finally:
                validate_phase._session = saved
            [prompt] = prompts
            for pid in ("prim.region_offset_along", "prim.closest_approach_within"):
                self.assertIn(f"the primitive `{pid.replace('.', '_')}`", prompt)
                self.assertIn(f"[{ONTO.contract(pid)}]", prompt)
                self.assertIn(contract_row(pid), prompt)
            for leak in ("RECORD_MARKER", "RULE_RENDERING_MARKER", "RULE_GLOSS_MARKER", "BODY_JSON_MARKER", "### Record", "### Rendering",
                         "`kin.speed`", CONTRACT, "the concept `"):
                self.assertNotIn(leak, prompt)
            rows = re.findall(r"^\| `([^`]+)` \|", prompt.split("### The case", 1)[1], re.M)
            self.assertEqual(sorted(rows), ["prim.closest_approach_within", "prim.region_offset_along"])


class IdentityIgnoresTheRendering(unittest.TestCase):
    """A case's id and a body's canonical form, pinned to the values computed before primitives were
    labelled apart: neither reads the rendering."""
    CASE = {"and": [{"cmp": "lt", "lhs": {"quantity": "prim_region_offset_along", "args": [{"var": "user1"}, {"var": "r1"}, {"var": "r2"}],
                                          "params": []}, "rhs": {"lit": {"num": 0, "den": 1}, "unit": "m"}},
                    {"derived": "prim_closest_approach_within", "args": [{"var": "user1"}, {"var": "user2"}],
                     "params": [{"lit": {"num": 3, "den": 1}, "unit": "s"}]}]}
    BODY = {"and": [{"derived": "prim_closest_approach_within", "args": [{"var": "s"}, {"var": "o"}], "params": [{"param": "h"}]},
                    {"cmp": "lt", "lhs": {"quantity": "prim_heading_change", "args": [{"var": "s"}], "params": [{"param": "w"}]},
                     "rhs": {"lit": {"num": 0, "den": 1}, "unit": "deg"}}]}

    def test_case_id_and_canonical_body(self):
        law = corpus.Law("ZZ-1-1", "An invented duty", "A road user halts.", "invented")
        canon = {"case": self.CASE, "entities": {"r1": {"kind": "lane", "id": 7}, "r2": {"kind": "lane", "id": 8}},
                 "grounding": {"user1": 1, "user2": 2}}
        d = {"trace": {"scenes": [{"t": 0}]}, "at": 0}
        self.assertIn("the primitive `prim_region_offset_along`", review.render_case(self.CASE, canon["entities"], 0, canon["grounding"], {}))
        self.assertEqual(review.case_id(law, d, canon), "ea8eb8c74840054f80f620c03d677ff51d0f4d1218cd72e8f41e097eed3e7e9e")
        self.assertEqual(render_formula.canonical(self.BODY, ["s", "o"], ["h", "w"]),
                         '{"and":[{"args":[{"var":"$a0"},{"var":"$a1"}],"derived":"prim_closest_approach_within","params":[{"param":"$p0"}]},'
                         '{"cmp":"lt","lhs":{"args":[{"var":"$a0"}],"params":[{"param":"$p1"}],"quantity":"prim_heading_change"},'
                         '"rhs":{"lit":{"den":1,"num":0},"unit":"deg"}}]}')
        self.assertEqual(review.concept_case_id("drv.x.y", {"kind": "too_wide", "trace": d["trace"], "at": 0, "instance": {"params": {}},
                                                            "grounding": {"s": 1}}),
                         "0fd3912735c1d02cf4bb8af6703cdd72fd10bb9bf517b00e9ef1b7dd15eab0c2")


if __name__ == "__main__":
    unittest.main()
