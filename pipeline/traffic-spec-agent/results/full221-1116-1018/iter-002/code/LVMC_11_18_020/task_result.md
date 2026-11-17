# LVMC_11_18_020 — task result

**Final verdict: OK** (10 witnesses, 20 names, composes nothing).

## Gate runs (3 of 6 used)
1. **UNUSED_CLAIM** — run by mistake on the untouched harness skeleton (all formulas `.tt`), before any edit. Nothing changed on account of it.
   (An extra `--help` invocation was attempted and denied by the shell; it did not run the gate.)
2. **WITNESS_FAIL** — forbid and branch_2…6 gave compliant instead of violated. Cause: `Build.scene` derived occupancy from the reference point alone, so at the instant the subject entered the crosswalk it no longer occupied its approach lane, and applicability failed there. Fix: occupancy is now stated explicitly from the bodies' footprints (subject in highway + lane 11, + crosswalk once entered, + one-way roadway where present; person in highway + crosswalk).
3. **OK**.

## How the rule is written
- Class: `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`.
- Applicability: ∃ travel_region c, ∃ intersection j with `rel_occupies(subject,c)` ∧ `st_lane_enters(c,j)`; ∃ zone_sign d with `dev_zone_sign_kind(d, school_crossing)` ∧ `dev_governs(d,c)`; ∃ crosswalk cw with `st_entrance_of(cw,c)`; ∃ road user o ≠ subject, of class pedestrian / bicycle / electric_bicycle / electric_scooter, with `rel_occupies(o,cw)`, on the subject's side: the subject occupies a one_way_roadway, or ∃ highway w with `st_on_way(cw,w)` and ∃ centre_line cl with `st_on_way(cl,w)` and, with L = `prim_region_lateral_offset(subject,cl)` and y = `rel_bearing(subject,o).y`, (L > 0 ∧ y < L) ∨ (L < 0 ∧ y > L).
- Obligation: for every (c, j, d, cw) with the whole selection above restated, `¬ rises(rel_occupies(subject, cw))`.

## Choices the node left open
None that the record did not fix. The obligation is applied to every crosswalk the selection picks out, which is what the record's "re-bound with the same selection" asks for. I declared no narrowings.

## Witnesses
The node planned forbid, permit, idle, blind (masks `dev.governs`) and branch_1 (person on the far side of the centre line, not_applicable). I added these so that every part of the formula is tested:
- branch_2: one-way roadway, person on the far side (violated).
- branch_3: subject's lane left of the centre line, L < 0 (violated).
- branch_4/5/6: the person is a bicycle, electric bicycle or electric scooter rider (violated).

## Why I finished
The gate returned OK.
