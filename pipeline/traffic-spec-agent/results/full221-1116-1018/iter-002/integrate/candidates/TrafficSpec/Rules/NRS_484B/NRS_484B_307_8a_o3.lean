/-
  NRS_484B_307_8a_o3 — NRS-484B-307-8a

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (trigger): Where the signal is a steady red signal alone:
    s2 (subject): Vehicular traffic facing the signal
    s3 (sibling): must stop before entering the crosswalk on the nearest side of the intersection where the sign or pavement marking indicates where the stop must be made, or in the absence of any such crosswalk, sign or marking, then before entering the intersection,
    s4 (boilerplate): and,
    s5 (sibling): except as otherwise provided in paragraphs (c) and (d) [(c) is appended below, NRS-484B-307-8d],
    s6 (sibling): must remain stopped or standing until the green signal is shown.
    s7 (condition): After complying with the requirement to stop,
    s8 (subject): vehicular traffic facing such a signal and situated on the extreme right of the highway
    s9 (condition): may proceed into the intersection
    s10 (condition): for a right turn
    s11 (condition): only when the intersecting highway is two-directional or one-way to the right,
    s12 (subject): or vehicular traffic facing such a signal and situated on the extreme left of a one-way highway
    s13 (condition): may proceed into the intersection
    s14 (condition): for a left turn
    s15 (condition): only when the intersecting highway is one-way to the left,
    s16 (obligation): but must yield
    s17 (standard): the right-of-way
    s18 (condition): to pedestrians and other traffic proceeding as directed by the signal at the intersection.

  Elements (span → atoms, derived):
    s1: atoms ['dev.traffic_signal'], derived []
    s2: atoms ['dev.governs', 'rel.occupies', 'ru.aggregate=DEF-NRS-484A-285::traffic', 'ru.aggregate=DEF-NRS-484A-320::vehicle', 'st.intersection', 'st.lane_enters', 'st.travel_region'], derived []
    s7: atoms ['prim.region_offset_along', 'rel.occupies', 'st.crosswalk', 'st.entrance_of', 'st.intersection', 'st.lane_direction', 'st.region_geometry', 'st.stop_line'], derived ['drv.motion.complete_halt']
    s8: atoms ['dev.governs', 'rel.occupies', 'ru.aggregate=DEF-NRS-484A-285::traffic', 'ru.aggregate=DEF-NRS-484A-320::vehicle', 'st.lane', 'st.lane_adjacency', 'st.lane_enters'], derived []
    s9: atoms ['rel.occupies', 'st.intersection', 'st.lane_enters', 'st.travel_region'], derived []
    s11: atoms ['st.highway', 'st.on_way', 'st.intersection', 'st.lane', 'st.lane_direction', 'st.median_or_divider'], derived []
    s12: atoms ['dev.governs', 'rel.occupies', 'ru.aggregate=DEF-NRS-484A-285::traffic', 'ru.aggregate=DEF-NRS-484A-320::vehicle', 'st.lane', 'st.lane_adjacency', 'st.lane_enters', 'st.one_way_roadway'], derived []
    s13: atoms ['rel.occupies', 'st.intersection', 'st.lane_enters', 'st.travel_region'], derived []
    s15: atoms ['st.highway', 'st.on_way', 'st.intersection', 'st.lane', 'st.lane_direction'], derived []
    s16: atoms ['kin.speed', 'rel.contact'], derived []
    s18: atoms ['ru.aggregate=DEF-NRS-484A-165::pedestrian', 'ru.aggregate=DEF-NRS-484A-285::traffic', 'kin.speed', 'rel.occupies', 'st.intersection', 'st.crosswalk', 'st.entrance_of', 'st.lane_enters', 'st.travel_region', 'dev.governs', 'dev.traffic_signal'], derived []

  How each span is written.
    Binder: `subject` is of both admitted aggregates, traffic and vehicle (`ru_aggregate`, ids as claimed).
    The selection (s1, s2, s7, s8/s9/s10/s11, s12/s13/s14/s15), written once as `selection i c s` and
    used by both formulas so that the obligation speaks of the same intersection, carrier and head:
      - i ranges over intersections, c over travel regions, s over traffic-signal heads; s governs c
        (`dev_governs`) and c's entrance end is i (`st_lane_enters`).
      - s9/s13 entry: the subject's footprint overlaps i here and did not at the observation before
        (`rises (occupies i)`), and at that observation it overlapped c: written as
        `not (rises (occupies i or occupies c))`, which, given the rise of `occupies i`, is exactly
        "occupies c at the observation before" (the language has no previous-observation operator;
        this is the equivalent statement).
      - s1: at the entry, s shows `circular_red` and none of the other indications of the signal
        enumeration (steady red, alone).
      - s7: the halt (`drv_motion_complete_halt`, p.halt_speed_tolerance) at the place of the stop:
        a stop line recorded as marking c's entrance; else (no such stop line) a crosswalk recorded as
        marking it; else (neither) i itself. At that place: footprint not overlapping the region
        (`rel_occupies`), region ahead along c's designated direction (`prim_region_offset_along` > 0)
        and body-to-region gap within p.stop_point_tolerance (`st_region_geometry_distance`).
        History bound: the halt is on the approach that ends in this entry — from the halt up to the
        entry the subject occupied c and not i at every observation, the entry observation itself
        being the rise into i (`since`). The record names this bound by reference to NRS_484B_307_8a_o1;
        it is written here from this node's own atoms as the approach through c ending in the entry.
      - s8 (right): c is a lane (`st_lane`) whose ordinal equals the count of lanes in its direction
        (`st_lane_adjacency_ordinal` = `st_lane_adjacency_count`); s10: `int.right_turn` declared true
        for the subject at i, at the entry observation; s11: every highway i lies on (`st_on_way`) that
        c does not lie on is two-directional (no median or divider lies on it, and two lanes on it
        have designated directions whose dot product is below −p.lane_opposed_direction_cos) or
        one-way to the right (some lane lies on it, and every lane on it has c's direction × its
        direction below −p.cross_direction_sin_min).
      - s12 (left): c is a lane of ordinal 1, written through the same atom's neighbour reading: no
        lane is c's left neighbour of the same direction (`st_lane_adjacency` with side `left`, which
        Core decides false for every lane exactly where c's ordinal is 1); this avoids a bare count
        literal the node does not declare. "of a one-way highway": the subject's footprint overlaps a
        one-way roadway (`st_one_way_roadway`, `rel_occupies`). s14: `int.left_turn` declared true at
        i at the entry; s15: every such highway is one-way to the left (some lane on it; every lane
        on it has the cross product above p.cross_direction_sin_min).
      - The footprint has overlapped i at every observation since that entry, the judged one
        included (`since (occupies i) entry`).
    Obligation (s16, s17, s18): for every selected (i, c, s) and every road user p other than the
    subject, of the aggregate pedestrian or traffic, moving (speed above p.halt_speed_tolerance) and
    proceeding as directed by the signal at i — its footprint overlaps i, or overlaps a crosswalk
    recorded as marking the entrance of a travel region entering i, or it occupies a travel region
    entering i governed by a head showing `circular_green` or a `green_arrow` — it is not the case
    that the subject's speed is above p.halt_speed_tolerance while the centres' closest approach lies
    within p.conflict_horizon at a centre distance below p.conflict_centre_clearance; and the bodies
    do not touch (`rel_contact`). The standard s17 is the node's operationalization, unchanged.

  No reading of mine narrows a span: `narrowings` is empty.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_307_8a_o3

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

