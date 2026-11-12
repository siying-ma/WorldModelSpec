/-
  drv.interaction.overtakes — Road user a overtakes and passes road user b: travelling with headings aligned, a goes from wholly behind b to wholly ahead of it. The act is recognized at the observation at which a becomes wholly ahead of b, that is, at which drv.position.behind of b relative to a becomes true, provided that a was behind b (drv.position.behind of a relative to b) at an earlier observation and the headings stayed aligned (rel.same_direction with the alignment tolerance) at every observation from that one to the recognition. Its observed beginning is the last observation at which a was behind b before the recognition. The concept holds at the recognition observation only. Where the recording shows no observation of a behind b before a becomes wholly ahead of it, with the headings aligned at every observation since the recording began, whether a overtook b is unknown, never false. Not a stand-in for a lane change or for contact between the bodies; it does not say in which lane either travels.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    drv.position.behind of b relative to a becomes true: atoms [], concepts ['drv.position.behind']
    the headings stayed aligned (rel.same_direction with the alignment tolerance): atoms ['rel.same_direction'], concepts []

  No magnitude below is this file's own: parameters are formals the caller fills.

  Written as the conjunction, at one observation, of
    rises(drv_position_behind(b, a)): b behind a here and not at the previous observation — the
      observation at which a becomes wholly ahead of b; true there only, so the concept holds at the
      recognition observation only;
    since(rel_same_direction(a, b), drv_position_behind(a, b)): a behind b at some observation, and
      the headings aligned (the formal `alignment` as the cosine tolerance) at every observation after
      it up to this one. Some such observation exists exactly when the last one before the
      recognition (the observed beginning) has the headings aligned from it on, so the existential
      `since` states the contract's "last observation" condition. At the recognition a is wholly
      ahead of b, so a is not behind b there, and the observation of a behind b is an earlier one.
  History: where no observation of a behind b precedes the recognition and the headings are
  aligned at every observation since the recording began, `since` carries the unobserved past and
  is unknown (truncated), never false; `rises` at the first observation is likewise unknown.
  No lane and no contact is read. No choice was left open by the contract: no narrowing.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.interaction.overtakes

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aA : Arg := .var "a"
def aB : Arg := .var "b"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
def pAlignment : Term := .param "alignment"

/-- Headings aligned: `rel_same_direction` with the alignment tolerance. -/
def aligned : Formula := .atom "rel_same_direction" [aA, aB] [pAlignment]

/-- a behind b: drv.position.behind of a relative to b (the beginning). -/
def aBehindB : Formula := .derived "drv_position_behind" [aA, aB] [pAlignment]

/-- a wholly ahead of b: drv.position.behind of b relative to a (the recognition). -/
def bBehindA : Formula := .derived "drv_position_behind" [aB, aA] [pAlignment]

/-- The recognition: b behind a here and not at the previous observation. -/
def becomesAhead : Formula := .rises bBehindA

/-- a was behind b at some observation up to here, the headings aligned at every one since. -/
def wasBehindAligned : Formula := .since aligned aBehindB

def body : Formula := .and becomesAhead wasBehindAligned

def concept : Concept :=
  { id := "drv.interaction.overtakes"
    contract := "Road user a overtakes and passes road user b: travelling with headings aligned, a goes from wholly behind b to wholly ahead of it. The act is recognized at the observation at which a becomes wholly ahead of b, that is, at which drv.position.behind of b relative to a becomes true, provided that a was behind b (drv.position.behind of a relative to b) at an earlier observation and the headings stayed aligned (rel.same_direction with the alignment tolerance) at every observation from that one to the recognition. Its observed beginning is the last observation at which a was behind b before the recognition. The concept holds at the recognition observation only. Where the recording shows no observation of a behind b before a becomes wholly ahead of it, with the headings aligned at every observation since the recording began, whether a overtook b is unknown, never false. Not a stand-in for a lane change or for contact between the bodies; it does not say in which lane either travels."
    definition := none
    args := [("a", .track), ("b", .track)]
    params := [⟨"alignment", .ratio⟩]
    body := .formula body
    residues := []  -- the record's, verbatim; not yours to change
    narrowings := []  -- one { span := "<words of the contract>", why := "<why>", kind := "reading" } per reading you chose that the contract leaves open, explained in the header
    supersedes := none }

end TrafficSpec.Concepts.interaction.overtakes
