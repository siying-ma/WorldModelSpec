/-
  drv.motion.moving — A road user is in motion at the observation: the magnitude of its velocity (kin.speed) exceeds `tol`, a tolerance that names only the source's speed resolution, below which a reading counts as standing still. It denotes motion in any direction, forwards or backwards, whoever or whatever controls the road user. Not denoted: the direction of motion; a halt held over a window, since the concept reads the one observation.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    the magnitude of its velocity (kin.speed): atoms ['kin.speed'], concepts []

  No magnitude below is this file's own: parameters are formals the caller fills.

  Writing: "the magnitude of its velocity (kin.speed) exceeds `tol`" is `kin_speed x > tol`, a
  strict comparison, so a reading at `tol` counts as standing still, as the parameter's meaning says.
  kin.speed carries no direction, so motion forwards and backwards alike is denoted; no class or
  control condition is read. One observation, no time operator. No narrowing: the contract
  dictates every choice.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.motion.moving

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aX : Arg := .var "x"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
def pTol : Term := .param "tol"

/-- The speed of `x` exceeds the resolution `tol`. -/
def body : Formula := .cmp (.measure "kin_speed" [aX]) .gt pTol

def concept : Concept :=
  { id := "drv.motion.moving"
    contract := "A road user is in motion at the observation: the magnitude of its velocity (kin.speed) exceeds `tol`, a tolerance that names only the source's speed resolution, below which a reading counts as standing still. It denotes motion in any direction, forwards or backwards, whoever or whatever controls the road user. Not denoted: the direction of motion; a halt held over a window, since the concept reads the one observation."
    definition := none
    args := [("x", .track)]
    params := [⟨"tol", .metrePerSecond⟩]
    body := .formula body
    residues := []  -- the record's, verbatim; not yours to change
    narrowings := []
    supersedes := none }

end TrafficSpec.Concepts.motion.moving
