/-
  Witnesses for NRS_484B_363_4.

  Geometry (every figure is the witness's own and appears nowhere in the rule):
  - An eastbound road: lane 10 (y −2…2 m) from x = −50 m to the zone's end (300 m unless a scene
    ends it earlier), governed by zone sign 100; where it ends, lane 12 (no sign) continues to
    x = 300 m; lane 11 (y 2…6 m), the adjacent eastbound lane, x −50…300 m.
  - Subject (track 1), a motor vehicle 4 m × 2 m, on y = 0, heading east; at rest at x = 0 at the
    first observation, then at vs m/s (10 unless stated), x = vs·(k − 1).
  - Other vehicle (track 2), a motor vehicle 4 m × 2 m, on y = 4, heading east at vs − 3 m/s
    (7 m/s; 0 in branch_1, which slows the subject to 3 m/s). Its lead over the subject is
    36 − 3k m: ahead-aligned (gap ≥ 2 m) up to k = 10, alongside at k = 11, 12, 13 (lead 3, 0,
    −3 m), behind and clear at k = 14 (lead −6 m), the recognition.
  - Instants k = 0…14 at 1 s; the witnesses speak about k = 11…14 (window 11 000…14 000 ms),
    where every 10 s window behind is covered. The pass is under way at k = 11…14 (U); "the first
    observations of the pass" are k ≤ 12, "the later ones" k ≥ 13, "before the pass" k ≤ 9.
  - Zone sign legend: 07:00–08:00 any day; the civil time is 07:30 (conditions hold) or 10:00
    (they do not). Beacon 200 governs lane 10 (lane 11 only, in branch_6).
  - blind: the other vehicle's extent is not reported (so neither is its occupancy): the overlap
    of the projections is neither measured nor computable; the subject is fully observed.
  - Reading values: halt tolerance 0.1 m/s (speeds 3, 7, 10 m/s, or 0), same-direction cosine
    0.9 (headings identical), overtake window 10 s (the pass from k = 10 to k = 14 takes 4 s).
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_363_4
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_363_4

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def ext : Q × Q × Q := (m 2, m 1, m 1)

def civil (minute : Nat) : CivilTime :=
  { year := 2026, month := 11, day := 16, weekday := 0, minuteOfDay := minute }

/-- 07:30, inside the legend's window; 10:00, outside it. -/
def held : Nat := 450
def off : Nat := 600

def schoolHours : Conditions := { windows := [{ startMinute := 420, endMinute := 480 }] }

def laneRect (id : RegionId) (x0 x1 y0 y1 : Int) : Structure :=
  Build.lane id [(m x0, m y0), (m x1, m y0), (m x1, m y1), (m x0, m y1)] Build.east

def roads (zoneEnd : Int) : List Structure :=
  [laneRect 10 (-50) zoneEnd (-2) 2, laneRect 11 (-50) 300 2 6] ++
  (if zoneEnd < 300 then [laneRect 12 zoneEnd 300 (-2) 2] else [])

def subjectAt (vs : Int) (k : Nat) : RoadUser :=
  if k = 0 then Build.user 1 [.motorVehicle] (m 0, m 0) Build.east Q.zero ext
  else Build.user 1 [.motorVehicle] (m (vs * ((k : Int) - 1)), m 0) Build.east (Units.metresPerSecond vs) ext

def otherAt (vs : Int) (k : Nat) : RoadUser :=
  Build.user 2 [.motorVehicle] (m (vs * ((k : Int) - 1) + 36 - 3 * (k : Int)), m 4) Build.east
    (Units.metresPerSecond (vs - 3)) ext

def pedestrian : RoadUser :=
  Build.user 3 [.pedestrian] (m 20, m (-5)) Build.east (Units.metresPerSecond 1) (cm 30, cm 30, m 1)

def beaconOn (lanes : List RegionId) (inoperative flashing : Bool) : Device :=
  { Build.device 200 .speedLimitBeacon lanes with inoperative := some inoperative, flashing := some flashing }

def beacon (inoperative flashing : Bool) : Device := beaconOn [10] inoperative flashing

