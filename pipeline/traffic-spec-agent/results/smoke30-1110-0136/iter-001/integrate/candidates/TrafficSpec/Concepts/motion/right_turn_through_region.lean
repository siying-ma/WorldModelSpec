/-
  drv.motion.right_turn_through_region — A road user has turned to the right through a region, such as an intersection the caller passes: at the observation it leaves the region (its footprint overlaps the region, rel.occupies, at the observation before and not at this one), and its heading change since its entry, integrated from its yaw rate (kin.yaw_rate, left positive) with sampling step bound `step`, is at most minus `min_angle` and above minus `max_angle`, the band in which the crossing counts as a right turn rather than a through movement or a reversal. The act begins at the entry, the observation at which the overlap last became true. The act is recognized at the observation it leaves the region. The concept holds only at the exit observation, ending at the next observation. Conduct before the entry is not read. Not denoted: a through movement or a heading change to the right smaller than `min_angle`; a turn to the left; a reversal, a change to the right at or beyond `max_angle`; a road user still within the region; which carrier it entered from, which the caller states; a crossing whose entry the recording does not show, for which the heading change since entry is unknown.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    its footprint overlaps the region, rel.occupies: atoms ['rel.occupies'], concepts []
    integrated from its yaw rate (kin.yaw_rate, left positive): atoms ['kin.yaw_rate'], concepts []

  How the words are written:
    "it leaves the region (... at the observation before and not at this one)" is
      `rises (not (rel_occupies x i))`: not overlapping here, overlapping at the observation
      before. Being a `rises`, it holds only at the exit observation, as the act's extent says.
    "its heading change since its entry, integrated from its yaw rate ... with sampling step
      bound `step`" is `Term.headingSince "x" step (rel_occupies x i)`: the yaw rate (left
      positive) integrated from the observation at which the overlap last rose, the entry; the
      overlap turning false at the exit does not end it. A crossing whose entry the recording
      does not show leaves it unknown, as the contract's last exclusion says; conduct before the
      entry is not read.
    "at most minus `min_angle`" is `.le` against `neg min_angle`; "above minus `max_angle`" is
      `.gt` against `neg max_angle`, so a change to the right at or beyond `max_angle` fails.

  Choices the contract did not dictate: none. No narrowing is declared.

  No magnitude below is this file's own: parameters are formals the caller fills.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.motion.right_turn_through_region

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aX : Arg := .var "x"
def aI : Arg := .var "i"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
def pStep : Term := .param "step"
def pMinAngle : Term := .param "min_angle"
def pMaxAngle : Term := .param "max_angle"

/-- The footprint of x overlaps the region i. -/
def occupies : Formula := .atom "rel_occupies" [aX, aI] []

/-- x leaves i here: it overlapped i at the observation before and does not here. -/
def leaves : Formula := .rises (.not occupies)

/-- The heading change of x (degrees, left positive) since the overlap with i last became true. -/
def headingChange : Term := .headingSince "x" pStep occupies

/-- Exit from i with a heading change to the right in [min_angle, max_angle). -/
def body : Formula :=
  .and leaves
    (.and (.cmp headingChange .le (.neg pMinAngle))
          (.cmp headingChange .gt (.neg pMaxAngle)))

def concept : Concept :=
  { id := "drv.motion.right_turn_through_region"
    contract := "A road user has turned to the right through a region, such as an intersection the caller passes: at the observation it leaves the region (its footprint overlaps the region, rel.occupies, at the observation before and not at this one), and its heading change since its entry, integrated from its yaw rate (kin.yaw_rate, left positive) with sampling step bound `step`, is at most minus `min_angle` and above minus `max_angle`, the band in which the crossing counts as a right turn rather than a through movement or a reversal. The act begins at the entry, the observation at which the overlap last became true. The act is recognized at the observation it leaves the region. The concept holds only at the exit observation, ending at the next observation. Conduct before the entry is not read. Not denoted: a through movement or a heading change to the right smaller than `min_angle`; a turn to the left; a reversal, a change to the right at or beyond `max_angle`; a road user still within the region; which carrier it entered from, which the caller states; a crossing whose entry the recording does not show, for which the heading change since entry is unknown."
    definition := none
    args := [("x", .track), ("i", .region)]
    params := [⟨"step", .second⟩, ⟨"min_angle", .degree⟩, ⟨"max_angle", .degree⟩]
    body := .formula body
    residues := []  -- the record's, verbatim; not yours to change
    narrowings := []  -- one { span := "<words of the contract>", why := "<why>", kind := "reading" } per reading you chose that the contract leaves open, explained in the header
    supersedes := none }

end TrafficSpec.Concepts.motion.right_turn_through_region
