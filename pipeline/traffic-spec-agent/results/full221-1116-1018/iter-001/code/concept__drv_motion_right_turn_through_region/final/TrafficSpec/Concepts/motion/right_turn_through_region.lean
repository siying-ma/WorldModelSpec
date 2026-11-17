/-
  drv.motion.right_turn_through_region — Road user a has made a turn to the right through region r, recognized as it leaves r. The act begins at the observation at which a's footprint came to overlap r (rel.occupies), having not overlapped it at the previous observation: its entry into r. The act is recognized at the observation at which a's footprint does not overlap r, having overlapped it at the previous observation: its exit from r. The concept holds at that observation only, and not again until a has entered r again and left it. At that observation the heading change of a since its entry into r, in degrees and positive to the left, integrated from its yaw rate (kin.yaw_rate) with no interval between consecutive observations longer than step, lies in the band from minus u_turn_min exclusive to minus turn_min inclusive: a turn to the right by at least turn_min and by less than u_turn_min, so that a passage whose heading changes too little to be a turn and a reversal of direction both lie outside it. Conduct before the entry is not read. It denotes the change of a's heading between its entry into r and its exit only: it says nothing of the lanes a uses, of its speed, of its class, or of why it turns. Not denoted: a passage through r whose heading change is above minus turn_min, such as one straight through or a turn to the left; a heading change of minus u_turn_min or less, which is a reversal of direction; an observation at which a is still in r. Where the entry was not observed (it lies before the recording, or a's overlap with r was unknown at an observation since), where an interval between consecutive observations since the observation before the entry is longer than step, or where a yaw rate since the entry is missing, it is unknown.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    a's footprint came to overlap r (rel.occupies): atoms ['rel.occupies'], concepts []
    integrated from its yaw rate (kin.yaw_rate): atoms ['kin.yaw_rate'], concepts []

  Writing:
    entry into r   = the latest definite rise of rel_occupies(a, r), the onset `headingSince` reads;
    exit from r    = rises (not rel_occupies(a, r)): not overlapping here, overlapping before;
    heading change = headingSince a step (rel_occupies(a, r)), integrated from kin_yaw_rate;
    band           = −u_turn_min < change ≤ −turn_min.
  No choice beyond the contract's words was needed: no narrowing.

  No magnitude below is this file's own: parameters are formals the caller fills.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.motion.right_turn_through_region

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aA : Arg := .var "a"
def aR : Arg := .var "r"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
def pStep : Term := .param "step"
def pTurnMin : Term := .param "turn_min"
def pUTurnMin : Term := .param "u_turn_min"

/-- a's footprint overlaps r (rel.occupies). -/
def inR : Formula := .atom "rel_occupies" [aA, aR] []

/-- The exit: a does not overlap r here, having overlapped it at the previous observation. A
    `rises` holds at that observation only, and not again until a has entered and left r again. -/
def exitR : Formula := .rises (.not inR)

/-- The heading change of a (degrees, left positive) since its entry into r — the latest definite
    rise of its overlap with r — integrated from kin.yaw_rate with no interval longer than step.
    Unknown where the entry is unobserved or the overlap unknown since, where an interval from the
    observation before the entry is longer than step, or where a yaw rate since is missing. -/
def turned : Term := .headingSince "a" pStep inR

/-- At the exit, the heading change lies in (−u_turn_min, −turn_min]. -/
def body : Formula :=
  .and exitR
    (.and (.cmp turned .le (.neg pTurnMin))
          (.cmp turned .gt (.neg pUTurnMin)))

def concept : Concept :=
  { id := "drv.motion.right_turn_through_region"
    contract := "Road user a has made a turn to the right through region r, recognized as it leaves r. The act begins at the observation at which a's footprint came to overlap r (rel.occupies), having not overlapped it at the previous observation: its entry into r. The act is recognized at the observation at which a's footprint does not overlap r, having overlapped it at the previous observation: its exit from r. The concept holds at that observation only, and not again until a has entered r again and left it. At that observation the heading change of a since its entry into r, in degrees and positive to the left, integrated from its yaw rate (kin.yaw_rate) with no interval between consecutive observations longer than step, lies in the band from minus u_turn_min exclusive to minus turn_min inclusive: a turn to the right by at least turn_min and by less than u_turn_min, so that a passage whose heading changes too little to be a turn and a reversal of direction both lie outside it. Conduct before the entry is not read. It denotes the change of a's heading between its entry into r and its exit only: it says nothing of the lanes a uses, of its speed, of its class, or of why it turns. Not denoted: a passage through r whose heading change is above minus turn_min, such as one straight through or a turn to the left; a heading change of minus u_turn_min or less, which is a reversal of direction; an observation at which a is still in r. Where the entry was not observed (it lies before the recording, or a's overlap with r was unknown at an observation since), where an interval between consecutive observations since the observation before the entry is longer than step, or where a yaw rate since the entry is missing, it is unknown."
    definition := none
    args := [("a", .track), ("r", .region)]
    params := [⟨"step", .second⟩, ⟨"turn_min", .degree⟩, ⟨"u_turn_min", .degree⟩]
    body := .formula body
    residues := []  -- the record's, verbatim; not yours to change
    narrowings := []  -- one { span := "<words of the contract>", why := "<why>", kind := "reading" } per reading you chose that the contract leaves open, explained in the header
    supersedes := none }

end TrafficSpec.Concepts.motion.right_turn_through_region
