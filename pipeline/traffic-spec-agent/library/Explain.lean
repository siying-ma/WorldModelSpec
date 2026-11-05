/-
  explain — why a rule has its verdict at an observation of a trace, and the values its
  comparisons take there.

    explain --manifest <m.json> --reading <r.json> --rule <id> [--bind name=track ...]
            (--at <t ms> [--values] | --scan [--from <ms> --to <ms>] [--max <k>] [--max-groundings <n>])
            [--json] <trace.json>

  Execution is the monitor's: the whole trace is admitted (identities joined, the manifest's absent
  atoms masked), the rule is registered with every rule it composes (`Rule.closure`), concepts are
  expanded, the support is the monitor's (an unsupported rule is evaluated by nobody: it is reported
  and nothing is explained), the groundings are the monitor's (`Grounding.check`), and the verdict at
  an observation is the monitor's timeline verdict, with its reasons.

  At an observation, the binder classes and the applicability are walked, then the obligation: a
  conjunction descends into the conjuncts that carry its value, a disjunction into its disjuncts, an
  implication into its consequent, a quantifier into the members that carry its value (with their
  binding), a comparison prints both sides (exact rationals in JSON) and the parameters it reads.
  This tree is a diagnosis: a true conjunction or implication is not opened, and members, depth and
  lines are bounded; every bound that cuts something is reported as `truncated`.

  A temporal operator reports the observations it reads and how the Core decides it there, branch
  for branch: a missing position, a window past the trace (truncated), a sampling gap, or the
  observation that decides it (the first failure of a window behind, the latest guard of `atLast` —
  or a later unknown guard, the first success ahead, the latest right operand of `since` or where a
  failure or unknown enters, the previous observation of a rise), or the interval that jointly
  supports it. Where an observation decides it, the operand is walked there.

  `--values` (with `--at`) lists every comparison of the rule at the observation, unpruned: through
  every connective, every member of every quantifier, and the operands of temporal operators at the
  observation itself, each with a path, both sides exact, and its value. It is the interface for
  quantities a check reads; a cut is reported as `truncated`.

  `--scan` chooses the observations (at most `--max`, default 3) on the whole trace, or, with
  `--from <ms> --to <ms>`, among the observations of that closed interval only (a label's scoring
  interval; the trace is still evaluated whole, a violated run entering the interval is chosen at
  its first observation inside):
  - violated somewhere: the first observation of each violated interval;
  - else engaged somewhere: the first unknown observation, and, for each comparison of the obligation
    outside quantifiers and temporal operators, the engaged compliant observation at which it is
    relatively closest to its boundary; the comparisons not searched are counted;
  - else never engaged: the observation at which the most binder classes and applicability
    conjuncts hold (a heuristic, not a distance).
  Without `--bind`, every grounding of the monitor is explained (at most `--max-groundings`, every
  one by default; a cut is reported).
-/
import TrafficSpec
import TrafficSpec.Core.Runtime.Decode

open TrafficSpec
open TrafficSpec.Semantics
open TrafficSpec.Grounding

namespace Explain

def maxLines : Nat := 160
def maxDepth : Nat := 16
def maxMembers : Nat := 3
def maxValues : Nat := 5000

-- ---------------------------------------------------------------------------------------------
-- Numbers and names
-- ---------------------------------------------------------------------------------------------

def qStr (q : Q) : String :=
  let n := q.num.natAbs
  let scaled := (n * 1000 + q.den / 2) / q.den
  let fs := toString (scaled % 1000)
  let fs := "".pushn '0' (3 - fs.length) ++ fs
  (if q.num < 0 && scaled != 0 then "-" else "") ++ toString (scaled / 1000) ++ "." ++ fs

/-- A rational in lowest terms. -/
def qNorm (q : Q) : Int × Nat :=
  let g := Nat.gcd q.num.natAbs q.den
  let g := if g == 0 then 1 else g
  (q.num / (Int.ofNat g), q.den / g)

def qFloat (q : Q) : Float := Float.ofInt q.num / Float.ofNat q.den

def triStr : Tri → String | .t => "true" | .f => "false" | .u => "unknown"

def reasonTags (r : R) : List String := (r.why.map UnknownReason.tag).eraseDups.take 4

def rStr (r : R) : String :=
  match r.v with
  | .u => "unknown (" ++ ", ".intercalate (reasonTags r) ++ ")"
  | v => triStr v

def qrStr : QR → String
  | .ok q => qStr q
  | .error w => s!"unknown ({w.tag})"

def valStr : Val → String
  | .track t => s!"track {t}" | .region r => s!"region {r}" | .device d => s!"device {d}"

def argStr (β : Binding) : Arg → String
  | .var n => match β.lookup n with | some v => s!"{n}={valStr v}" | none => n
  | .lit s => s!"\"{s}\""
  | .nat n => toString n

def cut (s : String) (n : Nat := 140) : String := if s.length ≤ n then s else (s.take n).toString ++ "…"

def opStr : CmpOp → String | .lt => "<" | .le => "≤" | .eq => "=" | .ge => "≥" | .gt => ">"

mutual
  partial def termStr (β : Binding) : Term → String
    | .lit q _ => qStr q
    | .param p => p
    | .measure a args => s!"{a}({", ".intercalate (args.map (argStr β))})"
    | .quantity c args _ => s!"{c}({", ".intercalate (args.map (argStr β))})"
    | .distanceWhile s _ => s!"distance travelled by {s} while …"
    | .sinceRise _ => "time since …"
    | .aggregate op v _ t => s!"{op} over road users {v} of {termStr β t}"
    | .add a b => s!"({termStr β a} + {termStr β b})"
    | .sub a b => s!"({termStr β a} - {termStr β b})"
    | .mul a b => s!"{termStr β a}·{termStr β b}"
    | .div a b => s!"{termStr β a}/{termStr β b}"
    | .neg a => s!"-{termStr β a}"
    | .abs a => s!"|{termStr β a}|"
    | .cond φ a b => s!"(if {headStr β φ} then {termStr β a} else {termStr β b})"

  partial def headStr (β : Binding) : Formula → String
    | .tt => "true" | .ff => "false"
    | .atom n args _ => s!"{n}({", ".intercalate (args.map (argStr β))})"
    | .cmp l op r => s!"{termStr β l} {opStr op} {termStr β r}"
    | .asm id => s!"assumption {id}"
    | .intent id a b => s!"intention {id} of {argStr β a} at {argStr β b}"
    | .same a b => s!"{argStr β a} is {argStr β b}"
    | .not _ => "not" | .and _ _ => "and" | .or _ _ => "or" | .implies _ _ => "implies"
    | .always _ => "always (from here on)" | .eventually _ => "eventually (here or later)"
    | .until _ _ => "until" | .since _ _ => "since (looking back)"
    | .holdsFor _ _ s _ => s!"throughout the window behind ({s})" | .within _ _ s _ => s!"within the window ahead ({s})"
    | .untilWithin _ _ s _ _ => s!"until, within the window ahead ({s})" | .atLast _ _ s _ _ => s!"at the last time, in the window behind ({s})"
    | .count _ _ op k => s!"count of rising edges {opStr op} {k}"
    | .rises _ => "becomes true here (was not at the previous observation)"
    | .definedWhen _ _ => "defined when"
    | .derived c args _ => s!"{c}({", ".intercalate (args.map (argStr β))})"
    | .rule id _ => s!"rule {id} complied with" | .ruleApplies id _ => s!"rule {id} applies"
    | .existsUser v _ => s!"some road user {v}" | .forallUser v _ => s!"every road user {v}"
    | .existsRegion k v _ => s!"some region {v} of kind {argStr β k}" | .forallRegion k v _ => s!"every region {v} of kind {argStr β k}"
    | .existsDevice k v _ => s!"some device {v} of kind {argStr β k}" | .forallDevice k v _ => s!"every device {v} of kind {argStr β k}"
