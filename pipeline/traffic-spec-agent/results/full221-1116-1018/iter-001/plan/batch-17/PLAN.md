# Plan — batch 17 (NRS 484B.293, 484B.297(2), 484B.307(2)(a), (2)(b), (3)(a), (4)(a), (12)(a), (12)(b))

All nine nodes pass the validator (`accept`). No concept is proposed: every manoeuvre or state is a
concept already proposed this iteration (`drv.motion.complete_halt`, `moving_across_carrier`,
`moving_against_carrier`, `left_/right_/u_turn_through_region`), reused by id. No gap and no law-local
aggregate (`aggregates.jsonl` is empty).

## Nodes

**NRS_484B_293** (pedestrians on the right half of crosswalks). One obligation: "upon the right half of
crosswalks". "shall move" is a condition: the duty applies only while the pedestrian moves (not
`drv.motion.complete_halt`). The right half is read from the crosswalk's reference point
(`st.region_geometry`) and the pedestrian's velocity. The pedestrian complies when that point is not to
its right by more than the new `p.pedestrian_lateral_tolerance`. "whenever practicable" is
operationalized, not surrogate. Keeping right is impracticable when one of two things lies on the
pedestrian's right within `p.pedestrian_near_reach`:
- another road user ahead in the same crosswalk (`rel.bearing`, `rel.surface_gap`);
- an obstruction (`prim.region_lateral_offset`, `st.region_geometry`).

The narrowing says the catch-all is read only through those two. *Reversal signal:* sources where a
crosswalk's reference point is not its centroid; then a geometric "half of a region" primitive is
needed (see operator section).

**NRS_484B_297_2** (walk on the left, facing traffic, where no sidewalk is provided). The two
obligation phrases are one obligation span. "Left side" is read against the centre line of the
pedestrian's highway (`prim.region_lateral_offset`), reusing the index mapping of "left side of the
highway" (NRS_484B_213_2a). "Facing the approaching traffic" means `drv.motion.moving_against_carrier`
for every lane of that highway within `p.pedestrian_near_reach`.

The trigger "walking along" reuses the atoms LVMC_11_30_090 uses for "walk along": moving, and not
`moving_across_carrier` for the nearby lanes. "where sidewalks are not provided" reuses the index
mapping of "Where sidewalks are provided": no `st.sidewalk` on that highway (`st.on_way`).

"Except as otherwise provided in subsection 6" carries two exception compositions,
NRS_484B_297_6_o1 and NRS_484B_297_6_o2.

The word "traffic" (the admitted aggregate DEF-NRS-484A-285::traffic) is deliberately not claimed. It
names the stream the lanes carry, and the duty is the same whether or not a road user is approaching.
Quantifying over traffic members would report a violation against a pedestrian when a wrong-way
vehicle is present. *Reversal signals:*
- the selection or validator insists the aggregate be claimed;
- on one-way highways (no centre line) the left side is read through the facing element only, which
  the narrowing discloses — reverse if the operator wants a road-edge reading there.

**NRS_484B_307_12a** (downward green arrow over a lane: "may drive in any lane …"). The text grants a
permission and states no duty, but the harness requires a violable rule. I read the permission as its
scope:
- It applies to a moving vehicle that faces a green arrow over some lane and drives in a lane with a
  lit lane-control signal facing it.
- It complies when the signal over the vehicle's own lane shows `green_down_arrow`.

Driving under another lit indication is reported as outside the permission. The narrowing says
whether that conduct is also forbidden is for (12)(b) and the following paragraphs. "facing the
signal" reuses the "pedestrians facing the signal" mapping (`dev.position`, `kin.position`,
`kin.heading`): the head lies ahead along the heading. *Reversal signal:* an operator rule that
permissive clauses are not formalized as violable rules, or a label showing yellow-X lanes judged
`not_applicable` under (12)(a).

**NRS_484B_307_12b** (red X: must not enter or drive in the lane). This applies where a lane-control
signal showing `red_x` is over some lane and faces the subject. The subject must not enter that lane
(`rel.occupies` rises) and must not occupy it while moving. A vehicle halted in the lane neither
enters nor drives in it (disclosed). *Reversal signal:* a label that treats a halted vehicle in a
red-X lane as a violation.

**NRS_484B_307_2a** (circular green alone: yield). There is one obligation, "must yield". The
right-of-way standard (DEF-NRS-484A-210, "danger of a crash") is operationalized by the
constant-velocity closest approach, with `p.conflict_horizon` and `p.conflict_centre_clearance` as
proposed by LVMC_11_12_070_B. "must yield" reuses the index mapping `kin.speed`, `rel.contact`.

The subject is traffic and a vehicle. "Facing the signal" means the subject is on, or entered the
intersection from, an approach carrier (`st.lane_enters`) governed by a signal (`dev.governs`) that
shows circular green alone.

The parties are other vehicles and pedestrians within the intersection or an adjacent crosswalk. An
adjacent crosswalk is one that marks the entrance (`st.entrance_of`) of a carrier into the same
intersection. "lawfully" is not read (see operator section). "unless another device … prohibits …
turns" limits the permission to turn, not the yield. It is a `scope: none` residue.

*Reversal signal:* the operator directs that "lawfully within" be composed with specific rules.

