/-
  drv.motion.turning — The road user's heading is changing at this observation: its body is turning to one hand or the other. The state is read at the observation itself, from the magnitude of the road user's rate of change of heading being above the tolerance, the reading below which a rate of turn is sensor noise or the jitter of holding a straight course. The concept denotes the body's own change of heading: it is not the shape of the road it travels on, not a steering input, not the hand of the turn, and not any particular manoeuvre or the place where it is made.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    the magnitude of the road user's rate of change of heading: atoms ['kin.yaw_rate'], concepts []
      written `.abs (.measure "kin_yaw_rate" [u])`: the yaw rate is 'rate of change of heading,
      positive when the heading turns to the left', and taking its magnitude prefers neither hand,
      as the contract requires ('not the hand of the turn'). Nothing else is read: no road
      curvature (st.curvature), no steering input (kin.steer_angle), no manoeuvre and no place.
      The reading is at the judged observation — no temporal operator — as the contract says.

  Narrowing (a choice the contract left open):
    "being above the tolerance" — read as a strict comparison (`.gt`), so a magnitude exactly at
    the tolerance is no turn. The parameter is 'the magnitude below which a rate of change of
    heading counts as none', which does not settle the boundary itself; the strict reading leaves
    the boundary reading on the side of sensor noise and of holding a straight course.

  No magnitude below is this file's own: parameters are formals the caller fills.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.motion.turning

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aU : Arg := .var "u"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
def pYawRateTolerance : Term := .param "yaw_rate_tolerance"

/-- The magnitude of the road user's rate of change of heading, read at this observation. -/
def yawRateMagnitude : Term := .abs (.measure "kin_yaw_rate" [aU])

/-- The heading is changing here: the magnitude of the yaw rate is above the tolerance. Neither
    hand is preferred (the magnitude is read), and nothing but the body's own yaw is read. -/
def body : Formula := .cmp yawRateMagnitude .gt pYawRateTolerance

def concept : Concept :=
  { id := "drv.motion.turning"
    contract := "The road user's heading is changing at this observation: its body is turning to one hand or the other. The state is read at the observation itself, from the magnitude of the road user's rate of change of heading being above the tolerance, the reading below which a rate of turn is sensor noise or the jitter of holding a straight course. The concept denotes the body's own change of heading: it is not the shape of the road it travels on, not a steering input, not the hand of the turn, and not any particular manoeuvre or the place where it is made."
    definition := none
    args := [("u", .track)]
    params := [⟨"yaw_rate_tolerance", .degreePerSecond⟩]
    body := .formula body
    residues := []  -- the record's, verbatim; not yours to change
    narrowings :=
      [ { span := "being above the tolerance"
          why := "Read as strict: the magnitude must exceed the tolerance, so a reading exactly at the tolerance counts as no turn. The tolerance is 'the magnitude below which a rate of change of heading counts as none', which leaves the reading at the boundary open; the strict reading keeps the tolerance itself on the side of sensor noise."
          kind := "reading" } ]
    supersedes := none }

end TrafficSpec.Concepts.motion.turning
