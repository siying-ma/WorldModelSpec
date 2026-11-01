"""A gate holds the library lock only to write its registries and build: its evaluation runs beside
other gates' evaluations and the reviews, so one slow evaluation delays no other gate. The rerun
of a resource failure is still isolated: it starts only once every running evaluation has ended,
and no evaluation starts while it runs."""
import fcntl
import tempfile
import threading
import time
import unittest
from pathlib import Path

from harness.checks import gate
from harness.lean import lean
from harness.store import owner, paths

DONE = (0, "DECL\t{}\nDONE")


class Locks(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.lib = Path(self.tmp.name) / "library"; (self.lib / "TrafficSpec").mkdir(parents=True)
        self.saved = (paths.LIBRARY, lean.lake_build, lean.lean_run)
        paths.LIBRARY = self.lib
        self.events: list[tuple[float, str]] = []
        self.mu = threading.Lock()

    def tearDown(self):
        paths.LIBRARY, lean.lake_build, lean.lean_run = self.saved
        owner.STOP.clear()
        self.tmp.cleanup()

    def note(self, what):
        with self.mu:
            self.events.append((time.monotonic(), what))

    def at(self, what):
        return next(t for t, w in self.events if w == what)

    def work(self, name):
        w = Path(self.tmp.name) / name; w.mkdir(exist_ok=True)
        return w

    def library_lock_free(self) -> bool:
        with open(self.lib / ".harness.lock", "w") as fh:
            try:
                fcntl.flock(fh, fcntl.LOCK_EX | fcntl.LOCK_NB)
            except BlockingIOError:
                return False
            fcntl.flock(fh, fcntl.LOCK_UN)
            return True

    def toolchain(self, name):
        return gate._toolchain(self.work(name), ["T"], set(), ("X.",), self.work(name) / "gate_harness.lean")

    def test_the_build_holds_the_library_lock_and_the_evaluation_does_not(self):
        free = []
        lean.lake_build = lambda lib, targets: (free.append(("build", self.library_lock_free())), (0, ""))[1]
        lean.lean_run = lambda lib, f, **k: (free.append(("evaluation", self.library_lock_free())), DONE)[1]
        self.toolchain("a")
        self.assertEqual(free, [("build", False), ("evaluation", True)])

    def test_a_slow_evaluation_delays_no_other_gates_build(self):
        lean.lake_build = lambda lib, targets: (0, "")

        def run(lib, f, **k):
            if "slow" in str(f):
                time.sleep(1.0)
            return DONE
        lean.lean_run = run
        slow = threading.Thread(target=lambda: gate._toolchain(self.work("slow"), ["T"], set(), ("X.",), self.work("slow") / "h.lean"))
        slow.start(); time.sleep(0.2)
        t0 = time.monotonic()
        gate._toolchain(self.work("fast"), ["T"], set(), ("X.",), self.work("fast") / "h.lean")
        took = time.monotonic() - t0
        slow.join()
        self.assertLess(took, 0.5)

    def test_the_rerun_of_a_resource_failure_runs_alone(self):
        lean.lake_build = lambda lib, targets: (0, "")
        calls = {"n": 0}

        def run(lib, f, **k):
            calls["n"] += 1
            if calls["n"] == 1:
                return -9, "DECL\t{}"                     # a resource failure: rerun in isolation
            self.note("rerun starts"); time.sleep(0.3); self.note("rerun ends")
            return DONE
        lean.lean_run = run

        def review_evaluation(label, delay):
            time.sleep(delay)
            with lean.evaluation_lock(self.lib):
                self.note(f"{label} starts"); time.sleep(0.4); self.note(f"{label} ends")
        early = threading.Thread(target=review_evaluation, args=("early", 0.0))
        early.start(); time.sleep(0.1)                     # running when the gate begins
        late = threading.Thread(target=review_evaluation, args=("late", 0.45))
        late.start()                                       # asks while the rerun waits or runs
        verdict = self.toolchain("g")
        early.join(); late.join()
        self.assertEqual(verdict, ("", DONE[1]))
        self.assertGreaterEqual(self.at("rerun starts"), self.at("early ends"))
        self.assertTrue(self.at("late starts") >= self.at("rerun ends") or self.at("late ends") <= self.at("rerun starts"))

    def test_an_isolated_rerun_and_other_gates_finish(self):
        """No cycle: a rerun holds the evaluation lock and waits for the library lock; no holder of
        the library lock waits for the evaluation lock."""
        def build(lib, targets):
            time.sleep(0.1)
            return 0, ""
        lean.lake_build = build
        first = {}

        def run(lib, f, **k):
            name = Path(f).parent.name
            if name not in first:
                first[name] = True
                if name.startswith("r"):
                    return -9, "DECL\t{}"
            time.sleep(0.1)
            return DONE
        lean.lean_run = run
        names = ["r1", "g1", "r2", "g2", "g3"]
        done = []
        ts = [threading.Thread(target=lambda n=n: done.append(self.toolchain(n))) for n in names]
        for t in ts:
            t.start()
        for t in ts:
            t.join(timeout=20)
        self.assertEqual(len(done), len(names))


if __name__ == "__main__":
    unittest.main()
