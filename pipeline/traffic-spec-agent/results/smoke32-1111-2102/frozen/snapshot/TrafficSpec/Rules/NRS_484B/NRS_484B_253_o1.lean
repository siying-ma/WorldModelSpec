/-
  NRS_484B_253_o1 — NRS-484B-253

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    f1 (subject): The driver of a vehicle
    f2 (condition): within an intersection
    f3 (condition): intending to turn to the left
    f4 (obligation): shall yield
    f5 (standard): the right-of-way
    f6 (condition): to any vehicle approaching from the opposite direction
    f7 (condition): which is within the intersection
    f8 (standard): or so close thereto as to constitute an immediate hazard,
    f9 (boilerplate): but such driver,
    f10 (sibling): having so yielded
    f11 (sibling): and having given a signal when and as required,
    f12 (sibling): may make such left turn
    f13 (sibling): and the drivers of all other vehicles approaching the intersection from the opposite direction
    f14 (sibling): shall yield
    f15 (sibling): the right-of-way
    f16 (sibling): to the vehicle making the left turn.

  Elements (span → atoms, derived):
    f1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    f2: atoms ['st.intersection', 'rel.occupies'], derived []
    f4: atoms [], derived ['drv.motion.at_rest']
    f6: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle', 'st.lane_enters', 'st.lane_direction', 'st.travel_region', 'rel.occupies'], derived []
    f7: atoms ['rel.occupies', 'st.intersection'], derived []

  How each is written:
    f1: ego's class is ru_aggregate with the admitted aggregate id.
    f2/f3: an intersection i (quantifier kind `intersection`) that ego occupies and at which ego
      declares int.left_turn at the judged observation; the obligation re-selects i the same way.
    f6: every road user b of the aggregate other than ego whose approach carrier rb (a
      travel_region with st_lane_enters rb i, which b occupies now or from which it entered i:
      `since (occupies b i) (occupies b rb)`, rb other than i itself) and ego's approach carrier re (same form, for ego)
      carry st_lane_direction vectors whose dot product is below -p.opposite_direction_tolerance.
    f7/f8: b overlaps i, or b occupies rb with st_region_geometry_distance(b, i) at or below
      kin_speed(b) times p.immediate_hazard_time (the product form of the time to reach i).
    f4/f5: ego at rest (drv.motion.at_rest) or not in conflict with b: not both
      prim_closest_approach_within(ego, b) and prim_closest_approach_distance(ego, b) below
      p.conflict_clearance, the same horizon p.conflict_horizon for both.
  No choice beyond the record's own wording was needed; no narrowing is declared.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_253_o1

