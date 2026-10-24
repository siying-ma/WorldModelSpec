/-
  NRS_484B_600_1e — NRS-484B-600-1e

  THE READING (the blueprint's; the coding session records here, per span, how each element,
  operationalization and composition below is written, and every choice the text did not dictate).

  Spans:
    s1 (subject): It is unlawful for any person to drive or operate a vehicle of any kind or character at:
    s2 (boilerplate): In any event,
    s3 (obligation): a rate of speed greater than 80 miles per hour.

  Elements (span → atoms, derived):
    s1: atoms ['ru.aggregate=DEF-NRS-484A-320::vehicle', 'kin.speed'], derived []
    s3: atoms ['kin.speed'], derived []

  Literals the text states (each written through its Units constructor):
    s3: 80 mph — 80 miles per hour

  s1 is the binder's class and the whole of the applicability. "a vehicle of any kind or
  character" is the aggregate claimed whole: `ru_aggregate v "DEF-NRS-484A-320::vehicle"`, the
  admitted id and never the classes it covers. "any person to drive or operate" is who or what
  controls the vehicle, which the ontology holds to be unobservable; it is read through the
  vehicle's own controlled motion — `kin_speed v` standing clear of the source's resolution,
  `p.speed_resolution` — so that a vehicle at rest is not engaged and a vehicle in motion is
  engaged whoever or whatever is at its controls. That is the node's own observable reading on
  s1, already on its record, and so is not restated in `narrowings`.

  s1 names no place and no occasion, and s2 states the rate is forbidden "In any event": the
  applicability therefore carries no locational condition at all — no highway region and no
  occupancy of one — and the rule engages wherever the vehicle is driven. Nothing of the scene
  besides the subject's class and its motion is read, so the rule quantifies over nothing and
  there is no variable to anchor.

  s2 is boilerplate: it adds no leaf of its own; its force is the absence of any place, occasion
  or posted rate from the applicability, and it is what makes `branch_1` (a vehicle at that rate
  off any public way) a violation.

  s3 is the obligation: the subject's `kin_speed` is at most the rate the paragraph itself states,
  eighty miles per hour, carried as a literal of the rule in the unit the text gives
  (`Units.mph 80`) and compared through the formula language's units. A greater rate is the
  violation. The paragraph reads no posted device and no reading parameter stands for its figure.

  No magnitude below is this file's own: parameters name the reading, literals are the text's.
-/
import TrafficSpec.Core.Language.Rule

namespace TrafficSpec.Rules.NRS_484B_600_1e

/-- The binders, as arguments (order and names are the node's). -/
def vV : Arg := .var "v"

/-- The reading's parameters; no value of any of them lives in this file. -/
def pSpeedResolution : Term := .param "p.speed_resolution"

/-- s3: the rate the paragraph states, in the unit the text gives. -/
def eightyMilesPerHour : Term := .lit (Units.mph 80) .metrePerSecond

/-- s1 and s3: the rate of speed, read on the subject itself. -/
def speedV : Term := .measure "kin_speed" [vV]

/-- Class of `v`: ru.aggregate=DEF-NRS-484A-320::vehicle -/
def clsV : Formula := .atom "ru_aggregate" [vV, .lit "DEF-NRS-484A-320::vehicle"] []

/-- s1: the vehicle is being driven or operated — its speed stands clear of the source's
    resolution, which is how the controlling agency is read. -/
def inMotion : Formula := .cmp speedV .gt pSpeedResolution

/-- Applicability: s1 — a vehicle of the admitted aggregate, in motion. In any event (s2):
    no place and no occasion is required of the scene. -/
def applicability : Formula := inMotion

/-- Obligation: s3 (obligation): a rate of speed greater than 80 miles per hour. -/
def obligation : Formula := .cmp speedV .le eightyMilesPerHour

def rule : Rule :=
  { id := "NRS_484B_600_1e"
    laws := ["NRS-484B-600-1e"]
    binders :=
      [ { name := "v", cls := clsV } ]
    applicability := applicability
    obligation := obligation
    assumptions := []
    operationalizations := []
    residues := []  -- the node's, verbatim; not yours to change
    narrowings := []
    surrogate := false }

end TrafficSpec.Rules.NRS_484B_600_1e
