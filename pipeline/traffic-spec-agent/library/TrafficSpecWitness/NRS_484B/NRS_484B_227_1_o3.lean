/-
  Witnesses for NRS_484B_227_1_o3.

  The carriageway. A divided highway runs east–west: the highway region (id 10) spans
  y ∈ [-20, 20], the northern (westbound) roadway (11) y ∈ [4, 12], the southern (eastbound)
  roadway (12) y ∈ [-12, -4], and the dividing section between them y ∈ [-4, 4]. Three scenes of
  that dividing section are used: one continuous barrier (13), and a barrier broken by a paved
  crossover — a western section (13), the crossover itself (14, the `opening` attribute set), and
  an eastern section (15). One scene puts an intersection (16) across the way instead of a
  crossover. The undivided continuation is a street (20) with one roadway (21) and a painted
  centre line (22) and no dividing structure at all.

  The bodies. One motor vehicle, track 1, runs east on the southern roadway at 8 m/s with half
  extents 2 m × 1 m × 1 m. Occupancy is stated in every scene rather than left to the polygons,
  because a body swinging about overlaps more than the region its reference point falls in.

  The instants. Every trace is sampled at 1 s, so the 8 s window behind an observation covers the
  eight intervals before it and the heading change over it is the sum of eight yaw-rate readings.
  A turning is written as a yaw rate of 30 deg/s held for as many seconds as the swing needs: six
  for a half turn, three for a quarter. Each witness names the instants it speaks about from
  8 s onward, the first at which the window behind is covered rather than truncated.

  Every figure here is the witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_227_1_o3
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_227_1_o3

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: v ↦ 1

/-- Half-length, half-width, half-height of the body. -/
def car : Q × Q × Q := (m 2, m 1, m 1)
def cruise : Q := Units.metresPerSecond 8

-- The way, divided: highway, its two roadways, and one continuous dividing section.
def hwy : Structure := Build.rect 10 .highway (m (-200)) (m (-20)) (m 200) (m 20)
def northRoadway : Structure := Build.rect 11 .roadway (m (-200)) (m 4) (m 200) (m 12)
def southRoadway : Structure := Build.rect 12 .roadway (m (-200)) (m (-12)) (m 200) (m (-4))
def wholeMedian : Structure :=
  { Build.rect 13 .medianOrDivider (m (-200)) (m (-4)) (m 200) (m 4) with opening := some false }

-- The same way, its dividing section broken by a paved crossover.
def medianWest : Structure :=
  { Build.rect 13 .medianOrDivider (m (-200)) (m (-4)) (m (-10)) (m 4) with opening := some false }
def crossover : Structure :=
  { Build.rect 14 .medianOrDivider (m (-10)) (m (-4)) (m 10) (m 4) with opening := some true }
def medianEast : Structure :=
  { Build.rect 15 .medianOrDivider (m 10) (m (-4)) (m 200) (m 4) with opening := some false }

-- The same way, crossed by another at an intersection.
def crossing : Structure := Build.rect 16 .intersection (m (-12)) (m (-20)) (m 12) (m 20)

-- The undivided continuation: one roadway, a painted centre line, no dividing structure.
def street : Structure := Build.rect 20 .highway (m (-200)) (m (-10)) (m 200) (m 10)
def streetRoadway : Structure := Build.rect 21 .roadway (m (-200)) (m (-8)) (m 200) (m 8)
def streetCentreLine : Structure :=
  Build.rect 22 .centreLine (m (-200)) (cm (-10)) (m 200) (cm 10)

def dividedWay : List Structure := [hwy, northRoadway, southRoadway, wholeMedian]
def dividedWayWithCrossover : List Structure :=
  [hwy, northRoadway, southRoadway, medianWest, crossover, medianEast]
def dividedWayWithIntersection : List Structure :=
  [hwy, northRoadway, southRoadway, medianWest, medianEast, crossing]
def undividedWay : List Structure := [street, streetRoadway, streetCentreLine]

