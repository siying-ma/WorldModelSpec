/-
  TrafficSpec.Core.Params
  Readings and operationalizations: every number the statute did not state.

  A rule NAMES a parameter; it never owns the value. The value lives in the run's reading, which
  the rule and the label both cite, so a standard is quantified exactly once and can be swept for
  sensitivity. An `Operationalization` is the record that gives a judgement standard its concrete
  meaning (ATOMS.md §8): the standard's words, the derived concept that bounds it, the parameter
  values, the convention they come from, and whether the rule is a surrogate (the standard is the
  whole duty) rather than the law's own rule.

  No default values live here: a default in Core would be a threshold frozen before any law is seen.
-/
import TrafficSpec.Core.Units

namespace TrafficSpec

abbrev ParamName := String

inductive PUnit'
  | metre | second | metrePerSecond | metrePerSecondSq | degree | degreePerSecond | ratio | count
  deriving DecidableEq, Repr, Inhabited

structure ParamValue where
  name : ParamName
  value : Q
  unit : PUnit'
  deriving Repr, Inhabited

structure Operationalization where
  standard : String            -- the clause's words for the standard
  concept : String             -- the `drv.*` id that bounds it
  params : List ParamName      -- the parameters the bound uses
  convention : String          -- where the values come from
  surrogate : Bool := false    -- true when the standard is the whole duty
  deriving Repr, Inhabited

/-- Which observable classes a legal aggregate word ("vehicle", "traffic") covers. -/
structure LegalAggregate where
  word : String
  classes : List String        -- `ru.*` ids
  deriving Repr, Inhabited

structure Reading where
  params : List ParamValue := []
  operationalizations : List Operationalization := []
  aggregates : List LegalAggregate := []
  deriving Repr, Inhabited

namespace Reading
def param (ρ : Reading) (n : ParamName) : Option Q :=
  (ρ.params.find? (·.name == n)).map (·.value)
def paramUnit (ρ : Reading) (n : ParamName) : Option PUnit' :=
  (ρ.params.find? (·.name == n)).map (·.unit)
def has (ρ : Reading) (n : ParamName) : Bool := (ρ.param n).isSome
def aggregate (ρ : Reading) (w : String) : Option (List String) :=
  (ρ.aggregates.find? (·.word == w)).map (·.classes)
end Reading

end TrafficSpec
