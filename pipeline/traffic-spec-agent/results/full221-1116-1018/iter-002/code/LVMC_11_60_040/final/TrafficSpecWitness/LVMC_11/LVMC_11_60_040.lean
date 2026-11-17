/-
  Witnesses for LVMC_11_60_040.

  Geometry (the witness's own figures, nowhere in the rule): a city highway region `10`, the
  rectangle x ∈ [0, 500], y ∈ [0, 20]; a curb zone `20` of kind taxicab_stand, x ∈ [400, 430],
  y ∈ [0, 3], lying on the highway; a private lot `30` (a parking space, no highway) at
  x ∈ [0, 50], y ∈ [-80, -40]. The taxicab (track 1, classes taxicab and motor vehicle) is
  4.6 m × 1.8 m. The reading's figures are p.halt_speed_tolerance = 0.1 m/s and
  p.standing_min_duration = 60 s.

  forbid / permit / idle / blind: 31 scenes at 10 s, 0 … 300 s (5 minutes at rest, speed 0);
  the judged instants are 60 s … 300 s, where the 60 s look-back is covered.
  branch_1: 37 scenes at 5 s; moving at 2 m/s until 55 s, at rest at x = 120 m from 60 s to
  85 s (a 30 s halt), moving again from 90 s; judged 60 s … 180 s — never at rest for 60 s.
-/
import TrafficSpec.Rules.LVMC_11.LVMC_11_60_040
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.LVMC_11_60_040

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def highway : Structure := Build.rect 10 .highway (m 0) (m 0) (m 500) (m 20)
def taxiStand : Structure :=
  { Build.rect 20 .curbZone (m 400) (m 0) (m 430) (m 3) with
    curbKind := some .taxicabStand, ways := some [10] }
def privateLot : Structure := Build.rect 30 .parkingSpace (m 0) (m (-80)) (m 50) (m (-40))

def structures : List Structure := [highway, taxiStand, privateLot]

def taxi (pos : Vec) (speed : Q) : RoadUser :=
  Build.user 1 [.taxicab, .motorVehicle] pos Build.east speed (cm 230, cm 90, cm 75)

def restingTrace (pos : Vec) : Trace :=
  Build.trace 31 0 (Units.seconds 10) fun _k t =>
    Build.scene t (some 1) [taxi pos Q.zero] structures []

/-- `forbid` (violated): A taxicab halts at the curb of a city highway, outside any taxicab_stand curb zone, and stays at rest for 5 minutes. -/
def forbidTrace : Trace := restingTrace (m 100, cm 150)

/-- `permit` (compliant): A taxicab halts within a taxicab_stand curb zone of the highway and stays at rest for 5 minutes. -/
def permitTrace : Trace := restingTrace (m 415, cm 150)

/-- `idle` (not_applicable): A taxicab stands for 5 minutes in a private parking lot whose footprint lies on no highway. -/
def idleTrace : Trace := restingTrace (m 25, m (-60))

/-- `blind` (unknown): A taxicab is at the curb of a highway outside any taxicab stand for 5 minutes; the source supplies no speed, so whether it stands is unknown. -/
def blindTrace : Trace := restingTrace (m 100, cm 150)

/-- `branch_1` (compliant): A taxicab halts 30 seconds at the curb outside any taxicab stand, a passenger boards, and it drives off: the halt is a temporary stop, not standing. -/
def branch_1Trace : Trace :=
  Build.trace 37 0 (Units.seconds 5) fun k t =>
    let ts : Int := 5 * (Int.ofNat k)
    let (x, v) : Q × Q :=
      if k < 12 then (m (2 * ts), Units.metresPerSecond 2)
      else if k < 18 then (m 120, Q.zero)
      else (m (120 + 2 * (ts - 90)), Units.metresPerSecond 2)
    Build.scene t (some 1) [taxi (x, cm 150) v] structures []

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "")
    (window : Option (Timestamp × Timestamp) := none) : Scenario :=
  { name := name
    rule := "LVMC_11_60_040"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("subject", 1)]
    expected := expected
    window := window
    boundary := boundary }

def judged : Option (Timestamp × Timestamp) := some (60000, 300000)

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated (window := judged)
  , witness "permit" permitTrace .compliant (window := judged)
  , witness "idle" idleTrace .notApplicable (window := judged)
  , witness "blind" blindTrace (.unknown []) ["kin.speed"] (window := judged)
  , witness "branch_1" branch_1Trace .compliant (window := some (60000, 180000)) ]

end TrafficSpecWitness.LVMC_11_60_040
