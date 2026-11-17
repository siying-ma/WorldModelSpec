/-
  drv.motion.left_turn — Road user a has completed a turn to the left. Its heading change over the window behind the observation (prim.heading_change over a window of length window, degrees, positive to the left) lies in the band from turn_min inclusive to u_turn_min exclusive, so that a heading change too small to be a turn and a reversal of direction both lie outside it. The act begins within the window behind the observation at which it is recognized. The act is recognized at the observation at which the heading change over the window behind lies in that band and a's yaw rate (kin.yaw_rate) is at most yaw_tol in magnitude, where this did not hold at the previous observation: the heading has stopped turning. The concept holds at that observation only, and not again until that condition has ceased to hold and then holds again. Conduct before the window behind is not read: a turn that takes longer than the window is not recognized. It denotes the change of a's heading only: it says nothing of the lane, the intersection or the way on which a turns, of its speed, or of why it turns. Not denoted: a heading change to the left smaller than turn_min, such as a lane change or a drift; a heading change of u_turn_min or more, which is a reversal of direction; a turn to the right; a turn still under way, whose yaw rate exceeds yaw_tol. Where the window is truncated or a yaw rate in it is missing, it is unknown.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    Its heading change over the window behind the observation (prim.heading_change over a window of length window, degrees, positive to the left) lies in the band from turn_min inclusive to u_turn_min exclusive: atoms ['prim.heading_change'], concepts []
    a's yaw rate (kin.yaw_rate) is at most yaw_tol in magnitude: atoms ['kin.yaw_rate'], concepts []

  No magnitude below is this file's own: parameters are formals the caller fills.

  How each element is written:
    - "Its heading change over the window behind the observation ... lies in the band from
      turn_min inclusive to u_turn_min exclusive": `hc := Term.quantity "prim_heading_change" [a]
      [window]`, and the band is `hc ≥ turn_min ∧ hc < u_turn_min`. The primitive is signed, left
      positive, so a turn to the right (negative) and a change below turn_min lie outside the band,
      and one of u_turn_min or more (a reversal) lies above it. It is unknown where the window is
      truncated or a yaw rate in it is missing, as the contract's last sentence says.
    - "a's yaw rate (kin.yaw_rate) is at most yaw_tol in magnitude": `|kin_yaw_rate a| ≤ yaw_tol`.
  The recognition condition is the conjunction `settled` of the two; "recognized at the observation
  at which [it holds] where this did not hold at the previous observation ... holds at that
  observation only, and not again until that condition has ceased to hold and then holds again" is
  `rises settled`: true where `settled` holds and did not hold at the observation before.
  No choice was left open by the contract: no narrowing.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.motion.left_turn

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aA : Arg := .var "a"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
def pWindow : Term := .param "window"
def pTurnMin : Term := .param "turn_min"
def pUTurnMin : Term := .param "u_turn_min"
def pYawTol : Term := .param "yaw_tol"

/-- The heading change of a over the window behind (degrees, left positive). -/
def headingChange : Term := .quantity "prim_heading_change" [aA] [pWindow]

/-- The heading change lies in the band of a turn to the left: turn_min inclusive to u_turn_min exclusive. -/
def inBand : Formula :=
  .and (.cmp headingChange .ge pTurnMin) (.cmp headingChange .lt pUTurnMin)

/-- a's yaw rate is at most yaw_tol in magnitude: the heading has stopped turning. -/
def yawSettled : Formula :=
  .cmp (.abs (.measure "kin_yaw_rate" [aA])) .le pYawTol

/-- The recognition condition: a heading change in the band, and the heading no longer turning. -/
def settled : Formula := .and inBand yawSettled

/-- Recognized where the condition holds and did not hold at the previous observation. -/
def body : Formula := .rises settled

def concept : Concept :=
  { id := "drv.motion.left_turn"
    contract := "Road user a has completed a turn to the left. Its heading change over the window behind the observation (prim.heading_change over a window of length window, degrees, positive to the left) lies in the band from turn_min inclusive to u_turn_min exclusive, so that a heading change too small to be a turn and a reversal of direction both lie outside it. The act begins within the window behind the observation at which it is recognized. The act is recognized at the observation at which the heading change over the window behind lies in that band and a's yaw rate (kin.yaw_rate) is at most yaw_tol in magnitude, where this did not hold at the previous observation: the heading has stopped turning. The concept holds at that observation only, and not again until that condition has ceased to hold and then holds again. Conduct before the window behind is not read: a turn that takes longer than the window is not recognized. It denotes the change of a's heading only: it says nothing of the lane, the intersection or the way on which a turns, of its speed, or of why it turns. Not denoted: a heading change to the left smaller than turn_min, such as a lane change or a drift; a heading change of u_turn_min or more, which is a reversal of direction; a turn to the right; a turn still under way, whose yaw rate exceeds yaw_tol. Where the window is truncated or a yaw rate in it is missing, it is unknown."
    definition := none
    args := [("a", .track)]
    params := [⟨"window", .second⟩, ⟨"turn_min", .degree⟩, ⟨"u_turn_min", .degree⟩, ⟨"yaw_tol", .degreePerSecond⟩]
    body := .formula body
    residues := []  -- the record's, verbatim; not yours to change
    narrowings := []  -- one { span := "<words of the contract>", why := "<why>", kind := "reading" } per reading you chose that the contract leaves open, explained in the header
    supersedes := none }

end TrafficSpec.Concepts.motion.left_turn
