/-
  NRS_484B_257_2_o1 — NRS-484B-257-2

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    a (exception): Except when traffic is being controlled by a police officer
    b (exception): or a traffic-control signal:
    c (subject): The driver of a vehicle
    d (obligation): shall stop in obedience to a stop sign or yield in compliance with a yield sign,
    f (reference): in compliance with the manner prescribed in subsection 1 [NRS-484B-257-1],
    g (trigger): prior to entering an intersection
    h (condition): if a stop sign or a yield sign is erected at one or more entrances thereto
    i (condition): although not a part of a through highway
    j (sibling): and shall proceed cautiously,
    k (sibling): yielding
    l (sibling): to vehicles not so obligated to stop or yield
    m (sibling): and which are within the intersection
    n (sibling): or approaching so closely as to constitute an immediate hazard
    o (sibling): during the time such driver is moving across or within the intersection.

  Elements (span → atoms, derived):
    a: atoms ['ru.aggregate=DEF-NRS-484A-285::traffic', 'dev.human_direction', 'dev.governs', 'st.travel_region'], derived []
    b: atoms ['dev.traffic_signal', 'dev.governs', 'dev.inoperative'], derived []
    c: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    d: atoms ['dev.stop_sign', 'dev.yield_sign', 'dev.governs', 'kin.speed', 'st.stop_line', 'st.crosswalk', 'st.entrance_of', 'prim.region_offset_along', 'st.lane_direction', 'st.region_geometry', 'rel.occupies'], derived ['drv.motion.complete_halt']
    g: atoms ['rel.occupies', 'st.intersection', 'st.lane_enters', 'st.travel_region'], derived []
    h: atoms ['dev.stop_sign', 'dev.yield_sign', 'dev.governs', 'st.lane_enters', 'st.travel_region', 'rel.occupies', 'st.intersection'], derived []

  Compositions (span → node, as, map):
    f: NRS_484B_257_1_o1 as compliance map {'subject': 'subject'}

  How each span is written.
    g (entry): for an intersection X and a travel region c with st_lane_enters(c, X), the entry is
      `rises (occupies X)` and, at the previous observation, the subject on c and not in X. The
      previous observation is read through `since`: `since (occupies X) (occupies c ∧ ¬occupies X)`
      at the entry steps back over the entry observation (in X) to the one before it (not in X,
      since the footprint rose into X), where it reads the subject on c.
    h: a stop sign or a yield sign that governs c or X (dev_governs), read at the entry.
    a: the subject a member of traffic (DEF-NRS-484A-285::traffic) and a human direction of role
      police_officer governing c or X; b: a traffic signal, not inoperative, governing c or X.
      Both are exceptions in the applicability.
    f: `.rule "NRS_484B_257_1_o1"` conjoined into the obligation (compliance).
    d: the obligation re-selects X and c by the entry (3c) and, at each entry, requires the act
      on the approach: where a stop sign governs c or X, a complete halt (drv_motion_complete_halt,
      p.halt_speed_tolerance); where a yield sign does and no stop sign, kin_speed at or below
      p.yield_line_speed_max. The act is found at an observation where the subject occupies c and
      is within the stopping zone of the place, in subsection 1's order: (1) a stop line marking c
      (st_entrance_of), the line at or ahead of the reference point along c's direction
      (prim_region_offset_along ≥ 0), the body within p.stop_point_tolerance of it
      (st_region_geometry distance); (2) where every stop line's entrance list excludes c, a
      crosswalk marking c, not overlapped, ahead (offset > 0), the body within the tolerance; (3)
      where neither marks c, the footprint outside X and within the tolerance of X.
    The yield branch is written `¬(stop sign governs c or X) → found(slowed)`: under the
      applicability (a stop or a yield sign governs), "where only a yield sign does" is exactly
      "where no stop sign does".
    History bound (the record's): the search runs back from the observation before the entry,
      through `since`, and ends at the approach start — an observation at which the subject on c
      is outside the place's stopping zone upstream (short of the mark along c's direction,
      offset > 0, and farther than the tolerance from it; for every mark of the kind that marks c)
      — or at an observation in X (the previous visit to X, which begins with the previous
      entry). "Off the mark" is not written as a separate conjunct: a body farther than the
      tolerance from a mark does not overlap it. For place (3), X, the bound is the body farther
      than the tolerance from X while on c: c's entrance end is X, so a body on c farther than
      the tolerance from X is off X and short of it along c's direction. Act found: compliant;
      an end reached first: violated; the recording's start reached first: unknown (since's
      unobserved past). No bound comes from the recording's start, a first observation or a
      path length.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_257_2_o1

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"
def pStopPointTolerance : Term := .param "p.stop_point_tolerance"
def pYieldLineSpeedMax : Term := .param "p.yield_line_speed_max"

