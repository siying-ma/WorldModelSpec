/-
  Witnesses for NRS_484A_450_2.

  The map (metres, +x east, +y north; every figure here is the witness's own and appears nowhere in
  the rule):

  - the intersecting way (region 1, a highway) runs east-west, the strip x in [-100, 100],
    y in [-6, 6]; the junction (region 3, kind intersection) is the square [-6, 6] x [-6, 6].
  - the subject's approach is the northbound lane 11 (x in [0, 6], y in [-100, -6]), direction
    north, whose entrance end the source records as the junction (region 3). The subject is track
    1, a motor vehicle 4 m long and 2 m wide (half-extents 2 m, 1 m, 0.75 m), driving up the lane
    centre x = 3, so its footprint is the rectangle x in [2, 4], y in [p - 2, p + 2].
  - the marked crosswalk 21 at the lane's entrance is the band y in [-11, -8] across the lane; the
    stop line 22 at the lane's entrance is the band y in [-11, -10.5]. Where a scenario needs the
    mark not to govern this carrier, the same region id is placed on the west leg instead
    (x in [-11, -8] or [-11, -10.5], y in [0, 6]) with its entrances observed and an empty list, so
    the association is decided false rather than unobserved.
  - the stop sign (device 1) governs lane 11, or the junction, or nothing, as the scenario says.
  - region 4 (branch_6 only) is a second junction 50 m east, the one that scenario's source records
    as lane 11's entrance end.

  Distances the scenarios turn on, with the reading's stop-point tolerance of 1.5 m: a body at
  p = -14 stands 1 m short of the band at y = -11 (inside the mark's stopping zone, a halt there
  counts); at p = -16 it stands 3 m short of it and at p = -21 or beyond 8 m or more (outside the
  zone upstream, the start of the approach); at p = -10 its footprint overlaps the band; at p = -5
  its footprint overlaps the junction while still overlapping the lane's entrance end — the entry
  the duty is judged at. The view along the intersecting highway is 60 m where the scenarios want it
  shorter than the reading's 120 m and 150 m where they want it longer.

  Occupancy is declared scene by scene, as the footprint covers the regions. Instants are 1 s
  apart; each witness names the instants it speaks about (`window`), the rule searching into the
  past from the entry.
-/
import TrafficSpec.Rules.NRS_484A.NRS_484A_450_2
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484A_450_2

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n
def mps (n : Int) : Q := Units.metresPerSecond n

-- Binders ↦ tracks: subject ↦ 1

-- ---------------------------------------------------------------------------------------------
-- The map
-- ---------------------------------------------------------------------------------------------
def highwayRegion : Structure := Build.rect 1 .highway (m (-100)) (m (-6)) (m 100) (m 6)

def junction : Structure := Build.rect 3 .intersection (m (-6)) (m (-6)) (m 6) (m 6)

/-- A second junction, 50 m east: only `branch_6` maps it. -/
def farJunction : Structure := Build.rect 4 .intersection (m 50) (m (-6)) (m 62) (m 6)

def laneBoundary : List Vec :=
  [(m 0, m (-100)), (m 6, m (-100)), (m 6, m (-6)), (m 0, m (-6))]

/-- The subject's approach: its entrance end is the junction. -/
def approachLane : Structure := Build.lane 11 laneBoundary Build.north (enters := some 3)

/-- The same lane, recorded as the approach to the far junction instead (`branch_6`). -/
def approachLaneToFar : Structure := Build.lane 11 laneBoundary Build.north (enters := some 4)

/-- The marked crossing at this lane's entrance; the source observes the crosswalks' entrances. -/
def crossingAtEntrance : Structure :=
  { Build.rect 21 .crosswalk (m 0) (m (-11)) (m 6) (m (-8)) with
      marked := some true, entranceOf := [11], entranceObserved := true }

/-- A marked crossing on another leg, whose entrances are observed and mark no carrier here. -/
def crossingElsewhere : Structure :=
  { Build.rect 21 .crosswalk (m (-11)) (m 0) (m (-8)) (m 6) with
      marked := some true, entranceOf := [], entranceObserved := true }

/-- The stop line at this lane's entrance. -/
def lineAtEntrance : Structure :=
  { Build.rect 22 .stopLine (m 0) (m (-11)) (m 6) (cm (-1050)) with
      entranceOf := [11], entranceObserved := true }

