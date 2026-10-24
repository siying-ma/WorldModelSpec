"""Development regression tests for the run's operations: what a second-vendor request is known to
have cost (pending, unknown, settled, folded per request), the launches a task may make in one loop
launch, a rejected request never sent again, the owner's record written whole, the scope check that
ignores the harness's own files, a takeover scoped to its library, the mutating commands that take
the lock, and the real signals: a stopped owner ends its children, a dead one leaves them to the next."""
import json
import os
import signal
import subprocess
import sys
import tempfile
import threading
import time
import unittest
from pathlib import Path

from harness.agents import openai_runner, runner, session
from harness.checks import gate
from harness.store import budget, jsonl, owner, paths
from harness.store.state import Options

REPO = Path(__file__).resolve().parents[2]
ONTO = REPO / "ontology" / "ATOMS_train.md"
PRICES = {"gpt-x": {"input_usd_per_million": 1, "cached_input_usd_per_million": 1, "output_usd_per_million": 1000}}
CAP = 1000                                          # output tokens: a request's worst case is about $1


def worst(prompt_chars: int) -> float:
    return (prompt_chars / budget.CHARS_PER_TOKEN * 1 + CAP * 1000) / 1e6


class Spend(unittest.TestCase):
    """A request's rows fold into one state; a lost answer keeps its reservation."""

    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.d = Path(self.tmp.name)
        self.saved = (paths.RESULTS, openai_runner.run_openai, dict(budget._BUDGETS))
        paths.RESULTS = self.d
        (self.d / "t").mkdir()
        prices = self.d / "prices.json"
        prices.write_text(json.dumps(PRICES))
        self.opts = Options(run_id="t", laws=self.d / "l", ontology=ONTO, reading=self.d / "r", model="gpt-x", session_retries=0,
                            retry_wait=0, model_prices=prices, reviewer_max_output_tokens=CAP, openai_budget_usd=5.0)
        budget._BUDGETS.clear()
        owner.STOP.clear()

    def tearDown(self):
        paths.RESULTS, openai_runner.run_openai, b = self.saved
        budget._BUDGETS.clear(); budget._BUDGETS.update(b)
        self.tmp.cleanup()

    def outcome(self, answer):
        """The live and reloaded spend after one tool-less call answered by `answer` (a tuple, or an exception)."""
        def fake(prompt, *, model, stream_path, **kw):
            stream_path.write_text("")
            if isinstance(answer, BaseException):
                raise answer
            return answer
        openai_runner.run_openai = fake
        task = self.d / f"task{len(list(self.d.glob('task*')))}"; task.mkdir()
        try:
            session.run("p" * 300, task, task, self.opts, max_turns=1, effort=None)
        except (session.SessionUnavailable, budget.BudgetPaused, KeyboardInterrupt):
            pass
        live = budget.for_run(self.opts, self.d / "t").spent
        again = budget.Budget(self.d / "t" / "usage.jsonl", 5.0, PRICES).spent
        budget._BUDGETS.clear()
        (self.d / "t" / "usage.jsonl").unlink(missing_ok=True)
        return round(live, 9), round(again, 9)

    def test_each_outcome_is_counted_as_what_is_known_of_it(self):
        w = round(worst(300), 9)
        usage = {"input_tokens": 100, "output_tokens": 10}
        cost = round((100 * 1 + 10 * 1000) / 1e6, 9)
        self.assertEqual(self.outcome((openai_runner.LOST, None, True)), (w, w))           # a timeout after sending
        self.assertEqual(self.outcome((openai_runner.LOST, None, False)), (w, w))          # a dropped connection, an ambiguous 5xx
        self.assertEqual(self.outcome((1, None, True)), (w, w))                            # any timeout means the request was sent
        self.assertEqual(self.outcome(budget.BudgetPaused("quota")), (0.0, 0.0))           # the quota answered: nothing ran
        self.assertEqual(self.outcome((1, None, False)), (0.0, 0.0))                       # refused before execution
        self.assertEqual(self.outcome((0, {"type": "result", "result": "{}", "usage": usage}, False)), (cost, cost))
        self.assertEqual(self.outcome((0, {"type": "result", "result": "{}", "usage": {}}, False)), (w, w))   # no usage: unknown
        self.assertEqual(self.outcome(KeyboardInterrupt()), (w, w))                        # the process stopped during the call

    def test_a_settlement_replaces_unknown_and_happens_once(self):
        f = self.d / "u.jsonl"
        b = budget.Budget(f, 5.0, PRICES)
        t = b.reserve("gpt-x", 300, CAP, "r")
        b.unknown(t, budget.usage_row("r", "openai", "gpt-x", None, {}, None))
        self.assertAlmostEqual(b.spent, worst(300))
        row = budget.usage_row("r", "openai", "gpt-x", None, {"input_tokens": 1}, 0.2)
        b.settle(t, row); b.settle(t, row)
        self.assertAlmostEqual(b.spent, 0.2)
        self.assertAlmostEqual(budget.Budget(f, 5.0, PRICES).spent, 0.2)
        self.assertEqual([r["state"] for r in jsonl.read_strict(f)], ["pending", "unknown", "settled"])

    def test_a_process_ended_between_rows_loses_and_doubles_nothing(self):
        f = self.d / "u.jsonl"
        pend = {"request": "q", "state": "pending", "vendor": "openai", "reserved_usd": 1.0}
        for rows, want in (([pend], 1.0), ([pend, {"request": "q", "state": "unknown", "vendor": "openai", "reserved_usd": 1.0}], 1.0),
                           ([pend, {"request": "q", "state": "unknown", "vendor": "openai", "reserved_usd": 1.0, "cost_usd": 1.0},
                             {"request": "q", "state": "settled", "vendor": "openai", "cost_usd": 0.2}], 0.2)):
            f.write_text("".join(json.dumps(r) + "\n" for r in rows))
            self.assertAlmostEqual(budget.Budget(f, 5.0, PRICES).spent, want, msg=rows)

    def test_concurrent_reservations_stay_within_the_cap(self):
        b = budget.Budget(self.d / "u.jsonl", 1.5, PRICES)
        out = []

        def take():
            try:
                out.append(b.reserve("gpt-x", 300, CAP, "r"))
            except budget.BudgetPaused:
                out.append(None)
        threads = [threading.Thread(target=take) for _ in range(4)]
        [t.start() for t in threads]; [t.join() for t in threads]
        self.assertEqual(sum(1 for x in out if x), 1)

    def test_the_audit_timeout_no_longer_releases_the_cap(self):
        """A request that timed out after sending keeps its reservation."""
        self.opts.openai_budget_usd = 1.1
        budget._BUDGETS.clear()

        def fake(prompt, *, model, stream_path, **kw):
            stream_path.write_text(json.dumps({"type": "error", "error": "timeout after send"}) + "\n")
            return 1, None, True
        openai_runner.run_openai = fake
        with self.assertRaises(session.SessionUnavailable):
            session.run("x", self.d / "t", self.d / "t", self.opts, max_turns=1, effort=None)
        again = budget.Budget(self.d / "t" / "usage.jsonl", 1.1, PRICES)
        self.assertEqual(len(again.unresolved), 1)
        with self.assertRaises(budget.BudgetPaused):
            again.reserve("gpt-x", 1, CAP)

    def test_exception_classification(self):
        def exc(name, status=None, cause=None, base=Exception):
            cls = type(name, (base,), {})
            e = cls("boom"); e.status_code = status; e.__cause__ = cause
            return e
        conn = type("APIConnectionError", (Exception,), {})
        timeout = type("APITimeoutError", (conn,), {})("t")
        self.assertEqual(openai_runner._code(timeout), openai_runner.LOST)
        self.assertEqual(openai_runner._code(exc("APIConnectionError", cause=ConnectionRefusedError())), 1)
        self.assertEqual(openai_runner._code(exc("APIConnectionError", cause=OSError("reset by peer"))), openai_runner.LOST)
        self.assertEqual(openai_runner._code(exc("InternalServerError", 500)), openai_runner.LOST)
        self.assertEqual(openai_runner._code(exc("APIStatusError", 408)), openai_runner.LOST)
        self.assertEqual(openai_runner._code(exc("RateLimitError", 429)), 1)
        self.assertEqual(openai_runner._code(exc("AuthenticationError", 401)), 1)
        self.assertEqual(openai_runner._code(exc("BadRequestError", 400)), openai_runner.BAD_REQUEST)
        self.assertEqual(openai_runner._code(exc("APIResponseValidationError")), openai_runner.LOST)


