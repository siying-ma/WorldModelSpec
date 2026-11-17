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
    s7: 2 count — two

  No magnitude below is this file's own: parameters name the reading, literals are the text's.

  HOW THE SPANS ARE WRITTEN
    The applicability selects an intersection i (st.intersection quantifier), an approach carrier c
    (st.travel_region quantifier) with st_lane_enters c i, and a signal head s (dev.traffic_signal
    quantifier) with dev_governs s c (s7: the rider's own head). `sel i` holds at the judged
    observation when:
      s5: the subject entered i — `entry`: its footprint overlaps i (rel_occupies), and at the
          observation before it overlapped c and not i — and has overlapped i at every observation
          since (`since (occ i) entry`). "the observation before" is read through `rises Z` with
          Z = occ i ∨ ¬occ c ∨ ¬waited: true at the entry, false exactly where, the observation
          before, the subject was on c, outside i, and `waited` held there.
      s1/s8: s displays circular_red and none of the other states (`redAlone`) at the entry and at
          every observation from the latest onset of the halt (`rises halt`) up to the entry, with
          the subject outside i throughout (`since`).
      s2/s3: `halt c i` = drv_motion_complete_halt (p.halt_speed_tolerance) ∧ the subject occupies c
          ∧ it is at the place: a stop line recorded (st_entrance_of) as marking c's entrance; else
          a crosswalk so recorded; else i itself — the footprint not overlapping that region,
          prim_region_offset_along (along c's st.lane_direction) positive (the region ahead), and
          st_region_geometry_distance within p.stop_point_tolerance.
      s7: some head of the installation (a traffic signal governing a travel region that enters i)
          shows a rising green indication (circular_green or a green_arrow) at least two times
          (literal 2) since the latest onset of the halt (`count … (halt c i) .ge 2`, compared with
          the literal as a count term through `cond` so that the formula names the text's figure),
          read at the observation before the entry. The carrier of such a head is a region other than i itself
          (`¬ same`): an intersection is no approach of itself, and st.lane_enters is not recorded
          on an intersection region, so without it a source that cannot tell what a head governs
          would leave the entry topology of the intersection region in question as well.
      s10/s11: no regulatory sign governing c or i is coded no_right_turn while the passage begun at
          the entry is recognized at its exit as a right turn (drv_motion_right_turn_through_region,
          read ahead with `until (occ i) …`), nor coded no_left_turn while it is recognized as a
          left turn (drv_motion_left_turn_through_region). Where no such sign governs, this holds
          whatever the movement; where one does and the exit is not recorded, it is unknown.
    The obligation repeats the whole selection of i (`sel`) for every intersection so selected and
    requires, for every road user p other than the subject (s15) of the aggregate pedestrian or
    traffic, proceeding as directed — kin_speed above p.halt_speed_tolerance and either overlapping
    i, or overlapping a crosswalk recorded as marking the entrance of a travel region that enters i,
    or occupying a travel region entering i governed by a head showing a green indication —
    s13/s14: not (the subject's kin_speed above p.halt_speed_tolerance ∧
    prim_closest_approach_within (p.conflict_horizon) ∧ prim_closest_approach_distance below
    p.conflict_centre_clearance), and no rel_contact between the two.

  No narrowing is declared: every choice above is the record's own statement of the span.
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

/-- s7: "two" complete cycles — the text's literal, a count of rising green indications. -/
def twoCycles : Nat := 2
def twoCyclesLit : Term := .lit (Units.ratio 2 1) .count
def zeroCount : Term := .lit Q.zero .count

/-- At least two (s7) rising edges of `edge` since the latest onset of `onset`: the count operator
    compared with the text's literal, the literal carried as a count term so that the comparison
    names it (`cond` selects the literal where the count reaches it, zero where it does not). -/
def atLeastTwoRises (edge onset : Formula) : Formula :=
  .cmp (.cond (.count edge onset .ge twoCycles) twoCyclesLit zeroCount) .ge twoCyclesLit

-- ---------------------------------------------------------------------------------------------
-- Small builders over the claimed atoms
-- ---------------------------------------------------------------------------------------------
def anyF : List Formula → Formula
  | [] => .ff
  | [φ] => φ
  | φ :: rest => .or φ (anyF rest)

def allF : List Formula → Formula
  | [] => .tt
  | [φ] => φ
  | φ :: rest => .and φ (allF rest)

def occ (x r : String) : Formula := .atom "rel_occupies" [.var x, .var r] []
def shows (d ind : String) : Formula := .atom "dev_traffic_signal_shows" [.var d, .lit ind] []
def governs (d r : String) : Formula := .atom "dev_governs" [.var d, .var r] []
def enters (c i : String) : Formula := .atom "st_lane_enters" [.var c, .var i] []
def marks (l c : String) : Formula := .atom "st_entrance_of" [.var l, .var c] []
def agg (x id : String) : Formula := .atom "ru_aggregate" [.var x, .lit id] []
def speedAbove (x : String) : Formula :=
  .cmp (.measure "kin_speed" [.var x]) .gt pHaltSpeedTolerance

/-- Every state of dev.traffic_signal other than circular_red. -/
def otherIndications : List String :=
  [ "circular_green", "circular_yellow", "flashing_red", "flashing_yellow", "dark", "unknown",
    "green_arrow(left)", "green_arrow(right)", "green_arrow(straight)", "green_arrow(u_turn)",
    "yellow_arrow(left)", "yellow_arrow(right)", "yellow_arrow(straight)", "yellow_arrow(u_turn)",
    "red_arrow(left)", "red_arrow(right)", "red_arrow(straight)", "red_arrow(u_turn)",
    "flashing_yellow_arrow(left)", "flashing_yellow_arrow(right)", "flashing_yellow_arrow(straight)",
    "flashing_yellow_arrow(u_turn)" ]

/-- The green indications: the lights or lighted arrows that come on once in each cycle. -/
def greenIndications : List String :=
  [ "circular_green", "green_arrow(left)", "green_arrow(right)", "green_arrow(straight)", "green_arrow(u_turn)" ]

/-- s1/s8: head `s` displays a steady red signal alone. -/
def redAlone (s : String) : Formula :=
  .and (shows s "circular_red") (.not (anyF (otherIndications.map (shows s))))

/-- A head displays a green indication. -/
def greenOn (d : String) : Formula := anyF (greenIndications.map (shows d))

-- ---------------------------------------------------------------------------------------------
-- s2/s3: the halt at the place of the stop
-- ---------------------------------------------------------------------------------------------
/-- The subject's footprint does not overlap region `r`, `r` lies ahead along carrier `c`'s
    designated direction, and the body is within p.stop_point_tolerance of it. -/
def near (r c : String) : Formula :=
  allF [ .not (occ "subject" r),
         .cmp (.quantity "prim_region_offset_along" [vSubject, .var r, .var c] []) .gt zeroMetres,
         .cmp (.measure "st_region_geometry_distance" [vSubject, .var r]) .le pStopPointTolerance ]

/-- The place: the stop line marking c's entrance; else the crosswalk marking it; else i. -/
def place (c i : String) : Formula :=
  anyF [ .existsRegion (.lit "stop_line") "lineAt" (.and (marks "lineAt" c) (near "lineAt" c)),
         allF [ .not (.existsRegion (.lit "stop_line") "lineAny" (marks "lineAny" c)),
                .existsRegion (.lit "crosswalk") "walkAt" (.and (marks "walkAt" c) (near "walkAt" c)) ],
         allF [ .not (.existsRegion (.lit "stop_line") "lineNone" (marks "lineNone" c)),
                .not (.existsRegion (.lit "crosswalk") "walkNone" (marks "walkNone" c)),
                near i c ] ]

/-- The subject at complete cessation from movement on carrier c, at the place of the stop. -/
def halt (c i : String) : Formula :=
  allF [ .derived "drv_motion_complete_halt" [vSubject] [pHaltSpeedTolerance],
         occ "subject" c,
         place c i ]

/-- The wait: s red alone and the subject outside i. -/
def waitPhase (s i : String) : Formula := .and (redAlone s) (.not (occ "subject" i))

/-- s2/s7/s8, read at an observation before the entry: from the latest onset of the halt, s red
    alone and the subject outside i at every observation, and some head of the installation has
    begun a green indication at least two times since that onset. -/
def waited (c i s : String) : Formula :=
  .and
    (.since (waitPhase s i) (.and (.rises (halt c i)) (waitPhase s i)))
    (.existsDevice (.lit "traffic_signal") "head"
      (.existsRegion (.lit "travel_region") "headCarrier"
        (allF [ .not (.same (.var "headCarrier") (.var i)),
                enters "headCarrier" i,
                governs "head" "headCarrier",
                atLeastTwoRises (greenOn "head") (halt c i) ])))

/-- s5: the entry into i from c, s still red alone, after the wait held at the observation before. -/
def entry (c i s : String) : Formula :=
  allF [ occ "subject" i,
         redAlone s,
         .rises (anyF [occ "subject" i, .not (occ "subject" c), .not (waited c i s)]) ]

def rightTurn (i : String) : Formula :=
  .derived "drv_motion_right_turn_through_region" [vSubject, .var i]
    [pHeadingSinceStepCarlaSceneGraph, pTurnHeadingMin, pUTurnHeadingMin]

def leftTurn (i : String) : Formula :=
  .derived "drv_motion_left_turn_through_region" [vSubject, .var i]
    [pHeadingSinceStepCarlaSceneGraph, pTurnHeadingMin, pUTurnHeadingMin]

/-- s10/s11: a sign at the place prohibits the turn this passage through i makes at its exit. -/
def turnBarred (c i : String) : Formula :=
  .existsDevice (.lit "regulatory_sign") "sign"
    (.and (.or (governs "sign" c) (governs "sign" i))
      (.or (.and (.atom "dev_regulatory_sign_code" [.var "sign", .lit "no_right_turn"] [])
                 (.until (occ "subject" i) (rightTurn i)))
           (.and (.atom "dev_regulatory_sign_code" [.var "sign", .lit "no_left_turn"] [])
                 (.until (occ "subject" i) (leftTurn i)))))

/-- The whole selection of intersection i: the approach c, the rider's head s, the halt, the
    wait, the entry and the passage since, and no prohibited turn. -/
def sel (i : String) : Formula :=
  .existsRegion (.lit "travel_region") "c"
    (.existsDevice (.lit "traffic_signal") "s"
      (allF [ enters "c" i,
              governs "s" "c",
              .since (occ "subject" i) (entry "c" i "s"),
              .not (turnBarred "c" i) ]))

/-- s15: road user p proceeding as directed by the signal at i. -/
def proceeding (p i : String) : Formula :=
  .and (speedAbove p)
    (anyF [ occ p i,
            .existsRegion (.lit "crosswalk") "walkP"
              (.existsRegion (.lit "travel_region") "carrierP"
                (allF [enters "carrierP" i, marks "walkP" "carrierP", occ p "walkP"])),
            .existsRegion (.lit "travel_region") "carrierG"
              (allF [ enters "carrierG" i, occ p "carrierG",
                      .existsDevice (.lit "traffic_signal") "headP"
                        (.and (governs "headP" "carrierG") (greenOn "headP")) ]) ])

/-- s13/s14: the subject yields the right-of-way to p. -/
def yields (p : String) : Formula :=
  .and
    (.not (allF [ speedAbove "subject",
                  .derived "prim_closest_approach_within" [vSubject, .var p] [pConflictHorizon],
                  .cmp (.quantity "prim_closest_approach_distance" [vSubject, .var p] [pConflictHorizon])
                    .lt pConflictCentreClearance ]))
    (.not (.atom "rel_contact" [vSubject, .var p] []))

def duty (i : String) : Formula :=
  .forallUser "p"
    (.implies
      (allF [ .not (.same (.var "p") vSubject),
              .or (agg "p" "DEF-NRS-484A-165::pedestrian") (agg "p" "DEF-NRS-484A-285::traffic"),
              proceeding "p" i ])
      (yields "p"))

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-135::motorcycle, ru.aggregate=DEF-NRS-484A-125::moped, ru.motorcycle, ru.aggregate=DEF-NRS-484A-025::bicycle, ru.aggregate=DEF-NRS-484B-017::electric_bicycle, ru.aggregate=DEF-NRS-484B-018::electric_scooter -/
def clsSubject : Formula :=
  anyF [ agg "subject" "DEF-NRS-484A-135::motorcycle",
         agg "subject" "DEF-NRS-484A-125::moped",
         .atom "ru_motorcycle" [vSubject] [],
         agg "subject" "DEF-NRS-484A-025::bicycle",
         agg "subject" "DEF-NRS-484B-017::electric_bicycle",
         agg "subject" "DEF-NRS-484B-018::electric_scooter" ]

/-- Applicability: s1, s2/s3, s5, s7, s8, s10, s11 (s9 a residue). -/
def applicability : Formula := .existsRegion (.lit "intersection") "i" (sel "i")

/-- Obligation: s13/s14 towards the road users of s15, at every intersection so selected. -/
def obligation : Formula :=
  .forallRegion (.lit "intersection") "i" (.implies (sel "i") (duty "i"))

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
