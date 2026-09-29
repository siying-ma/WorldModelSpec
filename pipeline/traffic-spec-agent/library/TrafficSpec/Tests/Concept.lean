import TrafficSpec.Core.Export
import TrafficSpec.Core.Adequacy
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
#guard halted.atoms = ["kin_speed"]
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
end TrafficSpec.Tests.Concept
