# NRS_486_351_1 — task result

## Final verdict: OK

The final gate output was `OK — 10 witnesses, 9 names, composes nothing`.

## Gate runs

1. **Accidental run.** I wrongly wrapped the gate command as `… | head -0; echo skip`. The gate probably ran, but its output was thrown away. This broke the "exactly this command" rule and probably used up one run.
2. **WITNESS_FAIL**: `blind: expected unknown, got violated; the manifest masks rel.bearing`. Masking `rel.bearing` only drops a *measured* bearing, and Core still computed it from the kinematics. What I changed: in `blind`, the subject's heading is now unobserved, so Core cannot compute the bearing. Core then cannot compute `rel.longitudinal_overlap` either, so I supplied it as a measured relation (1 m with each car).
3. **Accidental run** (same mistake as run 1, `… | head -0 || true`). Its output was also thrown away.
4. **WITNESS_FAIL**: `blind: … track 1 is in occupancy_observed but lacks a position, a non-zero heading or an extent, so its footprint is undefined`. What I changed: the subject's occupancy is now unobserved in `blind` (`occupancyObserved := [2, 3]`). The two lanes are adjacent through `st.lane_adjacency`, so the obligation stays unknown only because of the bearing.
5. **OK.**

## How the rule is written (all from the record)

- **Class (s3):** `ru_aggregate subject "DEF-NRS-486-041::motorcycle"` or `ru_aggregate subject "DEF-NRS-486-038::moped"`.
- **Applicability (s2, exception):** the exception holds when all three of these hold:
  - `ru_emergency_vehicle subject`;
  - `ru_emergency_vehicle_kind subject police`;
  - some `sig_warning_lamp subject <colour> <mode>`, where the mode is flashing or rotating. The record names no colour, so all four colours are disjoined; these count as one leaf of one atom.

  The applicability is the negation of this exception.
- **Obligation (s4):** there are no `v1, v2` (users) and no `l1, l2` (`existsRegion lane`) such that all of the following hold:
  - neither `v1` nor `v2` is the subject (`not (same v subject)`), and each is in `DEF-NRS-484A-320::vehicle`;
  - `not (same l1 l2)`;
  - `rel_occupies v1 l1` and `rel_occupies v2 l2`;
  - the lanes are adjacent: `st_lane_adjacency l1 left|right l2`, or the subject occupies both `l1` and `l2`;
  - `rel_bearing subject v1 left` and `rel_bearing subject v2 right`;
  - `rel_longitudinal_overlap subject v ≥ 0` for each of `v1` and `v2`.

## Choices the node left open

- **"L2 is L1's neighbour per st.lane_adjacency":** the record names no side, so I read it on either side. This is the record's own wording, so I declared no narrowing.
- **Warning lamp colour:** the record names none, so every colour is admitted.
- **No narrowings declared.**

## Witnesses

| Witness | Expected | What it shows |
|---|---|---|
| `forbid` | violated | Motorcycle straddles the line between same-direction lanes; a car on each side with 1 m overlap. |
| `permit` | compliant | Motorcycle in L1 with a 9 m gap behind a car in L1; a car in L2 on its right overlaps 1 m. |
| `idle` | not applicable | Bicycle subject in the forbid geometry (see deviation below). |
| `blind` | unknown | Forbid scene with the subject's heading unobserved and overlaps supplied as measured. |
| `branch_1` | not applicable | Police motorcycle with a blue flashing lamp. |
| `branch_3` | violated | Police motorcycle with no lamp lit. |
| `branch_2` | compliant | Motorcycle alone. |
| `branch_4` (added) | violated | Opposite-direction lanes with no neighbours; the subject straddles both, so the lanes are adjacent only through its footprint. |
| `branch_5` (added) | violated | Motorcycle wholly inside L2, splitting between a car in L1 and a car in L2; the lanes are adjacent only through `st.lane_adjacency`. |
| `branch_6` (added) | violated | Moped subject, which exercises the moped aggregate. |

**Deviation from the planned narrative:** `idle` plans "a passenger car" as the subject. Under the run's reading, `motor_vehicle` (and every car class) is *unresolved* in both the `DEF-NRS-486-041::motorcycle` and `DEF-NRS-486-038::moped` aggregates. A car's membership is therefore unknown, never decided false, so a car subject cannot produce not applicable. I used a bicycle instead, which neither aggregate includes or leaves unresolved. The plan agent may want to update the `idle` narrative, or reconsider that the reading leaves passenger cars unresolved in the motorcycle and moped definitions.

## Why I finished

The gate returned OK.
