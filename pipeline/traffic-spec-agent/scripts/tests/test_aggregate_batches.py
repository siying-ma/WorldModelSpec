"""Development regression tests for the batched aggregate selection: fixed membership by definition, one
session per batch, answers kept on their full prompt, a batch that never rewrites another's rows, failures
counted once for the pair alone, and resumes interrupted at each step, counted in session launches; and the
deadline of a working session — `session.run` scripted."""
import json
import re
import tempfile
import unittest
from pathlib import Path
from unittest import mock

from harness.agents import session
from harness.checks import aggregates as checks
from harness.model import ontology
from harness.phases import aggregate
from harness.phases import validate as validate_phase
from harness.store import jsonl, paths
from harness.store.state import Options

ONTO = ontology.load(paths.REPO / "ontology" / "ATOMS_train.md")
CLASSES = checks.road_user_classes(ONTO)
WORDS = "every device upon which a person may be carried"
TERMS = {"DEF-TST-1": ["agg a", "plain b"], "DEF-TST-2": ["agg c"], "DEF-TST-3": ["plain d"],
         "DEF-TST-4": ["agg e", "plain f", "plain g"]}
DEFS = [{"id": d, "title": "", "source": "", "text": " ".join(f"“{t}” means {WORDS}." for t in ts)} for d, ts in TERMS.items()]
TABLE = {"laws": {f"TST-{d[-1]}{i}": [{"term": t, "status": "resolved", "definition": d, "step": "general_chapter",
                                        "chain": [d], "candidates": [d]}]
                  for d, ts in TERMS.items() for i, t in enumerate(ts)}}
USES = re.compile(r'^- `([^`]+)` / "([^"]+)": used by', re.M)


class Crash(Exception):
    """The process killed at a chosen point."""


class FakeRun:
    def __init__(self, d: Path, failures: dict | None = None):
        self.dir, self.iteration = d, 1
        self.aggregate_failures = dict(failures or {})
        self.opts = Options(run_id="t", laws=d / "laws.jsonl", ontology=ONTO.path, reading=d / "reading.json",
                            model="m", reviewer_model="gpt-x", session_timeout=1234.0)
        if not (d / "reading.json").exists():
            (d / "reading.json").write_text(json.dumps({"params": [], "aggregates": []}))

    @property
    def reading_file(self):
        return self.dir / "reading.json"

    @property
    def iter(self):
        return self.dir / f"iter-{self.iteration:03d}"

    def all_nodes(self):
        return {}

    def all_concepts(self):
        return {}


def row(d, t, **kw):
    rep = "aggregate" if t.startswith("agg") else "not_aggregate"
    r = {"definition": d, "term": t, "representation": rep, "target": checks.aggregate_id(d, t) if rep == "aggregate" else None,
         "quote": WORDS, "reason": "the words decide it"}
    r.update(kw)
    return r


def record(d, t):
    return {"aggregate_id": checks.aggregate_id(d, t), "term": t, "definition": d,
            "classifications": [{"class": c, "status": "included", "quotes": [{"definition": d, "words": WORDS}]} for c in CLASSES]}


class Sessions:
    """`session.run` scripted: a planner prompt is answered for the pairs it lists (with `bad` pairs
    answered defectively, `alter`ed rows changed and `extra` rows added), a verifier prompt with `supported` for every class;
    `crash(kind, n)` raises before the n-th launch of that kind."""
    def __init__(self, bad=(), extra=(), crash=None, alter=None):
        self.bad, self.extra, self.crash, self.alter = set(bad), list(extra), crash, dict(alter or {})
        self.planner, self.verifier = [], []

    def __call__(self, prompt, **kw):
        kind = "planner" if "### The defined terms the laws use" in prompt else "verifier"
        calls = getattr(self, kind)
        if self.crash and self.crash[0] == kind and len(calls) + 1 == self.crash[1]:
            raise session.SessionUnavailable("down")
        calls.append((kw.get("label"), prompt))
        if kind == "planner":
            asked = USES.findall(prompt.split("### The classes of road users")[0])
            rows = [row(d, t, quote="words that are not there") if (d, t) in self.bad else row(d, t, **self.alter.get((d, t), {}))
                    for d, t in asked] + self.extra
            ans = {"selection": rows, "aggregates": [record(d, t) for d, t in asked if t.startswith("agg") and (d, t) not in self.bad]}
        else:
            aid = re.search(r'"aggregate_id": "([^"]+)"', prompt).group(1)
            ans = {"aggregate_id": aid, "classifications": [{"class": c, "verdict": "supported", "reason": "r"} for c in CLASSES]}
        return {"result": {"result": json.dumps(ans)}}

    def planner_labels(self):
        return [label for label, _p in self.planner]


