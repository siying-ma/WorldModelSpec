# NRS_484B_587_2b — task result

## Final verdict: OK (15 witnesses, 22 names, composes nothing)

## Gate runs (4 of 6 used)
1. **WITNESS_FAIL** — `permit` and `blind` were unknown for `absent_atom:st_lane_adjacency`. The edge
   lanes had no neighbour on their outer side and no ordinal or count, so `st_lane_left_of` and
   `st_lane_right_of` were unknown there. Fix (witness only): every lane now has its ordinal from the
   left and the count of lanes in its direction (1, 2, 3 of 3).
2. **WITNESS_FAIL (same as run 1)** — I launched this run by mistake, on unchanged files. It used
   one run of the budget and produced no new information.
3. **VACUOUS** — the `dev_regulatory_sign_code … entrance/exit` leaves under "the other lane is
   governed by no such sign" (`dA2`, `dB1`) moved no witness. Fix: I added `branch_10` and
   `branch_11` (both compliant), where the solid white line separates two lanes that are both
   entrance-governed or both exit-governed.
4. **OK**.

## How the rule is written
- Binder class: `ru_aggregate(subject, "DEF-NRS-484A-320::vehicle")`.
- Applicability is the conjunction of four parts:
  - **Moving:** `¬drv_motion_complete_halt(subject; p.halt_speed_tolerance)`.
  - **On a controlled-access highway:** there is a `controlled_access` region `ca` with
    `rel_occupies(subject, ca)`.
  - **No emergency (e1):** not (`sig_hazard`, or `ru_emergency_vehicle` with `sig_warning_lamp` of
    any colour).
  - **Not authorized by subsection 3 (e2/e7/e10/e12–e18):** not (the subject is a listed vehicle and
    it is on a permitted shoulder).
    - Listed vehicle: emergency vehicle; official vehicle of kind incident_management or coroner;
      official vehicle of kind tow that is a motor vehicle; transit bus.
    - Permitted shoulder: the subject occupies a paved `shoulder` that lies on (`st_on_way`) a
      `highway` it occupies, and a `regulatory_sign` of code shoulder_use_permitted governs that
      shoulder with `prim_conditions_hold`.
- Obligation (e6): there are no lanes r1, r2 and side s ∈ {left, right} where all three hold:
  - `drv_lane_entering_adjacent_lane(subject, r1, r2, s)`;
  - the marking on side s of r1 is solid or double_solid, and white;
  - one of r1, r2 is governed by an entrance- or exit-coded regulatory sign and the other is not.
    Each lane gets its own device quantifier.

## Choices the node left open
- "A warning lamp lit": any colour (red, blue, amber or white). This follows the atom's contract and
  narrows nothing.
- The controlled-access region named in e10 is the e5 region the applicability already requires.
  `dev.governs` cannot name a controlled-access region, so the shoulder is tied to the way through
  `st_on_way` and a highway, as e18 and the record's applicability state.
- I declared no narrowings of my own.

## Witnesses
The 10 planned witnesses, plus:
- `branch_7`: an incident-management vehicle on the permitted shoulder (not applicable).
- `branch_8`: an ordinary car from the through lane into an exit lane (violated).
- `branch_9`: hazard lamps flashing (not applicable).
- `branch_10` and `branch_11`: both lanes entrance-governed, or both exit-governed (compliant).

The shoulder witnesses state an occupancy across shoulder, ramp and through lane together. I stated
it explicitly; the vehicle's extent is not built to that width.

## Why I finished
The gate returned OK on run 4.
