/-
  Witnesses for LVMC_11_52_030_B.

  Geometry (the witness's own figures, none in the rule): an east–west street. The parking lane
  (region 10, lane) is the strip y ∈ [0, 3] m, x ∈ [0, 60] m beside the curb; the travel lane
  (region 11) is y ∈ [3, 6]; the lane across the street (region 12) is y ∈ [6, 9]. The curb zone
  (region 20) is x ∈ [10, 30], y ∈ [0, 3], over the parking lane: colour yellow, kind
  freight_loading (white in `idle`). The accompanying sign (device 30) is a parking_restricted
  zone sign governing the parking lane 10, with conditions: Monday–Friday 08:00–18:00, vehicle
  class commercial motor vehicle.

  The subject (track 1, half-extent 2.4 × 0.9 × 0.75 m) stands at (20, 1.5) m, inside both the
  parking lane and the curb zone, at speed 0 (well under the 0.1 m/s tolerance) at three
  instants one second apart; in `permit` it drives east at 5 m/s (50 × the tolerance) along the
  zone. The civil time is Monday 09:00 (weekday 0, minute 540) except in `branch_1`, Sunday 09:00
  (weekday 6).
-/
import TrafficSpec.Rules.LVMC_11.LVMC_11_52_030_B
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.LVMC_11_52_030_B

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def carExtent : Q × Q × Q := (cm 240, cm 90, cm 75)

def parkingLane : Structure := Build.rect 10 .lane (m 0) (m 0) (m 60) (m 3)
def travelLane : Structure := Build.rect 11 .lane (m 0) (m 3) (m 60) (m 6)
def farLane : Structure := Build.rect 12 .lane (m 0) (m 6) (m 60) (m 9)

def curbZone (colour : CurbColour) : Structure :=
  { Build.rect 20 .curbZone (m 10) (m 0) (m 30) (m 3) with
    curbKind := some .freightLoading, curbColour := some colour }

def signConditions : Conditions :=
  { windows := [{ weekdays := [0, 1, 2, 3, 4], startMinute := 480, endMinute := 1080 }]
    vehicleClass := some .commercialMotorVehicle }

def sign (governs : List RegionId) (kind : ZoneKind := .parkingRestricted) : Device :=
  Build.zoneSign 30 governs kind false (some signConditions)

def weekdayMorning : Env := { civilTime := some { year := 2026, month := 11, day := 16, weekday := 0, minuteOfDay := 540 } }
def sundayMorning : Env := { civilTime := some { year := 2026, month := 11, day := 22, weekday := 6, minuteOfDay := 540 } }

def structures (colour : CurbColour) : List Structure :=
  [parkingLane, travelLane, farLane, curbZone colour]

/-- The subject halted in the curb zone. -/
def halted (classes : List RoadUserClass) : RoadUser :=
  Build.user 1 classes (m 20, cm 150) Build.east Q.zero carExtent

/-- A scene of a halted subject. -/
def haltScene (classes : List RoadUserClass) (colour : CurbColour) (devs : List Device) (env : Env)
    (t : Timestamp) : Scene :=
  Build.scene t (some 1) [halted classes] (structures colour) devs (env := env)

/-- `forbid` (violated): A curb zone z (st.curb_zone, colour yellow, kind freight_loading) has a zone sign d (dev.zone_sign kind parking_restricted, conditions: weekdays during business hours, class commercial motor vehicle) governing the parking lane beside it. A private passenger car (ru.motor_vehicle only) halts in z, at rest for several minutes on a weekday morning. The sign's conditions do not hold for it, so neither exception holds. -/
def forbidTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    haltScene [.motorVehicle] .yellow [sign [10]] weekdayMorning t

/-- `permit` (compliant): The same car drives along z without halting. -/
def permitTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.motorVehicle] (m (14 + 5 * (k : Int)), cm 150) Build.east (Units.metresPerSecond 5) carExtent ]
      (structures .yellow)
      [ sign [10] ]
      (env := weekdayMorning)

/-- `idle` (not_applicable): The same car halts for several minutes in a curb zone whose colour is white. -/
def idleTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    haltScene [.motorVehicle] .white [sign [10]] weekdayMorning t

/-- `blind` (unknown): As in forbid, but the source supplies no speed for the subject (kin.speed absent), so whether it halts is unknown. -/
def blindTrace : Trace :=
  Build.masked (Build.manifest ["kin.speed"]) forbidTrace

/-- `branch_1` (violated): A commercial delivery van (ru.motor_vehicle and ru.commercial_motor_vehicle) halts in z on a Sunday morning, outside the sign's time windows. The sign's conditions do not hold for it, so the commercial-vehicle exception is false whatever its membership. -/
def branch_1Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    haltScene [.motorVehicle, .commercialMotorVehicle] .yellow [sign [10]] sundayMorning t

/-- `branch_2` (violated): A taxicab (ru.motor_vehicle and ru.taxicab) halts in z on a weekday morning. The sign's vehicle class is commercial motor vehicle, so its conditions do not hold for the taxicab, and the taxicab exception is false whatever its membership. -/
def branch_2Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    haltScene [.motorVehicle, .taxicab] .yellow [sign [10]] weekdayMorning t

/-- `branch_3` (violated): The commercial van halts in z on a weekday morning; the sign's conditions
    hold for it, but the only parking_restricted sign governs the lane across the street, not a
    region the van occupies, so no accompanying sign excuses it. -/
def branch_3Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    haltScene [.motorVehicle, .commercialMotorVehicle] .yellow [sign [12]] weekdayMorning t

/-- `branch_4` (violated): The commercial van halts in z on a weekday morning; the zone sign over
    its lane carries conditions that hold for it, but it is a school zone sign, not a
    parking_restricted one, so no accompanying sign excuses it. -/
def branch_4Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    haltScene [.motorVehicle, .commercialMotorVehicle] .yellow [sign [10] .school] weekdayMorning t

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "LVMC_11_52_030_B"
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
  , witness "blind" blindTrace (.unknown []) ["kin.speed"]
  , witness "branch_1" branch_1Trace .violated
  , witness "branch_2" branch_2Trace .violated
  , witness "branch_3" branch_3Trace .violated
  , witness "branch_4" branch_4Trace .violated ]

end TrafficSpecWitness.LVMC_11_52_030_B
