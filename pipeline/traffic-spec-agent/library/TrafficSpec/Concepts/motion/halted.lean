/-
  drv.motion.halted — The road user is not moving at the observation: the magnitude of its velocity is at or below the speed tolerance the caller sets, which is what "complete cessation from movement" can be observed as on sampled measurements. The tolerance is the observer's and is the contract's own magnitude: a sampled speed is never exactly zero, so the caller sets the magnitude below which a measured speed counts as none. The concept is a state at an instant: it says nothing about how long the road user has been still, nothing about why it is still, and nothing about its controls - a halt is not the selected gear, not the brake input and not the brake lamp.

  The contract is the definition `DEF-NRS-484A-255`, verbatim.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    the magnitude of its velocity is at or below the speed tolerance: atoms ['kin.speed'], concepts []

  No magnitude below is this file's own: parameters are formals the caller fills.

  How the element is written:
    "the magnitude of its velocity is at or below the speed tolerance" →
      `kin_speed u ≤ halt_speed_tolerance`.
    `kin.speed` is the magnitude of the velocity in m/s, so the magnitude is read directly and not
    recomposed from the components of `kin.velocity`; "at or below" is `.le`, the bound included, as
    the words say. The body is one comparison at the instant: no window, no edge, no look-back, so
    it says nothing about how long the user has been still; it reads no gear, no brake input and no
    brake lamp, as the contract forbids. Where the source does not observe the speed the comparison
    is unknown, never false.

  Nothing in the contract is left open by this writing: the atom, the operator and the bound are all
  dictated by the words, so `narrowings` is empty.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.motion.halted

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aU : Arg := .var "u"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
def pHaltSpeedTolerance : Term := .param "halt_speed_tolerance"

/-- The measured speed of the road user: the magnitude of its velocity, in m/s. -/
def speedOfU : Term := .measure "kin_speed" [aU]

/-- The road user is not moving at the observation: its speed is at or below the caller's
    tolerance. -/
def body : Formula := .cmp speedOfU .le pHaltSpeedTolerance

def concept : Concept :=
  { id := "drv.motion.halted"
    contract := "The road user is not moving at the observation: the magnitude of its velocity is at or below the speed tolerance the caller sets, which is what \"complete cessation from movement\" can be observed as on sampled measurements. The tolerance is the observer's and is the contract's own magnitude: a sampled speed is never exactly zero, so the caller sets the magnitude below which a measured speed counts as none. The concept is a state at an instant: it says nothing about how long the road user has been still, nothing about why it is still, and nothing about its controls - a halt is not the selected gear, not the brake input and not the brake lamp."
    definition := some "DEF-NRS-484A-255"
    args := [("u", .track)]
    params := [⟨"halt_speed_tolerance", .metrePerSecond⟩]
    body := .formula body
    residues := ["the definition's scope clause: it says which uses of the word this definition governs, not what the state is. The caller selects this record where the stop is one the law requires; DEF-NRS-484A-260 is the record for a prohibited stopping and is a different concept."]  -- the record's, verbatim; not yours to change
    narrowings := []  -- one { span := "<words of the contract>", why := "<why>", kind := "reading" } per reading you chose that the contract leaves open, explained in the header
    supersedes := none }

end TrafficSpec.Concepts.motion.halted
