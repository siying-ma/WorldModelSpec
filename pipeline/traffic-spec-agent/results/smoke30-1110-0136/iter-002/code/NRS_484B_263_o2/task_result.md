# NRS_484B_263_o2 — task result

**Final verdict: OK** (7 witnesses, 9 names, composes nothing).

## Gate runs
1. `WITNESS_FAIL`: `blind` was unknown for `window_truncated:rises` and `window_truncated:since` as well as the masked atom. With `rel.occupies` masked, nothing could close the `since` run before the event. It therefore reached back past the start of the trace.
   - Change: the run is now read only at the event. Each limb is `event ∧ definedWhen event (since …)`. Where the event is false the limb is still false. Where the event is unknown the limb is unknown, and only the event's own reason (the masked occupancy) is reported.
2. `OK`.

(Before run 1 I also sent a modified gate command with `--help` and a pipe. The sandbox denied it and it did not run.)

## How the node is written (also in the rule's header)
- **x's class (s1):** `ru_aggregate x DEF-NRS-484A-320::vehicle`.
- **Events (s2):** an entry is `rises (rel_occupies x a)` and an exit is `rises (¬ rel_occupies x a)`, for each region `a` of kind controlled_access.
- **That traffic (s4/s5/s8, `thatTraffic`):** a road user `y` that is not x, is a member of both vehicle and traffic, and has one of these limbs:
  - **Entry limb:** x enters `a` now, and `since (x off a ∨ x entering a) (x off a ∧ y approaching on a)`.
  - **Exit limb:** x exits `a` now onto a `highway` region `h` it occupies now, and `since (x on a ∨ x exiting a) (x on a ∧ y approaching on h)`.
- **"Approaching" (s5):** `drv_motion_moving y`, `rel_occupies y r`, and `rel_surface_gap x y ≤ kin_speed y × p.immediate_hazard_time_gap`.
- **Obligation (s6/s7/s9):** `drv_motion_moving x → ∀y (thatTraffic → ¬(prim_closest_approach_within ∧ prim_closest_approach_distance < p.conflict_centre_clearance))`. The obligation restates the whole selection of `y`, including its regions and its run.

## Choices the node left open
- **How the run is written.** `since` stands for "the run immediately before the event during which x stayed on the near side". The disjunct `x entering a` (or `x exiting a`) only lets the run end at the event being judged.
  - Sampling limit: an earlier event observation also passes that disjunct. So a stay of exactly one observation on the far side does not end the run.
  - A tighter `φ = ¬rises(near side)` is exact. But its one leaf would only matter in an extra re-entry witness, so I did not use it.
  - I declared no narrowing, because nothing is read more narrowly than the record states.
- **Reading the run only at the event (`definedWhen`).** This changes only one case: where the event is unknown and the run is decided false, the limb is now unknown instead of false.
- **Witness windows.** Every witness is judged from its second observation on. At the first one, `rises` has no previous observation to compare with.

## Witnesses
- **The planned six (forbid, permit, idle, blind, branch_1, branch_2):** each is built as the plan's narrative describes and returns the planned verdict.
- **`idle`:** the far vehicle has left the recorded scene by the time x enters. If a road user is still present at the entry and no hazard was ever recorded, the run reaches back past the start of the recording. The rule then correctly reads it as unknown, not as not-applicable.
- **`branch_2`:** has the hazard only at the start of the run, not at the observation just before the exit.
- **`branch_3` (added, violated):** the same for an entry. y slows in a queue so that it is not a hazard at the observation just before the entry. This exercises the run, not only its last observation.

## Why I finished
The gate returned OK on the second run.
