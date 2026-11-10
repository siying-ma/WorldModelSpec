/-
  drv.motion.stopped — A road user is at a complete halt at the observation: the definition's "complete cessation from movement", observed as the magnitude of its velocity (kin.speed) at or below `tol`, a tolerance that names only the source's speed resolution, below which a sampled speed counts as no movement. It denotes the halt whoever or whatever controls the road user. Not denoted: a halt held over a window, since the concept reads the one observation; where the road user halts, which the caller states.

  The contract is the definition `DEF-NRS-484A-255`, verbatim.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    the magnitude of its velocity (kin.speed) at or below `tol`: atoms ['kin.speed'], concepts []
      written `kin_speed x ≤ tol` at the one observation judged; "at or below" is `.le`.

  No choice was left open: the contract names the atom, the comparison and the parameter, and
  excludes any window; no narrowing is declared.

  No magnitude below is this file's own: parameters are formals the caller fills.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.motion.stopped

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aX : Arg := .var "x"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
def pTol : Term := .param "tol"

/-- The magnitude of x's velocity at the observation, at or below the speed resolution `tol`. -/
def body : Formula := .cmp (.measure "kin_speed" [aX]) .le pTol

def concept : Concept :=
  { id := "drv.motion.stopped"
    contract := "A road user is at a complete halt at the observation: the definition's \"complete cessation from movement\", observed as the magnitude of its velocity (kin.speed) at or below `tol`, a tolerance that names only the source's speed resolution, below which a sampled speed counts as no movement. It denotes the halt whoever or whatever controls the road user. Not denoted: a halt held over a window, since the concept reads the one observation; where the road user halts, which the caller states."
    definition := some "DEF-NRS-484A-255"
    args := [("x", .track)]
    params := [⟨"tol", .metrePerSecond⟩]
    body := .formula body
    residues := ["The definition's scope ('when required'): which duty requires the halt is the caller's, not the concept's."]  -- the record's, verbatim; not yours to change
    narrowings := []  -- one { span := "<words of the contract>", why := "<why>", kind := "reading" } per reading you chose that the contract leaves open, explained in the header
    supersedes := none }

end TrafficSpec.Concepts.motion.stopped
