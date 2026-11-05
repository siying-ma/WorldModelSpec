# verifier_tools

Building verifier packages and testing the explainer. Nothing here is delivered; the packages, their
template and the evaluation guide are in `../verifier/`.

| path | what it is |
|---|---|
| `make_package.py` | `python3 make_package.py <run> [--out DIR] [--no-build] [--tar]`: a self-contained verifier package from one pipeline run (its rules, concepts and reading, the full split's Core, the monitor and the explainer from the library, and `../verifier/template/`). |
| `tests/run_tests.sh` | The explainer's and the verifier's checks on a delivered package (default `../verifier/smoke25`), which is only read: it is copied to `$WORK` and built there. Lean checks on the packaged rules' witness scenarios, hand-built windows and the design review's counter-examples; Python checks on recorded cases (`$CASES`). |

The builder copies the monitor (`Main.lean`) and the explainer (`Explain.lean`) from the pipeline
library (`../../traffic-spec-agent/library/`), their one source; a package holds copies.
