/-
  drv.lane.entering_adjacent_lane — Road user a, occupying lane r1, begins to move into lane r2, the neighbouring lane of the same direction on side s of r1 (s left or right): the event of a's footprint first reaching into r2 from r1. It is observed with a's footprint occupancy (rel.occupies) and the lanes' adjacency (st.lane_adjacency): r2 is r1's neighbour on side s, a's footprint overlaps both r1 and r2 at the observation, and at the previous observation it overlapped r1 and did not overlap r2. The event is recognized at the first observation at which a's footprint overlaps r2, and conduct before the previous observation is not read. The concept holds at that observation only, and not again until a's footprint has ceased to overlap r2 and again comes to overlap it from r1. It says nothing of whether a completes the move, of its signal, of its speed, or of why it moves. Not denoted: a road user that comes into r2 from elsewhere than r1; one that stays within r1; a lane r2 that is not r1's neighbour of the same direction on side s, such as an opposing lane. Where a's overlap with either lane at the observation or at the previous one is unobserved, where there is no previous observation, or where the adjacency of the two lanes is not observed, it is unknown.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    a's footprint occupancy (rel.occupies): atoms ['rel.occupies'], concepts []
    the lanes' adjacency (st.lane_adjacency): atoms ['st.lane_adjacency'], concepts []

  No magnitude below is this file's own: parameters are formals the caller fills.

  How the contract is written:
    - "r2 is r1's neighbour on side s": `st_lane_adjacency r1 s r2` — the literal formal s fills
      the side position; unknown where the adjacency is not observed.
    - "a's footprint overlaps both r1 and r2 at the observation": `rel_occupies a r1`,
      `rel_occupies a r2`.
    - "at the previous observation it overlapped r1 and did not overlap r2": the formula language
      has no `previous` operator, only the edge `rises φ` (φ here, not at the previous observation).
      `rises (rel_occupies a r2)` is "overlaps r2 here and not at the previous observation";
      `rel_occupies a r1 ∧ ¬ rises (rel_occupies a r1)` is "overlaps r1 here and at the previous
      observation" (with the overlap true here, ¬rises is the previous value). Only the previous
      observation is read, as the contract states.
    - holding at the first overlap only, and not again until a has left r2 and comes back from r1,
      follows from the edge on r2.
    - unknowns: `rises` at the first observation of a trace is truncated (unknown), and every atom
      read is unknown where unobserved; the conjunction is three-valued, so an unknown read leaves
      the concept unknown wherever it decides the outcome.
  No narrowing: every choice above is the contract's own words.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.lane.entering_adjacent_lane

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aA : Arg := .var "a"
def aR1 : Arg := .var "r1"
def aR2 : Arg := .var "r2"
def aS : Arg := .var "s"

/-- r2 is r1's neighbouring lane of the same direction on side s (st.lane_adjacency). -/
def adjacent : Formula := .atom "st_lane_adjacency" [aR1, aS, aR2] []

/-- a's footprint overlaps r1 (rel.occupies). -/
def inR1 : Formula := .atom "rel_occupies" [aA, aR1] []

/-- a's footprint overlaps r2 (rel.occupies). -/
def inR2 : Formula := .atom "rel_occupies" [aA, aR2] []

/-- a's footprint overlaps r1 here and at the previous observation: with `inR1` true here,
    `not (rises inR1)` is exactly "inR1 at the previous observation". -/
def stayedInR1 : Formula := .and inR1 (.not (.rises inR1))

/-- a's footprint overlaps r2 here and did not at the previous observation. -/
def reachesR2 : Formula := .rises inR2

/-- The event: r2 is r1's s-side neighbour; a overlaps r1 and r2 here; at the previous
    observation it overlapped r1 and not r2. -/
def body : Formula := .and adjacent (.and stayedInR1 reachesR2)

def concept : Concept :=
  { id := "drv.lane.entering_adjacent_lane"
    contract := "Road user a, occupying lane r1, begins to move into lane r2, the neighbouring lane of the same direction on side s of r1 (s left or right): the event of a's footprint first reaching into r2 from r1. It is observed with a's footprint occupancy (rel.occupies) and the lanes' adjacency (st.lane_adjacency): r2 is r1's neighbour on side s, a's footprint overlaps both r1 and r2 at the observation, and at the previous observation it overlapped r1 and did not overlap r2. The event is recognized at the first observation at which a's footprint overlaps r2, and conduct before the previous observation is not read. The concept holds at that observation only, and not again until a's footprint has ceased to overlap r2 and again comes to overlap it from r1. It says nothing of whether a completes the move, of its signal, of its speed, or of why it moves. Not denoted: a road user that comes into r2 from elsewhere than r1; one that stays within r1; a lane r2 that is not r1's neighbour of the same direction on side s, such as an opposing lane. Where a's overlap with either lane at the observation or at the previous one is unobserved, where there is no previous observation, or where the adjacency of the two lanes is not observed, it is unknown."
    definition := none
    args := [("a", .track), ("r1", .region), ("r2", .region), ("s", .literal ["left", "right"])]
    params := []
    body := .formula body
    residues := []  -- the record's, verbatim; not yours to change
    narrowings := []  -- one { span := "<words of the contract>", why := "<why>", kind := "reading" } per reading you chose that the contract leaves open, explained in the header
    supersedes := none }

end TrafficSpec.Concepts.lane.entering_adjacent_lane
