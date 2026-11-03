/-
  drv.motion.direction_reversal — At the observation the road user has turned so as to proceed in the direction opposite the one it was proceeding in: the magnitude of the heading change it has accumulated over the window behind of length window is at least heading_change_min, a bound near a half turn. The corpus definition this contract quotes speaks of "the turning of a vehicle upon a highway so as to proceed in the opposite direction, whether accomplished by one continuous movement or not", so the accumulation runs over a window long enough to cover a reversal made in several movements, and the window length is the caller's parameter; the turn is recognized once the change has been carried out, and a caller that needs the act reads the observation at which the concept rises. Where the window reaches past the start of the trace, is sampled too sparsely, or a yaw rate is missing, it is unknown. Not a stand-in for: a turn to the left or the right short of a reversal, a reversal of the direction of motion without turning (a vehicle backing), the place the turn is made at, the lawfulness of the manoeuvre, or the hand to which the turn is made -- the magnitude is read, so a reversal either way is one.

  The contract is the definition `DEF-NRS-484B-077`, verbatim.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    the magnitude of the heading change it has accumulated over the window behind of length window is at least heading_change_min: atoms ['prim.heading_change'], concepts []

  How that element is written. `prim.heading_change` is "the signed heading change (degrees, left
  positive) of a road user over the window behind the observation, integrated from kin.yaw_rate",
  and its one parameter is the window length: so `window` is that parameter, and nothing else in
  this file says what the window is. "The magnitude" is `Term.abs` of that signed value — the
  contract reads the magnitude, so a reversal to either hand is one, and neither sign is preferred.
  "Is at least" is `.ge`: the bound is inclusive. The primitive is already unknown where the window
  reaches past the start of the trace, is sampled too sparsely, or a yaw rate is missing, and a
  comparison over an unknown value is unknown, so the contract's three unknown cases need nothing
  of their own. The turn is recognized at every observation whose window behind carries the change,
  not only at the first: the contract says the caller that needs the act reads the observation at
  which the concept rises, so `rises` is the caller's and not written here.

  Nothing else of the contract reaches the body: the place ("upon a highway"), the lawfulness and
  the hand of the turn are residues or exclusions, and the reversal of the direction of motion
  without turning (a vehicle backing) is excluded by reading a heading change and nothing else.

  No magnitude below is this file's own: parameters are formals the caller fills.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.motion.direction_reversal

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aU : Arg := .var "u"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
def pHeadingChangeMin : Term := .param "heading_change_min"
def pWindow : Term := .param "window"

/-- The signed heading change of `u` over the window behind of length `window`, in degrees,
    left positive: `prim.heading_change`, whose one parameter is the window's length. -/
def headingChange : Term := .quantity "prim_heading_change" [aU] [pWindow]

/-- The magnitude of the heading change accumulated over the window behind is at least
    `heading_change_min`. -/
def body : Formula := .cmp (.abs headingChange) .ge pHeadingChangeMin

def concept : Concept :=
  { id := "drv.motion.direction_reversal"
    contract := "At the observation the road user has turned so as to proceed in the direction opposite the one it was proceeding in: the magnitude of the heading change it has accumulated over the window behind of length window is at least heading_change_min, a bound near a half turn. The corpus definition this contract quotes speaks of \"the turning of a vehicle upon a highway so as to proceed in the opposite direction, whether accomplished by one continuous movement or not\", so the accumulation runs over a window long enough to cover a reversal made in several movements, and the window length is the caller's parameter; the turn is recognized once the change has been carried out, and a caller that needs the act reads the observation at which the concept rises. Where the window reaches past the start of the trace, is sampled too sparsely, or a yaw rate is missing, it is unknown. Not a stand-in for: a turn to the left or the right short of a reversal, a reversal of the direction of motion without turning (a vehicle backing), the place the turn is made at, the lawfulness of the manoeuvre, or the hand to which the turn is made -- the magnitude is read, so a reversal either way is one."
    definition := some "DEF-NRS-484B-077"
    args := [("u", .track)]
    params := [⟨"heading_change_min", .degree⟩, ⟨"window", .second⟩]
    body := .formula body
    residues := ["the place the definition names is the caller's: this concept states the manoeuvre, and a rule that needs it to have been made upon a highway reads the structure region itself with its own relations.", "a reversal carried out in movements spread over more than the window the caller sets is not recognized; the contract names the window as the parameter that bounds this, and a caller needing a longer reversal sets a longer window."]  -- the record's, verbatim; not yours to change
    narrowings := []  -- one { span := "<words of the contract>", why := "<why>", kind := "reading" } per reading you chose that the contract leaves open, explained in the header
    supersedes := none }

end TrafficSpec.Concepts.motion.direction_reversal
