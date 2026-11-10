/-
  Witnesses for NRS_484B_363_3.

  Geometry (metres, +x east, +y north): a highway H (6) x ∈ [-100, 100], y ∈ [-7, 7]. Eastbound
  lanes LA (1) x ∈ [-100, 5] and LB (2) x ∈ [5, 100], y ∈ [-4, 0]; westbound lanes LC (3)
  x ∈ [0, 100] and LD (4) x ∈ [-100, 0], y ∈ [0, 4]; a sidewalk S (5) y ∈ [4, 7]. Every lane and
  the sidewalk lie on H.

  The car (track 1) drives east in LA at 1 m/s up to k = 19, then makes a U-turn over k 20–23
  (yaw rates 36.870, 53.130, 53.130, 36.870 deg/s: 180 deg; the window's change is 143 deg at
  k = 22 and 180 deg at k = 23, where the U-turn is recognized), its first half (k 20–21) in LB
  and its second half (k 22–23) in LC, then drives west. One scene a second, k = 0 … 44; every
  witness judges k 16 … 44, so each 15 s window it reads is covered. "Halfway" is k = 22,
  "before the U-turn" k < 18.

  A child (track 2) stands on the sidewalk at (10, 5.5), or off the highway at (10, 10).
  The school zone sign (device 10) has the legend "weekdays 07:00–09:00"; the day is a Tuesday and
  the time 08:00 (conditions hold), 10:00 (they fail), or 08:59 turning 09:00 at a chosen scene.
  The speed limit beacon (device 11), where built, is operational. School is declared in session
  and outside the half-hour margins in every scene.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_363_3
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_363_3

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: x ↦ 1

def lA : RegionId := 1
def lB : RegionId := 2
def lC : RegionId := 3
def lD : RegionId := 4
def sW : RegionId := 5
def hW : RegionId := 6

def structures : List Structure :=
  [ { Build.rect lA .lane (m (-100)) (m (-4)) (m 5) (m 0) with ways := some [hW] }
  , { Build.rect lB .lane (m 5) (m (-4)) (m 100) (m 0) with ways := some [hW] }
  , { Build.rect lC .lane (m 0) (m 0) (m 100) (m 4) with ways := some [hW] }
  , { Build.rect lD .lane (m (-100)) (m 0) (m 0) (m 4) with ways := some [hW] }
  , { Build.rect sW .sidewalk (m (-100)) (m 4) (m 100) (m 7) with ways := some [hW] }
  , Build.rect hW .highway (m (-100)) (m (-7)) (m 100) (m 7) ]

/-- The car at scene k, at 1 m/s: east in LA up to k = 19; the U-turn over k 20–23, headings
    (4/5, 3/5), north, (−4/5, 3/5), west, each reached by the yaw rate held over the second before
    it (36.870°, 53.130°, 53.130°, 36.870°: 180° in all), at k 20–21 in LB and k 22–23 in LC; then
    west. -/
def car (k : Nat) : RoadUser :=
  let ki : Int := k
  let (pos, hd) : Vec × Vec :=
    if k ≤ 19 then ((cm (450 - 100 * (19 - ki)), cm (-170)), Build.east)
    else if k == 20 then ((cm 530, cm (-110)), (Units.ratio 4 5, Units.ratio 3 5))
    else if k == 21 then ((cm 530, cm (-10)), Build.north)
    else if k == 22 then ((cm 450, cm 50), (Units.ratio (-4) 5, Units.ratio 3 5))
    else ((cm (350 - 100 * (ki - 23)), cm 50), Build.west)
  let yaw : Q :=
    if k == 20 || k == 23 then Units.millidegrees 36870
    else if k == 21 || k == 22 then Units.millidegrees 53130
    else Units.degrees 0
  Build.withKin (Build.user 1 [.motorVehicle] pos hd (m 1) (m 2, m 1, cm 75))
    fun kin => { kin with yawRate := some yaw }

/-- The child at scene k: on the sidewalk or off the highway. -/
def child (onWay : Bool) : RoadUser :=
  Build.user 2 [.pedestrian, .child] (if onWay then (m 10, cm 550) else (m 10, m 10)) Build.north Q.zero
    (cm 25, cm 25, cm 60)

def schoolHours : Conditions :=
  { windows := [{ weekdays := [0, 1, 2, 3, 4], startMinute := 420, endMinute := 540 }] }

/-- What a witness varies from the `forbid` scene. -/
structure Setup where
  zoneLanes : List RegionId := [lB, lC]      -- what the school zone sign governs; [] = no sign
  beaconLanes : Option (List RegionId) := none   -- what the beacon governs; none = no beacon
  flashing : Nat → Bool := fun _ => false
  childOnWay : Nat → Bool := fun _ => true
  minute : Nat → Nat := fun _ => 480
  pupils : Bool := true

def mkTrace (σ : Setup) : Trace :=
  Build.trace 45 0 (Units.seconds 1) fun k t =>
    let zone : List Device :=
      if σ.zoneLanes.isEmpty then [] else [Build.zoneSign 10 σ.zoneLanes .school false (some schoolHours)]
    let beacon : List Device :=
      match σ.beaconLanes with
      | none => []
      | some ls => [{ Build.device 11 .speedLimitBeacon ls with
                      flashing := some (σ.flashing k), inoperative := some false }]
    Build.scene t (some 1)
      [car k, child (σ.childOnWay k)]
      structures
      (zone ++ beacon)
      (env := { civilTime := some { year := 2026, month := 11, day := 10, weekday := 1,
                                    minuteOfDay := σ.minute k } })
      (assumptions := [("asm.school_not_in_session", false),
                       ("asm.school_out_of_operation_period", false),
                       ("asm.pupils_in_class", σ.pupils)])

