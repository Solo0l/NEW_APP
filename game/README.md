# ChromaEscape — modular foundation

Production refactor of the frozen prototype (`ChromaEscape_Situation02_Feinter.html`).
**Architecture only** — behaviour is byte-faithful to the prototype. No gameplay, feel, or
balance changes.

## Run

- **Ship / play:** `node build.mjs` → open `dist/chromaescape_demo.html` (works via `file://`
  and as an Artifact — one self-contained file, zero dependencies).
- **Dev:** serve this folder over http and open `index.html` (ES modules need a server).

## Layout

```
src/
  config.js            global constants (per-Mote tunables live in data/)
  core/     bus  canvas  input  loop          engine, knows nothing about the game
  world/    arena  player                     space + the avatar
  systems/  trap                              lasso geometry: stroke, loop-close, enclosure
  entities/ mote                              ONE generic agent, driven by a MoteConfig
  feel/     audio  particles  camera          bus SUBSCRIBERS — zero gameplay knowledge
  render/   renderer                          pure draw from a read-only view
  scene/    situation                         one data-driven scene runs ANY Situation
  data/     situations                        Situations as data (S01, S02)
  game.js   main.js                           composition root + entry
build.mjs                                     inline modules → dist single file
```

## Dependency direction (inward only)

```
main → game → scene → {player, trap, mote, arena}
                         mote → trap (senseEncirclement), arena
game → {input, camera, particles, audio, renderer} → core
feel (audio/particles/camera) ── subscribe ──▶ bus   (no inbound deps from gameplay)
data/situations ── consumed by ──▶ scene            (leaf)
```

Gameplay **emits** semantic events (`coil`, `hit`, `caught`, `escape`, `panic`, `threat`,
`emptyLoop`); feel modules **subscribe**. Gameplay never calls audio/particles/camera directly.

## Adding a Situation

Add one object to `data/situations.js`. No new scene, AI, or feel code. S01 vs S02 differ
only by `feintChance*`; they run identical code.

See `TECH-DEBT.md` for known debt and the risk list.
