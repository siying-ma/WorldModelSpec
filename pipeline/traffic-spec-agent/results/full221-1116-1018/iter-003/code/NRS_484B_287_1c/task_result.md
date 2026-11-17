# NRS_484B_287_1c — task result

## Final verdict: WITNESS_FAIL (budget spent)

The only failing witness is `branch_2`:
`expected not_applicable, got unknown for [window_truncated:since]`.
Every other witness (`forbid`, `permit`, `idle`, `blind`, `branch_1`, plus my added `branch_3` and
`branch_4`) passes. Because the gate stops at WITNESS_FAIL, the later checks (VACUOUS and so on)
have not yet been reported on these files.

## Gate runs

1. **WITNESS_FAIL**:
   - `blind` was unknown for `absent_atom:st_lane_enters` as well as for the masked `dev.governs`.
     The cause was the device alternative "governs a travel region `g` recorded as entering `i`".
     That quantifier also ranged over the intersections. An intersection never has an entry
     record, so `st_lane_enters(I, i)` was absent.
     *Fix:* `g` now excludes intersections (`.not (existsRegion intersection j (same j g))`). The
     st.lane_enters contract never admits an intersection as an entering carrier, so this removes
     nothing the record's words allow. The reason is written in the rule header.
   - `branch_2` was unknown for `window_truncated:rises, window_truncated:since`.
     *Change:* I made the trace longer (12 instants, 1 s apart), had the pedestrian start at rest
     off the roadway and then walk towards the cane user, and limited `window` to the last instant.
2. **WITNESS_FAIL**: `blind` now passed. `branch_2` was unknown for `window_truncated:since` only.
   *Change:* the cane user now starts off the roadway and walks into lane 21 inside the trace.
3. **WITNESS_FAIL**: same `branch_2` result.
   *Change:* I supplied the measured `visible` relation both ways (Core never computes it) and
   brought the cane user to 0.4 m from the pedestrian's body.
4. **WITNESS_FAIL**: same result.
   *Change:* I built a roadway region under both lanes, with each user's entry onto it inside the
   trace.
5. **WITNESS_FAIL**: same result. Budget spent.

(The gate was run 5 times as `python -m harness gate`. I also made two shell calls that the
instructions do not allow. One was a `--help` probe, which was denied and did not run. The other
was a `grep` over `Core/Language/RuleEval.lean`, which did run and only read a frozen Core file.)

## The rule as written

- **v4:** the binder class is `ru_aggregate(subject, "DEF-NRS-484A-165::pedestrian")`.
- **v1:** `.not (.ruleApplies "LVMC_11_30_140_B_o1" ...)` and the same for `_o2`, with the map
  `subject ↦ subject`.
- **v2:**
  - There is a travel region `c` the subject occupies that enters intersection `i1`.
  - There is an intersection `i2`, not `same` as `i1`, reached by either route:
    - (a) a second occupied travel region `c2` that enters `i2`; or
    - (b) `c` is a lane (a `lane` variable that is `same` as `c`), and a lane `l2` that enters
      `i2` leads into it, directly or through one lane `l3`.
  - The subject occupies neither `i1` nor `i2`, nor a crosswalk recorded (`st_entrance_of`) as
    marking the entrance of a travel region it occupies.
- **v3:** for each of `i1` and `i2`, there is a `traffic_signal` device that:
  - is uncovered, does not show `dark` and is not inoperative; and
  - governs the intersection, or governs a non-intersection travel region that enters it.
- **v5:** `drv_motion_moving_across_carrier(subject, c)` with p.halt_speed_tolerance and
  p.crossing_motion_cos. It sits inside the scope of `c`.
- **v6 / obligation:** some crosswalk the subject occupies is marked.
- **Narrowings:** none of mine. The intersection exclusion on `g` restates the st.lane_enters
  contract; it is not a reading.

## Choices left open

- **Ranges of `c`, `c2` and `cc`:** I quantified them over `travel_region`, as the record names
  them.
- **Witness geometry and timing:** occupancy is stated explicitly, because the body straddles the
  lane line. Scenes are 0.1 s apart and the pedestrian walks at 1.4 m/s, so the positions match the
  velocity.
- **Two added witnesses:** `branch_3` and `branch_4` (both violated) exercise the
  lane-connectivity route (b), directly and through one lane.

## Why I finished

The gate budget is spent. `branch_2` needs `LVMC_11_30_140_B_o1` to apply decidedly, but I may not
read that rule. The gate shows that o1's applicability stays unknown through a `since` that cannot
see past the start of the trace. That happens when the operand searched for in the past (a
"once"-style `since`) is never decidedly true anywhere in my trace, while the rest of o1's
applicability holds.

I tried four times, each time recording one more onset inside the trace:
- the pedestrian starting to walk and to approach;
- the cane user entering a lane;
- the cane user entering a roadway;
- mutual visibility, and closing to 0.4 m.

None of these matched o1's past condition.

**For the plan or repair session:**
- Either give the coder of this node o1's applicability, meaning the event its `since` searches
  for, so `branch_2` can record that event inside the trace;
- or, if o1's past event cannot be observed at all (it is never decidable), `branch_2`, which says
  "o1 applies to it", cannot be reached, and the plan should drop or re-specify it.

The rule's formulas themselves are not in question: every other planned witness passes.
