/-
  Witnesses for NRS_484B_363_3.

  Carriageway (axis-aligned rectangles, metres): lanes 10 (x 0…100, y 0…4, eastbound) and 11
  (y 4…8, westbound), with shoulder 17 (y 8…12) north of lane 11, the stretch beside the school;
  lanes 12 and 13 continue lanes 10 and 11 east of x = 100, lanes 15 and 16 west of x = 0.

  Instants: 36 scenes 1 s apart (t = 0 … 35 s). x (track 1, a motor vehicle 4.5 m × 1.8 m) runs at
  4 m/s. It drives east along y = 3 until 26 s, yaws at 90 °/s at 27 s and 28 s (the rate held over
  the second before each scene) and 0 °/s elsewhere: its heading is east until 26 s, north at
  27 s, west from 28 s, and each position is the one before plus the velocity of the scene — at
  27 s it stands at (X, 7) heading north, from 28 s it runs west along y = 7. X, the turning point,
  is 50 m unless a witness says otherwise. Its heading change over the 20 s U-turn window is 90° at
  27 s (90° short of the half turn, beyond the 30° tolerance) and 180° at 28 s: the U-turn is
  recognized at 28 s, and its act is the yawing observations, 27 s and 28 s (90 °/s is far above
  the 2 °/s resolution, 0 °/s at it). Every witness speaks of 21 … 35 s, where the 20 s windows
  behind the instant and the one before it are covered.

  Occupancy is read from each body's footprint (its box, every body heading along an axis): at
  27 s x heading north overlaps lane 11 and shoulder 17, at 28 s heading west lane 11 alone.

  Track 2 is a child (a pedestrian, 0.4 m × 0.4 m), standing on shoulder 17 at (50, 10), 1.8 m from
  lane 11, inside the 5 m reach; where it stands away, it is at (50, 16), 7.8 m from lane 11, or
  at (150, 10), 1.8 m from lane 13, which no school zone sign governs, and about 50 m from the zone.
  A child that moves does so at 6 m/s within one second. The zone sign is device 100, the beacon
  device 101; a sign with posted hours shows 7:00 to 16:00 on every day. Every figure here is the
  witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_363_3
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_363_3

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: x ↦ 1

def steps : Nat := 36

/-- x's yaw rate: the U-turn at 27 s and 28 s. -/
def yawAt (k : Nat) : Q := if k = 27 ∨ k = 28 then Units.degrees 90 else Q.zero

/-- An axis-aligned rectangular region. -/
structure Box where
  id : RegionId
  kind : StructureKind
  x0 : Q
  y0 : Q
  x1 : Q
  y1 : Q

def boxes : List Box :=
  [ ⟨10, .lane, m 0, m 0, m 100, m 4⟩
  , ⟨11, .lane, m 0, m 4, m 100, m 8⟩
  , ⟨12, .lane, m 100, m 0, m 200, m 4⟩
  , ⟨13, .lane, m 100, m 4, m 200, m 8⟩
  , ⟨15, .lane, m (-100), m 0, m 0, m 4⟩
  , ⟨16, .lane, m (-100), m 4, m 0, m 8⟩
  , ⟨17, .shoulder, m 0, m 8, m 100, m 12⟩ ]

def roads : List Structure := boxes.map fun b => Build.rect b.id b.kind b.x0 b.y0 b.x1 b.y1

/-- The regions a body's footprint overlaps (with positive area); every body heads along an axis. -/
def occupied (u : RoadUser) : List (TrackId × RegionId) :=
  match u.kin.position, u.kin.heading, u.kin.extent with
  | some (px, py), some h, some (hl, hw, _) =>
    let ax := if Q.isZero h.1 then hw else hl
    let ay := if Q.isZero h.1 then hl else hw
    boxes.filterMap fun b =>
      if Q.lt b.x0 (Q.add px ax) && Q.lt (Q.sub px ax) b.x1 && Q.lt b.y0 (Q.add py ay) && Q.lt (Q.sub py ay) b.y1
      then some (u.track, b.id) else none
  | _, _, _ => []

/-- x's position and heading at k, for a turn at (X, 7). -/
def xPose (X : Q) (k : Nat) : Vec × Vec :=
  if k ≤ 26 then ((Q.sub X (Q.mul (m 4) (Q.ofInt (Int.ofNat (26 - k)))), m 3), Build.east)
  else if k = 27 then ((X, m 7), Build.north)
  else ((Q.sub X (Q.mul (m 4) (Q.ofInt (Int.ofNat (k - 27)))), m 7), Build.west)