/-- The binders, as arguments (order and names are the node's). -/
def vEgo : Arg := .var "ego"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pConflictClearance : Term := .param "p.conflict_clearance"
def pConflictHorizon : Term := .param "p.conflict_horizon"
def pImmediateHazardTime : Term := .param "p.immediate_hazard_time"
def pOppositeDirectionTolerance : Term := .param "p.opposite_direction_tolerance"
def pRestSpeedTolerance : Term := .param "p.rest_speed_tolerance"

def zeroMetres : Term := .lit Q.zero .metre

def vAggregate : Arg := .lit "DEF-NRS-484A-320::vehicle"

/-- Class of `ego`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsEgo : Formula := .atom "ru_aggregate" [vEgo, vAggregate] []

/-- f2/f3: the intersection `i` ego's footprint overlaps and at which it declares int.left_turn. -/
def egoTurningLeftAt (i : String) : Formula :=
  .and (.atom "rel_occupies" [vEgo, .var i] [])
       (.intent "int.left_turn" vEgo (.var i))

/-- Applicability: f2 (condition): within an intersection; f3 (condition): intending to turn to the left; f6 (condition): to any vehicle approaching from the opposite direction; f7 (condition): which is within the intersection -/
def applicability : Formula :=
  .existsRegion (.lit "intersection") "i" (egoTurningLeftAt "i")

/-- `x`'s approach carrier `r` to `i`: a carrier entering `i` that `x` occupies now, or the one it
    occupied when it entered `i` (it has overlapped `i` at every observation since). A carrier
    entering `i` is never `i` itself. -/
def approachCarrier (x r i : String) : Formula :=
  .and (.not (.same (.var r) (.var i)))
  <| .and (.atom "st_lane_enters" [.var r, .var i] [])
       (.since (.atom "rel_occupies" [.var x, .var i] []) (.atom "rel_occupies" [.var x, .var r] []))

/-- The designated directions of carriers `r` and `r'` are opposed: their dot product is below
    minus the opposite-direction tolerance. -/
def opposed (r r' : String) : Formula :=
  let dir (v : String) (k : String) : Term := .measure "st_lane_direction" [.var v, .lit k]
  .cmp (.add (.mul (dir r "x") (dir r' "x")) (.mul (dir r "y") (dir r' "y")))
       .lt (.neg pOppositeDirectionTolerance)

/-- f6/f7/f8: `b` approaches `i` from the direction opposite to ego's approach, and either
    overlaps `i` or occupies its approach carrier at a ground distance from `i` at or below its
    speed times the critical headway. -/
def opposingHazard (b i : String) : Formula :=
  .existsRegion (.lit "travel_region") "rb"
    (.and (approachCarrier b "rb" i)
      (.and (.existsRegion (.lit "travel_region") "re"
               (.and (approachCarrier "ego" "re" i) (opposed "rb" "re")))
        (.or (.atom "rel_occupies" [.var b, .var i] [])
             (.and (.atom "rel_occupies" [.var b, .var "rb"] [])
                   (.cmp (.measure "st_region_geometry_distance" [.var b, .var i]) .le
                         (.mul (.measure "kin_speed" [.var b]) pImmediateHazardTime))))))

/-- f5: ego and `b` in conflict: their centres approach within the horizon, to a closest-approach
    centre distance below the clearance. -/
def inConflict (b : String) : Formula :=
  .and (.derived "prim_closest_approach_within" [vEgo, .var b] [pConflictHorizon])
       (.cmp (.quantity "prim_closest_approach_distance" [vEgo, .var b] [pConflictHorizon]) .lt
             pConflictClearance)

/-- Obligation: f4 (obligation): shall yield; f5 (standard): the right-of-way; f8 (standard): or so close thereto as to constitute an immediate hazard, -/
def obligation : Formula :=
  .forallRegion (.lit "intersection") "i"
    (.implies (egoTurningLeftAt "i")
      (.forallUser "b"
        (.implies
          (.and (.atom "ru_aggregate" [.var "b", vAggregate] [])
            (.and (.not (.same (.var "b") vEgo)) (opposingHazard "b" "i")))
          (.or (.derived "drv_motion_at_rest" [vEgo] [pRestSpeedTolerance])
               (.not (inConflict "b"))))))

def rule : Rule :=
  { id := "NRS_484B_253_o1"
    laws := ["NRS-484B-253"]
    binders :=
      [ { name := "ego", cls := clsEgo } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := ["int.left_turn"]
    operationalizations :=
      [ { standard := "the right-of-way: DEF-NRS-484A-210 \"approaching under such circumstances of direction, speed and proximity as to give rise to the danger of a crash unless one grants precedence to the other\""
          concepts := ["prim.closest_approach_distance", "prim.closest_approach_within"]
          params := ["p.conflict_horizon", "p.conflict_clearance"]
          convention := "Traffic-conflict technique: two road users are in conflict where, projected at their current velocities, their centres approach within the time-to-collision horizon and their closest-approach centre distance is below the clearance at which their bodies would touch. Direction, speed and proximity enter by degree through the projected velocities and positions."
          surrogate := false }
      , { standard := "so close thereto as to constitute an immediate hazard"
          concepts := ["kin.speed", "st.region_geometry"]
          params := ["p.immediate_hazard_time"]
          convention := "Gap acceptance: an approaching vehicle is an immediate hazard where its time to reach the intersection is below the critical headway for a left turn, read as the ground distance from its body to the intersection (st.region_geometry) at or below its speed (kin.speed) times the critical headway; distance and speed enter by degree."
          surrogate := false } ]
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []  -- one { span := "<span id>", why := "<why>", kind := "reading" } per reading you chose on a carried span (kind no_atom / no_operator where the words cannot be stated), explained in the header; the record's own narrowings are not restated
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_253_o1
