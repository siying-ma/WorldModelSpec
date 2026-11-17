/-
  NRS_484B_210_2 — NRS-484B-210-2

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (subject): The driver of a vehicle
    s2 (obligation): may overtake and pass another vehicle upon the right only
    s3 (standard): under conditions permitting such movement in safety.

  Elements (span → atoms, derived):
    s1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    s2: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived ['drv.interaction.overtake_pass_on_right']

  How each is written.
    s1: the subject's class is `ru_aggregate subject DEF-NRS-484A-320::vehicle` (the record's
        observable reading of "driver" is the plan's and is not restated).
    s2: `passedVehicle b` — b is of DEF-NRS-484A-320::vehicle, is not the subject, and
        `drv_interaction_overtake_pass_on_right(subject, b)` with p.overtake_window and
        p.overtake_same_direction_cos holds at the judged observation (the concept holds at the
        recognition only). Applicability: some such b. b is quantified, not a binder.
    Occasion (window boundary, read `throughout`): the obligation is
        `holdsFor .time p.overtake_window subject (underWay b → safe)` for every b that the
        applicability's selection picks (the whole selection is written again in the obligation).
        `underWay b` is written from the under_way element's atoms: an observation lies inside the
        act where, from it up to the recognition (strong `until` whose goal is the concept), b is
        not ahead of the subject with aligned headings — `aheadAligned`: rel.bearing "ahead"
        (longitudinal component positive), rel.longitudinal_overlap below zero, rel.same_direction
        with p.overtake_same_direction_cos — and the subject's velocity exceeds b's along the
        subject's heading (`closing`). So the observation is after the act's beginning (the last
        aligned-ahead observation) and at or before its recognition, as the justification states
        ("lies after its beginning ... and at or before its recognition").
        `closing` (kin.velocity): the subject's velocity along its own direction of travel exceeds
        b's, written without division as |v_subject|² > v_b · v_subject (the subject's velocity
        stands for its heading; multiplying both sides by |v_subject| ≥ 0). kin.heading is not
        claimed by the element, so the direction of travel is read from kin.velocity.
    s3: the record's operationalization: for every road user u other than the subject (b
        included), not rel.contact(subject, u), and not (prim.closest_approach_within(subject, u)
        over p.conflict_horizon and prim.closest_approach_distance(subject, u) over
        p.conflict_horizon below p.conflict_centre_clearance).

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_210_2

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- Quantified road users: `b` the vehicle passed, `u` any road user in the conflict check. -/
def vB : Arg := .var "b"
def vU : Arg := .var "u"

/-- The admitted aggregate. -/
def aggVehicle : Arg := .lit "DEF-NRS-484A-320::vehicle"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pConflictCentreClearance : Term := .param "p.conflict_centre_clearance"
def pConflictHorizon : Term := .param "p.conflict_horizon"
def pOvertakeSameDirectionCos : Term := .param "p.overtake_same_direction_cos"
def pOvertakeWindow : Term := .param "p.overtake_window"

def zeroMetres : Term := .lit Q.zero .metre

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, aggVehicle] []

/-- s2: the subject overtakes and passes `x` on `x`'s right (recognized here). -/
def passOnRight (x : Arg) : Formula :=
  .derived "drv_interaction_overtake_pass_on_right" [vSubject, x] [pOvertakeWindow, pOvertakeSameDirectionCos]

/-- s2: b is another vehicle, and the subject's pass on its right is recognized here. -/
def passedVehicle : Formula :=
  .and (.atom "ru_aggregate" [vB, aggVehicle] [])
    (.and (.not (.same vB vSubject)) (passOnRight vB))

/-- Applicability: some other vehicle b is passed on its right at this observation. -/
def applicability : Formula := .existsUser "b" passedVehicle

/-- under_way: b ahead of the subject with headings aligned (the act's beginning condition). -/
def aheadAligned : Formula :=
  .and (.atom "rel_bearing" [vSubject, vB, .lit "ahead"] [])
    (.and (.cmp (.measure "rel_longitudinal_overlap" [vSubject, vB]) .lt zeroMetres)
      (.atom "rel_same_direction" [vSubject, vB] [pOvertakeSameDirectionCos]))

def vel (x : Arg) (c : String) : Term := .measure "kin_velocity" [x, .lit c]

/-- under_way: the subject's velocity exceeds b's along the subject's direction of travel:
    |v_subject|² > v_b · v_subject. -/
def closing : Formula :=
  .cmp (.add (.mul (vel vSubject "x") (vel vSubject "x")) (.mul (vel vSubject "y") (vel vSubject "y")))
    .gt
    (.add (.mul (vel vB "x") (vel vSubject "x")) (.mul (vel vB "y") (vel vSubject "y")))

/-- under_way: this observation lies after the act's beginning and at or before its recognition. -/
def underWay : Formula := .until (.and (.not aheadAligned) closing) (passOnRight vB)

/-- s3: a conflict of the subject with road user u. -/
def conflictWith : Formula :=
  .or (.atom "rel_contact" [vSubject, vU] [])
    (.and (.derived "prim_closest_approach_within" [vSubject, vU] [pConflictHorizon])
      (.cmp (.quantity "prim_closest_approach_distance" [vSubject, vU] [pConflictHorizon]) .lt
        pConflictCentreClearance))

/-- s3: the movement is made in safety at this observation. -/
def safeMovement : Formula :=
  .forallUser "u" (.implies (.not (.same vU vSubject)) (.not conflictWith))

/-- Obligation: s2 (obligation): may overtake and pass another vehicle upon the right only; s3 (standard): under conditions permitting such movement in safety. -/
def obligation : Formula :=
  .forallUser "b" (.implies passedVehicle
    (.holdsFor .time pOvertakeWindow "subject" (.implies underWay safeMovement)))

def rule : Rule :=
  { id := "NRS_484B_210_2"
    laws := ["NRS-484B-210-2"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations :=
      [ { standard := "under conditions permitting such movement in safety"
          concepts := ["prim.closest_approach_distance", "prim.closest_approach_within", "rel.contact"]
          params := ["p.conflict_horizon", "p.conflict_centre_clearance"]
          convention := "Traffic-conflict technique: the movement is made in safety where, at every observation of the act, the subject is in contact (rel.contact) with no road user and no road user's closest approach to it under constant velocities (prim.closest_approach_within over p.conflict_horizon) comes closer than p.conflict_centre_clearance (prim.closest_approach_distance); the closest-approach distance is the measured magnitude the bound is compared with, so the verdict moves with how close the conflict is."
          surrogate := true } ]
    residues := []
    narrowings := []
    surrogate := true }

end TrafficSpec.Rules.NRS_484B_210_2
