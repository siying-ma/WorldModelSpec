/-
  NRS_484B_307_9a_o1 — NRS-484B-307-9a

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    b1 (trigger): Where the signal is a steady red with a green turn arrow:
    b2 (reference): Except as otherwise provided in paragraph (b) [NRS-484B-307-9b],
    b3 (subject): vehicular traffic
    b4 (trigger): facing the signal
    b5 (trigger): may enter the intersection
    b6 (obligation): only to make the movement indicated by the green turn arrow,
    b7 (sibling): but must yield the right-of-way
    b9 (sibling): to pedestrians lawfully within an adjacent crosswalk and to other traffic lawfully using the intersection.
    b11 (definitional): Drivers turning in the direction of the arrow are thereby advised that so long as the turn arrow is illuminated, oncoming or opposing traffic simultaneously faces a steady red signal.

  Elements (span → atoms, derived):
    b1: atoms ['dev.traffic_signal'], derived []
    b5: atoms ['rel.occupies', 'st.intersection', 'kin.speed', 'prim.region_offset_along', 'st.crosswalk', 'st.entrance_of', 'st.lane_enters', 'st.region_geometry', 'st.stop_line', 'st.travel_region'], derived ['drv.motion.entering_region', 'drv.motion.halted']
    b3: atoms ['ru.aggregate=DEF-NRS-484A-285::traffic', 'ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    b4: atoms ['dev.governs', 'st.lane_enters', 'st.travel_region', 'st.intersection', 'rel.occupies'], derived ['drv.motion.entering_region']
    b6: atoms ['kin.yaw_rate', 'rel.occupies', 'st.intersection'], derived ['drv.motion.heading_change_since_entry', 'drv.motion.leaving_region']

  Compositions (span → node, as, map):
    b2: NRS_484B_307_9b_o1 as exception map {'x': 'x'}
    b2: NRS_484B_307_9b_o2 as compliance map {'x': 'x'}
    b2: NRS_484B_307_9b_o3 as compliance map {'x': 'x'}
    b2: NRS_484B_307_9b_o4 as compliance map {'x': 'x'}

  How each span is written:
    b3: the class of x is ru_aggregate on both admitted aggregates (traffic, vehicle).
    b1/b4/b5: at the judged observation x leaves an intersection i (drv_motion_leaving_region);
      `since` reaches back to x's latest entry into i (drv_motion_entering_region), every
      observation after it up to now being no entry and either an occupation of i or the
      leaving itself. At that entry x occupies a travel region c (rel_occupies) with
      st_lane_enters(c, i), and a traffic signal s governing c or i (dev_governs) shows
      circular_red with green_arrow(left) or green_arrow(right) (dev_traffic_signal_shows).
      `c` is kept distinct from `i` (`same`): the intersection is itself a travel region, but
      never an approach carrier into itself, and Core leaves st_lane_enters unknown on a region
      that carries no lane record, so without the guard the intersection would stand as an
      undecided candidate carrier. This states no condition the record does not.
    b2: the exception is the conjunction E1 ∧ E2 ∧ E3 of the record, negated in the
      applicability: E1 `ruleApplies NRS_484B_307_9b_o1`, E3 `rule` of o2, o3, o4 (all read at
      the judged observation, map x → x), and E2 written here as a fact, read at the same entry
      through the same carrier c and signal: the place is the stop line recorded as marking c
      (st_entrance_of); where every stop line is recorded as not marking c, a crosswalk recorded
      as marking c; where neither, i itself. The act is drv_motion_halted (p.speed_resolution)
      while occupying c, st_region_geometry_distance to the place within p.stop_point_tolerance,
      prim_region_offset_along of the place from x not negative, x not occupying i (nor the
      crosswalk where it is the place). The search is a `since` from the entry: it ends at an
      approach start (x on c, off the place, the place ahead by prim_region_offset_along and
      farther than p.stop_point_tolerance) or at x's previous visit to i, read at that visit's
      leaving (drv_motion_leaving_region): no act can lie between a previous entry and its
      leaving, since the act requires x off i, so the two ends decide alike. The search
      reaching the trace start is `since`'s truncation: unknown.
    b6: at the leaving, drv_motion_heading_change_since_entry(x, i) with
      p.heading_since_step_carla_scene_graph is at least p.turn_recognition_angle where the
      signal at that entry showed green_arrow(left), at most its negation where it showed
      green_arrow(right); either complies where both were shown. The obligation repeats the
      applicability's whole selection of i (every intersection so selected: the leaving, the
      entry, the carrier and the signal); paragraph (b)'s permission is not repeated there, as
      it decides only whether the duty is engaged, and engagement gates the obligation.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_307_9a_o1

