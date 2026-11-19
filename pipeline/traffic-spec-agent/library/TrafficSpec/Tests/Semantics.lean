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
-- an aggregate id is collected at every position of a formula or a term that carries one
private def sr (id : String) : Term := .sinceRise (agg "x" id)
private def q : Term := .param "p"
#guard Formula.aggregateIds (.cmp (sr "A") .le q) = ["A"]
#guard Formula.aggregateIds (.cmp q .le (sr "A")) = ["A"]
#guard Formula.aggregateIds (.cmp (.distanceWhile "x" (agg "x" "A")) .le q) = ["A"]
#guard Formula.aggregateIds (.cmp (.aggregate .count "u" (agg "u" "A") q) .le q) = ["A"]
#guard Formula.aggregateIds (.cmp (.aggregate .max "u" .tt (sr "A")) .le q) = ["A"]
#guard Formula.aggregateIds (.cmp (.cond (agg "x" "A") q q) .le q) = ["A"]
#guard Formula.aggregateIds (.cmp (.cond .tt (sr "A") q) .le q) = ["A"]
#guard Formula.aggregateIds (.cmp (.cond .tt q (sr "A")) .le q) = ["A"]
#guard ([.add, .sub, .mul, .div] : List (Term → Term → Term)).all fun k =>
  Formula.aggregateIds (.cmp (k (sr "A") (sr "B")) .le q) = ["A", "B"]
#guard ([.neg, .abs] : List (Term → Term)).all fun k => Formula.aggregateIds (.cmp (k (sr "A")) .le q) = ["A"]
#guard Formula.aggregateIds (.cmp (.quantity "c" [] [sr "A"]) .le q) = ["A"]
#guard Formula.aggregateIds (.atom "rel_occupies" [.var "x", .var "y"] [sr "A"]) = ["A"]
#guard Formula.aggregateIds (.atom "ru_aggregate" [.var "x", .lit "A"] [sr "B"]) = ["A", "B"]
#guard Formula.aggregateIds (.derived "c" [] [sr "A"]) = ["A"]
#guard Formula.aggregateIds (.holdsFor .time (sr "A") "x" (agg "x" "B")) = ["A", "B"]
#guard Formula.aggregateIds (.within .time (sr "A") "x" (agg "x" "B")) = ["A", "B"]
#guard Formula.aggregateIds (.untilWithin .time (sr "A") "x" (agg "x" "B") (agg "x" "C")) = ["A", "B", "C"]
#guard Formula.aggregateIds (.atLast .path (sr "A") "x" (agg "x" "B") (agg "x" "C")) = ["A", "B", "C"]
#guard Formula.aggregateIds (.count (.cmp (sr "A") .le q) (.cmp (sr "B") .le q) .ge 1) = ["A", "B"]
#guard Formula.aggregateIds (.forallRegion (.lit "lane") "r" (.existsDevice (.lit "sign") "d" (.cmp (sr "A") .le q))) = ["A"]
-- the reading check holds an aggregate named inside a term as it holds one named by a formula
def aggTermRule : Rule :=
  { id := "t_agg_term", laws := [], binders := [{ name := "x", cls := agg "x" "D-1::vehicle" }]
    applicability := .tt, obligation := .cmp (.sinceRise (agg "x" "D-9::none")) .ge (.lit Q.zero .second) }
#guard Rule.checkReading [aggTermRule] aggTermRule ρa = ["t_agg_term: aggregate `D-9::none` is not declared by the reading"]
-- the reading check reads each rule with its concept calls expanded: at any depth, in a formula or
-- a quantity concept, through a composed rule, with the id a call gives a literal formal
private def cMember : Concept :=
  { id := "drv.audit.member", contract := "", args := [("u", .track)], params := []
    body := .formula (agg "u" "DEF-AUDIT::member") }
private def cNested : Concept :=
  { id := "drv.audit.nested", contract := "", args := [("u", .track)], params := []
    body := .formula (.derived "drv_audit_member" [.var "u"] []) }
