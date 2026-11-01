"""Protocol tests of the replay of a saved upheld concept challenge, with the body's execution and the
recheck's answer stubbed: they show how the harness routes, identifies and records a challenge, never
what a model answers.
- R0: a challenge that cannot be run (formals, admission, history, units, grounding) is carried to the
  reviewer with its reason, never discharged, and no row is written.
- R1: a challenge decided under the current contract (the same digest) is satisfied where the body
  gives its claim, and goes to the adjudicator where it does not.
- R2: a challenge decided under another contract, or under none recorded, is rechecked and the answer
  is compared with the body. `undecided` becomes the effective claim: the challenge is carried, never
  compared or rechecked again under the same contract. The body within the answer is satisfied (the
  same id when the answer is the recorded claim, else a renewed case with `lineage`). The body outside
  it sends the renewed case to the concept adjudicator, whose ruling is recorded.
- The recheck prompt holds none of the body's verdict or value, its rendering, the narrowings, the
  recorded claim or words, the reviewer's situation, or any ruling.
- Rows are appended only: every earlier row is byte-identical after each step."""
import copy
import json
import re
import tempfile
import unittest
from pathlib import Path

from harness.model.blueprint import ConceptRecord
from harness.phases import review
from harness.phases import validate as validate_phase
from scripts.tests.test_review_routing import FakeRun, scripted_reviewer, submit

CID = "drv.motion.x"
V1 = "The first road user moves at the observation: its speed is above the floor named by the parameter."
V2 = "The first road user moves at the observation: its speed is strictly greater than the floor named by the parameter."
V3 = "The first road user moves at the observation: its speed, read in the world frame, is strictly greater than the floor."
Q1 = "The speed of the first road user at the observation, as its kinematics state it."
Q2 = "The speed of the first road user at the observation, read from its kinematics in the world frame."
WORDS1 = "its speed is above the floor"
WORDS2 = "its speed is strictly greater than the floor"


def formula(contract: str = V1, formals=(("u", "track"),), unit: str = "m/s", **raw) -> ConceptRecord:
    return ConceptRecord({"concept_id": CID, "kind": "formula", "contract": contract,
                          "args": [{"name": n, "sort": s} for n, s in formals],
                          "params": [{"name": "floor", "unit": unit, "meaning": "PARAM_MEANING the speed below which a road user counts as still"}],
                          "elements": [{"span": "its speed", "atoms": ["kin.speed"], "concepts": []}], **raw})


def quantity(contract: str = Q2) -> ConceptRecord:
    return ConceptRecord({"concept_id": CID, "kind": "quantity", "contract": contract, "args": [{"name": "u", "sort": "track"}],
                          "params": [], "elements": [{"span": "the speed", "atoms": ["kin.speed"], "concepts": []}]})


def challenge(contract: str | None = V1, **kw) -> dict:
    r = {"key": f"concept:{CID}", "schema": review.CONCEPT_CASE_SCHEMA, "ruling": "upheld", "obligation": "open", "subject": CID,
         "iteration": 1, "item": "ITEM_MARKER", "reason": "RULING_REASON_MARKER — \"ADJUDICATOR_QUOTE_MARKER\"",
         "kind": "fails_wrongly", "situation": "SITUATION_MARKER", "contract_words": WORDS1, "contract_verdict": "holds",
         "contract_value": None, "instance": {"literals": {}, "nats": {}, "params": {"floor": [0.5, "m/s"]}}, "grounding": {"u": 1},
         "trace": {"scenes": [{"t": 0, "users": [{"track": 1}]}]}, "at": 0, "verdict": "violated", "value": None, "body_digest": "b0"}
    if contract is not None:
        r["contract_digest"] = review._digest(review._ws(contract))
    r.update(kw)
    r.setdefault("case_id", review.concept_case_id(CID, r))
    return r


def speed_challenge(contract: str = Q1, lo=(10, "m/s"), hi=(20, "m/s")) -> dict:
    r = challenge(contract, kind="value_wrongly", contract_words="The speed of the first road user", contract_verdict=None,
                  contract_value={"lo": list(lo), "hi": list(hi)}, instance={"literals": {}, "nats": {}, "params": {}}, case_id=None)
    r.pop("contract_verdict")
    r["case_id"] = review.concept_case_id(CID, r)
    return r


class Body:
    """The body as executed: its verdict (`tag`) or its value (`value`, `num/den` in Core units), or a
    trace that no longer admits (`mode` lint) or whose history is incomplete (`mode` history)."""
    def __init__(self):
        self.tag, self.value, self.mode, self.calls = "compliant", None, None, 0

    def __call__(self, rec, answer, out_dir, result_dim=None, reading=None, saved=False, registry=None, runs=None):
        self.calls += 1
        runs = {} if runs is None else runs
        conf, unconf, errs, inc = [], [], [], []
        for k, d in enumerate(answer.get("divergences") or [], 1):
            if self.mode == "lint":
                runs[k] = {"tag": "violated", "reason": "admission"}
                inc.append(f"divergence {k}: trace check: a region no scene of the trace holds")
                continue
            if self.mode == "history":
                runs[k] = {"tag": "unknown", "reason": "history"}
                inc.append(f"divergence {k}: s — the body's verdict on the trace is unknown only because the trace is incomplete: extend it")
                continue
            q = rec.get("kind") == "quantity"
            tag = ("compliant" if review.body_within(rec, {"contract_value": d["contract_value"]}, {"value": self.value}) else "violated") if q else self.tag
            runs[k] = {"tag": tag, "why": "", "value": self.value, "facts": f"### The executed facts\n\n- FACTS_MARKER of divergence {k}\n", "reason": None}
            line = f"divergence {k} ({d.get('kind')}) at t={d.get('at')} ms: the body {tag}"
            if tag == ("compliant" if q else review.CONTRACT_VERDICTS[d["contract_verdict"]]):
                unconf.append(line + review.CONCEPT_AGREES)
            else:
                conf.append({"line": line, "div": d, "rule": tag, "key": d.get("kind"), "verdict": tag, "value": None, "facts": "F"})
        return conf, unconf, errs, inc