/-- A stop line on another leg, whose entrances are observed and mark no carrier here. -/
def lineElsewhere : Structure :=
  { Build.rect 22 .stopLine (m (-11)) (m 0) (cm (-1050)) (m 6) with
      entranceOf := [], entranceObserved := true }

/-- A crossing marks this carrier's entrance: place (1) of the cascade governs. -/
def crossingLayout : List Structure := [highwayRegion, junction, approachLane, crossingAtEntrance]

/-- No crossing marks it, a stop line does: place (2) governs. -/
def lineLayout : List Structure :=
  [highwayRegion, junction, approachLane, crossingElsewhere, lineAtEntrance]

/-- Neither kind of mark marks it, both lists observed: place (3) governs. -/
def viewLayout : List Structure :=
  [highwayRegion, junction, approachLane, crossingElsewhere, lineElsewhere]

/-- The crossing layout, but the source records the lane as the far junction's approach. -/
def farEntranceLayout : List Structure :=
  [highwayRegion, junction, farJunction, approachLaneToFar, crossingAtEntrance]

def stopSignAtLane : List Device := [Build.sign 1 .stopSign [11]]
def stopSignAtJunction : List Device := [Build.sign 1 .stopSign [3]]
/-- A stop sign the source records as governing no region of this scene. -/
def stopSignElsewhere : List Device := [Build.sign 1 .stopSign []]

-- ---------------------------------------------------------------------------------------------
-- Scenes and traces: a step is a position along the lane centre, a speed, the regions the
-- footprint covers, the view along the intersecting highway where the source reports it, and
-- whether the body is moving rearward (the velocity then points south of its heading).
-- ---------------------------------------------------------------------------------------------
def sceneOf (classes : List RoadUserClass) (structures : List Structure) (devices : List Device)
    (t : Timestamp) (step : Q × Q × List RegionId × Option Q × Bool) : Scene :=
  let (y, speed, occ, sight, backing) := step
  let body := Build.user 1 classes (m 3, y) Build.north speed (m 2, m 1, cm 75)
  let seen := { body with sightAlongWay := sight.map fun d => [(1, d)] }
  let u := if backing then Build.withKin seen (fun k => { k with velocity := some (Build.scale Build.south speed) })
           else seen
  Build.scene t (some 1) [u] structures devices (some (occ.map fun r => (1, r)))

def traceOf (classes : List RoadUserClass) (structures : List Structure) (devices : List Device)
    (steps : List (Q × Q × List RegionId × Option Q × Bool)) : Trace :=
  Build.trace steps.length 0 (Units.seconds 1) fun k t =>
    sceneOf classes structures devices t (steps[k]?.getD (Q.zero, Q.zero, [], none, false))

def vehicle : List RoadUserClass := [.motorVehicle]

/-- `forbid` (violated): The subject is a motor vehicle on a lane whose entrance end the source records as the junction ahead; a stop sign governs that lane, and a marked crosswalk is recorded as marking that lane's entrance (the source observes the crosswalk's entrances, and this lane is on its list). The recording begins with the subject well upstream of the crossing — off it, with the crossing ahead along the lane's direction and farther from it than the stop-point tolerance — and it rolls on at a steady speed well above the halt tolerance, its speed never falling to that tolerance. It crosses the crossing and at the next observation its footprint overlaps the junction while still overlapping the entrance end of the lane. No other road user is in the scene, and the duty is still decided: the search back from that entry reaches the start of the approach without a halt. -/
def rollOnSteps : List (Q × Q × List RegionId × Option Q × Bool) :=
  [ (m (-30), mps 5, [11], none, false)
  , (m (-25), mps 5, [11], none, false)
  , (m (-20), mps 5, [11], none, false)
  , (m (-15), mps 5, [11], none, false)
  , (m (-10), mps 5, [11, 21], none, false)
  , (m (-5), mps 5, [11, 3, 1], none, false) ]

def forbidTrace : Trace := traceOf vehicle crossingLayout stopSignAtLane rollOnSteps

/-- `permit` (compliant): The same lane, stop sign and marked crosswalk. The subject approaches from outside the crossing's stopping zone, comes to a complete halt with its body short of the crossing, the crossing ahead along the lane's direction and within the stop-point tolerance of it, stands still for two observations, then moves off; at the next observation its footprint overlaps the junction while still overlapping the entrance end of the lane. No other road user is present in the scene, and the duty is still decided. -/
def haltAtCrossingSteps : List (Q × Q × List RegionId × Option Q × Bool) :=
  [ (m (-26), mps 5, [11], none, false)
  , (m (-21), mps 5, [11], none, false)
  , (m (-16), mps 5, [11], none, false)
  , (m (-14), Q.zero, [11], none, false)
  , (m (-14), Q.zero, [11], none, false)
  , (m (-10), mps 4, [11, 21], none, false)
  , (m (-5), mps 5, [11, 3, 1], none, false) ]

