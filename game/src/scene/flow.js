import { makeSceneManager } from './manager.js';
import { makeMenuScene } from './menu.js';
import { makeCompleteScene } from './complete.js';
import { makeSituationScene } from './situation.js';
import { DEMO_SITUATIONS } from '../data/situations.js';

// The demo spine: menu -> [situations...] -> complete -> (loop to menu).
// Placeholder skeleton; each station is polished later. Pure sequencing, no new mechanics.
export function makeFlow(deps) {
  const { ctx, size, hud, bus, arena, input, renderer, camera, particles } = deps;
  const mgr = makeSceneManager();
  const N = DEMO_SITUATIONS.length;
  let step = -1;

  function build(i) {
    if (i === 0) return makeMenuScene(ctx, size, hud, { onStart: advance });
    if (i <= N) return makeSituationScene(DEMO_SITUATIONS[i - 1], bus, arena, input, { onWin: advance, renderer, camera, particles });
    return makeCompleteScene(ctx, size, hud, { onStart: restart });
  }
  function advance() { step++; mgr.set(build(step)); }
  function restart() { step = -1; advance(); }

  advance(); // -> menu
  return mgr;
}
