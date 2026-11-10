/-
  Witnesses for NRS_484B_113_2.

  Geometry (the witness's own figures, none in the rule): an intersection (region 10) is the
  square x ∈ [0, 20] m, y ∈ [-10, 10] m; a marked mid-block crosswalk (region 30) is the strip
  x ∈ [-50, -46] m, y ∈ [-6, 6] m; a roadway (region 20) runs x ∈ [-100, -20] m, y ∈ [-5, 5] m.
  The car (track 1, a motor vehicle) is 4 m × 2 m (half-extents 2 m, 1 m). Its heading is a
  cardinal direction and its velocity is set apart from it: backing is a velocity of 2 or 6 m/s
  opposite the heading (against a speed resolution of 0.2 m/s), forwards a velocity along it.
  Turning is a left yaw rate of 90 deg/s (against a yaw-rate resolution of 2 deg/s), the heading
  turning a quarter turn over each 1 s interval so that it stays exact; straight is 0.

  Three instants at 0, 1000 and 2000 ms. Entry into an intersection is a rising edge, undecided at
  the first observation, so every witness speaks about the instants 1000–2000 ms (`window`).
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_113_2
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_113_2

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: x ↦ 1

def asmCity : AsmId := "asm.within_city_limits"

/-- The car: position, heading, speed, velocity (none where unobserved) and yaw rate. -/
def car (pos heading : Vec) (speed : Q) (vel : Option Vec) (yaw : Q) : RoadUser :=
  Build.withKin (Build.user 1 [.motorVehicle] pos heading speed (m 2, m 1, cm 75))
    fun k => { k with velocity := vel, yawRate := some yaw }

def intersection : Structure := Build.rect 10 .intersection (m 0) (m (-10)) (m 20) (m 10)
def roadway : Structure := Build.rect 20 .roadway (m (-100)) (m (-5)) (m (-20)) (m 5)
def crosswalk : Structure :=
  { Build.rect 30 .crosswalk (m (-50)) (m (-6)) (m (-46)) (m 6) with marked := some true }

/-- x positions of a car approaching the intersection from the west: well clear (footprint
    -14…-10, -8…-4) at 0 and 1000 ms, wholly inside (footprint 4…8) at 2000 ms. -/
def approachX (k : Nat) : Q := [m (-12), m (-6), m 6].getD k Q.zero

/-- `forbid` (violated): A car moves backwards (kin.velocity opposite kin.heading) and at this observation its footprint begins to overlap a st.intersection region. -/
def forbidTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ car (approachX k, m 0) Build.west (Units.metresPerSecond 6)
          (some (Build.scale Build.east (Units.metresPerSecond 6))) Q.zero ]
      [ intersection ]
      [ ]
      (assumptions := [(asmCity, true)])

/-- `permit` (compliant): The same car drives forwards into the intersection. -/
def permitTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ car (approachX k, m 0) Build.east (Units.metresPerSecond 6)
          (some (Build.scale Build.east (Units.metresPerSecond 6))) Q.zero ]
      [ intersection ]
      [ ]
      (assumptions := [(asmCity, true)])

/-- `idle` (not_applicable): A car backs straight along a roadway mid-block; no intersection or crosswalk is overlapped and it is not yawing. -/
def idleTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ car ([m (-80), m (-78), m (-76)].getD k Q.zero, m 0) Build.west (Units.metresPerSecond 2)
          (some (Build.scale Build.east (Units.metresPerSecond 2))) Q.zero ]
      [ roadway, intersection ]
      [ ]
      (assumptions := [(asmCity, true)])

/-- `blind` (unknown): A car enters an intersection; the source declares kin.velocity absent, so whether it is backing is unknown. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ car (approachX k, m 0) Build.west (Units.metresPerSecond 6) none Q.zero ]
      [ intersection ]
      [ ]
      (assumptions := [(asmCity, true)])

/-- `branch_1` (violated): A car backs over a marked mid-block st.crosswalk (no intersection). -/
def branch_1Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ car ([m (-52), m (-50), m (-48)].getD k Q.zero, m 0) Build.west (Units.metresPerSecond 2)
          (some (Build.scale Build.east (Units.metresPerSecond 2))) Q.zero ]
      [ roadway, crosswalk ]
      [ ]
      (assumptions := [(asmCity, false)])

/-- A turning car's headings at 0, 1000, 2000 ms: a left yaw of 90 deg/s, held over each 1 s
    interval, turns the heading a quarter turn per step (the rate at a scene is held over the
    interval before it; none before the first). -/
def turnHeadings (h0 h1 h2 : Vec) (k : Nat) : Vec := [h0, h1, h2].getD k h0
def turnYaw (k : Nat) : Q := if k = 0 then Q.zero else Units.degrees 90

/-- A car inside the intersection: forwards and straight at 0 ms (it entered before the
    recording), then backing at 2 m/s at 1000 and 2000 ms; `turning` yaws it left at 90 deg/s
    (heading east, north, west), otherwise it keeps pointing east with no yaw. -/
def cornerScene (turning city : Bool) (k : Nat) (t : Timestamp) : Scene :=
  let h := if turning then turnHeadings Build.east Build.north Build.west k else Build.east
  let yaw := if turning then turnYaw k else Q.zero
  let v := Units.metresPerSecond 2
  Build.scene t (some 1)
    [ if k = 0 then
        car (m 10, m 0) h v (some (Build.scale h v)) yaw
      else
        car ([m 10, m 9, m 8].getD k Q.zero, m 0) h v (some (Build.scale h (Q.neg v))) yaw ]
    [ intersection ]
    [ ]
    (assumptions := [(asmCity, city)])

/-- `branch_2` (violated): Having entered an intersection forwards, a car backs while yawing round its corner, its footprint on the intersection and on no crosswalk; asm.within_city_limits true. -/
def branch_2Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t => cornerScene true true k t

/-- `branch_3` (not_applicable): As branch_2, with asm.within_city_limits false: the corner is no street corner, the car entered forwards and overlaps no crosswalk. -/
def branch_3Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t => cornerScene true false k t

/-- `branch_4` (not_applicable): As branch_2, but the car backs straight (no yaw) within the
    intersection it already entered: neither into it nor around a corner. -/
def branch_4Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t => cornerScene false true k t

/-- `branch_5` (not_applicable): Inside a city, a car backs while yawing mid-block on the roadway
    (heading west, south, east), its footprint on no intersection and no crosswalk. -/
def branch_5Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    let h := turnHeadings Build.west Build.south Build.east k
    let v := Units.metresPerSecond 2
    Build.scene t (some 1)
      [ car ([m (-80), m (-78), m (-76)].getD k Q.zero, m 0) h v
          (some (Build.scale h (Q.neg v))) (turnYaw k) ]
      [ roadway, intersection ]
      [ ]
      (assumptions := [(asmCity, true)])

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_113_2"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("x", 1)]
    expected := expected
    window := some (1000, 2000)
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["kin.velocity"]
  , witness "branch_1" branch_1Trace .violated
  , witness "branch_2" branch_2Trace .violated
  , witness "branch_3" branch_3Trace .notApplicable
  , witness "branch_4" branch_4Trace .notApplicable
  , witness "branch_5" branch_5Trace .notApplicable ]

end TrafficSpecWitness.NRS_484B_113_2
