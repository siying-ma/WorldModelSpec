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
    b3: atoms ['ru.aggregate=DEF-NRS-484A-285::traffic', 'ru.aggregate=DEF-NRS-484A-165::pedestrian'], derived []
    b4: atoms ['dev.governs', 'st.lane_enters', 'st.travel_region', 'st.intersection', 'rel.occupies'], derived ['drv.motion.entering_region']
    b5: atoms ['rel.occupies', 'st.intersection'], derived ['drv.motion.entering_region']
    b9: atoms ['ru.aggregate=DEF-NRS-484A-165::pedestrian', 'ru.aggregate=DEF-NRS-484A-285::traffic', 'rel.occupies', 'st.crosswalk', 'st.entrance_of', 'st.lane_enters', 'st.intersection'], derived []

  Compositions (span → node, as, map):
    b2: NRS_484B_307_9b_o1 as exception map {'x': 'x'}

  How each is written:
    b3: class of x = ru_aggregate(x, traffic) ∧ ¬ ru_aggregate(x, pedestrian).
    b1, b4, b5: some intersection i that x occupies, and has occupied at every observation since
      (`since`) the observation it entered i (drv_motion_entering_region) from a travel region c it
      occupied with st_lane_enters(c, i), while a traffic signal governing c or i showed
      circular_red with green_arrow(left) or green_arrow(right).
    b2: ¬ ruleApplies NRS_484B_307_9b_o1 {x ↦ x}.
    b7, b9: where x is moving (drv_motion_moving, p.speed_resolution), at every intersection the
      applicability selects (its selection restated), every pedestrian occupying a crosswalk that is
      the entrance of a travel region entering i, and every other member of traffic occupying i,
      is not in conflict with x: prim_closest_approach_within over p.immediate_hazard_gap and a
      prim_closest_approach_distance below p.conflict_clearance.

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

def aggTraffic : Arg := .lit "DEF-NRS-484A-285::traffic"
def aggPedestrian : Arg := .lit "DEF-NRS-484A-165::pedestrian"

/-- b3: vehicular traffic — a member of traffic that is no pedestrian. -/
def clsX : Formula :=
  .and (.atom "ru_aggregate" [vX, aggTraffic] [])
    (.not (.atom "ru_aggregate" [vX, aggPedestrian] []))

/-- b1: signal `s` displays a steady red together with a green turn arrow, left or right. -/
def redWithGreenArrow : Formula :=
  .and (.atom "dev_traffic_signal_shows" [.var "s", .lit "circular_red"] [])
    (.or (.atom "dev_traffic_signal_shows" [.var "s", .lit "green_arrow(left)"] [])
         (.atom "dev_traffic_signal_shows" [.var "s", .lit "green_arrow(right)"] []))

/-- b4, b5: at this observation `x` enters intersection `i` from a carrier `c` it occupies that
    enters `i`, while a traffic signal governing `c` or `i` displays b1's indication. -/
def entryUnderArrow : Formula :=
  .and (.derived "drv_motion_entering_region" [vX, .var "i"] [])
    (.existsRegion (.lit "travel_region") "c"
      (.and (.atom "rel_occupies" [vX, .var "c"] [])
        (.and (.atom "st_lane_enters" [.var "c", .var "i"] [])
          (.existsDevice (.lit "traffic_signal") "s"
            (.and (.or (.atom "dev_governs" [.var "s", .var "c"] [])
                       (.atom "dev_governs" [.var "s", .var "i"] []))
              redWithGreenArrow)))))

/-- The intersection `i` selected: `x` occupies it, and has at every observation since its latest
    entry into it, which was made facing a steady red with a green arrow. -/
def inIntersectionSinceArrowEntry : Formula :=
  .and (.atom "rel_occupies" [vX, .var "i"] [])
    (.since (.atom "rel_occupies" [vX, .var "i"] []) entryUnderArrow)

/-- Applicability: b1, b4, b5; b2 — not engaged where NRS_484B_307_9b_o1 applies to x. -/
def applicability : Formula :=
  .and (.existsRegion (.lit "intersection") "i" inIntersectionSinceArrowEntry)
    (.not (.ruleApplies "NRS_484B_307_9b_o1" [("x", "x")]))

/-- b7: danger of a crash between `x` and road user `v` — their predicted closest approach within
    the critical gap comes nearer than the conflict radius. -/
def conflictWith (v : String) : Formula :=
  .and (.derived "prim_closest_approach_within" [vX, .var v] [pImmediateHazardGap])
    (.cmp (.quantity "prim_closest_approach_distance" [vX, .var v] [pImmediateHazardGap]) .lt pConflictClearance)

/-- b9: a pedestrian within a crosswalk marking the entrance of a carrier that enters `i`. -/
def pedestrianInAdjacentCrosswalk : Formula :=
  .and (.atom "ru_aggregate" [.var "p", aggPedestrian] [])
    (.existsRegion (.lit "crosswalk") "w"
      (.and (.atom "rel_occupies" [.var "p", .var "w"] [])
        (.existsRegion (.lit "travel_region") "c2"
          (.and (.atom "st_entrance_of" [.var "w", .var "c2"] [])
            (.atom "st_lane_enters" [.var "c2", .var "i"] [])))))

/-- b9: other traffic using `i`. -/
def otherTrafficInIntersection : Formula :=
  .and (.not (.same (.var "u") vX))
    (.and (.atom "ru_aggregate" [.var "u", aggTraffic] [])
      (.atom "rel_occupies" [.var "u", .var "i"] []))

/-- Obligation: b7, b9 — while proceeding, no such party is in danger of a crash with `x`, at
    every intersection the applicability selects. -/
def obligation : Formula :=
  .implies (.derived "drv_motion_moving" [vX] [pSpeedResolution])
    (.forallRegion (.lit "intersection") "i"
      (.implies inIntersectionSinceArrowEntry
        (.and
          (.forallUser "p" (.implies pedestrianInAdjacentCrosswalk (.not (conflictWith "p"))))
          (.forallUser "u" (.implies otherTrafficInIntersection (.not (conflictWith "u")))))))

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
    narrowings := []  -- one { span := "<span id>", why := "<why>", kind := "reading" } per reading you chose on a carried span (kind no_atom / no_operator where the words cannot be stated), explained in the header; the record's own narrowings are not restated
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_307_9a_o2
