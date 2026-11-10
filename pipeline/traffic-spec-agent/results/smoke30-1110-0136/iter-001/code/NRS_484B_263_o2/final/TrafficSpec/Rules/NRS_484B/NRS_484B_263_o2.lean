/-
  NRS_484B_263_o2 — NRS-484B-263

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (subject): The driver of a vehicle
    s2 (trigger): about to enter or exit a controlled-access highway
    s3 (sibling): shall yield the right-of-way
    s4 (condition): to all vehicles approaching on the highway
    s5 (standard): whose proximity constitutes an immediate hazard
    s6 (obligation): and shall continue to yield
    s7 (standard): the right-of-way
    s8 (condition): to that traffic
    s9 (standard): until the driver may proceed with reasonable safety.

  Elements (span → atoms, derived):
    s1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    s2: atoms ['rel.occupies', 'st.controlled_access', 'st.highway'], derived []
    s4: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle', 'rel.occupies', 'st.controlled_access', 'st.highway'], derived ['drv.motion.moving']
    s6: atoms ['rel.occupies', 'st.controlled_access'], derived ['drv.motion.moving']
    s8: atoms ['ru.aggregate=DEF-NRS-484A-285::traffic'], derived []

  How each is written:
    s1: the binder class, `ru_aggregate x DEF-NRS-484A-320::vehicle`.
    s2: per controlled-access region `a` (`existsRegion controlled_access`), an entry is
        `rises (rel_occupies x a)` and an exit `rises (not (rel_occupies x a))`. At an exit the
        highway being entered is a `highway` region `h` x occupies at the exit observation; x
        does not occupy `a` there, so `h` is never `a` and no `same` test is written.
    s4/s5: a vehicle y other than x, moving (drv.motion.moving), occupying the highway being
        entered, with `rel_surface_gap x y ≤ kin_speed y · p.immediate_hazard_time_gap`.
        "At some observation of the run immediately before the event during which x stayed on
        the near side" is `since (near) (hazard ∧ near)` read at the observation before the
        event; that previous-observation value is `since (rises E) S` at the event (E the event's
        state, S the inner `since`): at the event S is false (x is no longer on the near side)
        and E did not rise at the observation before, so the outer `since` returns exactly S
        there. The run's start before the recording leaves the search unknown, as `since` reads it.
    s8: y also carries `ru_aggregate y DEF-NRS-484A-285::traffic`; that traffic is y with the
        whole selection of s4/s5, written once (`thatTraffic`) and bound again in the
        obligation, with the region `a` re-quantified over every controlled-access region and
        the event re-stated there.
    s6/s7/s9: where x is moving at the event (drv.motion.moving), no y of that traffic has
        `prim_closest_approach_within x y p.conflict_time_horizon` with
        `prim_closest_approach_distance x y p.conflict_time_horizon < p.conflict_centre_clearance`.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_263_o2

