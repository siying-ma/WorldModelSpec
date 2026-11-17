/-
  LVMC_11_52_060 — LVMC-11-52-060

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (subject): In no case shall any part of any vehicle
    s2 (subject): part of the load of such vehicle
    s3 (subject): or trailer
    s4 (condition): attached to such vehicle
    s5 (obligation): project into the street more than fifteen feet measured on a line at right angles to the curb.

  Elements (span → atoms, derived):
    s1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle', 'kin.extent'], derived []
    s3: atoms ['ru.aggregate=DEF-LVMC-11-02-170::trailer'], derived []
    s2: atoms ['kin.extent'], derived []
    s5: atoms ['rel.occupies', 'st.highway', 'st.road_edge', 'st.region_geometry', 'st.on_way', 'kin.heading', 'kin.extent', 'st.lane_direction', 'st.travel_region'], derived ['drv.motion.parked']

  Literals the text states (each written through its Units constructor):
    s5: 15 ft — fifteen feet

  No magnitude below is this file's own: parameters name the reading, literals are the text's.

  How each span is written:
    s1, s3: the binder class is ru_aggregate on the subject with either admitted aggregate id.
    s1, s2: "any part of the vehicle / its load" is the body outline the source reports: the full
      length and width read from kin_extent enter the projection; no load beyond it is seen (the
      record's narrowing).
    s4: residue, no formula.
    s5: applicability — drv_motion_parked(subject; p.halt_speed_tolerance, p.parking_min_duration)
      and some highway h (quantifier kind "highway") with rel_occupies subject h.
      obligation — for every highway h the subject occupies, every road edge c lying on h
      (st_on_way c h) whose st_region_geometry_distance from the body is at most that of every
      road edge lying on h (the curb it stands at), and every travel region r it occupies: the
      distance to c + length·|heading × dir(r)| + width·|heading · dir(r)| ≤ 15 ft (Units.feet 15).
      The heading and direction are read normalised by Core; the absolute values make the sign
      of the direction irrelevant. Where r has no direction, or a heading, extent or distance is
      unobserved, the comparison is unknown.
  Choices the record left open: none beyond the record's own narrowings (the curb as the nearest
  road edge of the street, its line as the occupied travel region's direction, "every" over
  highways, nearest curbs and travel regions as the record states). No narrowing of this file's own.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.LVMC_11_52_060

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"
def pParkingMinDuration : Term := .param "p.parking_min_duration"

def zeroMetres : Term := .lit Q.zero .metre

/-- s5: "fifteen feet", the text's figure. -/
def fifteenFeet : Term := .lit (Units.feet 15) .metre

def vH : Arg := .var "h"
def vC : Arg := .var "c"
def vC' : Arg := .var "c_other"
def vR : Arg := .var "r"

/-- Class of `subject` (s1, s3): ru.aggregate=DEF-NRS-484A-320::vehicle or
    ru.aggregate=DEF-LVMC-11-02-170::trailer, each claimed whole as an aggregate. -/
def clsSubject : Formula :=
  .or (.atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-320::vehicle"] [])
      (.atom "ru_aggregate" [vSubject, .lit "DEF-LVMC-11-02-170::trailer"] [])

/-- s5 "project into the street": the subject is parked (drv.motion.parked) and its footprint
    overlaps a highway (st.highway, rel.occupies). s4 is a residue: no restriction. -/
def applicability : Formula :=
  .and (.derived "drv_motion_parked" [vSubject] [pHaltSpeedTolerance, pParkingMinDuration])
       (.existsRegion (.lit "highway") "h" (.atom "rel_occupies" [vSubject, vH] []))

/-- Ground distance from the subject's body outline to road edge `x` (st.region_geometry). -/
def distTo (x : Arg) : Term := .measure "st_region_geometry_distance" [vSubject, x]

def hx : Term := .measure "kin_heading" [vSubject, .lit "x"]
def hy : Term := .measure "kin_heading" [vSubject, .lit "y"]
def dx : Term := .measure "st_lane_direction" [vR, .lit "x"]
def dy : Term := .measure "st_lane_direction" [vR, .lit "y"]

/-- The subject's full length and width (kin.extent): "any part of any vehicle" (s1) and the load
    within the reported outline (s2). -/
def bodyLength : Term := .measure "kin_extent" [vSubject, .lit "length"]
def bodyWidth : Term := .measure "kin_extent" [vSubject, .lit "width"]

/-- |heading × direction| and |heading · direction|: the share of the length and of the width that
    lies at right angles to the curb's line. -/
def absCross : Term := .abs (.sub (.mul hx dy) (.mul hy dx))
def absDot : Term := .abs (.add (.mul hx dx) (.mul hy dy))

/-- The projection into the street measured at right angles to curb `c` across region `r`. -/
def projection : Term :=
  .add (distTo vC) (.add (.mul bodyLength absCross) (.mul bodyWidth absDot))

/-- `c` is the curb the subject stands at: a road edge of street `h` no farther from the body than
    any other road edge of `h`. -/
def nearestCurb : Formula :=
  .and (.atom "st_on_way" [vC, vH] [])
       (.forallRegion (.lit "road_edge") "c_other"
          (.implies (.atom "st_on_way" [vC', vH] [])
                    (.cmp (distTo vC) .le (distTo vC'))))

/-- s5: for every street the subject occupies, the curb of it the subject stands at, and every
    travel region it occupies (whose designated direction gives the curb's line), the projection
    is at most fifteen feet. -/
def obligation : Formula :=
  .forallRegion (.lit "highway") "h"
    (.implies (.atom "rel_occupies" [vSubject, vH] [])
      (.forallRegion (.lit "road_edge") "c"
        (.implies nearestCurb
          (.forallRegion (.lit "travel_region") "r"
            (.implies (.atom "rel_occupies" [vSubject, vR] [])
              (.cmp projection .le fifteenFeet))))))

def rule : Rule :=
  { id := "LVMC_11_52_060"
    laws := ["LVMC-11-52-060"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations := []
    residues := ["A trailer is itself \"a vehicle\" by its definition DEF-LVMC-11-02-170, so the duty binds its body through \"any vehicle\" whether or not it is attached; attachment adds no restriction."]  -- the node's, verbatim; not yours to change
    narrowings := []  -- one { span := "<span id>", why := "<why>", kind := "reading" } per reading you chose on a carried span (kind no_atom / no_operator where the words cannot be stated), explained in the header; the record's own narrowings are not restated
    surrogate := false }

end TrafficSpec.Rules.LVMC_11_52_060
