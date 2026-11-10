"""The boundary of Core's `count` and what it does to the accepted rule NRS_484B_257_1_o1 (demo22).

`count edge sinceφ` counts the rising edges of `edge` at the observations k in (j, i], j the first
observation of the latest run of `sinceφ`: an edge exactly at j is not counted. The definition is
kept (some laws require the act strictly after a boundary); these tests are regression evidence for
the boundary, not a change of it.

Layer 1 runs `Temporal.countEdgesAll` on the working library's built Core. Layer 2 builds the
demo22 rule and the two concepts it calls, from sources pinned by digest, in a temporary library,
and runs it end to end on synthetic traces (the witness builders, footprint occupancy, admission,
`Grounding.evaluate`, the episode verdict). Five cases assert the verdict the law requires; Y1, on
which the demo22 rule gives another verdict, is an expected failure, so a corrected rule reports an
unexpected success. F (a one-observation junction occupancy) is a diagnostic: its tests pin the
rule's observed verdicts and their cause and make no claim about the law's verdict. A sketch of a
search written with `since` (existing Core only) is run on the same cases for comparison; that it
passes them is not a claim that it is a fix."""
import hashlib
import shutil
import tempfile
import unittest
from pathlib import Path

from harness.lean import lean
from harness.store import paths
from scripts.tests import test_precondition_continuity as P

FIXTURE = Path(__file__).parent / "fixtures" / "o10_257_1_o1"

#: The Lean sources, copied byte for byte from the demo22 run's frozen snapshot
#: (results/demo22-1109-0108/frozen/snapshot), and the reading's four parameters and two aggregates
#: as that run's reading gives them. Built in a temporary library, never read from a build cache.
LEAN_SOURCES = {
    "TrafficSpec/Rules/NRS_484B/NRS_484B_257_1_o1.lean": "5aa199fa4a9391a47bce3fb8727cc84da2c81909f7cbc04efd4493bef50ea774",
    "TrafficSpec/Concepts/motion/standstill.lean": "5dce168a44d42f8a3ca8fd15b8ad05ceb7165dac5c339d005040873b01d25327",
    "TrafficSpec/Concepts/motion/region_entry.lean": "2fcfe70da77ac2ca42dfc56239ba0b06ed413c15c4d3784439473f7da1b47ca7",
}
READING_SHA = "8b9e491993a64bf3491b625faca5bd84223caf1a6ea79951e544b1735e18b160"

RULE, SKETCH = "NRS_484B_257_1_o1", "O10_SKETCH_257_1_o1"


def _sha(p: Path) -> str:
    return hashlib.sha256(p.read_bytes()).hexdigest()


# --------------------------------------------------------------------------------------------------
# Layer 1: Core's `count`
# --------------------------------------------------------------------------------------------------

COUNT_PROBE = r'''import TrafficSpec.Core.Foundations.Temporal
open TrafficSpec
def bs (xs : List Bool) : Array R := xs.toArray.map R.ofBool
def shw (a : Array (Except UnknownReason Nat)) : String :=
  ",".intercalate (a.toList.map fun e => match e with | .ok n => toString n | .error w => w.tag)
def row (k : String) (edge since : List Bool) : IO Unit :=
  IO.println s!"{k}\t{shw (Temporal.countEdgesAll "count" (bs edge) (bs since))}"
def main : IO Unit := do
  row "AT_J"         [false, true,  true,  true,  true ] [false, true, true,  true, true]
  row "AFTER_J"      [false, false, true,  true,  true ] [false, true, true,  true, true]
  row "AT_AND_AFTER" [false, true,  false, false, true ] [false, true, true,  true, true]
  row "NEW_RUN_AT_J" [false, false, false, true,  true ] [false, true, false, true, true]
  row "OLD_RUN"      [false, false, true,  false, false] [false, true, true,  false, true]
  row "AT_START"     [false, true,  true ]               [true,  true, true]
'''


