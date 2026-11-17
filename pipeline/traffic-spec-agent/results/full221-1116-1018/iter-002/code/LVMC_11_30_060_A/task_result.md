# LVMC_11_30_060_A — task result

## Final verdict: VACUOUS (node defect, f4 `kin.speed` against the f2 applicability)

## Gate runs
1. **UNUSED_CLAIM** — this run was on the untouched skeleton (every formula still `.tt`). It was a wasted run.
2. **VACUOUS**, obligation leaf 7 (`kin_speed(subject) > p.halt_speed_tolerance`) and leaf 9
   (`prim_closest_approach_distance < p.conflict_centre_clearance`). Everything else passed: build,
   checks, anchoring and all 8 witnesses (forbid, permit, idle, blind, branch_1…branch_4).
   - Change made: added `branch_5` (compliant). A car passes behind the pedestrian. Their centres
     approach within the horizon (about 2 s) but stay about 4.3 m apart, so the distance leaf is
     exercised on its own.
3. **VACUOUS**, obligation leaf 7 only. Leaf 7 can't be exercised (explained below), so I stopped
   with 3 of the 6 runs used.

## How the rule is written
- Class: `ru_aggregate subject DEF-NRS-484A-165::pedestrian`.
- Applicability: there is a roadway r that the subject occupies and crosses. "Crosses" means the
  subject is `moving_across_carrier` either a lane k it occupies or the roadway r itself, with
  speed_tol = `p.halt_speed_tolerance` and cos_max = `p.crossing_motion_cos`. No
  `pedestrians_prohibited` regulatory sign governs r. The subject also occupies no crosswalk.
- Obligation: for every roadway r chosen by the record's selection again (occupied and crossed),
  and for every vehicle-aggregate member v that occupies r:
  - the subject is not in `rel_contact` with v, **and**
  - it is not the case that the subject's speed is above `p.halt_speed_tolerance` while
    `closest_approach_within(subject, v, p.conflict_horizon)` holds and
    `closest_approach_distance < p.conflict_centre_clearance`.

## Choices the node left open
- **Re-selecting r in the obligation:** I used exactly the record's words ("the roadway the
  subject occupies and crosses"). The f8 sign condition is not repeated there.
- **Lane or roadway as the carrier:** written as a disjunction, as the record states. `branch_2`
  (an unlaned roadway) exercises the roadway branch, and `forbid` (a roadway with no direction of
  its own) exercises the lane branch.
- **Narrowings:** none.

## Why the node is wrong (what the plan agent must change)
**Spans f4 and f2.** f4 puts `kin.speed` into the obligation: the subject is "moving (kin.speed
above p.halt_speed_tolerance)" while a conflict is projected. But the f2 trigger already requires
`drv.motion.moving_across_carrier` with speed_tol = `p.halt_speed_tolerance`. By that concept's
contract, it needs kin.speed above speed_tol, at the same observation.

So wherever the rule applies, the speed conjunct is already true. No scene can make it false while
the rule applies, and the gate correctly reports it as vacuous. The node's own `branch_1`
narrative ("halts in the lane … then walks on") shows the intended reading: a halted pedestrian
yields. But under this applicability a halted pedestrian is simply outside the rule
(not applicable), never compliant because it halted.

The plan must do one of these:
- **(a)** Drop `kin.speed` from f4. "Shall yield" would then read as not being in a projected
  conflict or in contact while crossing; the halting reading is carried by the trigger.
- **(b)** Rewrite f2 so the rule also applies to a pedestrian who is still crossing but has halted
  on the roadway. For example, `rel.occupies` the roadway, with crossing motion observed in a
  window behind (that needs a temporal operator and a window parameter). Then the obligation's
  speed test can tell halting apart from walking on.

## Why I finished
All other checks pass. The only remaining verdict is caused by the node's own mapping (f4's
`kin.speed` is implied by f2's claimed concept). The procedure says to report this, not to delete
the atom.