def nearChild : Vec := (m 50, m 10)
def awayChild : Vec := (m 50, m 16)
def farChild : Vec := (m 150, m 10)

def schoolZone (gov : List RegionId) (conds : Option Conditions) : Device :=
  Build.zoneSign 100 gov .school false conds
def beaconOn (gov : List RegionId) (flashing : Bool) : Device :=
  { (Build.device 101 .speedLimitBeacon gov) with flashing := some flashing }
/-- The legend's posted hours: 7:00 to 16:00, every day. -/
def postedHours : Conditions := { windows := [{ startMinute := 420, endMinute := 960 }] }
def clock (minute : Nat) : Option CivilTime :=
  some { year := 2026, month := 11, day := 11, weekday := 2, minuteOfDay := minute }

/-- The baseline is `forbid`: a child near, school in session, inside the operation margin,
    pupils in class, a flashing beacon governing the zone's lanes, the sign unconditional. -/
structure Setup where
  xClasses : List RoadUserClass := [.motorVehicle]
  turnX : Q := m 50
  childClasses : List RoadUserClass := [.pedestrian, .child]
  /-- The child's position, heading and speed at k. -/
  child : Nat → Vec × Vec × Q := fun _ => (nearChild, Build.north, Q.zero)
  zones : List Device := [schoolZone [10, 11] (some {})]
  beacons : Nat → List Device := fun _ => [beaconOn [10, 11] true]
  civil : Nat → Option CivilTime := fun _ => none
  notInSession : Bool := false
  outsideMargin : Bool := false
  pupilsInClass : Bool := true

def build (s : Setup) : Trace :=
  Build.trace steps 0 (Units.seconds 1) fun k t =>
    let (xp, xh) := xPose s.turnX k
    let x := Build.withKin
      (Build.user 1 s.xClasses xp xh (Units.metresPerSecond 4) (cm 225, cm 90, cm 75))
      fun kin => { kin with yawRate := some (yawAt k) }
    let (cp, ch, cv) := s.child k
    let c := Build.user 2 s.childClasses cp ch cv (cm 20, cm 20, cm 60)
    Build.scene t (some 1) [x, c] roads (s.zones ++ s.beacons k) (some (occupied x ++ occupied c))
      { civilTime := s.civil k }
      [ ("asm.school_not_in_session_day", s.notInSession)
      , ("asm.outside_school_operation_margin", s.outsideMargin)
      , ("asm.pupils_in_class", s.pupilsInClass) ]

/-- `forbid` (violated): x (ru.motor_vehicle) makes a U-turn on a lane governed by a school zone sign z; a ru.child stands within p.child_presence_reach of z's lane at every observation, asm.school_not_in_session_day and asm.outside_school_operation_margin are declared false, and a speed limit beacon governing the lane is flashing. -/
def forbidTrace : Trace := build {}

/-- `permit` (compliant): x makes a U-turn on z's lane while no ru.child lies within p.child_presence_reach of any region z governs at any observation of the act. The child stands beside lane 13, outside the zone. -/
def permitTrace : Trace := build { child := fun _ => (farChild, Build.north, Q.zero) }

/-- `idle` (not_applicable): x makes a U-turn on a street no school zone or school crossing zone sign governs. The sign governs lanes 12 and 13 only. -/
def idleTrace : Trace := build { zones := [schoolZone [12, 13] (some {})] }

/-- `blind` (unknown): x drives along z's lane with children on the sidewalk and turns about, but its yaw rate is missing, so whether a U-turn was made is unknown. -/
def blindTrace : Trace := Build.masked (Build.manifest ["kin.yaw_rate"]) forbidTrace

/-- `occasion_d3` (violated): Baseline as in forbid (children present, school in session, inside the operation margin, beacon flashing): x begins its U-turn on z's lane and completes it on a lane beyond the stretch z governs; it occupied z's lane for part of the act only. Turning at x = 1 m, it is on lane 11 at 27 s and on lane 16 alone at 28 s. -/
def occasion_d3Trace : Trace := build { turnX := m 1 }

/-- `occasion_d3_outside` (not_applicable): x drove along z's lane, left the governed stretch, and only afterwards, on a lane no zone sign governs, makes its U-turn: it was in the zone before the act began only. Turning at x = 110 m, it leaves lane 10 after 24 s and turns on lane 13. -/
def occasion_d3_outsideTrace : Trace := build { turnX := m 110 }

