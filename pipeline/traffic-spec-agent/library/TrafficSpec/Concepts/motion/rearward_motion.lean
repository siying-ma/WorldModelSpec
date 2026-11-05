/-
  drv.motion.rearward_motion — The road user is travelling rearward at this observation: its body is moving in the direction opposite to the one it points in. The state is read at the observation itself, from the component of the road user's velocity along its heading: that component is negative and its magnitude is above the speed tolerance, the reading below which a velocity component counts as no travel rather than movement. The concept denotes the direction of the body's travel only: it is not the gear selected, not a lamp or any other signal, and not a manoeuvre such as entering a place while reversing, which a caller states with its own relations.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    its body is moving in the direction opposite to the one it points in: atoms ['kin.velocity', 'kin.heading'], concepts []
      → `alongHeading`, the component of the velocity vector along the direction the body points:
        the dot product of `kin.velocity` with `kin.heading`, written over the two components the
        vector atoms expose (`.lit "x"`, `.lit "y"`): vx·hx + vy·hy. `kin.heading` is read
        normalised by its own contract, so this product is the signed length of the velocity's
        projection on the heading: negative exactly where the body moves opposite to the direction
        it points in. Neither gear nor any lamp is read: the contract excludes them.
    that component is negative and its magnitude is above the speed tolerance: atoms ['kin.velocity'], concepts []
      → the same `alongHeading` term, twice over: `alongHeading < 0 m/s` is 'negative', and
        `|alongHeading| > reverse_speed_tolerance` is 'its magnitude is above the speed tolerance'
        (strict, as 'above' says). Both conjuncts are at this observation: no temporal operator.
        `kin.speed` is not read — unsigned, it cannot tell rearward travel from forward.

  Readings this session chose that the contract left open (declared as narrowings below):
    - 'the component of the road user's velocity along its heading': written as the dot product of
      the velocity with the heading as `kin.heading` delivers it. That atom's contract normalises
      the heading only to within a micrometre of unit length (exactly unit for an axis-aligned
      direction), so the component is the true projection up to that factor, below 1 + 2·10⁻⁶.

  No magnitude below is this file's own: parameters are formals the caller fills.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.motion.rearward_motion

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aU : Arg := .var "u"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
def pReverseSpeedTolerance : Term := .param "reverse_speed_tolerance"

/-- The components of the velocity vector of `u`, in the world frame. -/
def vX : Term := .measure "kin_velocity" [aU, .lit "x"]
def vY : Term := .measure "kin_velocity" [aU, .lit "y"]

/-- The components of the direction `u` points in; the atom delivers it normalised. -/
def hX : Term := .measure "kin_heading" [aU, .lit "x"]
def hY : Term := .measure "kin_heading" [aU, .lit "y"]

/-- The component of the road user's velocity along its heading: v · ĥ, negative where the body
    moves opposite to the direction it points in. -/
def alongHeading : Term := .add (.mul vX hX) (.mul vY hY)

/-- No travel at all: the zero of the component's own unit. -/
def zeroSpeed : Term := .lit (Units.metresPerSecond 0) .metrePerSecond

/-- That component is negative, and its magnitude is above the speed tolerance. -/
def body : Formula :=
  .and (.cmp alongHeading .lt zeroSpeed)
       (.cmp (.abs alongHeading) .gt pReverseSpeedTolerance)

def concept : Concept :=
  { id := "drv.motion.rearward_motion"
    contract := "The road user is travelling rearward at this observation: its body is moving in the direction opposite to the one it points in. The state is read at the observation itself, from the component of the road user's velocity along its heading: that component is negative and its magnitude is above the speed tolerance, the reading below which a velocity component counts as no travel rather than movement. The concept denotes the direction of the body's travel only: it is not the gear selected, not a lamp or any other signal, and not a manoeuvre such as entering a place while reversing, which a caller states with its own relations."
    definition := none
    args := [("u", .track)]
    params := [⟨"reverse_speed_tolerance", .metrePerSecond⟩]
    body := .formula body
    residues := []  -- the record's, verbatim; not yours to change
    narrowings :=
      [ { span := "the component of the road user's velocity along its heading"
          why := "written as the dot product of kin.velocity with kin.heading over the two vector components; kin.heading is normalised by its own contract only to within a micrometre of unit length, so the component read is the true projection times a factor in [1, 1 + 2·10⁻⁶), exact for an axis-aligned heading"
          kind := "reading" } ]
    supersedes := none }

end TrafficSpec.Concepts.motion.rearward_motion
