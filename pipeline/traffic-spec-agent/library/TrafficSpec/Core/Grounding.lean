/-
  TrafficSpec.Core.Grounding
  Which assignments of tracks to binders exist over a trace, how a broken track is followed, and
  the per-grounding timeline of verdicts.

  A track is a source's identity, not an object's. When a tracker breaks and the adapter claims a
  continuation (`Scene.links`, old ↦ new), the grounding follows it when the break is shorter than
  the manifest's re-identification gap; the instants inside the gap are unknown (identityGap),
  never a fresh party. A binder whose track is not present at an instant outside any gap leaves
  the rule not engaged there: the other party has left the scene.

  Rules never import this file: a rule that could see the census of tracks could special-case it.
-/
import TrafficSpec.Core.Rule

namespace TrafficSpec
namespace Grounding
open Semantics

/-- An assignment of canonical tracks to binder names. -/
structure Grounding where
  assign : List (String × TrackId)
  deriving Repr, DecidableEq, Inhabited

def Grounding.render (g : Grounding) : String :=
  String.intercalate "," (g.assign.map fun (n, t) => s!"{n}={t}")

-- ---------------------------------------------------------------------------------------------
-- Identity: canonical tracks through accepted links
-- ---------------------------------------------------------------------------------------------
def firstSeen (τ : Trace) (t : TrackId) : Option Nat :=
  (List.range τ.length).find? fun i => (τ[i]?).map (·.tracks.contains t) == some true
def lastSeen (τ : Trace) (t : TrackId) : Option Nat :=
  ((List.range τ.length).reverse).find? fun i => (τ[i]?).map (·.tracks.contains t) == some true
def timeAt (τ : Trace) (i : Nat) : Option Q := (τ[i]?).map fun s => Time.ofTimestamp s.t

/-- A link old ↦ new is accepted when `new` first appears after `old` was last seen, within `gap`. -/
def acceptedLinks (τ : Trace) (gap : Q) : List (TrackId × TrackId) :=
  (τ.flatMap (·.links)).eraseDups.filter fun (old, new) =>
    match lastSeen τ old, firstSeen τ new with
    | some lo, some fn =>
      fn > lo && (match timeAt τ fn, timeAt τ lo with
        | some tf, some tl => Q.le (Q.sub tf tl) gap
        | _, _ => false)
    | _, _ => false

/-- The canonical (root) track of every track, following accepted links backwards. -/
def canonMap (τ : Trace) (gap : Q) : List (TrackId × TrackId) :=
  let links := acceptedLinks τ gap
  let tracks := (τ.flatMap (·.tracks)).eraseDups
  let rec root (t : TrackId) (fuel : Nat) : TrackId :=
    match fuel with
    | 0 => t
    | fuel + 1 =>
      match links.find? (·.2 == t) with
      | some (old, _) => root old fuel
      | none => t
  tracks.map fun t => (t, root t (links.length + 1))

def canon (cm : List (TrackId × TrackId)) (t : TrackId) : TrackId :=
  ((cm.find? (·.1 == t)).map (·.2)).getD t
def canonicalTracks (cm : List (TrackId × TrackId)) : List TrackId := (cm.map (·.2)).eraseDups
/-- The track in scene `s` that carries canonical identity `c`, if present. -/
def present (cm : List (TrackId × TrackId)) (s : Scene) (c : TrackId) : Option TrackId :=
  s.tracks.find? fun t => canon cm t == c
/-- Span of a canonical identity over the trace (first and last index of any of its tracks). -/
def span (τ : Trace) (cm : List (TrackId × TrackId)) (c : TrackId) : Option (Nat × Nat) :=
  let idx := (List.range τ.length).filter fun i => (τ[i]?).bind (fun s => present cm s c) |>.isSome
  match idx.head?, idx.getLast? with
  | some a, some b => some (a, b)
  | _, _ => none

-- ---------------------------------------------------------------------------------------------
-- Enumeration
-- ---------------------------------------------------------------------------------------------
/-- Everything the enumeration and the timeline need about one trace. -/
structure Setup where
  rules : List Rule
  τ : Trace
  ρ : Reading
  gap : Q
  cm : List (TrackId × TrackId) := []

