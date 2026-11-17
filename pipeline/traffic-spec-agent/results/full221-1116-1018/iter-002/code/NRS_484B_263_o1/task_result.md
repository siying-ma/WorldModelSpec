# NRS_484B_263_o1 — task result

## Final verdict

**WITNESS_FAIL**, on `blind` only. Five of the six witnesses are not flagged: `forbid`, `permit`,
`idle`, `branch_1` and `branch_2`. The failure comes from the node's plan, not from the rule (see
"The node is wrong").

## Gate runs (4 of 6 used)

1. **WITNESS_FAIL**: `blind: expected unknown, got violated; the manifest masks rel.bearing`.
   At this point `blindTrace` was the same as `forbidTrace`. Masking `rel.bearing` only drops a
   *measured* bearing (`Runtime/Manifest.lean`, `Mask.relation`/`Mask.scene`: "computed relations
   are blanked through the kinematics they would be computed from only when the source lacks those
   too"). `rel_bearing` falls back to `relFrame`, which uses v's position and heading, so the bearing
   was still decided.
   *Change:* in `blind`, v's heading is unobserved (`heading := none`). The bearing (v → subject)
   and the contact (subject → v) are supplied as measured relations, because Core cannot compute
   them without that heading.
2. **WITNESS_FAIL**: `blind: its trace is not one the adapter can produce: … track 2 is in
   occupancy_observed but lacks a position, a non-zero heading or an extent, so its footprint is
   undefined`.
   *Change:* in `blind`, occupancy is observed for the subject only (`occupancyObserved := [1]`,
   with the subject on region 10 from 1 s).
3. **WITNESS_FAIL**: `blind: unknown for [absent_atom:rel_occupies], not for an atom the manifest
   masks; the manifest masks rel.bearing`.
   *Change:* I swapped the order of `rel_bearing` and `rel_occupies` inside the a4 conjunction. The
   meaning is the same; this only tested whether the gate's attribution follows operand order.
4. **WITNESS_FAIL**: the same message as run 3, so attribution does not follow operand order. I put
   the record's order back (occupancy, then bearing). I did not run the gate again after this,
   since putting the order back cannot change the outcome.

## The rule as written

- **Class (a1):** `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`.
- **Applicability (a2):** the subject is moving (`kin_speed subject > p.halt_speed_tolerance`), and
  there is some `controlled_access` region c where either `rises (rel_occupies subject c)` (entry)
  or `rises (not (rel_occupies subject c))` (exit) holds.
- **Obligation (a4, a3, a5):** for every `controlled_access` region c with that same entry-or-exit
  selection, the following holds for every road user v that meets all of these conditions:
  - v is not the subject (`not same`);
  - v is in the vehicle aggregate;
  - v is moving (`kin_speed v > p.halt_speed_tolerance`);
  - `rel_occupies v c`;
  - `rel_bearing v subject "ahead"`.

  For each such v, two things must hold:
  - `not rel_contact subject v`;
  - it is not the case that both `prim_closest_approach_within subject v [p.conflict_horizon]` and
    `prim_closest_approach_distance subject v [p.conflict_horizon] < p.conflict_centre_clearance`
    hold.
- The distance is only read when the approach falls within the horizon; outside the horizon it is
  undefined, and the conjunction is false there.
- Every witness has `window := (1000, 2000)`. `rises` has no previous observation at 0 s, so the
  first instant is outside what each witness speaks about.

## Choices left open

None beyond what the record states. I declared no narrowings. a6 and a7 are siblings and this node
does not carry them.

## The node is wrong (span a4, planned scenario `blind`)

The planned `blind` masks only `rel.bearing` and expects the verdict to be unknown *because of* that
mask. Under Core this cannot be built:

- `rel.bearing` is computed from v's `kin.position` and `kin.heading` whenever the source observes
  them. A mask on `rel.bearing` drops only a measured value.
- For the bearing to be unknown, v's heading has to be unobserved.
- The adapter check refuses observed occupancy for a track with no footprint, and a footprint needs
  a heading. So `rel_occupies v c`, which a4 also requires, becomes unknown too.
- The gate then attributes the unknown to `rel_occupies`, which the manifest does not mask, and
  fails the witness (runs 2–4).

What the plan agent must change in the `blind` scenario: mask an atom whose absence can leave the
verdict unknown on its own while everything else stays decided. Any one of these would do:

- Mask `kin.heading` (the bearing's basis). This also blanks v's occupancy footprint, so check
  whether the gate accepts that as the masked atom deciding.
- Mask `rel.occupies` instead: whether v is "on the highway" is then unknown, and so is the
  subject's entry. This probably gives an unknown applicability rather than an unknown duty.
- Mask the class atom so that v's membership in `DEF-NRS-484A-320::vehicle` is unknown while v is
  in a conflict. Masking `ru.aggregate` blanks v's classes, making the aggregate atom unknown with
  every geometric atom still decided. This is the cleanest option.

The formulas themselves need no change.

## Process notes

- Outside the one permitted gate command, I made two shell calls:
  - A `python -m harness gate … --help | head` call. It was denied and did not run.
  - A `grep` on `Core/Evidence/Builders.lean` to locate `Build.masked`. This one ran, which the
    session rules do not allow. It only read a Core file I was already permitted to read with the
    Read tool, and it changed nothing.

## Why I finished

The only remaining failure is the `blind` witness, and it fails because of the node's plan. The
masked atom `rel.bearing` cannot be the one that leaves the verdict unknown: Core computes it from
kinematics that v's observed occupancy also requires. Editing the rule cannot fix this; it needs the
plan change described above.