def zeroMetres : Term := .lit Q.zero .metre

/-- The intersection entered and the approach carrier: quantifier variables. -/
def vX : Arg := .var "X"
def vC : Arg := .var "c"

/-- The subject's footprint overlaps region `r`. -/
def occ (r : String) : Formula := .atom "rel_occupies" [vSubject, .var r] []

/-- Device `d` governs c or X. -/
def govCX (d : String) : Formula :=
  .or (.atom "dev_governs" [.var d, vC] []) (.atom "dev_governs" [.var d, vX] [])

/-- Signed distance from the subject's reference point to region `r` along c's direction. -/
def offsetAlong (r : String) : Term := .quantity "prim_region_offset_along" [vSubject, .var r, vC] []

/-- Ground distance from the subject's body to region `r`. -/
def distTo (r : String) : Term := .measure "st_region_geometry_distance" [vSubject, .var r]

/-- Region `r` (a stop line or a crosswalk) marks c's entrance. -/
def marks (r : String) : Formula := .atom "st_entrance_of" [.var r, vC] []

-- ---------------------------------------------------------------------------------------------
-- g: the entry into X through c
-- ---------------------------------------------------------------------------------------------

/-- The entry observation: the footprint comes to overlap X, and at the previous observation the
    subject occupied c (entering X) and not X. -/
def entry : Formula :=
  .and (.atom "st_lane_enters" [vC, vX] [])
    (.and (.rises (occ "X"))
      (.since (occ "X") (.and (occ "c") (.not (occ "X")))))

-- ---------------------------------------------------------------------------------------------
-- h, a, b: the signs and the exceptions
-- ---------------------------------------------------------------------------------------------

def stopGoverns : Formula := .existsDevice (.lit "stop_sign") "dStop" (govCX "dStop")
def yieldGoverns : Formula := .existsDevice (.lit "yield_sign") "dYield" (govCX "dYield")

def signed : Formula := .or stopGoverns yieldGoverns

/-- a: traffic being controlled by a police officer (a person directing traffic of that role)
    governing c or X. -/
