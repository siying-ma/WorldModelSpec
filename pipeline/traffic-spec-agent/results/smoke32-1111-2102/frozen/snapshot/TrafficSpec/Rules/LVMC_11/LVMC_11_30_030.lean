/-
  LVMC_11_30_030 — LVMC-11-30-030

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (trigger): Whenever any vehicle is stopped
    s2 (condition): at a marked crosswalk or at any unmarked crosswalk at an intersection
    s3 (condition): to permit a pedestrian to cross the roadway
    s4 (subject): the driver of any other vehicle approaching from the rear
    s5 (obligation): shall not overtake and pass such stopped vehicle.

  Elements (span → atoms, derived):
    s1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived ['drv.motion.at_rest']
    s2: atoms ['st.crosswalk', 'st.region_geometry'], derived ['drv.position.near_region']
    s3: atoms ['ru.aggregate=DEF-NRS-484A-165::pedestrian'], derived ['drv.position.near_region']
    s4: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived ['drv.position.behind']
    s5: atoms [], derived ['drv.interaction.overtakes']

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.LVMC_11_30_030

/-- The binders, as arguments (order and names are the node's). -/
def vEgo : Arg := .var "ego"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pCrosswalkReach : Term := .param "p.crosswalk_reach"
def pRestSpeedTolerance : Term := .param "p.rest_speed_tolerance"
def pSameDirectionTolerance : Term := .param "p.same_direction_tolerance"

def zeroMetres : Term := .lit Q.zero .metre

/-
  How each span is written.
    s1: the stopped vehicle is a road user `b` quantified in the rule, a member of the admitted
        aggregate DEF-NRS-484A-320::vehicle (`ru_aggregate`) and not ego (`same`); "is stopped" is
        drv.motion.at_rest of b with p.rest_speed_tolerance.
    s2: `w` ranges over every region of kind `crosswalk` (marked and unmarked alike, as the element
        reads it); "at" w is drv.position.near_region of b and w with p.crosswalk_reach, the
        relation that anchors w to b.
    s3: some road user `p` of the admitted aggregate DEF-NRS-484A-165::pedestrian is at the same w
        (drv.position.near_region, p.crosswalk_reach) at the same observation as s1-s2: the three
        are one conjunction `stoppedFor b w`, evaluated at one observation.
    s4: ego's class is the vehicle aggregate; "approaching from the rear" is drv.position.behind of
        ego relative to b (p.same_direction_tolerance): it engages the duty at an observation where
        `stoppedFor b w` holds (the record's first limb of the applicability), and it is the
        occasion's onset.
    s5: drv.interaction.overtakes of ego and b, judged once at its recognition (`rises`). The act
        stretch runs from the onset (the last observation at which ego is behind b) to the
        recognition; `stoppedFor b w` at some moment of it is
        `since (not behind(ego, b)) (stoppedFor b w)`: stoppedFor at some observation j up to the
        recognition with ego not behind b at any observation after j, i.e. j at or after the onset.
    The obligation restates the whole selection of b and w (class, not ego, crosswalk kind, the
    occasion) so that it speaks of the same b and w as the applicability.
-/

/-- The admitted aggregates the node claims. -/
def aggVehicle : Arg := .lit "DEF-NRS-484A-320::vehicle"
def aggPedestrian : Arg := .lit "DEF-NRS-484A-165::pedestrian"

/-- Class of `ego`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsEgo : Formula := .atom "ru_aggregate" [vEgo, aggVehicle] []

/-- s1 and s4 ("any vehicle", "any other vehicle"): b is a vehicle other than ego. -/
def otherVehicle : Formula :=
  .and (.atom "ru_aggregate" [.var "b", aggVehicle] []) (.not (.same (.var "b") vEgo))

/-- s1-s3 at one observation: b at rest at crosswalk w, and a pedestrian at w. -/
def stoppedFor : Formula :=
  .and (.derived "drv_motion_at_rest" [.var "b"] [pRestSpeedTolerance])
    (.and (.derived "drv_position_near_region" [.var "b", .var "w"] [pCrosswalkReach])
      (.existsUser "p"
        (.and (.atom "ru_aggregate" [.var "p", aggPedestrian] [])
          (.derived "drv_position_near_region" [.var "p", .var "w"] [pCrosswalkReach]))))

/-- s4: ego behind b (the occasion's onset). -/
def egoBehind : Formula := .derived "drv_position_behind" [vEgo, .var "b"] [pSameDirectionTolerance]

/-- s5: the overtaking of b by ego, at its recognition. -/
def overtakes : Formula :=
  .rises (.derived "drv_interaction_overtakes" [vEgo, .var "b"] [pSameDirectionTolerance])

/-- s1-s3 at some observation of the act stretch, from the onset to the recognition. -/
def stoppedForDuringPass : Formula := .since (.not egoBehind) stoppedFor

/-- The recognition of an overtaking of b during which b was stopped at a crosswalk w with a
    pedestrian at w. -/
def passOfStopped : Formula :=
  .and overtakes (.existsRegion (.lit "crosswalk") "w" stoppedForDuringPass)

/-- Applicability: s1 (trigger): Whenever any vehicle is stopped; s2 (condition): at a marked crosswalk or at any unmarked crosswalk at an intersection; s3 (condition): to permit a pedestrian to cross the roadway -/
def applicability : Formula :=
  .existsUser "b"
    (.and otherVehicle
      (.or (.and egoBehind (.existsRegion (.lit "crosswalk") "w" stoppedFor))
        passOfStopped))

/-- Obligation: s5 (obligation): shall not overtake and pass such stopped vehicle. -/
def obligation : Formula :=
  .not (.existsUser "b" (.and otherVehicle passOfStopped))

def rule : Rule :=
  { id := "LVMC_11_30_030"
    laws := ["LVMC-11-30-030"]
    binders :=
      [ { name := "ego", cls := clsEgo } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations := []
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []  -- one { span := "<span id>", why := "<why>", kind := "reading" } per reading you chose on a carried span (kind no_atom / no_operator where the words cannot be stated), explained in the header; the record's own narrowings are not restated
    surrogate := false }

end TrafficSpec.Rules.LVMC_11_30_030