/-- The binders, as arguments (order and names are the node's). -/
def vX : Arg := .var "x"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pHeadingSinceStepCarlaSceneGraph : Term := .param "p.heading_since_step_carla_scene_graph"
def pSpeedResolution : Term := .param "p.speed_resolution"
def pStopPointTolerance : Term := .param "p.stop_point_tolerance"
def pTurnRecognitionAngle : Term := .param "p.turn_recognition_angle"

def zeroMetres : Term := .lit Q.zero .metre

/-- Quantifier variables: the intersection, the approach carrier, the signal, the marks. -/
def vI : Arg := .var "i"
def vC : Arg := .var "c"
def vS : Arg := .var "s"
def vL : Arg := .var "l"
def vW : Arg := .var "w"

/-- A conjunction of a non-empty list. -/
def conj : List Formula → Formula
  | [] => .ff
  | [φ] => φ
  | φ :: rest => .and φ (conj rest)

def mapX : List (String × String) := [("x", "x")]

/-- Class of `x`: ru.aggregate=DEF-NRS-484A-285::traffic, ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsX : Formula :=
  .and (.atom "ru_aggregate" [vX, .lit "DEF-NRS-484A-285::traffic"] [])
       (.atom "ru_aggregate" [vX, .lit "DEF-NRS-484A-320::vehicle"] [])

def occupies (r : Arg) : Formula := .atom "rel_occupies" [vX, r] []
def entering (r : Arg) : Formula := .derived "drv_motion_entering_region" [vX, r] []
def leaving (r : Arg) : Formula := .derived "drv_motion_leaving_region" [vX, r] []

/-- b4/b5: `atEntry` held at x's latest entry into `i`, x occupying `i` from then to the
    observation before now (now the leaving or a later occupation). -/
def sinceEntry (i : Arg) (atEntry : Formula) : Formula :=
  .since (.and (.not (entering i)) (.or (occupies i) (leaving i))) (.and (entering i) atEntry)

/-- b4: the approach carrier `c` x occupies, entering `i`, and `φ` of it. -/
def approach (i : Arg) (φ : Formula) : Formula :=
  .existsRegion (.lit "travel_region") "c"
    (conj [.not (.same vC i), occupies vC, .atom "st_lane_enters" [vC, i] [], φ])

def shows (ind : String) : Formula := .atom "dev_traffic_signal_shows" [vS, .lit ind] []

/-- b1/b4: a traffic signal governing the carrier or the intersection shows a steady red with
    the arrow `arrow` states. -/
def facingSignal (c i : Arg) (arrow : Formula) : Formula :=
  .existsDevice (.lit "traffic_signal") "s"
    (conj [.or (.atom "dev_governs" [vS, c] []) (.atom "dev_governs" [vS, i] []),
           shows "circular_red", arrow])

def anyArrow : Formula := .or (shows "green_arrow(left)") (shows "green_arrow(right)")

/-- b1/b4/b5: x's latest entry into `i` was made through an approach carrier under a steady red
    with the arrow `arrow` states. -/
def entryUnder (i : Arg) (arrow : Formula) : Formula :=
  sinceEntry i (approach i (facingSignal vC i arrow))

-- E2: paragraph (b)(1), the halt before the entry, searched back from the entry.

def halted : Formula := .derived "drv_motion_halted" [vX] [pSpeedResolution]
def distTo (p : Arg) : Term := .measure "st_region_geometry_distance" [vX, p]
def offsetAlong (p c : Arg) : Term := .quantity "prim_region_offset_along" [vX, p, c] []

/-- The act: halted on `c`, within the tolerance of the place `p`, not past it, off `i`. -/
def haltAt (p c i : Arg) (extra : List Formula) : Formula :=
  conj ([halted, occupies c, .cmp (distTo p) .le pStopPointTolerance,
         .cmp (offsetAlong p c) .ge zeroMetres, .not (occupies i)] ++ extra)

/-- The approach start: x on `c`, off the place, short of it and farther than the tolerance. -/
def approachStart (p c : Arg) : Formula :=
  conj [occupies c, .not (occupies p), .cmp (offsetAlong p c) .gt zeroMetres,
        .cmp (distTo p) .gt pStopPointTolerance]

/-- The search back from the entry, ended by the approach start or x's previous visit to `i`. -/
def search (p c i : Arg) (extra : List Formula) : Formula :=
  .since (.and (.not (approachStart p c)) (.not (leaving i))) (haltAt p c i extra)

def noStopLine (c : Arg) : Formula :=
  .forallRegion (.lit "stop_line") "l" (.not (.atom "st_entrance_of" [vL, c] []))
def noCrosswalk (c : Arg) : Formula :=
  .forallRegion (.lit "crosswalk") "w" (.not (.atom "st_entrance_of" [vW, c] []))

/-- E2 at the entry through `c`: the place in the record's order, and the search for the act. -/
def haltBefore (c i : Arg) : Formula :=
  .or (.existsRegion (.lit "stop_line") "l"
        (.and (.atom "st_entrance_of" [vL, c] []) (search vL c i [])))
    (.or (.and (noStopLine c)
           (.existsRegion (.lit "crosswalk") "w"
             (.and (.atom "st_entrance_of" [vW, c] []) (search vW c i [.not (occupies vW)]))))
         (conj [noStopLine c, noCrosswalk c, search i c i []]))

/-- b2: paragraph (b)'s permission, E1 ∧ E2 ∧ E3. -/
def excused (i : Arg) : Formula :=
  conj [.ruleApplies "NRS_484B_307_9b_o1" mapX,
        sinceEntry i (approach i (.and (facingSignal vC i anyArrow) (haltBefore vC i))),
        .rule "NRS_484B_307_9b_o2" mapX,
        .rule "NRS_484B_307_9b_o3" mapX,
        .rule "NRS_484B_307_9b_o4" mapX]

/-- The selection of `i`: x leaves it, having entered it last under a steady red with a green
    arrow on a signal facing its approach. -/
def selected (i : Arg) : Formula :=
  .and (leaving i) (entryUnder i anyArrow)

/-- Applicability: b1 (trigger): Where the signal is a steady red with a green turn arrow:; b4 (trigger): facing the signal; b5 (trigger): may enter the intersection -/
def applicability : Formula :=
  .existsRegion (.lit "intersection") "i" (.and (selected vI) (.not (excused vI)))

def turn : Term :=
  .quantity "drv_motion_heading_change_since_entry" [vX, vI] [pHeadingSinceStepCarlaSceneGraph]

/-- Obligation: b6 (obligation): only to make the movement indicated by the green turn arrow, -/
def obligation : Formula :=
  .forallRegion (.lit "intersection") "i"
    (.implies (selected vI)
      (.or (.and (entryUnder vI (shows "green_arrow(left)")) (.cmp turn .ge pTurnRecognitionAngle))
           (.and (entryUnder vI (shows "green_arrow(right)")) (.cmp turn .le (.neg pTurnRecognitionAngle)))))

def rule : Rule :=
  { id := "NRS_484B_307_9a_o1"
    laws := ["NRS-484B-307-9a"]
    binders :=
      [ { name := "x", cls := clsX } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations := []
    residues := ["An advisory to drivers turning with the arrow about what opposing traffic faces at the same time; it permits, requires and forbids nothing, and no rule reads it."]  -- the node's, verbatim; not yours to change
    narrowings := []  -- one { span := "<span id>", why := "<why>", kind := "reading" } per reading you chose on a carried span (kind no_atom / no_operator where the words cannot be stated), explained in the header; the record's own narrowings are not restated
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_307_9a_o1