class Batched(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.d = Path(self.tmp.name)
        (self.d / "definition_resolution.json").write_text(json.dumps(TABLE))
        patch = mock.patch.object(aggregate, "BATCH_PAIRS", 2)
        patch.start()
        self.addCleanup(patch.stop)

    def tearDown(self):
        self.tmp.cleanup()

    def prepare(self, sessions, run=None, crash_save=None):
        """One preparation; a `Crash` or an unavailable session leaves the run as an interruption would."""
        run = run or FakeRun(self.d)
        real_save = aggregate.save_selection
        saves = []

        def save(r, rows):
            saves.append(1)
            if crash_save and len(saves) == crash_save:
                raise Crash()
            real_save(r, rows)
        with mock.patch.object(session, "run", sessions), mock.patch.object(aggregate, "save_selection", save):
            try:
                return run, aggregate.prepare(run, [], DEFS, ONTO, run.iter / "aggregates")
            except (Crash, session.SessionUnavailable):
                return run, None

    def resume(self, sessions, before):
        """The resume: a fresh run object carrying the counts the interrupted one held in memory (what
        an infrastructure stop persists), on the same directory."""
        return self.prepare(sessions, FakeRun(self.d, before.aggregate_failures))

    def selection(self):
        return aggregate.load_selection(FakeRun(self.d))

    # --- membership ---------------------------------------------------------------------------------
    def test_batches_are_whole_definitions_in_a_fixed_order(self):
        b = aggregate.batches(checks.pairs_of(TABLE))
        self.assertEqual([[d for d, _t in x] for x in b],
                         [["DEF-TST-1", "DEF-TST-1"], ["DEF-TST-2", "DEF-TST-3"], ["DEF-TST-4"] * 3])
        self.assertEqual(aggregate.batches(reversed(list(checks.pairs_of(TABLE)))), b)
        self.assertEqual(len({aggregate.batch_label(x) for x in b}), 3)

    def test_one_session_per_batch_each_asked_its_own_pairs_and_an_oversized_definition_reported(self):
        s = Sessions()
        run, (notes, _u, hold, stop) = self.prepare(s)
        self.assertEqual((hold, stop), ({}, ""))
        self.assertEqual(len(s.planner), 3)
        asked = [sorted(USES.findall(p.split("### The classes of road users")[0])) for _l, p in s.planner]
        self.assertEqual(asked, [sorted(x) for x in aggregate.batches(checks.pairs_of(TABLE))])
        self.assertEqual(len(s.verifier), 3)                                       # agg a, agg c, agg e
        self.assertTrue(any("`DEF-TST-4` has 3 pairs" in n for n in notes), notes)
        self.assertEqual(set(self.selection()), set(checks.pairs_of(TABLE)))
        later = s.planner[1][1]                                                     # the second batch sees the first read-only
        self.assertIn('- `DEF-TST-1` / "agg a": aggregate', later)
        self.assertNotIn("DEF-TST-2", later.split("### Rows already selected (read-only)")[1].split("### Feedback")[0])

    def test_the_whole_batch_is_asked_but_only_its_pending_pairs_are_taken(self):
        first, _out = self.prepare(Sessions(bad={("DEF-TST-1", "plain b")}))
        kept = self.selection()[("DEF-TST-1", "agg a")]
        s = Sessions(alter={("DEF-TST-1", "agg a"): {"reason": "another reason"}})
        run = FakeRun(self.d, first.aggregate_failures); run.iteration = 2          # the next iteration asks the pair again
        _run, (_n, _u, hold, _stop) = self.prepare(s, run)
        self.assertEqual((hold, run.aggregate_failures), ({}, {}))                 # selected now: its count is cleared
        self.assertEqual(len(s.planner), 1)
        self.assertEqual(sorted(USES.findall(s.planner[0][1].split("### The classes")[0])), [("DEF-TST-1", "agg a"), ("DEF-TST-1", "plain b")])
        self.assertEqual(self.selection()[("DEF-TST-1", "agg a")], kept)          # never rewritten

    # --- a batch never rewrites another's rows ------------------------------------------------------------
    def test_a_later_batch_cannot_rewrite_an_earlier_one(self):
        s = Sessions(extra=[row("DEF-TST-1", "agg a", representation="gap", target=None)])
        self.prepare(s)
        self.assertEqual(self.selection()[("DEF-TST-1", "agg a")]["representation"], "aggregate")
        self.assertEqual(self.selection()[("DEF-TST-3", "plain d")]["representation"], "not_aggregate")

    # --- failures ----------------------------------------------------------------------------------------
    def test_a_failure_is_charged_to_its_pair_alone(self):
        run, (_n, _u, hold, stop) = self.prepare(Sessions(bad={("DEF-TST-1", "plain b")}))
        self.assertEqual(run.aggregate_failures, {"select:DEF-TST-1::plain b": 1})
        self.assertEqual(sorted(hold), ["TST-11"])
        self.assertIn(("DEF-TST-1", "agg a"), self.selection())                  # its batch-mate is selected and admitted
        self.assertIsNotNone(aggregate.Reading(run.reading_file).aggregate("DEF-TST-1::agg_a"))
        self.assertEqual(stop, "")

    def test_an_interrupted_preparation_counts_a_failure_once(self):
        s = Sessions(bad={("DEF-TST-1", "plain b")}, crash=("planner", 3))       # batch 1 defective (2 launches), batch 2 down
        run, out = self.prepare(s)
        self.assertIsNone(out)
        self.assertEqual(run.aggregate_failures, {})                                # nothing counted before every batch is through
        s2 = Sessions(bad={("DEF-TST-1", "plain b")})
        run2, (_n, _u, hold, stop) = self.resume(s2, run)
        self.assertEqual(run2.aggregate_failures, {"select:DEF-TST-1::plain b": 1})
        self.assertEqual(stop, "")
        self.assertEqual(len(s2.planner), 2)                                        # batch 1's defective answer is taken back
        self.assertNotIn(aggregate.batch_label(aggregate.batches(checks.pairs_of(TABLE))[0]), s2.planner_labels())

    def test_a_later_batches_saved_rows_do_not_reask_an_earlier_defective_batch(self):
        for bad_on_resume in (True, False):
            with self.subTest(bad_on_resume=bad_on_resume), tempfile.TemporaryDirectory() as tmp:
                original_dir = self.d
                self.d = Path(tmp)
                try:
                    (self.d / "definition_resolution.json").write_text(json.dumps(TABLE))
                    bad = {("DEF-TST-1", "plain b")}
                    first = Sessions(bad=bad, crash=("verifier", 2))
                    run, out = self.prepare(first)
                    self.assertIsNone(out)
                    self.assertIn(("DEF-TST-3", "plain d"), self.selection())
                    resumed = Sessions(bad=bad if bad_on_resume else ())
                    run2, (_n, _u, hold, stop) = self.resume(resumed, run)
                    self.assertEqual(len(resumed.planner), 1)  # only the unanswered third batch
                    self.assertEqual(len(resumed.verifier), 2)
                    self.assertEqual(run2.aggregate_failures, {"select:DEF-TST-1::plain b": 1})
                    self.assertEqual(sorted(hold), ["TST-11"])
                    self.assertEqual(stop, "")
                finally:
                    self.d = original_dir

    def test_context_order_does_not_depend_on_the_planners_answer_order(self):
        first = Sessions(crash=("verifier", 2))

        def reversed_rows(prompt, **kw):
            response = first(prompt, **kw)
            answer = json.loads(response["result"]["result"])
            if "selection" in answer:
                answer["selection"].reverse()
            response["result"]["result"] = json.dumps(answer)
            return response
        run, out = self.prepare(reversed_rows)
        self.assertIsNone(out)
        resumed = Sessions()
        self.resume(resumed, run)
        self.assertEqual(len(resumed.planner), 1)  # only the unanswered third batch

    # --- interruptions, counted in launches ---------------------------------------------------------------
    def test_interrupted_after_the_answer_is_kept(self):
        s = Sessions()
        run, out = self.prepare(s, crash_save=1)                                    # killed before batch 1's rows are saved
        self.assertIsNone(out)
        self.assertEqual((len(s.planner), len(s.verifier)), (1, 0))
        s2 = Sessions()
        self.resume(s2, run)
        self.assertEqual((len(s2.planner), len(s2.verifier)), (2, 3))               # batch 1 taken back; batches 2 and 3 asked

    def test_interrupted_after_the_selection_is_saved(self):
        s = Sessions(crash=("verifier", 1))                                         # batch 1 saved, its gate down
        run, out = self.prepare(s)
        self.assertIsNone(out)
        self.assertIn(("DEF-TST-1", "plain b"), self.selection())                  # its not-aggregate row stays …
        s2 = Sessions()
        self.resume(s2, run)                                                        # … and the orphan's removal changes no prompt
        self.assertEqual((len(s2.planner), len(s2.verifier)), (2, 3))

    def test_interrupted_after_a_partial_admission(self):
        with mock.patch.object(aggregate, "BATCH_PAIRS", 3):                        # DEF-TST-1 and DEF-TST-2: agg a admitted, agg c not
            s = Sessions(crash=("verifier", 2))
            run, out = self.prepare(s)
            self.assertIsNone(out)
            self.assertIsNotNone(aggregate.Reading(run.reading_file).aggregate("DEF-TST-1::agg_a"))
            s2 = Sessions()
            self.resume(s2, run)
        self.assertEqual(len(s2.planner), 2)                                        # batch 1 taken back; DEF-TST-3, DEF-TST-4 asked
        self.assertEqual(sorted(re.search(r'"aggregate_id": "([^"]+)"', p).group(1) for _l, p in s2.verifier),
                         ["DEF-TST-2::agg_c", "DEF-TST-4::agg_e"])                  # agg a is not verified again
        self.assertEqual(len(jsonl.read_strict(aggregate.certificates_file(run))), 3)

    def test_interrupted_before_the_next_batch(self):
        s = Sessions(crash=("planner", 2))
        run, out = self.prepare(s)
        self.assertIsNone(out)
        s2 = Sessions()
        self.resume(s2, run)
        self.assertEqual((len(s2.planner), len(s2.verifier)), (2, 2))               # batch 1 done: neither asked nor verified again
        self.assertEqual(set(self.selection()), set(checks.pairs_of(TABLE)))

    def test_a_finished_preparation_asks_nothing(self):
        run, _out = self.prepare(Sessions())
        s2 = Sessions()
        _run, out = self.resume(s2, run)
        self.assertEqual((out, len(s2.planner), len(s2.verifier)), (([], [], {}, ""), 0, 0))

    # --- changed inputs are never answered from a kept answer ---------------------------------------------
    def test_a_changed_definition_is_asked_again(self):
        run, _out = self.prepare(Sessions(), crash_save=1)
        changed = [dict(d, text=d["text"] + " More words.") if d["id"] == "DEF-TST-1" else d for d in DEFS]
        s2 = Sessions()
        with mock.patch.object(session, "run", s2):
            aggregate.prepare(FakeRun(self.d), [], changed, ONTO, FakeRun(self.d).iter / "aggregates")
        self.assertEqual(len(s2.planner), 3)

    def test_a_changed_effort_is_asked_again(self):
        run, _out = self.prepare(Sessions(), crash_save=1)
        again = FakeRun(self.d); again.opts.plan_effort = "max"
        s2 = Sessions()
        self.prepare(s2, again)
        self.assertEqual(len(s2.planner), 3)

    def test_a_changed_earlier_row_reaches_the_later_batch(self):
        run, _out = self.prepare(Sessions(), crash_save=2)                          # batch 2's answer kept, its rows not saved
        rows = self.selection()
        rows[("DEF-TST-1", "plain b")] = {**rows[("DEF-TST-1", "plain b")], "representation": "gap"}
        aggregate.save_selection(FakeRun(self.d), rows)
        s2 = Sessions()
        self.resume(s2, run)
        self.assertEqual(len(s2.planner), 2)                                        # batch 2's prompt changed: asked again, then batch 3


class OneBatch(unittest.TestCase):
    """At the run's own target (every pair of this table in one batch): a failure, then the gate down
    before the iteration is through, is counted once by the resume, not again."""
    def test_an_admission_outage_after_a_failure_counts_it_once(self):
        self.assertEqual(getattr(aggregate, "BATCH_PAIRS", 20), 20)
        with tempfile.TemporaryDirectory() as t:
            d = Path(t)
            (d / "definition_resolution.json").write_text(json.dumps(TABLE))
            run = FakeRun(d)
            with mock.patch.object(session, "run", Sessions(bad={("DEF-TST-1", "plain b")}, crash=("verifier", 1))):
                with self.assertRaises(session.SessionUnavailable):
                    aggregate.prepare(run, [], DEFS, ONTO, run.iter / "aggregates")
            s2 = Sessions(bad={("DEF-TST-1", "plain b")})
            run2 = FakeRun(d, run.aggregate_failures)                                # what the infrastructure stop persisted
            with mock.patch.object(session, "run", s2):
                _n, _u, _hold, stop = aggregate.prepare(run2, [], DEFS, ONTO, run2.iter / "aggregates")
        self.assertEqual(run2.aggregate_failures, {"select:DEF-TST-1::plain b": 1})
        self.assertEqual(stop, "")
        self.assertEqual(len(s2.planner), 0)                                         # its defective answer is taken back

    def test_a_gate_outage_after_the_selection_resumes_without_a_planner_session(self):
        with tempfile.TemporaryDirectory() as t:
            d = Path(t)
            (d / "definition_resolution.json").write_text(json.dumps(TABLE))
            run = FakeRun(d)
            with mock.patch.object(session, "run", Sessions(crash=("verifier", 2))):
                with self.assertRaises(session.SessionUnavailable):
                    aggregate.prepare(run, [], DEFS, ONTO, run.iter / "aggregates")
            s2 = Sessions()
            with mock.patch.object(session, "run", s2):
                aggregate.prepare(FakeRun(d), [], DEFS, ONTO, run.iter / "aggregates")
        self.assertEqual((len(s2.planner), len(s2.verifier)), (0, 2))               # the selection taken back; agg c and agg e gated


class WorkDeadline(unittest.TestCase):
    """A working session has the run's deadline; a judge keeps 900 s."""
    def deadline(self, **kw):
        got = []

        def fake(prompt, **k):
            got.append(k["timeout"])
            return {"result": {"result": "{}"}}
        with tempfile.TemporaryDirectory() as t, mock.patch.object(session, "run", fake):
            run = FakeRun(Path(t))
            validate_phase._session(run, Path(t), "s", "p", check=lambda a: [], **kw)
        return got

    def test_by_role(self):
        self.assertEqual(self.deadline(role="work"), [1234.0])
        self.assertEqual(self.deadline(), [900])
        self.assertEqual(self.deadline(role="judge"), [900])

    def test_a_defective_answer_is_kept_only_when_asked(self):
        launches = []

        def fake(prompt, **k):
            launches.append(1)
            return {"result": {"result": "{}"}}
        with tempfile.TemporaryDirectory() as t, mock.patch.object(session, "run", fake):
            run = FakeRun(Path(t))
            for _ in range(2):
                self.assertEqual(validate_phase._session(run, Path(t), "s", "p", check=lambda a: ["bad"]), ({}, ["bad"]))
            self.assertEqual(len(launches), 4)                                      # a default caller is asked again
            for _ in range(2):
                self.assertEqual(validate_phase._session(run, Path(t), "k", "p", check=lambda a: ["bad"], keep_defective=True),
                                 ({}, ["bad"]))
            self.assertEqual(len(launches), 6)                                      # kept with its defects: no second pair of launches


if __name__ == "__main__":
    unittest.main()