class Launches(unittest.TestCase):
    """At most `session_retries + 1` launches per task per loop launch; a rejected request is not resent."""

    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.d = Path(self.tmp.name)
        self.saved = (paths.RESULTS, runner.run_claude, openai_runner.run_openai, openai_runner.request, dict(budget._BUDGETS),
                      owner._RECORD)
        paths.RESULTS = self.d
        (self.d / "t").mkdir()
        prices = self.d / "prices.json"
        prices.write_text(json.dumps(PRICES))
        self.opts = Options(run_id="t", laws=self.d / "l", ontology=ONTO, reading=self.d / "r", model="opus", session_retries=2,
                            retry_wait=0, model_prices=prices, reviewer_max_output_tokens=CAP)
        budget._BUDGETS.clear()
        owner.STOP.clear()
        owner._RECORD = {"nonce": "gen-1"}
        self.calls = 0

    def tearDown(self):
        paths.RESULTS, runner.run_claude, openai_runner.run_openai, openai_runner.request, b, owner._RECORD = self.saved
        budget._BUDGETS.clear(); budget._BUDGETS.update(b)
        self.tmp.cleanup()

    def refuse(self, prompt, cwd, stream_path, **kw):
        self.calls += 1
        stream_path.write_text("")
        return 0, {"type": "result", "subtype": "success", "is_error": True, "num_turns": 1, "api_error_status": 529,
                   "usage": {"output_tokens": 1}, "result": "Overloaded"}, False

    def test_three_failed_launches_spend_one_generation_and_a_new_one_renews(self):
        for k, name in enumerate(["session_result.json", "session_result.retry1.json", "session_result.retry2.json"], 1):
            (self.d / name).write_text(json.dumps({"attempt": k, "generation": "gen-1", "failure": "overloaded"}))
        runner.run_claude = self.refuse
        with self.assertRaises(session.SessionUnavailable):
            session.run("p", self.d, self.d, self.opts, max_turns=1, effort=None)
        self.assertEqual(self.calls, 0)                                 # the same loop launch: nothing is launched
        owner._RECORD = {"nonce": "gen-2"}
        with self.assertRaises(session.SessionUnavailable):
            session.run("p", self.d, self.d, self.opts, max_turns=1, effort=None)
        self.assertEqual(self.calls, 3)                                 # a new loop launch: at most retries + 1

    def test_the_audit_exhausted_retry(self):
        """Three earlier failures and two more invocations. Under one
        loop launch the task makes at most `session_retries + 1` launches, the second invocation none."""
        for k in range(3):
            (self.d / f"session_result.retry{k}.json").write_text(json.dumps({"failure": "timeout"}))
        runner.run_claude = self.refuse
        counts = []
        for _ in range(2):
            with self.assertRaises(session.SessionUnavailable):
                session.run("x", self.d, self.d, self.opts, max_turns=1, effort=None)
            counts.append(self.calls)
        self.assertEqual(counts, [3, 3])

    def test_a_launch_is_recorded_before_its_call(self):
        seen = []

        def fake(prompt, cwd, stream_path, **kw):
            seen.append(json.loads((self.d / "session_result.json").read_text()))
            raise SystemExit(1)                                         # the process ends during the call
        runner.run_claude = fake
        with self.assertRaises(SystemExit):
            session.run("p", self.d, self.d, self.opts, max_turns=1, effort=None)
        self.assertTrue(seen[0]["started"])
        self.assertEqual(session._launches(self.d, "session")[1], 1)    # it counts against the allowance
        self.assertFalse(session.finished(self.d))

    def test_a_rejected_request_is_not_resent_and_a_changed_one_is(self):
        sent = []

        def fake(prompt, *, model, stream_path, effort, **kw):
            sent.append(effort)
            stream_path.write_text(json.dumps({"type": "error", "error": "BadRequestError: unsupported"}) + "\n")
            return openai_runner.BAD_REQUEST, None, False
        openai_runner.run_openai = fake
        for _ in range(2):
            with self.assertRaises(session.BadRequest):
                session.run("p", self.d, self.d, self.opts, max_turns=1, effort="high", model="gpt-x")
        owner._RECORD = {"nonce": "gen-2"}                              # not in another loop launch either
        with self.assertRaises(session.BadRequest):
            session.run("p", self.d, self.d, self.opts, max_turns=1, effort="high", model="gpt-x")
        self.assertEqual(sent, ["high"])
        with self.assertRaises(session.BadRequest):
            session.run("p", self.d, self.d, self.opts, max_turns=1, effort="low", model="gpt-x")   # a changed request is sent
        self.assertEqual(sent, ["high", "low"])

    def test_a_tool_session_does_not_resend_its_rejected_request(self):
        class Tools:
            specs, done, max_requests = [], False, 3
            def reset(self): pass
            def choice(self): return "auto"
            def call(self, name, args): return "{}"
        sent = []

        def fake(items, **kw):
            sent.append(len(items))
            return openai_runner.BAD_REQUEST, {"error": "BadRequestError: bad schema"}, False
        openai_runner.request = fake
        self.opts.model = "gpt-x"
        for _ in range(2):
            with self.assertRaises(session.BadRequest):
                session.run_tools("p", self.d, self.opts, Tools(), label="review", effort="high")
        self.assertEqual(sent, [1])


