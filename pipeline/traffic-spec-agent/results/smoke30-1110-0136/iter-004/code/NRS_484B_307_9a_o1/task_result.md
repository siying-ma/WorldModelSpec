# NRS_484B_307_9a_o1 — task result

## Final verdict: WITNESS_FAIL (cause is upstream: the run's reading of the paragraph (b) aggregates)

The rule builds and passes the static checks. Its scenes are admitted, and `permit`, `idle` and
`branch_1` pass. `forbid`, `blind`, `branch_2`, `branch_3` and `branch_4` come out **unknown**, and
in every case the only reasons are:

    aggregate_unresolved:DEF-NRS-484A-135::motorcycle, DEF-NRS-484A-125::moped,
    DEF-NRS-484B-017::electric_bicycle, DEF-NRS-484B-018::electric_scooter

These are the aggregates the four exception nodes `NRS_484B_307_9b_o1 … o4` read. For a car,
`ruleApplies NRS_484B_307_9b_*` is unknown, so the applicability `… ∧ ¬ruleApplies(9b_*)` is
unknown too.

## Gate runs

1. **Accidental run (my mistake).** I ran the gate with its output thrown away (`| head -0`) while
   trying to look at files, plus one no-op `echo`. This probably used one run of the budget.
2. **WITNESS_FAIL.** forbid, blind and branch_4 were unknown because of the aggregates above.
   permit, branch_2 and branch_3 were rejected because the heading did not follow the yaw rate.
   Changes after it: I labelled the car `truck` to try to get a decided class, and recorded only
   position and yaw.
3. **WITNESS_FAIL.** A footprint needs a heading and an extent. Change after it: the headings now
   rotate exactly as the yaw says (11.25° per 50 ms interval, rational unit vectors to 1e-6). Every
   sampled position is at least 2 m from a region edge, so each footprint lies in one region.
4. **WITNESS_FAIL.** The scenes are now admitted. permit, idle and branch_1 pass. Everything else is
   unknown for the four aggregates, now with `truck`.
5. **WITNESS_FAIL (probe).** I added temporary witnesses `branch_5 … branch_16`: the forbid scene
   with each of bus, transit_bus, school_bus, tour_bus_or_limousine, taxicab,
   commercial_motor_vehicle, trailer_or_combination, rail_vehicle, bicycle, emergency_vehicle,
   official_vehicle and fire_apparatus.
   - Every class was unknown for all four aggregates except two.
   - rail_vehicle: only the motorcycle aggregate was decided; the other three stayed unknown.
   - bicycle: not_applicable, because (b) applies to it.

   So no road-user class that this duty covers lets the (b) exception be decided false.
6. **WITNESS_FAIL.** Final run on the cleaned files: probes removed, the car back to
   `motor_vehicle`. The result is the same five unknowns.

## The rule as written

- **Class.** `ru_aggregate x DEF-NRS-484A-285::traffic`. The applicability adds
  `¬ru_aggregate x DEF-NRS-484A-165::pedestrian` (a3, "vehicular").
- **Occasion (event; recognized at the exit).** "x leaves i" is `rises (¬ rel_occupies x i)`. The
  entry is the last rise of the overlap, read back from the exit as
  `since (¬ rises occ) (rises occ ∧ φ)`.
- **a1 and a4, at the entry.** There is a traffic signal `s` that:
  - shows `circular_red` and one of `green_arrow(left|right|u_turn)`;
  - and either governs `i` itself, or governs a `travel_region c` with `st_lane_enters c i` that x
    occupied at the observation before the entry.

  "At the previous observation" is written with `rises` alone: `(A ∧ ¬rises A) ∨ rises ¬A`.
- **a2.** `¬ruleApplies NRS_484B_307_9b_o1..o4 [x↦x]`.
- **a5.** For every intersection `i` and every traffic signal `s`, with the whole selection written
  again, the rule is violated in any of these cases:
  - `rises left_turn(x,i)` and no `green_arrow(left)` at the entry;
  - the right-turn version of that;
  - `rises straight_through(x,i)` and no `green_arrow(straight)` at the entry.

  Parameters: the step bound is `p.heading_since_step_carla_scene_graph`. Left turn uses
  `[p.left_turn_min_angle, p.reversal_min_angle]`, right turn uses
  `[p.right_turn_min_angle, p.reversal_min_angle]`, and through uses
  `[p.straight_through_max_heading_change]`.
- **Narrowings.** No narrowing of my own; the record's narrowings are not restated.

## Choices the node left open

- I wrote "the observation before the entry" exactly, with the `rises` identity above, instead of
  reading the carrier at the entry itself.
- I wrapped each act in `rises (…)` (rule 6b). Each concept holds only at the exit, so this changes
  nothing.
- The witnesses set `window = [100, 550] ms` (from the entry to the end). The entry is read back
  through `since` and `rises`, and both are truncated at the start of the trace.
- I added three branches: branch_2 (left turn under a right arrow only, violated), branch_3 (right
  turn under a left arrow, violated) and branch_4 (the signal governs the intersection itself, red
  with left and straight arrows, through movement, compliant).

## Why I finished

The planned `forbid` (and `blind`) witnesses cannot be met under this run's reading, whatever
I write in the two files.

The duty only applies where no paragraph (b) node applies. Each (b) node's class is one of these
aggregates: motorcycle (NRS 484A.135), moped (NRS 484A.125), electric_bicycle (NRS 484B.017) and
electric_scooter (NRS 484B.018). The reading classifies **every** other road-user class as
unresolved in at least one of them. The probe in run 5 showed this: rail_vehicle is decided only
in the motorcycle aggregate, and the other eleven classes in none. So for every vehicle this
duty covers, "(b) applies" is either true (motorcycle, bicycle) or unknown. The rule can never be
violated and can never be decidedly not applicable for a car.

This is not a defect of this node's mapping, and it cannot be fixed in Lean: writing the exception
any other way would mean changing the composition.

**What must change (plan / reading):**
- The reading should classify the obvious non-members as **excluded** in these four aggregates:
  motor_vehicle, truck, bus and its kinds, taxicab, trailer_or_combination, rail_vehicle and the
  like. A car is decidedly not a motorcycle, moped, e-bike or e-scooter.
- Alternatively, the (b) nodes' applicability should be decidable false for such vehicles some
  other way.

Once that is fixed, the files as they stand should pass: the scenes are admitted, and the
remaining witnesses failed only on these aggregate reasons.
