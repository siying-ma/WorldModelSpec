/-
  drv.motion.complete_cessation — True of a road user at an observation when its movement has entirely stopped within the observer's tolerance: the magnitude of its ground velocity stays at or below the speed tolerance throughout a window of at least the dwell, the window ending at the observation. That magnitude is the one quantity the concept bounds, and the only quantity that can fail; no other reading of the motion is taken. The definition it renders says "complete cessation from movement"; because a sampled speed never reads exactly zero and a single zero sample is indistinguishable from a sampling artefact, the absolute is observed only within a tolerance (m/s) and over a window (s) the caller sets, and those are the concept's parameters, never figures of its own. Frame: the ground — the magnitude of the road user's velocity over the ground, as kin.speed carries it. Unknown where the window behind the observation is truncated or a speed in it is unobserved. Not a stand-in for: the place of the halt, which is the caller's (this concept says nothing about where the road user is); a brake lamp or any other actuation, which is sig.brake_lamp; a vehicle standing or parked, which is a cessation of indefinite length and a different notion; or a yielding of precedence.

  The contract is the definition `DEF-NRS-484A-255`, verbatim.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    complete cessation from movement: atoms ['kin.speed'], concepts []
    throughout a window of at least the dwell, the window ending at the observation: atoms ['kin.time'], concepts []

  How the elements are written.

    "complete cessation from movement" → `.cmp (.measure "kin_speed" [u]) .le (.param "speed_tolerance")`.
    kin.speed is the magnitude of the ground velocity in m/s, so the whole span is one comparison:
    the one quantity the contract bounds against the one tolerance it names. "at or below" is `.le`,
    the contract's own words; the comparison is the body's only leaf, so it is also the only thing
    that can fail, and the only thing that can be unobserved — which is the contract's unknown.

    "throughout a window of at least the dwell, the window ending at the observation" →
    `.holdsFor .time (.param "dwell") "u" …`. `holdsFor` is "φ at every observation in the window of
    length d behind this one", and `.time` makes the window a length of trace time, which is what
    kin.time orders and measures (`Formula.measureAtom .time = kin_time`: the window reads the clock
    and nothing else). The window subject is the formal `u`; a time window does not use it, but it is
    the only track this concept speaks about. Core's `holdsFor` is unknown (windowTruncated) where the
    window reaches past the start of the trace, which is the contract's second unknown.

  CONSEQUENCE (a choice the contract did not dictate; appended to `residues` below). The window is
  written as the window of EXACTLY the dwell behind the observation. For the bound itself that is
  the contract's "at least the dwell": a stillness longer than the dwell contains the last `dwell`
  seconds, so it satisfies the same condition, and the concept says nothing about how much longer it
  ran. But `holdsFor` is defined on the observed instants only, so it also reports unknown where the
  observations inside the window are more than half the dwell apart — a sampling gap the contract
  does not speak of, and which the caller must read as "not decided", never as movement.

  No magnitude below is this file's own: parameters are formals the caller fills.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.motion.complete_cessation

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
private def aU : Arg := .var "u"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
private def pSpeedTolerance : Term := .param "speed_tolerance"
private def pDwell : Term := .param "dwell"

/-- The magnitude of `u`'s ground velocity stays at or below the speed tolerance at every
    observation in the window of the dwell behind this one, the window ending here. -/
private def body : Formula :=
  .holdsFor .time pDwell "u"
    (.cmp (.measure "kin_speed" [aU]) .le pSpeedTolerance)

def concept : Concept :=
  { id := "drv.motion.complete_cessation"
    contract := "True of a road user at an observation when its movement has entirely stopped within the observer's tolerance: the magnitude of its ground velocity stays at or below the speed tolerance throughout a window of at least the dwell, the window ending at the observation. That magnitude is the one quantity the concept bounds, and the only quantity that can fail; no other reading of the motion is taken. The definition it renders says \"complete cessation from movement\"; because a sampled speed never reads exactly zero and a single zero sample is indistinguishable from a sampling artefact, the absolute is observed only within a tolerance (m/s) and over a window (s) the caller sets, and those are the concept's parameters, never figures of its own. Frame: the ground — the magnitude of the road user's velocity over the ground, as kin.speed carries it. Unknown where the window behind the observation is truncated or a speed in it is unobserved. Not a stand-in for: the place of the halt, which is the caller's (this concept says nothing about where the road user is); a brake lamp or any other actuation, which is sig.brake_lamp; a vehicle standing or parked, which is a cessation of indefinite length and a different notion; or a yielding of precedence."
    definition := some "DEF-NRS-484A-255"
    args := [("u", .track)]
    params := [⟨"speed_tolerance", .metrePerSecond⟩, ⟨"dwell", .second⟩]
    body := .formula body
    residues := ["the definition's qualifier tells which statutory uses this sense of the word serves — it distinguishes this definition from DEF-NRS-484A-260's 'when prohibited' sense — and states no condition on the scene, so the contract carries the state of motion alone and the caller decides which sense its clause needs.",
                 "the window is written as the window of exactly the dwell behind the observation, which is the contract's 'at least the dwell' for the bound itself (a longer stillness contains the last dwell seconds) but says nothing about how much longer the stillness ran; and because the window is defined on the observed instants only, the concept also reports unknown where the observations inside it are more than half the dwell apart — a sampling gap the contract does not speak of, to be read as not decided, never as movement."]  -- the record's, verbatim; append one entry per CONSEQUENCE in the header
    supersedes := none }

end TrafficSpec.Concepts.motion.complete_cessation
