/-
  drv.motion.turning_left — A road user's heading is turning to the left at the observation: its yaw rate (kin.yaw_rate, positive to the left, counter-clockwise) exceeds `tol`, a tolerance that names only the source's yaw-rate resolution, whether the road user moves forwards or backwards. Not denoted: a heading turning to the right or not changing; the angle turned or a completed turn; where the turn is made, which the caller states. The concept does not tell a turn at a junction from a lane change or a bend; the caller's place condition does.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    its yaw rate (kin.yaw_rate, positive to the left, counter-clockwise) exceeds `tol`: atoms ['kin.yaw_rate'], concepts []

  No magnitude below is this file's own: parameters are formals the caller fills.

  The session's writing:
    "its yaw rate ... exceeds `tol`" is `kin_yaw_rate x > tol`: a strict comparison, so a yaw rate at
    `tol` reads as no turning to the left, as the parameter's meaning states. The sign of the yaw rate
    alone decides the hand (positive is left, counter-clockwise); no gear, speed or direction of travel
    is read, so the concept holds alike whether x moves forwards or backwards. A negative yaw rate
    (turning right) or one within `tol` of zero fails. The comparison is unknown where the yaw rate is
    unobserved. No choice was left open: no narrowing.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.motion.turning_left

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aX : Arg := .var "x"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
def pTol : Term := .param "tol"

/-- "its yaw rate (kin.yaw_rate, positive to the left, counter-clockwise) exceeds `tol`". -/
def body : Formula := .cmp (.measure "kin_yaw_rate" [aX]) .gt pTol

def concept : Concept :=
  { id := "drv.motion.turning_left"
    contract := "A road user's heading is turning to the left at the observation: its yaw rate (kin.yaw_rate, positive to the left, counter-clockwise) exceeds `tol`, a tolerance that names only the source's yaw-rate resolution, whether the road user moves forwards or backwards. Not denoted: a heading turning to the right or not changing; the angle turned or a completed turn; where the turn is made, which the caller states. The concept does not tell a turn at a junction from a lane change or a bend; the caller's place condition does."
    definition := none
    args := [("x", .track)]
    params := [⟨"tol", .degreePerSecond⟩]
    body := .formula body
    residues := []  -- the record's, verbatim; not yours to change
    narrowings := []  -- one { span := "<words of the contract>", why := "<why>", kind := "reading" } per reading you chose that the contract leaves open, explained in the header
    supersedes := none }

end TrafficSpec.Concepts.motion.turning_left
