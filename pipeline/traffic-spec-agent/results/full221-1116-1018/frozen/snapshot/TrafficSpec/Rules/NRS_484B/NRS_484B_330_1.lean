/-
  NRS_484B_330_1 — NRS-484B-330-1

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (subject): It is unlawful for a driver of a vehicle
    s2 (obligation): to fail or refuse to comply with any signal
    s3 (condition): of an authorized flagger serving in a traffic control capacity
    s4 (condition): in a clearly marked area of highway construction or maintenance
    s5 (condition): or any other area which has been designated as a temporary traffic control zone.

  Elements (span → atoms, derived):
    s1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    s2: atoms ['dev.human_direction', 'dev.position', 'kin.position', 'kin.heading', 'kin.accel_longitudinal', 'kin.yaw_rate'], derived []
    s3: atoms ['dev.human_direction', 'dev.governs', 'rel.occupies', 'st.travel_region'], derived []
    s4: atoms ['dev.temporary_traffic_control', 'dev.governs', 'rel.occupies', 'st.travel_region', 'st.highway', 'st.on_way'], derived []
    s5: atoms ['dev.zone_sign', 'dev.governs', 'rel.occupies', 'st.travel_region'], derived []

  How each span is written.
    s1: the binder class `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`.
    s3: a travel region `r` the subject occupies (`rel_occupies`), and a `human_direction` device `f`
        governing `r` (`dev_governs`) with role `flagger`, giving an indication (its indication is one of
        the enumeration's values: stop, proceed, slow, turn(left|right|straight|u_turn)).
    s4: a `temporary_traffic_control` device governing `r`, and `r` lying on a `highway` region
        (`st_on_way r h`).
    s5: a `zone_sign` governing `r` of kind `temporary_traffic_control` whose `end` attribute is false.
        s4 and s5 are alternatives (`or`).
    s2: the obligation re-binds `r` and `f` by the whole selection above (`sel r f`), for every such
        pair, and requires the three per-indication duties of the record:
        ahead(f): (dev_position f − kin_position subject) · kin_heading subject > 0;
        passes(f): `rises (not ahead(f))` — ahead at the previous observation, not ahead here;
        stop:  not (stop here ∧ not (rises stop) ∧ passes) — `stop ∧ ¬rises stop` is stop here and at the
               previous observation;
        slow:  not (slow ∧ ahead ∧ kin_accel_longitudinal ≥ p.speed_decrease_decel_min);
        turn:  not (passes ∧ turn(dir) ∧ not turned), where turned is the heading change since the
               turn(dir) indication last rose (`Term.headingSince subject p.heading_since_step… ψ`),
               selected by `Term.cond` on the direction: left ≥ p.turn_heading_min, right (negated,
               left positive) ≥ p.turn_heading_min, u_turn |·| ≥ p.u_turn_heading_min. A turn(straight)
               or proceed indication sets no duty, as the record states.
  Choices the text did not dictate: none beyond the record's; the per-direction bounds are selected
  with `Term.cond` (one comparison), which is the same statement as three conjuncts.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_330_1

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pHeadingSinceStepCarlaSceneGraph : Term := .param "p.heading_since_step_carla_scene_graph"
def pSpeedDecreaseDecelMin : Term := .param "p.speed_decrease_decel_min"
def pTurnHeadingMin : Term := .param "p.turn_heading_min"
def pUTurnHeadingMin : Term := .param "p.u_turn_heading_min"

def zeroMetres : Term := .lit Q.zero .metre

def vR : Arg := .var "r"
def vF : Arg := .var "f"

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-320::vehicle"] []

/-- The flagger's indication is `v`. -/
def indicates (v : String) : Formula := .atom "dev_human_direction_indication" [vF, .lit v] []

/-- s3: `f` is a person directing traffic in the role of flagger, governing the region `r`, and
    giving an indication (one of the enumeration's values). -/
def flaggerServes : Formula :=
  .and (.atom "dev_governs" [vF, vR] [])
    (.and (.atom "dev_human_direction_role" [vF, .lit "flagger"] [])
      (.or (indicates "stop")
        (.or (indicates "proceed")
          (.or (indicates "slow")
            (.or (indicates "turn(left)")
              (.or (indicates "turn(right)")
                (.or (indicates "turn(straight)") (indicates "turn(u_turn)"))))))))

/-- s4: `r` is governed by a temporary traffic control device and lies on a highway. -/
def constructionArea : Formula :=
  .and (.existsDevice (.lit "temporary_traffic_control") "c" (.atom "dev_governs" [.var "c", vR] []))
    (.existsRegion (.lit "highway") "h" (.atom "st_on_way" [vR, .var "h"] []))

/-- s5: `r` is governed by a temporary traffic control zone sign that does not mark the zone's end. -/
def designatedZone : Formula :=
  .existsDevice (.lit "zone_sign") "z"
    (.and (.atom "dev_governs" [.var "z", vR] [])
      (.and (.atom "dev_zone_sign_kind" [.var "z", .lit "temporary_traffic_control"] [])
        (.not (.atom "dev_zone_sign_end" [.var "z"] []))))

/-- The whole selection of the region `r` and the flagger `f`: s3 together with s4 or s5. -/
def selection : Formula :=
  .and (.atom "rel_occupies" [vSubject, vR] [])
    (.and flaggerServes (.or constructionArea designatedZone))

/-- Applicability: s3 (condition): of an authorized flagger serving in a traffic control capacity; s4 (condition): in a clearly marked area of highway construction or maintenance; s5 (condition): or any other area which has been designated as a temporary traffic control zone. -/
def applicability : Formula :=
  .existsRegion (.lit "travel_region") "r"
    (.existsDevice (.lit "human_direction") "f" selection)

/-- The flagger lies ahead: the vector from the subject's position to the flagger's position has a
    positive component along the subject's heading. -/
def ahead : Formula :=
  .cmp
    (.add
      (.mul (.sub (.measure "dev_position" [vF, .lit "x"]) (.measure "kin_position" [vSubject, .lit "x"]))
        (.measure "kin_heading" [vSubject, .lit "x"]))
      (.mul (.sub (.measure "dev_position" [vF, .lit "y"]) (.measure "kin_position" [vSubject, .lit "y"]))
        (.measure "kin_heading" [vSubject, .lit "y"])))
    .gt zeroMetres

/-- The subject passes the flagger: ahead at the previous observation, not ahead at this one. -/
def passes : Formula := .rises (.not ahead)

/-- (stop) not passing a flagger showing stop here and at the previous observation. -/
def stopDuty : Formula :=
  .not (.and (indicates "stop") (.and (.not (.rises (indicates "stop"))) passes))

/-- (slow) not speeding up toward a flagger showing slow. -/
def slowDuty : Formula :=
  .not (.and (indicates "slow")
    (.and ahead (.cmp (.measure "kin_accel_longitudinal" [vSubject]) .ge pSpeedDecreaseDecelMin)))

/-- The heading change since the flagger's turn(dir) indication last rose. -/
def headingSinceTurn (dir : String) : Term :=
  .headingSince "subject" pHeadingSinceStepCarlaSceneGraph (indicates s!"turn({dir})")

/-- Turned toward the indicated direction: left ≥ turn minimum, right (left positive) ≥ turn minimum,
    u_turn of magnitude ≥ u-turn minimum. -/
def turnedToward : Formula :=
  .cmp
    (.cond (indicates "turn(left)") (headingSinceTurn "left")
      (.cond (indicates "turn(right)") (.neg (headingSinceTurn "right"))
        (.abs (headingSinceTurn "u_turn"))))
    .ge
    (.cond (indicates "turn(u_turn)") pUTurnHeadingMin pTurnHeadingMin)

/-- (turn) not passing a flagger showing turn(dir) without having turned toward dir. -/
def turnDuty : Formula :=
  .not (.and passes
    (.and (.or (indicates "turn(left)") (.or (indicates "turn(right)") (indicates "turn(u_turn)")))
      (.not turnedToward)))

/-- Obligation: s2 (obligation): to fail or refuse to comply with any signal -/
def obligation : Formula :=
  .forallRegion (.lit "travel_region") "r"
    (.forallDevice (.lit "human_direction") "f"
      (.implies selection (.and stopDuty (.and slowDuty turnDuty))))

def rule : Rule :=
  { id := "NRS_484B_330_1"
    laws := ["NRS-484B-330-1"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations := []
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_330_1
