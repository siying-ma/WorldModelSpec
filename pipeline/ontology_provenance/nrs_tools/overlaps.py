"""Resolution of overlapping obligations: for each pair, the text with the narrower definition is
kept and the other is dropped from the corpus. `DROP` maps a dropped id to (kept ids, reason).
`PARTIAL` records pairs that were flagged as overlapping but where each text carries an
obligation the other lacks; both stay. This module is the single record of these choices; the
generator applies it and writes OVERLAPS.md from it."""

CRITERION = """A pair is decided by asking which text defines the rule more narrowly: a more
concretely stated trigger (a sign, a marked crosswalk, a distance, a class of vehicle) and an
obligation with fewer open judgement terms and with its exceptions stated. Three tie-breakers,
in order: (1) where the state statute expressly preempts municipal regulation of the subject
(NRS 486.180(2) for the operation and equipment of motorcycles and mopeds; NRS 484A.400 for the
rules of the road generally) the statute is kept; (2) where the texts are the same obligation in
the same words, the statute is kept because it applies on every Las Vegas street including those
outside city limits; (3) where neither text contains the other, both are kept and the pair is
recorded below as partial."""

DROP = {
 # ---- municipal text dropped, statute kept ----
 'LVMC-11-06-030': (['NRS-484B-100'], "NRS limits the duty to a police officer performing enforcement duties; LVMC extends it to any authorized official."),
 'LVMC-11-12-050': (['NRS-484B-403-1', 'NRS-484B-403-3'], "NRS 484B.403(3) states the business-district U-turn ban with its exceptions (at an intersection, at a divided-highway opening); LVMC states a flat ban. NRS 484B.403(1) carries the cross-references to the other U-turn prohibitions."),
 'LVMC-11-12-070-A': (['NRS-484B-257-1'], "NRS fixes where the stop is made (stop line, crosswalk, point of view) and when the yield applies (while moving across or within the intersection); LVMC says only 'stop as required by this Code'."),
 'LVMC-11-12-080-B': (['NRS-484B-127-2'], "NRS defines the vehicles (trucks or combinations 80 inches or more wide following the same), the space (500 feet) and the exception (two or more lanes in the direction); LVMC has none of these."),
 'LVMC-11-16-020': (['NRS-484B-363-1'], "NRS defines when the 15 mph school-zone limit is in effect by the sign legend and the speed limit beacon, which are observable; LVMC keys it to school hours and days in session. The LVMC remainder (school grounds and parking lots) is off-highway and out of scope."),
 'LVMC-11-16-070': (['NRS-484B-363-2', 'NRS-484B-600-1c'], "The school-crossing part of LVMC 11.16.070 is the NRS school crossing zone, which NRS defines by sign and beacon rather than by 'while children are going to or leaving school'; the schedule part (30–65 mph by Schedule 25) is the posted limit already carried by NRS 484B.600(1)(c)."),
 'LVMC-11-20-040': (['NRS-484A-450-2'], "Same stop positions; NRS adds the fallback 'point nearest the intersecting highway where the driver has a view of approaching traffic', LVMC only 'a point at the entrance'."),
 'LVMC-11-22-040': (['NRS-484B-117-1'], "NRS excepts driveway and alley entrances; LVMC excepts only driveways and adds standing on a sidewalk, which the parking rules already carry (NRS 484B.450(1)(a))."),
 'LVMC-11-22-050': (['NRS-484B-587-1'], "NRS conditions the prohibition on the entrance and exit devices being erected; LVMC on entrances 'established by public authority', which is not observable."),
 'LVMC-11-22-055': (['NRS-484D-285-1'], "Both turn on an unobservable muffler; NRS states its exceptions in full (operational muffler, emergency belief). Tie-breaker: statute."),
 'LVMC-11-22-070': (['NRS-484B-110'], "Identical words. Tie-breaker: statute."),
 'LVMC-11-22-090': (['NRS-484B-153-2', 'NRS-484B-153-3'], "NRS states the door duty as interference with moving traffic (observable) rather than LVMC's 'reasonably safe' (judgement), and splits the two duties."),
 'LVMC-11-22-100': (['NRS-484B-327-2'], "NRS is confined to a highway marked, signed or barricaded as closed; LVMC adds new pavement with a warning person or sign."),
 'LVMC-11-28-050': (['NRS-484D-400-2'], "Same horn duty; LVMC adds an equipment sentence. Tie-breaker: statute."),
 'LVMC-11-28-060': (['NRS-484D-400-5'], "Same siren-use limits; LVMC merges equipment and use. Tie-breaker: statute."),
 'LVMC-11-30-020': (['NRS-484B-283-1a', 'NRS-484B-283-1b'], "NRS limits the yield to a pedestrian within a crosswalk on the driver's half of the highway and defines 'half of the highway'; LVMC extends it to any pedestrian crossing the roadway."),
 'LVMC-11-30-040': (['NRS-484B-293'], "Identical words. Tie-breaker: statute."),
 'LVMC-11-30-070-A': (['NRS-484B-287-1c'], "NRS requires a marked crosswalk between signalised intersections; LVMC allows any crosswalk."),
 'LVMC-11-30-100': (['NRS-484B-297-2'], "NRS requires walking on the left side facing traffic without qualification; LVMC adds 'when practicable'."),
 'LVMC-11-30-130': (['NRS-484B-280-1a', 'NRS-484B-280-1b', 'NRS-484B-280-1c'], "NRS splits the due-care duty and names the places where proper caution is owed (bus stops, school zones, crosswalks); LVMC states it in one sentence."),
 'LVMC-11-32-040': (['NRS-484B-307-12a', 'NRS-484B-307-12b'], "NRS names the indications (downward-pointing green arrow, red X); LVMC says 'green signal' and 'red signal'."),
 'LVMC-11-38-010': (['NRS-486-191-1', 'NRS-486-181-1'], "NRS 486.180(2) preempts municipal regulation of motorcycle operation; the seat and passenger duties are NRS 486.191(1) and 486.181(1)."),
 'LVMC-11-38-020': (['NRS-486-181-1'], "Preempted by NRS 486.180(2); NRS 486.181(1) states the passenger rule. LVMC's operator-age condition is not observable."),
 'LVMC-11-38-050': (['NRS-486-351-1'], "Preempted by NRS 486.180(2); NRS also covers stationary vehicles and defines the manoeuvre as driving between vehicles occupying adjacent lanes."),
 'LVMC-11-38-120-B': (['NRS-486-251-1'], "Preempted by NRS 486.180(2); NRS states the lighting times (half hour after sunset, 1,000 feet)."),
 'LVMC-11-40-090': (['NRS-484B-770-1', 'NRS-484B-770-2'], "Identical words; NRS splits the two duties. Tie-breaker: statute."),
 'LVMC-11-40-100': (['NRS-484B-777-1'], "NRS states the exceptions (speed commensurate with traffic, preparing to turn left, unsafe conditions, with the conditions defined); LVMC has none."),
 'LVMC-11-40-110': (['NRS-484B-777-3'], "Identical words. Tie-breaker: statute."),
 'LVMC-11-40-160': (['NRS-484B-780'], "Identical words. Tie-breaker: statute."),
 'LVMC-11-40-190': (['NRS-484B-783-1'], "Different equipment lists for the same trigger (night use); NRS 484B.783 is the state equipment rule for bicycles. Tie-breaker: statute."),
 'LVMC-11-42-020': (['NRS-484B-220-1'], "NRS keys the one-way duty to a highway 'designated and signposted'; LVMC keys it to Schedules 26-I/II held by the City Clerk."),
 'LVMC-11-52-040-B': (['NRS-484B-457-1'], "NRS specifies right-hand wheels parallel to and within 18 inches of the right-hand curb where curbs exist; LVMC says wheels within 18 inches of the curb or edge."),
 'LVMC-11-52-050': (['NRS-484B-477-1b'], "NRS confines the 10-foot clearance rule to alleys; LVMC extends it to streets."),
 'LVMC-11-52-110': (['NRS-484B-533'], "NRS confines the unattended-vehicle duty to a perceptible grade and to observable acts (brake, wheels turned); LVMC applies everywhere and adds ignition and key."),
 'LVMC-11-52-130-A1': (['NRS-484B-450-1o'], "NRS prohibits stopping where devices prohibit it; LVMC A(1) also covers restrictions 'for a period longer or purpose other than permitted', which the time-limit and loading-zone lines carry separately."),
 'LVMC-11-52-130-A3': (['NRS-484B-450-1o'], "Contained in NRS 484B.450(1)(o) (posted signs are official devices); LVMC A(3)'s extra condition, a determination that the activity is dangerous, is administrative and not observable."),
 'LVMC-11-52-130-A6': (['NRS-484B-450-1a'], "NRS prohibits stopping on a sidewalk and carries the bicycle exception; LVMC adds 'or blocking', a judgement."),
 'LVMC-11-52-130-A8': (['NRS-484B-450-1i'], "Identical (50 feet of the nearest rail). Tie-breaker: statute."),
 'LVMC-11-52-130-A9': (['NRS-484B-450-1j'], "Identical (20 feet / 75 feet at a fire station). Tie-breaker: statute."),
 'LVMC-11-52-130-A10': (['NRS-484B-450-1l'], "Identical (double parking). Tie-breaker: statute."),
 'LVMC-11-52-130-A13': (['NRS-484B-450-1g'], "NRS confines the 30-foot rule to the approach to a traffic-control signal at the side of the highway; LVMC applies it to any signal or device."),
 'LVMC-11-52-130-A14': (['NRS-484B-270-3'], "NRS states the bicycle-lane prohibition with its six exceptions and the yield duty; LVMC states a flat parking ban."),
 'LVMC-11-52-130-A15': (['NRS-484B-450-1k'], "NRS names the place (alongside or opposite an excavation or obstruction) and the effect (would obstruct traffic); LVMC is a general 'undue obstruction or hazard' judgement."),
 'LVMC-11-52-130-A16': (['NRS-484B-450-1m'], "NRS: bridge, elevated structure or tunnel; LVMC adds underpass. Narrower text kept."),
 'LVMC-11-52-240': (['NRS-484B-450-1o'], "A schedule-based restatement of the sign/red-curb prohibition already carried by NRS 484B.450(1)(o); the curb-colour meaning is carried by LVMC 11.52.030(A), which stays."),
 'LVMC-11-60-020': (['NRS-484B-517'], "NRS carries the passenger-vehicle temporary-stop exception; LVMC has no exception."),
 'LVMC-11-60-080': (['NRS-484B-517'], "Contained in NRS 484B.517 (taxicab stands) with the same loading exception; LVMC adds only an emergency-vehicle exception."),
 'LVMC-11-12-080-A': (['NRS-484B-127-1'], "Same words (tie-breaker 2); LVMC adds only an exception for funeral processions, which are outside the operational design domain (decided 2026-10-13)."),
 # ---- statute text dropped, municipal kept ----
 'NRS-484B-223-1a': (['LVMC-11-18-030-B'], "LVMC states the exceptions to lane-keeping (lawfully passing, preparing a lawful turn); NRS states the duty as 'as nearly as practicable', a judgement."),
 'NRS-484B-283-1c': (['LVMC-11-30-030'], "LVMC triggers on a vehicle stopped at a crosswalk to permit a pedestrian to cross and prohibits passing outright; NRS makes the prohibition depend on what the overtaking driver 'has determined', a knowledge standard."),
 'NRS-484B-297-1': (['LVMC-11-30-090'], "LVMC forbids walking along the roadway where a sidewalk exists; NRS says 'highway', which by definition includes the sidewalk itself."),
 'NRS-484B-773': (['LVMC-11-40-150'], "LVMC binds riders of bicycles, electric bicycles and electric scooters; NRS also binds coasters, skates, sleds and toy vehicles. Narrower class kept."),
 'NRS-484B-503': (['LVMC-11-44-020'], "LVMC adds the time limits a passenger loading zone may post (three minutes; immediate loading only)."),
 'NRS-484B-507-1': (['LVMC-11-44-060'], "LVMC limits a commercial loading zone stop to thirty minutes and to vehicles whose commercial nature is evident or marked; NRS has neither."),
 'NRS-484B-450-1d': (['LVMC-11-52-130-A4'], "NRS's twenty-foot case applies only 'if angle parking is permitted and a local ordinance requires the greater distance'; LVMC 11.52.130(A)(4) is that ordinance and states both distances unconditionally."),
 'NRS-484B-450-1b': (['LVMC-11-52-130-A7'], "LVMC combines 'in front of' and 'within five feet of' a driveway and states the owner/invitee and postal exceptions; NRS splits them and has only the postal exception."),
 'NRS-484B-450-1n': (['LVMC-11-52-130-A7'], "As for the preceding line."),
 'NRS-484B-450-1f': (['LVMC-11-52-130-A12'], "LVMC confines the twenty-foot setback to a marked crosswalk; NRS applies it to any crosswalk, including unmarked ones."),
 'NRS-484B-477-1a': (['LVMC-11-52-180-A'], "LVMC keys the alley prohibition to posted signs and confines the loading exception to evidently commercial vehicles; NRS keys it to the business district, a reading assumption."),
 'NRS-484B-513': (['LVMC-11-60-030-A1', 'LVMC-11-60-030-A2', 'LVMC-11-60-040'], "LVMC names the places a bus may stand (bus stop, bus stand, designated origin or destination point) and stop to load (adding passenger loading zones), with an emergency exception, and states the taxicab rule separately; NRS states both in one sentence limited to business districts."),
}

