"""Development regression tests for the run's stops: each reason kept apart with its own record and its
own clearing condition, said through one status point, and the send gate held from reservation to
transport start. No model is called; the transports are stubbed.

- a reserved request whose transport has not started is refused by a stop written meanwhile (settled
  at zero, never started, its transport never called), at each of the three transports; a started one
  is settled at its cost whatever stop follows, never recorded as not executed;
- a restart, in another process, reads the stop from the usage file and sends nothing;
- a stop of the run's sends ends a launch as `awaiting_operator`, never as a spent limit, and a limit
  as `paused_budget`, each listed in `summary.json`'s `stops` with how it is cleared;
- a `paused_defect` and a reviewer stop active together: a resume answers the pause only and sends
  nothing while the stop stands; an acknowledgement confirms the stop only and leaves the pause
  active; both hold across restarts, and the operator's notices and the gaps are kept."""
import json
import subprocess
import sys
import tempfile
import threading
import unittest
from pathlib import Path
from unittest import mock

sys.path.insert(0, str(Path(__file__).resolve().parent))
import test_recovery as R                                  # noqa: E402
from test_shared_failures import repeated                 # noqa: E402

from harness.agents import openai_runner, runner, session   # noqa: E402
from harness.phases import feedback                       # noqa: E402
from harness.store import budget, jsonl, owner, paths     # noqa: E402
from harness.store.budget import BudgetPaused, RunStopped  # noqa: E402
from harness.store.gaps import GapLedger                  # noqa: E402
from harness.store.shared_failures import PAUSES          # noqa: E402
from harness.store.state import Options, Run              # noqa: E402

REPO = Path(__file__).resolve().parents[2]
ONTO = REPO / "ontology" / "ATOMS_train.md"
PRICES = {"gpt-x": {"input_usd_per_million": 1, "cached_input_usd_per_million": 1, "output_usd_per_million": 1}}
CLAUDE_OK = (0, {"type": "result", "subtype": "success", "is_error": False, "num_turns": 1, "total_cost_usd": 1.25,
                 "usage": {"output_tokens": 3}, "result": "{}"}, False)


class Tools:
    """A tool session that ends at its first answer."""
    specs = [{"type": "function", "name": "submit"}]
    max_requests = 3

    def reset(self):
        self.done = False

    def choice(self):
        return "required"

    def call(self, name, args):
        self.done = True
        return "{}"


