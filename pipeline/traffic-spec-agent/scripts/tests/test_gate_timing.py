"""Gate timing: every toolchain run of a gate or of integration records its wall time, the library
lock records how long it was waited for and held, and the generated harnesses time each part of
their evaluation — so a slow gate can be told apart as lock wait, build or evaluation."""
import json
import tempfile
import threading
import time
import unittest
from pathlib import Path

from harness.checks import gate
from harness.lean import lean
from harness.phases import integrate
from harness.store import owner, paths
from harness.model.reading import Reading


def rows(work: Path) -> list[dict]:
    f = work / "toolchain.jsonl"
    return [json.loads(l) for l in f.read_text().splitlines()] if f.exists() else []


class Fixture(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.lib = Path(self.tmp.name) / "library"; (self.lib / "TrafficSpec").mkdir(parents=True)
        self.work = Path(self.tmp.name) / "task"; self.work.mkdir()
        self.saved = (paths.LIBRARY, lean.lake_build, lean.lean_run)
        paths.LIBRARY = self.lib

    def tearDown(self):
        paths.LIBRARY, lean.lake_build, lean.lean_run = self.saved
        owner.STOP.clear()
        self.tmp.cleanup()


class ToolchainRows(Fixture):

    def test_each_build_and_evaluation_records_its_wall_time(self):
        def slow(result, seconds):
            def run(*a, **k):
                time.sleep(seconds)
                return result
            return run
        lean.lake_build = slow((0, ""), 0.2)
        lean.lean_run = slow((0, "DECL\t{}\nDONE"), 0.3)
        gate._toolchain(self.work, ["T"], set(), ("X.",), self.work / "gate_harness.lean")
        got = {r["phase"]: r["seconds"] for r in rows(self.work) if "seconds" in r}
        self.assertGreaterEqual(got["build"], 0.2)
        self.assertGreaterEqual(got["harness"], 0.3)
        self.assertLess(got["build"], 0.3)

    def test_the_lock_row_separates_the_wait_from_the_hold(self):
        held = threading.Event()

        def other():
            with lean.library_lock(self.lib):
                held.set()
                time.sleep(0.4)
        t = threading.Thread(target=other); t.start()
        held.wait()
        with gate._timed(self.work, "lock", lean.library_lock(self.lib)):
            time.sleep(0.2)
        t.join()
        lock = [r for r in rows(self.work) if r["phase"] == "lock"]
        self.assertEqual(len(lock), 1)
        self.assertGreaterEqual(lock[0]["wait"], 0.3)
        self.assertGreaterEqual(lock[0]["held"], 0.2)
        self.assertLess(lock[0]["held"], 0.4)

    def test_the_lock_row_is_written_when_the_gate_returns_from_inside_it(self):
        def inside():
            with gate._timed(self.work, "lock", lean.library_lock(self.lib)):
                return "returned"
        self.assertEqual(inside(), "returned")
        self.assertEqual([r["phase"] for r in rows(self.work)], ["lock"])


class IntegrationRows(Fixture):

    def test_integration_times_its_build_its_witnesses_and_the_lock(self):
        lean.lake_build = lambda lib, targets=None: (0, "")
        lean.lean_run = lambda lib, f: (0, "DONE")
        saved = integrate.index_sync.write_index
        integrate.index_sync.write_index = lambda **k: None
        try:
            r = Path(self.tmp.name) / "reading.json"; r.write_text(json.dumps({"params": [], "aggregates": []}))
            status, _p, _o = integrate.verify_library(self.work, Reading(r))
        finally:
            integrate.index_sync.write_index = saved
        self.assertEqual(status, "verified")
        phases = [x["phase"] for x in rows(self.work)]
        self.assertEqual(sorted(phases), ["build", "lock", "witnesses"])
        self.assertTrue(all(x.get("seconds") is not None for x in rows(self.work) if x["phase"] != "lock"))


class HarnessParts(unittest.TestCase):
    """The generated harnesses print a `TIME` line per part; the verdict reads only the tags it
    knows, so the lines change no verdict."""

    def test_the_node_harness_times_every_part(self):
        src = gate._harness_source("NRS_484B_600_1a", Path("/tmp/r.json"), ("", ""))
        for part in ("occurrences", "checks", "lint", "scenario:", "adequacy"):
            self.assertIn(f'TIME\\t{part}', src)

    def test_the_concept_harness_times_every_part(self):
        src = gate._concept_harness_source("drv.motion.creep", Path("/tmp/r.json"), ("", ""))
        for part in ("checks", "lint", "scenario:", "adequacy"):
            self.assertIn(f'TIME\\t{part}', src)


if __name__ == "__main__":
    unittest.main()