private def cSpeed : Concept :=
  { id := "drv.audit.speed", contract := "", args := [("u", .track)], params := []
    body := .quantity (.cond (agg "u" "DEF-AUDIT::member") (.measure "kin_speed" [.var "u"]) (.measure "kin_speed" [.var "u"])) }
private def cOf : Concept :=
  { id := "drv.audit.of", contract := "", args := [("u", .track), ("w", .literal ["DEF-AUDIT::member"])], params := []
    body := .formula (.atom "ru_aggregate" [.var "u", .var "w"] []) }
private def auditCs : List Concept := [cMember, cNested, cSpeed, cOf]
private def callRule (id : String) (φ : Formula) : Rule :=
  { id := id, laws := [], binders := [{ name := "x", cls := .tt }], applicability := .tt, obligation := φ }
private def undeclared (who : String) : List String := [s!"{who}: aggregate `DEF-AUDIT::member` is not declared by the reading"]
private def ρMember : Reading := { ρ with aggregates := [{ id := "DEF-AUDIT::member", included := ["ru.bus"] }] }
private def rCall : Rule := callRule "audit" (.derived "drv_audit_member" [.var "x"] [])
private def rNested : Rule := callRule "audit_nested" (.derived "drv_audit_nested" [.var "x"] [])
private def rSpeed : Rule := callRule "audit_speed" (.cmp (.quantity "drv_audit_speed" [.var "x"] []) .le (.lit Q.zero .metrePerSecond))
private def rOf : Rule := callRule "audit_of" (.derived "drv_audit_of" [.var "x", .lit "DEF-AUDIT::member"] [])
private def rComposes : Rule := callRule "audit_composes" (.rule "audit" [("x", "x")])
#guard Rule.checkReading [rCall] rCall {} auditCs = undeclared "audit"
#guard Rule.checkReading [rCall] rCall ρMember auditCs = []
#guard Rule.checkReading [rNested] rNested {} auditCs = undeclared "audit_nested"
#guard Rule.checkReading [rSpeed] rSpeed {} auditCs = undeclared "audit_speed"
#guard Rule.checkReading [rOf] rOf {} auditCs = undeclared "audit_of"
#guard Rule.checkReading [rCall, rComposes] rComposes {} auditCs = undeclared "audit"
#guard [rCall, rNested, rSpeed, rOf, rComposes].map (Concept.ruleAggregateIds auditCs) =
  [["DEF-AUDIT::member"], ["DEF-AUDIT::member"], ["DEF-AUDIT::member"], ["DEF-AUDIT::member"], []]
#guard auditCs.map (Concept.aggregateIds auditCs) = List.replicate 4 ["DEF-AUDIT::member"]
#guard Concept.checkReading auditCs cNested {} = undeclared "drv.audit.nested"
#guard Concept.checkReading auditCs cSpeed ρMember = []
-- an aggregate named in a heading change's onset or step bound is collected, held by the reading
-- check, and held through a concept whose body takes the heading change since it
#guard Formula.aggregateIds (.cmp (.headingSince "x" (sr "A") (agg "x" "B")) .le q) = ["A", "B"]
#guard Formula.aggregateIds (.cmp (.abs (.headingSince "x" q (agg "x" "A"))) .le q) = ["A"]
private def hsAgg : Term := .headingSince "x" (.lit (Q.ofInt 1) .second) (agg "x" "DEF-AUDIT::member")
private def rHs : Rule := callRule "audit_hs" (.cmp (.abs hsAgg) .le (.lit Q.zero .degree))
#guard Rule.checkReading [rHs] rHs {} = undeclared "audit_hs"
#guard Rule.checkReading [rHs] rHs ρMember = []
private def cTurn : Concept :=
  { id := "drv.audit.turn", contract := "", args := [("u", .track)], params := [⟨"s", .second⟩]
    body := .quantity (.headingSince "u" (.param "s") (agg "u" "DEF-AUDIT::member")) }
private def rTurn : Rule :=
  callRule "audit_turn" (.cmp (.quantity "drv_audit_turn" [.var "x"] [.lit (Q.ofInt 1) .second]) .le (.lit Q.zero .degree))