/-- `forbid` (violated): A car makes a U-turn in a lane governed by a school zone sign whose conditions hold, with children on the sidewalk of the same highway; school is declared in session and outside the half-hour margins, no speed limit beacon governs the lane. -/
def forbidTrace : Trace := mkTrace {}

/-- `permit` (compliant): The same U-turn with no child anywhere on the highway throughout the U-turn. -/
def permitTrace : Trace := mkTrace { childOnWay := fun _ => false }

/-- `idle` (not_applicable): A car makes a U-turn on a street governed by no school zone or school crossing zone sign. -/
def idleTrace : Trace := mkTrace { zoneLanes := [] }

/-- `blind` (unknown): The forbid scene with the source unable to classify children: whether children are present is unknown and no other exception holds. -/
def blindTrace : Trace := mkTrace {}

/-- `occasion_u3` (violated): The U-turn starts outside the zone and its second half lies in a lane the school zone sign governs, all exceptions failing. -/
def occasion_u3Trace : Trace := mkTrace { zoneLanes := [lC] }

/-- `occasion_u3_outside` (not_applicable): The car was in the zone only before the U-turn began and makes the whole U-turn after leaving the governed lanes. -/
def occasion_u3_outsideTrace : Trace := mkTrace { zoneLanes := [lA] }

/-- `occasion_u5` (violated): No child is present when the U-turn begins, a child steps onto the sidewalk halfway through; no other exception holds. -/
def occasion_u5Trace : Trace := mkTrace { childOnWay := fun k => 22 ≤ k }

/-- `occasion_u5_outside` (compliant): Children leave the highway before the U-turn begins and none is present at any observation of the U-turn. -/
def occasion_u5_outsideTrace : Trace := mkTrace { childOnWay := fun k => k < 18 }

/-- `occasion_u8` (violated): An operational beacon governs only the lane of the first part of the U-turn, its lights dark, pupils in class; the rest of the U-turn lies in a lane no beacon governs, where the zone sign's conditions hold; no child exception holds. -/
def occasion_u8Trace : Trace := mkTrace { beaconLanes := some [lB] }

/-- `occasion_u8_outside` (compliant): An operational beacon, dark, governs every lane the U-turn occupies, pupils in class, and governed none of the lanes the car occupied before it. -/
def occasion_u8_outsideTrace : Trace := mkTrace { beaconLanes := some [lB, lC] }

/-- `occasion_u10` (violated): Pupils in class, an operational beacon governs the lanes; its lights stop flashing halfway through the U-turn; no other exception holds. -/
def occasion_u10Trace : Trace := mkTrace { beaconLanes := some [lB, lC], flashing := fun k => k < 22 }

/-- `occasion_u10_outside` (compliant): The beacon flashes before the U-turn and is dark at every observation of it, pupils in class. -/
def occasion_u10_outsideTrace : Trace := mkTrace { beaconLanes := some [lB, lC], flashing := fun k => k < 18 }

/-- `occasion_u11` (violated): No beacon governs the lane of the first part of the U-turn, where the sign's conditions do not hold; an operational flashing beacon governs the lane of its second part; no other exception holds. -/
def occasion_u11Trace : Trace :=
  mkTrace { beaconLanes := some [lC], flashing := fun _ => true, minute := fun _ => 600 }

/-- `occasion_u11_outside` (compliant): No beacon governs any lane the U-turn occupies while one governed the lane the car occupied before it; the sign's conditions do not hold throughout the U-turn. -/
def occasion_u11_outsideTrace : Trace :=
  mkTrace { beaconLanes := some [lA], flashing := fun _ => true, minute := fun _ => 600 }

/-- `occasion_u12` (violated): No beacon; the zone sign's conditions stop holding only halfway through the U-turn; no other exception holds. -/
def occasion_u12Trace : Trace := mkTrace { minute := fun k => if k < 22 then 539 else 540 }

/-- `occasion_u12_outside` (compliant): No beacon; the zone sign's conditions hold before the U-turn and fail at every observation of it. -/
def occasion_u12_outsideTrace : Trace := mkTrace { minute := fun k => if k < 18 then 539 else 540 }

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_363_3"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("x", 1)]
    expected := expected
    window := some (16000, 44000)
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["ru.child"]
  , witness "occasion_u3" occasion_u3Trace .violated
  , witness "occasion_u3_outside" occasion_u3_outsideTrace .notApplicable
  , witness "occasion_u5" occasion_u5Trace .violated
  , witness "occasion_u5_outside" occasion_u5_outsideTrace .compliant
  , witness "occasion_u8" occasion_u8Trace .violated
  , witness "occasion_u8_outside" occasion_u8_outsideTrace .compliant
  , witness "occasion_u10" occasion_u10Trace .violated
  , witness "occasion_u10_outside" occasion_u10_outsideTrace .compliant
  , witness "occasion_u11" occasion_u11Trace .violated
  , witness "occasion_u11_outside" occasion_u11_outsideTrace .compliant
  , witness "occasion_u12" occasion_u12Trace .violated
  , witness "occasion_u12_outside" occasion_u12_outsideTrace .compliant ]

end TrafficSpecWitness.NRS_484B_363_3
