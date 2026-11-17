/-
  NRS_484B_253_o1 — NRS-484B-253

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    a (subject): The driver of a vehicle
    b (trigger): within an intersection
    c (trigger): intending to turn to the left
    d (obligation): shall yield
    e (standard): the right-of-way
    f (condition): to any vehicle approaching from the opposite direction
    g (condition): which is within the intersection
    h (standard): or so close thereto as to constitute an immediate hazard,
    i (sibling): but such driver, having so yielded
    j (sibling): and having given a signal when and as required,
    k (sibling): may make such left turn
    l (sibling): and the drivers of all other vehicles
    m (sibling): approaching the intersection from the opposite direction
    n (sibling): shall yield
    o (sibling): the right-of-way
    p (sibling): to the vehicle making the left turn.

  Elements (span → atoms, derived):
    a: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    b: atoms ['rel.occupies', 'st.intersection'], derived []
    d: atoms ['kin.speed', 'rel.contact'], derived []
    f: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle', 'rel.occupies', 'st.lane_enters', 'st.travel_region', 'st.lane_direction'], derived []
    g: atoms ['rel.occupies', 'st.intersection'], derived []

  How each span is written:
    a: binder class `ru_aggregate subject DEF-NRS-484A-320::vehicle`.
    b, c: applicability — some intersection X (quantifier kind st.intersection) the subject occupies
       (rel_occupies) with `intent int.left_turn subject X` at the judged observation.
    Obligation, re-binding X by the same selection (b, c) for every such X; then for every
       travel region c1 (quantifier kind st.travel_region) that is an approach entering X
       (st_lane_enters c1 X) and that the subject occupied when it last entered X
       (`since (occupies subject X) (occupies subject c1)`); then for every road user v:
    f: v is a vehicle (ru_aggregate), not the subject, and for some travel region c2 entering X
       (st_lane_enters c2 X), v has overlapped X continuously since an observation at which it
       occupied c2 (`since`, which includes occupying c2 now), with the st_lane_direction vectors of
       c1 and c2 having a dot product below −p.oncoming_heading_cos.
    g, h: and either v occupies X, or v occupies c2 and is in conflict with the subject
       (prim_closest_approach_within at p.conflict_horizon and prim_closest_approach_distance below
       p.conflict_centre_clearance).
    d, e: then the subject is not in contact with v (rel_contact) and it is not the case that the
       subject proceeds (kin_speed above p.halt_speed_tolerance) while in that conflict with v.
  Structural choice, not a narrowing: c1 and c2 range over travel regions, of which X itself is one;
  X is no carrier entering itself (Core reads st_lane_enters on a region without lane information as
  unknown), so `not (same c1 X)` / `not (same c2 X)` keep X out of the carrier positions.
  No narrowings: the record states every choice above.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_253_o1

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pConflictCentreClearance : Term := .param "p.conflict_centre_clearance"
def pConflictHorizon : Term := .param "p.conflict_horizon"
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"
def pOncomingHeadingCos : Term := .param "p.oncoming_heading_cos"

def zeroMetres : Term := .lit Q.zero .metre

/-- Quantified variables: the intersection, the subject's entry carrier, the other road user and its carrier. -/
def vX : Arg := .var "X"
def vC1 : Arg := .var "c1"
def vV : Arg := .var "v"
def vC2 : Arg := .var "c2"

/-- a, f: membership of the admitted aggregate DEF-NRS-484A-320::vehicle. -/
def isVehicle (a : Arg) : Formula := .atom "ru_aggregate" [a, .lit "DEF-NRS-484A-320::vehicle"] []

/-- rel.occupies: the road user's footprint overlaps the region. -/
def occupies (a r : Arg) : Formula := .atom "rel_occupies" [a, r] []

/-- st.lane_enters: carrier `c` is an approach to intersection `x`. -/
def enters (c x : Arg) : Formula := .atom "st_lane_enters" [c, x] []

/-- st.lane_direction component of a carrier (normalised as Core reads it). -/
def dirComp (c : Arg) (k : String) : Term := .measure "st_lane_direction" [c, .lit k]

/-- f: the designated directions of c1 and c2 are opposed: their dot product is below −p.oncoming_heading_cos. -/
def opposedCarriers : Formula :=
  .cmp (.add (.mul (dirComp vC1 "x") (dirComp vC2 "x")) (.mul (dirComp vC1 "y") (dirComp vC2 "y")))
    .lt (.neg pOncomingHeadingCos)

