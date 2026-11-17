/-
  NRS_484B_213_1 — NRS-484B-213-1

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (subject): A vehicle
    s2 (obligation): must not be driven to the left side of the center of a two-lane, two-directional highway and overtaking and passing another vehicle proceeding in the same direction,
    s5 (exception): unless such left side is clearly visible
    s6 (exception): and is free of oncoming traffic
    s7 (standard): for a sufficient distance ahead to permit such overtaking and passing to be completely made without interfering with the safe operation of any vehicle approaching from the opposite direction or any vehicle overtaken.

  Elements (span → atoms, derived):
    s1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    s2: atoms ['prim.region_lateral_offset', 'st.centre_line', 'st.on_way', 'st.highway', 'rel.occupies', 'st.lane', 'st.lane_adjacency', 'ru.aggregate=DEF-NRS-484A-320::vehicle'], derived ['drv.interaction.overtake_pass']
    s5: atoms ['st.sight_distance'], derived []
    s6: atoms ['ru.aggregate=DEF-NRS-484A-285::traffic', 'rel.oncoming', 'rel.centre_distance'], derived []

  Literals the text states (each written through its Units constructor):
    s2: 2 count — two-lane

  No magnitude below is this file's own: parameters name the reading, literals are the text's.

  How each span is written:
    s1: the binder class, ru_aggregate(subject, DEF-NRS-484A-320::vehicle).
    s2 (act): applicability ∃ b of DEF-NRS-484A-320::vehicle with
        drv_interaction_overtake_pass(subject, b; p.overtake_window, p.overtake_same_direction_cos)
        at the judged observation; the obligation re-selects the same b in full (class + act).
    occasion (window, s5/s6 throughout): `holdsFor .time p.overtake_window subject (U → duty)`.
        U = afterBeginning ∧ closing, from the under-way atoms:
          afterBeginning = until(¬aheadAligned, bBehind): from this observation b is never again
            ahead with aligned headings (rel_bearing ahead, rel_longitudinal_overlap < 0,
            rel_same_direction) until it is behind (rel_bearing behind, overlap < 0) — true exactly
            after the act's beginning (the last aligned-ahead observation) up to the recognition;
          closing = v_s·v_s > v_s·v_b (kin_velocity): the subject's velocity exceeds b's along its
            own direction of travel.
        The beginning observation itself is where afterBeginning is false and rises at the next
        observation; there the duty at the previous observation is required through
        `rises afterBeginning → ¬ rises dutyHere` (given dutyHere here, this is dutyHere at the
        previous observation): the language has no "next" operator, so the beginning is reached
        from the observation after it. No other observation before the beginning is read.
    s2 (place): ∀ highway h the subject occupies (rel_occupies), ∀ centre line c lying on h
        (st_on_way), if h is two-lane and prim_region_lateral_offset(subject, c) < 0, the duty holds.
        "two-lane" (literal 2): for every two lanes l, l2 lying on h, the st_lane_adjacency counts
        in their directions add up to 2 — equivalent to every lane on h being the single lane of its
        direction (l = l2 included), the record's "every lane lying on h has a single lane in its
        direction".
    s5 + s7: st_sight_distance at the subject's point is read on the highway region h the subject
        occupies (the region that is its place on the way), ≥ kin_speed(subject) × p.passing_sight_time.
    s6 + s7: every u of DEF-NRS-484A-285::traffic with rel_oncoming(subject, u; p.oncoming_heading_cos)
        has rel_centre_distance(subject, u) ≥ the same distance.
    s7 (interference): for every road user u that is b (`same u b`) or of DEF-NRS-484A-320::vehicle
        and oncoming (one quantifier over both, so one check carries both): no rel_contact,
        and not (prim_closest_approach_within over p.conflict_horizon with
        prim_closest_approach_distance < p.conflict_centre_clearance).
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_213_1

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pConflictCentreClearance : Term := .param "p.conflict_centre_clearance"
def pConflictHorizon : Term := .param "p.conflict_horizon"
def pOncomingHeadingCos : Term := .param "p.oncoming_heading_cos"
def pOvertakeSameDirectionCos : Term := .param "p.overtake_same_direction_cos"
def pOvertakeWindow : Term := .param "p.overtake_window"
def pPassingSightTime : Term := .param "p.passing_sight_time"

def zeroMetres : Term := .lit Q.zero .metre

/-- s2 literal "two-lane": 2 lanes (a count; Units has no count constructor, so the figure is
    written as the exact rational the count is). -/
