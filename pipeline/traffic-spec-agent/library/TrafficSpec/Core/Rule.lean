/-
  TrafficSpec.Core.Rule
  What a specification is: binders with class formulas, an applicability and an obligation, and
  the declarations a reviewer needs (parameters, assumptions, operationalizations, residues, the
  rules it composes, the surrogate flag).

  Applicability and obligation are two formulas because a rule whose situation never arises is
  not compliant, it is not engaged: `notApplicable` is a verdict of its own, the witness check can
  demand a scenario for it, and the VLM stage reads the applicability as the trigger and the
  obligation as what to verify once triggered.

  A surrogate rule (the whole duty is an operationalized standard) is monitored like any other,
  but its verdicts are evidence about the standard, never the law's own verdict; the flag is what
  the monitor and the export propagate so the two are never summed.
-/
import TrafficSpec.Core.Semantics

namespace TrafficSpec

/-- A binder: a variable and the class formula (over `ru_*` atoms and class-level derived
    concepts) a track must satisfy to be bound to it. The subject comes first. -/
structure Binder where
  name : String
  cls : Formula
  deriving Repr, Inhabited

structure Rule where
  id : String                                   -- <theme>/<slug>
  laws : List String                            -- the corpus ids this rule formalizes
  binders : List Binder
  applicability : Formula
  obligation : Formula
  assumptions : List AsmId := []
  operationalizations : List Operationalization := []
  residues : List String := []                  -- what the text says and the rule does not capture
  surrogate : Bool := false
  deriving Repr, Inhabited

inductive Verdict
  | violated
  | compliant
  | notApplicable
  | unknown (why : List UnknownReason)
  deriving Repr, DecidableEq, Inhabited

namespace Verdict
def tag : Verdict → String
  | .violated => "violated"
  | .compliant => "compliant"
  | .notApplicable => "not_applicable"
  | .unknown _ => "unknown"
def reasons : Verdict → List UnknownReason
  | .unknown w => w
  | _ => []
instance : ToString Verdict := ⟨tag⟩
end Verdict

/-- Kleene combination of the two formulas: not engaged ↦ notApplicable, engaged and the
    obligation decided ↦ compliant/violated, anything undecided ↦ unknown with its reasons. -/
def verdictAt (app obl : R) : Verdict :=
  match app.v with
  | .f => .notApplicable
  | .u => .unknown app.why
  | .t =>
    match obl.v with
    | .t => .compliant
    | .f => .violated
    | .u => .unknown obl.why

theorem verdictAt_notApplicable (app obl : R) (h : app.v = .f) : verdictAt app obl = .notApplicable := by
  unfold verdictAt; rw [h]
theorem verdictAt_violated (app obl : R) (ha : app.v = .t) (ho : obl.v = .f) : verdictAt app obl = .violated := by
  unfold verdictAt; rw [ha, ho]
theorem verdictAt_compliant (app obl : R) (ha : app.v = .t) (ho : obl.v = .t) : verdictAt app obl = .compliant := by
  unfold verdictAt; rw [ha, ho]

namespace Rule
open Semantics

/-- The formulas a rule consists of, class formulas first. -/
def formulas (r : Rule) : List Formula := r.binders.map (·.cls) ++ [r.applicability, r.obligation]
/-- Atom and derived-concept names the rule reads. -/
def atoms (r : Rule) : List String := (r.formulas.flatMap Formula.atoms).eraseDups
/-- Reading parameters the rule names. -/
def params (r : Rule) : List ParamName := (r.formulas.flatMap Formula.params).eraseDups
/-- Rules the rule composes. -/
def composes (r : Rule) : List String := (r.formulas.flatMap Formula.composed).eraseDups
/-- Assumptions the formulas read. -/
def usedAssumptions (r : Rule) : List AsmId := (r.formulas.flatMap Formula.assumptions).eraseDups
def binderNames (r : Rule) : List String := r.binders.map (·.name)
def subject (r : Rule) : Option String := r.binders.head?.map (·.name)

/-- Every binder's class holds for its bound track and the applicability holds. -/
def engaged (r : Rule) (c : SemCtx) (i : Nat) : R :=
  R.and (R.all (r.binders.map fun b => eval c i b.cls)) (eval c i r.applicability)

def verdict (r : Rule) (c : SemCtx) (i : Nat) : Verdict :=
  verdictAt (r.engaged c i) (eval c i r.obligation)

/-- The rule as a three-valued statement: complied with (true), violated (false), or unknown.
    Not engaged counts as complied with — a rule that does not apply is not broken. -/
def asR (r : Rule) (c : SemCtx) (i : Nat) : R :=
  match r.verdict c i with
  | .compliant | .notApplicable => R.t
  | .violated => R.f
  | .unknown w => ⟨.u, w⟩

/-- Structural well-formedness the gate checks before any trace: binders named, distinct, the
    subject first; every variable the formulas use is a binder or bound by a quantifier is the
    gate's job over the AST; every parameter and assumption used is declared where it must be. -/
def wellFormed (r : Rule) : Bool :=
  !r.binders.isEmpty &&
  r.binderNames.eraseDups.length == r.binders.length &&
  r.binders.all (fun b => !b.name.isEmpty) &&
  !r.id.isEmpty &&
  r.usedAssumptions.all (r.assumptions.contains ·) &&
  r.operationalizations.all (fun o => Derived.derivedNames.contains (defName o.concept))

end Rule

/-- Rule composition over a library, with fuel bounding the nesting depth. The composed rule's
    binders are bound through `map` (inner binder ↦ caller variable); an unmapped binder is an
    unbound variable, an unknown id is `compositionUnknown`. -/
def composeWith (rules : List Rule) (τ : Trace) (ρ : Reading) :
    Nat → String → List (String × String) → Binding → Nat → R
  | 0, id, _, _, _ => R.u (.compositionUnknown id)
  | fuel + 1, id, map, β, i =>
    match rules.find? (·.id == id) with
    | none => R.u (.compositionUnknown id)
    | some r =>
      let β' : Binding := ⟨map.filterMap fun (inner, outer) => (β.lookup outer).map fun v => (inner, v)⟩
      r.asR { τ := τ, ρ := ρ, β := β', compose := composeWith rules τ ρ fuel } i

/-- The evaluation context for a rule set over a trace: composition resolves against `rules`,
    nested at most `rules.length` deep. -/
def Rule.context (rules : List Rule) (τ : Trace) (ρ : Reading) (β : Binding) : Semantics.SemCtx :=
  { τ := τ, ρ := ρ, β := β, compose := composeWith rules τ ρ rules.length }

end TrafficSpec
