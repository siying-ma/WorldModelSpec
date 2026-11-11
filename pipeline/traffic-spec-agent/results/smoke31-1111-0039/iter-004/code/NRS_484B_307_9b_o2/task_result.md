# NRS_484B_307_9b_o2 — task result

## Final verdict: BARE_LITERAL (a conflict between the node, Core and the gate, not a defect in the files)

```
BARE_LITERAL
   formula literals [] ≠ the node's declared literals [('2', 'count')]; a figure the law states is declared on its span, any other magnitude belongs in the reading
```

Everything else in the two files passes the gate. A diagnostic run, described below, returned
`OK — 18 witnesses, 12 names, composes nothing; narrowings declared by the coder: 1`.

## Gate runs (4 of 6 used)

1. **BARE_LITERAL** — the first full draft. The literal "two" of span c9 was written where the
   node puts it: as the `Nat` bound of `Formula.count` (`.count edge waiting .gt 2`). The gate's
   literal check (`Formula.literals`) collects only `Term.lit` values, so it finds no literal.
2. **WITNESS_FAIL** (diagnostic) — to test the rest of the files, I temporarily conjoined an
   always-true comparison `2 count > 0` that carried the literal. All witnesses with a straight
   passage passed. The eight turning witnesses failed adapter admission: the heading did not
   follow the yaw rate. *Change:* a turn is now two exact 45° heading steps (±900 deg/s at k 80
   and 81, heading north → NW/NE → W/E). The velocity at the diagonal scene is left unobserved
   because that heading is not a unit vector.
3. **OK** (diagnostic, still with the always-true comparison) — 18 witnesses. Adequacy,
   anchoring, declarations and parameters all pass.
4. **BARE_LITERAL** — I removed the always-true comparison. It said nothing about the law and was
   there only to satisfy the literal check, so I did not leave it in the rule. These are the files
   as they stand now.

## Why the node and the gate disagree (what must change)

The node's obligation for span c9 says: "Counted from the start of that run (**Formula.count** …),
the rises … number more than the literal of span c9 (comparison gt)". It also declares the literal
`{span: c9, text: "two", value: 2, unit: "count"}`.

In Core, `Formula.count (edge) (sinceφ) (op : CmpOp) (n : Nat)` takes its bound as a bare `Nat`.
No `Term` counts the rises of a formula, so the language has nowhere a `Term.lit 2 .count` could
meaningfully appear. The gate's BARE_LITERAL check requires the declared literal among the formula's
`Term` literals, so the planned reading cannot pass it. Whatever the rule says, the only way through
is a meaningless comparison that carries the number, and I won't do that.

One of these has to change (it's for the harness/Core owners or the plan agent to decide; I can't
fix it from the rule):
- the gate's literal check also accepts the `n` of `Formula.count` (with unit `count`) as the
  written form of a declared count literal; or
- Core gives `count` a `Term` bound; or
- the plan stops declaring the c9 count as a `literals` entry, keeping it only as the bound of the
  `count` operator the obligation names.

## How the rule is written (also in the header comment of the rule file)

- **Class (c2, c4):** the `or` of the five `ru_aggregate` atoms, each with its aggregate id.
- **Applicability (c1, c5, c6):** judged at x's leaving of an intersection i
  (`drv_motion_leaving_region`). A `since` reaches back to x's latest entry
  (`drv_motion_entering_region`). Every observation in between is one where x occupies i or leaves
  it and does not enter it again, so the entry found is the latest one. At the entry, x occupies a
  travel region c with `st_lane_enters(c, i)`, and a traffic signal s governing c or i shows
  `circular_red` and `green_arrow(d)`. The passage is read at the leaving from
  `drv_motion_heading_change_since_entry` (step `p.heading_since_step_carla_scene_graph`):
  - straight: |H| < `p.turn_recognition_angle`;
  - left turn: H ≥ the angle;
  - right turn: H ≤ −the angle.

  Under a left arrow the rule applies to straight or right; under a right arrow, to straight or
  left. Each arrow side is a separate disjunct because the side is a spelling.
- **Obligation (c9):** the same leaving and entry selection is written again (rule 3c). It is
  split at the leaving by passage (straight / right turn / left turn) because the permissive arrow
  depends on the movement. At the entry, for every selected c and s:
  - `count (red ∧ green_arrow(d)) (halted ∧ occupies c) gt 2`;
  - and a `since` anchored at the first observation of the wait (`rises waiting`, not permissive
    there) that holds while no later observation is in the wait with `circular_green` or
    `green_arrow(<movement>)` showing.

  A wait that began before the recording leaves both unknown (truncated `count`/`since`).

## Choices the node left open

- **c9, declared narrowing (kind `reading`):** the duty is required of *every* carrier c and
  signal head s that meet the selection at the entry (`forallRegion`/`forallDevice` with
  implication), not of one chosen among them. This follows the `st.lane_enters` contract: a rule
  never picks the carrier that favours the road user.
- **Turn thresholds:** a turn is at or beyond the recognition angle (≥ / ≤ −). The record fixes
  only "straight = absolute value below the angle".
- **Latest entry:** made exact by requiring "not entering again" at every observation between the
  entry and the leaving.

## Witness notes

- **`idle` does not follow the plan's narrative.** The plan asks for a passenger car
  (`ru.motor_vehicle`). Under the run's reading, `ru.motor_vehicle` is *unresolved* for the
  motorcycle, moped, electric-bicycle and electric-scooter aggregates. A car therefore leaves the
  class unknown and the verdict unknown, not not_applicable. The witness is built with
  `ru.pedestrian`, which is decided false for all five aggregates. The plan's idle narrative should
  name a class the reading excludes.
- **Electric scooter aggregate:** `DEF-NRS-484B-018::electric_scooter` has no included class in
  this reading (`ru.electric_scooter` is only unresolved), so no witness can decide it true. Its
  leaf is exercised only through the `idle` witness.
- **`window` (50–4950 ms) on every witness:** at the first scene the entry and leaving concepts
  have no earlier observation of x.
- **Added branches:**
  - branch_2–4: right arrow, straight passage (violated, compliant, green during the wait).
  - branch_5–7: left arrow, right turn (same three).
  - branch_8–10: right arrow, left turn (same three).
  - branch_11: the head governs i, not c (violated).
  - branch_12 and branch_13: a turn in the arrow's own direction (not applicable).

## Why I finished

The only remaining verdict, BARE_LITERAL, comes from the planned reading (`Formula.count` with a
declared count literal) meeting a gate check that the language cannot satisfy honestly. The
instructions say to fix such a verdict against the node once and, if it persists, to report it.
With the literal written the only way the language allows, it persisted. The rest of the work is
complete and checked by the gate's OK on the diagnostic run.
