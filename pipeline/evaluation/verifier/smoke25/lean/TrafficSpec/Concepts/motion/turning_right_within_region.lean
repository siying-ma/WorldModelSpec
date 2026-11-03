/-
  drv.motion.turning_right_within_region — The road user's heading is turning to the right within the given region at this observation: its footprint overlaps the region, and its rate of change of heading, left positive so that a turning to the right is negative, is at most the negative of min_yaw_rate, the rate at which the body counts as turning rather than holding its course. The region is the caller's: the concept takes it as an argument and never looks for a region of its own. The concept denotes the state of the body's own motion, at the observation judged, at the place the caller names, and nothing else. It is not an accumulated change of direction: how far the body has turned, over any window, is not read here, so a body that has turned through a quarter circle and one that has just begun to turn are alike denoted while they turn within the region, and a body that has finished turning and holds its course again is not denoted at all - how much course a manoeuvre must change, and over what window, is the caller's to state. It is not a passage across the region, not an entry into it and not a departure from it: the body's footprint simply overlaps the region here, and where the body goes next is the caller's to state. It is not a manoeuvre with a destination, not any region beyond the one named, not a turn indicator or an arm signal, not an intention or a preparation to turn, and not a judgement that the turning is lawful, permitted or safe. It is not the curvature of the road: a body yaws on a straight road whenever it manoeuvres, and a body holding a bend at a steady radius within the region is turning by these words as much as one leaving its course, so a caller that must exclude the following of a bend states that itself. It is a state at an observation and not a duration: how long the body has been turning is the caller's to state. The bound is one-sided because a sharper rate is still turning to the right at this observation, and a body turning to the left does not satisfy these words at all.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    its footprint overlaps the region: atoms ['rel.occupies'], concepts []
    its rate of change of heading, left positive so that a turning to the right is negative, is at most the negative of min_yaw_rate: atoms ['kin.yaw_rate'], concepts []

  How the first element is written. `rel.occupies` is read of the two formals directly:
  `rel_occupies [u, r]` is "the road user's footprint overlaps the region", of the body the caller
  names and the region the caller names, at the observation judged. The region is never quantified
  over: the contract names it an argument, so the body binds no region of its own and reads no
  geometry and no distance — `st.region_geometry` is not claimed and not read, which is what the
  atom's "it is the overlap itself" asks. Nothing of the clause looks before or after this
  observation, so no entry, departure or passage across the region is written.

  How the second element is written. `kin.yaw_rate` is read of the body formal,
  `kin_yaw_rate [u]`, in degrees a second with the atom's own sign convention — positive when the
  heading turns to the left — and compared with the negative of the formal parameter:
  `kin_yaw_rate [u] ≤ -min_yaw_rate`. The sign convention of the atom is what makes a turning to
  the right the negative side, so no absolute value and no second bound appears: the comparison is
  one-sided, a sharper rate to the right satisfying it and any rate to the left failing it. No
  window operator is used anywhere in the body, so nothing is accumulated and nothing is a
  duration: the body is a state at the observation judged. Road curvature is not read at all —
  `st.curvature` is neither claimed nor named — so a body following a bend within the region is
  denoted as the contract says it is.

  The body is the conjunction of the two clauses, the contract's "and". Where the footprint overlap
  is unobserved, or the rate of change of heading is, the conjunct is unknown and so is the body,
  unless the other conjunct is already false.

  No magnitude below is this file's own: parameters are formals the caller fills.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.motion.turning_right_within_region

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aU : Arg := .var "u"
def aR : Arg := .var "r"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
def pMinYawRate : Term := .param "min_yaw_rate"

/-- Its footprint overlaps the region: the body the caller names and the region the caller names,
    at the observation judged. -/
def overlapsRegion : Formula := .atom "rel_occupies" [aU, aR] []

/-- Its rate of change of heading, left positive so that a turning to the right is negative, is at
    most the negative of `min_yaw_rate`. -/
def turningRight : Formula :=
  .cmp (.measure "kin_yaw_rate" [aU]) .le (.neg pMinYawRate)

/-- The body's heading is turning to the right within the given region at this observation. -/
def body : Formula := .and overlapsRegion turningRight

def concept : Concept :=
  { id := "drv.motion.turning_right_within_region"
    contract := "The road user's heading is turning to the right within the given region at this observation: its footprint overlaps the region, and its rate of change of heading, left positive so that a turning to the right is negative, is at most the negative of min_yaw_rate, the rate at which the body counts as turning rather than holding its course. The region is the caller's: the concept takes it as an argument and never looks for a region of its own. The concept denotes the state of the body's own motion, at the observation judged, at the place the caller names, and nothing else. It is not an accumulated change of direction: how far the body has turned, over any window, is not read here, so a body that has turned through a quarter circle and one that has just begun to turn are alike denoted while they turn within the region, and a body that has finished turning and holds its course again is not denoted at all - how much course a manoeuvre must change, and over what window, is the caller's to state. It is not a passage across the region, not an entry into it and not a departure from it: the body's footprint simply overlaps the region here, and where the body goes next is the caller's to state. It is not a manoeuvre with a destination, not any region beyond the one named, not a turn indicator or an arm signal, not an intention or a preparation to turn, and not a judgement that the turning is lawful, permitted or safe. It is not the curvature of the road: a body yaws on a straight road whenever it manoeuvres, and a body holding a bend at a steady radius within the region is turning by these words as much as one leaving its course, so a caller that must exclude the following of a bend states that itself. It is a state at an observation and not a duration: how long the body has been turning is the caller's to state. The bound is one-sided because a sharper rate is still turning to the right at this observation, and a body turning to the left does not satisfy these words at all."
    definition := none
    args := [("u", .track), ("r", .region)]
    params := [⟨"min_yaw_rate", .degreePerSecond⟩]
    body := .formula body
    residues := []  -- the record's, verbatim; not yours to change
    narrowings := []  -- one { span := "<words of the contract>", why := "<why>", kind := "reading" } per reading you chose that the contract leaves open, explained in the header
    supersedes := none }

end TrafficSpec.Concepts.motion.turning_right_within_region
