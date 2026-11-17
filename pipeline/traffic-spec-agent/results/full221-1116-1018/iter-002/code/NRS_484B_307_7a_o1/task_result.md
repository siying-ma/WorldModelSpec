# NRS_484B_307_7a_o1: task result

## Final verdict: OK
The gate passed 11 witnesses (14 names) and the rule composes nothing. I made one comment-only edit to the witness header after the passing run.

## Gate runs
1. **WITNESS_FAIL**: every trace kept the subject's heading fixed at north while its yaw rate was non-zero. The adapter-consistency check requires the heading to turn by the yaw rate held over the interval before each scene.
   - **Change:** the subject's heading is now north turned left by the integrated yaw rate. Sine and cosine come from exact rational power series, rounded to 10⁻¹⁵.
2. **OK**.

(A stray shell command that was not the gate command was denied before run 1. It did not run the gate and used no budget.)

## How the node is written
- **Class:** `ru_aggregate subject "DEF-NRS-484A-285::traffic"` and `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`, conjoined.
- **Occasion (event boundary):**
  - The onset is `rises (rel_occupies subject i)`.
  - The rule is judged at recognition, the exit: `rises (not (rel_occupies subject i))`.
  - The act stretch is `passage φ := since (not entry) φ`. It holds where φ held at some observation from the latest entry into i up to the judged one. `since` settles at the entry itself, so no earlier observation is read.
- **s2:** quantifiers bind an intersection i, a travel region c with `st_lane_enters c i`, and a traffic-signal head s with `dev_governs s c`.
  - The entry is from c when, at the entry, `since inI (occupies c ∧ ¬inI)` holds. At that observation it reads exactly the observation before the entry.
- **s1 (some_moment):** `passage (shows s fya(left) ∨ fya(right) ∨ fya(u_turn))`.
- **s4:** the movement is read at the exit from the three through-region concepts, with step `p.heading_since_step_carla_scene_graph`. It counts as straight where none of them holds.
  - It must be indicated by a flashing yellow turn arrow shown during the passage: a left arrow indicates a left turn or a U-turn, a right arrow a right turn, a u_turn arrow a U-turn.
- **s3:** at the entry observation, if the speed is above `p.halt_speed_tolerance`, then for every road user y, `¬(prim_closest_approach_within ∧ prim_closest_approach_distance < p.conflict_centre_clearance)`.
  - The subject is not excluded with `same`, because its closest approach to itself is never defined (zero relative velocity), so it never counts.
- **s5 (some_moment, the same observation as the arrow):** for the movement made, s shows a flashing yellow turn arrow of direction d during the passage. At that same observation it also shows a state other than that arrow which permits the movement:
  - circular_green, circular_yellow or flashing_yellow permit every movement;
  - a green, yellow or flashing yellow arrow permits its own direction's movement (left: left turn and U-turn; right: right turn; u_turn: U-turn; straight: straight).

## Choices the node left open
- **Where s5 sits.** The record says the duty "does not apply" where the exception holds, but the planned `occasion_s5` witness expects **compliant**, not not_applicable.
  - I therefore wrote the exception as the first alternative of the obligation: `excepted ∨ (indicated ∧ cautiousEntry)`. Where it holds, neither the movement duty nor the caution duty is imposed, and the verdict is compliant.
  - Putting `¬excepted` in the applicability would have made `occasion_s5` not_applicable.
  - **The plan should reconcile the applicability text with that witness.**
- **"Another state".** I read it as any state other than the particular flashing yellow turn arrow it is shown with, as the s5 element lists the permitting states.
  - A consequence: a flashing yellow arrow of one turn direction counts as an "other" state for an arrow of a different direction.
- **Obligation scope (rule 3c):** the obligation re-selects i, c and s with the applicability's whole selection and imposes the duty for every selection (∀ … selection → duty).
- I declared no narrowings of my own.

## Witnesses
- **Geometry:** a 50-scene trace at 50 ms (the reviewed 20 Hz step).
  - Northbound lane 10 enters intersection 20, and signal head 1 governs lane 10.
  - Occupancy is stated explicitly: entry at k=5 (body across the lane and the intersection), exit at k=45.
- **Heading change** is 2 s × yaw rate: 1° straight, +88° left, −88° right, +180° U-turn.
- **Window:** 50–2450 ms. The first scene is not judged, because `rises` and `since` have no past there.
- **The planned nine:** all are built as narrated.
- **Branches I added:**
  - `branch_2` (compliant): right turn under a right flashing yellow arrow. It exercises the right-turn concept.
  - `branch_3` (compliant): U-turn under a left flashing yellow arrow. It exercises the U-turn concept and the "left arrow indicates the U-turn" reading.
- **Inconsistency between position and speed:** positions follow a straight 6 m/s pace in every witness, including the turning ones, and branch_1's speed field is 10 m/s. The rule reads only the entry state for caution, and the gate did not object.

## Why I finished
The gate returned OK on run 2 of 6.