@unittest.skipUnless(P.TOOLCHAIN, P.SKIP)
class CountExcludesTheEdgeAtJ(unittest.TestCase):
    """`countEdgesAll` per observation i: edges counted at k in (j, i], never at j; `window_truncated`
    before any run and where the run reaches the trace start."""

    @classmethod
    def setUpClass(cls):
        with tempfile.TemporaryDirectory() as t:
            f = Path(t) / "count_probe.lean"
            f.write_text(COUNT_PROBE, encoding="utf-8")
            code, out = lean.lean_run(paths.LIBRARY, f, timeout=600)
        cls.rows = {l.split("\t")[0]: l.split("\t")[1].split(",") for l in out.splitlines() if "\t" in l}
        assert code == 0 and len(cls.rows) == 6, out[-2000:]

    def test_an_edge_at_j_is_not_counted(self):
        # the run starts at 1 and the act rises at 1: never counted, however long the run lasts
        self.assertEqual(self.rows["AT_J"], ["window_truncated:count", "0", "0", "0", "0"])

    def test_an_edge_after_j_is_counted(self):
        self.assertEqual(self.rows["AFTER_J"], ["window_truncated:count", "0", "1", "1", "1"])

    def test_only_the_edges_in_the_half_open_interval(self):
        # edges at 1 (= j) and at 4: one counted
        self.assertEqual(self.rows["AT_AND_AFTER"], ["window_truncated:count", "0", "0", "0", "1"])

    def test_a_new_run_moves_j_onto_the_edge(self):
        # since-runs start at 1 and at 3; the act rises at 3, the start of the latest run
        self.assertEqual(self.rows["NEW_RUN_AT_J"], ["window_truncated:count", "0", "0", "0", "0"])

    def test_an_edge_of_an_earlier_run_is_not_counted(self):
        # the edge at 2 lies in the run starting at 1; at 3 the condition is false and the run kept,
        # at 4 a new run starts and the edge at 2 no longer counts
        self.assertEqual(self.rows["OLD_RUN"], ["window_truncated:count", "0", "1", "1", "0"])

    def test_a_run_from_the_trace_start_is_truncated(self):
        self.assertEqual(self.rows["AT_START"], ["window_truncated:count"] * 3)


# --------------------------------------------------------------------------------------------------
# Layer 2: the demo22 rule on synthetic traces
# --------------------------------------------------------------------------------------------------

def fixture_library(root: Path) -> Path:
    """A library at `root`: this tree's Core sources and build files and the fixture's Lean sources
    (each checked against its digest), with those modules built there."""
    lib = root / "library"
    (lib / "TrafficSpec").mkdir(parents=True)
    for f in ("lakefile.lean", "lean-toolchain", "lake-manifest.json"):
        shutil.copy2(paths.LIBRARY / f, lib / f)
    shutil.copy2(paths.LIBRARY / "TrafficSpec" / "Core.lean", lib / "TrafficSpec" / "Core.lean")
    shutil.copytree(paths.CORE, lib / "TrafficSpec" / "Core")
    modules = ["TrafficSpec.Core"]
    for rel, sha in LEAN_SOURCES.items():
        src = FIXTURE / "library" / rel
        if _sha(src) != sha:
            raise AssertionError(f"test fixture {src} is not the recorded source (sha256 {_sha(src)}, recorded {sha})")
        (lib / rel).parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(src, lib / rel)
        modules.append(rel[:-len(".lean")].replace("/", "."))
    code, out = lean.lake_build(lib, modules)
    if code:
        raise AssertionError(f"the fixture's Lean sources do not build on this Core: {out[-1500:]}")
    return lib


def _parse(out: str) -> tuple[dict, dict, list]:
    cases, probes, lint = {}, {}, []
    for l in out.splitlines():
        f = l.split("\t")
        if f[0] == "CASE":
            cases[(f[1], f[2])] = {"episode": f[3], "reasons": [r for r in f[4].split(",") if r], "frames": f[5]}
        elif f[0] == "PROBE":
            probes[(f[1], f[2])] = f[3]
        elif f[0] == "LINT":
            lint.append(l)
    return cases, probes, lint


