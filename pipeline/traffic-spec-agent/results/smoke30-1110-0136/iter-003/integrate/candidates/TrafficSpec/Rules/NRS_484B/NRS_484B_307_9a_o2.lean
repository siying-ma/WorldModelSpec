/-
  NRS_484B_307_9a_o2 — NRS-484B-307-9a

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    a1 (trigger): Where the signal is a steady red with a green turn arrow:
    a2 (reference): Except as otherwise provided in paragraph (b) [NRS-484B-307-9b],
    a3 (subject): vehicular traffic
    a4 (condition): facing the signal
    a5 (sibling): may enter the intersection only to make the movement indicated by the green turn arrow,
    a6 (obligation): but must yield the right-of-way to pedestrians lawfully within an adjacent crosswalk and to other traffic lawfully using the intersection.
    a7 (definitional): Drivers turning in the direction of the arrow are thereby advised that so long as the turn arrow is illuminated, oncoming or opposing traffic simultaneously faces a steady red signal.

  Elements (span → atoms, derived):
    a1: atoms ['dev.traffic_signal', 'dev.governs', 'rel.occupies', 'st.lane_enters', 'st.travel_region', 'st.intersection'], derived []
    a3: atoms ['ru.aggregate=DEF-NRS-484A-285::traffic', 'ru.aggregate=DEF-NRS-484A-165::pedestrian'], derived []
    a4: atoms ['dev.governs', 'dev.traffic_signal', 'rel.occupies', 'st.lane_enters', 'st.travel_region', 'st.intersection'], derived []
    a6: atoms ['prim.closest_approach_within', 'prim.closest_approach_distance', 'rel.occupies', 'st.crosswalk', 'st.entrance_of', 'st.lane_enters', 'st.intersection', 'st.travel_region', 'ru.aggregate=DEF-NRS-484A-165::pedestrian', 'ru.aggregate=DEF-NRS-484A-285::traffic'], derived ['drv.motion.moving']

  Compositions (span → node, as, map):
    a2: NRS_484B_307_9b_o1 as exception map {'x': 'x'}
    a2: NRS_484B_307_9b_o2 as exception map {'x': 'x'}
    a2: NRS_484B_307_9b_o3 as exception map {'x': 'x'}
    a2: NRS_484B_307_9b_o4 as exception map {'x': 'x'}

  How each is written:
    a3: the binder class is ru_aggregate(x, traffic); "vehicular" is the applicability conjunct
        ¬ru_aggregate(x, pedestrian).
    a1/a4: `underArrow i` — x occupies the intersection i, and has since an entry: the rise of
        rel_occupies(x, i) at which some traffic_signal s shows circular_red together with a
        green_arrow of any direction (the four directions as disjuncts) and governs either a
        travel_region c with st_lane_enters(c, i) that x occupied, outside i, at the observation
        before the entry (`since (occ x i) (occ x c ∧ ¬occ x i)` read at the entry), or i itself.
    a2: each paragraph (b) node as `¬ruleApplies` with x ↦ x, conjoined into the applicability.
    a6: for every intersection i satisfying `underArrow i` (the applicability's whole selection,
        restated), while x is moving (drv_motion_moving, p.motion_speed_tolerance): every road user
        p of the pedestrian aggregate occupying a crosswalk w recorded as the entrance of a
        travel_region c2 entering i, and every road user z of the traffic aggregate other than x
        occupying i, is not in predicted conflict with x: not both prim_closest_approach_within over
        p.conflict_time_horizon and prim_closest_approach_distance below p.conflict_centre_clearance.
        The carrier c2 is written distinct from i (`¬same c2 i`): an approach that enters i is never
        i itself, and the intersection, a travel_region with no entry record, would otherwise leave
        st_lane_enters undecided wherever a crosswalk's entrances are not observed.
  No choice beyond the record's.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_307_9a_o2

