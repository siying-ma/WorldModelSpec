/-
  drv.motion.left_turn — True of one road user at an observation when it is in the course of turning to its left: the signed heading change of its body over a stated window ending at the observation is leftward, that is, positive in the sense in which left is positive, and the size of that leftward change is at least a stated angle. The two conditions are separate: the sense of the change decides the side the road user turns to, and the size decides whether it is a turn at all, so a change in the other sense is excluded however large it is and a change in this sense below the angle is excluded however it is signed. The stated angle is what separates a turn from the smaller heading changes of lane keeping, of a lane change and of following the road's curvature, and the stated window is what the change is integrated over; both are the caller's to set, the angle as a positive size in degrees. Unit: none - a condition on one road user; frame: ground plane, the heading change signed in the road user's own frame with left positive, integrated over the window behind the observation. Not a stand-in for: a turn indicator or an arm signal, which are emitted signals and may be shown without a turn and a turn made without them; an intention to turn, which is interior to the driver and not observable; the place at which the turn is made - a junction, a driveway, a lane - which the calling rule states on its own span; a lane change or a curve the roadway itself describes, which change heading without a turn and which the stated angle is set to exclude; or a right turn or a u-turn, which are a heading change in the other sense and which the leftward condition excludes however large their size.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    the signed heading change of its body over a stated window ending at the observation is leftward, that is, positive in the sense in which left is positive: atoms ['prim.heading_change'], concepts []
    the size of that leftward change is at least a stated angle: atoms ['prim.heading_change'], concepts []

  How the two elements are written.
    Both read one figure, the primitive `prim_heading_change (a, turn_window)`: "Signed heading
    change (degrees, left positive) over the back window w, integrated from the yaw rate; unknown
    where the window is truncated, sparsely sampled or a yaw rate is missing". It is exactly the
    quantity the contract names, in exactly the contract's sign convention ("left positive"), over
    exactly the contract's window ("a stated window ending at the observation" — the primitive's
    window is the one behind the observation, and its length is the formal parameter `turn_window`).
    The primitive reads `kin.yaw_rate` itself; this body claims no kinematic atom of its own, and
    is unknown wherever the primitive is.

    "the signed heading change … is leftward, that is, positive in the sense in which left is
    positive" is the one comparison of that figure with zero, strictly: left is the primitive's
    positive sense, so leftward is the figure above zero. Zero is the only magnitude in this file,
    and it is the origin of the primitive's own scale, not a quantity of this file's choosing.

    "the size of that leftward change is at least a stated angle" is the size — the absolute value
    — of the same figure against `turn_heading_change_min`, non-strictly, because the contract says
    "at least". The parameter is "a positive size in degrees" and "carries no sense of its own", so
    the comparison is of size with size.

    The two are conjoined and nothing else joins them: the contract makes them "separate", the
    sense deciding the side and the size deciding whether it is a turn at all, so a rightward change
    fails the first however large it is and a small leftward change fails the second.

    The window operator of the formula language is not used: the primitive integrates over its own
    back window, and wrapping it in `holdsFor` would state that the condition held at every
    observation of the window rather than that the change accumulated over it.

  Narrowings (readings the contract leaves open).
    "the size of that leftward change is at least a stated angle" — read as the absolute value of
    the signed figure, not the signed figure itself. The contract insists the two conditions are
    "separate" and that a change "in this sense below the angle is excluded however it is signed":
    on the signed reading the size condition would by itself exclude every rightward change, the
    sense condition would do no work of its own, and the parameter — declared "a positive size …
    [that] carries no sense of its own" — would silently carry the leftward sense as well. Taking
    the size as the size keeps each condition doing exactly the work the contract gives it.
    Declared in `narrowings` below.
    "is leftward, that is, positive in the sense in which left is positive" — read strictly: a
    heading change of exactly zero is not leftward. A body that did not turn at all has no side to
    have turned to, and the non-strict reading would make the sense condition true of every
    straight run, leaving the whole concept to the size condition alone. Declared in `narrowings`
    below.
    The sampling policy Core fixes for every window is carried here by the primitive, not chosen by
    this file: the body is unknown, not false, where the trace does not reach a whole window back
    and where the observations inside are more than half a window apart. That is not a narrowing.

  No magnitude below is this file's own: parameters are formals the caller fills.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.motion.left_turn

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
private def aA : Arg := .var "a"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
private def pTurnWindow : Term := .param "turn_window"
private def pTurnHeadingChangeMin : Term := .param "turn_heading_change_min"

