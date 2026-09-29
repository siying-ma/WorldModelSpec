/-
  TrafficSpec.Core.Evidence.Adequacy
  Mutation adequacy of a rule's witnesses: every leaf of the applicability and the obligation
  must do some work in some witness. A leaf is replaced by `tt` and by `ff` in turn; if neither
  replacement changes any scenario's episode verdict, the leaf is unexercised — the witnesses do
  not show that it matters, and a rule could carry an irrelevant atom without anyone noticing.

  A concept call is one leaf: the rule's witnesses must show the concept matters, and the
  concept's own witnesses exercise its body.

  Only the gate reads this file; rules never import it.
-/
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpec
namespace Adequacy

/-- The verdict tags a scenario list produces for a rule. -/
def profile (rules : List Rule) (r : Rule) (scs : List Scenario) (cs : List Concept := []) : List String :=
  scs.map fun sc =>
    match sc.run ((rules.filter (·.id != r.id)) ++ [r]) cs with
    | .ok v => v.tag
    | .error e => s!"error:{e}"

/-- Leaves of the applicability and the obligation (binder classes are exercised by the
    grounding itself) that neither `tt` nor `ff` replacement moves any witness on. -/
def unexercised (rules : List Rule) (r : Rule) (scs : List Scenario) (cs : List Concept := []) : List String :=
  let base := profile rules r scs cs
  let check (label : String) (get : Rule → Formula) (put : Rule → Formula → Rule) : List String :=
    let φ := get r
    (List.range (Formula.leafCount φ)).filterMap fun k =>
      let moved := [Formula.tt, Formula.ff].any fun rep =>
        profile rules (put r (Formula.replaceLeaf k rep φ)) scs cs != base
      if moved then none else some s!"{label} leaf {k}: {(Formula.leaves φ)[k]?.getD ""}"
  check "applicability" (·.applicability) (fun r φ => { r with applicability := φ }) ++
  check "obligation" (·.obligation) (fun r φ => { r with obligation := φ })

end Adequacy
end TrafficSpec
