/-
  drv.motion.yawing — A road user's heading is changing at the observation: the absolute value of its yaw rate exceeds yaw_floor. Yaw rate (kin.yaw_rate) is in deg/s, left positive, and either hand counts; yaw_floor is the source's yaw-rate resolution. Not denoted: a turn at a junction, a lane change, or the curvature of the road: a road user yaws wherever its path bends, and one running straight does not.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    the absolute value of its yaw rate exceeds yaw_floor: atoms ['kin.yaw_rate'], concepts []
      written `|kin_yaw_rate x| > yaw_floor`: `Term.abs` makes either hand count, `.gt` makes a
      rate at the floor itself count as no heading change, as the parameter's meaning states.

  No choice is left open: the contract fixes the atom, the absolute value, the strict comparison
  and the parameter; no narrowing is declared. A missing yaw rate leaves the body unknown.

  No magnitude below is this file's own: parameters are formals the caller fills.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.motion.yawing

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aX : Arg := .var "x"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
def pYawFloor : Term := .param "yaw_floor"

/-- The absolute value of its yaw rate exceeds yaw_floor. -/
def body : Formula :=
  .cmp (.abs (.measure "kin_yaw_rate" [aX])) .gt pYawFloor

def concept : Concept :=
  { id := "drv.motion.yawing"
    contract := "A road user's heading is changing at the observation: the absolute value of its yaw rate exceeds yaw_floor. Yaw rate (kin.yaw_rate) is in deg/s, left positive, and either hand counts; yaw_floor is the source's yaw-rate resolution. Not denoted: a turn at a junction, a lane change, or the curvature of the road: a road user yaws wherever its path bends, and one running straight does not."
    definition := none
    args := [("x", .track)]
    params := [⟨"yaw_floor", .degreePerSecond⟩]
    body := .formula body
    residues := []  -- the record's, verbatim; not yours to change
    narrowings := []
    supersedes := none }

end TrafficSpec.Concepts.motion.yawing