/-- The subject binder's name. -/
def subj : String := "subject"

/-- The admitted aggregates, by the ids the node claims. -/
def aggTraffic : String := "DEF-NRS-484A-285::traffic"
def aggVehicle : String := "DEF-NRS-484A-320::vehicle"
def aggPedestrian : String := "DEF-NRS-484A-165::pedestrian"

-- ---------------------------------------------------------------------------------------------
-- Leaves
-- ---------------------------------------------------------------------------------------------
def occ (x r : String) : Formula := .atom "rel_occupies" [.var x, .var r] []
def agg (x id : String) : Formula := .atom "ru_aggregate" [.var x, .lit id] []
def shows (s ind : String) : Formula := .atom "dev_traffic_signal_shows" [.var s, .lit ind] []
def governs (s r : String) : Formula := .atom "dev_governs" [.var s, .var r] []
def entersI (c i : String) : Formula := .atom "st_lane_enters" [.var c, .var i] []
def onWay (r h : String) : Formula := .atom "st_on_way" [.var r, .var h] []
def entranceOf (l c : String) : Formula := .atom "st_entrance_of" [.var l, .var c] []
def speedOf (x : String) : Term := .measure "kin_speed" [.var x]
def dirX (r : String) : Term := .measure "st_lane_direction" [.var r, .lit "x"]
def dirY (r : String) : Term := .measure "st_lane_direction" [.var r, .lit "y"]

def disj : List Formula → Formula
  | [] => .ff
  | [φ] => φ
  | φ :: rest => .or φ (disj rest)

def conj : List Formula → Formula
  | [] => .tt
  | [φ] => φ
  | φ :: rest => .and φ (conj rest)