class TransportStart(unittest.TestCase):
    """Reserve, then transport start: the gate is read at both."""

    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.d = Path(self.tmp.name)
        self.saved = (paths.RESULTS, runner.run_claude, openai_runner.run_openai, openai_runner.request, dict(budget._BUDGETS), owner._RECORD)
        paths.RESULTS = self.d
        (self.d / "t").mkdir()
        prices = self.d / "prices.json"
        prices.write_text(json.dumps(PRICES))
        self.opts = Options(run_id="t", laws=self.d / "l", ontology=ONTO, reading=self.d / "r", model="opus", session_retries=0,
                            retry_wait=0, session_budget_usd=4.0, model_prices=prices, reviewer_max_output_tokens=100, session_timeout=60)
        budget._BUDGETS.clear()
        owner.STOP.clear()
        owner._RECORD = {"nonce": "gen-1"}
        self.sent = []

    def tearDown(self):
        paths.RESULTS, runner.run_claude, openai_runner.run_openai, openai_runner.request, b, owner._RECORD = self.saved
        budget._BUDGETS.clear(); budget._BUDGETS.update(b)
        self.tmp.cleanup()

    @property
    def usage(self) -> Path:
        return self.d / "t" / "usage.jsonl"

    def transports(self, during=None):
        """Stub the three transports; each records that it started and runs `during` (another holder's stop)."""
        def claude(prompt, cwd, stream_path, **kw):
            self.sent.append("claude"); during and during()
            return CLAUDE_OK

        def openai(prompt, *, model, stream_path, **kw):
            self.sent.append("openai"); during and during()
            return 0, {"usage": {"input_tokens": 10, "output_tokens": 10}, "output_text": "{}"}, False

        def request(items, **kw):
            self.sent.append("tools"); during and during()
            return 0, {"output": [{"type": "function_call", "call_id": "c", "name": "submit", "arguments": "{}"}],
                       "usage": {"input_tokens": 10, "output_tokens": 10}, "status": "completed"}, False
        runner.run_claude, openai_runner.run_openai, openai_runner.request = claude, openai, request

    def launch(self, kind: str):
        task = self.d / f"task-{kind}-{len(self.sent)}-{len(list(self.d.glob('task*')))}"; task.mkdir()
        if kind == "claude":
            return session.run("p", task, task, self.opts, max_turns=1, effort=None)
        if kind == "openai":
            return session.run("p", task, task, self.opts, max_turns=1, effort=None, model="gpt-x")
        return session.run_tools("p", task, self.opts, Tools(), label="tools", effort=None, model="gpt-x")

    def stop_by_another_holder(self):
        other = budget.Budget(self.usage, None, PRICES)                 # another worker's or process's view of the run's file
        return budget.write_stop(other.file, "wrong_model", "another call of the run was answered by another model")

    def test_a_stop_between_reservation_and_transport_start_refuses_the_request(self):
        self.transports()
        for kind in ("claude", "openai", "tools"):
            with self.subTest(kind=kind):
                self.usage.unlink(missing_ok=True); budget._BUDGETS.clear(); self.sent.clear()
                b = budget.for_run(self.opts, self.d / "t")
                reserved, go = threading.Event(), threading.Event()
                for name in ("reserve", "reserve_session"):
                    real = getattr(b, name)

                    def held(*a, _real=real, **k):                   # the request is reserved; its transport waits
                        token = _real(*a, **k)
                        reserved.set()
                        go.wait(5)
                        return token
                    setattr(b, name, held)
                got = {}

                def worker():
                    try:
                        self.launch(kind)
                        got["out"] = "sent"
                    except RunStopped as e:
                        got["out"] = e
                t = threading.Thread(target=worker)
                t.start()
                self.assertTrue(reserved.wait(5))
                stop = self.stop_by_another_holder()                    # written after the reservation, before the start
                go.set()
                t.join(10)
                self.assertIsInstance(got.get("out"), RunStopped, got)
                self.assertIn(stop["stop"], str(got["out"]))
                self.assertEqual(self.sent, [])                         # no transport started
                rows = jsonl.read_strict(self.usage)
                self.assertEqual([r["state"] for r in rows], ["pending", "stop", "settled"])
                self.assertEqual((rows[2]["request"], rows[2]["cost_usd"], rows[2]["not_started"]),
                                 (rows[0]["request"], 0.0, f"stop `{stop['stop']}`"))
                self.assertEqual(budget.fold(rows)[0], {"openai": 0.0, "anthropic": 0.0})   # its reservation released, nothing spent
                self.assertEqual(b.reserved, {})

    def test_a_started_request_is_settled_at_its_cost_whatever_stop_follows(self):
        for kind in ("claude", "openai", "tools"):
            with self.subTest(kind=kind):
                self.usage.unlink(missing_ok=True); budget._BUDGETS.clear(); self.sent.clear()
                stops = []
                self.transports(during=lambda: stops.append(self.stop_by_another_holder()))
                self.launch(kind)
                rows = jsonl.read_strict(self.usage)
                self.assertEqual([r["state"] for r in rows], ["pending", "stop", "settled"])
                self.assertNotIn("not_started", rows[2])
                self.assertGreater(rows[2]["cost_usd"], 0.0)            # what it cost, never "not executed"
                with self.assertRaises(RunStopped):                     # and no new request starts
                    self.launch(kind)
                self.assertEqual(len(self.sent), 1)
                self.assertEqual(len(jsonl.read_strict(self.usage)), 3)  # refused at its reservation: no row written

    def test_a_restart_in_another_process_sends_nothing(self):
        stop = self.stop_by_another_holder()
        code = ("import sys; from pathlib import Path; from harness.store import budget\n"
                "b = budget.Budget(Path(sys.argv[1]), None, {})\n"
                "try:\n    b.reserve_session('m', 1.0, 'iter-001/plan/batch:L1')\nexcept budget.RunStopped as e:\n    print('stopped', e); sys.exit(3)\n"
                "print('reserved')")
        p = subprocess.run([sys.executable, "-c", code, str(self.usage)], cwd=REPO, capture_output=True, text=True, timeout=60)
        self.assertEqual(p.returncode, 3, p.stdout + p.stderr)
        self.assertIn(stop["stop"], p.stdout)
        self.assertEqual([r["state"] for r in jsonl.read_strict(self.usage)], ["stop"])


