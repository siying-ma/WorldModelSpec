/-
  drv.motion.rightward_course_change — At the observation the road user has turned its course to the right: the heading change it has accumulated over the window behind of length window is at least heading_change_min to the right, the change being read with the left-positive sign of the kinematics, so a rightward change is negative and the bound is reached where that signed change is at or below the negative of heading_change_min. The concept is recognized once the change has been carried out, so it holds at the observation at which that accumulated change first reaches the bound and at the later observations of the window over which it still does; a caller that needs the act itself reads the observation at which the concept rises. Where the window reaches past the start of the trace, is sampled too sparsely, or a yaw rate is missing, it is unknown. Not a stand-in for: a course change to the left, a reversal of the direction of travel, a lane change as a manoeuvre of its own, the road's curvature, a turn signal, the place the turn is made at, or the path the body swept.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    the heading change it has accumulated over the window behind of length window: atoms ['prim.heading_change'], concepts []
      Written as `Term.quantity "prim_heading_change" [u] [window]`: the accumulation over the window
      behind, its left-positive sign, and the three cases in which it is unknown (a window that
      reaches past the start of the trace, a window sampled too sparsely, a missing yaw rate) are the
      primitive's own, and the contract's last sentence but one states exactly those three. The
      window's length is the formal parameter `window`, the primitive's only parameter; `kin.yaw_rate`
      is the primitive's input, not this body's, so the body does not read it.
    is at least heading_change_min to the right, the change being read with the left-positive sign of the kinematics, so a rightward change is negative: atoms ['prim.heading_change'], concepts []
      Written as the one-sided comparison the contract spells out: the signed change at or below the
      negative of `heading_change_min` (`.le` against `Term.neg (.param "heading_change_min")`). The
      hand comes from the sign of the same primitive, so nothing else is read; `.le` is the
      contract's "at or below", and the bound is one-sided because a larger change to the right is
      still a change to the right. Nothing restricts the body to the instant of the act: the
      comparison holds at the observation at which the accumulated change first reaches the bound and
      at every later observation of the window over which it still does, which is what the contract
      says a caller that needs the act itself reads through its rise.

  Readings chosen that the contract did not dictate: none — the contract names the quantity, the
  sign, the sense of the bound and its strictness, so `narrowings` is empty.

  No magnitude below is this file's own: parameters are formals the caller fills.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.motion.rightward_course_change

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aU : Arg := .var "u"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
def pHeadingChangeMin : Term := .param "heading_change_min"
def pWindow : Term := .param "window"

/-- The course has been changed to the right: the heading change accumulated over the window behind,
    read with the left-positive sign of the kinematics, is at or below the negative of the caller's
    bound. Unknown wherever the primitive is: a truncated or sparsely sampled window, a missing yaw
    rate. -/
def body : Formula :=
  .cmp (.quantity "prim_heading_change" [aU] [pWindow]) .le (.neg pHeadingChangeMin)

def concept : Concept :=
  { id := "drv.motion.rightward_course_change"
    contract := "At the observation the road user has turned its course to the right: the heading change it has accumulated over the window behind of length window is at least heading_change_min to the right, the change being read with the left-positive sign of the kinematics, so a rightward change is negative and the bound is reached where that signed change is at or below the negative of heading_change_min. The concept is recognized once the change has been carried out, so it holds at the observation at which that accumulated change first reaches the bound and at the later observations of the window over which it still does; a caller that needs the act itself reads the observation at which the concept rises. Where the window reaches past the start of the trace, is sampled too sparsely, or a yaw rate is missing, it is unknown. Not a stand-in for: a course change to the left, a reversal of the direction of travel, a lane change as a manoeuvre of its own, the road's curvature, a turn signal, the place the turn is made at, or the path the body swept."
    definition := none
    args := [("u", .track)]
    params := [⟨"heading_change_min", .degree⟩, ⟨"window", .second⟩]
    body := .formula body
    residues := []  -- the record's, verbatim; not yours to change
    narrowings := []  -- one { span := "<words of the contract>", why := "<why>", kind := "reading" } per reading you chose that the contract leaves open, explained in the header
    supersedes := none }

end TrafficSpec.Concepts.motion.rightward_course_change