-- Where the body is: upon the southern roadway, upon the northern one, upon the dividing
-- section, within the crossover, within the intersection, upon the undivided street.
def onSouth : List (TrackId × RegionId) := [(1, 10), (1, 12)]
def onNorth : List (TrackId × RegionId) := [(1, 10), (1, 11)]
def onMedian : List (TrackId × RegionId) := [(1, 10), (1, 13)]
def onMedianEast : List (TrackId × RegionId) := [(1, 10), (1, 12), (1, 15)]
def inCrossover : List (TrackId × RegionId) := [(1, 10), (1, 12), (1, 14)]
def inCrossing : List (TrackId × RegionId) := [(1, 10), (1, 12), (1, 16)]
def onStreet : List (TrackId × RegionId) := [(1, 20), (1, 21)]

/-- The body runs east to the place of the manoeuvre (index `a`), holds about it while it swings
    (to index `b`), and runs west away from it at `yAway`. Position is indicative: the rule reads
    the yaw channel and the occupancy each scene states. -/
def place (k a b : Nat) (yAway : Int) : Vec :=
  if k ≤ a then (m (8 * ((k : Int) - (a : Int))), m (-8))
  else if k ≤ b then (m 4, m (-6))
  else (m (-8 * ((k : Int) - (b : Int))), m yAway)

/-- A yaw rate of `rate` deg/s at the observations `lo … hi`, and a steady heading elsewhere. -/
def yawIf (lo hi : Nat) (rate : Int) (k : Nat) : Q :=
  if lo ≤ k ∧ k ≤ hi then Units.degrees rate else Q.zero

def vehicle (pos : Vec) (hd : Vec) (yaw : Q) : RoadUser :=
  Build.withKin (Build.user 1 [.motorVehicle] pos hd cruise car)
    (fun kn => { kn with yawRate := some yaw })

/-- `forbid` (violated): On a dual carriageway separated by a continuous raised median, a vehicle swings through about a half turn across its own roadway and sets off back the way it came; it is on the divided highway throughout, and no opening and no intersection covers the place at any moment of the turning. -/
def forbidTrace : Trace :=
  Build.trace 20 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ vehicle (place k 10 15 (-6)) (if k ≤ 12 then Build.east else Build.west) (yawIf 10 15 30 k) ]
      dividedWay
      []
      (some onSouth)

/-- `permit` (compliant): A vehicle running along the same divided highway holds its heading past the median, making no swing to the left and no turning about; every atom the rule reads is observed throughout and the window behind each observation lies inside the trace. -/
def permitTrace : Trace :=
  Build.trace 20 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ vehicle (place k 19 19 (-8)) Build.east (Units.degrees (-3)) ]
      dividedWay
      []
      (some onSouth)

/-- `idle` (not_applicable): A vehicle makes a U-turn on an undivided two-lane street with a painted centre line: no barrier or dividing section divides the way into roadways at any moment of the turning, and all atoms are observed. -/
def idleTrace : Trace :=
  Build.trace 20 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ vehicle (place k 10 15 (-4)) (if k ≤ 12 then Build.east else Build.west) (yawIf 10 15 30 k) ]
      undividedWay
      []
      (some onStreet)

/-- `blind` (unknown): A vehicle crosses the median of a divided highway, but the source declares no yaw rate, so neither the heading change over the window nor whether a turning is under way can be formed. -/
def blindTrace : Trace :=
  Build.trace 20 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ vehicle (place k 10 15 4) (if k ≤ 12 then Build.east else Build.west) (yawIf 10 13 30 k) ]
      dividedWay
      []
      (some (if k ≤ 9 then onSouth else if k ≤ 13 then onMedian else onNorth))

/-- `occasion_s2` (violated): The vehicle begins its turning about on the divided highway and carries it through onto the undivided continuation of the way, so the trigger holds for the first part of the turning only; read at some moment while the act is under way, the rule is engaged and the turning is unexcused. -/
def occasion_s2Trace : Trace :=
  Build.trace 20 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ vehicle (place k 10 15 (-6)) (if k ≤ 12 then Build.east else Build.west) (yawIf 10 15 30 k) ]
      (if k ≤ 13 then dividedWay else undividedWay)
      []
      (some (if k ≤ 13 then onSouth else onStreet))

