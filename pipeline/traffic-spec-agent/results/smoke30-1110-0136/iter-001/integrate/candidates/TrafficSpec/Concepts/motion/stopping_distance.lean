/-
  drv.motion.stopping_distance — The distance a road user would travel from the observation to a halt if it kept its current speed for a reaction time and then slowed at a constant deceleration: its speed at the observation (kin.speed) times `reaction_time`, plus the square of that speed divided by twice `decel`, in metres along its path. It is a quantity of the road user's own motion at the one observation, whoever or whatever controls it, and is zero for a road user standing still. Not denoted: the distance an actual later halt takes; the grade or the surface, which the caller states through the deceleration it passes.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    its speed at the observation (kin.speed): atoms ['kin.speed'], concepts []

  Literals the contract states (declared; written through a `Units` constructor):
    2 count — The kinematic factor of constant deceleration: the distance to halt from a speed is the square of the speed over twice the deceleration.

  No magnitude below is this file's own: parameters are formals the caller fills.

  The session's writing:
    "its speed at the observation (kin.speed) times `reaction_time`, plus the square of that speed
    divided by twice `decel`" is `kin_speed x * reaction_time + (kin_speed x * kin_speed x) /
    (2 * decel)`. The divisor reads no measured atom: it is the declared literal 2 times the formal
    `decel`, which the record states is strictly positive. A road user standing still (speed 0)
    gives 0, as the contract states. The value is unknown where kin.speed is unobserved. No choice
    was left open: no narrowing.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.motion.stopping_distance

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aX : Arg := .var "x"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
def pReactionTime : Term := .param "reaction_time"
def pDecel : Term := .param "decel"

/-- "its speed at the observation (kin.speed)". -/
def vX : Term := .measure "kin_speed" [aX]

/-- The declared literal 2 (count): the factor of "twice `decel`". -/
def two : Term := .lit (Units.ratio 2 1) .count

/-- "its speed ... times `reaction_time`, plus the square of that speed divided by twice `decel`". -/
def body : Term :=
  .add (.mul vX pReactionTime) (.div (.mul vX vX) (.mul two pDecel))

def concept : Concept :=
  { id := "drv.motion.stopping_distance"
    contract := "The distance a road user would travel from the observation to a halt if it kept its current speed for a reaction time and then slowed at a constant deceleration: its speed at the observation (kin.speed) times `reaction_time`, plus the square of that speed divided by twice `decel`, in metres along its path. It is a quantity of the road user's own motion at the one observation, whoever or whatever controls it, and is zero for a road user standing still. Not denoted: the distance an actual later halt takes; the grade or the surface, which the caller states through the deceleration it passes."
    definition := none
    args := [("x", .track)]
    params := [⟨"reaction_time", .second⟩, ⟨"decel", .metrePerSecondSq⟩]
    body := .quantity body
    residues := []  -- the record's, verbatim; not yours to change
    narrowings := []  -- one { span := "<words of the contract>", why := "<why>", kind := "reading" } per reading you chose that the contract leaves open, explained in the header
    supersedes := none }

end TrafficSpec.Concepts.motion.stopping_distance
