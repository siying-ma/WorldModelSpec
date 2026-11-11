/-
  NRS_484D_100_1 — NRS-484D-100-1

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (subject): Every vehicle
    s2 (condition): upon a highway
    s3 (condition): of this State,
    s4 (exception): subject to exceptions with respect to parked vehicles as stated in chapters 484A to 484E, inclusive, of NRS,
    s5 (obligation): must display lighted lamps and illuminating devices
    s6 (reference): as respectively required in this chapter for different classes of vehicles:
    s7 (trigger): (a) At any time from one-half hour after sunset to one-half hour before sunrise;
    s8 (trigger): (b) At any other time when, because of insufficient light or unfavorable atmospheric conditions, persons and vehicles on the highway are not clearly discernible at a distance of 1,000 feet ahead;
    s9 (trigger): and (c) When directed by an official traffic control device.

  Elements (span → atoms, derived):
    s1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle'], derived []
    s2: atoms ['rel.occupies', 'st.highway'], derived []
    s4: atoms ['kin.speed', 'kin.engine_running'], derived ['drv.motion.halted']
    s5: atoms ['sig.headlamp'], derived []
    s7: atoms ['env.darkness'], derived []
    s8: atoms ['env.visibility'], derived []
    s9: atoms ['dev.regulatory_sign', 'dev.governs', 'rel.occupies', 'st.travel_region'], derived []

  Literals the text states (each written through its Units constructor):
    s7: 0.5 h — one-half hour
    s8: 1000 ft — 1,000 feet

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484D_100_1

/-- The binders, as arguments (order and names are the node's). -/
def vX : Arg := .var "x"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pSpeedResolution : Term := .param "p.speed_resolution"

def zeroMetres : Term := .lit Q.zero .metre

/-
  How each span is written.
    s1: ru_aggregate(x, DEF-NRS-484A-320::vehicle), the binder's class.
    s2: some region of kind `highway` that x's footprint overlaps (rel_occupies); the quantifier's
        kind is st.highway, the whole public way, not narrowed to a roadway.
    s4: x is not parked: not (drv.motion.halted(x; p.speed_resolution) and not kin_engine_running(x)).
    s7: env_darkness. The atom's sunset/sunrise boundary is the reading's parameter; the atom takes
        no argument for it, so the literal one-half hour is carried by the reading and not by a term
        here.
    s8: env_visibility below the literal 1,000 ft (Units.feet 1000).
    s7, s8 (and s9) are alternatives: any one of them engages the duty.
    s9: NOT WRITTEN — declared `no_atom`. The record maps it to dev.regulatory_sign / dev.governs /
        st.travel_region with an atom gap: no catalogue code of dev.regulatory_sign directs a road
        user to display lamps, so any formula over those atoms would make an unrelated regulatory
        sign (no_parking, one_way, …) engage the duty. The plan's gap (`dev.lamps_on_sign`) is filed.
    s5: sig_headlamp(x) is low_beam or high_beam.
-/

/-- Class of `x`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsX : Formula := .atom "ru_aggregate" [vX, .lit "DEF-NRS-484A-320::vehicle"] []

/-- s2: x's footprint overlaps a highway. -/
def onHighway : Formula :=
  .existsRegion (.lit "highway") "h" (.atom "rel_occupies" [vX, .var "h"] [])

/-- s4: a parked vehicle — halted with its engine not running. -/
def parked : Formula :=
  .and (.derived "drv_motion_halted" [vX] [pSpeedResolution])
       (.not (.atom "kin_engine_running" [vX] []))

/-- s7: from one-half hour after sunset to one-half hour before sunrise. -/
def darkness : Formula := .atom "env_darkness" [] []

/-- s8: persons and vehicles not clearly discernible at 1,000 feet. -/
def poorVisibility : Formula :=
  .cmp (.measure "env_visibility" []) .lt (.lit (Units.feet 1000) .metre)

/-- Applicability: s2 (condition): upon a highway; s3 (condition): of this State,; s4 (exception): subject to exceptions with respect to parked vehicles as stated in chapters 484A to 484E, inclusive, of NRS,; s7 (trigger): (a) At any time from one-half hour after sunset to one-half hour before sunrise;; s8 (trigger): (b) At any other time when, because of insufficient light or unfavorable atmospheric conditions, persons and vehicles on the highway are not clearly discernible at a distance of 1,000 feet ahead;; s9 (trigger): and (c) When directed by an official traffic control device. -/
def applicability : Formula :=
  .and onHighway (.and (.not parked) (.or darkness poorVisibility))

/-- Obligation: s5 (obligation): must display lighted lamps and illuminating devices -/
def obligation : Formula :=
  .or (.atom "sig_headlamp" [vX, .lit "low_beam"] [])
      (.atom "sig_headlamp" [vX, .lit "high_beam"] [])

def rule : Rule :=
  { id := "NRS_484D_100_1"
    laws := ["NRS-484D-100-1"]
    binders :=
      [ { name := "x", cls := clsX } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    intentions := []
    operationalizations := []
    residues := ["“of this State” names the jurisdiction whose law this is; the run applies Nevada's law to the highways of the maps it reads, so every highway the rule reads is one this State's law governs and the duty is the same whether or not the words are stated.", "The class-specific lamp sets the chapter requires (headlamps, tail lamps, clearance lamps, by class of vehicle) are provisions not in this corpus; the rule reads the headlamps every vehicle moving at these times shows (narrowing on s5), and the class-by-class sets are not captured."]  -- the node's, verbatim; not yours to change
    narrowings :=
      [ { span := "s9"
          why := "“When directed by an official traffic control device” to display lighted lamps: the record maps it to dev.regulatory_sign governing (dev.governs) a travel region (st.travel_region) the vehicle occupies, with an atom gap, and no catalogue code of dev.regulatory_sign (nor any dev.zone_sign kind) directs road users to display lamps. Written with those atoms, any regulatory sign — no_parking, one_way — would engage the duty by day, which the words do not say. No atom of the surface carries a lamps-on direction; the plan's gap `dev.lamps_on_sign` (or a code lamps_on of dev.regulatory_sign) is needed."
          kind := "no_atom" } ]
    surrogate := false }

end TrafficSpec.Rules.NRS_484D_100_1
