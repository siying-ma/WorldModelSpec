/-
  NRS_484B_307_5a_o1 — NRS-484B-307-5a

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (trigger): Where the signal is a green straight-through arrow alone:
    s2 (subject): Vehicular traffic facing the signal
    s3 (obligation): may proceed straight through, but must not turn right or left.
    s4 (sibling): Such vehicular traffic
    s5 (sibling): must yield
    s6 (sibling): the right-of-way
    s7 (sibling): to other vehicles
    s8 (sibling): and to pedestrians
    s9 (sibling): lawfully within the intersection or an adjacent crosswalk at the time the signal is exhibited.

  Elements (span → atoms, derived):
    s1: atoms ['dev.traffic_signal'], derived []
    s2: atoms ['dev.governs', 'rel.occupies', 'ru.aggregate=DEF-NRS-484A-285::traffic', 'ru.aggregate=DEF-NRS-484A-320::vehicle', 'st.intersection', 'st.lane_enters', 'st.travel_region'], derived []
    s3: atoms ['rel.occupies', 'st.intersection'], derived ['drv.motion.left_turn_through_region', 'drv.motion.right_turn_through_region', 'drv.motion.u_turn_through_region']

  How each span is written.
    s2: the subject is of both admitted aggregates (`ru_aggregate`, traffic and vehicle: vehicular
        traffic). "Facing the signal": a travel region c (quantifier over `travel_region`) whose
        entrance end is intersection i (`st_lane_enters c i`, i quantified over `intersection`) and
        which head s (quantifier over `traffic_signal`) governs (`dev_governs s c`); the subject
        came from c into i: the entry observation is `rises (rel_occupies subject i)` with
        `rel_occupies subject c` at the observation before (written `prev`, below, from `rises`).
    s1: "a green straight-through arrow alone": `dev_traffic_signal_shows s green_arrow(straight)`
        and no other indication of the enumeration shown by s. Read `some_moment` over the act
        stretch, from the entry to the recognition: `since inPassage (arrowAlone ∧ since inPassage
        entry)`, where `inPassage` holds at an observation inside i that is no new entry, and at the
        exit observation itself; so the arrow is found at some observation of this passage, the
        entry and the exit included, and an earlier passage is never reached.
    occasion: judged at the recognition, the exit `rises (¬ rel_occupies subject i)`.
    s3: at that recognition none of drv.motion.left_turn_through_region,
        drv.motion.right_turn_through_region, drv.motion.u_turn_through_region holds for the
        subject and i (step = p.heading_since_step_carla_scene_graph, turn_min = p.turn_heading_min,
        u_turn_min = p.u_turn_heading_min). The obligation re-selects i with the applicability's
        whole selection (c, s, the entry, the arrow, the exit), for every intersection so selected.
  Choices the text left open: none beyond the record's own readings; no narrowing is declared.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_307_5a_o1

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pHeadingSinceStepCarlaSceneGraph : Term := .param "p.heading_since_step_carla_scene_graph"
def pTurnHeadingMin : Term := .param "p.turn_heading_min"
def pUTurnHeadingMin : Term := .param "p.u_turn_heading_min"

def zeroMetres : Term := .lit Q.zero .metre

def vI : Arg := .var "i"
def vC : Arg := .var "c"
def vS : Arg := .var "s"

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-285::traffic, ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula :=
  .and (.atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-285::traffic"] [])
       (.atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-320::vehicle"] [])

/-- φ at the previous observation, from `rises` alone: φ here and not risen here, or ¬φ risen here. -/
def prev (φ : Formula) : Formula :=
  .or (.and φ (.not (.rises φ))) (.rises (.not φ))

/-- rel.occupies: the subject's footprint overlaps region `r`. -/
def occ (r : Arg) : Formula := .atom "rel_occupies" [vSubject, r] []

/-- The entry into i from c (occasion onset): the footprint came to overlap i, having occupied c
    (and not i) at the observation before. -/
def entry : Formula := .and (.rises (occ vI)) (prev (occ vC))

/-- The exit from i (occasion recognition): no overlap with i, having overlapped it before. -/
def exitI : Formula := .rises (.not (occ vI))

/-- An observation of the passage after its entry: inside i with no new entry, or the exit. -/
def inPassage : Formula := .or (.and (occ vI) (.not (.rises (occ vI)))) exitI

/-- s1: head s displays green_arrow(straight) and no other state. -/
def others : List String :=
  [ "circular_green", "circular_yellow", "circular_red", "flashing_red", "flashing_yellow", "dark",
    "unknown", "green_arrow(left)", "green_arrow(right)", "green_arrow(u_turn)",
    "yellow_arrow(left)", "yellow_arrow(right)", "yellow_arrow(straight)", "yellow_arrow(u_turn)",
    "red_arrow(left)", "red_arrow(right)", "red_arrow(straight)", "red_arrow(u_turn)",
    "flashing_yellow_arrow(left)", "flashing_yellow_arrow(right)",
    "flashing_yellow_arrow(straight)", "flashing_yellow_arrow(u_turn)" ]

def arrowAlone : Formula :=
  others.foldl (fun acc k => .and acc (.not (.atom "dev_traffic_signal_shows" [vS, .lit k] [])))
    (.atom "dev_traffic_signal_shows" [vS, .lit "green_arrow(straight)"] [])

/-- s1 read `some_moment` over the act stretch, from the entry to the judged exit. -/
def arrowDuringPassage : Formula :=
  .since inPassage (.and arrowAlone (.since inPassage entry))

/-- The whole selection of i, c and s at the judged observation (s2, s1, the recognition). -/
def selection : Formula :=
  .and (.atom "st_lane_enters" [vC, vI] [])
    (.and (.atom "dev_governs" [vS, vC] [])
      (.and exitI arrowDuringPassage))

def selected (body : Formula) : Formula :=
  .existsRegion (.lit "travel_region") "c"
    (.existsDevice (.lit "traffic_signal") "s" body)

/-- Applicability: s1 (trigger): Where the signal is a green straight-through arrow alone: -/
def applicability : Formula :=
  .existsRegion (.lit "intersection") "i" (selected selection)

/-- s3: a turn to the left, a turn to the right or a reversal through i. -/
def turned : Formula :=
  .or (.derived "drv_motion_left_turn_through_region" [vSubject, vI]
        [pHeadingSinceStepCarlaSceneGraph, pTurnHeadingMin, pUTurnHeadingMin])
    (.or (.derived "drv_motion_right_turn_through_region" [vSubject, vI]
          [pHeadingSinceStepCarlaSceneGraph, pTurnHeadingMin, pUTurnHeadingMin])
      (.derived "drv_motion_u_turn_through_region" [vSubject, vI]
          [pHeadingSinceStepCarlaSceneGraph, pUTurnHeadingMin]))

/-- Obligation: s3 (obligation): may proceed straight through, but must not turn right or left. -/
def obligation : Formula :=
  .forallRegion (.lit "intersection") "i" (.implies (selected selection) (.not turned))

def rule : Rule :=
  { id := "NRS_484B_307_5a_o1"
    laws := ["NRS-484B-307-5a"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations := []
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []  -- one { span := "<span id>", why := "<why>", kind := "reading" } per reading you chose on a carried span (kind no_atom / no_operator where the words cannot be stated), explained in the header; the record's own narrowings are not restated
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_307_5a_o1
