import TrafficSpec.Core.Runtime.Grounding
namespace TrafficSpec.Tests.PathSearch
open TrafficSpec Units

-- The distance travelled since the trace began is refused where it can decide a search into the
-- past, and admitted everywhere else.
def V : Arg := .var "v"
def path : Term := .measure "kin_path_length" [V]
def moved : Formula := .cmp path .gt (.lit Q.zero .metre)
def unmoved : Formula := .cmp path .le (.lit Q.zero .metre)
def slow : Formula := .cmp (.measure "kin_speed" [V]) .le (.lit (metresPerSecond 1) .metrePerSecond)
def sec : Term := .lit (seconds 3) .second
def rule (id : String) (obl : Formula) : Rule :=
  { id := id, laws := [], binders := [{ name := "v", cls := .atom "ru_motor_vehicle" [V] [] }], applicability := .tt, obligation := obl }
def flagged (rules : List Rule) (r : Rule) : Bool :=
  (Rule.check rules r).any fun e => (e.splitOn "search into the past").length > 1
def alone (obl : Formula) : Bool := let r := rule "t/p" obl; flagged [r] r

-- refused: inside each backward operator, at any depth, and through a term
#guard alone (.since moved slow)
#guard alone (.since .tt (.or slow unmoved))
#guard alone (.cmp (.sinceRise moved) .ge sec)
#guard alone (.atLast .time sec "v" unmoved slow)
#guard alone (.atLast .time sec "v" slow unmoved)
#guard alone (.count moved .tt .ge 1)
#guard alone (.count .tt unmoved .ge 1)
#guard alone (.rises moved)
#guard alone (.since (.existsRegion (.lit "lane") "l" (.and (.atom "rel_occupies" [V, .var "l"] []) moved)) slow)
#guard alone (.since (.not (.and slow (.cmp (.mul path (.lit (Q.ofInt 2) .ratio)) .le (.lit (metres 4) .metre)))) slow)
#guard alone (.since .tt (.cmp (.cond slow path (.lit Q.zero .metre)) .le (.lit Q.zero .metre)))
#guard alone (.since .tt (.cmp (.aggregate .max "w" .tt (.measure "kin_path_length" [.var "w"])) .le (.lit Q.zero .metre)))
#guard alone (.implies .tt (.not (.since (.eventually moved) slow)))
-- refused through a concept called inside the search (the check runs on the expanded rule)
def notMoved : Concept :=
  { id := "drv.motion.not_moved", contract := "c", args := [("x", .track)], params := []
    body := .formula (.cmp (.measure "kin_path_length" [.var "x"]) .le (.lit Q.zero .metre)) }
def viaConcept : Rule := rule "t/c" (.since (.not (.derived "drv_motion_not_moved" [V] [])) slow)
#guard flagged [] (Concept.expandRule [notMoved] viaConcept)
-- refused through a composed rule that reads it, at any depth of composition
def inner : Rule := rule "t/inner" unmoved
def middle : Rule := rule "t/middle" (.rule "t/inner" [("v", "v")])
def outer : Rule := rule "t/outer" (.since (.not (.rule "t/middle" [("v", "v")])) slow)
#guard flagged [inner, middle, outer] outer
#guard Rule.readsPath [inner, middle, outer] middle

-- admitted: arithmetic and comparisons outside a backward search, forward and windowed operators,
-- path windows and `distanceWhile`, a concept or a rule that reads it called outside a search, and a
-- composed rule that does not read it called inside one
#guard !alone moved
#guard !alone (.cmp (.add path path) .ge (.lit (metres 10) .metre))
#guard !alone (.eventually moved)
#guard !alone (.always unmoved)
#guard !alone (.holdsFor .time sec "v" unmoved)
#guard !alone (.within .time sec "v" moved)
#guard !alone (.until slow moved)
#guard !alone (.since .tt (.cmp (.distanceWhile "v" slow) .ge (.lit (metres 5) .metre)))
#guard !alone (.since (.holdsFor .path (.lit (metres 5) .metre) "v" slow) slow)
#guard !flagged [] (Concept.expandRule [notMoved] (rule "t/c2" (.and (.derived "drv_motion_not_moved" [V] []) slow)))
#guard !flagged [inner, middle, rule "t/o2" (.and (.rule "t/middle" [("v", "v")]) slow)] (rule "t/o2" (.and (.rule "t/middle" [("v", "v")]) slow))
def plain : Rule := rule "t/plain" slow
def outer2 : Rule := rule "t/outer2" (.since (.not (.rule "t/plain" [("v", "v")])) slow)
#guard !flagged [plain, outer2] outer2

-- concepts are held to it on their own bodies
def searchConcept : Concept :=
  { id := "drv.motion.since_moved", contract := "c", args := [("x", .track)], params := []
    body := .formula (.since (.cmp (.measure "kin_path_length" [.var "x"]) .gt (.lit Q.zero .metre)) .ff) }
#guard (Concept.check [searchConcept] searchConcept).any fun e => (e.splitOn "search into the past").length > 1
#guard Concept.check [notMoved] notMoved = []

end TrafficSpec.Tests.PathSearch
