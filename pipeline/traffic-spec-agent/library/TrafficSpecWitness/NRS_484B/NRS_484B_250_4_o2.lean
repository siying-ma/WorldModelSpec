/-
  Witnesses for NRS_484B_250_4_o2.

  The map (world frame, +x east, +y north; every figure below is this file's own).

    region 10  the junction, an intersection, the square from (−7, −7) to (7, 7) m;
    region 11  the north leg's southbound lane, x ∈ [0.4, 4.0], y ∈ [7, 60] m, direction south,
               recorded as entering region 10 — the subject's approach;
    region 12  its stop line, x ∈ [0.4, 4.0], y ∈ [7.6, 8.0] m, recorded as marking region 11's
               entrance (present in every witness but `branch_7` and `branch_8`);
    region 13  a marked crosswalk across the same lane, y ∈ [7.2, 10.2] m, recorded as marking
               region 11's entrance (`branch_7` only, where no stop line marks the approach);
    region 14  the through highway, the east–west way, x ∈ [−60, 60], y ∈ [−7, 7] m;
    region 21  the west leg's eastbound lane, x ∈ [−60, −7], y ∈ [−4.0, −0.4] m, direction east,
               recorded as entering region 10 — the other vehicle's approach;
    region 22  its stop line, x ∈ [−8.0, −7.6] m, recorded as marking region 21's entrance;
    device 31  the signal head governing region 10: installed, uncovered and inoperative in every
               witness but `idle`, where it works and shows a steady circular green.

  The bodies are passenger cars, 4.8 m by 1.8 m (half-extents 2.4 m and 0.9 m). Track 1 is the
  subject, southbound at x = 2.2 m; track 2, where a witness has one, is eastbound at y = −2.2 m.
  Observations are one second apart, from t = 0.

  The subject halts with its front edge on its stop line: centre y = 10.4 m, so the footprint
  touches region 12 (distance 0 m, well inside p.stop_point_tolerance = 1.5 m) and the line lies
  2.4 m ahead of the reference point along the lane's direction. It is 1.0 m short of the junction,
  which `branch_8` uses as the third place of the first sentence, with a view of 150 m along region
  14 (every other witness records 60 m there, under p.intersection_view_sight_distance = 120 m).
  Before the crosswalk of `branch_7` the halt is at centre y = 12.6 m.

  Occupancy is the one the scenes record (`Build.scene`): a body occupies the regions whose polygon
  holds its reference point. The entry into the junction is therefore the observation at which the
  subject's reference point first lies in region 10, two observations after it moves off; the duty
  is decided there, and the rule is engaged at no other observation of these traces.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_250_4_o2
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_250_4_o2

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n
def mps (n : Int) : Q := Units.metresPerSecond n

-- Binders ↦ tracks: subject ↦ 1

def junction : RegionId := 10
def northLane : RegionId := 11
def northStopLine : RegionId := 12
def northCrosswalk : RegionId := 13
def throughHighway : RegionId := 14
def westLane : RegionId := 21
def westStopLine : RegionId := 22
def signalHead : DeviceId := 31

/-- The four corners of an axis-aligned rectangle, as `Build.rect` writes them. -/
def pts (x0 y0 x1 y1 : Q) : List Vec := [(x0, y0), (x1, y0), (x1, y1), (x0, y1)]

def junctionRegion : Structure := Build.rect junction .intersection (m (-7)) (m (-7)) (m 7) (m 7)

def northApproach : Structure :=
  Build.lane northLane (pts (cm 40) (m 7) (m 4) (m 60)) Build.south (enters := some junction)

def westApproach : Structure :=
  Build.lane westLane (pts (m (-60)) (m (-4)) (m (-7)) (cm (-40))) Build.east (enters := some junction)

def northStop : Structure :=
  { Build.rect northStopLine .stopLine (cm 40) (cm 760) (m 4) (m 8) with
      entranceOf := [northLane], entranceObserved := true }

def westStop : Structure :=
  { Build.rect westStopLine .stopLine (m (-8)) (m (-4)) (cm (-760)) (cm (-40)) with
      entranceOf := [westLane], entranceObserved := true }

def northCross : Structure :=
  { Build.rect northCrosswalk .crosswalk (cm 40) (cm 720) (m 4) (cm 1020) with
      entranceOf := [northLane], entranceObserved := true, marked := some true }

def highwayRegion : Structure := Build.rect throughHighway .highway (m (-60)) (m (-7)) (m 60) (m 7)

/-- The map every witness shares, with the stop line marking the subject's approach. -/
def mapWithStopLine : List Structure :=
  [junctionRegion, northApproach, northStop, westApproach, westStop, highwayRegion]

/-- The same map with a crosswalk, and no stop line, marking the subject's approach. -/
def mapWithCrosswalk : List Structure :=
  [junctionRegion, northApproach, northCross, westApproach, westStop, highwayRegion]

/-- The same map with no mark at all for the subject's approach. -/
def mapWithoutMark : List Structure :=
  [junctionRegion, northApproach, westApproach, westStop, highwayRegion]

/-- The signal head of the subsection: installed, uncovered, showing nothing. -/
def deadSignal : Device :=
  { Build.signal signalHead [junction] [.dark] with
      uncovered := some true, inoperative := some true }

/-- A working signal head showing a steady circular green. -/
def liveSignal : Device :=
  { Build.signal signalHead [junction] [.circularGreen] with
      uncovered := some true, inoperative := some false }

def carExtent : Q × Q × Q := (cm 240, cm 90, cm 75)

/-- The subject on its approach, at `y`, with the view it has along the through highway. -/
def subjectAt (y speed sight : Q) : RoadUser :=
  { Build.user 1 [.motorVehicle] (cm 220, y) Build.south speed carExtent with
      sightAlongWay := some [(throughHighway, sight)] }

/-- The other vehicle, eastbound at y = −2.2 m. -/
def otherAt (x speed : Q) : RoadUser :=
  Build.user 2 [.motorVehicle] (x, cm (-220)) Build.east speed carExtent

def sceneOf (t : Timestamp) (us : List RoadUser) (sts : List Structure) (dvs : List Device) : Scene :=
  Build.scene t (some 1) us sts dvs

/-- The view along the through highway in every witness but `branch_8`: short of the sight
    distance the third place of the first sentence asks for. -/
def shortView : Q := m 60
/-- A view that reaches past p.intersection_view_sight_distance. -/
def longView : Q := m 150

/-- `forbid` (violated): At the junction whose signal head is installed, uncovered and inoperative, the subject halts at its stop line, then accelerates to 9 m/s into the junction while another car is already within the junction region crossing from the west; under the velocities observed the two centres approach within 0.65 s and the centre distance at that closest approach is 3.99 m, under the minimum clearance. -/
def forbidTrace : Trace :=
  Build.trace 4 0 (Units.seconds 1) fun k t =>
    let (sy, sv) : Q × Q := match k with
      | 0 => (cm 1040, Q.zero)
      | 1 => (cm 1040, Q.zero)
      | 2 => (cm 140, mps 9)
      | _ => (cm (-760), mps 9)
    let ox : Q := match k with
      | 0 => m (-17)
      | 1 => m (-11)
      | 2 => m (-5)
      | _ => m 1
    sceneOf t [subjectAt sy sv shortView, otherAt ox (mps 6)] mapWithStopLine [deadSignal]

/-- `permit` (compliant): The same junction and inoperative signal. A car comes up the west approach and halts 5 m short of the junction; one observation later the subject halts at its own stop line, so the car's halt began first; the car then crosses and clears the junction. Only then does the subject move off at 3 m/s and cross, the centres receding rather than approaching. -/
def permitTrace : Trace :=
  Build.trace 7 0 (Units.seconds 1) fun k t =>
    let (sy, sv) : Q × Q := match k with
      | 0 => (cm 1640, mps 3)
      | 1 => (cm 1340, mps 3)
      | 5 => (cm 740, mps 3)
      | 6 => (cm 440, mps 3)
      | _ => (cm 1040, Q.zero)
    let (ox, ov) : Q × Q := match k with
      | 0 => (m (-18), mps 6)
      | 1 => (m (-12), Q.zero)
      | 2 => (m (-12), Q.zero)
      | 3 => (m (-5), mps 7)
      | 4 => (m 2, mps 7)
      | 5 => (cm 1150, mps 7)
      | _ => (cm 1850, mps 7)
    sceneOf t [subjectAt sy sv shortView, otherAt ox ov] mapWithStopLine [deadSignal]

/-- `idle` (not_applicable): The signal head governing the junction works and displays a steady circular green; the subject never halts, and enters and crosses the junction at 11 m/s in front of a car waiting on the west leg. The subsection's trigger fails. -/
def idleTrace : Trace :=
  Build.trace 4 0 (Units.seconds 1) fun k t =>
    let sy : Q := match k with
      | 0 => cm 2440
      | 1 => cm 1340
      | 2 => cm 240
      | _ => cm (-860)
    sceneOf t [subjectAt sy (mps 11) shortView, otherAt (cm (-1040)) Q.zero]
      mapWithStopLine [liveSignal]

/-- `branch_4` (violated): The subject halts at its stop line under the inoperative signal and then crosses at 3 m/s, under the cautious-entry speed, while another car crosses the junction from the west at 3 m/s: the centres approach within 2.8 s to 1.70 m, under the minimum clearance. The yielding duty alone decides it. -/
def branch_4Trace : Trace :=
  Build.trace 4 0 (Units.seconds 1) fun k t =>
    let (sy, sv) : Q × Q := match k with
      | 0 => (cm 1040, Q.zero)
      | 1 => (cm 1040, Q.zero)
      | 2 => (cm 740, mps 3)
      | _ => (cm 440, mps 3)
    let ox : Q := match k with
      | 0 => m (-11)
      | 1 => m (-8)
      | 2 => m (-5)
      | _ => m (-2)
    sceneOf t [subjectAt sy sv shortView, otherAt ox (mps 3)] mapWithStopLine [deadSignal]

/-- `blind` (unknown): The scene of `branch_4` — the subject halts at its stop line under the inoperative signal and then moves off at 3 m/s while another car is in the junction — but the source does not observe region occupancy: rel.occupies is absent, so whether the subject entered the junction at all, and whether any road user is within it, is unknown. The halt at the recorded stop line is still decided, since the body-to-mark distance and the offset along the lane's direction are geometry. The witness speaks about the observations from t = 1 s, the recording's first observation being the one at which a search into the past has nothing behind it. -/
def blindTrace : Trace := branch_4Trace

/-- `branch_1` (violated): The subject halts at its stop line one observation after a car on the west leg has halted at its own stop line. The subject then moves off at 7 m/s and crosses in front of that car as it accelerates away at 8 m/s, the predicted closest approach of the centres falling to 3.49 m within 1.18 s: it did not yield to a vehicle that had previously completed a stop, and it did not proceed cautiously either. -/
def branch_1Trace : Trace :=
  Build.trace 5 0 (Units.seconds 1) fun k t =>
    let (sy, sv) : Q × Q := match k with
      | 0 => (cm 1640, mps 3)
      | 1 => (cm 1340, mps 3)
      | 2 => (cm 1040, Q.zero)
      | 3 => (cm 340, mps 7)
      | _ => (cm (-360), mps 7)
    let (ox, ov) : Q × Q := match k with
      | 0 => (m (-16), mps 6)
      | 1 => (cm (-1040), Q.zero)
      | 2 => (cm (-1040), Q.zero)
      | 3 => (cm (-950), mps 8)
      | _ => (cm (-150), mps 8)
    sceneOf t [subjectAt sy sv shortView, otherAt ox ov] mapWithStopLine [deadSignal]

/-- `branch_2` (compliant): The subject is the only road user in the scene: under the inoperative signal it halts at its stop line and then crosses the empty junction at 3 m/s, below the cautious-entry speed. The duty is decided for the subject alone. -/
def branch_2Trace : Trace :=
  Build.trace 4 0 (Units.seconds 1) fun k t =>
    let (sy, sv) : Q × Q := match k with
      | 0 => (cm 1340, mps 3)
      | 1 => (cm 1040, Q.zero)
      | 2 => (cm 740, mps 3)
      | _ => (cm 440, mps 3)
    sceneOf t [subjectAt sy sv shortView] mapWithStopLine [deadSignal]

/-- `branch_3` (violated): The subject halts at its stop line and then crosses the empty junction at 14 m/s, far above the cautious-entry speed, though no other road user is present: it did not proceed cautiously. -/
def branch_3Trace : Trace :=
  Build.trace 4 0 (Units.seconds 1) fun k t =>
    let (sy, sv) : Q × Q := match k with
      | 0 => (cm 1340, mps 3)
      | 1 => (cm 1040, Q.zero)
      | 2 => (cm (-360), mps 14)
      | _ => (cm (-1760), mps 14)
    sceneOf t [subjectAt sy sv shortView] mapWithStopLine [deadSignal]

/-- `branch_5` (violated): A car comes up the west approach at 6 m/s and halts 10 m short of the
    junction; one observation later the subject halts at its own stop line, so that car's halt
    began first. The subject then crosses at 3 m/s, under the cautious-entry speed, while the car
    accelerates away at 8 m/s and is still 2 m short of the junction: the centres approach within
    1.50 s to 2.25 m, under the minimum clearance. The subject keeps the cautious-entry speed and
    the other car is in no part of the junction, so the precedence of a vehicle that had
    previously completed a stop is what decides the verdict. -/
def branch_5Trace : Trace :=
  Build.trace 5 0 (Units.seconds 1) fun k t =>
    let (sy, sv) : Q × Q := match k with
      | 0 => (cm 1640, mps 3)
      | 1 => (cm 1340, mps 3)
      | 2 => (cm 1040, Q.zero)
      | 3 => (cm 740, mps 3)
      | _ => (cm 440, mps 3)
    let (ox, ov) : Q × Q := match k with
      | 0 => (m (-23), mps 6)
      | 1 => (m (-17), Q.zero)
      | 2 => (m (-17), Q.zero)
      | 3 => (m (-16), mps 8)
      | _ => (m (-9), mps 8)
    sceneOf t [subjectAt sy sv shortView, otherAt ox ov] mapWithStopLine [deadSignal]

/-- `branch_9` (compliant): `branch_5` with the other car's halt one observation later than the
    subject's: the car comes up the west approach at 6 m/s, the subject halts at its stop line,
    and only then does the car halt, 4 m short of the junction. The subject crosses at 3 m/s and
    the centres do approach to 2.25 m within the horizon as the car moves off again, but that car
    neither occupies the junction nor completed its stop before the subject's, so the subsection
    gives it no precedence and the entry is compliant. -/
def branch_9Trace : Trace :=
  Build.trace 5 0 (Units.seconds 1) fun k t =>
    let (sy, sv) : Q × Q := match k with
      | 0 => (cm 1640, mps 3)
      | 1 => (cm 1340, mps 3)
      | 2 => (cm 1040, Q.zero)
      | 3 => (cm 740, mps 3)
      | _ => (cm 440, mps 3)
    let (ox, ov) : Q × Q := match k with
      | 0 => (m (-29), mps 6)
      | 1 => (m (-23), mps 6)
      | 2 => (m (-17), mps 6)
      | 3 => (m (-11), Q.zero)
      | _ => (m (-9), mps 8)
    sceneOf t [subjectAt sy sv shortView, otherAt ox ov] mapWithStopLine [deadSignal]

/-- `branch_6` (compliant): The subject halts at its stop line and crosses at 3 m/s while a car that is within the junction leaves it eastward ahead of the subject at 4 m/s. The centres do approach within the horizon — at 0.54 s — but the centre distance there is 9.96 m, above the minimum clearance, so the yielding duty is kept. -/
def branch_6Trace : Trace :=
  Build.trace 4 0 (Units.seconds 1) fun k t =>
    let (sy, sv) : Q × Q := match k with
      | 0 => (cm 1340, mps 3)
      | 1 => (cm 1040, Q.zero)
      | 2 => (cm 740, mps 3)
      | _ => (cm 440, mps 3)
    let ox : Q := match k with
      | 0 => m (-2)
      | 1 => m 2
      | 2 => m 6
      | _ => m 10
    sceneOf t [subjectAt sy sv shortView, otherAt ox (mps 4)] mapWithStopLine [deadSignal]

/-- `branch_7` (compliant): No stop line marks the subject's approach; a marked crosswalk on its near side does. The subject halts before the crosswalk, then crosses the empty junction at 3 m/s: the second place of the first sentence is the one that carries the halt. -/
def branch_7Trace : Trace :=
  Build.trace 5 0 (Units.seconds 1) fun k t =>
    let (sy, sv) : Q × Q := match k with
      | 0 => (cm 1560, mps 3)
      | 1 => (cm 1260, Q.zero)
      | 2 => (cm 960, mps 3)
      | 3 => (cm 660, mps 3)
      | _ => (cm 360, mps 3)
    sceneOf t [subjectAt sy sv shortView] mapWithCrosswalk [deadSignal]

/-- `branch_8` (compliant): Neither a stop line nor a crosswalk marks the subject's approach. The subject halts 1.0 m short of the junction, where its view along the through highway reaches 150 m, and then crosses the empty junction at 3 m/s: the third place of the first sentence is the one that carries the halt. -/
def branch_8Trace : Trace :=
  Build.trace 4 0 (Units.seconds 1) fun k t =>
    let (sy, sv) : Q × Q := match k with
      | 0 => (cm 1340, mps 3)
      | 1 => (cm 1040, Q.zero)
      | 2 => (cm 740, mps 3)
      | _ => (cm 440, mps 3)
    sceneOf t [subjectAt sy sv longView] mapWithoutMark [deadSignal]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "")
    (window : Option (Timestamp × Timestamp) := none) : Scenario :=
  { name := name
    rule := "NRS_484B_250_4_o2"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("subject", 1)]
    expected := expected
    window := window
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["rel.occupies"] (window := some (1000, 3000))
  , witness "branch_1" branch_1Trace .violated
  , witness "branch_2" branch_2Trace .compliant
  , witness "branch_3" branch_3Trace .violated
  , witness "branch_4" branch_4Trace .violated
  , witness "branch_5" branch_5Trace .violated
  , witness "branch_6" branch_6Trace .compliant
  , witness "branch_7" branch_7Trace .compliant
  , witness "branch_8" branch_8Trace .compliant
  , witness "branch_9" branch_9Trace .compliant ]

end TrafficSpecWitness.NRS_484B_250_4_o2
