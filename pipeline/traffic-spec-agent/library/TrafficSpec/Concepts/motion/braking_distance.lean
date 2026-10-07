/-
  drv.motion.braking_distance — The ground distance, in metres, over which a road user's speed would fall from its speed at the observation to standing, braking at a constant deceleration: the square of that speed over twice the deceleration. The deceleration is the caller's parameter, since what a surface and a set of brakes will sustain is not observed and is a magnitude the caller's convention sets. Not a stand-in for: the distance a road user needs to come to a halt once the time before braking begins is allowed for, which is drv.motion.stopping_distance and is longer; the distance to anything in the scene - a gap, a sight distance, a region - which is what the caller compares this distance with; the deceleration the road user is in fact undergoing (kin.accel_longitudinal) or the brake input it is in fact applying (kin.service_brake), neither of which is read here, the distance being what would be covered if it braked at the caller's rate and not a reading of what it does; and the distance the road user has in fact travelled, which is kin.path_length.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    its speed at the observation: atoms ['kin.speed'], concepts []

  Literals the contract states (declared; written through a `Units` constructor):
    2 count — the constant of the kinematic relation between a speed, a constant deceleration and the distance over which that speed falls to zero; it is a fact of the computation, not a magnitude anyone sets

  How the words are written:
  - "its speed at the observation" is `kin_speed user` at the instant, the magnitude of velocity in
    m/s; nothing else about the user is read. The deceleration the user is in fact undergoing
    (`kin_accel_longitudinal`) and the brake it is in fact applying (`kin_service_brake`) are not
    read: the contract says the rate is the caller's.
  - "the square of that speed over twice the deceleration" is `(v · v) / (2 · deceleration)`: the
    product of the speed with itself over the declared literal 2 times the formal parameter. The
    divisor reads no measurement — it is the caller's constant — so the quotient is unknown only
    where the speed is, never through a measured zero. Where the speed is unobserved the quotient
    is unknown, which is the `blind` witness.
  - The contract dictates the computation outright, so this file records no narrowing: nothing was
    left open for the session to choose. The deceleration's sign convention is the one the formal
    parameter's unit already fixes — a positive magnitude of deceleration, as the contract's
    "braking at a constant deceleration" and the division by it require.

  No magnitude below is this file's own: parameters are formals the caller fills.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.motion.braking_distance

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
private def aUser : Arg := .var "user"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
private def pDeceleration : Term := .param "deceleration"

/-- "its speed at the observation": the magnitude of the road user's velocity, m/s. -/
private def speed : Term := .measure "kin_speed" [aUser]

/-- The record's declared literal: the 2 of `v² = 2·a·d`, dimensionless. -/
private def twice : Term := .lit (Units.ratio 2 1) .count

/-- The square of the speed over twice the deceleration, in metres. -/
private def body : Term := .div (.mul speed speed) (.mul twice pDeceleration)

def concept : Concept :=
  { id := "drv.motion.braking_distance"
    contract := "The ground distance, in metres, over which a road user's speed would fall from its speed at the observation to standing, braking at a constant deceleration: the square of that speed over twice the deceleration. The deceleration is the caller's parameter, since what a surface and a set of brakes will sustain is not observed and is a magnitude the caller's convention sets. Not a stand-in for: the distance a road user needs to come to a halt once the time before braking begins is allowed for, which is drv.motion.stopping_distance and is longer; the distance to anything in the scene - a gap, a sight distance, a region - which is what the caller compares this distance with; the deceleration the road user is in fact undergoing (kin.accel_longitudinal) or the brake input it is in fact applying (kin.service_brake), neither of which is read here, the distance being what would be covered if it braked at the caller's rate and not a reading of what it does; and the distance the road user has in fact travelled, which is kin.path_length."
    definition := none
    args := [("user", .track)]
    params := [⟨"deceleration", .metrePerSecondSq⟩]
    body := .quantity body
    residues := []  -- the record's, verbatim; not yours to change
    narrowings := []  -- one { span := "<words of the contract>", why := "<why>", kind := "reading" } per reading you chose that the contract leaves open, explained in the header
    supersedes := none }

end TrafficSpec.Concepts.motion.braking_distance
