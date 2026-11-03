# verifier_tools

Building verifier packages and testing the explainer. Nothing here is delivered; the packages, their
template and the evaluation guide are in `../verifier/`.

| path | what it is |
|---|---|
| `make_package.py` | `python3 make_package.py <run> [--out DIR] [--no-build] [--tar]`: a self-contained verifier package from one pipeline run (its rules, concepts and reading, the full split's Core, the monitor, the explainer, and `../verifier/template/`). |
| `lean_src/Explain.lean` | A link to `../verifier/smoke25/lean/Explain.lean`, the one source of the explainer; the builder copies the file it points to. |
| `tests/run_tests.sh` | The explainer's and the verifier's checks on a delivered package (default `../verifier/smoke25`), which is only read: it is copied to `$WORK` and built there. Lean checks on the packaged rules' witness scenarios, hand-built windows and the design review's counter-examples; Python checks on recorded cases (`$CASES`). |

The builder copies `Main.lean` (the monitor) from the pipeline library. The delivered `smoke25`
package holds a newer `Main.lean`, which registers the rules a selected rule composes; until the
library's copy is updated, a package built again differs from `smoke25` in that file.
