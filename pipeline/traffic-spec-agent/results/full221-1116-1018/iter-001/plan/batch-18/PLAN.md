# Plan — batch 18: NRS 484B.307 paragraphs (4)(b), (5)(a), (6)(a), (7)(a), (8)(a)–(d)

There are 13 nodes. `aggregates.jsonl` is empty because no clause defines, adds or excludes members of its own. No new concept records are proposed: the nodes reuse `drv.motion.complete_halt`, `drv.motion.left_turn_through_region`, `drv.motion.right_turn_through_region` and `drv.motion.u_turn_through_region`. No gaps. The validator accepts every node.

Conventions used throughout:
- **"Facing the signal" for vehicular traffic** uses the index mapping from `NRS_484B_307_2a`: the subject occupies a carrier `c` whose entrance end is intersection `i` and that the head governs.
- **"Facing" for pedestrians** uses the index mapping from `NRS_484B_307_2b`: `dev.position`, `kin.heading` and `kin.position`, with that node's proposed parameters `p.ped_traffic_signal_facing_cos` and `p.ped_traffic_signal_facing_reach`, proposed again unchanged.
- **"Steady red / yellow alone"** means `circular_red` / `circular_yellow` and no other state.
- **"Yield the right-of-way"**:
  - "yield" is mapped to `kin.speed` and `rel.contact`, as in the index.
  - "the right-of-way" (DEF-NRS-484A-210) is operationalized by the traffic-conflict technique: `prim.closest_approach_*` with `p.conflict_horizon`, `p.conflict_centre_clearance` and `p.halt_speed_tolerance`.
- **"Stop"** is the ambiguous term. In every span here a stop is *required*, so DEF-NRS-484A-255 ("complete cessation from movement") applies, through `drv.motion.complete_halt`.

## Nodes

**NRS_484B_307_4b** — A pedestrian facing a vehicular head that shows a green turn arrow alone must not step onto the roadway.
- "Enter the highway" is read as entering the roadway, disclosed as a narrowing. The highway's defined width includes the sidewalk the pedestrian already stands on, and the index reads "cross the highway" the same way in 283-1d3.
- The bracket "as provided in NRS 484B.283" carries four exception compositions:
  - `_1d1` (walk) and `_1d2` (flashing with countdown) are the provisions that permit proceeding.
  - `_1d3_o2` and `_1d4_o2` are the provisions that let a lawfully entered pedestrian continue (for example onto a second roadway).
  - `_1d3_o1` and `_1d4_o1` were not composed: they forbid proceeding, so making them exceptions would excuse entry on "don't walk".
- Reversal signal: `NRS_484B_283_1d1`'s binder is the yielding vehicle rather than the pedestrian. In that case `ruleApplies` would never hold for a pedestrian, and the walk exception would need re-mapping.

**NRS_484B_307_5a_o1** — Under a green straight-through arrow alone, the subject's passage through the intersection must not be a right turn, a left turn or a U-turn.
- The U-turn is read as a turn (narrowing).
- The obligation is an act recognized at the exit, with an event boundary (onset at entry).
- The trigger is read at `some_moment` while the passage is under way, the default where the words say nothing of time. Scenarios `occasion_s1` and `occasion_s1_outside` are included.
- Reversal signal: a label that reads the arrow only at entry.

**NRS_484B_307_5a_o2** — Under that arrow, yield to vehicles and pedestrians that were within the intersection or an adjacent crosswalk at the time the arrow was exhibited.
- "At the time the signal is exhibited" is read at the arrow's latest onset, through a past operator.
- "Lawfully" is read through presence (narrowing), following the index for 2a.
- `branch_1` differs from `forbid` only in that weaker fact (present now, but not at the onset).

**NRS_484B_307_6a** — Traffic that faced the steady yellow alone on its approach must not enter the intersection while the steady red is shown.
- The warning sentence is a `definitional` residue: it imposes no duty.
- "The red signal" is read as `circular_red` without a green or flashing-yellow arrow, so that the arrow paragraphs govern arrow movements (narrowing).

**NRS_484B_307_7a_o1 / _o2 / _o3** — The line has three obligation spans: "is permitted to cautiously enter … only to make the movement indicated", "must yield" to pedestrians, and "and yield" to other traffic. Each is its own node.
- **o1** is an act recognized at the exit.
  - The movement indicated by the flashing yellow turn arrow is required; a left arrow also covers the U-turn.
  - The exception "other such movement … permitted by other indications displayed at the same time" is read at `some_moment`, the same moment as the arrow, because the words say "at the same time".
  - "Cautiously" is operationalized as no traffic conflict at the entry observation.
- **o2** and **o3** are yield duties toward pedestrians within the intersection or an adjacent crosswalk, and toward traffic within the intersection. "Lawfully" is read through presence.
- Reversal signal: a reviewer who requires one node for the coordinated "must yield … and yield …" would merge o2 and o3.

**NRS_484B_307_8a_o1** — Rule 4c duty: the subject must halt before the intersection when it enters on a steady red alone.
- The place is, in order: the stop line marking the carrier's entrance, else the crosswalk marking it, else the intersection's edge.
- The search uses the approach convention. The `history_boundary` scenario is planned.
- "Sign or pavement marking indicates where the stop must be made" is read as the recorded stop line (narrowing). A free-standing "stop here" sign has no regulatory-sign code.

