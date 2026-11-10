/-
  NRS_484B_253_o1 — NRS-484B-253

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (subject): The driver of a vehicle
    s2 (trigger): within an intersection
    s3 (condition): intending to turn to the left
    s4 (obligation): shall yield
    s5 (standard): the right-of-way
    s6 (condition): to any vehicle approaching from the opposite direction
    s7 (condition): which is within the intersection
    s8 (standard): or so close thereto as to constitute an immediate hazard,
    s9 (sibling): but such driver, having so yielded and having given a signal when and as required, may make such left turn and the drivers of all other vehicles approaching the intersection from the opposite direction shall yield the right-of-way to the vehicle making the left turn.

  Elements (span → atoms, derived):
    s1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    s2: atoms ['rel.occupies', 'st.intersection'], derived []
    s4: atoms ['rel.occupies', 'st.intersection'], derived ['drv.motion.moving']
    s6: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle', 'rel.occupies', 'st.lane_enters', 'st.travel_region', 'st.lane_direction'], derived []
    s7: atoms ['rel.occupies', 'st.intersection'], derived []

  How each is written:
    s1: the binder class `ru_aggregate x DEF-NRS-484A-320::vehicle`.
    s2, s3: some intersection `i` (`existsRegion intersection`) with `rel_occupies x i` and the
        declaration current at the judged observation `intent int.turn_left x i` (`leftTurnAt`).
    s6: some road user `y` with `ru_aggregate y DEF-NRS-484A-320::vehicle`, not x (`same`), whose
        approach carrier `cy` and x's approach carrier `cx` (both `existsRegion travel_region`) have
        designated directions (`st_lane_direction`, x and y components) with a dot product below
        minus p.opposed_approach_cos_tolerance (`opposed`).
        x's approach carrier: `st_lane_enters cx i` and the carrier x occupied when its current
        occupancy of i began (`enteredFrom`: `since (rel_occupies x i)
        (rel_occupies x cx ∧ rises (rel_occupies x i))`, i.e. at the observation at which the
        occupancy of i rose, and held at every observation since).
        y's approach carrier: a carrier y occupies with `st_lane_enters cy i`, or, for y within i,
        the carrier it occupied when its current occupancy of i began (`enteredFrom` for y).
        Both carriers are regions other than i (`not (same cx i)`, `not (same cy i)`): the
        travel-region quantifier also ranges over i itself (an intersection is a travel region),
        which is no carrier approaching i; the source records no entry or direction for it, so
        without this it would leave every scene unknown that the real carriers do not decide true.
        This removes no candidate the words admit, since a region is never its own approach.
    s7, s8: `rel_occupies y i`, or the ground distance of y's body to i
        (`st_region_geometry_distance`) at most y's speed (`kin_speed`) times
        p.immediate_hazard_time_gap (`hazard`). The record's "outside i" qualifier on the second
        limb is not written as a separate conjunct: the ground distance is zero where y's body
        overlaps i, so `A ∨ (¬A ∧ B)` and `A ∨ B` decide alike there.
    s4, s5: where x is moving (`drv_motion_moving x` with p.motion_speed_tolerance), no y of the
        applicability's whole selection (the intersection, the intention, the approaches and the
        hazard, bound again in the obligation) has `prim_closest_approach_within x y` with
        p.conflict_time_horizon and `prim_closest_approach_distance x y` below
        p.conflict_centre_clearance.

  No reading beyond the record's was chosen; no narrowing is declared.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_253_o1

