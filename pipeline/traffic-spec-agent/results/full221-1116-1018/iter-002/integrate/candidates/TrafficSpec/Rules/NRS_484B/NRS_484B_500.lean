/-
  NRS_484B_500 — NRS-484B-500

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (condition): When official traffic-control devices are erected at hazardous or congested places,
    s2 (obligation): a person shall not stop, stand or park a vehicle
    s3 (condition): in any such designated place.

  Elements (span → atoms, derived):
    s1: atoms ['dev.zone_sign', 'dev.regulatory_sign', 'prim.conditions_hold'], derived []
    s2: atoms ['dev.governs', 'dev.human_direction', 'dev.railway_signal_or_gate', 'dev.stop_sign', 'dev.traffic_signal', 'dev.yield_sign', 'rel.ahead_behind_in_lane', 'rel.occupies', 'rel.surface_gap', 'ru.aggregate=DEF-NRS-484A-320::vehicle', 'st.travel_region'], derived ['drv.motion.complete_halt']
    s3: atoms ['dev.governs', 'rel.occupies', 'st.travel_region'], derived []

  How each is written:
    class (s2): the subject is a member of the aggregate DEF-NRS-484A-320::vehicle (`ru_aggregate`).
    s1: a designating device `d` of region `r` is either a zone sign (quantifier kind `zone_sign`) of
        kind hazardous_place that begins a zone (`dev_zone_sign_end` false), or a regulatory sign
        (quantifier kind `regulatory_sign`) of code no_stopping; in both cases its posted conditions
        hold for the subject (`prim_conditions_hold d subject`).
    s3: the designated place is a travel region `r` (quantifier kind `travel_region`) the device
        governs (`dev_governs d r`) and the subject's footprint overlaps (`rel_occupies subject r`).
        The applicability asks for some such region; the obligation re-selects the region with the
        same whole selection and states the duty for every selected region.
    s2: the duty is `not complete_halt(subject, p.halt_speed_tolerance)`, except
        (a) some other road user `o` (`not same o subject`) ahead of the subject in the same lane
            (`rel_ahead_behind_in_lane o subject`, a ahead of b) with a body gap
            (`rel_surface_gap subject o`, read without a component: the distance) at most
            p.queue_halt_gap; or
        (b) some travel region `q` the subject occupies is governed by a stop sign, a yield sign, a
            traffic signal showing circular_red, circular_yellow, red_arrow(dir), yellow_arrow(dir) or
            flashing_red, a railway signal or gate with lights flashing or gate not up, or a
            human direction of role police_officer giving indication stop.
  No choice beyond the record's was needed; no narrowing is declared.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_500

/-- The binders, as arguments (order and names are the node's). -/
def vSubject : Arg := .var "subject"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pHaltSpeedTolerance : Term := .param "p.halt_speed_tolerance"
def pQueueHaltGap : Term := .param "p.queue_halt_gap"

def zeroMetres : Term := .lit Q.zero .metre

/-- Class of `subject`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsSubject : Formula := .atom "ru_aggregate" [vSubject, .lit "DEF-NRS-484A-320::vehicle"] []

/-- s1 + s3: region `r` is a designated place — governed by a hazardous_place zone sign that begins
    a zone, or by a no_stopping regulatory sign, whose conditions hold for the subject. -/
def designated (r : String) : Formula :=
  .or
    (.existsDevice (.lit "zone_sign") "dz"
      (.and (.atom "dev_zone_sign_kind" [.var "dz", .lit "hazardous_place"] [])
        (.and (.not (.atom "dev_zone_sign_end" [.var "dz"] []))
          (.and (.atom "dev_governs" [.var "dz", .var r] [])
            (.derived "prim_conditions_hold" [.var "dz", vSubject] [])))))
    (.existsDevice (.lit "regulatory_sign") "dn"
      (.and (.atom "dev_regulatory_sign_code" [.var "dn", .lit "no_stopping"] [])
        (.and (.atom "dev_governs" [.var "dn", .var r] [])
          (.derived "prim_conditions_hold" [.var "dn", vSubject] []))))

/-- s3: the whole selection of the designated region `r`. -/
def selected (r : String) : Formula :=
  .and (.atom "rel_occupies" [vSubject, .var r] []) (designated r)

/-- Applicability: s1 (condition): When official traffic-control devices are erected at hazardous or congested places,; s3 (condition): in any such designated place. -/
def applicability : Formula :=
  .existsRegion (.lit "travel_region") "r" (selected "r")

/-- s2: the halt. -/
def halted : Formula :=
  .derived "drv_motion_complete_halt" [vSubject] [pHaltSpeedTolerance]

/-- s2 exception (a): a halt to avoid conflict with other traffic — another road user ahead in the
    same lane within the queue gap. -/
def queueHalt : Formula :=
  .existsUser "o"
    (.and (.not (.same (.var "o") vSubject))
      (.and (.atom "rel_ahead_behind_in_lane" [.var "o", vSubject] [])
        (.cmp (.measure "rel_surface_gap" [vSubject, .var "o"]) .le pQueueHaltGap)))

def signalShowsHalt (e : String) : Formula :=
  let shows (i : String) : Formula := .atom "dev_traffic_signal_shows" [.var e, .lit i] []
  .or (shows "circular_red")
    (.or (shows "circular_yellow")
      (.or (shows "flashing_red")
        (.or (shows "red_arrow(left)") (.or (shows "red_arrow(right)")
          (.or (shows "red_arrow(straight)") (.or (shows "red_arrow(u_turn)")
            (.or (shows "yellow_arrow(left)") (.or (shows "yellow_arrow(right)")
              (.or (shows "yellow_arrow(straight)") (shows "yellow_arrow(u_turn)"))))))))))

/-- s2 exception (b): a halt in compliance with a device or an officer governing a travel region the
    subject occupies. -/
def complianceHalt : Formula :=
  .existsRegion (.lit "travel_region") "q"
    (.and (.atom "rel_occupies" [vSubject, .var "q"] [])
      (.or (.existsDevice (.lit "stop_sign") "es" (.atom "dev_governs" [.var "es", .var "q"] []))
        (.or (.existsDevice (.lit "yield_sign") "ey" (.atom "dev_governs" [.var "ey", .var "q"] []))
          (.or (.existsDevice (.lit "traffic_signal") "et"
                  (.and (.atom "dev_governs" [.var "et", .var "q"] []) (signalShowsHalt "et")))
            (.or (.existsDevice (.lit "railway_signal_or_gate") "er"
                    (.and (.atom "dev_governs" [.var "er", .var "q"] [])
                      (.or (.atom "dev_railway_signal_or_gate_lights" [.var "er", .lit "flashing"] [])
                        (.not (.atom "dev_railway_signal_or_gate_gate" [.var "er", .lit "up"] [])))))
              (.existsDevice (.lit "human_direction") "eh"
                (.and (.atom "dev_governs" [.var "eh", .var "q"] [])
                  (.and (.atom "dev_human_direction_role" [.var "eh", .lit "police_officer"] [])
                    (.atom "dev_human_direction_indication" [.var "eh", .lit "stop"] [])))))))))

/-- Obligation: s2 (obligation): a person shall not stop, stand or park a vehicle -/
def obligation : Formula :=
  .forallRegion (.lit "travel_region") "r"
    (.implies (selected "r")
      (.or (.not halted) (.or queueHalt complianceHalt)))

def rule : Rule :=
  { id := "NRS_484B_500"
    laws := ["NRS-484B-500"]
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

end TrafficSpec.Rules.NRS_484B_500
