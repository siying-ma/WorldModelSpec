# LVMC_11_43_010_C2 — task result

**Final verdict: OK** (5 witnesses, 7 names, composes nothing). 3 of 6 gate runs used.

## Gate runs

1. **WITNESS_FAIL**: the gate rejected every trace as one "the adapter cannot produce". The yaw
   rate was −90 deg/s but the heading vector stayed east, and the gate expects the yaw rate to
   turn the heading over the interval before each scene. The rule passed every static check.
   Change: rebuilt the witnesses so the subject drives a quarter circle about a point. The heading
   vector now rotates 4.5° per 50 ms scene, using rational cos/sin (Taylor series, π ≈ 355/113,
   rounded to micrometres). The yaw rate is nonzero exactly over the 20 intervals from entry to
   exit. Lanes are annular sectors about the same point.
2. **WITNESS_FAIL**: only `blind` failed. It came out unknown for `window_truncated:since`. The
   record's `since(φ, rises(occupies) ∧ φ)` does not stop at the entry when φ is unknown there.
   Before the entry φ holds vacuously, so the strong-since search ran back to the start of the
   trace. Also, `blind` had built its lanes without ordinals, so it was unknown even unmasked.
   Change: the left operand of `since` became `φ ∧ ¬rises(occupies(subject, r))`, and `blind` now
   uses `forbid`'s trace with only the manifest masking `st.lane_adjacency`.
3. **OK**.

## Choices the node left open

- **Obligation `since` form.** I wrote `since (φ ∧ ¬rises(occupies(subject,r))) (rises(occupies(subject,r)) ∧ φ)`
  in place of the record's literal `since(φ, rises(occupies) ∧ φ)`. This spells out the record's
  own words, "the latest observation at which rel.occupies(subject, r) rose". No rise may lie
  between the entry found and the judged observation, so the search into the past ends at the
  latest entry (rule 6c). Where φ is decided, it gives the same verdict as the literal form. It
  declares no narrowing, because nothing in s5 is read more narrowly.
- **Re-binding the roundabout in the obligation.** I used `forallRegion roundabout r (concept(subject, r) → …)`.
  This keeps the record's whole selection (kind and concept at the judged observation) and
  requires the duty for every roundabout so selected.
- **st.roundabout and st.lane.** Each is carried as the kind of a region quantifier (`roundabout`,
  `lane`). `st.lane_adjacency` is carried as `st_lane_adjacency_ordinal = st_lane_adjacency_count`.
- **Narrowings.** None of my own.

## Witness notes

- In the witness, ordinal 1 is the lane on the left of the clockwise direction of travel, the outer
  radius about the turn's centre. The narrative calls it "inner", meaning relative to the central
  island. Only the ordinals matter to the rule.
- Occupancy is computed from the polygons. `branch_1` is the exception: at the scenes where the
  footprint straddles the lane line, the subject is stated to occupy r and both lanes.

## Why I finished

The gate returned OK.
