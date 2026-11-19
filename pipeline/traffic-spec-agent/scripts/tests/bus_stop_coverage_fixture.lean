import TrafficSpec.Core.Language.Semantics
import TrafficSpec.Core.Evidence.Builders

/-
  A HYPOTHETICAL classification, never admitted by any gate, under the identity reading: the class
  whose contract names the defined kind (`ru.bus`) is included; the classes naming a narrower kind
  (school, transit, tour or shuttle) stay unresolved; the general motor-vehicle
  class is `covered` by `ru.bus`. Next to it, the same aggregate with the general
  class unresolved, as admitted records leave it today. A source lists every class it establishes
  for a road user and marks unobserved the classes it cannot confirm (here, a manifest that marks
  them absent).

  Membership and a minimal no-halt-in-a-bus-stop rule for every vehicle but a bus, with only a
  passenger-door exception (the shape of the duty, not any law's exception):
  - an ordinary car, every class of the aggregate observed: F, `violated`; under today's record U,
    `unknown`;
  - the same car with the bus classes unobserved, or with only the school-bus class unobserved: U,
    `unknown` (completeness must cover the included and the unresolved classes);
  - a transit bus the source also lists as a bus: T, `not_applicable`; listed only as a transit bus:
    U, `unknown`;
  - a school bus listed only as a school bus: U, `unknown`; also listed as a bus (a source-backed
    fleet or configuration mapping): T, `not_applicable`;
  - the same shape for a hire-vehicle stand, with the class naming the hire kind included and the
    general class covered: the car `violated`, a vehicle of that class `not_applicable`, the car
    with that class unobserved `unknown`.

  Run: `lake env lean --run <this file>` inside library/; every `#guard` must hold, and `main`
  prints the verdict tags.
-/
open TrafficSpec TrafficSpec.Semantics

namespace BusStopCoverageFixture

def openClasses : List String := ["ru.school_bus", "ru.transit_bus", "ru.tour_or_shuttle_bus"]
def aggClasses : List String := "ru.bus" :: openClasses

/-- HYPOTHETICAL, not admitted: the general class covered by `ru.bus` (in neither list). -/
def busCovered : LegalAggregate := { id := "HYP::bus", included := ["ru.bus"], unresolved := openClasses }
/-- As admitted records leave it: the general class unresolved. -/
def busOpen : LegalAggregate := { busCovered with unresolved := openClasses ++ ["ru.motor_vehicle"] }
/-- HYPOTHETICAL, not admitted: the class naming the hire kind included, the limousine class unresolved,
    the general class covered by it. -/
def taxiCovered : LegalAggregate := { id := "HYP::taxicab", included := ["ru.taxicab"], unresolved := ["ru.limousine"] }
def taxiClasses : List String := ["ru.taxicab", "ru.limousine"]
def vehicle : LegalAggregate :=
  { id := "HYP::vehicle", included := ["ru.motor_vehicle", "ru.bus", "ru.transit_bus", "ru.school_bus", "ru.taxicab"] }

def reading (bus : LegalAggregate) : Reading :=
  { params := [{ name := "p.halt_speed_tolerance", value := Q.mk' 1 10, unit := .metrePerSecond }]
    aggregates := [bus, taxiCovered, vehicle] }

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n
def ext : Q × Q × Q := (cm 230, cm 90, cm 75)

def at1 (cs : List RoadUserClass) : RoadUser := Build.user 1 cs (m 105, m 2) Build.east Q.zero ext
def sedan : RoadUser := at1 [.motorVehicle]
def transitBus : RoadUser := at1 [.motorVehicle, .bus, .transitBus]
def transitOnly : RoadUser := at1 [.motorVehicle, .transitBus]
def schoolOnly : RoadUser := at1 [.motorVehicle, .schoolBus]
def schoolAndBus : RoadUser := at1 [.motorVehicle, .bus, .schoolBus]
def taxi : RoadUser := at1 [.motorVehicle, .taxicab]

/-- The listed classes unobserved, as a manifest that marks them absent leaves the road user. -/
def masked (cs : List String) (u : RoadUser) : RoadUser := cs.foldl (fun u c => Mask.user c u) u

def tri (r : R) : Tri := r.v
def oneScene (u : RoadUser) : Scene := { t := 0, users := [u] }
def mem (a : LegalAggregate) (u : RoadUser) : Tri := tri (aggregateMembership (oneScene u) 1 a)

-- membership, straight from Core
#guard mem busCovered sedan = .f
#guard mem busOpen sedan = .u
#guard mem busCovered (masked aggClasses sedan) = .u
#guard mem busCovered (masked ["ru.school_bus"] sedan) = .u
#guard mem busCovered transitBus = .t
#guard mem busCovered transitOnly = .u
#guard mem busCovered schoolOnly = .u
#guard mem busCovered schoolAndBus = .t
#guard mem taxiCovered sedan = .f
#guard mem taxiCovered taxi = .t
#guard mem taxiCovered (masked ["ru.taxicab"] sedan) = .u

-- the rule
def vSubject : Arg := .var "subject"
def isAgg (x : Arg) (a : String) : Formula := .atom "ru_aggregate" [x, .lit a] []
def halted : Formula := .cmp (.measure "kin_speed" [vSubject]) .le (.param "p.halt_speed_tolerance")
/-- A curb zone of `kind` the subject occupies while it is not of the aggregate `agg`. -/
def selZone (kind agg z : String) : Formula :=
  .and (.atom "rel_occupies" [vSubject, .var z] [])
    (.and (.atom "st_curb_zone_kind" [.var z, .lit kind] []) (.not (isAgg vSubject agg)))

def mkRule (id kind agg : String) : Rule :=
  { id := id
    laws := []
    binders := [{ name := "subject", cls := isAgg vSubject "HYP::vehicle" }]
    applicability := .existsRegion (.lit "curb_zone") "z" (selZone kind agg "z")
    obligation := .forallRegion (.lit "curb_zone") "z"
      (.implies (selZone kind agg "z") (.or (.not halted) (.atom "sig_door_open" [vSubject] []))) }

def rules : List Rule :=
  [mkRule "fixture_bus_stop" "bus_stop" "HYP::bus", mkRule "fixture_taxicab_stand" "taxicab_stand" "HYP::taxicab"]

def lane : Structure :=
  Build.lane 10 [(m (-200), m 0), (m 300, m 0), (m 300, m 4), (m (-200), m 4)] Build.east (ordinal := some 1) (count := some 1)
def zone (k : CurbZoneKind) : Structure := { Build.rect 20 .curbZone (m 100) (m 0) (m 120) (m 3) with curbKind := some k }

def trace (k : CurbZoneKind) (u : RoadUser) : Trace :=
  Build.trace 3 0 (Units.seconds 5) fun _ t =>
    Build.scene t (some 1) [Build.withSignals u fun s => { s with doorsOpen := some [] }] [lane, zone k] []

def scenario (rule : String) (k : CurbZoneKind) (bus : LegalAggregate) (u : RoadUser) (absent : List String)
    (expected : Verdict) : Scenario :=
  { name := "fixture", rule := rule, trace := trace k u, reading := reading bus,
    manifest := Build.manifest absent, grounding := [("subject", 1)], expected := expected }

def tagAt (rule : String) (k : CurbZoneKind) (bus : LegalAggregate) (u : RoadUser) (absent : List String) : String :=
  match Scenario.run rules (scenario rule k bus u absent .violated) with
  | .ok v => v.tag
  | .error e =>
    -- `run` throws when the tag differs from the expected one; the message names the tag it got
    if (e.splitOn "got unknown").length > 1 then "unknown"
    else if (e.splitOn "got compliant").length > 1 then "compliant"
    else if (e.splitOn "got not_applicable").length > 1 then "not_applicable"
    else s!"error: {e}"

def tag := tagAt "fixture_bus_stop" .busStop
def taxiTag := tagAt "fixture_taxicab_stand" .taxicabStand busCovered

#guard tag busCovered sedan [] = "violated"
#guard tag busOpen sedan [] = "unknown"
#guard tag busCovered sedan aggClasses = "unknown"
#guard tag busCovered sedan ["ru.school_bus"] = "unknown"
#guard tag busCovered transitBus [] = "not_applicable"
#guard tag busCovered transitOnly [] = "unknown"
#guard tag busCovered schoolOnly [] = "unknown"
#guard tag busCovered schoolAndBus [] = "not_applicable"
#guard taxiTag sedan [] = "violated"
#guard taxiTag taxi [] = "not_applicable"
#guard taxiTag sedan ["ru.taxicab"] = "unknown"

def main : IO Unit := do
  IO.println s!"(a) car, classes complete, covered record:       {tag busCovered sedan []}"
  IO.println s!"(a') car, record as admitted today:              {tag busOpen sedan []}"
  IO.println s!"(b) car, bus classes unobserved:                 {tag busCovered sedan aggClasses}"
  IO.println s!"(b') car, only the school-bus class unobserved:  {tag busCovered sedan ["ru.school_bus"]}"
  IO.println s!"(c) transit bus also listed as a bus:            {tag busCovered transitBus []}"
  IO.println s!"(c') transit bus listed only as a transit bus:   {tag busCovered transitOnly []}"
  IO.println s!"(d) school bus listed only as a school bus:      {tag busCovered schoolOnly []}"
  IO.println s!"(d') school bus also listed as a bus:            {tag busCovered schoolAndBus []}"
  IO.println s!"(e) taxicab stand, car, classes complete:        {taxiTag sedan []}"
  IO.println s!"(e') taxicab stand, taxicab:                     {taxiTag taxi []}"
  IO.println s!"(e'') taxicab stand, car, taxicab unobserved:    {taxiTag sedan ["ru.taxicab"]}"

end BusStopCoverageFixture

def main : IO Unit := BusStopCoverageFixture.main
