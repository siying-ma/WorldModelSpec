/-
  drv.motion.moving_backward — Road user a is moving backward: it moves against the direction its body points. It is observed as the component of a's velocity (kin.velocity) along a's heading (kin.heading), the dot product of the velocity with the heading as a formula reads it normalised, being below minus speed_tol: the part of a's motion that runs against its heading exceeds the speed the source cannot tell from rest. It is a state at one observation: it says nothing of the gear selected, of the path a has followed or will follow, of where a is, or of why it moves so. Not denoted: a road user at rest, or one whose velocity component against its heading is at or below speed_tol; a road user moving forward. Where a's velocity or heading is unobserved, it is unknown.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    the component of a's velocity (kin.velocity) along a's heading (kin.heading): atoms ['kin.velocity', 'kin.heading'], concepts []
      written as vx·hx + vy·hy, each vector read by its "x" and "y" components (`kin_heading` is
      read normalised by the evaluator, as the contract says).
    being below minus speed_tol: `.cmp … .lt (.neg speed_tol)` — strict, so a component at
      exactly −speed_tol is not denoted, as the contract's "at or below speed_tol" requires.
    unknown where velocity or heading is unobserved: a `none` field makes the measure unknown.

  No choice was left open by the contract; no narrowing is declared.

  No magnitude below is this file's own: parameters are formals the caller fills.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.motion.moving_backward

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aA : Arg := .var "a"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
def pSpeedTol : Term := .param "speed_tol"

/-- The component of a's velocity along a's heading: the dot product of `kin_velocity` with
    `kin_heading` (which a formula reads normalised), component by component. -/
def alongHeading : Term :=
  .add (.mul (.measure "kin_velocity" [aA, .lit "x"]) (.measure "kin_heading" [aA, .lit "x"]))
       (.mul (.measure "kin_velocity" [aA, .lit "y"]) (.measure "kin_heading" [aA, .lit "y"]))

/-- That component below minus speed_tol. -/
def body : Formula := .cmp alongHeading .lt (.neg pSpeedTol)

def concept : Concept :=
  { id := "drv.motion.moving_backward"
    contract := "Road user a is moving backward: it moves against the direction its body points. It is observed as the component of a's velocity (kin.velocity) along a's heading (kin.heading), the dot product of the velocity with the heading as a formula reads it normalised, being below minus speed_tol: the part of a's motion that runs against its heading exceeds the speed the source cannot tell from rest. It is a state at one observation: it says nothing of the gear selected, of the path a has followed or will follow, of where a is, or of why it moves so. Not denoted: a road user at rest, or one whose velocity component against its heading is at or below speed_tol; a road user moving forward. Where a's velocity or heading is unobserved, it is unknown."
    definition := none
    args := [("a", .track)]
    params := [⟨"speed_tol", .metrePerSecond⟩]
    body := .formula body
    residues := []  -- the record's, verbatim; not yours to change
    narrowings := []  -- one { span := "<words of the contract>", why := "<why>", kind := "reading" } per reading you chose that the contract leaves open, explained in the header
    supersedes := none }

end TrafficSpec.Concepts.motion.moving_backward
