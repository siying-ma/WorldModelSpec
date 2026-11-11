/-
  drv.motion.stopping_distance — The distance road user x would cover from the observation to a standstill if it kept its present speed for reaction_time and then slowed at the constant deceleration deceleration: its speed (kin.speed, m/s) times reaction_time, plus the square of its speed divided by twice deceleration; in metres, zero for a body at a standstill. Not denoted: the distance x actually covers before a later halt, the deceleration the surface, the grade or the vehicle allows (the caller passes deceleration), whether anything lies within the distance, or whether x is required to stop.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    its speed (kin.speed, m/s): atoms ['kin.speed'], concepts []

  Literals the contract states (declared; written through a `Units` constructor):
    2 ratio — the factor of uniformly decelerated motion: a body slowing at constant deceleration from a speed covers the square of the speed divided by twice the deceleration

  Written as: v·reaction_time + (v·v) / (2·deceleration), v the measure `kin_speed` of x. The
  divisor reads only the formal parameter deceleration and the declared literal 2, never a
  measured atom; deceleration is strictly positive by the formal's meaning. An absent speed leaves
  the value unknown. No choice was left open.

  No magnitude below is this file's own: parameters are formals the caller fills.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.motion.stopping_distance

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aX : Arg := .var "x"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
def pReactionTime : Term := .param "reaction_time"
def pDeceleration : Term := .param "deceleration"

/-- x's speed (kin.speed, m/s); unknown where the source does not observe it. -/
def speed : Term := .measure "kin_speed" [aX]

/-- The declared factor 2 of uniformly decelerated motion. -/
def two : Term := .lit (Units.ratio 2 1) .ratio

/-- Speed times reaction_time, plus the squared speed over twice deceleration; the divisor reads
    parameters only, so the value is decided wherever the speed is observed (and deceleration is
    strictly positive, as the caller's formal states). Zero for a body at a standstill. -/
def body : Term :=
  .add (.mul speed pReactionTime) (.div (.mul speed speed) (.mul two pDeceleration))

def concept : Concept :=
  { id := "drv.motion.stopping_distance"
    contract := "The distance road user x would cover from the observation to a standstill if it kept its present speed for reaction_time and then slowed at the constant deceleration deceleration: its speed (kin.speed, m/s) times reaction_time, plus the square of its speed divided by twice deceleration; in metres, zero for a body at a standstill. Not denoted: the distance x actually covers before a later halt, the deceleration the surface, the grade or the vehicle allows (the caller passes deceleration), whether anything lies within the distance, or whether x is required to stop."
    definition := none
    args := [("x", .track)]
    params := [⟨"reaction_time", .second⟩, ⟨"deceleration", .metrePerSecondSq⟩]
    body := .quantity body
    residues := []  -- the record's, verbatim; not yours to change
    narrowings := []  -- one { span := "<words of the contract>", why := "<why>", kind := "reading" } per reading you chose that the contract leaves open, explained in the header
    supersedes := none }

end TrafficSpec.Concepts.motion.stopping_distance
