import TrafficSpec.Core.Runtime.Monitor
import TrafficSpec.Core.Runtime.Decode
import TrafficSpec.Core.Evidence.Builders
import TrafficSpec.Core.Evidence.Certificate
namespace TrafficSpec.Tests.Facts
open Lean TrafficSpec Units TrafficSpec.Grounding

-- Two road users at every scene (1 and 2); the ids are test labels.
private def X : Arg := .var "x"
private def Y : Arg := .var "y"
def mv (v : String) : Formula := .atom "ru_motor_vehicle" [.var v] []
def duty : FactId := "fact.on_duty"
def consent : FactId := "fact.consents_to"
def redFlashing : WarningLamp := { colour := .red, mode := .flashing, facing := .front }
def user (t : TrackId) (cls : List RoadUserClass) (speed : Int) (lamps hazard : Bool := false) : RoadUser :=
  { track := t, classes := some cls
    kin := { position := some (metres (Int.ofNat (10 * t)), Q.zero), speed := some (metresPerSecond speed) }
    sig := { warningLamps := some (if lamps then [redFlashing] else []), hazard := some hazard } }
def car (speed : Int) (hazard : Bool := false) : RoadUser := user 1 [.motorVehicle] speed false hazard
def official (speed : Int) (lamps : Bool) : RoadUser := user 1 [.motorVehicle, .emergencyVehicle] speed lamps
def traceOf (subject : RoadUser) (facts : List DeclaredFact) : Trace :=
  (List.range 3).map fun k => { t := Int.ofNat (k * 500), subject := some 1, users := [subject, user 2 [.motorVehicle] 0],
                                facts := facts }
