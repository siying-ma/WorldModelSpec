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

  How each span is written:
    d5: the binder class, `ru_aggregate(subject, DEF-NRS-484A-320::vehicle)`.
    d2: `existsRegion intersection j` with `rel_occupies(subject, j)` at the judged observation.
    d4: the approach is fixed by the entry into j: `since (occupies j) (¬ occupies j ∧ …)` selects
        the last observation before the subject's occupancy of j rose (since's ψ is read at that
        observation, its φ at every later one up to now). At that observation the last one hundred
        feet of path (`holdsFor .path (100 ft) subject`, the `.path` window reading
        kin.path_length) are searched for an observation at which the view was not clear:
        `¬ holdsFor .path 100ft subject (¬ unclear)`. No path length since the trace start is read.
    d6: `st_sight_distance(j) < st_region_geometry_distance(subject, j)`. The sight-distance atom
        is a region's; the only region the element claims is the intersection, so the sight
        distance read is j's (what can be seen from or at j), compared with the subject's ground
        distance to j.
    d8: some way w (`existsRegion highway w`, `st_on_way(j, w)`) with
        `st_sight_along_way(subject, w) < 100 ft`.
    d7: some way v with `st_on_way(j, v)` and some road user o, other than the subject, member of
        DEF-NRS-484A-285::traffic, occupying v, within 100 ft of j
        (`st_region_geometry_distance(o, j) ≤ 100 ft`), and not `rel_visible(subject, o)`.
        d6, d7, d8 are the three ways the view fails: their disjunction is `unclear`.
    d9: at the same pre-entry observation: some travel region c the subject occupies with
        `st_lane_enters(c, j)` governed by no stop sign, no yield sign and no traffic signal
        showing flashing_red, and some travel region e with `st_lane_enters(e, j)` governed by one
        of them. With one approach carrier per witness the existential choice of c is the
        record's "the carrier it occupied".
    d10: at the judged observation: some travel region k that is j itself (`same k j`) or enters
        j (`st_lane_enters(k, j)`) is governed by a traffic signal not showing dark, a stop sign
        or a yield sign.
    d1: the obligation, `kin_speed(subject) ≤ 15 mph`, judged at every observation at which the
        applicability (subject in j) holds; it names no region.
    d3: the record's residue.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.LVMC_11_16_040

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

def zeroMetres : Term := .lit Q.zero .metre

/-- d1: fifteen miles per hour. -/
def fifteenMph : Term := .lit (Units.mph 15) .metrePerSecond
/-- d4, d8: one hundred feet. -/
def hundredFeet : Term := .lit (Units.feet 100) .metre

def vJ : Arg := .var "j"

/-- The subject occupies the intersection j (d2, d4). -/
def inJ : Formula := .atom "rel_occupies" [vSubject, vJ] []

/-- d6: the sight distance at j is shorter than the subject's ground distance to j. -/
def viewOfJunctionBlocked : Formula :=
  .cmp (.measure "st_sight_distance" [vJ]) .lt (.measure "st_region_geometry_distance" [vSubject, vJ])

/-- d8: along some way entering j the subject sees less than one hundred feet. -/
def sightAlongWayShort : Formula :=
  .existsRegion (.lit "highway") "w"
    (.and (.atom "st_on_way" [vJ, .var "w"] [])
      (.cmp (.measure "st_sight_along_way" [vSubject, .var "w"]) .lt hundredFeet))

/-- d7: some traffic upon a way entering j, within one hundred feet of j, is not visible. -/
def trafficHidden : Formula :=
  .existsRegion (.lit "highway") "v"
    (.and (.atom "st_on_way" [vJ, .var "v"] [])
      (.existsUser "o"
        (.and (.not (.same (.var "o") vSubject))
          (.and (.atom "ru_aggregate" [.var "o", .lit "DEF-NRS-484A-285::traffic"] [])
            (.and (.atom "rel_occupies" [.var "o", .var "v"] [])
              (.and (.cmp (.measure "st_region_geometry_distance" [.var "o", vJ]) .le hundredFeet)
                (.not (.atom "rel_visible" [vSubject, .var "o"] []))))))))

/-- d6 ∨ d7 ∨ d8: the view is not clear at an observation. -/
def viewNotClear : Formula :=
  .or viewOfJunctionBlocked (.or trafficHidden sightAlongWayShort)

/-- A travel region governed by a stop sign, a yield sign or a flashing-red signal (d9). -/
def throughControl (r : String) (sfx : String) : Formula :=
  .or (.existsDevice (.lit "stop_sign") ("ds" ++ sfx) (.atom "dev_governs" [.var ("ds" ++ sfx), .var r] []))
    (.or (.existsDevice (.lit "yield_sign") ("dy" ++ sfx) (.atom "dev_governs" [.var ("dy" ++ sfx), .var r] []))
      (.existsDevice (.lit "traffic_signal") ("dt" ++ sfx)
        (.and (.atom "dev_traffic_signal_shows" [.var ("dt" ++ sfx), .lit "flashing_red"] [])
          (.atom "dev_governs" [.var ("dt" ++ sfx), .var r] []))))

/-- d9: the subject's approach carrier is ungoverned by a stop, yield or flashing-red control
    while another carrier entering j is governed by one. -/
def throughStreet : Formula :=
  .and
    (.existsRegion (.lit "travel_region") "c"
      (.and (.atom "rel_occupies" [vSubject, .var "c"] [])
        (.and (.atom "st_lane_enters" [.var "c", vJ] [])
          (.not (throughControl "c" "A")))))
    (.existsRegion (.lit "travel_region") "e"
      (.and (.atom "st_lane_enters" [.var "e", vJ] [])
        (throughControl "e" "B")))

/-- d10: a signal not dark, a stop sign or a yield sign governs j or a carrier entering j. -/
def trafficControlled : Formula :=
  .existsRegion (.lit "travel_region") "k"
    (.and (.or (.same (.var "k") vJ) (.atom "st_lane_enters" [.var "k", vJ] []))
      (.or (.existsDevice (.lit "traffic_signal") "ts"
              (.and (.not (.atom "dev_traffic_signal_shows" [.var "ts", .lit "dark"] []))
                (.atom "dev_governs" [.var "ts", .var "k"] [])))
        (.or (.existsDevice (.lit "stop_sign") "ss" (.atom "dev_governs" [.var "ss", .var "k"] []))
          (.existsDevice (.lit "yield_sign") "ys" (.atom "dev_governs" [.var "ys", .var "k"] [])))))

/-- d4 with d6–d8 and d9: at the last observation before the subject entered j, the view was not
    clear somewhere in the last one hundred feet of path, and the approach was not a through
    street; the subject has occupied j at every observation since. -/
def approachUnclear : Formula :=
  .since inJ
    (.and (.not inJ)
      (.and (.not (.holdsFor .path hundredFeet "subject" (.not viewNotClear)))
        (.not throughStreet)))

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-320::vehicle"] []

/-- Applicability: d2 (trigger): when traversing any intersection; d3 (condition): or street or highway; d4 (condition): if during the last one hundred feet of his approach to such intersection; d6 (condition): does not have a clear and unobstructed view of such intersection; d7 (condition): and of any traffic upon all of the streets or highways entering such intersection; d8 (condition): for a distance of one hundred feet along all such streets or highways; d9 (exception): except on a through street or highway; d10 (exception): or at a traffic-controlled intersection -/
def applicability : Formula :=
  .existsRegion (.lit "intersection") "j"
    (.and inJ (.and approachUnclear (.not trafficControlled)))

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
