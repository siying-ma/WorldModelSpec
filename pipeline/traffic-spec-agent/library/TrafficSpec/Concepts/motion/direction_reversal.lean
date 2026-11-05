/-
  drv.motion.direction_reversal — The road user has turned about so as to travel back the way it came: at this observation its direction of travel is the reverse of the one it had at the start of the window behind. It is read at the observation itself, from the signed heading change over the window behind lying in a band about a half turn — at least a half turn less the opposition tolerance and at most a half turn plus it, in either hand — while the road user's speed is above the motion tolerance at every observation of that window, so that the heading change is travel and not a body turning where it stands. The window is the time within which such a manoeuvre is completed, and the tolerance is the largest departure from an exact half turn still read as the opposite direction; the band is two-sided because a course change well beyond a half turn leaves the road user travelling otherwise than back the way it came. The concept denotes the reversal of the direction of travel only: it is not a turn into another road, not the hand the manoeuvre is made with, not the place where it is made, and not its lawfulness.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    the signed heading change over the window behind lying in a band about a half turn: atoms [], concepts ['prim.heading_change']
    the road user's speed is above the motion tolerance at every observation of that window: atoms ['kin.speed'], concepts []

  Literals the contract states (declared; written through a `Units` constructor):
    180 deg — a half turn, the heading change that leaves a body pointing the opposite way: a geometric constant of the notion, not a magnitude the reading sets

  How it is written. The body is the conjunction of the two elements, read at the observation
  itself.

  The course change: `prim.heading_change u reversal_window` is the signed heading change
  (degrees, left positive) over the window behind, which is the only thing the first element
  names; the band about a half turn is two comparisons on it — at least `180 − opposition_tolerance`
  and at most `180 + opposition_tolerance`. The contract makes the band hold "in either hand", so
  the comparisons are on the magnitude (`Term.abs`) of the signed change: a turn of the same size
  made to the left and one made to the right read alike, and the hand of the manoeuvre — which the
  contract excludes — is nowhere read. 180 deg is the declared literal, written through
  `Units.degrees`; the tolerance and the window are formal parameters the caller fills.

  The motion: `kin_speed u` above `motion_speed_tolerance` at every observation of the same window
  behind, written `holdsFor .time reversal_window`, the window measured in time, as the parameter's
  unit (seconds) states, and over the same length as the course change, since the contract says
  "that window". The operator reads the window's first observation and the judged one and every one
  between, and is unknown where the window reaches past the start of the trace or a speed there is
  unobserved. `kin.path_length` is not read: the concept bounds no distance.

  Nothing of a turn into another road, of the hand, of the place or of its lawfulness enters the
  body: no atom of a region, a lane or a device is read.

  No magnitude below is this file's own: parameters are formals the caller fills.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.motion.direction_reversal

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aU : Arg := .var "u"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
def pReversalWindow : Term := .param "reversal_window"
def pOppositionTolerance : Term := .param "opposition_tolerance"
def pMotionSpeedTolerance : Term := .param "motion_speed_tolerance"

/-- A half turn: the heading change that leaves a body pointing the opposite way. -/
def halfTurn : Term := .lit (Units.degrees 180) .degree

/-- The signed heading change (degrees, left positive) over the window behind. -/
def headingChange : Term := .quantity "prim_heading_change" [aU] [pReversalWindow]

/-- The course change lies in the band about a half turn, in either hand: its magnitude is at
    least a half turn less the tolerance and at most a half turn plus it. -/
def inOppositionBand : Formula :=
  .and (.cmp (.abs headingChange) .ge (.sub halfTurn pOppositionTolerance))
       (.cmp (.abs headingChange) .le (.add halfTurn pOppositionTolerance))

/-- The road user's speed is above the motion tolerance at this observation. -/
def travelling : Formula := .cmp (.measure "kin_speed" [aU]) .gt pMotionSpeedTolerance

/-- It travelled throughout the window behind: the heading change is travel, not a body turning
    where it stands. -/
def travellingThroughWindow : Formula :=
  .holdsFor .time pReversalWindow "u" travelling

/-- Turned about: the course change in the band about a half turn, while travelling throughout. -/
def body : Formula := .and inOppositionBand travellingThroughWindow

def concept : Concept :=
  { id := "drv.motion.direction_reversal"
    contract := "The road user has turned about so as to travel back the way it came: at this observation its direction of travel is the reverse of the one it had at the start of the window behind. It is read at the observation itself, from the signed heading change over the window behind lying in a band about a half turn — at least a half turn less the opposition tolerance and at most a half turn plus it, in either hand — while the road user's speed is above the motion tolerance at every observation of that window, so that the heading change is travel and not a body turning where it stands. The window is the time within which such a manoeuvre is completed, and the tolerance is the largest departure from an exact half turn still read as the opposite direction; the band is two-sided because a course change well beyond a half turn leaves the road user travelling otherwise than back the way it came. The concept denotes the reversal of the direction of travel only: it is not a turn into another road, not the hand the manoeuvre is made with, not the place where it is made, and not its lawfulness."
    definition := none
    args := [("u", .track)]
    params := [⟨"reversal_window", .second⟩, ⟨"opposition_tolerance", .degree⟩, ⟨"motion_speed_tolerance", .metrePerSecond⟩]
    body := .formula body
    residues := []  -- the record's, verbatim; not yours to change
    narrowings :=
      [ { span := "at least a half turn less the opposition tolerance and at most a half turn plus it, in either hand"
          why := "The band is written on the magnitude of the signed heading change (`abs` of `prim.heading_change`), so a course change of the same size made to the left and one made to the right read alike and the hand of the manoeuvre is nowhere read; the bounds are inclusive, as `at least` and `at most` say."
          kind := "reading" }
      , { span := "while the road user's speed is above the motion tolerance at every observation of that window"
          why := "Written `holdsFor .time reversal_window`: the same window behind as the heading change, measured in time (the parameter's unit is seconds), covering the window's first observation, the judged one and every one between. It is unknown where that window reaches past the start of the trace, where the observations in it are more than half the window apart, or where a speed in it is unobserved."
          kind := "reading" } ]
    supersedes := none }

end TrafficSpec.Concepts.motion.direction_reversal
