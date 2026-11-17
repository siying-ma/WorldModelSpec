/-
  NRS_484B_307_4b — NRS-484B-307-4b

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (trigger): Where the signal is a green turn arrow alone:
    s2 (subject): Pedestrians
    s3 (condition): facing such a signal
    s4 (obligation): shall not enter the highway
    s5 (exception): until permitted to proceed by another device
    s6 (reference): as provided in NRS 484B.283 [NRS-484B-283-1d1, NRS-484B-283-1d2, NRS-484B-283-1d3, NRS-484B-283-1d4].

  Elements (span → atoms, derived):
    s1: atoms ['dev.traffic_signal'], derived []
    s2: atoms ['ru.aggregate=DEF-NRS-484A-165::pedestrian'], derived []
    s3: atoms ['dev.position', 'kin.heading', 'kin.position'], derived []
    s4: atoms ['rel.occupies', 'st.roadway', 'st.highway', 'st.on_way', 'st.intersection', 'st.travel_region', 'st.lane_enters', 'dev.governs'], derived []
    s5: atoms ['dev.pedestrian_signal', 'dev.governs', 'dev.position', 'kin.heading', 'kin.position', 'rel.occupies', 'st.lane', 'st.roadway', 'st.on_way'], derived []

  Compositions (span → node, as, map):
    s6: NRS_484B_283_1d1 as exception map {'subject': 'subject'}
    s6: NRS_484B_283_1d2 as exception map {'subject': 'subject'}
    s6: NRS_484B_283_1d3_o2 as exception map {'subject': 'subject'}
    s6: NRS_484B_283_1d4_o2 as exception map {'subject': 'subject'}

  How each span is written:
    s1: `greenTurnArrowAlone s` — dev_traffic_signal_shows green_arrow(left|right|u_turn), and
        not shows any other indication (circular, flashing, dark, unknown, green straight arrow,
        any yellow, red or flashing-yellow arrow). The head is bound by `existsDevice traffic_signal`.
    s2: ru_aggregate(subject, DEF-NRS-484A-165::pedestrian).
    s3: `facing s` over dev_position, kin_position, kin_heading with p.ped_traffic_signal_facing_*.
    s4: x an intersection the head governs, or that a travel region it governs enters
        (st_lane_enters); w a highway with st_on_way(x, w); "had overlapped no roadway on w at the
        previous observation" is written with `rises` (rises ψ ∨ (¬ψ ∧ ¬rises ¬ψ)), the language
        having no previous-observation operator; the obligation repeats the whole selection and
        requires, for every roadway r on w, ¬rel_occupies(subject, r) or the s5 permission.
    s5: `permitted r w` — some pedestrian head showing walk, or dont_walk_flashing with countdown,
        faced (p.ped_signal_facing_*), governing r or a lane on w the subject overlaps.
    s6: four `.not (.ruleApplies …)` exceptions in the applicability.
  No choice beyond the record's own reading was made; no narrowing is declared.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_307_4b

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pPedSignalFacingCos : Term := .param "p.ped_signal_facing_cos"
def pPedSignalFacingReach : Term := .param "p.ped_signal_facing_reach"
def pPedTrafficSignalFacingCos : Term := .param "p.ped_traffic_signal_facing_cos"
def pPedTrafficSignalFacingReach : Term := .param "p.ped_traffic_signal_facing_reach"

def zeroMetres : Term := .lit Q.zero .metre

/-- s2: the admitted aggregate, never the class atom. -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-165::pedestrian"] []

/-- s3 / s5 "facing": with Δ the vector from the subject's kin.position to the device's
    dev.position and h its kin.heading: h·Δ > 0, (h·Δ)² ≥ cos²·|Δ|², |Δ|² ≤ reach². -/
def facing (dev : String) (cos reach : Term) : Formula :=
  let dx : Term := .sub (.measure "dev_position" [.var dev, .lit "x"]) (.measure "kin_position" [vSubject, .lit "x"])
  let dy : Term := .sub (.measure "dev_position" [.var dev, .lit "y"]) (.measure "kin_position" [vSubject, .lit "y"])
  let hx : Term := .measure "kin_heading" [vSubject, .lit "x"]
  let hy : Term := .measure "kin_heading" [vSubject, .lit "y"]
  let dot : Term := .add (.mul hx dx) (.mul hy dy)
  let dist2 : Term := .add (.mul dx dx) (.mul dy dy)
  .and (.cmp dot .gt zeroMetres)
    (.and (.cmp (.mul dot dot) .ge (.mul (.mul cos cos) dist2))
      (.cmp dist2 .le (.mul reach reach)))

def shows (dev : String) (ind : String) : Formula := .atom "dev_traffic_signal_shows" [.var dev, .lit ind] []

