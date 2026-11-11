/-
  drv.motion.reversing — A road user moves backwards relative to its own body at the observation: the component of its velocity along its heading is below minus speed_floor. Velocity (kin.velocity) is in m/s in the world frame and heading (kin.heading) is read normalised; speed_floor is the source's speed resolution, so a standing or barely creeping body is not reversing. It is read from kinematics only, never from the gear selected: a vehicle in reverse gear that rolls forward is not reversing, and one in a forward gear that rolls backwards is. Not denoted: a turn, the path followed, or the place the road user is in.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    the component of its velocity along its heading is below minus speed_floor: atoms ['kin.velocity', 'kin.heading'], concepts []
      written as vx·hx + vy·hy < −speed_floor, with kin_velocity and kin_heading read by their
      "x" and "y" world-frame components (kin_heading normalised by the evaluator); "below" is
      strict, as the words say. kin.gear is not read. No narrowing: the contract fixes the reading.

  No magnitude below is this file's own: parameters are formals the caller fills.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.motion.reversing

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aX : Arg := .var "x"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
def pSpeedFloor : Term := .param "speed_floor"

/-- The component of `x`'s velocity along its (normalised) heading: the dot product of the
    `kin_velocity` and `kin_heading` world-frame components. -/
def alongHeading : Term :=
  .add (.mul (.measure "kin_velocity" [aX, .lit "x"]) (.measure "kin_heading" [aX, .lit "x"]))
       (.mul (.measure "kin_velocity" [aX, .lit "y"]) (.measure "kin_heading" [aX, .lit "y"]))

/-- That component is below minus `speed_floor`. -/
def body : Formula := .cmp alongHeading .lt (.neg pSpeedFloor)

def concept : Concept :=
  { id := "drv.motion.reversing"
    contract := "A road user moves backwards relative to its own body at the observation: the component of its velocity along its heading is below minus speed_floor. Velocity (kin.velocity) is in m/s in the world frame and heading (kin.heading) is read normalised; speed_floor is the source's speed resolution, so a standing or barely creeping body is not reversing. It is read from kinematics only, never from the gear selected: a vehicle in reverse gear that rolls forward is not reversing, and one in a forward gear that rolls backwards is. Not denoted: a turn, the path followed, or the place the road user is in."
    definition := none
    args := [("x", .track)]
    params := [⟨"speed_floor", .metrePerSecond⟩]
    body := .formula body
    residues := []  -- the record's, verbatim; not yours to change
    narrowings := []  -- one { span := "<words of the contract>", why := "<why>", kind := "reading" } per reading you chose that the contract leaves open, explained in the header
    supersedes := none }

end TrafficSpec.Concepts.motion.reversing
