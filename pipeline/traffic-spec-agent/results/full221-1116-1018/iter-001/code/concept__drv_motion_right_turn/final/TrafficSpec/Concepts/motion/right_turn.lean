/-
  drv.motion.right_turn — Road user a has completed a turn to the right. Its heading change over the window behind the observation (prim.heading_change over a window of length window, degrees, positive to the left) lies in the band from minus u_turn_min exclusive to minus turn_min inclusive: a turn to the right by at least turn_min and by less than u_turn_min, so that a heading change too small to be a turn and a reversal of direction both lie outside it. The act begins within the window behind the observation at which it is recognized. The act is recognized at the observation at which the heading change over the window behind lies in that band and a's yaw rate (kin.yaw_rate) is at most yaw_tol in magnitude, where this did not hold at the previous observation: the heading has stopped turning. The concept holds at that observation only, and not again until that condition has ceased to hold and then holds again. Conduct before the window behind is not read: a turn that takes longer than the window is not recognized. It denotes the change of a's heading only: it says nothing of the lane, the intersection or the way on which a turns, of its speed, or of why it turns. Not denoted: a heading change to the right smaller than turn_min, such as a lane change or a drift; a heading change of u_turn_min or more, which is a reversal of direction; a turn to the left; a turn still under way, whose yaw rate exceeds yaw_tol. Where the window is truncated or a yaw rate in it is missing, it is unknown.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    Its heading change over the window behind the observation (prim.heading_change over a window of length window, degrees, positive to the left) lies in the band from minus u_turn_min exclusive to minus turn_min inclusive: atoms ['prim.heading_change'], concepts []
    a's yaw rate (kin.yaw_rate) is at most yaw_tol in magnitude: atoms ['kin.yaw_rate'], concepts []

  How they are written:
    - the band: `prim_heading_change a [window] ≤ −turn_min` and `> −u_turn_min` (the contract's
      inclusive and exclusive ends, as stated);
    - the yaw rate: `|kin_yaw_rate a| ≤ yaw_tol`;
    - recognition: `rises (band ∧ yaw)` — the condition here and not at the previous observation,
      which also gives "holds at that observation only, and not again until that condition has
      ceased to hold and then holds again". Truncation of the window and a missing yaw rate are
      unknown through prim_heading_change and kin_yaw_rate themselves.
  No choice beyond the contract's words was made: no narrowing.

  No magnitude below is this file's own: parameters are formals the caller fills.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.motion.right_turn

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aA : Arg := .var "a"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
def pWindow : Term := .param "window"
def pTurnMin : Term := .param "turn_min"
def pUTurnMin : Term := .param "u_turn_min"
def pYawTol : Term := .param "yaw_tol"

/-- a's heading change over the window behind (prim.heading_change, degrees, left positive). -/
def headingChange : Term := .quantity "prim_heading_change" [aA] [pWindow]

/-- a's yaw rate (kin.yaw_rate, deg/s, left positive). -/
def yawRate : Term := .measure "kin_yaw_rate" [aA]

/-- The heading change lies in the band from minus u_turn_min exclusive to minus turn_min
    inclusive: a turn to the right by at least turn_min and by less than u_turn_min. -/
def inRightBand : Formula :=
  .and (.cmp headingChange .le (.neg pTurnMin))
       (.cmp headingChange .gt (.neg pUTurnMin))

/-- a's yaw rate is at most yaw_tol in magnitude: the heading has stopped turning. -/
def stoppedTurning : Formula := .cmp (.abs yawRate) .le pYawTol

/-- The recognition condition: the heading change in the band and the heading no longer turning. -/
def completed : Formula := .and inRightBand stoppedTurning

/-- Recognized where the condition holds and did not hold at the previous observation; it holds
    there only, and again only after the condition has ceased and risen again. -/
def body : Formula := .rises completed

def concept : Concept :=
  { id := "drv.motion.right_turn"
    contract := "Road user a has completed a turn to the right. Its heading change over the window behind the observation (prim.heading_change over a window of length window, degrees, positive to the left) lies in the band from minus u_turn_min exclusive to minus turn_min inclusive: a turn to the right by at least turn_min and by less than u_turn_min, so that a heading change too small to be a turn and a reversal of direction both lie outside it. The act begins within the window behind the observation at which it is recognized. The act is recognized at the observation at which the heading change over the window behind lies in that band and a's yaw rate (kin.yaw_rate) is at most yaw_tol in magnitude, where this did not hold at the previous observation: the heading has stopped turning. The concept holds at that observation only, and not again until that condition has ceased to hold and then holds again. Conduct before the window behind is not read: a turn that takes longer than the window is not recognized. It denotes the change of a's heading only: it says nothing of the lane, the intersection or the way on which a turns, of its speed, or of why it turns. Not denoted: a heading change to the right smaller than turn_min, such as a lane change or a drift; a heading change of u_turn_min or more, which is a reversal of direction; a turn to the left; a turn still under way, whose yaw rate exceeds yaw_tol. Where the window is truncated or a yaw rate in it is missing, it is unknown."
    definition := none
    args := [("a", .track)]
    params := [⟨"window", .second⟩, ⟨"turn_min", .degree⟩, ⟨"u_turn_min", .degree⟩, ⟨"yaw_tol", .degreePerSecond⟩]
    body := .formula body
    residues := []  -- the record's, verbatim; not yours to change
    narrowings := []  -- one { span := "<words of the contract>", why := "<why>", kind := "reading" } per reading you chose that the contract leaves open, explained in the header
    supersedes := none }

end TrafficSpec.Concepts.motion.right_turn
