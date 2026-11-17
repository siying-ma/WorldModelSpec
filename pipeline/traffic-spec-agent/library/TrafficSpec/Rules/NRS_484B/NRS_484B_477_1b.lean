/-
  NRS_484B_477_1b — NRS-484B-477-1b

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    b1 (condition): Unless otherwise provided by ordinance of the local authority having jurisdiction,
    b2 (subject): a person
    b3 (obligation): shall not: Stop, stand or park a vehicle
    b4 (condition): in any other
    b5 (condition): alley
    b6 (condition): in such a manner, or under such conditions as to leave available less than 10 feet of the width of the alley for the free movement of vehicular traffic.

  Elements (span → atoms, derived):
    b2: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    b3: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle', 'dev.governs', 'dev.traffic_signal', 'dev.stop_sign', 'dev.yield_sign', 'dev.railway_signal_or_gate', 'dev.human_direction', 'st.travel_region', 'rel.occupies', 'rel.ahead_behind_in_lane', 'rel.surface_gap', 'ru.aggregate=DEF-NRS-484A-285::traffic'], derived ['drv.motion.complete_halt']
    b5: atoms ['rel.occupies', 'st.alley'], derived []
    b6: atoms ['st.road_edge', 'st.region_geometry', 'prim.region_lateral_offset', 'st.obstruction', 'rel.bearing', 'rel.longitudinal_overlap', 'rel.surface_gap', 'ru.aggregate=DEF-NRS-484A-285::traffic', 'ru.aggregate=DEF-NRS-484A-320::vehicle'], derived ['drv.motion.complete_halt']

  Literals the text states (each written through its Units constructor):
    b6: 10 ft — 10 feet

  How each span is written:
    b2: the binder `subject`, of class ru_aggregate DEF-NRS-484A-320::vehicle (the person read
        through the vehicle, the record's observable reading).
    b1: `not (asm asm.local_alley_ordinance)`.
    b4: `not (asm asm.business_district)` — "any other" alley is one not in a business district.
    b5: some region of kind alley the subject occupies (rel_occupies).
    b6: neither side of the subject is free. A side (left: prim_region_lateral_offset > 0 and
        rel_bearing "left"; right: < 0 and rel_bearing "right") is free where some road edge lies on
        it, every road edge on it lies at st_region_geometry_distance ≥ 10 ft from the body, every
        obstruction on it lies ≥ 10 ft from the body, and every member of DEF-NRS-484A-285::traffic at
        rest (drv_motion_complete_halt) alongside (rel_longitudinal_overlap ≥ 0) on it has a lateral
        rel_surface_gap ≥ 10 ft. The two sides are never added. "Some road edge lies on it" is
        written as some road edge on it at ≥ 10 ft: equivalent under the conjunct that every edge on
        it is at ≥ 10 ft, and it ties the existential edge to the subject through
        st_region_geometry_distance (the lateral-offset primitive is not an anchoring relation). The subject itself is excluded from
        the road users alongside by the bearing (its bearing to itself is neither left nor right).
    b3: violated where the subject is at rest (drv_motion_complete_halt, p.halt_speed_tolerance) and
        its halt is not one in the stream of traffic: it occupies no travel region governed by a
        traffic signal, stop sign, yield sign, railway signal or gate, or person directing traffic,
        and no member of traffic is ahead of it in its lane (rel_ahead_behind_in_lane ahead→subject)
        with a gap between bodies (rel_surface_gap read without a component: the distance, as its
        contract states) at or below p.queue_halt_gap. The subject is excluded from "ahead" by the
        relation itself (no road user is ahead of itself).

  Choices the record left open: none beyond the above; no narrowing is declared.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_477_1b

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"
def pQueueHaltGap : Term := .param "p.queue_halt_gap"

def zeroMetres : Term := .lit Q.zero .metre

/-- b6: the text's 10 feet. -/
def tenFeet : Term := .lit (Units.feet 10) .metre

def aggVehicle : String := "DEF-NRS-484A-320::vehicle"
def aggTraffic : String := "DEF-NRS-484A-285::traffic"

/-- A member of DEF-NRS-484A-285::traffic. -/
def isTraffic (x : Arg) : Formula := .atom "ru_aggregate" [x, .lit aggTraffic] []

/-- At rest at the observation. -/
def atRest (x : Arg) : Formula := .derived "drv_motion_complete_halt" [x] [pHaltSpeedTolerance]

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, .lit aggVehicle] []

