/-
  LVMC_11_40_120 — LVMC-11-40-120

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (boilerplate): Whenever a
    s2 (standard): usable
    s3 (condition): path for bicycles, electric bicycles, or electric scooters has been provided
    s4 (condition): adjacent to a roadway
    s5 (subject): riders of bicycles, electric bicycles, and electric scooters
    s6 (obligation): shall use such path and shall not use the roadway

  Elements (span → atoms, derived):
    s3: atoms ['st.bicycle_lane_or_path', 'st.on_way', 'st.highway'], derived []
    s4: atoms ['st.on_way', 'st.roadway', 'st.highway'], derived []
    s5: atoms ['ru.aggregate=DEF-NRS-484A-025::bicycle', 'ru.aggregate=DEF-LVMC-11-02-082::electric_bicycle', 'ru.aggregate=DEF-LVMC-11-02-083::electric_scooter'], derived []
    s6: atoms ['rel.occupies', 'st.roadway', 'st.lane', 'st.bicycle_lane_or_path'], derived ['drv.motion.moving_across_carrier', 'drv.motion.complete_halt']

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.LVMC_11_40_120

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"
def pRiderCrossingMotionCos : Term := .param "p.rider_crossing_motion_cos"
def pUsablePathWidthMin : Term := .param "p.usable_path_width_min"

def zeroMetres : Term := .lit Q.zero .metre

