/-
  drv.motion.proceeds_through_region — The road user has crossed the given region and continued beyond it rather than turning within it: at this observation its footprint no longer overlaps the region while it did overlap it at the previous observation, and the magnitude of the signed heading change integrated over the window behind is at or below max_heading_change, so the direction of travel with which the body leaves the region is the one it had on entering. The region is the caller's: the concept takes it as an argument and never looks for a region of its own. The concept denotes the passage of the body across a region as a footprint, a boundary and a heading observe it. It is not an entry (the observation at which the body began to overlap the region lies earlier), not a state that lasts while the body is inside the region, not a turn out of the region (a body whose integrated change over the window exceeds the bound is excluded, and that exclusion is what tells a crossing from a turn), not a lane change, not a halt within the region, and not a judgement that the passage is lawful or permitted. The window is the time over which the heading change of the passage is integrated, long enough to cover the body's time within a junction-sized region, and max_heading_change the change below which the course across the region counts as held rather than turned out of.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    its footprint no longer overlaps the region while it did overlap it at the previous observation: atoms ['rel.occupies'], concepts []
    the magnitude of the signed heading change integrated over the window behind is at or below max_heading_change: atoms ['prim.heading_change'], concepts []

  How the first element is written. `rel.occupies` is "a road user's footprint overlaps a lane /
  region", read of the formals `u` and `r`: the region is the caller's argument, so the body reads
  `rel_occupies u r` and never quantifies over a region. "no longer overlaps … while it did overlap
  it at the previous observation" is the rise of the negation of that overlap: `rises (not
  (rel_occupies u r))` is, by the formula language, the negation true here and not true at the
  previous observation, which is exactly the observation at which the overlap ceased. Written this
  way the concept is the leaving and not the entry (an entry is the rise of the overlap itself) and
  not a state that lasts while the body is inside (which is the overlap, not its rise). Where the
  overlap is unobserved at this observation or at the previous one the rise is unknown, which is
  what the `blind` witness shows.

  How the second element is written. `prim.heading_change` is "the signed heading change (degrees,
  left positive) of a road user over the window behind the observation, integrated from
  `kin.yaw_rate`", with the body as its only argument and the window length as its only parameter.
  "The magnitude … is at or below max_heading_change" is therefore the single comparison
  `|heading_change u window| ≤ max_heading_change`: two-sided, because a passage turned out of the
  region to either hand is excluded, and `.le` because the contract says "at or below". The bound
  is on the body's own yaw and not on the curvature of the way: that is what tells a crossing from
  a turn. Where the window is truncated at the start of the trace, sparsely sampled, or a yaw rate
  inside it is missing, the primitive is unknown and so is the comparison.

  Narrowing. The contract's "so the direction of travel with which the body leaves the region is
  the one it had on entering" is written as nothing beyond the bound on the integrated change: the
  clause is the contract's own gloss of what that bound secures, and no element claims an atom for
  the heading at entry, so the body does not compare the heading here with the heading at the
  observation at which the overlap began. A body that did compare them would read a heading at an
  observation the concept does not name and would decide differently on a passage that leaves and
  re-enters its entry course by two opposed swings — a case the integrated magnitude excludes and a
  comparison of the two headings would admit.

  No magnitude below is this file's own: parameters are formals the caller fills.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.motion.proceeds_through_region

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aU : Arg := .var "u"
def aR : Arg := .var "r"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
def pWindow : Term := .param "window"
def pMaxHeadingChange : Term := .param "max_heading_change"

/-- The body's footprint overlaps the caller's region. -/
def overlapsRegion : Formula := .atom "rel_occupies" [aU, aR] []

/-- The observation at which the overlap ceased: the footprint does not overlap the region here
    and it did overlap it at the previous observation. -/
def leavesRegion : Formula := .rises (.not overlapsRegion)

/-- The signed heading change of the body over the window behind this observation, in degrees and
    left positive, integrated from its rate of change of heading. -/
def headingChange : Term := .quantity "prim_heading_change" [aU] [pWindow]

/-- The magnitude of that change is at or below `max_heading_change`: the course across the region
    was held rather than turned out of. -/
def courseHeld : Formula := .cmp (.abs headingChange) .le pMaxHeadingChange

/-- The body leaves the region at this observation, holding the course it crossed it on. -/
def body : Formula := .and leavesRegion courseHeld

def concept : Concept :=
  { id := "drv.motion.proceeds_through_region"
    contract := "The road user has crossed the given region and continued beyond it rather than turning within it: at this observation its footprint no longer overlaps the region while it did overlap it at the previous observation, and the magnitude of the signed heading change integrated over the window behind is at or below max_heading_change, so the direction of travel with which the body leaves the region is the one it had on entering. The region is the caller's: the concept takes it as an argument and never looks for a region of its own. The concept denotes the passage of the body across a region as a footprint, a boundary and a heading observe it. It is not an entry (the observation at which the body began to overlap the region lies earlier), not a state that lasts while the body is inside the region, not a turn out of the region (a body whose integrated change over the window exceeds the bound is excluded, and that exclusion is what tells a crossing from a turn), not a lane change, not a halt within the region, and not a judgement that the passage is lawful or permitted. The window is the time over which the heading change of the passage is integrated, long enough to cover the body's time within a junction-sized region, and max_heading_change the change below which the course across the region counts as held rather than turned out of."
    definition := none
    args := [("u", .track), ("r", .region)]
    params := [⟨"window", .second⟩, ⟨"max_heading_change", .degree⟩]
    body := .formula body
    residues := []  -- the record's, verbatim; not yours to change
    narrowings :=
      [ { span := "so the direction of travel with which the body leaves the region is the one it had on entering"
          why := "written as nothing beyond the bound on the magnitude of the integrated heading change over the window behind, which the contract itself names as what secures the clause: no element claims an atom for the heading at the observation at which the overlap began, so the body does not compare the heading here with the heading on entering"
          kind := "reading" } ]
    supersedes := none }

end TrafficSpec.Concepts.motion.proceeds_through_region
