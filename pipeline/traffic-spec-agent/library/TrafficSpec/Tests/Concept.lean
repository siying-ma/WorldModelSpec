import TrafficSpec.Core.Language.Export
import TrafficSpec.Core.Evidence.Adequacy
import TrafficSpec.Tests.Decode
namespace TrafficSpec.Tests.Concept
open TrafficSpec Units

private def X : Arg := .var "x"
private def Y : Arg := .var "y"
private def sec (n : Int) : Term := .lit (seconds n) .second
private def mps (n : Int) : Term := .lit (metresPerSecond n) .metrePerSecond

-- Three concepts over the braking trace: one with a metric window and two formal parameters, one
-- that binds a variable named like a binder of the rules that will use it, one over both.
def halted : Concept :=
  { id := "drv.motion.halted", contract := "speed at most eps at every observation of the last d"
    args := [("x", .track)], params := [⟨"eps", .metrePerSecond⟩, ⟨"d", .second⟩]
    body := .formula (.holdsFor .time (.param "d") "x" (.cmp (.measure "kin_speed" [.var "x"]) .le (.param "eps"))) }
def touching : Concept :=
  { id := "drv.interaction.touching_some", contract := "in contact with some road user of the scene"
    args := [("x", .track)], params := []
    body := .formula (.existsUser "y" (.atom "rel_contact" [.var "x", .var "y"] [])) }
def both : Concept :=
  { id := "drv.motion.halted_touching", contract := "halted and touching"
    args := [("x", .track)], params := [⟨"eps", .metrePerSecond⟩, ⟨"d", .second⟩]
    body := .formula (.and (.derived "drv_motion_halted" [.var "x"] [.param "eps", .param "d"])
                           (.derived "drv_interaction_touching_some" [.var "x"] [])) }
def cs : List Concept := [halted, touching, both]

#guard halted.leanName = "drv_motion_halted"
#guard halted.atoms = ["kin_time", "kin_speed"]
def kinds : Concept :=
  { id := "drv.position.in_kind", contract := "the user occupies some region of the given kind"
    args := [("x", .track), ("k", .literal ["lane", "shoulder"])], params := []
    body := .formula (.existsRegion (.var "k") "r" (.atom "rel_occupies" [.var "x", .var "r"] [])) }
#guard kinds.atoms = ["st_lane", "rel_occupies", "st_shoulder"]                                   -- every admissible kind, over the samples
#guard both.refs = ["drv_motion_halted", "drv_interaction_touching_some"]
#guard Concept.check cs halted = []
#guard Concept.check cs touching = []
#guard Concept.check cs both = []
#guard Concept.onCycle cs = []

-- the static check: an undeclared parameter, a reading parameter as a formal, an unknown concept
-- (unknown to the list and malformed at the call), a composition, a track formal at a literal
-- position, an empty literal sort
#guard (Concept.check cs { halted with params := [⟨"eps", .metrePerSecond⟩] }).length = 1
def readingNamed : Concept :=
  { halted with params := [⟨"p.eps", .metrePerSecond⟩, ⟨"d", .second⟩]
                body := .formula (.holdsFor .time (.param "d") "x" (.cmp (.measure "kin_speed" [.var "x"]) .le (.param "p.eps"))) }
#guard (Concept.check cs readingNamed).length = 1
#guard (Concept.check cs { touching with body := .formula (.derived "drv_motion_nowhere" [.var "x"] []) }).length = 2
#guard (Concept.check cs { touching with body := .formula (.rule "test/gap" [("x", "x"), ("y", "x")]) }).length = 1
#guard (Concept.check cs { touching with body := .formula (.atom "rel_occupies" [.var "x", .var "x"] []) }).length = 1
#guard (Concept.check cs { touching with args := [("x", .track), ("s", .literal [])] }).length = 1
-- a literal formal is checked on each admissible value: one spelling no codec decodes
def sided : Concept :=
  { id := "drv.interaction.beside", contract := "the other body is on the given side"
    args := [("x", .track), ("o", .track), ("s", .literal ["left", "purple"])], params := []
    body := .formula (.atom "rel_bearing" [.var "x", .var "o", .var "s"] []) }