def permitTrace : Trace := traceOf vehicle crossingLayout stopSignAtLane haltAtCrossingSteps

/-- `idle` (not_applicable): The subject is a pedal bicycle, a device moved by human power, which DEF-NRS-484A-320 leaves out of the vehicle aggregate; it rides along the same lane past the same stop sign, over the same crossing and into the junction without ever halting. -/
def idleTrace : Trace := traceOf [.bicycle] crossingLayout stopSignAtLane rollOnSteps

/-- `blind` (unknown): The layout, the stop sign, the marked crosswalk marking this lane's entrance
    and the entry into the junction are the forbid scenario's, and the source maps its regions
    without their outlines: st.region_geometry is absent, so the distance from the subject's body to
    the crossing is unknown at every observation, and with it whether any halt lay at the place and
    whether the subject was ever outside the crossing's stopping zone.

    The trace adds to the narrative what the search needs in order to be unknown for the masked
    atom alone rather than for the unobserved past as well: it opens with the subject already
    overlapping the junction (the stay a previous entry began, which the trace shows at two
    observations), it then backs out over the crossing, halts short of it — the halt whose place the
    missing outlines leave unknown — and pulls forward into the junction again. The search back from
    that second entry therefore ends at the previous stay and not at the first observation of the
    recording; what it cannot tell is whether the halt it finds lay at the crossing. The instants
    the witness speaks about begin at the second observation, the first being the one at which the
    source cannot yet tell the opening stay from an entry. -/
def blindSteps : List (Q × Q × List RegionId × Option Q × Bool) :=
  [ (m (-5), mps 2, [11, 3, 1], none, true)
  , (m (-7), mps 2, [11, 21, 3, 1], none, true)
  , (m (-9), mps 2, [11, 21], none, true)
  , (m (-11), mps 2, [11, 21], none, true)
  , (m (-14), Q.zero, [11], none, false)
  , (m (-14), Q.zero, [11], none, false)
  , (m (-10), mps 4, [11, 21], none, false)
  , (m (-5), mps 5, [11, 3, 1], none, false) ]

def blindTrace : Trace := traceOf vehicle crossingLayout stopSignAtLane blindSteps

/-- `history_boundary` (unknown): The same lane, stop sign and marked crosswalk, but the recording begins with the subject already inside the crossing's stopping zone upstream — off the crossing, with it ahead along the lane's direction and within the stop-point tolerance of it. It rolls forward at a crawl, its speed always above the halt tolerance and never falling to it, crosses the crossing and enters the junction, its footprint still overlapping the entrance end of the lane at that observation. No observation shows it outside the zone before the entry, there is no earlier entry of the subject into this junction, and no recorded halt decides the verdict. -/
def history_boundarySteps : List (Q × Q × List RegionId × Option Q × Bool) :=
  [ (cm (-1350), mps 2, [11], none, false)
  , (cm (-1150), mps 2, [11, 21], none, false)
  , (cm (-950), mps 2, [11, 21], none, false)
  , (cm (-750), mps 2, [11, 21, 3, 1], none, false) ]

def history_boundaryTrace : Trace :=
  traceOf vehicle crossingLayout stopSignAtLane history_boundarySteps

/-- `branch_1` (compliant): The same lane and stop sign, but no crosswalk marks this lane's entrance: the source observes the crosswalks' entrances and none of their lists holds this lane. A stop line is recorded as marking the lane's entrance. The subject approaches from outside that line's stopping zone, halts with its body short of the line, the line ahead along the lane's direction and within the stop-point tolerance of it, then moves off and enters the junction, its footprint still overlapping the entrance end of the lane at that observation. -/
def branch_1Steps : List (Q × Q × List RegionId × Option Q × Bool) :=
  [ (m (-26), mps 5, [11], none, false)
  , (m (-21), mps 5, [11], none, false)
  , (m (-16), mps 5, [11], none, false)
  , (m (-14), Q.zero, [11], none, false)
  , (m (-14), Q.zero, [11], none, false)
  , (m (-10), mps 4, [11, 22], none, false)
  , (m (-5), mps 5, [11, 3, 1], none, false) ]

