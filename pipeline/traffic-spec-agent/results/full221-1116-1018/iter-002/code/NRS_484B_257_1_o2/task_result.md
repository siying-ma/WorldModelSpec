# NRS_484B_257_1_o2 — task result

**Final verdict: OK** (22 witnesses, 18 names, composes NRS_484B_257_1_o1).

## Gate runs
1. `UNUSED_CLAIM`: this ran on the untouched skeleton by mistake (every claim was unused while the formulas were still `.tt`). That wasted one run.
2. `VACUOUS`: these obligation leaves were not exercised:
   - the police and signal exception leaves in the obligation's restated selection: `ru_aggregate traffic`, `dev_human_direction_role`, and `dev_governs` p/g on c and X;
   - `dev_governs d X` among the proper signs.

   All witnesses passed. What changed afterwards:
   - **Rule:** the through-highway test ("none of whose carriers entering X is governed…") now excludes X itself (`¬ same c3 X`). X is a travel region whose `st_lane_enters` is never observed, so a sign governing X otherwise left the through-highway test unknown.
   - **Witnesses:** added branch_15 to branch_18 (see below).
3. `OK`.

## How the node is written
- **Subject class:** `ru_aggregate subject DEF-NRS-484A-320::vehicle`.
- **Applicability:** there is an `intersection` X and a `travel_region` c such that:
  - the subject occupies X and is moving (`kin_speed > p.halt_speed_tolerance`);
  - it has occupied X continuously (`since`) since its entry observation e;
  - **e** is where `rises(occupies X)` holds and `since (occupies X) (occupies c ∧ ¬occupies X)` holds. Together these pin "occupied c at the observation before".
  - At e all of the following hold:
    - `st_lane_enters(c, X)`;
    - a stop sign or yield sign governs c or X;
    - no police-officer `human_direction` governs c or X, given the subject is in DEF-NRS-484A-285::traffic;
    - no traffic signal that is not inoperative governs c or X;
    - `.rule NRS_484B_257_1_o1 {subject ↦ subject}` holds (compliance).
- **Obligation:** for every (X, c) satisfying the same whole selection, and for every other vehicle v that is protected through a through highway h_t:
  - **Through highway h_t:** `st_on_way(X, h_t)`, not `st_on_way(c, h_t)`, and no carrier c3 ≠ X entering X on h_t is governed by a stop or yield sign.
  - **v is protected** when, for some carrier c2 entering X on h_t, either (a) v has been in X continuously since it occupied c2, or (b) v occupies c2 and is in conflict with the subject.
  - **The duty:** `¬rel_contact(subject, v)`, and not (the subject is moving ∧ closest approach within p.conflict_horizon ∧ distance below p.conflict_centre_clearance).

## Choices the node left open
- **Entry observation:** read with `rises` plus a nested `since`, as the record words it ("having occupied at the observation before a carrier c"). Every condition read "at that entry observation" is read at e.
- **`¬ same c3 X` in the through-highway test:** X is not a carrier entering itself. This states "carriers entering X" exactly, so it is not a narrowing.
- **Several carriers or intersections:** the applicability takes ∃(X, c), and the obligation takes ∀(X, c) over the whole selection. When the subject entered through several carriers, the duty binds through each one that is selected. No carrier is picked to favour the subject.
- **Narrowings:** none declared.

## Witnesses added beyond the plan
| Witness | Scene | Expected |
|---|---|---|
| branch_4 | police officer directs c | not applicable |
| branch_5 | police officer directs X | not applicable |
| branch_6 | operating signal governs c | not applicable |
| branch_7 | operating signal governs X | not applicable |
| branch_8 | inoperative signal on c | violated |
| branch_9 | yield sign on c | violated |
| branch_10 | stop sign on c2, so h2 is not a through highway | compliant |
| branch_11 | yield sign on c2 | compliant |
| branch_12 | v halted inside X with no conflict | compliant |
| branch_13 | stop sign governs X only; v on the subject's own highway | compliant |
| branch_14 | yield sign governs X only; subject alone | compliant |
| branch_15 | stop sign governs X only; v from c2 in conflict | violated |
| branch_16 | police officer directs another approach | violated |
| branch_17 | operating signal governs another approach | violated |
| branch_18 | two overlapping carriers; police directs only the one through which v would be protected | compliant |

## Notes for later sessions
Some obligation leaves can only be exercised by scenes built for that purpose, because rule 3c makes the obligation restate the exception conditions:
- **Traffic membership and police role (obligation copy):** these only matter when two bindings of (X, c) differ. branch_18 therefore records the subject's carrier c on two highways, which is unusual data.
- **The other exception and sign leaves (obligation copy):** these needed the extra scenes branch_15 to branch_17.

## Why I finished
The gate returned OK on run 3 of 6.
