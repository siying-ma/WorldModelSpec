/-
  drv.interaction.overtake_pass_on_right — Road user a overtakes and passes road user b on b's right: a overtakes and passes b from the rear, as drv.interaction.overtake_pass states it with the same window and the same heading tolerance, and makes the passage with b on its left. b is on a's left where the lateral component of b's bearing in a's frame (rel.bearing) is positive; the two are side by side where their projections on a's heading share length (rel.longitudinal_overlap at or above zero). b is ahead of a where the longitudinal component, along a's heading (kin.heading), of the vector from a's position to b's position (kin.position) is positive and the two bodies' projections on a's heading share no length (rel.longitudinal_overlap negative); their headings are aligned where the cosine of the angle between them is above same_dir_cos (rel.same_direction). The act begins at the last observation of the window behind at which b was ahead of a with their headings aligned within same_dir_cos. The act is recognized at the observation at which drv.interaction.overtake_pass holds for a and b, where b is on a's left there and at every observation since the act began at which the two are side by side. The concept holds at that observation only, and not again until b has again been ahead of a and then comes to be behind it. Conduct before the window behind is not read: a pass that takes longer than the window is not recognized. It denotes the relative motion of the two road users and the side on which a passes only: it says nothing of the lanes or the pavement a uses, of whether b moves, or of why a passes. Not denoted: a pass with b on a's right at the recognition or at some observation at which the two are side by side, which is a pass on b's left; a drawing alongside b that does not clear b; b ahead of a only while their headings are not aligned. Where b's bearing, the positions or headings of a and b, or the overlap of the two bodies is unobserved at an observation the passage reads, it is unknown.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    a overtakes and passes b from the rear, as drv.interaction.overtake_pass states it with the same window and the same heading tolerance: atoms [], concepts ['drv.interaction.overtake_pass']
    b is on a's left where the lateral component of b's bearing in a's frame (rel.bearing) is positive: atoms ['rel.bearing'], concepts []
    the two are side by side where their projections on a's heading share length (rel.longitudinal_overlap at or above zero): atoms ['rel.longitudinal_overlap'], concepts []
    b is ahead of a where the longitudinal component, along a's heading (kin.heading), of the vector from a's position to b's position (kin.position) is positive and the two bodies' projections on a's heading share no length (rel.longitudinal_overlap negative): atoms ['kin.heading', 'kin.position', 'rel.longitudinal_overlap'], concepts []
    their headings are aligned where the cosine of the angle between them is above same_dir_cos (rel.same_direction): atoms ['rel.same_direction'], concepts []

  No magnitude below is this file's own: parameters are formals the caller fills.

  How the contract is written:
    - "a overtakes and passes b from the rear, as drv.interaction.overtake_pass states it with the
      same window and the same heading tolerance": `.derived "drv_interaction_overtake_pass" [a, b]
      [window, same_dir_cos]`; it carries the recognition instant, the onset within the window,
      the extent (holds once, not again until b is again ahead and then behind) and the history.
    - b on a's left: `rel_bearing a b "left"` (lateral component of the bearing positive).
    - side by side: `rel_longitudinal_overlap a b ≥ 0`.
    - b ahead of a: `lon > 0 ∧ overlap < 0`, `lon` the dot product of a's heading (`kin_heading`,
      read normalised) with b's position minus a's position (`kin_position`), as overtake_pass
      reads it; headings aligned: `rel_same_direction a b [same_dir_cos]`.
    - "b is on a's left there": `onLeft` at the judged observation.
    - "and at every observation since the act began at which the two are side by side":
      `since (sideBySide → onLeft) aheadAligned`. `since` is ψ ∨ (φ ∧ since at the previous
      observation), so it reaches back to the latest observation at which b was ahead with headings
      aligned — the onset, which overtake_pass requires to lie in the window behind — and requires
      the side at every side-by-side observation after it up to the judged one.
  No narrowing: every choice above is the contract's own words.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.interaction.overtake_pass_on_right

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aA : Arg := .var "a"
def aB : Arg := .var "b"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
def pWindow : Term := .param "window"
def pSameDirCos : Term := .param "same_dir_cos"

/-- Zero, the sign threshold of the components and of the overlap. -/
def zero : Term := .lit Q.zero .metre

def pos (x : Arg) (c : String) : Term := .measure "kin_position" [x, .lit c]
def hdg (x : Arg) (c : String) : Term := .measure "kin_heading" [x, .lit c]

/-- The longitudinal component, along a's heading (kin.heading), of the vector from a's position
    to b's position (kin.position). -/
def lon : Term :=
  .add (.mul (hdg aA "x") (.sub (pos aB "x") (pos aA "x")))
       (.mul (hdg aA "y") (.sub (pos aB "y") (pos aA "y")))

/-- The shared length of the two bodies' projections on a's heading. -/
def overlap : Term := .measure "rel_longitudinal_overlap" [aA, aB]

/-- b ahead of a: longitudinal component positive, projections sharing no length. -/
def ahead : Formula := .and (.cmp lon .gt zero) (.cmp overlap .lt zero)

/-- Headings aligned within same_dir_cos (rel.same_direction). -/
def aligned : Formula := .atom "rel_same_direction" [aA, aB] [pSameDirCos]

/-- b ahead of a with their headings aligned: the observation at which the act begins is the last
    such one. -/
def aheadAligned : Formula := .and ahead aligned

/-- The two side by side: the projections on a's heading share length (overlap at or above zero). -/
def sideBySide : Formula := .cmp overlap .ge zero

/-- b on a's left: the lateral component of b's bearing in a's frame is positive. -/
def onLeft : Formula := .atom "rel_bearing" [aA, aB, .lit "left"] []

/-- b on a's left at every observation since the act began at which the two are side by side. -/
def leftWhileAlongside : Formula := .since (.implies sideBySide onLeft) aheadAligned

/-- drv.interaction.overtake_pass holds for a and b (same window, same tolerance), with b on a's
    left there and at every side-by-side observation since the act began. -/
def body : Formula :=
  .and (.derived "drv_interaction_overtake_pass" [aA, aB] [pWindow, pSameDirCos])
    (.and onLeft leftWhileAlongside)

def concept : Concept :=
  { id := "drv.interaction.overtake_pass_on_right"
    contract := "Road user a overtakes and passes road user b on b's right: a overtakes and passes b from the rear, as drv.interaction.overtake_pass states it with the same window and the same heading tolerance, and makes the passage with b on its left. b is on a's left where the lateral component of b's bearing in a's frame (rel.bearing) is positive; the two are side by side where their projections on a's heading share length (rel.longitudinal_overlap at or above zero). b is ahead of a where the longitudinal component, along a's heading (kin.heading), of the vector from a's position to b's position (kin.position) is positive and the two bodies' projections on a's heading share no length (rel.longitudinal_overlap negative); their headings are aligned where the cosine of the angle between them is above same_dir_cos (rel.same_direction). The act begins at the last observation of the window behind at which b was ahead of a with their headings aligned within same_dir_cos. The act is recognized at the observation at which drv.interaction.overtake_pass holds for a and b, where b is on a's left there and at every observation since the act began at which the two are side by side. The concept holds at that observation only, and not again until b has again been ahead of a and then comes to be behind it. Conduct before the window behind is not read: a pass that takes longer than the window is not recognized. It denotes the relative motion of the two road users and the side on which a passes only: it says nothing of the lanes or the pavement a uses, of whether b moves, or of why a passes. Not denoted: a pass with b on a's right at the recognition or at some observation at which the two are side by side, which is a pass on b's left; a drawing alongside b that does not clear b; b ahead of a only while their headings are not aligned. Where b's bearing, the positions or headings of a and b, or the overlap of the two bodies is unobserved at an observation the passage reads, it is unknown."
    definition := none
    args := [("a", .track), ("b", .track)]
    params := [⟨"window", .second⟩, ⟨"same_dir_cos", .ratio⟩]
    body := .formula body
    residues := []  -- the record's, verbatim; not yours to change
    narrowings := []  -- one { span := "<words of the contract>", why := "<why>", kind := "reading" } per reading you chose that the contract leaves open, explained in the header
    supersedes := none }

end TrafficSpec.Concepts.interaction.overtake_pass_on_right
