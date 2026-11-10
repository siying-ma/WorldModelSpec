/-
  NRS_484B_560_7a — NRS-484B-560-7a

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (subject): It is unlawful for the driver of any vehicle:
    s2 (trigger): When crossing at grade any track or tracks of a railroad,
    s3 (obligation): to fail to completely cross the track or tracks without stopping
    s4 (condition): due to insufficient: (1) Space for the vehicle on the opposite side of the railroad crossing;
    s5 (condition): or (2) Undercarriage clearance of the vehicle.
    s6 (definitional): As used in this section, “completely cross” means to travel across a railroad track or tracks in such a manner that the trailing end of the vehicle is 15 feet or more past the nearest rail of the railroad track or tracks.

  Elements (span → atoms, derived):
    s1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    s2: atoms ['st.railway_crossing', 'rel.occupies', 'st.region_geometry'], derived []
    s3: atoms ['st.railway_crossing', 'rel.occupies', 'st.region_geometry', 'dev.human_direction', 'dev.governs', 'st.travel_region', 'prim.closest_approach_within', 'prim.closest_approach_distance'], derived ['drv.motion.stopped']
    s4: atoms ['rel.bearing', 'rel.surface_gap'], derived []
    s6: atoms ['st.railway_crossing', 'st.region_geometry', 'rel.occupies'], derived []

  Literals the text states (each written through its Units constructor):
    s6: 15 ft — 15 feet

  No magnitude below is this file's own: parameters name the reading, literals are the text's.

  How each span is written:
    s1: the binder class `ru_aggregate x "DEF-NRS-484A-320::vehicle"`; 'the driver of' claims nothing
        (the record's observable reading, agency): the duty reads the vehicle's own motion.
    s2 + s6 (`onCrossing r`): x is crossing railway crossing r (a region of kind `railway_crossing`)
        when its footprint overlaps r now, or overlapped r at an earlier observation and its body has
        been less than 15 ft (`Units.feet 15`, the s6 literal) from r's outline
        (`st_region_geometry_distance`) at every observation since: `since (dist < 15 ft) (occupies)`.
        Once the distance reaches the literal the vehicle has completely crossed and the `since`
        fails for good; a vehicle short of a crossing it has not entered never satisfies it.
    applicability: some railway crossing r with `onCrossing r`.
    obligation: for every railway crossing r with `onCrossing r` (the applicability's whole
        selection, bound again), x is not (halted ∧ due to an insufficiency ∧ not excused), where
      halted (s3): `drv_motion_stopped x` with `p.motion_speed_tolerance` (DEF-NRS-484A-260's
        "any halting, even momentarily", the halt at one observation);
      due to insufficient space (s4, the record's observable reading, purpose): some road user y
        other than x with `rel_bearing x y "ahead"` (the bearing's longitudinal component positive)
        and the gap between the bodies `rel_surface_gap x y` (the distance, no component) at most
        `p.queue_standstill_gap`;
      or due to insufficient undercarriage clearance (s5): the declared `asm.undercarriage_grounded`;
      excused (s3, the stopping definition's exclusions as the record reads them): some road user z
        other than x whose centre approaches x's within `p.conflict_time_horizon`
        (`prim_closest_approach_within z x`) at a centre distance below
        `p.conflict_centre_clearance` (`prim_closest_approach_distance z x`); or a `human_direction`
        device d with role `police_officer` and indication `stop` governing (`dev_governs`) a
        `travel_region` q that x occupies.
    Where x is halted on the crossing, no road user is ahead within the gap and the assumption is
    undeclared, the cause is unknown and so is the verdict, as the record states.

  Choices the record left open: none beyond the record's own narrowings. The road user y of s4 and
  z of the conflict exclusion are quantified over every road user of the scene other than x (the
  record names no class for either).
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_560_7a

/-- The binders, as arguments (order and names are the node's). -/
def vX : Arg := .var "x"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pConflictCentreClearance : Term := .param "p.conflict_centre_clearance"
def pConflictTimeHorizon : Term := .param "p.conflict_time_horizon"
def pMotionSpeedTolerance : Term := .param "p.motion_speed_tolerance"
def pQueueStandstillGap : Term := .param "p.queue_standstill_gap"

def zeroMetres : Term := .lit Q.zero .metre

/-- s6: "15 feet or more past the nearest rail". -/
def completelyCrossed : Term := .lit (Units.feet 15) .metre

/-- Class of `x`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsX : Formula := .atom "ru_aggregate" [vX, .lit "DEF-NRS-484A-320::vehicle"] []

/-- s2 + s6: x is crossing railway crossing `r` — its footprint overlaps `r`, or overlapped it and
    its body has stayed less than the s6 distance from `r` at every observation since. -/
def onCrossing (r : String) : Formula :=
  .since
    (.cmp (.measure "st_region_geometry_distance" [vX, .var r]) .lt completelyCrossed)
    (.atom "rel_occupies" [vX, .var r] [])

/-- s3: x halted at the observation. -/
def halted : Formula := .derived "drv_motion_stopped" [vX] [pMotionSpeedTolerance]

/-- s4: some road user y other than x ahead of x with the gap between their bodies within the
    queue standstill gap. -/
def spaceTaken : Formula :=
  .existsUser "y"
    (.and (.not (.same (.var "y") vX))
      (.and (.atom "rel_bearing" [vX, .var "y", .lit "ahead"] [])
        (.cmp (.measure "rel_surface_gap" [vX, .var "y"]) .le pQueueStandstillGap)))

/-- s5: the vehicle lacks the undercarriage clearance (declared assumption). -/
def grounded : Formula := .asm "asm.undercarriage_grounded"

/-- s3, the stopping definition's exclusion of a halt to avoid conflict with other traffic: some
    road user z other than x predicted to come within the conflict clearance of x within the
    conflict horizon. -/
def conflictAvoided : Formula :=
  .existsUser "z"
    (.and (.not (.same (.var "z") vX))
      (.and (.derived "prim_closest_approach_within" [.var "z", vX] [pConflictTimeHorizon])
        (.cmp (.quantity "prim_closest_approach_distance" [.var "z", vX] [pConflictTimeHorizon])
          .lt pConflictCentreClearance)))

/-- s3, the stopping definition's exclusion of a halt in compliance with a police officer's
    direction: an officer directing stop governs a travel region x occupies. -/
def officerDirected : Formula :=
  .existsDevice (.lit "human_direction") "d"
    (.and (.atom "dev_human_direction_role" [.var "d", .lit "police_officer"] [])
      (.and (.atom "dev_human_direction_indication" [.var "d", .lit "stop"] [])
        (.existsRegion (.lit "travel_region") "q"
          (.and (.atom "dev_governs" [.var "d", .var "q"] [])
            (.atom "rel_occupies" [vX, .var "q"] [])))))

/-- Applicability: s2 (trigger) with s6: x is crossing some railway crossing at grade. -/
def applicability : Formula :=
  .existsRegion (.lit "railway_crossing") "r" (onCrossing "r")

/-- Obligation: s3 (obligation): to fail to completely cross the track or tracks without stopping,
    due to s4/s5, unless the halt is one the stopping definition excludes. -/
def obligation : Formula :=
  .forallRegion (.lit "railway_crossing") "r"
    (.implies (onCrossing "r")
      (.not (.and halted
        (.and (.or spaceTaken grounded)
          (.not (.or conflictAvoided officerDirected))))))

def rule : Rule :=
  { id := "NRS_484B_560_7a"
    laws := ["NRS-484B-560-7a"]
    binders :=
      [ { name := "x", cls := clsX } ]
    applicability := applicability
    obligation := obligation
    assumptions := ["asm.undercarriage_grounded"]
    intentions := []
    operationalizations := []
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []  -- one { span := "<span id>", why := "<why>", kind := "reading" } per reading you chose on a carried span (kind no_atom / no_operator where the words cannot be stated), explained in the header; the record's own narrowings are not restated
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_560_7a