class Sessions:
    """The judges' sessions: the recheck's answer (`answer`) with every recheck prompt, and the concept
    adjudicator's ruling (`ruling`) on every item it lists, with every adjudication prompt."""
    def __init__(self):
        self.answer, self.prompts = {"verdict": "holds", "reason": "r", "quote": WORDS2}, []
        self.ruling, self.adjudications = "upheld", []

    def __call__(self, run, out_dir, label, prompt, check=None, **_kw):
        if label.startswith("adjudicate"):
            self.adjudications.append(prompt)
            items = re.findall(r"^(\d+)\. \(", prompt.split("### Items", 1)[1], re.M)
            quote = re.search(r"`drv\.motion\.x`: (.{20})", prompt).group(1)
            a = {"rulings": [{"item": int(k), "ruling": self.ruling, "reason": "stubbed ruling", "quote": quote} for k in items]}
        else:
            assert label.startswith("recheck"), label
            self.prompts.append(prompt)
            a = copy.deepcopy(self.answer)
        return a, (list(check(a)) if check else [])


class Base(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.run = FakeRun(Path(self.tmp.name))
        self.body, self.recheck, self.adjudicated, self.n = Body(), Sessions(), [], 0
        self.saved = (review.execute_concept_divergences, validate_phase._session, review.adjudicate_concept, review.concept_blocks,
                      review.session.run_tools)
        review.execute_concept_divergences = self.body
        validate_phase._session = self.recheck
        real = self.saved[2]
        review.adjudicate_concept = lambda *a, **k: (self.adjudicated.extend(a[3]), real(*a, **k))[1]
        review.concept_blocks = lambda _run, rec, _extras: ({**{x: "" for x in review.PLACEHOLDERS_REVIEW_CONCEPT},
                                                             "contract": review.contract_block(rec), "rendered": "RENDERING_MARKER"},
                                                            "RENDERING_MARKER", review._ws(rec.get("contract")))

    def tearDown(self):
        (review.execute_concept_divergences, validate_phase._session, review.adjudicate_concept, review.concept_blocks,
         review.session.run_tools) = self.saved
        self.tmp.cleanup()

    @property
    def file(self) -> Path:
        return self.run.dir / "rulings.jsonl"

    def seed(self, *rows) -> list[dict]:
        return [review.append_ruling(self.run, r) for r in rows]

    def bytes(self) -> bytes:
        return self.file.read_bytes() if self.file.exists() else b""

    def replay(self, rec, result_dim=None) -> review.ConceptReplay:
        before = self.bytes()
        self.n += 1
        rep = review.replay_concept(self.run, rec, self.run.dir / f"replay{self.n}", result_dim, "b1")
        self.assertTrue(self.bytes().startswith(before))           # append-only
        return rep

    def review(self, rec, divs=(), extras=None) -> review.ReviewOutcome:
        before = self.bytes()
        self.n += 1
        answer = {"verdict": "return" if divs else "accept", "divergences": list(divs), "not_general": [], "advisories": []}
        review.session.run_tools = scripted_reviewer([submit(answer)] * 3)
        out = review.review_concept(self.run, rec, extras or {"reads": [], "body_json": {}}, self.run.dir / f"review{self.n}")
        self.assertTrue(self.bytes().startswith(before))           # append-only
        return out

    def appended(self, before: bytes) -> list[dict]:
        after = self.bytes()
        self.assertTrue(after.startswith(before))
        return [json.loads(l) for l in after[len(before):].decode().splitlines()]

    def effective(self) -> list[dict]:
        return [r for r in review.effective_rows(review._all_rows(self.run)) if r.get("schema") == review.CONCEPT_CASE_SCHEMA]


class R0(Base):
    """A challenge that cannot be run is carried with its reason, under a changed contract too: no
    recheck, no row, never discharged; the review waits for an extension."""
    def carried(self, rec, row, reason):
        self.seed(row)
        before = self.bytes()
        rep = self.replay(rec)
        self.assertEqual([(c["case_id"], c["reason"]) for c in rep.carry], [(row["case_id"], reason)])
        self.assertEqual((rep.items, self.recheck.prompts, self.bytes()), ([], [], before))
        out = self.review(rec)
        self.assertEqual((out.status, out.defer_stage), ("deferred", "evidence"))
        self.assertEqual(self.bytes(), before)
        [eff] = self.effective()
        self.assertEqual((eff["case_id"], eff["obligation"]), (row["case_id"], "open"))

    def test_formals_that_do_not_correspond(self):
        self.carried(formula(V2, formals=(("w", "track"),)), challenge(), "formals")

    def test_a_trace_that_no_longer_admits(self):
        self.body.mode = "lint"
        self.carried(formula(V2), challenge(), "admission")

    def test_an_incomplete_recorded_history(self):
        self.body.mode = "history"
        self.carried(formula(V2), challenge(), "history")

    def test_incompatible_units(self):
        self.carried(formula(V2, unit="s"), challenge(), "units")

    def test_a_missing_grounding(self):
        self.carried(formula(V2), challenge(grounding={"u": None}), "grounding")

    def test_every_reason_is_named(self):
        self.assertEqual(set(review.R0_REASONS), {"formals", "admission", "history", "units", "grounding"})


class R1(Base):
    """The same contract: the recorded claim is compared with the body; no recheck."""
    def test_the_body_gives_the_claim(self):
        [old] = self.seed(challenge(V1))
        before = self.bytes()
        rep = self.replay(formula(V1))
        [row] = self.appended(before)
        self.assertEqual((row["case_id"], row["obligation"], row["supersedes"], row["contract_digest"]),
                         (old["case_id"], "satisfied", old["ruling_id"], old["contract_digest"]))
        self.assertEqual((rep.items, rep.carry, self.recheck.prompts), ([], [], []))
        self.assertNotIn("recheck", row)

    def test_the_body_differs_from_the_claim(self):
        self.body.tag = "violated"
        [old] = self.seed(challenge(V1))
        before = self.bytes()
        out = self.review(formula(V1))
        self.assertEqual(out.status, "returned")
        self.assertEqual([i.get("replay_of") for i in self.adjudicated], [old["case_id"]])
        [row] = self.appended(before)                                # the adjudicator's ruling, on the same case
        self.assertEqual((row["case_id"], row["ruling"], row["obligation"], self.recheck.prompts), (old["case_id"], "upheld", "open", []))


class R2(Base):
    """Another contract: the recheck's answer is compared with the body."""
    def test_the_answer_is_the_recorded_claim_and_the_body_gives_it(self):
        [old] = self.seed(challenge(V1))
        before = self.bytes()
        rep = self.replay(formula(V2))
        [row] = self.appended(before)
        self.assertEqual(len(self.recheck.prompts), 1)
        self.assertEqual((row["case_id"], row["obligation"], row["supersedes"]), (old["case_id"], "satisfied", old["ruling_id"]))
        self.assertEqual(row["contract_digest"], review.contract_digest(formula(V2)))
        self.assertEqual(row["recheck"], {"answer": {"verdict": "holds"}, "quote": WORDS2, "contract_digest": review.contract_digest(formula(V2))})
        self.assertEqual({x: row.get(x) for x in review.CONCEPT_CASE_FIELDS}, {x: old.get(x) for x in review.CONCEPT_CASE_FIELDS})
        self.assertEqual((rep.items, rep.carry), ([], []))

    def test_the_answer_differs_from_the_claim_and_the_body_gives_it(self):
        self.body.tag = "violated"
        self.recheck.answer = {"verdict": "fails", "reason": "r", "quote": WORDS2}
        [old] = self.seed(challenge(V1))
        before = self.bytes()
        out = self.review(formula(V2))
        self.assertEqual(out.status, "accepted")
        [row] = self.appended(before)
        content = {**{x: old.get(x) for x in review.CONCEPT_CASE_FIELDS}, "contract_verdict": "fails", "contract_words": WORDS2,
                   "kind": "holds_wrongly", "situation": f"renewed from {old['case_id']} under the current contract"}
        self.assertEqual({x: row.get(x) for x in review.CONCEPT_CASE_FIELDS}, content)
        self.assertEqual(row["case_id"], review.concept_case_id(CID, content))
        self.assertNotEqual(row["case_id"], old["case_id"])
        self.assertEqual((row["lineage"], row["supersedes"], row["obligation"]), (old["case_id"], old["ruling_id"], "satisfied"))
        self.assertEqual([r["case_id"] for r in self.effective()], [row["case_id"]])        # the old case is superseded, its row kept
        self.assertEqual(self.adjudicated, [])

    def renewed_to_the_adjudicator(self, ruling: str, answer: dict, tag: str):
        self.body.tag, self.recheck.ruling = tag, ruling
        self.recheck.answer = answer
        [old] = self.seed(challenge(V1))
        before = self.bytes()
        out = self.review(formula(V2))
        [item] = self.adjudicated                                    # a confirmed divergence, in the same review
        self.assertEqual((item["lineage_of"]["case_id"], item["div"]["contract_verdict"], item["div"]["contract_words"]),
                         (old["case_id"], answer["verdict"], answer["quote"]))
        self.assertEqual(len(self.recheck.adjudications), 1)
        self.assertIn("renewed from", self.recheck.adjudications[0])
        [row] = self.appended(before)                                # the adjudicator's ruling is R2's one row
        content = {x: item["div"].get(x) for x in review.CONCEPT_CASE_FIELDS}
        self.assertEqual((row["case_id"], row["lineage"], row["supersedes"], row["ruling"]),
                         (review.concept_case_id(CID, content), old["case_id"], old["ruling_id"], ruling))
        self.assertEqual((row["contract_digest"], row["recheck"]["answer"]), (review.contract_digest(formula(V2)), {"verdict": answer["verdict"]}))
        self.assertEqual(row["situation"], f"renewed from {old['case_id']} under the current contract")
        return out, row

    def test_the_answer_is_the_claim_the_body_differs_and_the_adjudicator_upholds(self):
        out, row = self.renewed_to_the_adjudicator("upheld", {"verdict": "holds", "reason": "r", "quote": WORDS2}, "violated")
        self.assertEqual((out.status, row["obligation"]), ("returned", "open"))

    def test_the_answer_is_the_claim_the_body_differs_and_the_adjudicator_dismisses(self):
        out, row = self.renewed_to_the_adjudicator("dismissed", {"verdict": "holds", "reason": "r", "quote": WORDS2}, "violated")
        self.assertEqual((out.status, row["obligation"]), ("accepted", None))
        self.assertEqual([r["ruling"] for r in self.effective()], ["dismissed"])     # recorded dismissed: no obligation is left

    def test_the_answer_differs_from_the_claim_and_from_the_body_upheld(self):
        out, row = self.renewed_to_the_adjudicator("upheld", {"verdict": "fails", "reason": "r", "quote": WORDS2}, "compliant")
        self.assertEqual((out.status, row["contract_verdict"], row["kind"]), ("returned", "fails", "holds_wrongly"))

    def test_the_answer_differs_from_the_claim_and_from_the_body_dismissed(self):
        out, row = self.renewed_to_the_adjudicator("dismissed", {"verdict": "fails", "reason": "r", "quote": WORDS2}, "compliant")
        self.assertEqual((out.status, row["ruling"]), ("accepted", "dismissed"))

    def test_undecided_keeps_it_open_and_carries_it(self):
        self.recheck.answer = {"verdict": "undecided", "reason": "r", "quote": WORDS2}
        [old] = self.seed(challenge(V1))
        before = self.bytes()
        out = self.review(formula(V2))
        self.assertEqual((out.status, out.defer_stage), ("deferred", "evidence"))
        self.assertIn(old["case_id"][:12], out.reasons[0])
        [row] = self.appended(before)
        self.assertEqual((row["case_id"], row["obligation"], row["recheck"]["answer"]), (old["case_id"], "open", {"verdict": "undecided"}))
        self.assertEqual(row["contract_digest"], review.contract_digest(formula(V2)))
        self.assertTrue(review.undecided_under(row, review.contract_digest(formula(V2))))

    def test_a_row_without_contract_digest(self):
        self.recheck.answer = {"verdict": "holds", "reason": "r", "quote": WORDS1}
        [old] = self.seed(challenge(None))
        self.assertNotIn("contract_digest", old)
        before = self.bytes()
        self.replay(formula(V1))                                   # the contract may even be unchanged: no digest is no evidence
        self.assertEqual(len(self.recheck.prompts), 1)
        [row] = self.appended(before)
        self.assertEqual((row["case_id"], row["obligation"], row["contract_digest"]),
                         (old["case_id"], "satisfied", review.contract_digest(formula(V1))))

    def test_an_invalid_answer_decides_nothing(self):
        self.recheck.answer = {"verdict": "holds", "reason": "r", "quote": "words the contract does not state"}
        self.seed(challenge(V1))
        before = self.bytes()
        out = self.review(formula(V2))
        self.assertEqual((out.status, out.defer_stage), ("deferred", "concept_adjudication"))
        self.assertEqual((len(self.recheck.prompts), self.bytes()), (1, before))


class Quantities(Base):
    """A quantity's answer is an interval: compared with the recorded one and with the body's value
    once both are in one unit, both ends included."""
    DIM = review._unit_dim("m/s")

    def run_with(self, value: str, answer: dict) -> tuple[dict, list, review.ConceptReplay]:
        self.tearDown(); self.setUp()
        self.body.value = value
        self.recheck.answer = {**answer, "reason": "r", "quote": "read from its kinematics"}
        [old] = self.seed(speed_challenge())
        before = self.bytes()
        rep = self.replay(quantity(), self.DIM)
        return old, self.appended(before), rep

    def check(self, value, answer, state, same_id: bool):
        old, rows, rep = self.run_with(value, answer)
        if state == "satisfied":
            [row] = rows
            self.assertEqual(row["obligation"], "satisfied", value)
            self.assertEqual(row["case_id"] == old["case_id"], same_id, value)
            self.assertEqual(row["contract_value"], old["contract_value"] if same_id else answer["interval"])
            self.assertEqual(rep.items, [])
        else:                                                         # outside: the renewed case goes to the adjudicator
            self.assertEqual(rows, [], value)
            [item] = rep.items
            self.assertEqual((item["lineage_of"]["case_id"], item["div"]["contract_value"]), (old["case_id"], answer["interval"]))

    def test_the_same_interval_in_another_unit_keeps_the_id(self):
        km = {"interval": {"lo": [36, "km/h"], "hi": [72, "km/h"]}}          # 10 to 20 m/s
        for value, state in (("10/1", "satisfied"), ("20/1", "satisfied"), ("15/1", "satisfied"),
                             ("99999/10000", "outside"), ("200001/10000", "outside")):
            self.check(value, km, state, True)

    def test_another_interval_is_a_new_case(self):
        km = {"interval": {"lo": [36, "km/h"], "hi": [54, "km/h"]}}          # 10 to 15 m/s
        for value, state in (("10/1", "satisfied"), ("15/1", "satisfied"), ("150001/10000", "outside"), ("99999/10000", "outside")):
            self.check(value, km, state, False)

    def test_an_interval_of_another_dimension_is_refused(self):
        self.recheck.answer = {"interval": {"lo": [1, "s"], "hi": [2, "s"]}, "reason": "r", "quote": "read from its kinematics"}
        self.seed(speed_challenge())
        with self.assertRaises(review.Deferred):
            self.replay(quantity(), self.DIM)

    def test_an_unknown_value_is_outside_every_interval(self):
        self.check("unknown:absent_atom:kin.speed", {"interval": {"lo": [36, "km/h"], "hi": [72, "km/h"]}}, "outside", True)


class Lifecycle(Base):
    """After a recheck the next replay is R1 (R0 for `undecided`); a recheck is paid again only when
    the contract changes."""
    def test_two_replays_after_a_recheck_take_r1(self):
        self.seed(challenge(V1))
        self.replay(formula(V2))
        after_r2 = self.bytes()
        for _ in range(2):
            rep = self.replay(formula(V2))
            self.assertEqual((len(self.recheck.prompts), self.bytes()), (1, after_r2))
            self.assertTrue(rep.notes)

    def test_a_restart_from_saved_state_takes_r1(self):
        self.seed(challenge(V1))
        self.replay(formula(V2))
        after_r2 = self.bytes()
        self.run = FakeRun(self.run.dir)                             # a new harness process on the same run directory
        rep = self.replay(formula(V2))
        self.assertEqual((len(self.recheck.prompts), self.bytes(), rep.carry, rep.items), (1, after_r2, [], []))

    def test_a_regressing_body_after_a_satisfied_recheck_is_a_confirmed_divergence(self):
        [old] = self.seed(challenge(V1))
        self.replay(formula(V2))
        self.body.tag = "violated"
        rep = self.replay(formula(V2))
        self.assertEqual(len(self.recheck.prompts), 1)
        self.assertEqual([i.get("replay_of") for i in rep.items], [old["case_id"]])
        self.assertEqual(self.review(formula(V2)).status, "returned")

    def test_a_renewed_case_is_replayed_against_its_new_claim(self):
        self.body.tag = "violated"
        self.recheck.answer = {"verdict": "fails", "reason": "r", "quote": WORDS2}
        self.seed(challenge(V1))
        self.replay(formula(V2))
        [new] = self.effective()
        self.body.tag = "compliant"                                  # a later body that holds where the contract now fails
        rep = self.replay(formula(V2))
        self.assertEqual((len(self.recheck.prompts), [i.get("replay_of") for i in rep.items]), (1, [new["case_id"]]))

    def test_a_contract_changed_again_is_rechecked_again(self):
        [old] = self.seed(challenge(V1))
        self.replay(formula(V2))
        self.recheck.answer = {"verdict": "holds", "reason": "r", "quote": "is strictly greater than the floor"}
        before = self.bytes()
        self.replay(formula(V3))
        self.assertEqual(len(self.recheck.prompts), 2)
        [row] = self.appended(before)
        self.assertEqual((row["case_id"], row["contract_digest"]), (old["case_id"], review.contract_digest(formula(V3))))
        self.replay(formula(V3))
        self.assertEqual(len(self.recheck.prompts), 2)

    def test_undecided_then_two_replays_are_carried_never_satisfied(self):
        self.recheck.answer = {"verdict": "undecided", "reason": "r", "quote": WORDS2}
        [old] = self.seed(challenge(V1))
        self.replay(formula(V2))
        after = self.bytes()
        for _ in range(2):                                           # the body gives the recorded claim: still never compared
            rep = self.replay(formula(V2))
            self.assertEqual([(c["case_id"], c["reason"]) for c in rep.carry], [(old["case_id"], "undecided")])
            self.assertIn(review.UNDECIDED, rep.carry[0]["why"])
            self.assertEqual((rep.items, rep.notes, len(self.recheck.prompts), self.bytes(), self.body.calls), ([], [], 1, after, 1))
        [eff] = self.effective()
        self.assertEqual(eff["obligation"], "open")
        out = self.review(formula(V2))
        self.assertEqual((out.status, out.defer_stage, len(self.recheck.prompts)), ("deferred", "evidence", 1))

    def test_undecided_then_an_extension_with_a_new_claim(self):
        self.recheck.answer = {"verdict": "undecided", "reason": "r", "quote": WORDS2}
        [old] = self.seed(challenge(V1))
        self.replay(formula(V2))
        [carried] = self.effective()
        self.body.tag = "violated"                                   # the body fails, as the extension's claim says the contract does
        ext = {**{x: old[x] for x in review.CONCEPT_CASE_FIELDS if x in old}, "kind": "holds_wrongly", "contract_verdict": "fails",
               "contract_words": WORDS2, "extends": old["case_id"]}
        before = self.bytes()
        out = self.review(formula(V2), [ext])
        self.assertEqual((out.status, len(self.recheck.prompts)), ("accepted", 1))
        [row] = self.appended(before)
        self.assertEqual((row["lineage"], row["supersedes"], row["obligation"], row["contract_verdict"], row["contract_digest"]),
                         (old["case_id"], carried["ruling_id"], "satisfied", "fails", review.contract_digest(formula(V2))))
        self.assertNotEqual(row["case_id"], old["case_id"])
        self.assertNotIn("recheck", row)
        rep = self.replay(formula(V2))                               # the new claim is decided: R1, no recheck
        self.assertEqual((rep.carry, len(self.recheck.prompts)), ([], 1))
        self.assertTrue(rep.notes)

    def test_a_new_claim_is_refused_unless_the_claim_is_undecided(self):
        old = challenge(V2, contract_words=WORDS2)
        ext = {**{x: old[x] for x in review.CONCEPT_CASE_FIELDS if x in old}, "contract_verdict": "fails"}
        self.assertTrue(review.concept_extension_defects(old, ext, formula(V2)))
        undecided = {**old, "recheck": {"answer": {"verdict": "undecided"}, "quote": WORDS2, "contract_digest": old["contract_digest"]}}
        self.assertEqual(review.concept_extension_defects(undecided, ext, formula(V2)), [])

    def test_undecided_then_the_contract_changes_again(self):
        self.recheck.answer = {"verdict": "undecided", "reason": "r", "quote": WORDS2}
        [old] = self.seed(challenge(V1))
        self.replay(formula(V2))
        self.recheck.answer = {"verdict": "holds", "reason": "r", "quote": "is strictly greater than the floor"}
        before = self.bytes()
        rep = self.replay(formula(V3))
        self.assertEqual((len(self.recheck.prompts), rep.carry), (2, []))
        [row] = self.appended(before)
        self.assertEqual((row["case_id"], row["obligation"], row["recheck"]["answer"]), (old["case_id"], "satisfied", {"verdict": "holds"}))

    def test_append_only_over_a_sequence(self):
        self.seed(challenge(V1))
        steps = [(V2, "compliant", {"verdict": "fails", "reason": "r", "quote": WORDS2}, "returned"),   # renewed, adjudicated, upheld
                 (V2, "violated", None, "accepted"),                                                   # R1, met
                 (V3, "violated", {"verdict": "fails", "reason": "r", "quote": "is strictly greater than the floor"}, "accepted"),
                 (V3, "compliant", None, "returned")]                                                  # R1, a confirmed divergence
        for contract, tag, answer, status in steps:
            before = self.bytes()
            self.body.tag = tag
            if answer:
                self.recheck.answer = answer
            self.assertEqual(self.review(formula(contract)).status, status)
            self.assertEqual(self.bytes()[:len(before)], before)
        rows = [json.loads(l) for l in self.bytes().decode().splitlines()]
        self.assertEqual(len({r["ruling_id"] for r in rows}), len(rows))
        self.assertEqual(len(self.recheck.prompts), 2)


class PromptIsolation(Base):
    """The rendered recheck prompt states the current contract with the posted text of the definition
    it quotes, the names' contracts, the parameters and the facts, and none of the fields it must
    never see."""
    def test_the_rendered_prompt_holds_none_of_the_excluded_fields(self):
        review.append_ruling(self.run, {**challenge(V1), "case_id": "earlier", "ruling": "dismissed", "obligation": None,
                                        "reason": "PRECEDENT_MARKER", "item": "PRECEDENT_ITEM_MARKER"})
        self.seed(challenge(V1, contract_words="RECORDED_WORDS_MARKER", verdict="BODY_VERDICT_MARKER"))
        rec = formula(V2, residues=["NARROWING_MARKER"], narrowings=["NARROWING_MARKER"])
        self.body.tag = "violated"
        self.review(rec, extras={"reads": [], "body_json": {"atom": "BODY_JSON_MARKER"}, "narrowings_added": [{"why": "NARROWING_MARKER"}]})
        [prompt] = self.recheck.prompts
        excluded = {"the body's verdict": ["violated", "compliant", "BODY_VERDICT_MARKER"], "the body": ["BODY_JSON_MARKER"],
                    "the body's rendering": ["RENDERING_MARKER"], "the record's narrowings": ["NARROWING_MARKER"],
                    "the recorded claim": ["contract_verdict", "fails_wrongly"], "the recorded contract words": ["RECORDED_WORDS_MARKER"],
                    "the adjudicator's quote": ["ADJUDICATOR_QUOTE_MARKER"], "the reviewer's situation": ["SITUATION_MARKER", "situation above"],
                    "earlier rulings": ["RULING_REASON_MARKER", "ITEM_MARKER", "PRECEDENT_MARKER", "Earlier rulings"]}
        for field, markers in excluded.items():
            for m in markers:
                self.assertNotIn(m, prompt, field)
        for shown in (V2, "PARAM_MEANING", "0.5 m/s", "FACTS_MARKER", "`kin.speed`", "magnitude of velocity", "formula"):
            self.assertIn(shown, prompt)

    def test_a_quantity_prompt_holds_neither_the_recorded_interval_nor_the_value(self):
        self.body.value = "123457/1000"
        self.recheck.answer = {"interval": {"lo": [1, "m/s"], "hi": [2, "m/s"]}, "reason": "r", "quote": "read from its kinematics"}
        self.seed(speed_challenge(lo=(7.77, "m/s"), hi=(8.88, "m/s")))
        self.replay(quantity(), review._unit_dim("m/s"))
        [prompt] = self.recheck.prompts
        for m in ("7.77", "8.88", "123.457", "123457", "contract_value", "value_wrongly"):
            self.assertNotIn(m, prompt)
        self.assertIn("quantity", prompt)

    def test_the_real_facts_carry_no_situation_note(self):
        facts = review.executed_facts(challenge(V1))
        self.assertIn("situation above", facts)
        self.assertNotIn("situation above", review.recheck_blocks(self.run, formula(V2), {}, facts, None)["facts"])

    def test_the_quoted_definition_is_shown_with_its_posted_text(self):
        (self.run.dir / "definitions.jsonl").write_text(json.dumps({"id": "DEF-X-1", "title": "t", "text": "POSTED_DEFINITION_TEXT",
                                                                     "source": "s"}) + "\n")
        block = review.recheck_blocks(self.run, formula(V2, definition="DEF-X-1"), {}, "facts", None)["contract"]
        self.assertIn("`DEF-X-1` — POSTED_DEFINITION_TEXT", block)
        self.assertNotIn("POSTED_DEFINITION_TEXT", review.contract_block(formula(V2, definition="DEF-X-1")))   # the adjudicator's is unchanged


class Extensions(Base):
    """An extension (R0 only) keeps the recorded contract words while they are verbatim in the contract;
    where they are not, it quotes the contract's words and records a case of new content under a new id."""
    def test_new_words_only_where_the_recorded_ones_are_gone(self):
        old = challenge(V1)
        d = {**{x: old[x] for x in review.CONCEPT_CASE_FIELDS if x in old}, "contract_words": WORDS2}
        self.assertEqual(review.concept_extension_defects(old, d, formula(V2)), [])
        self.assertTrue(review.concept_extension_defects(old, {**d, "contract_words": "The first road user moves"}, formula(V1)))

    def test_an_extension_with_new_words_is_a_new_case_with_lineage(self):
        [old] = self.seed(challenge(V1))
        rec = formula(V2, formals=(("u", "track"), ("w", "track")))
        ext = {**{x: old[x] for x in review.CONCEPT_CASE_FIELDS if x in old}, "contract_words": WORDS2, "grounding": {"u": 1, "w": 2},
               "extends": old["case_id"]}
        before = self.bytes()
        out = self.review(rec, [ext])
        self.assertEqual((out.status, self.recheck.prompts), ("accepted", []))
        [row] = self.appended(before)
        self.assertEqual((row["lineage"], row["supersedes"], row["obligation"], row["contract_words"]),
                         (old["case_id"], old["ruling_id"], "satisfied", WORDS2))
        self.assertEqual(row["case_id"], review.concept_case_id(CID, row))
        self.assertNotEqual(row["case_id"], old["case_id"])
        self.assertEqual(row["contract_digest"], review.contract_digest(rec))       # evaluated under the current contract

    def test_a_met_extension_with_the_same_words_records_the_current_digest(self):
        [old] = self.seed(challenge(V1, contract_words="The first road user moves at the observation"))
        rec = formula(V2, formals=(("u", "track"), ("w", "track")))
        ext = {**{x: old[x] for x in review.CONCEPT_CASE_FIELDS if x in old}, "grounding": {"u": 1, "w": 2}, "extends": old["case_id"]}
        before = self.bytes()
        self.assertEqual(self.review(rec, [ext]).status, "accepted")
        [row] = self.appended(before)
        self.assertEqual((row["case_id"], row["contract_digest"]), (old["case_id"], review.contract_digest(rec)))
        self.replay(rec)                                            # the next replay is R1: no recheck
        self.assertEqual(self.recheck.prompts, [])


class SmokeChallenge(Base):
    """smoke24's challenge c0fb080f on concept drv.road.two_directional: upheld at iteration 1, then
    deferred at stage `evidence` three times, because the repaired contract no longer states its
    words. On the iteration-4 record it runs, so it takes R2; the body's verdict stubbed here is the
    one the harness's own execution of the iteration-4 body gives on its trace (it holds)."""
    FIXTURE = Path(__file__).with_name("concept_recheck_two_directional.json")
    CASE = "c0fb080fdbf0031b3fcf527030cb23e7db3eaeb0717f6a4d634137f1c240cbfe"
    QUOTE = ("two of the travel regions lying on it - a lane or a roadway, the regions a vehicle proceeds in - carry designated "
             "directions that are opposed")

    def setUp(self):
        super().setUp()
        fx = json.loads(self.FIXTURE.read_text())
        self.file.write_text("".join(l + "\n" for l in fx["rows"]), encoding="utf-8")
        self.rec = ConceptRecord(fx["concept"])
        self.old = next(json.loads(l) for l in fx["rows"] if json.loads(l)["case_id"] == self.CASE)
        self.recheck.answer = {"verdict": "holds", "reason": "stubbed", "quote": self.QUOTE}

    def test_the_cause(self):
        self.assertFalse(review._in(self.old["contract_words"], review._ws(self.rec.get("contract"))))
        self.assertNotEqual(self.old["contract_digest"], review.contract_digest(self.rec))

    def test_it_is_rechecked_and_satisfied_under_its_own_id(self):
        before = self.bytes()
        rep = self.replay(self.rec)
        self.assertEqual((len(self.recheck.prompts), rep.carry, rep.items), (1, [], []))
        [row] = self.appended(before)
        self.assertEqual((row["case_id"], row["supersedes"], row["obligation"], row["contract_digest"]),
                         (self.CASE, self.old["ruling_id"], "satisfied", review.contract_digest(self.rec)))
        self.assertEqual(row["recheck"]["answer"], {"verdict": "holds"})
        self.assertNotIn(self.old["situation"], self.recheck.prompts[0])
        self.assertNotIn(self.old["contract_words"], self.recheck.prompts[0])
        after = self.bytes()
        self.replay(self.rec)
        self.assertEqual((len(self.recheck.prompts), self.bytes()), (1, after))

    def test_the_review_is_no_longer_deferred_at_evidence(self):
        self.assertEqual(self.review(self.rec).status, "accepted")


if __name__ == "__main__":
    unittest.main()


class RecheckAnswers(Base):
    """The run's recheck answers: a valid answer is kept under the digest of the full prompt, the
    model and the effort, and the same recheck asked again in a later iteration or after a restart
    takes it without a session, writing no ruling for it; any input the prompt shows, the prompt
    file, the model or the effort changed is a new key, and a kept answer the current check refuses
    is asked again."""
    def defer_adjudication(self):
        calls = []

        def deferred(*a, **k):
            calls.append(a[3])
            raise review.Deferred("concept_adjudication", "stubbed: the adjudication left the item without a valid ruling")
        review.adjudicate_concept = deferred
        return calls

    def test_a_deferred_adjudication_then_a_restart_or_the_next_iteration_pays_no_recheck(self):
        self.recheck.answer = {"verdict": "fails", "reason": "r", "quote": WORDS2}   # the body (compliant) departs: renewed, adjudicated
        self.seed(challenge(V1))
        adjudications = self.defer_adjudication()
        before = self.bytes()
        out = self.review(formula(V2))
        self.assertEqual((out.status, out.defer_stage, len(self.recheck.prompts), len(adjudications)), ("deferred", "concept_adjudication", 1, 1))
        self.assertEqual(self.bytes(), before)                                     # no row: neither a ruling nor one for the answer kept
        kept = [json.loads(l) for l in review.recheck_cache_file(self.run).read_text().splitlines()]
        self.assertEqual([k["answer"]["verdict"] for k in kept], ["fails"])
        self.run = FakeRun(self.run.dir)                                            # a restart: a new harness process on the run
        out = self.review(formula(V2))
        self.assertEqual((out.status, len(self.recheck.prompts), len(adjudications)), ("deferred", 1, 2))
        self.run.iteration = 2                                                      # the next iteration, a new review directory
        out = self.review(formula(V2))
        self.assertEqual((out.status, len(self.recheck.prompts), len(adjudications)), ("deferred", 1, 3))
        self.assertEqual(self.bytes(), before)
        self.assertEqual(len(review.recheck_cache_file(self.run).read_text().splitlines()), 1)
        self.assertEqual([i["recheck"]["answer"]["verdict"] for i in adjudications[-1]], ["fails"])   # the kept answer reached the adjudicator

    def ask(self, rec=None, instance=None, facts=None):
        rec = rec or formula(V2, definition="DEF-X-1")
        instance = {"literals": {}, "nats": {}, "params": {"floor": [0.5, "m/s"]}} if instance is None else instance
        facts = review.executed_facts(challenge(V1)) if facts is None else facts
        self.n += 1
        before = len(self.recheck.prompts)
        review.recheck_concept(self.run, rec, instance, facts, self.run.dir / f"ask{self.n}", None)
        return len(self.recheck.prompts) - before

    def test_any_input_of_the_prompt_changed_is_asked_again(self):
        import dataclasses, shutil
        from harness.store import paths
        definitions = self.run.dir / "definitions.jsonl"
        definitions.write_text(json.dumps({"id": "DEF-X-1", "title": "t", "text": "POSTED_TEXT_ONE", "source": "s"}) + "\n")
        self.assertEqual(self.ask(), 1)
        self.assertEqual(self.ask(), 0)                                              # unchanged: the kept answer
        record = lambda **kw: ConceptRecord({**formula(V2, definition="DEF-X-1").raw, **kw})
        floor = lambda meaning: [{"name": "floor", "unit": "m/s", "meaning": meaning}]
        changes = {
            "the definition's posted text": lambda: definitions.write_text(json.dumps({"id": "DEF-X-1", "title": "t", "text": "POSTED_TEXT_TWO",
                                                                                     "source": "s"}) + "\n"),
            "a parameter's value": dict(instance={"literals": {}, "nats": {}, "params": {"floor": [0.6, "m/s"]}}),
            "a parameter's meaning": dict(rec=record(params=floor("PARAM_MEANING the speed below which a road user stands"))),
            "the instance": dict(facts=review.executed_facts(challenge(V1, instance={"literals": {}, "nats": {}, "params": {"floor": [0.7, "m/s"]}}))),
            "the trace": dict(facts=review.executed_facts(challenge(V1, trace={"scenes": [{"t": 0, "users": [{"track": 1, "speed": 3}]}]}))),
            "the instant": dict(facts=review.executed_facts(challenge(V1, trace={"scenes": [{"t": 0, "users": [{"track": 1}]},
                                                                                         {"t": 500, "users": [{"track": 1}]}]}, at=500))),
            "a concept's contract the words use": "concept",
            "an atom's contract": "atom",
            "the prompt file": "prompt",
            "the model": lambda: setattr(self.run, "opts", dataclasses.replace(self.run.opts, model="m2")),
            "the effort": lambda: setattr(self.run, "opts", dataclasses.replace(self.run.opts, judge_effort="high")),
        }
        for what, change in changes.items():
            with self.subTest(what):
                saved_opts, saved_prompts = self.run.opts, paths.PROMPTS
                kw = {}
                if callable(change):
                    change()
                elif isinstance(change, dict):
                    kw = change
                elif change == "concept":
                    rec = record(elements=[{"span": "its speed", "atoms": ["kin.speed"], "concepts": ["drv.motion.y"]}])
                    for contract in ("CONCEPT_CONTRACT_ONE", "CONCEPT_CONTRACT_TWO"):
                        self.run.all_concepts = lambda c=contract: {"drv.motion.y": {"contract": c}}
                        self.assertEqual(self.ask(rec=rec), 1, contract)
                    self.run.all_concepts = lambda: {}
                    continue
                elif change == "atom":
                    onto = self.run.dir / "ATOMS_changed.md"
                    text = Path(self.run.opts.ontology).read_text(encoding="utf-8")
                    row = next(l for l in text.splitlines() if l.startswith("| `kin.speed` |"))
                    onto.write_text(text.replace(row, row.replace("| `kin.speed` | ", "| `kin.speed` | CHANGED_CONTRACT ", 1)), encoding="utf-8")
                    self.run.opts = dataclasses.replace(self.run.opts, ontology=onto)
                elif change == "prompt":
                    copy_dir = self.run.dir / "prompts"
                    shutil.copytree(paths.PROMPTS, copy_dir, dirs_exist_ok=True)
                    (copy_dir / "recheck_concept.md").write_text((copy_dir / "recheck_concept.md").read_text() + "\nA CHANGED SENTENCE.\n")
                    paths.PROMPTS = copy_dir
                try:
                    self.assertEqual(self.ask(**kw), 1, what)                         # a new key: asked
                    self.assertEqual(self.ask(**kw), 0, what)                         # and kept under it
                finally:
                    self.run.opts, paths.PROMPTS = saved_opts, saved_prompts
                    definitions.write_text(json.dumps({"id": "DEF-X-1", "title": "t", "text": "POSTED_TEXT_ONE", "source": "s"}) + "\n")
                self.assertEqual(self.ask(), 0, what)                                 # the unchanged inputs still take the first answer
        self.assertFalse(self.file.exists())                                          # no ruling is ever written for a kept answer

    def test_a_kept_answer_the_current_check_refuses_is_asked_again(self):
        self.assertEqual(self.ask(), 1)
        f = review.recheck_cache_file(self.run)
        row = json.loads(f.read_text())
        f.write_text(json.dumps({**row, "answer": {"verdict": "holds", "reason": "r", "quote": "WORDS NOT IN THE CONTRACT"}}) + "\n")
        self.assertEqual(self.ask(), 1)
        self.assertEqual(self.ask(), 0)


class UndecidedBy(Base):
    """An `undecided` recheck may say why: the facts it turns on are missing, or the contract does not
    decide. Both are carried to the reviewer alike; the reason is recorded on the row and counted apart."""
    def test_each_reason_is_recorded_carried_and_counted_apart(self):
        for by in ("facts", "contract", None):
            with self.subTest(by=by):
                self.tearDown(); self.setUp()
                self.recheck.answer = {"verdict": "undecided", "reason": "r", "quote": WORDS2, **({"undecided_by": by} if by else {})}
                [old] = self.seed(challenge(V1))
                rep = self.replay(formula(V2))
                expected = by or "unstated"
                self.assertEqual([(c["reason"], c["undecided_by"]) for c in rep.carry], [("undecided", expected)])
                self.assertEqual(rep.undecided(), {"facts": 0, "contract": 0, "unstated": 0, expected: 1})
                [eff] = self.effective()
                self.assertEqual(eff["recheck"]["answer"].get("undecided_by"), by)
                rep = self.replay(formula(V2))                                          # R0 from the recorded answer: the same reason
                self.assertEqual([c["undecided_by"] for c in rep.carry], [expected])
                if by:
                    self.assertIn(review.UNDECIDED_BY[by], rep.carry[0]["why"])
                out = self.review(formula(V2))
                self.assertEqual((out.status, out.defer_stage), ("deferred", "evidence"))
                outcome = json.loads((self.run.dir / f"review{self.n}" / "review_outcome.json").read_text())
                self.assertEqual(outcome["undecided"][expected], 1)

    def test_the_reason_is_given_only_with_undecided(self):
        rec = formula(V2)
        self.assertEqual(review.recheck_defects({"verdict": "undecided", "undecided_by": "facts", "reason": "r", "quote": WORDS2}, rec, None), [])
        self.assertTrue(review.recheck_defects({"verdict": "holds", "undecided_by": "facts", "reason": "r", "quote": WORDS2}, rec, None))
        self.assertTrue(review.recheck_defects({"verdict": "undecided", "undecided_by": "both", "reason": "r", "quote": WORDS2}, rec, None))