/-- e, h: danger of a crash / immediate hazard — the centres of subject and v approach within
    p.conflict_horizon to a centre distance below p.conflict_centre_clearance. -/
def conflict : Formula :=
  .and (.derived "prim_closest_approach_within" [vSubject, vV] [pConflictHorizon])
       (.cmp (.quantity "prim_closest_approach_distance" [vSubject, vV] [pConflictHorizon]) .lt pConflictCentreClearance)

/-- e: the subject proceeds — kin.speed above p.halt_speed_tolerance. -/
def proceeds : Formula := .cmp (.measure "kin_speed" [vSubject]) .gt pHaltSpeedTolerance

/-- b, c: the subject's footprint overlaps intersection X and it declares int.left_turn at X. -/
def selectsX : Formula :=
  .and (occupies vSubject vX) (.intent "int.left_turn" vSubject vX)

/-- c1: a carrier (not X itself) entering X that the subject occupied when it last entered X:
    it has overlapped X continuously since an observation at which it occupied c1. -/
def entryCarrier : Formula :=
  .and (.not (.same vC1 vX))
    (.and (enters vC1 vX) (.since (occupies vSubject vX) (occupies vSubject vC1)))

/-- f, g, h: v is another vehicle approaching from the opposite direction — on a carrier c2 (not X
    itself) entering X, or in X continuously since it occupied such a c2, c2's direction opposed to
    c1's — and v either overlaps X or, on c2, is in conflict with the subject. -/
def opposingVehicle : Formula :=
  .and (isVehicle vV)
    (.and (.not (.same vV vSubject))
      (.existsRegion (.lit "travel_region") "c2"
        (.and (.not (.same vC2 vX))
          (.and (enters vC2 vX)
            (.and (.since (occupies vV vX) (occupies vV vC2))
              (.and opposedCarriers
                (.or (occupies vV vX) (.and (occupies vV vC2) conflict))))))))

/-- d, e: yield — no contact with v, and not proceeding while in conflict with v. -/
def yields : Formula :=
  .and (.not (.atom "rel_contact" [vSubject, vV] []))
       (.not (.and proceeds conflict))

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula := isVehicle vSubject

/-- Applicability: b (trigger): within an intersection; c (trigger): intending to turn to the left.
    The conditions f, g select the protected vehicles inside the obligation, as the record states. -/
def applicability : Formula := .existsRegion (.lit "intersection") "X" selectsX

/-- Obligation: d (obligation): shall yield; e (standard): the right-of-way; h (standard): or so close thereto as to constitute an immediate hazard -/
def obligation : Formula :=
  .forallRegion (.lit "intersection") "X"
    (.implies selectsX
      (.forallRegion (.lit "travel_region") "c1"
        (.implies entryCarrier
          (.forallUser "v" (.implies opposingVehicle yields)))))

def rule : Rule :=
  { id := "NRS_484B_253_o1"
    laws := ["NRS-484B-253"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := ["int.left_turn"]
    operationalizations :=
      [ { standard := "the right-of-way: precedence owed where 'circumstances of direction, speed and proximity ... give rise to the danger of a crash' (DEF-NRS-484A-210)"
          concepts := ["kin.speed", "prim.closest_approach_distance", "prim.closest_approach_within"]
          params := ["p.conflict_horizon", "p.conflict_centre_clearance", "p.halt_speed_tolerance"]
          convention := "traffic-conflict technique: a danger of a crash exists where, under constant velocities, the two centres approach within the time-to-collision threshold p.conflict_horizon to a centre distance below p.conflict_centre_clearance; the subject proceeds where its speed exceeds p.halt_speed_tolerance"
          surrogate := false }
      , { standard := "so close to the intersection as to constitute an immediate hazard"
          concepts := ["prim.closest_approach_distance", "prim.closest_approach_within"]
          params := ["p.conflict_horizon", "p.conflict_centre_clearance"]
          convention := "traffic-conflict technique: a vehicle approaching on its carrier is an immediate hazard where, under constant velocities, its centre and the subject's approach within the time-to-collision threshold p.conflict_horizon to a centre distance below p.conflict_centre_clearance"
          surrogate := false } ]
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []  -- one { span := "<span id>", why := "<why>", kind := "reading" } per reading you chose on a carried span (kind no_atom / no_operator where the words cannot be stated), explained in the header; the record's own narrowings are not restated
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_253_o1