**NRS_484B_307_2b** (pedestrians facing circular green "may proceed … within any … crosswalk"). This
is a permission, read as its scope, the same way as (12)(a):
- It applies to a pedestrian who faces a circular-green-alone head and crosses a roadway lane
  (`moving_across_carrier`).
- It complies when the pedestrian occupies a crosswalk.

Facing uses two new parameters, `p.ped_traffic_signal_facing_cos` and
`p.ped_traffic_signal_facing_reach`. The pedestrian-signal parameters `p.ped_signal_facing_*` are
about pedestrian heads, so they are not reused. "unless directed otherwise by another device as
provided in NRS 484B.283 […]" names law lines 283-1d1 to 1d4. It becomes six exception compositions,
one per node of those lines: NRS_484B_283_1d1, _1d2, _1d3_o1, _1d3_o2, _1d4_o1 and _1d4_o2.
*Reversal signal:* same as (12)(a). A second signal would be if NRS_484B_283_1d1's subject turns out
to be the driver rather than the pedestrian; that composition would then never fire and could be
dropped.

**NRS_484B_307_3a** (circular green with green turn arrow: yield). This has the same structure as
(2)(a), with protected parties pedestrians in an adjacent crosswalk and other traffic
(DEF-NRS-484A-285::traffic) using the intersection. Two spans are `scope: none` residues:
- "to make the movement indicated … or such other movement as is permitted by the circular green
  signal" — the yield binds whatever the movement;
- the advisory sentence ("Drivers turning … are thereby advised …") — it requires nothing.

"Vehicular traffic" claims DEF-NRS-484A-320::vehicle although the definitions table lists no
"vehicle" term for this law. "Vehicular" is the defined word's adjective. Without it the subject
would include pedestrians and bicycles (human-powered devices are excluded from "vehicle" by
NRS 484A.320). *Reversal signal:* the selection role keeps its decision. If so, the subject becomes
traffic alone and a narrowing discloses the broader class.

**NRS_484B_307_4a_o1** (green turn arrow alone: proceed only in the arrow's direction). The obligation
is an act judged when the passage is recognized at the subject's exit from the intersection:
`left_/right_/u_turn_through_region` matched to the arrow's direction. The occasion boundary is the
event of entering the intersection (onset). "Where the signal is a green turn arrow alone" is read at
`some_moment` of the passage, with scenarios `occasion_s1` and `occasion_s1_outside`. "so long as the
arrow is illuminated" belongs to the obligation span and is read the same way (disclosed). A straight
arrow is no "turn arrow", so no straight case is needed. The vehicle aggregate claim is the same as
in 3a. *Reversal signal:* a label that reads the arrow at the entry instant only, which `atLast` on
the entry would carry.

**NRS_484B_307_4a_o2** (green turn arrow alone: yield). This has the same structure as 3a. "the
adjacent crosswalk" is read as every crosswalk marking an entrance into the intersection, because the
turning vehicle's exit leg is not known before the turn ends. The conflict bound then picks the
crosswalk its path meets (disclosed on the standard span).

## Conditions referring to words stated elsewhere

- **NRS_484B_297_2:** the reference span s1 points to NRS 484B.297(6). It is composed as an exception,
  so the duty does not apply where either node of (6) applies. (6) is about pedestrians moving around
  a sidewalk obstruction, a situation (2) would otherwise cover with a contrary direction rule.
- **NRS_484B_307_2b:** s6 points to NRS 484B.283(1)(d). It is composed as an exception, so where a
  pedestrian signal governs the crossing, its rules apply instead.
- **Nodes not yet published:** both sets of composed nodes are planned this iteration and not yet
  published. The compositions are kept regardless, because rule 5 says a dependency not yet coded is
  no reason to weaken them.

## For the operator

- **Permissions without a duty.** NRS 484B.307(12)(a) and (2)(b) grant permissions and impose no duty
  of their own. The harness requires a `forbid → violated` scenario, so each is read as the scope of
  its permission, disclosed on the obligation span. A corpus-wide convention for permissive clauses
  would settle whether such lines should be formalized at all.
- **"lawfully" in (2)(a), (3)(a), (4)(a).** The ontology says lawfulness of another road user's
  conduct is a rule composition, but these words name no rule. The parties' lawful presence could
  rest on 307(2)(b), 283(1)(d) or entries on earlier phases. The plan protects every party within,
  disclosed on the standard span. This over-reaches only toward unlawfully present parties. If the
  operator names the rules that make a party "lawfully within", the compositions can be added.
- **Facing a signal.** No atom carries a signal head's orientation, so "facing the signal" is read
  from where the head is (`dev.position`) relative to the road user's heading. Back-to-back heads at
  one gantry (reversible lanes) both lie "ahead". A device-facing attribute in the ontology would
  remove that ambiguity.
- **Halves of a crosswalk.** NRS 484B.293 relies on the crosswalk's reference point being its centre.
  A primitive for a region's half relative to a road user's motion would not need that assumption.
- **New parameters:**
  - `p.pedestrian_lateral_tolerance` — NRS_484B_293 and NRS_484B_297_2;
  - `p.ped_traffic_signal_facing_cos` — NRS_484B_307_2b;
  - `p.ped_traffic_signal_facing_reach` — NRS_484B_307_2b.

  Their provisional values are in the nodes' `param_proposals`. All other parameters are re-proposed
  with the earlier batches' names, values, units and conventions.
