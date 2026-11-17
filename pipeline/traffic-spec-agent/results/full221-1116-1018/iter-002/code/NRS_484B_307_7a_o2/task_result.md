# NRS_484B_307_7a_o2 — task result

**Final verdict: OK** (8 witnesses, 14 names, composes nothing). Gate runs used: 2 of 6.

## Gate runs
1. `WITNESS_FAIL`: `blind` came back unknown for `absent_atom:st_lane_enters` as well as for the
   masked `st.entrance_of`. The carrier `c2` of the adjacent-crosswalk test ranges over
   `travel_region`, and that kind includes the intersection `i`. `i` has no lane record, so
   `st_lane_enters i i` is unobserved. In `forbid`, `st_entrance_of w i = false` settled that
   case. In `blind`, with entrances masked, both atoms were unknown and both reasons were reported.
   - **Change:** added `not (same c2 i)` to the carrier selection in the rule. A region that
     enters `i` is never `i` itself (st.lane_enters: a carrier is an approach to the intersection
     it enters), so this adds no condition that `st_lane_enters c2 i` doesn't already imply. It is
     not an exclusion of a region kind. The header records it.
2. `OK`.

## Choices the node left open
- **Applicability:** the record's two limbs are written as one formula:
  `∃ intersection i, ∃ traffic_signal s, since (occupies subject i) (facing i s)`.
  - Limb one: the subject is in an approach `c` of `i` that `s` governs, and `s` shows the arrow now.
  - Limb two: the subject is in `i`, and has been at every observation since it faced `s` from
    such a `c` with the arrow shown.
  - The two-limb form and this one are equivalent: Core's `since` is `ψ ∨ (φ ∧ since')`.
  - Writing limb one separately as well would have added a duplicate leaf.
- **Flashing yellow turn arrow:** `flashing_yellow_arrow(left | right | u_turn)`, as element s1
  states.
- **Vehicular traffic:** the subject must be in both aggregates, traffic and vehicle.
- **Obligation:** repeats the applicability's whole selection of `i` and applies the duty to every
  selected `i` (rule 3c). Under it, the duty covers every road user `p` that:
  - is not the subject;
  - is in the pedestrian aggregate;
  - is in `i`, or in a crosswalk recorded as marking the entrance of a travel region (≠ `i`) that
    enters `i`.
- **The duty itself:** both of these must hold:
  - not (speed > `p.halt_speed_tolerance` ∧ `prim_closest_approach_within` ∧ distance <
    `p.conflict_centre_clearance`);
  - no `rel_contact`.
- **Narrowings:** none of my own. The node's own narrowing (s7, "lawfully" not judged) is not
  restated.

## Witnesses
Geometry:
- Intersection: [-10, 10]².
- Left-turn lane `c`: northbound, enters `i`; head `s` governs it.
- Cross-street eastbound approach `c2`: enters `i`.
- West-leg crosswalk `w`: marks `c2`.

There are two instants 1 s apart. At 0 s the car is in `c`, heading north at 7 m/s. At 1 s it is
in `i`, heading west at 7 m/s.

| Witness | Expected | What it tests |
|---|---|---|
| `forbid` | violated | Pedestrian in `w`; at 1 s the closest approach is about 1.1 s ahead, well under 1 m apart. |
| `permit` | compliant | The car is the only road user. |
| `idle` | not applicable | `s` shows circular_green only. |
| `blind` | unknown | Same as `forbid` with `st.entrance_of` masked. |
| `branch_1` | violated | Pedestrian inside `i` itself, the "within the intersection" limb. |
| `branch_2` | compliant | The approach is within the horizon but about 6 m apart, which exercises the clearance leaf. |
| `branch_3` | compliant | The car halts in `i` while a pedestrian approaches within the clearance without touching it, which exercises the speed leaf. |
| `branch_4` | violated | The halted car's body overlaps a pedestrian standing in `i`, which exercises the contact leaf. |

## Note for the harness / Core
- `st_lane_enters` reads a region with no lane record (any intersection) as unobserved, not false.
- So any rule that quantifies a carrier over `travel_region` against `st_lane_enters` will
  report extra unknown reasons whenever its other conjunct is masked.
- I handled this here with `not (same c2 i)`. An intersection other than `i` in the same scene
  would still be undecided.

## Why I finished
The gate returned `OK`.
