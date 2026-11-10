/-
  drv.motion.straight_through_region — A road user has travelled straight through a region, such as an intersection the caller passes: at the observation it leaves the region (its footprint overlaps the region, rel.occupies, at the observation before and not at this one), and the magnitude of its heading change since its entry, the observation at which the overlap last became true, integrated from its yaw rate with sampling step bound `step`, is below `max_angle`, the heading change below which a crossing counts as straight. The act begins at the entry, the observation at which the overlap last became true. The act is recognized at the observation it leaves the region. The concept holds only at the exit observation, ending at the next observation. Conduct before the entry is not read. Not denoted: a turn, a heading change at or beyond `max_angle`; a road user still within the region; which carrier it entered from, which the caller states; a crossing whose entry the recording does not show, for which the heading change since entry is unknown.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    its footprint overlaps the region, rel.occupies: atoms ['rel.occupies'], concepts []
    integrated from its yaw rate: atoms ['kin.yaw_rate'], concepts []

  No magnitude below is this file's own: parameters are formals the caller fills.

  How the words are written:
    "its footprint overlaps the region": `occ` = rel_occupies(x, i).
    "it leaves the region (... at the observation before and not at this one)": `rises (¬occ)`, ¬occ
      here and not at the previous observation, i.e. occ at the previous one; it holds at the exit
      observation only, ending at the next.
    "the magnitude of its heading change since its entry, the observation at which the overlap last
      became true, integrated from its yaw rate with sampling step bound `step`":
      `|headingSince x step occ|`; an entry the recording does not show leaves it unknown, as the
      contract's last exclusion says.
    "is below `max_angle`": strict `<` against the parameter.
  No choice was left open beyond these words; no narrowing is declared.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.motion.straight_through_region

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aX : Arg := .var "x"
def aI : Arg := .var "i"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
def pStep : Term := .param "step"
def pMaxAngle : Term := .param "max_angle"

/-- Its footprint overlaps the region. -/
def occ : Formula := .atom "rel_occupies" [aX, aI] []

/-- It leaves the region: the overlap held at the observation before and does not here. -/
def leaves : Formula := .rises (.not occ)

/-- The magnitude of its heading change since its entry is below `max_angle`. -/
def straight : Formula := .cmp (.abs (.headingSince "x" pStep occ)) .lt pMaxAngle

def body : Formula := .and leaves straight

def concept : Concept :=
  { id := "drv.motion.straight_through_region"
    contract := "A road user has travelled straight through a region, such as an intersection the caller passes: at the observation it leaves the region (its footprint overlaps the region, rel.occupies, at the observation before and not at this one), and the magnitude of its heading change since its entry, the observation at which the overlap last became true, integrated from its yaw rate with sampling step bound `step`, is below `max_angle`, the heading change below which a crossing counts as straight. The act begins at the entry, the observation at which the overlap last became true. The act is recognized at the observation it leaves the region. The concept holds only at the exit observation, ending at the next observation. Conduct before the entry is not read. Not denoted: a turn, a heading change at or beyond `max_angle`; a road user still within the region; which carrier it entered from, which the caller states; a crossing whose entry the recording does not show, for which the heading change since entry is unknown."
    definition := none
    args := [("x", .track), ("i", .region)]
    params := [⟨"step", .second⟩, ⟨"max_angle", .degree⟩]
    body := .formula body
    residues := []  -- the record's, verbatim; not yours to change
    narrowings := []  -- one { span := "<words of the contract>", why := "<why>", kind := "reading" } per reading you chose that the contract leaves open, explained in the header
    supersedes := none }

end TrafficSpec.Concepts.motion.straight_through_region
