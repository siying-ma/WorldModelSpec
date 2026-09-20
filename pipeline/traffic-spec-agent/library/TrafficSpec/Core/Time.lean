/-
  TrafficSpec.Core.Time
  Metric windows without a frame rate.

  Every observation carries a timestamp; a body also carries the path length it has travelled.
  A window is measured in one of the two ("remain stopped until …" is time; "during the last
  hundred feet traveled" is path). Semantics are defined on the OBSERVED instants only; the one
  interpolation-free precondition is adequacy: a window of length d over a span is adequate when
  consecutive observations in the span are at most d/2 apart. An inadequate span yields `unknown`
  with the reason `samplingGap`, never a verdict invented between frames.

  There is no `next`, no rate and no frame count anywhere in the library.
-/
import TrafficSpec.Core.Units

namespace TrafficSpec

/-- Milliseconds, monotone within a trace. -/
abbrev Timestamp := Int

/-- Which quantity a window is measured in. -/
inductive Measure
  | time | path
  deriving DecidableEq, Repr, Inhabited

/-- A window: a non-negative length in seconds (time) or metres (path). -/
structure Duration where
  measure : Measure
  length : Q
  deriving Repr

namespace Duration
def time (q : Q) : Duration := ⟨.time, q⟩
def path (q : Q) : Duration := ⟨.path, q⟩
end Duration

namespace Time

def ofTimestamp (t : Timestamp) : Q := Units.milliseconds t

/-- Consecutive gaps of a sorted list of positions (time or path). -/
def gaps : List Q → List Q
  | a :: b :: rest => Q.sub b a :: gaps (b :: rest)
  | _ => []

/-- Every consecutive gap in the span is at most `d / 2`. Vacuously true on one observation. -/
def adequate (d : Q) (span : List Q) : Bool :=
  (gaps span).all (fun g => Q.le g (Q.half d))

/-- The position recorded at index `j`, if the index exists and the position was observed. -/
def posAt (pos : List (Option Q)) (j : Nat) : Option Q := (pos[j]?).bind id

/-- Indices `j ≤ i` whose position is within `d` behind position `i`, oldest first, together
    with whether the trace reaches back past the window (so the window is fully covered): the
    oldest in-window observation is exactly `d` behind, or an observation precedes it.
    `none` when `i` is out of range, its position is missing, or a position inside the window
    is missing (a gap the adequacy test could not see). -/
def windowBack (pos : List (Option Q)) (i : Nat) (d : Q) : Option (List Nat × Bool) := do
  let pi ← posAt pos i
  let idx := (List.range (i + 1)).filter fun j =>
    match posAt pos j with
    | some pj => Q.le (Q.sub pi pj) d
    | none => false
  -- an index inside the window (between the oldest selected and i) with a missing position
  let j0 ← idx.head?
  if (List.range (i + 1)).any (fun j => j ≥ j0 && (posAt pos j).isNone) then none
  else
    let p0 ← posAt pos j0
    let covered := j0 > 0 || Q.ge (Q.sub pi p0) d
    pure (idx, covered)

/-- Indices `j ≥ i` whose position is within `d` ahead of position `i`, together with whether
    the trace reaches past the window. -/
def windowForward (pos : List (Option Q)) (i : Nat) (d : Q) : Option (List Nat × Bool) := do
  let pi ← posAt pos i
  let n := pos.length
  let idx := (List.range n).filter fun j =>
    j ≥ i && (match posAt pos j with
      | some pj => Q.le (Q.sub pj pi) d
      | none => false)
  let jl ← idx.getLast?
  if (List.range n).any (fun j => j ≥ i && j ≤ jl && (posAt pos j).isNone) then none
  else
    let pl ← posAt pos jl
    let covered := jl + 1 < n || Q.ge (Q.sub pl pi) d
    pure (idx, covered)

/-- The positions of a span selected by index. -/
def select (pos : List (Option Q)) (idx : List Nat) : List Q :=
  idx.filterMap fun j => posAt pos j

end Time
end TrafficSpec
