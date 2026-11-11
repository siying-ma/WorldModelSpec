/-
  NRS_484B_307_9b_o4 — NRS-484B-307-9b

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    c1 (trigger): Where the signal is a steady red with a green turn arrow:
    c2 (subject): A person driving a motorcycle, moped or
    c3 (subject): trimobile
    c4 (subject): or riding a bicycle, an electric bicycle or an electric scooter
    c5 (trigger): facing the signal
    c6 (trigger): may proceed straight through or turn in the direction opposite that indicated by the green turn arrow
    c7 (boilerplate): if:
    c8 (sibling): (1) The person stops before entering the crosswalk ...
    c9 (sibling): (2) The person waits for two complete cycles ...
    c11 (sibling): (3) No other device at the place prohibits the turn, if applicable;
    c12 (boilerplate): and
    c13 (standard): (4) The person yields the right-of-way
    c15 (obligation): to pedestrians lawfully within an adjacent crosswalk and to other traffic lawfully using the intersection.

  Elements (span → atoms, derived):
    c1: atoms ['dev.traffic_signal'], derived []
    c2: atoms ['ru.aggregate=DEF-NRS-484A-135::motorcycle', 'ru.aggregate=DEF-NRS-484A-125::moped'], derived []
    c4: atoms ['ru.aggregate=DEF-NRS-484A-025::bicycle', 'ru.aggregate=DEF-NRS-484B-017::electric_bicycle', 'ru.aggregate=DEF-NRS-484B-018::electric_scooter'], derived []
    c5: atoms ['dev.governs', 'st.lane_enters', 'st.travel_region', 'st.intersection', 'rel.occupies'], derived ['drv.motion.entering_region']
    c6: atoms ['rel.occupies', 'st.intersection', 'kin.yaw_rate'], derived ['drv.motion.entering_region', 'drv.motion.leaving_region', 'drv.motion.heading_change_since_entry']
    c15: atoms ['ru.aggregate=DEF-NRS-484A-165::pedestrian', 'ru.aggregate=DEF-NRS-484A-285::traffic', 'rel.occupies', 'st.crosswalk', 'st.entrance_of', 'st.lane_enters', 'st.intersection'], derived []

  How each is written.
    c2, c4 — `clsX`: x carries one of the five admitted aggregates (`ru_aggregate` with the id).
      c3 is the node's residue (a trimobile is in the motorcycle aggregate).
    The passage — `passage`: x occupies intersection i, or leaves it at this observation
      (`drv_motion_leaving_region`). The rule is judged at the leaving; the latest run of
      `passage` ending there starts at x's latest entry into i (`drv_motion_entering_region`),
      so "from that entry up to the leaving" is that run.
    "read through a past operator" — `count edge passage .eq 0`: no rising edge of `edge` since
      the start of the run of `passage`. An `edge` that holds through the whole run never rises
      inside it; one that fails at some observation of the run rises again by the leaving, at
      which it holds. So `count edge passage .eq 0` says `edge` held at every observation from
      the entry to the leaving. `count` is used rather than `since` because its start is the
      start of the run itself: where the overlap is unobserved the result is unknown for that
      reason alone, not for the unobserved past before the recording.
    c1, c5 — `facingRedWithArrow dir`, read at the entry (the edge is `entering → …`): x occupies a
      carrier c (`st.travel_region`, `rel_occupies`) with `st_lane_enters c i`, and some traffic
      signal s that governs c or i (`dev_governs`) shows `circular_red` and `green_arrow(dir)`.
      The direction of the arrow is fixed at the entry and the heading change read at the leaving,
      so the two arrow directions, left and right, are written as two disjuncts.
    c6 — `drv_motion_heading_change_since_entry x i` (step `p.heading_since_step_carla_scene_graph`)
      at the leaving. Straight through is |change| < `p.turn_recognition_angle`; a turn opposite a
      left arrow is a change beyond the angle to the right. Their union under a left arrow is
      "change < angle", under a right arrow "change > −angle"; the rule writes that union (the
      single value −angle itself, neither straight nor beyond, falls in it).
    c13 (operationalization) — x proceeds (`drv_motion_moving`, `p.speed_resolution`) while some
      party is in danger of a crash with it: `prim_closest_approach_within` over
      `p.immediate_hazard_gap` and `prim_closest_approach_distance` below `p.conflict_clearance`.
    c15 — the parties: every road user p other than x carrying the pedestrian aggregate whose
      footprint overlaps a crosswalk w recorded as marking the entrance of a carrier c2 entering i
      (`st_entrance_of w c2`, `st_lane_enters c2 i`); every road user u other than x carrying the
      traffic aggregate whose footprint overlaps i. The duty (`duty`): at every observation from
      the entry to the leaving, it is not the case that x occupies i, is moving, and does not yield
      to such a party.
    The obligation re-selects i by the applicability's whole selection (`selection`) and holds the
      duty for every intersection so selected.

  Choices the text did not dictate: x itself is excluded from the parties yielded to (`same`), as
  "pedestrians" and "other traffic" are parties other than the person yielding. No narrowing of my
  own; the node's narrowings (c2/c4 observable reading, c15 reading) are on its record.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_307_9b_o4

