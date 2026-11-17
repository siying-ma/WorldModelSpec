/-
  LVMC_11_16_040 — LVMC-11-16-040

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    d1 (obligation): The prima facie speed limit shall be fifteen miles per hour
    d2 (trigger): when traversing any intersection
    d3 (condition): or street or highway
    d4 (condition): if during the last one hundred feet of his approach to such intersection
    d5 (subject): the driver
    d6 (condition): does not have a clear and unobstructed view of such intersection
    d7 (condition): and of any traffic upon all of the streets or highways entering such intersection
    d8 (condition): for a distance of one hundred feet along all such streets or highways
    d9 (exception): except on a through street or highway
    d10 (exception): or at a traffic-controlled intersection

  Elements (span → atoms, derived):
    d1: atoms ['kin.speed'], derived []
    d2: atoms ['rel.occupies', 'st.intersection'], derived []
    d4: atoms ['kin.path_length', 'rel.occupies', 'st.intersection'], derived []
    d5: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    d6: atoms ['st.sight_distance', 'st.region_geometry', 'st.intersection'], derived []
    d7: atoms ['ru.aggregate=DEF-NRS-484A-285::traffic', 'rel.visible', 'rel.occupies', 'st.on_way', 'st.highway', 'st.region_geometry'], derived []
    d8: atoms ['st.sight_along_way', 'st.on_way', 'st.highway'], derived []
    d9: atoms ['dev.stop_sign', 'dev.yield_sign', 'dev.traffic_signal', 'dev.governs', 'st.lane_enters', 'rel.occupies', 'st.travel_region'], derived []
    d10: atoms ['dev.traffic_signal', 'dev.stop_sign', 'dev.yield_sign', 'dev.governs', 'st.lane_enters', 'st.travel_region', 'st.intersection'], derived []

  Literals the text states (each written through its Units constructor):
    d1: 15 mph — fifteen miles per hour
    d4: 100 ft — one hundred feet
    d8: 100 ft — one hundred feet

  How each span is written.
    d5: the binder class is `ru_aggregate subject DEF-NRS-484A-320::vehicle`.
    d2: some intersection j (region quantifier of kind `intersection`) with `rel_occupies subject j`
        at the judged observation, held continuously since the observation at which it rose
        (`since occ (rises occ ∧ …)`): the conditions are judged once, at that entry.
    d4: at the entry observation, `holdsFor .path (100 ft) subject viewClear` fails: the window is
        the last one hundred feet of the subject's own path (kin.path_length through the `.path`
        measure), ending at the entry; the view was not clear at some observation of it.
    d6: viewOfJClear — `st_sight_distance j ≥ st_region_geometry_distance subject j`; the only
        region the element claims whose sight distance can be read is j itself.
    d7: for every highway w with `st_on_way j w`, every road user o other than the subject that is
        traffic (`ru_aggregate o DEF-NRS-484A-285::traffic`), occupies w and lies within one
        hundred feet of j (`st_region_geometry_distance o j`) is `rel_visible subject o`. The
        subject itself is not among the traffic it views (`.not (.same o subject)`).
    d8: for every such w, `st_sight_along_way subject w ≥ 100 ft`.
    d9: read at the last observation of the 100 ft approach window at which the subject did not
        occupy j (`atLast .path (100 ft) subject (¬occ j)`), i.e. the observation before entry:
        the subject occupies some carrier c entering j (st_lane_enters), no carrier it occupies
        that enters j is governed by a stop sign, a yield sign or a traffic signal showing
        flashing_red (so no carrier is picked in the subject's favour), and some carrier c2
        entering j is governed by one of them.
    d10: at the judged observation, a traffic signal not showing `dark`, a stop sign or a yield
        sign governs j itself or a travel region c with `st_lane_enters c j`.
    d1: obligation `kin_speed subject ≤ 15 mph` at every observation the applicability selects,
        which are exactly the observations at which the subject occupies j.
    d3: residue (the node's).

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.LVMC_11_16_040

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

def zeroMetres : Term := .lit Q.zero .metre

def vJ : Arg := .var "j"
def vW : Arg := .var "w"
def vO : Arg := .var "o"
def vC : Arg := .var "c"
def vC2 : Arg := .var "c2"
def vCe : Arg := .var "ce"
def vD : Arg := .var "d"

/-- d1: fifteen miles per hour. -/
def fifteenMph : Term := .lit (Units.mph 15) .metrePerSecond
/-- d4 / d8: one hundred feet. -/
def hundredFeet : Term := .lit (Units.feet 100) .metre

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-320::vehicle"] []

/-- d2: the subject's footprint overlaps the intersection j. -/
def occupiesJ : Formula := .atom "rel_occupies" [vSubject, vJ] []

/-- d6: the sight distance of j reaches the subject's ground distance to j. -/
def viewOfJClear : Formula :=
  .cmp (.measure "st_sight_distance" [vJ]) .ge (.measure "st_region_geometry_distance" [vSubject, vJ])

/-- d8: sight along the way w is at least one hundred feet. -/
def sightAlongWayClear : Formula :=
  .cmp (.measure "st_sight_along_way" [vSubject, vW]) .ge hundredFeet

/-- d7: every traffic member upon w within one hundred feet of j is visible from the subject. -/
def trafficOnWayVisible : Formula :=
  .forallUser "o"
    (.implies
      (.and (.not (.same vO vSubject))
        (.and (.atom "ru_aggregate" [vO, .lit "DEF-NRS-484A-285::traffic"] [])
          (.and (.atom "rel_occupies" [vO, vW] [])
            (.cmp (.measure "st_region_geometry_distance" [vO, vJ]) .le hundredFeet))))
      (.atom "rel_visible" [vSubject, vO] []))

/-- d6 ∧ d7 ∧ d8 at one observation: the view is clear. -/
def viewClear : Formula :=
  .and viewOfJClear
    (.forallRegion (.lit "highway") "w"
      (.implies (.atom "st_on_way" [vJ, vW] [])
        (.and sightAlongWayClear trafficOnWayVisible)))

/-- d4: at some observation of the last one hundred feet of the approach the view was not clear. -/
def viewRestrictedOnApproach : Formula :=
  .not (.holdsFor .path hundredFeet "subject" viewClear)

/-- d9: a carrier region `r` is governed by a stop sign, a yield sign or a flashing-red signal. -/
def throughControl (r : Arg) : Formula :=
  .or (.existsDevice (.lit "stop_sign") "d" (.atom "dev_governs" [vD, r] []))
    (.or (.existsDevice (.lit "yield_sign") "d" (.atom "dev_governs" [vD, r] []))
      (.existsDevice (.lit "traffic_signal") "d"
        (.and (.atom "dev_traffic_signal_shows" [vD, .lit "flashing_red"] [])
          (.atom "dev_governs" [vD, r] []))))

/-- d9 at one observation: the subject approaches through a carrier entering j, none of the
    carriers it occupies that enter j is so governed, and another carrier entering j is. -/
def throughStreet : Formula :=
  .and
    (.existsRegion (.lit "travel_region") "ce"
      (.and (.atom "rel_occupies" [vSubject, vCe] []) (.atom "st_lane_enters" [vCe, vJ] [])))
    (.and
      (.forallRegion (.lit "travel_region") "c"
        (.implies
          (.and (.atom "rel_occupies" [vSubject, vC] []) (.atom "st_lane_enters" [vC, vJ] []))
          (.not (throughControl vC))))
      (.existsRegion (.lit "travel_region") "c2"
        (.and (.atom "st_lane_enters" [vC2, vJ] []) (throughControl vC2))))

/-- d9 read at the last observation before entry into j. -/
def throughAtEntry : Formula :=
  .atLast .path hundredFeet "subject" (.not occupiesJ) throughStreet

/-- d10: the device `d` governs j or a carrier entering j. -/
def controlsJ : Formula :=
  .or (.atom "dev_governs" [vD, vJ] [])
    (.existsRegion (.lit "travel_region") "c"
      (.and (.atom "st_lane_enters" [vC, vJ] []) (.atom "dev_governs" [vD, vC] [])))

/-- d10: a traffic-controlled intersection. -/
def trafficControlled : Formula :=
  .or (.existsDevice (.lit "traffic_signal") "d"
        (.and (.not (.atom "dev_traffic_signal_shows" [vD, .lit "dark"] [])) controlsJ))
    (.or (.existsDevice (.lit "stop_sign") "d" controlsJ)
      (.existsDevice (.lit "yield_sign") "d" controlsJ))

/-- Applicability: d2 (trigger): when traversing any intersection; d3 (condition): or street or highway; d4 (condition): if during the last one hundred feet of his approach to such intersection; d6 (condition): does not have a clear and unobstructed view of such intersection; d7 (condition): and of any traffic upon all of the streets or highways entering such intersection; d8 (condition): for a distance of one hundred feet along all such streets or highways; d9 (exception): except on a through street or highway; d10 (exception): or at a traffic-controlled intersection -/
def applicability : Formula :=
  .existsRegion (.lit "intersection") "j"
    (.and
      (.since occupiesJ
        (.and (.rises occupiesJ)
          (.and viewRestrictedOnApproach (.not throughAtEntry))))
      (.not trafficControlled))

/-- Obligation: d1 (obligation): The prima facie speed limit shall be fifteen miles per hour -/
def obligation : Formula :=
  .cmp (.measure "kin_speed" [vSubject]) .le fifteenMph

def rule : Rule :=
  { id := "LVMC_11_16_040"
    laws := ["LVMC-11-16-040"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations := []
    residues := ["every intersection is, by DEF-NRS-484A-105, a junction of highways and streets; the words add no region beyond the intersection whose approach the condition measures, so the duty is the same whether or not they are read"]  -- the node's, verbatim; not yours to change
    narrowings := []
    surrogate := false }

end TrafficSpec.Rules.LVMC_11_16_040
