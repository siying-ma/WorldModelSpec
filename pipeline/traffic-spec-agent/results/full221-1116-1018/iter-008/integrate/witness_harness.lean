import TrafficSpec
import TrafficSpecWitness
import TrafficSpec.Core.Runtime.Decode
open TrafficSpec
def main : IO Unit := do
  let text ← IO.FS.readFile "/scratch/fsw/portfolios/av/projects/av_alpamayo_reasoning/users/wcong/WorldModelSpec/.worktrees/full221-v2/pipeline/traffic-spec-agent/results/full221-1116-1018/iter-008/integrate/reading.json"
  match Decode.parse Decode.reading text with
  | .error e => IO.println s!"READING_DECODE\t{e}"
  | .ok ρ => do
    for f in TrafficSpecWitness.failures ρ do IO.println s!"FAIL\t{f}"
    IO.println s!"RULES\t{allRules.length}\tSCENARIOS\t{TrafficSpecWitness.allScenarios.length}"
    IO.println "DONE"
