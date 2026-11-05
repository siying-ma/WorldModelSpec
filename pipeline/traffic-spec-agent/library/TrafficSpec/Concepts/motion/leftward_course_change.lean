/-
  drv.motion.leftward_course_change — The road user is making a change of course to the left: at this observation the signed heading change over the window behind is to the left (positive) and lies between the smallest and the largest course change the caller admits as a turn, while the road user's speed is above the motion tolerance at every observation of that window. The window is the time within which such a manoeuvre is completed; below the smaller bound a change of course is lane-keeping or a bend taken, and above the larger the road user has turned about, which is a reversal of direction and not a change of course to the left. The concept denotes the change of course only: it is not the place where it is made, not a lamp or an arm signal, not a declared plan, and not the lawfulness of the manoeuvre.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    the signed heading change over the window behind is to the left (positive): atoms [], concepts ['prim.heading_change']
      written `Term.quantity "prim_heading_change" [u] [turn_window]`: the primitive is 'the signed
      heading change (degrees, left positive) of a road user over the window behind the
      observation', so the hand is carried by the sign and the window behind is the primitive's own
      parameter, filled with `turn_window`. The quantity is read at the judged observation and
      compared with the two bounds: `≥ min_course_change` and `≤ max_course_change`. Nothing else
      is read for the manoeuvre: no lamp (sig.turn_indicator), no arm signal (sig.hand_signal), no
      declared plan (an intention), no place (no region), and no other rule.
    the road user's speed is above the motion tolerance at every observation of that window:
      atoms ['kin.speed'], concepts []
      written `.holdsFor .time turn_window "u" (kin_speed u > motion_speed_tolerance)`: 'at every
      observation of that window' is the back window `holdsFor` reads, of the same length as the
      primitive's, measured in time because `turn_window` is a time (s). This tells the road user
      that travelled round the corner from one whose heading changed while it stood.

  Narrowings (choices the contract left open):
    "lies between the smallest and the largest course change the caller admits as a turn" — read
      inclusively at both ends (`.ge`, `.le`): the parameters are 'the smallest leftward heading
      change read as a change of course' and 'the largest leftward heading change still read as a
      change of course', so each named value is itself admitted as a turn.
    "is to the left (positive)" — written as the signed comparison against `min_course_change`
      alone, with no separate test against zero: `min_course_change` is a leftward (positive)
      heading change by its meaning, so a change that reaches it is already to the left, and a
      rightward change, being negative, falls below it.
    "the road user's speed is above the motion tolerance" — read strictly (`.gt`): the parameter
      is 'the speed below which a reading counts as no travel', which leaves the boundary open;
      the strict reading keeps a reading exactly at the tolerance on the side of no travel.

  No magnitude below is this file's own: parameters are formals the caller fills.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.motion.leftward_course_change

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aU : Arg := .var "u"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
def pTurnWindow : Term := .param "turn_window"
def pMinCourseChange : Term := .param "min_course_change"
def pMaxCourseChange : Term := .param "max_course_change"
def pMotionSpeedTolerance : Term := .param "motion_speed_tolerance"

/-- The signed heading change (degrees, left positive) of the road user over the window behind
    this observation, the window being `turn_window`. -/
def headingChange : Term := .quantity "prim_heading_change" [aU] [pTurnWindow]

/-- The change of course is to the left and large enough to be a change of course: the signed
    change reaches the smallest leftward change the caller admits as a turn. A rightward change,
    being negative, falls below it. -/
def atLeastMinimum : Formula := .cmp headingChange .ge pMinCourseChange

/-- The change of course is no turn about: the signed change does not exceed the largest leftward
    change the caller still admits as a turn. -/
def atMostMaximum : Formula := .cmp headingChange .le pMaxCourseChange

/-- The road user travelled through the manoeuvre: its speed is above the motion tolerance at
    every observation of the same window behind. -/
def inMotionThroughWindow : Formula :=
  .holdsFor .time pTurnWindow "u"
    (.cmp (.measure "kin_speed" [aU]) .gt pMotionSpeedTolerance)

/-- A change of course to the left is being made here: over the window behind, the signed heading
    change lies between the two bounds the caller admits as a turn, and the road user was in
    motion at every observation of that window. -/
def body : Formula := .and (.and atLeastMinimum atMostMaximum) inMotionThroughWindow

def concept : Concept :=
  { id := "drv.motion.leftward_course_change"
    contract := "The road user is making a change of course to the left: at this observation the signed heading change over the window behind is to the left (positive) and lies between the smallest and the largest course change the caller admits as a turn, while the road user's speed is above the motion tolerance at every observation of that window. The window is the time within which such a manoeuvre is completed; below the smaller bound a change of course is lane-keeping or a bend taken, and above the larger the road user has turned about, which is a reversal of direction and not a change of course to the left. The concept denotes the change of course only: it is not the place where it is made, not a lamp or an arm signal, not a declared plan, and not the lawfulness of the manoeuvre."
    definition := none
    args := [("u", .track)]
    params := [⟨"turn_window", .second⟩, ⟨"min_course_change", .degree⟩, ⟨"max_course_change", .degree⟩, ⟨"motion_speed_tolerance", .metrePerSecond⟩]
    body := .formula body
    residues := []  -- the record's, verbatim; not yours to change
    narrowings :=
      [ { span := "lies between the smallest and the largest course change the caller admits as a turn"
          why := "Read inclusively at both ends (`.ge`, `.le`). The parameters are 'the smallest leftward heading change read as a change of course rather than lane-keeping or a bend' and 'the largest leftward heading change still read as a change of course rather than a turn about', so each named value is itself a change of course, and only a change strictly below the smaller or strictly above the larger is excluded."
          kind := "reading" }
      , { span := "is to the left (positive)"
          why := "Written as the signed comparison against `min_course_change` alone, with no separate comparison against zero. `min_course_change` is a leftward, hence positive, heading change by its meaning, so a signed change that reaches it is already to the left, and a rightward change, being negative, falls below it; a separate zero test would decide nothing the bound does not."
          kind := "reading" }
      , { span := "the road user's speed is above the motion tolerance at every observation of that window"
          why := "Read strictly (`.gt`): the tolerance is 'the speed below which a reading counts as no travel', which leaves the reading exactly at the tolerance open; the strict reading keeps that reading on the side of no travel. The window is the same `turn_window` the heading change is taken over, measured in time, because the parameter is a time."
          kind := "reading" } ]
    supersedes := none }

end TrafficSpec.Concepts.motion.leftward_course_change
