# NRS_484B_250_2 — task result

## Final verdict

**OK** — `14 witnesses, 20 names, composes NRS_484B_250_4_o1,NRS_484B_250_4_o2` (gate run 4 of 6).

## Gate runs

1. **WITNESS_FAIL**: every trace was rejected because the highway regions had no boundary
   ("where occupancy is observed every structure needs one"). The rule built and checked.
   Fix: gave highways 101/102/301/303 rectangular outlines.
2. **WITNESS_FAIL**: only `branch_9` failed. v's yaw rate (120 °/s) turned it while its heading
   vector stayed west. Fix: v's heading now turns 6° per 50 ms step from west towards south
   (rational cos/sin to 10⁻⁵), matching the yaw rate held over the interval before each scene.
3. **VACUOUS**: the obligation's copy of the "X is controlled" exception
   (`st_lane_enters c X` and `dev_governs d c`) never decided a witness. With one intersection, a
   controlled X already makes the applicability false. Fix: added `branch_10`, which has two
   intersection records over the same square. One is uncontrolled and the rule applies there.
   The other is controlled by a yield sign on the carrier v arrives through. The repeated
   exception is the only thing that keeps v from being owed the right-of-way there, so the
   scene is compliant.
4. **OK**.

## How the rule is written (also in the rule file's header)

- **Class (a, e, h)**: `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`. The other road user
  v gets the same check.
- **Arrival (b)**: `rel_occupies x c ∧ rises(st_region_geometry_distance x X ≤ p.stop_point_tolerance)`,
  with `st_lane_enters c X`. "Occupied c or X at every observation since" is a `since` anchored
  at that arrival. X ranges over `intersection` and c over `travel_region`.
- **Different highways (c)**: there is a `highway` h with `st_on_way c2 h` and not `st_on_way c1 h`.
- **Approximately the same time (d)**: `|sinceRise(arrival subject c1) − sinceRise(arrival v c2)| ≤ p.same_time_arrival_window`,
  which is the time since each arrival.
- **On the right at the later arrival (e, h)**:
  `since(¬(arrS ∨ arrV), (arrS ∨ arrV) ∧ rel_bearing subject v "right")`. The last observation
  at which either arrival happened is the later arrival, and the bearing is read there.
- **Yield (f, g)**: the subject is not in contact with v (`¬rel_contact`). It is also not the case
  that it moves (`kin_speed > p.halt_speed_tolerance`) while
  `prim_closest_approach_within(…; p.conflict_horizon)` holds and
  `prim_closest_approach_distance < p.conflict_centre_clearance`.
- **Controlled X (j)**: one region quantifier over c with `(same c X ∨ st_lane_enters c X)`, and
  some traffic signal, stop sign or yield sign that `dev_governs` c.
- **Excepted pair (k, l, m)**: the pair is excepted when
  `st_lane_direction` c1 · c2 < −p.oncoming_heading_cos and one of these holds:
  - the subject declares `int.left_turn` at X;
  - v declares `int.left_turn` at X;
  - v's `headingSince` (onset `rel_occupies v X`, step `p.heading_since_step_carla_scene_graph`)
    is at least p.turn_heading_min and below p.u_turn_heading_min.
- **Subsection 4 (i)**: `¬ruleApplies` of NRS_484B_250_4_o1 and of _o2, each with subject ↦ subject,
  conjoined into the applicability.
- **Obligation**: for every intersection X and carrier c1, the obligation repeats the
  applicability's whole selection: the carrier enters X, the subject's arrival has held since,
  and X is not controlled. Then, for every v that is an owed vehicle, the subject yields to v.

## Choices the node left open

- **Arrival time for d**: I used `sinceRise` of the arrival event itself (occupying the carrier
  and the rise into tolerance), not of the distance condition alone. This follows the record's
  words "time since each arrival". It is not a narrowing.
- **"Governs X or a carrier entering X" (j)**: written as one quantifier over c using
  `same c X ∨ st_lane_enters c X`. This is the same meaning as two separate quantifiers, written
  as one disjunction.
- **No narrowings declared**: every span is written as the record maps it.

## Witnesses added beyond the plan

| Witness | Expected | What it shows |
|---|---|---|
| `branch_4` | not applicable | A traffic signal governs X itself. |
| `branch_5` | not applicable | A stop sign governs c1. |
| `branch_6` | violated | Violated by contact alone: the subject has halted inside X and v runs into it. |
| `branch_7` | compliant | Opposed approaches; the subject declares a left turn. |
| `branch_8` | compliant | Opposed approaches; v declares a left turn. |
| `branch_9` | compliant | Opposed approaches sampled at 20 Hz. v enters X and turns left 60°, and the subject proceeds in conflict only once v's turn reaches 45°. |
| `branch_10` | compliant | Two coincident intersection records, one of them controlled. This exercises the controlled-X exception repeated in the obligation. |

## Observations for the plan

- The excepted pair (k–m) only matters when v also lies on the subject's right at the later
  arrival. With opposed approaches in right-hand traffic, an oncoming vehicle is normally on the
  left. So `branch_7` to `branch_9` use an artificial layout: the westbound approach lies south of
  the subject's line. The rule is as the record states; this only means the exception rarely
  bites.
- I can't read the composed rules NRS_484B_250_4_o1/_o2. They did not apply in any witness, and
  none of the witnesses depended on them.

## Why I finished

The gate returned OK on run 4 of 6.