end

-- ---------------------------------------------------------------------------------------------
-- Evaluation, each sub-formula once per binding (the monitor's evaluator, memoized)
-- ---------------------------------------------------------------------------------------------

abbrev EM := StateM (Std.HashMap String (Array R))

def bindingKey (β : Binding) : String := ";".intercalate (β.binds.map fun (n, v) => s!"{n}={valStr v}")

def allAt (c : SemCtx) (φ : Formula) : EM (Array R) := do
  let k := bindingKey c.β ++ "|" ++ reprStr φ
  match (← get)[k]? with
  | some a => pure a
  | none =>
    let a := Rule.evalRuleFormula c φ
    modify (·.insert k a)
    pure a

def valAt (c : SemCtx) (i : Nat) (φ : Formula) : EM R := do
  pure ((← allAt c φ)[i]?.getD (R.u .outOfRange))

def tAt (c : SemCtx) (j : Nat) : Int := (c.scenes[j]?.map (·.t)).getD 0

def termAt (c : SemCtx) (i : Nat) (t : Term) : QR := (evalTAll c t)[i]?.getD (.error .outOfRange)

/-- A quantity with every selection resolved where its guard is decided at `i`, and both ways where
    it is unknown: the values the quantity can take, as the evaluator decides a comparison by cases. -/
partial def variants (c : SemCtx) (i : Nat) : Term → EM (List Term)
  | .cond φ a b => do
    match (← valAt c i φ).v with
    | .t => variants c i a
    | .f => variants c i b
    | .u => pure (((← variants c i a) ++ (← variants c i b)).take 8)
  | .add a b => two .add a b | .sub a b => two .sub a b | .mul a b => two .mul a b | .div a b => two .div a b
  | .neg a => do pure ((← variants c i a).map .neg)
  | .abs a => do pure ((← variants c i a).map .abs)
  | t => pure [t]
where
  two (k : Term → Term → Term) (a b : Term) : EM (List Term) := do
    let xs ← variants c i a
    let ys ← variants c i b
    pure ((xs.flatMap fun x => ys.map fun y => k x y).take 8)

partial def params : Term → List String
  | .param p => [p]
  | .quantity _ _ ps => ps.flatMap params
  | .aggregate _ _ _ t | .neg t | .abs t => params t
  | .add a b | .sub a b | .mul a b | .div a b | .cond _ a b => params a ++ params b
  | _ => []

/-- A side of a comparison at `i`: its value, exact where decided, and the values by case where a
    selection's guard is unknown. -/
structure Side where
  term : String
  value : Option Q
  unknown : Option String := none
  cases : List QR := []

def side (c : SemCtx) (i : Nat) (t : Term) : EM Side := do
  match termAt c i t with
  | .ok q => pure { term := cut (termStr c.β t) 160, value := some q }
  | .error w =>
    let vs := (← variants c i t).map (termAt c i)
    pure { term := cut (termStr c.β t) 160, value := none, unknown := some w.tag, cases := if vs.length ≤ 1 then [] else vs }

def sideStr (s : Side) : String :=
  match s.value, s.unknown with
  | some q, _ => qStr q
  | none, some w => if s.cases.isEmpty then s!"unknown ({w})"
                    else s!"{" or ".intercalate (s.cases.map qrStr).eraseDups} (by case: a selection's guard is unknown here, {w})"
  | none, none => "unknown"

partial def conj : Formula → List Formula | .and a b => conj a ++ conj b | φ => [φ]
partial def disj : Formula → List Formula | .or a b => disj a ++ disj b | φ => [φ]

/-- The members of a quantifier present at observation `i`: (binding value, value of the member's clause). -/
def members (c : SemCtx) (i : Nat) (φ : Formula) : EM (Option (String × List (Val × R))) := do
  match φ with
  | .existsUser v b | .forallUser v b =>
      let ts := (usersOf c).filter fun t => c.scenes[i]!.tracks.contains t
      pure (some (v, ← ts.mapM fun t => do pure (Val.track t, ← valAt (c.bindVar v (.track t)) i b)))
  | .existsRegion (.lit k) v b | .forallRegion (.lit k) v b =>
      match StructureKind.ofString k with
      | none => pure none
      | some kd =>
        let isE := match φ with | .existsRegion .. => true | _ => false
        let rs := (regionsOf c kd).filter fun r => (c.scenes[i]!.structure? r).isSome
        pure (some (v, ← rs.mapM fun r => do
          let kind := (regionIsKind c r kd)[i]!
          let body ← valAt (c.bindVar v (.region r)) i b
          pure (Val.region r, if isE then R.and kind body else R.implies kind body)))
  | .existsDevice (.lit k) v b | .forallDevice (.lit k) v b =>
      match DeviceKind.ofString k with
      | none => pure none
      | some kd =>
        let isE := match φ with | .existsDevice .. => true | _ => false
        let ds := (devicesOf c kd).filter fun d => (c.scenes[i]!.device d).isSome
        pure (some (v, ← ds.mapM fun d => do
          let kind := (deviceIsKind c d kd)[i]!
          let body ← valAt (c.bindVar v (.device d)) i b
          pure (Val.device d, if isE then R.and kind body else R.implies kind body)))
  | _ => pure none

def body : Formula → Option Formula
  | .existsUser _ b | .forallUser _ b | .existsRegion _ _ b | .forallRegion _ _ b
  | .existsDevice _ _ b | .forallDevice _ _ b => some b
  | _ => none

-- ---------------------------------------------------------------------------------------------
-- Temporal operators: how the Core decides them at an observation
-- ---------------------------------------------------------------------------------------------

/-- What a temporal operator reads at the observation and how the Core decides it there. -/
structure Win where
  op : String
  measure : String := ""                -- "time" or "path" for a metric window
  subject : String := ""
  length : Option Q := none             -- seconds or metres
  fromMs : Option Int := none
  toMs : Option Int := none
  covered : Option Bool := none
  adequate : Option Bool := none
  decidedAtMs : Option Int := none      -- the observation that decides the value
  supportFromMs : Option Int := none    -- an interval that jointly decides it
  supportToMs : Option Int := none
  how : String := ""

def firstIn (a b : Nat) (p : Nat → Bool) : Option Nat :=
  (List.range (b + 1 - a)).map (· + a) |>.find? p

def metricBase (op : String) (m : Measure) (s : String) (dv : Q) : Win :=
  { op, measure := match m with | .time => "time" | .path => "path", subject := s, length := some dv }

/-- The window of a temporal operator at `i`, decided branch for branch as the Core decides it,
    and the observation at which its operands are to be walked. -/
def winOf (c : SemCtx) (i : Nat) (φ : Formula) : EM (Option (Win × Option Nat)) := do
  let v := (← valAt c i φ).v
  let metric (op : String) (m : Measure) (d : Term) (s : String)
      (k : Win → Array (Option Q) → Q → EM (Win × Option Nat)) : EM (Option (Win × Option Nat)) := do
    match subjectFor c.β m s, termAt c i d with
    | .ok x, .ok dv => some <$> k (metricBase op m s dv) (Primitives.positions c.d m x) dv
    | .error w, _ => pure (some ({ op, how := s!"the window's subject is unknown ({w.tag})" }, none))
    | _, .error w => pure (some ({ op, how := s!"the window's length is unknown ({w.tag})" }, none))
  match φ with
  | .holdsFor m d s a => metric "holdsFor" m d s fun b pos dv => do
    let A ← allAt c a
    match (Time.backWindows pos dv)[i]? with
    | some (some w) =>
      let b := { b with fromMs := tAt c w.j0, toMs := tAt c i, covered := w.covered, adequate := w.adequate }
      if !w.covered then
        if v == .f then
          let j := (firstIn w.j0 i fun j => A[j]!.v == .f).getD i
          pure ({ b with decidedAtMs := tAt c j, how := "the operand fails here, inside the window, which reaches before the trace start" }, some j)
        else pure ({ b with how := "the window reaches before the trace start, and the operand fails nowhere in it: truncated" }, none)
      else if !w.adequate then pure ({ b with how := "observations in the window are more than half its length apart: sampling gap" }, none)
      else match v with
        | .f => let j := (firstIn w.j0 i fun j => A[j]!.v == .f).getD i
                pure ({ b with decidedAtMs := tAt c j, how := "the operand fails here" }, some j)
        | .u => let j := (firstIn w.j0 i fun j => A[j]!.v == .u).getD i
                pure ({ b with decidedAtMs := tAt c j, how := "the operand is unknown here, and fails nowhere in the window" }, some j)
        | .t => pure ({ b with supportFromMs := tAt c w.j0, supportToMs := tAt c i, how := "the operand holds at every observation of the window" }, none)
    | _ => pure ({ b with how := "a position in the window is missing" }, none)
  | .atLast m d s ψ _ => metric "atLast" m d s fun b pos dv => do
    let P ← allAt c ψ
    match (Time.backWindows pos dv)[i]? with
    | some (some w) =>
      let b := { b with fromMs := tAt c w.j0, toMs := tAt c i, covered := w.covered, adequate := w.adequate }
      -- the Core's search: from the observation back to the window's start, the first guard not false
      let hit := (firstIn 0 (i - w.j0) fun k => P[i - k]!.v != .f).map (i - ·)
      match hit with
      | some j =>
        if !w.adequate then pure ({ b with how := "observations in the window are more than half its length apart: sampling gap (a later unobserved instant could hold the guard)" }, none)
        else if P[j]!.v == .t then
          pure ({ b with decidedAtMs := tAt c j, how := "the latest observation in the window where the guard holds: the value is the body's there" }, some j)
        else
          pure ({ b with decidedAtMs := tAt c j, how := "the guard is unknown here, later than any observation where it holds: unknown" }, some j)
      | none =>
        if !w.covered then pure ({ b with how := "the guard holds nowhere in the observed window, which reaches before the trace start: truncated" }, none)
        else if !w.adequate then pure ({ b with how := "observations in the window are more than half its length apart: sampling gap" }, none)
        else pure ({ b with supportFromMs := tAt c w.j0, supportToMs := tAt c i, how := "the guard holds nowhere in the window: false" }, none)
    | _ => pure ({ b with how := "a position in the window is missing" }, none)
  | .within m d s a => metric "within" m d s fun b pos dv => do
    let A ← allAt c a
    match (Time.forwardWindows pos dv)[i]? with
    | some (some w) =>
      let b := { b with fromMs := tAt c i, toMs := tAt c w.jl, covered := w.covered, adequate := w.adequate }
      if !w.adequate then pure ({ b with how := "observations in the window are more than half its length apart: sampling gap" }, none)
      else match firstIn i w.jl (fun j => A[j]!.v == .t) with
        | some j => pure ({ b with decidedAtMs := tAt c j, how := "the operand holds here" }, some j)
        | none =>
          match firstIn i w.jl (fun j => A[j]!.v == .u) with
          | some j => pure ({ b with decidedAtMs := tAt c j, how := s!"the operand holds nowhere in the window and is unknown here{if w.covered then "" else "; the window runs past the trace end"}" }, some j)
          | none =>
            if w.covered then pure ({ b with supportFromMs := tAt c i, supportToMs := tAt c w.jl, how := "the operand fails at every observation of the window" }, none)
            else pure ({ b with how := "the operand holds nowhere in the observed window, which runs past the trace end: truncated" }, none)
    | _ => pure ({ b with how := "a position in the window is missing" }, none)
  | .untilWithin m d s a g => metric "untilWithin" m d s fun b pos dv => do
    let A ← allAt c a
    let G ← allAt c g
    match (Time.forwardWindows pos dv)[i]? with
    | some (some w) =>
      let b := { b with fromMs := tAt c i, toMs := tAt c w.jl, covered := w.covered, adequate := w.adequate }
      if !w.adequate then pure ({ b with how := "observations in the window are more than half its length apart: sampling gap" }, none)
      else
        let n := A.size
        let goal := (firstIn i (n - 1) fun j => G[j]!.v == .t).getD n
        let before := (List.range (goal - i)).all fun k => A[i + k]!.v == .t
        if goal ≤ w.jl && before then
          pure ({ b with decidedAtMs := tAt c goal, how := "the goal holds here, and the operand at every observation before it" }, some goal)
        else
          let aFail := (firstIn i (n - 1) fun j => A[j]!.v == .f).getD n
          let hi := min aFail w.jl
          match firstIn i hi (fun j => G[j]!.v == .u) with
          | some j => pure ({ b with decidedAtMs := tAt c j, how := "the goal is unknown here, before the operand fails or the window ends" }, some j)
          | none =>
            if v == .f then
              if aFail ≤ w.jl then pure ({ b with decidedAtMs := tAt c aFail, how := "the operand fails here, before any goal" }, some aFail)
              else pure ({ b with supportFromMs := tAt c i, supportToMs := tAt c w.jl, how := "the goal holds nowhere in the window" }, none)
            else pure ({ b with how := s!"no observation of the window decides it{if w.covered then "" else ": the window runs past the trace end"}" }, none)
    | _ => pure ({ b with how := "a position in the window is missing" }, none)
  | .since a b =>
    -- the Core's recursion r(k) = ψ(k) ∨ (φ(k) ∧ r(k-1)), r(-1) truncated: walked back from `i`
    let A ← allAt c a
    let B ← allAt c b
    let pick : Option (Nat × String) := match v with
      | .t => (firstIn 0 i fun k => B[i - k]!.v == .t).map fun k => (i - k, "the right operand holds here, and the left one at every observation since")
      | .f => (firstIn 0 i fun k => A[i - k]!.v == .f).map fun k => (i - k, "the left operand fails here, and the right one holds nowhere since")
      | .u => (firstIn 0 i fun k => B[i - k]!.v == .u || A[i - k]!.v == .u).map fun k =>
                (i - k, s!"an operand is unknown here (left {triStr A[i - k]!.v}, right {triStr B[i - k]!.v})")
    match pick with
    | some (j, how) => pure (some ({ op := "since", fromMs := tAt c j, toMs := tAt c i, decidedAtMs := tAt c j, how }, some j))
    | none => pure (some ({ op := "since", fromMs := tAt c 0, toMs := tAt c i,
                            how := "the search reaches the trace start without deciding: truncated" }, none))
  | .rises a =>
    let A ← allAt c a
    if A[i]!.v == .f then pure (some ({ op := "rises", toMs := tAt c i, decidedAtMs := tAt c i, how := "the operand is false here" }, some i))
    else if i = 0 then pure (some ({ op := "rises", toMs := tAt c i, how := "first observation: the previous value is unknown (truncated)" }, none))
    else pure (some ({ op := "rises", fromMs := tAt c (i - 1), toMs := tAt c i, decidedAtMs := tAt c (i - 1),
                       how := s!"the operand here: {triStr A[i]!.v}; at the previous observation: {triStr A[i - 1]!.v}" }, some (i - 1)))
  | _ => pure none

-- ---------------------------------------------------------------------------------------------
-- The explanation tree
-- ---------------------------------------------------------------------------------------------

structure Cmp where
  lhs : Side
  op : String
  rhs : Side
  params : List (String × Option Q)

inductive Item where
  | node (value : R) (head : String) (cmp : Option Cmp) (win : Option Win) (note : Option String)
         (truncated : List String) (children : List Item)
  | member (var : String) (is : String) (body : Item)
  | other (value : R) (head : String) (role : String)

instance : Inhabited Item := ⟨.other default "" ""⟩

def Item.value : Item → Option R
  | .node v .. => some v
  | .member _ _ b => b.value
  | .other v .. => some v

/-- The tree that explains `φ`'s value at observation `i`. -/
partial def build (c : SemCtx) (i : Nat) (φ : Formula) (d : Nat) : EM Item := do
  let v ← valAt c i φ
  let cmp ← match φ with
    | .cmp l op r => do
      pure (some { lhs := ← side c i l, op := opStr op, rhs := ← side c i r,
                   params := (params l ++ params r).eraseDups.map fun p => (p, c.d.ρ.param p) })
    | _ => pure none
  let w ← winOf c i φ
  let head := cut (headStr c.β φ)
  if d ≥ maxDepth then return .node v head cmp (w.map (·.1)) none ["depth"] []
  let into (ψs : List Formula) (pick : R → Bool) : EM (List Item) := do
    let vals ← ψs.mapM fun ψ => do pure (ψ, ← valAt c i ψ)
    let shown ← (vals.filter (fun (_, r) => pick r)).mapM fun (ψ, _) => build c i ψ (d + 1)
    pure (shown ++ (vals.filter (fun (_, r) => !pick r)).map fun (ψ, r) => .other r (cut (headStr c.β ψ) 100) "")
  let same (r : R) := r.v == v.v
  -- the operands of a temporal operator, walked where its decision is made
  let atI := (w.bind (·.2)).getD i
  let atNote := if atI == i then "(the operator also reads other observations; the operand here:)"
                else s!"(the operand at the deciding observation t={tAt c atI} ms:)"
  match φ with
  | .and .. =>
    let ch ← if v.v == .t then pure [] else into (conj φ) same
    return .node v head cmp none none [] ch
  | .or .. =>
    let ch ← into (disj φ) same
    return .node v head cmp none none (if v.v == .t && ch.length > 40 then ["disjuncts"] else []) (if v.v == .t then ch.take 40 else ch)
  | .implies a b =>
    if v.v == .t then return .node v head cmp none none [] []
    return .node v head cmp none none [] [.other (← valAt c i a) (cut (headStr c.β a)) "condition", ← build c i b (d + 1)]
  | .not a => return .node v head cmp none none [] [← build c i a (d + 1)]
  | .existsUser .. | .forallUser .. | .existsRegion .. | .forallRegion .. | .existsDevice .. | .forallDevice .. =>
    match ← members c i φ, body φ with
    | some (var, ms), some b =>
      let carry := ms.filter fun (_, r) => r.v == v.v
      let ch ← (carry.take maxMembers).mapM fun (x, _) => do pure (.member var (valStr x) (← build (c.bindVar var x) i b (d + 2)))
      return .node v head cmp none (some s!"{ms.length} member(s) present, {carry.length} {triStr v.v}")
        (if carry.length > maxMembers then [s!"members: {maxMembers} of {carry.length} shown"] else []) ch
    | _, _ => return .node v head cmp none none [] []
  | .since a b => return .node v head cmp (w.map (·.1)) (some atNote) [] [← build c atI b (d + 1), ← build c atI a (d + 1)]
  | .until a b => return .node v head cmp none none [] [← build c i b (d + 1), ← build c i a (d + 1)]
  | .rises a | .holdsFor _ _ _ a | .within _ _ _ a => return .node v head cmp (w.map (·.1)) (some atNote) [] [← build c atI a (d + 1)]
  | .always a | .eventually a => return .node v head cmp none (some "(the operator also reads other observations; the operand here:)") [] [← build c i a (d + 1)]
  | .atLast _ _ _ g a | .untilWithin _ _ _ a g => return .node v head cmp (w.map (·.1)) (some atNote) [] [← build c atI g (d + 1), ← build c atI a (d + 1)]
  | .definedWhen a b => return .node v head cmp none none [] [← build c i a (d + 1), ← build c i b (d + 1)]
  | _ => return .node v head cmp (w.map (·.1)) none [] []

-- ---------------------------------------------------------------------------------------------
-- Every comparison, unpruned (`--values`)
-- ---------------------------------------------------------------------------------------------

structure Value where
  path : String
  binding : String
  cmp : Cmp
  value : R

/-- Every comparison under `φ` at `i`: through every connective, every member of every quantifier,
    and the operands of temporal operators at `i` itself. -/
partial def values (c : SemCtx) (i : Nat) (φ : Formula) (path : String) : EM (List Value) := do
  match φ with
  | .cmp l op r =>
    pure [{ path, binding := bindingKey c.β, value := ← valAt c i φ,
            cmp := { lhs := ← side c i l, op := opStr op, rhs := ← side c i r,
                     params := (params l ++ params r).eraseDups.map fun p => (p, c.d.ρ.param p) } }]
  | .and a b | .or a b | .implies a b | .since a b | .until a b | .definedWhen a b
  | .atLast _ _ _ a b | .untilWithin _ _ _ a b =>
    pure ((← values c i a s!"{path}.0") ++ (← values c i b s!"{path}.1"))
  | .not a | .rises a | .always a | .eventually a | .holdsFor _ _ _ a | .within _ _ _ a => values c i a s!"{path}.0"
  | .existsUser .. | .forallUser .. | .existsRegion .. | .forallRegion .. | .existsDevice .. | .forallDevice .. =>
    match ← members c i φ, body φ with
    | some (var, ms), some b => do
      let xs ← ms.mapM fun (x, _) => values (c.bindVar var x) i b s!"{path}[{var}={valStr x}]"
      pure xs.flatten
    | _, _ => pure []
  | _ => pure []

-- ---------------------------------------------------------------------------------------------
-- Rendering: text and JSON from the same tree
-- ---------------------------------------------------------------------------------------------

def winLine (w : Win) : String :=
  let span := match w.fromMs, w.toMs with
    | some a, some b => s!"reads t={a}…{b} ms"
    | none, some b => s!"at t={b} ms"
    | _, _ => "window unknown"
  let len := match w.length with
    | some l => s!", {w.measure} window of {qStr l} {if w.measure == "path" then "m" else "s"} of {w.subject}"
    | none => ""
  let cov := match w.covered, w.adequate with
    | some c, some a => s!", {if c then "covered" else "not covered"}, {if a then "adequately sampled" else "sampled too sparsely"}"
    | _, _ => ""
  let dec := match w.decidedAtMs, w.supportFromMs, w.supportToMs with
    | some t, _, _ => s!"; decided at t={t} ms: {w.how}"
    | none, some a, some b => s!"; decided by t={a}…{b} ms together: {w.how}"
    | _, _, _ => if w.how.isEmpty then "" else s!"; {w.how}"
  s!"window ({w.op}): {span}{len}{cov}{dec}"

def cmpLines (pad : String) (v : R) (k : Cmp) : List String :=
  let ps := k.params.map fun (p, q) => s!"{p} = {match q with | some q => qStr q | none => "missing"}"
  [s!"{pad}{rStr v}: {cut k.lhs.term 90} = {sideStr k.lhs}  {k.op}  {sideStr k.rhs}", s!"{pad}    right side: {k.rhs.term}"] ++
    (if ps.isEmpty then [] else [s!"{pad}    parameters: {", ".intercalate ps}"])

partial def render (d : Nat) : Item → List String
  | .node v head cmp win note truncated children =>
    let pad := "".pushn ' ' (2 * d)
    let here := match cmp with
      | some k => cmpLines pad v k
      | none => [s!"{pad}{rStr v}: {head}"]
    let w := match win with | some x => [s!"{pad}    {winLine x}"] | none => []
    let n := match note with | some x => [s!"{pad}  {x}"] | none => []
    let tr := if truncated.isEmpty then [] else [s!"{pad}  (truncated: {", ".intercalate truncated})"]
    here ++ w ++ n ++ tr ++ children.flatMap fun ch => match ch with
      | .member var is b => s!"{pad}  {var} = {is}:" :: render (d + 2) b
      | .other r h role => [s!"{pad}  {rStr r}: {if role.isEmpty then "" else s!"({role}) "}{h}"]
      | x => render (d + 1) x
  | .member var is b => s!"{var} = {is}:" :: render (d + 1) b
  | .other r h role => [s!"{rStr r}: {if role.isEmpty then "" else s!"({role}) "}{h}"]

partial def truncations : Item → List String
  | .node _ _ _ _ _ tr ch => tr ++ ch.flatMap truncations
  | .member _ _ b => truncations b
  | .other .. => []

open Lean (Json toJson) in
def qJson (q : Q) : Json := let (n, d) := qNorm q; Json.mkObj [("num", toJson n), ("den", toJson d)]

open Lean (Json toJson) in
def rJson (r : R) : List (String × Json) :=
  [("value", toJson (triStr r.v))] ++ (if r.v == .u then [("reasons", toJson (reasonTags r))] else [])

open Lean (Json toJson) in
def sideJson (s : Side) : Json :=
  Json.mkObj ([("term", toJson s.term), ("text", toJson (sideStr s))]
    ++ (match s.value with | some q => [("exact", qJson q)] | none => [])
    ++ (match s.unknown with | some w => [("unknown", toJson w)] | none => [])
    ++ (if s.cases.isEmpty then [] else
        [("cases", Json.arr (s.cases.map fun r => match r with | .ok q => qJson q | .error w => toJson w.tag).toArray)]))

open Lean (Json toJson) in
def cmpJson (k : Cmp) : Json :=
  Json.mkObj [("lhs", sideJson k.lhs), ("op", toJson k.op), ("rhs", sideJson k.rhs),
    ("params", Json.mkObj (k.params.map fun (p, q) => (p, match q with | some q => qJson q | none => Json.null)))]

open Lean (Json toJson) in
def winJson (w : Win) : Json :=
  let opt {α} [Lean.ToJson α] (k : String) : Option α → List (String × Json) := fun o => match o with | some x => [(k, toJson x)] | none => []
  Json.mkObj ([("op", toJson w.op)]
    ++ (if w.measure.isEmpty then [] else [("measure", toJson w.measure), ("subject", toJson w.subject)])
    ++ (match w.length with | some l => [("length", qJson l)] | none => [])
    ++ opt "from_ms" w.fromMs ++ opt "to_ms" w.toMs ++ opt "covered" w.covered ++ opt "adequate" w.adequate
    ++ opt "decided_at_ms" w.decidedAtMs ++ opt "support_from_ms" w.supportFromMs ++ opt "support_to_ms" w.supportToMs
    ++ [("how", toJson w.how)])

open Lean (Json toJson) in
partial def itemJson : Item → Json
  | .node v head cmp win note truncated children =>
    Json.mkObj (rJson v ++ [("head", toJson head)]
      ++ (match cmp with | some k => [("cmp", cmpJson k)] | none => [])
      ++ (match win with | some w => [("window", winJson w)] | none => [])
      ++ (match note with | some n => [("note", toJson n)] | none => [])
      ++ (if truncated.isEmpty then [] else [("truncated", toJson truncated)])
      ++ [("children", Json.arr (children.map itemJson).toArray)])
  | .member var is b => Json.mkObj [("member", toJson var), ("is", toJson is), ("body", itemJson b)]
  | .other r h role => Json.mkObj (rJson r ++ [("head", toJson h), ("role", toJson role)])

-- ---------------------------------------------------------------------------------------------
-- Execution as the monitor executes, one observation, and the choice of observations
-- ---------------------------------------------------------------------------------------------

/-- The rule set up as the monitor sets it up for `--rules <id>`: concepts expanded, registered with
    the rules it composes, the whole trace admitted, the monitor's support. -/
def prepare (rules : List Rule) (concepts : List Concept) (rid : String) (τ : Trace) (ρ : Reading) (m : Manifest) :
    Except String (Setup × Rule × Support) := do
  let rules := rules.map (Concept.expandRule concepts)
  let some r := rules.find? (·.id == rid) | throw s!"no registered rule {rid}"
  let reg := Rule.closure rules r
  match Setup.admit reg (maskTrace m τ) ρ m.reidGap with
  | .ok S => pure (S, r, support reg r m)
  | .error ds => throw s!"the trace is not admitted: {"; ".intercalate ds}"

/-- The groundings explained: the given binding, or every grounding of the monitor
    (`Grounding.check`), at most `maxG` when given; with the number there are. -/
def selectGroundings (S : Setup) (r : Rule) (binds : List (String × Nat)) (maxG : Option Nat) :
    List (Grounding × Array (Timestamp × Verdict) × Verdict) × Nat :=
  let all : List (Grounding × Array (Timestamp × Verdict) × Verdict) :=
    if binds.isEmpty then (Grounding.check S r).map fun (g, tl, ep) => (g, tl.verdicts, ep)
    else
      let g : Grounding := { assign := binds.map fun (n, t) => (n, canon S.cm t) }
      let tl := Grounding.timeline S r g
      [(g, tl, Grounding.episode (tl.toList.map (·.2)))]
  ((match maxG with | some n => all.take n | none => all), all.length)

structure Report where
  i : Nat
  t : Int
  verdict : Verdict
  applies : R
  classes : List (String × Item)
  applicability : Item
  obligation : Item
  because : String := ""

def report (S : Setup) (r : Rule) (g : Grounding) (tl : Array (Timestamp × Verdict)) (i : Nat) (because : String := "") : EM Report := do
  let c := S.ctx g.binding
  pure { i, t := tAt c i, verdict := ((tl[i]?).map (·.2)).getD (.unknown [.outOfRange]),
         applies := (r.engagedAll c)[i]?.getD (R.u .outOfRange),
         classes := ← r.binders.mapM fun b => do pure (b.name, ← build c i b.cls 1),
         applicability := ← build c i r.applicability 1,
         obligation := ← build c i r.obligation 1, because }

/-- The comparisons reached through the connectives alone, and how many others lie under a
    quantifier or a temporal operator. -/
partial def topComparisons : Formula → List (Term × Term)
  | .and a b | .or a b | .implies a b => topComparisons a ++ topComparisons b
  | .not a => topComparisons a
  | .cmp l _ r => [(l, r)]
  | _ => []

partial def allComparisons : Formula → Nat
  | .cmp .. => 1
  | .and a b | .or a b | .implies a b | .since a b | .until a b | .definedWhen a b
  | .atLast _ _ _ a b | .untilWithin _ _ _ a b => allComparisons a + allComparisons b
  | .not a | .rises a | .always a | .eventually a | .holdsFor _ _ _ a | .within _ _ _ a
  | .existsUser _ a | .forallUser _ a | .existsRegion _ _ a | .forallRegion _ _ a
  | .existsDevice _ _ a | .forallDevice _ _ a => allComparisons a
  | _ => 0

def relMargin (L R' : Array QR) (i : Nat) : Option Float :=
  match L[i]?, R'[i]? with
  | some (.ok a), some (.ok b) =>
    let x := qFloat a
    let y := qFloat b
    some ((x - y).abs / max (max x.abs y.abs) 1e-9)
  | _, _ => none

def argBest (xs : List (Nat × Float)) (better : Float → Float → Bool) : Option (Nat × Float) :=
  xs.foldl (fun acc p => match acc with
    | none => some p
    | some q => if better p.2 q.2 then some p else acc) none

def addPick (acc : List (Nat × String)) (p : Nat × String) : List (Nat × String) :=
  if acc.any (·.1 == p.1) then acc else acc ++ [p]

/-- The observations `--scan` explains, each with the reason it was chosen, and what the choice
    left out. -/
def choose (S : Setup) (r : Rule) (g : Grounding) (tl : Array (Timestamp × Verdict)) (k : Nat)
    (inW : Nat → Bool := fun _ => true) : EM (List (Nat × String) × List String) := do
  let c := S.ctx g.binding
  let n := tl.size
  let tag (i : Nat) := ((tl[i]?).map (·.2.tag)).getD ""
  let idx := (List.range n).filter inW
  let viol := idx.filter fun i => tag i == "violated" && (i == 0 || !inW (i - 1) || tag (i - 1) != "violated")
  if !viol.isEmpty then
    return ((viol.take k).map (·, "first observation of a violated interval"),
            if viol.length > k then [s!"violated intervals: {k} of {viol.length} explained"] else [])
  let eng := r.engagedAll c
  let engaged := idx.filter fun i => (eng[i]?.map (·.v == .t)).getD false && tag i != "not_applicable"
  if !engaged.isEmpty then
    let tops := topComparisons r.obligation
    let skipped := allComparisons r.obligation - tops.length
    let mut picks : List (Nat × String) := []
    if let some i := engaged.find? (tag · == "unknown") then
      picks := addPick picks (i, "first engaged observation whose verdict is unknown")
    let compliant := engaged.filter (tag · == "compliant")
    for (l, rt) in tops do
      let L := evalTAll c l
      let Rr := evalTAll c rt
      if let some (i, m) := argBest (compliant.filterMap fun i => (relMargin L Rr i).map (i, ·)) (· < ·) then
        let (num, den) := qNorm (Q.mk' (Float.round (m * 1000)).toInt64.toInt 1000)
        picks := addPick picks (i, s!"engaged observation at which `{cut (termStr c.β l) 60}` is relatively closest to `{cut (termStr c.β rt) 60}` (margin {num}/{den})")
    if picks.isEmpty then
      picks := [(engaged.head!, "first engaged observation (no comparison of the obligation outside quantifiers and temporal operators decides a margin)")]
    let notes := (if skipped > 0 then [s!"comparisons not searched for a margin (under a quantifier or a temporal operator): {skipped}"] else [])
      ++ (if picks.length > k then [s!"observations: {k} of {picks.length} explained"] else [])
    return (picks.take k, notes)
  let parts := r.binders.map (·.cls) ++ conj r.applicability
  let arrs ← parts.mapM (allAt c)
  let present := idx.filter fun i => g.assign.all fun (_, t) => (S.scenes[i]!).tracks.contains t
  let scored := present.map fun i => (i, Float.ofNat (arrs.filter (fun a => (a[i]?.map (·.v == .t)).getD false)).length)
  match argBest scored (· > ·) with
  | some (i, s) => return ([(i, s!"never engaged; the observation at which the most binder classes and applicability conjuncts hold ({s.toUInt64} of {parts.length}; a count, not a distance)")], [])
  | none => return ([(idx.headD 0, "never engaged, and no observation has every bound track present")], [])

def bindingStr (g : Grounding) : String := ", ".intercalate (g.assign.map fun (n, t) => s!"{n}=track {t}")

def reportText (rid : String) (g : Grounding) (rp : Report) : List String :=
  let reasons := rp.verdict.reasons.map UnknownReason.tag |>.eraseDups
  [s!"rule {rid} at t={rp.t} ms (observation {rp.i + 1}), {bindingStr g}: verdict {rp.verdict.tag}{if reasons.isEmpty then "" else s!" ({", ".intercalate reasons})"}"]
  ++ (if rp.because.isEmpty then [] else [s!"chosen: {rp.because}"])
  ++ [s!"applies: {rStr rp.applies}"]
  ++ (rp.classes.filter (fun (_, it) => (it.value.map (·.v != .t)).getD false)).flatMap (fun (b, it) => s!"binder {b}:" :: render 1 it)
  ++ (if rp.applies.v == .t then [] else "applicability:" :: render 1 rp.applicability)
  ++ ["obligation:"] ++ render 1 rp.obligation

open Lean (Json toJson) in
def reportJson (rid : String) (g : Grounding) (rp : Report) : Json :=
  let text := reportText rid g rp
  let tr := (rp.classes.flatMap (truncations ·.2)) ++ truncations rp.applicability ++ truncations rp.obligation
    ++ (if text.length > maxLines then [s!"text: {maxLines} of {text.length} lines"] else [])
  Json.mkObj [("rule", toJson rid), ("at_ms", toJson rp.t), ("observation", toJson (rp.i + 1)),
    ("binding", Json.mkObj (g.assign.map fun (n, t) => (n, toJson t))), ("verdict", toJson rp.verdict.tag),
    ("verdict_reasons", toJson (rp.verdict.reasons.map UnknownReason.tag |>.eraseDups)),
    ("chosen_because", toJson rp.because), ("applies", Json.mkObj (rJson rp.applies)),
    ("classes", Json.mkObj (rp.classes.map fun (b, it) => (b, itemJson it))),
    ("applicability", itemJson rp.applicability), ("obligation", itemJson rp.obligation),
    ("truncated", toJson tr), ("text", toJson (text.take maxLines))]

open Lean (Json toJson) in
def valueJson (x : Value) : Json :=
  Json.mkObj ([("path", toJson x.path), ("binding", toJson x.binding)] ++ rJson x.value ++ [("cmp", cmpJson x.cmp)])

/-- Every comparison of the rule at observation `i`, for grounding `g`: (values, truncated). -/
def allValues (S : Setup) (r : Rule) (g : Grounding) (i : Nat) : EM (List Value × Bool) := do
  let c := S.ctx g.binding
  let cls ← r.binders.mapM fun b => values c i b.cls s!"classes.{b.name}"
  let xs := cls.flatten ++ (← values c i r.applicability "applicability") ++ (← values c i r.obligation "obligation")
  pure (xs.take maxValues, xs.length > maxValues)

end Explain

open Explain in
def main (args : List String) : IO UInt32 := do
  let usage := "explain --manifest M --reading R --rule ID [--bind name=track ...] (--at MS [--values] | --scan [--from MS --to MS] [--max K] [--max-groundings N]) [--json] TRACE"
  let rec parse : List String → (Std.HashMap String String × List (String × Nat) × Option String) →
      Except String (Std.HashMap String String × List (String × Nat) × Option String)
    | [], o => pure o
    | "--scan" :: r, (m, b, t) => parse r (m.insert "scan" "1", b, t)
    | "--json" :: r, (m, b, t) => parse r (m.insert "json" "1", b, t)
    | "--values" :: r, (m, b, t) => parse r (m.insert "values" "1", b, t)
    | "--bind" :: p :: r, (m, b, t) =>
      match p.splitOn "=" with
      | [n, k] => match k.toNat? with
        | some k => parse r (m, b ++ [(n, k)], t)
        | none => throw s!"--bind {p}: a track number expected"
      | _ => throw s!"--bind {p}: name=track expected"
    | o :: v :: r, (m, b, t) =>
      if ["--manifest", "--reading", "--rule", "--at", "--max", "--max-groundings", "--from", "--to"].contains o then parse r (m.insert o v, b, t)
      else if o.startsWith "--" then throw s!"unknown option {o}" else parse (v :: r) (m, b, some o)
    | [o], (m, b, _) => if o.startsWith "--" then throw s!"unknown option {o}" else pure (m, b, some o)
  match parse args ({}, [], none) with
  | .error e => IO.eprintln s!"explain: {e}\n{usage}"; return (2 : UInt32)
  | .ok (o, binds, tp?) =>
    let some mp := o["--manifest"]? | IO.eprintln usage; return (2 : UInt32)
    let some rp := o["--reading"]? | IO.eprintln usage; return (2 : UInt32)
    let some rid := o["--rule"]? | IO.eprintln usage; return (2 : UInt32)
    let some tp := tp? | IO.eprintln usage; return (2 : UInt32)
    let scan := o.contains "scan"
    let json := o.contains "json"
    let vals := o.contains "values"
    let atT? := (o["--at"]?).bind String.toInt?
    if scan == atT?.isSome then IO.eprintln s!"explain: give exactly one of --at and --scan\n{usage}"; return (2 : UInt32)
    if vals && scan then IO.eprintln s!"explain: --values goes with --at\n{usage}"; return (2 : UInt32)
    if !scan && binds.isEmpty then IO.eprintln s!"explain: --at needs --bind\n{usage}"; return (2 : UInt32)
    let fromT? := (o["--from"]?).bind String.toInt?
    let toT? := (o["--to"]?).bind String.toInt?
    if fromT?.isSome != toT?.isSome || (o.contains "--from" && fromT?.isNone) || (o.contains "--to" && toT?.isNone) then
      IO.eprintln s!"explain: --from and --to go together, each an integer of ms\n{usage}"; return (2 : UInt32)
    if fromT?.isSome && !scan then IO.eprintln s!"explain: --from and --to go with --scan\n{usage}"; return (2 : UInt32)
    let k := ((o["--max"]?).bind String.toNat?).getD 3
    let maxG? := (o["--max-groundings"]?).bind String.toNat?
    try
      let read {α : Type} (dec : Lean.Json → Decode.D α) (p : String) : IO α := do
        match Decode.parse dec (← IO.FS.readFile p) with
        | .ok v => pure v
        | .error e => throw (IO.userError s!"{p}: {e}")
      let m ← read Decode.manifest mp
      let ρ ← read Decode.reading rp
      let τ ← read Decode.trace tp
      let (S, r, sup) ← match prepare allRules allConcepts rid τ ρ m with
        | .ok x => pure x
        | .error e => IO.eprintln s!"explain: {e}"; return (2 : UInt32)
      let names := r.binders.map (·.name)
      if !binds.isEmpty && (binds.map (·.1)).toArray.qsort (· < ·) != names.toArray.qsort (· < ·) then
        IO.eprintln s!"explain: --bind must name each binder of {rid} once: {", ".intercalate names}"; return (2 : UInt32)
      let head := Lean.Json.mkObj [("rule", Lean.toJson rid), ("support", Lean.toJson sup.tag), ("absent", Lean.toJson sup.absent)]
      if let .unsupported a := sup then
        if json then IO.println (Lean.Json.mkObj [("rule", Lean.toJson rid), ("support", Lean.toJson "unsupported"), ("absent", Lean.toJson a),
                                                   ("groundings", Lean.Json.arr #[])]).compress
        else IO.println s!"rule {rid} is unsupported by the manifest (absent: {", ".intercalate a}): the monitor evaluates no grounding, and nothing is explained"
        return (0 : UInt32)
      let inW : Nat → Bool := match fromT?, toT? with
        | some a, some b => fun i => i < S.n && a ≤ S.scenes[i]!.t && S.scenes[i]!.t ≤ b
        | _, _ => fun _ => true
      if fromT?.isSome && !(List.range S.n).any inW then
        IO.eprintln s!"explain: no observation in [{fromT?.getD 0}, {toT?.getD 0}] ms"; return (2 : UInt32)
      let (chosen, total) := selectGroundings S r binds maxG?
      let mut out : Array Lean.Json := #[]
      -- the coverage line, in text, only where it adds something: a partial support or a cut
      if !json && (sup.tag != "supported" || chosen.length < total) then
        IO.println s!"rule {rid}: support {sup.tag}{if sup.absent.isEmpty then "" else s!" (absent: {", ".intercalate sup.absent})"}; {chosen.length} of {total} grounding(s) explained"
      for (g, tl, ep) in chosen do
        let picks : List (Nat × String) × List String ← match atT? with
          | some atT =>
            match (List.range S.n).find? (fun j => S.scenes[j]!.t == atT) with
            | some i => pure ([(i, "")], [])
            | none => IO.eprintln s!"explain: no observation at t={atT}"; return (2 : UInt32)
          | none => pure (Id.run ((choose S r g tl k inW).run' {}))
        if vals then
          let (i, _) := picks.1.head!
          let (xs, cutV) := Id.run ((allValues S r g i).run' {})
          if json then
            out := out.push (Lean.Json.mkObj [("binding", Lean.Json.mkObj (g.assign.map fun (n, t) => (n, Lean.toJson t))),
              ("at_ms", Lean.toJson (S.scenes[i]!.t)), ("verdict", Lean.toJson (((tl[i]?).map (·.2.tag)).getD "")),
              ("values", Lean.Json.arr (xs.map valueJson).toArray), ("truncated", Lean.toJson cutV)])
          else
            IO.println s!"{bindingStr g} at t={S.scenes[i]!.t} ms: {xs.length} comparison(s){if cutV then " (truncated)" else ""}"
            for x in xs do
              IO.println s!"  {x.path} [{x.binding}] {triStr x.value.v}: {x.cmp.lhs.term} = {sideStr x.cmp.lhs}  {x.cmp.op}  {sideStr x.cmp.rhs} = {x.cmp.rhs.term}"
        else
          let rps : List Report := Id.run ((picks.1.mapM fun (i, why) => report S r g tl i why).run' {})
          if json then
            out := out.push (Lean.Json.mkObj [("binding", Lean.Json.mkObj (g.assign.map fun (n, t) => (n, Lean.toJson t))),
              ("episode", Lean.toJson ep.tag), ("episode_reasons", Lean.toJson (ep.reasons.map UnknownReason.tag |>.eraseDups)),
              ("choice_notes", Lean.toJson picks.2), ("explanations", Lean.Json.arr (rps.map (reportJson rid g)).toArray)])
          else
            for n in picks.2 do IO.println s!"note: {n}"
            for rp in rps do
              for l in (reportText rid g rp).take maxLines do IO.println l
      if json then
        IO.println (head.mergeObj (Lean.Json.mkObj [("groundings_total", Lean.toJson total),
          ("groundings_explained", Lean.toJson chosen.length), ("groundings", Lean.Json.arr out)])).compress
      return (0 : UInt32)
    catch e => IO.eprintln s!"explain: {e}"; return (2 : UInt32)
