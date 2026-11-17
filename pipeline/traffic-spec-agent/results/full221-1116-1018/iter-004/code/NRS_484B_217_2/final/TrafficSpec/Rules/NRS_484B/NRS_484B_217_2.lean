/-
  NRS_484B_217_2 — NRS-484B-217-2

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (boilerplate): Except as otherwise provided in subsections 3 and 4,
    s2 (subject): a driver
    s3 (obligation): shall not drive on the left side of the highway within such zone or drive across or on the left side of any pavement striping designed to mark such zone throughout its length.
    s6 (exception): A driver may drive across a pavement striping marking such zone
    s7 (exception): to an adjoining highway if the driver has first given the appropriate turn signal
    s8 (standard): and there will be no impediment to
    s8b (exception): oncoming or following traffic.
    s9 (exception): Except where otherwise provided,
    s10 (exception): a driver may drive across a pavement striping marking such a zone
    s11 (exception): to make a left-hand turn
    s12 (exception): if the driver has first given the appropriate turn signal
    s13 (reference): in compliance with NRS 484B.413 [NRS-484B-413-2],
    s14 (standard): if it is safe
    s15 (standard): and if it would not be an impediment to
    s15b (exception): oncoming or following traffic.

  Elements (span → atoms, derived):
    s2: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    s3: atoms ['prim.region_lateral_offset', 'kin.extent', 'rel.occupies', 'st.centre_line', 'st.highway', 'st.on_way', 'dev.zone_sign', 'dev.governs', 'st.travel_region', 'st.lane', 'st.lane_marking'], derived []
    s6: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle', 'prim.region_lateral_offset', 'st.centre_line', 'kin.extent'], derived []
    s7: atoms ['rel.occupies', 'st.highway', 'sig.turn_indicator', 'sig.hand_signal'], derived []
    s10: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle', 'prim.region_lateral_offset', 'st.centre_line', 'kin.extent', 'st.intersection', 'st.driveway_or_alley_entrance'], derived []
    s8b: atoms ['ru.aggregate=DEF-NRS-484A-285::traffic', 'rel.oncoming', 'rel.same_direction', 'rel.bearing'], derived []
    s15b: atoms ['ru.aggregate=DEF-NRS-484A-285::traffic', 'rel.oncoming', 'rel.same_direction', 'rel.bearing'], derived []
    s12: atoms ['sig.turn_indicator', 'sig.hand_signal'], derived []

  Compositions (span → node, as, map):
    s13: NRS_484B_413_2 as compliance map {'subject': 'subject'}

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_217_2

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pConflictCentreClearance : Term := .param "p.conflict_centre_clearance"
def pConflictHorizon : Term := .param "p.conflict_horizon"
def pContestSameDirectionCos : Term := .param "p.contest_same_direction_cos"
def pLateralPositionTolerance : Term := .param "p.lateral_position_tolerance"
def pOncomingHeadingCos : Term := .param "p.oncoming_heading_cos"
def pVehicleTurnWindow : Term := .param "p.vehicle_turn_window"

def zeroMetres : Term := .lit Q.zero .metre

/-
  How each span is written.

  s2  — the subject is a member of the admitted aggregate DEF-NRS-484A-320::vehicle (`ru_aggregate`).
  s3  — applicability: the subject occupies (`rel_occupies`) a `highway` h on which (`st_on_way`) a
        `centre_line` c lies, and is within a no-passing zone: it occupies a `travel_region` that a
        `zone_sign` of kind no_passing, not an end sign, governs (`dev_governs`), or it occupies a
        `lane` whose left `st_lane_marking` is solid or double_solid and yellow; a solid_broken left
        marking leaves that lane's membership unknown (`definedWhen`).
        obligation: for every highway h the subject occupies and every centre line c on it, the
        body does not reach past c to the left: 2·offset(c) ≥ width − 2·tolerance, i.e. the lateral
        offset of c (`prim_region_lateral_offset`, left positive) is not below half the width
        (`kin_extent` "width") minus `p.lateral_position_tolerance` (written doubled so that no
        literal 2 is needed). Judged at every observation ("throughout its length").
  s6/s10 — the excused act is that same crossing of c.
  s7/s12 — "has first given the appropriate turn signal": `since crossing (¬crossing ∧ left signal)`,
        i.e. at the last observation before the crossing began, the crossing having held at every
        observation since, `sig_turn_indicator` left or `sig_hand_signal` left.
  s7  — "to an adjoining highway": within `p.vehicle_turn_window` ahead the subject occupies a
        highway h2 that is not h and no longer occupies h (E3).
  s8/s15 (s8b/s15b) — no impediment: no other road user that is a member of
        DEF-NRS-484A-285::traffic and is oncoming (`rel_oncoming`, `p.oncoming_heading_cos`) or
        following (`rel_bearing` behind and `rel_same_direction`, `p.contest_same_direction_cos`)
        has its centre approach the subject's within `p.conflict_horizon`
        (`prim_closest_approach_within`) to a centre distance below `p.conflict_centre_clearance`
        (`prim_closest_approach_distance`). Read at every observation of the crossing.
  s11 — the declared intention `int.left_turn` of the subject at an `intersection` or a
        `driveway_or_alley_entrance`, read at the judged observation (E4). The target region is
        tied to the zone's highway h by `st_on_way` (an intersection lies on every way meeting
        there; a driveway entrance on the highway it meets): the left-hand turn the crossing is
        made for leaves that highway. The gate requires the target to be anchored, and the intent
        alone does not anchor it.
  s13 — compliance with NRS_484B_413_2 for the subject (`.rule`).
  s14 — safe: no other road user is in contact with the subject (`rel_contact`) or has a
        conflicting closest approach as above.
  E3 and E4 share the signal and the no-impediment conditions; the obligation states them once:
  ¬crossing ∨ (signalled ∧ noImpediment ∧ (E3-reach ∨ (E4-intent ∧ 413 ∧ safe))), which is
  the record's (E3 ∨ E4) unfolded.
  s9  — the node's residue.
  "Another" road user: the subject itself is excluded from the traffic and safety quantifiers
  (`same`), since a body is trivially in contact with itself.
