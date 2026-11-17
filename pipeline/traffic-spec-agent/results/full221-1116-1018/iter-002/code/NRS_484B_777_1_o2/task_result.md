# NRS_484B_777_1_o2 — task result

**Final verdict: OK** (9 witnesses, 10 names, composes nothing)

## Gate runs
1. `UNUSED_CLAIM`: this ran by mistake on the harness skeleton before I had edited anything.
   Every claim was reported unused, as expected.
2. (Possibly counted.) I issued the gate command piped to `head -0`, which printed nothing. It
   may have used up a run; its verdict was not seen.
3. `WITNESS_FAIL` (blind came back violated). Masking `rel.surface_gap` drops only a measured
   gap. Core still computes the gap from the two footprints, so the 0.4 m gap decided the
   verdict. Fix: in blind, the car's extent is unobserved, so Core cannot compute the gap. The
   overlap along the bicycle's heading and `contact = false` are supplied as measured relations,
   which Core cannot compute without the car's body either.
4. `WITNESS_FAIL` (admission): track 2 was in `occupancyObserved` but had no footprint. Fix:
   blind marks occupancy observed for the bicycle only.
5. `OK`.

## How the node is written
- **s1 (binder class):** the three `ru_aggregate` atoms on the subject, joined by `or`.
- **s11 (trigger):** `existsUser b`, with these conditions:
  - b is not the subject;
  - `ru_aggregate b DEF-NRS-484A-320::vehicle`;
  - `drv_interaction_overtake_pass(subject, b)` with p.overtake_window and p.overtake_same_direction_cos.
- **s2 (condition):** `existsRegion roadway r (rel_occupies subject r)`. It is read "at some
  observation since the act began" as `since (not actStart) onRoadway`.
- **s10 (operationalization):** for every b the applicability selects, `since careHere actStart`.
  At every observation after the act's start up to the recognition where
  `rel_longitudinal_overlap ≥ 0`, the rule requires:
  - not `rel_contact`;
  - lateral `rel_surface_gap ≥ p.door_swing_reach` where `drv_motion_complete_halt(b)` holds (p.halt_speed_tolerance);
  - lateral `rel_surface_gap ≥ p.bicycle_pass_safe_gap` where `kin_speed b > p.halt_speed_tolerance` and `rel_same_direction(subject, b)`.

  The obligation repeats the applicability's whole selection of b (it is a `forallUser`
  implication).

## Choices the node left open
- **Where the act begins.** The record says the act begins at the last observation of the
  window behind at which b was ahead with headings aligned. Telling "ahead" from "behind" needs
  the bearing, which the node does not claim. I wrote `actStart` with the claimed atoms as:
  - `rel_longitudinal_overlap < 0` (b clear along the heading),
  - `rel_same_direction`,
  - `not overtake_pass` (this drops the recognition itself, where b is clear behind).

  Between the start and the recognition b is not behind the subject, so the latest such
  observation is the start. I treated this as writing the record's boundary, not as a narrower
  reading, so I declared **no narrowing**. It is explained in the rule's header.
- **Where the clearance is selected.** The record puts "standing" and "proceeding in the same
  direction" in the obligation's clearance selection, so I wrote them as two implications
  (at rest → door reach; moving and aligned → pass gap). A b that is moving but not aligned
  while alongside is held only to no contact. Both parameters are 1.0 m in this run, so the
  selection matters only through the moving-and-aligned guard.
- **Extra witness `branch_5` (violated):** a moving car passed with a 0.5 m gap and no contact.
  It exercises the `kin_speed` and `rel_same_direction` guards, which no planned scene decides.
- **Witness window:** every witness judges the instants 10–14 s, where the 10 s overtake window
  behind is covered.

## Why I finished
The gate returned OK on both files.