#guard Rule.checkReading [rTurn] rTurn {} [cTurn] = undeclared "audit_turn"
#guard Rule.checkReading [rTurn] rTurn ρMember [cTurn] = []
#guard Concept.ruleAggregateIds [cTurn] rTurn = ["DEF-AUDIT::member"]
#guard Concept.aggregateIds [cTurn] cTurn = ["DEF-AUDIT::member"]
#guard Concept.checkReading [cTurn] cTurn {} = undeclared "drv.audit.turn"
#guard Concept.checkReading [cTurn] cTurn ρMember = []
-- a heading is read as a direction, whatever the length a source writes
def τheading : Trace := [{ t := 0, users := [{ track := 1, kin := { heading := some (Q.ofInt 3, Q.ofInt 4) } }] }]
#guard (evalTAll (SemCtx.mk' τheading ρ β) (.measure "kin_heading" [.var "x", .lit "x"])).toList.map (·.toOption.map (Q.eq · (Q.mk' 3 5))) = [some true]
#guard (evalTAll (SemCtx.mk' τheading ρ β) (.measure "kin_heading" [.var "x", .lit "y"])).toList.map (·.toOption.map (Q.eq · (Q.mk' 4 5))) = [some true]

-- a designated direction is read as a heading is: normalised, at any length, unknown only when zero.
-- The body `v · d ≥ c · speed` then compares the cosine between velocity and direction with `c`.
def micro (n : Int) : Q := Q.mk' n 1000000
def vecRead (d : Vec) : Option (Q × Q) := Geom.unit d
#guard (vecRead (Q.ofInt 6, Q.ofInt 8)).map (fun (a, b) => Q.eq a (Q.mk' 3 5) && Q.eq b (Q.mk' 4 5)) = some true
#guard (vecRead (micro 999999, Q.zero)).map (fun (a, b) => Q.eq a (Q.ofInt 1) && Q.isZero b) = some true
#guard (vecRead (Q.mk' 1 10000000, Q.zero)).map (fun (a, b) => Q.eq a (Q.ofInt 1) && Q.isZero b) = some true
#guard vecRead (micro 1, micro 1) = vecRead (Q.ofInt 1, Q.ofInt 1)
#guard vecRead (Q.zero, Q.zero) = none
#guard (vecRead (Q.ofInt 1, Q.ofInt 1)).map (fun (a, _) => Q.le (Q.mk' 7071067 10000000) a && Q.lt a (Q.mk' 7071083 10000000)) = some true
def τheadingTiny : Trace := [{ t := 0, users := [{ track := 1, kin := { heading := some (Q.mk' 1 10000000, Q.zero) } }] }]
#guard (evalTAll (SemCtx.mk' τheadingTiny ρ β) (.measure "kin_heading" [.var "x", .lit "x"])).toList.map (·.toOption.map (Q.eq · (Q.ofInt 1))) = [some true]
def τdir (d : Option Vec) (vel : Vec) : Trace :=
  [{ t := 0, users := [{ track := 1, kin := { velocity := some vel, speed := some (Geom.norm vel) } }],
     structures := [{ id := 7, kind := .lane, lane := some { direction := d } }] }]
def agrees (c : Q) : Formula :=
  let comp (k : String) : Term := .mul (.measure "kin_velocity" [.var "x", .lit k]) (.measure "st_lane_direction" [.nat 7, .lit k])
  .cmp (.add (comp "x") (comp "y")) .ge (.mul (.lit c .ratio) (.measure "kin_speed" [.var "x"]))
def agreeOn (d : Option Vec) (vel : Vec) (c : Q) : Tri := (eval (SemCtx.mk' (τdir d vel) ρ β) 0 (agrees c)).v
def v34 : Vec := (Q.ofInt 3, Q.ofInt 4)
def v43 : Vec := (Q.ofInt 4, Q.ofInt 3)
def along (x : Q) : Option Vec := some (x, Q.zero)
-- velocity (3, 4) against the x axis: cosine 3/5, whatever the direction's length
#guard [along (Q.ofInt 1), along (Q.ofInt 2), along (Q.mk' 1 2)].all fun d =>
  agreeOn d v34 (Q.mk' 3 5) == .t && agreeOn d v34 (Q.mk' 61 100) == .f && agreeOn d v34 (Q.mk' 4 5) == .f
-- a non-axis direction: (1, 1) at 45°, cosine 7 / (5√2) ≈ 0.98995, at any scale
#guard [(Q.ofInt 1, Q.ofInt 1), (Q.ofInt 5, Q.ofInt 5), (micro 1, micro 1)].all fun d =>
  agreeOn (some d) v34 (Q.mk' 98 100) == .t && agreeOn (some d) v34 (Q.mk' 99 100) == .f
-- a direction along the velocity: cosine exactly 1, equality decides true
#guard agreeOn (some (Q.ofInt 6, Q.ofInt 8)) v34 (Q.ofInt 1) = .t
#guard agreeOn (some (Q.ofInt 6, Q.ofInt 8)) v34 (Q.mk' 1000001 1000000) = .f
-- a near-unit direction: velocity (4, 3), speed 5, cosine exactly 0.8
#guard agreeOn (along (micro 999999)) v43 (Q.mk' 4 5) = .t
#guard agreeOn (along (micro 999999)) v43 (Q.mk' 800001 1000000) = .f
-- tiny directions read as their unit direction
#guard agreeOn (along (Q.mk' 1 10000000)) v43 (Q.mk' 4 5) = agreeOn (along (Q.ofInt 1)) v43 (Q.mk' 4 5)
#guard agreeOn (along (Q.mk' 1 10000000)) v43 (Q.mk' 4 5) = .t
#guard [Q.mk' 98 100, Q.mk' 99 100].all fun c => agreeOn (some (micro 1, micro 1)) v34 c == agreeOn (some (Q.ofInt 1, Q.ofInt 1)) v34 c
-- a negative bound: velocity (−4, 3) against the x axis, cosine −0.8
def vBack : Vec := (Q.ofInt (-4), Q.ofInt 3)
#guard [along (Q.ofInt 1), along (Q.ofInt 2), along (micro 999999)].all fun d =>
  agreeOn d vBack (Q.mk' (-4) 5) == .t && agreeOn d vBack (Q.mk' (-79) 100) == .f && agreeOn d vBack (Q.mk' (-81) 100) == .t
-- no direction to read: zero or missing
#guard agreeOn (some (Q.zero, Q.zero)) v34 (Q.mk' 1 2) = .u
#guard agreeOn none v34 (Q.mk' 1 2) = .u

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
#guard v 0 (.cmp (.measure "rel_surface_gap" [X, Y, .lit "lateral"]) .eq (.lit Q.zero .metre)) = .t
#guard v 0 (.cmp (.measure "rel_surface_gap" [X, Y]) .eq (.lit (Q.mk' 255 10) .metre)) = .t   -- the distance
#guard why 0 (.cmp (.measure "rel_surface_gap" [X, Y, .lit "min"]) .eq (.lit Q.zero .metre)) = [.malformed "gap component"]
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
#guard v 1 stopped = .f                       -- the window reaches before the trace; speed 8 fails inside it
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
-- a 900 ms window over scenes 500 ms apart is not adequately sampled: unknown even where ψ held in it
#guard v 3 (.atLast .time (ms 900) "x" fast4 (pathGe 0)) = .u
#guard why 3 (.atLast .time (ms 900) "x" fast4 (pathGe 0)) = [.samplingGap "atLast"]
#guard why 8 (.atLast .time (ms 900) "x" (.cmp (.measure "kin_speed" [X]) .ge (mps 20)) (pathGe 0)) = [.samplingGap "atLast"]
#guard v 3 (.atLast .time (sec 1) "x" fast4 (pathGe 9)) = .t          -- the same witness in an adequately sampled window
#guard v 8 (.atLast .path (m 3) "y" .tt .tt) = .u                    -- the window has no path length to measure
#guard v 8 (.atLast .time (sec 3) "x" (.atom "sig_brake_lamp" [X] []) (pathGe 0)) = .u   -- ψ unknown at the last observation

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

-- `sig_warning_lamp` in its three forms, and the duration-limit measure, through the evaluator.
private def lampCtx (ls : Option (List WarningLamp)) : SemCtx :=
  SemCtx.mk' [{ t := 0, users := [{ track := 1, sig := { warningLamps := ls } }] }] {} β
private def lamp (args : List Arg) : Formula := .atom "sig_warning_lamp" (X :: args) []
private def redRear : WarningLamp := { colour := .red, mode := .flashing, facing := .rear }
private def whiteFront : WarningLamp := { colour := .white, mode := .flashing, facing := .front }
#guard evalTri (lampCtx (some [redRear, whiteFront])) 0 (lamp [.lit "red", .lit "flashing", .lit "front"]) = .f
#guard evalTri (lampCtx (some [redRear])) 0 (lamp [.lit "red", .lit "flashing", .lit "front"]) = .f
#guard evalTri (lampCtx none) 0 (lamp [.lit "red", .lit "flashing", .lit "front"]) = .u
#guard evalTri (lampCtx (some [redRear, whiteFront])) 0 (lamp [.lit "red", .lit "flashing", .lit "rear"]) = .t
#guard evalTri (lampCtx (some [redRear, whiteFront])) 0 (lamp [.lit "red", .lit "flashing"]) = .t
#guard evalTri (lampCtx (some [redRear, whiteFront])) 0 (lamp [.lit "red"]) = .t
#guard (eval (lampCtx (some [redRear])) 0 (lamp [.lit "red", .lit "flashing", .lit "up"])).why = [.malformed "up"]
#guard atomArgSorts "sig_warning_lamp" = some [some .track, none, none, none]
private def limitCtx (cd : Option Conditions) : SemCtx :=
  SemCtx.mk' [{ t := 0, devices := [{ id := 5, kind := .zoneSign, conditions := cd }] }] {} (({} : Binding).bind "d" (.device 5))
private def underLimit : Formula := .cmp (.lit (minutes 20) .second) .le (.measure "dev_zone_sign_duration_limit" [.var "d"])
#guard evalTri (limitCtx (some { durationLimit := some (minutes 30) })) 0 underLimit = .t
#guard evalTri (limitCtx (some { durationLimit := some (minutes 10) })) 0 underLimit = .f
#guard evalTri (limitCtx (some {})) 0 underLimit = .u
#guard evalTri (limitCtx none) 0 underLimit = .u
#guard knowsAtom "dev_zone_sign_duration_limit"

-- A count's bound is a literal in unit count; a zero bound is none, as a zero quantity is none.
#guard Formula.literals (.count .tt .ff .le 1) = [(Q.ofInt 1, .count)]
#guard Formula.literals (.count .tt .ff .ge 2) = [(Q.ofInt 2, .count)]
#guard Formula.literals (.count .tt .ff .eq 0) = []
#guard Formula.literals (.count (.cmp (.measure "kin_speed" [X]) .ge (mps 3)) .tt .ge 2) = [(metresPerSecond 3, .metrePerSecond), (Q.ofInt 2, .count)]

-- `rel_contact_structure` through the evaluator, with its sorts.
private def contactCtx (bd : Option (List Vec)) : SemCtx :=
  SemCtx.mk' [{ (sceneAt 0) with structures := [{ id := 30, kind := .obstruction, boundary := bd }] }] ρ (β.bind "r" (.region 30))
private def touches : Formula := .atom "rel_contact_structure" [X, .var "r"] []
#guard evalTri (contactCtx (some [(metres 2, metres (-1)), (metres 3, metres (-1)), (metres 3, metres 1)])) 0 touches = .t
#guard evalTri (contactCtx (some [(metres 5, metres (-1)), (metres 6, metres (-1)), (metres 6, metres 1)])) 0 touches = .f
#guard evalTri (contactCtx none) 0 touches = .u
#guard atomArgSorts "rel_contact_structure" = some [some .track, some .region]
#guard atomArgSorts "rel_contact" = some [some .track, some .track]

end TrafficSpec.Tests.Semantics
