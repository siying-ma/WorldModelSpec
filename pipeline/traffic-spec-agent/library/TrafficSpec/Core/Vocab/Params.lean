/-
  TrafficSpec.Core.Vocab.Params
  Readings and operationalizations: every number the statute did not state.

  A rule NAMES a parameter; it never owns the value. The value lives in the run's reading, which
  the rule and the label both cite, so a standard is quantified exactly once and can be swept for
  sensitivity. An `Operationalization` is the record that gives a judgement standard its concrete
  meaning (ATOMS.md §8): the standard's words, the atoms or derived concepts that bound it, the parameter
  values, the convention they come from, and whether the rule is a surrogate (the standard is the
  whole duty) rather than the law's own rule.

  No default values live here: a default in Core would be a threshold frozen before any law is seen.
-/
import TrafficSpec.Core.Foundations.Units

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
  concepts : List String       -- the `drv.*` and atom ids that bound it (ATOMS.md §8 pairs several)
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
/-- The `ru.*` ids an aggregate word covers; a member that is another declared word is expanded
    (fuel bounds the nesting), a member that is neither is kept as written so the check can name it. -/
def aggregate (ρ : Reading) (w : String) : Option (List String) :=
  let rec go (fuel : Nat) (w : String) : Option (List String) :=
    match fuel, ρ.aggregates.find? (·.word == w) with
    | 0, _ | _, none => none
    | fuel + 1, some a => some (a.classes.flatMap fun m =>
        if m.startsWith "ru." then [m] else (go fuel m).getD [m])
  go (ρ.aggregates.length + 1) w
end Reading

end TrafficSpec
