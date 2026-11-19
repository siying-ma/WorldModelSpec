"""Core's reading of a covered general class, end to end through a rule: the Lean fixture
`bus_stop_coverage_fixture.lean` holds a hypothetical, never admitted classification under the
identity reading (the class naming the defined kind included, narrower kinds unresolved,
the general motor-vehicle class covered), and its `#guard`s pin membership and a minimal
no-halt-in-a-bus-stop rule: a car whose classes the source observes is not a member and its halt is
violated; the same car under today's record, or with any class of the aggregate unobserved, is
unknown; a transit or school bus is a member only when the source also lists it as a bus, and
unknown otherwise. Runs only when the library is built."""
import subprocess
import unittest
from pathlib import Path

from harness.store import paths

FIXTURE = Path(__file__).with_name("bus_stop_coverage_fixture.lean")
BUILT = all((paths.LIBRARY / ".lake" / "build" / "lib" / "lean" / "TrafficSpec" / "Core" / p).exists()
            for p in ("Language/Semantics.olean", "Evidence/Builders.olean"))


@unittest.skipUnless(BUILT, "the library is not built (run `lake build` in library/)")
class BusStopCoverage(unittest.TestCase):
    def test_the_fixture_guards_hold_and_the_verdicts_are_as_pinned(self):
        out = subprocess.run(["lake", "env", "lean", "--run", str(FIXTURE)], cwd=paths.LIBRARY,
                             capture_output=True, text=True, timeout=900)
        self.assertEqual(out.returncode, 0, out.stderr or out.stdout)
        tags = [line.rsplit(" ", 1)[-1] for line in out.stdout.splitlines()]
        self.assertEqual(tags, ["violated", "unknown", "unknown", "unknown", "not_applicable", "unknown", "unknown",
                                "not_applicable", "violated", "not_applicable", "unknown"])


if __name__ == "__main__":
    unittest.main()
