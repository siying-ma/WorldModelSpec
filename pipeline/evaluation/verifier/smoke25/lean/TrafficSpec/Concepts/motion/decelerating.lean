/-
  drv.motion.decelerating — The road user is reducing its own speed at this observation: it is not at a complete halt, its ground speed being greater than speed_tolerance, the bound within which a sampled speed reading counts as no movement, and the component of its acceleration along its own heading is negative and its magnitude is greater than decel_tolerance, the magnitude of longitudinal acceleration within which a sampled reading cannot be told from travel at a steady speed. The concept denotes the change of the body's own speed as the body's motion shows it, and nothing else. It is not a halt: a body at rest sheds no further speed and is not denoted here whatever its acceleration reads, which is why the body's speed is read beside its acceleration, and a body that slows without stopping is denoted. It is not an actuation of the vehicle's controls - a lit brake lamp, a pressed service brake, a set parking brake and a selected gear are none of them this concept, and a body that slows on a grade with no control applied is denoted all the same. It is not a yielding, a giving of precedence or a halt at a place, and it carries no place: where the body is when it slows is the caller's to state. It is not a judgement that the reduction is enough, timely or safe: how much speed must be shed, and by what moment, is the caller's to state. It is a state at an observation and not a duration: how long the body has been slowing, and how much speed it has lost over a stretch, are the caller's to state. The bound on the reduction is one-sided below because a sharper reduction is still a reduction at this observation.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    it is not at a complete halt, its ground speed being greater than speed_tolerance: atoms [], concepts ['drv.motion.standstill']
    the component of its acceleration along its own heading is negative and its magnitude is greater than decel_tolerance: atoms ['kin.accel_longitudinal'], concepts []

  How the first element is written. `drv.motion.standstill` is "the road user is at a complete halt
  at this observation: the magnitude of its ground velocity is at or below speed_tolerance", so the
  denial of that call is exactly the contract's "it is not at a complete halt, its ground speed
  being greater than speed_tolerance": a ground speed strictly greater than the bound. The call
  takes this concept's track formal `u` and its `speed_tolerance` parameter, in the order that
  concept declares them, so the notion of a halt is defined once and the body reads no speed atom
  of its own. The denial is three-valued as the language is: where the body's ground speed is
  unobserved the halt is unknown and so is this conjunct, never false.

  How the second element is written. `kin.accel_longitudinal` is "acceleration along heading,
  signed" in m/s2, read once as `Term.measure "kin_accel_longitudinal" [u]`, and the contract's two
  words about it are written as two comparisons over that one reading: "is negative" as the reading
  below zero, and "its magnitude is greater than decel_tolerance" as the absolute value of the
  reading above `decel_tolerance`. No control atom is read: the lamp, the service brake, the parking
  brake and the gear are not this concept, and nothing but the rate of change of the body's own
  speed enters here, the speed itself entering through the halt element above. The bound is written
  one-sided below, a strict `>` on the magnitude, so a sharper reduction is still denoted.

  Narrowings. One, declared below: "negative and its magnitude is greater than decel_tolerance" is
  written as the conjunction of the two comparisons the words name, rather than as the single
  comparison of the signed reading below the negation of the bound. For the non-negative bound the
  parameter's meaning describes the two are the same; they part only on a caller that passes a
  negative magnitude, where the conjunction keeps the contract's "is negative" as a condition of
  its own and the single comparison would not.

  No magnitude below is this file's own: parameters are formals the caller fills.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.motion.decelerating

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aU : Arg := .var "u"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
def pSpeedTolerance : Term := .param "speed_tolerance"
def pDecelTolerance : Term := .param "decel_tolerance"

/-- The component of the body's acceleration along its own heading, signed. -/
def accelAlongHeading : Term := .measure "kin_accel_longitudinal" [aU]

/-- The body is not at a complete halt: its ground speed is greater than `speed_tolerance`, which
    is the denial of a halt as `drv.motion.standstill` renders one. -/
def notAtHalt : Formula :=
  .not (.derived "drv_motion_standstill" [aU] [pSpeedTolerance])

/-- The component of the body's acceleration along its own heading is negative and its magnitude is
    greater than `decel_tolerance`. -/
def shedsSpeed : Formula :=
  .and (.cmp accelAlongHeading .lt (.lit Q.zero .metrePerSecondSq))
    (.cmp (.abs accelAlongHeading) .gt pDecelTolerance)

/-- The body is reducing its own speed at this observation. -/
def body : Formula := .and notAtHalt shedsSpeed

def concept : Concept :=
  { id := "drv.motion.decelerating"
    contract := "The road user is reducing its own speed at this observation: it is not at a complete halt, its ground speed being greater than speed_tolerance, the bound within which a sampled speed reading counts as no movement, and the component of its acceleration along its own heading is negative and its magnitude is greater than decel_tolerance, the magnitude of longitudinal acceleration within which a sampled reading cannot be told from travel at a steady speed. The concept denotes the change of the body's own speed as the body's motion shows it, and nothing else. It is not a halt: a body at rest sheds no further speed and is not denoted here whatever its acceleration reads, which is why the body's speed is read beside its acceleration, and a body that slows without stopping is denoted. It is not an actuation of the vehicle's controls - a lit brake lamp, a pressed service brake, a set parking brake and a selected gear are none of them this concept, and a body that slows on a grade with no control applied is denoted all the same. It is not a yielding, a giving of precedence or a halt at a place, and it carries no place: where the body is when it slows is the caller's to state. It is not a judgement that the reduction is enough, timely or safe: how much speed must be shed, and by what moment, is the caller's to state. It is a state at an observation and not a duration: how long the body has been slowing, and how much speed it has lost over a stretch, are the caller's to state. The bound on the reduction is one-sided below because a sharper reduction is still a reduction at this observation."
    definition := none
    args := [("u", .track)]
    params := [⟨"speed_tolerance", .metrePerSecond⟩, ⟨"decel_tolerance", .metrePerSecondSq⟩]
    body := .formula body
    residues := []  -- the record's, verbatim; not yours to change
    narrowings :=
      [ { span := "the component of its acceleration along its own heading is negative and its magnitude is greater than decel_tolerance"
          why := "written as the conjunction of the two comparisons the words name over one reading of the signed longitudinal acceleration - that reading below zero, and its absolute value above decel_tolerance - rather than as the single comparison of the reading below the negation of the bound; for a non-negative bound, which is what the parameter's meaning as a magnitude describes, the two decide alike, and they part only on a caller that passes a negative magnitude, where this writing keeps the contract's 'is negative' as a condition of its own"
          kind := "reading" } ]
    supersedes := none }

end TrafficSpec.Concepts.motion.decelerating
