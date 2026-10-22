import TrafficSpec.Core.Language.Semantics
import TrafficSpec.Core.Vocab.Ontology.Ids
import TrafficSpec.Core.Language.RuleEval
namespace TrafficSpec.Tests.Semantics
open TrafficSpec Units TrafficSpec.Semantics

-- ---------------------------------------------------------------------------------------------
-- Bijections the doctor also checks: every ATOMS.md id dispatches, every prim id is defined.
-- ---------------------------------------------------------------------------------------------
#guard atomIds.all fun id => knowsAtom (defName id)
#guard !knowsAtom "ru_unicorn"
#guard primitiveIds.all fun id => Primitives.primitiveNames.contains (defName id)
#guard Primitives.primitiveNames.all fun n => primitiveIds.contains (n.replace "prim_" "prim.")
#guard primitiveIds.length = Primitives.primitiveNames.length

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

-- a legal aggregate by id: an included class holds; a class the definition leaves unresolved is
-- unknown with its own reason; an included class held dominates an unresolved one; an undeclared
-- id is unknown; an unobserved class keeps the observation's reason
def ρa : Reading := { ρ with aggregates := [{ id := "D-1::vehicle", included := ["ru.motor_vehicle", "ru.bus"] },
                                            { id := "D-2::heavy", included := ["ru.bus"] },
                                            { id := "D-3::goods", included := ["ru.bus"], unresolved := ["ru.truck"] },
                                            { id := "D-4::mixed", included := ["ru.motor_vehicle"], unresolved := ["ru.truck"] }] }
def ca : SemCtx := SemCtx.mk' τ ρa β
def agg (v id : String) : Formula := .atom "ru_aggregate" [.var v, .lit id] []
#guard (evalAll ca (agg "x" "D-1::vehicle")).all (·.v == .t)
#guard (evalAll ca (agg "y" "D-2::heavy")).all (·.v == .f)
#guard (evalAll ca (agg "y" "D-3::goods")).all fun r => r.v == .u && r.why.map UnknownReason.tag == ["aggregate_unresolved:D-3::goods"]
#guard (evalAll ca (agg "y" "D-4::mixed")).all (·.v == .t)
#guard (evalAll ca (agg "x" "D-9::none")).all fun r => r.v == .u && r.why.map UnknownReason.tag == ["parameter_missing:aggregate:D-9::none"]
#guard (evalAll c (agg "x" "D-1::vehicle")).all (·.v == .u)
def τclassless : Trace := [{ t := 0, users := [{ track := 1 }] }]
#guard (evalAll (SemCtx.mk' τclassless ρa β) (agg "x" "D-3::goods")).all fun r => r.v == .u && r.why.map UnknownReason.tag == ["absent_atom:ru_aggregate"]
-- the sensitivity override forces one track's membership of one aggregate, and nothing else
def caForced : SemCtx := { ca with d := { ca.d with aggregateOverrides := [(2, "D-3::goods", true)] } }
#guard (evalAll caForced (agg "y" "D-3::goods")).all (·.v == .t)
#guard (evalAll caForced (agg "x" "D-2::heavy")).all (·.v == .f)
#guard (UnknownReason.aggregateUnresolved "D-3::goods").tag = "aggregate_unresolved:D-3::goods"
-- the static check admits an aggregate atom; the reading check holds its id and its classes
def aggRule : Rule :=
  { id := "t_agg", laws := [], binders := [{ name := "x", cls := agg "x" "D-1::vehicle" }]
    applicability := .tt, obligation := agg "x" "D-2::heavy" }
