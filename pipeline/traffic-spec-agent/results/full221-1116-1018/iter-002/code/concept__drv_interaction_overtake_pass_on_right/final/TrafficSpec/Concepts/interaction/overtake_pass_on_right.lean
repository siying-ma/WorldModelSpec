/-
  drv.interaction.overtake_pass_on_right — Road user a overtakes and passes road user b on b's right: a overtakes and passes b from the rear, as drv.interaction.overtake_pass states it with the same window and the same heading tolerance, and makes the passage with b on its left. b is on a's left where the lateral component of b's bearing in a's frame (rel.bearing) is positive; the two are side by side where their projections on a's heading share length (rel.longitudinal_overlap at or above zero). The act begins at the last observation of the window behind at which b was ahead of a with their headings aligned within same_dir_cos. The act is recognized at the observation at which drv.interaction.overtake_pass holds for a and b, where b is on a's left there and at every observation since the act began at which the two are side by side. The concept holds at that observation only, and not again until b has again been ahead of a and then comes to be behind it. Conduct before the window behind is not read: a pass that takes longer than the window is not recognized. It denotes the relative motion of the two road users and the side on which a passes only: it says nothing of the lanes or the pavement a uses, of whether b moves, or of why a passes. Not denoted: a pass with b on a's right at the recognition or at some observation at which the two are side by side, which is a pass on b's left; a drawing alongside b that does not clear b; b ahead of a only while their headings are not aligned. Where b's bearing or the overlap of the two bodies is unobserved at an observation the passage reads, it is unknown.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    a overtakes and passes b from the rear, as drv.interaction.overtake_pass states it with the same window and the same heading tolerance: atoms [], concepts ['drv.interaction.overtake_pass']
    b is on a's left where the lateral component of b's bearing in a's frame (rel.bearing) is positive: atoms ['rel.bearing'], concepts []
    the two are side by side where their projections on a's heading share length (rel.longitudinal_overlap at or above zero): atoms ['rel.longitudinal_overlap'], concepts []

  No magnitude below is this file's own: parameters are formals the caller fills.

  UNEXPRESSED (no_atom). The recognition requires b on a's left "at every observation since the
  act began at which the two are side by side", and the act begins "at the last observation of
  the window behind at which b was ahead of a with their headings aligned within same_dir_cos".
  Locating that onset needs the alignment of the two headings at past observations. The record
  names rel.bearing (which gives ahead/behind and the side), rel.longitudinal_overlap (side by
  side) and drv.interaction.overtake_pass; that concept holds only at the recognition and exposes
  neither its onset nor the alignment, and no claimed atom denotes heading alignment
  (rel.same_direction is not claimed). Without it the onset can only be approximated: since b
  was last ahead (weaker: it misses side-by-side observations between the aligned onset and a
  later unaligned ahead observation) or since b was last behind (stronger: it also reads
  side-by-side observations before the onset). Both are readings written around a missing atom,
  so the body is not written. The plan should claim rel.same_direction (element: "with their
  headings aligned within same_dir_cos", with rel.bearing's longitudinal component and
  rel.longitudinal_overlap for "b was ahead of a"), or reword the onset in terms the claimed
  names state.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.interaction.overtake_pass_on_right

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aA : Arg := .var "a"
def aB : Arg := .var "b"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
def pWindow : Term := .param "window"
def pSameDirCos : Term := .param "same_dir_cos"

-- TODO(code): the formula, from the contract's elements, over the formals and claimed names only.
def body : Formula := .tt  -- TODO

def concept : Concept :=
  { id := "drv.interaction.overtake_pass_on_right"
    contract := "Road user a overtakes and passes road user b on b's right: a overtakes and passes b from the rear, as drv.interaction.overtake_pass states it with the same window and the same heading tolerance, and makes the passage with b on its left. b is on a's left where the lateral component of b's bearing in a's frame (rel.bearing) is positive; the two are side by side where their projections on a's heading share length (rel.longitudinal_overlap at or above zero). The act begins at the last observation of the window behind at which b was ahead of a with their headings aligned within same_dir_cos. The act is recognized at the observation at which drv.interaction.overtake_pass holds for a and b, where b is on a's left there and at every observation since the act began at which the two are side by side. The concept holds at that observation only, and not again until b has again been ahead of a and then comes to be behind it. Conduct before the window behind is not read: a pass that takes longer than the window is not recognized. It denotes the relative motion of the two road users and the side on which a passes only: it says nothing of the lanes or the pavement a uses, of whether b moves, or of why a passes. Not denoted: a pass with b on a's right at the recognition or at some observation at which the two are side by side, which is a pass on b's left; a drawing alongside b that does not clear b; b ahead of a only while their headings are not aligned. Where b's bearing or the overlap of the two bodies is unobserved at an observation the passage reads, it is unknown."
    definition := none
    args := [("a", .track), ("b", .track)]
    params := [⟨"window", .second⟩, ⟨"same_dir_cos", .ratio⟩]
    body := .formula body
    residues := []  -- the record's, verbatim; not yours to change
    narrowings :=
      [ { span := "with their headings aligned within same_dir_cos"
          why := "The onset of the act (the last observation of the window behind at which b was ahead of a with their headings aligned), from which the side-by-side observations the recognition reads are counted, needs the alignment of a's and b's headings at past observations. No name the record claims denotes it: rel.bearing gives b's direction in a's frame, rel.longitudinal_overlap the shared length of the projections, and drv.interaction.overtake_pass holds only at the recognition and exposes neither its onset nor the alignment. rel.same_direction would denote it but is not claimed; counting from the last ahead or the last behind observation instead would be an approximation, not the contract."
          kind := "no_atom" } ]
    supersedes := none }

end TrafficSpec.Concepts.interaction.overtake_pass_on_right
