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
    b3: atoms ['ru.aggregate=DEF-NRS-484A-285::traffic', 'ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    b4: atoms ['dev.governs', 'st.lane_enters', 'st.travel_region', 'st.intersection', 'rel.occupies'], derived ['drv.motion.entering_region']
    b5: atoms ['rel.occupies', 'st.intersection'], derived ['drv.motion.entering_region']
    b6: atoms ['kin.yaw_rate', 'rel.occupies', 'st.intersection'], derived ['drv.motion.heading_change_since_entry', 'drv.motion.leaving_region']

  Compositions (span → node, as, map):
    b2: NRS_484B_307_9b_o1 as exception map {'x': 'x'}

  How each is written:
    b3: the binder class is the conjunction of the two admitted aggregates, `ru_aggregate x
        "DEF-NRS-484A-285::traffic"` and `ru_aggregate x "DEF-NRS-484A-320::vehicle"`.
    b5: the intersection i (`existsRegion "intersection"`) is selected at the observation x leaves
        it (`drv_motion_leaving_region x i`); its latest entry is reached through `since`: at every
        observation after the entry up to the leaving x does not enter i again and either occupies
        i or leaves it (`rel_occupies x i ∨ drv_motion_leaving_region x i`), and the entry is the
        observation at which `drv_motion_entering_region x i` holds.
    b4, b1: at that entry observation x occupies a carrier c (`existsRegion "travel_region"`,
        `rel_occupies x c`) with `st_lane_enters c i`, and some traffic signal s
        (`existsDevice "traffic_signal"`) governing c or i (`dev_governs`) shows circular_red
        together with green_arrow(left) or green_arrow(right) (`dev_traffic_signal_shows`).
    b6: the obligation re-states the whole selection of i for every intersection i and requires,
        at the leaving observation, `drv_motion_heading_change_since_entry x i` with step
        p.heading_since_step_carla_scene_graph to be at least p.turn_recognition_angle where the
        same entry was made under a green left arrow, or at most minus it where under a green right
        arrow; either suffices where both were shown.
    b2: `.not (.ruleApplies "NRS_484B_307_9b_o1" [("x", "x")])` in the applicability.
  No choice beyond the record was needed; the rule declares no narrowing of its own.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_307_9a_o1

/-- The binders, as arguments (order and names are the node's). -/
def vX : Arg := .var "x"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pHeadingSinceStepCarlaSceneGraph : Term := .param "p.heading_since_step_carla_scene_graph"
def pTurnRecognitionAngle : Term := .param "p.turn_recognition_angle"

def zeroMetres : Term := .lit Q.zero .metre

/-- Class of `x`: ru.aggregate=DEF-NRS-484A-285::traffic, ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsX : Formula :=
  .and (.atom "ru_aggregate" [vX, .lit "DEF-NRS-484A-285::traffic"] [])
       (.atom "ru_aggregate" [vX, .lit "DEF-NRS-484A-320::vehicle"] [])

/-- x's footprint overlaps region `r`. -/
def occupies (r : String) : Formula := .atom "rel_occupies" [vX, .var r] []

/-- b5: x enters intersection `i` at the observation. -/
def entering (i : String) : Formula := .derived "drv_motion_entering_region" [vX, .var i] []

/-- x leaves intersection `i` at the observation. -/
def leaving (i : String) : Formula := .derived "drv_motion_leaving_region" [vX, .var i] []

/-- Signal `s` displays the indication spelled `k`. -/
def shows (k : String) : Formula := .atom "dev_traffic_signal_shows" [.var "s", .lit k] []

/-- b1: a steady red together with a green arrow to the left or to the right. -/
def redWithAnyArrow : Formula :=
  .and (shows "circular_red") (.or (shows "green_arrow(left)") (shows "green_arrow(right)"))

/-- b1: a steady red together with a green arrow in direction `d`. -/
def redWithArrow (d : String) : Formula :=
  .and (shows "circular_red") (shows s!"green_arrow({d})")

/-- b4: x occupies a carrier c entering `i`, and a traffic signal governing c or `i` displays
    `display`. -/
def facing (display : Formula) : Formula :=
  .existsRegion (.lit "travel_region") "c"
    (.and (occupies "c")
      (.and (.atom "st_lane_enters" [.var "c", .var "i"] [])
        (.existsDevice (.lit "traffic_signal") "s"
          (.and (.or (.atom "dev_governs" [.var "s", .var "c"] [])
                     (.atom "dev_governs" [.var "s", .var "i"] []))
                display))))

/-- From the latest entry into `i` up to now, x has not entered `i` again and has occupied it, or
    leaves it now. -/
def stayed : Formula :=
  .and (.not (entering "i")) (.or (occupies "i") (leaving "i"))

/-- b4, b5: the latest entry into `i` was made facing a signal displaying `display`. -/
def lastEntryUnder (display : Formula) : Formula :=
  .since stayed (.and (entering "i") (facing display))

/-- The selection of intersection `i`: x leaves it, having entered it last under a steady red with
    a green arrow on a signal governing its approach carrier or `i`. -/
def selected : Formula :=
  .and (leaving "i") (lastEntryUnder redWithAnyArrow)

/-- b6: x's heading change since its entry into `i`. -/
def headingChange : Term :=
  .quantity "drv_motion_heading_change_since_entry" [vX, .var "i"] [pHeadingSinceStepCarlaSceneGraph]

/-- Applicability: b1 (trigger): Where the signal is a steady red with a green turn arrow:; b4 (trigger): facing the signal; b5 (trigger): may enter the intersection -/
def applicability : Formula :=
  .and (.existsRegion (.lit "intersection") "i" selected)
       (.not (.ruleApplies "NRS_484B_307_9b_o1" [("x", "x")]))

/-- Obligation: b6 (obligation): only to make the movement indicated by the green turn arrow, -/
def obligation : Formula :=
  .forallRegion (.lit "intersection") "i"
    (.implies selected
      (.or (.and (lastEntryUnder (redWithArrow "left")) (.cmp headingChange .ge pTurnRecognitionAngle))
           (.and (lastEntryUnder (redWithArrow "right")) (.cmp headingChange .le (.neg pTurnRecognitionAngle)))))

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
