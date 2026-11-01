/-
  drv.motion.standstill — The road user is at a complete halt at this observation: the magnitude of its ground velocity is at or below speed_tolerance, the bound within which a sampled speed reading counts as no movement. The definition this renders requires, where a stop is required, "complete cessation from movement"; an absolute halt is observed over sampled measurements only within a bound the observer sets, and that bound is this parameter, so no figure appears in the contract. The concept denotes the state of the body itself and not an actuation or a control input: a lit brake lamp, a pressed service brake, a set parking brake, a gear selection and a stopped engine are none of them this concept, and a vehicle that rolls with its engine off is not at a standstill. It is a state at an observation, not a duration of halting: how long the halt has lasted is the caller's to state.

  The contract is the definition `DEF-NRS-484A-255`, verbatim.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    the magnitude of its ground velocity is at or below: atoms ['kin.speed'], concepts []
      written `kin_speed u ≤ speed_tolerance`. `kin.speed` is "magnitude of velocity", so the
      magnitude is the atom itself and no `abs` is taken; "at or below" is `.le`, the bound
      included. The comparison is at the observation being judged: no temporal operator, since
      the contract makes the halt a state and leaves its duration to the caller.

  Nothing the contract excludes is read: no lamp, pedal, parking brake, gear or engine state
  enters the body, which is what makes a vehicle rolling with its engine off not a standstill.

  No reading was chosen that the contract leaves open, so `narrowings` is empty: the one element
  dictates the atom, the direction of the comparison and the inclusion of the bound.

  No magnitude below is this file's own: parameters are formals the caller fills.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.motion.standstill

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aU : Arg := .var "u"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
def pSpeedTolerance : Term := .param "speed_tolerance"

/-- `the magnitude of its ground velocity is at or below` speed_tolerance: `kin.speed` is that
    magnitude in m/s, compared with `.le` to the formal parameter — "at or below" includes the
    bound. Nothing else is read: the actuations and control inputs the contract excludes
    (`sig.brake_lamp`, `kin.service_brake`, `kin.parking_brake`, `kin.gear`, `kin.engine_running`)
    appear nowhere, so a rolling vehicle with its engine off is not at a standstill here, and a
    halt is judged at this observation alone, with no lookback over how long it has lasted. -/
def body : Formula :=
  .cmp (.measure "kin_speed" [aU]) .le pSpeedTolerance

def concept : Concept :=
  { id := "drv.motion.standstill"
    contract := "The road user is at a complete halt at this observation: the magnitude of its ground velocity is at or below speed_tolerance, the bound within which a sampled speed reading counts as no movement. The definition this renders requires, where a stop is required, \"complete cessation from movement\"; an absolute halt is observed over sampled measurements only within a bound the observer sets, and that bound is this parameter, so no figure appears in the contract. The concept denotes the state of the body itself and not an actuation or a control input: a lit brake lamp, a pressed service brake, a set parking brake, a gear selection and a stopped engine are none of them this concept, and a vehicle that rolls with its engine off is not at a standstill. It is a state at an observation, not a duration of halting: how long the halt has lasted is the caller's to state."
    definition := some "DEF-NRS-484A-255"
    args := [("u", .track)]
    params := [⟨"speed_tolerance", .metrePerSecond⟩]
    body := .formula body
    residues := ["DEF-NRS-484A-255 confines its meaning to a stop 'when required'; which stops are required is a matter for the rules that call the concept, not for the physical state it denotes. The companion definition DEF-NRS-484A-260, the halt that is prohibited, is a different notion and would be a separate record."]  -- the record's, verbatim; not yours to change
    narrowings := []  -- one { span := "<words of the contract>", why := "<why>", kind := "reading" } per reading you chose that the contract leaves open, explained in the header
    supersedes := none }

end TrafficSpec.Concepts.motion.standstill
