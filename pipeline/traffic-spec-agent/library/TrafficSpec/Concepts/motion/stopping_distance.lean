/-
  drv.motion.stopping_distance — The ground distance, in metres, a road user would cover from its position at the observation before coming to a halt, when it goes on at its speed at the observation for the reaction time and then brakes at a constant deceleration until it stands: the distance covered during the reaction time, plus drv.motion.braking_distance of the same road user at that deceleration. The reaction time and the deceleration are the caller's parameters: how long a road user takes to begin braking, and what the surface and the brakes will sustain, are not observed, and the caller sets both from the convention by which it bounds its standard. Not a stand-in for: the distance to anything in the scene - the road clear ahead, the sight distance of a place (st.sight_distance), a gap between bodies (rel.surface_gap) - each of which is what the caller compares this distance with; the distance the road user in fact covers before halting, which is read from kin.path_length; whether it is braking at all, which is kin.service_brake or sig.brake_lamp; or any duty to be able to stop, which is the calling rule's and not this concept's.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    it goes on at its speed at the observation for the reaction time: atoms ['kin.speed'], concepts []
      → `Term.mul (Term.measure "kin_speed" [user]) (Term.param "reaction_time")`: the reaction leg
        is the ground distance covered while the road user goes on unchanged, and "goes on at its
        speed at the observation" fixes the speed of that leg at the one reading taken at the
        instant of evaluation — so the leg is that speed (m/s) times the reaction time (s), in
        metres. `kin.speed` is "magnitude of velocity", the magnitude the contract's "its speed"
        names; `kin.velocity` is not read, the leg being a length along the path and carrying no
        direction, and `kin.path_length` is not read, that being what the user has already covered
        and what the contract expressly disclaims.
    plus drv.motion.braking_distance of the same road user at that deceleration: atoms [], concepts ['drv.motion.braking_distance']
      → `Term.quantity "drv_motion_braking_distance" [user] [Term.param "deceleration"]`: the
        braking leg is called, not rebuilt. The relation between a speed, a constant deceleration
        and the distance to standing is stated once in that concept and only called here, on the
        same formal road user and with this concept's `deceleration` parameter passed through
        unchanged — "of the same road user at that deceleration". The atoms the call reads are its
        own and are not claimed again here.

  The sum. "the distance covered during the reaction time, plus …" is `Term.add` of the two legs,
  in that order; both are metres, so the quantity is metres. Where `kin.speed` is unobserved both
  legs are unknown and so is the sum — the contract's own reading, since neither leg can be
  computed without the speed at the observation.

  No division appears: the only quotient the contract asks for lives inside
  drv.motion.braking_distance, and its divisor is a parameter, never a measurement.

  Nothing here is observed beyond the speed: the reaction time and the deceleration are formal
  parameters, because how long a road user takes to begin braking and what the surface and the
  brakes will sustain are not read from the trace, and the caller sets both from the convention by
  which it bounds its standard.

  No reading was chosen that the contract leaves open: the contract names the two legs, their
  order, and the magnitudes each rests on, so `narrowings` is empty.

  No magnitude below is this file's own: parameters are formals the caller fills.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.motion.stopping_distance

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
private def aUser : Arg := .var "user"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
private def pReactionTime : Term := .param "reaction_time"
private def pDeceleration : Term := .param "deceleration"

/-- The ground distance to a halt, in metres: the reaction leg — the road user's speed at the
    observation carried on for the caller's reaction time — plus the braking leg, which is
    drv.motion.braking_distance of the same road user at the caller's deceleration. -/
private def body : Term :=
  .add
    (.mul (.measure "kin_speed" [aUser]) pReactionTime)
    (.quantity "drv_motion_braking_distance" [aUser] [pDeceleration])

def concept : Concept :=
  { id := "drv.motion.stopping_distance"
    contract := "The ground distance, in metres, a road user would cover from its position at the observation before coming to a halt, when it goes on at its speed at the observation for the reaction time and then brakes at a constant deceleration until it stands: the distance covered during the reaction time, plus drv.motion.braking_distance of the same road user at that deceleration. The reaction time and the deceleration are the caller's parameters: how long a road user takes to begin braking, and what the surface and the brakes will sustain, are not observed, and the caller sets both from the convention by which it bounds its standard. Not a stand-in for: the distance to anything in the scene - the road clear ahead, the sight distance of a place (st.sight_distance), a gap between bodies (rel.surface_gap) - each of which is what the caller compares this distance with; the distance the road user in fact covers before halting, which is read from kin.path_length; whether it is braking at all, which is kin.service_brake or sig.brake_lamp; or any duty to be able to stop, which is the calling rule's and not this concept's."
    definition := none
    args := [("user", .track)]
    params := [⟨"reaction_time", .second⟩, ⟨"deceleration", .metrePerSecondSq⟩]
    body := .quantity body
    residues := []  -- the record's, verbatim; not yours to change
    narrowings := []  -- one { span := "<words of the contract>", why := "<why>", kind := "reading" } per reading you chose that the contract leaves open, explained in the header
    supersedes := none }

end TrafficSpec.Concepts.motion.stopping_distance