/-- The signed heading change of a's body (degrees, left positive) over the window of length
    `turn_window` behind the observation, integrated from the yaw rate by the primitive. -/
private def headingChange : Term := .quantity "prim_heading_change" [aA] [pTurnWindow]

/-- "the signed heading change of its body over a stated window ending at the observation is
    leftward, that is, positive in the sense in which left is positive": the figure above zero,
    left being the primitive's positive sense. -/
private def leftward : Formula :=
  .cmp headingChange .gt (.lit (Units.degrees 0) .degree)

/-- "the size of that leftward change is at least a stated angle": the size of that same figure
    reaching `turn_heading_change_min`, which is a size and carries no sense of its own. -/
private def largeEnough : Formula :=
  .cmp (.abs headingChange) .ge pTurnHeadingChangeMin

/-- The two separate conditions: the sense decides the side turned to, the size decides whether it
    is a turn at all. -/
private def body : Formula := .and leftward largeEnough

def concept : Concept :=
  { id := "drv.motion.left_turn"
    contract := "True of one road user at an observation when it is in the course of turning to its left: the signed heading change of its body over a stated window ending at the observation is leftward, that is, positive in the sense in which left is positive, and the size of that leftward change is at least a stated angle. The two conditions are separate: the sense of the change decides the side the road user turns to, and the size decides whether it is a turn at all, so a change in the other sense is excluded however large it is and a change in this sense below the angle is excluded however it is signed. The stated angle is what separates a turn from the smaller heading changes of lane keeping, of a lane change and of following the road's curvature, and the stated window is what the change is integrated over; both are the caller's to set, the angle as a positive size in degrees. Unit: none - a condition on one road user; frame: ground plane, the heading change signed in the road user's own frame with left positive, integrated over the window behind the observation. Not a stand-in for: a turn indicator or an arm signal, which are emitted signals and may be shown without a turn and a turn made without them; an intention to turn, which is interior to the driver and not observable; the place at which the turn is made - a junction, a driveway, a lane - which the calling rule states on its own span; a lane change or a curve the roadway itself describes, which change heading without a turn and which the stated angle is set to exclude; or a right turn or a u-turn, which are a heading change in the other sense and which the leftward condition excludes however large their size."
    definition := none
    args := [("a", .track)]
    params := [⟨"turn_window", .second⟩, ⟨"turn_heading_change_min", .degree⟩]
    body := .formula body
    residues := []  -- the record's, verbatim; not yours to change
    narrowings :=
      [ ⟨"the size of that leftward change is at least a stated angle",
         "Read as the absolute value of the signed heading change, not the signed figure itself. The contract makes the two conditions separate and excludes a change in this sense below the angle 'however it is signed', and it declares the parameter a positive size that 'carries no sense of its own'; comparing the signed figure would make the size condition exclude every rightward change on its own, leaving the leftward condition no work and smuggling the sense into the caller's size."⟩
      , ⟨"is leftward, that is, positive in the sense in which left is positive",
         "Read strictly: a heading change of exactly zero is not leftward. A body whose heading did not change has no side it turned to, and on the non-strict reading the sense condition would hold of every straight run, leaving the concept to the size condition alone."⟩ ]
    supersedes := none }

end TrafficSpec.Concepts.motion.left_turn