PRELUDE = """
import json, os, signal, subprocess, sys, time
from pathlib import Path
from harness.store import paths, owner
paths.LIBRARY = Path(sys.argv[1])
allowed = json.loads(os.environ.get("TEST_ALLOWED_PIDS", "null"))
if allowed is not None:
    _all = owner._pids
    owner._pids = lambda: [p for p in _all() if p in allowed]
"""


def clean_env(**extra) -> dict:
    env = {k: v for k, v in os.environ.items() if k not in (owner.ENV, owner.LIB_ENV, "TEST_ALLOWED_PIDS")}
    env.update({k: v for k, v in extra.items() if v is not None})
    return env


def py(code: str, *args, allowed=None, env=None, timeout=60) -> subprocess.CompletedProcess:
    e = env or clean_env()
    if allowed is not None:
        e = {**e, "TEST_ALLOWED_PIDS": json.dumps(allowed)}
    return subprocess.run([sys.executable, "-c", PRELUDE + code, *map(str, args)], cwd=REPO, env=e,
                          capture_output=True, text=True, timeout=timeout)


def sleeper(env: dict) -> subprocess.Popen:
    return subprocess.Popen([sys.executable, "-c", "import time; time.sleep(120)"], env=env)


def alive(pid: int) -> bool:
    try:
        os.kill(pid, 0)
    except OSError:
        return False
    try:                                            # a zombie is not alive
        return Path(f"/proc/{pid}/stat").read_text().split()[2] != "Z"
    except OSError:
        return False


