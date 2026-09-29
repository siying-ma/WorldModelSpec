import TrafficSpec.Core.Evidence.Adequacy
import TrafficSpec.Tests.Decode
namespace TrafficSpec.Tests.Adequacy
open TrafficSpec Units TrafficSpec.Tests.Grounding

-- leaf enumeration and replacement
def φ3 : Formula := .and (.atom "a" [] []) (.or (.asm "b") (.derived "c" [] []))
#guard Formula.leafCount φ3 = 3
def same (a b : Formula) : Bool := reprStr a == reprStr b
#guard same (Formula.replaceLeaf 0 .tt φ3) (.and .tt (.or (.asm "b") (.derived "c" [] [])))
#guard same (Formula.replaceLeaf 2 .ff φ3) (.and (.atom "a" [] []) (.or (.asm "b") .ff))
#guard same (Formula.replaceLeaf 1 .ff (.until (.asm "p") (.asm "q"))) (.until (.asm "p") .ff)
#guard same (Formula.replaceLeaf 7 .ff φ3) φ3
#guard (Formula.literals (.cmp (.measure "kin_speed" [.var "x"]) .le (.lit (metresPerSecond 2) .metrePerSecond))).length = 1
#guard (Formula.literals (.cmp (.measure "kin_speed" [.var "x"]) .le (.param "p"))).length = 0
#guard (Formula.literals (.cmp (.measure "kin_speed" [.var "x"]) .le (.lit Q.zero .metrePerSecond))).length = 0

-- the truck-stop witnesses: one scenario cannot exercise the single leaf both ways
def stopped : Scenario := Tests.Decode.sc
#guard (TrafficSpec.Adequacy.unexercised rules truckRule [stopped]).length = 0     -- tt keeps compliant, ff makes it violated
-- the gap rule with only an idle witness (y is not ahead of x): the ahead-in-lane leaf is exercised
-- (replacing it by tt engages the rule), the gap comparison and the obligation leaf are not — no
-- witness ever reaches them
def idleOnly : Scenario := { stopped with rule := "test/gap", grounding := [("x", 2), ("y", 1)], expected := .notApplicable }
def unex := TrafficSpec.Adequacy.unexercised rules rule [idleOnly]
#guard unex.length = 2
#guard unex.any (·.startsWith "applicability leaf 1")
#guard unex.any (·.startsWith "obligation leaf 0")
-- with the following witness added, every leaf moves some verdict
def following : Scenario := { stopped with rule := "test/gap", grounding := [("x", 1), ("y", 2)], expected := .unknown [] }
#guard TrafficSpec.Adequacy.unexercised rules rule [idleOnly, following] = []
end TrafficSpec.Tests.Adequacy