def twoLanes : Term := .lit (Q.ofInt 2) .count

-- Quantified variables: `b` the road user passed, `u` another road user, `h` the highway,
-- `c` its centre line, `l`/`l2` lanes lying on it.
def vB : Arg := .var "b"
def vU : Arg := .var "u"
def vH : Arg := .var "h"
def vC : Arg := .var "c"
def vL : Arg := .var "l"
def vL2 : Arg := .var "l2"

/-- s1 / s2: membership of DEF-NRS-484A-320::vehicle. -/
def vehicle (x : Arg) : Formula := .atom "ru_aggregate" [x, .lit "DEF-NRS-484A-320::vehicle"] []
/-- s6: membership of DEF-NRS-484A-285::traffic. -/
def traffic (x : Arg) : Formula := .atom "ru_aggregate" [x, .lit "DEF-NRS-484A-285::traffic"] []

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula := vehicle vSubject

/-- s2: the act, recognized at the judged observation. -/
def overtakes : Formula :=
  .derived "drv_interaction_overtake_pass" [vSubject, vB] [pOvertakeWindow, pOvertakeSameDirectionCos]

/-- Applicability: the subject overtakes and passes a road user b of DEF-NRS-484A-320::vehicle
    (recognized here). The exceptions s5/s6 are read in the obligation, at the observations of the act. -/
def applicability : Formula := .existsUser "b" (.and (vehicle vB) overtakes)

-- ---------------------------------------------------------------------------------------------
-- The occasion's under-way formula U (atoms kin.velocity, rel.bearing, rel.longitudinal_overlap,
-- rel.same_direction).
-- ---------------------------------------------------------------------------------------------
def overlap : Term := .measure "rel_longitudinal_overlap" [vSubject, vB]
/-- b ahead of the subject: bearing's longitudinal component positive, projections sharing no length. -/
def bAhead : Formula := .and (.atom "rel_bearing" [vSubject, vB, .lit "ahead"] []) (.cmp overlap .lt zeroMetres)
/-- b behind the subject: bearing's longitudinal component negative, projections sharing no length. -/
def bBehind : Formula := .and (.atom "rel_bearing" [vSubject, vB, .lit "behind"] []) (.cmp overlap .lt zeroMetres)
/-- b ahead with headings aligned (the observations that can begin the act). -/
def aheadAligned : Formula :=
  .and bAhead (.atom "rel_same_direction" [vSubject, vB] [pOvertakeSameDirectionCos])
/-- From here on b is never again ahead with headings aligned until it is behind the subject:
    the observation lies after the act's beginning (the last aligned-ahead observation) and at or
    before its recognition. -/
def afterBeginning : Formula := .until (.not aheadAligned) bBehind
/-- The subject's velocity exceeds b's along the subject's direction of travel:
    v_s · v_s > v_s · v_b. -/
def vel (x : Arg) (k : String) : Term := .measure "kin_velocity" [x, .lit k]
def closing : Formula :=
  .cmp (.add (.mul (vel vSubject "x") (vel vSubject "x")) (.mul (vel vSubject "y") (vel vSubject "y")))
    .gt (.add (.mul (vel vSubject "x") (vel vB "x")) (.mul (vel vSubject "y") (vel vB "y")))
/-- U: the observation is inside the act (after its beginning, at or before its recognition)
    while the subject, faster than b, carries up to and past it. -/
def underWay : Formula := .and afterBeginning closing

-- ---------------------------------------------------------------------------------------------
-- s2 place, s5/s6 exceptions and s7 standard, at one observation, for the passed road user b.
-- ---------------------------------------------------------------------------------------------
/-- s7: the required distance, the subject's speed times p.passing_sight_time. -/
def needed : Term := .mul (.measure "kin_speed" [vSubject]) pPassingSightTime
/-- s5 + s7: the sight distance at the subject's place (the highway h it occupies) reaches it. -/
def sightClear : Formula := .cmp (.measure "st_sight_distance" [vH]) .ge needed
def oncoming (x : Arg) : Formula := .atom "rel_oncoming" [vSubject, x] [pOncomingHeadingCos]
/-- s6 + s7: every oncoming road user of traffic is at least the required distance away. -/
def oncomingTrafficClear : Formula :=
  .forallUser "u" (.implies (.and (traffic vU) (oncoming vU))
    (.cmp (.measure "rel_centre_distance" [vSubject, vU]) .ge needed))
/-- s7: no interference with x: no contact, and no closest approach within p.conflict_horizon
    closer than p.conflict_centre_clearance. -/