def branch_1Trace : Trace := traceOf vehicle lineLayout stopSignAtLane branch_1Steps

/-- `branch_2` (compliant): The same lane and stop sign, and neither a crosswalk nor a stop line marks this lane's entrance: both kinds of mark have their entrances observed and neither lists this lane. Well upstream the view along the intersecting highway is shorter than the intersection view sight distance; the subject rolls forward to an observation, its footprint still off the junction, at which the view along that highway reaches the intersection view sight distance, and there comes to a complete halt for two observations before moving off and entering the junction. -/
def branch_2Steps : List (Q × Q × List RegionId × Option Q × Bool) :=
  [ (m (-26), mps 5, [11], some (m 60), false)
  , (m (-21), mps 5, [11], some (m 60), false)
  , (m (-16), mps 5, [11], some (m 60), false)
  , (m (-14), Q.zero, [11], some (m 150), false)
  , (m (-14), Q.zero, [11], some (m 150), false)
  , (m (-10), mps 4, [11], some (m 150), false)
  , (m (-5), mps 5, [11, 3, 1], some (m 150), false) ]

def branch_2Trace : Trace := traceOf vehicle viewLayout stopSignAtLane branch_2Steps

/-- `branch_3` (violated): The layout of branch_2 — the same lane and stop sign, no crosswalk and no stop line marking this lane's entrance, both lists observed. The subject halts completely only well upstream, where the view along the intersecting highway is shorter than the intersection view sight distance, and then rolls on without halting again, its speed never falling to the halt tolerance, until its footprint overlaps the junction. -/
def branch_3Steps : List (Q × Q × List RegionId × Option Q × Bool) :=
  [ (m (-26), Q.zero, [11], some (m 60), false)
  , (m (-21), mps 5, [11], some (m 60), false)
  , (m (-16), mps 5, [11], some (m 60), false)
  , (m (-14), mps 5, [11], some (m 150), false)
  , (m (-10), mps 5, [11], some (m 150), false)
  , (m (-5), mps 5, [11, 3, 1], some (m 150), false) ]

def branch_3Trace : Trace := traceOf vehicle viewLayout stopSignAtLane branch_3Steps

/-- `branch_4` (violated): The forbid scenario's lane, crossing and approach, but the source records
    the stop sign as governing the junction itself rather than the lane: the duty arises through the
    second limb of the trigger, and the subject reaches the junction without halting. -/
def branch_4Trace : Trace := traceOf vehicle crossingLayout stopSignAtJunction rollOnSteps

/-- `branch_5` (not_applicable): The same lane, crossing and approach, but the source records the
    stop sign as governing neither this lane nor the junction (it faces the cross street), so no
    stop sign indicates this approach and the duty does not arise however the subject drives. -/
def branch_5Trace : Trace := traceOf vehicle crossingLayout stopSignElsewhere rollOnSteps

/-- `branch_6` (compliant): The same lane, crossing and stop sign, but the source records this
    lane's entrance end as a second junction 50 m east, not the junction the subject drives into:
    the junction it enters is no junction this carrier approaches, so no halt is owed before that
    entry, and the duty for the far junction never arises. -/
def branch_6Trace : Trace := traceOf vehicle farEntranceLayout stopSignAtLane rollOnSteps

def witness (name : String) (τ : Trace) (expected : Verdict) (lastMs : Timestamp)
    (firstMs : Timestamp := 0) (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484A_450_2"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("subject", 1)]
    expected := expected
    window := some (firstMs, lastMs)
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated 5000
  , witness "permit" permitTrace .compliant 6000
  , witness "idle" idleTrace .notApplicable 5000
  , witness "blind" blindTrace (.unknown []) 7000 (firstMs := 1000) (absent := ["st.region_geometry"])
  , witness "history_boundary" history_boundaryTrace (.unknown []) 3000
      (boundary := "the approach upstream of the crosswalk that marks this carrier's entrance: the trace holds no observation at which the subject lay outside that crossing's stopping zone before the entry, and no earlier entry of the subject into this intersection.")
  , witness "branch_1" branch_1Trace .compliant 6000
  , witness "branch_2" branch_2Trace .compliant 6000
  , witness "branch_3" branch_3Trace .violated 5000
  , witness "branch_4" branch_4Trace .violated 5000
  , witness "branch_5" branch_5Trace .notApplicable 5000
  , witness "branch_6" branch_6Trace .compliant 5000 ]

end TrafficSpecWitness.NRS_484A_450_2
