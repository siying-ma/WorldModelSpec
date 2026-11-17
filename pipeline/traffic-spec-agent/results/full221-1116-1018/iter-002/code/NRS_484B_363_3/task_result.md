# NRS_484B_363_3 — task result

**Final verdict: OK** (19 witnesses, 16 names, composes nothing).

## Gate runs
1. **WITNESS_FAIL** — every U-turn trace showed a yaw rate (30 deg/s) while its heading vector did not
   change: the adapter holds the rate at a scene over the interval *before* it, and my headings lagged
   by one scene (and used approximate 30° unit vectors). Fix: the turn is now two scenes at 90 deg/s
   (12 s: heading north, still in the eastbound lane; 13 s: heading west, in the westbound lane),
   recognised at 14 s. Headings are exactly axis-aligned. The permit vehicle jogs +90/−90 deg/s
   instead of wobbling ±5 deg/s. The "first / later turning observation" splits of the occasion
   witnesses moved to 12 s / 13 s.
2. **OK**.

## How the rule is written
- Class: `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`.
- Obligation (s2): `¬ drv_motion_u_turn(subject; p.vehicle_turn_window, p.u_turn_heading_min, p.turn_yaw_rate_tol)`.
- Occasion (window boundary): U = `|kin_yaw_rate subject| > p.turn_yaw_rate_tol`, W = `p.vehicle_turn_window`.
  - `some_moment φ` = `¬ holdsFor W (¬ (U ∧ φ))`.
  - `throughout φ` = `holdsFor W (U → φ)`.
- Applicability: ∃ zone_sign z, ∃ travel_region r:
  - s3, read `some_moment`: z is of kind school or school_crossing, not an end sign, governs r, and the subject occupies r.
  - Then ¬throughout for each exception:
    - (a) s5: no ru_child within `p.pedestrian_near_reach` (`st_region_geometry_distance`) of a travel region that z governs.
    - (b) s6: ¬asm.school_in_session_day.
    - (c) s7: asm.school_outside_operation_margin.
    - (d) s8–s10: some beacon governs r and is not inoperative, ∧ asm.pupils_in_class, ∧ no beacon that governs r and is operational is flashing.
    - (e) s11–s12: no operational beacon governs r, ∧ ¬prim_conditions_hold(z, subject).

## Choices the node left open
- **The U-turn is in the obligation only, not also in the applicability.** If the applicability also required the recognised U-turn, the planned `permit` witness (no U-turn, expected compliant) could only come out not applicable. So the applicability holds wherever the turning stretch in the window behind lies in the zone and no exception holds. At the recognition the duty is then broken; at the other turning observations it is kept.
- **(b) and (c) are also read `throughout`.** The occasion's `spans` list does not include s6 and s7, but the record's applicability says each exception excuses the act only where it holds at every observation while the act is under way. The witnesses' declarations are constant, so this choice is not tested by them.
- **No narrowing is declared.** Both choices above follow the record's own words.

## Witnesses
- Each witness judges 11–29 s, so every 10 s window behind is covered and no instant is unknown from truncation.
- Region and device quantifiers range over a sign and lanes that are present in every scene.
- `idle` uses a speed_zone sign, so the zone-kind atom is decided false rather than left unobserved.

## Process note
- Early in the session I ran one shell command that was not the gate: a bare `echo` with no
  arguments, issued by mistake. It read and changed nothing. Apart from that, the shell ran only the
  gate command, twice.

## Why I finished
The gate returned OK on the second run.