def noConflict (x : Arg) : Formula :=
  .and (.not (.atom "rel_contact" [vSubject, x] []))
    (.not (.and (.derived "prim_closest_approach_within" [vSubject, x] [pConflictHorizon])
      (.cmp (.quantity "prim_closest_approach_distance" [vSubject, x] [pConflictHorizon]) .lt pConflictCentreClearance)))
/-- s7: neither the vehicle overtaken (u is b) nor any oncoming vehicle is interfered with. -/
def noInterference : Formula :=
  .forallUser "u" (.implies (.or (.same vU vB) (.and (vehicle vU) (oncoming vU))) (noConflict vU))
/-- The exception's conditions, all required. -/
def passClear : Formula := .and sightClear (.and oncomingTrafficClear noInterference)

/-- s2 "two-lane": every pair of lanes lying on h carries, in their directions, two lanes
    together — each lane is the single lane of its direction. -/
def twoLane : Formula :=
  .forallRegion (.lit "lane") "l" (.implies (.atom "st_on_way" [vL, vH] [])
    (.forallRegion (.lit "lane") "l2" (.implies (.atom "st_on_way" [vL2, vH] [])
      (.cmp (.add (.measure "st_lane_adjacency" [vL, .lit "count"]) (.measure "st_lane_adjacency" [vL2, .lit "count"]))
        .eq twoLanes))))
/-- s2 "to the left side of the center": the centre line c lies to the right of the subject's reference point. -/
def leftOfCentre : Formula :=
  .cmp (.quantity "prim_region_lateral_offset" [vSubject, vC] []) .lt zeroMetres

/-- At one observation: wherever the subject occupies a highway h carrying a centre line c, h is
    two-lane and the subject is left of c, the pass is clear. -/
def dutyHere : Formula :=
  .forallRegion (.lit "highway") "h" (.implies (.atom "rel_occupies" [vSubject, vH] [])
    (.forallRegion (.lit "centre_line") "c"
      (.implies (.and (.atom "st_on_way" [vC, vH] []) (.and twoLane leftOfCentre)) passClear)))

/-- Obligation: s2 (obligation): must not be driven to the left side of the center of a two-lane, two-directional highway and overtaking and passing another vehicle proceeding in the same direction,; s7 (standard): for a sufficient distance ahead to permit such overtaking and passing to be completely made without interfering with the safe operation of any vehicle approaching from the opposite direction or any vehicle overtaken.

    Read throughout the act (boundary window, p.overtake_window): at every observation of the
    window behind at which U holds, the duty holds there; at the first observation after the
    beginning (where `afterBeginning` rises) it is also required at the beginning itself, the
    observation before (`rises dutyHere` false there, given `dutyHere`, is `dutyHere` at the
    previous observation). -/
def obligation : Formula :=
  .forallUser "b" (.implies (.and (vehicle vB) overtakes)
    (.holdsFor .time pOvertakeWindow "subject"
      (.implies underWay (.and dutyHere (.implies (.rises afterBeginning) (.not (.rises dutyHere)))))))

def rule : Rule :=
  { id := "NRS_484B_213_1"
    laws := ["NRS-484B-213-1"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations :=
      [ { standard := "for a sufficient distance ahead to permit such overtaking and passing to be completely made without interfering with the safe operation of any vehicle approaching from the opposite direction or any vehicle overtaken"
          concepts := ["kin.speed", "prim.closest_approach_distance", "prim.closest_approach_within", "rel.centre_distance", "rel.contact", "rel.oncoming", "st.sight_distance"]
          params := ["p.passing_sight_time", "p.oncoming_heading_cos", "p.conflict_horizon", "p.conflict_centre_clearance"]
          convention := "Passing sight distance: the MUTCD minimum passing sight distance by prevailing speed (Table 3B-1), expressed as the time the subject's speed takes to cover it (p.passing_sight_time), so the required distance moves with the subject's speed; both the sight distance at the subject's point and the centre distance to every oncoming road user of traffic must reach it. Interference with the safe operation of an oncoming vehicle or the vehicle overtaken: the traffic-conflict technique, a contact or a closest approach under constant velocities within p.conflict_horizon closer than p.conflict_centre_clearance."
          surrogate := false } ]
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []  -- one { span := "<span id>", why := "<why>", kind := "reading" } per reading you chose on a carried span (kind no_atom / no_operator where the words cannot be stated), explained in the header; the record's own narrowings are not restated
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_213_1
