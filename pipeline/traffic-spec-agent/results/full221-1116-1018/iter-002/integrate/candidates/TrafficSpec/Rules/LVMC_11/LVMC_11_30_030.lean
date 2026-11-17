/-
  LVMC_11_30_030 — LVMC-11-30-030

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    d1 (trigger): Whenever any vehicle is stopped at a marked crosswalk or at any unmarked crosswalk at an intersection to permit a pedestrian to cross the roadway
    d2 (subject): the driver of any other vehicle
    d3 (obligation): approaching from the rear shall not overtake and pass such stopped vehicle

  Elements (span → atoms, derived):
    d1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle', 'st.crosswalk', 'st.region_geometry', 'rel.occupies', 'st.travel_region', 'prim.region_offset_along', 'ru.aggregate=DEF-NRS-484A-165::pedestrian'], derived ['drv.motion.complete_halt']
    d2: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    d3: atoms [], derived ['drv.interaction.overtake_pass']

  How each span is written:
    d1 — `stoppedAtCrosswalk b`: b is at a complete halt (drv.motion.complete_halt, speed tolerance
         p.halt_speed_tolerance), and some crosswalk c (quantifier over kind `crosswalk`, which covers
         the marked crossing and the unmarked prolongation of sidewalks at an intersection alike) is
         such that b's body occupies c (rel_occupies) or lies within p.stop_point_tolerance of it
         (st_region_geometry_distance), c is not behind b along the direction of some travel region l
         b occupies (prim_region_offset_along b c l ≥ 0, l bound by `travel_region` and anchored by
         rel_occupies b l), and some pedestrian (ru_aggregate DEF-NRS-484A-165::pedestrian) occupies c
         at the same observation (the record's observable reading of the purpose).
         The vehicle b is a member of DEF-NRS-484A-320::vehicle other than the subject (`same`).
         Applicability: some such b for which d1 held at the observation or at some observation of the
         p.overtake_window behind it: `.not (.holdsFor .time W subject (.not d1))`.
    d2 — the binder `subject`, class ru_aggregate DEF-NRS-484A-320::vehicle.
    d3 — `.not (∃ b. other vehicle ∧ overtake_pass(subject, b) ∧ d1 at some moment of the pass)`,
         with drv.interaction.overtake_pass (window p.overtake_window, same_dir_cos
         p.overtake_same_direction_cos), true at its recognition only.
    Occasion (boundary `window`, d1 read `some_moment`): `.not (.holdsFor .time W subject
         (.not (.and U d1)))`, W = p.overtake_window, d1 re-selecting its crosswalk, carrier and
         pedestrian in full (rule 3c). U (under way) is written from its atoms:
           moving   = kin_speed subject > p.halt_speed_tolerance
           A        = b ahead of the subject with headings aligned: rel_bearing "ahead",
                      rel_longitudinal_overlap < 0, rel_same_direction (p.overtake_same_direction_cos)
           behind   = rel_bearing "behind" and rel_longitudinal_overlap < 0
           U        = moving ∧ (¬A until rises(behind))
         i.e. an observation at which the subject is moving, after which b is never again ahead
         with headings aligned before b comes to be behind the subject (the recognition).

  Choices the record left open:
    - The language has no "next observation" operator, so U cannot single out the last
      aligned-ahead observation itself (the act's first observation) from the earlier ones of the
      same run without reading ahead past it. U counts the observations strictly after it, up to and
      including the recognition; the act's first observation, at which b is still ahead of the
      subject with a gap between them, is not read. Declared as a narrowing on d3.
    - `¬A until rises(behind)` takes the first recognition after the observation; within one window
      only one pass of the same b is recognized in every witness.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.LVMC_11_30_030

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- Quantifier variables: the other vehicle, the crosswalk, the carrier, the pedestrian. -/
def vB : Arg := .var "b"
def vC : Arg := .var "c"
def vL : Arg := .var "l"
def vP : Arg := .var "p"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"
def pOvertakeSameDirectionCos : Term := .param "p.overtake_same_direction_cos"
def pOvertakeWindow : Term := .param "p.overtake_window"
def pStopPointTolerance : Term := .param "p.stop_point_tolerance"

def zeroMetres : Term := .lit Q.zero .metre

def aggVehicle : String := "DEF-NRS-484A-320::vehicle"
def aggPedestrian : String := "DEF-NRS-484A-165::pedestrian"

/-- `x` is a member of the admitted vehicle aggregate. -/
def isVehicle (x : Arg) : Formula := .atom "ru_aggregate" [x, .lit aggVehicle] []

/-- d1, for the vehicle `b`: at a complete halt at a crosswalk occupied by a pedestrian. -/
def stoppedAtCrosswalk : Formula :=
  .and (.derived "drv_motion_complete_halt" [vB] [pHaltSpeedTolerance])
    (.existsRegion (.lit "crosswalk") "c"
      (.and
        (.or (.atom "rel_occupies" [vB, vC] [])
             (.cmp (.measure "st_region_geometry_distance" [vB, vC]) .le pStopPointTolerance))
        (.and
          (.existsRegion (.lit "travel_region") "l"
            (.and (.atom "rel_occupies" [vB, vL] [])
                  (.cmp (.quantity "prim_region_offset_along" [vB, vC, vL] []) .ge zeroMetres)))
          (.existsUser "p"
            (.and (.atom "ru_aggregate" [vP, .lit aggPedestrian] [])
                  (.atom "rel_occupies" [vP, vC] []))))))

/-- b is ahead of the subject with headings aligned. -/
def aheadAligned : Formula :=
  .and (.atom "rel_bearing" [vSubject, vB, .lit "ahead"] [])
    (.and (.cmp (.measure "rel_longitudinal_overlap" [vSubject, vB]) .lt zeroMetres)
          (.atom "rel_same_direction" [vSubject, vB] [pOvertakeSameDirectionCos]))

/-- b is behind the subject, the projections sharing no length. -/
def behind : Formula :=
  .and (.atom "rel_bearing" [vSubject, vB, .lit "behind"] [])
       (.cmp (.measure "rel_longitudinal_overlap" [vSubject, vB]) .lt zeroMetres)

/-- The occasion's under-way element: the subject moving, inside the pass of b. -/
def underWay : Formula :=
  .and (.cmp (.measure "kin_speed" [vSubject]) .gt pHaltSpeedTolerance)
       (.until (.not aheadAligned) (.rises behind))

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula := isVehicle vSubject

/-- Applicability: d1 (trigger): Whenever any vehicle is stopped at a marked crosswalk or at any unmarked crosswalk at an intersection to permit a pedestrian to cross the roadway -/
def applicability : Formula :=
  .existsUser "b"
    (.and (.not (.same vB vSubject))
      (.and (isVehicle vB)
        (.not (.holdsFor .time pOvertakeWindow "subject" (.not stoppedAtCrosswalk)))))

/-- Obligation: d3 (obligation): approaching from the rear shall not overtake and pass such stopped vehicle -/
def obligation : Formula :=
  .not (.existsUser "b"
    (.and (.not (.same vB vSubject))
      (.and (isVehicle vB)
        (.and (.derived "drv_interaction_overtake_pass" [vSubject, vB]
                [pOvertakeWindow, pOvertakeSameDirectionCos])
              (.not (.holdsFor .time pOvertakeWindow "subject"
                (.not (.and underWay stoppedAtCrosswalk))))))))

def rule : Rule :=
  { id := "LVMC_11_30_030"
    laws := ["LVMC-11-30-030"]
    binders :=
      [ { name := "subject", cls := clsSubject } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations := []
    residues := []  -- the node's, verbatim; not yours to change
    narrowings :=
      [ { span := "d3"
          why := "The pass's observations are read from the one after the last observation at which b was ahead of the subject with headings aligned, up to the recognition: the language has no next-observation operator to single out that last aligned-ahead observation from the earlier ones of its run, so the act's first observation, at which b is still ahead of the subject with a gap between them, is not read for the trigger."
          kind := "reading" } ]
    surrogate := false }

end TrafficSpec.Rules.LVMC_11_30_030
