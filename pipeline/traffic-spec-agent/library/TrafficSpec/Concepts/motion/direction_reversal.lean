/-
  drv.motion.direction_reversal — True of a road user at an observation when it has just carried out a turn that reverses its direction of travel: the magnitude of its signed heading change (degrees, left positive, world frame) over the window behind the observation is at least the reversal angle, the user's footprint overlaps the roadway, and its speed (m/s) at the observation is above the motion speed, so that it is proceeding and not standing. The window, the reversal angle and the motion speed are the caller's parameters: the heading change is integrated over sampled measurements, so the concept is unknown wherever that integration is unknown — a window truncated at the start of a trace, a yaw rate too sparsely sampled, a yaw rate missing. Not a stand-in for: a turn into another way, a driveway or an alley, a lane change, or a turn at an intersection, none of which reverses the direction of travel over the window; the gear selected or the direction of motion — the heading change is of the body, so a vehicle that backs in a straight line has not turned and one that backs round until its body faces the other way has; where the turn is carried out, which is the caller's; whether the turn was lawful, which is another rule's verdict; and the driver's purpose in turning, which no source observes.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    the magnitude of its signed heading change (degrees, left positive, world frame) over the window behind the observation is at least the reversal angle: atoms ['prim.heading_change'], concepts []
    the user's footprint overlaps the roadway: atoms ['st.roadway', 'rel.occupies'], concepts []
    its speed (m/s) at the observation is above the motion speed: atoms ['kin.speed'], concepts []

  How each element is written:

  1. "the magnitude of its signed heading change … is at least the reversal angle" —
     `.abs (Term.quantity "prim_heading_change" [user] [window]) ≥ reversal_angle`. The primitive
     is the signed change in degrees, left positive, integrated over the back window from the yaw
     rate; `abs` is the contract's "magnitude", `.ge` its "at least". The window length is passed
     as the primitive's one parameter, so a truncated, sparsely sampled or yaw-rate-less window
     makes this comparison — and with it the conjunction — unknown rather than false, which is the
     unknown behaviour the contract demands. The sign of the turn is therefore not read: a turn of
     the stated magnitude counts whether the body swung left or right.

  2. "the user's footprint overlaps the roadway" — `existsRegion (.lit "roadway") rw,
     rel_occupies user rw`. `rel.occupies` is the anchor that makes the roadway this user's own;
     the quantifier's kind literal is `st.roadway`.

  3. "its speed (m/s) at the observation is above the motion speed" —
     `kin_speed user > motion_speed`, read at the observation only (no window), strictly above, as
     "above" says.

  The three are conjoined: the contract joins them with "and", and each is read at the observation
  the concept is evaluated at (element 1 over the window behind it).

  Readings the contract left open (declared as narrowings below):
    - "the roadway" is not a region the concept can name, so it is read existentially: SOME region
      of kind roadway that this user occupies. A scene with several roadway regions (a side street
      is a roadway too) therefore satisfies the element wherever the user is on any of them.

  No magnitude below is this file's own: parameters are formals the caller fills.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.motion.direction_reversal

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
private def aUser : Arg := .var "user"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
private def pWindow : Term := .param "window"
private def pReversalAngle : Term := .param "reversal_angle"
private def pMotionSpeed : Term := .param "motion_speed"

/-- The magnitude of the signed heading change over the window behind is at least the reversal
    angle. Unknown wherever the integration is (truncated window, sampling gap, missing yaw rate). -/
private def reversed : Formula :=
  .cmp (.abs (.quantity "prim_heading_change" [aUser] [pWindow])) .ge pReversalAngle

/-- The user's footprint overlaps some region of kind roadway. -/
private def onRoadway : Formula :=
  .existsRegion (.lit "roadway") "rw" (.atom "rel_occupies" [aUser, .var "rw"] [])

/-- Proceeding, not standing: speed at the observation above the motion speed. -/
private def proceeding : Formula :=
  .cmp (.measure "kin_speed" [aUser]) .gt pMotionSpeed

private def body : Formula := .and reversed (.and onRoadway proceeding)

def concept : Concept :=
  { id := "drv.motion.direction_reversal"
    contract := "True of a road user at an observation when it has just carried out a turn that reverses its direction of travel: the magnitude of its signed heading change (degrees, left positive, world frame) over the window behind the observation is at least the reversal angle, the user's footprint overlaps the roadway, and its speed (m/s) at the observation is above the motion speed, so that it is proceeding and not standing. The window, the reversal angle and the motion speed are the caller's parameters: the heading change is integrated over sampled measurements, so the concept is unknown wherever that integration is unknown — a window truncated at the start of a trace, a yaw rate too sparsely sampled, a yaw rate missing. Not a stand-in for: a turn into another way, a driveway or an alley, a lane change, or a turn at an intersection, none of which reverses the direction of travel over the window; the gear selected or the direction of motion — the heading change is of the body, so a vehicle that backs in a straight line has not turned and one that backs round until its body faces the other way has; where the turn is carried out, which is the caller's; whether the turn was lawful, which is another rule's verdict; and the driver's purpose in turning, which no source observes."
    definition := none
    args := [("user", .track)]
    params := [⟨"window", .second⟩, ⟨"reversal_angle", .degree⟩, ⟨"motion_speed", .metrePerSecond⟩]
    body := .formula body
    residues := []  -- the record's, verbatim; not yours to change
    narrowings :=
      [ { span := "the user's footprint overlaps the roadway"
          why := "The contract names no particular roadway, and the concept has no region formal, so the words are read existentially: the user occupies SOME region of kind roadway. Where a scene holds several roadway regions — a side street is a roadway too — the element holds on any of them, and the concept turns on the heading change alone."
          kind := "reading" } ]
    supersedes := none }

end TrafficSpec.Concepts.motion.direction_reversal
