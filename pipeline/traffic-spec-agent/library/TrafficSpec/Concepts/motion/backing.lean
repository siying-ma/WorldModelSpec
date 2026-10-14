/-
  drv.motion.backing — The road user is travelling rearward: at every observation in the window behind, the component of its velocity along its own heading is negative and its magnitude is at or above the floor the caller sets. Units: the window in seconds, the floor in m/s; the heading is the body's own direction in the world frame. Not a stand-in for: a selected reverse gear or any other control input — the direction of motion is read from kinematics; a halt; a turn, which is a change of heading and not a direction of travel; or the reversing lamps, which the ontology does not carry.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    the component of its velocity along its own heading is negative: atoms ['kin.velocity', 'kin.heading'], concepts []

  How the words are written:
  - "the component of its velocity along its own heading" is `alongHeading`: the dot product of
    `kin.velocity` with `kin.heading`, component by component (`x`, `y`) in the world frame.
    `kin.heading` is the ontology's unit vector of the direction the body points, so the dot
    product is already the signed component — nothing is divided by the heading's length, and no
    length of this file's own enters it. Declared as a narrowing: the contract says "component",
    and the dot product with a unit vector is the one writing of it the atoms allow.
  - "is negative" is `alongHeading < 0`, the zero of m/s, written through `Units.metresPerSecond`.
    The sign carries the direction of travel: negative is rearward, because the component is taken
    along the heading and not against it. No control input (`kin.gear`, `kin.throttle`) is read,
    as the contract's "Not a stand-in for" requires, and `kin.speed` is not read, being unsigned.
  - "its magnitude is at or above the floor the caller sets" is `|alongHeading| ≥ speed_floor`,
    a second conjunct rather than the single bound `alongHeading ≤ -speed_floor`. Declared as a
    narrowing: the two differ at a floor of zero, where the contract's words still demand a
    negative component and the single bound would accept a halt — which the contract excludes.
  - "at every observation in the window behind" is `holdsFor .time window user`: the window is the
    contract's seconds, so the measure is time and not path.

  No magnitude below is this file's own: parameters are formals the caller fills.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.motion.backing

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aUser : Arg := .var "user"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
def pWindow : Term := .param "window"
def pSpeedFloor : Term := .param "speed_floor"

/-- The zero the sign of the travel is read against; no magnitude of this file's own. -/
def zeroSpeed : Term := .lit (Units.metresPerSecond 0) .metrePerSecond

/-- The component of the user's velocity along its own heading, in m/s: the dot product of
    `kin.velocity` with the unit vector `kin.heading`. Negative is rearward. -/
def alongHeading : Term :=
  .add
    (.mul (.measure "kin_velocity" [aUser, .lit "x"]) (.measure "kin_heading" [aUser, .lit "x"]))
    (.mul (.measure "kin_velocity" [aUser, .lit "y"]) (.measure "kin_heading" [aUser, .lit "y"]))

/-- Travelling rearward at one observation: the component is negative, and its magnitude is at or
    above the floor the caller sets. -/
def rearward : Formula :=
  .and (.cmp alongHeading .lt zeroSpeed)
       (.cmp (.abs alongHeading) .ge pSpeedFloor)

/-- Rearward at every observation in the window behind. -/
def body : Formula := .holdsFor .time pWindow "user" rearward

def concept : Concept :=
  { id := "drv.motion.backing"
    contract := "The road user is travelling rearward: at every observation in the window behind, the component of its velocity along its own heading is negative and its magnitude is at or above the floor the caller sets. Units: the window in seconds, the floor in m/s; the heading is the body's own direction in the world frame. Not a stand-in for: a selected reverse gear or any other control input — the direction of motion is read from kinematics; a halt; a turn, which is a change of heading and not a direction of travel; or the reversing lamps, which the ontology does not carry."
    definition := none
    args := [("user", .track)]
    params := [⟨"window", .second⟩, ⟨"speed_floor", .metrePerSecond⟩]
    body := .formula body
    residues := []  -- the record's, verbatim; not yours to change
    narrowings :=
      [ { span := "the component of its velocity along its own heading"
          why := "written as the dot product of kin.velocity with kin.heading, component by component in the world frame; kin.heading is the ontology's unit vector of the direction the body points, so the dot product is the signed component and nothing is normalized"
          kind := "reading" }
      , { span := "is negative and its magnitude is at or above the floor the caller sets"
          why := "written as two conjuncts, a negative component and a magnitude at or above the floor, rather than the single bound component ≤ -floor; the two differ at a floor of zero, where the words still demand a negative component and the single bound would accept a halt, which the contract excludes"
          kind := "reading" } ]
    supersedes := none }

end TrafficSpec.Concepts.motion.backing
