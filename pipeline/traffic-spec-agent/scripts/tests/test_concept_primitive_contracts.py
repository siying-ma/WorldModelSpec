"""What a concept's judges are told a called primitive denotes, and how a call is named; sessions stubbed.
- The concept reviewer and the concept adjudicator are shown the ontology's contract row of every
  primitive the body calls, read from the body itself: a Boolean call, a quantity call, a call nested
  inside other operators, and the body of a saved accepted record that a dependency report reaches.
- The independent recheck is built from the contract and the record alone: a change of the body only
  leaves its prompt byte-identical.
- A primitive call is rendered "the primitive", a concept call "the concept".
- A concept challenge's identity and a body's canonical form do not depend on the rendering."""
import json
import re
import tempfile
import unittest
from pathlib import Path

from harness.agents import render
from harness.lean import render_formula
from harness.model.blueprint import ConceptRecord
from harness.phases import review
from harness.phases import validate as validate_phase
from scripts.tests.test_review_routing import ONTO, FakeRun, scripted_reviewer, submit

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

    def test_in_a_concept_s_rendering(self):
        self.check(render_formula.render_concept({"args": [{"name": "s", "sort": {"sort": "track"}}, {"name": "o", "sort": {"sort": "track"}}],
                                                  "params": [{"name": "h", "unit": "s"}], "kind": "formula", "body": self.CALLS},
                                                 self.GLOSSES))


class IdentityIgnoresTheRendering(unittest.TestCase):
    """A concept challenge's id and a body's canonical form, pinned to the values computed before
    primitives were labelled apart: neither reads the rendering."""
    BODY = {"and": [{"derived": "prim_closest_approach_within", "args": [{"var": "s"}, {"var": "o"}], "params": [{"param": "h"}]},
                    {"cmp": "lt", "lhs": {"quantity": "prim_heading_change", "args": [{"var": "s"}], "params": [{"param": "w"}]},
                     "rhs": {"lit": {"num": 0, "den": 1}, "unit": "deg"}}]}

    def test_concept_case_id_and_canonical_body(self):
        d = {"trace": {"scenes": [{"t": 0}]}, "at": 0}
        self.assertEqual(render_formula.canonical(self.BODY, ["s", "o"], ["h", "w"]),
                         '{"and":[{"args":[{"var":"$a0"},{"var":"$a1"}],"derived":"prim_closest_approach_within","params":[{"param":"$p0"}]},'
                         '{"cmp":"lt","lhs":{"args":[{"var":"$a0"}],"params":[{"param":"$p1"}],"quantity":"prim_heading_change"},'
                         '"rhs":{"lit":{"den":1,"num":0},"unit":"deg"}}]}')
        self.assertEqual(review.concept_case_id("drv.x.y", {"kind": "too_wide", "trace": d["trace"], "at": 0, "instance": {"params": {}},
                                                            "grounding": {"s": 1}}),
                         "0fd3912735c1d02cf4bb8af6703cdd72fd10bb9bf517b00e9ef1b7dd15eab0c2")


if __name__ == "__main__":
    unittest.main()
