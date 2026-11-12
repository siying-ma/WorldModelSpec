/-
  drv.motion.left_turn — Road user a makes a left turn: within the window behind the observation its heading turns to the left by an angle within the turn band, from the lower bound, below which a heading change counts as no turn, up to the upper bound, above which the road user's direction counts as reversed. Measured as the signed heading change over the window (prim.heading_change, degrees, left positive) at or above the lower bound and at or below the upper bound. The act is recognized at the observation at which the heading change over the window first reaches the lower bound. Its observed beginning lies within the window behind that observation. The concept holds at every observation at which the heading change over the window lies within the band, and ends where it leaves the band. It is unknown where the window reaches past the start of the recording or a yaw rate in it is missing. Not a stand-in for the turn indicator or for a declared intention to turn.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    the signed heading change over the window (prim.heading_change, degrees, left positive): atoms ['prim.heading_change'], concepts []

  No magnitude below is this file's own: parameters are formals the caller fills.

  How the words are written:
    "the signed heading change over the window" — `prim_heading_change a window`, a quantity term
      (degrees, left positive), read once and bounded on both sides.
    "at or above the lower bound and at or below the upper bound" — `≥ min_angle` and `≤ max_angle`,
      both inclusive as the contract says.
    "holds at every observation at which the heading change over the window lies within the band,
      and ends where it leaves the band" — the body is the band test itself at each observation, so
      its extent is the run of observations in the band; recognition ("first reaches the lower
      bound") is the rise of that run, and the onset lies within the window by construction of the
      primitive.
    "unknown where the window reaches past the start of the recording or a yaw rate in it is
      missing" — inherited from the primitive (`windowTruncated`, `absentAtom kin_yaw_rate`).
  No choice was left open: no narrowing.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.motion.left_turn

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aA : Arg := .var "a"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
def pWindow : Term := .param "window"
def pMinAngle : Term := .param "min_angle"
def pMaxAngle : Term := .param "max_angle"

/-- The signed heading change (degrees, left positive) of `a` over the window behind. -/
def headingChange : Term := .quantity "prim_heading_change" [aA] [pWindow]

/-- The heading change over the window lies within the turn band [min_angle, max_angle]. -/
def body : Formula :=
  .and (.cmp headingChange .ge pMinAngle) (.cmp headingChange .le pMaxAngle)

def concept : Concept :=
  { id := "drv.motion.left_turn"
    contract := "Road user a makes a left turn: within the window behind the observation its heading turns to the left by an angle within the turn band, from the lower bound, below which a heading change counts as no turn, up to the upper bound, above which the road user's direction counts as reversed. Measured as the signed heading change over the window (prim.heading_change, degrees, left positive) at or above the lower bound and at or below the upper bound. The act is recognized at the observation at which the heading change over the window first reaches the lower bound. Its observed beginning lies within the window behind that observation. The concept holds at every observation at which the heading change over the window lies within the band, and ends where it leaves the band. It is unknown where the window reaches past the start of the recording or a yaw rate in it is missing. Not a stand-in for the turn indicator or for a declared intention to turn."
    definition := none
    args := [("a", .track)]
    params := [⟨"window", .second⟩, ⟨"min_angle", .degree⟩, ⟨"max_angle", .degree⟩]
    body := .formula body
    residues := []  -- the record's, verbatim; not yours to change
    narrowings := []
    supersedes := none }

end TrafficSpec.Concepts.motion.left_turn
