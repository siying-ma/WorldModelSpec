/-
  drv.lane.heading_offset_from_direction — The signed departure of a road user's heading from a carrier's designated direction of travel at the observation, left positive: the sine of the angle from the carrier's direction (st.lane_direction) to the road user's heading (kin.heading), computed as the cross product of the two normalised vectors, the direction's first component times the heading's second minus the direction's second component times the heading's first. A ratio between -1 and 1 up to the normalisation factor both atoms carry; positive where the heading points to the left of the direction, negative where it points to the right, zero where it is aligned with or exactly opposed to it. Not denoted: occupancy of the carrier, which the caller states; whether the road user points with or against the direction, since a heading and its mirror across the perpendicular give the same value, which the caller states where it matters; the direction of motion, since the concept reads where the road user points, not where it moves; a carrier with no designated direction, for which the value is unknown.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    the road user's heading (kin.heading): atoms ['kin.heading'], concepts []
    the carrier's direction (st.lane_direction): atoms ['st.lane_direction'], concepts []

  Writing: both atoms are read by component (`.lit "x"`, `.lit "y"`), each normalised by Core as
  its contract states; the body is the contract's cross product dirX·headY − dirY·headX verbatim.
  A carrier with no designated direction leaves `st_lane_direction` absent, so the value is
  unknown. No choice was left open: no narrowing.

  No magnitude below is this file's own: parameters are formals the caller fills.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.lane.heading_offset_from_direction

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aX : Arg := .var "x"
def aC : Arg := .var "c"

/-- The normalised designated direction of the carrier `c`, by component. -/
def dirX : Term := .measure "st_lane_direction" [aC, .lit "x"]
def dirY : Term := .measure "st_lane_direction" [aC, .lit "y"]

/-- The normalised heading of the road user `x`, by component. -/
def headX : Term := .measure "kin_heading" [aX, .lit "x"]
def headY : Term := .measure "kin_heading" [aX, .lit "y"]

/-- The cross product direction × heading: the direction's first component times the heading's
    second minus the direction's second component times the heading's first (left positive). -/
def body : Term := .sub (.mul dirX headY) (.mul dirY headX)

def concept : Concept :=
  { id := "drv.lane.heading_offset_from_direction"
    contract := "The signed departure of a road user's heading from a carrier's designated direction of travel at the observation, left positive: the sine of the angle from the carrier's direction (st.lane_direction) to the road user's heading (kin.heading), computed as the cross product of the two normalised vectors, the direction's first component times the heading's second minus the direction's second component times the heading's first. A ratio between -1 and 1 up to the normalisation factor both atoms carry; positive where the heading points to the left of the direction, negative where it points to the right, zero where it is aligned with or exactly opposed to it. Not denoted: occupancy of the carrier, which the caller states; whether the road user points with or against the direction, since a heading and its mirror across the perpendicular give the same value, which the caller states where it matters; the direction of motion, since the concept reads where the road user points, not where it moves; a carrier with no designated direction, for which the value is unknown."
    definition := none
    args := [("x", .track), ("c", .region)]
    params := []
    body := .quantity body
    residues := []  -- the record's, verbatim; not yours to change
    narrowings := []  -- one { span := "<words of the contract>", why := "<why>", kind := "reading" } per reading you chose that the contract leaves open, explained in the header
    supersedes := none }

end TrafficSpec.Concepts.lane.heading_offset_from_direction
