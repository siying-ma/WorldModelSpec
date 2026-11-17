/-
  Witnesses for NRS_484B_307_2a.

  The map (static, every scene; +x east, +y north, metres):
    region 10  intersection, square (0,0)–(20,20);
    region 11  lane, northbound approach from the south, x 10..20, y −40..0, enters 10;
    region 12  lane, eastbound approach from the west, x −40..−4, y 0..10, enters 10;
    region 13  crosswalk across the west leg, x −4..0, y 0..20, marking the entrance of 12
               (entrances observed).
  Device 1: a traffic signal governing lane 11; its indications are the scenario's.
  Bodies: track 1 the subject, a motor vehicle (half-extents 2.4 × 1.0 × 0.8 m); track 2 a
  pedestrian (0.3 × 0.3 × 0.9 m); track 3 an oncoming motor vehicle (as the subject). Scenes are
  1 s apart; velocities follow the headings.

  forbid: the subject is in lane 11 (15,−5) northbound at 6 m/s, then in the intersection heading
  west at 6 m/s at (7,12) and (1,12), while the pedestrian walks north at 1 m/s in crosswalk 13
  at (−2, 8.5 / 9.5 / 10.5). At t = 1 s and 2 s the centres close to about 0.99 m in 1.53 s and
  0.53 s (horizon 3 s, clearance 3 m): violated. At t = 0 they approach in 2.7 s but only to 17 m.
  permit: the subject enters at 6 then 3 m/s, halts (speed 0) at (10,11) for three scenes while
  the pedestrian walks north at 1.5 m/s from (−2,14) to (−2,20), then moves west at 4 and 6 m/s
  once the pedestrian has left the crosswalk (y 21.5, 23). While moving with the pedestrian in
  the crosswalk the centres do not approach within 3 s (4.2 s, 6.3 s): compliant.
  idle / blind / branch_2: the forbid geometry with the signal showing circular_red, its states
  masked, and circular_green with green_arrow(left).
  branch_1: the subject alone, straight north at 6 m/s through lane 11 into the intersection.
  branch_3: the subject turns west at 7 m/s at (14,6) and (7,6) while the oncoming vehicle,
  southbound at 5 m/s inside the intersection at (6.6,13.4) and (6.6,8.4), closes to about 1.72 m
  in 1.2 s and 0.2 s: violated.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_307_2a
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_307_2a

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def carExt : Q × Q × Q := (cm 240, m 1, cm 80)
def pedExt : Q × Q × Q := (cm 30, cm 30, cm 90)

def intersection : Structure := Build.rect 10 .intersection (m 0) (m 0) (m 20) (m 20)
def laneSouth : Structure :=
  Build.lane 11 [(m 10, m (-40)), (m 20, m (-40)), (m 20, m 0), (m 10, m 0)] Build.north (enters := some 10)
def laneWest : Structure :=
  Build.lane 12 [(m (-40), m 0), (m (-4), m 0), (m (-4), m 10), (m (-40), m 10)] Build.east (enters := some 10)
def crosswalkWest : Structure :=
  { Build.rect 13 .crosswalk (m (-4)) (m 0) (m 0) (m 20) with
    entranceOf := [12], entranceObserved := true, marked := some true }

def structures : List Structure := [intersection, laneSouth, laneWest, crosswalkWest]

def signal (shows : List SignalIndication) : Device := Build.signal 1 [11] shows

def car (track : TrackId) (x y : Q) (h : Vec) (v : Q) : RoadUser :=
  Build.user track [.motorVehicle] (x, y) h v carExt
def ped (x y : Q) (v : Q) : RoadUser :=
  Build.user 2 [.pedestrian] (x, y) Build.north v pedExt

/-- The forbid geometry: subject turning west through the intersection, pedestrian in the
    crosswalk ahead of it. -/
def forbidUsers (k : Nat) : List RoadUser :=
  match k with
  | 0 => [car 1 (m 15) (m (-5)) Build.north (m 6), ped (m (-2)) (cm 850) (m 1)]
  | 1 => [car 1 (m 7) (m 12) Build.west (m 6), ped (m (-2)) (cm 950) (m 1)]
  | _ => [car 1 (m 1) (m 12) Build.west (m 6), ped (m (-2)) (cm 1050) (m 1)]

