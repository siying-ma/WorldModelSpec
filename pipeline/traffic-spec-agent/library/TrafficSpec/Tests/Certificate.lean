import TrafficSpec.Core.Evidence.Certificate
import TrafficSpec.Tests.Semantics
namespace TrafficSpec.Tests.Certificate
open TrafficSpec Units Lean

def has (msgs : List String) (frag : String) : Bool := msgs.any fun m => (m.splitOn frag).length > 1

-- ---------------------------------------------------------------------------------------------
-- The strict decoder is the encoder's inverse: every constructor round-trips.
-- ---------------------------------------------------------------------------------------------
def roundTrips (φ : Formula) : Bool :=
  match Decode.formula "f" φ.toJson with
  | .ok ψ => ψ.toJson == φ.toJson
  | .error _ => false

def speed : Term := .measure "kin_speed" [.var "v"]
def everyTerm : List Term :=
  [ .lit (Q.mk' (-3) 2) .metrePerSecond, .param "p.x", speed, .quantity "prim_heading_change" [.var "v"] [.lit (Q.ofInt 2) .second]
  , .distanceWhile "v" .tt, .sinceRise .ff, .aggregate .max "u" .tt (.measure "kin_speed" [.var "u"])
  , .add speed speed, .sub speed speed, .mul speed speed, .div speed (.lit (Q.ofInt 2) .ratio), .neg speed, .abs speed
  , .cond (.atom "env_darkness" [] []) speed (.lit Q.zero .metrePerSecond) ]
def everyFormula : List Formula :=
  [ .tt, .ff, .atom "rel_occupies" [.var "v", .lit "x", .nat 3] [.lit (Q.ofInt 1) .ratio], .asm "asm.a", .same (.var "a") (.var "b")
  , .not .tt, .and .tt .ff, .or .tt .ff, .implies .tt .ff, .always .tt, .eventually .ff, .until .tt .ff, .since .tt .ff
  , .holdsFor .time (.lit (Q.ofInt 3) .second) "v" .tt, .within .path (.param "p.d") "v" .ff
  , .untilWithin .time (.lit (Q.ofInt 3) .second) "v" .tt .ff, .atLast .path (.lit (Q.ofInt 3) .metre) "v" .tt .ff
  , .count .tt .ff .ge 2, .rises .tt, .definedWhen .tt .ff, .derived "prim_conditions_hold" [.var "d", .var "v"] []
  , .rule "r/x" [("a", "v")], .ruleApplies "r/x" [("a", "v")], .existsUser "u" .tt, .forallUser "u" .ff
  , .existsRegion (.lit "lane") "r" .tt, .forallRegion (.lit "lane") "r" .ff, .existsDevice (.lit "stop_sign") "d" .tt
  , .forallDevice (.var "k") "d" .ff ]
  ++ everyTerm.map fun t => .cmp t .lt t
#guard everyFormula.all roundTrips
#guard [Tests.Semantics.aggRule.obligation, Tests.Semantics.aggRule.binders.head!.cls].all roundTrips

-- rejections: an extra key, a missing key, a wrong length, a null, a zero denominator, a fractional
-- numerator, an unknown spelling
def rejects (text : String) : Bool :=
  match Json.parse text with
  | .ok j => (Decode.formula "f" j).toOption.isNone
  | .error _ => true
#guard rejects "{\"not\": \"tt\", \"x\": 1}"
#guard rejects "{\"atom\": \"env_darkness\", \"args\": []}"
#guard rejects "{\"and\": [\"tt\"]}"
#guard rejects "{\"or\": []}"
#guard rejects "{\"implies\": [\"tt\", \"ff\", \"tt\"]}"
-- `and` and `or` read two or more operands, joined to the right; the export is the nested form
def readsAs (text : String) (φ : Formula) : Bool :=
  match Json.parse text with
  | .ok j => match Decode.formula "f" j with | .ok ψ => ψ.toJson == φ.toJson | .error _ => false
  | .error _ => false
#guard readsAs "{\"and\": [\"tt\", \"ff\", \"tt\"]}" (.and .tt (.and .ff .tt))
#guard readsAs "{\"or\": [\"ff\", \"ff\", \"tt\", \"ff\"]}" (.or .ff (.or .ff (.or .tt .ff)))
#guard readsAs "{\"and\": [\"tt\", {\"or\": [\"ff\", \"tt\", \"ff\"]}]}" (.and .tt (.or .ff (.or .tt .ff)))
#guard rejects "{\"not\": null}"
#guard rejects "{\"cmp\": \"lt\", \"lhs\": {\"lit\": {\"num\": 1, \"den\": 0}, \"unit\": \"metre\"}, \"rhs\": {\"lit\": {\"num\": 1, \"den\": 1}, \"unit\": \"metre\"}}"
#guard rejects "{\"cmp\": \"lt\", \"lhs\": {\"lit\": {\"num\": 1.5, \"den\": 2}, \"unit\": \"metre\"}, \"rhs\": {\"lit\": {\"num\": 1, \"den\": 1}, \"unit\": \"metre\"}}"
#guard rejects "\"true\""
#guard !rejects "{\"cmp\": \"gt\", \"lhs\": {\"measure\": \"kin_speed\", \"args\": [{\"var\": \"v\"}]}, \"rhs\": {\"lit\": {\"num\": 6, \"den\": 4}, \"unit\": \"metre_per_second\"}}"
-- a decoded rational is normalized
#guard match Json.parse "{\"lit\": {\"num\": 6, \"den\": 4}, \"unit\": \"metre\"}" with
  | .ok j => match Decode.term "t" j with | .ok (.lit q _) => q.num == 3 && q.den == 2 | _ => false
  | .error _ => false

-- ---------------------------------------------------------------------------------------------
-- Case.check: one rejection per rule
-- ---------------------------------------------------------------------------------------------
def lit (n : Int) (u : PUnit') : Term := .lit (Q.ofInt n) u
def c0 (φ : Formula) (entities : List (String × Val) := [("lane", .region 7), ("other", .track 2)]) : Case := ⟨φ, entities, 1000⟩
def errs (φ : Formula) (entities : List (String × Val) := [("lane", .region 7), ("other", .track 2)]) : List String :=
  (c0 φ entities).check ["v"]
-- a measure written as a primitive is named as a measure, once
#guard (errs (.cmp (.quantity "kin_speed" [.var "v"] []) .gt (lit 1 .metrePerSecond))).filter (has [·] "kin_speed") ==
  ["`kin_speed` is a measure, not a primitive: write it {\"measure\": \"kin_speed\", \"args\": [...]}"]
#guard errs (.cmp speed .gt (lit 12 .metrePerSecond)) = []
-- a curvature is compared with a literal per metre
#guard errs (.cmp (.measure "st_curvature" [.var "lane"]) .gt (.lit (Q.mk' 1 1000) .perMetre)) = []
#guard match Lean.Json.parse "{\"lit\": {\"num\": 1, \"den\": 500}, \"unit\": \"per_metre\"}" with
  | .ok j => match Decode.term "t" j with | .ok (.lit q .perMetre) => q.num == 1 && q.den == 500 | _ => false
  | .error _ => false
#guard errs (.and (.atom "rel_occupies" [.var "v", .var "lane"] []) (.cmp (.measure "rel_centre_distance" [.var "v", .var "other"]) .lt (lit 20 .metre))) = []
#guard has (errs (.asm "asm.a")) "never an assumption"
#guard has (errs (.cmp speed .gt (.param "p.limit"))) "never a parameter"
#guard has (errs (.rule "r/x" [("a", "v")])) "names no other rule"
#guard has (errs (.derived "drv_motion_stop" [.var "v"] [])) "names no concept"
#guard has (errs (.cmp (.div speed speed) .gt (lit 1 .ratio))) "divides by something other than a non-zero literal"
#guard has (errs (.atom "ru_aggregate" [.var "v", .lit "D-1::vehicle"] [])) "never a legal aggregate"
#guard has (errs (.atom "ru_unicorn" [.var "v"] [])) "ru_unicorn"
#guard has (errs (.atom "rel_occupies" [.var "v", .lit "7"] [])) "literal `7`"
#guard has (errs (.atom "rel_occupies" [.var "v", .nat 7] [])) "number `7`"
#guard has (errs (.cmp speed .gt (lit 12 .metre))) "compares m·s^-1 with m"
#guard has (errs (.cmp (.add speed (lit 1 .second)) .gt (lit 12 .metrePerSecond))) "adds or subtracts"
#guard errs (.cmp (.measure "st_curvature" [.var "lane"]) .lt (.div (lit 1 .ratio) (lit 50 .metre))) = []
#guard has (errs (.holdsFor .time (lit 5 .metre) "v" .tt)) "measured in time has a length in m"
#guard has (errs (.derived "prim_closest_approach_within" [.var "v", .var "other"] [lit 3 .metre])) "a parameter in m where s is required"
#guard errs (.derived "prim_closest_approach_within" [.var "v", .var "other"] [lit 3 .second]) = []
#guard has (errs (.cmp (.quantity "prim_conditions_hold" [.var "lane", .var "v"] []) .gt (lit 0 .ratio))) "Boolean primitive"
#guard has (errs .tt [("lane", .region 7), ("lane", .region 8)]) "declared twice"
#guard has (errs .tt [("v", .track 1)]) "has the name of a binder"
#guard has (errs (.existsRegion (.lit "lane") "lane" .tt)) "a quantifier binds `lane`"
#guard has (errs (.cmp (.aggregate .count "v" .tt speed) .gt (lit 0 .count))) "a quantifier binds `v`"

-- ---------------------------------------------------------------------------------------------
-- DimCheck: the units of rules and concept bodies, apart from a case's prohibitions
-- ---------------------------------------------------------------------------------------------
def ρDim : Reading := { params := [{ name := "p.limit", value := Q.ofInt 15, unit := .metrePerSecond },
                                   { name := "p.horizon", value := Q.ofInt 3, unit := .second }] }
def qConcept : Concept := { id := "drv.motion.reach", contract := "c", args := [("u", .track)],
                            params := [⟨"t", .second⟩], body := .quantity (.mul speed (.param "t")) }
def envR : DimEnv := DimCheck.envOf ρDim [qConcept]
def dimErrs (φ : Formula) : List DimError := DimCheck.errors envR φ
-- what a case may not state is no unit defect in a rule
#guard dimErrs (.and (.asm "asm.a") (.atom "ru_aggregate" [.var "v", .lit "D-1::vehicle"] [])) = []
#guard dimErrs (.and (.rule "r/x" [("a", "v")]) (.cmp speed .lt (.param "p.limit"))) = []
#guard dimErrs (.cmp (.quantity "drv_motion_reach" [.var "v"] [.param "p.horizon"]) .lt (lit 40 .metre)) = []
#guard DimCheck.concept (DimCheck.envOf ρDim [qConcept] qConcept.params) qConcept = []
-- units only
#guard (dimErrs (.cmp speed .gt (lit 12 .metre))).map DimError.tag = ["mismatch"]
#guard (dimErrs (.holdsFor .time (lit 5 .metre) "v" .tt)).map DimError.tag = ["mismatch"]
#guard (dimErrs (.cmp (.quantity "drv_motion_reach" [.var "v"] [.param "p.horizon"]) .lt (lit 40 .second))).map DimError.tag = ["mismatch"]
#guard (dimErrs (.cmp (.quantity "drv_motion_reach" [.var "v"] [.param "p.limit"]) .lt (lit 40 .metre))).map DimError.tag = ["mismatch"]
#guard (dimErrs (.cmp speed .lt (.param "p.unknown"))).map DimError.tag = ["unknown"]
-- a valid zero and an illegal division
#guard dimErrs (.cmp speed .gt (lit 0 .metrePerSecond)) = []
#guard (dimErrs (.cmp (.div speed (lit 0 .ratio)) .gt (lit 1 .metrePerSecond))).map DimError.tag = ["zero_division"]
#guard dimErrs (.cmp (.div speed (.param "p.limit")) .gt (lit 1 .ratio)) = []

-- ---------------------------------------------------------------------------------------------
-- Case.eval: holds, fails, undecided at the instant
-- ---------------------------------------------------------------------------------------------
def τ : Trace :=
  [ { t := 0, users := [{ track := 1, classes := some [.motorVehicle], kin := { speed := some (metresPerSecond 20) } }] }
  , { t := 1000, users := [{ track := 1, classes := some [.motorVehicle], kin := { speed := some (metresPerSecond 20) } }] } ]
def S : Grounding.Setup := Grounding.Setup.mk' [] τ {} Q.zero
#guard (Case.eval S [("v", 1)] (c0 (.cmp speed .gt (lit 12 .metrePerSecond)) [])).v == .t
#guard (Case.eval S [("v", 1)] (c0 (.cmp speed .gt (lit 50 .metrePerSecond)) [])).v == .f
#guard (Case.eval S [("v", 1)] (c0 (.cmp (.measure "kin_accel_longitudinal" [.var "v"]) .gt (lit 0 .metrePerSecondSq)) [])).v == .u

-- ---------------------------------------------------------------------------------------------
-- record: one divergence end to end, with an aggregate the rule's binder reads
-- ---------------------------------------------------------------------------------------------
def rSpeed : Rule :=
  { id := "t/speed", laws := [], binders := [{ name := "v", cls := .atom "ru_aggregate" [.var "v", .lit "D-1::vehicle"] [] }]
    applicability := .tt, obligation := .cmp speed .lt (lit 15 .metrePerSecond) }
def ρ : Reading := { aggregates := [{ id := "D-1::vehicle", included := ["ru.motor_vehicle"] }] }
def traceText : String :=
  "{\"scenes\": [{\"t\": 0, \"users\": [{\"track\": 1, \"classes\": [\"motor_vehicle\"], \"kin\": {\"speed\": 20}}]}, " ++
  "{\"t\": 1000, \"users\": [{\"track\": 1, \"classes\": [\"motor_vehicle\"], \"kin\": {\"speed\": 20}}]}]}"
def caseText : String :=
  "{\"case\": {\"cmp\": \"gt\", \"lhs\": {\"measure\": \"kin_speed\", \"args\": [{\"var\": \"v\"}]}, " ++
  "\"rhs\": {\"lit\": {\"num\": 18, \"den\": 1}, \"unit\": \"metre_per_second\"}}, \"entities\": {}, \"at\": 1000}"
def rec : Json := Certificate.record [rSpeed] rSpeed ρ 1 traceText caseText [("v", 1)]
#guard rec.getObjValD "schema" == Json.str "certificate-run/1"
#guard rec.getObjValD "lint_errors" == Json.arr #[]
#guard (rec.getObjValD "case_value").getObjValD "value" == Json.str "true"
#guard (rec.getObjValD "rule_result").getObjValD "verdict" == Json.str "violated"
#guard rec.getObjValD "sensitivity_overrides" == Json.arr #[
  Json.mkObj [("aggregate_id", "D-1::vehicle"), ("track", toJson (1 : Nat)), ("original", "true"), ("override", toJson true), ("rule_verdict", "violated")],
  Json.mkObj [("aggregate_id", "D-1::vehicle"), ("track", toJson (1 : Nat)), ("original", "true"), ("override", toJson false), ("rule_verdict", "not_applicable")]]
-- a case that does not hold stops before the rule; a trace that does not decode stops the lint
def recFalse : Json := Certificate.record [rSpeed] rSpeed ρ 2 traceText (caseText.replace "18" "50") [("v", 1)]
#guard (recFalse.getObjValD "case_value").getObjValD "value" == Json.str "false"
#guard recFalse.getObjValD "rule_result" == Json.null
def recBad : Json := Certificate.record [rSpeed] rSpeed ρ 3 "{\"scenes\": []}" caseText [("v", 1)]
#guard recBad.getObjValD "lint_errors" == Json.null
#guard recBad.getObjValD "witness_errors" == Json.null
#guard recBad.getObjValD "case_check_errors" == Json.arr #[]
#guard recBad.getObjValD "case_value" == Json.null
def recCase : Json := Certificate.record [rSpeed] rSpeed ρ 4 traceText "{\"case\": {\"not\": null}, \"entities\": {}, \"at\": 1000}" [("v", 1)]
#guard recCase.getObjValD "canonical_case" == Json.null
#guard recCase.getObjValD "witness_errors" == Json.null
#guard recCase.getObjValD "lint_errors" == Json.arr #[]

end TrafficSpec.Tests.Certificate
