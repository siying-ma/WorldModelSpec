/-
  drv.motion.left_turn — Road user a has completed a turn to the left. Its heading change over the window behind the observation (prim.heading_change over a window of length window, degrees, positive to the left) lies in the band from turn_min inclusive to u_turn_min exclusive, so that a heading change too small to be a turn and a reversal of direction both lie outside it. The act begins within the window behind the observation at which it is recognized. The act is recognized at the observation at which the heading change over the window behind lies in that band and a's yaw rate (kin.yaw_rate) is at most yaw_tol in magnitude, where this did not hold at the previous observation: the heading has stopped turning. The concept holds at that observation only, and not again until that condition has ceased to hold and then holds again. Conduct before the window behind is not read: a turn that takes longer than the window is not recognized. It denotes the change of a's heading only: it says nothing of the lane, the intersection or the way on which a turns, of its speed, or of why it turns. Not denoted: a heading change to the left smaller than turn_min, such as a lane change or a drift; a heading change of u_turn_min or more, which is a reversal of direction; a turn to the right; a turn still under way, whose yaw rate exceeds yaw_tol. Where the window is truncated or a yaw rate in it is missing, it is unknown.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    Its heading change over the window behind the observation (prim.heading_change over a window of length window, degrees, positive to the left) lies in the band from turn_min inclusive to u_turn_min exclusive: atoms ['prim.heading_change'], concepts []
    a's yaw rate (kin.yaw_rate) is at most yaw_tol in magnitude: atoms ['kin.yaw_rate'], concepts []

  No magnitude below is this file's own: parameters are formals the caller fills.

  How the contract is written:
    - heading change over the window behind: `Term.quantity "prim_heading_change" [a] [window]`;
      its unknowns (window truncated, sampled too sparsely, a yaw rate missing) are the contract's.
    - the band: `turn_min ≤ Δψ` and `Δψ < u_turn_min`, signed (left positive), so a turn to the
      right (negative) and a reversal lie outside it.
    - stopped turning: `|kin_yaw_rate a| ≤ yaw_tol`.
    - recognition, holding at that observation only and not again until the condition has ceased
      and holds again: `rises (band ∧ stopped)`.
  No narrowing: every choice above is the contract's own words.
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

/-- a's heading change over the window behind the observation (prim.heading_change), degrees,
    left positive; unknown where the window is truncated or a yaw rate in it is missing. -/
def turned : Term := .quantity "prim_heading_change" [aA] [pWindow]

/-- a's yaw rate (kin.yaw_rate). -/
def yaw : Term := .measure "kin_yaw_rate" [aA]

/-- The heading change lies in the band [turn_min, u_turn_min). -/
def inBand : Formula := .and (.cmp turned .ge pTurnMin) (.cmp turned .lt pUTurnMin)

/-- The heading has stopped turning: |yaw rate| ≤ yaw_tol. -/
def settled : Formula := .cmp (.abs yaw) .le pYawTol

/-- The recognition condition: in the band and no longer turning. -/
def complete : Formula := .and inBand settled

/-- Recognized where the condition holds and did not hold at the previous observation. -/
def body : Formula := .rises complete

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