-/

def aggVehicle : Arg := .lit "DEF-NRS-484A-320::vehicle"
def aggTraffic : Arg := .lit "DEF-NRS-484A-285::traffic"

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, aggVehicle] []

/-- The subject's footprint overlaps region `r`. -/
def occupies (r : String) : Formula := .atom "rel_occupies" [vSubject, .var r] []

/-- Centre line `c` lies on highway `h`. -/
def onWay (c h : String) : Formula := .atom "st_on_way" [.var c, .var h] []

/-- s3: a no_passing zone sign (not an end sign) governs a travel region the subject occupies. -/
def zoneBySign : Formula :=
  .existsDevice (.lit "zone_sign") "z"
    (.existsRegion (.lit "travel_region") "r"
      (.and (occupies "r")
        (.and (.atom "dev_governs" [.var "z", .var "r"] [])
          (.and (.atom "dev_zone_sign_kind" [.var "z", .lit "no_passing"] [])
                (.not (.atom "dev_zone_sign_end" [.var "z"] []))))))

def markingLeft (l t col : String) : Formula :=
  .atom "st_lane_marking" [.var l, .lit "left", .lit t, .lit col] []

/-- s3: the subject occupies a lane whose left marking is solid or double_solid yellow;
    solid_broken leaves it unknown. -/
def zoneByMarking : Formula :=
  .existsRegion (.lit "lane") "l"
    (.and (occupies "l")
      (.definedWhen (.not (.atom "st_lane_marking" [.var "l", .lit "left", .lit "solid_broken"] []))
        (.or (markingLeft "l" "solid" "yellow") (markingLeft "l" "double_solid" "yellow"))))

def inZone : Formula := .or zoneBySign zoneByMarking

/-- The lateral offset of region `c` from the subject (m, left positive). -/
def offsetOf (c : String) : Term := .quantity "prim_region_lateral_offset" [vSubject, .var c] []

def subjectWidth : Term := .measure "kin_extent" [vSubject, .lit "width"]

/-- s3/s6/s10: the body reaches past `c` to its left: offset < width/2 − tolerance. -/
def crossing (c : String) : Formula :=
  .cmp (.add (offsetOf c) (offsetOf c)) .lt
    (.sub (.sub subjectWidth pLateralPositionTolerance) pLateralPositionTolerance)

/-- s7/s12: the left signal (indicator or arm). -/
def signalLeft : Formula :=
  .or (.atom "sig_turn_indicator" [vSubject, .lit "left"] [])
      (.atom "sig_hand_signal" [vSubject, .lit "left"] [])

/-- s7/s12: the signal was given at the last observation before the crossing of `c` began. -/
def signalledFirst (c : String) : Formula :=
  .since (crossing c) (.and (.not (crossing c)) signalLeft)

/-- s8/s14/s15: a closest approach of road user `u` to the subject within the conflict horizon,
    at a centre distance below the conflict clearance. -/
def conflict (u : String) : Formula :=
  .and (.derived "prim_closest_approach_within" [vSubject, .var u] [pConflictHorizon])
       (.cmp (.quantity "prim_closest_approach_distance" [vSubject, .var u] [pConflictHorizon])
             .lt pConflictCentreClearance)

