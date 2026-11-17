/-
  Witnesses for NRS_484B_633_2.

  Geometry (the witness's own figures, nowhere in the rule): an eastbound highway region 10
  spanning x 0…200 m, y −10…10 m; an approach lane 30 (x 0…60, y −5…5) and a bridge lane 31
  (x 60…140, y −5…5), both lying on the highway; an elevated structure 20 (the bridge,
  x 60…140, y −8…8) lying on the highway. Speed limit sign 1 governs lane 31 (or lane 30 in
  branch_1) at 11 m/s. The subject (track 1) stands at x 100 on the bridge, or at x 30 on the
  approach; three instants one second apart, the scene unchanged across them.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_633_2
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_633_2

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def highwayId : RegionId := 10
def bridgeId : RegionId := 20
def approachLaneId : RegionId := 30
def bridgeLaneId : RegionId := 31

def highway : Structure := Build.rect highwayId .highway (m 0) (m (-10)) (m 200) (m 10)

def bridge (ways : List RegionId) : Structure :=
  { Build.rect bridgeId .elevatedStructure (m 60) (m (-8)) (m 140) (m 8) with ways := some ways }

def approachLane : Structure :=
  { Build.lane approachLaneId [(m 0, m (-5)), (m 60, m (-5)), (m 60, m 5), (m 0, m 5)] Build.east
    with ways := some [highwayId] }

def bridgeLane (ways : List RegionId) : Structure :=
  { Build.lane bridgeLaneId [(m 60, m (-5)), (m 140, m (-5)), (m 140, m 5), (m 60, m 5)] Build.east
    with ways := some ways }

def world : List Structure :=
  [highway, bridge [highwayId], approachLane, bridgeLane [highwayId]]

def truckAt (x : Int) (speed : Q) : RoadUser :=
  Build.user 1 [.truck, .motorVehicle] (m x, m 0) Build.east speed (m 6, cm 125, cm 200)

def carAt (x : Int) (speed : Q) : RoadUser :=
  Build.user 1 [.motorVehicle] (m x, m 0) Build.east speed (m 2, cm 90, cm 75)

def structureSign (governs : List RegionId) : Device :=
  Build.speedLimit 1 governs (Units.metresPerSecond 11) .structureMaximum

/-- `forbid` (violated): A truck occupies a bridge lying on a highway; a structure_maximum speed sign of 11 m/s governs the bridge lane it occupies; its speed is 16 m/s. -/
def forbidTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ truckAt 100 (Units.metresPerSecond 16) ]
      world
      [ structureSign [bridgeLaneId] ]

/-- `permit` (compliant): The same truck on the same bridge at 10 m/s. -/
def permitTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ truckAt 100 (Units.metresPerSecond 10) ]
      world
      [ structureSign [bridgeLaneId] ]

/-- `idle` (not_applicable): A car on a bridge lying on a highway whose lanes no structure_maximum speed sign governs (the only sign there is an ordinary maximum-speed sign). -/
def idleTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ carAt 100 (Units.metresPerSecond 16) ]
      world
      [ Build.speedLimit 1 [bridgeLaneId] (Units.metresPerSecond 11) .maximum ]

/-- `blind` (unknown): As in forbid, but the source does not observe which regions the speed limit sign governs, so whether the bridge is signposted is unknown. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ truckAt 100 (Units.metresPerSecond 16) ]
      world
      [ { structureSign [] with governsObserved := false } ]

/-- `branch_1` (not_applicable): A car at 16 m/s on an ordinary roadway lane, off any elevated structure, though a structure_maximum sign governs the lane ahead of the bridge. -/
def branch_1Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ carAt 30 (Units.metresPerSecond 16) ]
      world
      [ structureSign [approachLaneId] ]

/-- `branch_2` (not_applicable): A truck at 16 m/s on a bridge whose structure-maximum sign
    governs the bridge lane, but the bridge lies on no highway (the highway ends at the approach). -/
def branch_2Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ truckAt 100 (Units.metresPerSecond 16) ]
      [ Build.rect highwayId .highway (m 0) (m (-10)) (m 60) (m 10), bridge [], approachLane,
        bridgeLane [] ]
      [ structureSign [bridgeLaneId] ]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_633_2"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("subject", 1)]
    expected := expected
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["dev.governs"]
  , witness "branch_1" branch_1Trace .notApplicable
  , witness "branch_2" branch_2Trace .notApplicable ]

end TrafficSpecWitness.NRS_484B_633_2
