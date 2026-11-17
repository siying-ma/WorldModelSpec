/-
  NRS_484B_127_1 — NRS-484B-127-1

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    f1 (subject): The driver of a vehicle
    f2 (obligation): shall not follow another vehicle
    f3 (standard): more closely than is reasonable and prudent, having due regard for the speed of such vehicles and the traffic upon and the condition of the highway.

  Elements (span → atoms, derived):
    f1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    f2: atoms ['rel.ahead_behind_in_lane', 'ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []

  How each is written:
    f1: the binder class `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`; the applicability is
        `.tt` (no trigger or condition span).
    f2: a quantifier over road users `other`, restricted to vehicles (`ru_aggregate other …`) ahead
        of the subject in its lane (`rel_ahead_behind_in_lane other subject`: `other` ahead of
        `subject`). The ahead relation is false for the subject itself, so 'another' needs no
        further term.
    f3: `rel_surface_gap subject other "longitudinal"` ≥ v_s·H + (v_s² − v_o²)/(2·D), with (H, D)
        selected by `Term.cond`: ice/snow → _ice; else wet road or precipitation → _wet; else _dry.
        `2·D` is written `D + D` (no literal two is declared); every divisor reads parameters only.
  No choice beyond the record's reading was made; no narrowing is declared.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_127_1

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pFollowingDecelDry : Term := .param "p.following_decel_dry"
def pFollowingDecelIce : Term := .param "p.following_decel_ice"
def pFollowingDecelWet : Term := .param "p.following_decel_wet"
def pFollowingHeadwayDry : Term := .param "p.following_headway_dry"
def pFollowingHeadwayIce : Term := .param "p.following_headway_ice"
def pFollowingHeadwayWet : Term := .param "p.following_headway_wet"

def zeroMetres : Term := .lit Q.zero .metre

/-- The followed road user, bound by the obligation's quantifier. -/
def vOther : Arg := .var "other"

/-- The aggregate id the node admits for 'vehicle'. -/
def aggVehicle : Arg := .lit "DEF-NRS-484A-320::vehicle"

/-- f1 / f2: membership of the vehicle aggregate (ru.aggregate). -/
def isVehicle (x : Arg) : Formula := .atom "ru_aggregate" [x, aggVehicle] []

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula := isVehicle vSubject

/-- Applicability: the node has no trigger or condition span; the subject's class (f1) is the
    binder's class, so the duty applies wherever the subject is a vehicle. -/
def applicability : Formula := .tt

/-- f3, condition of the highway: icy or snow-covered surface. -/
def iceOrSnow : Formula := .atom "env_ice_or_snow" [] []
/-- f3, condition of the highway: wet surface or falling rain. -/
def wetOrRain : Formula := .or (.atom "env_wet_road" [] []) (.atom "env_precipitation" [] [])

def speedOf (x : Arg) : Term := .measure "kin_speed" [x]

/-- The stopping-distance bound for a headway `h` and a braking deceleration `d`:
    v_s·h + (v_s² − v_o²) / (2·d). `2·d` is written `d + d` (no literal two is declared); the
    divisor reads parameters only. -/
def bound (h d : Term) : Term :=
  .add (.mul (speedOf vSubject) h)
    (.div (.sub (.mul (speedOf vSubject) (speedOf vSubject)) (.mul (speedOf vOther) (speedOf vOther)))
      (.add d d))

/-- f3: the bound selected by the condition of the highway (ice, else wet or rain, else dry). -/
def requiredGap : Term :=
  .cond iceOrSnow (bound pFollowingHeadwayIce pFollowingDecelIce)
    (.cond wetOrRain (bound pFollowingHeadwayWet pFollowingDecelWet)
      (bound pFollowingHeadwayDry pFollowingDecelDry))

/-- f3: the longitudinal component of the body gap from the subject to the followed vehicle. -/
def gap : Term := .measure "rel_surface_gap" [vSubject, vOther, .lit "longitudinal"]

/-- Obligation: f2 (obligation): shall not follow another vehicle; f3 (standard): more closely than
    is reasonable and prudent, having due regard for the speed of such vehicles and the traffic upon
    and the condition of the highway. For every vehicle ahead of the subject in its lane, the gap is
    at least the selected bound. -/
def obligation : Formula :=
  .forallUser "other"
    (.implies (.and (isVehicle vOther) (.atom "rel_ahead_behind_in_lane" [vOther, vSubject] []))
      (.cmp gap .ge requiredGap))

def rule : Rule :=
  { id := "NRS_484B_127_1"
    laws := ["NRS-484B-127-1"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations :=
      [ { standard := "more closely than is reasonable and prudent, having due regard for the speed of such vehicles and the traffic upon and the condition of the highway"
          concepts := ["env.ice_or_snow", "env.precipitation", "env.wet_road", "kin.speed", "rel.surface_gap"]
          params := ["p.following_headway_dry", "p.following_headway_wet", "p.following_headway_ice", "p.following_decel_dry", "p.following_decel_wet", "p.following_decel_ice"]
          convention := "Car-following stopping-distance convention: the longitudinal component of the body gap to each vehicle ahead in the lane (rel.surface_gap) is at least the subject's speed times a time headway, plus the difference of the two vehicles' braking distances (subject speed squared minus the followed vehicle's speed squared, over twice a braking deceleration). The speeds of both vehicles enter the bound by degree; the condition of the highway selects the headway and the deceleration: icy or snow-covered surface (env.ice_or_snow) the _ice pair, else a wet surface or falling rain (env.wet_road or env.precipitation) the _wet pair, else the _dry pair. Headways from the driver-manual following-time rules; decelerations from tyre-road friction tables."
          surrogate := true } ]
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []  -- one { span := "<span id>", why := "<why>", kind := "reading" } per reading you chose on a carried span (kind no_atom / no_operator where the words cannot be stated), explained in the header; the record's own narrowings are not restated
    surrogate := true }

end TrafficSpec.Rules.NRS_484B_127_1