**NRS_484B_307_8a_o2** — "Remain stopped or standing until the green signal is shown" is read as not entering the crosswalk that marks the carrier's entrance, nor the intersection, while the steady red alone is shown (narrowing: closing up in a queue is not leaving the stop).
- **Exceptions.** The bracket says "(c) is appended below", so the exception for paragraph (c) is carried inline by the appended words s7–s15, as exception spans. The exception for (d) is a composition with `NRS_484B_307_8d`.
  - Inlining (c) also avoids a composition cycle: o2 → 8c → (yield beneficiaries).
- **"After complying with the requirement to stop" (s7).**
  - Referring span: s7. Defining span: s3, the stop place and order of o1.
  - The halt itself is carried, with o1's place, zone and history bound, not compliance with o1. Compliance would be granted wherever o1 is not engaged, which would wrongly satisfy the condition.
- **"For a right turn" / "for a left turn"** use the catalogued declared intentions `int.right_turn` and `int.left_turn` at the intersection. The words state the turn the entry is made for, and the exception must be decided at the entry, before the turn is recognized at the exit.
- **Other conditions:**
  - "Extreme right": `st.lane_adjacency` ordinal equals the lane count.
  - "Extreme left of a one-way highway": ordinal 1 on a `st.one_way_roadway`.
  - The intersecting highway is every way the intersection lies on other than the subject's own.
  - "Two-directional" quotes DEF-NRS-484B-073: no median lies on the way, and two lanes on it are opposed within `p.lane_opposed_direction_cos`.
  - "One-way to the right/left": every lane on the way points to that side of the approach's direction by more than `p.cross_direction_sin_min`.
  - Both of those parameters are proposed new.
- Scenarios: `branch_1` and `branch_3` differ only in the referred halt.

**NRS_484B_307_8a_o3** — The obligation "but must yield" of the appended (c) words, which this line contains.
- Its applicability is the permitted turn on red, with the same conditions as o2's (c) exception.
- "Pedestrians and other traffic proceeding as directed by the signal" is read as: moving road users that are within the intersection or an adjacent crosswalk, or on an approach whose head shows a green indication (narrowing). This node is word-for-word the duty of `NRS_484B_307_8c`, because the corpus appends (c) to this line.
- Reversal signal: the operator removes the appended text from 8a's line. In that case o3 is withdrawn and o2's (c) exception becomes a composition with `NRS_484B_307_8c`.

**NRS_484B_307_8b** — Same as 4b, with the steady red alone. The four 283 exception compositions are the same, for the same reasons.

**NRS_484B_307_8c** — Same duty as 8a_o3.
- "The requirement to stop" names 8a's words from another line, so it is a `definition` reference to NRS-484B-307-8a with the stop words quoted. "After complying with" carries the halt itself, with `source_spans` [s3]; the reference's `why` says why no 8a rule need apply.

**NRS_484B_307_8d** — The permission for motorcycle, moped, trimobile, bicycle, electric-bicycle and electric-scooter riders is the applicability; (3) "the person yields" is the obligation. 8a_o2 is excused through `ruleApplies(8d)`, and a failure to yield is 8d's own violation, so together they cover what the "if" makes unlawful.
- **(1) Two complete cycles.** Since the onset of the rider's halt at the place, some head governing an approach of the intersection has begun a green indication at least the literal two times, and the rider's own head kept the steady red alone throughout (s8).
- **The malfunction / detection-failure cause** is a `scope: none` residue: the unchanged red through two cycles is all the scene shows, and the duty is the same whichever cause holds.
- **(2) "No other device prohibits … such turns, if applicable".**
  - This is read through the passage's recognized turn: right or left `_through_region` at the exit, against regulatory signs coded `no_right_turn` / `no_left_turn` governing the approach or the intersection.
  - It is read from each observation of the passage forward to its exit, so that it is decided at the entry where the exit is recorded.
  - Two intention ids on one span were returned by the validator, which is why this reading was chosen.
- **"Trimobile"** has no applicable definition. It is carried by `ru.motorcycle`, whose contract includes "three-wheeled variants".
- **"After complying with the requirement to stop"** is handled as in 8c.
- Reversal signal: the operator adds a trimobile class atom or definition, or a regulatory-sign code for "no turn on red".

## For the operator

- **Duplicate text.** NRS-484B-307-8a's line contains paragraph (c)'s text ("with 484B.307(8)(c)"), and NRS-484B-307-8c is also a separate line. As a result, `NRS_484B_307_8a_o3` and `NRS_484B_307_8c` are the same duty. If the appendix exists only to resolve the (c) reference, removing it from 8a's line would drop o3 and make o2's (c) exception a composition.
- **Signs the ontology cannot express.**
  - `dev.regulatory_sign` has no code for a sign that prohibits turns only on red ("no turn on red"), nor for a free-standing "stop here on red" sign. 8d's (2) reads only `no_left_turn` / `no_right_turn`.
  - 8a's stop place is read as the recorded stop line.
  - A code for each would close both readings.
- **Trimobile** has no definition in the corpus and no class atom. `ru.motorcycle` carries it, which covers three-wheelers ridden astride but not seated three-wheelers that are not ridden astride.
- **Binder of `NRS_484B_283_1d1`.** 4b and 8b compose `NRS_484B_283_1d1` as an exception with `subject → subject` (pedestrian). If that node's binder is the yielding vehicle, the walk exception never engages for a pedestrian. Its applicability should then be exposed for the pedestrian, or 4b/8b re-planned.
- **New parameters.** `p.lane_opposed_direction_cos` (0.9) and `p.cross_direction_sin_min` (0.5) are new proposals and need review.
