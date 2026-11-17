/-
  Witnesses for LVMC_11_52_040_A.

  Geometry: a street whose roadway (region 10) spans x ∈ [0, 200] m, y ∈ [0, 8] m, eastbound
  (its designated direction east); its curbside lane l (region 11) spans y ∈ [0, 4] m, direction
  east. The subject, track 1, a passenger car (ru.motor_vehicle, half-extent 2 m × 1 m × 0.75 m),
  stands at (100, 2), inside both l and the roadway. Scenes every 10 s from 0 s to 140 s; the
  verdict is read over 80 s … 140 s, so the standing window (60 s in the run's reading) is covered
  at every judged instant. Headings: east (dot 1, well above the 0.97 bound), west (dot −1),
  north (dot 0). The idle car moves east at 1 m/s (ten times the halt tolerance). In branch_2, a
  regulatory sign (device 20) with code angle_parking and no stated conditions governs l.
  Every figure here is the witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.LVMC_11.LVMC_11_52_040_A
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.LVMC_11_52_040_A

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def carExtent : Q × Q × Q := (m 2, m 1, cm 75)

/-- The roadway, eastbound. -/
def roadway (withDirection : Bool := true) : Structure :=
  let r := Build.rect 10 .roadway (m 0) (m 0) (m 200) (m 8)
  if withDirection then { r with lane := some { direction := some Build.east } } else r

/-- The curbside lane l, eastbound. -/
def laneL (withDirection : Bool := true) : Structure :=
  let l := Build.lane 11 [(m 0, m 0), (m 200, m 0), (m 200, m 4), (m 0, m 4)] Build.east
  if withDirection then l else { l with lane := some {} }

def angleSign : Device :=
  { Build.sign 20 .regulatorySign [11] with code := some .angleParking, conditions := some {} }

/-- The car standing at (100, 2) with the given heading. -/
def standingTrace (heading : Vec) (devices : List Device) (dir : Bool := true) : Trace :=
  Build.trace 15 0 (Units.seconds 10) fun _k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.motorVehicle] (m 100, m 2) heading Q.zero carExtent ]
      [ roadway dir, laneL dir ]
      devices

/-- `forbid` (violated): A street whose roadway carries a curbside lane l (st.lane, direction east). The subject, a passenger car (ru.motor_vehicle), stands at rest in l for several minutes with its heading pointing west, against the lane's direction; no angle_parking sign governs l. -/
def forbidTrace : Trace := standingTrace Build.west []

/-- `permit` (compliant): The same car stands at rest in l for several minutes with its heading east, along the lane's direction. -/
def permitTrace : Trace := standingTrace Build.east []

/-- `idle` (not_applicable): The same car drives along l at a steady speed without halting. -/
def idleTrace : Trace :=
  Build.trace 15 0 (Units.seconds 10) fun k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.motorVehicle] (m (5 + 10 * (Int.ofNat k)), m 2) Build.east (Units.metresPerSecond 1) carExtent ]
      [ roadway, laneL ]
      []

/-- `blind` (unknown): As in forbid, but the source supplies no designated direction for l (st.lane_direction absent). -/
def blindTrace : Trace := standingTrace Build.west []

/-- `branch_1` (violated): The car stands in l for several minutes with its heading pointing north, across the lane's direction. -/
def branch_1Trace : Trace := standingTrace Build.north []

/-- `branch_2` (not_applicable): As in branch_1, but a dev.regulatory_sign with code angle_parking governs l. -/
def branch_2Trace : Trace := standingTrace Build.north [angleSign]

def judged : Option (Timestamp × Timestamp) := some (80000, 140000)

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "LVMC_11_52_040_A"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("subject", 1)]
    expected := expected
    window := judged
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["st.lane_direction"]
  , witness "branch_1" branch_1Trace .violated
  , witness "branch_2" branch_2Trace .notApplicable ]

end TrafficSpecWitness.LVMC_11_52_040_A
