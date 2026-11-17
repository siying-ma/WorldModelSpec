/-
  NRS_484B_777_1_o2 — NRS-484B-777-1

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (subject): Every person operating a bicycle, an electric bicycle or an electric scooter
    s2 (condition): upon a roadway shall, except:
    s3 (sibling): (a) When traveling at a lawful rate of speed
    s4 (sibling): commensurate with the speed of
    s4b (sibling): any nearby traffic;
    s5 (sibling): (b) When preparing to turn left;
    s6 (boilerplate): or
    s7 (sibling): (c) When doing so would not be safe,
    s8 (sibling): ride as near to the right side of the roadway
    s9 (sibling): as practicable,
    s10 (obligation): exercising due care
    s11 (trigger): when passing a standing vehicle or one proceeding in the same direction.
    s12 (sibling): For purposes of paragraph (c) of subsection 1, the conditions under which it is not safe to operate a bicycle, an electric bicycle or an electric scooter as near to the right side of the roadway as practicable include, without limitation:
    s13 (sibling): (a) When fixed or moving objects, parked or moving vehicles, bicycles, pedestrians, animals or surface hazards impede access to the right side of the roadway.
    s14 (sibling): (b) When a lane is too narrow for a bicycle and a vehicle to travel safely side by side within the lane.

  Elements (span → atoms, derived):
    s1: atoms ['ru.aggregate=DEF-NRS-484A-025::bicycle', 'ru.aggregate=DEF-NRS-484B-017::electric_bicycle', 'ru.aggregate=DEF-NRS-484B-018::electric_scooter'], derived []
    s2: atoms ['rel.occupies', 'st.roadway'], derived []
    s11: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle', 'kin.speed', 'rel.same_direction'], derived ['drv.interaction.overtake_pass', 'drv.motion.complete_halt']

  How each is written:
    s1: the binder class is the disjunction of the three `ru_aggregate` atoms on the subject.
    s11: `existsUser b` with b not the subject, `ru_aggregate b DEF-NRS-484A-320::vehicle`, and
        `drv_interaction_overtake_pass(subject, b)` recognized at the judged observation
        (p.overtake_window, p.overtake_same_direction_cos). "Standing" / "proceeding in the same
        direction" select the clearance in the obligation (as the record places them): standing
        is `drv_motion_complete_halt(b)` (p.halt_speed_tolerance), proceeding is `kin_speed b`
        above that tolerance with `rel_same_direction(subject, b)`.
    s2: `existsRegion roadway r (rel_occupies subject r)`, read at some observation since the act
        began: `since (not actStart) onRoadway`.
    s10 (operationalization): at every observation after the act's start up to the recognition
        (`since careHere actStart`), where `rel_longitudinal_overlap ≥ 0`: not `rel_contact`, and
        the lateral `rel_surface_gap` ≥ p.door_swing_reach where b is at rest and
        ≥ p.bicycle_pass_safe_gap where b is proceeding the same way.

  The act's start (record: the last observation of the window behind at which b was ahead of the
  subject with headings aligned) is located with the claimed atoms: `actStart` is b clear of the
  subject along its heading (rel_longitudinal_overlap < 0) with headings aligned
  (rel_same_direction), at an observation that is not a recognition of the pass. Between the
  start and its recognition b is not behind the subject (the concept recognizes the first
  observation at which b is behind), so the latest such observation before the recognition is
  the start; the recognition itself (b clear behind) is excluded by `not overtakePass`. The
  bearing atoms that tell ahead from behind are not claimed; this is the writing of the record's
  boundary through what it claims, not a narrower reading.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_777_1_o2

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pBicyclePassSafeGap : Term := .param "p.bicycle_pass_safe_gap"
def pDoorSwingReach : Term := .param "p.door_swing_reach"
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"
def pOvertakeSameDirectionCos : Term := .param "p.overtake_same_direction_cos"
def pOvertakeWindow : Term := .param "p.overtake_window"

def zeroMetres : Term := .lit Q.zero .metre

/-- The passed road user, bound by the quantifiers below (never the subject). -/
def vB : Arg := .var "b"

