/-
  drv.motion.in_motion — True of a road user at an observation when it is proceeding over the ground rather than standing: its speed at the observation, the magnitude of its velocity in the world frame, in m/s, is above the motion speed. The motion speed is the caller's parameter, because a source that estimates speed from sampled positions reports a small speed for a body that stands still, and below that speed nothing is told apart from standing; the magnitude at which the two part is the caller's, never a figure of this contract. Not a stand-in for: the engine or motor running, which is kin.engine_running and which a vehicle shows while it stands; the gear selected (kin.gear), the accelerator or brake inputs (kin.throttle, kin.service_brake), or any other thing a driver does to the controls; the direction of travel, since the magnitude says nothing of it and a road user backing is in motion; a journey, a trip, or the act of driving as a person performs it, none of which a source observes; or a halt that a rule requires, which is another rule's verdict.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    its speed at the observation, the magnitude of its velocity in the world frame: atoms ['kin.speed'], concepts []
      → `Term.measure "kin_speed" [user]`, the magnitude of the velocity in m/s, read of the formal
        track at the instant of evaluation. Nothing else is read: not `kin.velocity`, whose direction
        the contract disclaims (a road user backing is in motion), not `kin.engine_running`,
        `kin.gear`, `kin.throttle` or `kin.service_brake`, each of which the contract names only to
        say it is not this concept.

  The comparison. "is above the motion speed" is strict: `.gt`, the formal parameter on the right.
  At exactly the motion speed the road user is not proceeding — the contract puts the parting
  magnitude at the caller's disposal and asks for what is above it, so equality is standing.
  Where `kin.speed` is unobserved the comparison is unknown, which is the contract's own reading:
  below the resolution of the source nothing is told apart from standing, and with no reading at
  all nothing is told at all.

  No magnitude below is this file's own: parameters are formals the caller fills.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.motion.in_motion

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
private def aUser : Arg := .var "user"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
private def pMotionSpeed : Term := .param "motion_speed"

/-- The road user's speed — the magnitude of its velocity in the world frame, m/s — is above the
    motion speed the caller sets. -/
private def body : Formula :=
  .cmp (.measure "kin_speed" [aUser]) .gt pMotionSpeed

def concept : Concept :=
  { id := "drv.motion.in_motion"
    contract := "True of a road user at an observation when it is proceeding over the ground rather than standing: its speed at the observation, the magnitude of its velocity in the world frame, in m/s, is above the motion speed. The motion speed is the caller's parameter, because a source that estimates speed from sampled positions reports a small speed for a body that stands still, and below that speed nothing is told apart from standing; the magnitude at which the two part is the caller's, never a figure of this contract. Not a stand-in for: the engine or motor running, which is kin.engine_running and which a vehicle shows while it stands; the gear selected (kin.gear), the accelerator or brake inputs (kin.throttle, kin.service_brake), or any other thing a driver does to the controls; the direction of travel, since the magnitude says nothing of it and a road user backing is in motion; a journey, a trip, or the act of driving as a person performs it, none of which a source observes; or a halt that a rule requires, which is another rule's verdict."
    definition := none
    args := [("user", .track)]
    params := [⟨"motion_speed", .metrePerSecond⟩]
    body := .formula body
    residues := []  -- the record's, verbatim; not yours to change
    narrowings := []  -- one { span := "<words of the contract>", why := "<why>", kind := "reading" } per reading you chose that the contract leaves open, explained in the header
    supersedes := none }

end TrafficSpec.Concepts.motion.in_motion