PARTIAL = {
 'LVMC-11-12-070-B': (['NRS-484B-257-1'], "Distinct obligation: through-highway drivers must yield to a vehicle that has stopped, yielded and is proceeding; NRS 484B.257 has no reciprocal duty."),
 'LVMC-11-12-100-C': (['NRS-484B-223-3a'], "First sentence matches NRS 484B.223(3)(a); the second ('a left turn shall not be made from any other lane where a two-way left-turn lane has been designated') has no statutory counterpart."),
 'LVMC-11-20-060': (['NRS-484B-260'], "LVMC adds a stop before the sidewalk and a yield to pedestrians, in business and residence districts; NRS 484B.260 is the yield to vehicles from any private way anywhere."),
 'LVMC-11-40-070': (['NRS-484B-300-1'], "Same duty, different subject: LVMC binds riders directly, NRS binds drivers and reaches riders only through the applicability rule (NRS 484B.763)."),
 'LVMC-11-52-070': (['NRS-484B-460'], "Different obligations at an angle-parking location: LVMC requires the front of the vehicle toward the direction of traffic; NRS requires the angle the devices indicate."),
 'LVMC-11-30-060-A': (['NRS-484B-287-1a'], "Different place: NRS binds a pedestrian crossing a highway, the whole right-of-way including the shoulder, to yield to all vehicles upon the highway; LVMC binds one crossing the roadway, the travelled part, to yield to all vehicles upon the roadway. Neither text contains the other (operator, 2026-11-18)."),
 'LVMC-11-30-060-B': (['NRS-484B-287-1b'], "Highway, shoulder included, versus roadway, as for the preceding pair, for a pedestrian crossing where a pedestrian tunnel or overhead crossing has been provided (operator, 2026-11-18)."),
 'LVMC-11-30-140-B': (['NRS-484B-290'], "Different protected person and duty: NRS protects a blind pedestrian using a service animal or carrying a white cane, and the driver yields and comes to a full stop if necessary; LVMC protects one carrying a white cane or assisted by a person, and the driver comes immediately to a full stop (operator, 2026-11-18)."),
 'LVMC-11-46-030': (['NRS-484B-350-1a', 'NRS-484B-350-1b'], "Different place and release: NRS requires a stop in obedience to a school crossing guard's direction or signal, wherever given, and no proceeding until the highway is clear of all persons; LVMC requires a stop not less than fifty feet from a school pedestrian lane where a signal device, flagman or other person is stationed, until the signal is stopped, raised or removed or the flagman or person signals to go or leaves (operator, 2026-11-18)."),
}
