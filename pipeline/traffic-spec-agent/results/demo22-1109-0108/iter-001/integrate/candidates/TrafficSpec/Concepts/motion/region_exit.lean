/-
  drv.motion.region_exit — The road user's footprint ceases to overlap a structure region at the observation: it does not overlap the region at the observation and did overlap it at the observation before. The concept is the event of that ceasing to overlap, read at the observation at which the overlap has ended, and not the state of lying outside the region at the later observations. It states no direction of departure, no carrier the road user leaves through, no speed and no place outside the region. Not a stand-in for: lying outside the region, which the occupancy relation carries on its own; a later observation at which the road user is still outside; the carrier or the way the road user goes on to, which a caller reads with its own relations; a crossing of a boundary the source represents by no region; or an entry into the region, which has its own concept.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    it does not overlap the region at the observation and did overlap it at the observation before: atoms ['rel.occupies'], concepts []

  How that element is written. `rel.occupies u r` is the footprint's overlap with the region the
  caller singles out, read at the judged observation. The element's two conjuncts — "does not
  overlap ... at the observation" and "did overlap it at the observation before" — are together the
  rising edge of the overlap's negation, so the body is `rises (not (rel_occupies u r))`: `rises φ`
  is φ here and not at the previous observation, which is exactly "not overlapping here, overlapping
  one observation back". Nothing else is read: no geometry of the region, no distance, no heading,
  no speed, no second region and no carrier, which the contract expressly excludes.

  Three values. Where the overlap is unobserved at the observation or at the one before, the edge is
  unknown, not false; at the first observation of a recording the overlap's earlier value is
  truncated, so the body is false where the footprint overlaps there and unknown where it does not.
  Both come from `rises` and the atom, not from a choice made here.

  Choices the contract left open: none. "the observation before" is the previous observation of the
  trace, which is the only predecessor the formula language has, and the event reading ("read at the
  observation at which the overlap has ended") is the contract's own, carried by the edge rather than
  by the state. So `narrowings` is empty.

  No magnitude below is this file's own: parameters are formals the caller fills (there are none).
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.motion.region_exit

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aU : Arg := .var "u"
def aR : Arg := .var "r"

/-- The road user's footprint overlaps the region the caller singles out, at the observation. -/
def overlaps : Formula := .atom "rel_occupies" [aU, aR] []

/-- The overlap has just ceased: no overlap at the observation, overlap at the observation before. -/
def body : Formula := .rises (.not overlaps)

def concept : Concept :=
  { id := "drv.motion.region_exit"
    contract := "The road user's footprint ceases to overlap a structure region at the observation: it does not overlap the region at the observation and did overlap it at the observation before. The concept is the event of that ceasing to overlap, read at the observation at which the overlap has ended, and not the state of lying outside the region at the later observations. It states no direction of departure, no carrier the road user leaves through, no speed and no place outside the region. Not a stand-in for: lying outside the region, which the occupancy relation carries on its own; a later observation at which the road user is still outside; the carrier or the way the road user goes on to, which a caller reads with its own relations; a crossing of a boundary the source represents by no region; or an entry into the region, which has its own concept."
    definition := none
    args := [("u", .track), ("r", .region)]
    params := []
    body := .formula body
    residues := []  -- the record's, verbatim; not yours to change
    narrowings := []  -- one { span := "<words of the contract>", why := "<why>", kind := "reading" } per reading you chose that the contract leaves open, explained in the header
    supersedes := none }

end TrafficSpec.Concepts.motion.region_exit
