import TrafficSpec.Tests.Semantics
import TrafficSpec.Tests.Refinement
import TrafficSpec.Core.Language.EvalFast
namespace TrafficSpec.Tests.EvalFast
open TrafficSpec Units TrafficSpec.Semantics TrafficSpec.Tests.Semantics

-- ---------------------------------------------------------------------------------------------
-- The cached evaluator against `evalAll`: the same value and the same reasons at every instant.
-- ---------------------------------------------------------------------------------------------
def sameR (a b : Array R) : Bool := a.size == b.size && (a.zip b).all fun (x, y) => x.v == y.v && x.why == y.why
def sameQ (a b : Array QR) : Bool := a.size == b.size && (a.zip b).all fun
  | (.ok x, .ok y) => Q.eq x y | (.error e, .error e') => e == e' | _ => false
def agrees (cells : Nat) (c : SemCtx) (φ : Formula) : Bool := sameR (evalFastWith cells c φ).1 (evalAll c φ)
def agreesT (cells : Nat) (c : SemCtx) (t : Term) : Bool := sameQ (evalFastTWith cells c t).1 (evalTAll c t)

def Z : Arg := .var "z"
-- a body whose sub-formulas repeat under a quantifier, reading the outer and the bound variable
def nested : Formula :=
  .forallUser "u" (.and fast4 (.existsRegion (.lit "lane") "r"
    (.or (.atom "rel_occupies" [.var "u", .var "r"] []) (.atom "rel_occupies" [X, .var "r"] []))))
-- `x` bound by the binding and again by a quantifier: the inner `x` is the quantified user
def shadowed : Formula := .and fast4 (.existsUser "x" (.and slow (.forallUser "x" fast)))
-- an unbound variable: unknown at every instant
def unbound : Formula := .cmp (.measure "kin_speed" [Z]) .ge (mps 1)
def previously (φ : Formula) : Formula := .or (.rises (.not φ)) (.and φ (.not (.rises φ)))
def corpus : List Formula :=
  [.tt, .ff, fast4, slow, fast, never, stopped, following timeGap, onWet .le 7, pathGe 10,
   .until slow halted, .since green halted, .always (.implies fast4 (.eventually halted)),
   .holdsFor .path (.lit (metres 3) .metre) "x" slow, .within .time (sec 2) "x" halted,
   .untilWithin .time (sec 3) "x" (.not halted) halted, .atLast .time (sec 4) "x" green fast4,
   .count green (.rises halted) .ge 1, .definedWhen fast4 slow, nested, shadowed, unbound,
   previously (previously fast4), .existsUser "u" (.cmp (.distanceWhile "u" halted) .ge (.lit (metres 0) .metre)),
   .cmp (.aggregate .max "u" .tt (.measure "kin_speed" [.var "u"])) .ge (mps 8),
   .cmp (.cond fast4 (sec 1) (sec 2)) .eq (sec 1), .cmp (.sinceRise halted) .ge (sec 1),
   agg "x" "D-1::vehicle", .existsDevice (.lit "traffic_signal") "s" (.atom "dev_governs" [.var "s", .nat 7] []),
   .forallDevice (.lit "traffic_signal") "s" .ff, .forallRegion (.lit "lane") "r" .tt,
   .existsRegion (.lit "highway") "h" (.atom "rel_occupies" [X, .var "h"] []), .rule "some/rule" []]
def contexts : List SemCtx := [c, ca, clane, cgeo, cunk, carr, SemCtx.mk' [] ρ β, SemCtx.mk' τ ρ {}]

-- every formula in every context, with a cache large enough to keep everything and one so small
-- that it is emptied again and again
#guard contexts.all fun c => corpus.all (agrees defaultCells c)
#guard contexts.all fun c => corpus.all (agrees 10 c)
#guard contexts.all fun c => [timeGap, .aggregate .min "u" fast4 (.measure "kin_speed" [.var "u"]),
  .cond green (mps 1) (.measure "kin_speed" [Z]), .distanceWhile "z" halted].all (agreesT 10 c)

