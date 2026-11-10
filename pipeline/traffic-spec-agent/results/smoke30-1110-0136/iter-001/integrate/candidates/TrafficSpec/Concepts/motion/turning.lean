/-
  drv.motion.turning — A road user's heading is changing at the observation: the magnitude of its yaw rate (kin.yaw_rate) exceeds `tol`, a tolerance that names only the source's yaw-rate resolution, to either hand and whether the road user moves forwards or backwards. Not denoted: the curvature of the road, which the concept does not read; a completed turn or the angle turned; the hand of the turn.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    the magnitude of its yaw rate (kin.yaw_rate): atoms ['kin.yaw_rate'], concepts []
      written `Term.abs (Term.measure "kin_yaw_rate" [x])`; "exceeds `tol`" is a strict `.gt`
      against the formal parameter, so a yaw rate at or below `tol` in magnitude counts as none.

  Choices the contract did not dictate: none. "To either hand" is the absolute value; "whether
  the road user moves forwards or backwards" needs no term, since the body reads no speed, gear
  or direction of travel. No narrowing is declared.

  No magnitude below is this file's own: parameters are formals the caller fills.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.motion.turning

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aX : Arg := .var "x"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
def pTol : Term := .param "tol"

/-- |kin.yaw_rate x| > tol: the absolute value covers either hand, and the yaw rate is the
    heading's own rate, so the sense of travel (forwards or backwards) does not enter. -/
def body : Formula :=
  .cmp (.abs (.measure "kin_yaw_rate" [aX])) .gt pTol

def concept : Concept :=
  { id := "drv.motion.turning"
    contract := "A road user's heading is changing at the observation: the magnitude of its yaw rate (kin.yaw_rate) exceeds `tol`, a tolerance that names only the source's yaw-rate resolution, to either hand and whether the road user moves forwards or backwards. Not denoted: the curvature of the road, which the concept does not read; a completed turn or the angle turned; the hand of the turn."
    definition := none
    args := [("x", .track)]
    params := [⟨"tol", .degreePerSecond⟩]
    body := .formula body
    residues := []  -- the record's, verbatim; not yours to change
    narrowings := []  -- one { span := "<words of the contract>", why := "<why>", kind := "reading" } per reading you chose that the contract leaves open, explained in the header
    supersedes := none }

end TrafficSpec.Concepts.motion.turning