def gated(fake, budget_of):
    """The fixture's scripted coding session behind the run's real send gate: reserved, started, settled."""
    def run(prompt, cwd=None, out_dir=None, opts=None, **kw):
        b = budget_of(opts)
        row = budget.usage_row(str(out_dir), "anthropic", "claude-test", None, {}, 0.0)
        token = b.reserve_session("claude-test", 1.0, str(out_dir))
        b.start(token, row)
        try:
            out = fake(prompt, cwd=cwd, out_dir=out_dir, opts=opts, **kw)
        except BaseException:
            b.unknown(token, {**row, "cost_usd": None})
            raise
        b.settle(token, {**row, "cost_usd": 0.01})
        return out
    return run


class Dispatch(unittest.TestCase):
    """A launch's status names what ended it; `stops` lists every stop active, each with its clearing condition."""

    def setUp(self):
        budget._BUDGETS.clear()
        self.addCleanup(budget._BUDGETS.clear)

    def world(self):
        w = R.World({"L-1": "shall stop."})
        w.plans = {"L-1": [R.node("L_1", "shall stop.", "L-1")]}
        return w

    def test_a_stop_of_the_sends_is_never_reported_as_a_spent_limit(self):
        with R.Fixture(self.world()) as f:
            usage = paths.RESULTS / "r" / "usage.jsonl"
            written = []

            def run_budget(o):                                          # the stop is written before the first send
                if not written:
                    written.append(budget.write_stop(usage, "wrong_channel", "a call of the run was answered on another channel"))
                return budget.for_run(o, paths.run_dir(o.run_id))
            with mock.patch.object(session, "run", gated(session.run, run_budget)):
                self.assertEqual(f.drive(launches=1), ["awaiting_operator"])
            stop = written[0]
            s = json.loads((paths.RESULTS / "r" / "summary.json").read_text())
            self.assertIn(stop["stop"], s["stop_reason"])
            self.assertEqual([(x["id"], x["kind"]) for x in s["stops"]], [(stop["stop"], "wrong_channel")])
            self.assertIn(f"acknowledge --stop {stop['stop']}", s["stops"][0]["clears"])
            self.assertFalse(s["generation"]["stop"]["budget"])
            self.assertEqual(f.w.calls[("code", "L_1", 1)], 0)
            self.assertIn(stop["stop"], (paths.RESULTS / "r" / "TO_USER.md").read_text())

    def test_the_one_status_point_writes_the_stops_and_the_spend_together(self):
        """`write_status` writes `stops` and `spend` into one `summary.json`, each read from the same usage
        file: a stop ends the launch while earlier requests stand settled, cash apart from the API equivalent."""
        with R.Fixture(self.world()) as f:
            usage = paths.RESULTS / "r" / "usage.jsonl"
            written = []

            def run_budget(o):
                if not written:
                    for r in ({"state": "settled", "request": "q-acct", "vendor": "anthropic", "cost_usd": 1.25, "billing": "account", "label": "x"},
                              {"state": "settled", "request": "q-key", "vendor": "anthropic", "cost_usd": 0.75, "billing": "api_key", "label": "x"},
                              {"state": "settled", "request": "q-oai", "vendor": "openai", "cost_usd": 0.5, "label": "x"}):
                        jsonl.append_atomic(usage, r)
                    written.append(budget.write_stop(usage, "wrong_model", "a call of the run was answered by another model"))
                return budget.for_run(o, paths.run_dir(o.run_id))
            with mock.patch.object(session, "run", gated(session.run, run_budget)):
                self.assertEqual(f.drive(launches=1), ["awaiting_operator"])
            s = json.loads((paths.RESULTS / "r" / "summary.json").read_text())
            self.assertEqual([(x["id"], x["kind"]) for x in s["stops"]], [(written[0]["stop"], "wrong_model")])
            self.assertEqual(s["spend"], {"cash": {"openai": 0.5, "claude_api_key": 0.75}, "claude_api_equivalent": 1.25,
                                          "claude_billing_not_recorded": 0.0, "unsettled_requests": 0})

    def test_a_spent_limit_stays_paused_budget_and_says_how_it_is_cleared(self):
        with R.Fixture(self.world(), claude_budget_usd=0.5) as f:
            with mock.patch.object(session, "run", gated(session.run, lambda o: budget.for_run(o, paths.run_dir(o.run_id)))):
                self.assertEqual(f.drive(launches=1), ["paused_budget"])
            s = json.loads((paths.RESULTS / "r" / "summary.json").read_text())
            self.assertEqual([x["kind"] for x in s["stops"]], ["budget"])
            self.assertEqual(s["stops"][0]["cause"], s["stop_reason"])
            self.assertIn("raise the limit", s["stops"][0]["clears"])


