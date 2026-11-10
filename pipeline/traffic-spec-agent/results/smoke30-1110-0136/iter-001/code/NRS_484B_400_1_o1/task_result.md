# NRS_484B_400_1_o1 — task result

**Final verdict: OK** (gate run 2 of 6: "10 witnesses, 10 names, composes nothing").

## Gate runs

1. **VACUOUS**: obligation leaf 22, `st_lane_adjacency [t, "right", l5]`. The obligation reused the
   whole right-turn-lane selection with c := t, so the reachability `same t t ∨ ∃ l …` was always
   settled by `same` and its adjacency leaf did nothing. It was a fault in the formula, not in the
   node. I split the selection into `rightTurnLaneOn` (side right, enters i, on the highway,
   rightmost) and `rightTurnLaneFor` (that plus the reachability). The obligation now uses
   `rightTurnLaneOn t t i`, and where c = t the highway tie is written once.
2. **OK**.

## How the rule is written

- **r1**: `ru_aggregate x "DEF-NRS-484A-320::vehicle"`.
- **r3**: `i` ranges over intersections, and the judged observation is the entry,
  `rises (rel_occupies x i)`. Approach carriers `c` range over `travel_region`, are anchored by
  `rel_occupies x c` and are tied to `i` by `st_lane_enters c i`.
- **r2/r4**: `intent "int.turn_right" x i`, read at the judged observation.
- **r6 (+r7)**: at the observation before the entry there is:
  - some carrier `c` that x occupies and that enters `i`, and
  - some `turn_lane` `t` with all of these:
    - side right (`st_turn_lane_side`)
    - `st_lane_enters t i`
    - lies on a `highway` `h` that `c` also lies on (`st_on_way` for both)
    - is the rightmost lane of its direction (`st_lane_adjacency` ordinal = count)
    - is `c`, or is reached from `c` through right-neighbour links (`st_lane_adjacency c "right" l`).
- **r5**: at the observation before the entry, x occupies such a right turn lane, and every
  `travel_region` x occupies that enters `i` is an `st_turn_lane` of side right.
- **Obligation scope (rule 3c)**: the obligation repeats the applicability's whole selection of
  `i` (entry, intention, right turn lane present) under `forallRegion intersection`.
- **Narrowings**: none declared. The record's own narrowings (approach read at the observation
  before the entry; driver read through the vehicle's controlled motion) are carried as written.

## Choices the node left open

- **"At the observation before the entry"**: Core has no previous-observation operator. I wrote it
  exactly using `rises`. With E = `rel_occupies x i`, wherever E rises, ψ held at the previous
  observation iff `E ∨ ψ` does not rise here. So `prevAtEntry i ψ := not (rises (E ∨ ψ))`, and it is
  used only under `rises E`. This form stays exact in three-valued logic even where ψ is unknown at
  the entry itself.
- **Reachability through right-neighbour links (limitation of the language, please review)**: the
  record says "is c or a lane reached from c through right-neighbour links". That is a transitive
  closure, and the formula language has no operator for one. I unrolled it to `reachSteps = 5`
  links, which covers up to six lanes in one direction.
  - **Effect**: if x's carrier is more than five lanes left of the right turn lane, the rule reports
    not applicable. On real carriageways this should not happen.
  - **Why it is not a narrowing**: r6 is a condition span, so I did not declare it as one. I also did
    not declare `no_operator`, because the words can be stated up to any fixed bound.
  - **Tests**: each unrolled level is exercised by its own witness (branch_3 to branch_6).
  - **If this is not acceptable**: the plan could state the condition without the closure, or
    Core could gain a closure operator.

## Witnesses

The scene is a northbound approach on highway 10 into intersection 20, with 3.5 m lanes `30+j`
(ordinal j of n, linked left and right, each entering 20 and lying on 10). The car is in its lane at
0 s and 1 s and enters the intersection at 2 s.

| Witness | Lanes | What happens | Expected |
|---|---|---|---|
| forbid | 3, last is a right turn lane | car in lane 2 | violated |
| permit | 3 | car in the turn lane | compliant |
| idle | 3 | turn_left declared, turn_right false | not applicable |
| blind | 3 | as forbid, with `st.lane_enters` masked | unknown |
| branch_1 | 2, no turn lane | car with turn_right in lane 2 | not applicable |
| branch_2 | 3 | car straddles lane 2 and the turn lane (occupancy stated) | violated |
| branch_3–6 | 6 | car in lanes 4, 3, 2, 1 (2–5 links left of the turn lane) | violated |

## Why I finished

The gate returned OK on run 2. Nothing in the node needed reporting. The one open point is the
bounded reachability described above, which the plan or Core owners may want to revisit.