def Setup.mk' (rules : List Rule) (τ : Trace) (ρ : Reading) (gap : Q) : Setup :=
  { rules := rules, τ := τ, ρ := ρ, gap := gap, cm := canonMap τ gap }

def Setup.ctx (S : Setup) (β : Binding) : SemCtx := Rule.context S.rules S.τ S.ρ β

/-- The binding at instant `i` for a grounding, or the binders whose identity is not present. -/
def bindingAt (S : Setup) (g : Grounding) (i : Nat) : Except (List (String × TrackId)) Binding :=
  match S.τ[i]? with
  | none => .error g.assign
  | some s =>
    let resolved := g.assign.map fun (n, c) => (n, c, present S.cm s c)
    let missing := resolved.filterMap fun (n, c, o) => if o.isNone then some (n, c) else none
    if missing.isEmpty then .ok ⟨resolved.filterMap fun (n, _, o) => o.map fun t => (n, Val.track t)⟩
    else .error missing

/-- Canonical identities that satisfy a binder's class at some instant. -/
def candidates (S : Setup) (b : Binder) : List TrackId :=
  (canonicalTracks S.cm).filter fun c =>
    (List.range S.τ.length).any fun i =>
      match S.τ[i]? with
      | none => false
      | some s =>
        match present S.cm s c with
        | none => false
        | some t => (eval (S.ctx ⟨[(b.name, .track t)]⟩) i b.cls).v == .t

/-- All assignments of distinct candidates to the binders, subject first. -/
def groundings (S : Setup) (r : Rule) : List Grounding :=
  let rec go (bs : List Binder) (used : List TrackId) : List (List (String × TrackId)) :=
    match bs with
    | [] => [[]]
    | b :: rest =>
      (candidates S b).filter (fun c => !used.contains c) |>.flatMap fun c =>
        (go rest (c :: used)).map fun tail => (b.name, c) :: tail
  (go r.binders []).map Grounding.mk

/-- Predicted grounding count without enumerating: the product of candidate counts (an upper bound
    when candidates overlap). -/
def predictedGroundings (S : Setup) (r : Rule) : Nat :=
  r.binders.foldl (fun acc b => acc * (candidates S b).length) 1

-- ---------------------------------------------------------------------------------------------
-- Timelines
-- ---------------------------------------------------------------------------------------------
/-- The verdict of a rule for a grounding at one instant. A binder absent inside its identity's
    span is an identity gap (unknown); absent outside it, the rule is not engaged. -/
def verdictAt (S : Setup) (r : Rule) (g : Grounding) (i : Nat) : Verdict :=
  match bindingAt S g i with
  | .ok β => r.verdict (S.ctx β) i
  | .error missing =>
    let inGap := missing.filter fun (_, c) =>
      match span S.τ S.cm c with
      | some (a, b) => a < i && i < b
      | none => false
    if inGap.isEmpty then .notApplicable
    else .unknown (inGap.map fun (_, c) => .identityGap c)

def timeline (S : Setup) (r : Rule) (g : Grounding) : List (Timestamp × Verdict) :=
  (List.range S.τ.length).filterMap fun i => (S.τ[i]?).map fun s => (s.t, verdictAt S r g i)

/-- The episode verdict: a violation anywhere is a violation; else any unknown is unknown (with
    every reason); else engaged anywhere is compliant; else not applicable. -/
def episode (tl : List Verdict) : Verdict :=
  if tl.any (· == .violated) then .violated
  else
    let unknowns := tl.flatMap Verdict.reasons
    if tl.any (fun v => match v with | .unknown _ => true | _ => false) then .unknown unknowns.eraseDups
    else if tl.any (· == .compliant) then .compliant
    else .notApplicable

/-- Engaged (applicability true) at some instant for some grounding: the rule says something on
    this trace. -/
def live (S : Setup) (r : Rule) : Bool :=
  (groundings S r).any fun g =>
    (List.range S.τ.length).any fun i =>
      match bindingAt S g i with
      | .ok β => (r.engaged (S.ctx β) i).v == .t
      | .error _ => false

/-- Every grounding's episode verdict, for the whole-library check. -/
def check (S : Setup) (r : Rule) : List (Grounding × Verdict) :=
  (groundings S r).map fun g => (g, episode ((timeline S r g).map (·.2)))

end Grounding
end TrafficSpec
