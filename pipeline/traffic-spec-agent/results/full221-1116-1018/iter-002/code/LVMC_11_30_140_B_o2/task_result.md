# LVMC_11_30_140_B_o2 — task result

## Final verdict: **OK** (7 witnesses, 7 names, composes nothing)

## Gate runs (6 of 6 used)

1. **UNUSED_CLAIM** — I ran the gate on the untouched skeleton by mistake (every claimed name unused). No change was needed for it.
2. **WITNESS_FAIL** — `blind` came back compliant. Masking `rel.centre_distance` only drops a *measured* value. Core still computes the distance from positions (`Atoms.rel_centre_distance`, `Manifest.Mask.scene`), so with both positions observed the mask had no effect.
   → I rebuilt `blind` with the pedestrian's position unobserved, and supplied the centre distance and contact as measured relations (Core cannot compute either without that position).
3. **WITNESS_FAIL** — the adapter would not accept the pedestrian: it was listed in `occupancy_observed` but had no position.
   → Set `occupancyObserved := [1]` in the blind scenes.
4. **WITNESS_FAIL** — `blind` was unknown for `window_truncated:since`, and was unknown with nothing masked too.
   → Redesigned the scene (car at rest, then an approach with no halt after it).
5. **WITNESS_FAIL** — same message as run 4.
   → Redesigned again so the halt's history is decided by a recorded contact event (below).
6. **OK**.

## How the rule is written
- **Subject class (s1, s2):** `ru_aggregate(subject, DEF-NRS-484A-165::pedestrian) ∧ ¬ru_pedestrian_with_white_cane_or_guide_animal(subject)`, or `ru_aggregate(subject, DEF-NRS-484A-320::vehicle)`.
- **Event (s3):** `event b := rises(rel_contact(subject,b)) ∨ (rises(rel_centre_distance(subject,b) ≤ p.blind_person_approach_reach) ∧ ¬complete_halt(subject, p.halt_speed_tolerance))`.
- **Selection of b (s4 + s8):** `selected b := ¬same(subject,b) ∧ white_cane(b) ∧ since(¬event b, halt ∧ once(event b))`, with `once φ = since tt φ`. In words: the subject was at rest at some observation at or after an event with b, and no event with b has occurred since.
- **Applicability:** `¬halt ∧ ∃b. selected b`.
- **Obligation (s9, surrogate):** `∀b. selected b → ¬(rel_contact ∨ (prim_closest_approach_within(h) ∧ prim_closest_approach_distance(h) < p.conflict_centre_clearance))`. The obligation repeats the applicability's whole selection of b.
- **Narrowings:** none added. Every choice above is the record's own wording.

## Witnesses
- **forbid:** the car approaches, halts, then moves off toward the pedestrian; closest approach 0 m in 2 s.
- **permit:** the car waits while the pedestrian crosses, then moves off; predicted closest approach about 10 m.
- **idle:** the permit scene with an ordinary pedestrian.
- **blind:** see the deviation below.
- **branch_1 (contact limb):** contact begins while the car is at rest. The car then moves off at the pedestrian's own velocity with contact persisting, so there is no closing course.
- **branch_2 (violated):** the subject is an ordinary pedestrian; this exercises the pedestrian limb of the class.
- **branch_3 (not applicable):** the subject is itself a white-cane pedestrian, which the class excludes.

Every scenario except `blind` sets `window` to start after the trace's first instant. At the first instant `since`/`once` are truncated, which is correct: the event could predate the recording.

## Deviation from the planned narrative
**`blind` deviates from its planned narrative.** The plan says "no contact occurs". Under this record's applicability, though, with `rel.centre_distance` masked and no contact, no event can ever be decided. That leaves `once(event)` unknown back to the start of the trace, and the gate rejects this as "not for an atom the manifest masks" (runs 4–5).

The witness that passed works differently:
- The pedestrian touches the car while it is at rest. This is a recorded event, and the halt follows it.
- The car then moves off with the contact still on.
- With nothing masked, the verdict is decided **violated**.
- With the mask, it is unknown, solely through `rel.centre_distance` (whether a new approach occurred after the halt).

The plan should reword this scenario's narrative accordingly.

## Issue for the plan (not a blocker)
The record's applicability counts as the latest event any event "at or before the judged observation". A contact that *begins* while the subject is proceeding is therefore itself a new event with no halt after it, so the rule is not engaged at that instant. As a result, the obligation's `rel.contact` limb only fires on contact that persists from, or began during, the halt. That is why `branch_1` is built that way.

The planned narrative for `branch_1` ("moves off and its body touches the pedestrian") suggests the plan meant the latest event *before* the judged observation. If so, s3/s8 should say that. I could write it, since `Y χ = (χ ∧ ¬rises χ) ∨ rises ¬χ`, but I did not, because a trigger span may not be narrowed or re-read by the coder.

## Process notes
- Two shell commands outside the gate were attempted: a mistaken gate call with `--help`, which was denied, and several `grep`s into Core files, which ran. Reading a library concept file was denied.
- No files other than the two owned files and this report were changed.

## Why I finished
The gate returned **OK** on the sixth and last run.
