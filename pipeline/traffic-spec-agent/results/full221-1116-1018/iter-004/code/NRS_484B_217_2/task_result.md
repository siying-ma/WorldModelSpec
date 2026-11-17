# NRS_484B_217_2 — coding session result

## Final verdict

**WITNESS_FAIL** — `branch_4: expected violated, got compliant`. All other 15 witnesses pass:
forbid, permit, idle, blind, branch_1–3, branch_5–12.

## Gate runs

1. **(Not a valid use.)** By mistake I ran the gate command with `2>&1 | head -0; true` appended. That
   is not the exact command, and it printed nothing. It probably still used one run against the
   untouched skeleton.
2. `UNUSED_CLAIM` (every claimed name): this was the skeleton, before my edit. After it I wrote the rule and 16 witnesses.
3. `UNANCHORED_VARIABLE` on `t`, the turn-target region of s10/s11. An `intent` leaf does not anchor
   a region. After this run I tied `t` to the zone's highway `h` with `st_on_way t h`, which the node claims under s3 (see "Choices").
4. `WITNESS_FAIL`: the trace's path lengths grew by less than the straight-line distance. I fixed
   the cumulative `pathLength` values.
5. `WITNESS_FAIL`: branch_4 came out compliant. I moved the k = 18 crossing instant so the body
   already enters the exit region (driveway, intersection or side highway) while it still straddles the opposing lane.
6. `WITNESS_FAIL`: branch_4 still came out compliant. The budget is spent.

## How the rule is written (also in the rule file's header)

- **Class:** `ru_aggregate subject DEF-NRS-484A-320::vehicle`.
- **Applicability** has two parts:
  - The subject occupies a `highway` h, and a `centre_line` c lies on h (`st_on_way`).
  - The subject is in a no-passing zone, shown either way:
    - it occupies a `travel_region` that a `zone_sign` of kind no_passing governs, and the sign is not an end sign;
    - or it occupies a `lane` whose left `st_lane_marking` is solid or double_solid yellow. If that marking is solid_broken, the result is unknown (`definedWhen`).
- **Obligation:** for every highway h the subject occupies, and every centre line c on h:
  `¬crossing(c) ∨ (signalledFirst(c) ∧ noImpediment ∧ (reachesAdjoiningHighway(h) ∨ (leftTurnDeclared(h) ∧ rule NRS_484B_413_2 ∧ safe)))`.
  This is the record's E3 ∨ E4 with the conditions they share factored out, so it is logically
  equivalent. Each part:
  - `crossing(c)`: `2·offset(c) < width − 2·p.lateral_position_tolerance`. This is the record's
    "offset below half the width minus the tolerance", doubled so no literal 2 is needed.
  - `signalledFirst(c)`: `since crossing(c) (¬crossing(c) ∧ (indicator left ∨ hand signal left))`.
    The signal must be on at the last observation before the crossing began, and the crossing must
    have held at every observation since.
  - `noImpediment`: no other member of traffic that is oncoming (`rel_oncoming`) or following
    (`rel_bearing` behind and `rel_same_direction`) has `prim_closest_approach_within` the horizon
    with a `prim_closest_approach_distance` below the clearance.
  - `safe`: no other road user is in `rel_contact` with the subject or has such a conflicting approach.
  - `reachesAdjoiningHighway(h)`: `within p.vehicle_turn_window` the subject occupies a highway h2
    that is not h, and no longer occupies h.

## Choices the node left open

- **Anchoring of the turn target `t` (s10/s11).** The gate requires `t` to be anchored, and
  `intent` does not anchor it. I used `st_on_way t h`: the intersection or driveway entrance lies on
  the zone's highway h. This is the only claimed atom that can tie `t` to the subject. I did not
  declare it as a narrowing, because exception spans may not be narrowed. My reasoning is that a
  left-hand turn made by crossing this highway's striping leaves this highway, so the condition
  follows from the words. The plan agent should confirm this reading, or add it to the node's s10
  element.
- **"Another" road user.** The traffic and safety quantifiers exclude the subject itself (`same`),
  because every body is in contact with itself.
- **Narrowings:** none declared.

## Why branch_4 fails: the node is underdetermined

branch_4 expects violated because "NRS_484B_413_2 is violated although a signal was given at the
observation before the crossing". The rule reads 413_2 through `.rule "NRS_484B_413_2"`, which gives
413_2's verdict at each instant, and E4 is judged at the crossing instants (k = 17, 18). In the scene:

- the left indicator comes on at k = 16, about 8 m before the crossing;
- in branch_1 it is on from 120 m before the crossing;
- at k = 18 the body is already entering the driveway.

Even so, 413_2 reports complied or not engaged at the crossing instants. I may not read 413_2's
file, so I can't tell what engages it: what marks the "turn", which intention or region kind it
reads, or whether it engages only at an intersection. Without that I can't build a scene in which
413_2 is violated *at an instant where this rule crosses the striping*.

**What the plan agent should change.** One of the following:
- (a) Tell the coder what engages NRS_484B_413_2 (its turn recognition and the regions and
  intentions it reads), so that branch_4 can be built.
- (b) Reconsider where the composition is read. 413_2's violation, which comes from the signal's
  history over the last 100 ft "before turning", may only be decided at the turn's recognition. That
  can fall after the crossing instants this rule judges. If E4 is meant to require 413_2 compliance
  for the turn the crossing is made for, the record has to say at which observation that
  compliance is read.

## Why I finished

The gate budget (6 runs) is spent. One run was wasted on the malformed command in run 1. The
remaining failure depends on the content of the composed rule NRS_484B_413_2, which this session
cannot see.