/-- b5: the subject occupies an alley. -/
def inAlley : Formula :=
  .existsRegion (.lit "alley") "alley" (.atom "rel_occupies" [vSubject, .var "alley"] [])

def sideName (left : Bool) : String := if left then "left" else "right"

/-- A region lies on the given side of the subject (sign of the lateral offset only). -/
def onSide (left : Bool) (r : Arg) : Formula :=
  .cmp (.quantity "prim_region_lateral_offset" [vSubject, r] [])
    (if left then CmpOp.gt else CmpOp.lt) zeroMetres

/-- A region lies at least 10 feet from the subject's body. -/
def clearOf (r : Arg) : Formula :=
  .cmp (.measure "st_region_geometry_distance" [vSubject, r]) .ge tenFeet

/-- b6: the side leaves at least 10 feet of the alley's width free. -/
def sideFree (left : Bool) : Formula :=
  let s := sideName left
  let e := "edge_" ++ s
  let eAll := "edgeEvery_" ++ s
  let o := "obstruction_" ++ s
  let u := "beside_" ++ s
  .and (.existsRegion (.lit "road_edge") e (.and (onSide left (.var e)) (clearOf (.var e))))
    (.and (.forallRegion (.lit "road_edge") eAll
            (.implies (onSide left (.var eAll)) (clearOf (.var eAll))))
      (.and (.forallRegion (.lit "obstruction") o
              (.implies (onSide left (.var o)) (clearOf (.var o))))
        (.forallUser u
          (.implies
            (.and (isTraffic (.var u))
              (.and (atRest (.var u))
                (.and (.cmp (.measure "rel_longitudinal_overlap" [vSubject, .var u]) .ge zeroMetres)
                  (.atom "rel_bearing" [vSubject, .var u, .lit s] []))))
            (.cmp (.measure "rel_surface_gap" [vSubject, .var u, .lit "lateral"]) .ge tenFeet)))))

/-- Applicability: b1 (condition): Unless otherwise provided by ordinance of the local authority having jurisdiction,; b4 (condition): in any other; b5 (condition): alley; b6 (condition): in such a manner, or under such conditions as to leave available less than 10 feet of the width of the alley for the free movement of vehicular traffic. -/
def applicability : Formula :=
  .and inAlley
    (.and (.not (.asm "asm.business_district"))
      (.and (.not (.asm "asm.local_alley_ordinance"))
        (.and (.not (sideFree true)) (.not (sideFree false)))))

/-- A device of the kind governs the region. -/
def governedBy (kind d : String) (r : Arg) : Formula :=
  .existsDevice (.lit kind) d (.atom "dev_governs" [.var d, r] [])

/-- b3 exception: the subject occupies a travel region governed by a control device or a person
    directing traffic. -/
def governedHalt : Formula :=
  let r : Arg := .var "travel"
  .existsRegion (.lit "travel_region") "travel"
    (.and (.atom "rel_occupies" [vSubject, r] [])
      (.or (governedBy "traffic_signal" "signal" r)
        (.or (governedBy "stop_sign" "stopSign" r)
          (.or (governedBy "yield_sign" "yieldSign" r)
            (.or (governedBy "railway_signal_or_gate" "railway" r)
              (governedBy "human_direction" "director" r))))))

/-- b3 exception: a member of traffic ahead in the subject's lane within the queue spacing. -/
def queueHalt : Formula :=
  let a : Arg := .var "ahead"
  .existsUser "ahead"
    (.and (isTraffic a)
      (.and (.atom "rel_ahead_behind_in_lane" [a, vSubject] [])
        (.cmp (.measure "rel_surface_gap" [vSubject, a]) .le pQueueHaltGap)))

/-- Obligation: b3 (obligation): shall not: Stop, stand or park a vehicle -/
def obligation : Formula :=
  .not (.and (atRest vSubject) (.not (.or governedHalt queueHalt)))

def rule : Rule :=
  { id := "NRS_484B_477_1b"
    laws := ["NRS-484B-477-1b"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := ["asm.local_alley_ordinance", "asm.business_district"]
    intentions := []
    operationalizations := []
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_477_1b
