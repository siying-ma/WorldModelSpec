# NRS_484B_507_1 — task result

## Final verdict
**OK** (gate run 1 of 6): 18 witnesses, 27 names, composes nothing; 1 coder narrowing.

## Gate runs
1. `OK` on the first submission. Nothing was changed after it.

(One stray shell call that combined the gate with `--help` and an `ls` was denied by the
permission layer before it ran. It produced no gate verdict and changed nothing.)

## How the rule is written
- **Subject class:** `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`.
- **Applicability (s5, s6):** there is a `curb_zone` z with `rel_occupies subject z`,
  `st_curb_zone_kind z freight_loading`, and the provisions are in effect. "In effect" means every
  `zone_sign` of kind `parking_restricted` that `dev_governs` a `travel_region` the subject occupies
  has `prim_conditions_hold zs subject`. Where no such sign exists, the zone is in effect at all hours.
- **Obligation:** for every curb zone z picked out by the same selection, `complete_halt(subject) →`
  one of these holds:
  - (a) a road user ahead in the lane (`rel_ahead_behind_in_lane y subject`) with
    `rel_surface_gap ≤ p.queue_halt_gap`;
  - (b) an occupied travel region governed by a stop sign, a yield sign, a signal showing circular
    red, circular yellow or flashing red, a railway signal whose lights are flashing or whose gate is
    not `up`, or a police officer indicating stop;
  - (c) the subject is a truck or a CMV, is not `parked` over `p.commercial_loading_max_halt`, and has
    a door open during the halt;
  - (d) the subject is not `parked` over `p.standing_min_duration`, has a door open during the halt,
    and has not interfered with a waiting goods vehicle. That means
    `not (since halt (halt ∧ ∃w ≠ subject: motor_vehicle aggregate ∧ truck ∧ ¬occupies w z ∧ halt w ∧ st_region_geometry_distance w z ≤ p.zone_entry_wait_reach))`.
- **"A door open at some observation of the same halt, before or after":**
  `since halt (halt ∧ door) ∨ until halt (halt ∧ door)`.

## Choices the node left open
- **Narrowing on s1 (`kind := "reading"`):** I read "a traffic signal displaying a red or yellow
  indication or flashing_red" as `circular_red`, `circular_yellow` and `flashing_red`. Red and yellow
  arrows are left out, because an arrow controls only the movement it points to.
- **"Gate not up":** written literally as `not (gate = up)`. As a result, gate state `none` (no gate)
  also counts as "not up", so a crossing signal with no gate excuses a halt even when its lights are
  dark. That is the record's wording. The plan agent may want to restrict it to
  lowering, down or raising.

## Witnesses (beyond the six planned)
- `branch_3`: queue ahead.
- `branch_4` to `branch_9`: stop sign, yield sign, red signal, railway lights flashing, railway gate
  down, police officer stop.
- `branch_10`: zone sign outside its hours, not applicable.
- `branch_11`: commercial motor vehicle loading.
- `branch_12`: truck stands past the 1800 s limit, violated.
- `branch_13`: the stop interfered with a truck earlier in the halt, after which the truck left.
  This shows the `since` memory.
- `branch_14`: several zone signs. This exercises the s6 leaves inside both the applicability and
  the obligation's re-selection.

In `branch_2` and `permit`, the door opens only partway through the halt, so both the `since` and
the `until` branches of the door test decide some of the instants.

## Why I finished
The gate returned OK, and the node's mapping covered every span without a defect I needed to report.
