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

  How each is written:
    s1  the subject's class: `ru_aggregate subject "DEF-NRS-484A-320::vehicle"` ('driver' is the
        plan's observable reading through the vehicle's controlled motion; nothing more is written).
    s2  applicability: some road user b, not the subject, of the same aggregate, with
        `drv_interaction_overtake_pass_on_right(subject, b)` over p.overtake_window and
        p.overtake_same_direction_cos recognized at the judged observation (the concept holds at the
        recognition only, so the rule is judged once per pass).
    s3  obligation, for every b so selected (the selection repeated in full): the occasion's
        `throughout` reading `holdsFor .time p.overtake_window subject (U → safe)`, where
          U (under way, from the occasion's atoms):
            * after the act's beginning: not ahead-aligned here, and `since (not AA) AA` — an
              ahead-aligned observation earlier with none since; AA is b ahead of the subject
              (rel_bearing "ahead"), the bodies' projections sharing no length
              (rel_longitudinal_overlap < 0) and headings aligned (rel_same_direction over
              p.overtake_same_direction_cos), as the record's under_way states;
            * the window behind the recognition bounds it at or before the recognition;
            * the subject's velocity exceeds b's along the subject's own direction of travel
              (kin_velocity): v_s·v_s > v_b·v_s, the comparison of the two components along v_s
              multiplied through by |v_s| (no division by a measured quantity);
          safe, for every road user u other than the subject (b included): not rel_contact, and
            not (prim_closest_approach_within over p.conflict_horizon with
            prim_closest_approach_distance over p.conflict_horizon below p.conflict_centre_clearance).
    Choices the text left open: "after the beginning" is written with `since` from each observation
    of the window: an observation counts as inside the act where an ahead-aligned observation
    precedes it with none in between. Where b was ahead, fell alongside and came ahead again within
    the window, the earlier alongside stretch is also read — the duty is checked on more
    observations, never fewer, so this is no narrowing of the duty.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_210_2

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"
/-- The overtaken road user, quantified at the judged observation. -/
def vB : Arg := .var "b"
/-- Any other road user the movement may conflict with. -/
def vU : Arg := .var "u"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pConflictCentreClearance : Term := .param "p.conflict_centre_clearance"
def pConflictHorizon : Term := .param "p.conflict_horizon"
def pOvertakeSameDirectionCos : Term := .param "p.overtake_same_direction_cos"
def pOvertakeWindow : Term := .param "p.overtake_window"

def zeroMetres : Term := .lit Q.zero .metre

/-- Membership of the admitted aggregate DEF-NRS-484A-320::vehicle. -/
def vehicle (x : Arg) : Formula := .atom "ru_aggregate" [x, .lit "DEF-NRS-484A-320::vehicle"] []

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula := vehicle vSubject

/-- The act: the subject overtakes and passes b on b's right, recognized here. -/
def passOnRight : Formula :=
  .derived "drv_interaction_overtake_pass_on_right" [vSubject, vB] [pOvertakeWindow, pOvertakeSameDirectionCos]

/-- b selected: another vehicle the subject passes on its right, recognized here. -/
def selected : Formula :=
  .and (.not (.same vB vSubject)) (.and (vehicle vB) passOnRight)

/-- Applicability: s2 — some other vehicle b passed on its right, recognized at this observation. -/
def applicability : Formula := .existsUser "b" selected

/-- b ahead of the subject with headings aligned: the act's beginning, at its last occurrence. -/
def aheadAligned : Formula :=
  .and (.atom "rel_bearing" [vSubject, vB, .lit "ahead"] [])
    (.and (.cmp (.measure "rel_longitudinal_overlap" [vSubject, vB]) .lt zeroMetres)
      (.atom "rel_same_direction" [vSubject, vB] [pOvertakeSameDirectionCos]))

def vel (x : Arg) (c : String) : Term := .measure "kin_velocity" [x, .lit c]

/-- The subject's velocity exceeds b's along the subject's direction of travel:
    v_s·v_s > v_b·v_s (both components along v_s, multiplied through by |v_s|). -/
def fasterAlong : Formula :=
  .cmp (.add (.mul (vel vSubject "x") (vel vSubject "x")) (.mul (vel vSubject "y") (vel vSubject "y")))
    .gt
    (.add (.mul (vel vB "x") (vel vSubject "x")) (.mul (vel vB "y") (vel vSubject "y")))

/-- Under way (occasion `under_way`): after the act's beginning (the last ahead-aligned
    observation), with the subject carried up to and past b by its greater velocity. -/
def underWay : Formula :=
  .and (.not aheadAligned) (.and (.since (.not aheadAligned) aheadAligned) fasterAlong)

/-- s3: no contact with u, and no closest approach to u within the horizon closer than the clearance. -/
def safeWith : Formula :=
  .and (.not (.atom "rel_contact" [vSubject, vU] []))
    (.not (.and (.derived "prim_closest_approach_within" [vSubject, vU] [pConflictHorizon])
      (.cmp (.quantity "prim_closest_approach_distance" [vSubject, vU] [pConflictHorizon]) .lt
        pConflictCentreClearance)))

/-- Obligation: s2 (obligation): may overtake and pass another vehicle upon the right only; s3 (standard): under conditions permitting such movement in safety. -/
def obligation : Formula :=
  .forallUser "b" (.implies selected
    (.holdsFor .time pOvertakeWindow "subject"
      (.implies underWay (.forallUser "u" (.implies (.not (.same vU vSubject)) safeWith)))))

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
