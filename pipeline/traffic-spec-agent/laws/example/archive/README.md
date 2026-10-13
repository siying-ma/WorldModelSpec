# Retired subsets

Kept as they were when retired (2026-10-02), so the runs made on them can be read against their
input. No run uses them any more.

| folder | was | used by | why retired |
|---|---|---|---|
| `demo_v1/` | `example/demo/`: 18 lines of NRS 484B.200–.270 and .413 | `results/demo1` … `demo5` | not self-contained (one line rests on a subsection outside the corpus, another cites statutes outside it); 11 of 18 lines are overtaking or left-side driving; several name vehicle classes and road features few lines use |
| `smoke_v1/` | `example/smoke/`: NRS 484B.257(1) and (2) | `results/smoke1` … `smoke4` | replaced by a two-line subset of the new demo |
| `corpus_2026-09-20/` | the corpus (`full_list/`), its train/test split, the analysis sidecars, the evaluation records and `ATOMS.md` / `ATOMS_train.md` before 2026-10-13 | every run before 2026-10-13 | the corpus was scoped to ordinary urban Las Vegas driving with a vehicle driver as the party judged (23 lines left; NRS 484B.127(1) replaced LVMC 11.12.080(A)) and the split rebuilt; kept so the scope can be revisited |

The `options.json` of those runs still names the old paths (`laws/example/demo/…`,
`laws/example/smoke/…`); read their inputs here.
