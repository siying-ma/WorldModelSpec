/-
  drv.interaction.overtake_pass — Road user a overtakes and passes road user b from the rear: a, travelling in the same direction as b, comes from having b ahead of it to having b behind it. b is ahead of a where the longitudinal component of b's bearing in a's frame (rel.bearing) is positive and the two bodies' projections on a's heading share no length (rel.longitudinal_overlap negative); b is behind a where that component is negative and the projections share no length. The act begins at the last observation of the window behind at which b was ahead of a with their headings aligned within same_dir_cos (rel.same_direction). The act is recognized at the observation at which b is behind a and was not behind a at the previous observation, where b was ahead of a with headings aligned at some observation of the window behind. The concept holds at that observation only, and not again until b has again been ahead of a and then comes to be behind it. Conduct before the window behind is not read: a pass that takes longer than the window is not recognized. It denotes the relative motion of the two road users only: it says nothing of the lanes they occupy, of whether b moves, or of why a passes. Not denoted: a drawing alongside b that does not clear b; b ahead of a only while their headings are not aligned (a road user met head-on or crossing); b behind a at every observation of the window.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    the longitudinal component of b's bearing in a's frame (rel.bearing): atoms ['rel.bearing'], concepts []
    the two bodies' projections on a's heading share no length (rel.longitudinal_overlap negative): atoms ['rel.longitudinal_overlap'], concepts []
    with their headings aligned within same_dir_cos (rel.same_direction): atoms ['rel.same_direction'], concepts []

  No magnitude below is this file's own: parameters are formals the caller fills.

  How the words are written:
    - "b is ahead of a": `rel_bearing a b "ahead"` (longitudinal component > 0) and
      `rel_longitudinal_overlap a b < 0`; "b is behind a": `rel_bearing a b "behind"` (< 0) and the
      same overlap condition. Zero is the only literal.
    - "with their headings aligned within same_dir_cos": `rel_same_direction a b [same_dir_cos]`,
      conjoined with "b ahead of a" at the same observation.
    - "The act begins at the last observation of the window behind at which b was ahead of a with
      their headings aligned" / "at some observation of the window behind": `atLast .time window`
      with that condition as its search and `tt` as what it asks there: true exactly where such an
      observation lies in the window (time window, the parameter's unit being seconds).
    - "b is behind a and was not behind a at the previous observation" together with "not again
      until b has again been ahead of a and then comes to be behind it": b behind here, and at the
      previous observation `since (¬ behind) aheadAligned` held (b not behind at any observation
      since the last one at which it was ahead with headings aligned). The formula language has no
      previous-observation operator; `rises (¬ S)` at an observation where `S` is false (b behind
      and not ahead) is exactly `S` at the previous one. `S` at the previous observation implies b
      not behind there, so the edge of "behind" is included.
  No reading was chosen beyond the contract's words: no narrowing.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.interaction.overtake_pass

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aA : Arg := .var "a"
def aB : Arg := .var "b"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
def pWindow : Term := .param "window"
def pSameDirCos : Term := .param "same_dir_cos"

/-- The two bodies' projections on a's heading share no length: `rel_longitudinal_overlap` negative. -/
def clear : Formula :=
  .cmp (.measure "rel_longitudinal_overlap" [aA, aB]) .lt (.lit Q.zero .metre)

/-- b ahead of a: the longitudinal component of b's bearing in a's frame positive
    (`rel_bearing … "ahead"`), and the projections sharing no length. -/
def bAhead : Formula := .and (.atom "rel_bearing" [aA, aB, .lit "ahead"] []) clear

/-- b behind a: that component negative (`rel_bearing … "behind"`), and the projections sharing
    no length. -/
def bBehind : Formula := .and (.atom "rel_bearing" [aA, aB, .lit "behind"] []) clear

/-- b ahead of a with their headings aligned within `same_dir_cos`: an observation at which the
    act may begin. -/
def aheadAligned : Formula :=
  .and bAhead (.atom "rel_same_direction" [aA, aB] [pSameDirCos])

/-- Since the latest observation at which b was ahead of a with headings aligned, b has not been
    behind a (that observation included, where b is ahead and so not behind). -/
def notBehindSinceAhead : Formula := .since (.not bBehind) aheadAligned

/-- Recognition: b behind a here; at the previous observation b had not been behind a since it was
    last ahead of a with headings aligned (written as the rise of the negation of
    `notBehindSinceAhead`, which is false here because b is behind and not ahead: so the rise says
    it held at the previous observation — this also gives "b was not behind a at the previous
    observation", and "not again until b has again been ahead of a and then comes to be behind
    it"); and the last observation of the window behind at which b was ahead of a with headings
    aligned — the onset — lies in the window (`atLast`, false where there is none in a covered
    window: a pass longer than the window is not recognized). -/
def body : Formula :=
  .and bBehind
    (.and (.rises (.not notBehindSinceAhead))
      (.atLast .time pWindow "a" aheadAligned .tt))

def concept : Concept :=
  { id := "drv.interaction.overtake_pass"
    contract := "Road user a overtakes and passes road user b from the rear: a, travelling in the same direction as b, comes from having b ahead of it to having b behind it. b is ahead of a where the longitudinal component of b's bearing in a's frame (rel.bearing) is positive and the two bodies' projections on a's heading share no length (rel.longitudinal_overlap negative); b is behind a where that component is negative and the projections share no length. The act begins at the last observation of the window behind at which b was ahead of a with their headings aligned within same_dir_cos (rel.same_direction). The act is recognized at the observation at which b is behind a and was not behind a at the previous observation, where b was ahead of a with headings aligned at some observation of the window behind. The concept holds at that observation only, and not again until b has again been ahead of a and then comes to be behind it. Conduct before the window behind is not read: a pass that takes longer than the window is not recognized. It denotes the relative motion of the two road users only: it says nothing of the lanes they occupy, of whether b moves, or of why a passes. Not denoted: a drawing alongside b that does not clear b; b ahead of a only while their headings are not aligned (a road user met head-on or crossing); b behind a at every observation of the window."
    definition := none
    args := [("a", .track), ("b", .track)]
    params := [⟨"window", .second⟩, ⟨"same_dir_cos", .ratio⟩]
    body := .formula body
    residues := []  -- the record's, verbatim; not yours to change
    narrowings := []  -- one { span := "<words of the contract>", why := "<why>", kind := "reading" } per reading you chose that the contract leaves open, explained in the header
    supersedes := none }

end TrafficSpec.Concepts.interaction.overtake_pass
