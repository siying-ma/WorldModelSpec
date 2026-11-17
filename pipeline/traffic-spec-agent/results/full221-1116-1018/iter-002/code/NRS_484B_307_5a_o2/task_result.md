# NRS_484B_307_5a_o2 — task result

**Final verdict: OK** (9 witnesses, 14 names, composes nothing)

## Gate runs

1. **UNUSED_CLAIM** on the untouched skeleton. I ran the gate before editing, which used one run.
2. A second run went through by accident: I piped the gate command into `head -0`. Its output was thrown away, so it told me nothing.
3. **WITNESS_FAIL**, `blind`: the verdict was unknown because of `absent_atom:st_lane_enters`, not because of the masked `st.entrance_of`. The quantifier `existsRegion "travel_region" c2` also ranges over the intersection `i`, since an intersection is a travel region. Core reads `st_lane_enters i i` as unknown because an intersection has no lane record. Once `st_entrance_of` is masked, nothing else decides that conjunct.
   - **Fix:** I added `not (same c2 i)` and, in the facing clause, `not (same c i)`. The contracts of `st.lane_enters` and `st.entrance_of` say an intersection is never a carrier and never enters itself, so this removes no carrier the contracts allow.
4. **OK**.

## The rule

- **Class:** `ru_aggregate subject DEF-NRS-484A-285::traffic` ∧ `ru_aggregate subject DEF-NRS-484A-320::vehicle`.
- **Applicability:** some traffic-signal head `s` and some intersection `i` such that:
  - `facing s i` holds: `since (rel_occupies subject i) (∃ travel_region c ≠ i. rel_occupies subject c ∧ st_lane_enters c i ∧ dev_governs s c)`. This covers both limbs: the subject is on the approach now, or it is in `i` and has been at every observation since it was on one.
  - `arrowAlone s` holds.
- **Obligation:** for every head `s` and intersection `i` with `facing s i ∧ arrowAlone s`, and every road user `p`:
  - **if** `p` ≠ subject, `p` is in the vehicle or the pedestrian aggregate, `inZone p i` holds now, and `since arrowAlone (rises arrowAlone ∧ inZone p i)` holds (so `p` was in the zone at the latest onset of the arrow alone),
  - **then** it is not the case that (speed > `p.halt_speed_tolerance` ∧ `prim_closest_approach_within` ∧ closest-approach distance < `p.conflict_centre_clearance`), and there is no `rel_contact subject p`.
- **`inZone p i`:** `rel_occupies p i`, or `p` occupies a crosswalk `w` with `st_entrance_of w c2 ∧ st_lane_enters c2 i` for some travel region `c2 ≠ i`.

## Choices the node left open

- **"Arrow alone":** the head shows `green_arrow(straight)` and none of the 21 other display states. For the `unknown` display state, "alone" is undefined (`definedWhen (not shows unknown) tt`) rather than decided either way: a lamp the source could not read can neither confirm nor deny that the arrow is alone.
- **"At the time the signal is exhibited":** I used `since` on the arrow-alone display, anchored on its latest `rises`. This picks the latest onset with no window length, and it is decided wherever the trace starts with the arrow off.
- **Re-selection in the obligation (rule 3c):** the obligation repeats the whole selection of `s` and `i`, i.e. `facing` and `arrowAlone`, and states the duty for every head and intersection so selected.
- **Narrowings:** none declared.

## Witnesses

`forbid`, `permit`, `idle`, `blind` (masks `st.entrance_of`) and `branch_1` follow the node's narratives. I added four branches so that every leaf is exercised:

- **`branch_2` (violated):** the subject enters `i` after the arrow and closes on a car stalled in `i`. This exercises the "faces from inside `i`" limb, a vehicle as `p`, and `p` occupying `i`.
- **`branch_3` (compliant):** the subject stays halted while a car in `i` passes close by. This exercises the speed bound and contact.
- **`branch_4` (not applicable):** circular green and the arrow are shown together, so the arrow is not alone.
- **`branch_5` (violated):** the arrow becomes the only display one step after appearing with circular green, and the pedestrian is in the crosswalk at that later instant. This exercises "alone" inside the time-of-exhibition clause.

## Note for the harness

Core gives `st_lane_enters` as unknown on any region without a lane record, intersections included, where the contract would make it false for a non-carrier. Any rule that quantifies carriers over `travel_region` will meet this. Here it is handled in the formula with `not (same c i)`.

## Why I finished

The gate returned OK.
