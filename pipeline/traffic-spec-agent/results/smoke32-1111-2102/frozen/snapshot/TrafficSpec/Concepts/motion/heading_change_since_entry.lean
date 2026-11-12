/-
  drv.motion.heading_change_since_entry — The heading change of road user a since it entered region r: the signed change of the direction its body points (degrees, left positive), accumulated from the observation at which a's footprint last came to overlap r, where it is zero, to the observation, whether or not a still overlaps r. Measured by integrating a's yaw rate (kin.yaw_rate, deg/s, left positive) from the observation at which a's occupancy of r (rel.occupies) last became true, with the step bound, the largest interval between consecutive observations integrated across. It is unknown where that entry is not observed (a occupied r from the start of the recording, or an unknown occupancy could hide the entry), where an interval between consecutive observations since the observation before the entry exceeds the step bound, or where a yaw rate since the entry is missing. Not a stand-in for a turn: it is a magnitude that a caller bounds, and a road user that follows a bend of the way through r accumulates the bend's heading change.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    the observation at which a's occupancy of r (rel.occupies) last became true: atoms ['rel.occupies'], concepts []
    integrating a's yaw rate (kin.yaw_rate, deg/s, left positive): atoms ['kin.yaw_rate'], concepts []

  No magnitude below is this file's own: parameters are formals the caller fills.

  The writing. The contract's quantity is Core's `Term.headingSince` as it stands: the subject is
  the track formal a, the onset ψ is a's occupancy of r (`rel_occupies a r`), so the value counts
  from zero at the observation at which that occupancy last rose definitely and runs on after a
  leaves r; the step bound is the formal parameter `step`, passed directly. The operator's own
  unknowns are the contract's: an entry not observed (occupied from the start of the recording, or
  hidden by an unknown occupancy), an interval since the observation before the entry longer than
  the step bound, a missing yaw rate since the entry. No choice is left open; no narrowing.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.motion.heading_change_since_entry

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aA : Arg := .var "a"
def aR : Arg := .var "r"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
def pStep : Term := .param "step"

/-- a's occupancy of r: its rise is the entry the heading change counts from. -/
def occupiesR : Formula := .atom "rel_occupies" [aA, aR] []

/-- The heading change of a, integrated from its yaw rate since its occupancy of r last rose. -/
def body : Term := .headingSince "a" pStep occupiesR

def concept : Concept :=
  { id := "drv.motion.heading_change_since_entry"
    contract := "The heading change of road user a since it entered region r: the signed change of the direction its body points (degrees, left positive), accumulated from the observation at which a's footprint last came to overlap r, where it is zero, to the observation, whether or not a still overlaps r. Measured by integrating a's yaw rate (kin.yaw_rate, deg/s, left positive) from the observation at which a's occupancy of r (rel.occupies) last became true, with the step bound, the largest interval between consecutive observations integrated across. It is unknown where that entry is not observed (a occupied r from the start of the recording, or an unknown occupancy could hide the entry), where an interval between consecutive observations since the observation before the entry exceeds the step bound, or where a yaw rate since the entry is missing. Not a stand-in for a turn: it is a magnitude that a caller bounds, and a road user that follows a bend of the way through r accumulates the bend's heading change."
    definition := none
    args := [("a", .track), ("r", .region)]
    params := [⟨"step", .second⟩]
    body := .quantity body
    residues := []  -- the record's, verbatim; not yours to change
    narrowings := []  -- one { span := "<words of the contract>", why := "<why>", kind := "reading" } per reading you chose that the contract leaves open, explained in the header
    supersedes := none }

end TrafficSpec.Concepts.motion.heading_change_since_entry
