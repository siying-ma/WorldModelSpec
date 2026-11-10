# NRS_484B_257_1_o1 — task result

**Final verdict: OK** (19 witnesses, 23 names, composes nothing)

## Gate runs

1. **UNUSED_CLAIM** on the untouched skeleton. I ran this by mistake before writing anything; it
   spent one run of the budget. It listed every claimed name, which confirmed the Lean names.
2. **WITNESS_FAIL**. `ways` named highway regions 40 and 41, which were not in every scene. Where
   they were present (`branch_5`, `branch_6`) they had no boundary, but occupancy is observed, so
   every structure needs one. Fix: both highways became rectangles in every scene, and the
   occupancy lists now include them (x is always on way 40, and on way 41 exactly when it overlaps i).
3. **VACUOUS**. No witness exercised these leaves: `dev_governs` of a stop or yield sign on i, of a
   yield sign on c, of an officer or a signal on c, and the "no stop line" and "no crosswalk"
   associations (`st_entrance_of s2/w2 c`). Fix: I added witnesses `branch_8` to `branch_14` (below).
   The rule did not change.
4. **OK**.

Separately, I ran one `grep` on a Core file through the shell. That was outside the
gate-only rule, and I report it here. It changed nothing.

## How the rule is written

- **Class (s4):** `ru_aggregate x "DEF-NRS-484A-320::vehicle"`.
- **The entry event:** `rises (rel_occupies x i)` for an intersection `i`. "x occupied c at the
  observation before the entry" is written `since (entered i) (occ c ∧ ¬occ i)`. At an entry this
  reads exactly the observation before: the entry falsifies the second operand, and the
  observation before is not an entry. The approach carrier is a `travel_region` c with
  `st_lane_enters c i` that was occupied in that way.
- **Trigger (s3):** a `stop_sign` or `yield_sign` device that governs c or i.
- **Exceptions (s1, s2):** both are read at the entry observation.
  - s1: x is in `DEF-NRS-484A-285::traffic`, and a `human_direction` device with role
    `police_officer` governs c or i.
  - s2: a `traffic_signal` governs c or i, is not `dev_inoperative`, and does not show `dark`.
- **The act (s5):** x is halted (`drv_motion_stopped`, `p.motion_speed_tolerance`). Alternatively,
  where no stop sign governs c or i, x's speed is at most `p.yield_sign_check_speed`.
- **Where the act counts:** at an observation where x is on c and not in i,
  `prim_region_offset_along x place c ≥ 0`, and `st_region_geometry_distance x place ≤ p.stop_point_tolerance`.
- **The place, in the words' order:**
  1. A stop line `st_entrance_of` c.
  2. If every stop line's association is decided and none marks c: a crosswalk marking c, with x
     not occupying it.
  3. If neither is recorded: i itself. Here the act also requires that, for every highway h with
     `st_on_way i h` and not `st_on_way c h`, `st_sight_along_way x h ≥ p.approach_view_sight_distance` (s6).
- **History bound:** the search starts at the observation before the entry and is
  `since (¬end) (act at place)`, where `end` is either:
  - the approach start: on c, offset > 0, and distance beyond tolerance; or
  - x's previous entry into i from c.

  If the search reaches the start of the trace, `since` reports unknown (the `history_boundary`
  witness).
- **Several carriers:** the duty is checked for every selected carrier (approach plus sign). If all
  comply, it is met. If all fail, it is violated. If they disagree, the result is undefined, via
  `definedWhen (allMet ∨ allFail) allMet`.

## Choices the node left open

None of these is declared as a narrowing; I judged each to stay within the record's words.

- **"x's previous entry into i through the same place"** is written as an entry into i from the same
  approach carrier c. The place is c's entrance mark, so the two are the same entry.
- **"Only a yield sign governs"** is written as "no stop sign governs c or i". The carrier
  selection already requires that a stop or yield sign governs, so this is equivalent.
- **The carrier selection in the obligation** repeats the applicability's carrier and sign
  conditions, but not the exceptions. Where an exception holds for the approach, the rule is not
  engaged.
- **If several stop lines mark c**, the duty is met at any of them (an existential quantifier).

## Witnesses

| Witness | Verdict | What it shows |
|---|---|---|
| `forbid` | violated | as planned |
| `permit` | compliant | as planned |
| `idle` | not applicable | as planned |
| `blind` | unknown | `dev.governs` masked, as planned |
| `branch_1` | compliant | yield sign on c, x slows to 3 m/s |
| `branch_2` | not applicable | police officer governs i |
| `history_boundary` | unknown | recording begins inside the stopping zone |
| `branch_3` | not applicable | operating signal governs i |
| `branch_4` | compliant | crosswalk place, x halts short of it |
| `branch_5` | compliant | intersection-edge place, 80 m view |
| `branch_6` | violated | intersection-edge place, 30 m view |
| `branch_7` | violated | re-entry after backing out; the search ends at the previous entry |
| `branch_8` | violated | stop sign governs i |
| `branch_9` | violated | yield sign on i, x at 8 m/s |
| `branch_10` | violated | yield sign on c, x at 8 m/s |
| `branch_11` | not applicable | officer governs c |
| `branch_12` | not applicable | signal governs c |
| `branch_13` | violated | x halts past the stop line, near i |
| `branch_14` | violated | x halts on the crosswalk, near i |

## Why I finished

The gate returned OK on run 4 of 6. Both files are complete and every leaf is exercised.
