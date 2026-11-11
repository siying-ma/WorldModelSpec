/-
  drv.motion.turning_left — Road user x is turning to its left at the observation: it is moving (drv.motion.moving with speed_floor) and its yaw rate (kin.yaw_rate, deg/s, left positive) exceeds yaw_floor, the source's yaw-rate resolution. It does not tell a turn at a junction from following a left-hand bend: the caller states the place. Not denoted: a completed turn manoeuvre, an intention to turn, or a turn indicator.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    it is moving (drv.motion.moving with speed_floor): atoms ['kin.speed'], concepts ['drv.motion.moving']
      written as the call `drv_motion_moving x [speed_floor]`; the concept's own floor test is
      not restated.
    its yaw rate (kin.yaw_rate, deg/s, left positive) exceeds yaw_floor: atoms ['kin.yaw_rate'], concepts []
      written as kin_yaw_rate x > yaw_floor; "exceeds" is strict, as the words say, and the sign
      convention (left positive) makes a right-hand yaw (negative) never exceed the floor.
    The two are joined by `and`. No narrowing: the contract fixes the reading.

  No magnitude below is this file's own: parameters are formals the caller fills.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.motion.turning_left

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aX : Arg := .var "x"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
def pSpeedFloor : Term := .param "speed_floor"
def pYawFloor : Term := .param "yaw_floor"

/-- `x` is moving: `drv.motion.moving` with `speed_floor`. -/
def moving : Formula := .derived "drv_motion_moving" [aX] [pSpeedFloor]

/-- `x`'s yaw rate (deg/s, left positive) exceeds `yaw_floor`. -/
def yawingLeft : Formula := .cmp (.measure "kin_yaw_rate" [aX]) .gt pYawFloor

/-- Moving, and yawing to the left above the source's resolution. -/
def body : Formula := .and moving yawingLeft

def concept : Concept :=
  { id := "drv.motion.turning_left"
    contract := "Road user x is turning to its left at the observation: it is moving (drv.motion.moving with speed_floor) and its yaw rate (kin.yaw_rate, deg/s, left positive) exceeds yaw_floor, the source's yaw-rate resolution. It does not tell a turn at a junction from following a left-hand bend: the caller states the place. Not denoted: a completed turn manoeuvre, an intention to turn, or a turn indicator."
    definition := none
    args := [("x", .track)]
    params := [⟨"speed_floor", .metrePerSecond⟩, ⟨"yaw_floor", .degreePerSecond⟩]
    body := .formula body
    residues := []  -- the record's, verbatim; not yours to change
    narrowings := []  -- one { span := "<words of the contract>", why := "<why>", kind := "reading" } per reading you chose that the contract leaves open, explained in the header
    supersedes := none }

end TrafficSpec.Concepts.motion.turning_left