#guard Rule.check [aggRule] aggRule = []
#guard Rule.checkReading [aggRule] aggRule ρa = []
#guard (Rule.checkReading [aggRule] aggRule ρ).length = 2
#guard (Rule.checkReading [aggRule] aggRule { ρ with aggregates := [{ id := "D-1::vehicle", included := ["D-2::heavy"] }, { id := "D-2::heavy" }] }).length = 1
#guard Formula.aggregateIds (.and (agg "x" "D-1::vehicle") (.existsUser "u" (agg "u" "D-2::heavy"))) = ["D-1::vehicle", "D-2::heavy"]
-- a heading is read as a direction, whatever the length a source writes
def τheading : Trace := [{ t := 0, users := [{ track := 1, kin := { heading := some (Q.ofInt 3, Q.ofInt 4) } }] }]
#guard (evalTAll (SemCtx.mk' τheading ρ β) (.measure "kin_heading" [.var "x", .lit "x"])).toList.map (·.toOption.map (Q.eq · (Q.mk' 3 5))) = [some true]
#guard (evalTAll (SemCtx.mk' τheading ρ β) (.measure "kin_heading" [.var "x", .lit "y"])).toList.map (·.toOption.map (Q.eq · (Q.mk' 4 5))) = [some true]

-- `cond` selects a quantity by a guard; τ observes darkness (false) and not the wet road. Where the
-- guard is unknown a comparison is decided by cases exactly when both selections decide it alike.
def wet : Formula := .atom "env_wet_road" [] []
def dark : Formula := .atom "env_darkness" [] []
def m (n : Int) : Term := .lit (metres n) .metre
def onWet (op : CmpOp) (k : Int) : Formula := .cmp (.add (m 1) (.cond wet (m 10) (m 5))) op (m k)
#guard (evalAll c (Formula.elimCond (onWet .gt 3))).all (·.v == .t)
#guard (evalAll c (Formula.elimCond (onWet .lt 3))).all (·.v == .f)
#guard (evalAll c (Formula.elimCond (onWet .gt 8))).all (·.v == .u)
#guard (evalAll c (onWet .gt 3)).all (·.v == .u)
#guard (evalAll c (.cmp (.cond wet (m 4) (m 4)) .eq (m 4))).all (·.v == .t)
#guard (evalAll c (Formula.elimCond (.cmp (.cond dark (m 10) (m 5)) .eq (m 5)))).all (·.v == .t)
#guard (evalAll c (Formula.elimCond (.cmp (m 0) .lt (.cond wet (.cond dark (m 1) (m 2)) (m 3))))).all (·.v == .t)
#guard Formula.atoms (onWet .gt 3) = ["env_wet_road"]

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
#guard v 0 (.atom "st_lane_adjacency" [.nat 7, .lit "left", .nat 8] []) = .f          -- first from the left: none there
#guard v 0 (.atom "st_lane_adjacency" [.nat 7, .lit "right", .nat 8] []) = .u         -- neighbour not observed
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
def timeGap : Term := .div (.measure "rel_surface_gap" [X, Y, .lit "longitudinal"]) (.measure "kin_speed" [X])
#guard v 0 (.cmp timeGap .eq (.lit (Q.mk' 255 100) .second)) = .t    -- 25.5 m / 10 m/s
#guard why 5 (.cmp timeGap .eq (sec 0)) = [.divisionByZero "div"]

-- connectives keep strong Kleene
#guard v 0 (.and (.atom "ru_motor_vehicle" [X] []) (.atom "sig_brake_lamp" [X] [])) = .u
#guard v 0 (.and (.atom "ru_taxicab" [X] []) (.atom "sig_brake_lamp" [X] [])) = .f
#guard v 0 (.or (.atom "ru_motor_vehicle" [X] []) (.atom "sig_brake_lamp" [X] [])) = .t
#guard v 0 (.implies (.atom "sig_brake_lamp" [X] []) .ff) = .u
#guard v 0 (.not (.atom "sig_brake_lamp" [X] [])) = .u

