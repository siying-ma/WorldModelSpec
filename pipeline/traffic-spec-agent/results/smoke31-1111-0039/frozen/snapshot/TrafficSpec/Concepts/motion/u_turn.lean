/-
  drv.motion.u_turn — Road user x has turned so as to proceed in the opposite direction: the turning that the corpus defines as "the turning of a vehicle upon a highway so as to proceed in the opposite direction, whether accomplished by one continuous movement or not", observed as a reversal of x's heading. It holds at an observation where the absolute value of x's signed heading change over the window behind it (prim.heading_change with window; degrees, left positive) differs from the literal half turn by no more than reversal_tolerance: the heading now points the opposite way within the tolerance, and a heading change that has gone past the half turn by more than the tolerance (a loop back toward the first direction) does not count. A turning made in several movements, forward and backing, counts, since the heading change is integrated through all of them. The act begins within the window behind the observation of recognition; it is recognized at the observation at which this condition rises; it holds at the later observations at which the reversal still lies within the window behind them, which are not the act again, and it ends when the reversal leaves that window. Unknown where the window is truncated, sampled too sparsely, or a yaw rate is missing. Not denoted: a turning by less than a reversal, or the place of the turning: the caller states the highway or the zone.

  Based on the posted definition `DEF-NRS-484B-077`: the contract above is this record's reading
  of it, not its text.

  The posted text (the definition's words; the concept denotes its contract):
    “U-turn” means the turning of a vehicle upon a highway so as to proceed in the opposite direction, whether accomplished by one continuous movement or not.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    the absolute value of x's signed heading change over the window behind it (prim.heading_change with window; degrees, left positive): atoms ['prim.heading_change'], concepts []

  Literals the contract states (declared; written through a `Units` constructor):
    180 deg — the half turn: a heading pointing the opposite way

  How each element is written:
    the absolute value of x's signed heading change over the window behind it: written
      `.abs (Term.quantity "prim_heading_change" [x] [window])`; the primitive integrates
      kin.yaw_rate through forward and backing movements alike, so a turning in several movements
      counts, and it is unknown on a truncated or sparsely sampled window or a missing yaw rate.
    differs from the literal half turn by no more than reversal_tolerance: written
      `|(|Δ|) − 180 deg| ≤ reversal_tolerance` (`.cmp … .le …`), so a change short of the half
      turn and one gone past it by more than the tolerance (a loop back) both fail.
    act (recognition at the rise, extent while the reversal lies in the window): the body is the
      condition at the observation; it rises at recognition and holds while the reversal stays in
      the back window, which is what the condition itself does, so no time operator surrounds it.

  Choices the contract left open: none (no narrowing).

  No magnitude below is this file's own: parameters are formals the caller fills.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.motion.u_turn

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aX : Arg := .var "x"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
def pWindow : Term := .param "window"
def pReversalTolerance : Term := .param "reversal_tolerance"

/-- The declared literal: the half turn, 180 deg. -/
def halfTurn : Term := .lit (Units.degrees 180) .degree

/-- The signed heading change of x over the window behind the observation (degrees, left positive). -/
def headingChange : Term := .quantity "prim_heading_change" [aX] [pWindow]

/-- The size of the heading change differs from the half turn by no more than the tolerance, at
    this observation; a change past the half turn by more than the tolerance does not count. -/
def body : Formula :=
  .cmp (.abs (.sub (.abs headingChange) halfTurn)) .le pReversalTolerance

def concept : Concept :=
  { id := "drv.motion.u_turn"
    contract := "Road user x has turned so as to proceed in the opposite direction: the turning that the corpus defines as \"the turning of a vehicle upon a highway so as to proceed in the opposite direction, whether accomplished by one continuous movement or not\", observed as a reversal of x's heading. It holds at an observation where the absolute value of x's signed heading change over the window behind it (prim.heading_change with window; degrees, left positive) differs from the literal half turn by no more than reversal_tolerance: the heading now points the opposite way within the tolerance, and a heading change that has gone past the half turn by more than the tolerance (a loop back toward the first direction) does not count. A turning made in several movements, forward and backing, counts, since the heading change is integrated through all of them. The act begins within the window behind the observation of recognition; it is recognized at the observation at which this condition rises; it holds at the later observations at which the reversal still lies within the window behind them, which are not the act again, and it ends when the reversal leaves that window. Unknown where the window is truncated, sampled too sparsely, or a yaw rate is missing. Not denoted: a turning by less than a reversal, or the place of the turning: the caller states the highway or the zone."
    definition := some "DEF-NRS-484B-077"
    args := [("x", .track)]
    params := [⟨"window", .second⟩, ⟨"reversal_tolerance", .degree⟩]
    body := .formula body
    residues := ["The place is the caller's: the concept reads x's heading only, and the calling rule states the region (the highway or the zone) the turning is made in.", "Read as the reversal of x's own heading. A road user following a bend of the way that itself turns through a half turn within the window also reverses its heading; no atom of the closed set states the course of the way along x's path, so the two are not told apart."]  -- the record's, verbatim; not yours to change
    narrowings := []  -- one { span := "<words of the contract>", why := "<why>", kind := "reading" } per reading you chose that the contract leaves open, explained in the header
    supersedes := none }

end TrafficSpec.Concepts.motion.u_turn