-- ---------------------------------------------------------------------------------------------
-- s1: a steady red signal alone; s18: a green indication
-- ---------------------------------------------------------------------------------------------
def arrowDirs : List String := ["left", "right", "straight", "u_turn"]
def arrowsOf (kind : String) : List String := arrowDirs.map fun d => kind ++ "(" ++ d ++ ")"

/-- Every indication of the signal enumeration other than `circular_red`. -/
def otherThanRed : List String :=
  ["circular_green", "circular_yellow", "flashing_red", "flashing_yellow", "dark", "unknown"]
    ++ arrowsOf "green_arrow" ++ arrowsOf "yellow_arrow" ++ arrowsOf "red_arrow"
    ++ arrowsOf "flashing_yellow_arrow"

def steadyRedAlone (s : String) : Formula :=
  .and (shows s "circular_red") (.not (disj (otherThanRed.map (shows s))))

def greenShown (s : String) : Formula :=
  disj ((["circular_green"] ++ arrowsOf "green_arrow").map (shows s))

-- ---------------------------------------------------------------------------------------------
-- s7: after complying with the requirement to stop
-- ---------------------------------------------------------------------------------------------
/-- The subject's body is before region r on carrier c: not overlapping it, r ahead along c's
    designated direction, the body-to-region gap within the stop-point tolerance. -/
def haltPlaceAt (r c : String) : Formula := conj
  [ .not (occ subj r)
  , .cmp (.quantity "prim_region_offset_along" [.var subj, .var r, .var c] []) .gt zeroMetres
  , .cmp (.measure "st_region_geometry_distance" [.var subj, .var r]) .le pStopPointTolerance ]

def markedBy (kind v c : String) : Formula := .existsRegion (.lit kind) v (entranceOf v c)

/-- The place of the stop on approach c into i: the stop line marking c's entrance; else the
    crosswalk marking it; else the intersection itself. -/
def stopPlace (i c : String) : Formula := disj
  [ .existsRegion (.lit "stop_line") "sl" (.and (entranceOf "sl" c) (haltPlaceAt "sl" c))
  , .and (.not (markedBy "stop_line" "sl2" c))
      (.existsRegion (.lit "crosswalk") "cw" (.and (entranceOf "cw" c) (haltPlaceAt "cw" c)))
  , conj [ .not (markedBy "stop_line" "sl3" c), .not (markedBy "crosswalk" "cw2" c), haltPlaceAt i c ] ]

def haltedAtPlace (i c : String) : Formula :=
  .and (.derived "drv_motion_complete_halt" [.var subj] [pHaltSpeedTolerance]) (stopPlace i c)

/-- On the approach through c that ends in the entry into i. -/
def onApproach (i c : String) : Formula :=
  .or (.and (occ subj c) (.not (occ subj i))) (.rises (occ subj i))

def compliedWithStop (i c : String) : Formula := .since (onApproach i c) (haltedAtPlace i c)

-- ---------------------------------------------------------------------------------------------
-- s9 / s13: the entry into i from c
-- ---------------------------------------------------------------------------------------------
def entersFrom (i c : String) : Formula :=
  .and (.rises (occ subj i)) (.not (.rises (.or (occ subj i) (occ subj c))))

