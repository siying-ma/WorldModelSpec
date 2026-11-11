/-
  drv.motion.entering_region — Road user x enters structure region r at the observation: its footprint overlaps r (rel.occupies) at the observation and did not at the observation before. The entry is that one observation; the later observations at which the overlap continues are not the entry again. Unknown where the overlap is unobserved at the observation or at the one before, or where there is no observation of x before it. Not denoted: x's direction or speed, the region x came from, or its whole body being inside r: an overlap by any part of the footprint counts.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    its footprint overlaps r (rel.occupies) at the observation and did not at the observation before: atoms ['rel.occupies'], concepts []
      written `rises (rel_occupies x r)`: the overlap here and not at the previous observation.

  No choice was left open: the contract's words are `rises` over the one claimed atom.

  No magnitude below is this file's own: parameters are formals the caller fills.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.motion.entering_region

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aX : Arg := .var "x"
def aR : Arg := .var "r"

/-- The footprint of x overlaps r here and did not at the observation before: `rises` is exactly
    "here and not at the previous observation", unknown where either reading is unknown or there is
    no observation before. -/
def body : Formula := .rises (.atom "rel_occupies" [aX, aR] [])

def concept : Concept :=
  { id := "drv.motion.entering_region"
    contract := "Road user x enters structure region r at the observation: its footprint overlaps r (rel.occupies) at the observation and did not at the observation before. The entry is that one observation; the later observations at which the overlap continues are not the entry again. Unknown where the overlap is unobserved at the observation or at the one before, or where there is no observation of x before it. Not denoted: x's direction or speed, the region x came from, or its whole body being inside r: an overlap by any part of the footprint counts."
    definition := none
    args := [("x", .track), ("r", .region)]
    params := []
    body := .formula body
    residues := []  -- the record's, verbatim; not yours to change
    narrowings := []  -- one { span := "<words of the contract>", why := "<why>", kind := "reading" } per reading you chose that the contract leaves open, explained in the header
    supersedes := none }

end TrafficSpec.Concepts.motion.entering_region
