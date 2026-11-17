/-
  drv.interaction.overtake_pass — Road user a overtakes and passes road user b from the rear: a, travelling in the same direction as b, comes from having b ahead of it to having b behind it. b is ahead of a where the longitudinal component of b's bearing in a's frame, the component along a's heading (kin.heading) of the vector from a's position to b's position (kin.position), is positive and the two bodies' projections on a's heading share no length (rel.longitudinal_overlap negative); b is behind a where that component is negative and the projections share no length. The act begins at the last observation of the window behind at which b was ahead of a with their headings aligned within same_dir_cos (rel.same_direction). The act is recognized at the observation at which b is behind a and was not behind a at the previous observation, where b was ahead of a with headings aligned at some observation of the window behind. The concept holds at that observation only, and not again until b has again been ahead of a and then comes to be behind it. Conduct before the window behind is not read: a pass that takes longer than the window is not recognized. It denotes the relative motion of the two road users only: it says nothing of the lanes they occupy, of whether b moves, or of why a passes. Not denoted: a drawing alongside b that does not clear b; b ahead of a only while their headings are not aligned (a road user met head-on or crossing); b behind a at every observation of the window. Where the positions of a and b are unobserved, it is unknown.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    the component along a's heading (kin.heading) of the vector from a's position to b's position (kin.position): atoms ['kin.heading', 'kin.position'], concepts []
    the two bodies' projections on a's heading share no length (rel.longitudinal_overlap negative): atoms ['rel.longitudinal_overlap'], concepts []
    with their headings aligned within same_dir_cos (rel.same_direction): atoms ['rel.same_direction'], concepts []

  No magnitude below is this file's own: parameters are formals the caller fills.

  How the contract is written:
    - the longitudinal component of b's bearing in a's frame: `lon`, the dot product of a's
      heading (`kin_heading a x/y`, read normalised) with b's position minus a's position
      (`kin_position`); only its sign is read, against zero. Unobserved positions leave it unknown.
    - the projections share no length: `rel_longitudinal_overlap a b < 0`.
    - b ahead of a: `lon > 0 ∧ overlap < 0`; b behind a: `lon < 0 ∧ overlap < 0`.
    - headings aligned within same_dir_cos: `rel_same_direction a b [same_dir_cos]`;
      `aheadAligned` is b ahead of a with headings aligned.
    - "b was ahead of a with headings aligned at some observation of the window behind", whose
      last such observation is the onset: `atLast .time window aheadAligned tt` — true where
      aheadAligned held at some observation of the window, false where it held at none of a
      covered window; conduct before the window is not read.
    - recognition: `rises behind` — b behind a here and not at the previous observation.
    - "not again until b has again been ahead of a and then comes to be behind it": `pending`
      is `since (¬ behind) aheadAligned` (b has been ahead with headings aligned, and not behind
      at any observation since); the concept requires it at the previous observation, written
      `rises (¬ pending)`: at an observation where b is behind, pending is false, so the rise is
      exactly pending at the previous one. A second coming-behind without b ahead between (b
      falls alongside again and then behind again) is therefore not recognized.
  No narrowing: every choice above is the contract's own words.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.interaction.overtake_pass

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aA : Arg := .var "a"
def aB : Arg := .var "b"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
def pWindow : Term := .param "window"
def pSameDirCos : Term := .param "same_dir_cos"

/-- Zero, the sign threshold of the longitudinal component and of the overlap. -/
def zero : Term := .lit Q.zero .metre

def pos (x : Arg) (c : String) : Term := .measure "kin_position" [x, .lit c]
def hdg (x : Arg) (c : String) : Term := .measure "kin_heading" [x, .lit c]

/-- The component along a's heading (kin.heading) of the vector from a's position to b's
    position (kin.position). -/
def lon : Term :=
  .add (.mul (hdg aA "x") (.sub (pos aB "x") (pos aA "x")))
       (.mul (hdg aA "y") (.sub (pos aB "y") (pos aA "y")))

/-- The two bodies' projections on a's heading share no length (rel.longitudinal_overlap negative). -/
def apart : Formula := .cmp (.measure "rel_longitudinal_overlap" [aA, aB]) .lt zero

/-- b is ahead of a. -/
def ahead : Formula := .and (.cmp lon .gt zero) apart

/-- b is behind a. -/
def behind : Formula := .and (.cmp lon .lt zero) apart

/-- Headings aligned within same_dir_cos (rel.same_direction). -/
def aligned : Formula := .atom "rel_same_direction" [aA, aB] [pSameDirCos]

/-- b ahead of a with their headings aligned. -/
def aheadAligned : Formula := .and ahead aligned

/-- b has been ahead of a with headings aligned, and not behind it at any observation since. -/
def pending : Formula := .since (.not behind) aheadAligned

/-- b was ahead of a with headings aligned at some observation of the window behind (the last
    such observation is the onset). -/
def onsetInWindow : Formula := .atLast .time pWindow "a" aheadAligned .tt

/-- Recognized where b comes to be behind a, b having been ahead of it with headings aligned and
    not behind it since (pending at the previous observation), within the window behind. -/
def body : Formula :=
  .and (.rises behind)
    (.and (.rises (.not pending)) onsetInWindow)

def concept : Concept :=
  { id := "drv.interaction.overtake_pass"
    contract := "Road user a overtakes and passes road user b from the rear: a, travelling in the same direction as b, comes from having b ahead of it to having b behind it. b is ahead of a where the longitudinal component of b's bearing in a's frame, the component along a's heading (kin.heading) of the vector from a's position to b's position (kin.position), is positive and the two bodies' projections on a's heading share no length (rel.longitudinal_overlap negative); b is behind a where that component is negative and the projections share no length. The act begins at the last observation of the window behind at which b was ahead of a with their headings aligned within same_dir_cos (rel.same_direction). The act is recognized at the observation at which b is behind a and was not behind a at the previous observation, where b was ahead of a with headings aligned at some observation of the window behind. The concept holds at that observation only, and not again until b has again been ahead of a and then comes to be behind it. Conduct before the window behind is not read: a pass that takes longer than the window is not recognized. It denotes the relative motion of the two road users only: it says nothing of the lanes they occupy, of whether b moves, or of why a passes. Not denoted: a drawing alongside b that does not clear b; b ahead of a only while their headings are not aligned (a road user met head-on or crossing); b behind a at every observation of the window. Where the positions of a and b are unobserved, it is unknown."
    definition := none
    args := [("a", .track), ("b", .track)]
    params := [⟨"window", .second⟩, ⟨"same_dir_cos", .ratio⟩]
    body := .formula body
    residues := []  -- the record's, verbatim; not yours to change
    narrowings := []  -- one { span := "<words of the contract>", why := "<why>", kind := "reading" } per reading you chose that the contract leaves open, explained in the header
    supersedes := none }

end TrafficSpec.Concepts.interaction.overtake_pass
