/-
  LVMC_11_40_130 — LVMC-11-40-130

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (trigger): It shall be unlawful for any person to operate
    s2 (subject): a bicycle
    s3 (obligation): at a speed greater than
    s4 (standard): is reasonable and prudent under the conditions then existing

  Elements (span → atoms, derived):
    s1: atoms ['kin.speed'], derived []
    s2: atoms ['ru.aggregate=DEF-NRS-484A-025::bicycle'], derived []
    s3: atoms ['kin.speed'], derived []

  How each is written:
    s2 → the binder class: `ru_aggregate subject "DEF-NRS-484A-025::bicycle"` (the aggregate id,
         never its classes).
    s1 → applicability: the subject moves, `kin_speed subject > p.halt_speed_tolerance` (the
         plan's observable reading of "operate").
    s3 + s4 → obligation, the stopping-sight-distance surrogate written as a product bound so no
         measured atom is a divisor:
           v² ≤ (a + a) · (D − v · p.bicycle_reaction_time)
         with v = kin_speed subject and a the surface's deceleration selected by `Term.cond`:
         p.bicycle_decel_ice where env_ice_or_snow, else p.bicycle_decel_wet where env_wet_road
         or env_precipitation, else p.bicycle_decel_dry.
         The distance seen D is env_visibility, and where env_darkness holds the smaller of
         env_visibility and p.bicycle_lamp_reach. "At most the smaller of two" is written as the
         bound against env_visibility conjoined with the bound against p.bicycle_lamp_reach where
         env_darkness holds (the two are equivalent since a > 0); no choice beyond the record's.
    Twice the deceleration is written a + a: the record declares no literal 2.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.LVMC_11_40_130

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pBicycleDecelDry : Term := .param "p.bicycle_decel_dry"
def pBicycleDecelIce : Term := .param "p.bicycle_decel_ice"
def pBicycleDecelWet : Term := .param "p.bicycle_decel_wet"
def pBicycleLampReach : Term := .param "p.bicycle_lamp_reach"
def pBicycleReactionTime : Term := .param "p.bicycle_reaction_time"
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"

def zeroMetres : Term := .lit Q.zero .metre

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-025::bicycle -/
def clsSubject : Formula :=
  .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-025::bicycle"] []

/-- kin.speed of the subject. -/
def speed : Term := .measure "kin_speed" [vSubject]

/-- Applicability: s1 (trigger): It shall be unlawful for any person to operate — the bicycle moves. -/
def applicability : Formula :=
  .cmp speed .gt pHaltSpeedTolerance

/-- env conditions. -/
def iceOrSnow : Formula := .atom "env_ice_or_snow" [] []
def wetRoad : Formula := .atom "env_wet_road" [] []
def precipitation : Formula := .atom "env_precipitation" [] []
def darkness : Formula := .atom "env_darkness" [] []
def visibility : Term := .measure "env_visibility" []

/-- The braking deceleration the surface selects (a selection among bounds). -/
def decel : Term :=
  .cond iceOrSnow pBicycleDecelIce
    (.cond (.or wetRoad precipitation) pBicycleDecelWet pBicycleDecelDry)

/-- Reaction distance: speed times the perception-reaction time. -/
def reactionDistance : Term := .mul speed pBicycleReactionTime

/-- Stopping within a seen distance `d`, as a product bound:
    v² ≤ 2 · a · (d − v · t_r). -/
def stopsWithin (d : Term) : Formula :=
  .cmp (.mul speed speed) .le (.mul (.add decel decel) (.sub d reactionDistance))

/-- Obligation: s3 (obligation): at a speed greater than; s4 (standard): is reasonable and prudent
    under the conditions then existing — stopping distance within the visibility, and in darkness
    also within the headlamp's reach. -/
def obligation : Formula :=
  .and (stopsWithin visibility)
    (.implies darkness (stopsWithin pBicycleLampReach))

def rule : Rule :=
  { id := "LVMC_11_40_130"
    laws := ["LVMC-11-40-130"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations :=
      [ { standard := "a speed reasonable and prudent under the conditions then existing"
          concepts := ["env.darkness", "env.ice_or_snow", "env.precipitation", "env.visibility", "env.wet_road", "kin.speed"]
          params := ["p.bicycle_reaction_time", "p.bicycle_decel_dry", "p.bicycle_decel_wet", "p.bicycle_decel_ice", "p.bicycle_lamp_reach"]
          convention := "bicycle stopping-sight-distance model: the distance travelled during the perception-reaction time plus the braking distance at a deceleration set by the surface does not exceed the distance ahead the rider can see; the surface (dry, wet or precipitation, ice or snow) selects the deceleration, and darkness caps the distance seen at the reach of a bicycle headlamp"
          surrogate := true } ]
    residues := []
    narrowings := []
    surrogate := true }

end TrafficSpec.Rules.LVMC_11_40_130
