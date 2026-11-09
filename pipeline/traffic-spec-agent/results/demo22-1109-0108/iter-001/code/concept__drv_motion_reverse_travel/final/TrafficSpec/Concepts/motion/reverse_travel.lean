/-
  drv.motion.reverse_travel — The road user is travelling rearward at the observation: the component of its velocity along the direction its body points is at most the negative of the reverse speed tolerance, a speed the caller sets, so that a rearward component smaller than it is read as none. The concept states the direction of the body's motion relative to the direction it points, at the observation only, and says nothing of how long the rearward motion lasts or where it happens. Not a stand-in for: the gear selected — a body in a forward gear rolls backwards on a grade and one in reverse stands still — a reversing lamp or any other signal, a halt, a turn, or the place the motion happens at.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    the component of its velocity along the direction its body points: atoms ['kin.velocity', 'kin.heading'], concepts []

      Written as the scalar product of the velocity vector with the direction the body points:
      `kin_velocity(u, x)·kin_heading(u, x) + kin_velocity(u, y)·kin_heading(u, y)`. A formula reads
      `kin.heading` normalised (Core divides it by its larger absolute component and then by its
      length taken to a micrometre), so the product is the signed speed along the heading in m/s:
      positive forward, negative rearward. `kin.speed` is not read, being unsigned, and `kin.gear`
      is not read at all — the ontology directs backing to be read from kinematics.

      The contract's bound is written exactly as its words state it: the component is *at most*
      (`.le`) the negative of the tolerance, so a rearward component of exactly the tolerance holds
      and one smaller in magnitude fails. Either atom unobserved leaves the comparison, and with it
      the concept, unknown.

  Nothing of duration, place, gear, signal or turn enters the body: the comparison speaks of the
  judged observation alone.

  No magnitude below is this file's own: parameters are formals the caller fills. (The two `.lit`
  arguments are the vector-component selectors "x" and "y", not magnitudes.)
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.motion.reverse_travel

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aU : Arg := .var "u"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
def pReverseSpeedTolerance : Term := .param "reverse_speed_tolerance"

/-- The components of the velocity vector of `u`, in the world frame (m/s). -/
def velX : Term := .measure "kin_velocity" [aU, .lit "x"]
def velY : Term := .measure "kin_velocity" [aU, .lit "y"]

/-- The components of the direction `u`'s body points, read normalised. -/
def headX : Term := .measure "kin_heading" [aU, .lit "x"]
def headY : Term := .measure "kin_heading" [aU, .lit "y"]

/-- The component of `u`'s velocity along the direction its body points: the signed speed in that
    direction (m/s), positive forward, negative rearward. -/
def alongHeading : Term := .add (.mul velX headX) (.mul velY headY)

/-- The component along the heading is at most the negative of the reverse speed tolerance. -/
def body : Formula := .cmp alongHeading .le (.neg pReverseSpeedTolerance)

def concept : Concept :=
  { id := "drv.motion.reverse_travel"
    contract := "The road user is travelling rearward at the observation: the component of its velocity along the direction its body points is at most the negative of the reverse speed tolerance, a speed the caller sets, so that a rearward component smaller than it is read as none. The concept states the direction of the body's motion relative to the direction it points, at the observation only, and says nothing of how long the rearward motion lasts or where it happens. Not a stand-in for: the gear selected — a body in a forward gear rolls backwards on a grade and one in reverse stands still — a reversing lamp or any other signal, a halt, a turn, or the place the motion happens at."
    definition := none
    args := [("u", .track)]
    params := [⟨"reverse_speed_tolerance", .metrePerSecond⟩]
    body := .formula body
    residues := []  -- the record's, verbatim; not yours to change
    narrowings := []  -- one { span := "<words of the contract>", why := "<why>", kind := "reading" } per reading you chose that the contract leaves open, explained in the header
    supersedes := none }

end TrafficSpec.Concepts.motion.reverse_travel
