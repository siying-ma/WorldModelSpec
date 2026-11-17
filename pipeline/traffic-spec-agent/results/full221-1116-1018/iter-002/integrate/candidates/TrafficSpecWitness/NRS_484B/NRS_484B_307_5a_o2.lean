/-
  Witnesses for NRS_484B_307_5a_o2.

  Geometry (metres, +x east, +y north), the witness's own figures:
  - intersection i (10): x ∈ [0, 8], y ∈ [-8, 8];
  - approach lane c (11): x ∈ [-40, 0], y ∈ [-4, 0], eastbound, enters i; head s (20) governs it;
  - far-side crosswalk w (12): x ∈ [8, 12], y ∈ [-6, 8], recorded as marking the entrance of
    lane cw (13): x ∈ [12, 50], y ∈ [0, 4], westbound, enters i;
  - sidewalk sw (14): x ∈ [8, 12], y ∈ [-10, -6], the corner beside w.
  Bodies: subject car 1 (half 2.3 × 0.9 m), pedestrian 2 (half 0.3 × 0.3 m), other car 3.
  Instants: k = 0, 1, 2 at 1 s spacing; the head shows circular red at k = 0 and changes at k = 1.
  The subject eastbound at y = -2: halted at x = -8.6 (k0), at 8 m/s at x = -4.6 (k1) and x = -0.6
  (k2). The pedestrian northbound at 1.2 m/s at x = 9: in w at y = -5.3, -4.1, -2.9 (forbid); at
  k2 the centres' closest approach lies 1.19 s ahead at 0.53 m (horizon 3 s, clearance 3 m).
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_307_5a_o2
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_307_5a_o2

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def carHalf : Q × Q × Q := (cm 230, cm 90, cm 75)
def pedHalf : Q × Q × Q := (cm 30, cm 30, cm 90)
def pedSpeed : Q := Units.micrometresPerSecond 1200000

def rectPts (x0 y0 x1 y1 : Q) : List Vec := [(x0, y0), (x1, y0), (x1, y1), (x0, y1)]

def intersectionI : Structure := Build.rect 10 .intersection (m 0) (m (-8)) (m 8) (m 8)
def laneC : Structure :=
  Build.lane 11 (rectPts (m (-40)) (m (-4)) (m 0) (m 0)) Build.east (enters := some 10)
def crosswalkW : Structure :=
  { Build.rect 12 .crosswalk (m 8) (m (-6)) (m 12) (m 8) with
      marked := some true, entranceOf := [13], entranceObserved := true }
def laneCW : Structure :=
  Build.lane 13 (rectPts (m 12) (m 0) (m 50) (m 4)) Build.west (enters := some 10)
def sidewalkSW : Structure := Build.rect 14 .sidewalk (m 8) (m (-10)) (m 12) (m (-6))

def structures : List Structure := [intersectionI, laneC, crosswalkW, laneCW, sidewalkSW]

def red : List SignalIndication := [.circularRed]
def arrow : List SignalIndication := [.greenArrow .straight]
def arrowAndGreen : List SignalIndication := [.circularGreen, .greenArrow .straight]
def green : List SignalIndication := [.circularGreen]

def car (x y : Q) (speed : Q) : RoadUser := Build.user 1 [.motorVehicle] (x, y) Build.east speed carHalf
def ped (y : Q) : RoadUser := Build.user 2 [.pedestrian] (cm 900, y) Build.north pedSpeed pedHalf

def scn (t : Timestamp) (shows : List SignalIndication) (users : List RoadUser) : Scene :=
  Build.scene t (some 1) users structures [Build.signal 20 [11] shows]

/-- The subject leaves its halt at the change and proceeds at 8 m/s, still in c at k2. -/
def carStraight (k : Nat) : RoadUser :=
  match k with
  | 0 => car (cm (-860)) (cm (-200)) Q.zero
  | 1 => car (cm (-460)) (cm (-200)) (Units.metresPerSecond 8)
  | _ => car (cm (-60)) (cm (-200)) (Units.metresPerSecond 8)

/-- Pedestrian in the crosswalk at every instant. -/
def pedInCrosswalk (k : Nat) : RoadUser :=
  match k with
  | 0 => ped (cm (-530))
  | 1 => ped (cm (-410))
  | _ => ped (cm (-290))

/-- Pedestrian on the sidewalk at k0 and k1, in the crosswalk at k2. -/
def pedLate (k : Nat) : RoadUser :=
  match k with
  | 0 => ped (cm (-770))
  | 1 => ped (cm (-650))
  | _ => ped (cm (-530))

