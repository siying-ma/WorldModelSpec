# NRS_484B_477_1b — task result

**Final verdict: OK** (17 witnesses, 19 names, composes nothing). 3 of 6 gate runs used.

## Gate runs
1. **UNANCHORED_VARIABLE** — `edge_left` / `edge_right`, the edges in "some road edge lies on that side", were linked
   to the subject only through `prim_region_lateral_offset`, and the gate does not count that as an anchoring relation.
   **Fix:** the existential now reads "some road edge on that side at ≥ 10 ft" (`st_region_geometry_distance`).
   The side-free conjunction already requires every road edge on that side to be at ≥ 10 ft, so this means the
   same thing.
2. **VACUOUS** — no witness used the right-side road-edge leaves (applicability leaves 14–17), because no scene
   left the right side free. **Fix:** added `branch_13` (not_applicable), the mirror of `branch_3`: left edge
   0.3 m away, right edge 4.0 m away.
3. **OK**.

## How the rule is written
- Class: `ru_aggregate subject DEF-NRS-484A-320::vehicle`.
- Applicability is the conjunction of:
  - the subject occupies an alley (b5);
  - `¬asm.business_district` (b4);
  - `¬asm.local_alley_ordinance` (b1);
  - neither side is free (b6).

  A side is free when all four of these hold:
  - some road edge lies on that side;
  - every road edge on that side is ≥ 10 ft away (`Units.feet 10`), measured with `st_region_geometry_distance`;
  - every obstruction on that side is ≥ 10 ft away;
  - every member of traffic that is at rest, alongside (`rel_longitudinal_overlap ≥ 0`) and on that side has a
    lateral `rel_surface_gap` ≥ 10 ft.

  The side is read from the sign of `prim_region_lateral_offset` for regions and from the `rel_bearing` left/right
  for road users.
- Obligation: `¬(complete_halt(subject) ∧ ¬(governedHalt ∨ queueHalt))`.
  - `governedHalt`: the subject occupies a travel region governed by a traffic signal, stop sign, yield sign,
    railway signal or gate, or a person directing traffic.
  - `queueHalt`: a member of traffic is ahead of the subject in its lane, with a `rel_surface_gap` distance
    ≤ `p.queue_halt_gap`.

## Choices the node left open
- **Excluding the subject from the road-user quantifiers:** no explicit `same` test is used.
  - In the alongside clause, the subject is excluded because its bearing to itself is neither left nor right.
  - In the queue clause, it is excluded because `rel_ahead_behind_in_lane` is false for a road user and itself.
- **Queue gap:** `rel_surface_gap` is read without a component, which its contract defines as the distance between
  the bodies.
- **No narrowings declared.** Each reading above is the record's own or exactly equivalent to it.

## Witnesses added beyond the plan
| Witness | Verdict | Scene |
|---|---|---|
| `branch_4` | violated | obstruction 1 m away on the left; left edge 4 m away |
| `branch_5` | violated | no road edges mapped |
| `branch_6` | violated | obstruction 1 m away on the right; right edge 4 m away |
| `branch_7` | violated | vehicle at rest on the right with a 1.5 m gap |
| `branch_8` – `branch_12` | compliant | a halt in a lane governed by each of the five device kinds |
| `branch_13` | not_applicable | right side free |

## Why I finished
The gate returned OK.
