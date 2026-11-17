/-
  NRS_484B_210_3 — NRS-484B-210-3

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (subject): The driver of a vehicle
    s2 (obligation): shall not overtake and pass another vehicle upon the right
    s3 (condition): when such movement requires driving off the paved portion of the highway.

  Elements (span → atoms, derived):
    s1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    s2: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived ['drv.interaction.overtake_pass_on_right']
    s3: atoms ['rel.occupies', 'st.shoulder', 'st.road_edge'], derived []

  How each is written.
    s1: the subject's class is `ru_aggregate subject DEF-NRS-484A-320::vehicle`; 'driver' is the
        record's observable reading (the vehicle's conduct), not restated.
    s2: the act is `drv_interaction_overtake_pass_on_right(subject, b)` with p.overtake_window and
        p.overtake_same_direction_cos, b another road user (`not (same subject b)`) of
        DEF-NRS-484A-320::vehicle. The applicability quantifies b (some such b at the judged
        observation); the obligation re-selects b with the same whole selection and requires the
        duty for every such b.
    s3: off the paved portion = the subject's footprint overlaps (rel_occupies) an st.shoulder whose
        paved attribute is false, or an st.road_edge whose paved attribute (for the surface beyond
        it) is false. Read `some_moment` over the occasion, boundary `window`:
          some_moment = not (holdsFor time W subject (not (U and offPaved)))
        and the obligation is its negation (at no observation of the act is the subject off the
        pavement).
    occasion (under_way U, for b): the observation lies inside the act — after its beginning (the
        last observation at which b was ahead of the subject with aligned headings: rel_bearing
        "ahead", rel_longitudinal_overlap below zero, rel_same_direction within
        p.overtake_same_direction_cos) and at or before its recognition. Written as
          untilWithin time W subject (not aheadAligned) (overtake_pass_on_right subject b)
        — from the observation, b is never again ahead-aligned up to a recognition of the pass in
        the window ahead — conjoined with the subject's velocity exceeding b's along the subject's
        direction of motion: v_s·v_s > v_b·v_s (kin_velocity components), which is "the subject's
        velocity exceeding b's along its heading" stated without dividing by a measured magnitude
        and without reading kin.heading, which the node does not claim; for a vehicle moving
        forward its velocity points along its heading.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_210_3

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"
/-- The other vehicle, quantified (not a binder). -/
def vB : Arg := .var "b"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pOvertakeSameDirectionCos : Term := .param "p.overtake_same_direction_cos"
def pOvertakeWindow : Term := .param "p.overtake_window"

def zeroMetres : Term := .lit Q.zero .metre

def aggVehicle : String := "DEF-NRS-484A-320::vehicle"

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, .lit aggVehicle] []

/-- s2: the subject overtakes and passes b, another vehicle, on b's right. -/
def passOnRight : Formula :=
  .and (.atom "ru_aggregate" [vB, .lit aggVehicle] [])
    (.and (.not (.same vSubject vB))
      (.derived "drv_interaction_overtake_pass_on_right" [vSubject, vB]
        [pOvertakeWindow, pOvertakeSameDirectionCos]))

/-- b ahead of the subject with headings aligned (the act's beginning, as the occasion states it). -/
def aheadAligned : Formula :=
  .and (.atom "rel_bearing" [vSubject, vB, .lit "ahead"] [])
    (.and (.cmp (.measure "rel_longitudinal_overlap" [vSubject, vB]) .lt zeroMetres)
      (.atom "rel_same_direction" [vSubject, vB] [pOvertakeSameDirectionCos]))

def vel (x : Arg) (c : String) : Term := .measure "kin_velocity" [x, .lit c]

/-- The subject's velocity exceeds b's along the subject's direction of motion: v_s·v_s > v_b·v_s. -/
def subjectFaster : Formula :=
  .cmp (.add (.mul (vel vSubject "x") (vel vSubject "x")) (.mul (vel vSubject "y") (vel vSubject "y")))
    .gt
    (.add (.mul (vel vB "x") (vel vSubject "x")) (.mul (vel vB "y") (vel vSubject "y")))

/-- Occasion `under_way` U: the observation lies inside the act (after its beginning, at or before
    its recognition), the subject carrying itself up to and past b. -/
def underWay : Formula :=
  .and (.untilWithin .time pOvertakeWindow "subject" (.not aheadAligned) passOnRight)
    subjectFaster

/-- s3: the subject's footprint overlaps an unpaved shoulder or a road edge with an unpaved surface beyond. -/
def offPaved : Formula :=
  .or
    (.existsRegion (.lit "shoulder") "r"
      (.and (.atom "rel_occupies" [vSubject, .var "r"] [])
        (.not (.atom "st_shoulder_paved" [.var "r"] []))))
    (.existsRegion (.lit "road_edge") "e"
      (.and (.atom "rel_occupies" [vSubject, .var "e"] [])
        (.not (.atom "st_road_edge_paved" [.var "e"] []))))

/-- s3 read `some_moment` over the act (boundary `window`, p.overtake_window). -/
def s3SomeMoment : Formula :=
  .not (.holdsFor .time pOvertakeWindow "subject" (.not (.and underWay offPaved)))

/-- Applicability: s2's act recognized at the judged observation, for some other vehicle b. -/
def applicability : Formula := .existsUser "b" passOnRight

/-- Obligation: for every vehicle b passed on its right here, at no observation of the act was the
    subject off the paved portion of the highway (s3). -/
def obligation : Formula :=
  .forallUser "b" (.implies passOnRight (.not s3SomeMoment))

def rule : Rule :=
  { id := "NRS_484B_210_3"
    laws := ["NRS-484B-210-3"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations := []
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_210_3
