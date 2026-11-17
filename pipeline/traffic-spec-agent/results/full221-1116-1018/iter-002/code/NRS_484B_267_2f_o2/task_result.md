# NRS_484B_267_2f_o2 — task result

## Final verdict

`WITNESS_FAIL` — `forbid: expected violated, got compliant`. The node itself is wrong: its
obligation can't be written (see below). I ended the session instead of making up a duty.

## Gate runs (3 of 6 used)

1. `UNUSED_CLAIM` (every claimed name). This ran on the untouched skeleton by mistake: I meant to
   read a Core file and invoked the gate instead.
2. `UNUSED_CLAIM`, the same mistake repeated on the unchanged skeleton.
3. `WITNESS_FAIL` (`forbid` came out compliant, not violated). This ran after I wrote the
   applicability, the class, and six witnesses (`forbid`, `permit`, `idle`, `blind`, `branch_1`,
   `branch_2`). The build, the static check (`CHECK_FAIL`), the claim checks (`UNCLAIMED_ATOM` /
   `UNUSED_CLAIM`), the anchoring check (`UNANCHORED_VARIABLE`) and the literal check
   (`BARE_LITERAL`) all passed. Only `forbid` failed, as expected.

## What is written

- **Subject's class:** `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`.
- **Applicability:** some road user `e` satisfies all of the following:
  - it is not the subject;
  - it is a member of DEF-NRS-484A-020::authorized_emergency_vehicle, or an `ru_official_vehicle`
    of kind `regulatory_agency`;
  - it shows a red flashing warning lamp now;
  - `drv_motion_complete_halt(e, p.halt_speed_tolerance)` holds now, and has held `since` the
    last observation at which the trigger held.

  The trigger is: the lamp is lit; `e` is moving (`kin_speed > p.halt_speed_tolerance`) or
  preparing to move (`rel_visible subject e` together with a hand signal other than `no_signal` or
  a turn indicator other than `off`); and the subject is moving, has `e` "ahead" by `rel_bearing`,
  and is within `p.emergency_approach_reach` by `rel_centre_distance`.

  The whole is excluded where a `human_direction` device with role `police_officer` governs a
  `travel_region` the subject occupies.
- **Obligation:** `.tt`. The record says the obligation is "Not expressible … no formula is
  written for it and the duty is not weakened to a weaker one".
- **Narrowings:** none chosen.

## Why the node is wrong (for the plan agent)

1. **s11 / s11r — the obligation has no content, yet the planned witnesses need one.** All the
   duty says is "proceed as required pursuant to NRS 484B.607". The node keeps that law as a
   residue (outside the corpus) and states the obligation is not expressible. Even so, it plans:
   - `forbid` (violated): "drives past it in the adjacent lane without slowing or moving over";
   - `permit` (compliant): "slows and moves to a lane not adjacent".

   Telling these apart *is* the content of NRS 484B.607. The node neither states it nor claims the
   atoms it would need (lane adjacency, occupancy of the halted vehicle's adjacent lane, a speed
   bound). The only obligation claim is `kin.speed` ("proceed"). Writing that as "keeps moving"
   would be the weakened duty the record forbids, and would also fail `forbid`. So no obligation
   meets both the record and the witnesses.

   **The plan must choose one of these:**
   - (a) Withdraw the node. If the whole duty is a residue, there is no rule to write.
   - (b) Bring NRS 484B.607 into the corpus. Then write s11/s11r as a `compliance` composition
     (`.rule "<NRS_484B_607 node>" map`), and drop the `forbid`/`permit` narratives that assume
     its content without it.
   - (c) Keep the node, but plan witnesses that match an empty obligation: no `forbid`, and
     `permit` merely compliant.
2. **s3 / s4 — "visible from the front" can't be read.** The borrowed words fix a lamp lit red,
   flashing, **facing front**. The only formula atom for it, `sig_warning_lamp`
   (`Core/Language/Semantics.lean` `evalAtomE`), accepts colour and mode only. Nothing in the
   formula language reads `WarningLamp.facing`. Since s3 is a trigger, it may not be narrowed or
   written as a weaker fact. My rule writes `sig_warning_lamp e red flashing`, which also admits a
   lamp facing only rear or side. The plan should either record the facing as a gap or residue for
   this profile, or get Core to expose a facing argument.
3. **s1 — a "police car" can't decide the trigger.** The narratives use a police car, but under
   this run's reading `DEF-NRS-484A-020::authorized_emergency_vehicle` has no included class. A
   police car (`ru.emergency_vehicle`) is therefore always *unknown* as a member. The witnesses
   use an official vehicle of a regulatory agency, which decides the trigger through the
   `ru.official_vehicle` limb. If the plan wants the police-car narratives to decide, the
   aggregate needs an included class.

## Choices left open and what I chose

- **"Stops" (s10):** written as `halt ∧ (halt since trigger)`, so the vehicle must be at rest
  now and at every observation after the last one at which the trigger held. This is the record's
  "past mirror of until", read with the halt also required at the judged observation.
- **"Ahead":** the `rel_bearing … "ahead"` atom, i.e. a positive longitudinal component, which is
  the record's words.
- **Extra witness:** `branch_2` (not applicable) exercises the s6 exception: a police officer
  directing traffic governs the subject's lane.

## Why I finished

The node is wrong. Its declared non-expressible obligation contradicts its planned
`forbid`/`permit` scenarios, and no obligation built from its claims can both honour the record
and pass the gate. More gate runs can't fix that; the plan agent has to fix it as described above.
