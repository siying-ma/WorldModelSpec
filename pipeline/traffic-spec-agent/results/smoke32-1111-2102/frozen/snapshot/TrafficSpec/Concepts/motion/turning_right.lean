/-
  drv.motion.turning_right — Road user a is turning to the right at an observation: it moves and its heading turns to the right. Measured as a not at rest (drv.motion.at_rest with the speed tolerance does not hold) and its yaw rate (kin.yaw_rate, deg/s, left positive) at or below the negative of the yaw tolerance, the rate below which a change of heading counts as none. A state at each observation while a turn is under way, not a completed manoeuvre: it does not say how far the turn goes, and it holds alike where the road user follows a bend of the road to the right. Not a stand-in for the turn indicator or for a declared intention to turn.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    a not at rest (drv.motion.at_rest with the speed tolerance does not hold): atoms [], concepts ['drv.motion.at_rest']
    its yaw rate (kin.yaw_rate, deg/s, left positive) at or below the negative of the yaw tolerance: atoms ['kin.yaw_rate'], concepts []

  The body is the conjunction, at the observation judged, of the negation of
  drv_motion_at_rest(a; speed_tolerance) and the comparison kin_yaw_rate(a) ≤ −yaw_tolerance. It reads
  no turn indicator, no declared intention and no road geometry, so a bend followed to the right
  counts alike. No choice beyond the contract's words was made.

  No magnitude below is this file's own: parameters are formals the caller fills.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.motion.turning_right

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aA : Arg := .var "a"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
def pYawTolerance : Term := .param "yaw_tolerance"
def pSpeedTolerance : Term := .param "speed_tolerance"

/-- a is not at rest (drv.motion.at_rest with the speed tolerance does not hold) and its yaw rate
    is at or below the negative of the yaw tolerance at this observation. -/
def body : Formula :=
  .and
    (.not (.derived "drv_motion_at_rest" [aA] [pSpeedTolerance]))
    (.cmp (.measure "kin_yaw_rate" [aA]) .le (.neg pYawTolerance))

def concept : Concept :=
  { id := "drv.motion.turning_right"
    contract := "Road user a is turning to the right at an observation: it moves and its heading turns to the right. Measured as a not at rest (drv.motion.at_rest with the speed tolerance does not hold) and its yaw rate (kin.yaw_rate, deg/s, left positive) at or below the negative of the yaw tolerance, the rate below which a change of heading counts as none. A state at each observation while a turn is under way, not a completed manoeuvre: it does not say how far the turn goes, and it holds alike where the road user follows a bend of the road to the right. Not a stand-in for the turn indicator or for a declared intention to turn."
    definition := none
    args := [("a", .track)]
    params := [⟨"yaw_tolerance", .degreePerSecond⟩, ⟨"speed_tolerance", .metrePerSecond⟩]
    body := .formula body
    residues := []  -- the record's, verbatim; not yours to change
    narrowings := []  -- one { span := "<words of the contract>", why := "<why>", kind := "reading" } per reading you chose that the contract leaves open, explained in the header
    supersedes := none }

end TrafficSpec.Concepts.motion.turning_right
