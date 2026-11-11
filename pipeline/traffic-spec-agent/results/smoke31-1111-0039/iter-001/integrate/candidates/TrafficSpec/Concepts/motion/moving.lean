/-
  drv.motion.moving — A road user is in motion at the observation: its speed exceeds speed_floor. The floor names only the source's speed resolution, below which a reading counts as no motion; speed (kin.speed) is in m/s. The concept says nothing of the direction of motion relative to the body or to the road, of a manoeuvre, or of who or what controls the motion. Not denoted: a halt held for a duration, travel along a particular carrier, or a road user being driven by a person.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    its speed exceeds speed_floor: atoms ['kin.speed'], concepts []
      written `kin_speed x > speed_floor`; "exceeds" is strict, as the contract's "at or below it
      counts as no motion" states. No choice was left open: no narrowing.

  No magnitude below is this file's own: parameters are formals the caller fills.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.motion.moving

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aX : Arg := .var "x"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
def pSpeedFloor : Term := .param "speed_floor"

/-- "its speed exceeds speed_floor": the measured speed of `x` strictly above the floor, so a
    reading at or below it is no motion. Unknown where the speed is not observed. -/
def body : Formula := .cmp (.measure "kin_speed" [aX]) .gt pSpeedFloor

def concept : Concept :=
  { id := "drv.motion.moving"
    contract := "A road user is in motion at the observation: its speed exceeds speed_floor. The floor names only the source's speed resolution, below which a reading counts as no motion; speed (kin.speed) is in m/s. The concept says nothing of the direction of motion relative to the body or to the road, of a manoeuvre, or of who or what controls the motion. Not denoted: a halt held for a duration, travel along a particular carrier, or a road user being driven by a person."
    definition := none
    args := [("x", .track)]
    params := [⟨"speed_floor", .metrePerSecond⟩]
    body := .formula body
    residues := []  -- the record's, verbatim; not yours to change
    narrowings := []  -- one { span := "<words of the contract>", why := "<why>", kind := "reading" } per reading you chose that the contract leaves open, explained in the header
    supersedes := none }

end TrafficSpec.Concepts.motion.moving