-- ---------------------------------------------------------------------------------------------
-- s11 / s15: the intersecting highway
-- ---------------------------------------------------------------------------------------------
/-- c's designated direction × lane l's (positive where l points to c's left). -/
def crossOf (c l : String) : Term := .sub (.mul (dirX c) (dirY l)) (.mul (dirY c) (dirX l))

def twoDirectional (h : String) : Formula := .and
  (.not (.existsRegion (.lit "median_or_divider") "md" (onWay "md" h)))
  (.existsRegion (.lit "lane") "la" (.and (onWay "la" h)
    (.existsRegion (.lit "lane") "lb" (.and (onWay "lb" h)
      (.cmp (.add (.mul (dirX "la") (dirX "lb")) (.mul (dirY "la") (dirY "lb"))) .lt
        (.neg pLaneOpposedDirectionCos))))))

def oneWayRight (c h : String) : Formula := .and
  (.existsRegion (.lit "lane") "lc" (onWay "lc" h))
  (.forallRegion (.lit "lane") "ld" (.implies (onWay "ld" h)
    (.cmp (crossOf c "ld") .lt (.neg pCrossDirectionSinMin))))

def oneWayLeft (c h : String) : Formula := .and
  (.existsRegion (.lit "lane") "le" (onWay "le" h))
  (.forallRegion (.lit "lane") "lf" (.implies (onWay "lf" h)
    (.cmp (crossOf c "lf") .gt pCrossDirectionSinMin)))

/-- φ of every highway i lies on other than one c lies on. -/
def everyIntersecting (i c h : String) (φ : Formula) : Formula :=
  .forallRegion (.lit "highway") h (.implies (.and (onWay i h) (.not (onWay c h))) φ)

-- ---------------------------------------------------------------------------------------------
-- s8-s11 (right) and s12-s15 (left)
-- ---------------------------------------------------------------------------------------------
def rightTurnCase (i c : String) : Formula := conj
  [ .atom "st_lane" [.var c] []
  , .cmp (.measure "st_lane_adjacency_ordinal" [.var c]) .eq (.measure "st_lane_adjacency_count" [.var c])
  , .intent "int.right_turn" (.var subj) (.var i)
  , everyIntersecting i c "hr" (.or (twoDirectional "hr") (oneWayRight c "hr")) ]

def leftTurnCase (i c : String) : Formula := conj
  [ .atom "st_lane" [.var c] []
  , .not (.existsRegion (.lit "lane") "ln" (.atom "st_lane_adjacency" [.var c, .lit "left", .var "ln"] []))
  , .existsRegion (.lit "one_way_roadway") "ow" (occ subj "ow")
  , .intent "int.left_turn" (.var subj) (.var i)
  , everyIntersecting i c "hl" (oneWayLeft c "hl") ]

/-- The entry into i from c under s's steady red alone, after the halt at the place, on one of
    the two permitted turns. -/
def entryOnRed (i c s : String) : Formula := conj
  [ entersFrom i c
  , steadyRedAlone s
  , compliedWithStop i c
  , .or (rightTurnCase i c) (leftTurnCase i c) ]

/-- The whole selection of (i, c, s): s governs c, c enters i, and the subject has been in i at
    every observation since such an entry. -/
def selection (i c s : String) : Formula := conj
  [ governs s c
  , entersI c i
  , .since (occ subj i) (entryOnRed i c s) ]

-- ---------------------------------------------------------------------------------------------
-- s18: pedestrians and other traffic proceeding as directed by the signal at i
-- ---------------------------------------------------------------------------------------------
def proceedingAsDirected (p i : String) : Formula := disj
  [ occ p i
  , .existsRegion (.lit "crosswalk") "w" (.and (occ p "w")
      (.existsRegion (.lit "travel_region") "ca" (.and (entranceOf "w" "ca") (entersI "ca" i))))
  , .existsRegion (.lit "travel_region") "cb" (conj
      [ occ p "cb", entersI "cb" i
      , .existsDevice (.lit "traffic_signal") "sg" (.and (governs "sg" "cb") (greenShown "sg")) ]) ]

def entitled (p i : String) : Formula := conj
  [ .not (.same (.var p) (.var subj))
  , .or (agg p aggPedestrian) (agg p aggTraffic)
  , .cmp (speedOf p) .gt pHaltSpeedTolerance
  , proceedingAsDirected p i ]

/-- s16/s17: the subject yields the right-of-way to p (the node's operationalization). -/
def yieldsTo (p : String) : Formula := .and
  (.not (conj
    [ .cmp (speedOf subj) .gt pHaltSpeedTolerance
    , .derived "prim_closest_approach_within" [.var subj, .var p] [pConflictHorizon]
    , .cmp (.quantity "prim_closest_approach_distance" [.var subj, .var p] [pConflictHorizon]) .lt
        pConflictCentreClearance ]))
  (.not (.atom "rel_contact" [.var subj, .var p] []))

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-285::traffic, ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula := .and (agg subj aggTraffic) (agg subj aggVehicle)

/-- Applicability: s1, s7, s9, s10, s11, s13, s14, s15 (with the subject spans s2, s8, s12). -/
def applicability : Formula :=
  .existsRegion (.lit "intersection") "i"
    (.existsRegion (.lit "travel_region") "c"
      (.existsDevice (.lit "traffic_signal") "s" (selection "i" "c" "s")))

/-- Obligation: s16 (obligation): but must yield; s17 (standard): the right-of-way; s18. -/
def obligation : Formula :=
  .forallRegion (.lit "intersection") "i"
    (.forallRegion (.lit "travel_region") "c"
      (.forallDevice (.lit "traffic_signal") "s"
        (.implies (selection "i" "c" "s")
          (.forallUser "p" (.implies (entitled "p" "i") (yieldsTo "p"))))))

def rule : Rule :=
  { id := "NRS_484B_307_8a_o3"
    laws := ["NRS-484B-307-8a"]
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
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_307_8a_o3
