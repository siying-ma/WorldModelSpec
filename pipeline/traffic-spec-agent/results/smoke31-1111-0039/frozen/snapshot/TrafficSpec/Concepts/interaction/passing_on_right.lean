/-
  drv.interaction.passing_on_right — Road user x is passing road user y on y's right at the observation: the side-by-side phase of an overtaking. It holds where their headings are aligned (rel.same_direction, with aligned_cosine as the relation's tolerance), their bodies overlap along x's heading (rel.longitudinal_overlap positive), y lies on x's left (the lateral component of rel.bearing of y from x, in x's frame), and x's speed exceeds y's (kin.speed, m/s) by more than speed_margin, the speed resolution below which the two count as keeping pace. Not denoted: the approach from behind or the return ahead of y, where either body is on the road, a lane change, contact, or the clearance between the bodies.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    their headings are aligned (rel.same_direction, with aligned_cosine as the relation's tolerance): atoms ['rel.same_direction'], concepts []
    their bodies overlap along x's heading (rel.longitudinal_overlap positive): atoms ['rel.longitudinal_overlap'], concepts []
    y lies on x's left (the lateral component of rel.bearing of y from x, in x's frame): atoms ['rel.bearing'], concepts []
    x's speed exceeds y's (kin.speed, m/s) by more than speed_margin: atoms ['kin.speed'], concepts []

  Written as the conjunction of the four elements, at the one observation:
    aligned      `rel_same_direction x y` with tolerance `aligned_cosine`;
    overlapping  `rel_longitudinal_overlap x y > 0` (the zero is the contract's "positive");
    yOnLeft      `rel_bearing x y "left"` — the Boolean reading of the bearing's lateral component,
                 positive to x's left;
    gaining      `kin_speed x - kin_speed y > speed_margin` ("by more than": strict).
  No choice beyond the contract's words was needed: no narrowing.

  No magnitude below is this file's own: parameters are formals the caller fills.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.interaction.passing_on_right

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aX : Arg := .var "x"
def aY : Arg := .var "y"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
def pAlignedCosine : Term := .param "aligned_cosine"
def pSpeedMargin : Term := .param "speed_margin"

/-- Headings aligned: `rel_same_direction` with `aligned_cosine` as its cosine tolerance. -/
def aligned : Formula := .atom "rel_same_direction" [aX, aY] [pAlignedCosine]

/-- The bodies overlap along x's heading: the shared length of the projections is positive. -/
def overlapping : Formula :=
  .cmp (.measure "rel_longitudinal_overlap" [aX, aY]) .gt (.lit (Units.metres 0) .metre)

/-- y on x's left: the lateral component of y's bearing from x, in x's frame, is positive. -/
def yOnLeft : Formula := .atom "rel_bearing" [aX, aY, .lit "left"] []

/-- x's speed exceeds y's by more than `speed_margin`. -/
def gaining : Formula :=
  .cmp (.sub (.measure "kin_speed" [aX]) (.measure "kin_speed" [aY])) .gt pSpeedMargin

def body : Formula := .and aligned (.and overlapping (.and yOnLeft gaining))

def concept : Concept :=
  { id := "drv.interaction.passing_on_right"
    contract := "Road user x is passing road user y on y's right at the observation: the side-by-side phase of an overtaking. It holds where their headings are aligned (rel.same_direction, with aligned_cosine as the relation's tolerance), their bodies overlap along x's heading (rel.longitudinal_overlap positive), y lies on x's left (the lateral component of rel.bearing of y from x, in x's frame), and x's speed exceeds y's (kin.speed, m/s) by more than speed_margin, the speed resolution below which the two count as keeping pace. Not denoted: the approach from behind or the return ahead of y, where either body is on the road, a lane change, contact, or the clearance between the bodies."
    definition := none
    args := [("x", .track), ("y", .track)]
    params := [⟨"aligned_cosine", .ratio⟩, ⟨"speed_margin", .metrePerSecond⟩]
    body := .formula body
    residues := []  -- the record's, verbatim; not yours to change
    narrowings := []  -- one { span := "<words of the contract>", why := "<why>", kind := "reading" } per reading you chose that the contract leaves open, explained in the header
    supersedes := none }

end TrafficSpec.Concepts.interaction.passing_on_right
