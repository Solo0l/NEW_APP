import { CFG } from '../config.js';

// The Mote is ONE generic agent. All behaviour differences between Situations come from
// its config (mc), never from forked code. It emits semantic events; feel modules react.
// Behaviour ported verbatim from Situation02 (Sprinter locomotion + flee-to-gap + Feinter + panic).
export function makeMote(mc, bus, arena) {
  const s = {
    x: 0, y: 0, vx: 0, vy: 0, stun: 0,
    tx: 0, ty: 0, fleeing: false, fledT: 0,
    phase: 'rest', phaseT: 0, squash: 1,
    feint: false, leanAng: 0,
    trap: 0, trapTarget: 0, wasHigh: false, freeWiggle: 0,
  };

  const radius = (caps) => mc.rBase + Math.min(caps, 12) * mc.rGrow;
  const speed = (caps) => mc.speed0 + caps * mc.speedPer;

  function spawn() {
    const p = arena.spawnMote();
    s.x = p.x; s.y = p.y; s.vx = 0; s.vy = 0; s.stun = 0;
    s.phase = 'rest'; s.phaseT = 0; s.squash = 1; s.feint = false; s.leanAng = 0;
    s.trap = 0; s.trapTarget = 0; s.wasHigh = false; s.freeWiggle = 0; s.fledT = 0;
    bus.emit('spawn', { x: s.x, y: s.y });
  }

  function update(dt, world) {
    const { player, trap, caps } = world;

    if (s.stun > 0) { s.stun -= dt; s.fleeing = false; s.trapTarget = 0; }
    else {
      let tx = player.x, ty = player.y, fleeing = false, cover = 0;
      const enc = trap.senseEncirclement(s.x, s.y);
      cover = enc.cover;
      if (mc.fleeEnabled && enc.fleeing) { tx = enc.gapX; ty = enc.gapY; fleeing = true; }
      s.tx = tx; s.ty = ty; s.fleeing = fleeing; s.trapTarget = cover;
      s.fledT = fleeing ? 0.25 : Math.max(0, s.fledT - dt);

      // SPRINTER locomotion: rest -> coil (telegraph) -> burst
      s.phaseT -= dt;
      if (s.phaseT <= 0) {
        if (s.phase === 'coil') { s.phase = 'burst'; s.phaseT = mc.burstT; }
        else if (s.phase === 'burst') { s.phase = 'rest'; s.phaseT = mc.restT * Math.max(0.6, 1 - caps * 0.03); }
        else {
          s.phase = 'coil'; s.phaseT = mc.coilT;
          // FEINTER: the body may lean a lie; the eye (tx/ty) always tells the truth
          const trueAng = Math.atan2(ty - s.y, tx - s.x);
          s.feint = Math.random() < (fleeing ? mc.feintChanceFlee : mc.feintChanceHunt);
          s.leanAng = s.feint ? trueAng + (Math.random() < 0.5 ? -1 : 1) * (1.9 + Math.random() * 0.7) : trueAng;
          bus.emit('coil', { feint: s.feint });
        }
      }
      let sp;
      if (s.phase === 'burst') sp = (mc.burstSpeed + caps * 22) * (fleeing ? 1.12 : 1);
      else if (s.phase === 'coil') sp = 0;
      else sp = mc.restCreep;
      s.squash = s.phase === 'coil' ? 0.66 : 1;
      const mvx = tx - s.x, mvy = ty - s.y, md = Math.hypot(mvx, mvy) || 1;
      const px = s.x, py = s.y;
      s.x += mvx / md * sp * dt; s.y += mvy / md * sp * dt; s.vx = s.x - px; s.vy = s.y - py;
      if (Math.hypot(s.x - player.x, s.y - player.y) < 24 + radius(caps) * 0.3) {
        player.life -= mc.drain * dt; bus.emit('hit', {});
      }
    }

    // PANIC (feel only): the more surrounded, the harder it struggles / the higher it cries
    s.trap = s.trap + (s.trapTarget - s.trap) * Math.min(1, dt * 9);
    bus.emit('panic', { level: s.stun > 0 ? 0 : s.trap });

    // IT BROKE FREE: latch "nearly caught", fire once on breakout -> "it got away!"
    if (s.trap > 0.62) s.wasHigh = true;
    if (s.stun > 0) s.wasHigh = false;
    if (s.stun <= 0 && s.wasHigh && s.trap < 0.4) {
      if (s.fledT > 0) { bus.emit('escape', { x: s.x, y: s.y }); s.freeWiggle = 0.35; }
      s.wasHigh = false;
    }
    if (s.freeWiggle > 0) s.freeWiggle -= dt;

    // threat drives the heartbeat (silence when stunned or far)
    let threat = -1;
    if (s.stun <= 0) { const d = Math.hypot(s.x - player.x, s.y - player.y); if (d <= CFG.DANGER) threat = 1 - d / CFG.DANGER; }
    bus.emit('threat', { level: threat });
  }

  return { state: s, spawn, update, radius, speed, coilT: mc.coilT };
}