-- a window over an atom: stopped ≤ 0.1 m/s for 1.5 s; primitives and unexpanded concept calls
def stopped : Formula := .holdsFor .time (ms 1500) "x" (.cmp (.measure "kin_speed" [X]) .le (.param "p.stop_speed"))
#guard v 8 stopped = .t
#guard v 6 stopped = .f                       -- 2500 ms back reaches speed 4
#guard v 1 stopped = .u                       -- the window reaches before the trace
#guard why 1 stopped = [.windowTruncated "holdsFor"]
#guard why 0 (.derived "prim_conditions_hold" [X] []) = [.malformed "arity prim_conditions_hold"]
#guard why 0 (.derived "drv_nothing" [X] []) = [.malformed "concept drv_nothing"]
def following (g : Term) : Formula :=
  .and (.atom "rel_ahead_in_lane" [Y, X] []) (.cmp (.measure "rel_surface_gap" [X, Y, .lit "longitudinal"]) .le g)
#guard v 8 (following (.lit (metres 30) .metre)) = .t
#guard v 8 (following (.lit (metres 5) .metre)) = .f
#guard v 1 (.cmp (.measure "kin_accel_longitudinal" [X]) .le (.lit (metresPerSecondSq (-3)) .metrePerSecondSq)) = .u  -- no accel observed
#guard v 8 (.existsRegion (.lit "lane") "r" (.and (.atom "rel_occupies" [X, .var "r"] []) (.cmp (.measure "st_lane_adjacency" [.var "r", .lit "count"]) .ge (.lit (Q.ofInt 2) .count)))) = .t

-- the last observation at which a condition held: φ there; false in a covered window without one; unknown off the trace
def fast4 : Formula := .cmp (.measure "kin_speed" [X]) .ge (mps 4)
def pathGe (m : Int) : Formula := .cmp (.measure "kin_path_length" [X]) .ge (.lit (metres m) .metre)
#guard v 8 (.atLast .time (sec 3) "x" fast4 (pathGe 12)) = .t      -- speed ≥ 4 last held at k = 3, where the path is 12 m
#guard v 8 (.atLast .time (sec 3) "x" fast4 (pathGe 13)) = .f
#guard v 8 (.atLast .time (sec 2) "x" fast4 (pathGe 0)) = .f       -- the window k = 4..8 has no observation with speed ≥ 4
#guard why 1 (.atLast .time (sec 3) "x" (.cmp (.measure "kin_speed" [X]) .ge (mps 20)) (pathGe 0)) = [.windowTruncated "atLast"]

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
def night : TimeWindow := { startMinute := 19 * 60, endMinute := 6 * 60 }
#guard Primitives.inWindow night (23 * 60) && Primitives.inWindow night (5 * 60) && !Primitives.inWindow night (12 * 60)
#guard Primitives.inWindow { startMinute := 7 * 60, endMinute := 10 * 60 } (8 * 60)
#guard !Primitives.inWindow { startMinute := 7 * 60, endMinute := 10 * 60 } (10 * 60)

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
#guard v 0 (.existsDevice (.lit "traffic_signal") "d" (.atom "dev_traffic_signal_shows" [.var "d", .lit "circular_red"] [])) = .t
#guard v 3 (.existsDevice (.lit "traffic_signal") "d" (.atom "dev_traffic_signal_shows" [.var "d", .lit "circular_red"] [])) = .f
#guard v 0 (.existsDevice (.lit "stop_sign") "d" .tt) = .f
#guard v 0 (.forallDevice (.lit "stop_sign") "d" .ff) = .t
#guard v 0 (.forallRegion (.lit "lane") "r" (.atom "rel_occupies" [X, .var "r"] [])) = .t
#guard v 0 (.existsRegion (.lit "lane") "r" (.and (.atom "rel_occupies" [X, .var "r"] []) (.atom "dev_governs" [.nat 9, .var "r"] []))) = .t

-- rule composition goes through the callback; the default knows no rules
#guard why 0 (.rule "some/rule" []) = [.compositionUnknown "some/rule"]

-- runs that reach the trace start are unknown, not measured from the recording
#guard why 2 (.cmp (.distanceWhile "x" (.cmp (.measure "kin_speed" [X]) .ge (mps 6))) .ge (.lit (metres 1) .metre)) = [.windowTruncated "distance_while"]
#guard why 0 (.holdsFor .time (ms 500) "y" (.cmp (.measure "kin_speed" [Y]) .le (.param "p.stop_speed"))) = [.windowTruncated "holdsFor"]
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

