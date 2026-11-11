/-
  Witnesses for NRS_484B_440_1_o2.

  The carriageway: a rural highway (region 10) from x = 0 to 200 m, y = −3 to 11 m; a shoulder
  (13) at y −3…0; the roadway (11) at y 0…8 with two 4 m lanes, lane A (12) eastbound at y 0…4
  and lane B (14) westbound at y 4…8, each measured 4 m wide. Every scene is outside a business or
  residence district (the assumption is declared false), and x's engine runs with hazard lamps off
  unless a witness says otherwise.

  The bodies: x (track 1), a motor vehicle 4.5 m by 1.8 m, stands at (50, 2.5) facing east, so its
  body spans y 1.6…3.4 and lies 0.6 m from lane B. Another vehicle (track 2) of the same size
  stands or drives in lane B at y = 6. Three instants one second apart.

  Every figure here is the witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_440_1_o2
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_440_1_o2

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: x ↦ 1

def outside : List (AsmId × Bool) := [("asm.within_business_or_residence_district", false)]
def inside : List (AsmId × Bool) := [("asm.within_business_or_residence_district", true)]

def body : Q × Q × Q := (cm 225, cm 90, cm 75)

/-- A lane on highway `way`, from `y0` to `y1`, with its measured width. -/
def laneOn (id : RegionId) (way : RegionId) (y0 y1 : Q) (dir : Vec) (width : Q) : Structure :=
  { Build.rect id .lane (m 0) y0 (m 200) y1 with
      ways := some [way]
      lane := some { direction := some dir, width := some width } }

/-- The rural two-lane highway; lane B's top edge and measured width are the caller's. -/
def road (bTop bWidth : Q) : List Structure :=
  [ Build.rect 10 .highway (m 0) (m (-3)) (m 200) (m 11)
  , { Build.rect 13 .shoulder (m 0) (m (-3)) (m 200) (m 0) with ways := some [10] }
  , { Build.rect 11 .roadway (m 0) (m 0) (m 200) bTop with ways := some [10] }
  , laneOn 12 10 (m 0) (m 4) Build.east (m 4)
  , laneOn 14 10 (m 4) bTop Build.west bWidth ]

def twoLane : List Structure := road (m 8) (m 4)

/-- x standing at `(50, y)`, engine and hazard as given. -/
def standing (y : Q) (engine hazard : Bool) : RoadUser :=
  Build.withSignals
    (Build.withKin (Build.user 1 [.motorVehicle] (m 50, y) Build.east Q.zero body)
      fun k => { k with engineRunning := some engine })
    fun s => { s with hazard := some hazard }

def xStanding : RoadUser := standing (cm 250) true false

/-- The other vehicle, standing in lane B at `(px, 6)`. -/
def otherStanding (px : Q) : RoadUser :=
  Build.user 2 [.motorVehicle] (px, m 6) Build.west Q.zero body

def still (users : List RoadUser) (structures : List Structure) (asms : List (AsmId × Bool) := outside) : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1) users structures [] (assumptions := asms)

/-- `forbid` (violated): On a rural two-lane highway x (ru.motor_vehicle) halts in one lane while another vehicle halts in the other lane alongside it (rel.longitudinal_overlap positive): no lane beside x is free. -/
def forbidTrace : Trace := still [xStanding, otherStanding (m 50)] twoLane

/-- `permit` (compliant): x halts in one lane of a rural two-lane highway; the other lane, within p.opposite_lane_reach, has st.lane_width above p.free_passage_width and no other road user is in the scene. -/
def permitTrace : Trace := still [xStanding] twoLane

/-- `idle` (not_applicable): x drives along the rural roadway without halting. -/
def idleTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.withSignals
          (Build.withKin
            (Build.user 1 [.motorVehicle] (Q.add (m 20) (m (15 * (k : Int))), cm 250) Build.east
              (Units.metresPerSecond 15) body)
            fun kn => { kn with engineRunning := some true })
          fun s => { s with hazard := some false } ]
      twoLane [] (assumptions := outside)

/-- `blind` (unknown): x halts in one lane of a rural two-lane highway with the other lane empty, but the source does not observe lane widths. -/
def blindTrace : Trace := still [xStanding] twoLane

/-- `branch_1` (not_applicable): x halts with its engine not running and its hazard lamps flashing: the disabled-vehicle exception applies. -/
def branch_1Trace : Trace := still [standing (cm 250) false true, otherStanding (m 50)] twoLane

/-- `branch_2` (not_applicable): the permit scene, but inside a declared business or residence district. -/
def branch_2Trace : Trace := still [xStanding] twoLane inside

/-- `branch_3` (not_applicable): x stands on the shoulder, off the roadway, with the lanes empty. -/
def branch_3Trace : Trace := still [standing (cm (-150)) true false] twoLane

/-- `branch_4` (violated): the other lane is empty but only 2 m wide, below the free-passage width. -/
def branch_4Trace : Trace := still [xStanding] (road (m 6) (m 2))

/-- `branch_5` (violated): x stands at the far edge of lane A, 2.1 m from lane B, beyond the beside reach. -/
def branch_5Trace : Trace := still [standing (m 1) true false] twoLane

/-- `branch_6` (compliant): the other vehicle drives past in lane B alongside x without halting. -/
def branch_6Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ xStanding
      , Build.user 2 [.motorVehicle] (Q.add (m 55) (m (-(10 * (k : Int)))), m 6) Build.west
          (Units.metresPerSecond 10) body ]
      twoLane [] (assumptions := outside)

/-- `branch_7` (compliant): the other vehicle stands in lane B 30 m ahead, not alongside x. -/
def branch_7Trace : Trace := still [xStanding, otherStanding (m 80)] twoLane

/-- `branch_8` (violated): a one-lane roadway; the empty lane beside x belongs to another highway (a frontage road). -/
def branch_8Trace : Trace :=
  still [xStanding]
    [ Build.rect 10 .highway (m 0) (m (-3)) (m 200) (m 4)
    , { Build.rect 11 .roadway (m 0) (m 0) (m 200) (m 4) with ways := some [10] }
    , laneOn 12 10 (m 0) (m 4) Build.east (m 4)
    , Build.rect 20 .highway (m 0) (m 4) (m 200) (m 11)
    , { Build.rect 21 .roadway (m 0) (m 4) (m 200) (m 8) with ways := some [20] }
    , laneOn 22 20 (m 4) (m 8) Build.west (m 4) ]

/-- `branch_9` (violated): the forbid scene with x's engine off but no hazard lamps: not read as disabled. -/
def branch_9Trace : Trace := still [standing (cm 250) false false, otherStanding (m 50)] twoLane

/-- `branch_10` (violated): the forbid scene with hazard lamps on but the engine running: not read as disabled. -/
def branch_10Trace : Trace := still [standing (cm 250) true true, otherStanding (m 50)] twoLane

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_440_1_o2"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("x", 1)]
    expected := expected
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["st.lane_width"]
  , witness "branch_1" branch_1Trace .notApplicable
  , witness "branch_2" branch_2Trace .notApplicable
  , witness "branch_3" branch_3Trace .notApplicable
  , witness "branch_4" branch_4Trace .violated
  , witness "branch_5" branch_5Trace .violated
  , witness "branch_6" branch_6Trace .compliant
  , witness "branch_7" branch_7Trace .compliant
  , witness "branch_8" branch_8Trace .violated
  , witness "branch_9" branch_9Trace .violated
  , witness "branch_10" branch_10Trace .violated ]

end TrafficSpecWitness.NRS_484B_440_1_o2
