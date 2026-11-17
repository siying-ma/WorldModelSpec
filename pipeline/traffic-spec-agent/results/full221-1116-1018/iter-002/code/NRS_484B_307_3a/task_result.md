# NRS_484B_307_3a — task result

**Final verdict: OK** (7 witnesses, 14 names, composes nothing).

## Gate runs
1. `OK`: first run. Nothing changed afterwards.

## How the rule is written
- **Class (s2/s5):** `ru_aggregate subject DEF-NRS-484A-285::traffic` ∧ `ru_aggregate subject DEF-NRS-484A-320::vehicle`.
- **Applicability (s1, s2, s3, s13):** ∃ intersection `i`, ∃ travel_region `c` with `st_lane_enters c i`, ∃ traffic_signal `d` with `dev_governs d c`. The signal `d` shows `circular_green` and one of `green_arrow(left|right|u_turn)`. The subject's approach is `rel_occupies subject c ∨ (rel_occupies subject i since rel_occupies subject c)`.
- **Obligation (s6, s7, s9–s12):** ∀ `i`, `c`, `d`: if the whole selection holds, then for every road user `u` that is not the subject and is either
  - a pedestrian occupying a crosswalk `x` that marks (`st_entrance_of x c2`) some carrier `c2` entering `i`, or
  - a member of traffic occupying `i`,

  it is not the case that `kin_speed subject > p.halt_speed_tolerance` while either:
  - `prim_closest_approach_within(subject,u;p.conflict_horizon)` holds and `prim_closest_approach_distance(subject,u;p.conflict_horizon) < p.conflict_centre_clearance`, or
  - `rel_contact subject u` holds.

## Choices the node left open
- **Choices made:**
  - **Selections:** the obligation holds the duty for **every** selection (i, c, d) of the applicability, using universal quantifiers and an implication. The record says to re-bind but does not name the quantifier. I chose "every" because the duty arises at each selected approach.
  - **Approach condition:** I wrote it as `occ c ∨ (occ i since occ c)`, leaving out the extra `occ i` conjunct. Strong `since` already requires `i` to be occupied whenever `c` is not, so the extra conjunct would be a leaf that changes nothing.
- **Narrowings declared:** none. The formulas do not state any span more narrowly than the record does.

## Witnesses
- The planned `forbid`, `permit`, `idle`, `blind`, `branch_1` and `branch_2` are built.
- `branch_2` triggers the violation only at the instant where the subject is in the intersection through `since`.
- Added `branch_3` (violated) to exercise the `rel_contact` limb: the bodies overlap while the centres are already moving apart, so there is no closest approach ahead.
- In `branch_2` the closest approach at the violating instant is about 0.5 m in about 1.1 s, not the narrative's 1.2 m in 1.0 s. It is still well below the 3 m clearance.

## Session note
- Early on I ran one stray shell command that was not the gate (a directory listing, then an attempted `--help`). The listing ran; the second was denied. Neither changed any file.

## Why I finished
The gate returned `OK` on the first run.
