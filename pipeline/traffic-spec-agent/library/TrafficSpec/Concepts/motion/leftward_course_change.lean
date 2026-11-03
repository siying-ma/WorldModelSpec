/-
  drv.motion.leftward_course_change — At the observation the road user has turned its course to the left: the heading change it has accumulated over the window behind of length window is at least heading_change_min to the left. The concept is recognized once the change has been carried out, so it holds at the observation at which that accumulated change first reaches the bound and at the later observations of the window over which it still does; a caller that needs the act itself reads the observation at which the concept rises. Where the window reaches past the start of the trace, is sampled too sparsely, or a yaw rate is missing, it is unknown. Not a stand-in for: a reversal of the direction of travel, a lane change, the road's curvature, a turn signal, the place the turn is made at, or the path the body swept.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    the heading change it has accumulated over the window behind of length window is at least heading_change_min to the left: atoms ['prim.heading_change'], concepts []

      `prim.heading_change u window` is the signed heading change in degrees, left positive,
      accumulated over the window behind the observation of length `window`, integrated from
      `kin.yaw_rate`. "at least heading_change_min to the left" is therefore one comparison on that
      signed value: the accumulated change is at or above `+heading_change_min`. The sign carries
      the direction, so no magnitude and no second comparison is needed: a rightward change is
      negative and fails the bound, as do a leftward change below it and a window whose leftward
      and rightward parts cancel.

      Everything the contract makes unknown is the primitive's own: a window reaching past the
      start of the trace (`windowTruncated`), a window sampled more sparsely than half its length
      (`samplingGap`), and a missing yaw rate inside it (`absentAtom kin.yaw_rate`). The body adds
      no case of its own, so it is unknown exactly where the contract says it is.

      The three sentences of the contract that follow the element are not further conditions: the
      comparison is evaluated at every observation, so it is true at the observation at which the
      accumulated change first reaches the bound and at the later ones at which it still does, and
      a caller after the act itself wraps the call in `rises`. Nothing here reads the direction of
      travel, a lane, the road's curvature, a turn signal, a region or a swept path, which is what
      the "not a stand-in for" list excludes.

  No choice was left open: the contract's one element is one comparison on one primitive, so
  `narrowings` stays empty.

  No magnitude below is this file's own: parameters are formals the caller fills.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.motion.leftward_course_change

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aU : Arg := .var "u"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
def pHeadingChangeMin : Term := .param "heading_change_min"
def pWindow : Term := .param "window"

/-- The heading change `u` has accumulated over the window behind of length `window`, in degrees,
    left positive. -/
def accumulatedChange : Term := .quantity "prim_heading_change" [aU] [pWindow]

/-- That accumulated change is at least `heading_change_min` to the left. -/
def body : Formula := .cmp accumulatedChange .ge pHeadingChangeMin

def concept : Concept :=
  { id := "drv.motion.leftward_course_change"
    contract := "At the observation the road user has turned its course to the left: the heading change it has accumulated over the window behind of length window is at least heading_change_min to the left. The concept is recognized once the change has been carried out, so it holds at the observation at which that accumulated change first reaches the bound and at the later observations of the window over which it still does; a caller that needs the act itself reads the observation at which the concept rises. Where the window reaches past the start of the trace, is sampled too sparsely, or a yaw rate is missing, it is unknown. Not a stand-in for: a reversal of the direction of travel, a lane change, the road's curvature, a turn signal, the place the turn is made at, or the path the body swept."
    definition := none
    args := [("u", .track)]
    params := [⟨"heading_change_min", .degree⟩, ⟨"window", .second⟩]
    body := .formula body
    residues := []  -- the record's, verbatim; not yours to change
    narrowings := []  -- one { span := "<words of the contract>", why := "<why>", kind := "reading" } per reading you chose that the contract leaves open, explained in the header
    supersedes := none }

end TrafficSpec.Concepts.motion.leftward_course_change
