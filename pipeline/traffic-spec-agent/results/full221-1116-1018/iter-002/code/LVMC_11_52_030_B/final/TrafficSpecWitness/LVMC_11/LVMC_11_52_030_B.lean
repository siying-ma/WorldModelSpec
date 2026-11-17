/-
  Witnesses for LVMC_11_52_030_B.

  Geometry (every figure is the witness's own and appears nowhere in the rule): a parking lane
  (region 10, kind lane, eastbound) from x = 0 to 60 m, y = 0 to 3 m, along the curb at y = 0; a
  curb zone (region 20) painted over x = 10 … 30 m, y = 0 … 3 m, kind freight_loading (taxicab_stand
  in branch_2), colour yellow (white in idle); a zone sign (device 30, parking_restricted, not an
  end sign) governing the lane, its legend Monday–Friday 08:00–18:00 for commercial motor vehicles
  (taxicabs, any time, in branch_2). The subject (track 1, half-extent 2.25 × 0.9 × 0.75 m) stands
  at (20, 1.5) at 0 m/s, far below p.halt_speed_tolerance (0.1 m/s), or in permit drives east at
  5 m/s through x = 14, 19, 24 m, far above it. Three instants, 1 s apart; civil time Tuesday
  10:00 (weekday 1, minute 600), Sunday 10:00 in branch_3.
-/
import TrafficSpec.Rules.LVMC_11.LVMC_11_52_030_B
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.LVMC_11_52_030_B

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def body : Q × Q × Q := (cm 225, cm 90, cm 75)

def parkingLane : Structure :=
  Build.lane 10 [(m 0, m 0), (m 60, m 0), (m 60, m 3), (m 0, m 3)] Build.east

def curbZone (kind : CurbZoneKind) (colour : CurbColour) : Structure :=
  { Build.rect 20 .curbZone (m 10) (m 0) (m 30) (m 3) with
      curbKind := some kind, curbColour := some colour }

/-- Weekdays during business hours, for commercial motor vehicles. -/
def freightConditions : Conditions :=
  { windows := [{ weekdays := [0, 1, 2, 3, 4], startMinute := 480, endMinute := 1080 }]
    vehicleClass := some .commercialMotorVehicle }

/-- Any time, for taxicabs. -/
def taxiConditions : Conditions :=
  { vehicleClass := some .taxicab }

def zoneSign (c : Conditions) : Device :=
  Build.zoneSign 30 [10] .parkingRestricted false (some c)

def weekdayMorning : Env :=
  { civilTime := some { year := 2026, month := 11, day := 17, weekday := 1, minuteOfDay := 600 } }

def sundayMorning : Env :=
  { civilTime := some { year := 2026, month := 11, day := 22, weekday := 6, minuteOfDay := 600 } }

def car : List RoadUserClass := [.motorVehicle]
def van : List RoadUserClass := [.motorVehicle, .commercialMotorVehicle]
def taxi : List RoadUserClass := [.motorVehicle, .taxicab]

/-- A subject of the given classes at rest in the zone, three instants. -/
def haltTrace (classes : List RoadUserClass) (zone : Structure) (sign : Device) (env : Env) : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ Build.user 1 classes (m 20, cm 150) Build.east Q.zero body ]
      [ parkingLane, zone ]
      [ sign ]
      (env := env)

/-- `forbid` (violated): A curb zone z (st.curb_zone, colour yellow, kind freight_loading) with a zone sign d (dev.zone_sign kind parking_restricted, conditions: weekdays during business hours, class commercial) governing the parking lane beside it. A private passenger car (ru.motor_vehicle, not classified as commercial) halts in z at rest for several minutes on a weekday morning. -/
def forbidTrace : Trace :=
  haltTrace car (curbZone .freightLoading .yellow) (zoneSign freightConditions) weekdayMorning

/-- `permit` (compliant): The same car drives along z without halting. -/
def permitTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.user 1 car (Q.add (m 14) (m (5 * k)), cm 150) Build.east (Units.metresPerSecond 5) body ]
      [ parkingLane, curbZone .freightLoading .yellow ]
      [ zoneSign freightConditions ]
      (env := weekdayMorning)

/-- `idle` (not_applicable): The same car halts for several minutes in a curb zone whose colour is white. -/
def idleTrace : Trace :=
  haltTrace car (curbZone .freightLoading .white) (zoneSign freightConditions) weekdayMorning

/-- `blind` (unknown): As in forbid, but the source supplies no speed for the subject (kin.speed absent): whether it halts is unknown. -/
def blindTrace : Trace := forbidTrace

/-- `branch_1` (not_applicable): A commercial delivery van classified under DEF-LVMC-11-02-070::commercial_vehicle halts in z on a weekday morning, within the sign's time window. -/
def branch_1Trace : Trace :=
  haltTrace van (curbZone .freightLoading .yellow) (zoneSign freightConditions) weekdayMorning

/-- `branch_2` (not_applicable): A taxicab classified under DEF-LVMC-11-02-140::taxicab halts in a yellow zone of kind taxicab_stand whose zone sign's conditions hold for it. -/
def branch_2Trace : Trace :=
  haltTrace taxi (curbZone .taxicabStand .yellow) (zoneSign taxiConditions) weekdayMorning

/-- `branch_3` (violated): The commercial van of branch_1 halts in z on a Sunday, outside the sign's time windows. -/
def branch_3Trace : Trace :=
  haltTrace van (curbZone .freightLoading .yellow) (zoneSign freightConditions) sundayMorning

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
  , witness "branch_1" branch_1Trace .notApplicable
  , witness "branch_2" branch_2Trace .notApplicable
  , witness "branch_3" branch_3Trace .violated ]

end TrafficSpecWitness.LVMC_11_52_030_B