/-- s8/s8b/s15/s15b: no oncoming or following member of traffic has a conflicting approach. -/
def noImpediment : Formula :=
  .forallUser "u"
    (.implies
      (.and (.not (.same (.var "u") vSubject))
        (.and (.atom "ru_aggregate" [.var "u", aggTraffic] [])
          (.or (.atom "rel_oncoming" [vSubject, .var "u"] [pOncomingHeadingCos])
               (.and (.atom "rel_bearing" [vSubject, .var "u", .lit "behind"] [])
                     (.atom "rel_same_direction" [vSubject, .var "u"] [pContestSameDirectionCos])))))
      (.not (conflict "u")))

/-- s14: no other road user is in contact with the subject or has a conflicting approach. -/
def safe : Formula :=
  .forallUser "w"
    (.implies (.not (.same (.var "w") vSubject))
      (.and (.not (.atom "rel_contact" [vSubject, .var "w"] [])) (.not (conflict "w"))))

/-- s7 (E3): within the turn window the subject occupies a highway other than `h`, and not `h`. -/
def reachesAdjoiningHighway (h : String) : Formula :=
  .within .time pVehicleTurnWindow "subject"
    (.existsRegion (.lit "highway") "h2"
      (.and (occupies "h2") (.and (.not (.same (.var "h2") (.var h))) (.not (occupies h)))))

/-- s10/s11: the declared left-turn intention at an intersection or a driveway/alley entrance
    lying on the zone's highway `h` (the place where the left turn leaves that highway). -/
def leftTurnDeclared (h : String) : Formula :=
  .or (.existsRegion (.lit "intersection") "t"
        (.and (onWay "t" h) (.intent "int.left_turn" vSubject (.var "t"))))
      (.existsRegion (.lit "driveway_or_alley_entrance") "t"
        (.and (onWay "t" h) (.intent "int.left_turn" vSubject (.var "t"))))

/-- s10–s14 (E4), less the signal and impediment conditions it shares with E3. -/
def leftTurnExcuse (h : String) : Formula :=
  .and (leftTurnDeclared h) (.and (.rule "NRS_484B_413_2" [("subject", "subject")]) safe)

/-- Applicability: the subject, on a highway with a centre line, within a no-passing zone. -/
def applicability : Formula :=
  .and (.existsRegion (.lit "highway") "h"
          (.and (occupies "h") (.existsRegion (.lit "centre_line") "c" (onWay "c" "h"))))
       inZone

/-- Obligation: for every highway occupied and centre line on it, no crossing unless excused
    (E3 to an adjoining highway, E4 to make a left-hand turn). -/
def obligation : Formula :=
  .forallRegion (.lit "highway") "h"
    (.implies (occupies "h")
      (.forallRegion (.lit "centre_line") "c"
        (.implies (onWay "c" "h")
          (.or (.not (crossing "c"))
            (.and (signalledFirst "c")
              (.and noImpediment
                (.or (reachesAdjoiningHighway "h") (leftTurnExcuse "h"))))))))

def rule : Rule :=
  { id := "NRS_484B_217_2"
    laws := ["NRS-484B-217-2"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := ["int.left_turn"]
    operationalizations :=
      [ { standard := "no impediment to oncoming or following traffic"
          concepts := ["prim.closest_approach_distance", "prim.closest_approach_within"]
          params := ["p.conflict_horizon", "p.conflict_centre_clearance"]
          convention := "traffic-conflict technique: a road user of traffic is impeded where its centre and the subject's, under constant velocities, approach within the conflict horizon to a centre distance below the conflict clearance; oncoming is rel.oncoming within the opposed-heading tolerance, following is a road user behind the subject (negative longitudinal bearing) with headings aligned within the same-direction tolerance; read at every observation of the crossing"
          surrogate := false }
      , { standard := "it is safe"
          concepts := ["prim.closest_approach_distance", "prim.closest_approach_within", "rel.contact"]
          params := ["p.conflict_horizon", "p.conflict_centre_clearance"]
          convention := "traffic-conflict technique: the crossing is safe where no road user of the scene is in contact with the subject and none approaches the subject's centre, under constant velocities, within the conflict horizon to a centre distance below the conflict clearance; read at every observation of the crossing"
          surrogate := false }
      , { standard := "no impediment to oncoming or following traffic"
          concepts := ["prim.closest_approach_distance", "prim.closest_approach_within"]
          params := ["p.conflict_horizon", "p.conflict_centre_clearance"]
          convention := "as for s8: traffic-conflict technique on oncoming (rel.oncoming) and following (behind, headings aligned) members of traffic, read at every observation of the crossing"
          surrogate := false } ]
    residues := ["'Except where otherwise provided' defers to provisions it does not name; those provisions are judged by their own rules, and this rule's verdict on crossing the striping to make a left-hand turn is the same whether or not they apply."]  -- the node's, verbatim; not yours to change
    narrowings := []  -- one { span := "<span id>", why := "<why>", kind := "reading" } per reading you chose on a carried span (kind no_atom / no_operator where the words cannot be stated), explained in the header; the record's own narrowings are not restated
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_217_2