#guard (Concept.check cs sided).length = 1
#guard Concept.check cs { sided with args := [("x", .track), ("o", .track), ("s", .literal ["left", "right"])] } = []
-- cycles: the structural error, and the call left unexpanded once the fuel is spent
def cyA : Concept := { touching with id := "drv.x.a", body := .formula (.derived "drv_x_b" [.var "x"] []) }
def cyB : Concept := { touching with id := "drv.x.b", body := .formula (.derived "drv_x_a" [.var "x"] []) }
#guard Concept.onCycle [cyA, cyB] = ["drv.x.a", "drv.x.b"]
#guard (Concept.check [cyA, cyB] cyA).length = 2

-- expansion: actuals substituted, parameters replaced by the caller's terms, the bound variable
-- renamed so the caller's `y` is not captured, nested calls expanded to atoms
def same (a b : Formula) : Bool := reprStr a == reprStr b
def callHalted : Formula := .derived "drv_motion_halted" [Y] [.param "p.stop_speed", sec 1]
#guard same (Concept.expand cs callHalted)
  (.holdsFor .time (sec 1) "y" (.cmp (.measure "kin_speed" [Y]) .le (.param "p.stop_speed")))
#guard same (Concept.expand cs (.derived "drv_interaction_touching_some" [Y] []))
  (.existsUser "y#0" (.atom "rel_contact" [Y, .var "y#0"] []))
#guard (Formula.atoms (Concept.expand cs (.derived "drv_motion_halted_touching" [X] [mps 1, sec 2]))).all fun n => !n.startsWith "drv_"
#guard same (Concept.expand cs (.derived "drv_motion_unknown" [X] [])) (.derived "drv_motion_unknown" [X] [])
#guard same (Concept.expand cs (.derived "drv_motion_halted" [X] [])) (.derived "drv_motion_halted" [X] [])   -- arity: left for the check
-- once: the outer call only
#guard (Formula.atoms (Concept.expandOnce cs (.derived "drv_motion_halted_touching" [X] [mps 1, sec 2]))).contains "drv_motion_halted"

-- a rule through a concept evaluates as the same formula written inline
def haltRule : Rule :=
  { Tests.Grounding.truckRule with obligation := .derived "drv_motion_halted" [X] [.param "p.stop_speed", sec 1] }
def haltWitness : Scenario := Tests.Decode.sc
#guard (haltWitness.run [haltRule] cs).isOk
#guard !(haltWitness.run [haltRule]).isOk                                     -- no concepts: the call is malformed
#guard Rule.check [Concept.expandRule cs haltRule] (Concept.expandRule cs haltRule) = []