/-- `occasion_s2_outside` (not_applicable): The vehicle runs along the divided highway, passes its end onto an undivided street and only then turns about: the trigger held only before the turning began, so at no moment of the act is the subject upon a divided highway. -/
def occasion_s2_outsideTrace : Trace :=
  Build.trace 20 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ vehicle (place k 12 17 (-4)) (if k ≤ 14 then Build.east else Build.west) (yawIf 12 17 30 k) ]
      (if k ≤ 9 then dividedWay else undividedWay)
      []
      (some (if k ≤ 9 then onSouth else onStreet))

/-- `occasion_s6` (violated): The vehicle starts its turning about within the paved gap in the median but swings out of the gap onto the continuous dividing section partway through, so the exception holds for part of the turning only and does not excuse it. -/
def occasion_s6Trace : Trace :=
  Build.trace 20 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ vehicle (place k 10 15 4) (if k ≤ 12 then Build.east else Build.west) (yawIf 10 15 30 k) ]
      dividedWayWithCrossover
      []
      (some (if k ≤ 9 then onSouth else if k ≤ 12 then inCrossover
             else if k ≤ 15 then onMedianEast else onNorth))

/-- `occasion_s6_outside` (compliant): The vehicle runs along the roadway, enters the paved gap in the median and makes the whole turning about within the gap: the exception did not hold before the turning began and holds at every moment while it is under way. -/
def occasion_s6_outsideTrace : Trace :=
  Build.trace 22 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ vehicle (place k 12 17 4) (if k ≤ 14 then Build.east else Build.west) (yawIf 12 17 30 k) ]
      dividedWayWithCrossover
      []
      (some (if k ≤ 9 then onSouth else if k ≤ 19 then inCrossover else onNorth))

/-- `branch_1` (violated): on the divided highway the vehicle swings through a quarter turn to its
    left, off its roadway and onto the continuous dividing section: a left turn through more than
    the swing the reading sets, and no turning about. -/
def branch_1Trace : Trace :=
  Build.trace 20 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ vehicle (place k 10 12 (-2)) (if k ≤ 11 then Build.east else Build.north) (yawIf 10 12 30 k) ]
      dividedWay
      []
      (some (if k ≤ 12 then onSouth else onMedian))

/-- `branch_2` (violated): the vehicle turns about to its right upon the divided highway, through
    a half turn the other way about: no left turn at all, and a turning about all the same. -/
def branch_2Trace : Trace :=
  Build.trace 20 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ vehicle (place k 10 15 (-10)) (if k ≤ 12 then Build.east else Build.west) (yawIf 10 15 (-30) k) ]
      dividedWay
      []
      (some onSouth)

/-- `branch_3` (compliant): the dividing section is interrupted by an intersection instead of a
    crossover, and the vehicle makes the whole turning about within the intersection. -/
def branch_3Trace : Trace :=
  Build.trace 22 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ vehicle (place k 12 17 4) (if k ≤ 14 then Build.east else Build.west) (yawIf 12 17 30 k) ]
      dividedWayWithIntersection
      []
      (some (if k ≤ 9 then onSouth else if k ≤ 19 then inCrossing else onNorth))

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (win : Option (Timestamp × Timestamp) := some (8000, 19000)) :
    Scenario :=
  { name := name
    rule := "NRS_484B_227_1_o3"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("v", 1)]
    expected := expected
    window := win }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["kin.yaw_rate"]
  , witness "occasion_s2" occasion_s2Trace .violated
  , witness "occasion_s2_outside" occasion_s2_outsideTrace .notApplicable
  , witness "occasion_s6" occasion_s6Trace .violated
  , witness "occasion_s6_outside" occasion_s6_outsideTrace .compliant [] (some (8000, 21000))
  , witness "branch_1" branch_1Trace .violated
  , witness "branch_2" branch_2Trace .violated
  , witness "branch_3" branch_3Trace .compliant [] (some (8000, 21000)) ]

end TrafficSpecWitness.NRS_484B_227_1_o3
