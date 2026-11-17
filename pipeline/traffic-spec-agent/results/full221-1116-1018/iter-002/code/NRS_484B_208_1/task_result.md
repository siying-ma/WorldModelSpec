# NRS_484B_208_1 — task result

## Final verdict
**UNANCHORED_VARIABLE** (expected on the final files; this was the result of gate run 2, which is the formula left in place). The node is wrong in two places, described below. The rule and the 19 witnesses are written in full. Every witness except `branch_4` passed in a diagnostic run.

## Gate runs (4 of 6 used)
1. **Skeleton, before any edit** → `UNUSED_CLAIM` (all claims; the formulas were still `.tt`). This run was wasted.
2. **Full rule and witnesses** → `UNANCHORED_VARIABLE`: `turnAtS`, `turnAtR`, which are the intersection region of k10/k11 inside the two copies of S. The rule builds and passes the static check.
3. **Diagnostic**: anchored the intersection with `st_region_geometry_distance(subject, ix) ≥ 0` → still `UNANCHORED_VARIABLE`. The gate refuses this vacuous anchor, correctly.
4. **Diagnostic**: anchored it with `rel_occupies(subject, ix)` (wrong meaning, used only to reach the witness stage) → `WITNESS_FAIL`:
   - `branch_4: expected not_applicable, got unknown for [aggregate_unresolved:DEF-NRS-484A-020::authorized_emergency_vehicle]`
   - `branch_7: expected compliant, got violated`. This failure comes only from the diagnostic anchor (the subject is not in the intersection).
   - Every other witness passed: forbid, permit, idle, blind, and branches 1–3 and 5–15.

   After run 4 I reverted k10/k11 to the record's formula: `existsRegion intersection ix (intent int.left_turn subject ix)`.

## Node defects (for the plan agent)

### 1. k10/k11: the intersection region has no anchor
The record binds the target region of `int.left_turn` with "the intention's region quantifier" (element k11 claims only `st.intersection`). The gate does not count `intent` as tying a region to a binder, and k11 claims no anchoring atom (`rel.occupies`, `st.region_geometry` with a bound, `dev.governs`). A vacuous distance anchor is refused, and occupancy changes the meaning.

**Fix:** claim an anchor for k11 that the words support. For example, use `st.region_geometry` (`st_region_geometry_distance(subject, ix)`) with a reviewed distance parameter for "preparing … at an intersection", meaning the intersection ahead lies within that distance. Alternatively, use an occupied lane that enters it (`st.lane_enters`). Otherwise, have the gate accept `intent(subject, ix)` as an anchor.

### 2. k18 (and k14): the reading resolves no class as an authorized emergency vehicle
Under this run's reading, `DEF-NRS-484A-020::authorized_emergency_vehicle` includes no class, and every motor-vehicle class (including `ru.emergency_vehicle`) is unresolved. So for any subject that is a motor vehicle, membership is at best `aggregate_unresolved`.

- **Planned `branch_4`** (an authorized emergency vehicle with lamps flashing, expected `not_applicable`) can only be **unknown**. This was confirmed in run 4.
- **k14** ("engaged in … maintenance", read as an amber warning lamp flashing or rotating) can never be decided either. Such a lamp also satisfies k18's "warning lamp flashing or rotating", so the applicability's `¬(AEV ∧ lamp)` stays unknown for every highway-maintenance vehicle with its lamp on. No decided witness can show the k14 exception, so I added none. I expect `VACUOUS` on the k14 leaves once (1) is fixed; this is predicted, not verified.

**Fix:** have the reading include at least `ru.emergency_vehicle`, and probably `ru.fire_apparatus`, in `DEF-NRS-484A-020::authorized_emergency_vehicle`. That makes branch_4 reachable and lets a non-emergency maintenance vehicle be decided as not an AEV. Alternatively, re-plan branch_4's expected verdict and the k14 reading.

## Choices the node left open
- **Leftmost lane (k3/k4)**: written as "there is no lane `l'` with `st_lane_adjacency(l, "left", l')`". Core decides this false for every `l'` exactly when the lane is first from the left with no left neighbour, so it reads the record's "ordinal first" without a figure the text doesn't state. "Two or more" is `st_lane_adjacency(l, "count") ≥ Units.ratio 2 1` (the declared literal, unit `.count`).
- **Stopping distance (k16)**: `speed × H + speed² / (D + D)`. The convention's 2 × D is written as D + D, so no undeclared figure enters. H and D are selected by `cond`: ice first, then wet or rain, then dry.
- **"The lane to the right" (k15/k17)**: the right neighbour (`st_lane_adjacency(ls, "right", lr)`) of a lane the subject occupies.
- **"Another vehicle" / "traffic member" / "motor vehicle behind"**: each excludes the subject (`¬ same`).
- **AEV "warning lamp flashing or rotating"**: any colour, as the record says. The lamp atom needs a colour, so I wrote one disjunct per colour and mode.
- **HOV (k13a)**: "for every zone sign of kind high_occupancy_lane governing the lane" is an implication under `forallDevice`, as the record states.
- I added no narrowings: every choice above stays within the record's own wording.

## Witness design notes
- In the base timeline the subject is in the middle lane at t = 0 and in the leftmost lane from t = 1. This keeps the obligation's `since` from starting on unrecorded history. Without it, permit and blind could only report a truncation unknown.
- `blind` is judged on 0–20 s, so S's look-ahead window (overtaking) is never truncated. `branch_6` (overtake) is judged on 0–14 s, before the move-over window has run again after the pass.
- Branches 5–15 each excuse the subject through exactly one exception, against a scene that would otherwise be violated: traffic, overtake, left turn, HOV, obstruction, wet road, rain, ice, lane-control signal, regulatory sign, temporary traffic control, police officer.

## Why I finished
The node is wrong. The quantifier in k10/k11 can't be anchored with what the node claims, and the reading makes the planned `branch_4` (and k14) undecidable. Neither can be repaired in Lean without changing the record's meaning. Two gate runs remain unused.
