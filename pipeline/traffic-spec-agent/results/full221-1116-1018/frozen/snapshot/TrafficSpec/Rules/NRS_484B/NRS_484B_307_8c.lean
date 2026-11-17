/-
  NRS_484B_307_8c — NRS-484B-307-8c

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (trigger): Where the signal is a steady red signal alone:
    s2 (condition): After complying with
    s3 (reference): the requirement to stop,
    s4 (subject): vehicular traffic facing such a signal and situated on the extreme right of the highway
    s5 (condition): may proceed into the intersection
    s6 (condition): for a right turn
    s7 (condition): only when the intersecting highway is two-directional or one-way to the right,
    s8 (subject): or vehicular traffic facing such a signal and situated on the extreme left of a one-way highway
    s9 (condition): may proceed into the intersection
    s10 (condition): for a left turn
    s11 (condition): only when the intersecting highway is one-way to the left,
    s12 (obligation): but must yield
    s13 (standard): the right-of-way
    s14 (condition): to pedestrians and other traffic proceeding as directed by the signal at the intersection.

  Elements (span → atoms, derived):
    s1: atoms ['dev.traffic_signal'], derived []
    s2: atoms ['prim.region_offset_along', 'rel.occupies', 'st.crosswalk', 'st.entrance_of', 'st.intersection', 'st.lane_direction', 'st.region_geometry', 'st.stop_line'], derived ['drv.motion.complete_halt'], borrowing ['s3']
    s4: atoms ['dev.governs', 'rel.occupies', 'ru.aggregate=DEF-NRS-484A-285::traffic', 'ru.aggregate=DEF-NRS-484A-320::vehicle', 'st.lane', 'st.lane_adjacency', 'st.lane_enters', 'st.travel_region', 'st.intersection'], derived []
    s5: atoms ['rel.occupies', 'st.intersection', 'st.lane_enters', 'st.travel_region'], derived []
    s7: atoms ['st.highway', 'st.on_way', 'st.intersection', 'st.lane', 'st.lane_direction', 'st.median_or_divider'], derived []
    s8: atoms ['dev.governs', 'rel.occupies', 'ru.aggregate=DEF-NRS-484A-285::traffic', 'ru.aggregate=DEF-NRS-484A-320::vehicle', 'st.lane', 'st.lane_adjacency', 'st.lane_enters', 'st.one_way_roadway'], derived []
    s9: atoms ['rel.occupies', 'st.intersection', 'st.lane_enters', 'st.travel_region'], derived []
    s11: atoms ['st.highway', 'st.on_way', 'st.intersection', 'st.lane', 'st.lane_direction'], derived []
    s12: atoms ['kin.speed', 'rel.contact'], derived []
    s14: atoms ['ru.aggregate=DEF-NRS-484A-165::pedestrian', 'ru.aggregate=DEF-NRS-484A-285::traffic', 'kin.speed', 'rel.occupies', 'st.intersection', 'st.crosswalk', 'st.entrance_of', 'st.lane_enters', 'st.travel_region', 'dev.governs', 'dev.traffic_signal'], derived []

  Borrowed words (span → source: the words; no rule is composed, the elements naming the span carry them):
    s3: NRS-484B-307-8a: must stop before entering the crosswalk on the nearest side of the intersection where the sign or pavement marking indicates where the stop must be made, or in the absence of any such crosswalk, sign or marking, then before entering the intersection

  How each span is written (the coding session's record):
    Selection (`selected i c sig`, shared by the applicability and, whole, by the obligation):
      intersection i (quantifier kind `intersection`), travel region c (kind `travel_region`)
      with `st_lane_enters c i`, traffic-signal head sig (device kind `traffic_signal`) with
      `dev_governs sig c` ("facing such a signal", s4/s8).
    s5/s9 the entry: `occ subject i` now and, at the observation before, the subject was on the
      approach (`occ subject c ∧ ¬occ subject i`). The "observation before" is read through
      `rises (¬ haltedOnApproach)`: haltedOnApproach requires the approach, so it is false at the
      entry and its fall marks that it held at the observation before.
    s2 with s3 (the history bound): `haltedOnApproach i c` = `since onApproach (onApproach ∧ halted)`:
      the subject halted (drv.motion.complete_halt at p.halt_speed_tolerance) at the place of the
      stop while on the approach, and has stayed on the approach since — so the halt is on the
      approach that ends in this entry and nowhere earlier. The place, in the order the record
      gives: the stop line recorded as marking c's entrance (st_entrance_of); where no stop line
      marks c, the crosswalk marking it; where neither does, i itself. At the place m: the body
      does not overlap m, m lies ahead along c's designated direction
      (prim_region_offset_along > 0) and the body-to-m distance (st_region_geometry_distance) is at
      most p.stop_point_tolerance.
    s1 "steady red alone": sig shows circular_red and none of the other states; where the head
      displays `unknown` beside it, whether red is alone is undefined (unknown), never decided.
    s4/s6/s7 right branch: st_lane c; ordinal(c) = count(c) (st_lane_adjacency_ordinal/_count);
      intent int.right_turn of the subject at i; every highway h that i lies on and c does not
      (st_on_way) is two-directional (no median_or_divider lies on h, and two lanes on h have
      designated directions whose dot product is below −p.lane_opposed_direction_cos) or one-way
      to the right (some lane lies on h and every lane on h has cross(d_c, d_l) below
      −p.cross_direction_sin_min).
    s8/s10/s11 left branch: st_lane c; c is leftmost — no lane is c's left neighbour of its
      direction (`st_lane_adjacency c left _`, which the accessor decides false for every lane
      exactly where c has ordinal 1 and no left neighbour; this reads "ordinal 1" without a
      numeric literal); the subject's footprint overlaps a one_way_roadway; intent int.left_turn
      at i; every such highway is one-way to the left (cross above p.cross_direction_sin_min).
    Duration: `since (occ subject i) (entry ∧ redAlone ∧ (right ∨ left))` — the footprint has
      overlapped i at every observation since the entry, the judged one included.
    s12/s13/s14 obligation: for every selected (i, c, sig) — the whole selection repeated, as the
      obligation speaks of the i the applicability selected — every road user p other than the
      subject, of class pedestrian or traffic (ru_aggregate), proceeding (kin_speed above
      p.halt_speed_tolerance, and: overlapping i; or overlapping a crosswalk recorded as marking
      the entrance of a travel region entering i; or occupying a travel region entering i
      governed by a head showing circular_green or a green_arrow): not (subject speed above
      p.halt_speed_tolerance ∧ prim_closest_approach_within at p.conflict_horizon ∧
      prim_closest_approach_distance below p.conflict_centre_clearance), and not rel_contact.
  No narrowing of my own: every choice above is the record's statement or an exact restatement.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_307_8c

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pConflictCentreClearance : Term := .param "p.conflict_centre_clearance"
def pConflictHorizon : Term := .param "p.conflict_horizon"
def pCrossDirectionSinMin : Term := .param "p.cross_direction_sin_min"
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"
def pLaneOpposedDirectionCos : Term := .param "p.lane_opposed_direction_cos"
def pStopPointTolerance : Term := .param "p.stop_point_tolerance"

def zeroMetres : Term := .lit Q.zero .metre

-- ---------------------------------------------------------------------------------------------
-- Small builders
-- ---------------------------------------------------------------------------------------------
def conj : List Formula → Formula
  | [] => .tt
  | [φ] => φ
  | φ :: rest => .and φ (conj rest)

def disj : List Formula → Formula
  | [] => .ff
  | [φ] => φ
  | φ :: rest => .or φ (disj rest)

def occ (who r : String) : Formula := .atom "rel_occupies" [.var who, .var r] []
def shows (d ind : String) : Formula := .atom "dev_traffic_signal_shows" [.var d, .lit ind] []
def onWay (r w : String) : Formula := .atom "st_on_way" [.var r, .var w] []
def enters (c i : String) : Formula := .atom "st_lane_enters" [.var c, .var i] []
def entranceOf (l c : String) : Formula := .atom "st_entrance_of" [.var l, .var c] []
def governs (d r : String) : Formula := .atom "dev_governs" [.var d, .var r] []
def dirX (r : String) : Term := .measure "st_lane_direction" [.var r, .lit "x"]
def dirY (r : String) : Term := .measure "st_lane_direction" [.var r, .lit "y"]
/-- cross(d_a, d_b) = a_x·b_y − a_y·b_x: positive where b points to the left of a. -/
def crossDir (a b : String) : Term := .sub (.mul (dirX a) (dirY b)) (.mul (dirY a) (dirX b))
def dotDir (a b : String) : Term := .add (.mul (dirX a) (dirX b)) (.mul (dirY a) (dirY b))

-- ---------------------------------------------------------------------------------------------
-- s1: a steady red signal alone
-- ---------------------------------------------------------------------------------------------
def otherIndications : List String :=
  [ "circular_green", "circular_yellow", "flashing_red", "flashing_yellow", "dark",
    "green_arrow(left)", "green_arrow(right)", "green_arrow(straight)", "green_arrow(u_turn)",
    "yellow_arrow(left)", "yellow_arrow(right)", "yellow_arrow(straight)", "yellow_arrow(u_turn)",
    "red_arrow(left)", "red_arrow(right)", "red_arrow(straight)", "red_arrow(u_turn)",
    "flashing_yellow_arrow(left)", "flashing_yellow_arrow(right)", "flashing_yellow_arrow(straight)",
    "flashing_yellow_arrow(u_turn)" ]

def redAlone (d : String) : Formula :=
  .definedWhen (.not (shows d "unknown"))
    (.and (shows d "circular_red") (.not (disj (otherIndications.map (shows d ·)))))

-- ---------------------------------------------------------------------------------------------
-- s2 with s3: the halt at the place of the stop, on the approach that ends in this entry
-- ---------------------------------------------------------------------------------------------
def haltAt (m c : String) : Formula :=
  conj [ .not (occ "subject" m),
         .cmp (.quantity "prim_region_offset_along" [vSubject, .var m, .var c] []) .gt zeroMetres,
         .cmp (.measure "st_region_geometry_distance" [vSubject, .var m]) .le pStopPointTolerance ]

def stopLineMarks (c : String) : Formula :=
  .existsRegion (.lit "stop_line") "m0" (entranceOf "m0" c)

def crosswalkMarks (c : String) : Formula :=
  .existsRegion (.lit "crosswalk") "m1" (entranceOf "m1" c)

def stopPlace (i c : String) : Formula :=
  disj [ .existsRegion (.lit "stop_line") "m" (.and (entranceOf "m" c) (haltAt "m" c)),
         .and (.not (stopLineMarks c))
              (.existsRegion (.lit "crosswalk") "m" (.and (entranceOf "m" c) (haltAt "m" c))),
         conj [ .not (stopLineMarks c), .not (crosswalkMarks c), haltAt i c ] ]

def halted (i c : String) : Formula :=
  .and (.derived "drv_motion_complete_halt" [vSubject] [pHaltSpeedTolerance]) (stopPlace i c)

def onApproach (i c : String) : Formula := .and (occ "subject" c) (.not (occ "subject" i))

def haltedOnApproach (i c : String) : Formula :=
  .since (onApproach i c) (.and (onApproach i c) (halted i c))

/-- s5/s9: the entry into i from the approach c, the halt behind it. -/
def entry (i c : String) : Formula :=
  .and (occ "subject" i) (.rises (.not (haltedOnApproach i c)))

-- ---------------------------------------------------------------------------------------------
-- s7 / s11: the intersecting highway
-- ---------------------------------------------------------------------------------------------
def intersecting (i c h : String) : Formula := .and (onWay i h) (.not (onWay c h))

def twoDirectional (h : String) : Formula :=
  .and (.not (.existsRegion (.lit "median_or_divider") "md" (onWay "md" h)))
       (.existsRegion (.lit "lane") "l1" (.existsRegion (.lit "lane") "l2"
          (conj [ onWay "l1" h, onWay "l2" h,
                  .cmp (dotDir "l1" "l2") .lt (.neg pLaneOpposedDirectionCos) ])))

def oneWayRight (c h : String) : Formula :=
  .and (.existsRegion (.lit "lane") "l" (onWay "l" h))
       (.forallRegion (.lit "lane") "l"
          (.implies (onWay "l" h) (.cmp (crossDir c "l") .lt (.neg pCrossDirectionSinMin))))

def oneWayLeft (c h : String) : Formula :=
  .and (.existsRegion (.lit "lane") "l" (onWay "l" h))
       (.forallRegion (.lit "lane") "l"
          (.implies (onWay "l" h) (.cmp (crossDir c "l") .gt pCrossDirectionSinMin)))

/-- s4, s6, s7: extreme right lane, a right turn, the intersecting highway two-directional or
    one-way to the right. -/
def rightBranch (i c : String) : Formula :=
  conj [ .atom "st_lane" [.var c] [],
         .cmp (.measure "st_lane_adjacency_ordinal" [.var c]) .eq (.measure "st_lane_adjacency_count" [.var c]),
         .intent "int.right_turn" vSubject (.var i),
         .forallRegion (.lit "highway") "h"
           (.implies (intersecting i c "h") (.or (twoDirectional "h") (oneWayRight c "h"))) ]

/-- s8, s10, s11: extreme left lane of a one-way highway, a left turn, the intersecting highway
    one-way to the left. -/
def leftBranch (i c : String) : Formula :=
  conj [ .atom "st_lane" [.var c] [],
         .forallRegion (.lit "lane") "lft" (.not (.atom "st_lane_adjacency" [.var c, .lit "left", .var "lft"] [])),
         .existsRegion (.lit "one_way_roadway") "w" (occ "subject" "w"),
         .intent "int.left_turn" vSubject (.var i),
         .forallRegion (.lit "highway") "h" (.implies (intersecting i c "h") (oneWayLeft c "h")) ]

/-- The whole selection of (i, c, sig): the approach, the head facing it, and the subject in i at
    every observation since its entry under a steady red alone after the halt, on a branch. -/
def selected (i c d : String) : Formula :=
  conj [ enters c i,
         governs d c,
         .since (occ "subject" i)
           (conj [ entry i c, redAlone d, .or (rightBranch i c) (leftBranch i c) ]) ]

-- ---------------------------------------------------------------------------------------------
-- s12, s13, s14: yield the right-of-way
-- ---------------------------------------------------------------------------------------------
def greenShown (d : String) : Formula :=
  disj [ shows d "circular_green", shows d "green_arrow(left)", shows d "green_arrow(right)",
         shows d "green_arrow(straight)", shows d "green_arrow(u_turn)" ]

def proceeding (p i : String) : Formula :=
  .and (.cmp (.measure "kin_speed" [.var p]) .gt pHaltSpeedTolerance)
    (disj [ occ p i,
            .existsRegion (.lit "crosswalk") "k"
              (.and (occ p "k")
                    (.existsRegion (.lit "travel_region") "ck" (.and (entranceOf "k" "ck") (enters "ck" i)))),
            .existsRegion (.lit "travel_region") "cg"
              (conj [ enters "cg" i, occ p "cg",
                      .existsDevice (.lit "traffic_signal") "sg" (.and (governs "sg" "cg") (greenShown "sg")) ]) ])

def duty (i : String) : Formula :=
  .forallUser "p"
    (.implies
      (conj [ .not (.same (.var "p") vSubject),
              .or (.atom "ru_aggregate" [.var "p", .lit "DEF-NRS-484A-165::pedestrian"] [])
                  (.atom "ru_aggregate" [.var "p", .lit "DEF-NRS-484A-285::traffic"] []),
              proceeding "p" i ])
      (.and
        (.not (conj [ .cmp (.measure "kin_speed" [vSubject]) .gt pHaltSpeedTolerance,
                      .derived "prim_closest_approach_within" [vSubject, .var "p"] [pConflictHorizon],
                      .cmp (.quantity "prim_closest_approach_distance" [vSubject, .var "p"] [pConflictHorizon])
                        .lt pConflictCentreClearance ]))
        (.not (.atom "rel_contact" [vSubject, .var "p"] []))))

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-285::traffic, ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula :=
  .and (.atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-285::traffic"] [])
       (.atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-320::vehicle"] [])

/-- Applicability: s1 (trigger): Where the signal is a steady red signal alone:; s2 (condition): After complying with; s5 (condition): may proceed into the intersection; s6 (condition): for a right turn; s7 (condition): only when the intersecting highway is two-directional or one-way to the right,; s9 (condition): may proceed into the intersection; s10 (condition): for a left turn; s11 (condition): only when the intersecting highway is one-way to the left,; s14 (condition): to pedestrians and other traffic proceeding as directed by the signal at the intersection. -/
def applicability : Formula :=
  .existsRegion (.lit "intersection") "i"
    (.existsRegion (.lit "travel_region") "c"
      (.existsDevice (.lit "traffic_signal") "sig" (selected "i" "c" "sig")))

/-- Obligation: s12 (obligation): but must yield; s13 (standard): the right-of-way -/
def obligation : Formula :=
  .forallRegion (.lit "intersection") "i"
    (.forallRegion (.lit "travel_region") "c"
      (.forallDevice (.lit "traffic_signal") "sig"
        (.implies (selected "i" "c" "sig") (duty "i"))))

def rule : Rule :=
  { id := "NRS_484B_307_8c"
    laws := ["NRS-484B-307-8c"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := ["int.right_turn", "int.left_turn"]
    operationalizations :=
      [ { standard := "the right-of-way: DEF-NRS-484A-210, 'the right of one vehicle or pedestrian to proceed in a lawful manner in preference to another vehicle or pedestrian approaching under such circumstances of direction, speed and proximity as to give rise to the danger of a crash unless one grants precedence to the other'"
          concepts := ["kin.speed", "prim.closest_approach_distance", "prim.closest_approach_within"]
          params := ["p.conflict_horizon", "p.conflict_centre_clearance", "p.halt_speed_tolerance"]
          convention := "traffic-conflict technique: the danger of a crash is a closest approach of the two centres, under constant velocities, within the time-to-collision horizon (p.conflict_horizon) at a centre distance below the conflict clearance (p.conflict_centre_clearance); the subject grants precedence where, while its speed is above the halt tolerance (p.halt_speed_tolerance), no such approach to the other road user arises. Direction, speed and proximity enter by degree through the constant-velocity extrapolation of both road users."
          surrogate := false } ]
    residues := []
    narrowings := []
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_307_8c
