# NRS_484B_403_3 — task result

**Final verdict: OK** (10 witnesses, 10 names, composes nothing).

## Gate runs (3 of 6 used)

1. **UNUSED_CLAIM** — I ran this on the untouched skeleton, before writing anything. It used up one run and told me nothing new.
2. **WITNESS_FAIL** — two problems:
   - (a) The adapter check rejected every trace. The heading stayed the same between scenes while the yaw rate said the vehicle was turning 36° per interval.
   - (b) `blind` came back unknown for `window_truncated:prim_heading_change`. Most likely the concept looks further back than its own window, so instants early in the fully masked trace leaked their truncation into the verdict. That trace also had no yaw rate at all, even before masking.
   - Changes made:
     - The turn is now 4 steps of 36.87 / 53.13 / 53.13 / 36.87 deg/s. The heading moves through the rational unit vectors (4/5, 3/5), north and (-4/5, 3/5) to west, and the rate at each scene is held over the interval before it.
     - The traces are now 45 s long, with the turn at t = 30–33 s and recognition at t = 34 s. Witnesses judge t = 25–44 s.
     - The `blind` trace now records the yaw rate and lets the manifest mask it.
3. **OK**.

## How the rule is written

- **Class:** `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`.
- **Applicability (s3):** `asm "asm.business_district"`.
- **Occasion (s2):** `rises (drv_motion_u_turn subject [p.vehicle_turn_window, p.u_turn_heading_min, p.turn_yaw_rate_tol])`, while the subject occupies a `highway` region.
- **Under way (U):** `|kin_yaw_rate subject| > p.turn_yaw_rate_tol`.
- **s4 (throughout):** `holdsFor time W subject (U → ∃ intersection occupied)`.
- **s5 (throughout):** `holdsFor time W subject (U → ∃ highway occupied with ∃ median_or_divider on_way it)`.
- **s6 (some moment):** `¬ holdsFor time W subject ¬(U ∧ ∃ median_or_divider occupied with the opening attribute, on_way a highway the subject occupies)`.
- **Obligation:** occasion → s4 ∨ (s5 ∧ s6).

## Choices the node left open

- **"On that highway" (s6):** I took it to mean a highway the subject occupies, and selected it again inside the s6 formula. This is the record's own wording, so it is not declared as a narrowing.
- **Narrowings:** none.
- **Opening attribute:** written with the accessor `st_median_or_divider_opening` of the claimed atom `st.median_or_divider`. The gate accepted it as claimed.

## Witness notes

- Occupancy is stated for each instant rather than derived from the geometry.
- Every scenario sets `window := (25000, 44000)`. This keeps out the early instants, where the concept's look-back is cut off by the start of the trace.
- No `branch_*` witnesses were needed. The planned scenes reach every leaf:
  - `permit` exercises s4.
  - `occasion_s5` exercises s5 false with s6 true.
  - `occasion_s6_outside` exercises s5 true with s6 false.
  - `occasion_s6` exercises both s5 and s6 true.

## Gate behaviour worth noting

In run 2, `blind` was unknown for a truncated `prim_heading_change` window even at t ≥ 11 s, where the rule's own 10 s windows are covered. That suggests `drv.motion.u_turn` reaches back further than its declared window when its inputs are unknown. Recording more history fixed it, so I filed no defect.

## Why I finished

The gate returned OK on both files.
