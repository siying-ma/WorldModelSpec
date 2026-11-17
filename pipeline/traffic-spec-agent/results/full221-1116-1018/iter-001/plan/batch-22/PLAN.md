# Plan — batch 22: NRS 484B.450(1)(g)–(m), (o)

All eight lines share one preamble, and every node segments it the same way, reusing the mappings earlier batches made of the same words:

- "A person" maps to the vehicle aggregate, through the vehicle's controlled motion (an `agency` reading).
- "shall not stop, stand or park a vehicle," maps to `drv.motion.complete_halt` plus the vehicle aggregate.
- "with other traffic" maps to `rel.ahead_behind_in_lane`, `rel.surface_gap` and the traffic aggregate.
- "or in compliance with law" maps to a stop sign or a red traffic signal governing the occupied travel region.
- "or the directions of a police officer" maps to `dev.human_direction` with role police_officer and indication stop.
- "or official traffic-control device," maps to a stop sign, a yield sign, a red signal or an active railway signal or gate governing the occupied region.

"except when necessary to avoid conflict" is a `standard`. It is operationalized as a halt behind a member of traffic ahead in the same lane, within `p.queue_halt_gap`; a narrowing discloses that halts for crossing traffic are not read. Stop, stand and park are each a halting under DEF-484A-260/250/155, so forbidding all three forbids any halt. One concept carries that: the catalogued proposal `drv.motion.complete_halt`. No node proposes a new concept, and `aggregates.jsonl` is empty because no clause defines its own members.

**NRS_484B_450_1g.** The place is the approach to a vehicular traffic signal (`dev.traffic_signal`, per DEF-484A-290 "alternately directed to stop or proceed"). The approach is a travel region the subject occupies that the signal governs, or that enters an intersection the signal governs. The head (`dev.position`) must lie ahead along that region's direction, and the subject's front must be within the literal 30 ft of it. "Located at the side of a highway" means the head lies laterally beyond a roadway edge in the subject's frame (`prim.region_lateral_offset`), rather than over the roadway. Pedestrian, lane-control and railway signals are left out by the definition and the law's own words. Reversal signal: a source that records how a signal is mounted, or a reviewer who rejects the lateral test against the roadway edge.

**NRS_484B_450_1h.** The adjacent curb is the roadway edge nearest the safety zone, computed from both regions' signed lateral offsets from the subject. The subject is "between" when the zone and that edge lie on opposite sides of it, the zone is alongside (body distance at most the lateral offset), and the subject is not inside the zone. "Within 30 feet of points on the curb opposite the ends" is the right-triangle combination of two gaps: the gap along the carrier beyond the zone's end (`prim.region_offset_along` less half the subject's length) and the gap to that curb. Reversal signal: a reviewer who rules that "adjacent" between two regions needs its own relation atom; that would be an atom gap on s9.

**NRS_484B_450_1i — carries a gap.** "the nearest rail of a railroad" can only reach `st.railway_crossing`, which holds rails only where a railway crosses the roadway. That leaves two problems:
- a railroad's rails running beside a highway are read by no atom;
- the crossing kind cannot exclude streetcars, as DEF-484A-200 requires.

Since a duty must cover its domain, I filed the atom gap `st.railway_track` (kind ∈ {railroad, streetcar}) on s9 instead of narrowing the trigger. The node keeps its full mapping to the nearest atoms. Reversal signal: the operator retires the gap, or declares that railway crossings are the only rails a source maps within 50 ft of a highway and that streetcars are out of scope.

**NRS_484B_450_1j.** The first place is within the literal 20 ft of a `st.fire_station_entrance`. The driveway definition's "private ownership" is read from the feature's presence (a `status` reading). The second place is "on the side of a highway opposite the entrance". The subject occupies a highway, and some roadway edge of that highway lies between the subject and the entrance that is farther from the subject than every edge on its other side. That means the subject is past the middle of the way, which works for two-way, one-way and divided ways without needing a centre line. The subject must also be within the literal 75 ft of that same entrance region. Reversal signal: a source that maps highways without their outer edges.

**NRS_484B_450_1k.** "Alongside or opposite" means a `st.obstruction` of any kind, lying on the highway the subject occupies, is off to the subject's side rather than ahead or behind. "Would obstruct traffic" is a standard operationalized with `p.free_passage_width`. Traffic is obstructed when the free width is too narrow on both sides of the halted vehicle: between its body and the object, and between its body and the roadway edge on its other side. A narrowing on that standard span discloses two things: the passage beyond the object's far side is not read, and "traffic" is read as the passage traffic needs, not as traffic actually present. Reversal signal: a labelled scene in which traffic passes beyond the object while the rule reports a violation.

**NRS_484B_450_1l.** "any vehicle stopped or parked" is another vehicle of the aggregate, quantified inside the applicability (the idle scenario has none). It is at rest (`drv.motion.complete_halt`), and its body is within the new proposed parameter `p.edge_standing_gap` of a roadway edge lying on a highway. The subject is on its highway side when the two are side by side (`rel.longitudinal_overlap` ≥ 0) and the other vehicle and its edge lie on the same side of the subject. The words state no distance, so none is added.

**NRS_484B_450_1m.** `st.elevated_structure` ("bridge, viaduct or tunnel carrying the roadway") carries both the bridge/elevated-structure span and the "highway tunnel" span, anchored by `rel.occupies`.

**NRS_484B_450_1o.** The prohibiting devices are:
- `dev.regulatory_sign` with code no_stopping, no_standing or no_parking, under `prim.conditions_hold` and governing the occupied region;
- `st.curb_zone` of kind no_stopping or no_parking that the subject occupies.

The obligation is read respectively, and a `reading` narrowing on the obligation span s2 discloses this:
- under no-stopping, any halt is forbidden;
- under no-standing, `drv.motion.parked` with `p.standing_min_duration`;
- under no-parking, `drv.motion.parked` with `p.parking_min_duration`.

The purpose part of standing and parking is read through how long the vehicle has been at rest (a `purpose` reading). Reversal signal: a reviewer who holds the literal reading, under which any halt at any of these places is forbidden.

**"or in compliance with law" (every node).** I mapped it as earlier batches did (NRS_484B_450_1a, LVMC_11_52_130_A11): a halt commanded by a stop sign or a red signal that governs the occupied region. The validator does not allow a narrowing on an exception span, so the limits of this reading are stated in the element's justification and here: a halt that another law requires without such a device is not excused.

## For the operator

- Open operator gap smoke31-1111-0039:G22 sits on the same words "or in compliance with law", filed on NRS-484B-450-1c. This iteration's batches, and this one, carry those words with device atoms instead. If G22 is accepted, these eight nodes, 1a, 1c, 1e and LVMC_11_52_130_A11 should be re-planned together with it.
- The NRS_484B_450_1i gap `st.railway_track` blocks only (1)(i). A road-crossing-only reading would unblock it, but the rule would then be wrong next to rails running beside a road and next to streetcar lines.
- The parameters re-proposed here are `p.halt_speed_tolerance`, `p.queue_halt_gap`, `p.free_passage_width`, `p.standing_min_duration` and `p.parking_min_duration`, each with the same name, value, unit and convention earlier batches used. The only new one is `p.edge_standing_gap`.