/-- s1: the three admitted aggregates, each one `ru_aggregate` atom on the subject. -/
def clsSubject : Formula :=
  .or (.atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-025::bicycle"] [])
    (.or (.atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484B-017::electric_bicycle"] [])
      (.atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484B-018::electric_scooter"] []))

/-- s11: the pass of b, recognized here (window p.overtake_window, heading tolerance
    p.overtake_same_direction_cos). -/
def overtakePass : Formula :=
  .derived "drv_interaction_overtake_pass" [vSubject, vB] [pOvertakeWindow, pOvertakeSameDirectionCos]

/-- The bodies' projections on the subject's heading share no length / share some length. -/
def overlap : Term := .measure "rel_longitudinal_overlap" [vSubject, vB]
def clear : Formula := .cmp overlap .lt zeroMetres
def sideBySide : Formula := .cmp overlap .ge zeroMetres

/-- The observation that begins the act, as the obligation and applicability locate it: b clear
    of the subject along its heading with headings aligned (rel.same_direction), at an observation
    that is not itself the recognition of the pass (where b is clear behind). The latest such
    observation before a recognition is the last at which b was ahead with headings aligned. -/
def actStart : Formula :=
  .and clear (.and (.atom "rel_same_direction" [vSubject, vB] [pOvertakeSameDirectionCos]) (.not overtakePass))

/-- s2: the subject's footprint overlaps a roadway. -/
def onRoadway : Formula :=
  .existsRegion (.lit "roadway") "r" (.atom "rel_occupies" [vSubject, .var "r"] [])

/-- s2 read over the act: the subject was on a roadway at some observation from the act's start
    up to here (a roadway observation after which no act start was seen). -/
def onRoadwayDuringAct : Formula := .since (.not actStart) onRoadway

/-- s11 and s2: b of the vehicle aggregate, other than the subject, passed here, the subject on a
    roadway at some observation of the act. -/
def selection : Formula :=
  .and (.not (.same vB vSubject))
    (.and (.atom "ru_aggregate" [vB, .lit "DEF-NRS-484A-320::vehicle"] [])
      (.and overtakePass onRoadwayDuringAct))

/-- Applicability: s2 (condition) and s11 (trigger): some such b. -/
def applicability : Formula := .existsUser "b" selection

/-- b at rest (standing) / b moving with its heading aligned with the subject's (proceeding in the
    same direction). -/
def bAtRest : Formula := .derived "drv_motion_complete_halt" [vB] [pHaltSpeedTolerance]
def bProceedingSameWay : Formula :=
  .and (.cmp (.measure "kin_speed" [vB]) .gt pHaltSpeedTolerance)
    (.atom "rel_same_direction" [vSubject, vB] [pOvertakeSameDirectionCos])

/-- The lateral component of the body gap. -/
def lateralGap : Term := .measure "rel_surface_gap" [vSubject, vB, .lit "lateral"]

/-- s10 at one observation: where side by side, no contact and the clearance the passed
    vehicle's motion selects there. -/
def careHere : Formula :=
  .implies sideBySide
    (.and (.not (.atom "rel_contact" [vSubject, vB] []))
      (.and (.implies bAtRest (.cmp lateralGap .ge pDoorSwingReach))
        (.implies bProceedingSameWay (.cmp lateralGap .ge pBicyclePassSafeGap))))

/-- Obligation: s10 (obligation): for each b the applicability selects, care at every observation
    after the act's start up to the recognition (the start itself has b clear ahead). -/
def obligation : Formula :=
  .forallUser "b" (.implies selection (.since careHere actStart))

def rule : Rule :=
  { id := "NRS_484B_777_1_o2"
    laws := ["NRS-484B-777-1"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations :=
      [ { standard := "exercising due care when passing"
          concepts := ["drv.motion.complete_halt", "rel.contact", "rel.longitudinal_overlap", "rel.surface_gap"]
          params := ["p.door_swing_reach", "p.bicycle_pass_safe_gap", "p.halt_speed_tolerance", "p.overtake_window", "p.overtake_same_direction_cos"]
          convention := "Due care is a standard of the rider's state of mind; it is bounded by the clearance kept while passing. At every observation of the pass at which the two bodies are side by side (rel.longitudinal_overlap at or above zero) the bodies do not touch (rel.contact) and the lateral component of their body gap (rel.surface_gap) is at least p.door_swing_reach where the passed vehicle is at rest (the reach of a door opened into the rider's path) and at least p.bicycle_pass_safe_gap where it moves (the bicyclist's operating-space sway beyond its body width); the bound is selected by the passed vehicle's motion at each such observation."
          surrogate := true } ]
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []  -- one { span := "<span id>", why := "<why>", kind := "reading" } per reading you chose on a carried span (kind no_atom / no_operator where the words cannot be stated), explained in the header; the record's own narrowings are not restated
    surrogate := true }

end TrafficSpec.Rules.NRS_484B_777_1_o2