structure Cfg where
  vs : Int := 10
  other : Bool := true
  extra : List RoadUser := []
  zoneEnd : Int := 300
  zoneKind : ZoneKind := .schoolCrossing
  beacons : List Device := []
  minute : Nat := held
  inSession : Bool := true
  margin : Bool := false
  pupils : Bool := false
  /-- The source reports no extent for the other vehicle (nor, therefore, its occupancy): the overlap
      of the two bodies' projections cannot be computed. -/
  noExtent : Bool := false

def bodies (c : Cfg) (k : Nat) : List RoadUser :=
  let us := [subjectAt c.vs k] ++ (if c.other then [otherAt c.vs k] else []) ++ c.extra
  if c.noExtent then
    us.map fun u => if u.track == 1 then u else Build.withKin u fun kn => { kn with extent := none }
  else us

def sceneCore (c : Cfg) (k : Nat) (t : Timestamp) : Scene :=
  Build.scene t (some 1)
    (bodies c k)
    (roads c.zoneEnd)
    ([Build.zoneSign 100 [10] c.zoneKind false (some schoolHours)] ++ c.beacons)
    (env := { civilTime := some (civil c.minute) })
    (assumptions := [("asm.school_in_session_day", c.inSession),
                     ("asm.school_outside_operation_margin", c.margin),
                     ("asm.pupils_in_class", c.pupils)])

/-- The scene; where the other vehicle's extent is not reported, only the subject's occupancy is. -/
def sceneOf (c : Cfg) (k : Nat) (t : Timestamp) : Scene :=
  let s := sceneCore c k t
  if c.noExtent then
    { s with occupancyObserved := [1], occupies := s.occupies.filter (·.1 == 1) }
  else s

def passTrace (f : Nat → Cfg) : Trace :=
  Build.trace 15 0 (Units.seconds 1) fun k t => sceneOf (f k) k t

/-- `forbid` (violated): school-crossing zone over lane 10, conditions holding (07:30), a school
    day, outside the margin false, no beacon; the subject passes the 7 m/s vehicle, recognized at
    k = 14; the recording begins 14 s before the recognition. -/
def forbidTrace : Trace := passTrace fun _ => {}

/-- `permit` (compliant): same zone and declarations; the subject is the only vehicle. -/
def permitTrace : Trace := passTrace fun _ => { other := false }

/-- `idle` (not_applicable): the same pass on lane 10, whose only zone sign is a speed_zone sign. -/
def idleTrace : Trace := passTrace fun _ => { zoneKind := .speedZone }

/-- `blind` (unknown): forbid, with rel.longitudinal_overlap absent from the manifest; the source
    reports positions, headings, speeds and occupancy but no body extents, so the overlap of the
    projections is neither measured nor computable. -/
def blindTrace : Trace := passTrace fun _ => { noExtent := true }

/-- `branch_1` (not_applicable): forbid, but the other vehicle is at rest (the subject at 3 m/s). -/
def branch_1Trace : Trace := passTrace fun _ => { vs := 3 }

/-- `branch_2` (not_applicable): no beacon; 10:00, the zone sign's conditions false throughout. -/
def branch_2Trace : Trace := passTrace fun _ => { minute := off }

/-- `branch_3` (not_applicable): an operational beacon governs lane 10, not flashing, pupils in class. -/
def branch_3Trace : Trace := passTrace fun _ => { beacons := [beacon false false], pupils := true }

/-- `branch_4` (compliant): the subject, the only vehicle, in the zone; a pedestrian beside the road
    (not a vehicle). -/
def branch_4Trace : Trace := passTrace fun _ => { other := false, extra := [pedestrian] }

/-- `branch_5` (violated): an operational beacon governs lane 10, not flashing, but the pupils are
    not in class; conditions hold: (c) fails on its pupils limb, (d) on the beacon. -/
def branch_5Trace : Trace := passTrace fun _ => { beacons := [beacon false false], pupils := false }

/-- `branch_6` (violated): an operational, non-flashing beacon governs only the adjacent lane 11,
    not the zone's lane; pupils in class; conditions hold: no beacon designates the zone, so (c)
    fails, and (d) fails on the conditions. -/
def branch_6Trace : Trace := passTrace fun _ => { beacons := [beaconOn [11] false false], pupils := true }