def tl (τ : Trace) (r : Rule) (g : List (String × TrackId)) (m : Manifest := Manifest.full "t") : List Verdict :=
  (timeline (Setup.mk' [r] (maskTrace m τ) {} Q.zero) r { assign := g }).toList.map (·.2)
def all (v : Verdict) : List Verdict := List.replicate 3 v

-- An exception that turns on the subject's own duty, written beside the duty: at most 10 m/s,
-- unless the subject is on duty. Undeclared, the fact leaves the verdict open only where it can
-- change it.
def slow : Formula := .cmp (.measure "kin_speed" [X]) .le (.lit (metresPerSecond 10) .metrePerSecond)
def exempt : Rule :=
  { id := "test/exempt", laws := [], binders := [⟨"x", mv "x"⟩], applicability := .tt,
    obligation := .or (.fact duty [X]) slow, facts := [duty] }
def onDuty (b : Bool) : List DeclaredFact := [Build.fact duty [1] b]
#guard tl (traceOf (car 20) (onDuty true)) exempt [("x", 1)] = all .compliant
#guard tl (traceOf (car 20) (onDuty false)) exempt [("x", 1)] = all .violated
#guard tl (traceOf (car 20) []) exempt [("x", 1)] = all (.unknown [.factMissing duty])
#guard tl (traceOf (car 5) []) exempt [("x", 1)] = all .compliant              -- the fact cannot change it: decided
#guard tl (traceOf (car 20) (onDuty true)) exempt [("x", 2)] = all .compliant  -- road user 2 is slow
-- The same exception in the applicability: a false conjunct beside it decides.
def exemptApp : Rule :=
  { id := "test/exempt_app", laws := [], binders := [⟨"x", mv "x"⟩], applicability := .and (.not slow) (.not (.fact duty [X])),
    obligation := .ff, facts := [duty] }
#guard tl (traceOf (car 5) []) exemptApp [("x", 1)] = all .notApplicable
#guard tl (traceOf (car 20) []) exemptApp [("x", 1)] = all (.unknown [.factMissing duty])
#guard tl (traceOf (car 20) (onDuty true)) exemptApp [("x", 1)] = all .notApplicable

-- A lamp never stands for the duty: the class with its warning lamps on and no task declared stays
-- unknown; a declared task with the lamps off is exempt; an ordinary car with its hazard lamps on
-- is held to the duty as declared, and unknown where nothing is declared.
#guard tl (traceOf (official 20 true) []) exempt [("x", 1)] = all (.unknown [.factMissing duty])
#guard tl (traceOf (official 20 true) (onDuty false)) exempt [("x", 1)] = all .violated
#guard tl (traceOf (official 20 false) (onDuty true)) exempt [("x", 1)] = all .compliant
#guard tl (traceOf (car 20 (hazard := true)) []) exempt [("x", 1)] = all (.unknown [.factMissing duty])
#guard tl (traceOf (car 20 (hazard := true)) (onDuty false)) exempt [("x", 1)] = all .violated
-- Where the words name only the class and its lamps (a duty of others toward a vehicle so lit), the
-- rule reads the class and the lamp and needs no fact: it decides with none declared.
def yieldsToLit : Rule :=
  { id := "test/lit", laws := [], binders := [⟨"y", mv "y"⟩],
    applicability := .existsUser "e" (.and (.not (.same (.var "e") Y))
      (.and (.atom "ru_emergency_vehicle" [.var "e"] []) (.atom "sig_warning_lamp" [.var "e", .lit "red"] []))),
    obligation := .cmp (.measure "kin_speed" [Y]) .le (.lit (metresPerSecond 1) .metrePerSecond) }
#guard tl (traceOf (official 20 true) []) yieldsToLit [("y", 2)] = all .compliant
#guard tl (traceOf (official 20 false) []) yieldsToLit [("y", 2)] = all .notApplicable
#guard tl (traceOf (car 20 (hazard := true)) []) yieldsToLit [("y", 2)] = all .notApplicable

-- A pair is ordered: declared for (1, 2), it is not declared for (2, 1).
def consents : Rule :=
  { id := "test/consent", laws := [], binders := [⟨"x", mv "x"⟩, ⟨"y", mv "y"⟩], applicability := .fact consent [X, Y],
    obligation := .ff, facts := [consent] }
def pairTrace : Trace := traceOf (car 5) [Build.fact consent [1, 2] true]
#guard tl pairTrace consents [("x", 1), ("y", 2)] = all .violated
#guard tl pairTrace consents [("x", 2), ("y", 1)] = all (.unknown [.factMissing consent])
#guard tl (traceOf (car 5) [Build.fact consent [1, 2] false]) consents [("x", 1), ("y", 2)] = all .notApplicable

-- A manifest supplies a fact only when it lists its id: unlisted, the declaration is dropped.
#guard tl (traceOf (car 20) (onDuty true)) exempt [("x", 1)] (Build.manifest (facts := some [])) = all (.unknown [.factMissing duty])
#guard tl (traceOf (car 20) (onDuty true)) exempt [("x", 1)] (Build.manifest (facts := some [duty])) = all .compliant
#guard (({ source := "s", entries := [] } : Manifest).suppliesFact duty) = false
-- A witness may be unknown for a fact its manifest does not supply, never for one it does.
def scenario (m : Manifest) (τ : Trace) : Scenario :=
  { name := "w", rule := exempt.id, trace := τ, reading := {}, manifest := m, grounding := [("x", 1)], expected := .unknown [] }
#guard ((scenario (Build.manifest (facts := some [])) (traceOf (car 20) (onDuty true))).run [exempt]).isOk
#guard !((scenario (Build.manifest) (traceOf (car 20) [])).run [exempt]).isOk

-- Static checks: declared, well-formed, one road user or two distinct ones, each a bound track;
-- a concept reads no declared fact.
#guard exempt.wellFormed && consents.wellFormed
#guard !({ exempt with facts := [] } : Rule).wellFormed
#guard !({ exempt with facts := [duty, "fact.Bad"] } : Rule).wellFormed
#guard Rule.check [exempt] exempt = [] && Rule.check [consents] consents = []
def withApp (φ : Formula) : Rule := { exempt with id := "test/f", applicability := φ, facts := [duty] }
#guard (Rule.check [] (withApp (.fact duty []))).length = 1
#guard (Rule.check [] (withApp (.fact duty [X, X]))).length = 1
#guard (Rule.check [] (withApp (.fact duty [X, .var "z"]))).length = 1
#guard (Rule.check [] (withApp (.fact duty [X, .lit "x"]))).length = 1
#guard (Rule.check [] (withApp (.existsDevice (.lit "stop_sign") "d" (.fact duty [.var "d"])))).length = 1
#guard (Rule.check [] (withApp (.fact duty [X, X, X]))).length ≥ 1
def readsFact : Concept := { id := "drv.x.on_duty", contract := "c", args := [("x", .track)], params := [], body := .formula (.fact duty [X]) }
#guard (Concept.check [readsFact] readsFact).any (·.endsWith "a concept reads no declared fact (`fact.on_duty`)")
#guard Formula.facts (.and slow (.not (.fact duty [X]))) = [duty]
#guard match Concept.substF ⟨[("x", .var "v")], [], "t"⟩ (.fact consent [X, Y]) with
  | .fact _ [.var "v", .var "y"] => true
  | _ => false

-- Export and decoding are inverse; a scene's records decode strictly.
#guard match Decode.parse (Decode.formula "f") ((Formula.fact consent [X, Y]).toJson.compress) with
  | .ok φ => φ.toJson == (Formula.fact consent [X, Y]).toJson
  | .error _ => false
def sceneJson (facts : String) : String :=
  "{\"scenes\": [{\"t\": 0, \"users\": [{\"track\": 1}, {\"track\": 2}], \"facts\": [" ++ facts ++ "]}]}"
def factJson (id : String) (subjects : String) (value : Bool) : String :=
  s!"\{\"id\": \"{id}\", \"users\": {subjects}, \"value\": {value}}"
#guard match Decode.parse Decode.trace (sceneJson (factJson "fact.consents_to" "[1, 2]" true)) with
  | .ok [s] => s.fact consent [1, 2] [] == some true && s.fact consent [2, 1] [] == none
  | _ => false
#guard !(Decode.parse Decode.trace (sceneJson "{\"id\": \"fact.on_duty\", \"users\": [1]}")).isOk
#guard !(Decode.parse Decode.trace (sceneJson "{\"id\": \"fact.on_duty\", \"users\": [1], \"value\": true, \"source\": \"s\"}")).isOk
#guard !(Decode.parse Decode.trace (sceneJson "{\"id\": \"fact.on_duty\", \"subjects\": [1], \"value\": true}")).isOk
#guard match Decode.parse Decode.manifest "{\"source\": \"s\", \"atoms\": {}, \"facts\": [\"fact.on_duty\"]}" with
  | .ok m => m.suppliesFact duty && !m.suppliesFact consent
  | .error _ => false
#guard match Decode.parse Decode.manifest "{\"source\": \"s\", \"atoms\": {}}" with
  | .ok m => !m.suppliesFact duty
  | .error _ => false

-- Admission: each defect, on the JSON path and the Lean path alike.
def admitted (text : String) : List String :=
  match Decode.parse Decode.trace text with
  | .ok τ => Admission.defects τ Q.zero
  | .error e => [e]
#guard admitted (sceneJson (factJson "fact.on_duty" "[1]" true)) = []
#guard (admitted (sceneJson (factJson "fact.on_duty" "[3]" true))).length = 1
#guard (admitted (sceneJson (factJson "fact.on_duty" "[]" true))).length = 1
#guard (admitted (sceneJson (factJson "fact.consents_to" "[1, 1]" true))).length = 1
#guard (admitted (sceneJson (factJson "fact.consents_to" "[1, 2, 1]" true))).length ≥ 1
#guard (admitted (sceneJson (factJson "fact.Duty" "[1]" true))).length = 1
#guard (admitted (sceneJson (factJson "fact.on_duty" "[1]" true ++ ", " ++ factJson "fact.on_duty" "[1]" false))).length = 1
#guard admitted (sceneJson (factJson "fact.on_duty" "[1]" true ++ ", " ++ factJson "fact.on_duty" "[2]" false)) = []
#guard Admission.defects [{ t := 0, users := [{ track := 1 }, { track := 2 }], facts := [Build.fact duty [3] true] }] Q.zero
  == admitted (sceneJson (factJson "fact.on_duty" "[3]" true))
-- Identity: a fact declared of a track that a link continues is the continued road user's.
def linked : Trace :=
  [{ t := 0, users := [car 20], facts := onDuty true },
   { t := 500, users := [{ car 20 with track := 5 }], links := [(1, 5)], facts := [Build.fact duty [5] true] }]
#guard (timeline (Setup.mk' [exempt] linked {} (seconds 1)) exempt { assign := [("x", 1)] }).toList.map (·.2) = [.compliant, .compliant]

-- A fact of a region (a map record) and of a road user at a region: one door, the subjects' sorts
-- telling them apart.
def onSegment : FactId := "fact.on_named_segment"
def terminus : FactId := "fact.route_terminus_here"
def r7 : Structure := { id := 7, kind := .sidewalk }
def regionTrace (facts : Nat → List DeclaredFact) : Trace :=
  (List.range 3).map fun k => { t := Int.ofNat (k * 500), subject := some 1, users := [car 5], structures := [r7], facts := facts k }
def segRule : Rule :=
  { id := "test/segment", laws := [], binders := [⟨"x", mv "x"⟩],
    applicability := .existsRegion (.lit "sidewalk") "r" (.fact onSegment [.var "r"]), obligation := .ff, facts := [onSegment] }
def termRule : Rule :=
  { id := "test/terminus", laws := [], binders := [⟨"x", mv "x"⟩],
    applicability := .existsRegion (.lit "sidewalk") "r" (.fact terminus [X, .var "r"]), obligation := .ff, facts := [terminus] }
def tlR (τ : Trace) (r : Rule) : List Verdict := (timeline (Setup.mk' [r] τ {} Q.zero) r { assign := [("x", 1)] }).toList.map (·.2)
#guard tlR (regionTrace fun _ => [Build.fact onSegment [] true [7]]) segRule = all .violated
#guard tlR (regionTrace fun _ => [Build.fact onSegment [] false [7]]) segRule = all .notApplicable
#guard tlR (regionTrace fun _ => []) segRule = all (.unknown [.factMissing onSegment])
#guard tlR (regionTrace fun _ => [Build.fact terminus [1] true [7]]) termRule = all .violated
#guard tlR (regionTrace fun _ => [Build.fact terminus [1] true []]) termRule = all (.unknown [.factMissing terminus])
#guard Rule.check [segRule] segRule = [] && Rule.check [termRule] termRule = []
def twoRegions : Formula := .existsRegion (.lit "sidewalk") "r" (.existsRegion (.lit "sidewalk") "q" (.fact onSegment [.var "r", .var "q"]))
#guard (Rule.check [] { segRule with id := "test/two_regions", applicability := twoRegions }).length = 1
-- a fact of a region alone is the same wherever it is declared; one of a road user may change
#guard (Admission.defects (regionTrace fun k => [Build.fact onSegment [] (k == 0) [7]]) Q.zero).length = 1
#guard Admission.defects (regionTrace fun k => [Build.fact terminus [1] (k == 0) [7]]) Q.zero = []
-- the lint compares one region id within one trace (one source version) only: a scene that leaves
-- it out is unknown there, not a contradiction; two regions, or two traces, are never compared
#guard Admission.defects (regionTrace fun k => if k == 0 then [Build.fact onSegment [] true [7]] else []) Q.zero = []
def twoRegionTrace : Trace := (List.range 2).map fun k =>
  { t := Int.ofNat (k * 500), users := [car 5], structures := [r7, { id := 8, kind := .sidewalk }],
    facts := [Build.fact onSegment [] true [7], Build.fact onSegment [] false [8]] }
#guard Admission.defects twoRegionTrace Q.zero = []
#guard Admission.defects (regionTrace fun _ => [Build.fact onSegment [] true [7]]) Q.zero = []
#guard Admission.defects (regionTrace fun _ => [Build.fact onSegment [] false [7]]) Q.zero = []
#guard (Admission.defects (regionTrace fun _ => [Build.fact onSegment [] true [9]]) Q.zero).length = 3
#guard (Admission.defects (regionTrace fun _ => [Build.fact onSegment [] true [7, 7]]) Q.zero).length = 3
#guard match Decode.parse Decode.trace "{\"scenes\": [{\"t\": 0, \"users\": [{\"track\": 1}], \"structures\": [{\"id\": 7, \"kind\": \"sidewalk\"}], \"facts\": [{\"id\": \"fact.route_terminus_here\", \"users\": [1], \"regions\": [7], \"value\": true}]}]}" with
  | .ok [s] => s.fact terminus [1] [7] == some true && s.fact terminus [1] [] == none
  | _ => false

-- A case may state a declared fact; it is named with its kind.
#guard Case.policyErrors [] (.fact consent [.var "e1", .var "e2"]) = []
#guard Certificate.declarations (.and (.fact duty [X]) (.asm "asm.d")) ==
  Json.arr #[Json.mkObj [("id", Json.str duty), ("kind", "fact")], Json.mkObj [("id", Json.str "asm.d"), ("kind", "asm")]]

end TrafficSpec.Tests.Facts
