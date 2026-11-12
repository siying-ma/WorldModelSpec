# NRS_484B_250_4_o1 — task result

**Final verdict: OK** (10 witnesses, 14 names, composes nothing). 2 of 6 gate runs used.

## Gate runs
1. **VACUOUS**: the leaf `dev_governs d i` (a head governing the intersection itself) moved no
   witness: every scene had the head governing lane c. The formula was right. I added witness
   `branch_5` (violated), where the inoperative head governs intersection 20 only, and left the rule
   unchanged.
2. **OK**.

(Before run 1, a stray shell command with `--help` piped into `head` was denied by the permission
layer and did not run. It used no gate run.)

## How the rule is written
- **Class:** `ru_aggregate ego "DEF-NRS-484A-320::vehicle"`.
- **Entry (a1):** for some intersection i and travel region c:
  - `rises (rel_occupies ego i)`, and
  - at the observation before: ego occupied c, did not occupy i, and `st_lane_enters c i`.
  - "At the observation before" is `since (occ i) (φ ∧ ¬occ i)`. At an observation where occupancy of i has just risen, this is exactly φ at the previous observation.
- **Signal (a2/a3):** at the entry, some `traffic_signal` head governs c or i, and every such head is `dev_inoperative`.
- **Halt (a5–a8):** `drv_motion_at_rest` with `p.rest_speed_tolerance`, ego on c, and:
  - body within `p.stop_point_tolerance` of the place (`st_region_geometry_distance`);
  - not past it (`prim_region_offset_along ego place c ≥ 0`);
  - for the crosswalk and the intersection edge, ego's footprint not over the place.
- **Which place governs:**
  - the stop line marking c (`st_entrance_of`);
  - else the crosswalk marking c;
  - else the edge of i.
  - An unobserved entrance list leaves the choice unknown.
- **Search:** a `since` that starts at the observation before the entry and runs back. It stops at either:
  - the approach start: ego, on a carrier the place marks (`st_entrance_of`, or `st_lane_enters` for the edge), is off the place, short of it along c (offset > 0), and farther than the tolerance; or
  - ego's previous entry into i (`rises (rel_occupies ego i)`).
  - Nothing else ends it. Its head before the recording is `windowTruncated "since"`.
- **Obligation:** I re-wrote the whole selection of i and c (entry plus signal condition) inside it. The verdict is wrapped in `definedWhen(all halted ∨ all missed, all halted)`. Where ego enters through several carriers at once and the verdict differs between them, the result is unknown. This follows the `st.lane_enters` contract: a rule never picks the carrier that favours the road user.

## Choices the node left open
- **"Not past" a stop line** is offset ≥ 0, so a reference point on the line is not past it. For a crosswalk and the edge, the footprint must also be off the place, so in effect the offset is > 0. This is no narrower than the words, so I declared no narrowing.
- **Several stop lines (or crosswalks) marking c:** a halt at any one of them counts.
- **No narrowings declared.** `narrowings := []`.

## Witnesses
These are the planned ones plus:
- `branch_3`: edge place, no halt → violated.
- `branch_4`: crosswalk, halt short of it → compliant.
- `branch_5`: the head governs the intersection itself → violated.

Ego's occupancy is stated from its body extent, so a body across two regions occupies both.

## Why I finished
The gate returned OK.
