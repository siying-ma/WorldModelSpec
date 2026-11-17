# LVMC_11_52_030_A — task result

## Final verdict: WITNESS_FAIL (node defect; the two remaining failures cannot be fixed in Lean without contradicting the record)

```
WITNESS_FAIL
   branch_1: expected not_applicable, got unknown for [aggregate_unresolved:DEF-LVMC-11-02-150::tour_bus, aggregate_unresolved:DEF-LVMC-11-02-150::shuttle_bus, aggregate_unresolved:DEF-LVMC-11-02-090::limo]
   branch_5: expected not_applicable, got compliant
```

Every other witness passes: forbid, permit, idle, blind, branch_2, branch_3, branch_4, and the
witnesses I added (branch_6 to branch_10).

## Gate runs (5 of 6 used)

1. **UNUSED_CLAIM** — run on the unmodified skeleton, where every formula was still `.tt`.
2. **UNUSED_CLAIM** — the same skeleton again. I started this run by mistake, without changing anything.
3. A third run, also started by mistake, on the unchanged skeleton (I moved it to the background with no useful output).
4. **WITNESS_FAIL** — the first run on the written rule and witnesses. There were four failures:
   - branch_1 and branch_5 failed because of the node (see below).
   - branch_4 and branch_10 failed because the mail drop box had no outline: a structure needs a
     boundary when occupancy is observed. I rebuilt the box as a 0.6 × 0.6 m rectangle.
5. **WITNESS_FAIL** — only branch_1 and branch_5 failed. Both come from the node, so I stopped.

## How the rule is written

- **Subject's class:** `ru_aggregate(subject, DEF-NRS-484A-320::vehicle)`.
- **Applicability:** some region `z` of kind `curb_zone` with colour red that the subject occupies, and none of these exceptions holds:
  - **(2)** The subject is a tour_bus, shuttle_bus or limo aggregate, `z` is of kind tour_bus_loading,
    the subject is at rest, and `sinceRise(halt ∧ occupies z) ≤ 30 min`.
  - **(3)** The same with rtc_bus and kind bus_stop.
  - **(4)** The subject is an official vehicle of kind armored_car, or an emergency vehicle.
  - **(5)** Some `obstruction` of kind mail_drop_box is within `p.mail_drop_box_reach` of the
    subject's body (`st_region_geometry_distance`), the subject is at rest, and
    `sinceRise(...) ≤ p.mail_deposit_max_halt`.
- **Obligation:** `halt(subject; p.halt_speed_tolerance)` implies one of:
  - some other road user `u` is ahead of the subject in a shared lane (`rel_ahead_behind_in_lane(u, subject)`)
    with `rel_surface_gap(subject, u) ≤ p.queue_halt_gap`; or
  - the subject occupies a travel region governed by a police officer directing stop, a signal
    showing circular_red, flashing_red or red_arrow (any of the four directions), or a stop sign.

## Choices the node left open

- **The halt test in exceptions (2), (3) and (5).** The halt-duration test is conjoined with the
  subject being at rest now (the halt that s10, s12 and s17 claim). Without it, a moving vehicle
  would be judged on a stale `sinceRise` from an earlier halt, or on one whose start the recording
  never saw. This can only change not_applicable into compliant at observations where the subject
  is moving, so it never changes the duty. It is not declared as a narrowing because the spans are
  exceptions, which must not be narrowed. It is explained in the rule header.
- **Exception (4) has no halt test.** The node's applicability states none, so I added none.
- **The obligation does not restate `z`.** The node's obligation is "halt ⇒ (queue ∨ directed halt)".
  The applicability already places the subject in the red zone at the judged observation.
- **Narrowings:** none declared.

## Why I finished — the node is wrong

### 1. Branch_1 (spans s9/s10) cannot be not_applicable under this run's reading

The reading lists **no included class** for any of these aggregates:
`DEF-LVMC-11-02-150::tour_bus`, `DEF-LVMC-11-02-150::shuttle_bus`, `DEF-LVMC-11-02-090::limo`
(and also `DEF-LVMC-11-02-120::rtc_bus`). Every vehicle class is "unresolved".

`aggregateMembership` (Core `Semantics.lean`) is only ever true for a road user that carries an
included class. So no road user can be a member of these aggregates: exception (2) is unknown at
best, never true. The planned branch_1 ("a tour bus classified under
DEF-LVMC-11-02-150::tour_bus … not_applicable") is unreachable. The rule reports unknown, with
reason `aggregate_unresolved`. The same holds for exception (3) (RTC buses): no witness can ever
make it hold.

**Fix (plan/reading):** either the reading classifies at least `ru.tour_bus_or_limousine` as
included in tour_bus/limo (and some class in shuttle_bus and rtc_bus), or branch_1 is re-planned
to expect `unknown`. Branch_2 (violated after 30 min) already passes.

### 2. Branch_5 (span s3) contradicts the node's own obligation

The node's `obligation` puts the exclusion "necessary to avoid conflict with other traffic"
(a road user ahead in the lane within `p.queue_halt_gap`) **inside the obligation**:
`complete_halt(subject) ⇒ (queue ∨ directed halt)`. A halt in a queue therefore makes the subject
applicable and **compliant**. The planned branch_5 expects **not_applicable**, which is the
verdict only if the exclusion sat in the applicability.

I wrote the obligation as the record states it, rather than moving s3's content into the
applicability to match the planned verdict.

**Fix (plan):** either change branch_5 to expect `compliant`, or move the stopping definition's
exclusions (queue and directed halt) from the obligation into the applicability, as conditions
under which the halt is not "stopping". The device branches I added (branch_7, branch_8,
branch_9, each expecting compliant) follow the same placement and would then need to expect
not_applicable too.

## Note on the session

I wasted three gate runs: one on the unmodified skeleton and two by accident before any file
was edited. One run is left; I did not use it, because the two remaining failures can only be
fixed in the node, not in Lean.
