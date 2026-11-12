/-
  drv.interaction.overtakes — Road user a overtakes and passes road user b: travelling with headings aligned, a goes from wholly behind b to wholly ahead of it. a is wholly behind b at an observation where drv.position.behind of a relative to b holds and drv.position.behind of b relative to a does not; a is wholly ahead of b where drv.position.behind of b relative to a holds and drv.position.behind of a relative to b does not. Where both hold, as headings that are aligned but not parallel allow for bodies apart sideways, a is neither wholly behind nor wholly ahead of b. The act is recognized at the observation at which a becomes wholly ahead of b, provided that a was wholly behind b at an earlier observation and the headings stayed aligned (rel.same_direction with the alignment tolerance) at every observation from that one to the recognition. Its observed beginning is the last observation at which a was wholly behind b before the recognition. The concept holds at the recognition observation only. Where the recording shows no observation of a wholly behind b before a becomes wholly ahead of it, with the headings aligned at every observation since the recording began, whether a overtook b is unknown, never false. Not a stand-in for a lane change or for contact between the bodies; it does not say in which lane either travels.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    drv.position.behind of a relative to b holds and drv.position.behind of b relative to a does not: atoms [], concepts ['drv.position.behind']
    drv.position.behind of b relative to a holds and drv.position.behind of a relative to b does not: atoms [], concepts ['drv.position.behind']
    the headings stayed aligned (rel.same_direction with the alignment tolerance): atoms ['rel.same_direction'], concepts []

  The body is the conjunction, at the observation judged, of two parts. The first is the rising
  edge of "a wholly ahead of b" (drv.position.behind(b, a) and not drv.position.behind(a, b)):
  wholly ahead here and not at the observation before, the observation at which a becomes wholly
  ahead, so the concept holds at the recognition observation only. The second is
  since(rel.same_direction(a, b), wholly behind), with "a wholly behind b" written as
  drv.position.behind(a, b) and not drv.position.behind(b, a): some observation j at or before the
  one judged has a wholly behind b, and the headings are aligned at every observation after j up to
  and including the recognition; at j itself they are aligned because drv.position.behind reads
  rel.same_direction. Wholly behind and wholly ahead exclude each other, so j lies strictly before
  the recognition; the latest such j is the observed beginning. Where no observation of a wholly
  behind b precedes the recognition and the headings are aligned at every observation since the
  recording began, `since` reaches the trace start and is unknown (its unobserved past), so the
  concept is unknown, never false. No choice beyond the contract's words was made.

  No magnitude below is this file's own: parameters are formals the caller fills.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.interaction.overtakes

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aA : Arg := .var "a"
def aB : Arg := .var "b"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
def pAlignment : Term := .param "alignment"

/-- drv.position.behind of a relative to b (with the alignment tolerance). -/
def aBehindB : Formula := .derived "drv_position_behind" [aA, aB] [pAlignment]

/-- drv.position.behind of b relative to a (with the alignment tolerance). -/
def bBehindA : Formula := .derived "drv_position_behind" [aB, aA] [pAlignment]

/-- a is wholly behind b: a behind b and b not behind a. -/
def whollyBehind : Formula := .and aBehindB (.not bBehindA)

/-- a is wholly ahead of b: b behind a and a not behind b. -/
def whollyAhead : Formula := .and bBehindA (.not aBehindB)

/-- The headings aligned (rel.same_direction with the alignment tolerance). -/
def aligned : Formula := .atom "rel_same_direction" [aA, aB] [pAlignment]

/-- a becomes wholly ahead of b here, having been wholly behind it at an earlier observation with
    the headings aligned at every observation since: the recognition observation. -/
def body : Formula :=
  .and (.rises whollyAhead) (.since aligned whollyBehind)

def concept : Concept :=
  { id := "drv.interaction.overtakes"
    contract := "Road user a overtakes and passes road user b: travelling with headings aligned, a goes from wholly behind b to wholly ahead of it. a is wholly behind b at an observation where drv.position.behind of a relative to b holds and drv.position.behind of b relative to a does not; a is wholly ahead of b where drv.position.behind of b relative to a holds and drv.position.behind of a relative to b does not. Where both hold, as headings that are aligned but not parallel allow for bodies apart sideways, a is neither wholly behind nor wholly ahead of b. The act is recognized at the observation at which a becomes wholly ahead of b, provided that a was wholly behind b at an earlier observation and the headings stayed aligned (rel.same_direction with the alignment tolerance) at every observation from that one to the recognition. Its observed beginning is the last observation at which a was wholly behind b before the recognition. The concept holds at the recognition observation only. Where the recording shows no observation of a wholly behind b before a becomes wholly ahead of it, with the headings aligned at every observation since the recording began, whether a overtook b is unknown, never false. Not a stand-in for a lane change or for contact between the bodies; it does not say in which lane either travels."
    definition := none
    args := [("a", .track), ("b", .track)]
    params := [⟨"alignment", .ratio⟩]
    body := .formula body
    residues := []  -- the record's, verbatim; not yours to change
    narrowings := []  -- one { span := "<words of the contract>", why := "<why>", kind := "reading" } per reading you chose that the contract leaves open, explained in the header
    supersedes := none }

end TrafficSpec.Concepts.interaction.overtakes
