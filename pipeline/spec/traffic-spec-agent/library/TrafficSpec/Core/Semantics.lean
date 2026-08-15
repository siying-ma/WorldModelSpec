/-
  TrafficSpec.Core.Semantics
  Finite-trace (LTLf) semantics for property formulas.

  `eval τ i φ = true` iff `φ` holds at position `i` of the finite trace `τ`.
  Ported from scene-flow-spec-lean (`SceneFlowSpec/Semantics.lean`).
-/
import TrafficSpec.Core.Formula

namespace TrafficSpec

open SFProp

/-- Evaluate an atomic predicate at position `i`. Out-of-trace positions are
    false (strong-next / LTLf convention). -/
def evalAtom (τ : Trace) (i : Nat) (p : AtomicPred) : Bool :=
  if i < τ.length then p.test (τ.getScene i) else false

----------------------------------------------------------------------
-- Temporal loops (structural recursion on `fuel`)
----------------------------------------------------------------------

/-- `eventually`: is there a `j ∈ [i, i+fuel)` with `f j = true`? -/
def loopEventually (f : Nat → Bool) (i : Nat) : Nat → Bool
  | 0        => false
  | fuel + 1 => f i || loopEventually f (i + 1) fuel

/-- `always`: does `f j = true` for every `j ∈ [i, i+fuel)`? -/
def loopAlways (f : Nat → Bool) (i : Nat) : Nat → Bool
  | 0        => true
  | fuel + 1 => f i && loopAlways f (i + 1) fuel

/-- `until`: is there a `j ∈ [i, i+fuel)` with `f₂ j`, and `f₁ k` for all
    `k ∈ [i, j)`? -/
def loopUntil (f₁ f₂ : Nat → Bool) (i : Nat) : Nat → Bool
  | 0        => false
  | fuel + 1 =>
    if f₂ i then true
    else if f₁ i then loopUntil f₁ f₂ (i + 1) fuel
    else false

/-- `release`: the dual of `until`. -/
def loopRelease (f₁ f₂ : Nat → Bool) (i : Nat) : Nat → Bool
  | 0        => true   -- vacuously true at the end of the trace
  | fuel + 1 =>
    if f₁ i && f₂ i then true
    else if f₂ i then loopRelease f₁ f₂ (i + 1) fuel
    else false

/-- bounded: `f` holds for `n` consecutive positions from `i`, with strong-next
    semantics — running off the end of the trace is false. Matches the
    SceneFlowLang desugaring of `$[n][φ]` into `φ ∧ Xφ ∧ … ∧ X^(n-1)φ`. -/
def loopBounded (f : Nat → Bool) (i : Nat) (len : Nat) : Nat → Bool
  | 0     => true
  | n + 1 =>
    if i < len then f i && loopBounded f (i + 1) len n
    else false

----------------------------------------------------------------------
-- Evaluator
----------------------------------------------------------------------

/-- Evaluate a formula at position `i` of `τ`. Structurally recursive on the
    formula; temporal operators delegate to the loops above with
    `fuel = τ.length - i`. -/
def eval (τ : Trace) (i : Nat) : SFProp → Bool
  | .top           => true
  | .bot           => false
  | .atom p        => evalAtom τ i p
  | .neg ψ         => !eval τ i ψ
  | .conj ψ₁ ψ₂    => eval τ i ψ₁ && eval τ i ψ₂
  | .disj ψ₁ ψ₂    => eval τ i ψ₁ || eval τ i ψ₂
  | .impl ψ₁ ψ₂    => !eval τ i ψ₁ || eval τ i ψ₂
  | .next ψ        => eval τ (i + 1) ψ
  | .until ψ₁ ψ₂   => loopUntil (eval τ · ψ₁) (eval τ · ψ₂) i (τ.length - i)
  | .release ψ₁ ψ₂ => loopRelease (eval τ · ψ₁) (eval τ · ψ₂) i (τ.length - i)
  | .eventually ψ  => loopEventually (eval τ · ψ) i (τ.length - i)
  | .always ψ      => loopAlways (eval τ · ψ) i (τ.length - i)
  | .bounded n ψ   => loopBounded (eval τ · ψ) i τ.length n

/-- A trace satisfies a formula when the formula holds at position 0. -/
def satisfies (τ : Trace) (φ : SFProp) : Bool := eval τ 0 φ

/-- `τ ⊨ φ` — the trace satisfies the formula. -/
scoped notation:50 τ " ⊨ " φ => satisfies τ φ = true

/-- `τ ⊭ φ` — the trace violates the formula. -/
scoped notation:50 τ " ⊭ " φ => satisfies τ φ = false

----------------------------------------------------------------------
-- Unfolding lemmas (kept so specs can be reasoned about later)
----------------------------------------------------------------------

@[simp] theorem eval_top (τ : Trace) (i : Nat) :
    eval τ i ⊤ₛ = true := rfl

@[simp] theorem eval_bot (τ : Trace) (i : Nat) :
    eval τ i ⊥ₛ = false := rfl

@[simp] theorem eval_neg (τ : Trace) (i : Nat) (φ : SFProp) :
    eval τ i (¬ₛ φ) = !eval τ i φ := rfl

@[simp] theorem eval_conj (τ : Trace) (i : Nat) (φ ψ : SFProp) :
    eval τ i (φ ⋀ ψ) = (eval τ i φ && eval τ i ψ) := rfl

@[simp] theorem eval_disj (τ : Trace) (i : Nat) (φ ψ : SFProp) :
    eval τ i (φ ⋁ ψ) = (eval τ i φ || eval τ i ψ) := rfl

@[simp] theorem eval_impl (τ : Trace) (i : Nat) (φ ψ : SFProp) :
    eval τ i (φ ⟹ ψ) = (!eval τ i φ || eval τ i ψ) := rfl

@[simp] theorem eval_next (τ : Trace) (i : Nat) (φ : SFProp) :
    eval τ i (◯ φ) = eval τ (i + 1) φ := rfl

@[simp] theorem eval_eventually_def (τ : Trace) (i : Nat) (φ : SFProp) :
    eval τ i (◇ φ) = loopEventually (eval τ · φ) i (τ.length - i) := rfl

@[simp] theorem eval_always_def (τ : Trace) (i : Nat) (φ : SFProp) :
    eval τ i (□ φ) = loopAlways (eval τ · φ) i (τ.length - i) := rfl

@[simp] theorem eval_bounded_def (τ : Trace) (i n : Nat) (φ : SFProp) :
    eval τ i (.bounded n φ) = loopBounded (eval τ · φ) i τ.length n := rfl

@[simp] theorem loopEventually_zero (f : Nat → Bool) (i : Nat) :
    loopEventually f i 0 = false := rfl

@[simp] theorem loopEventually_succ (f : Nat → Bool) (i fuel : Nat) :
    loopEventually f i (fuel + 1) = (f i || loopEventually f (i + 1) fuel) := rfl

@[simp] theorem loopAlways_zero (f : Nat → Bool) (i : Nat) :
    loopAlways f i 0 = true := rfl

@[simp] theorem loopAlways_succ (f : Nat → Bool) (i fuel : Nat) :
    loopAlways f i (fuel + 1) = (f i && loopAlways f (i + 1) fuel) := rfl

@[simp] theorem loopBounded_zero (f : Nat → Bool) (i len : Nat) :
    loopBounded f i len 0 = true := rfl

end TrafficSpec
