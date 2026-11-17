# LVMC_11_40_180_C_o2 — task result

**Final verdict: OK** (10 witnesses, 11 names, composes nothing). Gate runs used: 2 of 6.

## Gate runs
1. `CHECK_FAIL` — `measure rel_bearing: component`. I had written the bearing selector as
   `"longitudinal"`, but Core's vector component selectors are `"x"`/`"y"` (`Semantics.comp`).
   The bearing is `(long, lat)` in the subject's frame, so the longitudinal component is `"x"`.
   Fixed that.
2. `OK`.

(Before the first gate run I sent one stray shell command, a no-op `--help` call wrapped around
the gate command. It was denied automatically and nothing ran, so the gate budget was not touched.)

## How the rule is written
- **Class**: the three admitted aggregates (bicycle, electric bicycle, electric scooter) joined by `or`.
- **Applicability** is `existsUser p` with three conditions:
  - p is in `ru_aggregate` DEF-NRS-484A-165::pedestrian.
  - `drv_interaction_overtake_pass(subject, p; p.overtake_window, p.overtake_same_direction_cos)` holds.
  - `since (¬aheadAligned) ridingOnSidewalk` holds. `ridingOnSidewalk` means the subject is in a
    region of kind `sidewalk` (`rel_occupies`) and is not in `drv_motion_complete_halt`
    (p.halt_speed_tolerance). Read at the recognition, this finds an observation from the onset
    (the last aligned-ahead observation) up to the recognition.
- **Obligation**: `forallUser p (same selection → atLast .time p.overtake_window subject aheadAligned
  (since aheadOf (aheadOf ∧ (sig_horn ∨ sig_siren))))`. The search starts at the onset and goes
  back through the run of observations where p is ahead. It gives:
  - **compliant** if a signal is found while p is ahead;
  - **violated** if the run is seen to begin (p alongside or behind) with no signal;
  - **unknown** if the run reaches the start of the recording, or a signal is unobserved.

## Choices the node left open
- **Run of "p ahead" in the search**: written without heading alignment (`aheadOf`). This follows
  the record's wording ("p stays ahead"); alignment only fixes the onset (`aheadAligned`). This
  follows the record, so I declared no narrowing.
- **"Not the subject"** is not written as a `same` conjunct. `overtake_pass(subject, subject)` can
  never hold, so the conjunct would decide nothing and would only be a vacuous leaf.
- **Extra witnesses**: `branch_3` (n/a: the bicycle is on the sidewalk during the pass only while
  at rest, which exercises `complete_halt`), `branch_4` (n/a: the road user passed is another
  bicycle, which exercises the pedestrian aggregate) and `branch_5` (compliant: the horn sounds
  rather than the bell, which exercises `sig_horn`).

## Issue for the plan / reading (not blocking)
In the run's reading, the aggregate `DEF-LVMC-11-02-083::electric_scooter` includes no class, and
`ru.electric_scooter` itself is **unresolved** there. So a road user labelled only as an electric
scooter always has an unknown class for this rule. The rule can never decide violated or compliant
for one; it can only reach not-applicable where the applicability is false.
- `branch_2` (not applicable) uses a real electric scooter.
- `branch_1` (violated) **is built with an electric bicycle**. With a scooter it could only be
  unknown.

The reading should classify `ru.electric_scooter` as included under that aggregate. Otherwise the
"electric scooter" part of c1 is not decided in practice.

## Why I finished
The gate returned OK.