-- a witness instance of the concept itself, and adequacy over its body
def inst : Concept.Instance :=
  { name := "halted@slow", concept := "drv.motion.halted", params := [("eps", .lit (Q.mk' 1 10) .metrePerSecond), ("d", sec 1)] }
def instRule : Rule := (Concept.asRule cs inst).getD default
#guard (Concept.asRule cs inst).isSome
#guard instRule.binders.map (·.name) = ["x"]
#guard (Concept.asRule cs { inst with params := [] }).isNone
#guard (Concept.asRule cs { inst with concept := "drv.motion.none" }).isNone
def scInst : Scenario := { Tests.Decode.sc with rule := "halted@slow", grounding := [("x", 2)] }
#guard (scInst.run [instRule] cs).isOk
#guard (TrafficSpec.Adequacy.unexercised [instRule] instRule [scInst] cs).length = 0
-- a quantity concept, witnessed through bounds
def bumped : Concept :=
  { id := "drv.motion.speed_plus", contract := "the speed plus a margin"
    args := [("x", .track)], params := [⟨"margin", .metrePerSecond⟩]
    body := .quantity (.add (.measure "kin_speed" [.var "x"]) (.param "margin")) }
#guard Concept.check cs bumped = []
#guard bumped.isQuantity
def instQ : Concept.Instance :=
  { name := "speed_plus@3", concept := "drv.motion.speed_plus", params := [("margin", mps 3)], bounds := some (mps 2, mps 4) }
#guard (Concept.asRule (bumped :: cs) { instQ with bounds := none }).isNone
def instQRule : Rule := (Concept.asRule (bumped :: cs) instQ).getD default
#guard (({ scInst with rule := "speed_plus@3" } : Scenario).run [instQRule] (bumped :: cs)).isOk   -- track 2 stands: 0 + 3 ∈ [2, 4]

-- export
#guard ((Formula.toJson callHalted).compress.splitOn "drv_motion_halted").length = 2
#guard ((Concept.toJson halted).compress.splitOn "holds_for").length = 2
#guard ((Concept.toJson { halted with narrowings := [⟨"a run of words", "read as a bound", "reading"⟩] }).compress.splitOn "\"narrowings\":[{\"kind\":\"reading\",\"span\":\"a run of words\"").length = 2
#guard ((Concept.toJson halted).compress.splitOn "\"narrowings\":[]").length = 2

-- region formals: a concept takes the region its caller singles out
def onLane : Concept :=
  { id := "drv.place.on", contract := "x occupies region j", args := [("x", .track), ("j", .region)], params := []
    body := .formula (.atom "rel_occupies" [X, .var "j"] []) }
#guard Concept.check [onLane] onLane = []
#guard !(Concept.check [{ onLane with args := [("x", .track), ("j", .track)] }] { onLane with args := [("x", .track), ("j", .track)] }).isEmpty
#guard ((Concept.toJson onLane).compress.splitOn "\"sort\":\"region\"").length = 2
def lanes : Trace := (List.range 3).map fun k =>
  { Tests.Semantics.sceneAt k with structures := [Tests.Semantics.lane7, Tests.Semantics.lane8], occupies := [(1, 7), (2, 7)] }
def mv (v : String) : Formula := .atom "ru_motor_vehicle" [.var v] []
def onSome : Rule := { id := "test/on", laws := [], binders := [⟨"x", mv "x"⟩], applicability := .tt
                       obligation := .existsRegion (.lit "lane") "j" (.derived "drv_place_on" [X, .var "j"] []) }
#guard Rule.check [Concept.expandRule [onLane] onSome] (Concept.expandRule [onLane] onSome) = []
#guard Concept.ruleCallDefects [onLane] onSome = []

-- instances and their regions
def instOn : Concept.Instance := { name := "on@j", concept := "drv.place.on" }
def instOnRule : Rule := (Concept.asRule [onLane] instOn).getD default
#guard instOnRule.binders.map (·.name) = ["x"]
#guard Concept.Instance.defects [onLane] instOn = []
#guard Rule.check [instOnRule] instOnRule ["j"] = []
#guard !(Rule.check [instOnRule] instOnRule).isEmpty                       -- `j` unbound without the region scope
#guard Concept.regionDefects onLane "s" [("j", 7)] = []
#guard (Concept.regionDefects onLane "s" []).length = 1
#guard (Concept.regionDefects onLane "s" [("j", 7), ("j", 8)]).length = 1
#guard (Concept.regionDefects onLane "s" [("q", 7)]).length = 2
def kindOf : Concept :=
  { id := "drv.place.on_kind", contract := "x occupies some region of kind k", args := [("x", .track), ("k", .literal ["lane", "crosswalk"])], params := []
    body := .formula (.existsRegion (.var "k") "r" (.atom "rel_occupies" [X, .var "r"] [])) }
#guard Concept.check [kindOf] kindOf = []
def instK : Concept.Instance := { name := "k", concept := "drv.place.on_kind", literals := [("k", "lane")] }
#guard Concept.Instance.defects [kindOf] instK = []
#guard (Concept.Instance.defects [kindOf] { instK with literals := [] }).length = 1
#guard (Concept.Instance.defects [kindOf] { instK with literals := [("k", "lane"), ("k", "lane")] }).length = 1
#guard (Concept.Instance.defects [kindOf] { instK with literals := [("k", "bogus")] }).length = 1
#guard (Concept.Instance.defects [kindOf] { instK with literals := [("k", "lane"), ("z", "lane")] }).length = 1
#guard (Concept.Instance.defects [kindOf] { instK with concept := "drv.place.none" }).length = 1

-- the binding reaches every evaluation, each scenario with its own region
def scOn (reg : RegionId) (v : Verdict) : Scenario :=
  { name := s!"on {reg}", rule := "on@j", trace := lanes, reading := {}, manifest := Manifest.full "t",
    grounding := [("x", 1)], regions := [("j", reg)], expected := v }
#guard ((scOn 7 .compliant).run [instOnRule] [onLane]).isOk
#guard ((scOn 8 .violated).run [instOnRule] [onLane]).isOk
#guard !(({ scOn 7 .compliant with regions := [] } : Scenario).run [instOnRule] [onLane]).isOk
#guard !((scOn 99 .compliant).run [instOnRule] [onLane]).isOk                        -- no structure 99 in the trace
def lanesEarly : Trace := lanes.mapIdx fun k s => if k == 0 then s else { s with structures := [Tests.Semantics.lane7] }
#guard (({ scOn 8 .violated with trace := lanesEarly } : Scenario).run [instOnRule] [onLane]).isOk   -- structure 8 in the first scene only
#guard ((Grounding.timeline (Grounding.Setup.mk' [instOnRule] lanes {} Q.zero) instOnRule { assign := [("x", 1)], regions := [("j", 7)] }).toList.map (·.2))
  = List.replicate 3 .compliant
#guard ((Grounding.timeline (Grounding.Setup.mk' [instOnRule] lanes {} Q.zero) instOnRule { assign := [("x", 1)], regions := [("j", 8)] }).toList.map (·.2))
  = List.replicate 3 .violated
#guard TrafficSpec.Adequacy.unexercised [instOnRule] instOnRule [scOn 7 .compliant, scOn 8 .violated] [onLane] = []
#guard ({ assign := [("x", 5)], regions := [("j", 5)] } : Grounding.Grounding).binding.lookup "j" = some (.region 5)
#guard ({ assign := [("x", Grounding.canon Tests.Grounding.Sb.cm 5)], regions := [("j", 5)] } : Grounding.Grounding).binding.binds
  = [("x", .track 1), ("j", .region 5)]                                             -- re-identification maps tracks only

-- call signatures, checked before expansion
def sameTrack : Concept :=
  { id := "drv.x.same_track", contract := "a and b are the same road user", args := [("a", .track), ("b", .track)], params := []
    body := .formula (.same (.var "a") (.var "b")) }
def sameQ : Concept :=
  { id := "drv.x.same_q", contract := "1 s where a and b are the same road user, else 0 s", args := [("a", .track), ("b", .track)], params := []
    body := .quantity (.cond (.same (.var "a") (.var "b")) (sec 1) (sec 0)) }
def withJ (φ : Formula) : Rule := { onSome with id := "test/sig", obligation := .existsRegion (.lit "lane") "j" φ }
def sigCs : List Concept := [onLane, kindOf, sameTrack, sameQ]
#guard Rule.check [Concept.expandRule sigCs (withJ (.derived "drv_x_same_track" [X, .var "j"] []))]
  (Concept.expandRule sigCs (withJ (.derived "drv_x_same_track" [X, .var "j"] []))) = []             -- expansion loses the signature
#guard (Concept.ruleCallDefects sigCs (withJ (.derived "drv_x_same_track" [X, .var "j"] []))).length = 1
#guard (Concept.ruleCallDefects sigCs (withJ (.cmp (.quantity "drv_x_same_q" [X, .var "j"] []) .le (sec 1)))).length = 1
#guard (Concept.ruleCallDefects sigCs (withJ (.derived "drv_place_on" [X, X] []))).length = 1
#guard (Concept.ruleCallDefects sigCs (withJ (.derived "drv_place_on_kind" [X, .lit "bogus"] []))).length = 1
#guard (Concept.ruleCallDefects sigCs { onSome with binders := [⟨"x", .derived "drv_place_on_kind" [X, .lit "bogus"] []⟩] }).length = 1
#guard Concept.ruleCallDefects sigCs (withJ (.derived "drv_place_on_kind" [X, .lit "lane"] [])) = []
#guard Concept.ruleCallDefects sigCs (withJ (.derived "drv_x_same_track" [X, X] [])) = []
def wraps : Concept :=
  { id := "drv.x.wraps", contract := "c", args := [("a", .track), ("b", .region)], params := []
    body := .formula (.derived "drv_x_same_track" [.var "a", .var "b"] []) }
#guard (Concept.check (wraps :: sigCs) wraps).any (·.startsWith "drv.x.wraps: `drv.x.same_track` formal `b`")
def forwards : Concept :=
  { id := "drv.x.forwards", contract := "c", args := [("u", .track), ("k", .literal ["lane"])], params := []
    body := .formula (.derived "drv_place_on_kind" [.var "u", .var "k"] []) }
#guard Concept.check (forwards :: sigCs) forwards = []
def widens : Concept := { forwards with id := "drv.x.widens", args := [("u", .track), ("k", .literal ["lane", "stop_line"])] }
#guard (Concept.check (widens :: sigCs) widens).any (·.startsWith "drv.x.widens: `drv.place.on_kind` formal `k`")
def countsN : Concept := { id := "drv.x.n", contract := "c", args := [("x", .track), ("n", .nat)], params := [], body := .formula (mv "x") }
def forwardsN : Concept := { countsN with id := "drv.x.fn", body := .formula (.derived "drv_x_n" [X, .var "n"] []) }
#guard Concept.check [countsN, forwardsN] forwardsN = []
#guard !(Concept.check [countsN, { forwardsN with body := .formula (.derived "drv_x_n" [X, .lit "3"] []) }]
  { forwardsN with body := .formula (.derived "drv_x_n" [X, .lit "3"] []) }).isEmpty

-- a concept with region formals only: checked and evaluated with no road-user argument
def occupied : Concept :=
  { id := "drv.place.occupied", contract := "some road user occupies region j", args := [("j", .region)], params := []
    body := .formula (.existsUser "u" (.atom "rel_occupies" [.var "u", .var "j"] [])) }
#guard Concept.check [occupied] occupied = []
def instOcc : Rule := (Concept.asRule [occupied] { name := "occ", concept := "drv.place.occupied" }).getD default
#guard instOcc.binders = []
#guard Rule.check [instOcc] instOcc ["j"] = []
#guard !(Rule.check [instOcc] instOcc).isEmpty                                       -- a rule with no binder, outside an instance
#guard (({ name := "occ 7", rule := "occ", trace := lanes, reading := {}, manifest := Manifest.full "t", grounding := [],
           regions := [("j", 7)], expected := .compliant } : Scenario).run [instOcc] [occupied]).isOk
