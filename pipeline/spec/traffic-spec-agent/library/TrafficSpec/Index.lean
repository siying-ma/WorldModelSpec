/-
  TrafficSpec.Index
  The rule registry.

  MANAGED FILE — rewritten by `scripts/index_sync.py` during the integrate
  phase. Do not edit by hand; add a rule file under `Rules/` and the integrate
  phase will register it. A rule that compiles but is not registered here is
  invisible to the library, which is why `check_library` treats an unregistered
  rule file as an integration failure.
-/
import TrafficSpec.Core
-- BEGIN GENERATED IMPORTS
import TrafficSpec.Rules.Emergency.R0012_pull_right_for_emergency
import TrafficSpec.Rules.Emergency.R0013_clear_junction_for_emergency
import TrafficSpec.Rules.Following.R0003_following_distance
import TrafficSpec.Rules.Following.R0010_prudent_gap_when_lead_brakes
import TrafficSpec.Rules.Junction.R0006_yield_in_occupied_junction
import TrafficSpec.Rules.Lane.R0008_opposing_lane_oncoming
import TrafficSpec.Rules.Lane.R0011_keep_right_of_roadway
import TrafficSpec.Rules.Signal.R0004_red_light_entry
import TrafficSpec.Rules.Speed.R0001_max_speed
import TrafficSpec.Rules.Speed.R0002_junction_speed
import TrafficSpec.Rules.Stop.R0005_stop_sign_dwell
-- END GENERATED IMPORTS

namespace TrafficSpec

/-- Every formalized rule in the library. -/
def allRules : List RuleEntry :=
  -- BEGIN GENERATED RULES
  [ Rules.Emergency.R0012.entry, Rules.Emergency.R0013.entry, Rules.Following.R0003.entry, Rules.Following.R0010.entry, Rules.Junction.R0006.entry, Rules.Lane.R0008.entry, Rules.Lane.R0011.entry, Rules.Signal.R0004.entry, Rules.Speed.R0001.entry, Rules.Speed.R0002.entry, Rules.Stop.R0005.entry ]
  -- END GENERATED RULES

/-- Every declared scenario, paired with the rule it belongs to. -/
def allScenarios : List (RuleEntry × List Scenario) :=
  -- BEGIN GENERATED SCENARIOS
  [ (Rules.Emergency.R0012.entry, Rules.Emergency.R0012.scenarios), (Rules.Emergency.R0013.entry, Rules.Emergency.R0013.scenarios), (Rules.Following.R0003.entry, Rules.Following.R0003.scenarios), (Rules.Following.R0010.entry, Rules.Following.R0010.scenarios), (Rules.Junction.R0006.entry, Rules.Junction.R0006.scenarios), (Rules.Lane.R0008.entry, Rules.Lane.R0008.scenarios), (Rules.Lane.R0011.entry, Rules.Lane.R0011.scenarios), (Rules.Signal.R0004.entry, Rules.Signal.R0004.scenarios), (Rules.Speed.R0001.entry, Rules.Speed.R0001.scenarios), (Rules.Speed.R0002.entry, Rules.Speed.R0002.scenarios), (Rules.Stop.R0005.entry, Rules.Stop.R0005.scenarios) ]
  -- END GENERATED SCENARIOS

/-- Report every rule's verdict on a trace — the entry point a monitoring
    application calls. -/
def checkLibrary (τ : Trace) : List String :=
  allRules.foldr (fun r acc => (r.instantiate τ).map (checkProperty τ) ++ acc) []

/-- Re-run every declared scenario. Used by the integrate phase to confirm that
    adding a rule did not break an existing one. -/
def scenarioReport : String :=
  String.intercalate "\n"
    (allScenarios.map (fun p => report p.1 p.2 Carla.sampleTrace))

def scenarioReportIO : IO Unit := IO.println scenarioReport

end TrafficSpec
