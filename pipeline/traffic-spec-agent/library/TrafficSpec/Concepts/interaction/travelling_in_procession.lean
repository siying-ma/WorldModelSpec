/-
  drv.interaction.travelling_in_procession — At this observation the road user travels in a close succession of road users on one line of travel: there is another road user it follows in its own line of travel whose body lies within the maximum succession gap ahead of it, and that has held at every observation of the window behind. The gap read is the longitudinal component, along the road user's heading, of the distance between the nearest points of the two bodies; the maximum succession gap is the largest such gap at which successive road users are still read as travelling in one line, and the window is the time over which the succession must have held for it to be read as travel together rather than one body momentarily catching another. Both, with the alignment and motion tolerances the following relation needs, are the concept's own magnitudes, since gaps, headings and speeds are observed over sampled measurements only within bounds the caller sets. The concept denotes travel in close succession only: it is not the number of road users in the line, not their organization, purpose or destination, not any permit or escort, not the adequacy of the gaps between them, and not the lawfulness of the travel.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    there is another road user it follows in its own line of travel: atoms [], concepts ['drv.interaction.following_vehicle_ahead']
      written `.existsUser "v" (.and (.not (.same aU aV)) …)` with
      `.derived "drv_interaction_following_vehicle_ahead" [aU, aV] [pAlignmentTolerance,
      pMotionSpeedTolerance]`: the following relation is the co-proposed concept, whose contract is
      "the second is ahead of the first in the same lane along that lane's direction, their
      headings are aligned … and the first road user is in motion". It is called with the road user
      this concept takes in the first position (the one that follows) and the quantified road user
      in the second (the one ahead), and this concept's `alignment_tolerance` and
      `motion_speed_tolerance` are passed through unchanged, so the figures stay the caller's. The
      lane is the called concept's own — it reads the lane the two share — so this concept
      quantifies over no region and takes none. "another" is the distinctness test
      `.not (.same aU aV)`, and "there is" is the existential over the scene's road users.
    The gap read is the longitudinal component, along the road user's heading, of the distance between the nearest points of the two bodies: atoms ['rel.surface_gap'], concepts []
      written `.cmp (.measure "rel_surface_gap" [aU, aV, .lit "longitudinal"]) .le
      pProcessionGapMax`: rel.surface_gap is the "distance between the nearest points of two
      bodies, each body's footprint read with its own heading and extent … its longitudinal and
      lateral components are the lengths of the vector between those nearest points along and
      across the subject's heading", and the component selected is `longitudinal`, the one the
      contract names. The subject — the body whose heading the component is read along — is the
      road user this concept takes, so it stands in the first argument position and the road user
      ahead in the second. rel.centre_distance is not read: its own contract excludes it as a
      stand-in for a clearance between bodies.

  Narrowings (choices the contract did not dictate):
    "whose body lies within the maximum succession gap ahead of it" — the bound is written `.le`,
      the gap at the maximum included, because the parameter is "the largest such gap at which
      successive road users are still read as travelling in one line": a reading exactly at it is
      still read as one line. That the body lies *ahead* is not a second reading of the gap: the
      called concept already decides the order in the lane, and rel.surface_gap's components are
      distances, never signed.
    "and that has held at every observation of the window behind" — the whole of the first element
      and the gap bound together lie under one `.holdsFor .time pProcessionWindow "u" …`, which is
      the value at every observation of the window behind, this observation included, so nothing is
      asserted twice. The window is measured in time, not in path length, because the parameter is
      a time in seconds.
    the road user ahead is quantified inside the window rather than fixed across it: the contract
      asks only that at each observation there be another road user followed within the gap, so a
      line of travel in which the road user ahead changes (one pulls out, the next closes up) still
      reads as one close succession.
    nothing else is required: the number of road users in the line, their organization, purpose or
      destination, any permit or escort, the adequacy of the gaps and the lawfulness of the travel
      are each excluded by the contract and no name reads them here.

  No magnitude below is this file's own: parameters are formals the caller fills.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.interaction.travelling_in_procession

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aU : Arg := .var "u"

/-- The road user ahead: no formal, but the variable the body quantifies over. -/
def aV : Arg := .var "v"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
def pProcessionWindow : Term := .param "procession_window"
def pProcessionGapMax : Term := .param "procession_gap_max"
def pAlignmentTolerance : Term := .param "alignment_tolerance"
def pMotionSpeedTolerance : Term := .param "motion_speed_tolerance"

/-- The road user quantified over is another one, not the road user judged. -/
def another : Formula := .not (.same aU aV)

