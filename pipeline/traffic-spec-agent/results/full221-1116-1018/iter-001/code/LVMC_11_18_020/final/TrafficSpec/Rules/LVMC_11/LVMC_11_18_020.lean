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
    subject (k4): `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`; the operator is read through the
      vehicle's own motion (the record's agency reading), never as a class.
    k5: a carrier c (`existsRegion travel_region`) the subject occupies, entering an intersection j
      (`st_lane_enters c j`), governed (`dev_governs d c`) by a zone sign d (`existsDevice zone_sign`)
      whose kind attribute is `school_crossing` (`dev_zone_sign_kind`), and a crosswalk cw
      (`existsRegion crosswalk`) recorded as marking c's entrance (`st_entrance_of cw c`).
    k6, k8, k9: some road user o other than the subject (`not (same o subject)`), of class
      pedestrian, bicycle, electric bicycle or electric scooter, occupying cw (`rel_occupies o cw`).
    k7: either a highway w that cw lies on (`st_on_way cw w`) and a centre line cl lying on w
      (`st_on_way cl w`) with L = prim_region_lateral_offset(subject, cl) and y the lateral component of
      rel_bearing(subject, o): (L > 0 and y < L) or (L < 0 and y > L); or the subject occupies a
      one-way roadway (`existsRegion one_way_roadway`, `rel_occupies subject r`).
    k4 (obligation): for every selection of (c, j, d, cw) the applicability makes — re-bound with the
      whole selection (k5–k9) — the subject's occupancy of cw does not rise here:
      `not (rises (rel_occupies subject cw))`. The duty is stated for each crosswalk so selected,
      as the record's "for the cw bound in the applicability, re-bound with the same selection".

  Choices the text did not dictate: none beyond the record's. No narrowing is declared.

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
def vR : Arg := .var "r"

/-- `x`'s footprint overlaps region `r` (rel.occupies). -/
def occ (x r : Arg) : Formula := .atom "rel_occupies" [x, r] []

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-320::vehicle"] []

/-- k8: a person on foot or in a wheelchair, or riding a bicycle, an electric bicycle or an electric
    scooter. -/
def personClass : Formula :=
  .or (.or (.atom "ru_pedestrian" [vO] []) (.atom "ru_bicycle" [vO] []))
      (.or (.atom "ru_electric_bicycle" [vO] []) (.atom "ru_electric_scooter" [vO] []))

/-- L: the signed lateral offset of the centre line from the subject (left positive). -/
def lateralOfCentreLine : Term := .quantity "prim_region_lateral_offset" [vSubject, vCl] []

/-- y: the lateral component of o's bearing from the subject (left positive). -/
def lateralOfPerson : Term := .measure "rel_bearing" [vSubject, vO, .lit "y"]

/-- k7: o is on the side of the roadway on which the subject is coming. -/
def onSubjectSide : Formula :=
  .or
    (.existsRegion (.lit "highway") "w"
      (.and (.atom "st_on_way" [vCw, vW] [])
        (.existsRegion (.lit "centre_line") "cl"
          (.and (.atom "st_on_way" [vCl, vW] [])
            (.or
              (.and (.cmp lateralOfCentreLine .gt zeroMetres) (.cmp lateralOfPerson .lt lateralOfCentreLine))
              (.and (.cmp lateralOfCentreLine .lt zeroMetres) (.cmp lateralOfPerson .gt lateralOfCentreLine)))))))
    (.existsRegion (.lit "one_way_roadway") "r" (occ vSubject vR))

/-- k6, k8, k9, k7: some person other than the subject in cw, on the subject's side. -/
def personInCrosswalk : Formula :=
  .existsUser "o"
    (.and (.not (.same vO vSubject))
      (.and personClass
        (.and (occ vO vCw) onSubjectSide)))

/-- k5 with k6–k9, for bound c, j, d, cw: the subject occupies carrier c entering intersection j, a
    School-Xing zone sign d governs c, crosswalk cw marks c's entrance, and a person of the named
    classes is in cw on the subject's side. -/
def selection : Formula :=
  .and (occ vSubject vC)
    (.and (.atom "st_lane_enters" [vC, vJ] [])
      (.and (.atom "dev_zone_sign_kind" [vD, .lit "school_crossing"] [])
        (.and (.atom "dev_governs" [vD, vC] [])
          (.and (.atom "st_entrance_of" [vCw, vC] [])
            personInCrosswalk))))

/-- Applicability: k1 (condition): The City Traffic Engineer is authorized to mark and maintain with yellow paint or road buttons crosswalks approximately twelve feet in width at intersections in the vicinity of schools where in the opinion of the City Traffic Engineer crossing the roadway by schoolchildren is unsafe.; k2 (condition): The City Traffic Engineer, if necessary, is further authorized to mark and maintain with a distinguishing color or road buttons upon the pavement or by signs erected along the curb in a conspicuous manner, the words "School-Xing," not less than one hundred feet in advance of each crosswalk established; k5 (condition): where there is displayed a sign with the words "School-Xing,"; k6 (condition): when there is in the crosswalk; k7 (condition): upon the side of the roadway on which said vehicle is coming; k8 (condition): any person; k9 (condition): attempting to cross the street -/
def applicability : Formula :=
  .existsRegion (.lit "travel_region") "c"
    (.existsRegion (.lit "intersection") "j"
      (.existsDevice (.lit "zone_sign") "d"
        (.existsRegion (.lit "crosswalk") "cw" selection)))

/-- Obligation: k4 (obligation): it shall be unlawful for the operator of any vehicle to drive into a crosswalk -/
def obligation : Formula :=
  .forallRegion (.lit "travel_region") "c"
    (.forallRegion (.lit "intersection") "j"
      (.forallDevice (.lit "zone_sign") "d"
        (.forallRegion (.lit "crosswalk") "cw"
          (.implies selection (.not (.rises (occ vSubject vCw)))))))

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
