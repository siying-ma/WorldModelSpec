/-
  NRS_484B_307_9b_o4 — NRS-484B-307-9b

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    b1 (trigger): Where the signal is a steady red with a green turn arrow:
    b2 (subject): A person driving a motorcycle,
    b3 (subject): moped or trimobile
    b4 (subject): or riding a bicycle, an electric bicycle or an electric scooter
    b5 (condition): facing the signal
    b6 (trigger): may proceed straight through or turn in the direction opposite that indicated by the green turn arrow if:
    b7 (sibling): (1) The person stops before entering the crosswalk on the nearest side of the intersection where the sign or pavement marking indicates where the stop must be made or, in the absence of any such crosswalk, sign or marking, before entering the intersection;
    b8 (sibling): (2) The person waits for two complete cycles of the lights or lighted arrows of the applicable official traffic-control device and the signal does not change
    b9 (sibling): because of a malfunction or because the signal failed to detect the presence of the motorcycle, moped, trimobile, bicycle, electric bicycle or electric scooter;
    b10 (sibling): (3) No other device at the place prohibits the turn,
    b11 (sibling): if applicable;
    b12 (obligation): and (4) The person yields the right-of-way to pedestrians lawfully within an adjacent crosswalk and to other traffic lawfully using the intersection.

  Elements (span → atoms, derived):
    b1: atoms ['dev.traffic_signal', 'dev.governs', 'rel.occupies', 'st.lane_enters', 'st.travel_region', 'st.intersection'], derived []
    b2: atoms ['ru.aggregate=DEF-NRS-484A-135::motorcycle'], derived []
    b3: atoms ['ru.aggregate=DEF-NRS-484A-125::moped', 'ru.motorcycle'], derived []
    b4: atoms ['ru.aggregate=DEF-NRS-484A-025::bicycle', 'ru.aggregate=DEF-NRS-484B-017::electric_bicycle', 'ru.aggregate=DEF-NRS-484B-018::electric_scooter'], derived []
    b5: atoms ['dev.governs', 'dev.traffic_signal', 'rel.occupies', 'st.lane_enters', 'st.travel_region', 'st.intersection'], derived []
    b6: atoms ['rel.occupies', 'st.intersection', 'kin.yaw_rate', 'dev.traffic_signal'], derived ['drv.motion.straight_through_region', 'drv.motion.left_turn_through_region', 'drv.motion.right_turn_through_region']
    b12: atoms ['prim.closest_approach_within', 'prim.closest_approach_distance', 'rel.occupies', 'st.crosswalk', 'st.entrance_of', 'st.lane_enters', 'st.intersection', 'st.travel_region', 'ru.aggregate=DEF-NRS-484A-165::pedestrian', 'ru.aggregate=DEF-NRS-484A-285::traffic'], derived ['drv.motion.moving']

  How each span is written:
    b2, b3, b4 (class of x): the disjunction of the five admitted aggregates, each `ru_aggregate`
      with its id, and the class atom `ru_motorcycle` (b3's nearest atom for "trimobile"; the gap
      the record carries on b3 stays the plan's).
    b6 (the crossing): judged at the observation x leaves an intersection i (the quantifier over
      `intersection`): `drv_motion_straight_through_region(x, i)` under either arrow,
      `drv_motion_right_turn_through_region(x, i)` under green_arrow(left),
      `drv_motion_left_turn_through_region(x, i)` under green_arrow(right); the step bound is the
      reviewed `p.heading_since_step_carla_scene_graph`, the turn band's upper end
      `p.reversal_min_angle`.
    b1, b5 (the signal faced, at the entry): each crossing is paired with
      `since (¬ rises occupies(x, i)) (rises occupies(x, i) ∧ facing dir)`: the last entry into i,
      with no later entry, at which some traffic signal s shows circular_red and green_arrow(dir)
      and governs either x's approach carrier c — a `travel_region` with `st_lane_enters(c, i)`
      that x occupied at the observation before the entry — or i itself. "Occupied at the
      observation before" is written from one-step edges, as the language has no previous-
      observation operator: occupies now and not newly (`occupies ∧ ¬ rises occupies`), or
      newly not (`rises ¬ occupies`).
    b12 (the yield): the obligation selects i again with the whole b1/b5/b6 selection (rule 3c) and
      requires that no observation since the entry into i (the same `¬ rises occupies(x, i)`
      bound, read with since from the exit) fails the duty. The duty at one observation: where x
      occupies i and is moving (`drv_motion_moving`, p.motion_speed_tolerance), for every road
      user p of DEF-NRS-484A-165::pedestrian occupying a `crosswalk` w that st_entrance_of marks
      for a `travel_region` c2 with `st_lane_enters(c2, i)`, and for every road user z of
      DEF-NRS-484A-285::traffic other than x (`same`) occupying i: not both
      `prim_closest_approach_within(x, ·)` over p.conflict_time_horizon and
      `prim_closest_approach_distance(x, ·)` below p.conflict_centre_clearance.
      The carrier c2 is required to be other than i (`¬ same c2 i`): an intersection is no carrier
      that enters itself, and the guard keeps the reading decided where the source records no
      entry topology for the intersection region itself (st.lane_enters is unknown there). It
      excludes nothing the record's selection admits.
    b7–b11 (siblings) are other nodes' conditions and are not read here.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_307_9b_o4

/-- The binders, as arguments (order and names are the node's). -/
def vX : Arg := .var "x"

/-- The intersection the crossing passes (a quantifier variable of each formula). -/
def vI : Arg := .var "i"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pConflictCentreClearance : Term := .param "p.conflict_centre_clearance"
def pConflictTimeHorizon : Term := .param "p.conflict_time_horizon"
def pHeadingSinceStepCarlaSceneGraph : Term := .param "p.heading_since_step_carla_scene_graph"
def pLeftTurnMinAngle : Term := .param "p.left_turn_min_angle"
def pMotionSpeedTolerance : Term := .param "p.motion_speed_tolerance"
def pReversalMinAngle : Term := .param "p.reversal_min_angle"
def pRightTurnMinAngle : Term := .param "p.right_turn_min_angle"
def pStraightThroughMaxHeadingChange : Term := .param "p.straight_through_max_heading_change"

def zeroMetres : Term := .lit Q.zero .metre

def aggregate (v : String) (id : String) : Formula := .atom "ru_aggregate" [.var v, .lit id] []
def occupies (u r : String) : Formula := .atom "rel_occupies" [.var u, .var r] []
def entersI (c : String) : Formula := .atom "st_lane_enters" [.var c, vI] []
def shows (s ind : String) : Formula := .atom "dev_traffic_signal_shows" [.var s, .lit ind] []

/-- Class of `x`: ru.aggregate=DEF-NRS-484A-135::motorcycle, ru.aggregate=DEF-NRS-484A-125::moped, ru.motorcycle, ru.aggregate=DEF-NRS-484A-025::bicycle, ru.aggregate=DEF-NRS-484B-017::electric_bicycle, ru.aggregate=DEF-NRS-484B-018::electric_scooter -/
def clsX : Formula :=
  .or (aggregate "x" "DEF-NRS-484A-135::motorcycle")
    (.or (aggregate "x" "DEF-NRS-484A-125::moped")
      (.or (.atom "ru_motorcycle" [vX] [])
        (.or (aggregate "x" "DEF-NRS-484A-025::bicycle")
          (.or (aggregate "x" "DEF-NRS-484B-017::electric_bicycle")
            (aggregate "x" "DEF-NRS-484B-018::electric_scooter")))))

/-- b5: x occupied carrier `c` at the observation before this one. -/
def wasOn (c : String) : Formula :=
  .or (.rises (.not (occupies "x" c)))
    (.and (occupies "x" c) (.not (.rises (occupies "x" c))))

/-- b1/b5: a traffic signal showing a steady red with the green arrow `dir`, governing x's
    approach carrier into i (occupied at the observation before the entry) or i itself. -/
def facing (dir : String) : Formula :=
  .existsDevice (.lit "traffic_signal") "s"
    (.and (shows "s" "circular_red")
      (.and (shows "s" s!"green_arrow({dir})")
        (.or (.existsRegion (.lit "travel_region") "c"
               (.and (entersI "c")
                 (.and (wasOn "c") (.atom "dev_governs" [.var "s", .var "c"] []))))
             (.atom "dev_governs" [.var "s", vI] []))))

/-- The entry into i: the observation at which x's overlap with i begins. -/
def entry : Formula := .rises (occupies "x" "i")

/-- φ held at x's last entry into i (read from a later observation, with no entry since). -/
def atEntry (φ : Formula) : Formula := .since (.not entry) (.and entry φ)

/-- b6: the crossing of i, recognized at the exit. -/
def straightThrough : Formula :=
  .derived "drv_motion_straight_through_region" [vX, vI]
    [pHeadingSinceStepCarlaSceneGraph, pStraightThroughMaxHeadingChange]
def leftTurn : Formula :=
  .derived "drv_motion_left_turn_through_region" [vX, vI]
    [pHeadingSinceStepCarlaSceneGraph, pLeftTurnMinAngle, pReversalMinAngle]
def rightTurn : Formula :=
  .derived "drv_motion_right_turn_through_region" [vX, vI]
    [pHeadingSinceStepCarlaSceneGraph, pRightTurnMinAngle, pReversalMinAngle]

/-- b1, b5, b6: x leaves i straight through, or turned opposite the arrow it faced at the entry. -/
def crossing : Formula :=
  .or (.and straightThrough (atEntry (.or (facing "left") (facing "right"))))
    (.or (.and rightTurn (atEntry (facing "left")))
      (.and leftTurn (atEntry (facing "right"))))

/-- Applicability: b1 (trigger): Where the signal is a steady red with a green turn arrow:; b5 (condition): facing the signal; b6 (trigger): may proceed straight through or turn in the direction opposite that indicated by the green turn arrow if: -/
def applicability : Formula := .existsRegion (.lit "intersection") "i" crossing

/-- b12: x and road user `y` in predicted conflict. -/
def conflict (y : String) : Formula :=
  .and (.derived "prim_closest_approach_within" [vX, .var y] [pConflictTimeHorizon])
    (.cmp (.quantity "prim_closest_approach_distance" [vX, .var y] [pConflictTimeHorizon])
      .lt pConflictCentreClearance)

/-- b12: a pedestrian within an adjacent crosswalk of i. -/
def adjacentPedestrian : Formula :=
  .and (aggregate "p" "DEF-NRS-484A-165::pedestrian")
    (.existsRegion (.lit "crosswalk") "w"
      (.and (occupies "p" "w")
        (.existsRegion (.lit "travel_region") "c2"
          (.and (.not (.same (.var "c2") vI))
            (.and (.atom "st_entrance_of" [.var "w", .var "c2"] []) (entersI "c2"))))))

/-- b12: other traffic using i. -/
def otherTraffic : Formula :=
  .and (aggregate "z" "DEF-NRS-484A-285::traffic")
    (.and (.not (.same (.var "z") vX)) (occupies "z" "i"))

/-- b12: the yield at one observation: wherever x moves in i, no predicted conflict with a party. -/
def yieldsHere : Formula :=
  .implies (.and (occupies "x" "i") (.derived "drv_motion_moving" [vX] [pMotionSpeedTolerance]))
    (.and (.forallUser "p" (.implies adjacentPedestrian (.not (conflict "p"))))
      (.forallUser "z" (.implies otherTraffic (.not (conflict "z")))))

/-- Obligation: b12 (obligation): and (4) The person yields the right-of-way to pedestrians lawfully within an adjacent crosswalk and to other traffic lawfully using the intersection. -/
def obligation : Formula :=
  .forallRegion (.lit "intersection") "i"
    (.implies crossing (.not (.since (.not entry) (.not yieldsHere))))

def rule : Rule :=
  { id := "NRS_484B_307_9b_o4"
    laws := ["NRS-484B-307-9b"]
    binders :=
      [ { name := "x", cls := clsX } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations := []
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_307_9b_o4
