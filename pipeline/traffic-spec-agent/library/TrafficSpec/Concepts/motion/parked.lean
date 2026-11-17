/-
  drv.motion.parked — Road user a is parked: "the standing of a vehicle, whether occupied or not", observed as a at rest at every observation of the window behind the observation, of length min_duration: at each of them a's speed (kin.speed, read through drv.motion.complete_halt) is at or below speed_tol. A halt shorter than min_duration, which may be the temporary halt the definition leaves out, is not denoted. It denotes a state at one observation: it says nothing of whether a rider is on a, of where a stands, or of why it stands. Not denoted: a road user whose speed was above speed_tol at some observation of that window. Where the window reaches before the start of the recording or a speed in it is unobserved, it is unknown.

  Based on the posted definition `DEF-NRS-484A-155`: the contract above is this record's reading
  of it, not its text.

  The posted text (the definition's words; the concept denotes its contract):
    “Park” or “parking” means the standing of a vehicle, whether occupied or not, otherwise than temporarily for the purpose of and while actually engaged in loading or unloading of merchandise or passengers.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    a at rest at every observation of the window behind the observation, of length min_duration: atoms [], concepts ['drv.motion.complete_halt']

  No magnitude below is this file's own: parameters are formals the caller fills.

  How the contract is written:
    - "a at rest": `.derived "drv_motion_complete_halt" [a] [speed_tol]` — a's speed (kin.speed)
      at or below speed_tol at the one observation, read through the accepted concept.
    - "at every observation of the window behind the observation, of length min_duration":
      `holdsFor .time min_duration a (…)` — a time window, as the contract states a length in
      seconds; a window reaching before the recording's start is unknown (windowTruncated), and an
      unobserved speed in it leaves it unknown, as the contract says.
  No narrowing: every choice above is the contract's own words.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.motion.parked

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aA : Arg := .var "a"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
def pSpeedTol : Term := .param "speed_tol"
def pMinDuration : Term := .param "min_duration"

/-- a at rest at one observation: drv.motion.complete_halt with the caller's speed tolerance. -/
def atRest : Formula := .derived "drv_motion_complete_halt" [aA] [pSpeedTol]

/-- Parked: at rest at every observation of the time window of length min_duration behind. -/
def body : Formula := .holdsFor .time pMinDuration "a" atRest

def concept : Concept :=
  { id := "drv.motion.parked"
    contract := "Road user a is parked: \"the standing of a vehicle, whether occupied or not\", observed as a at rest at every observation of the window behind the observation, of length min_duration: at each of them a's speed (kin.speed, read through drv.motion.complete_halt) is at or below speed_tol. A halt shorter than min_duration, which may be the temporary halt the definition leaves out, is not denoted. It denotes a state at one observation: it says nothing of whether a rider is on a, of where a stands, or of why it stands. Not denoted: a road user whose speed was above speed_tol at some observation of that window. Where the window reaches before the start of the recording or a speed in it is unobserved, it is unknown."
    definition := some "DEF-NRS-484A-155"
    args := [("a", .track)]
    params := [⟨"speed_tol", .metrePerSecond⟩, ⟨"min_duration", .second⟩]
    body := .formula body
    residues := ["a purpose is not observable; the definition's exclusion of a temporary halt is read only by the halt's duration (min_duration): a halt held longer than min_duration while loading is denoted, a halt shorter than it for any purpose is not"]  -- the record's, verbatim; not yours to change
    narrowings := []  -- one { span := "<words of the contract>", why := "<why>", kind := "reading" } per reading you chose that the contract leaves open, explained in the header
    supersedes := none }

end TrafficSpec.Concepts.motion.parked
