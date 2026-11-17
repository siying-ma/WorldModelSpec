# NRS_484B_450_1k — task result

**Final verdict: OK** (12 witnesses, 23 names, composes nothing).

## Gate runs (3 of 6 used)

1. **UNUSED_CLAIM**: run on the untouched skeleton by mistake, before I had written anything. It listed every claimed name, which is expected for the placeholder `.tt` formulas.
2. **CHECK_FAIL** (`units: compares m^2 with m`): I wrote the opposite-side test as the product of the two lateral offsets compared with `zeroMetres`. I changed the comparison target to `zeroSquareMetres := .mul zeroMetres zeroMetres`, which is zero with the right unit.
3. **OK**.

One more attempted command was blocked by permissions and never ran. It was a `--help` call to the gate.

## How the rule is written

The record's own `applicability` and `obligation` fields decide what goes where:
- **Applicability:** where the vehicle is (s9) and whether halting there would obstruct traffic (s10).
- **Obligation:** the halt (s2) and its exceptions (s3–s7).

The spans:
- **s1:** `ru_aggregate(subject, DEF-NRS-484A-320::vehicle)`.
- **s9:** there is an obstruction `o` of any kind on a highway `h` that the subject occupies (`st_on_way o h`, `rel_occupies subject h`). The offset `prim_region_lateral_offset(subject, o)` is not zero, and `st_region_geometry_distance(subject, o)` is at most the absolute value of that offset.
- **s10:** that distance is less than `p.free_passage_width`, and there is no road edge `e` on the side opposite `o` at a distance of at least `p.free_passage_width`. "Opposite side" means the product of the two offsets is below zero.
- **s2:** the obligation is `¬drv_motion_complete_halt(subject, p.halt_speed_tolerance)`, unless an exception holds.
- **s3/s4:** some road user `u` who is not the subject, belongs to `DEF-NRS-484A-285::traffic`, is ahead in the subject's lane (`rel_ahead_behind_in_lane u subject`), and whose body gap `rel_surface_gap(subject, u)` (distance form) is at most `p.queue_halt_gap`.
- **s5/s6/s7:** within a travel region the subject occupies, one of these devices governs it:
  - a stop sign;
  - a yield sign;
  - a traffic signal showing `circular_red`, `flashing_red` or `red_arrow` in any direction;
  - a railway signal or gate with lights `flashing`, or gate `lowering` or `down`;
  - a human direction with role `police_officer` and indication `stop`.

## Choices the node left open

- **s5 and s7 written once.** The record's exception (b) (s5: a stop sign or a red signal) is entirely contained in its exception (d) (s7). I wrote them as one disjunction rather than repeating the same leaves, which would have left duplicates that do no work. The meaning is the record's (b) ∨ (c) ∨ (d).
- **"Opposite sign" written as a product below zero (m²).** This is exactly what the record states.
- No narrowings are declared, because no reading went beyond the record.

## Witnesses

- `forbid`, `permit`, `idle`, `blind`, `branch_1` and `branch_2` follow the planned narratives, with the geometry described in the witness header.
- I added these branches, all compliant, so that every exception leaf is exercised:
  - `branch_3`: stop sign;
  - `branch_4`: yield sign;
  - `branch_5`: signal showing `circular_red`;
  - `branch_6`: railway lights flashing, gate up;
  - `branch_7`: railway gate down, lights dark;
  - `branch_8`: a halted motor vehicle 2 m ahead in the same lane.

## Why I finished

The gate returned OK, and no defect was found in the node or in any concept.
