/-
  NRS_484B_283_1b — NRS-484B-283-1b

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    r (reference): Except as otherwise provided in NRS 484B.287 [NRS-484B-287-1c, NRS-484B-287-1d, NRS-484B-287-1e, LVMC-11-30-060-A, LVMC-11-30-060-B], 484B.290 [LVMC-11-30-140-B] and 484B.350 [LVMC-11-46-030]:
    s (subject): A pedestrian
    ob (obligation): shall not suddenly leave a curb or other place of safety and walk or run into the path of a vehicle
    st (standard): which is so close that it is impossible for the driver to yield.

  Elements (span → atoms, derived):
    s: atoms ['ru.aggregate=DEF-NRS-484A-165::pedestrian'], derived []
    ob: atoms ['rel.occupies', 'st.sidewalk', 'st.safety_zone', 'st.median_or_divider', 'st.roadway', 'prim.closest_approach_within', 'prim.closest_approach_distance', 'ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []

  Compositions (span → node, as, map):
    r: NRS_484B_287_1c as exception map {'subject': 'subject'}
    r: NRS_484B_287_1d as exception map {'subject': 'subject'}
    r: NRS_484B_287_1e as exception map {'subject': 'subject'}
    r: LVMC_11_30_060_A as exception map {'subject': 'subject'}
    r: LVMC_11_30_060_B as exception map {'subject': 'subject'}
    r: LVMC_11_30_140_B_o1 as exception map {'subject': 'subject'}
    r: LVMC_11_30_140_B_o2 as exception map {'subject': 'subject'}
    r: LVMC_11_46_030_o1 as exception map {'subject': 'v'}
    r: LVMC_11_46_030_o2 as exception map {'subject': 'v'}

  How each span is written:
    s: binder class ru_aggregate(subject, DEF-NRS-484A-165::pedestrian).
    ob (leaving the place of safety, in the applicability as the record states it): onRoadway here
      ∧ rises(onRoadway ∨ ¬onPlaceOfSafety) — the rise gives, at the previous observation, no
      roadway and a sidewalk / safety zone / median-or-divider (rel_occupies over regions of each
      kind, anchored to the subject). Conjunct order (exceptions, then the rise, then onRoadway) is
      logically immaterial.
    ob (into the path of a vehicle), in the obligation: ¬∃ v. ru_aggregate(v, DEF-NRS-484A-320::vehicle)
      ∧ prim_closest_approach_within(subject, v; p.conflict_horizon)
      ∧ prim_closest_approach_distance(subject, v; p.conflict_horizon) < p.conflict_centre_clearance
      ∧ cannotYield. With no vehicle, the existential is false: compliant.
    st: 2·a·t_ca < 2·a·t_r + speed(v), rearranged as a·((t_ca + t_ca) − (t_r + t_r)) < speed(v)
      (an equivalent form; the deceleration term is read once so the cond-elimination stays
      small; the factor 2 is written as a sum, no literal). a = cond(ice, p.following_decel_ice,
      cond(wet, p.following_decel_wet, p.following_decel_dry)).
    r: each composition `.not (.ruleApplies id map)` in the applicability; LVMC_11_46_030_o1/o2
      map their subject to a scene road user v bound by `.existsUser "v"` around the composition
      (the composed rule's own binder class decides whether v is a vehicle).
  No choice beyond the record's own narrowings: `narrowings` is empty.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_283_1b

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pConflictCentreClearance : Term := .param "p.conflict_centre_clearance"
def pConflictHorizon : Term := .param "p.conflict_horizon"
def pDriverReactionTime : Term := .param "p.driver_reaction_time"
def pFollowingDecelDry : Term := .param "p.following_decel_dry"
def pFollowingDecelIce : Term := .param "p.following_decel_ice"
def pFollowingDecelWet : Term := .param "p.following_decel_wet"

def zeroMetres : Term := .lit Q.zero .metre

/-- The vehicle the obligation (and the 484B.350 exceptions) quantify over. -/
def vV : Arg := .var "v"

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-165::pedestrian -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-165::pedestrian"] []

/-- `v` is a vehicle: ru.aggregate=DEF-NRS-484A-320::vehicle. -/
def isVehicle : Formula := .atom "ru_aggregate" [vV, .lit "DEF-NRS-484A-320::vehicle"] []

/-- ob: the subject's footprint overlaps a roadway (st.roadway, rel.occupies). -/
def onRoadway : Formula :=
  .existsRegion (.lit "roadway") "rw" (.atom "rel_occupies" [vSubject, .var "rw"] [])

/-- ob: the subject's footprint overlaps a place of safety: a sidewalk (the curb's), a safety zone,
    or a median or divider (st.sidewalk, st.safety_zone, st.median_or_divider, rel.occupies). -/
def onPlaceOfSafety : Formula :=
  .or (.existsRegion (.lit "sidewalk") "sw" (.atom "rel_occupies" [vSubject, .var "sw"] []))
    (.or (.existsRegion (.lit "safety_zone") "sz" (.atom "rel_occupies" [vSubject, .var "sz"] []))
         (.existsRegion (.lit "median_or_divider") "md" (.atom "rel_occupies" [vSubject, .var "md"] [])))

/-- ob: the subject leaves a place of safety at this observation: on a roadway here, and at the
    previous observation on no roadway and on a place of safety. `rises (R ∨ ¬S)` is `R ∨ ¬S` here
    and `¬R ∧ S` at the previous observation; conjoined with `R` here it is exactly that. -/
def leavesPlaceOfSafety : Formula :=
  .and (.rises (.or onRoadway (.not onPlaceOfSafety))) onRoadway

/-- r: the exceptions (as exception, `.not (.ruleApplies …)`). -/
def exceptions : Formula :=
  .and (.not (.ruleApplies "NRS_484B_287_1c" [("subject", "subject")]))
  (.and (.not (.ruleApplies "NRS_484B_287_1d" [("subject", "subject")]))
  (.and (.not (.ruleApplies "NRS_484B_287_1e" [("subject", "subject")]))
  (.and (.not (.ruleApplies "LVMC_11_30_060_A" [("subject", "subject")]))
  (.and (.not (.ruleApplies "LVMC_11_30_060_B" [("subject", "subject")]))
  (.and (.not (.ruleApplies "LVMC_11_30_140_B_o1" [("subject", "subject")]))
  (.and (.not (.ruleApplies "LVMC_11_30_140_B_o2" [("subject", "subject")]))
  (.and (.not (.existsUser "v" (.ruleApplies "LVMC_11_46_030_o1" [("subject", "v")])))
        (.not (.existsUser "v" (.ruleApplies "LVMC_11_46_030_o2" [("subject", "v")]))))))))))

/-- Applicability: the subject leaves a place of safety for the roadway here, and no exception
    of span r is engaged. -/
def applicability : Formula := .and exceptions leavesPlaceOfSafety

/-- st: the braking deceleration selected by the surface: ice/snow, else wet, else dry. -/
def decel : Term :=
  .cond (.atom "env_ice_or_snow" [] []) pFollowingDecelIce
    (.cond (.atom "env_wet_road" [] []) pFollowingDecelWet pFollowingDecelDry)

/-- prim.closest_approach_time of subject and v, horizon p.conflict_horizon. -/
def tCa : Term := .quantity "prim_closest_approach_time" [vSubject, vV] [pConflictHorizon]

/-- prim.closest_approach_distance of subject and v, horizon p.conflict_horizon. -/
def dCa : Term := .quantity "prim_closest_approach_distance" [vSubject, vV] [pConflictHorizon]

/-- kin.speed of v. -/
def speedV : Term := .measure "kin_speed" [vV]

/-- st: impossible to yield: 2·a·t_ca < 2·a·t_r + speed(v), rearranged as
    a·((t_ca + t_ca) − (t_r + t_r)) < speed(v) so that the surface-selected deceleration is read
    once; the factor 2 is written as a sum. -/
def cannotYield : Formula :=
  .cmp (.mul decel (.sub (.add tCa tCa) (.add pDriverReactionTime pDriverReactionTime))) .lt speedV

/-- ob: v's path: the centres approach within the horizon to below the conflict clearance. -/
def intoPath : Formula :=
  .and (.derived "prim_closest_approach_within" [vSubject, vV] [pConflictHorizon])
       (.cmp dCa .lt pConflictCentreClearance)

/-- Obligation: ob (obligation): shall not suddenly leave a curb or other place of safety and walk or run into the path of a vehicle; st (standard): which is so close that it is impossible for the driver to yield. -/
def obligation : Formula :=
  .not (.existsUser "v" (.and isVehicle (.and intoPath cannotYield)))

def rule : Rule :=
  { id := "NRS_484B_283_1b"
    laws := ["NRS-484B-283-1b"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations :=
      [ { standard := "so close that it is impossible for the driver to yield"
          concepts := ["env.ice_or_snow", "env.wet_road", "kin.speed", "prim.closest_approach_time"]
          params := ["p.driver_reaction_time", "p.following_decel_dry", "p.following_decel_wet", "p.following_decel_ice"]
          convention := "stopping-distance model: the vehicle cannot yield where the time to the predicted closest approach (prim.closest_approach_time) is less than the driver's perception-reaction time plus the vehicle's speed (kin.speed) divided by twice the braking deceleration, written as a product (2·a·t_ca < 2·a·t_r + v); the deceleration is selected by the surface: icy or snow-covered (env.ice_or_snow), else wet (env.wet_road), else dry"
          surrogate := false } ]
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []  -- one { span := "<span id>", why := "<why>", kind := "reading" } per reading you chose on a carried span (kind no_atom / no_operator where the words cannot be stated), explained in the header; the record's own narrowings are not restated
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_283_1b
