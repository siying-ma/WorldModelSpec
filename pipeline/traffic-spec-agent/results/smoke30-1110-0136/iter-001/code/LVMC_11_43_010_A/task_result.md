# LVMC_11_43_010_A — task result

## Final verdict

**OK** (gate run 1 of 6): "6 witnesses, 5 names, composes nothing".

## Gate runs

1. `OK` — first run, after writing both files in one pass. Nothing changed afterwards.

## The rule

- Class of `x`: `ru_aggregate x "DEF-NRS-484A-320::vehicle"` (s2, s4 'vehicular').
- Applicability: `drv_motion_moving x [p.motion_speed_tolerance]` (s4 'travel') ∧
  `existsRegion "roundabout" r (rel_occupies x r)` (s3).
- Obligation: `forallRegion "roundabout" r (rel_occupies x r → ¬ drv_motion_clockwise_about_region x r [p.motion_speed_tolerance])` (s5).
  The obligation repeats the applicability's full selection of the roundabout (kind plus
  occupancy), and quantifies over every selected roundabout, as the record states.

## Choices the node left open

None. The record states the applicability and obligation in full, and its own narrowings cover
the readings of s2 (agency) and s5 (counterclockwise read as "no clockwise motion about the
reference point"). I declared no narrowing of my own. `zeroMetres` from the skeleton is left
unused.

## Witnesses

Roundabout region 10 is a 60 m square centred on the origin, with its reference point at (0, 0).
The car is track 1 (`.motorVehicle`).
- forbid: the car is at x = 15 m heading south at 8 m/s. That is clockwise, with a cross product of −120.
- permit: the same spot, heading north at 8 m/s. That is counterclockwise.
- idle: the car is on a straight roadway (region 20) and no roundabout exists, so the applicability is decided false.
- blind: the same scene as forbid, with `st.region_geometry` masked, so the clockwise concept is unknown.
- branch_1: the car comes up the south approach on x = 0 toward the island at 4 m/s. The cross product is zero, so it is compliant.
- branch_2: the car stands at (15, 0) with speed zero, so it is not moving and the rule does not apply.

## Process note

Before the gate run I ran one shell command that was not allowed, a no-op `echo skip`, by mistake.
It changed nothing. The only other shell command was the gate.

## Why I finished

The gate returned `OK` on the first run.
