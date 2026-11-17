# LVMC_11_20_060_o3 — task result

## Final verdict

**SCOPE_VIOLATION, triggered by the infrastructure and not by the node's files.** The gate never
judged the rule or the witnesses. Every run stopped at the scope check, which listed only files
under `.runtime/tmp/claude-154266/…`:
- the tool-output files (`tasks/*.output`) of this session;
- the tool-output files of other coding sessions running at the same time (LVMC_11_18_020,
  LVMC_11_30_050, LVMC_11_43_010_B_o1);
- a `cache-break-state-*.json` file and an `fswatch-probe` file.

None of these is one of my files, and I can't write to any of them. The harness creates a
`tasks/*.output` file for each shell call, including the gate call itself. So the gate cannot
pass its own scope check in this environment, however often it runs. This should be treated as
`INFRA`: the harness's scope check needs to ignore `.runtime/`.

## Gate runs

1. SCOPE_VIOLATION (`.runtime/tmp/.../tasks/b6hh0f3iv.output`, `fswatch-probe-*/probe`). I ran it
   by mistake before editing anything, on the harness's skeletons.
2. and 3. I ran the gate command again by mistake, with its output thrown away (`| head -0`), while
   meaning to read Core files. Neither run had any edits to judge. This was my error and it cost
   budget.
4. SCOPE_VIOLATION, on the finished rule and witnesses: the list of other sessions' `.runtime/tmp`
   files given above. Nothing about my files was reported, so I don't know whether they build or
   pass.

I stopped after run 4 instead of using the last two runs. Each call adds a new file under
`.runtime/tmp`, so a rerun cannot pass the scope check. The harness reruns the gate itself after
the session ends.

## What was written

### Rule (`library/TrafficSpec/Rules/LVMC_11/LVMC_11_20_060_o3.lean`)
- **Subject class (e1):** `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`.
- **Applicability:**
  - **e2:** `asm.business_or_residence_district`.
  - **e11:** there is a region r of kind `roadway` that the subject occupies.
  - **e3:** the subject is emerging onto r from a region d. There is one region quantifier per
    kind the record names: `driveway_or_alley_entrance` (d1) or `alley` (d2). The formula is
    `occ(s,d) ∧ since(occ(s,d), occ(s,d) ∧ ¬occ(s,r))`.
- **Obligation:**
  - **Region selection (rule 3c):** the obligation repeats the whole selection of r: for every
    roadway r with `occ(s,r) ∧ emerging-onto r`.
  - **Road users (e14):** for every road user o with `¬same(o, subject) ∧ ru_aggregate(o, vehicle)
    ∧ occ(o,r)`.
  - **Duty (e12/e13):**
    `¬(kin_speed(s) > p.halt_speed_tolerance ∧ prim_closest_approach_within(s,o;p.conflict_horizon) ∧ prim_closest_approach_distance(s,o;p.conflict_horizon) < p.conflict_centre_clearance) ∧ ¬rel_contact(s,o)`.
- The declarations are the skeleton's. `narrowings := []`.

### Witnesses
- **Layout:** roadway 10 (y ∈ [0,10]) and driveway 20 (or alley 30) south of it. The subject
  comes north out of the driveway. Occupancy is stated in each scene.
- **forbid:** the subject pulls out in front of a car at 10 m/s. Closest approach is about 1.5 m,
  about 1.5 s ahead.
- **permit:** the subject waits halted until the car has passed, then moves.
- **idle:** the subject turns from the roadway into the driveway.
- **blind:** forbid's trace with `rel.occupies` masked.
- **branch_1:** the subject emerges with no other road user present.
- **Extra branches (one per leaf, so no leaf is left vacuous):**
  - branch_2 (violated): the subject is halted and a creeping car touches it (`rel_contact`).
  - branch_3 (compliant): the closest approach is within the horizon but about 9.7 m apart.
  - branch_4 (compliant): a car passes close by but is not on the roadway.
  - branch_5 (compliant): a bicycle on the roadway, which is not in the aggregate.
  - branch_6 (not_applicable): no district.
  - branch_7 (violated): the subject emerges from an alley.

## Choices the node left open

None of substance. One structural choice follows the record: "driveway-or-alley-entrance or
alley region d" is written as two region quantifiers joined by `or`, one per named kind.

## Why I finished

The gate cannot judge these files while its scope check counts the harness's own `.runtime/tmp`
files, including the output file each gate call creates. More runs would only use up budget on
the same infrastructure result. Two of my four runs were also wasted by mistake (runs 2 and 3
above).
