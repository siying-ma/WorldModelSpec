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
    s2: the binder class `ru_aggregate subject "DEF-NRS-484A-025::bicycle"`.
    s1: the applicability `kin_speed subject > p.halt_speed_tolerance` (operation read through the
        bicycle's controlled motion: the record's observable reading).
    s3 + s4: the stopping-sight-distance bound, written as a product so that no measured atom is a
        divisor: with v = kin_speed, a the surface deceleration and D the distance seen,
          v·v ≤ 2·a·(D − v·p.bicycle_reaction_time),
        the factor 2 written as a sum of two equal terms (no literal but zero is the file's own).
        a = Term.cond: p.bicycle_decel_ice where env_ice_or_snow, else p.bicycle_decel_wet where
        env_wet_road or env_precipitation, else p.bicycle_decel_dry.
        D: "env_visibility, and where env_darkness holds the smaller of env_visibility and
        p.bicycle_lamp_reach" is written as the conjunction of the bound at D = env_visibility and,
        where env_darkness holds, the bound at D = p.bicycle_lamp_reach. The bound is monotone in
        D, so holding at both is holding at their minimum: the same statement, not a narrowing,
        and no measured atom is placed in a selection condition.

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

/-- kin.speed of the subject. -/
def speed : Term := .measure "kin_speed" [vSubject]

/-- env.visibility. -/
def visibility : Term := .measure "env_visibility" []

def iceOrSnow : Formula := .atom "env_ice_or_snow" [] []
def wetRoad : Formula := .atom "env_wet_road" [] []
def precipitation : Formula := .atom "env_precipitation" [] []
def darkness : Formula := .atom "env_darkness" [] []

/-- The deceleration the surface selects (a selection among bounds). -/
def decel : Term :=
  .cond iceOrSnow pBicycleDecelIce
    (.cond (.or wetRoad precipitation) pBicycleDecelWet pBicycleDecelDry)

/-- The distance travelled during the perception-reaction time. -/
def reactionDistance : Term := .mul speed pBicycleReactionTime

/-- The stopping bound at a distance seen `d`: v·v ≤ 2·a·(d − v·t_r). -/
def stopsWithin (d : Term) : Formula :=
  let margin : Term := .mul decel (.sub d reactionDistance)
  .cmp (.mul speed speed) .le (.add margin margin)

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-025::bicycle -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-025::bicycle"] []

/-- Applicability: s1 (trigger): It shall be unlawful for any person to operate -/
def applicability : Formula := .cmp speed .gt pHaltSpeedTolerance

/-- Obligation: s3 (obligation): at a speed greater than; s4 (standard): is reasonable and prudent under the conditions then existing -/
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
