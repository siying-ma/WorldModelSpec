/-
  drv.lane.enters_region — The observation at which the road user enters the structure region given to it: its footprint did not overlap that region at the previous observation and overlaps it at this one. It is an event, read at the observation at which it occurs, and not a state that persists afterwards: a road user that stays in the region is not entering it again at the following observations. Where there is no previous observation of the road user, because its recording begins here, or the overlap at either of the two observations is unobserved, the concept is unknown. The region is the caller's: the concept reads the road user's overlap with that region and of no other, so which intersection, lane or crossing is entered is fixed by the caller and never by the road user's heading, its velocity or a distance. Not a stand-in for: the region the road user leaves or comes from, the carrier through which the entry is made, the manoeuvre that carries the road user in (a turn, a lane change) or any signal of it, the lawfulness of the entry, the part of the body that crossed the boundary — any overlap of the footprint is an entry — or a crossing that happened between two observations, which the trace does not show.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    its footprint did not overlap that region at the previous observation and overlaps it at this one: atoms ['rel.occupies'], concepts []

  How it is written. The element is one read of `rel_occupies u r` — the footprint's overlap with the
  caller's region — under `rises`, which is Core's operator for exactly this pair of readings: the
  formula here and not at the previous observation. So the body is `rises (rel_occupies u r)`: true
  at the observation at which the overlap begins, false at an observation at which the overlap does
  not begin (the user outside, or inside and inside before), unknown wherever either reading of the
  overlap is unobserved — `rel_occupies` is unknown, not false, for a track whose occupancy the
  source does not declare, and the conjunction carries that through. Nothing else is read: no
  heading, no velocity, no distance, no second region, no quantifier, so which region is entered is
  the caller's argument and the event is not a state that persists.

  Narrowing (declared on the concept): the contract's sentence on the first observation of a road
  user. `rises` is the only operator for "here and not at the previous observation", and at the
  first observation it reads the missing previous observation as unknown: the concept is then
  unknown where the footprint overlaps the region there (nothing says whether the overlap began),
  and false where it does not overlap (the conjunction is false whatever the unseen previous
  overlap was, and a user whose footprint is outside the region is not entering it at this
  observation). That is the contract's "unknown" on the only case it can bite, and it never asserts
  an entry the trace does not show.

  No magnitude below is this file's own: parameters are formals the caller fills.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.lane.enters_region

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aU : Arg := .var "u"
def aR : Arg := .var "r"

/-- The road user's footprint overlaps the caller's region at this observation. -/
def overlaps : Formula := .atom "rel_occupies" [aU, aR] []

/-- The observation at which the overlap begins: it holds here and not at the previous observation. -/
def body : Formula := .rises overlaps

def concept : Concept :=
  { id := "drv.lane.enters_region"
    contract := "The observation at which the road user enters the structure region given to it: its footprint did not overlap that region at the previous observation and overlaps it at this one. It is an event, read at the observation at which it occurs, and not a state that persists afterwards: a road user that stays in the region is not entering it again at the following observations. Where there is no previous observation of the road user, because its recording begins here, or the overlap at either of the two observations is unobserved, the concept is unknown. The region is the caller's: the concept reads the road user's overlap with that region and of no other, so which intersection, lane or crossing is entered is fixed by the caller and never by the road user's heading, its velocity or a distance. Not a stand-in for: the region the road user leaves or comes from, the carrier through which the entry is made, the manoeuvre that carries the road user in (a turn, a lane change) or any signal of it, the lawfulness of the entry, the part of the body that crossed the boundary — any overlap of the footprint is an entry — or a crossing that happened between two observations, which the trace does not show."
    definition := none
    args := [("u", .track), ("r", .region)]
    params := []
    body := .formula body
    residues := []  -- the record's, verbatim; not yours to change
    narrowings :=
      [ { span := "Where there is no previous observation of the road user, because its recording begins here, or the overlap at either of the two observations is unobserved, the concept is unknown."
          why := "Written with `rises`, the operator for \"here and not at the previous observation\": at the first observation of the road user the missing previous overlap is read as unknown, so the concept is unknown there where the footprint overlaps the region, and false where it does not overlap — an observation at which the footprint is outside the region is no entry whatever the unseen previous observation held. Where either reading of the overlap is unobserved the concept is unknown, as the contract says."
          kind := "reading" } ]
    supersedes := none }

end TrafficSpec.Concepts.lane.enters_region
