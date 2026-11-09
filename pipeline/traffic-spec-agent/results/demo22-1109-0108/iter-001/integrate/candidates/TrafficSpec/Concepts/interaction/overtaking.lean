/-
  drv.interaction.overtaking — Road user a is passing road user b at the observation: the two headings are aligned within the same-direction tolerance, a's speed exceeds b's by at least the speed excess the caller sets, and either the two bodies' projections on a's heading overlap — a is drawing level with b — or b is still ahead of a in the same lane. It is the state of a passing manoeuvre at the observation and states no lane used, no clearance between the bodies, no completion of the pass and no right to make it. Not a stand-in for: a completed pass, the lane or side the pass is made on, a signal or an intention, or the clearance between the bodies, which the gap atom carries.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    the two headings are aligned within the same-direction tolerance: atoms ['rel.same_direction'], concepts []
    a's speed exceeds b's by at least the speed excess: atoms ['kin.speed'], concepts []
    the two bodies' projections on a's heading overlap: atoms ['rel.longitudinal_overlap'], concepts []
    b is still ahead of a in the same lane: atoms ['rel.ahead_behind_in_lane'], concepts []

  How each element is written:
  - "the two headings are aligned within the same-direction tolerance":
    `rel_same_direction a b` with the tolerance as the atom's own parameter, the formal
    `same_direction_tolerance`. The atom's first argument is the subject; a is the subject of the
    manoeuvre, so the pair is read in a's order.
  - "a's speed exceeds b's by at least the speed excess": the difference of the two `kin_speed`
    readings, a's less b's, at or above `min_speed_excess`. "By at least" is the weak bound, so the
    comparison is `≥`; the difference is written as a subtraction of the two measurements, so the
    clause is unknown wherever either speed is unobserved.
  - "the two bodies' projections on a's heading overlap": `rel_longitudinal_overlap a b` strictly
    above zero. The atom is the signed shared length of the two projections on a's heading,
    "negative for the gap between the projections", so a positive value is the overlap the clause
    states; a zero value is projections that merely abut, not an overlap. The strictness is the
    reading declared as a narrowing below.
  - "b is still ahead of a in the same lane": `rel_ahead_behind_in_lane b a`, the atom read in the
    order "b is ahead of a", a's lane order being the earlier part of the pass.
  The three clauses are joined as the contract joins them: the heading agreement and the speed
  excess conjoined with the disjunction of the overlap and the in-lane order.

  Readings chosen (declared as narrowings): the overlap is strictly positive.

  No magnitude below is this file's own: parameters are formals the caller fills; the only literal
  is zero metres, the origin of the signed overlap the atom returns.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.interaction.overtaking

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aA : Arg := .var "a"
def aB : Arg := .var "b"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
def pSameDirectionTolerance : Term := .param "same_direction_tolerance"
def pMinSpeedExcess : Term := .param "min_speed_excess"

/-- The headings are aligned within the tolerance the caller sets. -/
def headingsAligned : Formula := .atom "rel_same_direction" [aA, aB] [pSameDirectionTolerance]

/-- a's speed exceeds b's by at least the speed excess. -/
def gainingOnB : Formula :=
  .cmp (.sub (.measure "kin_speed" [aA]) (.measure "kin_speed" [aB])) .ge pMinSpeedExcess

/-- The two bodies' projections on a's heading overlap: a is drawing level with b. -/
def drawingLevel : Formula :=
  .cmp (.measure "rel_longitudinal_overlap" [aA, aB]) .gt (.lit (Units.metres 0) .metre)

/-- b is still ahead of a in the same lane. -/
def bAheadInLane : Formula := .atom "rel_ahead_behind_in_lane" [aB, aA] []

def body : Formula :=
  .and headingsAligned (.and gainingOnB (.or drawingLevel bAheadInLane))

def concept : Concept :=
  { id := "drv.interaction.overtaking"
    contract := "Road user a is passing road user b at the observation: the two headings are aligned within the same-direction tolerance, a's speed exceeds b's by at least the speed excess the caller sets, and either the two bodies' projections on a's heading overlap — a is drawing level with b — or b is still ahead of a in the same lane. It is the state of a passing manoeuvre at the observation and states no lane used, no clearance between the bodies, no completion of the pass and no right to make it. Not a stand-in for: a completed pass, the lane or side the pass is made on, a signal or an intention, or the clearance between the bodies, which the gap atom carries."
    definition := none
    args := [("a", .track), ("b", .track)]
    params := [⟨"same_direction_tolerance", .ratio⟩, ⟨"min_speed_excess", .metrePerSecond⟩]
    body := .formula body
    residues := []  -- the record's, verbatim; not yours to change
    narrowings :=
      [ { span := "the two bodies' projections on a's heading overlap"
          why := "read as a strictly positive shared length of the two projections: the atom is signed, zero where the projections abut and negative for the gap between them, and projections that merely touch at a point are no overlap, so the bound is strict rather than at-or-above zero."
          kind := "reading" } ]
    supersedes := none }

end TrafficSpec.Concepts.interaction.overtaking
