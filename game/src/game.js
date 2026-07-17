import { makeCanvas } from './core/canvas.js';
import { makeBus } from './core/bus.js';
import { makeInput } from './core/input.js';
import { makeLoop } from './core/loop.js';
import { makeArena } from './world/arena.js';
import { makeCamera } from './feel/camera.js';
import { makeParticles } from './feel/particles.js';
import { makeAudio } from './feel/audio.js';
import { makeRenderer } from './render/renderer.js';
import { makeSituationScene } from './scene/situation.js';
import { SITUATION_02 } from './data/situations.js';

// Composition root. Owns nothing gameplay-specific; wires systems and runs the frame.
// Which Situation to load is a data choice (default S02, the current prototype).
export function makeGame(cv, hud, boot, situation = SITUATION_02) {
  const { ctx, size } = makeCanvas(cv);
  const bus = makeBus();
  const camera = makeCamera(bus);
  const particles = makeParticles(bus);
  const audio = makeAudio(bus);
  const arena = makeArena(size);
  const draw = makeRenderer(ctx, size, hud);

  let started = false;

  function begin() { audio.init(); if (!started) { started = true; if (boot) boot.style.display = 'none'; scene.reset(); } cv.focus && cv.focus(); }
  function onPress() { if (!started) { begin(); return; } if (scene.isDead()) scene.restart(); }
  function onKey(k) { if (!started) { begin(); return; } if (scene.isDead() && (k === ' ' || k === 'enter')) scene.restart(); }

  const input = makeInput(cv, { press: onPress, key: onKey });
  const scene = makeSituationScene(situation, bus, arena, input);

  makeLoop((dt) => {
    // feel always advances; gameplay is paused during hit-stop
    camera.update(dt); particles.update(dt); audio.update(dt);
    if (started && !scene.isDead() && camera.freeze <= 0) scene.update(dt);
    if (started) draw(scene.view(), camera, particles);
  });

  return { bus, loadSituation(s) { /* future: scene swap */ } };
}
