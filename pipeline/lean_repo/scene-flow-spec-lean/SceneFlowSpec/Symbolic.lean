/-
  SceneFlowSpec.Symbolic
  SceneFlowLang-style symbolic grounding of property schemas onto the entities
  discovered in a concrete trace.

  NOTE: This is a TEMPORARY STUB to restore the build. The original file was
  referenced by `Examples.lean` (`import SceneFlowSpec.Symbolic`) and by the
  Python adapter (`sceneFlowLangProperties` / `sceneFlowLangEgoProperties`) but
  was never committed to git, so the published repo does not build without it.

  The real all-vehicle / ego-only grounding is Step 4 of the B2 plan
  ("Reconstruct the symbolic binder"). For Step 0 we only need the module to
  exist and expose the two builder signatures so `Examples.lean` and the
  generated trace compile and the boolean pipeline runs end-to-end.

  Dependency note: `Examples.lean` imports THIS module, so this module must NOT
  import `Examples`. Importing `Monitor` transitively brings in
  Scene / Formula / Semantics (and `Trace`, `NamedProperty`).
-/
import SceneFlowSpec.Monitor

namespace SceneFlowSpec

/-- Ground the SceneFlowLang property schemas on every vehicle binding found in
    the trace. STUB: returns no properties yet (see Step 4). -/
def sceneFlowLangProperties (_τ : Trace) : List NamedProperty := []

/-- Ego-only grounding variant (bindings restricted to the entity named `ego`).
    STUB: returns no properties yet (see Step 4). -/
def sceneFlowLangEgoProperties (_τ : Trace) : List NamedProperty := []

end SceneFlowSpec
