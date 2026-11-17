/-
  drv.motion.moving_across_carrier — Road user a moves across the designated direction of travel of carrier region r: a is moving, its speed (kin.speed) above speed_tol, and its velocity (kin.velocity) makes with r's designated direction (st.lane_direction) an angle whose cosine, in absolute value, is at most cos_max: the absolute value of the dot product of the velocity with the normalised direction is at most cos_max times the speed. Either sense of crossing is denoted: the sign of the direction does not matter. It is a state at one observation: it says nothing of whether a occupies r, of where a began or will end its movement, or of how long it has moved so. Not denoted: a road user at rest or moving at or below speed_tol; a road user moving more nearly along r's direction than cos_max allows. Where r carries no designated direction, or a's velocity is not observed, it is unknown.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    its speed (kin.speed) above speed_tol: atoms ['kin.speed'], concepts []
    its velocity (kin.velocity): atoms ['kin.velocity'], concepts []
    r's designated direction (st.lane_direction): atoms ['st.lane_direction'], concepts []

  No magnitude below is this file's own: parameters are formals the caller fills.

  Writing:
    "its speed (kin.speed) above speed_tol" → kin_speed a > speed_tol (strict: at or below is not
      denoted).
    "the absolute value of the dot product of the velocity with the normalised direction is at most
      cos_max times the speed" → |vx·dx + vy·dy| ≤ cos_max · kin_speed a, with kin_velocity a's
      components and st_lane_direction r's components (Core reads the direction normalised; an
      absent or zero direction is unknown). The absolute value makes either sense of crossing count.
    No ratio is formed: the cosine bound is written as a bound on a product, as the contract states it.
  No narrowing: the contract states the comparison exactly.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.motion.moving_across_carrier

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aA : Arg := .var "a"
def aR : Arg := .var "r"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
def pSpeedTol : Term := .param "speed_tol"
def pCosMax : Term := .param "cos_max"

/-- The speed of a (kin.speed). -/
def speed : Term := .measure "kin_speed" [aA]

/-- The dot product of a's velocity (kin.velocity) with r's normalised designated direction
    (st.lane_direction, read normalised by Core). -/
def along : Term :=
  .add (.mul (.measure "kin_velocity" [aA, .lit "x"]) (.measure "st_lane_direction" [aR, .lit "x"]))
       (.mul (.measure "kin_velocity" [aA, .lit "y"]) (.measure "st_lane_direction" [aR, .lit "y"]))

/-- a moving (speed above speed_tol), and |v · d| ≤ cos_max · speed: either sense of crossing. -/
def body : Formula :=
  .and (.cmp speed .gt pSpeedTol)
       (.cmp (.abs along) .le (.mul pCosMax speed))

def concept : Concept :=
  { id := "drv.motion.moving_across_carrier"
    contract := "Road user a moves across the designated direction of travel of carrier region r: a is moving, its speed (kin.speed) above speed_tol, and its velocity (kin.velocity) makes with r's designated direction (st.lane_direction) an angle whose cosine, in absolute value, is at most cos_max: the absolute value of the dot product of the velocity with the normalised direction is at most cos_max times the speed. Either sense of crossing is denoted: the sign of the direction does not matter. It is a state at one observation: it says nothing of whether a occupies r, of where a began or will end its movement, or of how long it has moved so. Not denoted: a road user at rest or moving at or below speed_tol; a road user moving more nearly along r's direction than cos_max allows. Where r carries no designated direction, or a's velocity is not observed, it is unknown."
    definition := none
    args := [("a", .track), ("r", .region)]
    params := [⟨"speed_tol", .metrePerSecond⟩, ⟨"cos_max", .ratio⟩]
    body := .formula body
    residues := []  -- the record's, verbatim; not yours to change
    narrowings := []  -- one { span := "<words of the contract>", why := "<why>", kind := "reading" } per reading you chose that the contract leaves open, explained in the header
    supersedes := none }

end TrafficSpec.Concepts.motion.moving_across_carrier
