/-
  Witnesses for NRS_484B_227_1_o1.

  The carriageway (every figure here is the witness's own and appears nowhere in the rule): a
  north–south divided highway, region 1, the whole public way from x = -20 m to x = +20 m and from
  y = -500 m to y = +500 m. On it lie two roadways — region 2, x ∈ [2, 14], designated north, and
  region 3, x ∈ [-14, -2], designated south — separated by region 4, a concrete barrier occupying
  x ∈ [-2, 2] along the whole stretch, with no opening recorded (`opening := some false`) except in
  `branch_1`, where the same barrier carries one. `branch_2` adds region 5, an intersection on the
  way covering y ∈ [-6, 6] across both roadways; `branch_3` is an undivided way of the same two
  opposed roadways meeting at x = 0, with no barrier region at all.

  The bodies: one road user, track 1, the subject, 4 m long and 2 m wide; each trace is three
  instants one second apart, the positions following the stated speed and heading. Against the run's
  tolerance of 0.3 m/s, 12 m/s of southward travel on the northbound roadway breaks the bound by a
  wide margin, and 25 m/s of northward travel keeps it by one.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_227_1_o1
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_227_1_o1

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

/-- The whole public way between its boundary lines. -/
def wayRegion : Structure := Build.rect 1 .highway (m (-20)) (m (-500)) (m 20) (m 500)

/-- The roadway of the northbound designation. -/
def northRoadway : Structure :=
  { Build.rect 2 .roadway (m 2) (m (-500)) (m 14) (m 500) with
      lane := some { direction := some Build.north }
      ways := some [1] }

/-- The roadway of the southbound designation. -/
def southRoadway : Structure :=
  { Build.rect 3 .roadway (m (-14)) (m (-500)) (m (-2)) (m 500) with
      lane := some { direction := some Build.south }
      ways := some [1] }

/-- The physical barrier between the two roadways, unbroken along the stretch recorded. -/
def barrier : Structure :=
  { Build.rect 4 .medianOrDivider (m (-2)) (m (-500)) (m 2) (m 500) with
      ways := some [1]
      opening := some false }

/-- The same barrier, with a recorded opening at a crossover. -/
def barrierWithOpening : Structure := { barrier with opening := some true }

/-- An intersection on the way, across both roadways. -/
def junction : Structure :=
  { Build.rect 5 .intersection (m (-14)) (m (-6)) (m 14) (m 6) with ways := some [1] }

/-- The divided way: the two roadways and the barrier between them. -/
def dividedWay : List Structure := [wayRegion, northRoadway, southRoadway, barrier]

/-- The subject, a car. -/
def car (pos : Vec) (heading : Vec) (speed : Q) : RoadUser :=
  Build.user 1 [.motorVehicle] pos heading speed (m 2, m 1, cm 75)

/-- `forbid` (violated): A divided highway carries two roadways separated by a concrete median with no opening along the stretch recorded. The subject, a car, occupies the roadway whose designated direction points north but travels at 12 m/s due south along it, far outside any opening or junction. No other road user is in the scene. -/
def forbidTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ car (m 8, m (-12 * (k : Int))) Build.south (m 12) ]
      dividedWay
      [ ]

/-- `permit` (compliant): The same divided highway; the subject travels at 25 m/s due north on the roadway whose designated direction points north, and is the only road user in the scene, so the duty is decided for the subject alone. -/
def permitTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ car (m 8, m (25 * (k : Int))) Build.north (m 25) ]
      dividedWay
      [ ]

/-- `idle` (not_applicable): The subject is a pedal bicycle, which the vehicle aggregate's definition leaves out; it rides southward on the northbound roadway of the divided highway. -/
def idleTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.bicycle] (m 8, m (-5 * (k : Int))) Build.south (m 5) (m 1, cm 30, cm 90) ]
      dividedWay
      [ ]

/-- `blind` (unknown): The subject travels along one roadway of the divided highway, but the source records no designated direction for that roadway: st.lane_direction is absent, so whether the subject travels with or against the roadway's designation is unknown. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ car (m 8, m (20 * (k : Int))) Build.north (m 20) ]
      dividedWay
      [ ]

/-- `branch_1` (not_applicable): The divider of the same highway has a recorded opening at a crossover. The subject's footprint overlaps that opening while it crosses from one roadway to the other, travelling across both designations; the exception releases it there. -/
def branch_1Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ car (m (4 - 5 * (k : Int)), m 0) Build.west (m 5) ]
      [ wayRegion, northRoadway, southRoadway, barrierWithOpening ]
      [ ]
      (some [(1, 1), (1, 2), (1, 3), (1, 4)])

/-- `branch_2` (not_applicable): The subject crosses an intersection established on the same divided
    way, travelling at 2 m/s against the northbound roadway's designation while its footprint lies
    within that junction; the exception releases it there. -/
def branch_2Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ car (m 8, m (-2 * (k : Int))) Build.south (m 2) ]
      [ wayRegion, northRoadway, southRoadway, barrier, junction ]
      [ ]

/-- `branch_3` (not_applicable): The way is undivided — its two opposed roadways meet at x = 0 with
    no barrier or dividing section between them — so the subject's southward travel on the
    northbound roadway engages no duty of this section. -/
def branch_3Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ car (m 8, m (-12 * (k : Int))) Build.south (m 12) ]
      [ wayRegion
      , { Build.rect 2 .roadway (m 0) (m (-500)) (m 14) (m 500) with
            lane := some { direction := some Build.north }
            ways := some [1] }
      , { Build.rect 3 .roadway (m (-14)) (m (-500)) (m 0) (m 500) with
            lane := some { direction := some Build.south }
            ways := some [1] } ]
      [ ]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_227_1_o1"
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
  , witness "blind" blindTrace (.unknown []) ["st.lane_direction"]
  , witness "branch_1" branch_1Trace .notApplicable
  , witness "branch_2" branch_2Trace .notApplicable
  , witness "branch_3" branch_3Trace .notApplicable ]

end TrafficSpecWitness.NRS_484B_227_1_o1
