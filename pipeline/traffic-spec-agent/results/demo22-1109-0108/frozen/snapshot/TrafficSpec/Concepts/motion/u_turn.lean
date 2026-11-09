/-
  drv.motion.u_turn — The road user's direction of travel upon a way has reversed: counting from the onset of the manoeuvre — the observation at which the magnitude of its rate of change of heading first rose above the onset yaw rate, a rate the caller sets — the magnitude of the heading change accumulated since that onset reaches at least the reversal angle, a size the caller sets below a half turn, while the road user's footprint overlaps a way. The definition this contract carries is the turning of a vehicle upon a highway “so as to proceed in the opposite direction”, “whether accomplished by one continuous movement or not”, so halts, rearward movements and steering the other way between the onset and the reversal do not end the manoeuvre, and the count runs on until the angle is reached or a later onset starts it again; the integration is bounded by the heading step, the largest interval between consecutive observations it may integrate across. The concept becomes true at the observation at which that angle is first reached, and it holds at the later observations at which the accumulated change still holds that angle, until a later onset starts the count again. Where no such onset is observed, with the rate of change of heading known at every observation from the one before it onwards and no interval between consecutive observations longer than the heading step, the concept is unknown and never false, so a reversal begun before the recording is never read as one made within it. The reversal angle is the contract's own magnitude, the bound within which a sampled heading change is read as the opposite direction. Not a stand-in for: a turn through a smaller angle, which has its own concept, a turn into another way, travel against a designated direction of travel, a reversing movement, or a signal or a declared intention.

  The contract is the definition `DEF-NRS-484B-077`, verbatim.

  THE READING (the blueprint's; the session records here, per element, how the contract's words are
  written, and every choice the contract did not dictate).

  Elements (contract words → atoms, concepts):
    the magnitude of its rate of change of heading first rose above the onset yaw rate: atoms ['kin.yaw_rate'], concepts []
      `onset` is the standing condition `|kin_yaw_rate u| > onset_yaw_rate`. The onset itself is not
      this condition but its definite rise, which `Term.headingSince` takes as the observation the
      count starts from: false at the observation before, true there.
    the magnitude of the heading change accumulated since that onset: atoms ['kin.yaw_rate'], concepts []
      `Term.headingSince "u" heading_step onset` — the signed heading change integrated from the
      same atom since that rise, zero at the onset, unaffected by the condition turning false (a
      halt, a rearward movement or steering the other way between the onset and the reversal does
      not end the count), bounded by the heading step; `.abs` of it is the magnitude the contract
      reads, so a reversal to either hand is recognized, and `.ge reversal_angle` is "reaches at
      least the reversal angle". Unobserved is unknown: where no onset is observed with the yaw
      rate known at every observation since, the term is unknown and the body with it, never false.
    while the road user's footprint overlaps a way: atoms ['st.highway', 'rel.occupies'], concepts []
      `existsRegion (.lit "highway") "w" (rel_occupies u w)` — the way the body is on, not any way
      of the scene; `w` is anchored to the formal `u` through `rel_occupies`.

  Readings chosen (declared as narrowings below):
    - "first rose above the onset yaw rate": the count is taken from the LATEST such rise, which is
      what `headingSince` anchors to. The contract's own extent fixes this ("the count runs on
      until the angle is reached or a later onset starts it again"), so "first" is read as the
      first rise of the run the count belongs to, not the first of the whole recording.
    - "while the road user's footprint overlaps a way": read at the observation the concept speaks
      about (the one at which the angle is reached, and each later one at which it still holds),
      not as a condition over the whole manoeuvre from the onset onwards.

  No magnitude below is this file's own: parameters are formals the caller fills.
-/
import TrafficSpec.Core.Language.Concept

namespace TrafficSpec.Concepts.motion.u_turn

/-- The formal arguments, as `Arg`s (a literal formal is written `.var` and filled by the caller). -/
def aU : Arg := .var "u"

/-- The formal parameters, as `Term`s; no value of any of them lives in this file. -/
def pHeadingStep : Term := .param "heading_step"
def pOnsetYawRate : Term := .param "onset_yaw_rate"
def pReversalAngle : Term := .param "reversal_angle"

/-- The onset condition: the magnitude of the road user's rate of change of heading above the
    onset yaw rate. The onset the count runs from is this condition's definite rise. -/
def onset : Formula :=
  .cmp (.abs (.measure "kin_yaw_rate" [aU])) .gt pOnsetYawRate

/-- The magnitude of the heading change accumulated since that onset reaches at least the
    reversal angle; unknown where no such onset is observed. -/
def reversed : Formula :=
  .cmp (.abs (.headingSince "u" pHeadingStep onset)) .ge pReversalAngle

/-- The road user's footprint overlaps a way. -/
def uponWay : Formula :=
  .existsRegion (.lit "highway") "w" (.atom "rel_occupies" [aU, .var "w"] [])

def body : Formula := .and reversed uponWay

def concept : Concept :=
  { id := "drv.motion.u_turn"
    contract := "The road user's direction of travel upon a way has reversed: counting from the onset of the manoeuvre — the observation at which the magnitude of its rate of change of heading first rose above the onset yaw rate, a rate the caller sets — the magnitude of the heading change accumulated since that onset reaches at least the reversal angle, a size the caller sets below a half turn, while the road user's footprint overlaps a way. The definition this contract carries is the turning of a vehicle upon a highway “so as to proceed in the opposite direction”, “whether accomplished by one continuous movement or not”, so halts, rearward movements and steering the other way between the onset and the reversal do not end the manoeuvre, and the count runs on until the angle is reached or a later onset starts it again; the integration is bounded by the heading step, the largest interval between consecutive observations it may integrate across. The concept becomes true at the observation at which that angle is first reached, and it holds at the later observations at which the accumulated change still holds that angle, until a later onset starts the count again. Where no such onset is observed, with the rate of change of heading known at every observation from the one before it onwards and no interval between consecutive observations longer than the heading step, the concept is unknown and never false, so a reversal begun before the recording is never read as one made within it. The reversal angle is the contract's own magnitude, the bound within which a sampled heading change is read as the opposite direction. Not a stand-in for: a turn through a smaller angle, which has its own concept, a turn into another way, travel against a designated direction of travel, a reversing movement, or a signal or a declared intention."
    definition := some "DEF-NRS-484B-077"
    args := [("u", .track)]
    params := [⟨"heading_step", .second⟩, ⟨"onset_yaw_rate", .degreePerSecond⟩, ⟨"reversal_angle", .degree⟩]
    body := .formula body
    residues := ["Which devices count as a vehicle is the aggregate the caller states of the road user it passes; the concept is written for any road user and adds no class of its own."]  -- the record's, verbatim; not yours to change
    narrowings :=
      [ { span := "the observation at which the magnitude of its rate of change of heading first rose above the onset yaw rate"
          why := "The count is anchored to the latest observation at which that magnitude rose above the onset yaw rate (false at the observation before, true there), not to the first such rise of the recording: the contract's own extent fixes this, since \"the count runs on until the angle is reached or a later onset starts it again\". \"First\" is therefore read as the first rise of the run the count belongs to."
          kind := "reading" }
      , { span := "while the road user's footprint overlaps a way"
          why := "Read at the observation the concept speaks about — the one at which the angle is reached, and each later one at which the accumulated change still holds it — and not as a condition required at every observation from the onset onwards; the contract makes the overlap a circumstance of the reversal it recognizes, not a further bound on the manoeuvre's course." } ]
    supersedes := none }

end TrafficSpec.Concepts.motion.u_turn
