/-
  Witnesses for NRS_484A_450_2.

  The geometry. One crossroads, built once and shared by every witness (+x east, +y north):

    region 10  the subject's own way, a highway 12 m wide (y from −6 to 6) running east from
               x = −260 to the far side of the junction at x = 14;
    region 11  the junction, the region where the two roadways meet: x from 0 to 14, y from −6
               to 6, lying on both ways (`ways := [10, 20]`);
    region 12  the subject's approach lane, x from −260 to 0 and y from −3.6 to 0, its designated
               direction east, its entrance end the junction (`enters := 11`), lying on way 10;
    region 20  the intersecting highway, the cross street: x from 0 to 14, y from −80 to 80 — the
               way no part of lane 12 lies on;
    region 21  a northbound approach carrier of the cross street, x from 7 to 14 and y from −80
               to −6, its entrance end the junction, lying on way 20. It is the carrier that makes
               way 20 the intersecting highway: a carrier entering the same junction lies on it,
               and no part of the subject's lane does.

  The marks each witness adds across the subject's lane (same y extent as the lane):

    region 13  a marked crosswalk from x = −10 to x = −7, 7 m short of the junction;
    region 14  a stop line, 0.3 m deep, placed where the witness needs it;
    regions 15, 16  a crosswalk and a stop line across the cross street's carrier (21), whose
               entrances the source observes and which mark that carrier only — the scene in which
               no mark marks the subject's lane.

  Every mark declares `entranceObserved`, so which carriers it marks is observed, except where a
  witness's manifest declares `st.entrance_of` absent.

  The subject is track 1, a passenger car 4 m by 1.8 m carried at y = −1.8 m, the middle of the
  lane, except in the witness where it swerves in from the south half of the way, and in the
  bicycle witness, where the same place carries a bicycle 1.8 m by 0.6 m. Each trace is a list of
  instants a second apart; each instant names the body's x, its speed, and the regions its
  footprint overlaps — stated rather than derived, since a footprint entering the junction still
  overlaps the lane behind it while its reference point lies in one polygon only. The subject's
  view is given per way (`sightAlongWay`), for the intersecting highway 20 — the way whose view
  the standard requires, and the only region a sight distance along a way is recorded for. No road
  user but the subject is anywhere in any scene.

  Every figure here is the witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.NRS_484A.NRS_484A_450_2
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484A_450_2

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n
def mps (n : Int) : Q := Units.metresPerSecond n

-- Binders ↦ tracks: veh ↦ 1

/-- Half-extents: a passenger car, 4 m by 1.8 m by 1.5 m. -/
def carHalf : Q × Q × Q := (m 2, cm 90, cm 75)
/-- Half-extents: a bicycle, 1.8 m by 0.6 m by 1.2 m. -/
def bikeHalf : Q × Q × Q := (cm 90, cm 30, cm 60)
/-- The middle of the subject's lane. -/
def laneY : Q := cm (-180)
/-- A view along the cross street well beyond the reading's sight distance. -/
def sightFar : Q := m 120
/-- A view along the cross street well short of it. -/
def sightShort : Q := m 60

-- -------------------------------------------------------------------------------------------
-- The crossroads
-- -------------------------------------------------------------------------------------------

/-- The subject's own way. -/
def ownWay : Structure := Build.rect 10 .highway (m (-260)) (m (-6)) (m 14) (m 6)

/-- The junction, which lies on both ways. -/
def junction : Structure :=
  { Build.rect 11 .intersection Q.zero (m (-6)) (m 14) (m 6) with ways := some [10, 20] }

/-- The subject's approach lane: direction east, entrance end the junction, on way 10. -/
def approachLane : Structure :=
  { Build.lane 12 [(m (-260), cm (-360)), (Q.zero, cm (-360)), (Q.zero, Q.zero), (m (-260), Q.zero)]
      Build.east (enters := some 11) with ways := some [10] }

/-- The intersecting highway. -/
def crossWay : Structure := Build.rect 20 .highway Q.zero (m (-80)) (m 14) (m 80)

/-- A northbound approach carrier of the intersecting highway. -/
def crossLane : Structure :=
  { Build.lane 21 [(m 7, m (-80)), (m 14, m (-80)), (m 14, m (-6)), (m 7, m (-6))]
      Build.north (enters := some 11) with ways := some [20] }

