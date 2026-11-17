/-
  Witnesses for LVMC_11_40_180_A.

  Geometry (every figure the witness's own): Fremont Street runs east–west. Its roadway `10` is the
  rectangle x ∈ [0, 100], y ∈ [0, 7]; the north sidewalk `20` is x ∈ [0, 100], y ∈ [7, 10]. The
  device (track 1) is 1.8 m long and 0.6 m wide. On the sidewalk it travels along y = 8.5 (its
  footprint y ∈ [8.2, 8.8], wholly inside the sidewalk); on the roadway along y = 3.5. A moving
  device goes east at 4 m/s (forty times the reading's halt tolerance of 0.1 m/s); one at rest has
  speed 0. Three instants, one second apart. The assumption `asm.fremont_street_main_to_seventh`
  is declared true in every scene except `branch_1`, where the map's reading places the stretch
  elsewhere (false).
-/
import TrafficSpec.Rules.LVMC_11.LVMC_11_40_180_A
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.LVMC_11_40_180_A

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def asmId : AsmId := "asm.fremont_street_main_to_seventh"

def roadway : Structure := Build.rect 10 .roadway (m 0) (m 0) (m 100) (m 7)
def sidewalk : Structure := Build.rect 20 .sidewalk (m 0) (m 7) (m 100) (m 10)
def structures : List Structure := [roadway, sidewalk]

def halfExt : Q × Q × Q := (cm 90, cm 30, cm 90)

/-- A device of the given classes at x, on the line y, going east at `speed`. -/
def device (classes : List RoadUserClass) (x : Q) (y : Q) (speed : Q) : RoadUser :=
  Build.user 1 classes (x, y) Build.east speed halfExt

def sidewalkY : Q := cm 850
def roadwayY : Q := cm 350

def movingX (k : Nat) : Q := Q.add (m 10) (Q.mul (m 4) (Q.ofInt k))

def scenes (u : Nat → RoadUser) (inStretch : Bool) : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [u k] structures [] (assumptions := [(asmId, inStretch)])

/-- `forbid` (violated): A bicycle moves along a sidewalk at a place the map's reading declares to be Fremont Street between Main Street and Seventh Street. -/
def forbidTrace : Trace :=
  scenes (fun k => device [.bicycle] (movingX k) sidewalkY (Units.metresPerSecond 4)) true

/-- `permit` (compliant): A bicycle stands at rest on that sidewalk. -/
def permitTrace : Trace :=
  scenes (fun _ => device [.bicycle] (m 20) sidewalkY Q.zero) true

/-- `idle` (not_applicable): A bicycle rides on the roadway of Fremont Street within the declared stretch, never on the sidewalk. -/
def idleTrace : Trace :=
  scenes (fun k => device [.bicycle] (movingX k) roadwayY (Units.metresPerSecond 4)) true

/-- `blind` (unknown): A bicycle on that sidewalk whose speed the source does not supply. -/
def blindTrace : Trace :=
  scenes (fun k =>
    Build.withKin (device [.bicycle] (movingX k) sidewalkY (Units.metresPerSecond 4))
      (fun kin => { kin with speed := none, velocity := none })) true

/-- `branch_1` (not_applicable): A bicycle rides on a sidewalk at a place the map's reading declares outside the named stretch. -/
def branch_1Trace : Trace :=
  scenes (fun k => device [.bicycle] (movingX k) sidewalkY (Units.metresPerSecond 4)) false

/-- `branch_2` (violated): An electric bicycle moves along the sidewalk within the declared stretch. -/
def branch_2Trace : Trace :=
  scenes (fun k => device [.electricBicycle] (movingX k) sidewalkY (Units.metresPerSecond 4)) true

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "LVMC_11_40_180_A"
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
  , witness "blind" blindTrace (.unknown []) ["kin.speed"]
  , witness "branch_1" branch_1Trace .notApplicable
  , witness "branch_2" branch_2Trace .violated ]

end TrafficSpecWitness.LVMC_11_40_180_A
