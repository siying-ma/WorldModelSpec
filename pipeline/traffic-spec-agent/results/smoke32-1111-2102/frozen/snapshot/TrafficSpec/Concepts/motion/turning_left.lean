/-
  drv.motion.turning_left — Road user a is turning to the left at an observation: it moves and its heading turns to the left. Measured as a not at rest (drv.motion.at_rest with the speed tolerance does not hold) and its yaw rate (kin.yaw_rate, deg/s, left positive) at or above the yaw tolerance, the rate below which a change of heading counts as none. A state at each observation while a turn is under way, not a completed manoeuvre: it does not say how far the turn goes, and it holds alike where the road user follows a bend of the road to the left. Not a stand-in for the turn indicator or for a declared intention to turn.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    a not at rest (drv.motion.at_rest with the speed tolerance does not hold): atoms [], concepts ['drv.motion.at_rest']
    its yaw rate (kin.yaw_rate, deg/s, left positive): atoms ['kin.yaw_rate'], concepts []

  The body is the conjunction, at the observation judged, of the negation of drv.motion.at_rest(a)
  called with the speed tolerance, and the comparison kin_yaw_rate(a) ≥ yaw_tolerance. It reads no
  road curvature, no turn indicator and no declared intention, and no time operator: a state at each
  observation. No choice beyond the contract's words was made.

  No magnitude below is this file's own: parameters are formals the caller fills.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.motion.turning_left

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aA : Arg := .var "a"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
def pYawTolerance : Term := .param "yaw_tolerance"
def pSpeedTolerance : Term := .param "speed_tolerance"

/-- The road user is not at rest (with the speed tolerance) and its yaw rate is at or above the yaw
    tolerance at this observation. -/
def body : Formula :=
  .and
    (.not (.derived "drv_motion_at_rest" [aA] [pSpeedTolerance]))
    (.cmp (.measure "kin_yaw_rate" [aA]) .ge pYawTolerance)

def concept : Concept :=
  { id := "drv.motion.turning_left"
    contract := "Road user a is turning to the left at an observation: it moves and its heading turns to the left. Measured as a not at rest (drv.motion.at_rest with the speed tolerance does not hold) and its yaw rate (kin.yaw_rate, deg/s, left positive) at or above the yaw tolerance, the rate below which a change of heading counts as none. A state at each observation while a turn is under way, not a completed manoeuvre: it does not say how far the turn goes, and it holds alike where the road user follows a bend of the road to the left. Not a stand-in for the turn indicator or for a declared intention to turn."
    definition := none
    args := [("a", .track)]
    params := [⟨"yaw_tolerance", .degreePerSecond⟩, ⟨"speed_tolerance", .metrePerSecond⟩]
    body := .formula body
    residues := []  -- the record's, verbatim; not yours to change
    narrowings := []  -- one { span := "<words of the contract>", why := "<why>", kind := "reading" } per reading you chose that the contract leaves open, explained in the header
    supersedes := none }

end TrafficSpec.Concepts.motion.turning_left