class _Runs:
    """Builds the fixture library once and runs the traces' driver on it."""
    out: str | None = None

    @classmethod
    def get(cls) -> str:
        if cls.out is None:
            if _sha(FIXTURE / "reading.json") != READING_SHA:
                raise AssertionError("the fixture's reading is not the recorded one")
            tmp = Path(tempfile.mkdtemp(prefix="o10-count-"))
            try:
                lib = fixture_library(tmp)
                code, out = lean.lean_run(lib, FIXTURE / "traces.lean", timeout=900, args=(str((FIXTURE / "reading.json").resolve()),))
            finally:
                shutil.rmtree(tmp, True)
            if code or "DONE" not in out.splitlines():
                raise AssertionError(f"the traces' driver failed: {out[-2000:]}")
            cls.out = out
        return cls.out


class _OnTraces(unittest.TestCase):
    rule = RULE

    @classmethod
    def setUpClass(cls):
        cls.cases, cls.probes, cls.lint = _parse(_Runs.get())

    def verdict(self, case: str) -> dict:
        return self.cases[(case, self.rule)]


@unittest.skipUnless(P.TOOLCHAIN, P.SKIP)
class Rule257_1_o1(_OnTraces):
    """The demo22 rule, end to end. Frame tags: C compliant, V violated, N not applicable, U unknown."""

    def test_every_evaluated_trace_passes_the_trace_check(self):
        """The driver checks the very trace it evaluates (no occupancy written by hand)."""
        self.assertEqual(self.lint, [])
        self.assertEqual({c for c, _ in self.cases}, {"y1_slowed_on_first_band_frame", "f_one_frame_junction_occupancy",
                                                      "later_act_counted", "no_act", "insufficient_history",
                                                      "previous_round_act_not_counted"})

    def _pinned(self, case: str, frames: str, entry: int):
        """The pinned rule's result on `case` exists, was reached without an admission, parse or
        evaluation error, and is `violated` at the observation `entry` alone, with `frames` per
        observation."""
        self.assertIn((case, self.rule), self.cases)
        v = self.cases[(case, self.rule)]
        self.assertNotEqual(v["episode"], "error", v["reasons"])
        self.assertEqual(v["reasons"], [])
        self.assertEqual(v["episode"], "violated")
        self.assertEqual(v["frames"], frames)
        self.assertEqual([k for k, c in enumerate(v["frames"]) if c == "V"], [entry])
        self.assertEqual(self.probes[(case, "entry")][entry], "C")       # the violated observation is an entry

    def test_y1_currently_violated_at_the_entry(self):
        """What the demo22 rule does now on Y1 (observed, not the law's verdict): violated at the
        entry, observation 6, and compliant or not applicable everywhere else."""
        self._pinned("y1_slowed_on_first_band_frame", "NCCCCCV", 6)

    def test_f_diagnostic_observed_verdicts(self):
        """Diagnostic, no claim about the law's verdict: what the pinned demo22 rule does on F (the
        car halts at the view point, its body overlaps the junction for one observation and backs
        out, it is halted at the view point again and enters). Compliant at the one-observation
        entry (observation 7), violated at the second entry (observation 10)."""
        self._pinned("f_one_frame_junction_occupancy", "NCCCCCCCCCV", 10)
        self.assertEqual(self.probes[("f_one_frame_junction_occupancy", "entry")], "NVVVVVVCVVC")

    @unittest.expectedFailure
    def test_y1_slowed_on_first_band_frame(self):
        """Law: compliant. Under a yield sign the car is at 4 m/s (at or below the slowed maximum,
        4.5 m/s) from its first observation inside the stop line's 1 m band until it leaves the band,
        so it slowed at the line. Rule: violated at the entry. Cause: the first in-band observation
        ends the run of `approachStarted`, so it is j, the start of the search's run; the act rises
        exactly there and `count` counts edges only in (j, i]; the act still holds at the next
        observation, so no later edge exists and the count is 0."""
        self.assertEqual(self.verdict("y1_slowed_on_first_band_frame")["episode"], "compliant")


    def test_later_act_counted(self):
        v = self.verdict("later_act_counted")
        self.assertEqual(v["episode"], "compliant")
        self.assertNotIn("V", v["frames"])

    def test_no_act(self):
        v = self.verdict("no_act")
        self.assertEqual(v["episode"], "violated")
        self.assertEqual(v["frames"].index("V"), len(v["frames"]) - 1)        # at the entry, and only there

    def test_insufficient_history(self):
        v = self.verdict("insufficient_history")
        self.assertEqual(v["episode"], "unknown")
        self.assertEqual(v["reasons"], ["window_truncated:count"])

    def test_previous_round_act_not_counted(self):
        """Round 1 halts at the line and enters; round 2 re-enters the lane already in the band and
        enters without halting. Law: violated at the round-2 entry only. The search ends at the
        round-1 entry, so the round-1 halt is outside it."""
        v = self.verdict("previous_round_act_not_counted")
        entries = [k for k, c in enumerate(self.probes[("previous_round_act_not_counted", "entry")]) if c == "C"]
        self.assertEqual(len(entries), 2)
        self.assertEqual(v["episode"], "violated")
        self.assertEqual(v["frames"][entries[0]], "C")
        self.assertEqual([k for k, c in enumerate(v["frames"]) if c == "V"], [entries[1]])
        self.assertNotIn("C", self.probes[("previous_round_act_not_counted", "end")][entries[0] + 1:entries[1]])  # no other search end

    def _edge_at_j(self, case: str) -> tuple[int, int, bool]:
        """(j, the number of the act's edges in (j, entry], whether it rises at j) for the last entry
        of `case`, from the probes."""
        act, end = self.probes[(case, "act")], self.probes[(case, "end")]
        entry = max(k for k, c in enumerate(self.probes[(case, "entry")]) if c == "C")
        last_end = max(k for k in range(entry) if end[k] == "C")
        j = last_end + 1
        rises = [k for k in range(1, len(act)) if act[k] == "C" and act[k - 1] == "V"]
        return j, len([k for k in rises if j < k <= entry]), j in rises

    def test_the_cause_in_y1_and_f_is_the_edge_at_j(self):
        """In Y1 and in the F diagnostic the act rises exactly at j and nowhere in (j, entry]; in the
        later-act case one observation after j. Observed mechanism only."""
        for case in ("y1_slowed_on_first_band_frame", "f_one_frame_junction_occupancy"):
            j, after, at_j = self._edge_at_j(case)
            self.assertTrue(at_j, case)                 # the act rises at the start of the search's run
            self.assertEqual(after, 0, case)            # and at no later observation up to the entry
        j, after, at_j = self._edge_at_j("later_act_counted")
        self.assertEqual((at_j, after), (False, 1))     # the contrast: the act rises one observation after j


