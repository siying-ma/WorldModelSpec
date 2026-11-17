/-
  Witnesses for NRS_484B_307_4a_o2.

  Geometry (metres, +x east, +y north), shared by every witness:
    intersection 1: the square x ∈ [-10, 10], y ∈ [-10, 10];
    lane 2: the subject's northbound approach, x ∈ [0, 4], y ∈ [-40, -10], entering 1; governed by
      signal 10;
    crosswalk 3: x ∈ [-10, 10], y ∈ [-14, -10], marking the entrance of lane 2;
    lane 4: the eastbound approach of the west leg, x ∈ [-40, -10], y ∈ [-4, 0], entering 1;
    crosswalk 5: x ∈ [-14, -10], y ∈ [-10, 10], marking the entrance of lane 4 (the crosswalk a
      left-turning subject crosses).
  Subject 1: a motor vehicle, half-extents 2.3 × 0.9 m. Pedestrian 2: half-extents 0.25 × 0.25 m.
  Observations 1 s apart. The subject is first observed in lane 2, so `since` never reaches past
  the start of a trace while it is in the intersection.

  Against the reading (horizon 3 s, clearance 3 m, halt tolerance 0.1 m/s):
    forbid, t = 2 s: subject at (-3, 2) westbound 6 m/s, pedestrian at (-12, -0.5) northbound 1 m/s
      in crosswalk 5: closest approach in ≈ 1.53 s at ≈ 1.0 m of centres — well inside both bounds.
    permit: the subject stands (0 m/s) in lane 2 while the pedestrian is in crosswalk 5, then turns
      once the pedestrian has left it (at (-12, 12), on no region).
    branch_2: another motor vehicle at (-5, 2) westbound at the subject's own velocity, its body
      overlapping the subject's: contact, no closing velocity (no closest approach).
    branch_3: subject in lane 2 at (2, -25) northbound 6 m/s, pedestrian at (-1, -12) eastbound
      1 m/s in crosswalk 3: closest approach in ≈ 2.19 s at ≈ 0.8 m.
  Every figure here is the witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_307_4a_o2
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_307_4a_o2

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n
def mps (n : Int) : Q := Units.metresPerSecond n

-- Binders ↦ tracks: subject ↦ 1

def junction1 : Structure := Build.rect 1 .intersection (m (-10)) (m (-10)) (m 10) (m 10)
def laneNorth : Structure :=
  Build.lane 2 [(m 0, m (-40)), (m 4, m (-40)), (m 4, m (-10)), (m 0, m (-10))] Build.north (enters := some 1)
def crosswalkSouth : Structure :=
  { Build.rect 3 .crosswalk (m (-10)) (m (-14)) (m 10) (m (-10)) with
    entranceOf := [2], entranceObserved := true, marked := some true }
def laneEast : Structure :=
  Build.lane 4 [(m (-40), m (-4)), (m (-10), m (-4)), (m (-10), m 0), (m (-40), m 0)] Build.east (enters := some 1)
def crosswalkWest : Structure :=
  { Build.rect 5 .crosswalk (m (-14)) (m (-10)) (m (-10)) (m 10) with
    entranceOf := [4], entranceObserved := true, marked := some true }

def worldMap : List Structure := [junction1, laneNorth, crosswalkSouth, laneEast, crosswalkWest]

def signalHead (shows : List SignalIndication) : Device := Build.signal 10 [2] shows

def subj (x y : Q) (h : Vec) (v : Q) : RoadUser :=
  Build.user 1 [.motorVehicle] (x, y) h v (cm 230, cm 90, cm 75)
def ped (x y : Q) (h : Vec) (v : Q) : RoadUser :=
  Build.user 2 [.pedestrian] (x, y) h v (cm 25, cm 25, cm 90)
def car (track : TrackId) (x y : Q) (h : Vec) (v : Q) : RoadUser :=
  Build.user track [.motorVehicle] (x, y) h v (cm 230, cm 90, cm 75)

