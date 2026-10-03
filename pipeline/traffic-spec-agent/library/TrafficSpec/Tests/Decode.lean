import TrafficSpec.Core.Runtime.Decode
import TrafficSpec.Core.Evidence.Builders
import TrafficSpec.Tests.Grounding
namespace TrafficSpec.Tests.Decode
open TrafficSpec Units TrafficSpec.Decode

def traceText : String := "{\"scenes\": [
  {\"t\": 0, \"subject\": 1,
   \"users\": [
     {\"track\": 1, \"classes\": [\"motor_vehicle\"],
      \"kin\": {\"position\": [0, 0], \"heading\": [1, 0], \"velocity\": [10, 0], \"speed\": 10, \"extent\": [2.25, 0.9, 0.75],
              \"engine_running\": true, \"gear\": -1, \"throttle\": 0.2},
      \"sig\": {\"turn_indicator\": \"left\", \"brake_lamp\": null}},
     {\"track\": 2, \"classes\": [\"motor_vehicle\", \"truck\"], \"unobserved_classes\": [\"taxicab\"],
      \"kin\": {\"position\": [30, 0], \"heading\": [1, 0], \"velocity\": [0, 0], \"speed\": 0, \"extent\": [2.25, 0.9, 0.75]}}],
   \"structures\": [{\"id\": 7, \"kind\": \"lane\", \"lane\": {\"count\": 2, \"ordinal\": 1, \"marking_left\": [\"broken\", \"white\"], \"enters_intersection\": 20}},
                  {\"id\": 20, \"kind\": \"intersection\"}],
   \"devices\": [{\"id\": 9, \"kind\": \"traffic_signal\", \"governs\": [7], \"indications\": [\"circular_red\", \"green_arrow(left)\"],
                  \"conditions\": {\"windows\": [{\"weekdays\": [0, 1, 2, 3, 4], \"start_minute\": 420, \"end_minute\": 600}], \"min_occupancy\": 2}}],
   \"occupancy_observed\": true, \"occupies\": [[1, 7], [2, 7]], \"relations\": [{\"a\": 1, \"b\": 2, \"visible\": true}],
   \"env\": {\"darkness\": false, \"civil_time\": {\"year\": 2026, \"month\": 9, \"day\": 21, \"weekday\": 0, \"minute_of_day\": 450}},
   \"assumptions\": [[\"asm.business_district\", true]]},
  {\"t\": 500, \"subject\": 1, \"users\": [{\"track\": 1, \"kin\": {\"speed\": 8.5}}], \"links\": [[3, 1]]}
]}"

def decoded : Except String Trace := parse trace traceText
#guard decoded.isOk
def τ : Trace := decoded.toOption.getD []
#guard τ.length = 2
#guard (kin_speed τ[0]! 1).map (Q.eq · (metresPerSecond 10)) = some true
#guard (kin_speed τ[1]! 1).map (Q.eq · (Q.mk' 17 2)) = some true              -- 8.5 exactly
#guard (kin_extent τ[0]! 1).map (fun e => Q.eq e.1 (Q.mk' 9 4)) = some true    -- 2.25 exactly
#guard sig_turn_indicator τ[0]! 1 = some .left
#guard sig_brake_lamp τ[0]! 1 = none                                          -- null is absent
#guard kin_speed τ[1]! 2 = none                                               -- track 2 not in scene 1
#guard ru_taxicab τ[0]! 2 = none                                              -- unobserved class
#guard ru_truck τ[0]! 2 = some true
#guard ru_taxicab τ[0]! 1 = some false
#guard st_lane_marking_left τ[0]! 7 = some (.broken, .white)
#guard dev_traffic_signal_shows τ[0]! 9 (.greenArrow .left) = some true
#guard (dev_zone_sign_conditions τ[0]! 9).map (·.minOccupancy) = some (some 2)
#guard (env_civil_time τ[0]!).map (·.minuteOfDay) = some 450
#guard kin_engine_running τ[0]! 1 = some true
#guard kin_gear τ[0]! 1 = some (-1)
#guard (kin_throttle τ[0]! 1).map (Q.eq · (Q.mk' 1 5)) = some true
#guard kin_engine_running τ[0]! 2 = none
#guard st_lane_enters τ[0]! 7 = some 20
#guard rel_visible τ[0]! 1 2 = some true
#guard rel_visible τ[0]! 2 1 = none
#guard rel_occupies τ[0]! 1 7 = some true
#guard rel_occupies τ[1]! 1 7 = none                                          -- occupancy not observed in scene 1
#guard τ[1]!.links = [(3, 1)]
#guard (τ[0]!.assumption "asm.business_district") = some true

-- the conditions primitive reads the decoded conditions: Monday 07:30 with one occupant
def c : Primitives.Ctx := Primitives.Ctx.mk' τ {}
#guard (Primitives.prim_conditions_hold c 9 1)[0]!.v = .u                      -- occupants not observed
#guard (Primitives.prim_conditions_hold c 9 2)[0]!.v = .u
#guard τ[0]!.occupancyObserved = [1, 2]                                        -- `true` means every user in the scene
#guard (parse trace "{\"scenes\": [{\"t\": 0, \"users\": [{\"track\": 1}], \"occupancy_observed\": [1]}]}").toOption.map (·.head!.occupancyObserved) = some [1]

-- malformed is an error, never false
#guard (parse trace "{\"scenes\": [{\"t\": 0, \"users\": [{\"track\": 1, \"classes\": [\"unicorn\"]}]}]}").isOk = false
#guard (parse trace "{\"scenes\": [{\"t\": 0, \"env\": {\"darkness\": \"yes\"}}]}").isOk = false
#guard (parse trace "{\"scenes\": [{\"t\": 5}, {\"t\": 5}]}").isOk = false           -- not increasing
#guard (parse trace "{\"scenes\": []}").isOk = false
#guard (parse trace "{\"scenes\": [{\"users\": []}]}").isOk = false                 -- t required
#guard match parse trace "{\"scenes\": [{\"t\": 0, \"users\": [{\"track\": 1, \"kin\": {\"speed\": \"fast\"}}]}]}" with
  | .error e => e == "trace.scenes[0].users[0].kin.speed: expected a number"
  | .ok _ => false

-- reading and manifest
def readingText : String := "{\"params\": [{\"name\": \"p.stop_speed\", \"value\": 0.1, \"unit\": \"m/s\"}, {\"name\": \"p.setback\", \"value\": 15, \"unit\": \"ft\"}, {\"name\": \"p.limit\", \"value\": 25, \"unit\": \"mph\"}],
  \"aggregates\": [{\"word\": \"vehicle\", \"classes\": [\"ru.motor_vehicle\", \"ru.bicycle\"]}]}"
def ρ : Reading := (parse reading readingText).toOption.getD {}
#guard (ρ.param "p.stop_speed").map (Q.eq · (Q.mk' 1 10)) = some true
#guard ρ.paramUnit "p.stop_speed" = some .metrePerSecond
#guard (ρ.param "p.setback").map (Q.eq · (feet 15)) = some true          -- 15 ft, stored in metres
#guard ρ.paramUnit "p.setback" = some .metre
#guard (ρ.param "p.limit").map (Q.eq · (mph 25)) = some true
#guard ρ.aggregate "vehicle" = some ["ru.motor_vehicle", "ru.bicycle"]
def manifestText : String := "{\"source\": \"video\", \"reid_gap\": 1.5, \"atoms\": {\"kin.speed\": \"estimate:coarse\", \"ru.motor_vehicle\": \"exact\", \"env.darkness\": \"absent\", \"kin.engine_running\": \"subject\"}}"
def m : Manifest := (parse manifest manifestText).toOption.getD default
#guard m.source = "video"
#guard Q.eq m.reidGap (Q.mk' 3 2)
#guard m.capability "kin.speed" = .estimate "coarse"
#guard m.capability "env.darkness" = .absent
#guard m.capability "kin.position" = .absent                                  -- unlisted is absent
#guard m.capability "kin.engine_running" = .subject
#guard m.observes "kin.engine_running"
-- a subject-only atom survives the mask on the subject and is blanked on everyone else
def subjectOnly : Manifest :=
  { Manifest.full "sim" with entries := (Manifest.full "sim").entries.map fun (id, c) =>
      if id == "kin.engine_running" || id == "rel.visible" then (id, .subject) else (id, c) }
#guard kin_engine_running (mask subjectOnly τ[0]!) 1 = some true
#guard kin_engine_running (mask subjectOnly { τ[0]! with subject := some 2 }) 1 = none
#guard rel_visible (mask subjectOnly τ[0]!) 1 2 = some true
#guard rel_visible (mask subjectOnly { τ[0]! with subject := some 2 }) 1 2 = none
#guard !m.complete
#guard (parse manifest "{\"source\": \"x\", \"atoms\": {\"kin.speed\": \"good\"}}").isOk = false

-- builders: a scenario for the test rule, padded so the stop window is covered
open Build in
def halt : Trace :=
  let base := trace 5 0 (Q.mk' 1 2) fun k t =>
    let v := metresPerSecond (Int.ofNat (8 - 2 * k))
    scene t (some 1)
      [user 1 [.motorVehicle] (metres (Int.ofNat (2 * k)), Q.zero) east v (Q.mk' 9 4, Q.mk' 9 10, Q.mk' 3 4),
       user 2 [.motorVehicle, .truck] (metres 40, Q.zero) east Q.zero (Q.mk' 9 4, Q.mk' 9 10, Q.mk' 3 4)]
      [lane 7 [(metres (-10), metres (-2)), (metres 60, metres (-2)), (metres 60, metres 2), (metres (-10), metres 2)] east]
      [signal 9 [7] [.circularRed]]
  pad base Q.zero (seconds 3) (Q.mk' 1 2)
#guard halt.length = 5 + 6
#guard Trace.monotone halt
#guard (halt.getLast?.map (·.t)) = some 5000
#guard rel_occupies halt[0]! 1 7 = some true                                  -- occupancy from geometry
#guard rel_occupies halt[0]! 2 7 = some true
#guard (kin_speed halt[10]! 1).map Q.isZero = some true

def sc : Scenario :=
  { name := "truck stands", rule := "test/truck_stop", trace := halt, reading := Tests.Semantics.ρ,
    manifest := Manifest.full "test", grounding := [("x", 2)], expected := .compliant, window := some (1000, 5000) }
#guard (sc.run Tests.Grounding.rules).isOk
#guard match ({ sc with window := none } : Scenario).run Tests.Grounding.rules with
  | .error e => e.startsWith "truck stands: expected compliant, got unknown [window_truncated:holdsFor]"
  | .ok _ => false
#guard match ({ sc with expected := .violated } : Scenario).run Tests.Grounding.rules with
  | .error e => e.startsWith "truck stands: expected violated, got compliant"
  | .ok _ => false
#guard match ({ sc with rule := "test/none" } : Scenario).run Tests.Grounding.rules with
  | .error e => e == "truck stands: rule test/none is not registered"
  | .ok _ => false
-- an unknown witness must be unknown for a masked atom: a division by zero is the rule's, not the mask's
def scGap : Scenario :=
  { sc with rule := "test/gap", grounding := [("x", 1), ("y", 2)], expected := .unknown [] }
#guard match scGap.run Tests.Grounding.rules with
  | .error e => e.startsWith "truck stands: unknown for [division_by_zero:div], not for an atom the manifest masks"
  | .ok _ => false
#guard ({ scGap with manifest := Build.manifest ["kin.speed"] } : Scenario).run Tests.Grounding.rules |>.isOk
#guard match ({ scGap with manifest := Build.manifest ["rel.bearing"] } : Scenario).run Tests.Grounding.rules with
  | .error e => e.startsWith "truck stands: unknown for [division_by_zero:div]"
  | .ok _ => false
#guard match ({ scGap with grounding := [("x", 1)], manifest := Build.manifest ["kin.speed"] } : Scenario).run Tests.Grounding.rules with
  | .error e => e.startsWith "truck stands: unknown for [unbound_variable:y]"      -- an unbound binder is a defect, not a masked atom
  | .ok _ => false
-- a not-applicable witness needs every bound track present at some instant
#guard ({ sc with rule := "test/gap", grounding := [("x", 2), ("y", 1)], expected := .notApplicable } : Scenario).run Tests.Grounding.rules |>.isOk
#guard match ({ sc with rule := "test/gap", grounding := [("x", 2), ("y", 9)], expected := .notApplicable } : Scenario).run Tests.Grounding.rules with
  | .error e => e == "truck stands: not applicable, but no instant has every bound track present"
  | .ok _ => false

end TrafficSpec.Tests.Decode