def officerControls : Formula :=
  .and (.atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-285::traffic"] [])
    (.existsDevice (.lit "human_direction") "dOfficer"
      (.and (.atom "dev_human_direction_role" [.var "dOfficer", .lit "police_officer"] [])
        (govCX "dOfficer")))

/-- b: a traffic signal that is not inoperative governing c or X. -/
def signalControls : Formula :=
  .existsDevice (.lit "traffic_signal") "dSignal"
    (.and (.not (.atom "dev_inoperative" [.var "dSignal"] [])) (govCX "dSignal"))

-- ---------------------------------------------------------------------------------------------
-- d: the place and its stopping zone
-- ---------------------------------------------------------------------------------------------

/-- Every stop line's entrance list excludes c. -/
def noLine : Formula := .forallRegion (.lit "stop_line") "L" (.not (marks "L"))
/-- Every crosswalk's entrance list excludes c. -/
def noWalk : Formula := .forallRegion (.lit "crosswalk") "W" (.not (marks "W"))

/-- Within the stopping zone of the place, at one observation (the subject on c). -/
def inZone : Formula :=
  .and (occ "c")
    (.or
      (.existsRegion (.lit "stop_line") "L"
        (.and (marks "L")
          (.and (.cmp (offsetAlong "L") .ge zeroMetres)
            (.cmp (distTo "L") .le pStopPointTolerance))))
      (.or
        (.and noLine
          (.existsRegion (.lit "crosswalk") "W"
            (.and (marks "W")
              (.and (.not (occ "W"))
                (.and (.cmp (offsetAlong "W") .gt zeroMetres)
                  (.cmp (distTo "W") .le pStopPointTolerance))))))
        (.and noLine
          (.and noWalk
            (.and (.not (occ "X"))
              (.cmp (distTo "X") .le pStopPointTolerance))))))

/-- Outside a mark's stopping zone upstream: short of it along c's direction and farther than the
    tolerance from it (a body farther than the tolerance is off the mark). -/
def upstreamOf (r : String) : Formula :=
  .and (.cmp (offsetAlong r) .gt zeroMetres)
    (.cmp (distTo r) .gt pStopPointTolerance)

/-- The approach start: the subject, on c, outside the place's stopping zone upstream (of every
    mark of the place's kind that marks c; for X, farther than the tolerance from it, which on c,
    whose entrance end is X, is short of it and off it). -/
def approachStart : Formula :=
  .and (occ "c")
    (.or
      (.and (.existsRegion (.lit "stop_line") "L" (marks "L"))
        (.forallRegion (.lit "stop_line") "L" (.implies (marks "L") (upstreamOf "L"))))
      (.or
        (.and noLine
          (.and (.existsRegion (.lit "crosswalk") "W" (marks "W"))
            (.forallRegion (.lit "crosswalk") "W" (.implies (marks "W") (upstreamOf "W")))))
        (.and noLine (.and noWalk (.cmp (distTo "X") .gt pStopPointTolerance)))))

/-- The act found on the approach, read at the entry: from the observation before the entry back
    to the approach start or to an observation in X (the previous visit), whichever comes first. -/
def found (act : Formula) : Formula :=
  .since (occ "X")
    (.and (.not (occ "X"))
      (.since (.and (.not approachStart) (.not (occ "X")))
        (.and inZone act)))

def halt : Formula := .derived "drv_motion_complete_halt" [vSubject] [pHaltSpeedTolerance]
def slowed : Formula := .cmp (.measure "kin_speed" [vSubject]) .le pYieldLineSpeedMax

-- ---------------------------------------------------------------------------------------------

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-320::vehicle"] []

/-- Applicability: a (exception): Except when traffic is being controlled by a police officer; b (exception): or a traffic-control signal:; g (trigger): prior to entering an intersection; h (condition): if a stop sign or a yield sign is erected at one or more entrances thereto; i (condition): although not a part of a through highway -/
def applicability : Formula :=
  .existsRegion (.lit "intersection") "X"
    (.existsRegion (.lit "travel_region") "c"
      (.and entry
        (.and signed
          (.and (.not officerControls) (.not signalControls)))))

/-- Obligation: d (obligation): shall stop in obedience to a stop sign or yield in compliance with a yield sign, -/
def obligation : Formula :=
  .and (.rule "NRS_484B_257_1_o1" [("subject", "subject")])
    (.forallRegion (.lit "intersection") "X"
      (.forallRegion (.lit "travel_region") "c"
        (.implies entry
          (.and (.implies stopGoverns (found halt))
            (.implies (.not stopGoverns) (found slowed))))))

def rule : Rule :=
  { id := "NRS_484B_257_2_o1"
    laws := ["NRS-484B-257-2"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations := []
    residues := ["'although' is concessive: the duty reaches signed entrances whether or not the intersection is part of a through highway, and the stop or yield owed at a signed entrance is the same in both cases (subsection 1 states the same act where it is part of one); the words withhold the duty nowhere."]  -- the node's, verbatim; not yours to change
    narrowings := []
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_257_2_o1
