/-
  drv.interaction.overtaking_alongside — Road user x is overtaking road user y alongside at the observation: the side-by-side phase of an overtaking, on either side of y. It holds where their headings are aligned (rel.same_direction, with aligned_cosine as the relation's tolerance), their bodies overlap along x's heading (rel.longitudinal_overlap positive), and x's speed exceeds y's (kin.speed, m/s) by more than speed_margin, the speed resolution below which the two count as keeping pace. Either side of y counts. Not denoted: the approach from behind or the return ahead of y, the side on which x passes, where either body is on the road, a lane change, contact, or the clearance between the bodies.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    their headings are aligned (rel.same_direction, with aligned_cosine as the relation's tolerance): atoms ['rel.same_direction'], concepts []
    their bodies overlap along x's heading (rel.longitudinal_overlap positive): atoms ['rel.longitudinal_overlap'], concepts []
    x's speed exceeds y's (kin.speed, m/s) by more than speed_margin: atoms ['kin.speed'], concepts []

  Written: the conjunction of the three elements, at one observation.
    aligned    — `rel_same_direction x y` with tolerance `aligned_cosine`;
    alongside  — `rel_longitudinal_overlap x y > 0` (x's heading is the axis: x is the relation's
                 first argument);
    gaining    — `kin_speed x - kin_speed y > speed_margin` (strictly more than the margin, as the
                 contract says "by more than").
  "Either side of y counts": no lateral reading enters the body. No choice beyond the contract's
  words was made; no narrowing.

  No magnitude below is this file's own: parameters are formals the caller fills.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.interaction.overtaking_alongside

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aX : Arg := .var "x"
def aY : Arg := .var "y"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
def pAlignedCosine : Term := .param "aligned_cosine"
def pSpeedMargin : Term := .param "speed_margin"

/-- Their headings are aligned: `rel.same_direction` with `aligned_cosine` as its tolerance. -/
def aligned : Formula := .atom "rel_same_direction" [aX, aY] [pAlignedCosine]

/-- Their bodies overlap along x's heading: `rel.longitudinal_overlap` positive. -/
def alongside : Formula :=
  .cmp (.measure "rel_longitudinal_overlap" [aX, aY]) .gt (.lit (Units.metres 0) .metre)

/-- x's speed exceeds y's by more than `speed_margin`. -/
def gaining : Formula :=
  .cmp (.sub (.measure "kin_speed" [aX]) (.measure "kin_speed" [aY])) .gt pSpeedMargin

def body : Formula := .and aligned (.and alongside gaining)

def concept : Concept :=
  { id := "drv.interaction.overtaking_alongside"
    contract := "Road user x is overtaking road user y alongside at the observation: the side-by-side phase of an overtaking, on either side of y. It holds where their headings are aligned (rel.same_direction, with aligned_cosine as the relation's tolerance), their bodies overlap along x's heading (rel.longitudinal_overlap positive), and x's speed exceeds y's (kin.speed, m/s) by more than speed_margin, the speed resolution below which the two count as keeping pace. Either side of y counts. Not denoted: the approach from behind or the return ahead of y, the side on which x passes, where either body is on the road, a lane change, contact, or the clearance between the bodies."
    definition := none
    args := [("x", .track), ("y", .track)]
    params := [⟨"aligned_cosine", .ratio⟩, ⟨"speed_margin", .metrePerSecond⟩]
    body := .formula body
    residues := []  -- the record's, verbatim; not yours to change
    narrowings := []  -- one { span := "<words of the contract>", why := "<why>", kind := "reading" } per reading you chose that the contract leaves open, explained in the header
    supersedes := none }

end TrafficSpec.Concepts.interaction.overtaking_alongside
