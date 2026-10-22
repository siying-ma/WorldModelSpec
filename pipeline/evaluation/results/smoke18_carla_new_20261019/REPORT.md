# smoke18 on carla_new

Evaluated the two accepted smoke18 rules on all five recordings: 6,761 frames at the original
50 ms spacing. No LLM calls, parameter changes, invented observations, or raw-dataset edits.
The accepted Lean sources are copied under `spec_sources/`; the actual reading, scoped aggregate
memberships, source hashes, and toolchain are retained with the results.

## Episode results

| Case | Frames | NRS_484B_407 | NRS_484B_600_1a | Decisive observations |
|---|---:|---|---|---|
| M010 | 1,443 | violated | unknown | 407 at 59.50 s |
| M011 | 1,440 | violated | unknown | 407 at 59.35 s |
| M012 | 1,437 | violated | unknown | 407 at 59.15 s |
| M023 | 2,033 | violated | violated | 407 at 87.15 and 94.15 s; 600 at 64.20–64.30 s |
| M024 | 408 | unknown | violated | 600 from 13.75 s through the recording's end at 20.35 s |

These are decisions of the accepted specifications, not independently established legal labels
or an accuracy score. Rule 600 is explicitly marked a surrogate. Every recording contains only
the subject vehicle, so none tests the traffic-ahead branch against another participant.

## What was actually executed

An isolated library copy uses full Core and registers exactly smoke18's two accepted rules and
two accepted concepts. The source library, Core, ontology, prompts, harness, accepted specs, and
reading were not edited. The reading includes provisional operator-owned parameters; they were
used as recorded, not approved or tuned by this evaluation.

Rule 600 was evaluated with the original compatible observations and with a separate finite-sight
view. Full geometry was restored before both evaluations. All per-frame verdicts agree between
the two views; only unknown-reason sets differ. Complete outputs are in each case's
`600_as_exported.monitor.jsonl` and `600_finite.monitor.jsonl`.

For 407, exact polygon-distance work remained prohibitively expensive even after repeated
boundaries were deduplicated. Full-geometry timeline runs were stopped, not reported as completed.
Instead, `407_episode.monitor.jsonl` contains a conservative monitoring run with
`st.region_geometry` withheld, plus a mechanically checked episode certificate:

- For M010, M011, M012 and M023, there is already a decided violation with that observation
  withheld. These rules use information-monotone Kleene connectives and time operators; restoring
  region geometry cannot reverse those decided violations. Their decisive occasions use the
  observed curve branch, not a presumed crest.
- For M024, the expanded obligation has no region-geometry dependency and is never false at any
  input frame. Restoring geometry therefore cannot produce a violation. The initial applicability
  is unavoidably unknown because its lookback window reaches before the recording. The episode
  must consequently remain unknown.

This establishes the episode conclusions above, not complete full-geometry 407 timelines or
their complete unknown-reason counts. The saved 407 timeline and reason counts are explicitly
for the geometry-withheld run. The certificates are executable evaluation checks, not proofs
that the specifications correctly interpret the statutes.

The current monitor's episode precedence is: any violation; otherwise any unknown; otherwise
any compliant instant; otherwise not applicable. In particular, a clean later drive does not
erase an unknown startup window.

## Compatibility and evidence preservation

| Item | Action |
|---|---|
| Retired ontology names | Removed retired names from unobserved-class lists and removed nine retired, already-absent manifest capabilities. Positive retired classifications are rejected, not silently dropped. |
| New capabilities | Declared `st.on_way`, `st.crest`, and `st.sight_along_way` absent. No highway, crest, or sight measurement was invented. |
| Turn indicators | Kept the existing preparer's mask for the legacy constant-left export. Neither evaluated rule uses that signal. |
| Kinematics and occupancy | Preserved timestamps, identities, SI values, half-extents, yaw rates, occupancy pairs, weather observations, and regional sight values. |
| Large static map | Stored each identical boundary once, then restored it before monitoring. All 6,761 restored scenes were checked equal to the compatible input scenes. Changing geometry is rejected rather than frozen. |
| Censored horizons | In a separate 600 view, removed scalar observations whose minimizing approach was search-censored. Removed 655 frames in M023 and 252 in M024; none in the other cases. No replacement distance was guessed. |

The original input fails current decoding on a retired class, including `vending_vehicle` in an
unobserved-class list. Converted manifests are complete over the full atom list. The adapter's
lane/roadway sight attachment matches the region kinds the current rules query; the old
lane-versus-highway argument mismatch is not present in these accepted implementations.

All 53 supplied SHA256 checks passed. Supplementary-record timestamps, measured speeds,
reflected headings, and attached sight values were checked against the traces; sight values agree
within the export's six-decimal precision. The measurement audit found no need to change their
units or reinterpret half-extents as full dimensions.

## Interpretation and quality findings

### 1. Setup numbers are not per-frame legal labels

**Is it sound, and does it matter?** Yes. The apparent disagreement on M011/M012 is real relative
to the setup-based expectation, but is not by itself a false positive. The exported sight scalar
changes with the moving ego, and the rule reads a qualifying moment within its lookback window,
not just the planned turn site's calibration.

**Example.** At M011's recognition at 59.35 s, roadway sight is 132.65625 m, below 152.4 m.
At M012's 59.15 s recognition it is 141.25 m. The 15 s window and 45 degree tolerance recognize
heading reversal at approximately 135 degrees, not exclusively at 180 degrees. The source
setups near 500 and 533 feet do not describe those observations.

**Recommendation.** Annotate the actual manoeuvre interval and the intended legal reading before
calling these successes or errors. Review the occasion and heading-reversal mapping separately
from the operator-owned window and tolerance values. Do not tune values to make setup-based
expectations pass.

