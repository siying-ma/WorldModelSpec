/-
  Witnesses for NRS_484B_587_1.

  Geometry (metres, +x east, +y north), the witness's own figures:
    region 10  controlled-access region, x ∈ [-100, 100], y ∈ [-15, 12] (mainline, its verge and ramps)
    region 11  mainline lane, x ∈ [-100, 100], y ∈ [0, 8]
    region 12  entrance ramp lane, x ∈ [-60, -20], y ∈ [-15, 0]
    region 13  exit ramp lane, x ∈ [20, 60], y ∈ [-15, 0]
    region 20  frontage road (roadway), x ∈ [-100, 100], y ∈ [-30, -15]
    device 101 regulatory sign, code entrance, governs region 12
    device 102 regulatory sign, code exit, governs region 13
    device 103 regulatory sign, code keep_right, governs region 11 (branch_3 only, which has no
               entrance or exit sign)
  The subject (track 1) is a motor vehicle, half-extent 2 m × 1 m × 0.75 m, observed at
  t = 0, 1000, 2000 ms. Entry and departure are read as rises, which need the previous
  observation, so every witness speaks about t ∈ [1000, 2000].
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_587_1
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_587_1

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def caRegion : Structure := Build.rect 10 .controlledAccess (m (-100)) (m (-15)) (m 100) (m 12)
def mainline : Structure := Build.rect 11 .lane (m (-100)) (m 0) (m 100) (m 8)
def entranceRamp : Structure := Build.rect 12 .lane (m (-60)) (m (-15)) (m (-20)) (m 0)
def exitRamp : Structure := Build.rect 13 .lane (m 20) (m (-15)) (m 60) (m 0)
def frontage : Structure := Build.rect 20 .roadway (m (-100)) (m (-30)) (m 100) (m (-15))

def structures : List Structure := [caRegion, mainline, entranceRamp, exitRamp, frontage]

def entranceSign : Device :=
  { Build.sign 101 .regulatorySign [12] with code := some .entrance, conditions := some {} }
def exitSign : Device :=
  { Build.sign 102 .regulatorySign [13] with code := some .exit, conditions := some {} }

def signs : List Device := [entranceSign, exitSign]

/-- A regulatory sign of another code (keep right) on the mainline: no notice of entrances or exits. -/
def keepRightSign : Device :=
  { Build.sign 103 .regulatorySign [11] with code := some .keepRight, conditions := some {} }

def car (x y : Int) (h : Vec) : RoadUser :=
  Build.user 1 [.motorVehicle] (m x, m y) h (Units.metresPerSecond 15) (m 2, m 1, cm 75)

/-- A trace of three observations, 1 s apart, the subject at the given positions. -/
def run3 (p : Nat → RoadUser) (devices : List Device) : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [p k] structures devices

/-- `forbid` (violated): Entrance- and exit-coded regulatory signs govern the ramps; the subject car leaves a frontage road, crosses the verge, and its footprint comes to overlap the controlled-access region in a mainline lane no entrance sign governs. -/
def forbidTrace : Trace :=
  run3 (fun k => match k with
    | 0 => car 0 (-20) Build.north
    | 1 => car 0 4 Build.east
    | _ => car 15 4 Build.east) signs

/-- `permit` (compliant): The subject car enters the controlled-access region through a ramp lane governed by an entrance-coded regulatory sign. -/
def permitTrace : Trace :=
  run3 (fun k => match k with
    | 0 => car (-40) (-20) Build.north
    | 1 => car (-40) (-5) Build.north
    | _ => car (-40) 4 Build.north) signs

/-- `idle` (not_applicable): The subject car stays on a surface street; its footprint never overlaps a controlled-access region. -/
def idleTrace : Trace :=
  run3 (fun k => match k with
    | 0 => car (-40) (-20) Build.east
    | 1 => car (-25) (-20) Build.east
    | _ => car (-10) (-20) Build.east) signs

/-- `blind` (unknown): Entrance signs are present and the subject car enters the controlled-access region, but the source does not observe which regions the signs govern. -/
def blindTrace : Trace := permitTrace

/-- `branch_1` (compliant): The subject car leaves the controlled-access region; at the previous observation it occupied an exit lane governed by an exit-coded regulatory sign. -/
def branch_1Trace : Trace :=
  run3 (fun k => match k with
    | 0 => car 40 4 Build.south
    | 1 => car 40 (-5) Build.south
    | _ => car 40 (-20) Build.south) signs

/-- `branch_2` (violated): The subject car leaves the controlled-access region across the shoulder from a mainline lane no exit sign governs. -/
def branch_2Trace : Trace :=
  run3 (fun k => match k with
    | 0 => car (-15) 4 Build.east
    | 1 => car 0 4 Build.east
    | _ => car 0 (-20) Build.south) signs

/-- `branch_3` (not_applicable): No entrance- or exit-coded regulatory sign is present in the scene; the subject car enters the controlled-access region across the verge. -/
def branch_3Trace : Trace :=
  run3 (fun k => match k with
    | 0 => car 0 (-20) Build.north
    | 1 => car 0 4 Build.east
    | _ => car 15 4 Build.east) [keepRightSign]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_587_1"
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
  , witness "blind" blindTrace (.unknown []) ["dev.governs"]
  , witness "branch_1" branch_1Trace .compliant
  , witness "branch_2" branch_2Trace .violated
  , witness "branch_3" branch_3Trace .notApplicable ]

end TrafficSpecWitness.NRS_484B_587_1
