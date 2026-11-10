/-
  drv.motion.region_entry — The road user's footprint comes to overlap a structure region at the observation: it overlaps the region at the observation and did not overlap it at the observation before. The concept is the event of that coming to overlap, read at the observation at which the overlap has begun, and not the state of lying inside the region afterwards. It states no direction of entry, no carrier the road user came through, no speed and no place within the region. Not a stand-in for: lying within the region, which the occupancy relation carries on its own; a later observation at which the road user is still inside; the carrier or the way the road user came from, which a caller reads with its own relations; a crossing of a boundary the source represents by no region; or a leaving of the region.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    comes to overlap a structure region at the observation: atoms ['rel.occupies'], concepts []
      written `rel_occupies u r`: the footprint of the road user formal overlaps the region formal
      at the judged observation. The kind of the region is the caller's: `r` is a region formal the
      caller binds, so the body reads no region quantifier and no structure kind.
    did not overlap it at the observation before: atoms ['rel.occupies'], concepts []
      written as the `rises` of that same reading: `rises (rel_occupies u r)` is the relation here
      and not at the previous observation, which is the event of the overlap having begun and
      nothing else — no direction, no carrier, no speed, no place within the region. At the first
      observation of a trace the previous observation is unobserved, so the event is unknown there,
      as `rises` gives it; the witnesses name the instants they speak about.

  No magnitude below is this file's own: parameters are formals the caller fills (this concept
  declares none, and the body holds no literal).
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.motion.region_entry

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aU : Arg := .var "u"
def aR : Arg := .var "r"

/-- The road user's footprint overlaps the region at the observation. -/
def overlaps : Formula := .atom "rel_occupies" [aU, aR] []

/-- The overlap has begun here: it holds at the observation and not at the observation before. -/
def body : Formula := .rises overlaps

def concept : Concept :=
  { id := "drv.motion.region_entry"
    contract := "The road user's footprint comes to overlap a structure region at the observation: it overlaps the region at the observation and did not overlap it at the observation before. The concept is the event of that coming to overlap, read at the observation at which the overlap has begun, and not the state of lying inside the region afterwards. It states no direction of entry, no carrier the road user came through, no speed and no place within the region. Not a stand-in for: lying within the region, which the occupancy relation carries on its own; a later observation at which the road user is still inside; the carrier or the way the road user came from, which a caller reads with its own relations; a crossing of a boundary the source represents by no region; or a leaving of the region."
    definition := none
    args := [("u", .track), ("r", .region)]
    params := []
    body := .formula body
    residues := []  -- the record's, verbatim; not yours to change
    narrowings := []  -- one { span := "<words of the contract>", why := "<why>", kind := "reading" } per reading you chose that the contract leaves open, explained in the header
    supersedes := none }

end TrafficSpec.Concepts.motion.region_entry
