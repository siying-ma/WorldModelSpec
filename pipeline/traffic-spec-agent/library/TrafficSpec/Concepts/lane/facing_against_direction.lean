/-
  drv.lane.facing_against_direction — A road user points against the designated direction of travel of a carrier at the observation: the cosine of the angle between its heading (kin.heading) and the carrier's designated direction (st.lane_direction), read as the dot product of the two normalised vectors, is below minus `cos_tol`, the cosine of the largest angle off exactly opposed that still counts as against. Not denoted: occupancy of the carrier, which the caller states; the direction of motion, since a vehicle pointing against the direction points against it whether it moves forwards or backs; travel across the carrier, with headings near perpendicular to it; a carrier with no designated direction, for which the concept is unknown.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    its heading (kin.heading): atoms ['kin.heading'], concepts []
    the carrier's designated direction (st.lane_direction): atoms ['st.lane_direction'], concepts []

  No magnitude below is this file's own: parameters are formals the caller fills.

  Writing: `kin_heading` and `st_lane_direction` are read through their "x" and "y" components
  (Core's measures read each normalised); the cosine is hx·dx + hy·dy, and the body is that sum
  strictly below `-cos_tol`. Either vector unobserved, or `c` carrying no designated direction,
  leaves a component unknown and so the comparison unknown. No choice beyond the contract's words.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.lane.facing_against_direction

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aX : Arg := .var "x"
def aC : Arg := .var "c"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
def pCosTol : Term := .param "cos_tol"

/-- The heading of `x`, normalised, component `k`. -/
def heading (k : String) : Term := .measure "kin_heading" [aX, .lit k]

/-- The designated direction of `c`, normalised, component `k`. -/
def direction (k : String) : Term := .measure "st_lane_direction" [aC, .lit k]

/-- The cosine of the angle between the heading and the designated direction: the dot product of
    the two normalised vectors. -/
def cosine : Term :=
  .add (.mul (heading "x") (direction "x")) (.mul (heading "y") (direction "y"))

/-- The cosine below minus `cos_tol`. -/
def body : Formula := .cmp cosine .lt (.neg pCosTol)

def concept : Concept :=
  { id := "drv.lane.facing_against_direction"
    contract := "A road user points against the designated direction of travel of a carrier at the observation: the cosine of the angle between its heading (kin.heading) and the carrier's designated direction (st.lane_direction), read as the dot product of the two normalised vectors, is below minus `cos_tol`, the cosine of the largest angle off exactly opposed that still counts as against. Not denoted: occupancy of the carrier, which the caller states; the direction of motion, since a vehicle pointing against the direction points against it whether it moves forwards or backs; travel across the carrier, with headings near perpendicular to it; a carrier with no designated direction, for which the concept is unknown."
    definition := none
    args := [("x", .track), ("c", .region)]
    params := [⟨"cos_tol", .ratio⟩]
    body := .formula body
    residues := []  -- the record's, verbatim; not yours to change
    narrowings := []  -- one { span := "<words of the contract>", why := "<why>", kind := "reading" } per reading you chose that the contract leaves open, explained in the header
    supersedes := none }

end TrafficSpec.Concepts.lane.facing_against_direction