/-- `occasion_s3` (violated): the zone lane ends at x = 105 m: the subject is in it at k = 11 (pass
    under way) and leaves it before the recognition at k = 14. -/
def occasion_s3Trace : Trace := passTrace fun _ => { zoneEnd := 105 }

/-- `occasion_s3_outside` (not_applicable): the zone lane ends at x = 45 m: the subject leaves it
    at k = 6, before the pass begins; the pass is made on lane 12, which no sign governs. -/
def occasion_s3_outsideTrace : Trace := passTrace fun _ => { zoneEnd := 45 }

/-- `occasion_s7` (violated): the beacon, not flashing, pupils in class, operational at k ≤ 12 and
    inoperative from k = 13; conditions hold. -/
def occasion_s7Trace : Trace :=
  passTrace fun k => { beacons := [beacon (decide (k ≥ 13)) false], pupils := true }

/-- `occasion_s7_outside` (not_applicable): the beacon inoperative at k ≤ 9, operational and not
    flashing from k = 10; pupils in class. -/
def occasion_s7_outsideTrace : Trace :=
  passTrace fun k => { beacons := [beacon (decide (k ≤ 9)) false], pupils := true }

/-- `occasion_s9` (violated): the operational beacon not flashing at k ≤ 12, flashing from k = 13;
    pupils in class. -/
def occasion_s9Trace : Trace :=
  passTrace fun k => { beacons := [beacon false (decide (k ≥ 13))], pupils := true }

/-- `occasion_s9_outside` (not_applicable): the operational beacon flashing at k ≤ 9, not flashing
    from k = 10; pupils in class. -/
def occasion_s9_outsideTrace : Trace :=
  passTrace fun k => { beacons := [beacon false (decide (k ≤ 9))], pupils := true }

/-- `occasion_s10` (violated): the beacon inoperative at k ≤ 12, operational and flashing from
    k = 13; 10:00, the zone sign's conditions false throughout. -/
def occasion_s10Trace : Trace :=
  passTrace fun k => { beacons := [beacon (decide (k ≤ 12)) true], pupils := true, minute := off }

/-- `occasion_s10_outside` (not_applicable): the beacon operational (flashing) at k ≤ 9,
    inoperative from k = 10; the zone sign's conditions false throughout. -/
def occasion_s10_outsideTrace : Trace :=
  passTrace fun k => { beacons := [beacon (decide (k ≥ 10)) true], pupils := true, minute := off }

/-- `occasion_s11` (violated): no beacon; 10:00 (conditions false) at k ≤ 12, 07:30 (true) from k = 13. -/
def occasion_s11Trace : Trace :=
  passTrace fun k => { minute := if k ≤ 12 then off else held }

/-- `occasion_s11_outside` (not_applicable): no beacon; 07:30 (conditions true) at k ≤ 9, 10:00
    (false) from k = 10. -/
def occasion_s11_outsideTrace : Trace :=
  passTrace fun k => { minute := if k ≤ 9 then held else off }

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_363_4"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("subject", 1)]
    expected := expected
    window := some (11000, 14000)
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["rel.longitudinal_overlap"]
  , witness "branch_1" branch_1Trace .notApplicable
  , witness "branch_2" branch_2Trace .notApplicable
  , witness "branch_3" branch_3Trace .notApplicable
  , witness "branch_4" branch_4Trace .compliant
  , witness "branch_5" branch_5Trace .violated
  , witness "branch_6" branch_6Trace .violated
  , witness "occasion_s3" occasion_s3Trace .violated
  , witness "occasion_s3_outside" occasion_s3_outsideTrace .notApplicable
  , witness "occasion_s7" occasion_s7Trace .violated
  , witness "occasion_s7_outside" occasion_s7_outsideTrace .notApplicable
  , witness "occasion_s9" occasion_s9Trace .violated
  , witness "occasion_s9_outside" occasion_s9_outsideTrace .notApplicable
  , witness "occasion_s10" occasion_s10Trace .violated
  , witness "occasion_s10_outside" occasion_s10_outsideTrace .notApplicable
  , witness "occasion_s11" occasion_s11Trace .violated
  , witness "occasion_s11_outside" occasion_s11_outsideTrace .notApplicable ]

end TrafficSpecWitness.NRS_484B_363_4
