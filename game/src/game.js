import { makeCanvas } from './core/canvas.js';
import { makeBus } from './core/bus.js';
import { makeInput } from './core/input.js';
import { makeLoop } from './core/loop.js';
import { makeArena } from './world/arena.js';
import { makeCamera } from './feel/camera.js';
import { makeParticles } from './feel/particles.js';
import { makeAudio } from './feel/audio.js';
import { makeRenderer } from './render/renderer.js';
import { makeFlow } from './scene/flow.js';

// Composition root. Wires systems + feel, then runs the demo flow through a scene manager.
export function makeGame(cv, hud, boot) {
  const { ctx, size } = makeCanvas(cv);
  const bus = makeBus();
  const camera = makeCamera(bus);
  const particles = makeParticles(bus);
  const audio = makeAudio(bus);
  const arena = makeArena(size);
  const renderer = makeRenderer(ctx, size, hud);
  if (boot) boot.style.display = 'none'; // the menu scene is the start screen now

  let mgr; // forward ref: input handlers dispatch to the current scene
  const input = makeInput(cv, {
    press: () => { audio.init(); mgr.press(); },
    key: (k) => { audio.init(); mgr.key(k); },
  });
  mgr = makeFlow({ ctx, size, hud, bus, arena, input, renderer, camera, particles });

  makeLoop((dt) => {
    camera.update(dt); particles.update(dt); audio.update(dt);
    if (camera.freeze <= 0) mgr.update(dt); // hit-stop pauses gameplay; menus never freeze
    mgr.draw();
  });

  return { bus };
}