class TwoStops(unittest.TestCase):
    """A `paused_defect` and a reviewer stop at once: handling one never clears the other or lets a send through."""

    def setUp(self):
        budget._BUDGETS.clear()
        self.addCleanup(budget._BUDGETS.clear)

    def first_launch(self, f):
        """Launch 1: three laws fail the same check (the pause); the third coding session's call is answered
        by another model (the stop, written by the reviewer side of the run)."""
        rd = paths.RESULTS / "r"
        n = {"code": 0}
        inner = gated(session.run, lambda o: budget.for_run(o, paths.run_dir(o.run_id)))

        def run(prompt, cwd=None, out_dir=None, opts=None, **kw):
            out = inner(prompt, cwd=cwd, out_dir=out_dir, opts=opts, **kw)
            n["code"] += 1
            if n["code"] == 3:
                budget.write_stop(rd / "usage.jsonl", "wrong_model", "a property call was answered by another model", law="L-3")
            return out
        f.stack.enter_context(mock.patch.object(session, "run", run))   # undone with the fixture's own patches, in order
        self.assertEqual(self.launch(f), "paused_defect")
        s = self.summary()
        self.assertEqual([x["kind"] for x in s["stops"]], ["paused_defect", "wrong_model"])
        self.assertEqual([x["kind"] for x in feedback.active_stops(Run(f.options()), s["status"], s["stop_reason"])],
                         ["paused_defect", "wrong_model"])
        head = (rd / "TO_USER.md").read_text().split("\n## ", 1)[0]
        self.assertTrue(all(x["id"] in head for x in s["stops"]))      # the operator's file opens with both
        self.assertEqual(self.notices(), 1)                              # raised by L_1 in the paused iteration, kept in its progress
        GapLedger(paths.GAPS_DIR).add({"kind": "no_atom", "span": "a word with no atom", "law_refs": ["L-9"]}, "r", 1)
        return [x["id"] for x in s["stops"]]

    @staticmethod
    def notices() -> int:
        """The parameter notice for the operator, in the iteration's committed progress and its file."""
        rd = paths.RESULTS / "r"
        prog = json.loads((rd / "state.json").read_text())["prog"]
        text = (rd / "TO_USER.md").read_text() if (rd / "TO_USER.md").exists() else ""
        return sum(1 for l in prog.get("to_user", []) if "`p.pause`" in l) + sum(1 for l in text.splitlines() if "`p.pause`" in l)

    def launch(self, f) -> str:
        budget._BUDGETS.clear()                                          # a launch is a new process
        return f.drive(launches=1)[0]

    def summary(self) -> dict:
        return json.loads((paths.RESULTS / "r" / "summary.json").read_text())

    def kept(self, notices: int = 1):
        """The operator's notice (in the iteration's progress until its section is written, then in both)
        and the gap, still there."""
        self.assertEqual(self.notices(), notices)
        self.assertEqual([g["span"] for g in GapLedger(paths.GAPS_DIR).rows], ["a word with no atom"])

    @staticmethod
    def world():
        w = repeated()
        n = w.plans["L-1"][0]
        n["params"] = ["p.pause"]
        n["param_proposals"] = [{"name": "p.pause", "value": 2.0, "unit": "s", "convention": "a pause convention", "source": "a source"}]
        return w

    def pending_after(self, stop_id: str) -> list[dict]:
        rows = jsonl.read_strict(paths.RESULTS / "r" / "usage.jsonl")
        at = next(i for i, r in enumerate(rows) if r.get("stop") == stop_id and r.get("state") == "stop")
        return [r for r in rows[at:] if r.get("state") == "pending"]

    def acknowledge(self, stop_id: str) -> None:
        rec = {"run_id": "r", "stop": stop_id, "decision": "acknowledge", "reason": "the call's model and spend were checked"}
        budget.acknowledge(paths.RESULTS / "r" / "usage.jsonl", stop_id, "sha-" + stop_id, rec)

    def test_a_resume_answers_the_pause_only_and_sends_nothing_while_the_stop_stands(self):
        with R.Fixture(self.world()) as f:
            defect, stop = self.first_launch(f)
            for _ in range(2):                                           # the resume, then a restart of it
                self.assertEqual(self.launch(f), "awaiting_operator")
                s = self.summary()
                self.assertEqual([x["id"] for x in s["stops"]], [stop])  # the pause answered, the stop standing
                self.assertEqual((f.w.calls[("code", "L_4", 1)], self.pending_after(stop)), (0, []))   # nothing sent
                self.kept()
            rows = jsonl.read_strict(paths.RESULTS / "r" / PAUSES)
            self.assertEqual([r.get("answered") for r in rows if "answered" in r], [1])   # answered once, by the first resume
            self.acknowledge(stop)
            self.assertNotEqual(self.launch(f), "awaiting_operator")
            self.assertEqual(f.w.calls[("code", "L_4", 1)], 1)           # both cleared, each by its own condition: it is sent
            self.assertEqual([x["id"] for x in self.summary()["stops"]], [])
            self.kept()

    def test_an_acknowledgement_confirms_the_stop_only_and_leaves_the_pause_active(self):
        with R.Fixture(self.world()) as f:
            defect, stop = self.first_launch(f)
            self.acknowledge(stop)
            s = self.summary()
            for _ in range(2):                                           # read now, and again as a restarted process would
                budget._BUDGETS.clear()
                active = feedback.active_stops(Run(f.options()), s["status"], s["stop_reason"])
                self.assertEqual([(x["id"], x["kind"]) for x in active], [(defect, "paused_defect")])
                self.assertEqual(budget.open_stops(jsonl.read_strict(paths.RESULTS / "r" / "usage.jsonl")), [])
                self.assertEqual(f.w.calls[("code", "L_4", 1)], 0)       # nothing sent: the run stays paused until a resume
                self.kept()
            self.assertEqual([r for r in jsonl.read_strict(paths.RESULTS / "r" / PAUSES) if "answered" in r], [])
            self.assertNotIn(self.launch(f), ("paused_defect", "awaiting_operator"))   # the resume is the pause's own answer
            self.assertEqual(f.w.calls[("code", "L_4", 1)], 1)
            self.assertEqual(self.summary()["stops"], [])
            self.kept()


if __name__ == "__main__":
    unittest.main()