#guard (({ name := "occ 8", rule := "occ", trace := lanes, reading := {}, manifest := Manifest.full "t", grounding := [],
           regions := [("j", 8)], expected := .violated } : Scenario).run [instOcc] [occupied]).isOk

-- expansion never captures the caller's region: the callee binds a variable of the same name
def otherLane : Concept :=
  { id := "drv.place.other_lane", contract := "x occupies a lane other than r", args := [("x", .track), ("r", .region)], params := []
    body := .formula (.existsRegion (.lit "lane") "j" (.and (.atom "rel_occupies" [X, .var "j"] []) (.not (.same (.var "j") (.var "r"))))) }
def callsOther : Rule := withJ (.derived "drv_place_other_lane" [X, .var "j"] [])
#guard ((Grounding.timeline (Grounding.Setup.mk' [Concept.expandRule [otherLane] callsOther] lanes {} Q.zero)
  (Concept.expandRule [otherLane] callsOther) { assign := [("x", 1)] }).toList.map (·.2)) = List.replicate 3 .compliant

-- a concept body reads no declared intention, with region formals present and the leaf in a `cond`
def intendsAt : Concept :=
  { onLane with id := "drv.x.intends_at"
                body := .formula (.cmp (.cond (.intent "int.turn_left" X (.var "j")) (sec 1) (sec 2)) .le (sec 3)) }
