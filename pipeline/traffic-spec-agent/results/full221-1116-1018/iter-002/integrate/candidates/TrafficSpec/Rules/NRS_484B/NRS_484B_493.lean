/-
  NRS_484B_493 — NRS-484B-493

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    e1 (trigger): When official traffic-control devices are erected giving notice thereof,
    e2 (subject): a person
    e3 (obligation): shall not stand or park a vehicle
    e4 (condition): upon the left-hand side of a one-way
    e5 (condition): street.

  Elements (span → atoms, derived):
    e1: atoms ['dev.regulatory_sign', 'dev.governs', 'st.travel_region', 'rel.occupies', 'prim.conditions_hold', 'st.curb_zone'], derived []
    e2: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    e3: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived ['drv.motion.parked']
    e4: atoms ['rel.occupies', 'st.one_way_roadway', 'st.road_edge', 'st.on_way', 'st.highway', 'st.region_geometry', 'prim.region_lateral_offset', 'kin.heading', 'st.lane_direction'], derived []

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_493

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"
def pStandingMinDuration : Term := .param "p.standing_min_duration"

def zeroMetres : Term := .lit Q.zero .metre

/-
  How each span is written:
    e2 (subject): the binder's class, `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`.
    e1 (trigger): notice at the subject's place, two ways (the record's disjunction):
      · some travel region `tr` the subject occupies (rel_occupies) is governed (dev_governs) by a
        regulatory sign `sg` of code no_standing or no_parking whose conditions hold for the
        subject (prim_conditions_hold); or
      · the subject occupies a curb zone `cz` of kind no_parking or no_stopping.
    e5 (condition): `asm.within_incorporated_city`, the record's assumption for "street".
    e4 (condition): the subject occupies a one-way roadway `ow` lying on a highway `hw`
      (st_on_way); with dot = kin_heading(subject) · st_lane_direction(ow) (component-wise), some
      road edge `el` on `hw` has dot × prim_region_lateral_offset(subject, el) > 0 (left of the
      roadway's direction) and is strictly nearer the subject's body
      (st_region_geometry_distance) than every road edge `er` on `hw` with
      dot × offset(subject, er) < 0 (right of the roadway's direction). The product's sign is the
      record's "s times its offset"; only the sign of the dot product matters, so the product
      states it without a division.
    e3 (obligation): not drv_motion_parked(subject; p.halt_speed_tolerance, p.standing_min_duration).
  No choice beyond the record's own narrowings was made; `narrowings` is empty.
-/

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-320::vehicle"] []

/-- e1: a no_standing / no_parking regulatory sign, its conditions holding, governs a travel
    region the subject occupies; or the subject occupies a no_parking / no_stopping curb zone. -/
def notice : Formula :=
  .or
    (.existsRegion (.lit "travel_region") "tr"
      (.and (.atom "rel_occupies" [vSubject, .var "tr"] [])
        (.existsDevice (.lit "regulatory_sign") "sg"
          (.and (.atom "dev_governs" [.var "sg", .var "tr"] [])
            (.and
              (.or (.atom "dev_regulatory_sign_code" [.var "sg", .lit "no_standing"] [])
                   (.atom "dev_regulatory_sign_code" [.var "sg", .lit "no_parking"] []))
              (.derived "prim_conditions_hold" [.var "sg", vSubject] []))))))
    (.existsRegion (.lit "curb_zone") "cz"
      (.and (.atom "rel_occupies" [vSubject, .var "cz"] [])
        (.or (.atom "st_curb_zone_kind" [.var "cz", .lit "no_parking"] [])
             (.atom "st_curb_zone_kind" [.var "cz", .lit "no_stopping"] []))))

/-- The dot product of the subject's heading with the designated direction of region `r`. -/
def headingDot (r : String) : Term :=
  .add
    (.mul (.measure "kin_heading" [vSubject, .lit "x"]) (.measure "st_lane_direction" [.var r, .lit "x"]))
    (.mul (.measure "kin_heading" [vSubject, .lit "y"]) (.measure "st_lane_direction" [.var r, .lit "y"]))

/-- s × the lateral offset of edge `e` from the subject, s the sign of `headingDot r`. -/
def sideOf (r e : String) : Term :=
  .mul (headingDot r) (.quantity "prim_region_lateral_offset" [vSubject, .var e] [])

/-- Ground distance from the subject's body to region `e`. -/
def distTo (e : String) : Term := .measure "st_region_geometry_distance" [vSubject, .var e]

/-- e4: on the left-hand side of a one-way roadway on a highway. -/
def leftSideOfOneWay : Formula :=
  .existsRegion (.lit "one_way_roadway") "ow"
    (.and (.atom "rel_occupies" [vSubject, .var "ow"] [])
      (.existsRegion (.lit "highway") "hw"
        (.and (.atom "st_on_way" [.var "ow", .var "hw"] [])
          (.existsRegion (.lit "road_edge") "el"
            (.and (.atom "st_on_way" [.var "el", .var "hw"] [])
              (.and (.cmp (sideOf "ow" "el") .gt zeroMetres)
                (.forallRegion (.lit "road_edge") "er"
                  (.implies
                    (.and (.atom "st_on_way" [.var "er", .var "hw"] [])
                          (.cmp (sideOf "ow" "er") .lt zeroMetres))
                    (.cmp (distTo "el") .lt (distTo "er"))))))))))

/-- Applicability: e1 (trigger): When official traffic-control devices are erected giving notice thereof,; e4 (condition): upon the left-hand side of a one-way; e5 (condition): street. -/
def applicability : Formula :=
  .and (.asm "asm.within_incorporated_city") (.and notice leftSideOfOneWay)

/-- Obligation: e3 (obligation): shall not stand or park a vehicle -/
def obligation : Formula :=
  .not (.derived "drv_motion_parked" [vSubject] [pHaltSpeedTolerance, pStandingMinDuration])

def rule : Rule :=
  { id := "NRS_484B_493"
    laws := ["NRS-484B-493"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := ["asm.within_incorporated_city"]
    intentions := []
    operationalizations := []
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []  -- one { span := "<span id>", why := "<why>", kind := "reading" } per reading you chose on a carried span (kind no_atom / no_operator where the words cannot be stated), explained in the header; the record's own narrowings are not restated
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_493