/-- Every indication other than a green turn arrow. -/
def otherIndications : List String :=
  [ "circular_green", "circular_yellow", "circular_red", "flashing_red", "flashing_yellow", "dark", "unknown",
    "green_arrow(straight)" ] ++
  (["yellow_arrow", "red_arrow", "flashing_yellow_arrow"].flatMap fun k =>
    ["left", "right", "straight", "u_turn"].map fun dir => s!"{k}({dir})")

/-- s1: a green turn arrow (left, right or u_turn) and no indication other than green turn arrows. -/
def greenTurnArrowAlone (dev : String) : Formula :=
  .and (.or (shows dev "green_arrow(left)") (.or (shows dev "green_arrow(right)") (shows dev "green_arrow(u_turn)")))
    (otherIndications.foldr (fun i acc => .and (.not (shows dev i)) acc) .tt)

/-- s4: the head controls junction x: it governs x itself, or a travel region that enters x. -/
def controls (dev x : String) : Formula :=
  .or (.atom "dev_governs" [.var dev, .var x] [])
    (.existsRegion (.lit "travel_region") "l"
      (.and (.atom "dev_governs" [.var dev, .var "l"] []) (.atom "st_lane_enters" [.var "l", .var x] [])))

/-- The subject's footprint overlaps some roadway lying on way w. -/
def onRoadwayOf (w : String) : Formula :=
  .existsRegion (.lit "roadway") "r0"
    (.and (.atom "st_on_way" [.var "r0", .var w] []) (.atom "rel_occupies" [vSubject, .var "r0"] []))

/-- ¬ψ at the previous observation, written from `rises`: ψ rose here, or ψ is false here and
    did not just become false (rises ψ ∨ (¬ψ ∧ ¬rises ¬ψ)). -/
def prevNot (ψ : Formula) : Formula :=
  .or (.rises ψ) (.and (.not ψ) (.not (.rises (.not ψ))))

/-- The whole selection of head s, junction x and highway w (s1, s3, s4). -/
def selection (s x w : String) : Formula :=
  .and (facing s pPedTrafficSignalFacingCos pPedTrafficSignalFacingReach)
    (.and (greenTurnArrowAlone s)
      (.and (controls s x)
        (.and (.atom "st_on_way" [.var x, .var w] [])
          (prevNot (onRoadwayOf w)))))

/-- s5: a pedestrian head showing walk, or dont_walk_flashing with its countdown, that the subject
    faces and that governs roadway r itself or a lane of highway w the subject overlaps. -/
def permitted (r w : String) : Formula :=
  .existsDevice (.lit "pedestrian_signal") "d"
    (.and (.or (.atom "dev_pedestrian_signal_state" [.var "d", .lit "walk"] [])
               (.and (.atom "dev_pedestrian_signal_state" [.var "d", .lit "dont_walk_flashing"] [])
                     (.atom "dev_pedestrian_signal_countdown" [.var "d"] [])))
      (.and (facing "d" pPedSignalFacingCos pPedSignalFacingReach)
        (.or (.atom "dev_governs" [.var "d", .var r] [])
          (.existsRegion (.lit "lane") "ln"
            (.and (.atom "st_on_way" [.var "ln", .var w] [])
              (.and (.atom "rel_occupies" [vSubject, .var "ln"] [])
                (.atom "dev_governs" [.var "d", .var "ln"] [])))))))

def compMap : List (String × String) := [("subject", "subject")]

/-- Applicability: s1, s3, s4's selection; s6 compositions as exceptions. -/
def applicability : Formula :=
  .and
    (.existsDevice (.lit "traffic_signal") "s"
      (.existsRegion (.lit "intersection") "x"
        (.existsRegion (.lit "highway") "w" (selection "s" "x" "w"))))
    (.and (.not (.ruleApplies "NRS_484B_283_1d1" compMap))
      (.and (.not (.ruleApplies "NRS_484B_283_1d2" compMap))
        (.and (.not (.ruleApplies "NRS_484B_283_1d3_o2" compMap))
          (.not (.ruleApplies "NRS_484B_283_1d4_o2" compMap)))))

/-- Obligation: s4 with s5 — for every selected s, x, w and every roadway r on w: the subject does
    not overlap r, or a pedestrian signal permits it to proceed. -/
def obligation : Formula :=
  .forallDevice (.lit "traffic_signal") "s"
    (.forallRegion (.lit "intersection") "x"
      (.forallRegion (.lit "highway") "w"
        (.implies (selection "s" "x" "w")
          (.forallRegion (.lit "roadway") "r"
            (.implies (.atom "st_on_way" [.var "r", .var "w"] [])
              (.or (.not (.atom "rel_occupies" [vSubject, .var "r"] []))
                   (permitted "r" "w")))))))

def rule : Rule :=
  { id := "NRS_484B_307_4b"
    laws := ["NRS-484B-307-4b"]
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

end TrafficSpec.Rules.NRS_484B_307_4b
