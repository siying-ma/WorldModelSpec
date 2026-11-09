import TrafficSpec
import TrafficSpecWitness
import TrafficSpec.Core.Runtime.Decode
open TrafficSpec
def main : IO Unit := do
  let text ← IO.FS.readFile "/local-scratch2/sma407/scratch_core/launch/remote/pipeline/traffic-spec-agent/results/demo22-1109-0108/iter-001/integrate/reading.json"
  match Decode.parse Decode.reading text with
  | .error e => IO.println s!"READING_DECODE\t{e}"
  | .ok ρ => do
    for f in TrafficSpecWitness.failures ρ do IO.println s!"FAIL\t{f}"
    IO.println s!"RULES\t{allRules.length}\tSCENARIOS\t{TrafficSpecWitness.allScenarios.length}"
    IO.println "DONE"
