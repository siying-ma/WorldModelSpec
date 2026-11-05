import TrafficSpec.Core.Foundations.Temporal
import TrafficSpec.Tests.Time
namespace TrafficSpec.Tests
open TrafficSpec Temporal Units

/-- The window operator that leaves every window not covered unknown, whatever φ holds inside it. -/
def truncatingHoldsForAll (pos : Array (Option Q)) (d : Q) (op : String) (missing : UnknownReason) (φ : Array R) :
    Array R :=
  let wins := Time.backWindows pos d
  let agg := RangeAgg.build φ
  (Array.range φ.size).map fun i =>
    match wins[i]! with
    | none => R.u missing
    | some w =>
      if !w.covered then truncated op
      else if !w.adequate then R.u (.samplingGap op)
      else agg.all w.j0 i

private theorem truncating_getElem! (pos : Array (Option Q)) (d : Q) (op : String) (missing : UnknownReason)
    (φ : Array R) (i : Nat) (hi : i < φ.size) :
    (truncatingHoldsForAll pos d op missing φ)[i]! =
      match (Time.backWindows pos d)[i]! with
      | none => R.u missing
      | some w =>
        if !w.covered then truncated op
        else if !w.adequate then R.u (.samplingGap op)
        else (RangeAgg.build φ).all w.j0 i := by
  unfold truncatingHoldsForAll
  rw [getElem!_pos _ i (by simpa using hi)]
  simp

/-- Every value the truncating operator decides, `holdsForAll` decides the same way. -/
theorem holdsForAll_keeps_decided (pos : Array (Option Q)) (d : Q) (op : String) (missing : UnknownReason)
    (φ : Array R) (i : Nat) (h : (truncatingHoldsForAll pos d op missing φ)[i]!.v ≠ .u) :
    (holdsForAll pos d op missing φ)[i]! = (truncatingHoldsForAll pos d op missing φ)[i]! := by
  rcases Nat.lt_or_ge i φ.size with hi | hi
  · rw [holdsForAll_getElem! pos d op missing φ i hi]
    rw [truncating_getElem! pos d op missing φ i hi] at h ⊢
    cases hw : (Time.backWindows pos d)[i]! with
    | none => rfl
    | some w =>
      cases hc : w.covered
      · simp [hw, hc, truncated, R.u] at h
      · simp [hc]
  · rw [getElem!_neg _ i (by simpa [size_holdsForAll] using hi),
        getElem!_neg _ i (by simpa [truncatingHoldsForAll] using hi)]

/-- A false the truncating operator did not report has a false observation `j` inside the window,
    which is not covered. -/
theorem holdsForAll_new_f (pos : Array (Option Q)) (d : Q) (op : String) (missing : UnknownReason)
    (φ : Array R) (i : Nat) (hf : (holdsForAll pos d op missing φ)[i]!.v = .f)
    (hold : (truncatingHoldsForAll pos d op missing φ)[i]!.v ≠ .f) :
    ∃ w, (Time.backWindows pos d)[i]! = some w ∧ w.covered = false ∧
      ∃ j, w.j0 ≤ j ∧ j ≤ i ∧ j < φ.size ∧ φ[j]!.v = .f := by
  rcases Nat.lt_or_ge i φ.size with hi | hi
  · cases hw : (Time.backWindows pos d)[i]! with
    | none =>
      rw [holdsForAll_getElem! pos d op missing φ i hi, hw] at hf
      simp [R.u] at hf
    | some w =>
      cases hc : w.covered
      · exact ⟨w, rfl, hc, holdsForAll_uncovered_f pos d op missing φ i w hi hw hc hf⟩
      · exfalso
        apply hold
        rw [truncating_getElem! pos d op missing φ i hi, hw]
        rw [holdsForAll_getElem! pos d op missing φ i hi, hw] at hf
        simpa [hc] using hf
  · exfalso
    apply hold
    rw [getElem!_neg _ i (by simpa [size_holdsForAll] using hi)] at hf
    rw [getElem!_neg _ i (by simpa [truncatingHoldsForAll] using hi)]
    exact hf

/-- Where the window is not covered and holds no false observation, the truncation stays,
    reason included. -/
theorem holdsForAll_keeps_truncation (pos : Array (Option Q)) (d : Q) (op : String) (missing : UnknownReason)
    (φ : Array R) (i : Nat) (w : Time.Back) (hi : i < φ.size) (hw : (Time.backWindows pos d)[i]! = some w)
    (hc : w.covered = false) (hn : ∀ j, w.j0 ≤ j → j ≤ i → φ[j]!.v ≠ .f) :
    (holdsForAll pos d op missing φ)[i]! = (truncatingHoldsForAll pos d op missing φ)[i]! := by
  rw [holdsForAll_uncovered_of_no_f pos d op missing φ i w hi hw hc hn, truncating_getElem! pos d op missing φ i hi, hw]
  simp [hc]

-- one observation, a 20 s window behind it: a false operand is false, as `always` reports it
def oneObs : Array (Option Q) := #[some (seconds 0)]
#guard (holdsForAll oneObs (seconds 20) "holdsFor" .outOfRange #[R.f])[0]!.v = .f
#guard (alwaysAll #[R.f])[0]!.v = .f
#guard ((truncatingHoldsForAll oneObs (seconds 20) "holdsFor" .outOfRange #[R.f])[0]!).why = [.windowTruncated "holdsFor"]
-- true or unknown inside a window not covered stays truncated, reason included
#guard ((holdsForAll oneObs (seconds 20) "holdsFor" .outOfRange #[R.t])[0]!).why = [.windowTruncated "holdsFor"]
#guard ((holdsForAll oneObs (seconds 20) "holdsFor" .outOfRange #[R.u (.absentAtom "a")])[0]!).why = [.windowTruncated "holdsFor"]
-- 0.5 s sampling, a 1 s window: covered from 1 s on; the false at 0.5 s decides 0.5 s and 1 s only
def mixed : Array R := #[R.t, R.f, R.t, R.t, R.t]
#guard ((holdsForAll pos5 (seconds 1) "holdsFor" .outOfRange mixed).map (·.v)) = #[.u, .f, .f, .f, .t]
#guard ((truncatingHoldsForAll pos5 (seconds 1) "holdsFor" .outOfRange mixed).map (·.v)) = #[.u, .u, .f, .f, .t]
-- a missing position and an inadequately sampled covered window are unchanged
#guard ((holdsForAll posGap (seconds 2) "holdsFor" .outOfRange #[R.f, R.f, R.f, R.f])[2]!).why = [.outOfRange]
#guard ((holdsForAll pos5 (milliseconds 500) "holdsFor" .outOfRange mixed)[2]!).why = [.samplingGap "holdsFor"]
