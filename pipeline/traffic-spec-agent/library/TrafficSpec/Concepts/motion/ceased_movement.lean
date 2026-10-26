/-
  drv.motion.ceased_movement — The road user is not moving at the observation: the magnitude of its velocity is at or below the speed tolerance the caller sets, which is what "complete cessation from movement" can be observed as on sampled measurements. The tolerance is the observer's and is the contract's own magnitude: a sampled speed is never exactly zero, so the caller sets the magnitude below which a measured speed counts as no movement, and it is no measure of how long the road user must stand still, which is the business of the law that calls the concept. The concept is a state of motion at an instant, read from the road user's own speed alone: it says nothing about how long the road user has stood, nothing about where on the road it stands or what regions its footprint overlaps, nothing about why it stands there, and nothing about the lawfulness of standing. It is not the brake lamp and not the selected gear - a vehicle stands with a forward gear engaged and rolls backwards with reverse selected - not the engine's running, not a halt required by a device, and not a halting prohibited at a place.

  The contract is the definition `DEF-NRS-484A-255`, verbatim.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    the magnitude of its velocity is at or below the speed tolerance the caller sets: atoms ['kin.speed'], concepts []

  How each element is written:

    "the magnitude of its velocity is at or below the speed tolerance the caller sets" — one
    comparison at the observation, and the whole of the body: `kin_speed u ≤ halt_speed_tolerance`,
    written `.cmp (.measure "kin_speed" [aU]) .le pHaltSpeedTolerance`. The left side is the
    road user's own measured speed, read of the formal `u` alone; the atom is the magnitude of
    velocity in m/s, so no `.abs` and no composition of components is written over it (see the
    narrowing on this span). The right side is the formal parameter, the unit of which the record
    gives as m/s: no magnitude of this file's own stands anywhere in the body. "At or below" is
    the inclusive comparison `.le`, so a measured speed equal to the tolerance counts as no
    movement, which is what the words say; `.lt` would exclude the boundary the contract includes.

    Nothing else is written, which is the whole of the contract's exclusions. The body carries no
    operator over time — no `holdsFor`, no `sinceRise`, no `since`, no `count` — because the
    concept is a state of motion at an instant and the tolerance "is no measure of how long the
    road user must stand still"; a window behind would make the concept say how long the body has
    stood, and would make it unknown at the start of a trace, which this concept is not. No
    region is quantified over and no `rel_occupies` or geometry is read, so nothing of where on
    the road the body stands or what its footprint overlaps enters. No `sig_brake_lamp`, no
    `kin_gear`, no `kin_engine_running`, no `kin_throttle`, no `kin_service_brake`, no device and
    no other road user is read, which are the stand-ins the contract names and refuses; and
    nothing of the lawfulness of standing is read, which belongs to the law that calls the
    concept.

  The unknowns are the atom's: where the source does not observe the road user's speed,
  `kin_speed` is unknown, the comparison is unknown, and so is the concept — never false.

  No magnitude below is this file's own: parameters are formals the caller fills.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.motion.ceased_movement

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aU : Arg := .var "u"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
def pHaltSpeedTolerance : Term := .param "halt_speed_tolerance"

/-- The road user's own measured speed: the magnitude of its velocity, in m/s. -/
def speedOf : Term := .measure "kin_speed" [aU]

/-- The road user is not moving at the observation: its measured speed is at or below the
    tolerance the caller sets. -/
def body : Formula := .cmp speedOf .le pHaltSpeedTolerance

def concept : Concept :=
  { id := "drv.motion.ceased_movement"
    contract := "The road user is not moving at the observation: the magnitude of its velocity is at or below the speed tolerance the caller sets, which is what \"complete cessation from movement\" can be observed as on sampled measurements. The tolerance is the observer's and is the contract's own magnitude: a sampled speed is never exactly zero, so the caller sets the magnitude below which a measured speed counts as no movement, and it is no measure of how long the road user must stand still, which is the business of the law that calls the concept. The concept is a state of motion at an instant, read from the road user's own speed alone: it says nothing about how long the road user has stood, nothing about where on the road it stands or what regions its footprint overlaps, nothing about why it stands there, and nothing about the lawfulness of standing. It is not the brake lamp and not the selected gear - a vehicle stands with a forward gear engaged and rolls backwards with reverse selected - not the engine's running, not a halt required by a device, and not a halting prohibited at a place."
    definition := some "DEF-NRS-484A-255"
    args := [("u", .track)]
    params := [⟨"halt_speed_tolerance", .metrePerSecond⟩]
    body := .formula body
    residues := ["when required"]  -- the record's, verbatim; not yours to change
    narrowings :=
      [ { span := "the magnitude of its velocity is at or below the speed tolerance the caller sets"
          why := "The magnitude is read by the atom that denotes it, `kin_speed` of the formal `u`, and not composed from `kin.velocity`: the atom is the magnitude of velocity in m/s, the unit of the tolerance, so no `.abs` and no arithmetic over components is written over it. Two consequences are declared. First, a source that reports a speed and a velocity that disagree is read on the speed alone; the concept takes the speed as the magnitude it speaks of. Second, because `kin_speed` is a magnitude and not a signed rate along the heading, a body rolling backwards is read exactly as one rolling forwards at the same rate - which is what the contract asks for, since it refuses the selected gear as a stand-in for the direction of motion. 'At or below' is written as the inclusive comparison `.le`, so a measured speed exactly equal to the tolerance counts as no movement."
          kind := "reading" } ]
    supersedes := none }

end TrafficSpec.Concepts.motion.ceased_movement
