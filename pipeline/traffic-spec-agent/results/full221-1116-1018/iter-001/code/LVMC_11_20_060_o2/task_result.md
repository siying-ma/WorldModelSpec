# LVMC_11_20_060_o2 — task result

## Final verdict
SCOPE_VIOLATION (an infrastructure problem: the gate never judged the two node files).

## Gate runs
1. **SCOPE_VIOLATION**: "changed outside the node's files" listed only agent-runtime scratch files
   under `.runtime/tmp/claude-154266/…/tasks/*.output` and `.runtime/tmp/claude-154266/cache-break-state-*.json`.
   These are the tool harness's command-output files. They come from this session (the output file of the gate
   command itself) and from concurrent sessions (LVMC_11_18_020, LVMC_11_30_050, LVMC_11_43_010_B_o1).
   I wrote none of them, and I could not prevent them: running the gate command creates one.
2. **SCOPE_VIOLATION**: identical, with the new output file of this run's own command. Nothing had changed.

I stopped after two runs. Each run creates a new runtime output file, so every further run would
return the same verdict. The harness should exclude `.runtime/tmp/` from its scope check, then
re-run the gate (it does so after this session ends).

## What was written
**Rule** (`library/TrafficSpec/Rules/LVMC_11/LVMC_11_20_060_o2.lean`):
- class: `ru_aggregate(subject, "DEF-NRS-484A-320::vehicle")`.
- applicability (e2, e3, e5): `asm.business_or_residence_district`
  ∧ (∃ driveway_or_alley_entrance d: rel_occupies(subject, d) ∨ ∃ alley d: rel_occupies(subject, d))
  ∧ ∃ sidewalk s: rel_occupies(subject, s).
- obligation (e6, e7, e8, e9): ∀ user p, (¬ same p subject ∧ ru_aggregate(p, "DEF-NRS-484A-165::pedestrian")) →
  ¬(kin_speed(subject) > p.halt_speed_tolerance ∧ prim_closest_approach_within(subject, p; p.conflict_horizon)
  ∧ prim_closest_approach_distance(subject, p; p.conflict_horizon) < p.conflict_centre_clearance)
  ∧ ¬ rel_contact(subject, p). This is the record's obligation as written. "exceeds" and "below" are strict.
- Declarations are unchanged from the skeleton. No narrowings: the record's text fixed every choice.

**Witnesses** (`library/TrafficSpecWitness/LVMC_11/LVMC_11_20_060_o2.lean`): a roadway, a sidewalk
y ∈ [0, 4] and a driveway region crossing it; a car with half-length 2 m; a pedestrian walking west at 1.5 m/s.
- forbid: the car moves at 1 m/s. The closest approach is about 0.3 m (below 3 m) at about 2.8 s and 1.8 s (within 3 s), with no contact. Expected violated.
- permit: the car is halted at 0 m/s. Closest approach 2.7 m at 2.7 s, then the pedestrian moves away; no contact. Expected compliant.
- idle: the car is on the roadway and occupies no driveway or sidewalk; occupancy is observed. Expected not applicable.
- blind: the forbid trace with `kin.speed` masked. Expected unknown.
- branch_1: the forbid trace with no pedestrian. Expected compliant.

The witnesses and the leaf adequacy are unverified, because the gate never reached the build.

## Choices the node left open
None beyond the record. Placement: the pedestrian quantifier (e8) is in the obligation, as the
record's obligation states it.

## Why I finished
The gate fails on files outside the node that the runtime itself writes, and nothing in the two
node files can change that. The node itself shows no defect.
