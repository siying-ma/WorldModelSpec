/-
  NRS_484B_153_2 — NRS-484B-153-2

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    d1 (subject): A person
    d2 (obligation): shall not open the door of or board or alight from
    d3 (condition): the side of a vehicle which is closest to passing traffic
    d4 (standard): in such a manner as to interfere with
    d5 (condition): moving vehicular traffic.

  Elements (span → atoms, derived):
    d1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    d2: atoms ['sig.door_open'], derived []
    d3: atoms ['sig.door_open', 'ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    d5: atoms ['ru.aggregate=DEF-NRS-484A-285::traffic', 'ru.aggregate=DEF-NRS-484A-320::vehicle'], derived ['drv.motion.complete_halt']

  How each is written:
    d1, d3 (vehicle): the binder class `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`.
    d2, d3 (door on the side closest to passing traffic): the applicability
      `sig_door_open subject "traffic"` — the subject's traffic-side door is open.
    d5 (moving vehicular traffic): a road user `c` other than the subject (`not (same c subject)`)
      with `ru_aggregate c "DEF-NRS-484A-285::traffic"` and `ru_aggregate c "DEF-NRS-484A-320::vehicle"`,
      and not at rest: `not drv_motion_complete_halt(c; p.halt_speed_tolerance)`.
    d4 (interfere with): the operationalization — `rel_contact(subject, c)`, or
      `rel_longitudinal_overlap(subject, c) > 0` (the projections on the subject's heading share
      length) and the lateral component of `rel_surface_gap(subject, c)` at most p.door_swing_reach.
    Obligation: for every road user c of the scene, c is not such an interfered-with vehicle;
      violated where one is (the node's obligation).

  Choices the record left open: none beyond the record's words. "share length" is written as a
  strictly positive overlap (a projection touching end to end shares no length).

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_153_2

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The road user of the traffic the obligation quantifies over. -/
def vOther : Arg := .var "c"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pDoorSwingReach : Term := .param "p.door_swing_reach"
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"

def zeroMetres : Term := .lit Q.zero .metre

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-320::vehicle"] []

/-- Applicability: d3 (condition): the side of a vehicle which is closest to passing traffic; d5 (condition): moving vehicular traffic. -/
def applicability : Formula := .atom "sig_door_open" [vSubject, .lit "traffic"] []

/-- d5: `c` is moving vehicular traffic (traffic, a vehicle, not at rest), other than the subject. -/
def movingVehicularTraffic : Formula :=
  .and (.not (.same vOther vSubject))
    (.and (.atom "ru_aggregate" [vOther, .lit "DEF-NRS-484A-285::traffic"] [])
      (.and (.atom "ru_aggregate" [vOther, .lit "DEF-NRS-484A-320::vehicle"] [])
        (.not (.derived "drv_motion_complete_halt" [vOther] [pHaltSpeedTolerance]))))

/-- d4: `c` touches the subject, or passes alongside it within the open door's lateral reach. -/
def interferedWith : Formula :=
  .or (.atom "rel_contact" [vSubject, vOther] [])
    (.and (.cmp (.measure "rel_longitudinal_overlap" [vSubject, vOther]) .gt zeroMetres)
      (.cmp (.measure "rel_surface_gap" [vSubject, vOther, .lit "lateral"]) .le pDoorSwingReach))

/-- Obligation: d2 (obligation): shall not open the door of or board or alight from; d4 (standard): in such a manner as to interfere with -/
def obligation : Formula :=
  .forallUser "c" (.not (.and movingVehicularTraffic interferedWith))

def rule : Rule :=
  { id := "NRS_484B_153_2"
    laws := ["NRS-484B-153-2"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations :=
      [ { standard := "in such a manner as to interfere with"
          concepts := ["rel.contact", "rel.longitudinal_overlap", "rel.surface_gap"]
          params := ["p.door_swing_reach"]
          convention := "While the traffic-side door is open, a moving vehicle of the traffic is interfered with where it touches the subject (rel.contact) or passes alongside it (rel.longitudinal_overlap: the two projections on the subject's heading share length) with a lateral body gap (rel.surface_gap, lateral component) no greater than the lateral reach of an open side door, p.door_swing_reach: it then drives through the space the open door takes."
          surrogate := false } ]
    residues := []
    narrowings := []
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_153_2