/-- The binders, as arguments (order and names are the node's). -/
def vX : Arg := .var "x"

/-- Quantified variables: the other vehicle, the controlled-access region, the highway entered at an exit. -/
def vY : Arg := .var "y"
def vA : Arg := .var "a"
def vH : Arg := .var "h"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pConflictCentreClearance : Term := .param "p.conflict_centre_clearance"
def pConflictTimeHorizon : Term := .param "p.conflict_time_horizon"
def pImmediateHazardTimeGap : Term := .param "p.immediate_hazard_time_gap"
def pMotionSpeedTolerance : Term := .param "p.motion_speed_tolerance"

def zeroMetres : Term := .lit Q.zero .metre

def isVehicle (v : Arg) : Formula := .atom "ru_aggregate" [v, .lit "DEF-NRS-484A-320::vehicle"] []
def isTraffic (v : Arg) : Formula := .atom "ru_aggregate" [v, .lit "DEF-NRS-484A-285::traffic"] []
def occupies (u r : Arg) : Formula := .atom "rel_occupies" [u, r] []
def moving (u : Arg) : Formula := .derived "drv_motion_moving" [u] [pMotionSpeedTolerance]

/-- Class of `x`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsX : Formula := isVehicle vX

/-- s4/s5: y moving on region `r` (the highway being entered), its body gap to x at most its
    speed times the critical gap. -/
def hazardOn (r : Arg) : Formula :=
  .and (moving vY)
    (.and (occupies vY r)
      (.cmp (.measure "rel_surface_gap" [vX, vY]) .le
        (.mul (.measure "kin_speed" [vY]) pImmediateHazardTimeGap)))

/-- s2 entry into `a`, with y a hazard on `a` at some observation of the run before it during
    which x stayed off `a`. -/
def entryHazard : Formula :=
  let on : Formula := occupies vX vA
  let off : Formula := .not on
  .and (.rises on)
    (.since (.rises on) (.since off (.and (hazardOn vA) off)))

/-- s2 exit from `a` onto a highway region `h` x occupies at the exit, with y a hazard on `h` at
    some observation of the run before it during which x stayed on `a`. -/
def exitHazard : Formula :=
  let on : Formula := occupies vX vA
  let off : Formula := .not on
  .and (.rises off)
    (.existsRegion (.lit "highway") "h"
      (.and (occupies vX vH)
        (.since (.rises off) (.since on (.and (hazardOn vH) on)))))

/-- s4/s5/s8: y is of that traffic at the event at `a`. -/
def thatTraffic : Formula :=
  .and (.not (.same vX vY))
    (.and (isVehicle vY)
      (.and (isTraffic vY) (.or entryHazard exitHazard)))

/-- s7/s9: a predicted closest approach of the centres within the horizon below the clearance. -/
def conflict : Formula :=
  .and (.derived "prim_closest_approach_within" [vX, vY] [pConflictTimeHorizon])
    (.cmp (.quantity "prim_closest_approach_distance" [vX, vY] [pConflictTimeHorizon]) .lt
      pConflictCentreClearance)

/-- Applicability: s2 (trigger): about to enter or exit a controlled-access highway; s4 (condition): to all vehicles approaching on the highway; s8 (condition): to that traffic -/
def applicability : Formula :=
  .existsRegion (.lit "controlled_access") "a" (.existsUser "y" thatTraffic)

/-- Obligation: s5 (standard): whose proximity constitutes an immediate hazard; s6 (obligation): and shall continue to yield; s7 (standard): the right-of-way; s9 (standard): until the driver may proceed with reasonable safety. -/
def obligation : Formula :=
  .implies (moving vX)
    (.forallRegion (.lit "controlled_access") "a"
      (.forallUser "y" (.implies thatTraffic (.not conflict))))

def rule : Rule :=
  { id := "NRS_484B_263_o2"
    laws := ["NRS-484B-263"]
    binders :=
      [ { name := "x", cls := clsX } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations :=
      [ { standard := "whose proximity constitutes an immediate hazard"
          concepts := ["kin.speed", "rel.surface_gap"]
          params := ["p.immediate_hazard_time_gap"]
          convention := "Gap acceptance for merging: the body gap (rel.surface_gap) at most the vehicle's speed (kin.speed) times the critical gap."
          surrogate := false }
      , { standard := "the right-of-way (DEF-NRS-484A-210: 'danger of a crash')"
          concepts := ["prim.closest_approach_distance", "prim.closest_approach_within"]
          params := ["p.conflict_time_horizon", "p.conflict_centre_clearance"]
          convention := "Traffic-conflict technique: the danger of a crash is a predicted closest approach of the two centres under constant velocities within the time-to-collision horizon at a centre distance below the clearance."
          surrogate := false }
      , { standard := "may proceed with reasonable safety"
          concepts := ["prim.closest_approach_distance", "prim.closest_approach_within"]
          params := ["p.conflict_time_horizon", "p.conflict_centre_clearance"]
          convention := "Traffic-conflict technique: x may proceed with reasonable safety once no vehicle of that traffic has a predicted closest approach to x within the time-to-collision horizon below the centre clearance."
          surrogate := false } ]
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_263_o2