-- reads and emptyings: a repeated sub-formula is read from the cache; a bound of one value per
-- observation empties it on every store and still gives the same values
#guard (evalFastWith defaultCells c (previously (previously fast4))).2.hits > 0
#guard (evalFastWith defaultCells c (previously (previously fast4))).2.evictions = 0
#guard (evalFastWith 9 c (previously (previously fast4))).2.evictions > 0
#guard (evalFastWith defaultCells c nested).2.hits > 0
-- the empty trace and the empty binding
#guard (evalFastAll (SemCtx.mk' [] ρ β) nested).size = 0
#guard (evalFastAll (SemCtx.mk' τ ρ {}) fast4).all fun r => r.v == .u
-- three values occur
#guard [Tri.t, .f, .u].all fun x => (corpus.flatMap fun φ => (evalFastAll cunk φ).toList).any (·.v == x)

-- composition reads the whole binding: a rule composed under two bindings, through one cache
def inner : Rule := { id := "t_inner", laws := [], binders := [{ name := "a", cls := .tt }], applicability := .tt,
                      obligation := .cmp (.measure "kin_speed" [.var "a"]) .ge (mps 4) }
def outer : Formula := .and (.rule "t_inner" [("a", "x")]) (.existsUser "x" (.rule "t_inner" [("a", "x")]))
def cr : SemCtx := Rule.context [inner] c.d β
#guard sameR (evalFastAll cr outer) (evalAll cr outer)
#guard sameR (evalFastAll cr (.ruleApplies "t_inner" [("a", "y")])) (evalAll cr (.ruleApplies "t_inner" [("a", "y")]))
#guard (Key.ofF (.rule "t_inner" [("a", "x")]) β).whole = β.binds
#guard (Key.ofF fast4 β).whole = []

-- region quantifiers through the tables, on scenes with a repeated id, absent regions, masked
-- kinds and region order that differs between scenes: every kind, both quantifiers, nested
def tCtx : SemCtx := Refinement.tCtx
def occR (u r : String) : Formula := .atom "rel_occupies" [.var u, .var r] []
def regionCorpus : List Formula :=
  Refinement.structureKinds.flatMap fun k =>
    [.existsRegion (.lit k.toString) "r" (occR "x" "r"), .forallRegion (.lit k.toString) "r" (occR "y" "r"),
     .forallUser "u" (.existsRegion (.lit k.toString) "r" (.or (occR "u" "r") (.existsRegion (.lit "travel_region") "q" (occR "u" "q"))))]
#guard regionCorpus.all (agrees defaultCells tCtx)
#guard regionCorpus.all (agrees 10 tCtx)
#guard corpus.all (agrees defaultCells tCtx)
#guard corpus.all (agrees 10 tCtx)

-- the arm the evaluator calls is the former region branch, for the evaluator itself
example (c : SemCtx) (kd : StructureKind) (v : String) (φ : Formula) :
    regionArm fastF c kd v φ R.and R.any = (do
      let ev ← (regionsOf c kd).mapM fun r =>
        return (r, Array.zipWith R.and (regionIsKind c r kd) (← fastF (c.bindVar v (.region r)) φ))
      return perScene c ev (fun s r => (s.structure? r).isSome) R.any) :=
  regionArm_eq _ _ _ _ _ _ _
example (c : SemCtx) (kd : StructureKind) (v : String) (φ : Formula) :
    regionArm fastF c kd v φ R.implies R.all = (do
      let ev ← (regionsOf c kd).mapM fun r =>
        return (r, Array.zipWith R.implies (regionIsKind c r kd) (← fastF (c.bindVar v (.region r)) φ))
      return perScene c ev (fun s r => (s.structure? r).isSome) R.all) :=
  regionArm_eq _ _ _ _ _ _ _

-- counting a miss before storing gives the cache that storing before counting gives
theorem putF_misses (c : Cache) (key : Key) (v : Array R) :
    { c.putF key v with misses := c.misses + 1 } = Cache.putF { c with misses := c.misses + 1 } key v := by
  unfold Cache.putF
  split <;> rfl
theorem putT_misses (c : Cache) (key : Key) (v : Array QR) :
    { c.putT key v with misses := c.misses + 1 } = Cache.putT { c with misses := c.misses + 1 } key v := by
  unfold Cache.putT
  split <;> rfl

end TrafficSpec.Tests.EvalFast
