/-
  drv.motion.heading_reversal — The road user's direction of travel reverses: over the window behind the observation the direction in which its body points turns through a half turn, so that at the observation it points back the way it came. The concept holds at the observation at which the accumulated turning first reaches that half turn and at every later observation of the window at which it is still within the band; it reads the road user's own turning however the road user brings it about, in one sweep or in several movements with intervening reversals, since what is accumulated is the signed rate of change of the heading throughout the window. It is recognized by the signed heading change of the road user over the window behind the observation, whose magnitude lies between a half turn less `heading_tolerance` and a half turn more `heading_tolerance`: a band and not a one-sided bound, since a road user that turns through a full circle comes back to the heading it had and has reversed nothing. Unknown where the window reaches past the start of the trace, where the observations are too sparse for the turning to be accumulated, or where the rate of change of heading is unobserved. Not a stand-in for: the direction of motion along the body's axis — a road user that backs travels the opposite way without turning, and one that turns while backing reverses its heading all the same; a single turn at an intersection or a change of lane, whose heading change falls short of the band; or the course of the way the road user travels on — the concept reads the body's heading alone, so a road user that follows a way which itself turns through a half turn within the window satisfies it.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    the signed heading change of the road user over the window behind the observation: atoms ['prim.heading_change'], concepts []

  How the element is written: `Term.quantity "prim_heading_change" [u] [window]` — the primitive
  integrates `kin.yaw_rate` over the window of length `window` behind the observation and is
  unknown exactly where the contract says the concept is unknown (the window reaches past the
  start of the trace, the observations are too sparse, a yaw rate is missing). Because the
  accumulated quantity is the SIGNED change, a turn carried through in several movements with
  intervening reversals accumulates to the same half turn, and a full circle accumulates to a
  whole turn and not to a half one — both as the contract reads them. Nothing else is read: no
  position, no course of a way, no direction of motion along the body's axis.

  The band: the magnitude of that change (`Term.abs`) is at least a half turn less
  `heading_tolerance` and at most a half turn more. Two comparisons, conjoined, because the
  contract states a band and not a one-sided bound. The concept is a statement about the
  observation it is read at, so the body is pointwise: it is true at the first observation whose
  window has accumulated into the band and at every later one still in it, which is what
  "holds at the observation at which the accumulated turning first reaches that half turn and at
  every later observation of the window at which it is still within the band" says.

  Readings chosen (declared as narrowings below):
    - the band is read CLOSED: a magnitude of exactly a half turn less (or more) the tolerance is
      within it. The words give the tolerance as the extent of the band, not as a margin the
      magnitude must beat, and a closed band is the reading under which the tolerance names the
      furthest admissible departure from a half turn.

  Literals the contract states (declared; written through a `Units` constructor):
    180 deg — a half turn: the heading change of a body that comes to point back the way it came. A constant of the geometry, not a figure any law states.

  No magnitude below is this file's own: parameters are formals the caller fills.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.motion.heading_reversal

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aU : Arg := .var "u"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
def pWindow : Term := .param "window"
def pHeadingTolerance : Term := .param "heading_tolerance"

/-- "the signed heading change of the road user over the window behind the observation":
    `prim.heading_change` of the road user over `window` (degrees, left positive). -/
def headingChange : Term := .quantity "prim_heading_change" [aU] [pWindow]

/-- "a half turn": the heading change of a body that comes to point back the way it came. -/
def halfTurn : Term := .lit (Units.degrees 180) .degree

/-- The magnitude of the accumulated signed heading change lies in the band a half turn less
    `heading_tolerance` … a half turn more `heading_tolerance`. -/
def body : Formula :=
  .and (.cmp (.abs headingChange) .ge (.sub halfTurn pHeadingTolerance))
       (.cmp (.abs headingChange) .le (.add halfTurn pHeadingTolerance))

def concept : Concept :=
  { id := "drv.motion.heading_reversal"
    contract := "The road user's direction of travel reverses: over the window behind the observation the direction in which its body points turns through a half turn, so that at the observation it points back the way it came. The concept holds at the observation at which the accumulated turning first reaches that half turn and at every later observation of the window at which it is still within the band; it reads the road user's own turning however the road user brings it about, in one sweep or in several movements with intervening reversals, since what is accumulated is the signed rate of change of the heading throughout the window. It is recognized by the signed heading change of the road user over the window behind the observation, whose magnitude lies between a half turn less `heading_tolerance` and a half turn more `heading_tolerance`: a band and not a one-sided bound, since a road user that turns through a full circle comes back to the heading it had and has reversed nothing. Unknown where the window reaches past the start of the trace, where the observations are too sparse for the turning to be accumulated, or where the rate of change of heading is unobserved. Not a stand-in for: the direction of motion along the body's axis — a road user that backs travels the opposite way without turning, and one that turns while backing reverses its heading all the same; a single turn at an intersection or a change of lane, whose heading change falls short of the band; or the course of the way the road user travels on — the concept reads the body's heading alone, so a road user that follows a way which itself turns through a half turn within the window satisfies it."
    definition := none
    args := [("u", .track)]
    params := [⟨"window", .second⟩, ⟨"heading_tolerance", .degree⟩]
    body := .formula body
    residues := []  -- the record's, verbatim; not yours to change
    narrowings :=
      [ { span := "whose magnitude lies between a half turn less `heading_tolerance` and a half turn more `heading_tolerance`"
        , why := "the band is written closed (`≥` and `≤`): a magnitude of exactly a half turn less, or exactly a half turn more, the tolerance is within it. The words state the tolerance as the extent of the band, not as a margin the magnitude must beat, and the contract leaves the endpoints open."
        , kind := "reading" } ]
    supersedes := none }

end TrafficSpec.Concepts.motion.heading_reversal
