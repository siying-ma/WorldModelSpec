# NRS_484B_210_2 — task result

## Final verdict: OK
`4 witnesses, 10 names, composes nothing`

## Gate runs
0. By mistake, my first shell call was the gate command with `| head -0; true` appended. That broke
   the "exactly this command" rule. It printed nothing, and it may have counted as a run against
   the budget. It was run on the unchanged skeletons, so it had no effect on the files.
1. Baseline on the skeletons: `UNUSED_CLAIM`, listing every claimed name, `kin_velocity`,
   `rel_bearing`, `rel_longitudinal_overlap` and `rel_same_direction` included. That confirmed the
   occasion's `under_way` atoms count as claims and have to be written in `U`.
2. After writing the rule and the four witnesses: `OK`.

## How the node is written
- **Class (s1):** `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`.
- **Applicability (s2):** `existsUser b`. b is not the subject, b is in the same aggregate, and
  `drv_interaction_overtake_pass_on_right(subject, b)` holds with `[p.overtake_window,
  p.overtake_same_direction_cos]`. The concept holds only at the recognition.
- **Obligation (s2 + s3):** `forallUser b`, with the full selection repeated, implies the occasion's
  `throughout` shape `holdsFor .time p.overtake_window subject (U → ∀u ≠ subject. safe(u))`.
  - `U` is three things:
    - b is not ahead-aligned at this observation, and `since (¬AA) AA` holds.
    - `AA` means b is ahead (`rel_bearing "ahead"`), `rel_longitudinal_overlap < 0`, and
      `rel_same_direction` holds over the cosine parameter.
    - The subject's velocity exceeds b's along the subject's direction of travel:
      `v_s·v_s > v_b·v_s`, from `kin_velocity` components. It is multiplied through by |v_s|, so
      there is no division by a measured quantity.
  - `safe(u)` is `¬rel_contact` and not (`prim_closest_approach_within` with
    `prim_closest_approach_distance < p.conflict_centre_clearance`), both over
    `p.conflict_horizon`.

## Choices the node left open
- **"After the act's beginning"** is written with `since` from each observation in the window: an
  ahead-aligned observation comes earlier, with none since. If b was ahead, then alongside, then
  ahead again within the window, the duty also checks the earlier alongside observations. That
  checks more observations, never fewer, so I declared no narrowing. It is explained in the
  rule's header.
- **The velocity condition** of `under_way` is kept as a condition on `U`, as the record words it
  ("while the subject's velocity … carries it up to and past b").
- **No narrowings** were declared.

## Witnesses
- **Shared setup:** a road heading east, with b on the subject's left at a 4 m lateral offset. The
  subject runs at 20 m/s and b at 15 m/s. b goes from 17 m ahead to 8 m behind over six 1 s
  instants, and the first scene is repeated for 12 s before so the windows are covered. Each
  scenario's `window` is 0–5000 ms.
- **forbid:** the subject closes to a 2 m centre offset while side by side, so the closest approach
  is 2 m, below the 3 m bound.
- **permit:** a 4 m offset is kept throughout.
- **idle:** the two cars follow each other in one lane at a steady 20 m gap.
- **blind:** the permit geometry with the four masked ids.

## Why I finished
The gate returned `OK`.
