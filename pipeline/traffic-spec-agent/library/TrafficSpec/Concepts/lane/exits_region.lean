/-
  drv.lane.exits_region — The observation at which the road user leaves the structure region given to it: its footprint overlapped that region at the previous observation and does not overlap it at this one. It is an event, read at the observation at which it occurs and not a state that persists after it; where there is no previous observation of the road user, or the overlap at either observation is unobserved, it is unknown. The region is the caller's: the concept reads the road user's overlap with that region and of no other. Not a stand-in for: the region the road user moves into, a lane change as a manoeuvre, a turn or a signal, the lateral movement within a region that precedes the leaving, or the reason the region was left.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    its footprint overlapped that region at the previous observation and does not overlap it at this one:
      atoms ['rel.occupies'], concepts []
      `rel_occupies u r` is the overlap of the road user's footprint with the caller's region, read
      at `u` and `r` and at nothing else: no second region, no distance, no boundary, no heading.
      The fall of that relation between the previous observation and this one is the edge the
      contract names, which the formula language writes as the rise of its negation:
      `rises (not (rel_occupies u r))` — not overlapping here, and overlapping at the previous
      observation. Being a `rises`, it is read at the observation at which it occurs and carries
      nothing forward, so the event is not a state; and the body says nothing about any other
      region, so the region moved into, the manoeuvre, the turn, the signal, the lateral movement
      before the leaving and the reason for it are all outside it.

  Readings chosen (declared as narrowings):
    - The unobserved past. `rises` is unknown wherever the previous observation is needed and not
      available: at the first observation of the trace when the road user does not overlap the
      region there, and at either observation when the overlap is unobserved. It settles `false`
      in the one remaining case the contract's words would leave unknown — the first observation
      of the trace at which the road user *does* overlap the region — because overlapping here
      already denies the leaving whatever the past held, so no previous observation is read. The
      alternative writing (unknown at every first observation) would have had to read the trace's
      start as an event of the road user's history, which it is not.

  No magnitude below is this file's own: parameters are formals the caller fills.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.lane.exits_region

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aU : Arg := .var "u"
def aR : Arg := .var "r"

/-- The road user's footprint overlaps the caller's region. -/
def occupies : Formula := .atom "rel_occupies" [aU, aR] []

/-- The leaving: not overlapping here, overlapping at the previous observation. -/
def body : Formula := .rises (.not occupies)

def concept : Concept :=
  { id := "drv.lane.exits_region"
    contract := "The observation at which the road user leaves the structure region given to it: its footprint overlapped that region at the previous observation and does not overlap it at this one. It is an event, read at the observation at which it occurs and not a state that persists after it; where there is no previous observation of the road user, or the overlap at either observation is unobserved, it is unknown. The region is the caller's: the concept reads the road user's overlap with that region and of no other. Not a stand-in for: the region the road user moves into, a lane change as a manoeuvre, a turn or a signal, the lateral movement within a region that precedes the leaving, or the reason the region was left."
    definition := none
    args := [("u", .track), ("r", .region)]
    params := []
    body := .formula body
    residues := []  -- the record's, verbatim; not yours to change
    narrowings :=
      [ { span := "where there is no previous observation of the road user, or the overlap at either observation is unobserved, it is unknown"
          why := "Written with `rises`, which is unknown wherever the previous observation is needed and not available (the overlap unobserved at either observation; the first observation of the trace where the road user does not overlap the region), but false at a first observation at which the road user does overlap the region: overlapping here denies the leaving without reading any past, and the start of a recording is no event of the road user's history."
          kind := "reading" } ]
    supersedes := none }

end TrafficSpec.Concepts.lane.exits_region