def redThen (then_ : List SignalIndication) (k : Nat) : List SignalIndication :=
  if k == 0 then red else then_

/-- `forbid` (violated): Head s governing lane c, which enters i, changes to green_arrow(straight) alone while a pedestrian walks at 1.2 m/s in the crosswalk marking the entrance of the far-side approach of i; the car leaves its halt and proceeds straight at 8 m/s, the closest approach of the two centres lying 1.2 s ahead at 0.5 m, while the pedestrian is still in that crosswalk. -/
def forbidTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    scn t (redThen arrow k) [carStraight k, pedInCrosswalk k]

/-- `permit` (compliant): Same arrow; no other road user is in the scene; the car proceeds straight through i. The duty binds the subject alone and is met. -/
def permitTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    let c := match k with
      | 0 => car (cm (-860)) (cm (-200)) Q.zero
      | 1 => car (cm (-460)) (cm (-200)) (Units.metresPerSecond 8)
      | _ => car (cm 300) (cm (-200)) (Units.metresPerSecond 8)
    scn t (redThen arrow k) [c]

/-- `idle` (not_applicable): s displays circular_green alone while the car proceeds through i. -/
def idleTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    let c := match k with
      | 0 => car (cm (-860)) (cm (-200)) (Units.metresPerSecond 8)
      | 1 => car (cm (-60)) (cm (-200)) (Units.metresPerSecond 8)
      | _ => car (cm 300) (cm (-200)) (Units.metresPerSecond 8)
    scn t green [c]

/-- `blind` (unknown): As forbid, but the source does not record which carriers' entrances the pedestrian's crosswalk marks: whether it is an adjacent crosswalk is unknown. -/
def blindTrace : Trace := forbidTrace

/-- `branch_1` (compliant): As forbid, but the pedestrian was on the sidewalk when s's arrow came on and stepped into the crosswalk afterwards: it was not within the crosswalk at the time the signal was exhibited, so no yield is owed to it under this paragraph and the subject complies. -/
def branch_1Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    scn t (redThen arrow k) [carStraight k, pedLate k]

/-- `branch_2` (violated): the car, halted in c when the arrow comes on, enters i at k2 at 4 m/s
    toward car 3, stalled in i since before the change: it faces s from inside i (entered from c)
    and the closest approach lies 1.25 s ahead at 0 m. -/
def branch_2Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    let c := match k with
      | 0 => car (cm (-860)) (cm (-200)) Q.zero
      | 1 => car (cm (-300)) (cm (-200)) Q.zero
      | _ => car (cm 100) (cm (-200)) (Units.metresPerSecond 4)
    let other := Build.user 3 [.motorVehicle] (m 6, cm (-200)) Build.east Q.zero carHalf
    scn t (redThen arrow k) [c, other]

/-- `branch_3` (compliant): the car stays halted in c after the arrow comes on while car 3 crosses
    i westbound at 3 m/s past its front: the closest approach is within the horizon and below the
    clearance, but the subject does not move and the bodies do not touch. -/
def branch_3Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    let x3 : Q := match k with
      | 0 => cm 750
      | 1 => cm 450
      | _ => cm 150
    let other := Build.user 3 [.motorVehicle] (x3, cm 50) Build.west (Units.metresPerSecond 3) carHalf
    scn t (redThen arrow k) [car (cm (-300)) (cm (-200)) Q.zero, other]

/-- `branch_4` (not_applicable): as forbid, but the head shows circular green together with the
    straight-through green arrow: the arrow is not shown alone. -/
def branch_4Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    scn t (redThen arrowAndGreen k) [carStraight k, pedInCrosswalk k]

/-- `branch_5` (violated): the head shows circular green with the arrow at k1 (pedestrian on the
    sidewalk) and the arrow alone from k2 (pedestrian in the crosswalk): the arrow alone is exhibited
    at k2, the pedestrian is within the crosswalk then, and the car's approach conflicts with it. -/
def branch_5Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    let shows := match k with
      | 0 => red
      | 1 => arrowAndGreen
      | _ => arrow
    scn t shows [carStraight k, pedLate k]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_307_5a_o2"
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
  , witness "blind" blindTrace (.unknown []) ["st.entrance_of"]
  , witness "branch_1" branch_1Trace .compliant
  , witness "branch_2" branch_2Trace .violated
  , witness "branch_3" branch_3Trace .compliant
  , witness "branch_4" branch_4Trace .notApplicable
  , witness "branch_5" branch_5Trace .violated ]

end TrafficSpecWitness.NRS_484B_307_5a_o2
