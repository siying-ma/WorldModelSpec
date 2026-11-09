/-
  NRS_484B_223_1b — NRS-484B-223-1b

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (trigger): If a highway has two or more clearly marked lanes for traffic traveling in one direction,
    s2 (subject): vehicles must:
    s3 (obligation): Not be moved from that lane
    s4 (condition): until the driver has given the appropriate turn signal
    s5 (standard): and ascertained that such movement can be made with safety.

  Elements (span → atoms, derived):
    s1: atoms ['st.highway', 'st.lane', 'st.lane_adjacency', 'st.lane_direction', 'st.lane_marking', 'st.on_way', 'rel.occupies', 'ru.aggregate=DEF-NRS-484A-285::traffic'], derived []
    s2: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    s3: atoms ['st.lane', 'rel.occupies'], derived ['drv.lane.lane_change']
    s4: atoms ['sig.turn_indicator', 'sig.hand_signal', 'st.lane_adjacency', 'st.lane'], derived []

  Literals the text states (each written through its Units constructor):
    s1: 2 count — two  (`twoLanes`, `Units.ratio 2 1` tagged `.count`)

  No magnitude below is this file's own: parameters name the reading, literals are the text's.

  HOW EACH SPAN IS WRITTEN

  s2 (subject) — `clsV`: the binder's class is the admitted aggregate, `ru_aggregate` with the id
  `DEF-NRS-484A-320::vehicle` and never a class the definition covers.

  s1 (trigger) — `laneSelection` and `applicability`: a lane `L` (`st_lane`, and the kind of the
  region quantifier) that lies on a highway (`st_highway` with `st_on_way`, the way bound by its
  own quantifier `W`), whose count of lanes in its direction of travel is at least the law's own
  two (`st_lane_adjacency` read in its `count` field, compared with `twoLanes`), and which carries
  a marking of a type other than none (`st_lane_marking`); the subject is traffic
  (`ru_aggregate` with `DEF-NRS-484A-285::traffic`), which is whose travel the lanes are for; and
  the subject's footprint overlaps `L` (`rel_occupies`). The direction the count is read in is the
  lane's own designated direction of travel, and `st_lane_direction` is read where the reading of
  "one direction" does work on the regions the duty compares: the lane the subject has moved into
  must be designated for travel in `L`'s direction (`sameDirectionAs`), so a lane of another
  direction is no neighbour of `L` for this rule.

  The record's selection of `L` also requires the marking to be on "the side the movement
  crosses". Which side that is is not a fact of an observation on its own: it follows from the
  regions the subject has moved between, which only the obligation (where the movement is read)
  can name. The applicability therefore carries the marking as the lane's own marking — a lane
  marked on a side — and the obligation's antecedent carries the record's whole qualified fact,
  `crossedSideMarked`: the marking of the side the movement crosses, left where the lane entered
  is `L`'s left neighbour, right where it is its right neighbour, and either where the lane
  entered is no neighbour of `L`. No observation is read more weakly than the record states it:
  the duty binds exactly the crossings of a side the map marks.

  s3 (obligation) + s4 (condition) — `obligation`: at every lane `L` the record's selection
  singles out, where the subject moves out of `L` (`drv.lane.lane_change` for the subject and
  `L`), the appropriate turn signal must have been given for the movement and the movement must be
  one that can be made with safety on the bound of s5. The selection of `L` is written again in
  the obligation in full (`laneSelection`, with `crossedSideMarked`); the one part of it the record
  states of the observation before the movement — that the subject occupied `L` then — is carried
  by `drv.lane.lane_change` itself, whose contract is that the footprint "overlapped the region at
  the observation before", so the region the obligation binds is the region the applicability
  selected and no other. The duty is written for every such lane, as the record requires it of
  each (`forallRegion`).

  s4 — `signalGiven`: the indication is the one the vehicle shows, `sig_turn_indicator` in the
  state for the side or `sig_hand_signal` with that meaning. Which indication is appropriate is
  `st_lane_adjacency` (`enteredNeighbour`): left where the lane the subject has moved into is
  `L`'s left neighbour of the same direction, right where it is its right neighbour. It has been
  given where the indication holds at the observation of the movement or at some observation in
  the window of `p.turn_signal_advance_window` behind it (`givenForTheMovement`); a window that
  reaches past the start of the recording leaves the duty unknown, never violated.

  s5 (standard) — `madeWithSafety`, the node's one operationalization: every road user other than
  the subject that occupies a lane the subject has moved into (`rel_occupies` with `st_lane`, the
  lane entered being a lane of `L`'s direction other than `L` itself) or lies alongside the
  subject (the longitudinal component of `rel_surface_gap` is zero, the only reading of
  "alongside" the standard's own atoms carry: the component is never negative, so zero is exactly
  the case of two bodies abreast) must stand off by the entry clearance —
  `p.lane_change_min_clearance` plus `p.lane_change_entry_headway_time` times the greater of the
  two `kin_speed` readings — and the two must not close to less than
  `p.lane_change_min_clearance` within `p.lane_change_conflict_horizon`
  (`prim_closest_approach_within` with `prim_closest_approach_distance`, the distance read only
  where the approach happens, so a pair that does not approach is no conflict).

  THE READING THIS SESSION CHOSE (declared in `narrowings`)

  s3/s4: where the lane the subject has moved into is no neighbour of `L` in `L`'s direction, the
  record admits "either indication given for the side the body moves towards". Which side the body
  moves towards is read by no atom this node claims, so the third limb of `signalGiven` accepts
  either indication for such a movement: the duty still requires an indication within the window,
  and only the side it names is left open. Declared as a narrowing on s3.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_223_1b

/-- The binders, as arguments (order and names are the node's). -/
def vV : Arg := .var "v"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pLaneChangeConflictHorizon : Term := .param "p.lane_change_conflict_horizon"
def pLaneChangeEntryHeadwayTime : Term := .param "p.lane_change_entry_headway_time"
def pLaneChangeMinClearance : Term := .param "p.lane_change_min_clearance"
def pTurnSignalAdvanceWindow : Term := .param "p.turn_signal_advance_window"

def zeroMetres : Term := .lit Q.zero .metre

/-- s1's literal: the law's own figure, two lanes. -/
def twoLanes : Term := .lit (Units.ratio 2 1) .count

/-- Class of `v`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsV : Formula := .atom "ru_aggregate" [vV, .lit "DEF-NRS-484A-320::vehicle"] []

/-- s1: whose travel the lanes are for — the subject is a member of the admitted aggregate
    `DEF-NRS-484A-285::traffic`, travelling in the lanes the trigger counts. -/
def subjectIsTraffic : Formula := .atom "ru_aggregate" [vV, .lit "DEF-NRS-484A-285::traffic"] []

/-- s1: the region `l` lies on a highway. -/
def onAHighway (l : String) : Formula :=
  .existsRegion (.lit "highway") "W"
    (.and (.atom "st_highway" [.var "W"] [])
          (.atom "st_on_way" [.var l, .var "W"] []))

/-- s1: lane `l` carries a marking of a type other than none on `side`. -/
def markedOn (l side : String) : Formula :=
  .not (.atom "st_lane_marking" [.var l, .lit side, .lit "none"] [])

/-- s1: a component of the direction of travel designated for lane `l`. -/
def laneDirection (l comp : String) : Term := .measure "st_lane_direction" [.var l, .lit comp]

/-- s1: lanes `a` and `b` are designated for travel in one direction. -/
def sameDirectionAs (a b : String) : Formula :=
  .and (.cmp (laneDirection a "x") .eq (laneDirection b "x"))
       (.cmp (laneDirection a "y") .eq (laneDirection b "y"))

/-- s1: the lane the words single out, apart from the subject's occupancy of it: a marked lane of
    a highway whose direction of travel carries two or more lanes, the lanes being lanes for
    traffic. -/
def laneSelection (l : String) : Formula :=
  .and (.atom "st_lane" [.var l] [])
    (.and (onAHighway l)
      (.and (.cmp (.measure "st_lane_adjacency" [.var l, .lit "count"]) .ge twoLanes)
        (.and (.or (markedOn l "left") (markedOn l "right"))
              subjectIsTraffic)))

/-- Applicability: s1 (trigger): If a highway has two or more clearly marked lanes for traffic traveling in one direction, -/
def applicability : Formula :=
  .existsRegion (.lit "lane") "L"
    (.and (laneSelection "L")
          (.atom "rel_occupies" [vV, .var "L"] []))

/-- s4: the lane the subject has moved into is `l`'s neighbour on `side`, of `l`'s direction. -/
def enteredNeighbour (l side : String) : Formula :=
  .existsRegion (.lit "lane") "M"
    (.and (.atom "st_lane" [.var "M"] [])
      (.and (.atom "rel_occupies" [vV, .var "M"] [])
        (.and (.atom "st_lane_adjacency" [.var l, .lit side, .var "M"] [])
              (sameDirectionAs l "M"))))

/-- s4: the indication for `side`, as the indicator shows it or the arm gives it. -/
def indicates (side : String) : Formula :=
  .or (.atom "sig_turn_indicator" [vV, .lit side] [])
      (.atom "sig_hand_signal" [vV, .lit side] [])

/-- s3/s4: the indication holds at the observation judged or at some observation in the window of
    `p.turn_signal_advance_window` behind it. -/
def givenForTheMovement (φ : Formula) : Formula :=
  .not (.holdsFor .time pTurnSignalAdvanceWindow "v" (.not φ))

/-- s4: the appropriate turn signal has been given for the movement out of `l`. -/
def signalGiven (l : String) : Formula :=
  .or (.and (enteredNeighbour l "left") (givenForTheMovement (indicates "left")))
    (.or (.and (enteredNeighbour l "right") (givenForTheMovement (indicates "right")))
         (.and (.not (.or (enteredNeighbour l "left") (enteredNeighbour l "right")))
               (givenForTheMovement (.or (indicates "left") (indicates "right")))))

/-- s1: `l` carries a marking on the side the movement crosses. -/
def crossedSideMarked (l : String) : Formula :=
  .or (.and (enteredNeighbour l "left") (markedOn l "left"))
    (.or (.and (enteredNeighbour l "right") (markedOn l "right"))
         (.and (.not (.or (enteredNeighbour l "left") (enteredNeighbour l "right")))
               (.or (markedOn l "left") (markedOn l "right"))))

/-- s5: road user `u` occupies a lane the subject has moved into — a lane of `l`'s direction that
    the subject occupies and that is not `l` itself. -/
def inLaneEntered (l u : String) : Formula :=
  .existsRegion (.lit "lane") "M"
    (.and (.atom "st_lane" [.var "M"] [])
      (.and (.atom "rel_occupies" [vV, .var "M"] [])
        (.and (.not (.same (.var "M") (.var l)))
          (.and (sameDirectionAs l "M")
                (.atom "rel_occupies" [.var u, .var "M"] [])))))

/-- s5: the longitudinal component of the gap between the subject's body and `u`'s. -/
def gapLongitudinal (u : String) : Term := .measure "rel_surface_gap" [vV, .var u, .lit "longitudinal"]

def speedOf (x : Arg) : Term := .measure "kin_speed" [x]

/-- s5: the greater of the two speed readings. -/
def fasterOfTheTwo (u : String) : Term :=
  .cond (.cmp (speedOf vV) .ge (speedOf (.var u))) (speedOf vV) (speedOf (.var u))

/-- s5: the clearance the entry must cover, at the speed of the faster of the two. -/
def entryClearance (u : String) : Term :=
  .add pLaneChangeMinClearance (.mul pLaneChangeEntryHeadwayTime (fasterOfTheTwo u))

/-- s5: the two do not close to less than the minimum clearance within the conflict horizon. -/
def noConflictWithin (u : String) : Formula :=
  .not (.and (.derived "prim_closest_approach_within" [vV, .var u] [pLaneChangeConflictHorizon])
             (.cmp (.quantity "prim_closest_approach_distance" [vV, .var u] [pLaneChangeConflictHorizon])
                   .lt pLaneChangeMinClearance))

/-- s5: the movement out of `l` can be made with safety. -/
def madeWithSafety (l : String) : Formula :=
  .forallUser "y"
    (.implies
      (.and (.not (.same (.var "y") vV))
            (.or (inLaneEntered l "y") (.cmp (gapLongitudinal "y") .le zeroMetres)))
      (.and (.cmp (gapLongitudinal "y") .ge (entryClearance "y"))
            (noConflictWithin "y")))

/-- Obligation: s3 (obligation): Not be moved from that lane; s5 (standard): and ascertained that such movement can be made with safety. -/
def obligation : Formula :=
  .forallRegion (.lit "lane") "L"
    (.implies
      (.and (laneSelection "L")
        (.and (crossedSideMarked "L")
              (.derived "drv_lane_lane_change" [vV, .var "L"] [])))
      (.and (signalGiven "L") (madeWithSafety "L")))

def rule : Rule :=
  { id := "NRS_484B_223_1b"
    laws := ["NRS-484B-223-1b"]
    binders :=
      [ { name := "v", cls := clsV } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations :=
      [ { standard := "ascertained that such movement can be made with safety"
          concepts := ["drv.lane.lane_change", "kin.speed", "prim.closest_approach_distance", "prim.closest_approach_within", "rel.occupies", "rel.surface_gap", "st.lane"]
          params := ["p.lane_change_entry_headway_time", "p.lane_change_min_clearance", "p.lane_change_conflict_horizon"]
          convention := "Gap-acceptance and conflict-avoidance convention (critical lane-change gap, with a closest-approach test over a conflict horizon). The movement can be made with safety at the observation of the change where, for every road user other than the subject that occupies the lane the subject moves into (rel.occupies with st.lane) or lies alongside the subject: the longitudinal component of rel.surface_gap, “distance between the nearest points of two bodies … its longitudinal and lateral components”, is at least p.lane_change_min_clearance + p.lane_change_entry_headway_time × the greater of the two kin.speed readings, so the required clearance grows with the speed of the faster of the pair; and the two do not close to less than p.lane_change_min_clearance within the horizon, which prim.closest_approach_within, “under constant velocities, the centres of two road users approach each other at some time between the observation and the horizon”, and prim.closest_approach_distance, “the centre distance at that closest approach”, decide over p.lane_change_conflict_horizon. drv.lane.lane_change fixes the observation and the lane the test is made for. The clearance and the horizon are parameters of the reading; the words state no figure."
          surrogate := false } ]
    residues := []  -- the node's, verbatim; not yours to change
    narrowings :=
      [ { span := "s3"
          why := "Where the lane the subject has moved into is no neighbour of the lane left in that lane's direction, the record admits “either indication given for the side the body moves towards”. The side the body moves towards is read by no atom this node claims, so the third limb of the signal requirement accepts either indication — the turn indicator showing left or right, or an arm signal meaning left or right — within the window behind the movement. The duty still requires an indication for such a movement; only which side it names is left open."
          kind := "reading" } ]
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_223_1b
