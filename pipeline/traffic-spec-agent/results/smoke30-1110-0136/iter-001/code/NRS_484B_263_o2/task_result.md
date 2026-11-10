# NRS_484B_263_o2 — task result

## Final verdict

**WITNESS_FAIL**, on `blind` only. The `blind` scenario the node plans cannot be built: masking
`rel.surface_gap` never leaves the gap unknown in a trace this rule can be judged on. The node is
wrong on this point (details below). The other six witnesses passed: in the first run the gate
listed `blind` as its only failure.

## Gate runs

1. **WITNESS_FAIL**: `blind: expected unknown, got violated; the manifest masks rel.surface_gap`.
   The rule built and passed the static checks, and forbid, permit, idle, branch_1, branch_2 and
   branch_3 passed. I read `Core/Runtime/Manifest.lean`: `Mask.scene "rel.surface_gap"` drops
   only a *measured* gap ("The computed relations are blanked through the kinematics they would
   be computed from only when the source lacks those too"). `rel_surface_gap` is then computed
   again from the footprints.
2. A gate run I started by mistake in the background, on unchanged files with a 1 ms timeout. It
   was killed before it gave a verdict. It may count against the budget.
3. **WITNESS_FAIL**: `blind: its trace is not one the adapter can produce … track 1 is in
   occupancy_observed but lacks … an extent, so its footprint is undefined`. For this run I had
   left out the extents and supplied the gap as a measured relation. Admission refuses this:
   every track whose occupancy is observed must have a footprint.

After run 3 I put `blind` back to forbid's trace (admissible, but it gives violated).

4. **WITNESS_FAIL**: the same `blind` failure as run 1, and nothing else. The files are left in
   this state.

Two other shell calls I sent at the start were denied by the permission layer and never ran:
a `--help` call, and the gate command with a flag it doesn't take.

## Why the node is wrong (`scenarios.blind`, `masked: ["rel.surface_gap"]`)

- The applicability and the obligation read `rel.occupies` for both x (the entry or exit event,
  span s2) and y (y on the highway being entered, span s4).
- Admission rejects a scene in which a track has observed occupancy but no footprint (position,
  non-zero heading and extent).
- When both footprints are present, `rel_surface_gap` (Vocab/Atoms.lean) computes the gap from
  them. The manifest mask for `rel.surface_gap` only clears `MeasuredRelation.surfaceGap`.
- So in any admissible trace where x's and y's occupancy is decided, the gap is decided as well,
  and `blind` can never be unknown because of the atom it masks. If occupancy is left unobserved
  instead, the result is unknown because of `rel_occupies`. The masked atom does not cover that,
  so the gate rejects it as a stray reason.

**What the plan agent must change:** mask an atom that does decide the hazard on its own. Either
of these makes the hazard, and so the verdict, unknown only because of the masked atom:
- `kin.speed`: it decides y's motion (`drv.motion.moving`) and the speed × gap bound.
- `rel.occupies`: it decides the entry or exit event and y's place on the highway.

Alternatively, drop the `blind` scenario's claim that the gap is the decisive unknown.

## How the rule is written (choices the node left open)

- **Entry and exit (s2).** For each `controlled_access` region `a`:
  - entry is `rises (rel_occupies x a)`;
  - exit is `rises (not (rel_occupies x a))`, with a `highway` region `h` that x occupies at the
    exit.
  
  The record's "not a" is already implied, because x does not occupy `a` at the exit. So I
  wrote no `same h a` test.
- **"Some observation of the run immediately before the event during which x stayed on the near
  side" (s4/s5).** The inner search is `since near (hazard ∧ near)`, read at the observation
  before the event. To read it there, the formula is `since (rises E) S` at the event, where E
  is the event's state and S is the inner `since`. At the event S is false, and E did not rise
  at the observation before, so the outer `since` returns exactly S's previous value. Where the
  run reaches back to the trace start, `since` leaves the search unknown.
- **Hazard (s5).** `rel_surface_gap x y ≤ kin_speed y · p.immediate_hazard_time_gap`, with y
  moving (`drv_motion_moving`, `p.motion_speed_tolerance`) on the highway being entered.
- **That traffic (s8).** y is a vehicle (`DEF-NRS-484A-320::vehicle`) and traffic
  (`DEF-NRS-484A-285::traffic`), other than x, with the s4/s5 selection. This is written once as
  `thatTraffic`. The obligation binds it again, together with `forallRegion controlled_access a`
  and the event.
- **Obligation (s6/s7/s9).** If x is moving at the event, then for every such y,
  `not (prim_closest_approach_within ∧ prim_closest_approach_distance < p.conflict_centre_clearance)`,
  with horizon `p.conflict_time_horizon`.
- **Narrowings.** I declared none: every choice above is a direct writing of the record's
  applicability and obligation.

## Witnesses

- `forbid`, `permit`, `idle` and `branch_1` follow the narratives.
- `idle`: x is first observed on `a`, drops onto `h`, then re-enters `a`. Starting x on `a`
  lets the hazard search end inside the trace, so idle is decided instead of being unknown at
  the trace start.
- Added `branch_2` (violated), which covers the exit limb.
- Added `branch_3` (compliant): x is on `a` at the entry but below the motion tolerance. It
  covers the "x is moving" condition of the obligation.
- Each witness sets `window` so the judged instants start after the trace's first observation.

## Why I finished

The only remaining failure is the node's `blind` scenario. Under Core's masking and admission
rules it cannot be built, and the witness may mask only the node's `masked` ids. The node has to
be repaired; Lean can't fix it.