#guard (Concept.check [intendsAt] intendsAt).any (·.endsWith "a concept reads no declared intention (`int.turn_left`)")

-- the defect of a concept that finds "the" junction for itself: the road user is on a lane into
-- junction A (signal working) and on one into junction B (signal dark)
def laneInto (id j : Nat) : Structure := { id := id, kind := .lane, lane := some { entersIntersection := some j } }
def ab : Trace :=
  [{ t := 0, users := [{ track := 1 }], occupancyObserved := [1], occupies := [(1, 11), (1, 12)]
     structures := [laneInto 11 20, laneInto 12 30, { id := 20, kind := .intersection }, { id := 30, kind := .intersection }]
     devices := [{ id := 41, kind := .trafficSignal, governs := [20], inoperative := some false },
                 { id := 42, kind := .trafficSignal, governs := [30], inoperative := some true }] }]
def darkAt (i : Arg) : Formula :=
  .and (.existsRegion (.lit "lane") "l" (.and (.atom "rel_occupies" [X, .var "l"] []) (.atom "st_lane_enters" [.var "l", i] [])))
       (.existsDevice (.lit "traffic_signal") "d" (.and (.atom "dev_governs" [.var "d", i] []) (.atom "dev_inoperative" [.var "d"] [])))
def darkAny : Concept :=
  { id := "drv.x.dark_any", contract := "c", args := [("x", .track)], params := [], body := .formula (.existsRegion (.lit "intersection") "i" (darkAt (.var "i"))) }
