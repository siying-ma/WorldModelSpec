/-
  drv.motion.stopping_distance — The distance the road user travels before it comes to rest, counted from the observation, if it holds the present speed for `reaction_time` and then decelerates steadily at `deceleration` until it stops: the distance covered at the present speed during `reaction_time`, plus the present speed squared over twice `deceleration`. Metres along the road user's path; never negative; zero where the road user is at rest, and growing with the present speed. It is a distance the road user's own motion implies, and the deceleration is the one the caller states, not one read from the scene. Not a stand-in for: a distance to any place or to any other road user in the scene — the concept looks at nothing outside the road user's motion; a clearance or a gap; or a judgement that the road user ought to be able to stop within what is available, which is a comparison the rule that calls the concept makes and bounds. Unknown where the speed is unobserved.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    the present speed: atoms ['kin.speed'], concepts []

  Literals the contract states (declared; written through a `Units` constructor):
    2 count — the factor of two in the distance a body covers while decelerating steadily to rest, the speed squared over twice the deceleration. A constant of the kinematics, not a figure any law states.

  No magnitude below is this file's own: parameters are formals the caller fills.

  How the words are written.
    "the present speed" → `Term.measure "kin_speed" [u]`, the magnitude of the road user's velocity
      at the observation, in m/s. It is the only thing the body reads of the scene: nothing about
      any place, any other road user, or any clearance enters it, as the contract's exclusions say.
    "the distance covered at the present speed during `reaction_time`" → `speed · reaction_time`.
    "the present speed squared over twice `deceleration`" → `speed · speed / (2 · deceleration)`,
      the declared literal `2` written `Units.ratio 2 1` and tagged `.count`.
    The two are summed; metres. The divisor reads no measurement — `deceleration` is the formal
      parameter the caller states, as the contract requires ("the deceleration is the one the
      caller states, not one read from the scene"), so the division cannot be by a measured zero.
    "never negative; zero where the road user is at rest, and growing with the present speed" is a
      property of this expression for a non-negative speed and a positive `deceleration`, not a
      separate clause: `kin.speed` is a magnitude, so it is never negative, and both summands
      vanish at rest and grow with the speed. Nothing is clamped.
    "Unknown where the speed is unobserved" needs no writing: an atom whose field is `none` is
      unknown, and the unknown propagates through the product, the quotient and the sum.

  Narrowing (declared below).
    "decelerates steadily at `deceleration`" — the contract gives the parameter as a deceleration
      (its meaning: "the steady deceleration ... from the present speed to rest") without fixing a
      sign convention. The body reads it as a positive magnitude and divides by it as written,
      rather than by its absolute value or by its negation; a caller that passed a signed
      longitudinal acceleration (negative while braking) would get a negative distance.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.motion.stopping_distance

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aU : Arg := .var "u"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
def pReactionTime : Term := .param "reaction_time"
def pDeceleration : Term := .param "deceleration"

/-- "the present speed" — the magnitude of the road user's velocity at the observation (m/s). -/
def speed : Term := .measure "kin_speed" [aU]

/-- The declared literal: the factor of two in the braking distance. -/
def two : Term := .lit (Units.ratio 2 1) .count

/-- "the distance covered at the present speed during `reaction_time`". -/
def reactionDistance : Term := .mul speed pReactionTime

/-- "the present speed squared over twice `deceleration`"; the divisor is the caller's parameter,
    never a measurement. -/
def brakingDistance : Term := .div (.mul speed speed) (.mul two pDeceleration)

/-- The distance travelled before coming to rest: the reaction distance plus the braking distance. -/
def body : Term := .add reactionDistance brakingDistance

def concept : Concept :=
  { id := "drv.motion.stopping_distance"
    contract := "The distance the road user travels before it comes to rest, counted from the observation, if it holds the present speed for `reaction_time` and then decelerates steadily at `deceleration` until it stops: the distance covered at the present speed during `reaction_time`, plus the present speed squared over twice `deceleration`. Metres along the road user's path; never negative; zero where the road user is at rest, and growing with the present speed. It is a distance the road user's own motion implies, and the deceleration is the one the caller states, not one read from the scene. Not a stand-in for: a distance to any place or to any other road user in the scene — the concept looks at nothing outside the road user's motion; a clearance or a gap; or a judgement that the road user ought to be able to stop within what is available, which is a comparison the rule that calls the concept makes and bounds. Unknown where the speed is unobserved."
    definition := none
    args := [("u", .track)]
    params := [⟨"reaction_time", .second⟩, ⟨"deceleration", .metrePerSecondSq⟩]
    body := .quantity body
    residues := []  -- the record's, verbatim; not yours to change
    narrowings := [{ span := "decelerates steadily at `deceleration`"
                     why := "The contract fixes no sign convention for the parameter. The body reads `deceleration` as a positive magnitude and divides the squared speed by twice it as written, not by its absolute value or its negation; a caller that passes a signed longitudinal acceleration (negative while braking) gets a negative distance."
                     kind := "reading" }]
    supersedes := none }

end TrafficSpec.Concepts.motion.stopping_distance