def crossroads : List Structure := [ownWay, junction, approachLane, crossWay, crossLane]

/-- A marked crosswalk across the subject's lane, from x = −10 to x = −7, marking the entrance of
    the carriers listed. -/
def crosswalkOfLane : Structure :=
  { Build.rect 13 .crosswalk (m (-10)) (cm (-360)) (m (-7)) Q.zero with
      marked := some true, ways := some [10], entranceOf := [12], entranceObserved := true }

/-- A stop line across the subject's lane, 0.3 m deep, whose near edge is at `x0`, marking the
    entrance of lane 12. -/
def stopLineOfLane (x0 : Q) : Structure :=
  { Build.rect 14 .stopLine x0 (cm (-360)) (Q.add x0 (cm 30)) Q.zero with
      ways := some [10], entranceOf := [12], entranceObserved := true }

/-- A crosswalk across the cross street's carrier, marking that carrier's entrance only. -/
def crosswalkOfCrossStreet : Structure :=
  { Build.rect 15 .crosswalk (m 7) (cm (-920)) (m 14) (cm (-620)) with
      marked := some true, ways := some [20], entranceOf := [21], entranceObserved := true }

/-- A stop line across the cross street's carrier, marking that carrier's entrance only. -/
def stopLineOfCrossStreet : Structure :=
  { Build.rect 16 .stopLine (m 7) (cm (-1450)) (m 14) (cm (-1420)) with
      ways := some [20], entranceOf := [21], entranceObserved := true }

/-- The scene whose only marks are the cross street's: the source observes their entrances and
    they exclude the subject's lane. -/
def noMarkOfLane : List Structure := crossroads ++ [crosswalkOfCrossStreet, stopLineOfCrossStreet]

/-- The scene with a crosswalk marking the subject's lane. -/
def crosswalkScene : List Structure := crossroads ++ [crosswalkOfLane]

/-- The scene with a stop line marking the subject's lane close to the junction (near edge at
    x = −8) and no crosswalk at all. -/
def stopLineScene : List Structure := crossroads ++ [stopLineOfLane (m (-8))]

/-- The scene with both marks across the subject's lane: the stop line well upstream (near edge at
    x = −18.5) and the crosswalk at x = −10. -/
def bothMarksScene : List Structure := crossroads ++ [crosswalkOfLane, stopLineOfLane (cm (-1850))]

-- -------------------------------------------------------------------------------------------
-- The subject and the instants
-- -------------------------------------------------------------------------------------------

/-- The subject at a place, running east at a speed, with the view it has along the cross street. -/
def subjectAt (classes : List RoadUserClass) (half : Q × Q × Q) (x y v sight : Q) : RoadUser :=
  { Build.user 1 classes (x, y) Build.east v half with
      sightAlongWay := some [(20, sight)] }

def car (x v : Q) : RoadUser := subjectAt [.motorVehicle] carHalf x laneY v sightFar
def carSeeing (x v sight : Q) : RoadUser := subjectAt [.motorVehicle] carHalf x laneY v sight

/-- An instant: the body and the regions its footprint overlaps. -/
def step (x v : Q) (occ : List RegionId) : RoadUser × List RegionId := (car x v, occ)
def stepSeeing (x v sight : Q) (occ : List RegionId) : RoadUser × List RegionId :=
  (carSeeing x v sight, occ)
/-- An instant at which the body is off the middle of the lane. -/
def stepOff (x y v : Q) (occ : List RegionId) : RoadUser × List RegionId :=
  (subjectAt [.motorVehicle] carHalf x y v sightFar, occ)
/-- An instant at which the body is backing: the velocity runs west, the heading stays east. -/
def stepBacking (x v : Q) (occ : List RegionId) : RoadUser × List RegionId :=
  (Build.withKin (car x v) (fun kn => { kn with velocity := some (Build.scale Build.west v) }), occ)
/-- An instant whose body is a bicycle. -/
def stepBike (x v : Q) (occ : List RegionId) : RoadUser × List RegionId :=
  (subjectAt [.bicycle] bikeHalf x laneY v sightFar, occ)

