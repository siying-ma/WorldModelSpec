# NRS_484B_270_3_o2 — task result

## Final verdict: UNEXPRESSED (s12, s17 declared `no_atom`)

The record carries gaps on s12 ("a disabled vehicle") and s17 ("In an emergency"). Its own
justifications say the mapped atoms (sig.hazard, kin.engine_running; sig.hazard,
ru.emergency_vehicle) do not denote these words, and no other atom on the surface carries them.
So I declared both spans `no_atom`, as the record's gaps direct. That files the plan's gaps
(`ru.disabled`, `env.emergency`). The rest of the rule was checked using a temporary stub
(see runs 3–5). With that stub, every other check passes: build, static check, claims, all 12
witnesses, and the adequacy (VACUOUS) check on every real leaf.

## Gate runs (6 of 6 used)

| # | verdict | what it showed / what changed after |
|---|---|---|
| 1 | UNEXPRESSED (s12, s17) | Expected. To check the rest of the rule, I removed the narrowings for a diagnostic run. |
| 2 | UNUSED_CLAIM (sig_hazard, kin_engine_running) | This check comes before the witnesses, so the run showed nothing about them. Next, I added a temporary stub `.and .ff (sig_hazard x ∧ kin_engine_running x)` to the exceptions, purely so the gate would reach the witness checks. It was never part of the reading. |
| 3 | WITNESS_FAIL: blind unknown for `window_truncated:since` | Occupancy was masked at every instant, so the past search in exception (c) ran back to the start of the trace. Fix: I wrapped the search as `definedWhen (rel_occupies x b) (since …)`. This changes no decided value: where occupancy is false the conjunction is already false, and where it is true the value is the same. Where occupancy is unobserved, the unknown now carries only the masked atom. I also gave `blind` the window 1000–6000 ms: the first instant has no observation before it, so an entry there would also be unknown for that reason. |
| 4 | VACUOUS: the stub's leaves, plus obligation `drv_motion_halted` and `drv_motion_moving` | In every violated scene, the entry instant already decided the violation. I added `branch_7` and `branch_8`: an entry excused by exception (a), followed by standing on b, or driving on along b, out of the driveway's reach. |
| 5 | VACUOUS: only the stub's two leaves | Everything real passes. I removed the stub and restored the `no_atom` narrowings. |
| 6 | UNEXPRESSED (s12, s17) | Final state of the files. |

Process note: at the start of the session I mistakenly tried a different shell command (the gate
command with `--help` appended). The harness denied it and it did not run; it was not one of the
six gate runs.

## How each span is written

- **s8**: the class is `ru_aggregate x "DEF-NRS-484A-130::motor_vehicle"`.
- **s9 + s10 (obligation)**: for every b of kind `bicycle_lane_or_path`, none of: `drv_motion_entering_region x b`; `rel_occupies x b ∧ drv_motion_halted x`; `rel_occupies x b ∧ drv_motion_moving x`. Both concepts take `p.speed_resolution`.
- **s11 (a)**: `drv_motion_moving x`, and some `driveway_or_alley_entrance` r with `st_region_geometry_distance x r ≤ p.access_crossing_reach`.
- **s13 (c)**: some b with `rel_occupies x b`, and `since (rel_occupies x b) (entering x b ∧ ∃z. z≠x ∧ traffic(z) ∧ ¬rel_occupies z b ∧ prim_closest_approach_within x z [p.immediate_hazard_gap] ∧ prim_closest_approach_distance x z [p.immediate_hazard_gap] < p.conflict_clearance)`, guarded by `definedWhen (rel_occupies x b)` as described in run 3.
- **s14 (d)**: `ru_official_vehicle x ∨ ru_emergency_vehicle x`.
- **s15 (e)**: some `human_direction` device d with `dev_human_direction_role d police_officer`, and some `travel_region` r with `rel_occupies x r ∧ dev_governs d r`. The bicycle lane is a travel region, so it is covered.
- **s12, s17**: not written; declared `no_atom`.

## Choices the node left open

- I read "within" in (a) as at most (≤). In (c), "below" is strictly less than (<).
- The `definedWhen` guard in (c) is a choice about which reason an unknown reports. It changes no truth value, so I did not declare it as a narrowing.
- No reading narrowings were added. The only narrowings are the two `no_atom` declarations.

## Witnesses

These are `forbid`, `permit`, `idle`, `blind`, and `branch_1`–`branch_3` as planned, plus ones I added:
- `branch_4` (compliant): exception (c).
- `branch_5` (not_applicable): an official vehicle.
- `branch_6` (not_applicable): an emergency vehicle.
- `branch_7` (violated): standing on b after an excused entry.
- `branch_8` (violated): driving along b after an excused entry.

## Why I finished

The node's s12 and s17 cannot be stated with any atom on the surface, which the record's own gaps
already say. The gate returns UNEXPRESSED for the repair session to withdraw these spans as gaps
or re-map them. The rest of the rule and its witnesses passed every gate check (run 5, apart from
the stub), so once the gaps are resolved the files should need only the s12/s17 narrowings
removed or the new atoms written in. All six gate runs are used.
