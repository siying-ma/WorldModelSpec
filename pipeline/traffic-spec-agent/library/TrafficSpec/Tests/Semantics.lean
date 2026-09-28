import TrafficSpec.Core.Semantics
import TrafficSpec.Core.Ontology.Ids
import TrafficSpec.Core.RuleEval
namespace TrafficSpec.Tests.Semantics
open TrafficSpec Units TrafficSpec.Semantics

-- ---------------------------------------------------------------------------------------------
-- Bijections the doctor also checks: every ATOMS.md id dispatches, every drv id is defined.
-- ---------------------------------------------------------------------------------------------
#guard atomIds.all fun id => knowsAtom (defName id)
#guard !knowsAtom "ru_unicorn"
#guard derivedIds.all fun id => Derived.derivedNames.contains (defName id)
#guard Derived.derivedNames.all fun n => derivedIds.contains (n.replace "drv_" "drv.")
#guard derivedIds.length = Derived.derivedNames.length

-- ---------------------------------------------------------------------------------------------
-- A trace: track 1 brakes to a halt behind track 2 (stationary, 20 m ahead), sampled at 500 ms.
-- ---------------------------------------------------------------------------------------------
def mover (v : Int) (path : Int) : RoadUser :=
  { track := 1
    classes := some [.motorVehicle]
    kin := { position := some (metres path, metres 0)
             heading := some (Q.ofInt 1, Q.ofInt 0)
             velocity := some (metresPerSecond v, metres 0)
             speed := some (metresPerSecond v)
             pathLength := some (metres path)
             extent := some (Q.mk' 225 100, Q.mk' 9 10, Q.mk' 3 4) } }
def blocker : RoadUser :=
  { track := 2
    classes := some [.motorVehicle, .truck]
    kin := { position := some (metres 30, metres 0)
             heading := some (Q.ofInt 1, Q.ofInt 0)
             velocity := some (Q.zero, Q.zero)
             speed := some Q.zero
             extent := some (Q.mk' 225 100, Q.mk' 9 10, Q.mk' 3 4) } }
def lane7 : Structure := { id := 7, kind := .lane, lane := some { countInDirection := some 2, ordinalFromLeft := some 1 } }
def sig9 (ind : SignalIndication) : Device := { id := 9, kind := .trafficSignal, indications := some [ind], governs := [7] }

def speeds : List Int := [10, 8, 6, 4, 2, 0, 0, 0, 0]
def paths : List Int := [0, 5, 9, 12, 14, 15, 15, 15, 15]
def signals : List SignalIndication := [.circularRed, .circularRed, .circularRed, .circularGreen, .circularGreen,
                                        .circularRed, .circularRed, .circularGreen, .circularGreen]

def sceneAt (k : Nat) : Scene :=
  { t := Int.ofNat (k * 500)
    subject := some 1
    users := [mover (speeds[k]?.getD 0) (paths[k]?.getD 0), blocker]
    structures := [lane7]
    devices := [sig9 (signals[k]?.getD .dark)]
    occupancyObserved := [1, 2]
    occupies := [(1, 7), (2, 7)]
    env := { darkness := some false }
    assumptions := [("asm.business_district", true)] }
def τ : Trace := (List.range 9).map sceneAt
#guard τ.monotone

def β : Binding := ({} : Binding).bind "x" (.track 1) |>.bind "y" (.track 2)
def ρ : Reading := { params := [{ name := "p.stop_speed", value := Q.mk' 1 10, unit := .metrePerSecond }] }
def c : SemCtx := SemCtx.mk' τ ρ β

-- aggregates resolve through the reading, nested words included; an undeclared word is unknown
def ρa : Reading := { ρ with aggregates := [{ word := "vehicle", classes := ["motor vehicle", "ru.trailer_or_combination"] },
                                            { word := "motor vehicle", classes := ["ru.motor_vehicle", "ru.bus"] },
                                            { word := "heavy", classes := ["ru.bus"] }] }
def ca : SemCtx := SemCtx.mk' τ ρa β
#guard (evalAll ca (.atom "ru_aggregate" [.var "x", .lit "vehicle"] [])).all (·.v == .t)
#guard (evalAll ca (.atom "ru_aggregate" [.var "y", .lit "heavy"] [])).all (·.v == .f)
#guard (evalAll ca (.atom "ru_aggregate" [.var "x", .lit "pedestrian"] [])).all (·.v == .u)
#guard (evalAll c (.atom "ru_aggregate" [.var "x", .lit "vehicle"] [])).all (·.v == .u)
-- the static check admits an aggregate atom; the reading check holds its word
def aggRule : Rule :=
  { id := "t_agg", laws := [], binders := [{ name := "x", cls := .atom "ru_aggregate" [.var "x", .lit "vehicle"] [] }]
    applicability := .tt, obligation := .atom "ru_aggregate" [.var "x", .lit "heavy"] [] }
#guard Rule.check [aggRule] aggRule = []
#guard Rule.checkReading [aggRule] aggRule ρa = []
#guard (Rule.checkReading [aggRule] aggRule ρ).length = 2
#guard Formula.aggregateWords (.and (.atom "ru_aggregate" [.var "x", .lit "vehicle"] []) (.existsUser "u" (.atom "ru_aggregate" [.var "u", .lit "traffic"] []))) = ["vehicle", "traffic"]
def v (i : Nat) (φ : Formula) : Tri := evalTri c i φ
def why (i : Nat) (φ : Formula) : List UnknownReason := (eval c i φ).why

def X : Arg := .var "x"
def Y : Arg := .var "y"
def sec (n : Int) : Term := .lit (seconds n) .second
def ms (n : Int) : Term := .lit (milliseconds n) .second
def mps (n : Int) : Term := .lit (metresPerSecond n) .metrePerSecond

-- atoms
#guard v 0 (.atom "ru_motor_vehicle" [X] []) = .t
#guard v 0 (.atom "ru_taxicab" [X] []) = .f
#guard v 0 (.atom "ru_truck" [Y] []) = .t
#guard v 0 (.atom "ru_motor_vehicle" [.var "z"] []) = .u
#guard why 0 (.atom "ru_motor_vehicle" [.var "z"] []) = [.unboundVariable "z"]
#guard why 0 (.atom "ru_unicorn" [X] []) = [.malformed "atom ru_unicorn"]
#guard why 0 (.atom "ru_motor_vehicle" [X, Y] []) = [.malformed "arity ru_motor_vehicle"]
#guard v 0 (.atom "sig_brake_lamp" [X] []) = .u                          -- not observed
#guard why 0 (.atom "sig_brake_lamp" [X] []) = [.absentAtom "sig_brake_lamp"]
#guard v 0 (.atom "rel_ahead_in_lane" [Y, X] []) = .t
#guard v 0 (.atom "rel_same_direction" [X, Y] [.lit (Q.mk' 9 10) .ratio]) = .t
#guard why 0 (.atom "rel_same_direction" [X, Y] []) = [.parameterMissing "rel_same_direction cosine tolerance"]
#guard v 0 (.atom "env_darkness" [] []) = .f
#guard v 0 (.atom "env_wet_road" [] []) = .u
#guard v 0 (.asm "asm.business_district") = .t
#guard why 0 (.asm "asm.school_day") = [.assumptionMissing "asm.school_day"]
#guard v 99 (.atom "env_darkness" [] []) = .u                            -- out of range
#guard v 0 (.atom "dev_traffic_signal_shows" [.nat 9, .lit "circular_red"] []) = .t
#guard v 0 (.atom "st_lane_adjacency" [.nat 7, .lit "left", .nat 8] []) = .u          -- neighbour not observed
#guard v 0 (.cmp (.measure "st_lane_adjacency" [.nat 7, .lit "count"]) .eq (.lit (Q.ofInt 2) .count)) = .t
#guard v 0 (.atom "ru_rider_posture" [X, .lit "on_seat"] []) = .u
#guard why 0 (.atom "dev_traffic_signal_shows" [.nat 9, .lit "purple"] []) = [.malformed "purple"]

-- comparisons, terms, parameters
#guard v 0 (.cmp (.measure "kin_speed" [X]) .gt (mps 9)) = .t
#guard v 5 (.cmp (.measure "kin_speed" [X]) .le (.param "p.stop_speed")) = .t
#guard v 0 (.cmp (.measure "kin_speed" [X]) .le (.param "p.stop_speed")) = .f
#guard why 0 (.cmp (.measure "kin_speed" [X]) .le (.param "p.missing")) = [.parameterMissing "p.missing"]
#guard v 0 (.cmp (.sub (.measure "kin_speed" [X]) (mps 2)) .eq (mps 8)) = .t
#guard why 0 (.cmp (.div (mps 1) (mps 0)) .eq (mps 0)) = [.divisionByZero "div"]
#guard v 0 (.cmp (.measure "rel_surface_gap" [X, Y, .lit "longitudinal"]) .eq (.lit (Q.mk' 255 10) .metre)) = .t
#guard v 0 (.cmp (.quantity "drv_time_gap" [X, Y] []) .eq (.lit (Q.mk' 255 100) .second)) = .t    -- 25.5 m / 10 m/s
#guard why 5 (.cmp (.quantity "drv_time_gap" [X, Y] []) .eq (sec 0)) = [.divisionByZero "drv_time_gap"]

-- connectives keep strong Kleene
#guard v 0 (.and (.atom "ru_motor_vehicle" [X] []) (.atom "sig_brake_lamp" [X] [])) = .u
#guard v 0 (.and (.atom "ru_taxicab" [X] []) (.atom "sig_brake_lamp" [X] [])) = .f
#guard v 0 (.or (.atom "ru_motor_vehicle" [X] []) (.atom "sig_brake_lamp" [X] [])) = .t
#guard v 0 (.implies (.atom "sig_brake_lamp" [X] []) .ff) = .u
#guard v 0 (.not (.atom "sig_brake_lamp" [X] [])) = .u

-- derived: stopped ≤ 0.1 m/s for 1.5 s
def stopped : Formula := .derived "drv_stopped" [X] [.param "p.stop_speed", ms 1500]
#guard v 8 stopped = .t
#guard v 6 stopped = .f                       -- 2500 ms back reaches speed 4
#guard v 1 stopped = .u                       -- the window reaches before the trace
#guard why 1 stopped = [.windowTruncated "drv_stopped"]
#guard why 0 (.derived "drv_stopped" [X] []) = [.malformed "arity drv_stopped"]
#guard why 0 (.derived "drv_nothing" [X] []) = [.malformed "derived concept drv_nothing"]
#guard v 8 (.derived "drv_following" [X, Y] [.lit (metres 30) .metre]) = .t
#guard v 8 (.derived "drv_following" [X, Y] [.lit (metres 5) .metre]) = .f
#guard v 8 (.derived "drv_forced_halt" [X] [.lit (metres 30) .metre, .param "p.stop_speed"]) = .t
#guard v 5 (.derived "drv_moving_off" [X] [.param "p.stop_speed"]) = .f
#guard v 1 (.derived "drv_hard_deceleration" [X] [.lit (metresPerSecondSq 3) .metrePerSecondSq]) = .u  -- no accel observed
#guard v 8 (.derived "drv_laned_roadway" [X] []) = .t
#guard v 8 (.derived "drv_extreme_lane" [X, .lit "right"] []) = .t
#guard v 8 (.derived "drv_extreme_lane" [X, .lit "left"] []) = .f

-- metric windows: adequacy and truncation
def slow : Formula := .cmp (.measure "kin_speed" [X]) .le (mps 2)
#guard v 8 (.holdsFor .time (sec 2) "x" slow) = .t
#guard v 4 (.holdsFor .time (sec 2) "x" slow) = .f
#guard why 8 (.holdsFor .time (ms 500) "x" slow) = [.samplingGap "holdsFor"]       -- 500 ms gaps, d/2 = 250 ms
#guard why 8 (.holdsFor .path (.lit (metres 1) .metre) "x" slow) = [.samplingGap "holdsFor"]  -- the 14→15 m step exceeds d/2
#guard v 8 (.holdsFor .path (.lit (metres 2) .metre) "x" slow) = .t                  -- 14 m onwards: speeds 2, 0, 0, 0, 0
#guard why 8 (.holdsFor .path (.lit (metres 2) .metre) "z" slow) = [.unboundVariable "z"]
#guard v 4 (.holdsFor .path (.lit (metres 6) .metre) "x" slow) = .f                  -- 14 back to 9: speed 6 at path 9
def fast : Formula := .cmp (.measure "kin_speed" [X]) .ge (mps 9)
#guard v 0 (.within .time (sec 1) "x" slow) = .f                                     -- window covered, no witness
#guard v 2 (.within .time (sec 1) "x" slow) = .t                                     -- speed 2 at 2000 ms
#guard v 8 (.within .time (sec 1) "x" fast) = .u                                     -- the trace ends inside the window
#guard why 8 (.within .time (sec 1) "x" fast) = [.windowTruncated "within"]
#guard v 3 (.untilWithin .time (sec 2) "x" (.not fast) slow) = .t
#guard v 0 (.untilWithin .time (sec 1) "x" fast slow) = .f                           -- covered, no witness
#guard why 0 (.untilWithin .time (ms 500) "x" fast slow) = [.samplingGap "untilWithin"]
#guard v 7 (.untilWithin .time (sec 2) "x" .tt fast) = .u                            -- truncated, φ never failed

-- unbounded operators never certify the unobserved future
#guard v 5 (.always slow) = .u
#guard v 0 (.always slow) = .f
#guard v 0 (.eventually slow) = .t
#guard v 0 (.eventually fast) = .t
#guard v 1 (.eventually fast) = .u
#guard v 0 (.until (.not slow) slow) = .t
#guard v 6 (.until slow fast) = .u
#guard v 0 (.until slow fast) = .t                                                   -- ψ at once
#guard v 8 (.since slow (.cmp (.measure "kin_speed" [X]) .eq (mps 2))) = .t          -- slow ever since speed 2
def never : Formula := .cmp (.measure "kin_speed" [X]) .eq (mps 99)
#guard v 3 (.since .tt never) = .u                                                    -- never witnessed: the unobserved past decides
#guard why 3 (.since .tt never) = [.windowTruncated "since"]
#guard v 3 (.since slow never) = .f                                                   -- φ failed inside the trace
#guard v 8 (.since (.cmp (.measure "kin_speed" [X]) .eq (mps 0)) (.cmp (.measure "kin_speed" [X]) .eq (mps 2))) = .t
#guard v 8 (.since (.cmp (.measure "kin_speed" [X]) .eq (mps 2)) (.cmp (.measure "kin_speed" [X]) .eq (mps 4))) = .f

-- decided-false sites: the lane change is seen while straddling; the night window wraps midnight
def lane8 : Structure := { id := 8, kind := .lane, lane := some { leftNeighbour := some 7 } }
def straddle : Scene := { sceneAt 8 with occupies := [(1, 7), (1, 8), (2, 7)], structures := [lane7, lane8] }
def afterChange : Scene := { straddle with t := 4500, occupies := [(1, 8), (2, 7)] }
def τlane : Trace := [sceneAt 7, straddle, afterChange]
def clane : SemCtx := SemCtx.mk' τlane ρ β
#guard (evalAll clane (.derived "drv_lane_change" [X] [])).toList.map (·.v) = [.u, .t, .f]   -- entry only: one manoeuvre, one edge
def night : TimeWindow := { startMinute := 19 * 60, endMinute := 6 * 60 }
#guard Derived.inWindow night (23 * 60) && Derived.inWindow night (5 * 60) && !Derived.inWindow night (12 * 60)
#guard Derived.inWindow { startMinute := 7 * 60, endMinute := 10 * 60 } (8 * 60)
#guard !Derived.inWindow { startMinute := 7 * 60, endMinute := 10 * 60 } (10 * 60)

-- counting signal cycles since the halt began
def green : Formula := .atom "dev_traffic_signal_shows" [.nat 9, .lit "circular_green"] []
def halted : Formula := .cmp (.measure "kin_speed" [X]) .eq (mps 0)
#guard v 8 (.count green halted .eq 1) = .t        -- the halt's run began at 5; one red→green edge (at 7) after it
#guard v 6 (.count green halted .eq 0) = .t
#guard why 8 (.count green (.cmp (.measure "kin_speed" [X]) .eq (mps 10)) .eq 2) = [.windowTruncated "count"]   -- the run holds at the first instant: it may have begun earlier
#guard v 8 (.count green (.cmp (.measure "kin_speed" [X]) .eq (mps 8)) .eq 2) = .t     -- since speed 8 at instant 1: edges at 3 and 7
#guard why 8 (.count green (.atom "sig_brake_lamp" [X] []) .eq 1) = [.absentAtom "sig_brake_lamp"]
#guard why 4 (.count green halted .eq 0) = [.windowTruncated "count"]

-- bounded quantifiers bind regions and devices
#guard v 0 (.existsDevice .trafficSignal "d" (.atom "dev_traffic_signal_shows" [.var "d", .lit "circular_red"] [])) = .t
#guard v 3 (.existsDevice .trafficSignal "d" (.atom "dev_traffic_signal_shows" [.var "d", .lit "circular_red"] [])) = .f
#guard v 0 (.existsDevice .stopSign "d" .tt) = .f
#guard v 0 (.forallDevice .stopSign "d" .ff) = .t
#guard v 0 (.forallRegion .lane "r" (.atom "rel_occupies" [X, .var "r"] [])) = .t
#guard v 0 (.existsRegion .lane "r" (.and (.atom "rel_occupies" [X, .var "r"] []) (.atom "dev_governs" [.nat 9, .var "r"] []))) = .t

-- rule composition goes through the callback; the default knows no rules
#guard why 0 (.rule "some/rule" []) = [.compositionUnknown "some/rule"]

-- runs that reach the trace start are unknown, not measured from the recording
#guard why 2 (.cmp (.distanceWhile "x" (.cmp (.measure "kin_speed" [X]) .ge (mps 6))) .ge (.lit (metres 1) .metre)) = [.windowTruncated "drv_distance_while"]
#guard why 0 (.derived "drv_stopped" [Y] [.param "p.stop_speed", ms 500]) = [.windowTruncated "drv_stopped"]
-- strong until with the witness at the first instant and φ false there
#guard v 0 (.untilWithin .time (sec 1) "x" .ff fast) = .t
#guard v 0 (.until .ff fast) = .t
-- an arrival already in progress at the first observation is a bound, not an instant
def junction : Structure := { id := 9, kind := .intersection }
def arrScene (k : Nat) : Scene :=
  { sceneAt k with
    structures := [lane7, junction]
    occupies := if k ≥ 4 then [(1, 7), (2, 7), (2, 9), (1, 9)] else [(1, 7), (2, 7), (2, 9)] }
def τarr : Trace := (List.range 9).map arrScene
def carr : SemCtx := SemCtx.mk' τarr ρ β
#guard (eval carr 8 (.derived "drv_arrival_order" [Y, X, .lit "intersection", .lit "before"] [.lit (seconds 1) .second])).v = .t   -- y in from the start, x at 2 s: decided by the bound
#guard (eval carr 8 (.derived "drv_arrival_order" [Y, X, .lit "intersection", .lit "same"] [.lit (seconds 1) .second])).v = .f
#guard (eval carr 8 (.derived "drv_arrival_order" [Y, X, .lit "intersection", .lit "same"] [.lit (seconds 3) .second])).v = .u
#guard (eval carr 8 (.derived "drv_arrival_order" [X, Y, .lit "intersection", .lit "before"] [.lit (seconds 1) .second])).v = .f

-- distance while
#guard v 8 (.cmp (.distanceWhile "x" halted) .eq (.lit (metres 0) .metre)) = .t
#guard v 4 (.cmp (.distanceWhile "x" (.not fast)) .eq (.lit (metres 9) .metre)) = .t   -- 14 − 5 since speed 8 at path 5

-- region geometry reaches a formula: distance from a road user to a region
def cross : Structure := { id := 9, kind := .crosswalk, boundary := some [(metres 40, metres (-2)), (metres 42, metres (-2)), (metres 42, metres 2), (metres 40, metres 2)] }
def cgeo : SemCtx := SemCtx.mk' ((List.range 9).map fun k => { sceneAt k with structures := [lane7, cross] }) ρ β
#guard (eval cgeo 8 (.existsRegion .crosswalk "r" (.cmp (.measure "st_region_geometry_distance" [X, .var "r"]) .le (.lit (metres 30) .metre)))).v = .t   -- 15 → 40: 25 m
#guard (eval cgeo 0 (.existsRegion .crosswalk "r" (.cmp (.measure "st_region_geometry_distance" [X, .var "r"]) .le (.lit (metres 30) .metre)))).v = .f   -- 0 → 40
#guard (eval c 0 (.existsRegion .lane "r" (.cmp (.measure "st_region_geometry_distance" [X, .var "r"]) .le (.lit (metres 30) .metre)))).v = .u       -- lane 7 has no geometry

-- static analysis
#guard (Formula.atoms (.and stopped (.cmp (.measure "kin_speed" [X]) .gt (mps 9)))) = ["drv_stopped", "kin_speed"]
#guard (Formula.params stopped) = ["p.stop_speed"]
#guard (Formula.composed (.and (.rule "a" []) (.rule "b" []))) = ["a", "b"]

end TrafficSpec.Tests.Semantics