/-- `occasion_d5` (violated): U-turn on z's lane; no ru.child is within p.child_presence_reach at the first observations of the act, then a child walks up beside the lane before the act is recognized; the other alternatives fail throughout. The child is 7.8 m away until 27 s and 1.8 m from 28 s. -/
def occasion_d5Trace : Trace :=
  build { child := fun k =>
            if k ≤ 27 then (awayChild, Build.south, Q.zero)
            else if k = 28 then (nearChild, Build.south, Units.metresPerSecond 6)
            else (nearChild, Build.south, Q.zero) }

/-- `occasion_d5_outside` (compliant): Children stood beside z's lane before the act began and left; at every observation of the U-turn none lies within p.child_presence_reach; the other alternatives fail. The child is 1.8 m away until 26 s and 7.8 m from 27 s. -/
def occasion_d5_outsideTrace : Trace :=
  build { child := fun k =>
            if k ≤ 26 then (nearChild, Build.north, Q.zero)
            else if k = 27 then (awayChild, Build.north, Units.metresPerSecond 6)
            else (awayChild, Build.north, Q.zero) }

/-- `occasion_d8` (violated): A beacon governs the region x occupies at the start of the U-turn only; x ends the turn on a region no beacon governs; asm.pupils_in_class holds and the beacon is not flashing; z's conditions hold; children present, school in session, inside the margin: neither (d) nor (e) covers the whole act. The beacon governs shoulder 17, which x overlaps at 27 s and not at 28 s. -/
def occasion_d8Trace : Trace := build { beacons := fun _ => [beaconOn [17] false] }

/-- `occasion_d8_outside` (compliant): No beacon governs the region x occupied before the act; a non-flashing beacon governs every region x occupies during the U-turn and asm.pupils_in_class holds throughout it; children present. z governs lane 10 and shoulder 17, the beacon lane 11: x is on lanes 15 and 10 before the act and on lane 11 throughout it. -/
def occasion_d8_outsideTrace : Trace :=
  build { zones := [schoolZone [10, 17] (some {})]
          beacons := (fun _ => [beaconOn [11] false]) }

/-- `occasion_d10` (violated): A beacon governs z's lane and asm.pupils_in_class holds throughout; the beacon is not flashing for the first part of the U-turn and flashing for the rest; children present. The beacon governs lane 10; it flashes from 28 s. -/
def occasion_d10Trace : Trace := build { beacons := fun k => [beaconOn [10] (28 ≤ k)] }

/-- `occasion_d10_outside` (compliant): A beacon governs z's lane and asm.pupils_in_class holds throughout; the beacon was flashing before the act and is not flashing at any observation of the U-turn; children present. The beacon governs lane 10, where x is not during the act; it flashes until 26 s. -/
def occasion_d10_outsideTrace : Trace := build { beacons := fun k => [beaconOn [10] (k ≤ 26)] }

/-- `occasion_d12` (violated): No beacon governs the region x occupies at the start of the U-turn, a flashing beacon governs the region it ends on; z's conditions do not hold throughout; children present, school in session, inside the margin. Turning at x = 1 m, x ends on lane 16, which the beacon governs; it is 18:00. -/
def occasion_d12Trace : Trace :=
  build { turnX := m 1
          zones := [schoolZone [10, 11] (some postedHours)]
          civil := (fun _ => clock 1080)
          beacons := (fun _ => [beaconOn [16] true]) }

/-- `occasion_d12_outside` (compliant): A beacon governed the region x occupied before the act; no beacon governs any region x occupies or z governs during the U-turn; z's conditions do not hold throughout; children present. The beacon governs lane 15, x's approach until 13 s; it is 18:00. -/
def occasion_d12_outsideTrace : Trace :=
  build { zones := [schoolZone [10, 11] (some postedHours)]
          civil := (fun _ => clock 1080)
          beacons := (fun _ => [beaconOn [15] true]) }

/-- `occasion_d13` (violated): No beacon; env.civil_time leaves z's posted window during the U-turn, so z's conditions do not hold for the first part of the act and hold for the rest; children present, school in session, inside the margin. It is 6:59 until 27 s and 7:00 from 28 s. -/
def occasion_d13Trace : Trace :=
  build { zones := [schoolZone [10, 11] (some postedHours)]
          beacons := (fun _ => [])
          civil := (fun k => clock (if 28 ≤ k then 420 else 419)) }

/-- `occasion_d13_outside` (compliant): No beacon; z's conditions held before the act and do not hold at any observation of the U-turn; children present. It is 15:59 until 26 s and 16:00 from 27 s. -/
def occasion_d13_outsideTrace : Trace :=
  build { zones := [schoolZone [10, 11] (some postedHours)]
          beacons := (fun _ => [])
          civil := (fun k => clock (if k ≤ 26 then 959 else 960)) }

