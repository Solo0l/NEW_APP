# Risks & Technical Debt — modular foundation

## Risk list
1. **Behaviour drift.** The port is hand-verified (geometry unit test + error-free bundle run),
   not pixel-diffed against the prototype. Risk that a subtle constant/order changed feel.
   *Mitigation:* keep the prototype file as the reference; add a side-by-side capture test.
2. **Bundler is hand-ordered.** `build.mjs` strips import/export and concatenates in a fixed
   list. A new file not added to `ORDER`, or a name collision, breaks the build silently.
   *Mitigation:* move to esbuild before the module count grows.
3. **Feel timing during hit-stop.** Heartbeat/panic levels are last-emitted values while gameplay
   is frozen (~90 ms). Acceptable now; revisit if freeze windows lengthen.
4. **DOM coupling.** `main.js` and `renderer` reach for `#c/#hud/#boot` by id. Fine for one
   scene; the Scene Manager (next sprint) should inject these.
5. **Global RNG.** Uses `Math.random`. Deterministic runs (replay/debug) need a seeded RNG
   injected into Mote/Arena — cheap now, expensive after content.

## Technical debt
- Replace `build.mjs` string-strip bundler with **esbuild** (real module graph, minify, sourcemaps).
- Extract render-only mote fields (`squash`, `leanAng`, `freeWiggle`, `trap`) into a small
  `MoteView` so entity state and presentation state are cleanly separated.
- `renderer.js` is one long function ported verbatim; split into `drawTrail/drawMote/drawHUD`.
- No automated test runner yet; unit checks are ad-hoc node scripts. Add a `test/` with a runner.
- Boot/HUD copy is duplicated between `index.html` and `build.mjs` template — single-source it.
- Scene abstraction exists but only `SituationScene`; Menu/Tutorial/Complete + `SceneManager`
  are the next sprint (demo flow).
