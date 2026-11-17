/-
  Witnesses for NRS_484B_363_3.

  Geometry (the witness's own figures; none appears in the rule). A two-way street along x:
  eastbound lanes 10 (x −100…100) and 12 (x 100…300), y 0…4 m; westbound lanes 11 and 13 above them,
  y 4…8 m; a sidewalk 14 along y −3…0 m. The school zone sign 20 (kind school unless stated, not an
  end sign) governs the lanes it lists; its legend states school hours, weekdays 07:30–16:00. The
  speed limit beacon 21, where built, governs all four lanes.

  Instants: 30 scenes at 1 s spacing (0 … 29 s). Each witness speaks of 11 … 29 s, where every window
  of 10 s behind is covered. The U-turn: the vehicle (track 1) drives east at y 2 m, yaws at 90 deg/s
  at the scenes of 12 s (heading north, at y 3.5 m in the eastbound lane) and 13 s (heading west, at
  y 6 m in the westbound lane): a 180 deg reversal, under way at those two scenes; it drives west
  from 14 s, where the U-turn is recognised (yaw rate 0). "First turning observation" is 12 s,
  "later" is 13 s. It turns about x = 40 m (lanes 10/11) unless stated. The permitted vehicle drives
  east in lane 10 with a jog (+90 then −90 deg/s at 12 s and 13 s, net heading change 0).
  Headings follow the yaw rate held over the interval before each scene.

  The child (track 2) stands at x 50 m: near at y −1.5 m (1.25 m from lane 10, within the 3 m reach),
  beyond the reach at y −7 m, far at y −10 m. Civil time: Tuesday; 08:00 is within the legend's
  hours, 16:40 is not. Declarations: school-session day true, outside-operation margin false,
  pupils in class true.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_363_3
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_363_3

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def allLanes : List RegionId := [10, 11, 12, 13]

def structures : List Structure :=
  [ Build.rect 10 .lane (m (-100)) (m 0) (m 100) (m 4)
  , Build.rect 11 .lane (m (-100)) (m 4) (m 100) (m 8)
  , Build.rect 12 .lane (m 100) (m 0) (m 300) (m 4)
  , Build.rect 13 .lane (m 100) (m 4) (m 300) (m 8)
  , Build.rect 14 .sidewalk (m (-100)) (m (-3)) (m 300) (m 0) ]

def vExtent : Q × Q × Q := (cm 240, cm 90, cm 75)

def car (pos : Vec) (h : Vec) (v : Q) (yaw : Option Q) : RoadUser :=
  Build.withKin (Build.user 1 [.motorVehicle] pos h v vExtent) (fun k => { k with yawRate := yaw })

/-- A U-turn about x = xc: east in lane 10/12 up to 11 s, yawing 90 deg/s over the intervals ending
    at 12 s (heading north, still in the eastbound lane) and 13 s (heading west, in the westbound
    lane), straight west from 14 s, where it is recognised. `yaw` false leaves the yaw rate
    unobserved. -/
def uTurnCar (xc : Int) (yaw : Bool) (k : Nat) : RoadUser :=
  let ω : Option Q :=
    if yaw then some (if 12 ≤ k ∧ k ≤ 13 then Units.degrees 90 else Q.zero) else none
  if k ≤ 11 then
    car (m (xc - 5 * (11 - (k : Int))), cm 200) Build.east (Units.metresPerSecond 5) ω
  else if k = 12 then
    car (m (xc + 2), cm 350) Build.north (Units.metresPerSecond 3) ω
  else if k = 13 then
    car (m xc, cm 600) Build.west (Units.metresPerSecond 3) ω
  else
    car (m (xc - 2 * ((k : Int) - 13)), cm 600) Build.west (Units.metresPerSecond 2) ω

/-- Through lane 10 with a jog: 90 deg/s left over the interval ending at 12 s, 90 deg/s right over
    the one ending at 13 s; turning at those scenes, net heading change zero, never reversing. -/
def straightCar (k : Nat) : RoadUser :=
  let ω : Q :=
    if k = 12 then Units.degrees 90
    else if k = 13 then Units.degrees (-90) else Q.zero
  if k ≤ 11 then
    car (m (3 * (k : Int)), cm 150) Build.east (Units.metresPerSecond 3) (some ω)
  else if k = 12 then
    car (m 33, cm 250) Build.north (Units.metresPerSecond 1) (some ω)
  else
    car (m (3 * (k : Int) - 3), cm 250) Build.east (Units.metresPerSecond 3) (some ω)

def child (y : Int) : RoadUser :=
  Build.user 2 [.pedestrian, .child] (m 50, cm y) Build.north Q.zero (cm 25, cm 25, cm 60)

def near : Int := -150
def beyond : Int := -700
def far : Int := -1000

def schoolHours : Conditions :=
  { windows := [{ weekdays := [0, 1, 2, 3, 4], startMinute := 450, endMinute := 960 }] }

def zone (kind : ZoneKind) (gov : List RegionId) : Device :=
  Build.zoneSign 20 gov kind false (some schoolHours)

def beacon (inop flash : Bool) : Device :=
  { Build.device 21 .speedLimitBeacon allLanes with inoperative := some inop, flashing := some flash }

def inHours : Nat := 480
def afterHours : Nat := 1000

def clock (minute : Nat) : Env :=
  { civilTime := some { year := 2026, month := 3, day := 10, weekday := 1, minuteOfDay := minute } }

def declared : List (AsmId × Bool) :=
  [ ("asm.school_in_session_day", true)
  , ("asm.school_outside_operation_margin", false)
  , ("asm.pupils_in_class", true) ]

def mk (veh : Nat → RoadUser) (childY : Nat → Int) (devs : Nat → List Device)
    (minute : Nat → Nat) : Trace :=
  Build.trace 30 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [veh k, child (childY k)] structures (devs k)
      (env := clock (minute k)) (assumptions := declared)

def schoolZone : Nat → List Device := fun _ => [zone .school allLanes]

/-- `forbid` (violated): A vehicle on a lane governed by a dev.zone_sign of kind school (not an end sign, conditions holding) reverses its heading within the window (kin.yaw_rate integrated into the reversal band, then below tolerance); a ru.child stands on the sidewalk beside the lane, within the reach; asm.school_in_session_day true, asm.school_outside_operation_margin false; no beacon governs the lane. -/
def forbidTrace : Trace :=
  mk (uTurnCar 40 true) (fun _ => near) schoolZone (fun _ => inHours)

/-- `permit` (compliant): Same zone, child and declarations as forbid; the vehicle drives straight through the zone and makes no U-turn (heading change below the reversal band). -/
def permitTrace : Trace :=
  mk straightCar (fun _ => near) schoolZone (fun _ => inHours)

/-- `idle` (not_applicable): The vehicle makes a U-turn on a street no dev.zone_sign of kind school or school_crossing governs; a ru.child stands nearby. (The street's only zone sign is a speed zone.) -/
def idleTrace : Trace :=
  mk (uTurnCar 40 true) (fun _ => near) (fun _ => [zone .speedZone allLanes]) (fun _ => inHours)

/-- `blind` (unknown): Same as forbid, but the source declares kin.yaw_rate absent, so neither the U-turn nor the moment it is under way is decided. -/
def blindTrace : Trace :=
  mk (uTurnCar 40 false) (fun _ => near) schoolZone (fun _ => inHours)

/-- `branch_1` (not_applicable): Same as forbid but no ru.child is within the reach of any region the zone sign governs at any observation while the U-turn is under way: exception (a) holds. -/
def branch_1Trace : Trace :=
  mk (uTurnCar 40 true) (fun _ => far) schoolZone (fun _ => inHours)

/-- `branch_2` (not_applicable): A school_crossing zone sign governs the lane; a beacon that is not inoperative governs it and is not flashing; asm.pupils_in_class true; a child is present; the vehicle makes a U-turn: exception (d) holds. -/
def branch_2Trace : Trace :=
  mk (uTurnCar 40 true) (fun _ => near)
    (fun _ => [zone .schoolCrossing allLanes, beacon false false]) (fun _ => inHours)

/-- `branch_3` (not_applicable): No beacon governs the zone's lane; prim.conditions_hold is false for the zone sign throughout the U-turn; a child is present: exception (e) holds. -/
def branch_3Trace : Trace :=
  mk (uTurnCar 40 true) (fun _ => near) schoolZone (fun _ => afterHours)

/-- `occasion_s3` (violated): The vehicle begins its U-turn (yaw rate above tolerance) while its footprint overlaps a lane the school zone sign governs and completes it on a lane the sign does not govern; a child is present and no other exception holds. (The sign governs lane 10 only.) -/
def occasion_s3Trace : Trace :=
  mk (uTurnCar 40 true) (fun _ => near) (fun _ => [zone .school [10]]) (fun _ => inHours)

/-- `occasion_s3_outside` (not_applicable): The vehicle occupies the zone's lane only before it begins turning; it leaves the zone and makes the whole U-turn on regions no zone sign governs. (The sign governs lanes 10/11; the turn is about x = 152 m in lanes 12/13.) -/
def occasion_s3_outsideTrace : Trace :=
  mk (uTurnCar 152 true) (fun _ => near) (fun _ => [zone .school [10, 11]]) (fun _ => inHours)

/-- `occasion_s5` (violated): A ru.child is within the reach of the zone's lane when the U-turn begins and has walked beyond the reach before it ends; no other exception holds: exception (a) does not hold throughout. -/
def occasion_s5Trace : Trace :=
  mk (uTurnCar 40 true) (fun k => if k ≤ 12 then near else beyond) schoolZone (fun _ => inHours)

/-- `occasion_s5_outside` (not_applicable): A ru.child is within the reach only before the U-turn begins; no child is within the reach at any observation while the U-turn is under way: exception (a) holds throughout. -/
def occasion_s5_outsideTrace : Trace :=
  mk (uTurnCar 40 true) (fun k => if k < 12 then near else beyond) schoolZone (fun _ => inHours)

/-- `occasion_s8` (violated): A beacon governs the zone's lane, not flashing, with asm.pupils_in_class true; it is not inoperative at the first turning observations and inoperative at the later ones, while the zone sign's conditions hold; a child is present: neither (d) nor (e) holds throughout. -/
def occasion_s8Trace : Trace :=
  mk (uTurnCar 40 true) (fun _ => near)
    (fun k => [zone .school allLanes, beacon (decide (13 ≤ k)) false]) (fun _ => inHours)

/-- `occasion_s8_outside` (not_applicable): The beacon is inoperative before the U-turn begins and operational, not flashing, at every observation while it is under way, with asm.pupils_in_class true: exception (d) holds throughout. -/
def occasion_s8_outsideTrace : Trace :=
  mk (uTurnCar 40 true) (fun _ => near)
    (fun k => [zone .school allLanes, beacon (decide (k < 12)) false]) (fun _ => inHours)

/-- `occasion_s10` (violated): An operational beacon governs the lane with asm.pupils_in_class true; it is not flashing at the first turning observations and flashing at the later ones; a child is present and no other exception holds. -/
def occasion_s10Trace : Trace :=
  mk (uTurnCar 40 true) (fun _ => near)
    (fun k => [zone .school allLanes, beacon false (decide (13 ≤ k))]) (fun _ => inHours)

/-- `occasion_s10_outside` (not_applicable): The operational beacon is flashing before the U-turn begins and not flashing at every observation while it is under way, with asm.pupils_in_class true: exception (d) holds throughout. -/
def occasion_s10_outsideTrace : Trace :=
  mk (uTurnCar 40 true) (fun _ => near)
    (fun k => [zone .school allLanes, beacon false (decide (k < 12))]) (fun _ => inHours)

/-- `occasion_s11` (violated): The beacon governing the lane is inoperative at the first turning observations and operational and flashing at the later ones; the zone sign's conditions do not hold throughout; a child is present: neither (d) nor (e) holds throughout. -/
def occasion_s11Trace : Trace :=
  mk (uTurnCar 40 true) (fun _ => near)
    (fun k => [zone .school allLanes, beacon (decide (k ≤ 12)) true]) (fun _ => afterHours)

/-- `occasion_s11_outside` (not_applicable): The beacon governing the lane is operational before the U-turn begins and inoperative at every observation while it is under way; prim.conditions_hold is false for the zone sign throughout: exception (e) holds throughout. -/
def occasion_s11_outsideTrace : Trace :=
  mk (uTurnCar 40 true) (fun _ => near)
    (fun k => [zone .school allLanes, beacon (decide (12 ≤ k)) true]) (fun _ => afterHours)

/-- `occasion_s12` (violated): No beacon governs the lane; prim.conditions_hold for the zone sign is false at the first turning observations and true at the later ones (its posted window opens mid-turn); a child is present. -/
def occasion_s12Trace : Trace :=
  mk (uTurnCar 40 true) (fun _ => near) schoolZone
    (fun k => if k ≤ 12 then 449 else 450)

/-- `occasion_s12_outside` (not_applicable): No beacon governs the lane; prim.conditions_hold is true before the U-turn begins and false at every observation while it is under way: exception (e) holds throughout. -/
def occasion_s12_outsideTrace : Trace :=
  mk (uTurnCar 40 true) (fun _ => near) schoolZone
    (fun k => if k < 12 then 959 else 960)

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_363_3"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("subject", 1)]
    expected := expected
    window := some (11000, 29000)
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["kin.yaw_rate"]
  , witness "branch_1" branch_1Trace .notApplicable
  , witness "branch_2" branch_2Trace .notApplicable
  , witness "branch_3" branch_3Trace .notApplicable
  , witness "occasion_s3" occasion_s3Trace .violated
  , witness "occasion_s3_outside" occasion_s3_outsideTrace .notApplicable
  , witness "occasion_s5" occasion_s5Trace .violated
  , witness "occasion_s5_outside" occasion_s5_outsideTrace .notApplicable
  , witness "occasion_s8" occasion_s8Trace .violated
  , witness "occasion_s8_outside" occasion_s8_outsideTrace .notApplicable
  , witness "occasion_s10" occasion_s10Trace .violated
  , witness "occasion_s10_outside" occasion_s10_outsideTrace .notApplicable
  , witness "occasion_s11" occasion_s11Trace .violated
  , witness "occasion_s11_outside" occasion_s11_outsideTrace .notApplicable
  , witness "occasion_s12" occasion_s12Trace .violated
  , witness "occasion_s12_outside" occasion_s12_outsideTrace .notApplicable ]

end TrafficSpecWitness.NRS_484B_363_3
