/-
  NRS_484B_263_o1 — NRS-484B-263

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (subject): The driver of a vehicle
    s2 (trigger): about to enter or exit a controlled-access highway
    s3 (obligation): shall yield
    s4 (standard): the right-of-way
    s5 (condition): to all vehicles approaching on the highway
    s6 (standard): whose proximity constitutes an immediate hazard
    s7 (sibling): and shall continue to yield the right-of-way to that traffic until the driver may proceed with reasonable safety.

  Elements (span → atoms, derived):
    s1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    s2: atoms ['rel.occupies', 'st.controlled_access', 'st.highway'], derived []
    s3: atoms ['rel.occupies', 'st.controlled_access'], derived ['drv.motion.moving']
    s5: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle', 'rel.occupies', 'st.controlled_access', 'st.highway'], derived ['drv.motion.moving']

  How each span is written:
    s1: x's class is the vehicle aggregate (ru_aggregate DEF-NRS-484A-320::vehicle).
    s2: over every controlled-access region a, the entry is `rises (rel_occupies x a)` and the exit
        `rises (not (rel_occupies x a))`; at an exit the highway being entered is a region h of
        kind highway that x occupies there.
    s5/s6: a vehicle y other than x, moving (drv_motion_moving), on the highway being entered (at an
        entry rel_occupies y a; at an exit rel_occupies y h and not a), whose surface gap to x is
        at most its speed times p.immediate_hazard_time_gap.
    s3/s4: where x is moving, for every such a, h and y (the applicability's whole selection again),
        not (closest approach within p.conflict_time_horizon and the centre distance there below
        p.conflict_centre_clearance).
  Choices: none beyond the record's own narrowings. The surface gap is read as the distance between
  the bodies (rel_surface_gap without a component).

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_263_o1

/-- The binders, as arguments (order and names are the node's). -/
def vX : Arg := .var "x"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pConflictCentreClearance : Term := .param "p.conflict_centre_clearance"
def pConflictTimeHorizon : Term := .param "p.conflict_time_horizon"
def pImmediateHazardTimeGap : Term := .param "p.immediate_hazard_time_gap"
def pMotionSpeedTolerance : Term := .param "p.motion_speed_tolerance"

def zeroMetres : Term := .lit Q.zero .metre

/-- Quantifier variables: `a` the controlled-access region, `h` the highway region x moves onto at
    an exit, `y` the vehicle approaching on the highway being entered. -/
def vA : Arg := .var "a"
def vH : Arg := .var "h"
def vY : Arg := .var "y"

def vehicleAggregate : Arg := .lit "DEF-NRS-484A-320::vehicle"

/-- s1, s5: membership of the vehicle aggregate. -/
def vehicle (u : Arg) : Formula := .atom "ru_aggregate" [u, vehicleAggregate] []

def occupies (u r : Arg) : Formula := .atom "rel_occupies" [u, r] []

/-- s3, s5: in motion at the observation (drv.motion.moving). -/
def moving (u : Arg) : Formula := .derived "drv_motion_moving" [u] [pMotionSpeedTolerance]

/-- s2: the entry, x's footprint overlaps `a` and did not at the observation before. -/
def entry : Formula := .rises (occupies vX vA)

/-- s2: the exit, x's footprint no longer overlaps `a` and did at the observation before. -/
def exit : Formula := .rises (.not (occupies vX vA))

/-- s6: proximity an immediate hazard, the body gap to x at most y's speed times the critical gap
    (a bound on a ratio written as a bound on a product). -/
def immediateHazard : Formula :=
  .cmp (.measure "rel_surface_gap" [vY, vX]) .le
    (.mul (.measure "kin_speed" [vY]) pImmediateHazardTimeGap)

/-- s5 with s6: y a vehicle other than x, moving, whose proximity is an immediate hazard. -/
def approaching : Formula :=
  .and (.not (.same vY vX)) (.and (vehicle vY) (.and (moving vY) immediateHazard))

/-- s5 at an entry: y on the controlled-access region being entered. -/
def onHighwayAtEntry : Formula := .and approaching (occupies vY vA)

/-- s5 at an exit: y on the highway region `h` x moves onto, and not on `a`. -/
def onHighwayAtExit : Formula := .and approaching (.and (occupies vY vH) (.not (occupies vY vA)))

/-- s4: the danger of a crash, a predicted closest approach of the centres within the horizon at a
    centre distance below the clearance. -/
def conflict : Formula :=
  .and (.derived "prim_closest_approach_within" [vX, vY] [pConflictTimeHorizon])
    (.cmp (.quantity "prim_closest_approach_distance" [vX, vY] [pConflictTimeHorizon]) .lt
      pConflictCentreClearance)

/-- Class of `x`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsX : Formula := vehicle vX

/-- Applicability: s2 (trigger): about to enter or exit a controlled-access highway; s5 (condition): to all vehicles approaching on the highway -/
def applicability : Formula :=
  .existsRegion (.lit "controlled_access") "a"
    (.or (.and entry (.existsUser "y" onHighwayAtEntry))
         (.and exit
           (.existsRegion (.lit "highway") "h"
             (.and (occupies vX vH) (.existsUser "y" onHighwayAtExit)))))

/-- Obligation: s3 (obligation): shall yield; s4 (standard): the right-of-way; s6 (standard): whose proximity constitutes an immediate hazard -/
def obligation : Formula :=
  .implies (moving vX)
    (.forallRegion (.lit "controlled_access") "a"
      (.and
        (.implies entry (.forallUser "y" (.implies onHighwayAtEntry (.not conflict))))
        (.implies exit
          (.forallRegion (.lit "highway") "h"
            (.implies (occupies vX vH)
              (.forallUser "y" (.implies onHighwayAtExit (.not conflict))))))))

def rule : Rule :=
  { id := "NRS_484B_263_o1"
    laws := ["NRS-484B-263"]
    binders :=
      [ { name := "x", cls := clsX } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations :=
      [ { standard := "the right-of-way (DEF-NRS-484A-210: 'circumstances of direction, speed and proximity as to give rise to the danger of a crash')"
          concepts := ["prim.closest_approach_distance", "prim.closest_approach_within"]
          params := ["p.conflict_time_horizon", "p.conflict_centre_clearance"]
          convention := "Traffic-conflict technique: the danger of a crash is a predicted closest approach of the two centres under constant velocities within the time-to-collision horizon at a centre distance below the clearance."
          surrogate := false }
      , { standard := "whose proximity constitutes an immediate hazard"
          concepts := ["kin.speed", "rel.surface_gap"]
          params := ["p.immediate_hazard_time_gap"]
          convention := "Gap acceptance for merging: a vehicle on the highway is an immediate hazard where the gap between the bodies (rel.surface_gap 'distance between the nearest points of two bodies') is at most its speed (kin.speed) times the critical gap, so the bound moves with its speed."
          surrogate := false } ]
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []  -- one { span := "<span id>", why := "<why>", kind := "reading" } per reading you chose on a carried span (kind no_atom / no_operator where the words cannot be stated), explained in the header; the record's own narrowings are not restated
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_263_o1
