/-
  drv.interaction.overtaking — Road user a is overtaking road user b at the observation: the two head the same way (rel.same_direction with cosine tolerance `cos_tol`), their footprints overlap along a's heading (rel.longitudinal_overlap not negative, so the two are side by side), and a's speed (kin.speed) exceeds b's by more than `speed_tol`, a tolerance that names only the source's speed resolution. It holds at each observation of the side-by-side phase in which a gains on b, on whichever side of b a is. Not denoted: the approach from behind before the footprints overlap, or the moment a draws clear ahead; the side on which a passes, which the caller states where it matters; b gaining on a; where either road user is, which the caller states.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    the two head the same way (rel.same_direction with cosine tolerance `cos_tol`): atoms ['rel.same_direction'], concepts []
    their footprints overlap along a's heading (rel.longitudinal_overlap not negative: atoms ['rel.longitudinal_overlap'], concepts []
    a's speed (kin.speed) exceeds b's by more than `speed_tol`: atoms ['kin.speed'], concepts []

  No magnitude below is this file's own: parameters are formals the caller fills.

  Writing: "the two head the same way (rel.same_direction with cosine tolerance `cos_tol`)" is
  `rel_same_direction a b` with `cos_tol` as its tolerance parameter. "rel.longitudinal_overlap not
  negative" is `rel_longitudinal_overlap a b ≥ 0` (zero, the projections touching, counts as side by
  side, as "not negative" says). "a's speed (kin.speed) exceeds b's by more than `speed_tol`" is
  `kin_speed a − kin_speed b > speed_tol`, strict as "more than" says. The three are conjoined at
  the one observation; no time operator, no side, no region and no class is read. No narrowing:
  the contract dictates every choice.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.interaction.overtaking

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aA : Arg := .var "a"
def aB : Arg := .var "b"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
def pCosTol : Term := .param "cos_tol"
def pSpeedTol : Term := .param "speed_tol"

/-- The two head the same way within `cos_tol`. -/
def sameWay : Formula := .atom "rel_same_direction" [aA, aB] [pCosTol]

/-- The footprints' projections on a's heading share a length not negative: side by side. -/
def sideBySide : Formula :=
  .cmp (.measure "rel_longitudinal_overlap" [aA, aB]) .ge (.lit (Units.metres 0) .metre)

/-- a's speed exceeds b's by more than the resolution `speed_tol`. -/
def gaining : Formula :=
  .cmp (.sub (.measure "kin_speed" [aA]) (.measure "kin_speed" [aB])) .gt pSpeedTol

def body : Formula := .and sameWay (.and sideBySide gaining)

def concept : Concept :=
  { id := "drv.interaction.overtaking"
    contract := "Road user a is overtaking road user b at the observation: the two head the same way (rel.same_direction with cosine tolerance `cos_tol`), their footprints overlap along a's heading (rel.longitudinal_overlap not negative, so the two are side by side), and a's speed (kin.speed) exceeds b's by more than `speed_tol`, a tolerance that names only the source's speed resolution. It holds at each observation of the side-by-side phase in which a gains on b, on whichever side of b a is. Not denoted: the approach from behind before the footprints overlap, or the moment a draws clear ahead; the side on which a passes, which the caller states where it matters; b gaining on a; where either road user is, which the caller states."
    definition := none
    args := [("a", .track), ("b", .track)]
    params := [⟨"cos_tol", .ratio⟩, ⟨"speed_tol", .metrePerSecond⟩]
    body := .formula body
    residues := []  -- the record's, verbatim; not yours to change
    narrowings := []  -- one { span := "<words of the contract>", why := "<why>", kind := "reading" } per reading you chose that the contract leaves open, explained in the header
    supersedes := none }

end TrafficSpec.Concepts.interaction.overtaking
