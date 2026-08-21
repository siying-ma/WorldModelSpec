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
import TrafficSpec.Rules.Emergency.R0020_yield_to_emergency_van_in_lane
import TrafficSpec.Rules.Following.R0003_following_distance
import TrafficSpec.Rules.Following.R0014_prudent_gap_when_lead_brakes
import TrafficSpec.Rules.Following.R0015_prudent_gap_at_speed
import TrafficSpec.Rules.Following.R0021_close_gap_across_lane_boundary
import TrafficSpec.Rules.Following.R0024_braking_lead_across_lane_boundary
import TrafficSpec.Rules.Junction.R0006_yield_in_occupied_junction
import TrafficSpec.Rules.Lane.R0008_keep_right_of_roadway
import TrafficSpec.Rules.Lane.R0016_crossing_into_opposing_lane
import TrafficSpec.Rules.Lane.R0017_wrong_way_progress_with_oncoming
import TrafficSpec.Rules.Lane.R0022_occupying_lane_against_observed_flow
import TrafficSpec.Rules.Lane.R0023_wrong_way_with_vehicle_in_lane
import TrafficSpec.Rules.Lane.R0025_travel_against_lane_flow
import TrafficSpec.Rules.Signal.R0010_red_light_in_junction
import TrafficSpec.Rules.Signal.R0018_stop_at_red_before_entering
import TrafficSpec.Rules.Signal.R0026_entry_on_red_without_stopping
import TrafficSpec.Rules.Speed.R0001_max_speed
import TrafficSpec.Rules.Speed.R0002_junction_speed
import TrafficSpec.Rules.Stop.R0007_stop_sign_dwell
import TrafficSpec.Rules.Stop.R0019_stop_landmark_dwell
-- END GENERATED IMPORTS

namespace TrafficSpec

/-- Every formalized rule in the library. -/
def allRules : List RuleEntry :=
  -- BEGIN GENERATED RULES
  [ Rules.Emergency.R0012.entry, Rules.Emergency.R0020.entry, Rules.Following.R0003.entry, Rules.Following.R0014.entry, Rules.Following.R0015.entry, Rules.Following.R0021.entry, Rules.Following.R0024.entry, Rules.Junction.R0006.entry, Rules.Lane.R0008.entry, Rules.Lane.R0016.entry, Rules.Lane.R0017.entry, Rules.Lane.R0022.entry, Rules.Lane.R0023.entry, Rules.Lane.R0025.entry, Rules.Signal.R0010.entry, Rules.Signal.R0018.entry, Rules.Signal.R0026.entry, Rules.Speed.R0001.entry, Rules.Speed.R0002.entry, Rules.Stop.R0007.entry, Rules.Stop.R0019.entry ]
  -- END GENERATED RULES

/-- Every declared scenario, paired with the rule it belongs to. -/
def allScenarios : List (RuleEntry × List Scenario) :=
  -- BEGIN GENERATED SCENARIOS
  [ (Rules.Emergency.R0012.entry, Rules.Emergency.R0012.scenarios), (Rules.Emergency.R0020.entry, Rules.Emergency.R0020.scenarios), (Rules.Following.R0003.entry, Rules.Following.R0003.scenarios), (Rules.Following.R0014.entry, Rules.Following.R0014.scenarios), (Rules.Following.R0015.entry, Rules.Following.R0015.scenarios), (Rules.Following.R0021.entry, Rules.Following.R0021.scenarios), (Rules.Following.R0024.entry, Rules.Following.R0024.scenarios), (Rules.Junction.R0006.entry, Rules.Junction.R0006.scenarios), (Rules.Lane.R0008.entry, Rules.Lane.R0008.scenarios), (Rules.Lane.R0016.entry, Rules.Lane.R0016.scenarios), (Rules.Lane.R0017.entry, Rules.Lane.R0017.scenarios), (Rules.Lane.R0022.entry, Rules.Lane.R0022.scenarios), (Rules.Lane.R0023.entry, Rules.Lane.R0023.scenarios), (Rules.Lane.R0025.entry, Rules.Lane.R0025.scenarios), (Rules.Signal.R0010.entry, Rules.Signal.R0010.scenarios), (Rules.Signal.R0018.entry, Rules.Signal.R0018.scenarios), (Rules.Signal.R0026.entry, Rules.Signal.R0026.scenarios), (Rules.Speed.R0001.entry, Rules.Speed.R0001.scenarios), (Rules.Speed.R0002.entry, Rules.Speed.R0002.scenarios), (Rules.Stop.R0007.entry, Rules.Stop.R0007.scenarios), (Rules.Stop.R0019.entry, Rules.Stop.R0019.scenarios) ]
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
