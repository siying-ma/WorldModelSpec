/-
  Witnesses for NRS_484B_307_4b.

  Geometry (the witness's own figures, nowhere in the rule): an east–west roadway (region 1) from
  y = 0 to y = 14 m; the near sidewalk (region 2) from y = 14 to 18 m, the far sidewalk (region 3)
  from y = −4 to 0 m; a crosswalk (region 4) across the roadway from x = −2 to 2 m.
  The pedestrian (track 1, half-extents 0.25 × 0.25 × 0.9 m) stands at (0, 15) on the near
  sidewalk, heading south. The vehicular head (device 10) stands at (3, −10): 25.2 m away (reach
  60 m), at about 7° from the pedestrian's heading (cos ≈ 0.99 against 0.87). The pedestrian head
  (device 11) stands at (2, −2) on the far sidewalk and governs the crosswalk.
  Instants 0, 1, 2 s; the pedestrian is on the sidewalk at 0 and 1 s and, where it steps, at (0, 12)
  on the roadway at 2 s. Each witness speaks about instants 1 s and 2 s (`window`): the previous
  observation the rule reads does not exist at 0 s.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_307_4b
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_307_4b

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def structures : List Structure :=
  [ Build.rect 1 .roadway (m (-50)) (m 0) (m 50) (m 14)
  , Build.rect 2 .sidewalk (m (-50)) (m 14) (m 50) (m 18)
  , Build.rect 3 .sidewalk (m (-50)) (m (-4)) (m 50) (m 0)
  , Build.rect 4 .crosswalk (m (-2)) (m 0) (m 2) (m 14) ]

def vehicularHead (shows : List SignalIndication) (pos : Vec) : Device :=
  { Build.signal 10 [1] shows with position := some pos }

def pedestrianHead (st : PedSignalState) : Device :=
  { Build.device 11 .pedestrianSignal [4] (some (m 2, m (-2))) with pedState := some st }

def headPos : Vec := (m 3, m (-10))

/-- A scene generator: the pedestrian's heading, whether it steps onto the roadway at 2 s (or is on
    it throughout), and the two heads' states. -/
def sceneOf (heading : Vec) (steps : Bool) (onRoadwayThroughout : Bool)
    (shows : List SignalIndication) (pos : Vec) (ped : PedSignalState) : Nat → Timestamp → Scene :=
  fun k t =>
    let p : Vec :=
      if onRoadwayThroughout then (m 0, m 12)
      else if steps && k ≥ 2 then (m 0, m 12) else (m 0, m 15)
    Build.scene t (some 1)
      [ Build.user 1 [.pedestrian] p heading (cm 100) (cm 25, cm 25, cm 90) ]
      structures
      [ vehicularHead shows pos, pedestrianHead ped ]

def arrowLeft : List SignalIndication := [.greenArrow .left]

/-- `forbid` (violated): A pedestrian stands on the sidewalk at a corner, 25 m from a vehicular head it faces (heading within 10 degrees of the line to the head) that displays green_arrow(left) alone; the pedestrian head it faces displays dont_walk_steady. At the next observation its footprint overlaps the roadway. -/
def forbidTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) (sceneOf Build.south true false arrowLeft headPos .dontWalkSteady)

/-- `permit` (compliant): Same scene; the pedestrian stays on the sidewalk while the head displays green_arrow(left) alone; its footprint never overlaps the roadway. -/
def permitTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) (sceneOf Build.south false false arrowLeft headPos .dontWalkSteady)

/-- `idle` (not_applicable): The head the pedestrian faces displays circular_green alone; it steps onto the roadway. -/
def idleTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) (sceneOf Build.south true false [.circularGreen] headPos .dontWalkSteady)

/-- `blind` (unknown): As forbid, but the source supplies no heading for the pedestrian: whether it faces the head is unknown. -/
def blindTrace : Trace :=
  Build.masked (Build.manifest ["kin.heading"]) forbidTrace

/-- `branch_1` (not_applicable): As forbid, but the pedestrian head it faces displays walk: NRS_484B_283_1d1 applies to it and the duty of this paragraph does not. -/
def branch_1Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) (sceneOf Build.south true false arrowLeft headPos .walk)

/-- `branch_2` (not_applicable): the pedestrian is already on the roadway at every instant while it
    faces the green left arrow alone: there is no entry from off the roadway. -/
def branch_2Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) (sceneOf Build.south false true arrowLeft headPos .dontWalkSteady)

/-- `branch_3` (not_applicable): as forbid, but the pedestrian heads north, away from the head. -/
def branch_3Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) (sceneOf Build.north true false arrowLeft headPos .dontWalkSteady)

/-- `branch_4` (not_applicable): as forbid, but the head stands 100 m beyond the pedestrian, out of
    reach (60 m), though straight ahead. -/
def branch_4Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) (sceneOf Build.south true false arrowLeft (m 3, m (-85)) .dontWalkSteady)

/-- `branch_5` (not_applicable): as forbid, but the head displays green_arrow(left) together with
    circular_red: a green turn arrow, not alone. -/
def branch_5Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) (sceneOf Build.south true false [.greenArrow .left, .circularRed] headPos .dontWalkSteady)

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_307_4b"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("subject", 1)]
    expected := expected
    window := some (1000, 2000)
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["kin.heading"]
  , witness "branch_1" branch_1Trace .notApplicable
  , witness "branch_2" branch_2Trace .notApplicable
  , witness "branch_3" branch_3Trace .notApplicable
  , witness "branch_4" branch_4Trace .notApplicable
  , witness "branch_5" branch_5Trace .notApplicable ]

end TrafficSpecWitness.NRS_484B_307_4b