/-- The subject's left turn: in lane 2, then in the intersection, then westbound across it. -/
def turning (k : Nat) : RoadUser :=
  match k with
  | 0 => subj (m 2) (m (-16)) Build.north (mps 6)
  | 1 => subj (m 2) (m (-9)) Build.north (mps 6)
  | _ => subj (m (-3)) (m 2) Build.west (mps 6)

/-- The pedestrian walking north in crosswalk 5 into the subject's path. -/
def crossing (k : Nat) : RoadUser :=
  match k with
  | 0 => ped (m (-12)) (m (-3)) Build.north (mps 1)
  | 1 => ped (m (-12)) (m (-2)) Build.north (mps 1)
  | _ => ped (m (-12)) (cm (-50)) Build.north (mps 1)

def conflictScene (shows : List SignalIndication) (k : Nat) (t : Timestamp) : Scene :=
  Build.scene t (some 1) [turning k, crossing k] worldMap [signalHead shows]

/-- `forbid` (violated): The subject vehicle occupies an approach lane whose dev.traffic_signal displays green_arrow(left) alone; it turns left at 6 m/s while a pedestrian walks in the crosswalk marking the entrance of the cross street's approach (st.entrance_of); prim.closest_approach_within holds with a closest centre distance of 1.0 m in 1.5 s, and the subject keeps moving. -/
def forbidTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t => conflictScene [.greenArrow .left] k t

/-- `permit` (compliant): The subject halts (kin.speed 0) short of the crosswalk until the pedestrian has crossed, then completes its turn with no closest approach below the clearance within the horizon. -/
def permitTrace : Trace :=
  Build.trace 4 0 (Units.seconds 1) fun k t =>
    let users : List RoadUser :=
      match k with
      | 0 => [subj (m 2) (m (-16)) Build.north (mps 0), ped (m (-12)) (m (-4)) Build.north (mps 1)]
      | 1 => [subj (m 2) (m (-16)) Build.north (mps 0), ped (m (-12)) (m 4) Build.north (mps 1)]
      | 2 => [subj (m 2) (m (-8)) Build.north (mps 6), ped (m (-12)) (m 12) Build.north (mps 1)]
      | _ => [subj (m (-3)) (m 2) Build.west (mps 6), ped (m (-12)) (m 14) Build.north (mps 1)]
    Build.scene t (some 1) users worldMap [signalHead [.greenArrow .left]]

/-- `idle` (not_applicable): The signal governing the subject's approach displays circular_red. -/
def idleTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t => conflictScene [.circularRed] k t

/-- `blind` (unknown): The subject turns at a signalized intersection whose signal states are not observed by the source. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t => conflictScene [.greenArrow .left] k t

/-- `branch_1` (compliant): On the green left arrow alone the subject turns left; no other road user is in the scene. -/
def branch_1Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [turning k] worldMap [signalHead [.greenArrow .left]]

/-- `branch_2` (violated): turning on the green left arrow alone, the subject runs into another
    vehicle within the intersection (rel.contact) with no closing velocity between their centres. -/
def branch_2Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [turning k, car 3 (m (-5)) (m 2) Build.west (mps 6)] worldMap
      [signalHead [.greenArrow .left]]

/-- `branch_3` (violated): still in its approach lane, the subject keeps moving towards a
    pedestrian in the crosswalk marking that lane's own entrance. -/
def branch_3Trace : Trace :=
  Build.trace 1 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [subj (m 2) (m (-25)) Build.north (mps 6), ped (m (-1)) (m (-12)) Build.east (mps 1)]
      worldMap [signalHead [.greenArrow .left]]

/-- `branch_4` (not_applicable): the same conflict, but the signal shows the green left arrow
    together with a circular red: no green turn arrow alone. -/
def branch_4Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t => conflictScene [.greenArrow .left, .circularRed] k t

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_307_4a_o2"
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
  , witness "blind" blindTrace (.unknown []) ["dev.traffic_signal"]
  , witness "branch_1" branch_1Trace .compliant
  , witness "branch_2" branch_2Trace .violated
  , witness "branch_3" branch_3Trace .violated
  , witness "branch_4" branch_4Trace .notApplicable ]

end TrafficSpecWitness.NRS_484B_307_4a_o2
