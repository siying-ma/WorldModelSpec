/-
  TrafficSpec.Core.Formula
  Formula AST for traffic-law properties over scene traces.

  Ported from scene-flow-spec-lean (`SceneFlowSpec/Formula.lean`):
  a finite-trace LTL with a bounded operator.
-/
import TrafficSpec.Core.Scene

namespace TrafficSpec

/-- An atomic predicate is a decidable Boolean test on a single scene snapshot,
    together with a human-readable label. -/
structure AtomicPred where
  label : String
  test  : Scene → Bool
  deriving Inhabited

instance : BEq AtomicPred where
  beq a b := a.label == b.label   -- identity by label

instance : Repr AtomicPred where
  reprPrec a _ := Std.Format.text s!"⟨{a.label}⟩"

/-- Property formulas — finite-trace LTL with bounded operators.

  `X` (next), `U` (until), `R` (release), `F` (eventually),
  `G` (always), and the bounded `$[n][φ]` operator.
-/
inductive SFProp where
  | atom       : AtomicPred → SFProp
  | top        : SFProp
  | bot        : SFProp
  | neg        : SFProp → SFProp
  | conj       : SFProp → SFProp → SFProp
  | disj       : SFProp → SFProp → SFProp
  | impl       : SFProp → SFProp → SFProp
  | next       : SFProp → SFProp
  | until      : SFProp → SFProp → SFProp
  | release    : SFProp → SFProp → SFProp
  | eventually : SFProp → SFProp
  | always     : SFProp → SFProp
  | bounded    : Nat → SFProp → SFProp
  deriving Inhabited

----------------------------------------------------------------------
-- Notation
----------------------------------------------------------------------

namespace SFProp

scoped notation "⊤ₛ" => SFProp.top
scoped notation "⊥ₛ" => SFProp.bot
scoped prefix:90 "¬ₛ"  => SFProp.neg
scoped infixl:65 " ⋀ " => SFProp.conj
scoped infixl:60 " ⋁ " => SFProp.disj
scoped infixr:55 " ⟹ " => SFProp.impl
scoped prefix:90 "◯"   => SFProp.next
scoped infixl:50 " 𝒰 " => SFProp.until
scoped infixl:50 " ℛ " => SFProp.release
scoped prefix:90 "◇"   => SFProp.eventually
scoped prefix:90 "□"   => SFProp.always

end SFProp

/-- How many frames, counting the evaluation position itself, the formula must
    be able to look at before its bounded operators can complete.

    **This is a soundness precondition, not a diagnostic.** `Semantics.loopBounded`
    returns `false` when a window overruns the end of the trace, and the common
    safety shape in this library is `□ (¬ₛ .bounded n bad)` — so on a trace
    shorter than `n`, `.bounded n bad` is false everywhere, `¬ₛ` makes it true
    everywhere, and the rule reports **compliant no matter what the trace
    contains**. Measured against `Rules/Lane/R0011` (window 80) on a trace of
    flagrant, every-frame violation:

        frames = 80 → check = false   (violation reported)
        frames = 79 → check = true    (compliant, same content)

    The grounding count stays ≥ 1 throughout, so the vacuity guard does not
    catch it. A trace shorter than `frameSpan` cannot be used to clear a rule;
    `Grounding.report` publishes this number so the Python side can refuse.

    `always` / `eventually` / `until` / `release` do not add to the span: they
    are already clamped to the end of the trace by their fuel, so they degrade
    gracefully rather than silently inverting. -/
def SFProp.frameSpan : SFProp → Nat
  | .atom _        => 1
  | .top           => 0
  | .bot           => 0
  | .neg ψ         => ψ.frameSpan
  | .conj ψ₁ ψ₂    => max ψ₁.frameSpan ψ₂.frameSpan
  | .disj ψ₁ ψ₂    => max ψ₁.frameSpan ψ₂.frameSpan
  | .impl ψ₁ ψ₂    => max ψ₁.frameSpan ψ₂.frameSpan
  | .next ψ        => 1 + ψ.frameSpan
  | .until ψ₁ ψ₂   => max ψ₁.frameSpan ψ₂.frameSpan
  | .release ψ₁ ψ₂ => max ψ₁.frameSpan ψ₂.frameSpan
  | .eventually ψ  => ψ.frameSpan
  | .always ψ      => ψ.frameSpan
  | .bounded n ψ   => match n with
                      | 0      => 0
                      | k + 1  => k + ψ.frameSpan

/-- Build an atomic predicate formula from a label and a scene test. -/
def mkAtom (label : String) (test : Scene → Bool) : SFProp :=
  .atom ⟨label, test⟩

end TrafficSpec