/-
  How each span is written.
    s5: the subject's class is the disjunction of the three admitted aggregates (`ru_aggregate`
        with the aggregate id). 'riders' (agency, the plan's observable reading): the subject is in
        controlled motion, not `drv_motion_complete_halt` at p.halt_speed_tolerance.
    s3: a `bicycle_lane_or_path` region p lying on a `highway` region h (`st_on_way p h`); its
        presence on the map is 'has been provided' (the plan's status reading).
    s2: p is usable (`usablePath`): `st_lane_width p ≥ p.usable_path_width_min`, no
        `regulatory_sign` of code closed_to_traffic or bicycles_prohibited governs p, and no
        `temporary_traffic_control` governs p (`dev_governs`).
    s4: a `roadway` region lies on the same h (`st_on_way r h`).
    Applicability: the moving subject occupies a roadway or a bicycle lane or path lying on such h.
    s6: re-binding h (every highway) and p with the whole selection: where the subject occupies a
        roadway lying on h, a usable path lies on h, and the subject occupies no usable path on h,
        it moves across (`drv_motion_moving_across_carrier`, p.halt_speed_tolerance,
        p.rider_crossing_motion_cos) a lane it occupies or a roadway on h it occupies; else
        violated. On the path the premise fails: compliant.
  Choices the record left open: none beyond the record's own narrowings. Region kinds are written
  as quantifier kinds (`existsRegion (.lit "roadway")` etc.), which reads the kind atoms.
-/

def vH : Arg := .var "h"
def vP : Arg := .var "p"
def vR : Arg := .var "r"
def vL : Arg := .var "l"
def vD : Arg := .var "d"

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-025::bicycle, ru.aggregate=DEF-LVMC-11-02-082::electric_bicycle, ru.aggregate=DEF-LVMC-11-02-083::electric_scooter -/
def clsSubject : Formula :=
  .or (.atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-025::bicycle"] [])
    (.or (.atom "ru_aggregate" [vSubject, .lit "DEF-LVMC-11-02-082::electric_bicycle"] [])
      (.atom "ru_aggregate" [vSubject, .lit "DEF-LVMC-11-02-083::electric_scooter"] []))

/-- s5 (agency): the rider in controlled motion. -/
def moving : Formula :=
  .not (.derived "drv_motion_complete_halt" [vSubject] [pHaltSpeedTolerance])

/-- s2: the path `pv` is usable — wide enough and closed by no device. -/
def usablePath (pv : Arg) : Formula :=
  .and (.cmp (.measure "st_lane_width" [pv]) .ge pUsablePathWidthMin)
    (.and
      (.not (.existsDevice (.lit "regulatory_sign") "d"
        (.and (.atom "dev_governs" [vD, pv] [])
          (.or (.atom "dev_regulatory_sign_code" [vD, .lit "closed_to_traffic"] [])
            (.atom "dev_regulatory_sign_code" [vD, .lit "bicycles_prohibited"] [])))))
      (.not (.existsDevice (.lit "temporary_traffic_control") "d"
        (.atom "dev_governs" [vD, pv] []))))

/-- s3 + s2: a usable bicycle lane or path lies on h. -/
def usablePathOn : Formula :=
  .existsRegion (.lit "bicycle_lane_or_path") "p"
    (.and (.atom "st_on_way" [vP, vH] []) (usablePath vP))

/-- s4: a roadway lies on h. -/
def roadwayOn : Formula :=
  .existsRegion (.lit "roadway") "r" (.atom "st_on_way" [vR, vH] [])

/-- The subject occupies a roadway lying on h. -/
def onRoadway : Formula :=
  .existsRegion (.lit "roadway") "r"
    (.and (.atom "st_on_way" [vR, vH] []) (.atom "rel_occupies" [vSubject, vR] []))

/-- The subject occupies a bicycle lane or path lying on h. -/
def onPathOfH : Formula :=
  .existsRegion (.lit "bicycle_lane_or_path") "p"
    (.and (.atom "st_on_way" [vP, vH] []) (.atom "rel_occupies" [vSubject, vP] []))

/-- The subject occupies a usable path lying on h. -/
def onUsablePath : Formula :=
  .existsRegion (.lit "bicycle_lane_or_path") "p"
    (.and (.atom "st_on_way" [vP, vH] [])
      (.and (usablePath vP) (.atom "rel_occupies" [vSubject, vP] [])))

/-- s6: the subject moves across a lane it occupies or a roadway on h it occupies. -/
def crossing : Formula :=
  .or
    (.existsRegion (.lit "lane") "l"
      (.and (.atom "rel_occupies" [vSubject, vL] [])
        (.derived "drv_motion_moving_across_carrier" [vSubject, vL] [pHaltSpeedTolerance, pRiderCrossingMotionCos])))
    (.existsRegion (.lit "roadway") "r"
      (.and (.atom "st_on_way" [vR, vH] [])
        (.and (.atom "rel_occupies" [vSubject, vR] [])
          (.derived "drv_motion_moving_across_carrier" [vSubject, vR] [pHaltSpeedTolerance, pRiderCrossingMotionCos]))))

/-- Applicability: s3 (condition): path for bicycles, electric bicycles, or electric scooters has been provided; s4 (condition): adjacent to a roadway -/
def applicability : Formula :=
  .and moving
    (.existsRegion (.lit "highway") "h"
      (.and (.or onRoadway onPathOfH)
        (.and usablePathOn roadwayOn)))

/-- Obligation: s2 (standard): usable; s6 (obligation): shall use such path and shall not use the roadway -/
def obligation : Formula :=
  .forallRegion (.lit "highway") "h"
    (.implies
      (.and onRoadway (.and usablePathOn (.not onUsablePath)))
      crossing)

def rule : Rule :=
  { id := "LVMC_11_40_120"
    laws := ["LVMC-11-40-120"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations :=
      [ { standard := "usable"
          concepts := ["dev.governs", "dev.regulatory_sign", "dev.temporary_traffic_control", "st.lane_width"]
          params := ["p.usable_path_width_min"]
          convention := "A bicycle path is usable where its width (st.lane_width) is at least the operating width of one rider, p.usable_path_width_min (AASHTO Guide for the Development of Bicycle Facilities), and no device closes it: no dev.regulatory_sign of code closed_to_traffic or bicycles_prohibited and no dev.temporary_traffic_control governs it (dev.governs)."
          surrogate := false } ]
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []  -- one { span := "<span id>", why := "<why>", kind := "reading" } per reading you chose on a carried span (kind no_atom / no_operator where the words cannot be stated), explained in the header; the record's own narrowings are not restated
    surrogate := false }

end TrafficSpec.Rules.LVMC_11_40_120
