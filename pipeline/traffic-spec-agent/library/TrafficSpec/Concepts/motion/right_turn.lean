/-
  drv.motion.right_turn — The road user turns its body to the right: the signed heading change over the window behind the observation, left positive, lies at or below the swing the caller sets taken negative - that is, the body has swung to its right through at least that swing. Units: the window in seconds, the swing in degrees. The verdict is unknown where the window reaches past the start of the trace or the heading change cannot be formed. Not a stand-in for: the turn indicator or an arm signal, which are what the road user shows and not what the body does; a lane change or a drift across a lane, which a small swing does not tell from a turn - the caller's swing does; the place at which the turning happens, which the caller reads; or a turn of the body to its left.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    the signed heading change over the window behind the observation, left positive: atoms ['prim.heading_change'], concepts []

  How the words are written:
  - "the signed heading change over the window behind the observation, left positive" is
    `Term.quantity "prim_heading_change" [user] [window]`: the primitive's contract is the
    contract's own sentence — degrees, left positive, over the back window of length `window`,
    integrated from the yaw rate — so the element is one call and nothing is assembled around it.
    The primitive's window is a time window of its parameter's seconds, which is the unit the
    contract gives `window`; the formal parameter is passed straight through as that length.
    `kin.heading` is not read beside it: the instantaneous direction a body points says nothing of
    how far it has swung over a window, and `kin.yaw_rate` is the primitive's own input, not an
    atom of this concept.
  - "lies at or below the swing the caller sets taken negative" is `.cmp Δ .le (.neg pSwing)`:
    "at or below" is `.le`, and "the swing … taken negative" is `.neg` of the formal parameter,
    so a caller sets a positive swing in degrees and the bound is its negation. Reading it to the
    other side is what drv.motion.left_turn does; no magnitude of this file's own enters the bound.
  - The body is not wrapped in `holdsFor`: the window behind is already the primitive's, and a
    second window over it would ask the swing to have been reached at every observation of a
    second, outer span — which the contract's words do not say.
  - Where the window reaches past the start of the trace the primitive is `windowTruncated`, and
    where a yaw rate inside it is missing it is `absentAtom`; the comparison carries either through
    unchanged, which is the unknown the contract names.
  - Nothing here is a reading the contract leaves open, so `narrowings` is empty: every operator
    above is the one its words name.

  No magnitude below is this file's own: parameters are formals the caller fills.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.motion.right_turn

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aUser : Arg := .var "user"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
def pWindow : Term := .param "window"
def pSwing : Term := .param "swing"

/-- The signed heading change of the user over the window behind the observation, in degrees,
    left positive: the primitive, with the caller's window as its length. -/
def headingChange : Term := .quantity "prim_heading_change" [aUser] [pWindow]

/-- The bound the swing sets: the caller's swing taken negative, the turn being to the right. -/
def rightBound : Term := .neg pSwing

/-- The body has swung to its right through at least the swing the caller sets. -/
def body : Formula := .cmp headingChange .le rightBound

def concept : Concept :=
  { id := "drv.motion.right_turn"
    contract := "The road user turns its body to the right: the signed heading change over the window behind the observation, left positive, lies at or below the swing the caller sets taken negative - that is, the body has swung to its right through at least that swing. Units: the window in seconds, the swing in degrees. The verdict is unknown where the window reaches past the start of the trace or the heading change cannot be formed. Not a stand-in for: the turn indicator or an arm signal, which are what the road user shows and not what the body does; a lane change or a drift across a lane, which a small swing does not tell from a turn - the caller's swing does; the place at which the turning happens, which the caller reads; or a turn of the body to its left."
    definition := none
    args := [("user", .track)]
    params := [⟨"window", .second⟩, ⟨"swing", .degree⟩]
    body := .formula body
    residues := []  -- the record's, verbatim; not yours to change
    narrowings := []  -- nothing the contract leaves open: see the header
    supersedes := none }

end TrafficSpec.Concepts.motion.right_turn
