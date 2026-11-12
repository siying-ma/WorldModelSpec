/-
  drv.motion.backing — A road user is backing at an observation: it moves in the direction opposite to the one its body points. Measured as the component of its velocity (kin.velocity, m/s, world frame) along its heading (kin.heading, unit vector) lying below the negative of the motion tolerance, the speed below which a sampled motion counts as none. Not a stand-in for the gear selected: a vehicle in reverse gear that stands still or rolls forward is not backing, and one in a forward gear that rolls backwards is.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    the component of its velocity (kin.velocity, m/s, world frame) along its heading (kin.heading, unit vector): atoms ['kin.velocity', 'kin.heading'], concepts []

  Written as: (vx·hx + vy·hy) < −motion_tolerance, with vx, vy from `kin_velocity a "x"/"y"` and
  hx, hy from `kin_heading a "x"/"y"` (Core reads the heading normalised to a unit vector). "Lying
  below" is a strict comparison, as the words say; no reading was left open, so no narrowing.

  No magnitude below is this file's own: parameters are formals the caller fills.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.motion.backing

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aA : Arg := .var "a"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
def pMotionTolerance : Term := .param "motion_tolerance"

/-- The component of `a`'s velocity along its heading: the dot product of the world-frame velocity
    (m/s) and the unit heading, each read by its `x` and `y` components. -/
def velocityAlongHeading : Term :=
  .add (.mul (.measure "kin_velocity" [aA, .lit "x"]) (.measure "kin_heading" [aA, .lit "x"]))
       (.mul (.measure "kin_velocity" [aA, .lit "y"]) (.measure "kin_heading" [aA, .lit "y"]))

/-- Backing: that component lies (strictly) below the negative of the motion tolerance. The gear is
    not read. -/
def body : Formula := .cmp velocityAlongHeading .lt (.neg pMotionTolerance)

def concept : Concept :=
  { id := "drv.motion.backing"
    contract := "A road user is backing at an observation: it moves in the direction opposite to the one its body points. Measured as the component of its velocity (kin.velocity, m/s, world frame) along its heading (kin.heading, unit vector) lying below the negative of the motion tolerance, the speed below which a sampled motion counts as none. Not a stand-in for the gear selected: a vehicle in reverse gear that stands still or rolls forward is not backing, and one in a forward gear that rolls backwards is."
    definition := none
    args := [("a", .track)]
    params := [⟨"motion_tolerance", .metrePerSecond⟩]
    body := .formula body
    residues := []  -- the record's, verbatim; not yours to change
    narrowings := []  -- one { span := "<words of the contract>", why := "<why>", kind := "reading" } per reading you chose that the contract leaves open, explained in the header
    supersedes := none }

end TrafficSpec.Concepts.motion.backing
