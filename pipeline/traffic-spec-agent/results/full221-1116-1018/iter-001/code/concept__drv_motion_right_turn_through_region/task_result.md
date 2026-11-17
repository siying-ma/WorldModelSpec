# drv.motion.right_turn_through_region — task result

## Final verdict
`SCOPE_VIOLATION` on both gate runs. The gate never judged the two concept files. The only path it
reported was a file the agent tool wrote itself, not one I wrote: the shell tool saves each command's output to
`.runtime/tmp/claude-154266/.../tasks/<id>.output`. That folder is the session's temp directory,
and it sits inside the tree the gate checks for changes. Each gate call creates a new file there,
so every run inside this session fails this way. This is an infrastructure problem, not a problem
with the concept. The harness's own re-run after the session should judge the files as they are,
provided `.runtime/` is excluded or cleaned.

## Gate runs
1. `SCOPE_VIOLATION`: the only path named was `.runtime/tmp/.../tasks/b6csmsqzg.output`, the
   tool's output capture. I changed nothing.
2. `SCOPE_VIOLATION`: same cause, with a new capture file (`bu542qjwo.output`). I stopped
   there because more runs would only create more such files.

## The body
```
inR    = rel_occupies(a, r)
exitR  = rises (¬ inR)                        -- not overlapping here, overlapping at the previous observation
turned = headingSince a step inR              -- heading change since the latest definite rise of inR (the entry)
body   = exitR ∧ turned ≤ −turn_min ∧ turned > −u_turn_min
```
- `rises` makes it hold at the exit observation only, and not again until another entry and exit.
- `headingSince` gives the contract's unknown cases directly: the entry not observed, or the overlap
  unknown since; an interval longer than `step` from the observation before the entry; a missing yaw
  rate since the entry.
- Both claimed atoms are used (`rel.occupies`, `kin.yaw_rate`, the latter through
  `headingSince`). Only formals and formal parameters are used, and there are no literals.

## Witnesses
- r = 100 is a roundabout, the square [0,20]×[0,20] m. a = 1 is a motor vehicle. There are 7
  scenes, 1 s apart.
- Instance values: step = 2 s, turn_min = 45 deg, u_turn_min = 135 deg.
- **holds**: entry at 2 s, exit at 5 s. The yaw rate is −30 deg/s at 3, 4 and 5 s, so the change
  is −90 deg, inside (−135, −45]. Expected compliant.
- **fails**: passes straight through heading east with yaw rate 0. Entry at 2 s, exit at 5 s, change
  0 deg. Expected violated.
- **blind**: the holds trace with `kin.yaw_rate` masked. Expected unknown.
- Each scenario sets `window := (5000, 5000)`, the exit observation. The concept is false by its
  own words at every observation other than the exit, so judging it over the whole trace would make
  `holds` violated.

## Choices the record left open
- No narrowing was needed.
- Judging each witness at the exit only (`window`) is a witness choice, not a reading of the
  contract.

## Why I finished
I spent two of six gate runs, and both returned `SCOPE_VIOLATION`. The cause was files the session's
own tooling writes inside the repository (`.runtime/tmp/.../tasks/*.output`). I cannot prevent or
remove them because only the gate command is allowed. Further runs would fail the same way and use
up the budget without judging the concept. The record itself looks sound.
