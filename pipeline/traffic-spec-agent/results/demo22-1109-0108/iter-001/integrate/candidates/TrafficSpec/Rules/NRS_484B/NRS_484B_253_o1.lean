/-
  NRS_484B_253_o1 — NRS-484B-253

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (subject): The driver of a vehicle
    t1 (trigger): within an intersection
    c1 (condition): intending to turn to the left
    ob1 (obligation): shall yield the right-of-way to any vehicle approaching from the opposite direction which is within the intersection
    st1 (standard): or so close thereto as to constitute an immediate hazard,
    sib1 (sibling): but such driver, having so yielded and having given a signal when and as required, may make such left turn and the drivers of all other vehicles approaching the intersection from the opposite direction shall yield the right-of-way to the vehicle making the left turn.

  Elements (span → atoms, derived):
    s1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    t1: atoms ['rel.occupies', 'st.intersection'], derived []
    ob1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle', 'rel.occupies', 'st.intersection', 'st.travel_region', 'st.lane_enters', 'st.lane_direction', 'rel.surface_gap', 'rel.contact', 'kin.speed', 'prim.closest_approach_within', 'prim.closest_approach_distance'], derived []

  How each span is written here:

    s1 — the binder's class is the admitted aggregate, one atom: `ru_aggregate v
    "DEF-NRS-484A-320::vehicle"`. The classes the definition includes are the reading's, never
    spelled here.

    t1 — `existsRegion "intersection" "j" (rel_occupies v j ∧ …)`: the junction is the subject's
    own by occupancy, which is the anchor the later conditions read. The applicability's junction
    is selected again, whole, in the obligation (`forallRegion "intersection" "j" (rel_occupies v j
    ∧ intent …→ …)`), since a region bound in one formula is not in scope in the other; the duty is
    owed at every junction so selected.

    c1 — the declared intention `int.left_turn` of `v` at that same junction `j`, read at the
    judged observation (no future operator stands over it).

    ob1 — the vehicles owed precedence are quantified with `forallUser "u"`, the subject excluded by
    `same`; each is of the aggregate; "approaching from the opposite direction" is read, as the
    ontology directs, through the carriers: `u` occupies a carrier of kind `travel_region` whose
    entrance end is `j` (`st_lane_enters`), `v` occupies such a carrier too, and the normalised dot
    product of their designated directions (`st_lane_direction`, read componentwise) lies at or
    below the negative of `p.same_direction_cosine_tolerance`. "which is within the intersection" is
    `rel_occupies u j`. Granting precedence is no contact (`rel_contact`) and no loss of the
    clearance.

    st1 — the standard, by the operationalization's convention: the distance of `u`'s body to the
    junction (`st_region_geometry_distance`) at most its own speed (`kin_speed`) times
    `p.yield_headway_time` — a product, never a ratio — or the clearance lost within
    `p.yield_conflict_horizon`.

  Narrowings declared below (readings this session chose, both on ob1):

    1. The clearance of "its closest approach to it" is read as: the centres approach each other
       within `p.yield_conflict_horizon` (`prim_closest_approach_within`), and at that approach
       either the centre distance (`prim_closest_approach_distance`) or the gap between the nearest
       points of the two bodies (`rel.surface_gap`, the measure the convention names) lies below
       `p.yield_min_clearance`. Where no approach of the centres falls within the horizon, no
       clearance is lost by this reading: two bodies already drawing apart are not read as a failure
       to grant precedence, and contact is read on its own atom beside it.
    2. The carrier by which the subject reached the junction is read existentially — some carrier it
       occupies whose entrance end is that junction — because the ontology fixes the approach by
       occupancy and entrance topology and the text names no further way to single one out.
    3. A carrier read as an approach to the junction is not the junction region itself. The kind the
       record names, `st.travel_region`, covers the intersection, but `st.lane_enters` is recorded
       on an approach segment and never on the junction it enters ("A carrier enters one
       intersection at most"), so for the junction region that relation is unrecorded, not false:
       asking it there could only add an unknown. The junction is therefore excluded as its own
       approach (`¬ same cu j`, `¬ same cs j`), which removes no case the relation could decide and
       no vehicle the duty could reach.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_253_o1

/-- The binders, as arguments (order and names are the node's). -/
def vV : Arg := .var "v"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pSameDirectionCosineTolerance : Term := .param "p.same_direction_cosine_tolerance"
def pYieldConflictHorizon : Term := .param "p.yield_conflict_horizon"
def pYieldHeadwayTime : Term := .param "p.yield_headway_time"
def pYieldMinClearance : Term := .param "p.yield_min_clearance"

def zeroMetres : Term := .lit Q.zero .metre

/-- The quantified vehicle owed precedence, the junction, and the two approach carriers. -/
def uV : Arg := .var "u"
def jV : Arg := .var "j"
def cuV : Arg := .var "cu"
def csV : Arg := .var "cs"

/-- The admitted aggregate of s1 and ob1, as its literal argument. -/
def vehicleAggregate : Arg := .lit "DEF-NRS-484A-320::vehicle"

/-- Membership of a road user in that aggregate. -/
def isVehicle (x : Arg) : Formula := .atom "ru_aggregate" [x, vehicleAggregate] []

/-- The dot product of two carriers' designated directions, each read normalised. -/
def directionDot (a b : Arg) : Term :=
  .add (.mul (.measure "st_lane_direction" [a, .lit "x"]) (.measure "st_lane_direction" [b, .lit "x"]))
       (.mul (.measure "st_lane_direction" [a, .lit "y"]) (.measure "st_lane_direction" [b, .lit "y"]))

/-- ob1: `u` reaches the junction `j` through a carrier whose designated direction is opposed to
    that of a carrier by which `v` reaches the same junction. -/
def fromOppositeDirection : Formula :=
  .existsRegion (.lit "travel_region") "cu"
    (.and (.not (.same cuV jV))
    (.and (.atom "rel_occupies" [uV, cuV] [])
    (.and (.atom "st_lane_enters" [cuV, jV] [])
      (.existsRegion (.lit "travel_region") "cs"
        (.and (.not (.same csV jV))
        (.and (.atom "rel_occupies" [vV, csV] [])
        (.and (.atom "st_lane_enters" [csV, jV] [])
          (.cmp (directionDot cuV csV) .le (.neg pSameDirectionCosineTolerance)))))))))

/-- ob1, st1: the clearance between `v` and `u` is lost within the conflict horizon. -/
def clearanceLost : Formula :=
  .and (.derived "prim_closest_approach_within" [vV, uV] [pYieldConflictHorizon])
    (.or (.cmp (.quantity "prim_closest_approach_distance" [vV, uV] [pYieldConflictHorizon])
               .lt pYieldMinClearance)
         (.cmp (.measure "rel_surface_gap" [vV, uV]) .lt pYieldMinClearance))

/-- st1: `u` is so close to the junction as to constitute an immediate hazard. -/
def soCloseToJunction : Formula :=
  .or (.cmp (.measure "st_region_geometry_distance" [uV, jV])
            .le (.mul (.measure "kin_speed" [uV]) pYieldHeadwayTime))
      clearanceLost

/-- ob1 with st1: the vehicles `v` must grant precedence to at the junction `j`. -/
def owedPrecedence : Formula :=
  .and (.not (.same uV vV))
  (.and (isVehicle uV)
  (.and fromOppositeDirection
        (.or (.atom "rel_occupies" [uV, jV] []) soCloseToJunction)))

/-- ob1: granting precedence — no contact, and the clearance kept. -/
def grantsPrecedence : Formula :=
  .and (.not (.atom "rel_contact" [vV, uV] [])) (.not clearanceLost)

/-- Class of `v`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsV : Formula := isVehicle vV

/-- Applicability: t1 (trigger): within an intersection; c1 (condition): intending to turn to the left -/
def applicability : Formula :=
  .existsRegion (.lit "intersection") "j"
    (.and (.atom "rel_occupies" [vV, jV] []) (.intent "int.left_turn" vV jV))

/-- Obligation: ob1 (obligation): shall yield the right-of-way to any vehicle approaching from the opposite direction which is within the intersection; st1 (standard): or so close thereto as to constitute an immediate hazard, -/
def obligation : Formula :=
  .forallRegion (.lit "intersection") "j"
    (.implies (.and (.atom "rel_occupies" [vV, jV] []) (.intent "int.left_turn" vV jV))
      (.forallUser "u" (.implies owedPrecedence grantsPrecedence)))

def rule : Rule :=
  { id := "NRS_484B_253_o1"
    laws := ["NRS-484B-253"]
    binders :=
      [ { name := "v", cls := clsV } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := ["int.left_turn"]
    operationalizations :=
      [ { standard := "or so close thereto as to constitute an immediate hazard"
          concepts := ["kin.speed", "prim.closest_approach_distance", "prim.closest_approach_within", "rel.surface_gap", "st.intersection", "st.region_geometry"]
          params := ["p.yield_headway_time", "p.yield_conflict_horizon", "p.yield_min_clearance"]
          convention := "Gap-acceptance convention for a left turn across an opposing stream. 'So close thereto' is the oncoming vehicle's distance to the junction, which st.region_geometry gives as 'the ground distance from a road user's body outline to it'; the hazard is read by the degree to which the words hold, the distance divided by nothing but carried as a product -- the vehicle is so close where that distance is at most its own speed (kin.speed) times p.yield_headway_time, so a faster approach makes a greater distance count and a slower one a smaller. The immediacy of the hazard is read in the same breath by the conflict-avoidance convention: the closest approach between the two bodies under constant velocities within p.yield_conflict_horizon falling below p.yield_min_clearance, measured between the nearest points of the bodies by rel.surface_gap. Both bounds are the reading's, set from gap-acceptance tables for a permitted left turn, and neither is a figure of the law's."
          surrogate := false } ]
    residues := []  -- the node's, verbatim; not yours to change
    narrowings :=
      [ { span := "ob1"
          why := "'Its closest approach to it' is read as: the centres approach each other within p.yield_conflict_horizon (prim.closest_approach_within), and at that approach either the centre distance (prim.closest_approach_distance) or the gap between the nearest points of the two bodies (rel.surface_gap, the measure the convention names) lies below p.yield_min_clearance. Where no approach of the centres falls within the horizon the clearance is not read as lost: two bodies drawing apart are no failure to grant precedence, and contact is read beside this by rel.contact."
          kind := "reading" }
      , { span := "ob1"
          why := "'The carrier by which the subject came to the junction' is read existentially: some carrier of kind st.travel_region that the subject occupies and whose entrance end is that junction. The ontology fixes a road user's approach by occupancy and entrance topology, and the words name no further way to single one carrier out."
          kind := "reading" }
      , { span := "ob1"
          why := "A carrier read as an approach to the junction is not the junction region itself. The kind the record names, st.travel_region, covers the intersection, but st.lane_enters is the source's record of an approach segment's entrance end and is never recorded on the junction that segment enters ('A carrier enters one intersection at most'), so on the junction region the relation is unrecorded rather than false and asking it there could only add an unknown. The junction is therefore excluded as its own approach carrier, which removes no case that relation could decide and no vehicle the duty could reach."
          kind := "reading" } ]
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_253_o1
