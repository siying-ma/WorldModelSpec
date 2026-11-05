/-
  drv.motion.rightward_course_change — The road user is making a change of course to the right: at this observation the signed heading change over the window behind is to the right (negative) and its magnitude lies between the smallest and the largest course change the caller admits as a turn, while the road user's speed is above the motion tolerance at every observation of that window. The window is the time within which such a manoeuvre is completed; below the smaller bound a change of course is lane-keeping or a bend taken, and above the larger the road user has turned about, which is a reversal of direction and not a change of course to the right. The concept denotes the change of course only: it is not the place where it is made, not a lamp or an arm signal, not a declared plan, and not the lawfulness of the manoeuvre.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    the signed heading change over the window behind is to the right (negative) and its magnitude lies between the smallest and the largest course change: atoms ['prim.heading_change'], concepts []
      written `Term.quantity "prim_heading_change" [aU] [pTurnWindow]`: the primitive is 'the
      signed heading change (degrees, left positive) of a road user over the window behind the
      observation, integrated from kin.yaw_rate', and its one parameter is the window length, which
      the formal `turn_window` fills. Left positive, so "to the right (negative)" is that quantity
      below zero: `.cmp headingChange .lt (.lit (Units.degrees 0) .degree)`. "its magnitude" is
      `.abs` of the same quantity, bounded below by `min_course_change` and above by
      `max_course_change`. The rate of change of heading and the observations it is integrated over
      are the primitive's own inputs and are not read here: the body names no `kin.yaw_rate`.
      Where the window is truncated, sampled too sparsely or a yaw rate is missing the primitive is
      unknown, and the comparisons over it are unknown with it.
    the road user's speed is above the motion tolerance at every observation of that window: atoms ['kin.speed'], concepts []
      written `.holdsFor .time pTurnWindow "u" (.cmp (.measure "kin_speed" [aU]) .gt
      pMotionSpeedTolerance)`: kin.speed is the 'magnitude of velocity' in m/s, and `holdsFor` is
      'φ at every observation in the window behind'. The window is the same `turn_window` the
      heading change is taken over — the contract's "that window" — and it is a `.time` window,
      the formal parameter being a time (s), not a distance travelled. The subject is the formal
      `u`, the road user whose course change this is. Where a speed in the window is unobserved the
      conjunct is unknown.

  The whole body is the conjunction of those four comparisons: the signed change to the right, its
  magnitude at or above the smaller bound, at or below the larger, and travel throughout the
  window. Nothing else is read: not the place of the manoeuvre (no region is quantified over and
  `rel.occupies` is not read), not a lamp or an arm signal (no `sig.*`), not a declared plan (no
  `intent`), and no rule.

  Narrowings (choices the contract left open):
    "its magnitude lies between the smallest and the largest course change" — read inclusively
      (`.ge`, `.le`), see the narrowing below.
    "the signed heading change over the window behind is to the right (negative)" — written as its
      own conjunct against zero degrees, see the narrowing below.
    "speed is above the motion tolerance" — read strictly (`.gt`), see the narrowing below.

  No magnitude below is this file's own: parameters are formals the caller fills; the only literal
  is zero, the hand of the signed change.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.motion.rightward_course_change

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aU : Arg := .var "u"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
def pTurnWindow : Term := .param "turn_window"
def pMinCourseChange : Term := .param "min_course_change"
def pMaxCourseChange : Term := .param "max_course_change"
def pMotionSpeedTolerance : Term := .param "motion_speed_tolerance"

/-- The signed heading change (degrees, left positive) of the road user over the window behind this
    observation, integrated by the primitive from the rate of change of heading. Unknown where the
    window is truncated, sampled too sparsely, or a yaw rate is missing. -/
def headingChange : Term := .quantity "prim_heading_change" [aU] [pTurnWindow]

/-- No change of course at all, the origin the hand of the signed change is read against. -/
def noChange : Term := .lit (Units.degrees 0) .degree

/-- The change of course is to the right: the signed heading change, left positive, is negative. -/
def toTheRight : Formula := .cmp headingChange .lt noChange

/-- Its magnitude is at least the smallest change of course the caller admits as a turn: below that
    bound a change of course is lane-keeping or a bend taken. -/
def atLeastSmallestTurn : Formula := .cmp (.abs headingChange) .ge pMinCourseChange

/-- Its magnitude is at most the largest change of course the caller admits as a turn: above that
    bound the road user has turned about, a reversal of direction. -/
def atMostLargestTurn : Formula := .cmp (.abs headingChange) .le pMaxCourseChange

/-- The road user's speed is above the motion tolerance at every observation of that window: the
    heading change is taken on a road user that travels, not on a body turning where it stands. -/
def travellingThroughWindow : Formula :=
  .holdsFor .time pTurnWindow "u"
    (.cmp (.measure "kin_speed" [aU]) .gt pMotionSpeedTolerance)

/-- A change of course to the right: the signed heading change over the window behind is negative
    and its magnitude lies between the two bounds, while the road user travels throughout that
    window. -/
def body : Formula :=
  .and (.and toTheRight (.and atLeastSmallestTurn atMostLargestTurn)) travellingThroughWindow

def concept : Concept :=
  { id := "drv.motion.rightward_course_change"
    contract := "The road user is making a change of course to the right: at this observation the signed heading change over the window behind is to the right (negative) and its magnitude lies between the smallest and the largest course change the caller admits as a turn, while the road user's speed is above the motion tolerance at every observation of that window. The window is the time within which such a manoeuvre is completed; below the smaller bound a change of course is lane-keeping or a bend taken, and above the larger the road user has turned about, which is a reversal of direction and not a change of course to the right. The concept denotes the change of course only: it is not the place where it is made, not a lamp or an arm signal, not a declared plan, and not the lawfulness of the manoeuvre."
    definition := none
    args := [("u", .track)]
    params := [⟨"turn_window", .second⟩, ⟨"min_course_change", .degree⟩, ⟨"max_course_change", .degree⟩, ⟨"motion_speed_tolerance", .metrePerSecond⟩]
    body := .formula body
    residues := []  -- the record's, verbatim; not yours to change
    narrowings :=
      [ { span := "its magnitude lies between the smallest and the largest course change"
          why := "Read inclusively (`.ge` against the smaller bound, `.le` against the larger). The parameters are 'the smallest magnitude of course change read as a turn rather than lane-keeping or a bend taken' and 'the largest magnitude of course change still read as a turn rather than a reversal of direction': at the smaller bound the change is already read as a turn, and at the larger it is 'still read as a turn', so both ends belong to the band the caller admits. A magnitude exactly at a bound is therefore a change of course to the right, not undecided and not excluded."
          kind := "reading" }
      , { span := "the signed heading change over the window behind is to the right (negative)"
          why := "Written as its own conjunct, the signed change below zero degrees, beside the two bounds on its magnitude rather than folded into them (as a bound on the negated change would fold them). The hand is then decided for every value the caller may give the bounds — a caller that sets the smaller bound at zero still gets the right hand only — and zero, a course held, is not to the right: the comparison is strict."
          kind := "reading" }
      , { span := "the road user's speed is above the motion tolerance at every observation of that window"
          why := "Read strictly (`.gt`). The tolerance is 'the speed below which a reading counts as no travel rather than movement', which leaves a reading exactly at the tolerance open; the strict reading keeps it on the side of no travel, so that the concept holds only where every observation of the window shows a speed the caller's tolerance does not cover. The window is the same `turn_window` the heading change is taken over, measured in time (`.time`), the parameter being a time."
          kind := "reading" } ]
    supersedes := none }

end TrafficSpec.Concepts.motion.rightward_course_change
