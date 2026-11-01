import TrafficSpec.Core.Runtime.Monitor
import TrafficSpec.Core.Runtime.Decode
import TrafficSpec.Core.Evidence.Builders
import TrafficSpec.Core.Evidence.Adequacy
import TrafficSpec.Core.Evidence.Certificate
import TrafficSpec.Tests.Semantics
namespace TrafficSpec.Tests.Intentions
open Lean TrafficSpec Units TrafficSpec.Grounding

-- A junction (20) and two motor vehicles (1, 2) at every scene; the ids are test labels.
private def X : Arg := .var "x"
private def J : Arg := .var "j"
def j20 : Structure := { id := 20, kind := .intersection }
def mv (v : String) : Formula := .atom "ru_motor_vehicle" [.var v] []
def turn : IntId := "int.turn_left"
def declared (b : Bool) : List DeclaredIntent := [{ vehicle := 1, target := 20, values := [(turn, b)] }]
def base (k : Nat) : Scene := { Tests.Semantics.sceneAt k with structures := [Tests.Semantics.lane7, j20] }
def traceWith (f : Nat → List DeclaredIntent) : Trace := (List.range 9).map fun k => { base k with intents := f k }
def atJ (φ : Formula) : Formula := .existsRegion (.lit "intersection") "j" φ
def intends : Formula := atJ (.intent turn X J)
/-- Triggered by the declared intention; its obligation never holds. -/
def intentRule : Rule :=
  { id := "test/intent", laws := [], binders := [⟨"x", mv "x"⟩], applicability := intends, obligation := .ff, intentions := [turn] }

