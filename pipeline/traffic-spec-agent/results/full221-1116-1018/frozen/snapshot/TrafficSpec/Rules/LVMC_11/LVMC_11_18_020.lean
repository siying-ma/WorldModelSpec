/-
  LVMC_11_18_020 — LVMC-11-18-020

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    k1 (condition): The City Traffic Engineer is authorized to mark and maintain with yellow paint or road buttons crosswalks approximately twelve feet in width at intersections in the vicinity of schools where in the opinion of the City Traffic Engineer crossing the roadway by schoolchildren is unsafe.
    k2 (condition): The City Traffic Engineer, if necessary, is further authorized to mark and maintain with a distinguishing color or road buttons upon the pavement or by signs erected along the curb in a conspicuous manner, the words "School-Xing," not less than one hundred feet in advance of each crosswalk established
    k3 (boilerplate): and
    k4 (obligation): it shall be unlawful for the operator of any vehicle to drive into a crosswalk
    k5 (condition): where there is displayed a sign with the words "School-Xing,"
    k6 (condition): when there is in the crosswalk
    k7 (condition): upon the side of the roadway on which said vehicle is coming
    k8 (condition): any person
    k9 (condition): attempting to cross the street

  Elements (span → atoms, derived):
    k4: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle', 'rel.occupies', 'st.crosswalk'], derived []
    k5: atoms ['dev.zone_sign', 'dev.governs', 'st.entrance_of', 'st.lane_enters', 'rel.occupies', 'st.travel_region', 'st.intersection', 'st.crosswalk'], derived []
    k6: atoms ['rel.occupies', 'st.crosswalk'], derived []
    k7: atoms ['st.centre_line', 'prim.region_lateral_offset', 'rel.bearing', 'st.on_way', 'st.highway', 'st.one_way_roadway'], derived []
    k8: atoms ['ru.pedestrian', 'ru.bicycle', 'ru.electric_bicycle', 'ru.electric_scooter'], derived []
    k9: atoms ['rel.occupies', 'st.crosswalk'], derived []

  How each span is written:
    subject: `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`.
    k5: a travel region c (quantifier over `travel_region`, so every refining kind) the subject
        occupies, entering an intersection j (`st_lane_enters c j`); a zone sign d (quantifier over
        `zone_sign`) of kind `school_crossing` governing c (`dev_governs d c`); a crosswalk cw
        marking c's entrance (`st_entrance_of cw c`).
    k6/k8/k9: some road user o, other than the subject (`same`), of class pedestrian, bicycle,
        electric bicycle or electric scooter, occupying cw.
    k7: either the subject occupies a one-way roadway, or for some highway w with
        `st_on_way cw w` and some centre line cl with `st_on_way cl w`, with
        L = prim_region_lateral_offset(subject, cl) and y = rel_bearing(subject, o).y:
        (L > 0 ∧ y < L) ∨ (L < 0 ∧ y > L).
    k4: the obligation, for every (c, j, d, cw) of the applicability's selection re-stated in full
        (including a person of the named classes on the subject's side), is that the subject's
        occupancy of cw does not rise at this observation: `.not (.rises (rel_occupies subject cw))`.
  Choices the record left open: none; no narrowing is declared.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.LVMC_11_18_020

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

def zeroMetres : Term := .lit Q.zero .metre

def vC : Arg := .var "c"
def vJ : Arg := .var "j"
def vD : Arg := .var "d"
def vCw : Arg := .var "cw"
def vO : Arg := .var "o"
def vW : Arg := .var "w"
def vCl : Arg := .var "cl"
def vOw : Arg := .var "ow"

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-320::vehicle"] []

/-- k8: any person — on foot / in a wheelchair, or riding a bicycle, e-bicycle or e-scooter. -/
def personClass : Formula :=
  .or (.atom "ru_pedestrian" [vO] [])
    (.or (.atom "ru_bicycle" [vO] [])
      (.or (.atom "ru_electric_bicycle" [vO] []) (.atom "ru_electric_scooter" [vO] [])))

/-- L: the signed lateral offset of the centre line cl from the subject (left positive). -/
def offsetL : Term := .quantity "prim_region_lateral_offset" [vSubject, vCl] []

/-- y: the lateral component of the bearing of o from the subject. -/
def bearingY : Term := .measure "rel_bearing" [vSubject, vO, .lit "y"]

/-- k7: o on the side of the roadway on which the subject is coming. -/
def onSubjectSide : Formula :=
  .or (.existsRegion (.lit "one_way_roadway") "ow" (.atom "rel_occupies" [vSubject, vOw] []))
    (.existsRegion (.lit "highway") "w"
      (.and (.atom "st_on_way" [vCw, vW] [])
        (.existsRegion (.lit "centre_line") "cl"
          (.and (.atom "st_on_way" [vCl, vW] [])
            (.or (.and (.cmp offsetL .gt zeroMetres) (.cmp bearingY .lt offsetL))
                 (.and (.cmp offsetL .lt zeroMetres) (.cmp bearingY .gt offsetL)))))))

/-- k6, k8, k9, k7: some person other than the subject in cw, on the subject's side. -/
def personInCrosswalk : Formula :=
  .existsUser "o"
    (.and (.not (.same vO vSubject))
      (.and personClass
        (.and (.atom "rel_occupies" [vO, vCw] []) onSubjectSide)))

/-- The selection of (c, j, d, cw), stated once and used in both formulas. -/
def carrierEntersAt : Formula :=
  .and (.atom "rel_occupies" [vSubject, vC] []) (.atom "st_lane_enters" [vC, vJ] [])

def signGoverns : Formula :=
  .and (.atom "dev_zone_sign_kind" [vD, .lit "school_crossing"] []) (.atom "dev_governs" [vD, vC] [])

def crosswalkSelected : Formula :=
  .and (.atom "st_entrance_of" [vCw, vC] []) personInCrosswalk

/-- Applicability: k5, k6, k7, k8, k9 (k1, k2 are residues). -/
def applicability : Formula :=
  .existsRegion (.lit "travel_region") "c"
    (.existsRegion (.lit "intersection") "j"
      (.and carrierEntersAt
        (.existsDevice (.lit "zone_sign") "d"
          (.and signGoverns
            (.existsRegion (.lit "crosswalk") "cw" crosswalkSelected)))))

/-- Obligation: k4 — for every crosswalk the applicability selects, re-selected in full, the
    subject's occupancy of it does not rise here. -/
def obligation : Formula :=
  .forallRegion (.lit "travel_region") "c"
    (.forallRegion (.lit "intersection") "j"
      (.forallDevice (.lit "zone_sign") "d"
        (.forallRegion (.lit "crosswalk") "cw"
          (.implies (.and carrierEntersAt (.and signGoverns crosswalkSelected))
            (.not (.rises (.atom "rel_occupies" [vSubject, vCw] [])))))))

def rule : Rule :=
  { id := "LVMC_11_18_020"
    laws := ["LVMC-11-18-020"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations := []
    residues := ["an authority given to the City Traffic Engineer to mark school crosswalks; it imposes nothing on a road user, and the duty's own words select the crosswalk by the School-Xing sign displayed for it (k5), so the duty is the same whether or not these words are read", "an authority given to the City Traffic Engineer to mark or sign 'School-Xing' in advance of a crosswalk; the duty's own words read the sign displayed (k5), whoever placed it and at whatever set-back, so the duty is the same whether or not these words are read"]  -- the node's, verbatim; not yours to change
    narrowings := []
    surrogate := false }

end TrafficSpec.Rules.LVMC_11_18_020
