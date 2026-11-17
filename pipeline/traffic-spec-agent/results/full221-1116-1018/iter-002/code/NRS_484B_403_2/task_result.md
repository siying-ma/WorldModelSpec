# NRS_484B_403_2 — task result

**Final verdict: OK** (9 witnesses, 13 names, composes nothing).

## Gate runs
1. **WITNESS_FAIL**: every trace was rejected as one the adapter cannot produce. The yaw rate at a scene
   is held over the interval before it, and the scene's heading must match. My turns were 30 deg/s
   while the headings jumped between compass points.
   *Change:* I rebuilt every turn so headings stay exact on the compass points. A U-turn is 90 deg/s,
   then a 0 deg/s pause, then 90 deg/s again (180° in total), then 0 deg/s.
2. **OK**.

(Before run 1 I accidentally issued one stray `echo` shell call. It ran but did nothing; it was not
a gate run.)

## How the rule is written
- Class: `ru_aggregate(subject, "DEF-NRS-484A-320::vehicle")`.
- Occasion: boundary is "window" and s1 is read `some_moment`. The applicability is
  `¬ holdsFor time p.vehicle_turn_window subject ¬(U ∧ φ)`, where:
  - U is `|kin_yaw_rate(subject)| > p.turn_yaw_rate_tol`.
  - φ is the s1 element. There is a `regulatory_sign` d with code `no_u_turn`, and
    `prim_conditions_hold(d, subject)` holds. Then either:
    - (a) d governs a `travel_region` r that the subject occupies; or
    - (b) the subject occupies an `intersection` i, d governs a `lane` l with `st_lane_enters(l, i)`,
      and `since(occupies i, occupies l)` holds.
- Obligation: `¬ drv_motion_u_turn(subject; p.vehicle_turn_window, p.u_turn_heading_min, p.turn_yaw_rate_tol)`.
- I added no narrowings of my own. The record's own narrowings (`official`, `driver`, and the s3
  reading) are not restated.

## Choices the node left open
- **"having occupied l at the observation before it entered that intersection"** is written as
  `.since (rel_occupies subject i) (rel_occupies subject l)`. This means the subject occupied l at
  some observation and has occupied i at every observation since: it came into i from l. An
  observation where the subject straddles both l and i counts as occupying l.
- **`permit` narrative:** the plan's text says "drives straight through the intersection". If the
  heading never turns, U is never true, so the occasion is not met and the rule is not applicable
  rather than compliant. I built `permit` as a 90° left turn out of the governed lane instead. U is
  then true under the sign, but the heading change is outside the reversal band, so no U-turn is
  recognized and the verdict is compliant. **The plan may want to reword this narrative.**

## Branch witnesses I added
- `branch_2` (violated): the subject drives straight from the governed approach lane into the
  intersection and makes the whole U-turn inside it. This exercises limb (b) on its own: the
  intersection, the lane entering it, and the entry via `since`.
- `branch_3` (not_applicable): as `forbid`, but the sign's code is `no_left_turn`. This exercises
  the code literal.
- `idle`: the sign governs a lane that enters the same intersection from the east, but the subject
  came from an ungoverned lane, so `since` is decided false.

## Why I finished
The gate returned OK on run 2.
