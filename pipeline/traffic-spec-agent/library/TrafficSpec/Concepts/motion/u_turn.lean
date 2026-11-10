/-
  drv.motion.u_turn — A road user has turned "so as to proceed in the opposite direction, whether accomplished by one continuous movement or not": over the window of length `window` behind the observation, the magnitude of its heading change (prim.heading_change, integrated from its yaw rate across forward and backing moves alike) is at least `min_angle` and at most `max_angle`, the band within which its heading has come round to the opposite direction (a smaller change is a turn, a larger one a loop past the opposite direction). The act is recognized at the observation at which the window's heading change entered that band. The act began within the window behind that observation. The concept holds while the window's change stays in the band, and ends when the change leaves it. No conduct before the window is read. Not denoted: a turn short of a reversal; a loop past the opposite direction; where the turn is made, which the caller states; the class of the road user, which the caller states.

  The contract is the definition `DEF-NRS-484B-077`, verbatim.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    the magnitude of its heading change (prim.heading_change: atoms ['prim.heading_change'], concepts []

  Written: |prim_heading_change(x; window)| ≥ min_angle ∧ |prim_heading_change(x; window)| ≤ max_angle.
  "magnitude" is `Term.abs` of the signed change, so a reversal to either side counts; "at least" and
  "at most" are `.ge` and `.le`. The contract left no choice open: no narrowing.

  No magnitude below is this file's own: parameters are formals the caller fills.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.motion.u_turn

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aX : Arg := .var "x"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
def pWindow : Term := .param "window"
def pMinAngle : Term := .param "min_angle"
def pMaxAngle : Term := .param "max_angle"

/-- "the magnitude of its heading change" over the window of length `window` behind the observation:
    the absolute value of `prim.heading_change`, which integrates the yaw rate over forward and
    backing moves alike. -/
def headingChange : Term := .abs (.quantity "prim_heading_change" [aX] [pWindow])

/-- "is at least `min_angle` and at most `max_angle`": the band, both ends inclusive. Holding exactly
    while the window's change lies in the band gives the act's recognition (the change entering the
    band), its extent (while it stays) and its end (when it leaves); nothing before the window is read. -/
def body : Formula :=
  .and (.cmp headingChange .ge pMinAngle) (.cmp headingChange .le pMaxAngle)

def concept : Concept :=
  { id := "drv.motion.u_turn"
    contract := "A road user has turned \"so as to proceed in the opposite direction, whether accomplished by one continuous movement or not\": over the window of length `window` behind the observation, the magnitude of its heading change (prim.heading_change, integrated from its yaw rate across forward and backing moves alike) is at least `min_angle` and at most `max_angle`, the band within which its heading has come round to the opposite direction (a smaller change is a turn, a larger one a loop past the opposite direction). The act is recognized at the observation at which the window's heading change entered that band. The act began within the window behind that observation. The concept holds while the window's change stays in the band, and ends when the change leaves it. No conduct before the window is read. Not denoted: a turn short of a reversal; a loop past the opposite direction; where the turn is made, which the caller states; the class of the road user, which the caller states."
    definition := some "DEF-NRS-484B-077"
    args := [("x", .track)]
    params := [⟨"window", .second⟩, ⟨"min_angle", .degree⟩, ⟨"max_angle", .degree⟩]
    body := .formula body
    residues := ["The place of the turn is the caller's condition: the concept reads the road user's motion only.", "The class of the road user is the caller's condition, stated with its own admitted aggregate."]  -- the record's, verbatim; not yours to change
    narrowings := []  -- one { span := "<words of the contract>", why := "<why>", kind := "reading" } per reading you chose that the contract leaves open, explained in the header
    supersedes := none }

end TrafficSpec.Concepts.motion.u_turn
