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
    s1: the binder `x` is a member of DEF-NRS-484A-320::vehicle (`ru_aggregate`).
    s2: an entry of x into a controlled-access region `a` is `rises (rel_occupies x a)`; an exit is
        `rises (not (rel_occupies x a))`. Every region `a` of kind controlled_access is judged
        (`existsRegion "controlled_access"`, anchored by `rel_occupies x a`).
    s4/s5/s8 (that traffic, `thatTraffic`): a road user `y`, not x (`same`), a member of both
        DEF-NRS-484A-320::vehicle and DEF-NRS-484A-285::traffic, and for some controlled-access
        region `a` either
          entry limb: x enters a now, and `since φ ψ` holds with ψ = x off a ∧ y approaching on a,
            φ = x off a ∨ x entering a (the latter only to let the run end at the judged entry);
          exit limb: x exits a now onto a highway region `h` it occupies now (h is not a, since x
            does not occupy a now), and `since φ ψ` holds with ψ = x on a ∧ y approaching on h,
            φ = x on a ∨ x leaving a.
        "Approaching" is y moving (drv.motion.moving, p.motion_speed_tolerance), occupying the
        highway being entered, with a body gap to x (rel_surface_gap, the distance) at most its
        speed (kin_speed) times p.immediate_hazard_time_gap (s5, written as a product).
        `since` is the run of observations immediately before the event during which x stayed on
        the near side: the near-side observations are φ, the judged event observation is let in by
        the disjunct `rises …`, and the run reaching back past the trace start is unknown.
        The run is read only at the event (`definedWhen <event> (since …)`, conjoined with the
        event): where the event is false the limb is false as before; where it is unknown (x's
        occupancy unobserved) the limb is unknown for that reason alone, not for a run that an
        unobserved occupancy can no longer bound and so reaches back past the recording.
        Sampling note: an earlier event observation is also let in by that disjunct, so a stay of
        exactly one observation on the far side does not end the run; at any slower crossing the
        run ends at the observation before the event exactly as the record states.
    s6/s7/s9 (obligation): where x is moving at the observation (drv.motion.moving), no road user
        `y` of that traffic — `thatTraffic` again, the whole selection with its regions and run —
        has a predicted closest approach to x within p.conflict_time_horizon
        (prim_closest_approach_within) at a centre distance below p.conflict_centre_clearance
        (prim_closest_approach_distance, undefined and so not read where no approach is predicted).

  No choice on a carried span beyond the record's: no narrowing is declared.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_263_o2

/-- The binders, as arguments (order and names are the node's). -/
def vX : Arg := .var "x"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pConflictCentreClearance : Term := .param "p.conflict_centre_clearance"
def pConflictTimeHorizon : Term := .param "p.conflict_time_horizon"
def pImmediateHazardTimeGap : Term := .param "p.immediate_hazard_time_gap"
def pMotionSpeedTolerance : Term := .param "p.motion_speed_tolerance"

def zeroMetres : Term := .lit Q.zero .metre

/-- The other variables: `y` the vehicle of that traffic, `a` the controlled-access region, `h` the
    highway region x moves onto at an exit. -/
def vY : Arg := .var "y"

def vehicle (u : Arg) : Formula := .atom "ru_aggregate" [u, .lit "DEF-NRS-484A-320::vehicle"] []
def traffic (u : Arg) : Formula := .atom "ru_aggregate" [u, .lit "DEF-NRS-484A-285::traffic"] []
def occupies (u r : String) : Formula := .atom "rel_occupies" [.var u, .var r] []
def moving (u : String) : Formula := .derived "drv_motion_moving" [.var u] [pMotionSpeedTolerance]

/-- s2: x off the controlled-access region `a`, entering it, leaving it. -/
def offA : Formula := .not (occupies "x" "a")
def entersA : Formula := .rises (occupies "x" "a")
def exitsA : Formula := .rises offA

/-- s4/s5: y moving on the highway region `r` being entered, its body gap to x at most its speed
    times the critical gap. -/
def approachingOn (r : String) : Formula :=
  .and (moving "y")
    (.and (occupies "y" r)
      (.cmp (.measure "rel_surface_gap" [vX, vY]) .le (.mul (.measure "kin_speed" [vY]) pImmediateHazardTimeGap)))

/-- s2/s4: x enters `a` now, and y approached on `a` at some observation of the run just before
    during which x stayed off `a`. -/
def entryLimb : Formula :=
  .and entersA (.definedWhen entersA (.since (.or offA entersA) (.and offA (approachingOn "a"))))

/-- s2/s4: x exits `a` now onto a highway region `h`, and y approached on `h` at some observation
    of the run just before during which x stayed on `a`. -/
def exitLimb : Formula :=
  .and exitsA
    (.definedWhen exitsA
      (.existsRegion (.lit "highway") "h"
        (.and (occupies "x" "h")
          (.since (.or (occupies "x" "a") exitsA) (.and (occupies "x" "a") (approachingOn "h"))))))

/-- s8: y is of that traffic — a vehicle other than x, a member of traffic, whose proximity was an
    immediate hazard before an entry or an exit of x judged now. -/
def thatTraffic : Formula :=
  .and (.not (.same vX vY))
    (.and (vehicle vY)
      (.and (traffic vY)
        (.existsRegion (.lit "controlled_access") "a" (.or entryLimb exitLimb))))

/-- s7/s9: a predicted closest approach of the centres within the horizon below the clearance. -/
def predictedConflict : Formula :=
  .and (.derived "prim_closest_approach_within" [vX, vY] [pConflictTimeHorizon])
    (.cmp (.quantity "prim_closest_approach_distance" [vX, vY] [pConflictTimeHorizon]) .lt pConflictCentreClearance)

/-- Class of `x`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsX : Formula := vehicle vX

/-- Applicability: s2 (trigger): about to enter or exit a controlled-access highway; s4 (condition): to all vehicles approaching on the highway; s8 (condition): to that traffic -/
def applicability : Formula := .existsUser "y" thatTraffic

/-- Obligation: s5 (standard): whose proximity constitutes an immediate hazard; s6 (obligation): and shall continue to yield; s7 (standard): the right-of-way; s9 (standard): until the driver may proceed with reasonable safety. -/
def obligation : Formula :=
  .implies (moving "x") (.forallUser "y" (.implies thatTraffic (.not predictedConflict)))

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
    narrowings := []  -- one { span := "<span id>", why := "<why>", kind := "reading" } per reading you chose on a carried span (kind no_atom / no_operator where the words cannot be stated), explained in the header; the record's own narrowings are not restated
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_263_o2
