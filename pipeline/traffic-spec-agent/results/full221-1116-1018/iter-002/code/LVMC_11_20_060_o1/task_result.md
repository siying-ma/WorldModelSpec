# LVMC_11_20_060_o1 — task result

**Final verdict: OK** (7 witnesses, 7 names, composes nothing)

## Gate runs
1. `OK` — first run, after writing the rule and the witnesses. Nothing changed after it.

## How the node is written
- Class (e1): `ru_aggregate(subject, "DEF-NRS-484A-320::vehicle")`.
- Applicability: `asm.business_or_residence_district` ∧ ∃ sidewalk `s`:
  `rises(rel_occupies(subject, s))` ∧ (∃ driveway_or_alley_entrance `d` occupied ∨ ∃ alley `a` occupied).
- Obligation: ∀ sidewalk `s`, (same entry selection, restated in full) →
  `rises(¬ (zone(s) since (zone(s) ∧ complete_halt)))`, where
  `zone(s) = ¬rel_occupies(subject, s) ∧ st_region_geometry_distance(subject, s) ≤ p.stop_point_tolerance`
  and the halt is `drv_motion_complete_halt(subject; p.halt_speed_tolerance)`.

## Choices the node left open
- The record writes the search as "(in the stop zone, or the entry observation itself) since (in the
  stop zone and halted)". I wrote it as the value of `zone since (zone ∧ halt)` **at the observation
  before the entry**, obtained as `rises(¬X)`. At the entry the subject is on `s`, so `zone` and `X` are
  false there, and the rise reduces to `X` at the previous observation (unknown where `X` is unknown).
  This matches the record's stated search ("back from the observation before the entry"). It also
  makes a previous entry onto `s` end the run, as the record requires, even when the subject was on
  `s` for only one observation. The literal `zone ∨ rises(occ s)` form would let a run continue
  through such a one-observation entry.
- I declared no narrowings: every choice is the record's own reading.

## Witnesses
`forbid`, `permit`, `idle`, `blind` (kin.speed masked), `branch_1` (halt upstream outside the zone),
and `history_boundary` (begins in the zone, so the run reaches the recording's start) are as planned.
I added `branch_2` (violated) to exercise the alley limb of e3. Every witness sets `window` from t = 1 s,
which skips the first observation, where no rise can be judged.

## Why I finished
The gate returned OK on the first run.
