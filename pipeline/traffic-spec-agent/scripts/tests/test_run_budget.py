"""Development regression tests for the run's limits over both vendors: a Claude session reserved at
its cap and settled at its cost, an answer without its cost kept at the reservation, a request that
does not fit waiting for one in flight and pausing only when none is, the vendors' limits apart and
the limit over both, runs sharing one limit through their usage files, a restart counting pending
rows, and a review resumed after a pause running only the passes and judgments it does not have."""
import json
import tempfile
import threading
import time
import unittest
from pathlib import Path
from types import SimpleNamespace

from harness.agents import runner, session
from harness.phases import review, validate
from harness.store import budget, jsonl, owner, paths
from harness.store.budget import Budget, BudgetPaused, usage_row
from harness.store.state import Options

REPO = Path(__file__).resolve().parents[2]
ONTO = REPO / "ontology" / "ATOMS_train.md"
PRICES = {"gpt-x": {"input_usd_per_million": 1, "cached_input_usd_per_million": 1, "output_usd_per_million": 1000}}


def claude_row(cost):
    return usage_row("s", "anthropic", "opus", None, {}, cost)


class Limits(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.d = Path(self.tmp.name)
        self.f = self.d / "usage.jsonl"

    def tearDown(self):
        self.tmp.cleanup()

    def test_a_claude_session_is_reserved_at_its_cap_and_settled_at_its_cost(self):
        b = Budget(self.f, None, PRICES, claude_limit_usd=10.0)
        t = b.reserve_session("opus", 4.0, "s")
        self.assertEqual(b.reserved[t], ("anthropic", 4.0))
        b.settle(t, claude_row(1.5))
        self.assertAlmostEqual(b.by_vendor["anthropic"], 1.5)
        self.assertEqual([r["state"] for r in jsonl.read_strict(self.f)], ["pending", "settled"])
        self.assertAlmostEqual(Budget(self.f, None, PRICES).by_vendor["anthropic"], 1.5)

    def test_an_answer_without_its_cost_counts_at_the_reservation(self):
        b = Budget(self.f, None, PRICES, claude_limit_usd=10.0)
        t = b.reserve_session("opus", 4.0, "s")
        b.unknown(t, claude_row(None))
        self.assertAlmostEqual(b.by_vendor["anthropic"], 4.0)
        self.assertAlmostEqual(Budget(self.f, None, PRICES).by_vendor["anthropic"], 4.0)

    def test_a_restart_counts_a_pending_session_at_its_reservation(self):
        Budget(self.f, None, PRICES, claude_limit_usd=10.0).reserve_session("opus", 4.0, "s")   # the process ends during it
        again = Budget(self.f, None, PRICES, claude_limit_usd=10.0)
        self.assertAlmostEqual(again.by_vendor["anthropic"], 4.0)
        self.assertEqual(again.reserved, {})                        # an old pending row is spent, never in flight

    def test_a_claude_limit_needs_a_capped_session(self):
        with self.assertRaises(BudgetPaused):
            Budget(self.f, None, PRICES, claude_limit_usd=10.0).reserve_session("opus", None, "s")
        Budget(self.f, None, PRICES).reserve_session("opus", None, "s")          # no limit: recorded, not limited

    def test_with_nothing_in_flight_a_request_that_does_not_fit_pauses(self):
        b = Budget(self.f, None, PRICES, claude_limit_usd=5.0, max_wait=60)
        b.settle(b.reserve_session("opus", 4.0, "s"), claude_row(3.0))
        t0 = time.monotonic()
        with self.assertRaises(BudgetPaused):
            b.reserve_session("opus", 4.0, "s")
        self.assertLess(time.monotonic() - t0, 5)                    # no wait: nothing could free room

    def test_a_request_that_does_not_fit_waits_for_one_in_flight(self):
        b = Budget(self.f, None, PRICES, claude_limit_usd=5.0, max_wait=60)
        first = b.reserve_session("opus", 4.0, "s")
        got = []
        waiter = threading.Thread(target=lambda: got.append(b.reserve_session("opus", 4.0, "s")))
        waiter.start()
        time.sleep(0.3)
        self.assertEqual(got, [])                                    # it waits while the first is in flight
        b.settle(first, claude_row(0.5))                             # a cheap settlement frees room
        waiter.join(timeout=10)
        self.assertEqual(len(got), 1)
        self.assertAlmostEqual(b.by_vendor["anthropic"], 0.5)

    def test_a_wait_ends_in_a_pause_when_the_settlement_frees_too_little(self):
        b = Budget(self.f, None, PRICES, claude_limit_usd=5.0, max_wait=60)
        first = b.reserve_session("opus", 4.0, "s")
        out = []

        def take():
            try:
                out.append(b.reserve_session("opus", 4.0, "s"))
            except BudgetPaused as e:
                out.append(e)
        waiter = threading.Thread(target=take)
        waiter.start()
        time.sleep(0.3)
        b.settle(first, claude_row(3.5))
        waiter.join(timeout=10)
        self.assertIsInstance(out[0], BudgetPaused)

    def test_the_vendors_limits_are_apart(self):
        b = Budget(self.f, 1.5, PRICES, claude_limit_usd=5.0)
        b.settle(b.reserve_session("opus", 4.0, "s"), claude_row(4.0))
        t = b.reserve("gpt-x", 0, 1000)                              # Claude's $4 does not count against OpenAI's $1.5
        b.settle(t, usage_row("r", "openai", "gpt-x", None, {}, 1.0))
        b.reserve_session("opus", 0.9, "s")                          # OpenAI's $1 does not count against Claude's $5
        with self.assertRaises(BudgetPaused):
            b.reserve_session("opus", 0.5, "s")                      # but Claude's own: 4 + 0.9 + 0.5 > 5
        with self.assertRaises(BudgetPaused):
            b.reserve("gpt-x", 0, 1000)                              # and OpenAI's own: 1 + 1 > 1.5

    def test_the_limit_over_both_vendors_counts_both(self):
        b = Budget(self.f, None, PRICES, total_limit_usd=5.0)
        b.settle(b.reserve_session("opus", 3.0, "s"), claude_row(3.0))
        b.settle(b.reserve("gpt-x", 0, 1000), usage_row("r", "openai", "gpt-x", None, {}, 1.5))
        with self.assertRaises(BudgetPaused):
            b.reserve("gpt-x", 0, 1000)                              # $1 more would pass $5 over both

    def test_runs_sharing_a_limit_exhaust_it_together(self):
        a, c = self.d / "a" / "usage.jsonl", self.d / "c" / "usage.jsonl"
        a.parent.mkdir(); c.parent.mkdir()
        ba = Budget(a, None, PRICES, total_limit_usd=6.0, peers=(c,))
        bc = Budget(c, None, PRICES, total_limit_usd=6.0, peers=(a,))
        ba.settle(ba.reserve_session("opus", 3.0, "s"), claude_row(3.0))                       # run a, Claude
        bc.settle(bc.reserve("gpt-x", 0, 1000), usage_row("r", "openai", "gpt-x", None, {}, 1.0))   # run c, OpenAI
        bc.reserve_session("opus", 1.5, "s")                                                    # 5.5 held over both runs
        with self.assertRaises(BudgetPaused):
            ba.reserve("gpt-x", 0, 1000)                             # a's own spend is 3; with c's it would pass 6
        with self.assertRaises(BudgetPaused):
            bc.reserve("gpt-x", 0, 1000)

    def test_runs_sharing_a_limit_never_both_reserve_the_same_remainder(self):
        """Two runs, $60 over both, each reserving $40 at the same moment: one reservation is admitted."""
        a, c = self.d / "a" / "usage.jsonl", self.d / "c" / "usage.jsonl"
        a.parent.mkdir(); c.parent.mkdir()
        lock = self.d / ".budget-group.lock"
        for _ in range(20):
            for f in (a, c):
                f.unlink(missing_ok=True)
            ba = Budget(a, None, PRICES, total_limit_usd=60.0, peers=(c,), group_lock=lock)
            bc = Budget(c, None, PRICES, total_limit_usd=60.0, peers=(a,), group_lock=lock)
            start, out = threading.Barrier(2), []

            def take(b):
                start.wait()
                try:
                    out.append(b.reserve_session("opus", 40.0, "s"))
                except BudgetPaused:
                    out.append(None)
            ts = [threading.Thread(target=take, args=(b,)) for b in (ba, bc)]
            [t.start() for t in ts]; [t.join(timeout=10) for t in ts]
            self.assertEqual(sum(1 for x in out if x), 1)

    def test_for_run_takes_the_runs_limits_and_peers(self):
        saved = (paths.RESULTS, dict(budget._BUDGETS))
        try:
            paths.RESULTS = self.d
            budget._BUDGETS.clear()
            opts = Options(run_id="x", laws=self.d / "l", ontology=ONTO, reading=self.d / "r", openai_budget_usd=2.0,
                           claude_budget_usd=7.0, total_budget_usd=8.0, budget_peers=["x", "y"], session_timeout=12.0)
            (self.d / "x").mkdir()
            b = budget.for_run(opts, self.d / "x")
            self.assertEqual((b.limits, b.total_limit, b.max_wait), ({"openai": 2.0, "anthropic": 7.0}, 8.0, 12.0))
            self.assertEqual(b.peers, (self.d / "y" / "usage.jsonl",))
            other = Options(run_id="y", laws=self.d / "l", ontology=ONTO, reading=self.d / "r", total_budget_usd=8.0, budget_peers=["x", "y"])
            (self.d / "y").mkdir()
            self.assertEqual(budget.for_run(other, self.d / "y").group_lock, b.group_lock)     # one lock for the group
        finally:
            paths.RESULTS = saved[0]; budget._BUDGETS.clear(); budget._BUDGETS.update(saved[1])


class ClaudeSessions(unittest.TestCase):
    """`session.run` reserves a Claude launch before it starts and records what became of it."""

    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.d = Path(self.tmp.name)
        self.saved = (paths.RESULTS, runner.run_claude, dict(budget._BUDGETS), owner._RECORD)
        paths.RESULTS = self.d
        (self.d / "t").mkdir()
        self.opts = Options(run_id="t", laws=self.d / "l", ontology=ONTO, reading=self.d / "r", model="opus", session_retries=0,
                            retry_wait=0, session_budget_usd=4.0, claude_budget_usd=10.0)
        budget._BUDGETS.clear()
        owner.STOP.clear()
        owner._RECORD = {"nonce": "gen-1"}

    def tearDown(self):
        paths.RESULTS, runner.run_claude, b, owner._RECORD = self.saved
        budget._BUDGETS.clear(); budget._BUDGETS.update(b)
        self.tmp.cleanup()

    def launch(self, answer):
        def fake(prompt, cwd, stream_path, **kw):
            stream_path.write_text("")
            if isinstance(answer, BaseException):
                raise answer
            return answer
        runner.run_claude = fake
        task = self.d / f"task{len(list(self.d.glob('task*')))}"; task.mkdir()
        try:
            session.run("p", task, task, self.opts, max_turns=1, effort=None)
        except (session.SessionUnavailable, KeyboardInterrupt):
            pass
        live = budget.for_run(self.opts, self.d / "t").by_vendor["anthropic"]
        states = [r.get("state") for r in jsonl.read_strict(self.d / "t" / "usage.jsonl")]
        budget._BUDGETS.clear()
        (self.d / "t" / "usage.jsonl").unlink(missing_ok=True)
        return round(live, 6), states

    def test_each_outcome_is_counted_as_what_is_known_of_it(self):
        ok = (0, {"type": "result", "subtype": "success", "is_error": False, "num_turns": 1, "total_cost_usd": 1.25,
                  "usage": {"output_tokens": 3}, "result": "{}"}, False)
        no_cost = (0, {"type": "result", "subtype": "success", "is_error": False, "num_turns": 1, "usage": {}, "result": "{}"}, False)
        self.assertEqual(self.launch(ok), (1.25, ["pending", "settled"]))
        self.assertEqual(self.launch(no_cost), (4.0, ["pending", "unknown"]))
        self.assertEqual(self.launch(KeyboardInterrupt()), (4.0, ["pending", "unknown"]))

    def test_a_session_that_does_not_fit_is_not_launched(self):
        self.opts.claude_budget_usd = 3.0                           # one session's cap does not fit
        launched = []
        runner.run_claude = lambda *a, **kw: launched.append(1)
        with self.assertRaises(BudgetPaused):
            session.run("p", self.d, self.d, self.opts, max_turns=1, effort=None)
        self.assertEqual(launched, [])


class SessionRoles(unittest.TestCase):
    """A Claude session is capped and reserved by its role: plan and coding sessions at
    `session_budget_usd`, repairs at `repair_budget_usd`, tool-less answers at `judge_budget_usd`."""

    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.d = Path(self.tmp.name)
        self.saved = (paths.RESULTS, runner.run_claude, dict(budget._BUDGETS), owner._RECORD)
        paths.RESULTS = self.d
        (self.d / "t").mkdir()
        self.opts = Options(run_id="t", laws=self.d / "l", ontology=ONTO, reading=self.d / "r", model="opus", session_retries=0,
                            retry_wait=0, session_budget_usd=20.0, repair_budget_usd=8.0, judge_budget_usd=2.0, claude_budget_usd=30.0)
        budget._BUDGETS.clear()
        owner.STOP.clear()
        owner._RECORD = {"nonce": "gen-1"}
        self.caps: list = []

    def tearDown(self):
        paths.RESULTS, runner.run_claude, b, owner._RECORD = self.saved
        budget._BUDGETS.clear(); budget._BUDGETS.update(b)
        self.tmp.cleanup()

    def answer(self, result):
        def fake(prompt, cwd, stream_path, max_budget_usd=None, **kw):
            stream_path.write_text("")
            self.caps.append(max_budget_usd)
            return 0, result, False
        runner.run_claude = fake

    def task(self) -> Path:
        t = self.d / f"task{len(list(self.d.glob('task*')))}"; t.mkdir()
        return t

    def pending(self) -> list[float]:
        return [r["reserved_usd"] for r in jsonl.read_strict(self.d / "t" / "usage.jsonl") if r.get("state") == "pending"]

    def test_the_defaults_are_the_documented_caps(self):
        o = Options(run_id="t", laws=self.d / "l", ontology=ONTO, reading=self.d / "r")
        self.assertEqual((o.session_budget_usd, o.repair_budget_usd, o.judge_budget_usd), (20.0, 8.0, 2.0))

    def test_each_role_is_capped_and_reserved_at_its_own_cap(self):
        self.answer({"type": "result", "subtype": "success", "is_error": False, "num_turns": 1, "total_cost_usd": 0.5,
                     "usage": {"output_tokens": 3}, "result": "{}"})
        for role in ("work", "repair", "judge"):
            session.run("p", self.task(), self.task(), self.opts, max_turns=1, effort=None, role=role)
        session.run("p", self.task(), self.task(), self.opts, max_turns=1, effort=None)      # a caller that names no role plans or codes
        self.assertEqual(self.caps, [20.0, 8.0, 2.0, 20.0])
        self.assertEqual(self.pending(), [20.0, 8.0, 2.0, 20.0])
        with self.assertRaises(ValueError):
            session.run("p", self.task(), self.task(), self.opts, max_turns=1, effort=None, role="reviewer")

    def test_the_tool_less_answer_takes_the_judge_cap_and_a_planning_answer_the_work_cap(self):
        self.answer({"type": "result", "subtype": "success", "is_error": False, "num_turns": 1, "total_cost_usd": 0.3,
                     "usage": {"output_tokens": 3}, "result": '{"ok": true}'})
        run = SimpleNamespace(opts=self.opts)
        self.assertEqual(validate._session(run, self.task(), "stage_a", "p"), ({"ok": True}, []))
        self.assertEqual(validate._session(run, self.task(), "plan_aggregates", "q", role="work"), ({"ok": True}, []))
        self.assertEqual(self.caps, [2.0, 20.0])

    def test_near_the_limit_a_role_launches_only_while_its_own_cap_fits(self):
        b = budget.for_run(self.opts, self.d / "t")
        b.settle(b.reserve_session("opus", 20.0, "earlier"), claude_row(21.0))             # $21 of $30 spent, nothing in flight
        self.answer({"type": "result", "subtype": "success", "is_error": False, "num_turns": 1, "total_cost_usd": 0.5,
                     "usage": {"output_tokens": 3}, "result": "{}"})
        session.run("p", self.task(), self.task(), self.opts, max_turns=1, effort=None, role="judge")     # 21.5 + 2 fits
        session.run("p", self.task(), self.task(), self.opts, max_turns=1, effort=None, role="repair")    # 22 + 8 fits
        self.assertEqual(self.caps, [2.0, 8.0])
        with self.assertRaises(BudgetPaused):
            session.run("p", self.task(), self.task(), self.opts, max_turns=1, effort=None, role="work")  # 22.5 + 20 does not
        b.settle(b.reserve_session("opus", 2.0, "more"), claude_row(5.0))                   # $27.5 spent
        with self.assertRaises(BudgetPaused):
            session.run("p", self.task(), self.task(), self.opts, max_turns=1, effort=None, role="repair")
        session.run("p", self.task(), self.task(), self.opts, max_turns=1, effort=None, role="judge")     # 27.5 + 2 still fits
        self.assertEqual(self.caps, [2.0, 8.0, 2.0])

    def test_an_unknown_cost_counts_at_the_role_reservation(self):
        self.answer({"type": "result", "subtype": "success", "is_error": False, "num_turns": 1, "usage": {"output_tokens": 3}, "result": "{}"})
        session.run("p", self.task(), self.task(), self.opts, max_turns=1, effort=None, role="judge")
        self.assertEqual(round(budget.for_run(self.opts, self.d / "t").by_vendor["anthropic"], 6), 2.0)

    def test_a_judge_past_its_cap_is_asked_again_then_deferred(self):
        """A judge the CLI stops at its budget cap left no answer: it is asked once more, and an answer
        that stays missing defers the review (`Deferred`), as a judge without an answer always did."""
        self.answer({"type": "result", "subtype": "error_max_budget_usd", "is_error": True, "num_turns": 1, "total_cost_usd": 2.4,
                     "usage": {"output_tokens": 9000}})
        run = SimpleNamespace(opts=self.opts)
        out = self.task()
        answer, errs = validate._session(run, out, "stage_a", "p")
        self.assertIsNone(answer)
        self.assertEqual(errs, ["stage_a: no JSON object in the answer, twice"])
        self.assertEqual(self.caps, [2.0, 2.0])
        self.assertEqual([json.loads((out / f).read_text())["cut_off"] for f in ("stage_a_result.json", "stage_a_again_result.json")],
                         ["the session stopped at its budget cap"] * 2)
        self.assertEqual(round(budget.for_run(self.opts, self.d / "t").by_vendor["anthropic"], 6), 4.8)   # settled at its actual cost
        ctx = SimpleNamespace(law=SimpleNamespace(text="t"), definitions=[], record={"node_id": "N"})
        with self.assertRaises(review.Deferred):
            review.run_stage_a(run, ctx, "p2", self.task(), "stage_a")


class ResumedReview(unittest.TestCase):
    """A review resumed after a pause runs only the passes and the judgments it does not have."""

    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.d = Path(self.tmp.name)
        self.saved = (review.session.run_tools, validate.session.run)
        self.run = SimpleNamespace(opts=Options(run_id="t", laws=self.d / "l", ontology=ONTO, reading=self.d / "r", model="opus",
                                                reviewer_model="gpt-x", judge_effort="medium"))

    def tearDown(self):
        review.session.run_tools, validate.session.run = self.saved
        self.tmp.cleanup()

    def passes(self):
        return [SimpleNamespace(out_dir=self.d / f"pass{k}", done=False, answer=None, attempts=[]) for k in (1, 2)]

    def test_a_pass_that_submitted_is_not_run_again(self):
        calls, pause = [], [True]

        def fake(prompt, out_dir, opts, t, *, label, **kw):
            calls.append(label)
            if label.endswith("p2") and pause[0]:
                raise BudgetPaused("over")
            t.done, t.answer, t.attempts = True, {"verdict": "accept", "divergences": []}, [{"divergences": 0}]
        review.session.run_tools = fake
        n = SimpleNamespace(id="N", raw={"node_id": "N"})
        with self.assertRaises(BudgetPaused):
            review.run_passes(self.run, n, lambda _k: "prompt", self.d, self.passes(), context="ctx")
        pause[0] = False
        again = self.passes()
        review.run_passes(self.run, n, lambda _k: "prompt", self.d, again, context="ctx")
        # the passes run one after another; the resumed review runs p2 alone
        self.assertEqual(calls, ["review_behaviour_p1", "review_behaviour_p2", "review_behaviour_p2"])
        self.assertEqual(again[0].answer, {"verdict": "accept", "divergences": []})

    def test_a_changed_context_or_no_context_runs_every_pass(self):
        calls = []

        def fake(prompt, out_dir, opts, t, *, label, **kw):
            calls.append(label)
            t.done, t.answer = True, {"verdict": "accept", "divergences": []}
        review.session.run_tools = fake
        n = SimpleNamespace(id="N", raw={"node_id": "N"})
        review.run_passes(self.run, n, lambda _k: "prompt", self.d, self.passes(), context="ctx")
        review.run_passes(self.run, n, lambda _k: "prompt", self.d, self.passes(), context="ctx-changed")
        review.run_passes(self.run, n, lambda _k: "prompt", self.d, self.passes(), context=None)
        self.assertEqual(len(calls), 6)

    def test_a_judgment_already_given_on_the_same_prompt_is_taken_back(self):
        calls = []

        def fake(ask, **kw):
            calls.append(ask)
            return {"result": {"result": json.dumps({"verdict": "lawful"})}}
        validate.session.run = fake
        out = self.d / "judge"
        first = validate._session(self.run, out, "stage_a", "the case")
        second = validate._session(self.run, out, "stage_a", "the case")
        other = validate._session(self.run, out, "stage_a", "another case")
        self.assertEqual((first, second, other[0]), (({"verdict": "lawful"}, []), ({"verdict": "lawful"}, []), {"verdict": "lawful"}))
        self.assertEqual(len(calls), 2)


if __name__ == "__main__":
    unittest.main()
