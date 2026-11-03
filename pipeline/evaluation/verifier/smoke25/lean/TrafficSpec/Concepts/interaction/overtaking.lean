/-
  drv.interaction.overtaking — Road user u is in the act of passing road user v at this observation: u and v are distinct, the cosine of the angle between their headings is above the tolerance same_direction_cosine (the bound above which two headings count as travelling in the same direction, so headings whose cosine is exactly the bound do not count as agreeing), their bodies overlap along u's heading so that they are side by side, u's speed is greater than v's, and u lies behind v along u's heading at this observation or lay behind it at an earlier observation of the trace. The concept denotes the passing manoeuvre while the bodies are abreast and u is still gaining, whether u's reference point is still behind v's or has already drawn past it. The order of arrival is read along u's heading, between the two reference points, and not within a lane, so a pass made from a neighbouring lane, or from a line of travel the two road users never shared, is denoted as much as one begun directly behind v. The two boundaries the sampled measurements leave open are read thus: the bodies count as side by side while the length their projections on u's heading share is not below zero, so projections that exactly touch still count and the configuration ends only once they part, while u counts as behind v only where v's reference point lies strictly ahead of u's along that axis, so two reference points exactly level are not u behind v. Whether u lay behind v earlier is read from the trace alone: where the recording does not reach back to an observation showing it and u does not lie behind v at this observation, the concept is undecided rather than false. It is not a lane change on its own, not the closing of a gap behind a vehicle, not the moment after the pass is complete (once u is clear ahead the bodies no longer overlap along the heading), and not a judgement that the pass is lawful, safe or permitted.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    the cosine of the angle between their headings is above the tolerance same_direction_cosine: atoms ['rel.same_direction'], concepts []
    their bodies overlap along u's heading so that they are side by side: atoms ['rel.longitudinal_overlap'], concepts []
    u's speed is greater than v's: atoms ['kin.speed'], concepts []
    u lies behind v along u's heading at this observation or lay behind it at an earlier observation of the trace: atoms ['rel.bearing'], concepts []

  How "u and v are distinct" is written. `same u v` is the formula language's identity of two
  bound entities, so its negation is the whole of the contract's clause: a road user never passes
  itself, and the conjunct is decided at every observation, reading no source.

  How the first element is written. `rel.same_direction`, 'headings aligned: the cosine of the
  angle between the headings is above its tolerance', read of the pair with this concept's
  `same_direction_cosine` as that tolerance (`rel_same_direction [u, v] [same_direction_cosine]`).
  The atom compares the cosine strictly against the bound, which is exactly the comparison the
  contract states ("above the tolerance ... so headings whose cosine is exactly the bound do not
  count as agreeing"), so nothing of this element is left to this file. The relation keeps a
  crossing or an oncoming road user out of the concept.

  How the second element is written. `rel.longitudinal_overlap` is 'the length the two footprints'
  projections on that axis share, negative for the gap between the projections', read with u as
  the subject (`rel_longitudinal_overlap [u, v]`, a quantity in metres), and compared at or above
  zero. The contract fixes that boundary itself ("not below zero, so projections that exactly touch
  still count and the configuration ends only once they part"), so the comparison is `.ge` against
  zero and the zero is the only literal in this file. Being a projection it reads nothing across the
  axis: no contact and no clearance is claimed here.

  How the third element is written. `kin.speed`, the 'magnitude of velocity', read of each road
  user and compared strictly: u's speed above v's is "u is still gaining", which separates a pass
  under way from two road users merely running abreast. Where either speed is unobserved the
  comparison is unknown and so is the concept, which is the blind witness.

  How the fourth element is written. "u lies behind v along u's heading" is `rel.bearing`, 'direction
  of b from a in a's frame (for "on the right of", "immediately to the rear")', read for v in u's
  frame along u's heading: the atom's `ahead` attribute is that component compared strictly above
  zero, so it is true exactly where v's reference point lies strictly ahead of u's, which is the
  strict reading the contract states ("two reference points exactly level are not u behind v"). The
  axis is u's heading, the same one the abreast element reads, and no lane is read: a pass from a
  neighbouring lane, or from a line of travel never shared, is denoted as the contract says, which
  is why `rel.ahead_behind_in_lane` (ahead or behind "in the same lane") is not the atom used. "at
  this observation or lay behind it at an earlier observation of the trace" is the past operator of
  the formula language, `since tt φ`: at an observation it is φ here, or φ at some earlier
  observation of the recording, and where neither holds the unobserved past makes it unknown — which
  is the contract's "where the recording does not reach back to an observation showing it and u does
  not lie behind v at this observation, the concept is undecided rather than false". No window of a
  fixed length behind the observation is read, so a pass begun long before is denoted as much as one
  begun an instant ago.

  Narrowings (declared below). (1) The order of arrival is read through the `ahead` attribute of
  `rel.bearing` rather than by comparing the signed component with zero: they are the same
  comparison (the component strictly above zero), and the attribute carries the strictness the
  contract states without a second literal. (2) The past disjunction is written with `since tt`,
  which is reflexive — φ at this observation satisfies it — so the contract's two cases ("at this
  observation or ... at an earlier observation") are one operator and not a disjunction of two
  readings of the trace.

  No magnitude below is this file's own: parameters are formals the caller fills.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.interaction.overtaking

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aU : Arg := .var "u"
def aV : Arg := .var "v"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
def pSameDirectionCosine : Term := .param "same_direction_cosine"

/-- u and v are distinct road users: no road user passes itself. -/
def distinct : Formula := .not (.same aU aV)

/-- The cosine of the angle between the two headings is above `same_direction_cosine`: the headings
    count as travelling in the same direction, the bound itself not counting. -/
def headingsAgree : Formula := .atom "rel_same_direction" [aU, aV] [pSameDirectionCosine]

/-- The length the two footprints' projections on u's heading share, in metres: positive where the
    bodies are side by side, the gap between the projections negated where they have parted. -/
def sharedLength : Term := .measure "rel_longitudinal_overlap" [aU, aV]

/-- The bodies are side by side along u's heading: the shared length of the projections is not
    below zero, so projections that exactly touch still count. -/
def abreast : Formula := .cmp sharedLength .ge (.lit Q.zero .metre)

/-- u is still gaining: u's speed is greater than v's. -/
def gaining : Formula := .cmp (.measure "kin_speed" [aU]) .gt (.measure "kin_speed" [aV])

/-- u lies behind v along u's heading at this observation: v's reference point lies strictly ahead
    of u's along that axis, in u's frame. -/
def behindNow : Formula := .atom "rel_bearing" [aU, aV, .lit "ahead"] []

/-- u lies behind v at this observation, or lay behind it at an earlier observation of the trace;
    unknown where the recording reaches back to no observation showing it. -/
def behindNowOrEarlier : Formula := .since .tt behindNow

/-- u is in the act of passing v: the two are distinct, their headings agree, their bodies are
    abreast along u's heading, u is still gaining, and u lies or lay behind v along that axis. -/
def body : Formula :=
  .and distinct (.and headingsAgree (.and abreast (.and gaining behindNowOrEarlier)))

def concept : Concept :=
  { id := "drv.interaction.overtaking"
    contract := "Road user u is in the act of passing road user v at this observation: u and v are distinct, the cosine of the angle between their headings is above the tolerance same_direction_cosine (the bound above which two headings count as travelling in the same direction, so headings whose cosine is exactly the bound do not count as agreeing), their bodies overlap along u's heading so that they are side by side, u's speed is greater than v's, and u lies behind v along u's heading at this observation or lay behind it at an earlier observation of the trace. The concept denotes the passing manoeuvre while the bodies are abreast and u is still gaining, whether u's reference point is still behind v's or has already drawn past it. The order of arrival is read along u's heading, between the two reference points, and not within a lane, so a pass made from a neighbouring lane, or from a line of travel the two road users never shared, is denoted as much as one begun directly behind v. The two boundaries the sampled measurements leave open are read thus: the bodies count as side by side while the length their projections on u's heading share is not below zero, so projections that exactly touch still count and the configuration ends only once they part, while u counts as behind v only where v's reference point lies strictly ahead of u's along that axis, so two reference points exactly level are not u behind v. Whether u lay behind v earlier is read from the trace alone: where the recording does not reach back to an observation showing it and u does not lie behind v at this observation, the concept is undecided rather than false. It is not a lane change on its own, not the closing of a gap behind a vehicle, not the moment after the pass is complete (once u is clear ahead the bodies no longer overlap along the heading), and not a judgement that the pass is lawful, safe or permitted."
    definition := none
    args := [("u", .track), ("v", .track)]
    params := [⟨"same_direction_cosine", .ratio⟩]
    body := .formula body
    residues := []  -- the record's, verbatim; not yours to change
    narrowings :=
      [ { span := "u counts as behind v only where v's reference point lies strictly ahead of u's along that axis"
          why := "written as the `ahead` attribute of rel.bearing read for v in u's frame (`rel_bearing [u, v, \"ahead\"]`), which is the longitudinal component of that bearing compared strictly above zero, rather than as a comparison of the signed component against a zero of this file's own: the two are the same comparison on the same axis, and the attribute carries the strictness the contract states, so two reference points exactly level are decidedly not u behind v"
          kind := "reading" }
      , { span := "u lies behind v along u's heading at this observation or lay behind it at an earlier observation of the trace"
          why := "written with the formula language's past operator as `since tt (u behind v)`, which is reflexive: the condition at this observation satisfies it, so the contract's two cases are one operator over the recorded past and not two separate reads, and no window of a fixed length behind the observation is read, so a pass begun long before counts as much as one begun an instant ago. Where the condition holds at no observation the recording reaches, the operator carries the unobserved past as unknown, which is the undecidedness the contract requires rather than falsity"
          kind := "reading" } ]
    supersedes := none }

end TrafficSpec.Concepts.interaction.overtaking