-- distance while
#guard v 8 (.cmp (.distanceWhile "x" halted) .eq (.lit (metres 0) .metre)) = .t
#guard v 4 (.cmp (.distanceWhile "x" (.not fast)) .eq (.lit (metres 9) .metre)) = .t   -- 14 − 5 since speed 8 at path 5

-- region geometry reaches a formula: distance from a road user to a region
def cross : Structure := { id := 9, kind := .crosswalk, boundary := some [(metres 40, metres (-2)), (metres 42, metres (-2)), (metres 42, metres 2), (metres 40, metres 2)] }
def cgeo : SemCtx := SemCtx.mk' ((List.range 9).map fun k => { sceneAt k with structures := [lane7, cross] }) ρ β
#guard (eval cgeo 8 (.existsRegion (.lit "crosswalk") "r" (.cmp (.measure "st_region_geometry_distance" [X, .var "r"]) .le (.lit (metres 30) .metre)))).v = .t   -- 15 → 40: 25 m
#guard (eval cgeo 0 (.existsRegion (.lit "crosswalk") "r" (.cmp (.measure "st_region_geometry_distance" [X, .var "r"]) .le (.lit (metres 30) .metre)))).v = .f   -- 0 → 40
#guard (eval c 0 (.existsRegion (.lit "lane") "r" (.cmp (.measure "st_region_geometry_distance" [X, .var "r"]) .le (.lit (metres 30) .metre)))).v = .u       -- lane 7 has no geometry

-- a quantifier over a kind the source cannot tell: unknown where such a region could decide it
def roadway5 : Structure := { id := 5, kind := .roadway, unobservedKinds := [.highway] }
def cunk : SemCtx := SemCtx.mk' ((List.range 9).map fun k =>
  { sceneAt k with structures := [lane7, roadway5], occupies := [(1, 7), (2, 7), (1, 5)] }) ρ β
#guard (eval cunk 0 (.existsRegion (.lit "highway") "h" (.atom "rel_occupies" [X, .var "h"] []))).v = .u
#guard (eval cunk 0 (.existsRegion (.lit "highway") "h" (.atom "rel_occupies" [Y, .var "h"] []))).v = .f
#guard (eval cunk 0 (.forallRegion (.lit "highway") "h" (.atom "rel_occupies" [Y, .var "h"] []))).v = .u
#guard (eval cunk 0 (.existsRegion (.lit "roadway") "h" (.atom "rel_occupies" [X, .var "h"] []))).v = .t
-- the kind atom itself is unknown on such a region, so a body that restates it stays unknown
#guard (eval cunk 0 (.atom "st_highway" [.nat 5] [])).v = .u
#guard (eval cunk 0 (.atom "st_highway" [.nat 7] [])).v = .f
#guard (eval cunk 0 (.existsRegion (.lit "highway") "h"
          (.and (.atom "st_highway" [.var "h"] []) (.atom "rel_occupies" [X, .var "h"] [])))).v = .u
#guard v 0 (.existsRegion (.lit "highway") "h" .tt) = .f          -- no region could be one
def cdev : SemCtx := SemCtx.mk' ((List.range 9).map fun k =>
  { sceneAt k with devices := [{ sig9 .circularRed with unobservedKinds := [.stopSign] }] }) ρ β
#guard (eval cdev 0 (.existsDevice (.lit "stop_sign") "d" .tt)).v = .u

-- static analysis
#guard (Formula.atoms (.and stopped (.cmp (.measure "kin_speed" [X]) .gt (mps 9)))).eraseDups = ["kin_time", "kin_speed"]
#guard (Formula.params stopped) = ["p.stop_speed"]
#guard (Formula.composed (.and (.rule "a" []) (.rule "b" []))) = ["a", "b"]

end TrafficSpec.Tests.Semantics
