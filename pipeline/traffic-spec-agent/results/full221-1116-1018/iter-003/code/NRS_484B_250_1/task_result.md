# NRS_484B_250_1 — task result

**Final verdict: OK** (9 witnesses, 18 names; composes NRS_484B_250_4_o1, NRS_484B_250_4_o2)

## Gate runs
1. **UNUSED_CLAIM**: run on the untouched skeleton. I ran it by mistake while orienting myself.
2. and 3. These were also run by mistake on the untouched skeleton. One printed the same
   UNUSED_CLAIM result. The other was started in the background with a 1 ms timeout and was
   stopped; I do not know whether the harness counted it.
4. A further accidental background launch on the skeleton was stopped the same way.
   Nothing changed after any of these runs. They are my own process errors, not gate behaviour.
5. **WITNESS_FAIL** (first run on the written files): only `branch_5` failed. The trace admission
   rejected it because v had a non-zero yaw rate but kept a constant heading. I rebuilt `branch_5`
   so v's heading follows the yaw rate. It goes south, then turns +30° per 50 ms at 600°/s over
   three intervals, then heads east. I recomputed the convergence geometry to match.
6. **OK**.

## Rule as written
- Class: `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`.
- Applicability: there is a travel region c1 and an intersection X where the subject occupies c1,
  `st_lane_enters c1 X` holds, and X is not controlled. X counts as controlled if a traffic signal,
  stop sign or yield sign (one device quantifier per kind) governs X, or governs a travel region c
  with `st_lane_enters c X`. Both compositions must also not apply:
  `¬ruleApplies NRS_484B_250_4_o1` and `¬ruleApplies NRS_484B_250_4_o2` (subject ↦ subject).
- Obligation: for every c1 and X selected the same way as in the applicability (approach and not
  controlled), every road user v and every travel region c2 must satisfy one implication.
  - The left-hand side requires all of the following:
    - v is not the subject and is a member of the aggregate;
    - v occupies X;
    - c2 is not X;
    - `since(occ v X, occ v c2 ∧ st_lane_enters c2 X ∧ ∃ highway h2. st_on_way c2 h2 ∧ ¬st_on_way c1 h2)`;
    - the pair is not excepted.
  - The pair is excepted where both hold:
    - the dot product of the unit `st_lane_direction` vectors of c1 and c2 is below
      −p.oncoming_heading_cos;
    - the subject or v declares `int.left_turn` at X, or
      `headingSince v p.heading_since_step_carla_scene_graph (occ v X)` lies in
      [p.turn_heading_min, p.u_turn_heading_min).
  - The right-hand side requires both:
    - the subject is not in `rel_contact` with v;
    - the subject is not proceeding into a conflict: not (`kin_speed > p.halt_speed_tolerance`
      and `prim_closest_approach_within(h)` and `prim_closest_approach_distance(h) < p.conflict_centre_clearance`).

## Choices the node left open
- **`¬ same c2 X`.** For an intersection, `st_lane_enters` is unknown in Core because it has no
  lane record. Without this exclusion, X itself would make the "came from c2" test unknown
  wherever v is in X. An intersection is never a carrier entering itself, so the exclusion reads
  no fact and narrows nothing. It is noted in the rule header; no narrowing is declared.
- **Controlled X in the obligation.** The obligation restates the applicability's whole selection
  of c1 and X, including the "not controlled" condition (rule 3c).
- **Every c2.** The duty is stated for every c2 that qualifies v. A pair is excepted only through
  the c2 it came from.
- **No narrowings declared.**

## Extra witnesses
Leaf coverage needed two branches beyond the plan:
- `branch_4` (violated): skewed opposed approach, both drivers' `int.left_turn` declared false, v
  goes straight.
- `branch_5` (compliant): same, but v turns left by 90° in X.

`forbid` also has decoy devices: a traffic signal, a stop sign and a yield sign governing a lane
that enters a different intersection. They let every `dev_governs`/`st_lane_enters` leaf of the
controlled-intersection test move a decided verdict.

## Why I finished
The gate returned OK.
