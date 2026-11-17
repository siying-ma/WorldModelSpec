/-
  LVMC_11_60_030_A4 — LVMC-11-60-030-A4

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    c1 (subject): The operator of a bus,
    c2 (exception): other than a tour bus,
    c3 (condition): shall: Enter a bus stop, bus stand, passenger loading zone or origin or destination point
    c4 (condition): on a public street
    c5 (trigger): in such a manner that the bus when stopped to load or unload passengers or baggage
    c6 (obligation): shall be in a position with the right-hand front wheel of such vehicle not farther than eighteen inches from the curb
    c7 (standard): and the bus approximately parallel to the curb so as not to unduly impede the movement of other vehicular traffic.

  Elements (span → atoms, derived):
    c1: atoms ['ru.aggregate=DEF-NRS-484A-030::bus'], derived []
    c2: atoms ['ru.aggregate=DEF-LVMC-11-02-150::tour_bus'], derived []
    c3: atoms ['st.curb_zone', 'st.transit_stop', 'rel.occupies'], derived []
    c4: atoms ['rel.occupies', 'st.highway'], derived []
    c5: atoms ['sig.door_open'], derived ['drv.motion.complete_halt']
    c6: atoms ['st.road_edge', 'st.region_geometry', 'prim.region_lateral_offset'], derived []

  Literals the text states (each written through its Units constructor):
    c6: 18 in — eighteen inches

  How each span is written:
    c1: binder class ru_aggregate(subject, DEF-NRS-484A-030::bus).
    c2: ¬ ru_aggregate(subject, DEF-LVMC-11-02-150::tour_bus) in the applicability.
    c3: the subject occupies some transit_stop, or some curb_zone of kind bus_stop or
        passenger_loading (one leaf per enumeration, written as the record maps them).
    c4: the subject occupies some highway region.
    c5: drv_motion_complete_halt(subject; p.halt_speed_tolerance) ∧ sig_door_open(subject) — any
        door, as the applicability states "a door open".
    c6: some road_edge with st_region_geometry_distance(subject, edge) ≤ 18 in and
        prim_region_lateral_offset(subject, edge) < 0 (on the right).
    c7: some travel_region the subject occupies with |heading · lane_direction| ≥
        p.curb_parallel_cos; both vectors are read normalised, so the dot product is the cosine.
  No choice beyond the record's own narrowings was made.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.LVMC_11_60_030_A4

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pCurbParallelCos : Term := .param "p.curb_parallel_cos"
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"

def zeroMetres : Term := .lit Q.zero .metre

/-- c6: the stated eighteen inches. -/
def eighteenInches : Term := .lit (Units.inches 18) .metre

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-030::bus -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-030::bus"] []

/-- c2: other than a tour bus. -/
def notTourBus : Formula :=
  .not (.atom "ru_aggregate" [vSubject, .lit "DEF-LVMC-11-02-150::tour_bus"] [])

/-- c3: the subject's footprint overlaps a bus stop (st.transit_stop), or a posted bus zone or
    passenger loading zone (st.curb_zone of kind bus_stop or passenger_loading). -/
def inStopPlace : Formula :=
  .or
    (.existsRegion (.lit "transit_stop") "stop"
      (.atom "rel_occupies" [vSubject, .var "stop"] []))
    (.existsRegion (.lit "curb_zone") "zone"
      (.and (.atom "rel_occupies" [vSubject, .var "zone"] [])
        (.or (.atom "st_curb_zone_kind" [.var "zone", .lit "bus_stop"] [])
             (.atom "st_curb_zone_kind" [.var "zone", .lit "passenger_loading"] []))))

/-- c4: on a public street — the subject's footprint overlaps a highway. -/
def onStreet : Formula :=
  .existsRegion (.lit "highway") "street" (.atom "rel_occupies" [vSubject, .var "street"] [])

/-- c5: stopped (drv.motion.complete_halt) with a door open (sig.door_open, either side). -/
def stoppedToLoad : Formula :=
  .and (.derived "drv_motion_complete_halt" [vSubject] [pHaltSpeedTolerance])
       (.atom "sig_door_open" [vSubject] [])

/-- Applicability: c2 (exception): other than a tour bus,; c3 (condition): shall: Enter a bus stop, bus stand, passenger loading zone or origin or destination point; c4 (condition): on a public street; c5 (trigger): in such a manner that the bus when stopped to load or unload passengers or baggage -/
def applicability : Formula :=
  .and notTourBus (.and inStopPlace (.and onStreet stoppedToLoad))

/-- c6: some road edge on the subject's right (lateral offset negative) within eighteen inches of
    its body outline. -/
def nearCurbOnRight : Formula :=
  .existsRegion (.lit "road_edge") "curb"
    (.and
      (.cmp (.measure "st_region_geometry_distance" [vSubject, .var "curb"]) .le eighteenInches)
      (.cmp (.quantity "prim_region_lateral_offset" [vSubject, .var "curb"] []) .lt zeroMetres))

/-- c7: for some travel region the subject occupies, |cos(heading, designated direction)| is at
    least p.curb_parallel_cos (dot product of the two normalised vectors). -/
def parallelToCurb : Formula :=
  .existsRegion (.lit "travel_region") "carrier"
    (.and (.atom "rel_occupies" [vSubject, .var "carrier"] [])
      (.cmp
        (.abs (.add
          (.mul (.measure "kin_heading" [vSubject, .lit "x"]) (.measure "st_lane_direction" [.var "carrier", .lit "x"]))
          (.mul (.measure "kin_heading" [vSubject, .lit "y"]) (.measure "st_lane_direction" [.var "carrier", .lit "y"]))))
        .ge pCurbParallelCos))

/-- Obligation: c6 (obligation): shall be in a position with the right-hand front wheel of such vehicle not farther than eighteen inches from the curb; c7 (standard): and the bus approximately parallel to the curb so as not to unduly impede the movement of other vehicular traffic. -/
def obligation : Formula := .and nearCurbOnRight parallelToCurb

def rule : Rule :=
  { id := "LVMC_11_60_030_A4"
    laws := ["LVMC-11-60-030-A4"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations :=
      [ { standard := "approximately parallel to the curb so as not to unduly impede the movement of other vehicular traffic"
          concepts := ["kin.heading", "rel.occupies", "st.lane_direction", "st.travel_region"]
          params := ["p.curb_parallel_cos"]
          convention := "the bus counts as approximately parallel to the curb, and so not projecting across the adjacent travel lane, where the absolute cosine between its heading (kin.heading) and the designated direction (st.lane_direction) of a travel region it occupies (rel.occupies, st.travel_region), whose carriers run along the curb, is at least p.curb_parallel_cos, the bus-stop alignment tolerance of transit stop design guidance"
          surrogate := false } ]
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []  -- one { span := "<span id>", why := "<why>", kind := "reading" } per reading you chose on a carried span (kind no_atom / no_operator where the words cannot be stated), explained in the header; the record's own narrowings are not restated
    surrogate := false }

end TrafficSpec.Rules.LVMC_11_60_030_A4
