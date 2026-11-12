/-
  drv.motion.u_turn — Road user a makes a U-turn: "the turning of a vehicle upon a highway so as to proceed in the opposite direction, whether accomplished by one continuous movement or not". Observed as a heading change within the window behind the observation, to either hand, whose magnitude lies within the reversal band: from the lower bound, at or beyond which the road user's direction counts as reversed, up to the upper bound, beyond which it has turned past the opposite direction. Measured as the magnitude of the signed heading change over the window (prim.heading_change, degrees). The window admits a turn made in several movements, forward and reverse. The act is recognized at the observation at which the magnitude first reaches the lower bound. Its observed beginning lies within the window behind that observation. The concept holds at every observation at which the magnitude lies within the band, and ends where it leaves the band. It is unknown where the window reaches past the start of the recording or a yaw rate in it is missing. Not a stand-in for backing: a reversal of travel without a change of heading is no U-turn.

  Based on the posted definition `DEF-NRS-484B-077`: the contract above is this record's reading
  of it, not its text.

  The posted text (the definition's words; the concept denotes its contract):
    “U-turn” means the turning of a vehicle upon a highway so as to proceed in the opposite direction, whether accomplished by one continuous movement or not.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    the magnitude of the signed heading change over the window (prim.heading_change, degrees): atoms ['prim.heading_change'], concepts []

  The body: |prim_heading_change(a, window)| ≥ min_angle ∧ |prim_heading_change(a, window)| ≤ max_angle,
  at each observation. The band is closed at both ends, as the contract states it ("at or beyond"
  the lower bound; "beyond" the upper bound is out). The recognition, onset and extent sentences
  follow from the pointwise reading over the back window; the history clause is the primitive's
  own unknown (a truncated window, a missing yaw rate). No narrowing is taken.

  No magnitude below is this file's own: parameters are formals the caller fills.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.motion.u_turn

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aA : Arg := .var "a"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
def pWindow : Term := .param "window"
def pMinAngle : Term := .param "min_angle"
def pMaxAngle : Term := .param "max_angle"

/-- The signed heading change of `a` over the window behind the observation (prim.heading_change,
    degrees, left positive): integrated from the yaw rate, it sums every movement of a turn made in
    several, forward and reverse; unknown where the window is truncated or a yaw rate is missing. -/
def headingChange : Term := .quantity "prim_heading_change" [aA] [pWindow]

/-- Its magnitude, so that a turn to either hand counts. -/
def magnitude : Term := .abs headingChange

/-- The magnitude lies within the reversal band: at or beyond the lower bound, and not beyond the
    upper bound. Holding pointwise, it is first true where the magnitude first reaches the lower
    bound and ends where the magnitude leaves the band; a backing manoeuvre, with no heading change,
    leaves the magnitude at zero. -/
def body : Formula :=
  .and (.cmp magnitude .ge pMinAngle) (.cmp magnitude .le pMaxAngle)

def concept : Concept :=
  { id := "drv.motion.u_turn"
    contract := "Road user a makes a U-turn: \"the turning of a vehicle upon a highway so as to proceed in the opposite direction, whether accomplished by one continuous movement or not\". Observed as a heading change within the window behind the observation, to either hand, whose magnitude lies within the reversal band: from the lower bound, at or beyond which the road user's direction counts as reversed, up to the upper bound, beyond which it has turned past the opposite direction. Measured as the magnitude of the signed heading change over the window (prim.heading_change, degrees). The window admits a turn made in several movements, forward and reverse. The act is recognized at the observation at which the magnitude first reaches the lower bound. Its observed beginning lies within the window behind that observation. The concept holds at every observation at which the magnitude lies within the band, and ends where it leaves the band. It is unknown where the window reaches past the start of the recording or a yaw rate in it is missing. Not a stand-in for backing: a reversal of travel without a change of heading is no U-turn."
    definition := some "DEF-NRS-484B-077"
    args := [("a", .track)]
    params := [⟨"window", .second⟩, ⟨"min_angle", .degree⟩, ⟨"max_angle", .degree⟩]
    body := .formula body
    residues := ["The place of the turn is read by the calling rule, which binds the region.", "The class of the road user is the calling rule's: a is whatever road user it passes."]  -- the record's, verbatim; not yours to change
    narrowings := []  -- one { span := "<words of the contract>", why := "<why>", kind := "reading" } per reading you chose that the contract leaves open, explained in the header
    supersedes := none }

end TrafficSpec.Concepts.motion.u_turn
