# LVMC_11_40_130 — task result

## Final verdict

`SCOPE_VIOLATION` on both gate runs. The cause is in the infrastructure, not in the node's files
(see below). The rule and witness files are complete. The gate has not yet judged them on their
content.

## Gate runs

1. **SCOPE_VIOLATION.** The files listed as "changed outside the node's files" are all under
   `.runtime/tmp/claude-154266/…/tasks/*.output` plus `.runtime/tmp/claude-154266/cache-break-state-*.json`.
   These are the agent runtime's own tool-output capture files, from this session (the capture of
   the gate command itself) and from parallel coding sessions (LVMC_11_18_020, LVMC_11_30_050,
   LVMC_11_30_070_B, LVMC_11_43_010_B_o1). I did not write any of them.
2. **SCOPE_VIOLATION** (re-run with no edits, to rule out a race). Same list. This session's entry
   is now a new capture file (`bgsxiyh2r.output` replaces `bjw2pk0id.output`), which confirms that
   each gate invocation creates the file that trips the check.

I stopped here. Every further run creates a new capture file, so the result cannot change, and the
remaining runs would only waste budget. **The harness should exclude `.runtime/` from the scope
diff.** After that, its post-session re-run will judge the files as they are.

## What was written

**Rule** (`library/TrafficSpec/Rules/LVMC_11/LVMC_11_40_130.lean`):
- **Class (s2):** `ru_aggregate subject "DEF-NRS-484A-025::bicycle"`.
- **Applicability (s1):** `kin_speed subject > p.halt_speed_tolerance`.
- **Obligation (s3+s4):** the stopping-sight-distance model written as a product bound,
  `v² ≤ (a + a) · (D − v · p.bicycle_reaction_time)`.
  - `a` is chosen with `Term.cond`: `p.bicycle_decel_ice` where `env_ice_or_snow` holds, else
    `p.bicycle_decel_wet` where `env_wet_road ∨ env_precipitation` holds, else `p.bicycle_decel_dry`.
  - `D` is "visibility, or the smaller of visibility and lamp reach in darkness". It is written as
    `stopsWithin env_visibility ∧ (env_darkness → stopsWithin p.bicycle_lamp_reach)`.

**Witnesses:**
- The four planned scenarios plus the planned `branch_1` (ice).
- I added `branch_2` (wet road), `branch_3` (precipitation, road not reported wet) and `branch_4`
  (darkness, stopping distance beyond the lamp reach, well inside the visibility). These exercise
  the wet, precipitation and darkness leaves.
- All margins against the reading are clear: forbid S≈41 m vs 15 m; permit 16.5 m vs 200 m;
  branch_1 51 m vs 40 m; branch_2/3 40 m vs 35 m; branch_4 35.6 m vs 30 m.

## Choices the node left open

- **"Smaller of visibility and lamp reach":** written as a conjunction of the two bounds rather
  than a nested `cond` minimum. Since `a > 0` the two are equivalent, and the conjunction still
  decides a violation from the lamp bound in darkness when visibility is unknown. This is not a
  narrowing.
- **"Twice the deceleration":** written `a + a`, because the node declares no literal 2.
- **Narrowings:** none of my own.

## Why I finished

The gate returns SCOPE_VIOLATION because of runtime temp files outside my control, and the result
is the same on every run. The node itself looks consistent; I found no defect in the blueprint.