/-- A trace from the instants, a second apart, with the stated occupancy. -/
def traceOf (structs : List Structure) (devs : List Device)
    (steps : List (RoadUser × List RegionId)) : Trace :=
  Build.trace steps.length 0 (Units.seconds 1) fun k t =>
    let (u, occ) := steps.getD k (car Q.zero Q.zero, [])
    Build.scene t (some 1) [u] structs devs (some (occ.map fun r => (1, r)))

/-- A stop sign governing the regions listed. -/
def stopSignFor (governs : List RegionId) : Device := Build.sign 100 .stopSign governs
/-- A yield sign governing the regions listed: no stop sign is anywhere in the scene. -/
def yieldSignFor (governs : List RegionId) : Device := Build.sign 100 .yieldSign governs

/-- The run up to the junction at 5 m/s, crossing the crosswalk of lane 12 without slowing, and
    entering the junction with the footprint wholly past the lane. -/
def rollingThrough : List (RoadUser × List RegionId) :=
  [ step (m (-25)) (mps 5) [10, 12]
  , step (m (-18)) (mps 5) [10, 12]
  , step (m (-11)) (mps 6) [10, 12, 13]
  , step (cm (-450)) (mps 6) [10, 12]
  , step (cm 250) (mps 6) [10, 11, 20]
  , step (cm 850) (mps 6) [10, 11, 20] ]

-- -------------------------------------------------------------------------------------------
-- The witnesses
-- -------------------------------------------------------------------------------------------

/-- `forbid` (violated): A car runs up a side-street approach governed by a stop sign, crosses the marked crosswalk at the entrance of its lane without ever dropping below walking pace, and rolls into the crossroads. Its approach is recorded from well upstream of the crosswalk, and no other road user is anywhere in the scene. -/
def forbidTrace : Trace := traceOf crosswalkScene [stopSignFor [12]] rollingThrough

/-- `permit` (compliant): The same approach and stop sign: the car comes to a complete standstill just short of the crosswalk that marks its lane's entrance, its body clear of the crossing, waits, then moves off and enters the crossroads. The halt is made with the crosswalk 0.5 m ahead of the front bumper, inside the stop-point tolerance, and at the entry the footprint overlaps both the lane and the junction. -/
def permitTrace : Trace :=
  traceOf crosswalkScene [stopSignFor [12]]
    [ step (m (-25)) (mps 5) [10, 12]
    , step (m (-18)) (mps 5) [10, 12]
    , step (m (-15)) (mps 4) [10, 12]
    , step (cm (-1250)) Q.zero [10, 12]
    , step (cm (-1250)) Q.zero [10, 12]
    , step (cm (-850)) (mps 4) [10, 12, 13]
    , step (m (-4)) (mps 4) [10, 12]
    , step (m (-1)) (mps 3) [10, 11, 12, 20] ]

/-- `idle` (not_applicable): A car crosses a junction on a carrier no stop sign governs - the only sign in the scene is a stop sign recorded as governing the cross street's approach, not the subject's, and no sign governs the junction region - and it enters without halting. -/
def idleTrace : Trace := traceOf crosswalkScene [stopSignFor [21]] rollingThrough