class Ownership(unittest.TestCase):
    """The owner's record is written whole; a takeover sees only its own library's processes."""

    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.lib = Path(self.tmp.name) / "library"; self.lib.mkdir()
        self.procs: list[subprocess.Popen] = []

    def tearDown(self):
        for p in self.procs:
            if p.poll() is None:
                p.kill()
            p.wait()
            for s in (p.stdout, p.stderr):
                if s:
                    s.close()
        self.tmp.cleanup()

    def keep(self, p):
        self.procs.append(p); return p

    def test_the_scope_check_ignores_the_harness_files_and_nothing_else(self):
        root = Path(self.tmp.name)
        (root / "library" / "TrafficSpec").mkdir()
        rule = root / "library" / "TrafficSpec" / "R.lean"; rule.write_text("a")
        files = {n: root / "library" / n for n in owner.HARNESS_FILES}
        for f in files.values():
            f.write_text("{}")
        tmp = root / "library" / "..run.owner.json.tmp-1-2"; tmp.write_text("{")      # the atomic writer's temporary file
        before = gate.repo_digest(root)
        self.assertFalse({f"library/{n}" for n in owner.HARNESS_FILES} & set(before))
        self.assertNotIn("library/" + tmp.name, before)
        for f in files.values():
            f.write_text(json.dumps({"pgids": [12345]}))               # an owner registering a worker
        self.assertEqual(gate.repo_digest(root), before)
        rule.write_text("b")
        self.assertNotEqual(gate.repo_digest(root), before)             # a rule file is still in scope

    def test_the_review_probe_owner_metadata_no_longer_violates_scope(self):
        """The review's `owner_metadata_scope` probe: the record changing during a session is no scope violation."""
        root = Path(self.tmp.name)
        saved = (paths.REPO, paths.LIBRARY)
        paths.REPO, paths.LIBRARY = root, root / "library"
        try:
            f = root / "library" / ".run.owner.json"
            f.write_text(json.dumps({"nonce": "n", "pgids": []}))
            base = gate.repo_digest()
            f.write_text(json.dumps({"nonce": "n", "pgids": [12345]}))
            self.assertEqual(gate.repo_digest(), base)
        finally:
            paths.REPO, paths.LIBRARY = saved

    def test_an_interrupted_record_write_leaves_the_record_whole(self):
        r = py("""
nonce = owner.acquire('r1')
def boom(*a): raise OSError('killed')
os.replace = boom
try:
    owner.register(4242)
except OSError:
    pass
print(json.dumps(json.loads(owner.record_path().read_text())))
""", self.lib)
        self.assertEqual(r.returncode, 0, r.stderr)
        rec = json.loads(r.stdout.strip().splitlines()[-1])
        self.assertEqual(rec["pgids"], [])                              # the earlier record, whole

    def test_an_unreadable_record_with_a_live_untold_writer_is_refused_even_by_force(self):
        """An empty owner record and a live child carrying the earlier nonce: the takeover is refused."""
        (self.lib / ".run.lock").write_text("")
        (self.lib / ".run.owner.json").write_text("")
        child = self.keep(sleeper(clean_env(**{owner.ENV: "audit_previous_owner_nonce"})))
        time.sleep(0.3)
        for force in ("False", "True"):
            r = py(f"owner.acquire('new', force={force})", self.lib, allowed=[child.pid])
            self.assertNotEqual(r.returncode, 0, force)
            self.assertIn(str(child.pid), r.stderr)
        self.assertTrue(alive(child.pid))

    def test_a_takeover_ends_only_its_own_library(self):
        lib_a = Path(self.tmp.name) / "a"; lib_a.mkdir()
        holder = self.keep(subprocess.Popen(
            [sys.executable, "-c", PRELUDE + """
owner.acquire('a')
c = subprocess.Popen([sys.executable, '-c', 'import time; time.sleep(120)'], stdout=subprocess.DEVNULL)
print(c.pid, flush=True); time.sleep(120)""", str(lib_a)], cwd=REPO, env=clean_env(), stdout=subprocess.PIPE, text=True))
        a_child = int(holder.stdout.readline())
        (self.lib / ".run.lock").write_text("")
        (self.lib / ".run.owner.json").write_text("{damaged")
        orphan = self.keep(sleeper(clean_env(**{owner.ENV: "b-earlier", owner.LIB_ENV: str(self.lib.resolve())})))
        time.sleep(0.3)
        pids = [holder.pid, a_child, orphan.pid]
        r = py("owner.acquire('b')", self.lib, allowed=pids)
        self.assertNotEqual(r.returncode, 0)
        self.assertIn(str(orphan.pid), r.stderr)
        r = py("owner.acquire('b', force=True); print('held')", self.lib, allowed=pids)
        self.assertEqual(r.returncode, 0, r.stderr)
        orphan.wait(timeout=10)
        self.assertFalse(alive(orphan.pid))
        self.assertTrue(alive(holder.pid) and alive(a_child))
        os.kill(a_child, signal.SIGKILL)

    def test_missing_empty_damaged_and_earlier_format_records(self):
        (self.lib / ".run.lock").write_text("")
        for content in (None, "", "{damaged"):
            f = self.lib / ".run.owner.json"
            if content is None:
                f.unlink(missing_ok=True)
            else:
                f.write_text(content)
            r = py("owner.acquire('r')", self.lib, allowed=[])
            self.assertEqual(r.returncode, 0, (content, r.stderr))
        (self.lib / ".run.owner.json").unlink()
        (self.lib / ".run.lock").write_text(json.dumps({"pid": 1, "run_id": "old", "nonce": "old-nonce", "pgids": []}))
        child = self.keep(sleeper(clean_env(**{owner.ENV: "old-nonce"})))
        time.sleep(0.3)
        r = py("owner.acquire('r')", self.lib, allowed=[child.pid])
        self.assertNotEqual(r.returncode, 0)                            # the earlier format's record is read
        child.kill(); child.wait()
        r = py("owner.acquire('r'); print(owner._RECORD['nonce'])", self.lib, allowed=[])
        self.assertEqual(r.returncode, 0, r.stderr)
        self.assertEqual((self.lib / ".run.lock").read_text(), "")      # moved, not kept in the lock file
        self.assertEqual(json.loads((self.lib / ".run.owner.json").read_text())["nonce"], r.stdout.strip())

    def test_index_and_a_standalone_gate_take_the_lock(self):
        holder = self.keep(subprocess.Popen([sys.executable, "-c", PRELUDE + "owner.acquire('loop'); print('held', flush=True); time.sleep(60)",
                                             str(self.lib)], cwd=REPO, env=clean_env(), stdout=subprocess.PIPE, text=True))
        self.assertEqual(holder.stdout.readline().strip(), "held")
        for call in ("from harness.__main__ import Cli; Cli().index()",
                     "from harness.__main__ import Cli; Cli().gate('r', 'L_1')"):
            r = py(call, self.lib)
            self.assertNotEqual(r.returncode, 0, call)
            self.assertIn("another process owns the library", r.stderr, call)
        nonce = json.loads((self.lib / ".run.owner.json").read_text())["nonce"]
        ok = py("owner.check_delegated(); print('delegated')", self.lib,
                env=clean_env(**{owner.ENV: nonce, owner.LIB_ENV: str(self.lib.resolve())}))
        self.assertEqual(ok.stdout.strip(), "delegated", ok.stderr)
        other = py("owner.check_delegated()", self.lib, env=clean_env(**{owner.ENV: nonce, owner.LIB_ENV: "/elsewhere/library"}))
        self.assertNotEqual(other.returncode, 0)


