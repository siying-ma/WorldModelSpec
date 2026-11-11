# NRS_484B_227_1_o1 — task result

**Final verdict: OK** (6 witnesses, 7 names, composes nothing). Gate runs used: 2 of 6.

## Gate runs
1. **VACUOUS**: obligation leaves `st_on_way d h` and `rel_occupies x d`. These are the dividing-section limb of "x is upon h", restated when the obligation re-binds h. That limb is logically redundant there, even in three-valued logic. The duty's antecedent ("x occupies a roadway q lying on h") already entails the roadway limb, so no scene can move the dividing-section limb.
   *Change:* the obligation now re-binds h as `divided h ∧ uponRoadway h`. The applicability keeps the full selection: `divided h ∧ (uponRoadway h ∨ uponDivider h)`.
2. **OK**.

## Rule
- Class: `ru_aggregate(x, "DEF-NRS-484A-320::vehicle")`.
- Applicability (a2): there is a `highway` h with some `median_or_divider` m where `st_on_way(m, h)`, and x occupies (`rel_occupies`) a `roadway` or a `median_or_divider` that lies on h.
- Obligation (a3): for every `highway` h that is divided and has a roadway on it occupied by x, and for every `roadway` q on h that x occupies, `¬ drv_motion_against_carrier_direction(x, q)` with `[p.speed_resolution, p.opposed_direction_cosine]`.

## Choices the node left open
- **Re-binding h in the obligation.** I used the roadway limb of the selection only (see run 1). The duty has content on exactly the same set of highways as under the record's whole selection: on a highway x is upon only through the dividing section, the duty is empty either way. This is a statement of the same selection, not a narrowing, so `narrowings` stays empty.
- No other choice was open. The readings on a1 (agency) and a3 are the record's own and are not restated.

## Witnesses
The divided highway is region 1, with a westbound north roadway (2), an eastbound south roadway (3) and a median with an opening (4). The car is track 1.
- `forbid`: the car drives east at 10 m/s on the westbound roadway (cosine −1).
- `permit`: the car drives east on the eastbound roadway (cosine +1).
- `idle`: one undivided roadway and no median.
- `blind`: the same scene as `permit`, with `st.lane_direction` masked.
- `branch_1`: the car crosses the westbound roadway northwards at 2 m/s (cosine 0) towards a side street (highway 5, roadway 6).
- `branch_2` (added): the car is in the median opening, on no roadway. It is compliant, which exercises the dividing-section limb of the applicability.

## Note for the plan
The record's obligation says "re-binding h with the same selection". Written literally, its dividing-section limb is a leaf that can never matter. A future record could state the re-selection as "a divided highway on which x occupies a roadway", which means the same thing.

## Why I finished
The gate returned OK.