/-- `blind` (unknown): A stop-sign approach across which a crosswalk and a stop line both lie - the line well upstream, the crossing at the lane's entrance - and the source does not observe which carriers' entrances those marks mark. The car halts just short of the crosswalk, its body clear of the crossing, and 5.7 m past the stop line, then enters. If the crosswalk governs the approach the halt discharges the duty; if the line governs it was made well beyond it; which mark governs cannot be decided, so the duty is unknown. (The plan's narrative for this witness has the car never halting at all, which the obligation decides as violated whichever mark governs - the verdict then turns on no masked observation; the scene is built so that it turns on exactly the masked atom, and the planned verdict and masked atom are kept.) -/
def blindTrace : Trace :=
  traceOf bothMarksScene [stopSignFor [12]]
    [ step (m (-25)) (mps 5) [10, 12]
    , step (m (-21)) (mps 4) [10, 12]
    , step (m (-16)) (mps 4) [10, 12]
    , step (cm (-1250)) Q.zero [10, 12]
    , step (cm (-1250)) Q.zero [10, 12]
    , step (cm (-850)) (mps 4) [10, 12, 13]
    , step (m (-4)) (mps 4) [10, 12]
    , step (m (-1)) (mps 3) [10, 11, 12, 20] ]

/-- `branch_1` (compliant): A stop-sign approach with no crosswalk and no stop line - the source observes the entrances of the marks in the scene and they exclude this carrier - and the car comes to a complete standstill at the last point on its lane from which the sight along a carrier of the intersecting highway that enters the junction is at least the distance the reading's sight parameter sets, then enters. The halt is made with the front bumper 0.5 m from the cross street and the junction not yet entered. -/
def branch_1Trace : Trace :=
  traceOf noMarkOfLane [stopSignFor [12]]
    [ stepSeeing (m (-25)) (mps 5) sightFar [10, 12]
    , stepSeeing (m (-18)) (mps 5) sightFar [10, 12]
    , stepSeeing (m (-10)) (mps 4) sightFar [10, 12]
    , stepSeeing (cm (-250)) Q.zero sightFar [10, 12]
    , stepSeeing (cm (-250)) Q.zero sightFar [10, 12]
    , stepSeeing (cm 250) (mps 5) sightFar [10, 11, 20] ]

/-- `branch_2` (violated): A stop-sign approach with a crosswalk marking the lane's entrance: the car rolls over the crosswalk without stopping and halts completely 2.5 m beyond it, just short of the junction, before entering. The halt is both past the crossing along the lane's direction and farther from it than the stop-point tolerance. -/
def branch_2Trace : Trace :=
  traceOf crosswalkScene [stopSignFor [12]]
    [ step (m (-25)) (mps 5) [10, 12]
    , step (m (-18)) (mps 5) [10, 12]
    , step (m (-11)) (mps 5) [10, 12, 13]
    , step (m (-6)) (mps 4) [10, 12, 13]
    , step (cm (-250)) Q.zero [10, 12]
    , step (cm 250) (mps 5) [10, 11, 20] ]

/-- `branch_3` (violated): The same stop-sign approach and crosswalk, but the car halts with the crosswalk just behind its rear bumper - nearer the mark than the stop-point tolerance, yet past it along the lane's designated direction - and then enters the junction. -/
def branch_3Trace : Trace :=
  traceOf crosswalkScene [stopSignFor [12]]
    [ step (m (-25)) (mps 5) [10, 12]
    , step (m (-18)) (mps 5) [10, 12]
    , step (m (-11)) (mps 5) [10, 12, 13]
    , step (m (-7)) (mps 3) [10, 12, 13]
    , step (cm (-450)) Q.zero [10, 12]
    , step (cm (-450)) Q.zero [10, 12]
    , step (cm 150) (mps 5) [10, 11, 12, 20] ]

/-- `branch_4` (violated): A stop-sign approach whose marks the source observes to mark only the cross street, so neither a crosswalk nor a stop line governs this carrier, and the car does come to a complete standstill at the point of its lane nearest the intersecting highway - but from every point of its lane the sight along the carriers of that highway falls short of the distance the reading's sight parameter sets. -/
def branch_4Trace : Trace :=
  traceOf noMarkOfLane [stopSignFor [12]]
    [ stepSeeing (m (-25)) (mps 5) sightShort [10, 12]
    , stepSeeing (m (-18)) (mps 5) sightShort [10, 12]
    , stepSeeing (m (-10)) (mps 4) sightShort [10, 12]
    , stepSeeing (cm (-250)) Q.zero sightShort [10, 12]
    , stepSeeing (cm (-250)) Q.zero sightShort [10, 12]
    , stepSeeing (cm 250) (mps 5) sightShort [10, 11, 20] ]

/-- `branch_5` (violated): A stop-sign approach recorded from well upstream: the car never halts, and at the first observation that shows it in the junction its footprint has wholly left the approach lane, so it no longer overlaps the carrier it came through, which it did occupy at the observation before. -/
def branch_5Trace : Trace :=
  traceOf crosswalkScene [stopSignFor [12]]
    [ step (m (-25)) (mps 7) [10, 12]
    , step (m (-18)) (mps 7) [10, 12]
    , step (m (-11)) (mps 7) [10, 12, 13]
    , step (m (-4)) (mps 7) [10, 12]
    , step (m 3) (mps 7) [10, 11, 20]
    , step (m 10) (mps 7) [10, 11, 20] ]

/-- `branch_6` (violated): The car halts at the stop line that marks its lane's entrance, enters the junction for a single observation, backs just outside it, halts again well past the line and inside the line's stopping zone, and then enters the junction a second time without halting at the line again. The first entry is discharged by the halt at the line; the second owes its own, and the search back from it ends at the earlier occupancy of the junction. -/
def branch_6Trace : Trace :=
  traceOf stopLineScene [stopSignFor [12]]
    [ step (m (-25)) (mps 5) [10, 12]
    , step (m (-18)) (mps 5) [10, 12]
    , step (m (-12)) (mps 4) [10, 12]
    , step (cm (-1030)) Q.zero [10, 12]
    , step (m (-4)) (mps 5) [10, 12]
    , step (m (-1)) (mps 4) [10, 11, 12, 20]
    , stepBacking (cm (-350)) (mps 2) [10, 12]
    , step (cm (-350)) Q.zero [10, 12]
    , step (m (-1)) (mps 3) [10, 11, 12, 20] ]

/-- `branch_7` (violated): A stop-sign approach with a crosswalk marking its entrance and no stop line: the car's only complete cessation from movement is made with its footprint already overlapping that crosswalk, and it then enters the junction. Its body is nearer the mark than any tolerance and its reference point lies on the crossing itself, so only the words 'before entering the crosswalk' decide it. -/
def branch_7Trace : Trace :=
  traceOf crosswalkScene [stopSignFor [12]]
    [ step (m (-25)) (mps 5) [10, 12]
    , step (m (-18)) (mps 5) [10, 12]
    , step (cm (-1250)) (mps 3) [10, 12]
    , step (cm (-850)) Q.zero [10, 12, 13]
    , step (cm (-850)) Q.zero [10, 12, 13]
    , step (m (-4)) (mps 4) [10, 12]
    , step (cm 150) (mps 5) [10, 11, 12, 20] ]

/-- `branch_8` (not_applicable): The same stop-sign approach and crosswalk, and the same failure to halt, but the subject is a bicycle - a device moved by human power, which the reading classes as excluded from DEF-NRS-484A-320::vehicle. The aggregate membership is decidedly false, so the duty does not engage. -/
def branch_8Trace : Trace :=
  traceOf crosswalkScene [stopSignFor [12]]
    [ stepBike (m (-25)) (mps 5) [10, 12]
    , stepBike (m (-18)) (mps 5) [10, 12]
    , stepBike (m (-9)) (mps 5) [10, 12, 13]
    , stepBike (m (-3)) (mps 5) [10, 12]
    , stepBike (cm 150) (mps 5) [10, 11, 20]
    , stepBike (m 6) (mps 5) [10, 11, 20] ]

/-- `branch_9` (violated): A stop-sign approach the car begins in its lane and then leaves, running up the south half of the way clear of the lane, before swerving back into the lane at the very observation at which it enters the junction. At the entry it occupies the carrier, and at the observation before it did not: the approach is read through the carrier it occupies at the entry. It never halts, so the duty is violated. -/
def branch_9Trace : Trace :=
  traceOf crosswalkScene [stopSignFor [12]]
    [ step (m (-25)) (mps 5) [10, 12]
    , step (m (-18)) (mps 5) [10, 12]
    , stepOff (m (-11)) (m (-3)) (mps 5) [10, 12, 13]
    , stepOff (m (-4)) (cm (-460)) (mps 5) [10]
    , stepOff (m (-1)) (cm (-250)) (mps 4) [10, 11, 12, 20]
    , step (m 4) (mps 4) [10, 11, 20] ]

/-- `branch_10` (not_applicable): The same approach, crosswalk and failure to halt, but the only device in the scene is a yield sign governing the lane: no stop sign governs the carrier or the junction, so the junction is no stop intersection indicated by a stop sign. -/
def branch_10Trace : Trace := traceOf crosswalkScene [yieldSignFor [12]] rollingThrough

/-- `branch_11` (compliant): A stop-sign approach with a stop line marking its lane's entrance and no crosswalk anywhere: the car comes to a complete standstill with its front bumper 0.3 m short of the line, waits, moves off and enters the junction. The second place of the words governs and the halt was made at it. -/
def branch_11Trace : Trace :=
  traceOf stopLineScene [stopSignFor [12]]
    [ step (m (-25)) (mps 5) [10, 12]
    , step (m (-18)) (mps 5) [10, 12]
    , step (m (-12)) (mps 4) [10, 12]
    , step (cm (-1030)) Q.zero [10, 12]
    , step (cm (-1030)) Q.zero [10, 12]
    , step (m (-4)) (mps 5) [10, 12]
    , step (m (-1)) (mps 4) [10, 11, 12, 20] ]

/-- `branch_12` (compliant): The same stop-line approach, but the car overshoots a little and halts with the line 0.7 m behind its reference point, its body still on the line - behind it by less than the stop-point tolerance, which the words 'at a clearly marked stop line' admit. It then enters the junction. -/
def branch_12Trace : Trace :=
  traceOf stopLineScene [stopSignFor [12]]
    [ step (m (-25)) (mps 5) [10, 12]
    , step (m (-18)) (mps 5) [10, 12]
    , step (m (-12)) (mps 4) [10, 12]
    , step (m (-7)) Q.zero [10, 12, 14]
    , step (m (-7)) Q.zero [10, 12, 14]
    , step (m (-1)) (mps 4) [10, 11, 12, 20] ]

/-- `branch_13` (violated): A stop-sign approach with a stop line marking its lane's entrance and no crosswalk anywhere, recorded from well upstream of the line: the car rolls over the line without ever stopping - one observation shows its body on the line itself - and enters the junction. The search back from the entry finds no halt and ends at the start of the approach, the last observation at which the car was off the line, short of it and farther from it than the stop-point tolerance. -/
def branch_13Trace : Trace :=
  traceOf stopLineScene [stopSignFor [12]]
    [ step (m (-25)) (mps 5) [10, 12]
    , step (m (-18)) (mps 5) [10, 12]
    , step (m (-12)) (mps 6) [10, 12]
    , step (cm (-850)) (mps 5) [10, 12, 14]
    , step (m (-3)) (mps 5) [10, 12]
    , step (cm 150) (mps 5) [10, 11, 12, 20] ]

/-- `history_boundary` (unknown): The recording opens with the car already inside the stopping zone upstream of the stop line that marks its lane's entrance on a stop-sign approach - nearer the line than the stop-point tolerance and short of it - still rolling at a steady pace; it never halts in the recording and enters the junction two observations later. Every observation of the trace lies inside the line's stopping zone upstream, so no halt is recorded, no earlier occupancy of the junction is recorded and no start of the approach is visible. -/
def history_boundaryTrace : Trace :=
  traceOf stopLineScene [stopSignFor [12]]
    [ step (cm (-1050)) (mps 5) [10, 12]
    , step (cm (-550)) (mps 5) [10, 12]
    , step (cm (-50)) (mps 5) [10, 11, 12, 20] ]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484A_450_2"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("veh", 1)]
    expected := expected
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["st.entrance_of"]
  , witness "branch_1" branch_1Trace .compliant
  , witness "branch_2" branch_2Trace .violated
  , witness "branch_3" branch_3Trace .violated
  , witness "branch_4" branch_4Trace .violated
  , witness "branch_5" branch_5Trace .violated
  , witness "branch_6" branch_6Trace .violated
  , witness "branch_7" branch_7Trace .violated
  , witness "branch_8" branch_8Trace .notApplicable
  , witness "branch_9" branch_9Trace .violated
  , witness "branch_10" branch_10Trace .notApplicable
  , witness "branch_11" branch_11Trace .compliant
  , witness "branch_12" branch_12Trace .compliant
  , witness "branch_13" branch_13Trace .violated
  , witness "history_boundary" history_boundaryTrace (.unknown []) (boundary := "The approach upstream of the stop line: the observations at which the subject, on the carrier that line marks, was outside the line's stopping zone upstream - off the line, short of it along the carrier's designated direction and farther from it than p.stop_point_tolerance - all of which lie before the recording begins.") ]

end TrafficSpecWitness.NRS_484A_450_2
