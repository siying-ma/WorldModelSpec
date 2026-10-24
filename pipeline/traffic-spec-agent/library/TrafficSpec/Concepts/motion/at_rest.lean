/-
  drv.motion.at_rest — The road user is not moving at the observation: the magnitude of its velocity is at or below the speed tolerance the caller sets, which is what "complete cessation from movement" can be observed as on sampled measurements. The tolerance is the observer's and is the contract's own magnitude: a sampled speed never stands exactly at zero, so the caller sets the magnitude below which a measured speed counts as no movement at all, and it is no measure of how long the road user must remain still, which is the business of the law that calls the concept. The concept is a state of motion at an instant, read from the road user's own speed alone: it says nothing about how long it has stood or how long it will stand, nothing about where on the road it stands or what regions its footprint overlaps, nothing about why it stopped, nothing about any device, marking or junction before it, and nothing about the lawfulness or the sufficiency of the halt. It is not the brake lamp or any other signal the road user emits, not the selected gear, not the engine's being shut off, not a parking or a standing of the vehicle, and not a slackening of speed short of rest. Where the source reports no speed for the road user at the observation, the concept is unknown.

  The contract is the definition `DEF-NRS-484A-255`, verbatim.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    the magnitude of its velocity is at or below the speed tolerance the caller sets: atoms ['kin.speed'], concepts []

  How the element is written:

    "the magnitude of its velocity is at or below the speed tolerance the caller sets" — one
    comparison of one measured quantity with one formal parameter, read at the observation:
    `.cmp (.measure "kin_speed" [u]) .le (.param "halt_speed_tolerance")`. `kin_speed` is the
    magnitude of the velocity in m/s and the formal parameter is declared in m/s, so the two
    sides of the comparison stand in the same unit and no conversion, scaling or division enters
    the body. "At or below" is the non-strict `.le`: a measured speed standing exactly at the
    tolerance counts as no movement, which is what the contract's "at or below" says and what its
    account of the tolerance — the magnitude below which a measured speed counts as no movement
    at all — requires, since a sampled speed never stands exactly at zero.

    The argument of the atom is the track formal `u` alone, so the speed read is the road user's
    own. Nothing else is read: no `kin_accel_longitudinal` (the contract excludes a slackening of
    speed short of rest, and that atom is no stand-in for speed), no `sig_brake_lamp` (a lamp is
    an actuation, not a halt), no `kin_gear`, no `kin_engine_running`, no `rel_occupies` or region
    of any kind (the contract says nothing about where the road user stands), no device and no
    other road user.

    No temporal operator is written. The contract is a state of motion at an instant and says
    expressly that it is no measure of how long the road user must remain still, so no `holdsFor`,
    `since`, `sinceRise`, `always` or `count` appears: a duration written into the body would make
    the concept the very measure of standing still that the contract leaves to the calling law.
    With no look-back the body is never truncated at the start of a trace.

    The unknown is the atom's: where the source reports no speed for the road user at the
    observation, `kin_speed` is unknown (`absentAtom`), the comparison over it is unknown, and so
    is the concept — which is the contract's last sentence, carried by the three-valued reading of
    the comparison alone and needing no guard of its own.

  No magnitude below is this file's own: parameters are formals the caller fills.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.motion.at_rest

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aU : Arg := .var "u"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
def pHaltSpeedTolerance : Term := .param "halt_speed_tolerance"

/-- The magnitude of the road user's velocity at the observation, as the source measures it: m/s. -/
def speedNow : Term := .measure "kin_speed" [aU]

/-- The road user is not moving at the observation: its measured speed is at or below the
    tolerance the caller sets. Unknown where the source reports no speed for it. -/
def body : Formula := .cmp speedNow .le pHaltSpeedTolerance

def concept : Concept :=
  { id := "drv.motion.at_rest"
    contract := "The road user is not moving at the observation: the magnitude of its velocity is at or below the speed tolerance the caller sets, which is what \"complete cessation from movement\" can be observed as on sampled measurements. The tolerance is the observer's and is the contract's own magnitude: a sampled speed never stands exactly at zero, so the caller sets the magnitude below which a measured speed counts as no movement at all, and it is no measure of how long the road user must remain still, which is the business of the law that calls the concept. The concept is a state of motion at an instant, read from the road user's own speed alone: it says nothing about how long it has stood or how long it will stand, nothing about where on the road it stands or what regions its footprint overlaps, nothing about why it stopped, nothing about any device, marking or junction before it, and nothing about the lawfulness or the sufficiency of the halt. It is not the brake lamp or any other signal the road user emits, not the selected gear, not the engine's being shut off, not a parking or a standing of the vehicle, and not a slackening of speed short of rest. Where the source reports no speed for the road user at the observation, the concept is unknown."
    definition := some "DEF-NRS-484A-255"
    args := [("u", .track)]
    params := [⟨"halt_speed_tolerance", .metrePerSecond⟩]
    body := .formula body
    residues := ["DEF-NRS-484A-255 confines its sense to a stop that is required. The concept is the state of motion alone; which law requires a halt, and where, is carried by the rule that calls it."]  -- the record's, verbatim; not yours to change
    narrowings :=
      [ { span := "the magnitude of its velocity is at or below the speed tolerance the caller sets"
          why := "The magnitude is read from the road user's own measured speed, `.measure \"kin_speed\" [u]`, and not computed from the components of `kin.velocity`. The ontology carries kin.speed as the magnitude of the velocity in m/s, which is the very quantity the contract compares with the tolerance, so the one atom answers the span directly; taking the length of the velocity vector instead would call for a square root the formula language does not carry, and would make the concept unknown wherever a source reports a speed but no velocity vector. Both sides of the comparison therefore stand in m/s, the unit the formal parameter is declared in, and no scaling or division appears. 'At or below' is written as the non-strict `.le`, so a measured speed standing exactly at the tolerance counts as no movement at all, which is what the contract's account of the tolerance asks for."
          kind := "reading" }
      , { span := "The concept is a state of motion at an instant"
          why := "No temporal operator is written over the comparison: the body is the comparison itself, read at the observation. The contract says the concept is no measure of how long the road user must remain still and that it says nothing about how long it has stood or will stand, so no window behind, no `since`, no `always` and no counting of a run of observations enters; any of those would turn the concept into the measure of a duration that the contract reserves to the law that calls it. One consequence is declared here: a road user at rest at a run of observations satisfies the concept at each of them separately, and the concept distinguishes no first, last or interior observation of such a run."
          kind := "reading" } ]
    supersedes := none }

end TrafficSpec.Concepts.motion.at_rest
