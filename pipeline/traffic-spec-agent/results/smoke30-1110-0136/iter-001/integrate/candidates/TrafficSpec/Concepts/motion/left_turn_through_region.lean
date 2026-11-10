/-
  drv.motion.left_turn_through_region — A road user has turned to the left through a region, such as an intersection the caller passes: at the observation it leaves the region (its footprint overlaps the region, rel.occupies, at the observation before and not at this one), and its heading change since its entry, integrated from its yaw rate (kin.yaw_rate, left positive) with sampling step bound `step`, is at least `min_angle` and below `max_angle`, the band in which the crossing counts as a left turn rather than a through movement or a reversal. The act begins at the entry, the observation at which the overlap last became true. The act is recognized at the observation it leaves the region. The concept holds only at the exit observation, ending at the next observation. Conduct before the entry is not read. Not denoted: a through movement or a heading change to the left below `min_angle`; a turn to the right; a reversal, a change at or beyond `max_angle`; a road user still within the region; which carrier it entered from, which the caller states; a crossing whose entry the recording does not show, for which the heading change since entry is unknown.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    its footprint overlaps the region, rel.occupies: atoms ['rel.occupies'], concepts []
    integrated from its yaw rate (kin.yaw_rate, left positive): atoms ['kin.yaw_rate'], concepts []
      written `rel_occupies x i`; the exit, "overlaps at the observation before and not at this
      one", is `rises (¬ rel_occupies x i)`; the entry, "the observation at which the overlap last
      became true", is the onset of `Term.headingSince "x" step (rel_occupies x i)`, which
      integrates x's kin_yaw_rate (left positive) from that last definite rise, with `step` as
      its sampling step bound. "At least `min_angle`" is `.ge`, "below `max_angle`" is `.lt`.
      A crossing whose entry the trace does not show leaves the heading change unknown, as the
      contract says, by the operator's own definition.

  No choice was left open: the contract names the atoms, the edges, the band and its bounds'
  inclusiveness; no narrowing is declared.

  No magnitude below is this file's own: parameters are formals the caller fills.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.motion.left_turn_through_region

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aX : Arg := .var "x"
def aI : Arg := .var "i"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
def pStep : Term := .param "step"
def pMinAngle : Term := .param "min_angle"
def pMaxAngle : Term := .param "max_angle"

/-- x's footprint overlaps the region i. -/
def occ : Formula := .atom "rel_occupies" [aX, aI] []

/-- x leaves i here: it overlapped i at the observation before and does not at this one. -/
def leaves : Formula := .rises (.not occ)

/-- x's heading change (left positive) since its entry, the last rise of the overlap. -/
def turned : Term := .headingSince "x" pStep occ

/-- At the exit, the heading change since the entry is at least `min_angle` and below `max_angle`. -/
def body : Formula :=
  .and leaves (.and (.cmp turned .ge pMinAngle) (.cmp turned .lt pMaxAngle))

def concept : Concept :=
  { id := "drv.motion.left_turn_through_region"
    contract := "A road user has turned to the left through a region, such as an intersection the caller passes: at the observation it leaves the region (its footprint overlaps the region, rel.occupies, at the observation before and not at this one), and its heading change since its entry, integrated from its yaw rate (kin.yaw_rate, left positive) with sampling step bound `step`, is at least `min_angle` and below `max_angle`, the band in which the crossing counts as a left turn rather than a through movement or a reversal. The act begins at the entry, the observation at which the overlap last became true. The act is recognized at the observation it leaves the region. The concept holds only at the exit observation, ending at the next observation. Conduct before the entry is not read. Not denoted: a through movement or a heading change to the left below `min_angle`; a turn to the right; a reversal, a change at or beyond `max_angle`; a road user still within the region; which carrier it entered from, which the caller states; a crossing whose entry the recording does not show, for which the heading change since entry is unknown."
    definition := none
    args := [("x", .track), ("i", .region)]
    params := [⟨"step", .second⟩, ⟨"min_angle", .degree⟩, ⟨"max_angle", .degree⟩]
    body := .formula body
    residues := []  -- the record's, verbatim; not yours to change
    narrowings := []  -- one { span := "<words of the contract>", why := "<why>", kind := "reading" } per reading you chose that the contract leaves open, explained in the header
    supersedes := none }

end TrafficSpec.Concepts.motion.left_turn_through_region
