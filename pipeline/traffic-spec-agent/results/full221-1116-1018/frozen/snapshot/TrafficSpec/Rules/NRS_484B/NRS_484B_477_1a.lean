/-
  NRS_484B_477_1a — NRS-484B-477-1a

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    a1 (condition): Unless otherwise provided by ordinance of the local authority having jurisdiction,
    a2 (subject): a person
    a3 (obligation): shall not: Stop, stand or park a vehicle
    a4 (condition): within an alley
    a5 (condition): in a business district
    a6 (standard): except for the expeditious loading or unloading of goods.

  How each span is written:
    a2: the binder `subject`, of class ru_aggregate DEF-NRS-484A-320::vehicle (the record's
        observable reading of the person through the vehicle's controlled motion).
    a1: `not (asm asm.local_alley_ordinance)` in the applicability.
    a4: some region of kind `alley` (st.alley) the subject occupies (rel.occupies).
    a5: `asm asm.business_district` in the applicability.
    a3: the halt is drv.motion.complete_halt (speed_tol p.halt_speed_tolerance); the stopping
        definition's exception is the stream-of-traffic excuse: the subject occupies a region of
        kind `travel_region` (st.travel_region) governed (dev.governs) by a device of kind
        traffic_signal, stop_sign, yield_sign, railway_signal_or_gate or human_direction, or some
        road user is ahead of the subject in its lane (rel_ahead_behind_in_lane other subject:
        the other is ahead of the subject) with a gap between bodies (rel.surface_gap, the
        distance read: no component selected) at or below p.queue_halt_gap.
    a6: the operationalization: the halt is beyond the excepted expeditious loading or unloading
        where drv.motion.parked holds (speed_tol p.halt_speed_tolerance, min_duration
        p.parking_min_duration).
  Obligation: not (complete_halt ∧ parked ∧ ¬ excuse).

  Choices the record left open: none beyond the record's own narrowings (the surface gap is read
  as the distance between the bodies, which is the record's "gap between bodies").

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_477_1a

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"
def pParkingMinDuration : Term := .param "p.parking_min_duration"
def pQueueHaltGap : Term := .param "p.queue_halt_gap"

def zeroMetres : Term := .lit Q.zero .metre

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula :=
  .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-320::vehicle"] []

/-- a4: the subject occupies an alley. -/
def inAlley : Formula :=
  .existsRegion (.lit "alley") "alley" (.atom "rel_occupies" [vSubject, .var "alley"] [])

/-- Applicability: a1 (condition): Unless otherwise provided by ordinance of the local authority having jurisdiction,; a4 (condition): within an alley; a5 (condition): in a business district -/
def applicability : Formula :=
  .and inAlley
    (.and (.asm "asm.business_district")
      (.not (.asm "asm.local_alley_ordinance")))

/-- A device of the given kind governs region `tr`. -/
def governedBy (kind : String) : Formula :=
  .existsDevice (.lit kind) "dev" (.atom "dev_governs" [.var "dev", .var "tr"] [])

/-- a3 exception: the subject occupies a travel region governed by a traffic-control device or a
    person directing traffic. -/
def deviceHalt : Formula :=
  .existsRegion (.lit "travel_region") "tr"
    (.and (.atom "rel_occupies" [vSubject, .var "tr"] [])
      (.or (governedBy "traffic_signal")
        (.or (governedBy "stop_sign")
          (.or (governedBy "yield_sign")
            (.or (governedBy "railway_signal_or_gate")
              (governedBy "human_direction"))))))

/-- a3 exception: a road user ahead of the subject in its lane within the queue spacing. -/
def queueHalt : Formula :=
  .existsUser "other"
    (.and (.atom "rel_ahead_behind_in_lane" [.var "other", vSubject] [])
      (.cmp (.measure "rel_surface_gap" [vSubject, .var "other"]) .le pQueueHaltGap))

/-- a3: the halt. -/
def halted : Formula :=
  .derived "drv_motion_complete_halt" [vSubject] [pHaltSpeedTolerance]

/-- a6: a halt beyond the expeditious loading or unloading. -/
def parkedBeyondLoading : Formula :=
  .derived "drv_motion_parked" [vSubject] [pHaltSpeedTolerance, pParkingMinDuration]

/-- Obligation: a3 (obligation): shall not: Stop, stand or park a vehicle; a6 (standard): except for the expeditious loading or unloading of goods. -/
def obligation : Formula :=
  .not (.and halted
    (.and parkedBeyondLoading
      (.not (.or deviceHalt queueHalt))))

def rule : Rule :=
  { id := "NRS_484B_477_1a"
    laws := ["NRS-484B-477-1a"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := ["asm.local_alley_ordinance", "asm.business_district"]
    intentions := []
    operationalizations :=
      [ { standard := "expeditious loading or unloading of goods"
          concepts := ["drv.motion.parked"]
          params := ["p.halt_speed_tolerance", "p.parking_min_duration"]
          convention := "Loading or unloading is a purpose, read through the conduct it explains; 'expeditious' bounds how long that conduct may keep the vehicle standing. A halt counts as the expeditious loading or unloading the words except while the vehicle has not been at rest for longer than the temporary-halt bound of a loading zone (p.parking_min_duration): drv.motion.parked, at rest at every observation of that window behind, marks a halt beyond it."
          surrogate := false } ]
    residues := []
    narrowings := []
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_477_1a
