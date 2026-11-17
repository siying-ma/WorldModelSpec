/-
  LVMC_11_16_090_A_o1 — LVMC-11-16-090-A

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    g1 (obligation): No person shall engage in
    g2 (subject): any motor vehicle
    g3 (standard): speed contest or exhibition of power or speed
    g4 (condition): on a highway
    g5 (boilerplate): and
    g6 (sibling): no person shall aid or abet in
    g7 (sibling): any such motor vehicle
    g8 (sibling): speed contest or exhibition
    g9 (sibling): upon any highway

  Elements (span → atoms, derived):
    g1: atoms ['kin.accel_longitudinal', 'kin.speed'], derived []
    g2: atoms ['ru.aggregate=DEF-NRS-484A-130::motor_vehicle'], derived []
    g4: atoms ['rel.occupies', 'st.highway'], derived []

  How each is written:
    g2  the binder class: `ru_aggregate subject "DEF-NRS-484A-130::motor_vehicle"`.
    g4  the applicability: some region of kind `highway` (st.highway, the quantifier's kind) that
        the subject occupies (rel.occupies anchors the region to the subject).
    g1/g3  the obligation: not any of
        (a) exhibition of power: kin_accel_longitudinal(subject) ≥ p.exhibition_accel_min;
        (b) exhibition of speed: kin_speed(subject) ≥ p.exhibition_speed_min;
        (c) contest: some other road user o (`not (same subject o)`) that is a member of the same
            aggregate, with, at every observation of the p.contest_window seconds behind,
            rel_same_direction(subject, o; p.contest_same_direction_cos), rel_longitudinal_overlap
            (subject, o) > 0, and both accelerations ≥ p.contest_accel_min.
        The record states "one road user throughout", so the user quantifier stands outside the
        time window and the same o is held at every observation of it; this is the record's
        words, not a choice of this file. The window is a time window of the subject (`.time`).

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.LVMC_11_16_090_A_o1

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The other party of a contest (a quantifier variable). -/
def vOther : Arg := .var "o"

/-- The region the subject is on (a quantifier variable). -/
def vHighway : Arg := .var "h"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pContestAccelMin : Term := .param "p.contest_accel_min"
def pContestSameDirectionCos : Term := .param "p.contest_same_direction_cos"
def pContestWindow : Term := .param "p.contest_window"
def pExhibitionAccelMin : Term := .param "p.exhibition_accel_min"
def pExhibitionSpeedMin : Term := .param "p.exhibition_speed_min"

def zeroMetres : Term := .lit Q.zero .metre

/-- The admitted aggregate "motor vehicle" (DEF-NRS-484A-130). -/
def motorVehicle (x : Arg) : Formula :=
  .atom "ru_aggregate" [x, .lit "DEF-NRS-484A-130::motor_vehicle"] []

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-130::motor_vehicle -/
def clsSubject : Formula := motorVehicle vSubject

/-- Applicability: g4 (condition): on a highway — the subject occupies a highway region. -/
def applicability : Formula :=
  .existsRegion (.lit "highway") "h" (.atom "rel_occupies" [vSubject, vHighway] [])

/-- (a) exhibition of power. -/
def exhibitionOfPower : Formula :=
  .cmp (.measure "kin_accel_longitudinal" [vSubject]) .ge pExhibitionAccelMin

/-- (b) exhibition of speed. -/
def exhibitionOfSpeed : Formula :=
  .cmp (.measure "kin_speed" [vSubject]) .ge pExhibitionSpeedMin

/-- At one observation: o side by side with the subject in the same direction, both accelerating
    at least p.contest_accel_min. -/
def sideBySideHardAcceleration : Formula :=
  .and (.atom "rel_same_direction" [vSubject, vOther] [pContestSameDirectionCos])
    (.and (.cmp (.measure "rel_longitudinal_overlap" [vSubject, vOther]) .gt zeroMetres)
      (.and (.cmp (.measure "kin_accel_longitudinal" [vSubject]) .ge pContestAccelMin)
        (.cmp (.measure "kin_accel_longitudinal" [vOther]) .ge pContestAccelMin)))

/-- (c) a speed contest: one other motor vehicle, side by side and hard accelerating with the
    subject at every observation of the window behind. -/
def speedContest : Formula :=
  .existsUser "o"
    (.and (.not (.same vSubject vOther))
      (.and (motorVehicle vOther)
        (.holdsFor .time pContestWindow "subject" sideBySideHardAcceleration)))

/-- Obligation: g1 (obligation): No person shall engage in; g3 (standard): speed contest or exhibition of power or speed -/
def obligation : Formula :=
  .not (.or exhibitionOfPower (.or exhibitionOfSpeed speedContest))

def rule : Rule :=
  { id := "LVMC_11_16_090_A_o1"
    laws := ["LVMC-11-16-090-A"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations :=
      [ { standard := "speed contest or exhibition of power or speed"
          concepts := ["kin.accel_longitudinal", "kin.speed", "rel.longitudinal_overlap", "rel.same_direction"]
          params := ["p.exhibition_accel_min", "p.exhibition_speed_min", "p.contest_accel_min", "p.contest_window", "p.contest_same_direction_cos"]
          convention := "naturalistic-driving harsh-event thresholds: an exhibition of power is a longitudinal acceleration above a harsh-acceleration threshold, an exhibition of speed a speed above a bound far beyond any posted limit, and a contest two motor vehicles side by side in the same direction both accelerating above a lower threshold throughout a window"
          surrogate := true } ]
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []
    surrogate := true }

end TrafficSpec.Rules.LVMC_11_16_090_A_o1
