/-
  NRS_484B_307_8d — NRS-484B-307-8d

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (trigger): Where the signal is a steady red signal alone:
    s2 (condition): After complying with
    s3 (reference): the requirement to stop,
    s4 (subject): a person driving a motorcycle, moped or trimobile or riding a bicycle, an electric bicycle or an electric scooter
    s5 (condition): may proceed straight through or turn right or left
    s6 (boilerplate): if:
    s7 (condition): (1) The person waits for two complete cycles of the lights or lighted arrows of the applicable official traffic-control device
    s8 (condition): and the signal does not change
    s9 (condition): because of a malfunction or because the signal failed to detect the presence of the motorcycle, moped, trimobile, bicycle, electric bicycle or electric scooter;
    s10 (condition): (2) No other device at the place prohibits
    s11 (condition): either or both such turns, if applicable;
    s12 (boilerplate): and
    s13 (obligation): (3) The person yields
    s14 (standard): the right-of-way
    s15 (condition): to pedestrians and other traffic proceeding as directed by the signal at the intersection.

  Elements (span → atoms, derived):
    s1: atoms ['dev.traffic_signal'], derived []
    s2: atoms ['prim.region_offset_along', 'rel.occupies', 'st.crosswalk', 'st.entrance_of', 'st.intersection', 'st.lane_direction', 'st.region_geometry', 'st.stop_line'], derived ['drv.motion.complete_halt'], borrowing ['s3']
    s4: atoms ['ru.aggregate=DEF-NRS-484A-135::motorcycle', 'ru.aggregate=DEF-NRS-484A-125::moped', 'ru.motorcycle', 'ru.aggregate=DEF-NRS-484A-025::bicycle', 'ru.aggregate=DEF-NRS-484B-017::electric_bicycle', 'ru.aggregate=DEF-NRS-484B-018::electric_scooter'], derived []
    s5: atoms ['rel.occupies', 'st.intersection', 'st.lane_enters', 'st.travel_region'], derived []
    s7: atoms ['dev.governs', 'dev.traffic_signal', 'st.intersection', 'st.lane_enters', 'st.travel_region'], derived []
    s8: atoms ['dev.traffic_signal'], derived []
    s10: atoms ['dev.governs', 'dev.regulatory_sign', 'st.intersection', 'st.travel_region'], derived []
    s11: atoms ['rel.occupies', 'st.intersection'], derived ['drv.motion.right_turn_through_region', 'drv.motion.left_turn_through_region']
    s13: atoms ['kin.speed', 'rel.contact'], derived []
    s15: atoms ['ru.aggregate=DEF-NRS-484A-165::pedestrian', 'ru.aggregate=DEF-NRS-484A-285::traffic', 'kin.speed', 'rel.occupies', 'st.intersection', 'st.crosswalk', 'st.entrance_of', 'st.lane_enters', 'st.travel_region', 'dev.governs', 'dev.traffic_signal'], derived []

  Borrowed words (span → source: the words; no rule is composed, the elements naming the span carry them):
    s3: NRS-484B-307-8a: must stop before entering the crosswalk on the nearest side of the intersection where the sign or pavement marking indicates where the stop must be made, or in the absence of any such crosswalk, sign or marking, then before entering the intersection

  Literals the text states (each written through its Units constructor):
    s7: 2 count — two (the count operator takes a natural number: `twoCycles`)

  HOW EACH SPAN IS WRITTEN (variables: i the intersection, c the rider's approach carrier, s the
  rider's signal head; all three bound existentially in the applicability):
    s4: the binder class, the disjunction of the five admitted aggregates and ru_motorcycle (the
        trimobile).
    s5: `entry` — the subject's footprint overlaps i here (rel_occupies), and at the observation
        before it did not overlap i and occupied c (written as the rise of `inI ∨ ¬(onC ∧ wait)`,
        which reads the observation before with no other operator); c enters i (st_lane_enters).
        The judged observations are the entry and every later one at which the subject still
        overlaps i (`since inI entry`).
    s1/s8: `redAlone s` — s shows circular_red and none of the other states of dev.traffic_signal;
        required at the entry and at every observation from the halt's onset to the observation
        before the entry (the φ of the `since` in `wait`), with the subject not overlapping i.
    s2/s3: `halt` — complete_halt (p.halt_speed_tolerance) while occupying c, at the place: the stop
        line recorded as marking c's entrance, else the crosswalk recorded as marking it, else i
        itself; "at" a region is: footprint not overlapping it, the region ahead along c's
        designated direction (prim_region_offset_along > 0, which reads st.lane_direction), and the
        body-to-region distance (st_region_geometry_distance) at most p.stop_point_tolerance.
        "latest onset" is the rise of `halt` read by `since` and by `count`.
    s7: some head h (dev.traffic_signal) governing a travel region that enters i (dev_governs,
        st_lane_enters) has at least `twoCycles` rising edges of a green indication (circular_green
        or any green_arrow) since the start of the latest run of `halt`, counted at the observation
        before the entry. s itself governs c (dev_governs). The travel region c2 the head governs is
        an approach carrier, never the junction itself (`¬ st_intersection c2`): st.lane_enters
        admits as carriers only lanes, roadways, shoulders and bicycle lanes or paths, and an
        intersection carries no entry record, so its own lane_enters is absent rather than false.
    s10/s11: `prohibited` — a regulatory sign governing c or i coded no_right_turn while the passage
        is recognized at its exit as a right turn (`until inI right_turn_through_region`), or coded
        no_left_turn with a left turn; unknown where a sign governs and the exit is unrecorded.
    s13/s14/s15: obligation, for every intersection i selected as in the applicability (lane_enters,
        governs and the whole entry/halt/wait selection; the turn prohibition is a condition on the
        movement, not a selection of i, and is not repeated): every road user p other than the
        subject, of the class pedestrian or traffic, with speed above p.halt_speed_tolerance, and
        overlapping i, or overlapping a crosswalk marking the entrance of a carrier entering i, or
        occupying a carrier entering i governed by a head showing a green indication: not (subject
        speed above p.halt_speed_tolerance, closest approach within p.conflict_horizon at a centre
        distance below p.conflict_centre_clearance), and no contact.
    s9: residue (the node's).

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_307_8d

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pConflictCentreClearance : Term := .param "p.conflict_centre_clearance"
def pConflictHorizon : Term := .param "p.conflict_horizon"
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"
def pHeadingSinceStepCarlaSceneGraph : Term := .param "p.heading_since_step_carla_scene_graph"
def pStopPointTolerance : Term := .param "p.stop_point_tolerance"
def pTurnHeadingMin : Term := .param "p.turn_heading_min"
def pUTurnHeadingMin : Term := .param "p.u_turn_heading_min"

def zeroMetres : Term := .lit Q.zero .metre

/-- s7: the text's literal "two" (complete cycles), a count. -/
def twoCycles : Nat := 2

/-- A disjunction of a non-empty list, with no constant operand. -/
def orAll : List Formula → Formula
  | [] => .ff
  | [φ] => φ
  | φ :: rest => .or φ (orAll rest)

def occ (x r : String) : Formula := .atom "rel_occupies" [.var x, .var r] []
def shows (d ind : String) : Formula := .atom "dev_traffic_signal_shows" [.var d, .lit ind] []
def governs (d r : String) : Formula := .atom "dev_governs" [.var d, .var r] []
def entersI (c i : String) : Formula := .atom "st_lane_enters" [.var c, .var i] []
def entranceOf (m c : String) : Formula := .atom "st_entrance_of" [.var m, .var c] []
def agg (x id : String) : Formula := .atom "ru_aggregate" [.var x, .lit id] []

def arrowDirs : List String := ["left", "right", "straight", "u_turn"]

/-- Every state of dev.traffic_signal other than circular_red. -/
def otherStates : List String :=
  ["circular_green", "circular_yellow", "flashing_red", "flashing_yellow", "dark", "unknown"]
  ++ arrowDirs.map (fun d => s!"green_arrow({d})")
  ++ arrowDirs.map (fun d => s!"yellow_arrow({d})")
  ++ arrowDirs.map (fun d => s!"red_arrow({d})")
  ++ arrowDirs.map (fun d => s!"flashing_yellow_arrow({d})")

/-- s1/s8: head d displays a steady red alone. -/
def redAlone (d : String) : Formula :=
  .and (shows d "circular_red") (.not (orAll (otherStates.map (shows d))))

/-- s7: head d displays a green indication (circular or arrow). -/
def green (d : String) : Formula :=
  orAll (("circular_green" :: arrowDirs.map (fun a => s!"green_arrow({a})")).map (shows d))

/-- The subject's footprint overlaps intersection i. -/
def inI : Formula := occ "subject" "i"
/-- The subject's footprint overlaps carrier c. -/
def onC : Formula := occ "subject" "c"

/-- s2/s3: the subject is at region r as the place of the stop on carrier c: not overlapping it,
    r ahead along c's designated direction, and within the stop-point tolerance of it. -/
def atPlace (r : String) : Formula :=
  .and (.not (occ "subject" r))
    (.and (.cmp (.quantity "prim_region_offset_along" [vSubject, .var r, .var "c"] []) .gt zeroMetres)
          (.cmp (.measure "st_region_geometry_distance" [vSubject, .var r]) .le pStopPointTolerance))

/-- s2/s3: the place of the stop on c: the stop line marking c's entrance, else the crosswalk
    marking it, else the intersection i. -/
def place : Formula :=
  .or (.existsRegion (.lit "stop_line") "l" (.and (entranceOf "l" "c") (atPlace "l")))
    (.and (.not (.existsRegion (.lit "stop_line") "l" (entranceOf "l" "c")))
      (.or (.existsRegion (.lit "crosswalk") "w" (.and (entranceOf "w" "c") (atPlace "w")))
        (.and (.not (.existsRegion (.lit "crosswalk") "w" (entranceOf "w" "c")))
          (atPlace "i"))))

/-- s2: the halt the requirement to stop names: complete cessation from movement on c, at the place. -/
def halt : Formula :=
  .and (.derived "drv_motion_complete_halt" [vSubject] [pHaltSpeedTolerance])
    (.and onC place)

/-- s1/s8 between the halt and the entry: s shows red alone and the subject is not in i. -/
def waiting : Formula := .and (redAlone "s") (.not inI)

/-- s7: some head of the installation at i began a green indication at least two times since the
    latest onset of the halt. -/
def cycles : Formula :=
  .existsDevice (.lit "traffic_signal") "h"
    (.and (.existsRegion (.lit "travel_region") "c2"
            (.and (.not (.atom "st_intersection" [.var "c2"] []))
              (.and (governs "h" "c2") (entersI "c2" "i"))))
          (.count (green "h") halt .ge twoCycles))

/-- s2/s7/s8: from the latest onset of the halt to here, s red alone and the subject outside i, and
    the two cycles counted since that onset. -/
def wait : Formula :=
  .and (.since waiting (.and (.rises halt) waiting)) cycles

/-- s5: the subject enters i here, having occupied c at the observation before, where the wait held;
    s still red alone. -/
def entry : Formula :=
  .and inI (.and (redAlone "s") (.rises (.or inI (.not (.and onC wait)))))

/-- The selection of (i, c, s): c enters i, s governs c, and the subject has overlapped i at every
    observation since such an entry. -/
def selection : Formula :=
  .and (entersI "c" "i") (.and (governs "s" "c") (.since inI entry))

/-- s10/s11: a regulatory sign governing c or i prohibits the turn the passage is recognized as at
    its exit. -/
def prohibited : Formula :=
  .existsDevice (.lit "regulatory_sign") "g"
    (.and (.or (governs "g" "c") (governs "g" "i"))
      (.or (.and (.atom "dev_regulatory_sign_code" [.var "g", .lit "no_right_turn"] [])
                 (.until inI (.derived "drv_motion_right_turn_through_region" [vSubject, .var "i"]
                    [pHeadingSinceStepCarlaSceneGraph, pTurnHeadingMin, pUTurnHeadingMin])))
           (.and (.atom "dev_regulatory_sign_code" [.var "g", .lit "no_left_turn"] [])
                 (.until inI (.derived "drv_motion_left_turn_through_region" [vSubject, .var "i"]
                    [pHeadingSinceStepCarlaSceneGraph, pTurnHeadingMin, pUTurnHeadingMin])))))

/-- s15: road user p is proceeding as directed by the signal at i. -/
def proceeding : Formula :=
  .and (.cmp (.measure "kin_speed" [.var "p"]) .gt pHaltSpeedTolerance)
    (orAll
      [ occ "p" "i"
      , .existsRegion (.lit "crosswalk") "w2"
          (.and (occ "p" "w2")
            (.existsRegion (.lit "travel_region") "c3" (.and (entranceOf "w2" "c3") (entersI "c3" "i"))))
      , .existsRegion (.lit "travel_region") "c4"
          (.and (occ "p" "c4")
            (.and (entersI "c4" "i")
              (.existsDevice (.lit "traffic_signal") "h2" (.and (governs "h2" "c4") (green "h2"))))) ])

/-- s15: p is a pedestrian or other traffic, other than the subject, proceeding as directed. -/
def otherTraffic : Formula :=
  .and (.not (.same (.var "p") vSubject))
    (.and (.or (agg "p" "DEF-NRS-484A-165::pedestrian") (agg "p" "DEF-NRS-484A-285::traffic"))
      proceeding)

/-- s13/s14: the subject grants precedence to p: no danger of a crash while it moves, and no contact. -/
def yields : Formula :=
  .and
    (.not (.and (.cmp (.measure "kin_speed" [vSubject]) .gt pHaltSpeedTolerance)
      (.and (.derived "prim_closest_approach_within" [vSubject, .var "p"] [pConflictHorizon])
            (.cmp (.quantity "prim_closest_approach_distance" [vSubject, .var "p"] [pConflictHorizon])
              .lt pConflictCentreClearance))))
    (.not (.atom "rel_contact" [vSubject, .var "p"] []))

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-135::motorcycle, ru.aggregate=DEF-NRS-484A-125::moped, ru.motorcycle, ru.aggregate=DEF-NRS-484A-025::bicycle, ru.aggregate=DEF-NRS-484B-017::electric_bicycle, ru.aggregate=DEF-NRS-484B-018::electric_scooter -/
def clsSubject : Formula :=
  orAll
    [ agg "subject" "DEF-NRS-484A-135::motorcycle"
    , agg "subject" "DEF-NRS-484A-125::moped"
    , .atom "ru_motorcycle" [vSubject] []
    , agg "subject" "DEF-NRS-484A-025::bicycle"
    , agg "subject" "DEF-NRS-484B-017::electric_bicycle"
    , agg "subject" "DEF-NRS-484B-018::electric_scooter" ]

/-- Applicability: s1, s2/s3, s5, s7, s8, s10, s11 (s9 is a residue). -/
def applicability : Formula :=
  .existsRegion (.lit "intersection") "i"
    (.existsRegion (.lit "travel_region") "c"
      (.existsDevice (.lit "traffic_signal") "s"
        (.and selection (.not prohibited))))

/-- Obligation: s13 (obligation): (3) The person yields; s14 (standard): the right-of-way; s15. -/
def obligation : Formula :=
  .forallRegion (.lit "intersection") "i"
    (.implies
      (.existsRegion (.lit "travel_region") "c" (.existsDevice (.lit "traffic_signal") "s" selection))
      (.forallUser "p" (.implies otherTraffic yields)))

def rule : Rule :=
  { id := "NRS_484B_307_8d"
    laws := ["NRS-484B-307-8d"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations :=
      [ { standard := "the right-of-way: DEF-NRS-484A-210, 'the right of one vehicle or pedestrian to proceed in a lawful manner in preference to another vehicle or pedestrian approaching under such circumstances of direction, speed and proximity as to give rise to the danger of a crash unless one grants precedence to the other'"
          concepts := ["kin.speed", "prim.closest_approach_distance", "prim.closest_approach_within"]
          params := ["p.conflict_horizon", "p.conflict_centre_clearance", "p.halt_speed_tolerance"]
          convention := "traffic-conflict technique: the danger of a crash is a closest approach of the two centres, under constant velocities, within the time-to-collision horizon (p.conflict_horizon) at a centre distance below the conflict clearance (p.conflict_centre_clearance); the rider grants precedence where, while its speed is above the halt tolerance (p.halt_speed_tolerance), no such approach to the other road user arises. Direction, speed and proximity enter by degree through the constant-velocity extrapolation of both road users."
          surrogate := false } ]
    residues := ["The words give the cause of the unchanged red. A head that keeps its steady red alone through two complete cycles of the installation's other indications while the rider waits at its stop place has not served the rider's approach, which is a malfunction or a failure to detect the rider; the duty is the same whichever of the two causes holds, and neither shows in the scene beyond the unchanged red (s8) and the cycles (s7), which the rule reads."]  -- the node's, verbatim; not yours to change
    narrowings := []
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_307_8d
