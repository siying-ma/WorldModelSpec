# NRS_484B_363_3 — task result

## Final verdict

`UNUSED_CLAIM prim_heading_change`. The node is wrong in span d2: see below. Everything else
passes: with a temporary always-true use of `prim_heading_change` (now removed) the gate returned
`OK` (26 witnesses, 16 names).

## Gate runs (5 of 6 used)

1. `UNUSED_CLAIM` (every claimed name). I ran this by mistake on the untouched skeleton.
2. `UNUSED_CLAIM prim_heading_change`. This was the first full rule and witness set.
3. `WITNESS_FAIL` (every witness). This run had the temporary probe in. The adapter refused the
   traces: the heading at a scene must be the previous heading turned by that scene's yaw rate,
   held over the interval before it. My first witnesses yawed 36 °/s with headings that did not
   follow.
   - Change: I rebuilt the motion so it is consistent. Yaw is 90 °/s at 27 s and 28 s, so the
     heading goes east, north, west.
   - Each position is the previous one plus the scene's velocity.
   - Occupancy is computed from each body's footprint box.
   - A child that moves does so with a matching velocity.
4. `OK` with the probe. The probe was `|prim_heading_change x W| ≥ 0°`, conjoined into the
   applicability only to find out whether the rest of the rule and witnesses pass.
5. `UNUSED_CLAIM prim_heading_change` on the final files, after I removed the probe. The probe
   always holds wherever it is decided. It is padding, not the law's meaning, so I did not leave
   it in to get an `OK`.

## The node defect (span d2)

The d2 element claims `atoms: ["prim.heading_change"]` and `derived: ["drv.motion.u_turn"]`. The
accepted concept `drv.motion.u_turn` already reads the heading change: its contract says it is
"the absolute value of x's signed heading change over the window behind it (prim.heading_change
with window …)", and it reads `kin.yaw_rate`. The rule states the U-turn through that concept
(`rises (drv_motion_u_turn x (p.u_turn_window, p.u_turn_reversal_tolerance))`). Nothing in the
node's words needs the heading change outside the concept.

A direct use of `prim_heading_change` in the rule would do one of two things:
- Restate the concept's body, which also needs a half-turn literal (180°) that the node does not
  declare.
- Add a vacuous conjunct, like the probe.

The gate does not count the concept's own reading as the rule's use of the claim. So the claim
cannot be met honestly.

**What the plan must change:** remove `prim.heading_change` from the atoms of the d2 element. The
element would keep `derived: ["drv.motion.u_turn"]` with an empty atom list, or name only what
the concept denotes. With that change, the files as they stand should pass: the run-4 `OK`
differed from them only by the probe conjunct.

**Note on the gate:** it did not report the always-true probe conjunct as `VACUOUS` (run 4).

## How the rule is written (choices the node left open)

- **Act and occasion.** The rule judges the U-turn once, at `rises drv_motion_u_turn`. The act's
  observations are those within `p.u_turn_window` behind the recognition at which
  `drv_motion_yawing x p.yaw_rate_resolution` holds.
  - d3 is read `some_moment`, as `¬holdsFor W x ¬(U ∧ φ)`.
  - d5, d8, d10, d12 and d13 are read `throughout`, as `holdsFor W x (U → φ)`.
  - Each exception (a)–(e) is read throughout on its own, and the obligation is their
    disjunction.
- **d3 zone.** z is a `zone_sign` device of kind school or school_crossing that is not an end
  sign. It must govern a travel region r that x occupies at some yawing observation of the act.
- **One zone across formulas (rule 3c).** The obligation repeats z's whole selection and requires
  the exceptions for every selected sign (`forallDevice zone_sign z (selection → exceptions)`).
  With one zone, which is the record's case, this is the same as the record. With several, the
  duty is held for each. I chose this because the record speaks of "the" zone x turned in. If the
  plan meant "some selected zone", it should say so.
- **The exceptions:**
  - (a): no `ru_child` road user within `p.child_presence_reach` (`st_region_geometry_distance`)
    of a travel region z governs.
  - (b): `asm.school_not_in_session_day`.
  - (c): `asm.outside_school_operation_margin`.
  - (d): a `speed_limit_beacon` b governs a travel region that x occupies or z governs, b is not
    flashing, and `asm.pupils_in_class` holds.
  - (e): no beacon governs such a region, and `prim_conditions_hold z x` is false.
- I declared no narrowings of my own.
- **Witnesses.** There are the 17 planned witnesses plus `branch_2` to `branch_10`, so that every
  leaf moves a decided witness:
  - exception (c);
  - an end sign;
  - a non-school zone;
  - x a bicycle, which is not a vehicle;
  - an adult instead of a child;
  - pupils not in class;
  - a second sign that is not selected: an end sign, a speed zone, and a school sign off x's path.

  Every witness speaks of 21–35 s, so the 20 s windows are covered.

## Why I finished

The only remaining verdict, `UNUSED_CLAIM prim_heading_change`, comes from the node's mapping of
d2, not from the files. The task's procedure says to report such a mismatch, not to work around
it. I fixed the rule against the node once, and the verdict persisted.
