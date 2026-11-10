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

  How each is written:
    s1: the class of `x` is `ru_aggregate x "DEF-NRS-484A-320::vehicle"`.
    s2: two judged observations, over every controlled-access region `a` (`existsRegion
        controlled_access`): the entry, `rises (rel_occupies x a)`; the exit,
        `rises (not (rel_occupies x a))` together with a highway region `h` (`existsRegion highway`)
        that x occupies there — the highway x moves onto.
    s5: some road user `y`, not `x` (`not (same y x)`), of the vehicle aggregate, on the highway
        being entered — at an entry `rel_occupies y a`; at an exit `rel_occupies y h` and
        `not (rel_occupies y a)` — and moving (`drv_motion_moving y` with p.motion_speed_tolerance).
    s6: `rel_surface_gap x y ≤ kin_speed y × p.immediate_hazard_time_gap` (the record's "at most";
        a product, never a ratio over the speed).
    s3 + s4: where x is moving at the judged observation (`drv_motion_moving x`), no vehicle `y` of
        the applicability's whole selection (the regions and the road user bound again with every
        relation that fixed them) has `prim_closest_approach_within x y p.conflict_time_horizon`
        and `prim_closest_approach_distance x y p.conflict_time_horizon < p.conflict_centre_clearance`
        (the record's "below").
    s7 is a sibling: not written here.

  No choice beyond the record's: `narrowings` is empty.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_263_o1

/-- The binders, as arguments (order and names are the node's). -/
def vX : Arg := .var "x"

/-- The quantified variables: the controlled-access region, the highway moved onto at an exit,
    and the approaching vehicle. -/
def vA : Arg := .var "a"
def vH : Arg := .var "h"
def vY : Arg := .var "y"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pConflictCentreClearance : Term := .param "p.conflict_centre_clearance"
def pConflictTimeHorizon : Term := .param "p.conflict_time_horizon"
def pImmediateHazardTimeGap : Term := .param "p.immediate_hazard_time_gap"
def pMotionSpeedTolerance : Term := .param "p.motion_speed_tolerance"

def zeroMetres : Term := .lit Q.zero .metre

/-- The vehicle aggregate (DEF-NRS-484A-320). -/
def vehicle (u : Arg) : Formula := .atom "ru_aggregate" [u, .lit "DEF-NRS-484A-320::vehicle"] []

/-- A road user's footprint overlaps a region. -/
def occupies (u r : Arg) : Formula := .atom "rel_occupies" [u, r] []

/-- A road user is in motion. -/
def moving (u : Arg) : Formula := .derived "drv_motion_moving" [u] [pMotionSpeedTolerance]

/-- s6: y's proximity is an immediate hazard — the body gap to x at most y's speed times the critical gap. -/
def immediateHazard : Formula :=
  .cmp (.measure "rel_surface_gap" [vX, vY]) .le (.mul (.measure "kin_speed" [vY]) pImmediateHazardTimeGap)

/-- s4: the danger of a crash — a predicted closest approach of the centres within the horizon
    at a centre distance below the clearance. -/
def conflict : Formula :=
  .and (.derived "prim_closest_approach_within" [vX, vY] [pConflictTimeHorizon])
    (.cmp (.quantity "prim_closest_approach_distance" [vX, vY] [pConflictTimeHorizon]) .lt
      pConflictCentreClearance)

/-- s5 + s6: a vehicle y other than x, on the highway being entered (`onWay`), moving, whose
    proximity is an immediate hazard; with `extra` conjoined when the obligation binds it again. -/
def approaching (onWay : Formula) (extra : Option Formula) : Formula :=
  let core : Formula := .and (moving vY) immediateHazard
  .existsUser "y"
    (.and (.not (.same vY vX))
      (.and (vehicle vY)
        (.and onWay
          (match extra with
           | some φ => .and core φ
           | none => core))))

/-- s2 + s5: the whole selection — an entry into, or an exit from, a controlled-access region,
    with a vehicle approaching on the highway being entered. -/
def selection (extra : Option Formula) : Formula :=
  .or
    (.existsRegion (.lit "controlled_access") "a"
      (.and (.rises (occupies vX vA))
        (approaching (occupies vY vA) extra)))
    (.existsRegion (.lit "controlled_access") "a"
      (.and (.rises (.not (occupies vX vA)))
        (.existsRegion (.lit "highway") "h"
          (.and (occupies vX vH)
            (approaching (.and (occupies vY vH) (.not (occupies vY vA))) extra)))))

/-- Class of `x`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsX : Formula := vehicle vX

/-- Applicability: s2 (trigger): about to enter or exit a controlled-access highway; s5 (condition): to all vehicles approaching on the highway -/
def applicability : Formula := selection none

/-- Obligation: s3 (obligation): shall yield; s4 (standard): the right-of-way; s6 (standard): whose proximity constitutes an immediate hazard -/
def obligation : Formula := .implies (moving vX) (.not (selection (some conflict)))

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
    narrowings := []
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_263_o1
