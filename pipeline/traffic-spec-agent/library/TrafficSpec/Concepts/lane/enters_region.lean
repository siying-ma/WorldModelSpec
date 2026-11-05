/-
  drv.lane.enters_region — The road user enters the given region at this observation: the event, not the state that follows it. It holds exactly at the observation at which the road user's footprint overlaps the region and did not overlap it at the previous observation; at the later observations of the same stay it is false, and it is unknown where either overlap is unknown. The concept denotes the crossing of the region's boundary by the body's footprint: it is not presence in the region, not an approach to it, not a distance from it, and not the direction from which it was reached, which a caller states with its own relations.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    the road user's footprint overlaps the region and did not overlap it at the previous observation: atoms ['rel.occupies'], concepts []

  How it is written. `rel_occupies u r` is the footprint's overlap with the region; the event the
  contract names — overlap here, no overlap at the previous observation — is `rises` of it, the
  language's edge operator, so the body is `.rises (rel_occupies u r)` and nothing else. Presence,
  approach, distance and the direction of arrival are not read: no atom of them enters the body.

  The one reading the contract leaves open (declared as a narrowing): the contract says the concept
  is unknown "where either overlap is unknown", and `rises` is Kleene — where the overlap here is
  observed false the event is false whatever the previous observation was, since no previous value
  could make an entry out of a non-overlap. The unknown therefore stands only where the overlap
  here is unknown, or where it holds here and the previous observation is unknown.

  No magnitude below is this file's own: parameters are formals the caller fills.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.lane.enters_region

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aU : Arg := .var "u"
def aR : Arg := .var "r"

/-- The road user's footprint overlaps the region at this observation. -/
def overlaps : Formula := .atom "rel_occupies" [aU, aR] []

/-- The entry event: the overlap here, and not at the previous observation. -/
def body : Formula := .rises overlaps

def concept : Concept :=
  { id := "drv.lane.enters_region"
    contract := "The road user enters the given region at this observation: the event, not the state that follows it. It holds exactly at the observation at which the road user's footprint overlaps the region and did not overlap it at the previous observation; at the later observations of the same stay it is false, and it is unknown where either overlap is unknown. The concept denotes the crossing of the region's boundary by the body's footprint: it is not presence in the region, not an approach to it, not a distance from it, and not the direction from which it was reached, which a caller states with its own relations."
    definition := none
    args := [("u", .track), ("r", .region)]
    params := []
    body := .formula body
    residues := []  -- the record's, verbatim; not yours to change
    narrowings :=
      [ { span := "it is unknown where either overlap is unknown"
          why := "The body is `rises` of the overlap, whose connectives are Kleene: where the overlap here is observed to be false the event is false, whatever the previous observation was, because no previous value makes an entry out of a non-overlap. The unknown stands where the overlap here is unknown, and where it holds here and the previous observation is unknown."
          kind := "reading" } ]
    supersedes := none }

end TrafficSpec.Concepts.lane.enters_region
