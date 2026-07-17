import { CFG } from '../config.js';
import { makePlayer } from '../world/player.js';
import { makeTrap, pointInPoly } from '../systems/trap.js';
import { makeMote } from '../entities/mote.js';

// One generic, data-driven scene. Runs ANY SituationConfig. Adding a Situation adds NO scene code.
// Owns run state (score, timer, death) and loop-closure CONSEQUENCES; emits feel events.
export function makeSituationScene(sit, bus, arena, input) {
  const player = makePlayer(arena);
  const trap = makeTrap();
  const mote = makeMote(sit.mote, bus, arena);
  let caps = 0, tSurv = 0, dead = false, best = 0;
  const fx = [];   // loop-ignite polygons
  const fxT = [];  // floating "CAUGHT" labels

  function reset() {
    player.reset(); trap.reset(); mote.spawn();
    caps = 0; tSurv = 0; dead = false; fx.length = 0; fxT.length = 0;
  }

  // consequences of a closed loop (the "trap" resolution) — feel is emitted, never called
  function resolveLoop(poly) {
    if (poly.length < CFG.LOOP_MIN) return;
    fx.push({ poly, t: 0.6, t0: 0.6 });
    const m = mote.state;
    if (m.stun <= 0 && pointInPoly({ x: m.x, y: m.y }, poly)) {
      caps++;
      player.life = Math.min(CFG.MAX_LIFE, player.life + CFG.HEAL);
      bus.emit('caught', { x: m.x, y: m.y, streak: caps });
      fxT.push({ x: m.x, y: m.y - 20, txt: 'CAUGHT ×' + caps, t: 1.0, t0: 1.0 });
      m.stun = 1.3;
      const f = arena.fling(m.x); m.x = f.x; m.y = f.y;
    } else {
      bus.emit('emptyLoop', {});
    }
  }

  function update(dt) {
    tSurv += dt;
    const intent = input.moveVector(player.x, player.y);
    player.update(dt, intent);
    if (intent.moving) {
      if (player.maybeDrop()) { const poly = trap.addPoint(player.x, player.y); if (poly) resolveLoop(poly); }
      player.idleT = 0;
    } else {
      player.idleT += dt; if (player.idleT > CFG.IDLE_BREAK) trap.breakStroke();
    }
    trap.update(dt);
    mote.update(dt, { player, trap, caps });
    for (let i = fx.length - 1; i >= 0; i--) { fx[i].t -= dt; if (fx[i].t <= 0) fx.splice(i, 1); }
    for (let i = fxT.length - 1; i >= 0; i--) { fxT[i].t -= dt; fxT[i].y -= 20 * dt; if (fxT[i].t <= 0) fxT.splice(i, 1); }
    if (player.life <= 0) { player.life = 0; dead = true; best = Math.max(best, caps); }
  }

  return {
    reset,
    restart: reset,
    update,
    isDead() { return dead; },
    // read-only snapshot for the renderer
    view() { return { player, mote, trap, fx, fxT, get caps() { return caps; }, get tSurv() { return tSurv; }, get dead() { return dead; }, get best() { return best; }, get life() { return player.life; } }; },
  };
}