@unittest.skipUnless(P.TOOLCHAIN, P.SKIP)
class SinceSketch(_OnTraces):
    """The sketch `since (¬approachStarted ∧ (¬occupies v j ∨ entersIntersection)) actedAtPlace` in
    place of `actFound`, on the same traces. Y1 and the other four cases are asserted at the verdict
    the law requires; F only at the sketch's observed verdict, compared with the demo22 rule's, with
    no claim that it is the legal one. Comparison only: none of this makes it a fix."""
    rule = SKETCH

    def test_y1(self):
        self.assertEqual(self.verdict("y1_slowed_on_first_band_frame")["episode"], "compliant")

    def test_f_diagnostic_observed_behaviour(self):
        """Behaviour comparison only, not a legal verdict: on F the sketch is compliant at every
        observation, where the demo22 rule is violated at the second entry."""
        self.assertEqual(self.verdict("f_one_frame_junction_occupancy")["frames"], "NCCCCCCCCCC")

    def test_later_act(self):
        self.assertEqual(self.verdict("later_act_counted")["episode"], "compliant")

    def test_no_act(self):
        self.assertEqual(self.verdict("no_act")["episode"], "violated")

    def test_insufficient_history(self):
        v = self.verdict("insufficient_history")
        self.assertEqual((v["episode"], v["reasons"]), ("unknown", ["window_truncated:since"]))

    def test_previous_round(self):
        v = self.verdict("previous_round_act_not_counted")
        self.assertEqual(v["episode"], "violated")
        self.assertEqual(v["frames"].count("V"), 1)
        self.assertEqual(v["frames"][-1], "V")


if __name__ == "__main__":
    unittest.main()
