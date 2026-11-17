/-
  NRS_484B_267_2c — NRS-484B-267-2c

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (trigger): Upon approaching an authorized emergency vehicle or an official vehicle of a regulatory agency which is moving or preparing to move in any direction,
    s2 (trigger): including, without limitation, arriving at or leaving the scene of a crash or other incident,
    s3 (trigger): and making use of flashing lights meeting the requirements of
    s4 (reference): subsection 3 of NRS 484A.480 [DEF-NRS-484A-480-3],
    s5 (subject): the driver of any other vehicle shall,
    s6 (exception): except when otherwise directed by a law enforcement officer:
    s7 (obligation): Be prepared to stop.
    s8 (definitional): As used in this section, “preparing to move” means any indication that is visible to an approaching driver that an authorized emergency vehicle or an official vehicle of a regulatory agency is about to move, including, without limitation: (a) A movement of the vehicle; or (b) The use of hand signals by the driver of the vehicle.

  Elements (span → atoms, derived):
    s1: atoms ['kin.speed', 'rel.bearing', 'rel.centre_distance', 'ru.aggregate=DEF-NRS-484A-020::authorized_emergency_vehicle', 'ru.official_vehicle', 'rel.visible', 'sig.hand_signal', 'sig.turn_indicator'], derived []
    s3: atoms ['sig.warning_lamp'], derived [], borrowing ['s4']
    s5: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    s6: atoms ['dev.human_direction', 'dev.governs', 'rel.occupies', 'st.travel_region'], derived []
    s8: atoms ['kin.speed', 'rel.visible', 'sig.hand_signal', 'sig.turn_indicator'], derived []

  Borrowed words (span → source: the words; no rule is composed, the elements naming the span carry them):
    s4: DEF-NRS-484A-480-3: at least one flashing red warning lamp visible from the front

  How each span is written.
    s5 (subject class): `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`.
    s1 (approach): the subject moving (`kin_speed subject > p.halt_speed_tolerance`) and some road
      user `e` selected by `approachedVehicle`: not the subject (`same`, the word 'other'); a member
      of DEF-NRS-484A-020::authorized_emergency_vehicle (`ru_aggregate`) or an official vehicle
      (`ru_official_vehicle`) of kind regulatory_agency (`ru_official_vehicle_kind`); ahead of the
      subject (`rel_bearing … "ahead"`, longitudinal component positive) within
      p.emergency_approach_reach of centre distance (`rel_centre_distance ≤`). 'in any direction':
      no heading of `e` is read.
    s1/s8 (moving or preparing to move): `kin_speed e > p.halt_speed_tolerance`, or `e` visible
      from the subject (`rel_visible subject e`) and showing an arm signal (`sig_hand_signal e` other
      than no_signal) or a lit turn indicator (`sig_turn_indicator e` other than off).
    s3/s4 (flashing lights): `sig_warning_lamp e "red" "flashing"`. The record also fixes the
      facing (front); no atom form of the surface reads a lamp's facing (`sig_warning_lamp` takes a
      colour and a mode only), so the facing is declared `no_atom` on s3 in `narrowings` below.
    s6 (exception): no `human_direction` device of role police_officer governs (`dev_governs`) a
      `travel_region` the subject occupies (`rel_occupies`); the region is anchored to the subject by
      `rel_occupies`, the device to the region by `dev_governs`.
    s7 (obligation, surrogate stopping-distance model): for every `e` re-selected by the whole
      `approachedVehicle` selection, v·T + v²/(2a) ≤ gap, written without a division as
      v² ≤ a·(gap − v·T) + a·(gap − v·T) (a > 0), with v = `kin_speed subject`, T =
      p.driver_reaction_time, gap = `rel_surface_gap subject e` (the distance between the bodies),
      and a = p.following_decel_ice where `env_ice_or_snow`, else p.following_decel_wet where
      `env_wet_road` or `env_precipitation`, else p.following_decel_dry (`Term.cond`).
    s2: residue (the node's).

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_267_2c

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The approached vehicle (quantified, never a binder), the officer's device, the region. -/
def vE : Arg := .var "e"
def vD : Arg := .var "d"
def vR : Arg := .var "r"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pDriverReactionTime : Term := .param "p.driver_reaction_time"
def pEmergencyApproachReach : Term := .param "p.emergency_approach_reach"
def pFollowingDecelDry : Term := .param "p.following_decel_dry"
def pFollowingDecelIce : Term := .param "p.following_decel_ice"
def pFollowingDecelWet : Term := .param "p.following_decel_wet"
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"

def zeroMetres : Term := .lit Q.zero .metre

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-320::vehicle"] []

/-- s1: an authorized emergency vehicle or an official vehicle of a regulatory agency. -/
def emergencyOrRegulatory : Formula :=
  .or (.atom "ru_aggregate" [vE, .lit "DEF-NRS-484A-020::authorized_emergency_vehicle"] [])
      (.and (.atom "ru_official_vehicle" [vE] [])
            (.atom "ru_official_vehicle_kind" [vE, .lit "regulatory_agency"] []))

/-- s3/s4: flashing red warning lamp lit (the facing cannot be read: see the header). -/
def flashingRedLamp : Formula := .atom "sig_warning_lamp" [vE, .lit "red", .lit "flashing"] []

/-- s1/s8: moving, or preparing to move by an indication visible from the subject. -/
def movingOrPreparing : Formula :=
  .or (.cmp (.measure "kin_speed" [vE]) .gt pHaltSpeedTolerance)
      (.and (.atom "rel_visible" [vSubject, vE] [])
            (.or (.not (.atom "sig_hand_signal" [vE, .lit "no_signal"] []))
                 (.not (.atom "sig_turn_indicator" [vE, .lit "off"] []))))

/-- s1: ahead of the subject within the approach reach. -/
def aheadWithinReach : Formula :=
  .and (.atom "rel_bearing" [vSubject, vE, .lit "ahead"] [])
       (.cmp (.measure "rel_centre_distance" [vSubject, vE]) .le pEmergencyApproachReach)

/-- The whole selection of the approached vehicle `e`. -/
def approachedVehicle : Formula :=
  .and (.not (.same vE vSubject))
    (.and emergencyOrRegulatory
      (.and flashingRedLamp
        (.and movingOrPreparing aheadWithinReach)))

/-- s6: a law enforcement officer directs traffic in a travel region the subject occupies. -/
def officerDirecting : Formula :=
  .existsDevice (.lit "human_direction") "d"
    (.and (.atom "dev_human_direction_role" [vD, .lit "police_officer"] [])
      (.existsRegion (.lit "travel_region") "r"
        (.and (.atom "dev_governs" [vD, vR] [])
              (.atom "rel_occupies" [vSubject, vR] []))))

/-- Applicability: s1 (trigger): Upon approaching an authorized emergency vehicle or an official vehicle of a regulatory agency which is moving or preparing to move in any direction,; s2 (trigger): including, without limitation, arriving at or leaving the scene of a crash or other incident,; s3 (trigger): and making use of flashing lights meeting the requirements of; s6 (exception): except when otherwise directed by a law enforcement officer: -/
def applicability : Formula :=
  .and (.cmp (.measure "kin_speed" [vSubject]) .gt pHaltSpeedTolerance)
    (.and (.existsUser "e" approachedVehicle)
          (.not officerDirecting))

/-- The braking deceleration selected by the surface. -/
def decel : Term :=
  .cond (.atom "env_ice_or_snow" [] [])
    pFollowingDecelIce
    (.cond (.or (.atom "env_wet_road" [] []) (.atom "env_precipitation" [] []))
      pFollowingDecelWet
      pFollowingDecelDry)

def subjectSpeed : Term := .measure "kin_speed" [vSubject]

/-- The gap left after the reaction distance. -/
def gapAfterReaction : Term :=
  .sub (.measure "rel_surface_gap" [vSubject, vE]) (.mul subjectSpeed pDriverReactionTime)

/-- v·T + v²/(2a) ≤ gap, as v² ≤ 2a·(gap − v·T). -/
def canStopShort : Formula :=
  .cmp (.mul subjectSpeed subjectSpeed) .le
       (.add (.mul decel gapAfterReaction) (.mul decel gapAfterReaction))

/-- Obligation: s7 (obligation): Be prepared to stop. -/
def obligation : Formula :=
  .forallUser "e" (.implies approachedVehicle canStopShort)

def rule : Rule :=
  { id := "NRS_484B_267_2c"
    laws := ["NRS-484B-267-2c"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations :=
      [ { standard := "Be prepared to stop"
          concepts := ["env.ice_or_snow", "env.precipitation", "env.wet_road", "kin.speed", "rel.surface_gap"]
          params := ["p.driver_reaction_time", "p.following_decel_dry", "p.following_decel_wet", "p.following_decel_ice"]
          convention := "stopping-distance model: the subject is prepared to stop where the distance it needs to come to 'complete cessation from movement' (the stop when required, DEF-NRS-484A-255) — its speed times the perception-reaction time plus its speed squared over twice the braking deceleration — does not exceed the gap between its body and the approached vehicle's (rel.surface_gap); the deceleration is selected by the surface: ice or snow, else a wet road or falling precipitation, else dry"
          surrogate := true } ]
    residues := ["'including, without limitation' lists examples of a vehicle moving or preparing to move; the duty is the same whether or not the vehicle is arriving at or leaving the scene of a crash or other incident"]  -- the node's, verbatim; not yours to change
    narrowings :=
      [ { span := "s3"
          why := "the borrowed words of DEF-NRS-484A-480-3 'visible from the front', which the record writes as a lit sig.warning_lamp facing front, cannot be stated: no atom form of the surface reads a warning lamp's facing (sig_warning_lamp takes a colour, or a colour and a mode, only; WarningLamp.facing is read by no accessor), so the rule can require a red flashing lamp but not one facing front, and would wrongly fire on a red flashing lamp facing only rear or side"
          kind := "no_atom" } ]
    surrogate := true }

end TrafficSpec.Rules.NRS_484B_267_2c
