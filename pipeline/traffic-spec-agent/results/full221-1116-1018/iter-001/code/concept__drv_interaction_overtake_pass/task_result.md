# drv.interaction.overtake_pass — task result

## Final verdict

**SCOPE_VIOLATION (infrastructure, not the concept's files).** The gate never judged the two files.
Each gate run flagged a file that the agent's shell tool writes to capture the output of the command
it runs. It does this for every command, including the gate command itself:

- run 1: `.runtime/tmp/claude-154266/…/1fd5f94f-…/tasks/bg10asrf8.output`
- run 2: `.runtime/tmp/claude-154266/…/1fd5f94f-…/tasks/bbe1co7r1.output`

These files sit in the session scratch directory, `.runtime/tmp/…`, which is inside the repository
tree that the gate's scope check diffs. Nothing I wrote touches them. I can't remove them either: the
shell runs only the gate command, and I have no delete tool. Every gate run makes one more such file,
so the remaining 4 runs could only return the same verdict. Both files are still on disk. If the
harness's own re-run diffs the same tree, it may flag them too. The fix belongs in the harness: the
scope check should ignore `.runtime/tmp`, or the scratch directory should live outside the repository.

## Gate runs

| run | verdict | what changed after it |
|---|---|---|
| 1 | SCOPE_VIOLATION (the shell tool's output file `tasks/bg10asrf8.output`) | nothing; reran without a custom timeout to see if the file was avoided |
| 2 | SCOPE_VIOLATION (the shell tool's output file `tasks/bbe1co7r1.output`) | stopped: each run creates a new such file |

## The body (`library/TrafficSpec/Concepts/interaction/overtake_pass.lean`)

```
clear        := rel_longitudinal_overlap(a,b) < 0
bAhead       := rel_bearing(a,b,"ahead")  ∧ clear
bBehind      := rel_bearing(a,b,"behind") ∧ clear
aheadAligned := bAhead ∧ rel_same_direction(a,b)[same_dir_cos]
S            := since(¬bBehind, aheadAligned)
body         := bBehind ∧ rises(¬S) ∧ atLast(time, window, a, aheadAligned, tt)
```

- **Ahead and behind.** Taken straight from the contract: the sign of the bearing's longitudinal
  component (the `"ahead"` / `"behind"` selectors of `rel_bearing`), plus a negative longitudinal
  overlap.
- **Recognition plus extent.** "b is behind a and was not behind a at the previous observation" and
  "not again until b has again been ahead of a and then comes to be behind it" are written together:
  b is behind here, and at the previous observation `S` held (b had not been behind a since it was
  last ahead with headings aligned). The language has no previous-observation operator. Where `S` is
  false here (b is behind, so not ahead), `rises(¬S)` equals `S` at the previous observation. `S`
  there implies b was not behind there, so the edge of "behind" is included.
- **Window.** "Ahead with headings aligned at some observation of the window behind" (whose last such
  observation is the onset) is `atLast .time window` with search `aheadAligned` and `tt`. That
  formula is false where no such observation lies in a covered window, so a pass longer than the
  window is not recognized.
- **Claims.** All three claimed atoms are used. The only literal is zero. There are no narrowings:
  the contract dictated every choice.

## Witnesses (`library/TrafficSpecWitness/Concepts/interaction/overtake_pass.lean`)

- **Instance:** window 6 s, same_dir_cos 9/10. Both bodies are 4 m × 2 m. b is halted at (0,0)
  heading east. Samples are 1 s apart, starting at t = 10 s, with 6 s of padding before.
- **holds** (judged at t = 15 s):
  - b is ahead and aligned at t = 10 s and 11 s (11 s is the onset).
  - At 12 s a is angled 37° to the left (cos 0.8): b is still ahead but the headings are not aligned.
  - At 13 s and 14 s a is alongside. At 14 s b's centre is already behind a's centre but the bodies
    still overlap.
  - At 15 s b is behind with a 3 m gap, 4 s after the onset.
- **fails:** a draws alongside and halts with 3 m of shared projection, so b is never behind.
- **blind:** the holds trace with `rel.bearing` absent, judged at t = 15 s.
- **Leaf coverage.** The scenes are built so that every leaf changes the holds verdict when it is
  replaced:
  - the angled step at 12 s exercises the bearing leaf inside `since`;
  - the alongside-with-centre-behind step at 14 s exercises the overlap leaf inside `since`;
  - every conjunct leaf kills the verdict when replaced by `ff`.
- **Unchecked by the gate.** That the files build, and these verdicts, are worked out by hand from
  Core's evaluator (`Foundations/Temporal.lean`, `Language/Semantics.lean`, `Vocab/Atoms.lean`). The
  gate has not confirmed them.

## Why I finished

The gate could not judge my files. Every run of the one command I'm allowed creates a file inside the
repository, and the scope check counts it as a change outside the concept's files. More runs would
only add more such files. The record itself looks sound to me: I found no defect in it.