def forbidLike (shows : List SignalIndication) : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) (forbidUsers k) structures [signal shows]

/-- `forbid` (violated): The subject vehicle occupies an approach lane entering an intersection whose dev.traffic_signal (dev.governs the lane) displays circular_green alone; it turns left into the intersection at 6 m/s while a pedestrian (ru.aggregate pedestrian) walks in the crosswalk that marks the entrance of the cross street's approach (st.entrance_of); prim.closest_approach_within holds with a closest centre distance of 1.0 m in 1.5 s, and the subject keeps moving. -/
def forbidTrace : Trace := forbidLike [.circularGreen]

/-- `permit` (compliant): The same subject halts (kin.speed 0) inside the intersection until the pedestrian has crossed, then completes its turn with no closest approach below the clearance within the horizon. -/
def permitUsers (k : Nat) : List RoadUser :=
  match k with
  | 0 => [car 1 (m 15) (m (-5)) Build.north (m 6), ped (m (-2)) (m 14) (cm 150)]
  | 1 => [car 1 (m 13) (m 6) Build.north (m 3), ped (m (-2)) (cm 1550) (cm 150)]
  | 2 => [car 1 (m 10) (m 11) Build.west (m 0), ped (m (-2)) (m 17) (cm 150)]
  | 3 => [car 1 (m 10) (m 11) Build.west (m 0), ped (m (-2)) (cm 1850) (cm 150)]
  | 4 => [car 1 (m 10) (m 11) Build.west (m 0), ped (m (-2)) (m 20) (cm 150)]
  | 5 => [car 1 (m 10) (m 11) Build.west (m 4), ped (m (-2)) (cm 2150) (cm 150)]
  | _ => [car 1 (m 4) (m 11) Build.west (m 6), ped (m (-2)) (m 23) (cm 150)]

def permitTrace : Trace :=
  Build.trace 7 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) (permitUsers k) structures [signal [.circularGreen]]

/-- `idle` (not_applicable): The signal governing the subject's approach displays circular_red. -/
def idleTrace : Trace := forbidLike [.circularRed]

/-- `blind` (unknown): The subject drives through a signalized intersection whose signal states are not observed by the source. -/
def blindTrace : Trace := forbidLike [.circularGreen]

/-- `branch_1` (compliant): The subject proceeds straight through on circular green alone; no other road user is in the scene. -/
def branch_1Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [car 1 (m 15) (Q.add (m (-5)) (Q.mul (m 6) (Q.ofInt (Int.ofNat k)))) Build.north (m 6)]
      structures [signal [.circularGreen]]

/-- `branch_2` (not_applicable): The signal governing the subject's approach displays circular_green together with green_arrow(left): the green is not alone. -/
def branch_2Trace : Trace := forbidLike [.circularGreen, .greenArrow .left]

/-- `branch_3` (violated): On circular green alone, the subject turns left at 7 m/s across the path of an oncoming vehicle already within the intersection; prim.closest_approach_within holds with a closest centre distance of 1.5 m in 1.2 s. -/
def branch_3Users (k : Nat) : List RoadUser :=
  match k with
  | 0 => [car 1 (m 15) (m (-5)) Build.north (m 7), car 3 (cm 660) (cm 1840) Build.south (m 5)]
  | 1 => [car 1 (m 14) (m 6) Build.west (m 7), car 3 (cm 660) (cm 1340) Build.south (m 5)]
  | _ => [car 1 (m 7) (m 6) Build.west (m 7), car 3 (cm 660) (cm 840) Build.south (m 5)]

def branch_3Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) (branch_3Users k) structures [signal [.circularGreen]]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_307_2a"
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
  , witness "branch_2" branch_2Trace .notApplicable
  , witness "branch_3" branch_3Trace .violated ]

end TrafficSpecWitness.NRS_484B_307_2a
