/-
  drv.motion.slowing — Road user x is slowing while moving forward at the observation: the component of its velocity (kin.velocity, m/s, world frame) along its heading (kin.heading, read normalised) exceeds speed_floor, and its longitudinal acceleration (kin.accel_longitudinal, m/s², signed along the heading) is below minus decel_floor, the source's acceleration resolution. Not denoted: slowing while backing, a brake lamp or a brake input, a halt, or how much the speed has fallen.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    the component of its velocity (kin.velocity, m/s, world frame) along its heading (kin.heading, read normalised) exceeds speed_floor: atoms ['kin.velocity', 'kin.heading'], concepts []
    its longitudinal acceleration (kin.accel_longitudinal, m/s², signed along the heading) is below minus decel_floor: atoms ['kin.accel_longitudinal'], concepts []

  The body: (kin_velocity·x · kin_heading·x + kin_velocity·y · kin_heading·y) > speed_floor
  ∧ kin_accel_longitudinal < −decel_floor. The heading is read through the measure, which
  normalises it, so the dot product is the velocity's component along the heading. Both
  comparisons are strict, as the contract's "exceeds" and "is below" say. No choice was left open.

  No magnitude below is this file's own: parameters are formals the caller fills.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.motion.slowing

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aX : Arg := .var "x"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
def pSpeedFloor : Term := .param "speed_floor"
def pDecelFloor : Term := .param "decel_floor"

/-- The component of x's velocity along its (normalised) heading: the dot product of the two. -/
def forwardSpeed : Term :=
  .add (.mul (.measure "kin_velocity" [aX, .lit "x"]) (.measure "kin_heading" [aX, .lit "x"]))
       (.mul (.measure "kin_velocity" [aX, .lit "y"]) (.measure "kin_heading" [aX, .lit "y"]))

/-- Moving forward faster than the speed resolution, and decelerating beyond the acceleration
    resolution along the heading. -/
def body : Formula :=
  .and (.cmp forwardSpeed .gt pSpeedFloor)
       (.cmp (.measure "kin_accel_longitudinal" [aX]) .lt (.neg pDecelFloor))

def concept : Concept :=
  { id := "drv.motion.slowing"
    contract := "Road user x is slowing while moving forward at the observation: the component of its velocity (kin.velocity, m/s, world frame) along its heading (kin.heading, read normalised) exceeds speed_floor, and its longitudinal acceleration (kin.accel_longitudinal, m/s², signed along the heading) is below minus decel_floor, the source's acceleration resolution. Not denoted: slowing while backing, a brake lamp or a brake input, a halt, or how much the speed has fallen."
    definition := none
    args := [("x", .track)]
    params := [⟨"speed_floor", .metrePerSecond⟩, ⟨"decel_floor", .metrePerSecondSq⟩]
    body := .formula body
    residues := []  -- the record's, verbatim; not yours to change
    narrowings := []  -- one { span := "<words of the contract>", why := "<why>", kind := "reading" } per reading you chose that the contract leaves open, explained in the header
    supersedes := none }

end TrafficSpec.Concepts.motion.slowing
