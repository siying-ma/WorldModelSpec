"""Traffic-law verifier: given a trace in the Core JSON format, report which formalized laws it
violates. `verify` is the whole API; `python -m traffic_verifier` and the `verify` script wrap it."""
from .core import verify, laws, VerifierError

__all__ = ["verify", "laws", "VerifierError"]