### 2. The slow case genuinely crosses the stopping-model bound briefly

**Is it sound, and does it matter?** The three-frame model violation is reproducible, survives
removal of censored horizons, and is not merely clear-side rounding. It contradicts the
informal expectation that M023 should be compliant throughout, but does not establish a legal
violation independently of the surrogate and its measurement interpretation.

**Example.** At 64.20 s, speed is approximately 7.049518 m/s. Even the shortest recorded model
branch, dry stopping with reaction time 2.5 s and deceleration 3.4 m/s², needs about 24.93199 m.
The sampled occlusion bracket is [24.6875, 24.84375] m. The next two frames also exceed their
blocked-side bracket endpoints. This occurs during approach, before the commanded U-turn.
At M024's first violation, required dry stopping is about 196.08398 m against a finite bracket
[195.3125, 195.46875] m; the 230 m search cap is not the cause of its onset.

**Recommendation.** Keep the observed three-frame finding and its uncertainty margins. Assess
the model's intended scope and the parameter proposals with the operator; do not smooth the
frames away or label every slow-profile frame compliant by construction.

### 3. The dataset cannot establish full stopping-safety compliance

**Is it sound, and does it matter?** Yes. Atmospheric visibility and ice/snow status are absent
in every case; M023/M024 also lack lane widths. The first three cases therefore remain unknown
throughout driving. A known false conjunct can still establish a violation in the other two
cases even when other conjuncts are unknown.

There is a separate semantic limitation: the sight instrument measures incoming observers'
visibility of the ego's sampled body points. It is not a direct observation of the ego driver's
clear path to an obstacle. Core's mutual sight-distance atom can carry it, but that does not
validate its use as a stopping-clearance surrogate.

**Example.** A vehicle body can be visible to an approaching driver while its own driver cannot
see a low object in the path. The two measurements must not be relabelled as equivalent. Also,
an `at_least 230 m` horizon cannot establish a violation merely because a stopping model requires
more than 230 m; the finite-sight evaluation deliberately makes such observations unknown.

**Recommendation.** Obtain forward-view/path-clearance evidence and missing environmental facts
from the adapter's sources where measurable. Never substitute incoming sight for atmospheric
visibility or guess missing widths/weather. Independently audit whether the planner's disclosed
600 operationalization is adequate; compilation and these outputs do not settle that question.

### 4. Exact geometry has a generic runtime bottleneck

**Is it sound, and does it matter?** Yes, for evaluation cost rather than accepted-rule semantics.
The ordinary two-frame probe took about 3.53 s with boundaries and 0.08 s without them. Restoring
shared boundaries removes repeated decoding but not the expensive distance queries needed by an
unknown crest branch.

**Example.** `library/TrafficSpec/Core/Vocab/Atoms.lean:88` builds polygon edges using repeated
indexing into a linked list. This has quadratic list-traversal cost for thousands of vertices.
The distance and overlap routines invoke those operations repeatedly across frames and regions.

**Recommendation.** Audit a generic linear adjacent-pair traversal and safe evaluation caching
under the full Core change process, with arithmetic/geometry regressions. This is independent
of a particular statute or dataset. No such Core optimization was implemented here.

## Checks and artifacts

- Six conversion unit tests and three helper guard checks passed.
- All restored scenes equal their compatible originals; no frames were downsampled.
- A seven-frame fragment, including an unknown-crest situation, gives byte-identical ordinary
  and boundary-restoring monitor output.
- Native and interpreted evaluation give identical M024 episode-check output.
- The finite-sight view changes no 600 per-frame verdict in these recordings.
- `summary.json` holds machine-readable case results; `metadata.json` records exact scope,
  hashes, checks and the intentionally uncomputed full-geometry timelines.
- Large compatible, shared-map and finite-sight trace derivatives are retained in
  `/tmp/smoke18_carla_new.9wH3JE/`; raw dataset files remain unchanged.

## Reproduce in a fresh evaluation workspace

Run from the repository root. This uses the current source library; compare its hashes with
`metadata.json` if that library has changed since the recorded evaluation.

```bash
export RUN=smoke18
export WORK="$(mktemp -d /tmp/smoke18_carla_replay.XXXXXX)"
source pipeline/evaluation/lib/common.sh
build_monitor
REPORT="$EVAL_DIR/results/smoke18_carla_new_20261019"
for c in M010 M011 M012 M023 M024; do
  python3 "$EVAL_DIR/lib/prepare_cases.py" "$DATA/$c" "$WORK/cases/$c" --library "$WORK/lib"
  python3 "$REPORT/project_trace.py" "$WORK/cases/$c" "$WORK/shared/$c"
  python3 "$REPORT/prepare_finite_sight.py" "$WORK/shared/$c" \
    "$DATA/$c/supplementary_evidence.jsonl" "$WORK/finite/$c"
  (cd "$WORK/lib" && lake env lean --run "$REPORT/SharedMapMain.lean" \
    "$WORK/shared/$c/manifest.json" "$READING" "$WORK/shared/$c/trace.json" \
    "$WORK/shared/$c/boundaries.json" NRS_484B_407 --certify-without-region-geometry) \
    > "$WORK/$c.407.jsonl"
  (cd "$WORK/lib" && lake env lean --run "$REPORT/SharedMapMain.lean" \
    "$WORK/finite/$c/manifest.json" "$READING" "$WORK/finite/$c/trace.json" \
    "$WORK/finite/$c/boundaries.json" NRS_484B_600_1a) > "$WORK/$c.600.jsonl"
done
```

The boundary-free intermediate must not be passed directly to the ordinary monitor. The
boundary-restoring runner is part of this evaluation's input decoding, and its explicit
geometry-withholding option certifies episodes only.
