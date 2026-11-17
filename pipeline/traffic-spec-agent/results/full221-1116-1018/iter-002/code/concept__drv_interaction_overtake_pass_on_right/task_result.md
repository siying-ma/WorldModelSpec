# drv.interaction.overtake_pass_on_right — task result

## Final verdict
**UNEXPRESSED**: one `no_atom` declaration, on the span "with their headings aligned within same_dir_cos".

## Gate runs
1. **UNEXPRESSED**. I declared the `no_atom` narrowing and documented the gap in the concept file's header. The body is still `.tt` and the witness file is unchanged. The procedure says to stop once a gap is declared, so I made no other changes.

## The gap (the record is incomplete)
The recognition requires that b be on a's left "at every observation since the act began at which the two are side by side". The act begins "at the last observation of the window behind at which b was ahead of a with their headings aligned within same_dir_cos". To find that onset, the body has to read whether a's and b's headings were aligned at past observations.

The record claims three names, and none of them gives that:
- `rel.bearing` gives b's direction in a's frame, so it can tell ahead/behind and the side, but not heading alignment.
- `rel.longitudinal_overlap` only tells whether the two are side by side.
- `drv.interaction.overtake_pass` holds only at the recognition and does not expose its onset or the alignment.

`rel.same_direction` would provide the alignment, but the record does not claim it.

The only bodies I could write with the claimed names approximate the onset:
- **Counting from the last observation at which b was ahead** (any alignment) is weaker than the contract. It misses side-by-side observations, with b on the right, that fall between the aligned onset and a later observation where b is ahead but not aligned.
- **Counting from the last observation at which b was behind** is stronger than the contract. It also reads side-by-side observations before the onset, for example a that had dropped back alongside b on the right before the pass began.

Both would be readings written around a missing atom, not narrowings, so I did not write either.

## What the plan agent must change
Pick one:
- **Claim `rel.same_direction`** with an element for "with their headings aligned within same_dir_cos". Together with `rel.bearing`'s longitudinal component and `rel.longitudinal_overlap` < 0 for "b was ahead of a", the body could then mark the onset exactly. The recognition would be:

  `overtake_pass ∧ left ∧ since (sideBySide → left) aheadAligned`
- **Reword the onset** in terms the claimed names state, such as "since b was last ahead of a". That changes the contract, so it is the plan's decision to make.

The `blind` narrative also needs a correction. It says that masking `rel.bearing` hides the order of the two road users. In fact `drv.interaction.overtake_pass` reads the order from `kin.position`/`kin.heading`, so masking `rel.bearing` hides only the side.

## Choices left open
None taken. The one open point is the gap above, and I declared it rather than resolving it.

## Why I finished
The contract's onset cannot be written exactly with the names the record claims. The rules say to declare that gap (`no_atom`) and go no further rather than approximate it. The gate returned UNEXPRESSED, which sends the concept to re-planning.
