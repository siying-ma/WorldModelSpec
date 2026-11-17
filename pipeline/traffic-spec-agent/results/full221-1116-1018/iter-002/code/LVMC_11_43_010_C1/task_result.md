# LVMC_11_43_010_C1 — task result

## Final verdict: BARE_LITERAL (node defect: s5 needs the declared literal `1` (count))

The rule is written as the node states it. The one literal it needs, the left lane's ordinal `1`,
is one the node never declares. The witnesses are complete. With that comparison temporarily
written without a literal, the gate returned **OK** (6 witnesses), so declaring the literal is the
only thing the node is missing.

## Gate runs (6 of 6 used)

1. **BARE_LITERAL**: `formula literals [('1','count')] ≠ the node's declared literals []`. The
   obligation compares `st_lane_adjacency_ordinal(l)` with the count 1, exactly as the record's
   obligation states it ("ordinal(l) = 1").
   - Change: as a diagnostic only, I wrote ordinal = 1 as `n·n = n ∧ n > 0`, which uses zero only.
     This let me check the rest of the rule and the witnesses.
2. **WITNESS_FAIL**: the adapter check failed on every witness. Each scene kept the previous
   scene's heading although the yaw rate turned it 4.5° (the rate at a scene is held over the
   interval before it).
   - Change: I removed the heading and velocity from the witnesses.
3. **WITNESS_FAIL**: a track in `occupancy_observed` needs a position, a non-zero heading and an
   extent, because the footprint is defined from them.
   - Change: I rebuilt the witnesses so they are physically consistent:
     - Headings are integrated from the yaw rate, using a rational cos/sin series rounded to 1e-6.
     - Positions advance 1 m per 50 ms along the heading.
     - The turn lies entirely inside the roundabout.
     - Occupancy is stated from footprint overlap. The roundabout's entry edge and exit edge each
       lie 0.5 m from where the footprint crosses them.
4. **OK**: 6 witnesses, 7 names, composes nothing (still with the diagnostic `n·n = n ∧ n > 0`).
   - Change: I put back the honest comparison `ordinal(l) = 1` (`.lit (Units.ratio 1 1) .count`).
     The encoding only hid the figure 1 from the literal check; it does not satisfy that check.
     Leaving it in would have worked around the gate rather than passed it.
   - My edit left a stray docstring behind.
5. **BUILD_FAIL**: the stray docstring.
   - Change: I removed it.
6. **BARE_LITERAL**: the same as run 1. This is the state I'm leaving.

The harness re-runs the gate on these files and will get BARE_LITERAL.

## The node defect (span s5)

- **What the node states:** s5's element maps "use the left lane" to "st.lane_adjacency ... ordinal
  1 is the leftmost lane: the left lane is the lane of ordinal 1". The obligation writes
  `ordinal(l) = 1`.
- **What it leaves out:** the node's `literals` list is empty.
- **Why it can't be read otherwise:** the figure 1 is not a reading parameter. It also cannot be
  stated without a literal:
  - `st_lane_adjacency_left` reads a neighbour id. For a leftmost lane that id is `none`, which is
    unknown rather than false, so "has no left neighbour" never decides.
  - Any arithmetic that produces 1 out of measured terms only disguises the literal.

**What the plan agent must change:** declare a literal on s5 for the left lane's ordinal: value 1,
unit count. Its source is st.lane_adjacency's contract, "ordinal 1 is the leftmost lane", which is
what "the left lane" means. Once that is declared, this rule file passes unchanged. The gate
returned OK on these exact formulas and witnesses apart from how the 1 was written.

## The reading as written

- **Subject class:** `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`.
- **Applicability:** `∃ roundabout r. rises(left_turn_through_region(subject, r, step, turn_min,
  u_turn_min) ∨ u_turn_through_region(subject, r, step, u_turn_min))`.
  - The step is `.param "p.heading_since_step_carla_scene_graph"`.
  - The act is judged once, at its recognition (the exit), as the occasion requires (s4,
    at_recognition).
- **Obligation:** the record's whole selection of r again (kind roundabout, the same act
  recognized), together with `since(φ, rises(occupies(subject, r)) ∧ φ)`.
  - `φ = occupies(subject, r) → ∀ lane l. occupies(subject, l) → ordinal(l) = 1`.
  - The search back ends at the latest entry into r, which is the event onset the record declares.
- **Narrowings:** none of my own. Every choice above is the record's.

## Witnesses

| witness | lane used | turn | expected |
|---|---|---|---|
| forbid | ordinal 2 | +90° (quarter turn left) | violated |
| permit | ordinal 1 | +90° (quarter turn left) | compliant |
| idle | ordinal 2 | −90° (right turn, no left turn or U-turn recognized) | not applicable |
| blind | as forbid, with `st.lane_adjacency` masked | +90° | unknown |
| branch_1 | ordinal 2 | +180° (U-turn) | violated |
| branch_2 | ordinal 1 | +180° (U-turn) | compliant |

Each witness judges the instants from 50 ms to 2250 ms.

## Note on a denied command

Once I mistakenly sent a second shell command (the gate command with extra flags). It was denied
and not run, and it did not count as a gate run.

## Why I finished

The gate budget is spent. The only remaining verdict is BARE_LITERAL, which is the node's missing
literal declaration on s5 and is not something a coding session can fix. Everything else the gate
checks passed.
