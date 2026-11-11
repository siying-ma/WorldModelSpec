/-
  Witnesses for NRS_484B_210_3.

  The carriageway runs east along +x. The paved eastbound lane (region 10) spans y ∈ [0, 3.5] m;
  where a second eastbound lane is built (region 11) it spans y ∈ [3.5, 7] m. Beside the lane on the
  right (south) lies the shoulder (region 20), y ∈ [-3, 0] m, or, in the road-edge branches, a road
  edge strip (region 30), y ∈ [-0.6, 0] m; its paved attribute is set per scene. Both cars are
  4.6 m × 1.8 m (half-extents 2.3 m, 0.9 m, 0.75 m) heading east. The subject (track 1) rides
  the shoulder at y = -1.5 m (the road edge at y = -0.3 m); the other car (track 2) keeps to the lane
  at y = 1.75 m, so it lies 3.25 m on the subject's left (2.05 m on the road-edge branches).
  Three instants 1 s apart; positions follow the speeds, and the subject's centre goes from 3 m
  behind to 3 m ahead of the other car's, so the bodies overlap along the heading (4.6 m − 3 m
  at the ends) at every instant. Speed differences are 3 m/s, far from the reading's 0.5 m/s
  margin; headings are identical, far from its 0.9 cosine tolerance.
  In `blind` the source does not place the other car (no position), so its side is not computed
  from kinematics; the overlap along the subject's heading is supplied as measured.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_210_3
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_210_3

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: x ↦ 1

def carExtent : Q × Q × Q := (cm 230, cm 90, cm 75)

/-- The paved eastbound lane. -/
def rightLane : Structure := Build.rect 10 .lane (m (-100)) (m 0) (m 100) (cm 350)
/-- A second paved eastbound lane, on the left of the first. -/
def leftLane : Structure := Build.rect 11 .lane (m (-100)) (cm 350) (m 100) (m 7)
/-- The shoulder on the right of the lane, with its paved attribute. -/
def shoulder (paved : Bool) : Structure :=
  { Build.rect 20 .shoulder (m (-100)) (m (-3)) (m 100) (m 0) with paved := some paved }
/-- The road edge on the right of the lane, with the paved attribute of the surface beyond it. -/
def roadEdge (paved : Bool) : Structure :=
  { Build.rect 30 .roadEdge (m (-100)) (cm (-60)) (m 100) (m 0) with paved := some paved }

/-- A car heading east at a centre `(cx, cy)` (cm) and a speed (m/s). -/
def car (track : TrackId) (cls : RoadUserClass) (cx cy : Int) (v : Int) : RoadUser :=
  Build.user track [cls] (cm cx, cm cy) Build.east (Units.metresPerSecond v) carExtent

/-- The subject at `xy` (cm across) moving at `vx`, beside the other car in the lane moving at `vy`;
    the subject's centre is 3 m behind the other's at the first instant. -/
def pair (structures : List Structure) (xy : Int) (vx vy : Int) (otherCls : RoadUserClass := .motorVehicle) :
    Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    let k : Int := Int.ofNat k
    Build.scene t (some 1)
      [ car 1 .motorVehicle (100 * (vx * k - 3)) xy vx
      , car 2 otherCls (100 * (vy * k)) 175 vy ]
      structures
      [ ]

/-- `forbid` (violated): On a two-lane highway a car moves onto the unpaved shoulder and drives alongside a slower car that waits to turn left, the slower car on its left, the bodies side by side. -/
def forbidTrace : Trace := pair [rightLane, shoulder false] (-150) 3 0

/-- `permit` (compliant): A car alone in the scene pulls onto the unpaved shoulder and slows to a stop: it passes no vehicle, and the duty binds it alone. -/
def permitTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    let (pos, v) : Int × Int := match k with
      | 0 => (0, 4)
      | 1 => (300, 2)
      | _ => (400, 0)
    Build.scene t (some 1)
      [ car 1 .motorVehicle pos (-150) v ]
      [rightLane, shoulder false]
      [ ]

/-- `idle` (not_applicable): On a highway with two lanes in its direction, a car passes a slower car on its right within the paved right lane, never leaving the pavement. -/
def idleTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    let k : Int := Int.ofNat k
    Build.scene t (some 1)
      [ car 1 .motorVehicle (100 * (6 * k - 6)) 175 6
      , car 2 .motorVehicle (100 * (3 * k - 3)) 525 3 ]
      [rightLane, leftLane, shoulder false]
      [ ]

/-- `blind` (unknown): A car on the unpaved shoulder moves faster than a car beside it; the source declares rel.bearing absent, so on which side of it the other car lies is not observed. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    let k : Int := Int.ofNat k
    -- the source reports the other car's heading, speed and size and the bodies' overlap along the
    -- subject's heading (4.6 m less the 3 m, 0 m, 3 m offset), but not where it stands
    let other := Build.withKin (car 2 .motorVehicle (100 * (2 * k)) 175 2) fun kn => { kn with position := none }
    let overlap : Int := if k == 1 then 460 else 160
    -- with no position, the other car's occupancy is not observed: only the subject's is
    let s := Build.scene t (some 1)
        [ car 1 .motorVehicle (100 * (5 * k - 3)) (-150) 5, other ]
        [rightLane, shoulder false]
        [ ]
    Build.withRelations { s with occupancyObserved := [1] }
      [ Build.relation 1 2 fun r => { r with longitudinalOverlap := some (cm overlap) } ]

/-- `branch_1` (compliant): A car crawling on the unpaved shoulder is overtaken by a faster car in the lane on its left: the subject is slower and passes no one. -/
def branch_1Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    let k : Int := Int.ofNat k
    Build.scene t (some 1)
      [ car 1 .motorVehicle (100 * k) (-150) 1
      , car 2 .motorVehicle (100 * (4 * k - 3)) 175 4 ]
      [rightLane, shoulder false]
      [ ]

/-- `branch_2` (violated): A car runs over the road edge onto the unpaved surface beyond it,
    alongside a slower car in the lane on its left. -/
def branch_2Trace : Trace := pair [rightLane, roadEdge false] (-30) 3 0

/-- `branch_3` (compliant): A car on the unpaved shoulder goes past a bicycle in the lane on its
    left: the one passed is no vehicle. -/
def branch_3Trace : Trace := pair [rightLane, shoulder false] (-150) 5 2 .bicycle

/-- `branch_4` (not_applicable): A car passes a slower car on its right on a paved shoulder: it
    never leaves the pavement. -/
def branch_4Trace : Trace := pair [rightLane, shoulder true] (-150) 3 0

/-- `branch_5` (not_applicable): A car passes a slower car on its right over a road edge with
    paved surface beyond it. -/
def branch_5Trace : Trace := pair [rightLane, roadEdge true] (-30) 3 0

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_210_3"
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
  , witness "blind" blindTrace (.unknown []) ["rel.bearing"]
  , witness "branch_1" branch_1Trace .compliant
  , witness "branch_2" branch_2Trace .violated
  , witness "branch_3" branch_3Trace .compliant
  , witness "branch_4" branch_4Trace .notApplicable
  , witness "branch_5" branch_5Trace .notApplicable ]

end TrafficSpecWitness.NRS_484B_210_3
