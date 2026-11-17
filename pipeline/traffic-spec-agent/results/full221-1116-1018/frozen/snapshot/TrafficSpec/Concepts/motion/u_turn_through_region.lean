/-
  drv.motion.u_turn_through_region — Road user a has turned "so as to proceed in the opposite direction" through region r, "whether accomplished by one continuous movement or not", recognized as it leaves r. The act begins at the observation at which a's footprint came to overlap r (rel.occupies), having not overlapped it at the previous observation: its entry into r. The act is recognized at the observation at which a's footprint does not overlap r, having overlapped it at the previous observation: its exit from r. The concept holds at that observation only, and not again until a has entered r again and left it. At that observation the magnitude of the heading change of a since its entry into r, in degrees and positive to the left, integrated from its yaw rate (kin.yaw_rate) with no interval between consecutive observations longer than step, lies in the band from u_turn_min to a full turn minus u_turn_min, both inclusive, so that a turn short of a reversal and a full loop both lie outside it; a reversal to either hand is denoted, and one made in several movements, with halts or backing between them inside r, is denoted where its integrated heading change lies in the band. Conduct before the entry is not read. It denotes the change of a's heading between its entry into r and its exit only: it says nothing of the lanes a uses, of its speed, of its class, or of why it turns. Not denoted: a passage through r whose heading change magnitude is below u_turn_min, such as a turn to the left or the right or a passage straight through; a heading change magnitude above a full turn minus u_turn_min, which is a loop; an observation at which a is still in r. Where the entry was not observed (it lies before the recording, or a's overlap with r was unknown at an observation since), where an interval between consecutive observations since the observation before the entry is longer than step, or where a yaw rate since the entry is missing, it is unknown.

  Based on the posted definition `DEF-NRS-484B-077`: the contract above is this record's reading
  of it, not its text.

  The posted text (the definition's words; the concept denotes its contract):
    “U-turn” means the turning of a vehicle upon a highway so as to proceed in the opposite direction, whether accomplished by one continuous movement or not.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    a's footprint came to overlap r (rel.occupies): atoms ['rel.occupies'], concepts []
    integrated from its yaw rate (kin.yaw_rate): atoms ['kin.yaw_rate'], concepts []

  Literals the contract states (declared; written through a `Units` constructor):
    360 deg — a full turn of the heading: the upper end of the band is a full turn minus u_turn_min, so that a loop is told apart from a reversal

  No magnitude below is this file's own: parameters are formals the caller fills.

  How the contract is written:
    - entry into r: `rises (rel_occupies a r)` — overlap here and not at the previous observation.
    - exit from r (the recognition, and the only observation at which the concept can hold):
      `rises (not (rel_occupies a r))` — no overlap here, overlap at the previous observation.
      Holding there only, and not again until a re-enters and leaves, follows from the edge.
    - heading change since the entry: `abs (headingSince a step (rises (rel_occupies a r)))`, the
      magnitude of the signed yaw-rate integral from the latest definite entry; `step` is the formal
      parameter, passed directly as the sampling bound. Its unknowns are the contract's: an entry
      not observed (before the recording, or hidden by an unknown overlap since), an interval longer
      than `step`, a yaw rate missing since the entry.
    - the band: `u_turn_min ≤ |Δψ| ≤ 360° − u_turn_min`, both inclusive; 360° is the declared literal.
  No narrowing: every choice above is the contract's own words.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.motion.u_turn_through_region

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aA : Arg := .var "a"
def aR : Arg := .var "r"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
def pStep : Term := .param "step"
def pUTurnMin : Term := .param "u_turn_min"

/-- a's footprint overlaps r (rel.occupies). -/
def occ : Formula := .atom "rel_occupies" [aA, aR] []

/-- The entry into r: overlap here, none at the previous observation. -/
def entry : Formula := .rises occ

/-- The exit from r: no overlap here, overlap at the previous observation. -/
def exitR : Formula := .rises (.not occ)

/-- The magnitude of a's heading change since its entry into r, integrated from its yaw rate
    with no interval longer than `step`; unknown where the entry or a yaw rate since is unobserved. -/
def turned : Term := .abs (.headingSince "a" pStep entry)

/-- A full turn of the heading (the record's declared literal). -/
def fullTurn : Term := .lit (Units.degrees 360) .degree

/-- At the exit, the heading change since the entry lies in [u_turn_min, 360° − u_turn_min]. -/
def body : Formula :=
  .and exitR
    (.and (.cmp turned .ge pUTurnMin)
          (.cmp turned .le (.sub fullTurn pUTurnMin)))

def concept : Concept :=
  { id := "drv.motion.u_turn_through_region"
    contract := "Road user a has turned \"so as to proceed in the opposite direction\" through region r, \"whether accomplished by one continuous movement or not\", recognized as it leaves r. The act begins at the observation at which a's footprint came to overlap r (rel.occupies), having not overlapped it at the previous observation: its entry into r. The act is recognized at the observation at which a's footprint does not overlap r, having overlapped it at the previous observation: its exit from r. The concept holds at that observation only, and not again until a has entered r again and left it. At that observation the magnitude of the heading change of a since its entry into r, in degrees and positive to the left, integrated from its yaw rate (kin.yaw_rate) with no interval between consecutive observations longer than step, lies in the band from u_turn_min to a full turn minus u_turn_min, both inclusive, so that a turn short of a reversal and a full loop both lie outside it; a reversal to either hand is denoted, and one made in several movements, with halts or backing between them inside r, is denoted where its integrated heading change lies in the band. Conduct before the entry is not read. It denotes the change of a's heading between its entry into r and its exit only: it says nothing of the lanes a uses, of its speed, of its class, or of why it turns. Not denoted: a passage through r whose heading change magnitude is below u_turn_min, such as a turn to the left or the right or a passage straight through; a heading change magnitude above a full turn minus u_turn_min, which is a loop; an observation at which a is still in r. Where the entry was not observed (it lies before the recording, or a's overlap with r was unknown at an observation since), where an interval between consecutive observations since the observation before the entry is longer than step, or where a yaw rate since the entry is missing, it is unknown."
    definition := some "DEF-NRS-484B-077"
    args := [("a", .track), ("r", .region)]
    params := [⟨"step", .second⟩, ⟨"u_turn_min", .degree⟩]
    body := .formula body
    residues := ["the class of the road user and the way it turns on are not part of the motion; the caller states the class of a and binds r on the way the words name"]  -- the record's, verbatim; not yours to change
    narrowings := []  -- one { span := "<words of the contract>", why := "<why>", kind := "reading" } per reading you chose that the contract leaves open, explained in the header
    supersedes := none }

end TrafficSpec.Concepts.motion.u_turn_through_region
