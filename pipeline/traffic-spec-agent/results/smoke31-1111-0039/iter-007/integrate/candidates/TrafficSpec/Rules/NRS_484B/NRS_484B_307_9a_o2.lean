/-
  NRS_484B_307_9a_o2 — NRS-484B-307-9a

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    b1 (trigger): Where the signal is a steady red with a green turn arrow:
    b2 (reference): Except as otherwise provided in paragraph (b) [NRS-484B-307-9b],
    b3 (subject): vehicular traffic
    b4 (trigger): facing the signal
    b5 (trigger): may enter the intersection
    b6 (sibling): only to make the movement indicated by the green turn arrow,
    b7 (standard): but must yield the right-of-way
    b9 (obligation): to pedestrians lawfully within an adjacent crosswalk and to other traffic lawfully using the intersection.
    b11 (definitional): Drivers turning in the direction of the arrow are thereby advised that so long as the turn arrow is illuminated, oncoming or opposing traffic simultaneously faces a steady red signal.

  Elements (span → atoms, derived):
    b1: atoms ['dev.traffic_signal'], derived []
    b3: atoms ['ru.aggregate=DEF-NRS-484A-285::traffic', 'ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    b4: atoms ['dev.governs', 'st.lane_enters', 'st.travel_region', 'st.intersection', 'rel.occupies'], derived ['drv.motion.entering_region']
    b5: atoms ['rel.occupies', 'st.intersection'], derived ['drv.motion.entering_region']
    b9: atoms ['ru.aggregate=DEF-NRS-484A-165::pedestrian', 'ru.aggregate=DEF-NRS-484A-285::traffic', 'rel.occupies', 'st.crosswalk', 'st.entrance_of', 'st.lane_enters', 'st.intersection'], derived []

  Compositions (span → node, as, map):
    b2: NRS_484B_307_9b_o1 as exception map {'x': 'x'}

  How each is written:
    b3: the class of x is ru_aggregate(x, DEF-NRS-484A-285::traffic) ∧ ru_aggregate(x, DEF-NRS-484A-320::vehicle).
    b1/b4/b5 (`selects i`): an intersection i (region quantifier over `intersection`) that x
      occupies now and has occupied at every observation since its latest entry into i
      (`since (rel_occupies x i) (entry …)`), the entry being drv.motion.entering_region(x, i) at
      an observation where x occupies a carrier c (quantifier over `travel_region`) with
      st_lane_enters(c, i), while some traffic signal s (quantifier over `traffic_signal`) that
      governs c or i shows circular_red together with green_arrow(left) or green_arrow(right).
      An entry before the recording leaves `since` unknown (its unobserved head).
    b2: `.not (.ruleApplies "NRS_484B_307_9b_o1" [x ↦ x])` in the applicability.
    b7/b9 (obligation): where x is moving (drv.motion.moving, p.speed_resolution), for every
      intersection i selected exactly as in the applicability (the whole selection is restated),
      no party is in danger of a crash with x: danger is prim_closest_approach_within over
      p.immediate_hazard_gap with prim_closest_approach_distance below p.conflict_clearance. The
      parties: every road user p ≠ x carrying DEF-NRS-484A-165::pedestrian occupying a crosswalk w
      with st_entrance_of(w, c2) for some carrier c2 (`travel_region`) with st_lane_enters(c2, i);
      every road user u ≠ x carrying DEF-NRS-484A-285::traffic occupying i.
    Choice (narrowing on b9): x itself is never among the pedestrians yielded to (`¬ same p x`),
      as it is excluded from "other traffic" by the words; a road user does not yield to itself.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_307_9a_o2

/-- The binders, as arguments (order and names are the node's). -/
def vX : Arg := .var "x"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pConflictClearance : Term := .param "p.conflict_clearance"
def pImmediateHazardGap : Term := .param "p.immediate_hazard_gap"
def pSpeedResolution : Term := .param "p.speed_resolution"

def zeroMetres : Term := .lit Q.zero .metre

def vI : Arg := .var "i"

def traffic (a : Arg) : Formula := .atom "ru_aggregate" [a, .lit "DEF-NRS-484A-285::traffic"] []
def vehicle (a : Arg) : Formula := .atom "ru_aggregate" [a, .lit "DEF-NRS-484A-320::vehicle"] []
def pedestrian (a : Arg) : Formula := .atom "ru_aggregate" [a, .lit "DEF-NRS-484A-165::pedestrian"] []

def occupies (a r : Arg) : Formula := .atom "rel_occupies" [a, r] []
def laneEnters (c i : Arg) : Formula := .atom "st_lane_enters" [c, i] []
def shows (s : Arg) (k : String) : Formula := .atom "dev_traffic_signal_shows" [s, .lit k] []

/-- Class of `x`: ru.aggregate=DEF-NRS-484A-285::traffic, ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsX : Formula := .and (traffic vX) (vehicle vX)

/-- b1: a steady red with a green turn arrow, on a signal that governs carrier `c` or intersection `i`. -/
def redWithGreenArrow : Formula :=
  .existsDevice (.lit "traffic_signal") "s"
    (.and (.or (.atom "dev_governs" [.var "s", .var "c"] []) (.atom "dev_governs" [.var "s", vI] []))
      (.and (shows (.var "s") "circular_red")
        (.or (shows (.var "s") "green_arrow(left)") (shows (.var "s") "green_arrow(right)"))))

/-- b4/b5: x enters `i` from a carrier `c` entering `i`, facing the signal of b1. -/
def entryUnderArrow : Formula :=
  .and (.derived "drv_motion_entering_region" [vX, vI] [])
    (.existsRegion (.lit "travel_region") "c"
      (.and (occupies vX (.var "c")) (.and (laneEnters (.var "c") vI) redWithGreenArrow)))

/-- The selection of `i`: x occupies it and has since its latest entry, made under the arrow. -/
def selectsI : Formula :=
  .and (occupies vX vI) (.since (occupies vX vI) entryUnderArrow)

/-- Applicability: b1 (trigger): Where the signal is a steady red with a green turn arrow:; b4 (trigger): facing the signal; b5 (trigger): may enter the intersection -/
def applicability : Formula :=
  .and (.existsRegion (.lit "intersection") "i" selectsI)
    (.not (.ruleApplies "NRS_484B_307_9b_o1" [("x", "x")]))

/-- b7: danger of a crash between x and road user `a`. -/
def danger (a : Arg) : Formula :=
  .and (.derived "prim_closest_approach_within" [vX, a] [pImmediateHazardGap])
    (.cmp (.quantity "prim_closest_approach_distance" [vX, a] [pImmediateHazardGap]) .lt pConflictClearance)

/-- b9: a pedestrian within a crosswalk marking the entrance of a carrier entering `i`. -/
def pedestrianInAdjacentCrosswalk : Formula :=
  .and (.not (.same (.var "p") vX))
    (.and (pedestrian (.var "p"))
      (.existsRegion (.lit "crosswalk") "w"
        (.and (occupies (.var "p") (.var "w"))
          (.existsRegion (.lit "travel_region") "c2"
            (.and (.atom "st_entrance_of" [.var "w", .var "c2"] []) (laneEnters (.var "c2") vI))))))

/-- b9: other traffic using `i`. -/
def otherTrafficInIntersection : Formula :=
  .and (.not (.same (.var "u") vX)) (.and (traffic (.var "u")) (occupies (.var "u") vI))

/-- Obligation: b7 (standard): but must yield the right-of-way; b9 (obligation): to pedestrians lawfully within an adjacent crosswalk and to other traffic lawfully using the intersection. -/
def obligation : Formula :=
  .implies (.derived "drv_motion_moving" [vX] [pSpeedResolution])
    (.forallRegion (.lit "intersection") "i"
      (.implies selectsI
        (.and (.forallUser "p" (.implies pedestrianInAdjacentCrosswalk (.not (danger (.var "p")))))
          (.forallUser "u" (.implies otherTrafficInIntersection (.not (danger (.var "u"))))))))

def rule : Rule :=
  { id := "NRS_484B_307_9a_o2"
    laws := ["NRS-484B-307-9a"]
    binders :=
      [ { name := "x", cls := clsX } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations :=
      [ { standard := "yield the right-of-way: not proceeding where the parties' \"direction, speed and proximity\" \"give rise to the danger of a crash unless one grants precedence to the other\" (DEF-NRS-484A-210)"
          concepts := ["drv.motion.moving", "kin.speed", "prim.closest_approach_distance", "prim.closest_approach_within"]
          params := ["p.speed_resolution", "p.immediate_hazard_gap", "p.conflict_clearance"]
          convention := "Gap-acceptance and surrogate-safety convention: the subject grants precedence where it does not proceed (it is not moving, drv.motion.moving) while a party is in danger of a crash with it; that danger is their predicted closest approach under constant velocities, within the critical gap, coming nearer than the conflict radius, so direction, speed and proximity all enter the prediction by their degree."
          surrogate := false } ]
    residues := ["An advisory to drivers turning with the arrow about what opposing traffic faces at the same time; it permits, requires and forbids nothing, and no rule reads it."]  -- the node's, verbatim; not yours to change
    narrowings :=
      [ { span := "b9"
          why := "x itself is not among the pedestrians yielded to (p ≠ x): a road user does not yield to itself, as the words exclude it from \"other traffic\"."
          kind := "reading" } ]
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_307_9a_o2