def darkAtJ : Concept :=
  { id := "drv.x.dark_at", contract := "c", args := [("x", .track), ("i", .region)], params := [], body := .formula (darkAt (.var "i")) }
#guard Concept.check [darkAny] darkAny = []
#guard Concept.check [darkAtJ] darkAtJ = []
def abRun (c : Concept) (regions : List (String × RegionId)) (v : Verdict) : Bool :=
  let r := (Concept.asRule [c] { name := "ab", concept := c.id }).getD default
  (({ name := "ab", rule := "ab", trace := ab, reading := {}, manifest := Manifest.full "t", grounding := [("x", 1)],
      regions := regions, expected := v } : Scenario).run [r] [c]).isOk
#guard abRun darkAny [] .compliant                                                      -- true through B
#guard abRun darkAtJ [("i", 20)] .violated                                              -- called with A
#guard abRun darkAtJ [("i", 30)] .compliant                                             -- called with B


-- a call's sorts are those of the innermost binding of each name, as evaluation reads them
def shadowed (φ : Formula) : Rule := { onSome with id := "test/shadow", obligation := φ }
#guard (Concept.ruleCallDefects sigCs (shadowed (.existsRegion (.lit "lane") "x" (.derived "drv_place_on" [X, .var "x"] [])))).length = 1
#guard (Concept.ruleCallDefects sigCs (shadowed (.existsRegion (.lit "lane") "j" (.existsUser "j" (.derived "drv_place_on" [X, .var "j"] []))))).length = 1
#guard Concept.ruleCallDefects sigCs (shadowed (.existsRegion (.lit "lane") "j" (.existsRegion (.lit "lane") "j" (.derived "drv_place_on" [X, .var "j"] [])))) = []
#guard (Concept.check (wraps :: sigCs) { wraps with id := "drv.x.wraps2", body := .formula (.existsRegion (.lit "lane") "a" (.derived "drv_x_same_track" [.var "a", .var "a"] [])) }).any
  (·.startsWith "drv.x.wraps2: `drv.x.same_track` formal `a`")

end TrafficSpec.Tests.Concept
