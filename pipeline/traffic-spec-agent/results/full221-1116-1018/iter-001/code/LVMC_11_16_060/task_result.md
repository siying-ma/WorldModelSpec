# LVMC_11_16_060 — task result

## Final verdict
`SCOPE_VIOLATION` on both runs. The gate never got as far as judging the rule or the witnesses.
The files it named are not ones I touched. They are the agent runtime's own scratch files under
`.runtime/tmp/claude-154266/…`: the output capture of each gate command (`tasks/*.output`), the
output files of concurrent sessions for LVMC_11_18_020 and LVMC_11_30_050, and
`cache-break-state-*.json`. This is an environment or harness problem, not a defect in this node's
files. Running the gate again would just use more of the budget: each run writes a fresh
`tasks/*.output` file, and the other sessions' files stay there.

I edited only the two node files below. Both are complete; they were not built or checked by the
gate in this session.

## Gate runs
1. `SCOPE_VIOLATION` — the changed files listed were runtime temp files (mine and other
   sessions'). No change was made to my files after this run.
2. `SCOPE_VIOLATION` — same list, except my own output file had a new name. I stopped here.

## What was written
Rule (`library/TrafficSpec/Rules/LVMC_11/LVMC_11_16_060.lean`):
- class: `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`;
- applicability, f2 ∧ ¬f3:
  - f2: `existsRegion highway w (rel_occupies subject w)`;
  - f3: `existsDevice speed_limit_sign d ((kind d maximum ∨ structure_maximum ∨ zone) ∧
    existsRegion travel_region r (dev_governs d r ∧ rel_occupies subject r))`;
- obligation (f1): `kin_speed subject ≤ Units.mph 25` (m/s).
- Declarations are the skeleton's. `narrowings := []`: the maximum reading and the sign-presence
  reading are the record's own narrowings and are not restated.

Witnesses (`library/TrafficSpecWitness/LVMC_11/LVMC_11_16_060.lean`): highway 1, x 0…200 m by
y −10…10 m, containing lanes 2 (y −2…2 m) and 3 (y 2…6 m). The subject is a motor vehicle in
lane 2. There are three instants, 1 s apart.

| witness | scene | expected |
|---|---|---|
| forbid | no sign, 35 mph | violated |
| permit | no sign, 20 mph | compliant |
| idle | 45 mph maximum sign governs lane 2 | not_applicable |
| blind | a maximum sign with `governsObserved := false`, `dev.governs` masked, 35 mph | unknown |
| branch_1 | a minimum sign governs lane 2 (the kind leaf is false), 35 mph | violated |
| branch_2 | a maximum sign governs lane 3 only (`rel_occupies` on the travel region is false), 35 mph | violated |
| branch_3 | subject at y = 50 m, off the highway, 35 mph | not_applicable |

## Choices the node left open
None beyond the record. The kinds that count as a "different speed limit" (maximum,
structure_maximum, zone) are the ones in the record's applicability. `st.highway` and
`st.travel_region` are written as the quantifier kinds `highway` and `travel_region`.
`dev.speed_limit_sign` is written as the device quantifier kind plus its
`dev_speed_limit_sign_kind` accessor.

## Why I finished
The gate rejects every run with SCOPE_VIOLATION because of files the agent runtime writes under
`.runtime/tmp`, some from other concurrent sessions. Nothing I can do in my two files clears that.
For the harness: the scope check should exclude `.runtime/tmp/`, or the agent's temp directory
should be outside the tree the gate compares. The harness's own re-run after this session should
judge the files as they are.