/-- The binders, as arguments (order and names are the node's). -/
def vX : Arg := .var "x"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pConflictCentreClearance : Term := .param "p.conflict_centre_clearance"
def pConflictTimeHorizon : Term := .param "p.conflict_time_horizon"
def pMotionSpeedTolerance : Term := .param "p.motion_speed_tolerance"

def zeroMetres : Term := .lit Q.zero .metre

def vI : Arg := .var "i"
def vC : Arg := .var "c"
def vS : Arg := .var "s"
def vW : Arg := .var "w"
def vC2 : Arg := .var "c2"
def vP : Arg := .var "p"
def vZ : Arg := .var "z"

def traffic : Arg := .lit "DEF-NRS-484A-285::traffic"
def pedestrian : Arg := .lit "DEF-NRS-484A-165::pedestrian"

def occupies (u r : Arg) : Formula := .atom "rel_occupies" [u, r] []

/-- The signal shows a green arrow, whatever its direction. -/
def greenArrow (s : Arg) : Formula :=
  .or (.atom "dev_traffic_signal_shows" [s, .lit "green_arrow(left)"] [])
    (.or (.atom "dev_traffic_signal_shows" [s, .lit "green_arrow(right)"] [])
      (.or (.atom "dev_traffic_signal_shows" [s, .lit "green_arrow(straight)"] [])
        (.atom "dev_traffic_signal_shows" [s, .lit "green_arrow(u_turn)"] [])))

/-- a4: the signal governs the approach carrier x occupied, outside i, at the observation before
    the entry and whose entrance end is i; or it governs i itself. -/
def facing (s i : Arg) : Formula :=
  .or
    (.existsRegion (.lit "travel_region") "c"
      (.and (.atom "dev_governs" [s, vC] [])
        (.and (.atom "st_lane_enters" [vC, i] [])
          (.since (occupies vX i) (.and (occupies vX vC) (.not (occupies vX i)))))))
    (.atom "dev_governs" [s, i] [])

/-- a1/a4: the entry into i, under a steady red with a green arrow on a signal x faces. -/
def entryUnderArrow (i : Arg) : Formula :=
  .and (.rises (occupies vX i))
    (.existsDevice (.lit "traffic_signal") "s"
      (.and (.atom "dev_traffic_signal_shows" [vS, .lit "circular_red"] [])
        (.and (greenArrow vS) (facing vS i))))

/-- x occupies i, and has occupied it at every observation since its entry under the arrow. -/
def underArrow (i : Arg) : Formula :=
  .since (occupies vX i) (entryUnderArrow i)

/-- Predicted conflict of x with another road user over the horizon. -/
def conflict (y : Arg) : Formula :=
  .and (.derived "prim_closest_approach_within" [vX, y] [pConflictTimeHorizon])
    (.cmp (.quantity "prim_closest_approach_distance" [vX, y] [pConflictTimeHorizon]) .lt
      pConflictCentreClearance)

/-- A pedestrian within a crosswalk marking the entrance of an approach to i. -/
def pedestrianInAdjacentCrosswalk (p i : Arg) : Formula :=
  .and (.atom "ru_aggregate" [p, pedestrian] [])
    (.existsRegion (.lit "crosswalk") "w"
      (.and (occupies p vW)
        (.existsRegion (.lit "travel_region") "c2"
          (.and (.not (.same vC2 i))
            (.and (.atom "st_entrance_of" [vW, vC2] [])
              (.atom "st_lane_enters" [vC2, i] []))))))

/-- Other traffic using i. -/
def otherTrafficInIntersection (z i : Arg) : Formula :=
  .and (.atom "ru_aggregate" [z, traffic] [])
    (.and (.not (.same z vX)) (occupies z i))

/-- Class of `x`: ru.aggregate=DEF-NRS-484A-285::traffic -/
def clsX : Formula := .atom "ru_aggregate" [vX, traffic] []

/-- Applicability: a1 (trigger): Where the signal is a steady red with a green turn arrow:; a4 (condition): facing the signal -/
def applicability : Formula :=
  .and (.not (.atom "ru_aggregate" [vX, pedestrian] []))
    (.and (.existsRegion (.lit "intersection") "i" (underArrow vI))
      (.and (.not (.ruleApplies "NRS_484B_307_9b_o1" [("x", "x")]))
        (.and (.not (.ruleApplies "NRS_484B_307_9b_o2" [("x", "x")]))
          (.and (.not (.ruleApplies "NRS_484B_307_9b_o3" [("x", "x")]))
            (.not (.ruleApplies "NRS_484B_307_9b_o4" [("x", "x")]))))))

/-- Obligation: a6 (obligation): but must yield the right-of-way to pedestrians lawfully within an adjacent crosswalk and to other traffic lawfully using the intersection. -/
def obligation : Formula :=
  .forallRegion (.lit "intersection") "i"
    (.implies (.and (underArrow vI) (.derived "drv_motion_moving" [vX] [pMotionSpeedTolerance]))
      (.and
        (.forallUser "p" (.implies (pedestrianInAdjacentCrosswalk vP vI) (.not (conflict vP))))
        (.forallUser "z" (.implies (otherTrafficInIntersection vZ vI) (.not (conflict vZ))))))

def rule : Rule :=
  { id := "NRS_484B_307_9a_o2"
    laws := ["NRS-484B-307-9a"]
    binders :=
      [ { name := "x", cls := clsX } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations := []
    residues := ["An advisory statement of the signal phasing (opposing traffic faces a steady red while the arrow is lit); it permits, requires and forbids nothing, and no duty of the road user turns on it."]  -- the node's, verbatim; not yours to change
    narrowings := []
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_307_9a_o2