/-- `branch_1` (compliant): x makes a U-turn on z's lane with children present while asm.school_not_in_session_day is declared true at every observation of the act. -/
def branch_1Trace : Trace := build { notInSession := true }

/-- `branch_2` (compliant): as forbid, but asm.outside_school_operation_margin is declared true throughout: exception (c). -/
def branch_2Trace : Trace := build { outsideMargin := true }

/-- `branch_3` (not_applicable): as forbid, but the school zone sign is an end sign. -/
def branch_3Trace : Trace := build { zones := [Build.zoneSign 100 [10, 11] .school true (some {})] }

/-- `branch_4` (not_applicable): as forbid, but the sign begins a pedestrian safety zone, not a school zone. -/
def branch_4Trace : Trace := build { zones := [Build.zoneSign 100 [10, 11] .pedestrianSafety false (some {})] }

/-- `branch_5` (not_applicable): as forbid, but x is a bicycle, no vehicle of DEF-NRS-484A-320. -/
def branch_5Trace : Trace := build { xClasses := [.bicycle] }

/-- `branch_6` (compliant): as forbid, but the pedestrian beside the lane is an adult: no child is present. -/
def branch_6Trace : Trace := build { childClasses := [.pedestrian] }

/-- `branch_7` (violated): a non-flashing beacon governs z's lanes, but the pupils are not in class: (d) fails, and the beacon defeats (e). -/
def branch_7Trace : Trace :=
  build { beacons := (fun _ => [beaconOn [10, 11] false]), pupilsInClass := false }

/-- `branch_8` (compliant): z's posted hours are over (18:00, no beacon), so (e) covers the act; an end sign 102 also governs z's lanes, unconditionally, and is no zone x turned in. -/
def branch_8Trace : Trace :=
  build { zones := [schoolZone [10, 11] (some postedHours), Build.zoneSign 102 [10, 11] .school true (some {})]
          beacons := (fun _ => [])
          civil := (fun _ => clock 1080) }

/-- `branch_9` (compliant): as branch_8, with a speed zone sign 102 governing z's lanes instead of the end sign. -/
def branch_9Trace : Trace :=
  build { zones := [schoolZone [10, 11] (some postedHours), Build.zoneSign 102 [10, 11] .speedZone false (some {})]
          beacons := (fun _ => [])
          civil := (fun _ => clock 1080) }

/-- `branch_10` (compliant): as branch_8, with an unconditional school zone sign 102 governing lanes 12 and 13, where x never is. -/
def branch_10Trace : Trace :=
  build { zones := [schoolZone [10, 11] (some postedHours), Build.zoneSign 102 [12, 13] .school false (some {})]
          beacons := (fun _ => [])
          civil := (fun _ => clock 1080) }

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_363_3"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("x", 1)]
    expected := expected
    window := some (21000, 35000)
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["kin.yaw_rate"]
  , witness "occasion_d3" occasion_d3Trace .violated
  , witness "occasion_d3_outside" occasion_d3_outsideTrace .notApplicable
  , witness "occasion_d5" occasion_d5Trace .violated
  , witness "occasion_d5_outside" occasion_d5_outsideTrace .compliant
  , witness "occasion_d8" occasion_d8Trace .violated
  , witness "occasion_d8_outside" occasion_d8_outsideTrace .compliant
  , witness "occasion_d10" occasion_d10Trace .violated
  , witness "occasion_d10_outside" occasion_d10_outsideTrace .compliant
  , witness "occasion_d12" occasion_d12Trace .violated
  , witness "occasion_d12_outside" occasion_d12_outsideTrace .compliant
  , witness "occasion_d13" occasion_d13Trace .violated
  , witness "occasion_d13_outside" occasion_d13_outsideTrace .compliant
  , witness "branch_1" branch_1Trace .compliant
  , witness "branch_2" branch_2Trace .compliant
  , witness "branch_3" branch_3Trace .notApplicable
  , witness "branch_4" branch_4Trace .notApplicable
  , witness "branch_5" branch_5Trace .notApplicable
  , witness "branch_6" branch_6Trace .compliant
  , witness "branch_7" branch_7Trace .violated
  , witness "branch_8" branch_8Trace .compliant
  , witness "branch_9" branch_9Trace .compliant
  , witness "branch_10" branch_10Trace .compliant ]

end TrafficSpecWitness.NRS_484B_363_3
