/-
  drv.lane.exits_region — The road user leaves the given region at this observation: the event, not the state that follows it. It holds exactly at the observation at which the road user's footprint does not overlap the region and did overlap it at the previous observation; at the later observations of the same absence it is false, and it is unknown where either overlap is unknown. The concept denotes the crossing of the region's boundary outward by the body's footprint: it is not absence from the region, not a distance from it, not the direction in which the body left or the region it moved into, and not the lawfulness of leaving.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    the road user's footprint does not overlap the region and did overlap it at the previous observation: atoms ['rel.occupies'], concepts []
      written `.rises (.not (.atom "rel_occupies" [aU, aR] []))`: rel.occupies is "a road user's
      footprint overlaps a lane / region", read of the formal road user `u` and the formal region
      `r` — the region the caller singles out, never a region the body quantifies over.
      `rises φ` is Core's only reading of the previous observation: φ here and not at the previous
      observation. With φ the negation of the overlap, it is exactly the contract's conjunction —
      no overlap at this observation, overlap at the previous one — and so is false at the later
      observations of the same absence, as the contract states, rather than true throughout the
      absence. Nothing else is read: no `st.region_geometry` distance (its distance is "not a
      stand-in for: occupancy", and a distance standing clear of zero is not the crossing of a
      boundary), no heading or bearing (the contract excludes "the direction in which the body
      left"), no second region (it excludes "the region it moved into"), and no rule (it excludes
      "the lawfulness of leaving").

  Narrowings (choices the contract did not dictate):
    "does not overlap the region and did overlap it at the previous observation" — written as one
      `rises` of the negated overlap rather than as a conjunction of two separately timed
      readings, because `rises` is the formula language's only reading of the previous
      observation. Its consequence at the first observation of a trace, where there is no previous
      observation to compare with, is that the event is unknown (`windowTruncated "rises"`) where
      the overlap is absent there and false where it is present: the contract fixes the value only
      at observations that have a predecessor, and leaving the start of a trace unknown rather
      than deciding it is the reading that claims nothing the trace does not show.

  No magnitude below is this file's own: parameters are formals the caller fills.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.lane.exits_region

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aU : Arg := .var "u"
def aR : Arg := .var "r"

/-- The road user's footprint overlaps the given region at this observation. -/
def overlaps : Formula := .atom "rel_occupies" [aU, aR] []

/-- The road user leaves the region at this observation: its footprint does not overlap the region
    here and did overlap it at the previous observation — the rising edge of non-overlap, which is
    the crossing of the boundary outward and not the absence that follows it. -/
def body : Formula := .rises (.not overlaps)

def concept : Concept :=
  { id := "drv.lane.exits_region"
    contract := "The road user leaves the given region at this observation: the event, not the state that follows it. It holds exactly at the observation at which the road user's footprint does not overlap the region and did overlap it at the previous observation; at the later observations of the same absence it is false, and it is unknown where either overlap is unknown. The concept denotes the crossing of the region's boundary outward by the body's footprint: it is not absence from the region, not a distance from it, not the direction in which the body left or the region it moved into, and not the lawfulness of leaving."
    definition := none
    args := [("u", .track), ("r", .region)]
    params := []
    body := .formula body
    residues := []  -- the record's, verbatim; not yours to change
    narrowings :=
      [ { span := "does not overlap the region and did overlap it at the previous observation"
          why := "Written as a single `rises` of the negated `rel_occupies` reading, not as a conjunction of two separately timed readings: `rises φ` is the formula language's only reading of the previous observation (φ here and not at the previous observation), so with φ the negation of the overlap it is exactly the contract's conjunction, false at the later observations of the same absence. At the first observation of a trace, which has no predecessor, the reading is therefore unknown where the overlap is absent there rather than decided: the contract fixes the value only where a previous observation exists."
          kind := "reading" } ]
    supersedes := none }

end TrafficSpec.Concepts.lane.exits_region
