/-
  Witnesses for NRS_484B_440_1_o3.

  Geometry: a rural highway (region 10) is the rectangle x ∈ [0, 400] m, y ∈ [-10, 10] m; its
  roadway (region 11, lying on 10) is x ∈ [0, 400] m, y ∈ [-4, 4] m. Car 1 (a motor vehicle,
  half-extent 2 m × 0.9 m × 0.75 m) heads east. In its lane it sits at (200, -2), inside both
  polygons; off the roadway it sits at (200, 7), inside the highway only. The roadway's recorded
  sight distance is 40 m beyond a crest (well under 200 ft ≈ 61 m) or 300 m on a straight, level
  stretch (well over it). Three instants, one second apart; the rule reads no history.
  Every figure here is the witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_440_1_o3
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_440_1_o3

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: x ↦ 1

def highway : Structure := Build.rect 10 .highway (m 0) (m (-10)) (m 400) (m 10)

def roadway (sight : Option Q) : Structure :=
  { Build.rect 11 .roadway (m 0) (m (-4)) (m 400) (m 4) with
    ways := some [10], sightDistance := sight }

def car (pos : Vec) (speed : Q) : RoadUser :=
  Build.user 1 [.motorVehicle] pos Build.east speed (m 2, cm 90, cm 75)

def inLane : Vec := (m 200, m (-2))
def offRoadway : Vec := (m 200, m 7)

/-- One scene: car 1 at `pos` with `speed`, the roadway's recorded sight distance `sight`, and
    the three assumptions (district, disabled, immovable). -/
def stage (pos : Vec) (speed : Q) (sight : Option Q)
    (district disabled immovable : Bool) : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ car pos speed ]
      [ highway, roadway sight ]
      [ ]
      (assumptions :=
        [ ("asm.business_or_residence_district", district)
        , ("asm.vehicle_disabled", disabled)
        , ("asm.disabled_vehicle_immovable", immovable) ])

/-- `forbid` (violated): On a rural highway, district assumption false and disabled assumptions false, a car halts in its lane just beyond a crest where the recorded sight distance is 40 m. -/
def forbidTrace : Trace := stage inLane Q.zero (some (m 40)) false false false

/-- `permit` (compliant): The car halts in its lane on a straight, level stretch whose recorded sight distance is 300 m. -/
def permitTrace : Trace := stage inLane Q.zero (some (m 300)) false false false

/-- `idle` (not_applicable): The car drives over the crest without halting. -/
def idleTrace : Trace := stage inLane (Units.metresPerSecond 15) (some (m 40)) false false false

/-- `blind` (unknown): The car halts in its lane; the source does not record sight distances. -/
def blindTrace : Trace := stage inLane Q.zero none false false false

/-- `branch_1` (not_applicable): the car halts in its lane at the crest, but the stretch lies in a
    business or residence district. -/
def branch1Trace : Trace := stage inLane Q.zero (some (m 40)) true false false

/-- `branch_2` (not_applicable): the car is disabled and immovable, halted in its lane at the crest. -/
def branch2Trace : Trace := stage inLane Q.zero (some (m 40)) false true true

/-- `branch_3` (not_applicable): the car halts on the highway off the roadway, beside the crest. -/
def branch3Trace : Trace := stage offRoadway Q.zero (some (m 40)) false false false

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_440_1_o3"
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
  , witness "blind" blindTrace (.unknown []) ["st.sight_distance"]
  , witness "branch_1" branch1Trace .notApplicable
  , witness "branch_2" branch2Trace .notApplicable
  , witness "branch_3" branch3Trace .notApplicable ]

end TrafficSpecWitness.NRS_484B_440_1_o3
