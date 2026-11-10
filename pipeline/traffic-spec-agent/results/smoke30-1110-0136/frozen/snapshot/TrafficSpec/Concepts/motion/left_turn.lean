/-
  drv.motion.left_turn — A road user has turned to the left: over the window of length `window` behind the observation, its heading changed to the left (prim.heading_change, left positive) by at least `min_angle` and by less than `max_angle`, the change at which the heading has come round to the opposite direction (a reversal, not a left turn). The act is recognized at the observation at which the window's heading change entered that band. The act began within the window behind that observation. The concept holds while the window's change stays in the band, and ends when the change leaves it. No conduct before the window is read. Not denoted: a right turn; a reversal of direction; a lane change or a bend's drift below `min_angle`; where the turn is made, which the caller states.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    its heading changed to the left (prim.heading_change, left positive): atoms ['prim.heading_change'], concepts []

  No magnitude below is this file's own: parameters are formals the caller fills.

  The writing. `hc` is `prim_heading_change x window`: the signed heading change (left positive)
  over the back window of length `window`, read at each observation. The body is the band
  `min_angle ≤ hc ∧ hc < max_angle`: "by at least `min_angle`" is `≥`, "by less than `max_angle`"
  is `<`. Recognition, onset, extent and history follow from the primitive itself: the band holds
  from the observation at which the window's change entered it, the turn lies within the window
  behind that observation, the concept holds while the change stays in the band and ends when it
  leaves it, and nothing before the window is read. A right turn (negative change), a drift below
  `min_angle` and a reversal (`≥ max_angle`) all fall outside the band. Where the turn is made is
  not read. No choice was left open: no narrowing.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.motion.left_turn

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aX : Arg := .var "x"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
def pWindow : Term := .param "window"
def pMinAngle : Term := .param "min_angle"
def pMaxAngle : Term := .param "max_angle"

/-- The heading change (degrees, left positive) of `x` over the window behind the observation. -/
def hc : Term := .quantity "prim_heading_change" [aX] [pWindow]

/-- Turned left: the window's change is at least `min_angle` and less than `max_angle`. -/
def body : Formula :=
  .and (.cmp hc .ge pMinAngle) (.cmp hc .lt pMaxAngle)

def concept : Concept :=
  { id := "drv.motion.left_turn"
    contract := "A road user has turned to the left: over the window of length `window` behind the observation, its heading changed to the left (prim.heading_change, left positive) by at least `min_angle` and by less than `max_angle`, the change at which the heading has come round to the opposite direction (a reversal, not a left turn). The act is recognized at the observation at which the window's heading change entered that band. The act began within the window behind that observation. The concept holds while the window's change stays in the band, and ends when the change leaves it. No conduct before the window is read. Not denoted: a right turn; a reversal of direction; a lane change or a bend's drift below `min_angle`; where the turn is made, which the caller states."
    definition := none
    args := [("x", .track)]
    params := [⟨"window", .second⟩, ⟨"min_angle", .degree⟩, ⟨"max_angle", .degree⟩]
    body := .formula body
    residues := []  -- the record's, verbatim; not yours to change
    narrowings := []
    supersedes := none }

end TrafficSpec.Concepts.motion.left_turn
