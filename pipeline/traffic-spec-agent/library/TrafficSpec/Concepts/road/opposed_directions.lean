/-
  drv.road.opposed_directions — The designated directions of two travel carriers point opposite ways: the dot product of their designated directions (st.lane_direction, read normalised, world frame) is below minus opposed_cosine, so the angle between them is wider than the angle whose cosine is minus opposed_cosine. Unknown where either carrier carries no designated direction. Not denoted: the motion or heading of any road user on them, the carriers lying on the same way, or their entering the same intersection: the caller states those.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    the dot product of their designated directions (st.lane_direction, read normalised, world frame) is below minus opposed_cosine: atoms ['st.lane_direction'], concepts []

  Written as: (x₁·x₂ + y₁·y₂) < −opposed_cosine, each component the measure `st_lane_direction`
  of the carrier with selector "x" or "y" (Core reads it normalised, world frame). An absent
  direction leaves its components, hence the comparison, unknown. No choice was left open.

  No magnitude below is this file's own: parameters are formals the caller fills.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.road.opposed_directions

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aC1 : Arg := .var "c1"
def aC2 : Arg := .var "c2"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
def pOpposedCosine : Term := .param "opposed_cosine"

/-- A component of a carrier's designated direction, read normalised (world frame). -/
def dir (c : Arg) (k : String) : Term := .measure "st_lane_direction" [c, .lit k]

/-- The dot product of the two designated directions: the cosine of the angle between them. -/
def dot : Term := .add (.mul (dir aC1 "x") (dir aC2 "x")) (.mul (dir aC1 "y") (dir aC2 "y"))

/-- The dot product below minus opposed_cosine; unknown where either direction is absent. -/
def body : Formula := .cmp dot .lt (.neg pOpposedCosine)

def concept : Concept :=
  { id := "drv.road.opposed_directions"
    contract := "The designated directions of two travel carriers point opposite ways: the dot product of their designated directions (st.lane_direction, read normalised, world frame) is below minus opposed_cosine, so the angle between them is wider than the angle whose cosine is minus opposed_cosine. Unknown where either carrier carries no designated direction. Not denoted: the motion or heading of any road user on them, the carriers lying on the same way, or their entering the same intersection: the caller states those."
    definition := none
    args := [("c1", .region), ("c2", .region)]
    params := [⟨"opposed_cosine", .ratio⟩]
    body := .formula body
    residues := []  -- the record's, verbatim; not yours to change
    narrowings := []
    supersedes := none }

end TrafficSpec.Concepts.road.opposed_directions
