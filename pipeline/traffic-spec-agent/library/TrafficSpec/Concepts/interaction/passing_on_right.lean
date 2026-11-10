/-
  drv.interaction.passing_on_right — Road user a is passing road user b on b's right at the observation: the two head the same way (rel.same_direction with cosine tolerance `cos_tol`), their footprints overlap along a's heading (rel.longitudinal_overlap not negative, so the two are side by side), b lies to a's left (the lateral component of rel.bearing from a to b is positive, left positive), and a's speed (kin.speed) exceeds b's by more than `speed_tol`, a tolerance that names only the source's speed resolution. It holds at each observation of the side-by-side phase in which a gains on b. Not denoted: the approach from behind before the footprints overlap, or the moment a draws clear ahead; a pass on b's left; b gaining on a; a lane change; where either road user is, which the caller states.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    the two head the same way (rel.same_direction with cosine tolerance `cos_tol`): atoms ['rel.same_direction'], concepts []
    their footprints overlap along a's heading (rel.longitudinal_overlap not negative: atoms ['rel.longitudinal_overlap'], concepts []
    b lies to a's left (the lateral component of rel.bearing from a to b is positive: atoms ['rel.bearing'], concepts []
    a's speed (kin.speed) exceeds b's: atoms ['kin.speed'], concepts []

  How each element is written:
    - the two head the same way: `rel_same_direction a b` with tolerance `cos_tol`.
    - their footprints overlap along a's heading, "not negative": `rel_longitudinal_overlap a b ≥ 0`
      (zero, projections that just meet, is not negative and counts).
    - b lies to a's left, lateral component of the bearing from a to b positive: the bearing atom's
      `left` selector, which is exactly that component strictly above zero.
    - a's speed exceeds b's by more than `speed_tol`: `kin_speed a > kin_speed b + speed_tol`, strict,
      since a difference at or below `speed_tol` counts as none.
  The four are conjoined at the observation; the contract leaves no reading open.

  No magnitude below is this file's own: parameters are formals the caller fills.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.interaction.passing_on_right

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aA : Arg := .var "a"
def aB : Arg := .var "b"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
def pCosTol : Term := .param "cos_tol"
def pSpeedTol : Term := .param "speed_tol"

/-- The two head the same way. -/
def sameWay : Formula := .atom "rel_same_direction" [aA, aB] [pCosTol]

/-- Their footprints overlap along a's heading: the signed overlap is not negative. -/
def sideBySide : Formula :=
  .cmp (.measure "rel_longitudinal_overlap" [aA, aB]) .ge (.lit (Units.metres 0) .metre)

/-- b lies to a's left: the lateral component of the bearing from a to b is positive. -/
def bOnLeft : Formula := .atom "rel_bearing" [aA, aB, .lit "left"] []

/-- a's speed exceeds b's by more than the speed resolution. -/
def aGains : Formula :=
  .cmp (.measure "kin_speed" [aA]) .gt (.add (.measure "kin_speed" [aB]) pSpeedTol)

def body : Formula := .and sameWay (.and sideBySide (.and bOnLeft aGains))

def concept : Concept :=
  { id := "drv.interaction.passing_on_right"
    contract := "Road user a is passing road user b on b's right at the observation: the two head the same way (rel.same_direction with cosine tolerance `cos_tol`), their footprints overlap along a's heading (rel.longitudinal_overlap not negative, so the two are side by side), b lies to a's left (the lateral component of rel.bearing from a to b is positive, left positive), and a's speed (kin.speed) exceeds b's by more than `speed_tol`, a tolerance that names only the source's speed resolution. It holds at each observation of the side-by-side phase in which a gains on b. Not denoted: the approach from behind before the footprints overlap, or the moment a draws clear ahead; a pass on b's left; b gaining on a; a lane change; where either road user is, which the caller states."
    definition := none
    args := [("a", .track), ("b", .track)]
    params := [⟨"cos_tol", .ratio⟩, ⟨"speed_tol", .metrePerSecond⟩]
    body := .formula body
    residues := []  -- the record's, verbatim; not yours to change
    narrowings := []  -- one { span := "<words of the contract>", why := "<why>", kind := "reading" } per reading you chose that the contract leaves open, explained in the header
    supersedes := none }

end TrafficSpec.Concepts.interaction.passing_on_right