/-- The binders, as arguments (order and names are the node's). -/
def vX : Arg := .var "x"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pConflictClearance : Term := .param "p.conflict_clearance"
def pHeadingSinceStepCarlaSceneGraph : Term := .param "p.heading_since_step_carla_scene_graph"
def pImmediateHazardGap : Term := .param "p.immediate_hazard_gap"
def pSpeedResolution : Term := .param "p.speed_resolution"
def pTurnRecognitionAngle : Term := .param "p.turn_recognition_angle"

def zeroMetres : Term := .lit Q.zero .metre

def vI : Arg := .var "i"

def aggregate (u : String) (id : String) : Formula := .atom "ru_aggregate" [.var u, .lit id] []
def occupies (u r : String) : Formula := .atom "rel_occupies" [.var u, .var r] []

/-- Class of `x`: ru.aggregate=DEF-NRS-484A-135::motorcycle, ru.aggregate=DEF-NRS-484A-125::moped, ru.aggregate=DEF-NRS-484A-025::bicycle, ru.aggregate=DEF-NRS-484B-017::electric_bicycle, ru.aggregate=DEF-NRS-484B-018::electric_scooter -/
def clsX : Formula :=
  .or (aggregate "x" "DEF-NRS-484A-135::motorcycle")
    (.or (aggregate "x" "DEF-NRS-484A-125::moped")
      (.or (aggregate "x" "DEF-NRS-484A-025::bicycle")
        (.or (aggregate "x" "DEF-NRS-484B-017::electric_bicycle")
          (aggregate "x" "DEF-NRS-484B-018::electric_scooter"))))

/-- c5/c6: x enters, leaves intersection i. -/
def entering : Formula := .derived "drv_motion_entering_region" [vX, vI] []
def leaving : Formula := .derived "drv_motion_leaving_region" [vX, vI] []

/-- x's passage through i: in it, or leaving it here. Its latest run, judged at the leaving, runs
    from x's latest entry into i to the leaving. -/
def passage : Formula := .or (occupies "x" "i") leaving

/-- `edge` at every observation of the passage, from the entry to here (see the header). -/
def throughoutPassage (edge : Formula) : Formula := .count (.and passage edge) passage .eq 0

/-- c1/c5: x occupies a carrier c entering i, and a traffic signal s governing c or i shows a
    steady red together with a green arrow in direction `dir`. -/
def facingRedWithArrow (dir : String) : Formula :=
  .existsRegion (.lit "travel_region") "c"
    (.and (occupies "x" "c")
      (.and (.atom "st_lane_enters" [.var "c", vI] [])
        (.existsDevice (.lit "traffic_signal") "s"
          (.and (.or (.atom "dev_governs" [.var "s", .var "c"] []) (.atom "dev_governs" [.var "s", vI] []))
            (.and (.atom "dev_traffic_signal_shows" [.var "s", .lit "circular_red"] [])
              (.atom "dev_traffic_signal_shows" [.var "s", .lit s!"green_arrow({dir})"] []))))))

/-- At the latest entry into i, x faced the red with a green arrow in direction `dir`. -/
def enteredUnder (dir : String) : Formula := throughoutPassage (.implies entering (facingRedWithArrow dir))

/-- c6: the heading change since x's entry into i, read at the leaving. -/
def headingChange : Term :=
  .quantity "drv_motion_heading_change_since_entry" [vX, vI] [pHeadingSinceStepCarlaSceneGraph]

/-- Straight through, or a turn opposite a left arrow (to the right). -/
def straightOrOppositeLeft : Formula := .cmp headingChange .lt pTurnRecognitionAngle
/-- Straight through, or a turn opposite a right arrow (to the left). -/
def straightOrOppositeRight : Formula := .cmp headingChange .gt (.neg pTurnRecognitionAngle)

/-- The selection of i: x leaves i here, having entered it under the red with a green arrow, and
    passed straight through or turned opposite the arrow. -/
def selection : Formula :=
  .and leaving
    (.or (.and (enteredUnder "left") straightOrOppositeLeft)
      (.and (enteredUnder "right") straightOrOppositeRight))

/-- Applicability: c1 (trigger): Where the signal is a steady red with a green turn arrow:; c5 (trigger): facing the signal; c6 (trigger): may proceed straight through or turn in the direction opposite that indicated by the green turn arrow -/
def applicability : Formula := .existsRegion (.lit "intersection") "i" selection

/-- c13: the danger of a crash between x and road user `u`. -/
def inDanger (u : String) : Formula :=
  .and (.derived "prim_closest_approach_within" [vX, .var u] [pImmediateHazardGap])
    (.cmp (.quantity "prim_closest_approach_distance" [vX, .var u] [pImmediateHazardGap]) .lt pConflictClearance)

/-- c15: a pedestrian p, other than x, within a crosswalk marking the entrance of a carrier entering i. -/
def pedestrianInAdjacentCrosswalk : Formula :=
  .and (.not (.same (.var "p") vX))
    (.and (aggregate "p" "DEF-NRS-484A-165::pedestrian")
      (.existsRegion (.lit "crosswalk") "w"
        (.and (occupies "p" "w")
          (.existsRegion (.lit "travel_region") "c2"
            (.and (.atom "st_entrance_of" [.var "w", .var "c2"] [])
              (.atom "st_lane_enters" [.var "c2", vI] []))))))

/-- c15: other traffic u using the intersection. -/
def otherTrafficInIntersection : Formula :=
  .and (.not (.same (.var "u") vX))
    (.and (aggregate "u" "DEF-NRS-484A-285::traffic") (occupies "u" "i"))

/-- c13/c15: no party yielded to is in danger of a crash with x. -/
def noPartyInDanger : Formula :=
  .and (.forallUser "p" (.implies pedestrianInAdjacentCrosswalk (.not (inDanger "p"))))
    (.forallUser "u" (.implies otherTrafficInIntersection (.not (inDanger "u"))))

/-- x proceeds inside i without yielding. -/
def proceedsWithoutYielding : Formula :=
  .and (occupies "x" "i")
    (.and (.derived "drv_motion_moving" [vX] [pSpeedResolution]) (.not noPartyInDanger))

/-- From the entry up to the leaving, x never proceeds inside i without yielding. -/
def duty : Formula := throughoutPassage (.not proceedsWithoutYielding)

/-- Obligation: c13 (standard): (4) The person yields the right-of-way; c15 (obligation): to pedestrians lawfully within an adjacent crosswalk and to other traffic lawfully using the intersection. -/
def obligation : Formula := .forallRegion (.lit "intersection") "i" (.implies selection duty)

def rule : Rule :=
  { id := "NRS_484B_307_9b_o4"
    laws := ["NRS-484B-307-9b"]
    binders :=
      [ { name := "x", cls := clsX } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations :=
      [ { standard := "yields the right-of-way: not proceeding where the parties' \"direction, speed and proximity\" \"give rise to the danger of a crash unless one grants precedence to the other\" (DEF-NRS-484A-210)"
          concepts := ["drv.motion.moving", "kin.speed", "prim.closest_approach_distance", "prim.closest_approach_within"]
          params := ["p.speed_resolution", "p.immediate_hazard_gap", "p.conflict_clearance"]
          convention := "Gap-acceptance and surrogate-safety convention: the person grants precedence where they do not proceed (not moving, drv.motion.moving) while a party is in danger of a crash with them; that danger is the predicted closest approach under constant velocities, within the critical gap, coming nearer than the conflict radius, so direction, speed and proximity all enter the prediction by their degree."
          surrogate := false } ]
    residues := ["Every trimobile, a motor vehicle with a seat designed to travel on three wheels, is already a member of the motorcycle aggregate claimed on span c2 (\"every motor vehicle equipped with a seat or saddle for the use of the driver and designed to travel on not more than three wheels in contact with the ground\"): the duty is the same whether or not the word is read."]  -- the node's, verbatim; not yours to change
    narrowings := []
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_307_9b_o4
