/-
  drv.motion.backing — The road user is moving backwards at this observation: the component of its velocity along its own heading is negative, and its magnitude is greater than speed_tolerance, the bound within which a sampled velocity counts as no motion along the heading. The concept denotes the direction of the body's motion relative to the way it points, whatever the cause: a vehicle that rolls back on a grade is backing. It is not the gear selected — a vehicle in a forward gear rolls backwards on a grade and one in reverse may stand still — not a reversing lamp, and not a manoeuvre with a destination: where the body goes, and whether it reaches a region, is the caller's to state.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    the component of its velocity along its own heading: atoms ['kin.velocity', 'kin.heading'], concepts []
      Written as the scalar product of `kin.velocity` (the world-frame velocity vector) with
      `kin.heading` (the direction the body points, which a formula reads normalised, per that
      atom's contract): `v_x·h_x + v_y·h_y`, the signed speed along the heading. Each vector is
      read component by component, the only way a formula reads a vector atom.

  "is negative, and its magnitude is greater than speed_tolerance": for a negative number, a
  magnitude greater than the bound is the number itself strictly below the negated bound, so the
  two conditions together are the single comparison `v·h < −speed_tolerance`. The comparison is
  strict, as "greater than" is: a component whose magnitude is exactly the tolerance is not
  backing. Nothing is divided: the heading is normalised by the atom, so the scalar product is
  already the component, and no measurement stands in a denominator.

  Not read, as the contract directs: `kin.gear` (a forward gear rolls back on a grade and reverse
  may stand still), any reversing or signal lamp, and any region or destination — where the body
  goes is the caller's to state.

  No magnitude below is this file's own: parameters are formals the caller fills. No reading the
  contract leaves open was chosen here, so `narrowings` is empty.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.motion.backing

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aU : Arg := .var "u"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
def pSpeedTolerance : Term := .param "speed_tolerance"

/-- The component of the body's velocity along its own heading: the scalar product of the velocity
    vector with the (normalised) heading, read component by component. -/
def speedAlongHeading : Term :=
  .add (.mul (.measure "kin_velocity" [aU, .lit "x"]) (.measure "kin_heading" [aU, .lit "x"]))
       (.mul (.measure "kin_velocity" [aU, .lit "y"]) (.measure "kin_heading" [aU, .lit "y"]))

/-- Moving backwards: the component along the heading is negative with magnitude above the
    tolerance, i.e. below the negated tolerance. -/
def body : Formula := .cmp speedAlongHeading .lt (.neg pSpeedTolerance)

def concept : Concept :=
  { id := "drv.motion.backing"
    contract := "The road user is moving backwards at this observation: the component of its velocity along its own heading is negative, and its magnitude is greater than speed_tolerance, the bound within which a sampled velocity counts as no motion along the heading. The concept denotes the direction of the body's motion relative to the way it points, whatever the cause: a vehicle that rolls back on a grade is backing. It is not the gear selected — a vehicle in a forward gear rolls backwards on a grade and one in reverse may stand still — not a reversing lamp, and not a manoeuvre with a destination: where the body goes, and whether it reaches a region, is the caller's to state."
    definition := none
    args := [("u", .track)]
    params := [⟨"speed_tolerance", .metrePerSecond⟩]
    body := .formula body
    residues := []  -- the record's, verbatim; not yours to change
    narrowings := []  -- one { span := "<words of the contract>", why := "<why>", kind := "reading" } per reading you chose that the contract leaves open, explained in the header
    supersedes := none }

end TrafficSpec.Concepts.motion.backing