/-- The road user judged follows the other one in its own line of travel: the co-proposed
    following relation, called on the two and given this concept's alignment and motion
    tolerances. Unknown where the order in the lane, a heading or the speed is unobserved. -/
def followsIt : Formula :=
  .derived "drv_interaction_following_vehicle_ahead" [aU, aV] [pAlignmentTolerance, pMotionSpeedTolerance]

/-- The other body lies within the maximum succession gap: the longitudinal component, along the
    judged road user's heading, of the distance between the nearest points of the two bodies is at
    most the maximum succession gap. Unknown where that gap is unobserved. -/
def withinSuccessionGap : Formula :=
  .cmp (.measure "rel_surface_gap" [aU, aV, .lit "longitudinal"]) .le pProcessionGapMax

/-- At this observation there is another road user the judged one follows in its own line of
    travel, whose body lies within the maximum succession gap ahead of it. -/
def inCloseSuccession : Formula :=
  .existsUser "v" (.and another (.and followsIt withinSuccessionGap))

/-- Travel in a close succession of road users on one line of travel: the close succession has
    held at every observation of the window behind, this one included. -/
def body : Formula := .holdsFor .time pProcessionWindow "u" inCloseSuccession

def concept : Concept :=
  { id := "drv.interaction.travelling_in_procession"
    contract := "At this observation the road user travels in a close succession of road users on one line of travel: there is another road user it follows in its own line of travel whose body lies within the maximum succession gap ahead of it, and that has held at every observation of the window behind. The gap read is the longitudinal component, along the road user's heading, of the distance between the nearest points of the two bodies; the maximum succession gap is the largest such gap at which successive road users are still read as travelling in one line, and the window is the time over which the succession must have held for it to be read as travel together rather than one body momentarily catching another. Both, with the alignment and motion tolerances the following relation needs, are the concept's own magnitudes, since gaps, headings and speeds are observed over sampled measurements only within bounds the caller sets. The concept denotes travel in close succession only: it is not the number of road users in the line, not their organization, purpose or destination, not any permit or escort, not the adequacy of the gaps between them, and not the lawfulness of the travel."
    definition := none
    args := [("u", .track)]
    params := [⟨"procession_window", .second⟩, ⟨"procession_gap_max", .metre⟩, ⟨"alignment_tolerance", .ratio⟩, ⟨"motion_speed_tolerance", .metrePerSecond⟩]
    body := .formula body
    residues := ["That the road users in the succession belong to one group — organized, escorted or bound for one destination — is not observable in any contract of the ontology; the concept carries the close succession the group displays on the road and nothing of its organization."]  -- the record's, verbatim; not yours to change
    narrowings :=
      [ { span := "there is another road user it follows in its own line of travel"
          why := "Written `.existsUser \"v\" (.and (.not (.same aU aV)) …)` over the scene's road users, with the following relation the co-proposed concept `drv.interaction.following_vehicle_ahead` called `[u, v]` — the road user judged in the first position, the one ahead in the second — and this concept's `alignment_tolerance` and `motion_speed_tolerance` passed through unchanged. \"another\" is the distinctness test `.not (.same aU aV)`. The lane is the called concept's own, so this concept quantifies over no region and takes none."
          kind := "reading" }
      , { span := "whose body lies within the maximum succession gap ahead of it"
          why := "Written `.cmp (.measure \"rel_surface_gap\" [aU, aV, .lit \"longitudinal\"]) .le pProcessionGapMax`: the component selected is the longitudinal one, read along the heading of the road user judged, which therefore stands in the subject (first) argument position. The bound is `.le`, the gap at the maximum included, because the parameter is \"the largest such gap at which successive road users are still read as travelling in one line\". That the body lies ahead is not read a second time here: the called concept already decides the order in the lane, and the gap's components are distances, never signed. rel.centre_distance is not read, its own contract excluding it as a stand-in for a clearance between bodies."
          kind := "reading" }
      , { span := "and that has held at every observation of the window behind"
          why := "The whole of the succession — another road user followed within the maximum gap — lies under one `.holdsFor .time pProcessionWindow \"u\"`, whose window behind includes this observation, so the words \"at this observation\" are not asserted a second time. The window is measured in time, not in path length, because `procession_window` is a time in seconds. The road user ahead is quantified inside the window rather than fixed across it: the contract asks only that at each observation there be another road user followed within the gap, so a line in which the road user ahead changes still reads as one close succession. Nothing further is required: the number of road users in the line, their organization, purpose or destination, any permit or escort, the adequacy of the gaps and the lawfulness of the travel are each excluded by the contract."
          kind := "reading" } ]
    supersedes := none }

end TrafficSpec.Concepts.interaction.travelling_in_procession
