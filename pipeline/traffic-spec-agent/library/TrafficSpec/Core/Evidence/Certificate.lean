/-
  TrafficSpec.Core.Evidence.Certificate
  A case: the statement, as a formula of the specification language, of the facts a written
  counterexample trace shows at one instant, with the entities it names. It is evidence about a
  scene, never a mapping of a law's words.

  `Case.check` admits a case only when:
  - it uses the constructors of observable facts: no assumption, no reading parameter, no other
    rule, no concept (a derived concept or quantity whose name is not a primitive's), no division
    except by a non-zero literal, and no `ru_aggregate` (a case names a road user's concrete
    classes, never a legal aggregate);
  - every atom and primitive it names is in the active vocabulary, with the arity and argument
    sorts the static check holds a rule to, every entity position filled by a bound variable;
  - its units agree: a measured atom and a primitive have the units the ontology states
    (`Dimensions`), a literal has its unit's; the two sides of a comparison, the operands of a sum
    or difference and the branches of a selection have the same unit; a product adds and a
    quotient subtracts units; a window's length is a time or a distance as the window measures;
    an atom's and a primitive's parameters have their stated units;
  - its entity names are distinct and distinct from the grounding's binders, and no quantifier
    binds a binder's or an entity's name.
  `Case.eval` decides the case at its instant with the grounding's tracks and the entities bound
  and an empty reading, which a checked case never reads.

  `record` runs the admission of one divergence — trace decoding (the occupancy of every observed
  track then derived from the geometry, `TraceLint.completeOccupancy`), case decoding, the trace lint,
  the witness check, the case check, the case at its instant, the rule's verdict at that instant,
  and the rule's verdict with each referenced aggregate's membership of each track forced true and
  false — and reports it as one JSON object of schema `certificate-run/1`. A step whose
  prerequisites failed reports null; every step that can run does, so all defects are reported at
  once. The rule's verdict and the overrides are computed only when everything before passed and
  the case holds.
-/
import TrafficSpec.Core.Evidence.TraceLint
import TrafficSpec.Core.Runtime.Grounding
import TrafficSpec.Core.Runtime.Manifest
import TrafficSpec.Core.Runtime.Decode
import TrafficSpec.Core.Language.Export
import TrafficSpec.Core.Vocab.Ontology.Dimensions

namespace TrafficSpec

namespace Dim
def one : Dim := ⟨0, 0, 0⟩
def length : Dim := ⟨1, 0, 0⟩
def time : Dim := ⟨0, 1, 0⟩
def mul (a b : Dim) : Dim := ⟨a.m + b.m, a.s + b.s, a.deg + b.deg⟩
def div (a b : Dim) : Dim := ⟨a.m - b.m, a.s - b.s, a.deg - b.deg⟩
def ofUnit : PUnit' → Dim
  | .metre => ⟨1, 0, 0⟩ | .second => ⟨0, 1, 0⟩ | .metrePerSecond => ⟨1, -1, 0⟩
  | .metrePerSecondSq => ⟨1, -2, 0⟩ | .degree => ⟨0, 0, 1⟩ | .degreePerSecond => ⟨0, -1, 1⟩ | .perMetre => ⟨-1, 0, 0⟩
  | .ratio => one | .count => one
def render (d : Dim) : String :=
  let parts := ([("m", d.m), ("s", d.s), ("deg", d.deg)].filter (·.2 != 0)).map fun (u, e) =>
    if e == 1 then u else s!"{u}^{e}"
  if parts.isEmpty then "1 (no unit)" else String.intercalate "·" parts
end Dim

/-- A case: a formula over the trace, the entities it names beside the grounding's binders, and
    the instant (milliseconds) at which it is stated. -/
structure Case where
  formula : Formula
  entities : List (String × Val)
  at_ : Timestamp
  deriving Inhabited

namespace Case
open Semantics

/-- Why a name written as a primitive is not one: a measure is written `measure`; any other name
    is a concept, which a case never names. -/
def notPrimitive (c : String) : String :=
  if (Dimensions.ofMeasure.lookup c).isSome then
    s!"`{c}` is a measure, not a primitive: write it {"{"}\"measure\": \"{c}\", \"args\": [...]{"}"}"
  else s!"`{c}` is not a primitive; a case names no concept"

/-- The unit of a term, or why a case may not state it. -/
partial def termDim : Term → Except String Dim
  | .lit _ u => .ok (Dim.ofUnit u)
  | .param p => .error s!"`{p}` is a reading parameter; a case states facts, never a parameter"
  | .measure a _ => match Dimensions.ofMeasure.lookup a with
    | some d => .ok d
    | none => .error s!"measure `{a}` is not in the case vocabulary"
  | .quantity c _ ps =>
    match Dimensions.ofPrimitive.find? (·.1 == c) with
    | some (_, some r, pds) =>
      if ps.length != pds.length then .error s!"`{c}` takes {pds.length} parameter(s), given {ps.length}"
      else match (ps.zip pds).findSome? (fun (p, d) => match termDim p with
          | .ok x => if x == d then none else some s!"`{c}`: a parameter in {x.render} where {d.render} is required"
          | .error e => some e) with
        | some e => .error e
        | none => .ok r
    | some (_, none, _) => .error s!"`{c}` is a Boolean primitive, not a quantity"
    | none => .error (notPrimitive c)
  | .distanceWhile _ _ => .ok Dim.length
  | .sinceRise _ => .ok Dim.time
  | .aggregate op _ _ t => if op == .count then .ok Dim.one else termDim t
  | .add a b | .sub a b => do
    let x ← termDim a; let y ← termDim b
    if x == y then .ok x else .error s!"adds or subtracts {x.render} and {y.render}"
  | .mul a b => do pure (Dim.mul (← termDim a) (← termDim b))
  | .div a b =>
    match b with
    | .lit q _ => if Q.isZero q then .error "divides by zero" else do pure (Dim.div (← termDim a) (← termDim b))
    | _ => .error "divides by something other than a non-zero literal"
  | .neg a | .abs a => termDim a
  | .cond _ a b => do
    let x ← termDim a; let y ← termDim b
    if x == y then .ok x else .error s!"a selection between {x.render} and {y.render}"

private def dimErrors (t : Term) : List String :=
  match termDim t with | .ok _ => [] | .error e => [e]

private def paramErrors (name : String) (ps : List Term) (want : List Dim) : List String :=
  if ps.length != want.length then [s!"`{name}` takes {want.length} parameter(s), given {ps.length}"]
  else (ps.zip want).flatMap fun (p, d) => match termDim p with
    | .ok x => if x == d then [] else [s!"`{name}`: a parameter in {x.render} where {d.render} is required"]
    | .error e => [e]

/-- The formulas a term carries (a window's, an aggregate's condition, a selection's guard), with
    the variables the term itself binds. -/
private partial def inTerm : Term → List Formula × List String
  | .distanceWhile _ φ | .sinceRise φ => ([φ], [])
  | .aggregate _ v φ t => let (fs, vs) := inTerm t; (φ :: fs, v :: vs)
  | .cond φ a b => let (fa, va) := inTerm a; let (fb, vb) := inTerm b; (φ :: fa ++ fb, va ++ vb)
  | .add a b | .sub a b | .mul a b | .div a b => let (fa, va) := inTerm a; let (fb, vb) := inTerm b; (fa ++ fb, va ++ vb)
  | .neg a | .abs a => inTerm a
  | .quantity _ _ ps => ps.foldl (fun (fs, vs) p => let (f, v) := inTerm p; (fs ++ f, vs ++ v)) ([], [])
  | _ => ([], [])

/-- The defects of a case formula other than names, arities and sorts: banned constructors,
    units, and quantifier variables that reuse a reserved name. -/
partial def formulaErrors (reserved : List String) : Formula → List String
  | .tt | .ff | .same _ _ => []
  | .asm id => [s!"assumption `{id}`: a case states facts of the trace, never an assumption"]
  | .rule id _ | .ruleApplies id _ => [s!"rule `{id}`: a case names no other rule"]
  | .atom n _ ps =>
    (if n == "ru_aggregate" then ["`ru_aggregate`: a case names the road user's concrete classes, never a legal aggregate"] else [])
    ++ ps.flatMap (fun p => (match termDim p with
        | .ok d => if d == Dim.one then [] else [s!"atom `{n}`: a parameter in {d.render}; its parameters carry no unit"]
        | .error e => [e]))
    ++ ps.flatMap terms
  | .derived c _ ps =>
    (if !c.startsWith "prim_" then [notPrimitive c]
     else match Dimensions.ofPrimitive.find? (·.1 == c) with
       | some (_, none, pds) => paramErrors c ps pds
       | some (_, some _, _) => [s!"`{c}` is a quantity, not a Boolean primitive"]
       | none => [s!"`{c}` is not in the case vocabulary"])
    ++ ps.flatMap terms
  | .cmp l _ r =>
    (match termDim l, termDim r with
     | .ok x, .ok y => if x == y then [] else [s!"compares {x.render} with {y.render}"]
     | .error e, .ok _ | .ok _, .error e => [e]
     | .error e, .error e' => [e, e'])
    ++ terms l ++ terms r
  | .not φ | .always φ | .eventually φ | .rises φ => formulaErrors reserved φ
  | .and φ ψ | .or φ ψ | .implies φ ψ | .until φ ψ | .since φ ψ | .definedWhen φ ψ =>
    formulaErrors reserved φ ++ formulaErrors reserved ψ
  | .holdsFor m d _ φ | .within m d _ φ => window m d ++ formulaErrors reserved φ
  | .untilWithin m d _ φ ψ | .atLast m d _ φ ψ => window m d ++ formulaErrors reserved φ ++ formulaErrors reserved ψ
  | .count e s _ _ => formulaErrors reserved e ++ formulaErrors reserved s
  | .existsUser v φ | .forallUser v φ | .existsRegion _ v φ | .forallRegion _ v φ
  | .existsDevice _ v φ | .forallDevice _ v φ => binds v ++ formulaErrors reserved φ
where
  binds (v : String) : List String :=
    if reserved.contains v then [s!"a quantifier binds `{v}`, which names a binder or an entity"] else []
  terms (t : Term) : List String :=
    let (fs, vs) := inTerm t
    vs.flatMap binds ++ fs.flatMap (formulaErrors reserved)
  window (m : Measure) (d : Term) : List String :=
    let want := match m with | .time => Dim.time | .path => Dim.length
    (match termDim d with
     | .ok x => if x == want then [] else [s!"a window measured in {match m with | .time => "time" | .path => "path length"} has a length in {x.render}"]
     | .error e => [e])
    ++ terms d

/-- Every defect of a case, given the grounding's binder names. Empty for an admitted case. -/
def check (c : Case) (binders : List String) : List String :=
  let names := c.entities.map (·.1)
  let scope : Rule.Scope := binders.map (fun b => (b, EntityKind.track)) ++ c.entities.map fun (n, v) => (n, v.kind)
  ((names.filter fun n => names.count n > 1).eraseDups.map fun n => s!"entity `{n}` is declared twice")
  ++ ((names.filter binders.contains).map fun n => s!"entity `{n}` has the name of a binder")
  ++ own
  ++ ((Rule.checkFormula scope "case" c.formula).eraseDups.filter fun e => !(named e).any (reported ·))
where
  own := (formulaErrors (binders ++ c.entities.map (·.1)) c.formula).eraseDups
  /-- The names a message quotes in backticks. -/
  named (e : String) : List String := ((e.splitOn "`").zip (List.range (e.splitOn "`").length)).filterMap
    fun (x, i) => if i % 2 == 1 then some x else none
  /-- A name the case's own checks already reported: the generic check would report it again. -/
  reported (n : String) : Bool := own.any fun o => (named o).contains n

/-- The case's value at its instant on a set-up trace: the grounding's tracks and the entities
    bound (tracks through the trace's canonical identities), and an empty reading. -/
def eval (S : Grounding.Setup) (grounding : List (String × TrackId)) (c : Case) : R :=
  let canon := Grounding.canon S.cm
  let β : Binding := ⟨grounding.map (fun (n, t) => (n, Val.track (canon t)))
    ++ c.entities.map fun (n, v) => (n, match v with | .track t => Val.track (canon t) | other => other)⟩
  let ctx := Rule.context S.rules { S.d with ρ := {} } β
  match S.scenes.findIdx? (·.t == c.at_) with
  | some i => (Rule.evalRuleFormula ctx c.formula)[i]?.getD (R.u .outOfRange)
  | none => R.u .outOfRange
end Case

namespace Certificate
open Lean

private def strs (xs : List String) : Json := Json.arr (xs.map Json.str).toArray
private def triTag : Tri → String
  | .t => "true" | .f => "false" | .u => "unknown"
private def reasons (rs : List UnknownReason) : Json := strs (rs.map UnknownReason.tag)

/-- The case of a divergence from its JSON, `{"case": formula, "entities": {...}, "at": ms}`:
    every decoding error, or the case. -/
def decodeCase (text : String) : List String × Option Case :=
  match Json.parse text with
  | .error e => ([s!"case: {e}"], none)
  | .ok j =>
    let f := Decode.need "case" j "case" >>= Decode.formula "case"
    let en := Decode.need "case" j "entities" >>= Decode.entities "entities"
    let at_ := Decode.need "case" j "at" >>= Decode.strictInt "at"
    let errs := (match f with | .error e => [e] | .ok _ => []) ++ (match en with | .error e => [e] | .ok _ => [])
      ++ (match at_ with | .error e => [e] | .ok _ => [])
    match f, en, at_ with
    | .ok f, .ok en, .ok a => ([], some ⟨f, en, a⟩)
    | _, _, _ => (errs, none)

/-- The rule's verdict at instant `i` for the grounding, on a set-up trace. -/
def verdictAt (S : Grounding.Setup) (r : Rule) (g : Grounding.Grounding) (i : Nat) : Verdict :=
  ((Grounding.evaluate S r g).verdicts[i]?).map (·.2) |>.getD (.unknown [.outOfRange])

private def verdictJson (v : Verdict) : Json :=
  Json.mkObj [("verdict", v.tag), ("unknown_reasons", reasons v.reasons)]

/-- The admission of divergence `k`: its trace and case text, the grounding of the rule's binders,
    the rule (expanded) among the library's rules, and the run's reading. -/
def record (rules : List Rule) (r : Rule) (ρ : Reading) (k : Nat) (traceText caseText : String)
    (grounding : List (String × TrackId)) : Json :=
  let traceRes := Decode.parse Decode.trace traceText
  let (caseErrs, caseOpt) := decodeCase caseText
  let τo := match traceRes with | .ok τ => some (TraceLint.completeOccupancy τ) | .error _ => none
  let lint := τo.map TraceLint.checkTrace
  let witness := match τo, caseOpt with
    | some τ, some c => some (TraceLint.checkWitness τ grounding c.entities c.at_)
    | _, _ => none
  let checked := caseOpt.map fun c => Case.check c (grounding.map (·.1))
  let m := Manifest.full "review"
  let setup := τo.map fun τ => Grounding.Setup.mk' rules (maskTrace m τ) ρ m.reidGap
  let caseValue : Option R := match setup, caseOpt, witness, checked with
    | some S, some c, some [], some [] => some (Case.eval S grounding c)
    | _, _, _, _ => none
  let ready : Option (Grounding.Setup × Grounding.Grounding × Nat) :=
    match setup, caseOpt, lint, caseValue with
    | some S, some c, some [], some v =>
      if v.v != .t then none
      else (S.scenes.findIdx? (·.t == c.at_)).map fun i =>
        (S, ⟨grounding.map fun (n, t) => (n, Grounding.canon S.cm t)⟩, i)
    | _, _, _, _ => none
  let ruleResult := ready.map fun (S, g, i) => verdictJson (verdictAt S r g i)
  let overrides := ready.map fun (S, g, i) =>
    let ids := ((Rule.closure rules r).flatMap fun x => x.formulas.flatMap Formula.aggregateIds).eraseDups
    Json.arr (ids.flatMap (fun id => S.tracks.flatMap fun t =>
      let original := match ρ.aggregate id, S.scenes[i]? with
        | some a, some s => triTag (Semantics.aggregateMembership s t a).v
        | _, _ => "unknown"
      [true, false].map fun b =>
        let S' := { S with d := { S.d with aggregateOverrides := [(t, id, b)] } }
        Json.mkObj [("aggregate_id", id), ("track", toJson t), ("original", original),
                    ("override", toJson b), ("rule_verdict", (verdictAt S' r g i).tag)])).toArray
  let orNull := fun (o : Option Json) => o.getD Json.null
  Json.mkObj
    [ ("schema", "certificate-run/1")
    , ("divergence", toJson k)
    , ("trace_decode_errors", strs (match traceRes with | .error e => [e] | .ok _ => []))
    , ("case_decode_errors", strs caseErrs)
    , ("canonical_case", orNull (caseOpt.map (·.formula.toJson)))
    , ("case_atoms", orNull (caseOpt.map fun c => strs (Formula.atoms c.formula).eraseDups))
    , ("lint_errors", orNull (lint.map strs))
    , ("witness_errors", orNull (witness.map strs))
    , ("case_check_errors", orNull (checked.map strs))
    , ("case_value", orNull (caseValue.map fun v => Json.mkObj [("value", triTag v.v), ("unknown_reasons", reasons v.why)]))
    , ("rule_result", orNull ruleResult)
    , ("sensitivity_overrides", orNull overrides) ]
end Certificate

end TrafficSpec
