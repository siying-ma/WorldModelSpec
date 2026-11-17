# NRS_484B_283_1d4_o2 — task result

## Final verdict: OK

The last gate run returned `OK` with 9 witnesses and 13 names. It composes NRS_484B_287_1c/1d/1e,
LVMC_11_30_060_A/B, LVMC_11_30_140_B_o1/o2 and LVMC_11_46_030_o1/o2. After that run I changed
only a header comment in the witness file. No formula and no scene changed.

## Gate runs

1. **UNUSED_CLAIM** (this run was on the untouched skeleton by mistake, so it used one run of the
   budget). After it, I wrote the rule and witnesses in full.
2. **WITNESS_FAIL**: the roadway witnesses (forbid, permit, blind, branch_1) came back unknown on
   `absent_atom:st_lane_direction`. My rule does not read that atom; one of the composed exception
   rules does. Fix: region 100 now has `lane := some { direction := some Build.east }`.
3. **WITNESS_FAIL**: forbid, permit and branch_1 came back not_applicable. One of the composed
   exceptions applied to a pedestrian crossing a roadway outside a crosswalk; the lane variants
   were unaffected. Fix: a marked crosswalk (region 300) now lies across the roadway in the
   roadway variants, and the pedestrian crosses inside it. This fits the narrative (a crossing
   controlled by a pedestrian signal).
4. **OK**.

## How the spans are written (also in the rule's header)

- **s2**: `ru_aggregate subject "DEF-NRS-484A-165::pedestrian"`.
- **r**: nine `.not (.ruleApplies …)` exceptions. The two LVMC_11_46_030 rules use the map
  `subject ↦ v` and are wrapped as `.not (.existsUser "v" …)`.
- **c0 / t**: some `pedestrian_signal` device `d` shows `dont_walk_steady` here and governs
  (`dev_governs`) a region `r`. There is one `existsRegion` for kind `roadway` and one for kind
  `lane`, with the same body under each.
- **e1 (ref2) / e2**: `since (occupies r) lawfulStep`. Here `lawfulStep` means: the subject is on
  `r`; it stops overlapping every sidewalk at that observation (`rises (not ∃ sidewalk occupied)`);
  `d` shows `walk`, or `dont_walk_flashing` with the countdown on; and the subject faces `d`
  (h·Δ > 0, (h·Δ)² ≥ cos²·|Δ|², |Δ|² ≤ reach²). `since` and `rises` look back with no other limit.
  If the search reaches the start of the recording without finding the step, the result is unknown.
- **ob2 / st**: `kin_speed subject ≥ p.pedestrian_clearing_speed_min`.

## Choices the node left open

- **The moment of "the step from a sidewalk onto r"**: the latest observation at which the
  footprint is on `r` and stops overlapping every sidewalk, with the footprint on `r` at every
  observation since. This is how I read the record's "latest step from a sidewalk onto r". It is
  not a narrowing, because e1 is a condition span and condition spans cannot be narrowed.
- **"roadway or lane"**: written as two region quantifiers with the same body, so the record's
  kinds are kept exactly.
- **Obligation**: speed only, as the record states. It is judged where the applicability holds,
  which already puts the subject on `r`, so `r` is not selected again.
- **Narrowings**: none of my own. The record's two narrowings (on ob2 and st) are the plan's and
  are not restated.

## Extra witnesses added for adequacy

- **branch_1** (violated): the pedestrian entered during `dont_walk_flashing` with the countdown on.
- **branch_2** (violated): same as forbid, but the region is a lane.
- **branch_3** (violated): same as branch_1, on a lane.
- **branch_4** (not_applicable): the pedestrian entered during `dont_walk_flashing` with no
  countdown, which is not a lawful entry under (1) or (2).

## Observation for the plan (not a defect of this node)

- The composed exceptions decide these scenes only if the roadway has a lane direction and the
  crossing is inside a crosswalk. Without them, they are unknown (no lane direction) or they apply
  (no crosswalk). Any later witness of a sibling node that crosses a roadway will need the same
  scenery.

## Why I finished

The gate returned OK, and the files are complete.
