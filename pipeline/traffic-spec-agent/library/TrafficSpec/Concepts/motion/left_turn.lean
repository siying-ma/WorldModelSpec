/-
  drv.motion.left_turn — The road user turns its body to the left: the signed heading change over the window behind the observation, left positive, is at or above the swing the caller sets. Units: the window in seconds, the swing in degrees. The verdict is unknown where the window reaches past the start of the trace or the heading change cannot be formed. Not a stand-in for: the turn indicator or an arm signal, which are what the road user shows and not what the body does; a lane change or a drift across a lane, which a small swing does not tell from a turn — the caller's swing does; the place at which the turning happens, which the caller reads; or a turn of the body to its right.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    the signed heading change over the window behind the observation, left positive: atoms ['prim.heading_change'], concepts []

  How the words are written:
  - "the signed heading change over the window behind the observation, left positive" is the
    primitive `prim_heading_change` called on the one track formal with the formal parameter
    `window` as its window length: the primitive is exactly this quantity — "signed heading change
    (degrees, left positive) over the back window w, integrated from the yaw rate". It is
    `QR`-valued, so it is written as a `Term.quantity`. Its sign convention (left positive) and its
    window (behind, in time) are the primitive's own; nothing here negates, reorients or rescales
    it, and the concept reads no kinematic atom of its own — the yaw rate the integration needs is
    the primitive's input.
  - "is at or above the swing the caller sets" is `.cmp … .ge pSwing`: the comparison is on the
    SIGNED change, so a swing to the right (a negative change) falls below any swing the caller
    sets to the left, and the contract's exclusion of "a turn of the body to its right" is carried
    by the sign rather than by a test of its own. "At or above" is `.ge`, inclusive.
  - "unknown where the window reaches past the start of the trace or the heading change cannot be
    formed" needs nothing written: the primitive already returns `windowTruncated` on an uncovered
    window, `samplingGap` on one sampled too sparsely and `absentAtom "kin_yaw_rate"` where a yaw
    rate inside the window is missing, and a comparison on an unknown quantity is unknown.
  - "a lane change or a drift across a lane … the caller's swing does" and "the place at which the
    turning happens, which the caller reads" are left to the caller, as the contract says: the
    body carries no magnitude and no region of its own.

  No magnitude below is this file's own: parameters are formals the caller fills.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.motion.left_turn

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aUser : Arg := .var "user"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
def pWindow : Term := .param "window"
def pSwing : Term := .param "swing"

/-- The signed heading change of the user over the window behind, in degrees, left positive:
    the primitive, integrated from the yaw rate, with the caller's window as its length. -/
def headingChange : Term := .quantity "prim_heading_change" [aUser] [pWindow]

/-- The swing to the left over the window behind is at or above the one the caller sets. -/
def body : Formula := .cmp headingChange .ge pSwing

def concept : Concept :=
  { id := "drv.motion.left_turn"
    contract := "The road user turns its body to the left: the signed heading change over the window behind the observation, left positive, is at or above the swing the caller sets. Units: the window in seconds, the swing in degrees. The verdict is unknown where the window reaches past the start of the trace or the heading change cannot be formed. Not a stand-in for: the turn indicator or an arm signal, which are what the road user shows and not what the body does; a lane change or a drift across a lane, which a small swing does not tell from a turn — the caller's swing does; the place at which the turning happens, which the caller reads; or a turn of the body to its right."
    definition := none
    args := [("user", .track)]
    params := [⟨"window", .second⟩, ⟨"swing", .degree⟩]
    body := .formula body
    residues := []  -- the record's, verbatim; not yours to change
    narrowings := []
    supersedes := none }

end TrafficSpec.Concepts.motion.left_turn
