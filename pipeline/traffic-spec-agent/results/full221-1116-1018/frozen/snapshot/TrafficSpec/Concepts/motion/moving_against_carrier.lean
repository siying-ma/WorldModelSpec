/-
  drv.motion.moving_against_carrier — Road user a moves against the designated direction of travel of carrier region r: part of its motion runs opposite to r's designated direction. It is observed as the component of a's velocity (kin.velocity) along r's designated direction (st.lane_direction), the dot product of the velocity with the direction as a formula reads it normalised, being below minus speed_tol: the part of a's motion that runs against r's direction exceeds the speed the source cannot tell from rest. It is a state at one observation: it says nothing of whether a occupies r, of where a's body points, of the gear selected, of how long a has moved so, or of why. Not denoted: a road user at rest; one whose velocity component against r's direction is at or below speed_tol, such as one moving along r's direction or straight across it. Where r carries no designated direction, or a's velocity is unobserved, it is unknown.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    the component of a's velocity (kin.velocity): atoms ['kin.velocity'], concepts []
    r's designated direction (st.lane_direction): atoms ['st.lane_direction'], concepts []

  Body: (kin_velocity a x)·(st_lane_direction r x) + (kin_velocity a y)·(st_lane_direction r y)
  < −speed_tol. The direction is read normalised by Core's measure (`Geom.unit`), as the contract
  states; an unobserved velocity or a missing direction makes a factor unknown, so the comparison is
  unknown. No occupancy, heading, gear or duration is read. No choice was left open: no narrowings.

  No magnitude below is this file's own: parameters are formals the caller fills.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.motion.moving_against_carrier

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aA : Arg := .var "a"
def aR : Arg := .var "r"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
def pSpeedTol : Term := .param "speed_tol"

/-- The component of a's velocity along r's designated direction (as a formula reads it, normalised):
    v.x · d.x + v.y · d.y, in m/s. -/
def alongComponent : Term :=
  .add (.mul (.measure "kin_velocity" [aA, .lit "x"]) (.measure "st_lane_direction" [aR, .lit "x"]))
       (.mul (.measure "kin_velocity" [aA, .lit "y"]) (.measure "st_lane_direction" [aR, .lit "y"]))

/-- The component is below minus speed_tol. -/
def body : Formula := .cmp alongComponent .lt (.neg pSpeedTol)

def concept : Concept :=
  { id := "drv.motion.moving_against_carrier"
    contract := "Road user a moves against the designated direction of travel of carrier region r: part of its motion runs opposite to r's designated direction. It is observed as the component of a's velocity (kin.velocity) along r's designated direction (st.lane_direction), the dot product of the velocity with the direction as a formula reads it normalised, being below minus speed_tol: the part of a's motion that runs against r's direction exceeds the speed the source cannot tell from rest. It is a state at one observation: it says nothing of whether a occupies r, of where a's body points, of the gear selected, of how long a has moved so, or of why. Not denoted: a road user at rest; one whose velocity component against r's direction is at or below speed_tol, such as one moving along r's direction or straight across it. Where r carries no designated direction, or a's velocity is unobserved, it is unknown."
    definition := none
    args := [("a", .track), ("r", .region)]
    params := [⟨"speed_tol", .metrePerSecond⟩]
    body := .formula body
    residues := []  -- the record's, verbatim; not yours to change
    narrowings := []  -- one { span := "<words of the contract>", why := "<why>", kind := "reading" } per reading you chose that the contract leaves open, explained in the header
    supersedes := none }

end TrafficSpec.Concepts.motion.moving_against_carrier
