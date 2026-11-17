/-
  drv.motion.right_turn_through_region — Road user a has made a turn to the right through region r, recognized as it leaves r. The act begins at the observation at which a's footprint came to overlap r (rel.occupies), having not overlapped it at the previous observation: its entry into r. The act is recognized at the observation at which a's footprint does not overlap r, having overlapped it at the previous observation: its exit from r. The concept holds at that observation only, and not again until a has entered r again and left it. At that observation the heading change of a since its entry into r, in degrees and positive to the left, integrated from its yaw rate (kin.yaw_rate) with no interval between consecutive observations longer than step, lies in the band from minus u_turn_min exclusive to minus turn_min inclusive: a turn to the right by at least turn_min and by less than u_turn_min, so that a passage whose heading changes too little to be a turn and a reversal of direction both lie outside it. Conduct before the entry is not read. It denotes the change of a's heading between its entry into r and its exit only: it says nothing of the lanes a uses, of its speed, of its class, or of why it turns. Not denoted: a passage through r whose heading change is above minus turn_min, such as one straight through or a turn to the left; a heading change of minus u_turn_min or less, which is a reversal of direction; an observation at which a is still in r. Where the entry was not observed (it lies before the recording, or a's overlap with r was unknown at an observation since), where an interval between consecutive observations since the observation before the entry is longer than step, or where a yaw rate since the entry is missing, it is unknown.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    a's footprint came to overlap r (rel.occupies): atoms ['rel.occupies'], concepts []
    integrated from its yaw rate (kin.yaw_rate): atoms ['kin.yaw_rate'], concepts []

  No magnitude below is this file's own: parameters are formals the caller fills.

  How the contract is written:
    - entry into r: `rises (rel_occupies a r)` — overlap here and not at the previous observation.
    - exit from r (the recognition, and the only observation at which the concept can hold):
      `rises (not (rel_occupies a r))` — no overlap here, overlap at the previous observation.
      Holding there only, and not again until a re-enters and leaves, follows from the edge.
    - heading change since the entry: `headingSince a step (rises (rel_occupies a r))`, the signed
      yaw-rate integral (left positive) from the latest definite entry; `step` is the formal
      parameter, passed directly as the sampling bound. Its unknowns are the contract's: an entry
      not observed (before the recording, or hidden by an unknown overlap since), an interval longer
      than `step`, a yaw rate missing since the entry.
    - the band: `−u_turn_min < Δψ ≤ −turn_min`, the lower end exclusive and the upper inclusive,
      as the contract states.
  No narrowing: every choice above is the contract's own words.
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
def occ : Formula := .atom "rel_occupies" [aA, aR] []

/-- The entry into r: overlap here, none at the previous observation. -/
def entry : Formula := .rises occ

/-- The exit from r: no overlap here, overlap at the previous observation. -/
def exitR : Formula := .rises (.not occ)

/-- The signed heading change of a since its entry into r (degrees, left positive), integrated
    from its yaw rate with no interval longer than `step`; unknown where the entry or a yaw rate
    since is unobserved. -/
def turned : Term := .headingSince "a" pStep entry

/-- At the exit, the heading change since the entry lies in (−u_turn_min, −turn_min]. -/
def body : Formula :=
  .and exitR
    (.and (.cmp turned .gt (.neg pUTurnMin))
          (.cmp turned .le (.neg pTurnMin)))

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