class Signals(unittest.TestCase):
    """Real signals: a stopped owner ends its children and relaunches nothing; a killed one leaves them to the next."""

    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name)
        self.lib = self.root / "library"; self.lib.mkdir()

    def tearDown(self):
        self.tmp.cleanup()

    def test_sigterm_ends_the_children_and_launches_no_relaunch(self):
        results = self.root / "results"; results.mkdir()
        p = subprocess.Popen([sys.executable, "-c", PRELUDE + f"""
paths.RESULTS = Path(sys.argv[2])
from harness.agents import runner, session
from harness.store.state import Options
owner.acquire('sig')
child = subprocess.Popen([sys.executable, '-c', 'import time; time.sleep(120)'], start_new_session=True)
owner.register(child.pid)
def fake(prompt, cwd, stream_path, **kw):
    with open(Path(sys.argv[2]) / 'launches', 'a') as f: f.write('x\\n')
    print('ready', child.pid, flush=True)
    time.sleep(120)
    return 1, None, False
runner.run_claude = fake
opts = Options(run_id='s', laws=Path('l'), ontology=Path({str(ONTO)!r}), reading=Path('r'), model='opus', session_retries=3, retry_wait=0)
d = Path(sys.argv[2]) / 'task'; d.mkdir(parents=True)
session.run('p', d, d, opts, max_turns=1, effort=None)
""", str(self.lib), str(results)], cwd=REPO, env=clean_env(), stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        try:
            line = p.stdout.readline().split()
            self.assertEqual(line[0], "ready", p.stderr.read() if not line else line)
            child = int(line[1])
            p.send_signal(signal.SIGTERM)
            code = p.wait(timeout=30)
        finally:
            if p.poll() is None:
                p.kill(); p.wait()
            p.stdout.close(); p.stderr.close()
        self.assertNotEqual(code, 0)
        deadline = time.time() + 10
        while alive(child) and time.time() < deadline:
            time.sleep(0.1)
        self.assertFalse(alive(child))
        self.assertEqual((results / "launches").read_text().count("x"), 1)   # no relaunch after the stop

    def test_a_killed_owner_leaves_children_the_next_owner_refuses_then_ends_with_force(self):
        p = subprocess.run([sys.executable, "-c", PRELUDE + """
owner.acquire('dies')
c = subprocess.Popen([sys.executable, '-c', 'import time; time.sleep(120)'], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
print(c.pid, flush=True)
os.kill(os.getpid(), signal.SIGKILL)""", str(self.lib)], cwd=REPO, env=clean_env(), capture_output=True, text=True, timeout=60)
        child = int(p.stdout.split()[0])
        try:
            self.assertTrue(alive(child))
            r = py("owner.acquire('next')", self.lib, allowed=[child])
            self.assertNotEqual(r.returncode, 0)
            self.assertIn("--force_takeover", r.stderr)
            r = py("owner.acquire('next', force=True); print('held')", self.lib, allowed=[child])
            self.assertEqual(r.returncode, 0, r.stderr)
            deadline = time.time() + 10
            while alive(child) and time.time() < deadline:
                time.sleep(0.1)
            self.assertFalse(alive(child))
        finally:
            try:
                os.kill(child, signal.SIGKILL)
            except OSError:
                pass


if __name__ == "__main__":
    unittest.main()