/-- The binders, as arguments (order and names are the node's). -/
def vX : Arg := .var "x"

/-- Quantified variables: the intersection, the oncoming vehicle, the two approach carriers. -/
def vI : Arg := .var "i"
def vY : Arg := .var "y"
def vCx : Arg := .var "cx"
def vCy : Arg := .var "cy"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pConflictCentreClearance : Term := .param "p.conflict_centre_clearance"
def pConflictTimeHorizon : Term := .param "p.conflict_time_horizon"
def pImmediateHazardTimeGap : Term := .param "p.immediate_hazard_time_gap"
def pMotionSpeedTolerance : Term := .param "p.motion_speed_tolerance"
def pOpposedApproachCosTolerance : Term := .param "p.opposed_approach_cos_tolerance"

def zeroMetres : Term := .lit Q.zero .metre

/-- Membership of the vehicle aggregate (s1, s6). -/
def vehicle (a : Arg) : Formula := .atom "ru_aggregate" [a, .lit "DEF-NRS-484A-320::vehicle"] []

def occ (a r : Arg) : Formula := .atom "rel_occupies" [a, r] []

def enters (c r : Arg) : Formula := .atom "st_lane_enters" [c, r] []

/-- Class of `x`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsX : Formula := vehicle vX

/-- s2, s3: x within the intersection i, declaring a left turn at it. -/
def leftTurnAt : Formula := .and (occ vX vI) (.intent "int.turn_left" vX vI)

/-- Road user `a` occupied carrier `c` when its current occupancy of i began. -/
def enteredFrom (a c : Arg) : Formula :=
  .since (occ a vI) (.and (occ a c) (.rises (occ a vI)))

/-- s6: x's approach carrier `cx` (a region other than i itself). -/
def xApproach : Formula :=
  .and (.not (.same vCx vI)) (.and (enters vCx vI) (enteredFrom vX vCx))

/-- s6: y's approach carrier `cy` (a region other than i itself): one it occupies entering i, or,
    within i, the one it entered from. -/
def yApproach : Formula :=
  .and (.not (.same vCy vI))
    (.or (.and (occ vY vCy) (enters vCy vI))
         (.and (occ vY vI) (enteredFrom vY vCy)))

def dir (c : Arg) (k : String) : Term := .measure "st_lane_direction" [c, .lit k]

/-- s6: the two approach carriers' designated directions are opposed. -/
def opposed : Formula :=
  .cmp (.add (.mul (dir vCx "x") (dir vCy "x")) (.mul (dir vCx "y") (dir vCy "y")))
    .lt (.neg pOpposedApproachCosTolerance)

/-- s7, s8: y within i, or its time to reach i at most the critical gap. -/
def hazard : Formula :=
  .or (occ vY vI)
      (.cmp (.measure "st_region_geometry_distance" [vY, vI]) .le
        (.mul (.measure "kin_speed" [vY]) pImmediateHazardTimeGap))

/-- s6–s8: y is a vehicle other than x approaching i from the opposite direction, within i or an
    immediate hazard. -/
def oncoming : Formula :=
  .and (vehicle vY)
    (.and (.not (.same vX vY))
      (.and hazard
        (.existsRegion (.lit "travel_region") "cx"
          (.and xApproach
            (.existsRegion (.lit "travel_region") "cy" (.and yApproach opposed))))))

/-- s5: a predicted closest approach of the centres within the horizon below the clearance. -/
def conflict : Formula :=
  .and (.derived "prim_closest_approach_within" [vX, vY] [pConflictTimeHorizon])
       (.cmp (.quantity "prim_closest_approach_distance" [vX, vY] [pConflictTimeHorizon])
          .lt pConflictCentreClearance)

/-- Applicability: s2 (trigger): within an intersection; s3 (condition): intending to turn to the left; s6 (condition): to any vehicle approaching from the opposite direction; s7 (condition): which is within the intersection -/
def applicability : Formula :=
  .existsRegion (.lit "intersection") "i" (.and leftTurnAt (.existsUser "y" oncoming))

/-- Obligation: s4 (obligation): shall yield; s5 (standard): the right-of-way; s8 (standard): or so close thereto as to constitute an immediate hazard, -/
def obligation : Formula :=
  .implies (.derived "drv_motion_moving" [vX] [pMotionSpeedTolerance])
    (.not (.existsRegion (.lit "intersection") "i"
      (.and leftTurnAt (.existsUser "y" (.and oncoming conflict)))))

def rule : Rule :=
  { id := "NRS_484B_253_o1"
    laws := ["NRS-484B-253"]
    binders :=
      [ { name := "x", cls := clsX } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := ["int.turn_left"]
    operationalizations :=
      [ { standard := "the right-of-way (DEF-NRS-484A-210: 'circumstances of direction, speed and proximity as to give rise to the danger of a crash')"
          concepts := ["prim.closest_approach_distance", "prim.closest_approach_within"]
          params := ["p.conflict_time_horizon", "p.conflict_centre_clearance"]
          convention := "Traffic-conflict technique: the danger of a crash is a predicted closest approach of the two centres under constant velocities within the time-to-collision horizon at a centre distance below the clearance."
          surrogate := false }
      , { standard := "so close thereto as to constitute an immediate hazard"
          concepts := ["kin.speed", "st.region_geometry"]
          params := ["p.immediate_hazard_time_gap"]
          convention := "Gap acceptance: an approaching vehicle outside the intersection is an immediate hazard where its time to reach the intersection is at most the critical gap, i.e. its ground distance to the intersection (st.region_geometry) is at most its speed (kin.speed) times the critical gap; the bound moves with the vehicle's speed and distance."
          surrogate := false } ]
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_253_o1
