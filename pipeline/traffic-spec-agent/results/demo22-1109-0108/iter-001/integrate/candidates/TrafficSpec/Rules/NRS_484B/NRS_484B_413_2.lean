/-
  NRS_484B_413_2 — NRS-484B-413-2

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (obligation): A signal of intention to turn right or left, or otherwise turn a vehicle from a direct course, shall be given continuously during not less than the last 100 feet traveled
    s2 (condition): in a business or residential district and not less than the last 300 feet traveled in any other area
    s3 (condition): prior to changing the course of a vehicle.
    s4 (condition): This rule shall be observed, regardless of the weather.

  Elements (span → atoms, derived):
    s1: atoms ['kin.path_length', 'kin.yaw_rate', 'ru.aggregate=DEF-NRS-484A-320::vehicle', 'sig.hand_signal', 'sig.turn_indicator'], derived []
    s3: atoms [], derived ['drv.motion.turning']

  Literals the text states (each written through its Units constructor):
    s1: 100 ft — 100 feet
    s2: 300 ft — 300 feet

  No magnitude below is this file's own: parameters name the reading, literals are the text's.

  How each span is written:

  - binder `v` (subject): `ru_aggregate v "DEF-NRS-484A-320::vehicle"` — the admitted aggregate id,
    never the classes the posted definition covers.

  - s3 (condition, the occasion of the duty): `drv.motion.turning` rises for `v`
    (`.rises (.derived "drv_motion_turning" [v] [p.turn_recognition_window,
    p.heading_change_noise_floor])`). The concept is the law's own "turn right or left, or
    otherwise turn ... from a direct course"; "prior to" is read, as the record states, from the
    observation at which that change is first recognized, and the window of travelled path runs
    back from it. The parameters are the node's, in the concept's order (window, tolerance).

  - s1 + s2 (the duty and the length it selects): over the window of path travelled behind that
    observation — `.holdsFor .path (100 ft) "v"` where the trace declares
    `asm.in_business_or_residential_district`, `.holdsFor .path (300 ft) "v"` where it declares it
    does not — `v` gave the signal of the hand of the course change at every observation:
    `sig_turn_indicator v <hand>` or `sig_hand_signal v <hand>`. The two lengths are written as a
    pair of conditionals on the declaration rather than a `cond` term, because a window's length
    must be a constant term (`Rule.check`); where the trace declares the district neither way both
    conditionals are undecided and the verdict is unknown, as the record requires. The hand is
    read at the judged observation from the sign of `kin.yaw_rate` (left positive), outside the
    window, so that the window asks for the hand of the course change being judged and not for the
    hand of each past observation.

  - s4: residue, as the plan declares it; no weather atom is read.

  Narrowing declared by this session (the record's own narrowings are not restated): the hand is
  read from the SIGN of `kin.yaw_rate`, so at an observation whose rate of change of heading is
  exactly zero neither hand is read and the duty is not stated there — see `narrowings` below.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_413_2

/-- The binders, as arguments (order and names are the node's). -/
def vV : Arg := .var "v"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pHeadingChangeNoiseFloor : Term := .param "p.heading_change_noise_floor"
def pTurnRecognitionWindow : Term := .param "p.turn_recognition_window"

def zeroMetres : Term := .lit Q.zero .metre

/-- The district declaration of s2, which selects the length of the window. -/
def inDistrict : Formula := .asm "asm.in_business_or_residential_district"

/-- The text's own figures (s1, s2), each through the `Units` constructor of its unit. -/
def feet100 : Term := .lit (Units.feet 100) .metre
def feet300 : Term := .lit (Units.feet 300) .metre

/-- The subject's rate of change of heading at the judged observation, left positive. -/
def yawRateOfV : Term := .measure "kin_yaw_rate" [vV]
def zeroYawRate : Term := .lit Q.zero .degreePerSecond

/-- Class of `v`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsV : Formula := .atom "ru_aggregate" [vV, .lit "DEF-NRS-484A-320::vehicle"] []

/-- s3: the subject's heading is changing at the observation — the concept of the node's element,
    with the node's parameters in the concept's order. -/
def turning : Formula :=
  .derived "drv_motion_turning" [vV] [pTurnRecognitionWindow, pHeadingChangeNoiseFloor]

/-- Applicability: s2 (condition): in a business or residential district and not less than the last 300 feet traveled in any other area; s3 (condition): prior to changing the course of a vehicle.; s4 (condition): This rule shall be observed, regardless of the weather. -/
def applicability : Formula := .rises turning

/-- The signal of the hand `h`: the indicator lit on that hand, or an arm signal whose meaning is
    that hand. -/
def signalOfHand (h : String) : Formula :=
  .or (.atom "sig_turn_indicator" [vV, .lit h] [])
      (.atom "sig_hand_signal" [vV, .lit h] [])

/-- The signal of the hand of the course change at every observation of the window of travelled
    path `d` behind the judged observation; the hand is read here, at that observation. -/
def gaveSignalOver (d : Term) : Formula :=
  .and
    (.implies (.cmp yawRateOfV .gt zeroYawRate) (.holdsFor .path d "v" (signalOfHand "left")))
    (.implies (.cmp yawRateOfV .lt zeroYawRate) (.holdsFor .path d "v" (signalOfHand "right")))

/-- Obligation: s1 (obligation): A signal of intention to turn right or left, or otherwise turn a vehicle from a direct course, shall be given continuously during not less than the last 100 feet traveled -/
def obligation : Formula :=
  .and
    (.implies inDistrict (gaveSignalOver feet100))
    (.implies (.not inDistrict) (gaveSignalOver feet300))

def rule : Rule :=
  { id := "NRS_484B_413_2"
    laws := ["NRS-484B-413-2"]
    binders :=
      [ { name := "v", cls := clsV } ]
    applicability := applicability
    obligation := obligation
    assumptions := ["asm.in_business_or_residential_district"]
    intentions := []
    operationalizations := []
    residues := ["The words add no observable condition and no restriction: the signal is owed over the same window, in the same terms, whether or not rain, snow, wet road, ice or any other weather is present, so the duty is the same whether or not these words hold. The rule reads no weather atom for them, and nothing of the obligation is dropped."]  -- the node's, verbatim; not yours to change
    narrowings :=
      [ { span := "s1"
          why := "The hand of the course change is read from the sign of kin.yaw_rate at the judged observation: strictly positive is left, strictly negative is right. At an observation whose rate of change of heading is exactly zero no hand is read, so the duty of s1 is stated for a course change whose rate of change of heading is non-zero where it is recognized; the signal is required on the hand the sign gives and a signal on the other hand does not satisfy it."
          kind := "reading" } ]
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_413_2
