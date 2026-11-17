/-
  Witnesses for LVMC_11_40_180_A.

  Geometry (the witness's own figures): a sidewalk `10` spans x ∈ [0, 200] m, y ∈ [0, 4] m; the
  roadway `20` beside it spans x ∈ [0, 200] m, y ∈ [-10, 0] m. A device is 1.8 m long, 0.6 m wide
  (half-extents 0.9, 0.3, 0.6 m); on the sidewalk its centre line is y = 2 m, on the roadway
  y = -5 m, so its whole footprint lies inside the one region. Three instants at 1 s spacing.
  Moving devices travel east at 3 m/s (far above the 0.1 m/s tolerance); the one at rest has
  speed 0. Each scene declares `asm.fremont_street_main_to_seventh` true, except `branch_1`, whose
  map reading declares it false.
-/
import TrafficSpec.Rules.LVMC_11.LVMC_11_40_180_A
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.LVMC_11_40_180_A

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

def asmId : String := "asm.fremont_street_main_to_seventh"

def bodyExtent : Q × Q × Q := (cm 90, cm 30, cm 60)

def sidewalk : Structure := Build.rect 10 .sidewalk (m 0) (m 0) (m 200) (m 4)
def roadway : Structure := Build.rect 20 .roadway (m 0) (m (-10)) (m 200) (m 0)

def structures : List Structure := [sidewalk, roadway]

/-- A device moving east at 3 m/s along line `y`, at instant `k`. -/
def moving (cls : RoadUserClass) (y : Int) (k : Nat) : RoadUser :=
  Build.user 1 [cls] (m (10 + 3 * (k : Int)), m y) Build.east (Units.metresPerSecond 3) bodyExtent
    (some (m (3 * (k : Int))))

-- Binders ↦ tracks: subject ↦ 1

/-- `forbid` (violated): An electric scooter moves along a sidewalk at a place the map's reading declares to be Fremont Street between Main Street and Seventh Street. -/
def forbidTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ moving .electricScooter 2 k ]
      structures
      []
      (assumptions := [(asmId, true)])

/-- `permit` (compliant): A bicycle stands at rest on that sidewalk. -/
def permitTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.bicycle] (m 10, m 2) Build.east Q.zero bodyExtent (some Q.zero) ]
      structures
      []
      (assumptions := [(asmId, true)])

/-- `idle` (not_applicable): A bicycle rides on the roadway of Fremont Street within the declared stretch, never on the sidewalk. -/
def idleTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ moving .bicycle (-5) k ]
      structures
      []
      (assumptions := [(asmId, true)])

/-- `blind` (unknown): A bicycle on that sidewalk whose speed the source does not supply. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ moving .bicycle 2 k ]
      structures
      []
      (assumptions := [(asmId, true)])

/-- `branch_1` (not_applicable): A bicycle rides on a sidewalk at a place the map's reading declares outside the named stretch. -/
def branch_1Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ moving .bicycle 2 k ]
      structures
      []
      (assumptions := [(asmId, false)])

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
  , witness "branch_1" branch_1Trace .notApplicable ]

end TrafficSpecWitness.LVMC_11_40_180_A
