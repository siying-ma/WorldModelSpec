# NRS_484B_257_2_o2 — task result

**Final verdict: OK** (13 witnesses, 16 names, composes nothing)

## Gate runs
1. **VACUOUS**: obligation leaves `ru_aggregate subject DEF-NRS-484A-285::traffic` and
   `dev_human_direction_role d police_officer` (both in the obligation's re-selection of X and c).
   - Role leaf: a witness was missing. Added `branch_9` (violated): a *flagger* directs on c and a
     yield sign governs c, so the span-a exception does not apply.
   - Traffic leaf: no scene can move it. Whenever the rule is engaged, the subject is a vehicle,
     and every class `DEF-NRS-484A-320::vehicle` includes or leaves unresolved is an included
     class of `DEF-NRS-484A-285::traffic`. Where the police conjunct holds, the applicability is
     already false. The obligation's re-selection therefore leaves this conjunct out and denotes
     the same (X, c); the rule header explains this. The applicability keeps the conjunct, and
     `branch_3` exercises it there.
2. **OK**.

Total gate runs: 2. A stray first Bash call (the gate command with an extra `ls`) was denied and
never ran, so it is not counted as a gate run.

## How the rule is written
- **Entry (h, a, b):** at the entry observation:
  - `rises(occupies subject X)`;
  - `since(occupies subject X, occupies subject c)`, meaning the subject was on c just before,
    or overlaps both;
  - c is a `travel_region` with `st_lane_enters c X`;
  - a stop or yield sign governs c or X;
  - no police officer's direction (with the subject a member of traffic) governs c or X;
  - no traffic signal that is not inoperative governs c or X.
- **Applicability:** `∃X:intersection ∃c:travel_region [occupies subject X ∧ since(occupies subject X, entry)] ∧ speed > p.halt_speed_tolerance`.
  This is the latest entry, because a rise of the occupancy cannot recur while it holds
  continuously.
- **Obligation:** `∀X ∀c [same selection → ∀v (v ≠ subject ∧ vehicle(v) ∧ protected(v,X) → ¬contact ∧ ¬(moving ∧ within ∧ distance < clearance))]`.
- **protected(v, X):** some carrier c2 entering X (c2 ≠ X), with no stop or yield sign governing
  c2 or X, such that:
  - `since(occupies v X, occupies v c2)`; and
  - v overlaps X, **or** v is on c2 and its closest approach is within the horizon at a centre
    distance below the clearance.

## Choices the node left open
- **`.not (.same c X)` and `.not (.same c2 X)`:** X is an intersection, which is itself a
  `travel_region`. In the carrier quantifiers, `st_lane_enters X X` would be unobserved rather
  than false, because an intersection records no entry. A carrier is never the intersection it
  enters, so this adds no condition the record does not state.
- **Device conditions:** they are read at the entry observation itself, the one where the
  occupancy of X rises, as the record says.
- **Narrowings:** none of my own.

## Witnesses
| Witness | Expected | What it shows |
|---|---|---|
| forbid | violated | yield sign on c; subject and v on a collision course in X (centres meet 1.2 s ahead) |
| permit | compliant | subject waits at rest; enters X while v is in X but moving away; then v leaves X |
| idle | not applicable | no signs |
| blind | unknown | forbid scene with `dev.governs` masked |
| branch_1 | compliant | subject alone |
| branch_2 | compliant | all-way stop; v is obligated |
| branch_3 | not applicable | police officer directs on c |
| branch_4 | not applicable | operating signal on X |
| branch_5 | violated | inoperative signal on c, yield sign on c |
| branch_6 | violated | v still on unsigned c2, an immediate hazard |
| branch_7 | compliant | yield sign on X itself, so v is obligated |
| branch_8 | compliant | stop sign on X itself, so v is obligated |
| branch_9 | violated | flagger, not police, on c |

## Why I finished
The gate returned OK.

## Note for the plan
In this node, the obligation's re-selection of X and c (rule 3c) repeats the applicability's
exception conjuncts. The `traffic` membership conjunct of span a is redundant for any vehicle
subject, because DEF-NRS-484A-320::vehicle is contained in DEF-NRS-484A-285::traffic, so the
VACUOUS check cannot be met for it inside the obligation. I left it out of the obligation only.
If the plan prefers, it could drop the `traffic` claim from span a's element, since the subject's
class already entails it.