def tl (τ : Trace) (r : Rule) (x : TrackId) : List Verdict :=
  (timeline (Setup.mk' [r] τ {} Q.zero) r { assign := [("x", x)] }).toList.map (·.2)

-- Semantics and verdicts: true, false, and absent where the pair or the id is not declared.
#guard tl (traceWith fun _ => declared true) intentRule 1 = List.replicate 9 .violated
#guard tl (traceWith fun _ => declared false) intentRule 1 = List.replicate 9 .notApplicable
#guard tl (traceWith fun _ => []) intentRule 1 = List.replicate 9 (.unknown [.intentionMissing turn])
#guard tl (traceWith fun _ => declared true) intentRule 2 = List.replicate 9 (.unknown [.intentionMissing turn])   -- the pair is absent
#guard tl (traceWith fun _ => [{ vehicle := 1, target := 20, values := [("int.other", true)] }]) intentRule 1 =
  List.replicate 9 (.unknown [.intentionMissing turn])                                                         -- the id is absent

-- Cancellation: the two traces differ only in the declaration after t₁ (instant 4). A rule that
-- reads the declaration now and in a window behind gives the same verdict at every instant up to t₁.
def behind : Rule := { intentRule with id := "test/intent_behind", applicability := .holdsFor .time (.lit (seconds 1) .second) "x" intends }
def kept : Trace := traceWith fun _ => declared true
def cancelled : Trace := traceWith fun k => if k ≤ 4 then declared true else declared false
def dropped : Trace := traceWith fun k => if k ≤ 4 then declared true else []
#guard (tl kept behind 1).take 5 = (tl cancelled behind 1).take 5
#guard (tl kept behind 1).take 5 = (tl dropped behind 1).take 5
#guard (tl kept intentRule 1).take 5 = (tl cancelled intentRule 1).take 5
#guard (tl kept intentRule 1).drop 5 != (tl cancelled intentRule 1).drop 5

-- Grounding: a link 1 ↦ 5, the intention declared for 5 after it, decides as the trace written
-- with 1 throughout, after the break.
def renamed (k : Nat) : Scene :=
  let s := base k
  { s with users := s.users.map (fun u => if u.track == 1 then { u with track := 5 } else u)
           occupies := s.occupies.map fun (t, r) => if t == 1 then (5, r) else (t, r)
           subject := some 5 }
def broken (who : TrackId) : Trace := (List.range 9).map fun k =>
  let s := base k
  if k == 3 || k == 4 then { s with users := s.users.filter (·.track != 1), occupies := s.occupies.filter (·.1 != 1) }
  else if k ≥ 5 then { (if who == 5 then renamed k else s) with intents := [{ vehicle := who, target := 20, values := [(turn, true)] }],
                                                                 links := if k == 5 && who == 5 then [(1, 5)] else [] }
  else s
def tlGap (τ : Trace) : List Verdict :=
  (timeline (Setup.mk' [intentRule] τ {} (Q.mk' 15 10)) intentRule { assign := [("x", 1)] }).toList.map (·.2)
#guard (tlGap (broken 5)).drop 5 = (tlGap (broken 1)).drop 5
#guard (tlGap (broken 5)).drop 5 = List.replicate 4 .violated

-- Decoding: a record decodes; a missing or an extra key, or an empty `source`, is an error.
def sceneJson (extra : String) : String :=
  "{\"scenes\": [{\"t\": 0, \"users\": [{\"track\": 1}], \"structures\": [{\"id\": 20, \"kind\": \"intersection\"}]" ++ extra ++ "}]}"
def rec (body : String) : String := ", \"intents\": [" ++ body ++ "]"
def good : String := "{\"vehicle\": 1, \"target\": 20, \"source\": \"authored_scenario\", \"values\": [[\"int.turn_left\", true]]}"
#guard match Decode.parse Decode.trace (sceneJson (rec good)) with
  | .ok [s] => s.intents.length == 1 && s.intention turn 1 20 == some true
  | _ => false
#guard !(Decode.parse Decode.trace (sceneJson (rec "{\"vehicle\": 1, \"target\": 20, \"values\": []}"))).isOk
#guard !(Decode.parse Decode.trace (sceneJson (rec "{\"vehicle\": 1, \"target\": 20, \"source\": \"x\", \"values\": [], \"note\": 1}"))).isOk
#guard !(Decode.parse Decode.trace (sceneJson (rec "{\"vehicle\": 1, \"target\": 20, \"source\": \"\", \"values\": []}"))).isOk
#guard (Decode.parse Decode.trace (sceneJson "")).isOk                                    -- a trace without `intents`

-- Admission: each defect rejected on the JSON path (the monitor) and the Lean path (a witness),
-- with the same text.
def lean1 (intents : List DeclaredIntent) (asms : List (AsmId × Bool) := []) : Trace :=
  [{ t := 0, users := [{ track := 1 }], structures := [j20], intents := intents, assumptions := asms }]
def viaMonitor (text : String) : List String :=
  match Decode.parse Decode.trace text with
  | .ok τ => match Monitor.check [] τ {} (Manifest.full "t") with | .error ds => ds | .ok _ => []
  | .error e => [e]
def viaWitness (τ : Trace) : List String :=
  let sc : Scenario := { name := "w", rule := "test/intent", trace := τ, reading := {}, manifest := Manifest.full "t",
                         grounding := [("x", 1)], expected := .violated }
  match sc.run [intentRule] with
  | .error e => [e]
  | .ok _ => []
def sameBoth (text : String) (τ : Trace) : Bool :=
  let ds := viaMonitor text
  !ds.isEmpty && ds == Admission.defects τ Q.zero && viaWitness τ == [s!"w: the trace is not admitted: {"; ".intercalate ds}"]
def one (v t : Nat) (vals : String) : String :=
  s!"\{\"vehicle\": {v}, \"target\": {t}, \"source\": \"s\", \"values\": {vals}}"
#guard sameBoth (sceneJson (rec (one 3 20 "[[\"int.turn_left\", true]]"))) (lean1 [{ vehicle := 3, target := 20, values := [(turn, true)] }])
#guard sameBoth (sceneJson (rec (one 1 99 "[[\"int.turn_left\", true]]"))) (lean1 [{ vehicle := 1, target := 99, values := [(turn, true)] }])
#guard sameBoth (sceneJson (rec (one 1 20 "[[\"int.turn_left\", true]]" ++ ", " ++ one 1 20 "[[\"int.turn_left\", false]]")))
  (lean1 [{ vehicle := 1, target := 20, values := [(turn, true)] }, { vehicle := 1, target := 20, values := [(turn, false)] }])
#guard sameBoth (sceneJson (rec (one 1 20 "[[\"int.turn_left\", true], [\"int.turn_left\", false]]")))
  (lean1 [{ vehicle := 1, target := 20, values := [(turn, true), (turn, false)] }])
#guard sameBoth (sceneJson (rec (one 1 20 "[[\"int.Turn\", true]]"))) (lean1 [{ vehicle := 1, target := 20, values := [("int.Turn", true)] }])
#guard sameBoth (sceneJson ", \"assumptions\": [[\"asm.district\", true], [\"asm.district\", false]]") (lean1 [] [("asm.district", true), ("asm.district", false)])
#guard viaMonitor (sceneJson (rec good)) = []

-- Identity: accepted links are one-to-one. A branch and a merge are rejected; a chain is admitted.
def tracksAt (t : Timestamp) (ids : List TrackId) (links : List (TrackId × TrackId) := []) : Scene :=
  { t := t, users := ids.map fun i => { track := i }, links := links }
def branch : Trace := [tracksAt 0 [7], tracksAt 500 [17, 27] [(7, 17), (7, 27)]]
def merge : Trace := [tracksAt 0 [7, 8], tracksAt 500 [27] [(7, 27), (8, 27)]]
def chain : Trace := [tracksAt 0 [7], tracksAt 500 [17] [(7, 17)], tracksAt 1000 [27] [(17, 27)]]
#guard (Admission.defects branch (seconds 2)).length = 1
#guard (Admission.defects merge (seconds 2)).length = 1
#guard Admission.defects chain (seconds 2) = []
#guard !(Setup.admit [] branch {} (seconds 2)).toOption.isSome
#guard (Setup.admit [] chain {} (seconds 2)).toOption.isSome

-- Static checks: declaration, well-formed ids, the causal read, and concepts.
#guard intentRule.wellFormed
#guard !({ intentRule with intentions := [] } : Rule).wellFormed
#guard !({ intentRule with intentions := [turn, "int.Bad"] } : Rule).wellFormed
#guard Rule.check [intentRule] intentRule = []
def ahead : Rule := { intentRule with id := "test/ahead", applicability := .within .time (.lit (seconds 1) .second) "x" intends }
#guard (Rule.check [ahead] ahead).length = 1
#guard Rule.check [behind] behind = []
def caller (id : String) (φ : Formula) : Rule := { id := id, laws := [], binders := [⟨"x", mv "x"⟩], applicability := φ, obligation := .tt }
def r0 : Rule := caller "test/r0" (.ruleApplies "test/intent" [("x", "x")])
def win (φ : Formula) : Formula := .within .time (.lit (seconds 1) .second) "x" φ
def callsAhead : Rule := caller "test/c1" (win (.ruleApplies "test/intent" [("x", "x")]))
def callsAhead2 : Rule := caller "test/c2" (win (.ruleApplies "test/r0" [("x", "x")]))
def callsBehind : Rule := caller "test/c3" (.holdsFor .time (.lit (seconds 1) .second) "x" (.ruleApplies "test/intent" [("x", "x")]))
def lib : List Rule := [intentRule, r0, callsAhead, callsAhead2, callsBehind]
#guard (Rule.check lib callsAhead).length = 1
#guard (Rule.check lib callsAhead2).length = 1
#guard Rule.check lib callsBehind = []
#guard Rule.check lib r0 = []
def readsIntent : Concept :=
  { id := "drv.x.intends", contract := "c", args := [("x", .track)], params := [], body := .formula intends }
#guard (Concept.check [readsIntent] readsIntent).any (·.endsWith "a concept reads no declared intention (`int.turn_left`)")

-- Nesting: each leaf only inside a `Term.cond` under a `cmp`.
def inCond (φ : Formula) : Formula := .cmp (.cond φ (.lit (seconds 1) .second) (.lit (seconds 2) .second)) .le (.lit (seconds 3) .second)
def nestedIntent : Formula := inCond intends
#guard !({ intentRule with applicability := nestedIntent, intentions := [] } : Rule).wellFormed
#guard Rule.check [intentRule] { intentRule with applicability := nestedIntent } = []
#guard (Rule.check [intentRule] { intentRule with applicability := win nestedIntent }).length = 1
#guard (Concept.check [{ readsIntent with body := .formula nestedIntent }] { readsIntent with body := .formula nestedIntent }).any
  (·.endsWith "a concept reads no declared intention (`int.turn_left`)")
#guard Formula.intentions nestedIntent = [turn]
def nestedAsm : Formula := inCond (.asm "asm.district")
#guard !({ intentRule with applicability := nestedAsm, intentions := [] } : Rule).wellFormed
#guard ({ intentRule with applicability := win nestedAsm, intentions := [], assumptions := ["asm.district"] } : Rule).wellFormed
#guard Rule.check [] { intentRule with applicability := win nestedAsm, intentions := [], assumptions := ["asm.district"] } = []
#guard Case.policyErrors [] nestedAsm = Case.policyErrors [] nestedIntent
#guard Case.policyErrors [] nestedAsm = []
#guard Case.policyErrors [] (win (.asm "asm.district")) = Case.policyErrors [] (win intends)
#guard Case.policyErrors [] (win (.asm "asm.district")) = []
def nestedCall (id : String) (map : List (String × String)) : Formula := inCond (.ruleApplies id map)
#guard (Rule.check lib (caller "test/n1" (nestedCall "test/none" [("x", "x")]))).any (·.endsWith "composes unknown rule `test/none`")
#guard (Rule.check lib (caller "test/n2" (nestedCall "test/intent" []))).any (·.endsWith "leaves its binder `x` unmapped")
#guard (Rule.check lib (caller "test/n3" (nestedCall "test/intent" [("x", "x"), ("z", "x")]))).any (·.endsWith "maps `z`, not one of its binders")
#guard (Rule.check lib (caller "test/n4" (win (nestedCall "test/intent" [("x", "x")])))).length = 1
def noIntentRule : Rule := { intentRule with id := "test/plain", applicability := .tt, intentions := [] }
#guard Rule.check (noIntentRule :: lib) (caller "test/n5" (win (nestedCall "test/plain" [("x", "x")]))) = []
#guard (Concept.check [] { readsIntent with body := .formula (nestedCall "test/intent" [("x", "x")]) }).any (·.endsWith "a concept composes no rule (`test/intent`)")

-- Case policy: a case may state a declared intention and an assumption, true or negated; it is
-- certified only where the trace declares what it states.
#guard Case.policyErrors [] (.intent turn (.var "e1") (.var "e2")) = []
#guard Case.policyErrors [] (.asm "asm.district") = []
#guard Case.policyErrors [] (.not (.asm "asm.district")) = []
def district : AsmId := "asm.district"
def asmRule : Rule :=
  { id := "test/asm", laws := [], binders := [⟨"x", mv "x"⟩], applicability := .asm district, obligation := .ff, assumptions := [district] }
def asmTrace (decl : String) : String :=
  "{\"scenes\": [{\"t\": 0, \"users\": [{\"track\": 1, \"classes\": [\"motor_vehicle\"]}]" ++ decl ++ "}]}"
def declares (id : String) (b : Bool) : String := s!", \"assumptions\": [[\"{id}\", {b}]]"
def certify (trace formula : String) : Json :=
  Certificate.record [asmRule] asmRule {} 1 trace ("{\"case\": " ++ formula ++ ", \"entities\": {}, \"at\": 0}") [("x", 1)]
def stated : String := "{\"asm\": \"asm.district\"}"
def negated : String := "{\"not\": {\"asm\": \"asm.district\"}}"
def valueOf (j : Json) : Json := (j.getObjValD "case_value").getObjValD "value"
def verdictOf (j : Json) : Json := (j.getObjValD "rule_result").getObjValD "verdict"
def asDeclared (id kind : String) : Json := Json.arr #[Json.mkObj [("id", Json.str id), ("kind", Json.str kind)]]
-- declared true, stated true: admitted and certified
#guard (certify (asmTrace (declares district true)) stated).getObjValD "case_check_errors" == Json.arr #[]
#guard valueOf (certify (asmTrace (declares district true)) stated) == Json.str "true"
#guard verdictOf (certify (asmTrace (declares district true)) stated) == Json.str "violated"
#guard (certify (asmTrace (declares district true)) stated).getObjValD "case_declarations" == asDeclared district "asm"
-- declared false, stated by negation: admitted and certified
#guard (certify (asmTrace (declares district false)) negated).getObjValD "case_check_errors" == Json.arr #[]
#guard valueOf (certify (asmTrace (declares district false)) negated) == Json.str "true"
#guard verdictOf (certify (asmTrace (declares district false)) negated) == Json.str "not_applicable"
#guard (certify (asmTrace (declares district false)) negated).getObjValD "case_declarations" == asDeclared district "asm"
-- not declared: the case is not true on the trace, so it is not certified, stated either way
#guard valueOf (certify (asmTrace "") stated) == Json.str "unknown"
#guard valueOf (certify (asmTrace "") negated) == Json.str "unknown"
#guard (certify (asmTrace "") stated).getObjValD "rule_result" == Json.null
-- declared false, stated true: not certified
#guard valueOf (certify (asmTrace (declares district false)) stated) == Json.str "false"
#guard (certify (asmTrace (declares district false)) stated).getObjValD "rule_result" == Json.null
-- an id outside the run's catalogue is named with its kind: the harness's catalogue check refuses it
#guard (certify (asmTrace (declares "asm.other" true)) "{\"asm\": \"asm.other\"}").getObjValD "case_declarations" == asDeclared "asm.other" "asm"
-- each id once, with its kind, nested or not
#guard Certificate.declarations (.and nestedAsm (.and (.asm district) (atJ (.intent turn X J)))) ==
  Json.arr #[Json.mkObj [("id", Json.str district), ("kind", "asm")], Json.mkObj [("id", Json.str turn), ("kind", "int")]]

-- Adequacy: an intention leaf no witness moves (it sits beside a true disjunct) is reported, like
-- any other leaf; the same leaf alone is exercised.
def scTrue (r : Rule) : Scenario := { name := "t", rule := r.id, trace := traceWith (fun _ => declared true), reading := {},
                                      manifest := Manifest.full "t", grounding := [("x", 1)], expected := .violated }
def beside : Rule := { intentRule with id := "test/beside", applicability := .or intends (mv "x") }
#guard ((scTrue intentRule).run [intentRule]).isOk
#guard Adequacy.unexercised [intentRule] intentRule [scTrue intentRule] = []
#guard ((scTrue beside).run [beside]).isOk
#guard (Adequacy.unexercised [beside] beside [scTrue beside]).any (·.startsWith "applicability")


-- the static checks read the innermost binding of a name, as evaluation does
def shadowRule (φ : Formula) : Rule := { intentRule with id := "test/shadow", applicability := φ }
#guard (Rule.check [intentRule] (shadowRule (.existsRegion (.lit "intersection") "x" (.intent turn X (.var "x"))))).length = 1
#guard (Rule.check [intentRule] (shadowRule (atJ (.existsUser "j" (.intent turn X J))))).length = 1
#guard Rule.check [intentRule] (shadowRule (atJ (.existsRegion (.lit "intersection") "j" (.intent turn X J)))) = []
#guard (Rule.check lib (caller "test/s1" (.existsRegion (.lit "intersection") "x" (.ruleApplies "test/intent" [("x", "x")])))).length = 1
#guard (Rule.check lib (caller "test/s2" (.existsRegion (.lit "intersection") "x"
  (.holdsFor .path (.lit (Units.metres 1) .metre) "x" (.atom "ru_motor_vehicle" [X] []))))).length ≥ 1
#guard (Rule.check lib (caller "test/s3" (.existsRegion (.lit "intersection") "x"
  (.cmp (.distanceWhile "x" (.atom "ru_motor_vehicle" [X] [])) .le (.lit (Units.metres 1) .metre))))).length ≥ 1
-- the reproduction: statically admitted before, malformed at evaluation
#guard tl (traceWith fun _ => declared true) (shadowRule (.existsRegion (.lit "intersection") "x" (.intent turn X (.var "x")))) 1
  = List.replicate 9 (.unknown [.malformed "intent: a track and a region expected"])

end TrafficSpec.Tests.Intentions
