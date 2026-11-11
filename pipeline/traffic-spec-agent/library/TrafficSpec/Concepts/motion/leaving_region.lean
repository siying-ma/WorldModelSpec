/-
  drv.motion.leaving_region — Road user x leaves structure region r at the observation: its footprint overlapped r (rel.occupies) at the observation before and does not overlap it at the observation. The exit is that one observation; the later observations at which x stays off r are not the exit again. Unknown where the overlap is unobserved at the observation or at the one before, or where there is no observation of x before it. Not denoted: x's direction or speed, or the region x moves into.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    its footprint overlapped r (rel.occupies) at the observation before and does not overlap it at the observation: atoms ['rel.occupies'], concepts []

  No magnitude below is this file's own: parameters are formals the caller fills.

  Writing. `occ` is `rel_occupies x r`. The exit is `rises (not occ)`: x off r at the observation
  and on r at the one before — an edge, so the later observations at which x stays off r are not
  the exit again. Unknown where `occ` is unknown here or at the observation before (x not observed
  there leaves its occupancy unknown). At the first observation of the trace `rises` reads the
  unobserved past as unknown, but a conjunction with a false `not occ` would still decide false;
  the contract makes the exit unknown wherever there is no observation before, so the body adds the
  disjunct `rises tt`, false at every observation that has one before it and unknown at the first:
  it changes nothing where an observation before exists and leaves the first one unknown.
  No reading the contract left open was chosen; there are no narrowings.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.motion.leaving_region

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aX : Arg := .var "x"
def aR : Arg := .var "r"

/-- x's footprint overlaps r. -/
def occ : Formula := .atom "rel_occupies" [aX, aR] []

/-- x off r here and on r at the observation before; unknown where there is no observation before. -/
def body : Formula := .or (.rises (.not occ)) (.rises .tt)

def concept : Concept :=
  { id := "drv.motion.leaving_region"
    contract := "Road user x leaves structure region r at the observation: its footprint overlapped r (rel.occupies) at the observation before and does not overlap it at the observation. The exit is that one observation; the later observations at which x stays off r are not the exit again. Unknown where the overlap is unobserved at the observation or at the one before, or where there is no observation of x before it. Not denoted: x's direction or speed, or the region x moves into."
    definition := none
    args := [("x", .track), ("r", .region)]
    params := []
    body := .formula body
    residues := []  -- the record's, verbatim; not yours to change
    narrowings := []
    supersedes := none }

end TrafficSpec.Concepts.motion.leaving_region
