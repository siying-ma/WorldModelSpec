/-
  drv.lane.entering_adjacent_lane — Road user a, occupying lane r1, begins to move into lane r2, the neighbouring lane of the same direction on side s of r1 (s left or right): the event of a's footprint first reaching into r2 from r1. It is observed with a's footprint occupancy (rel.occupies) and the lanes' adjacency (st.lane_adjacency): r2 is r1's neighbour on side s, a's footprint overlaps both r1 and r2 at the observation, and at the previous observation it overlapped r1 and did not overlap r2. The concept holds at that observation only, and not again until a's footprint has ceased to overlap r2 and again comes to overlap it from r1. It says nothing of whether a completes the move, of its signal, of its speed, or of why it moves. Not denoted: a road user that comes into r2 from elsewhere than r1; one that stays within r1; a lane r2 that is not r1's neighbour of the same direction on side s, such as an opposing lane. Where a's overlap with either lane at the observation or at the previous one is unobserved, or the adjacency of the two lanes is not observed, it is unknown.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    a's footprint occupancy (rel.occupies): atoms ['rel.occupies'], concepts []
    the lanes' adjacency (st.lane_adjacency): atoms ['st.lane_adjacency'], concepts []

  No magnitude below is this file's own: parameters are formals the caller fills.

  How the words are written:
    "r2 is r1's neighbour on side s" — `st_lane_adjacency r1 s r2` (r2 is lane r1's neighbour of the
      same direction on side s; unknown where r1's neighbour on that side is not observed).
    "a's footprint overlaps both r1 and r2 at the observation, and at the previous observation it
      overlapped r1 and did not overlap r2" — `rel_occupies a r1` here, and the rise of
      ψ := `rel_occupies a r2 ∨ ¬ rel_occupies a r1`: ψ here and not at the previous observation.
      ψ false at the previous observation is exactly "overlapped r1 and did not overlap r2" there;
      ψ true here together with `rel_occupies a r1` here is exactly "overlaps r2" here. So the
      conjunction is the contract's two-observation condition, written with the one operator the
      language has for "the previous observation" (`rises`). At the first observation of a trace
      the previous one is unobserved, and the rise is unknown, as the contract states.
    "holds at that observation only, and not again until …" — follows from the condition: it
      requires a's footprint off r2 at the previous observation, so it cannot hold twice without
      a's footprint ceasing to overlap r2 in between.
  No reading was chosen that the contract leaves open: no narrowings.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.lane.entering_adjacent_lane

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aA : Arg := .var "a"
def aR1 : Arg := .var "r1"
def aR2 : Arg := .var "r2"
def aS : Arg := .var "s"

/-- r2 is r1's neighbouring lane of the same direction on side s. -/
def adjacent : Formula := .atom "st_lane_adjacency" [aR1, aS, aR2] []
/-- a's footprint overlaps r1. -/
def inR1 : Formula := .atom "rel_occupies" [aA, aR1] []
/-- a's footprint overlaps r2. -/
def inR2 : Formula := .atom "rel_occupies" [aA, aR2] []

/-- Adjacent, a in r1 now, and `inR2 ∨ ¬inR1` rising: now in r2, previously in r1 and not in r2. -/
def body : Formula :=
  .and adjacent (.and inR1 (.rises (.or inR2 (.not inR1))))

def concept : Concept :=
  { id := "drv.lane.entering_adjacent_lane"
    contract := "Road user a, occupying lane r1, begins to move into lane r2, the neighbouring lane of the same direction on side s of r1 (s left or right): the event of a's footprint first reaching into r2 from r1. It is observed with a's footprint occupancy (rel.occupies) and the lanes' adjacency (st.lane_adjacency): r2 is r1's neighbour on side s, a's footprint overlaps both r1 and r2 at the observation, and at the previous observation it overlapped r1 and did not overlap r2. The concept holds at that observation only, and not again until a's footprint has ceased to overlap r2 and again comes to overlap it from r1. It says nothing of whether a completes the move, of its signal, of its speed, or of why it moves. Not denoted: a road user that comes into r2 from elsewhere than r1; one that stays within r1; a lane r2 that is not r1's neighbour of the same direction on side s, such as an opposing lane. Where a's overlap with either lane at the observation or at the previous one is unobserved, or the adjacency of the two lanes is not observed, it is unknown."
    definition := none
    args := [("a", .track), ("r1", .region), ("r2", .region), ("s", .literal ["left", "right"])]
    params := []
    body := .formula body
    residues := []  -- the record's, verbatim; not yours to change
    narrowings := []  -- one { span := "<words of the contract>", why := "<why>", kind := "reading" } per reading you chose that the contract leaves open, explained in the header
    supersedes := none }

end TrafficSpec.Concepts.lane.entering_adjacent_lane
