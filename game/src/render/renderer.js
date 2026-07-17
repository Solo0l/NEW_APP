import { CFG } from '../config.js';

// Pure presentation. Draws the world from a read-only view; contains no gameplay logic.
// Ported verbatim from Situation02 draw(); only variable sources changed.
export function makeRenderer(ctx, size, hud) {
  const HUE = CFG.HUE, MAX = CFG.MAX_LIFE;

  return function draw(view, camera, particles) {
    const W = size.w, H = size.h;
    const player = view.player, m = view.mote.state, caps = view.caps, tSurv = view.tSurv, dead = view.dead;
    const baseR = view.mote.radius(caps);
    const trail = view.trap.trail, stroke = view.trap.stroke, fx = view.fx, fxT = view.fxT;
    const shake = camera.shake;
    const lf = Math.max(0, view.life / MAX);

    ctx.setTransform(1, 0, 0, 1, 0, 0);
    ctx.fillStyle = '#0b0c0f'; ctx.fillRect(0, 0, W, H);
    ctx.save();
    if (shake > 0) ctx.translate((Math.random() * 2 - 1) * shake, (Math.random() * 2 - 1) * shake);

    // faded trail
    ctx.globalCompositeOperation = 'lighter';
    for (const p of trail) { const a = Math.max(0, 1 - p.age / CFG.TRAIL_LIFE) * 0.5; ctx.beginPath(); ctx.fillStyle = `hsla(${HUE},100%,60%,${a})`; ctx.arc(p.x, p.y, 3.2, 0, 7); ctx.fill(); }
    // live lasso
    if (stroke.length > 1) {
      ctx.strokeStyle = `hsla(${HUE},100%,72%,0.9)`; ctx.lineWidth = 3.5; ctx.shadowBlur = 12; ctx.shadowColor = `hsl(${HUE},100%,60%)`;
      ctx.beginPath(); ctx.moveTo(stroke[0].x, stroke[0].y); for (const s of stroke) ctx.lineTo(s.x, s.y); ctx.stroke(); ctx.shadowBlur = 0;
    }
    ctx.globalCompositeOperation = 'source-over';

    // loop-catch flashes
    for (const f of fx) {
      const k = f.t / f.t0; ctx.beginPath(); ctx.moveTo(f.poly[0].x, f.poly[0].y);
      for (const p of f.poly) ctx.lineTo(p.x, p.y); ctx.closePath();
      ctx.fillStyle = `hsla(${HUE},100%,70%,${0.3 * k})`; ctx.fill();
      ctx.strokeStyle = `hsla(${HUE},100%,82%,${0.9 * k})`; ctx.lineWidth = 3; ctx.stroke();
    }

    // MOTE
    {
      const caught = m.stun > 0, tp = m.trap || 0;
      ctx.save();
      let ox = 0, oy = 0;
      if (!caught && (tp > 0.35 || m.freeWiggle > 0)) { const j = tp * tp * 6 + (m.freeWiggle > 0 ? 4 : 0); ox += (Math.random() * 2 - 1) * j; oy += (Math.random() * 2 - 1) * j; }
      if (!caught && m.phase === 'coil') { const amt = 15 * (1 - (m.phaseT || 0) / view.mote.coilT); ox += Math.cos(m.leanAng || 0) * amt; oy += Math.sin(m.leanAng || 0) * amt; }
      if (ox || oy) ctx.translate(ox, oy);
      const spd = Math.hypot(m.vx || 0, m.vy || 0), ang = Math.atan2(m.vy || 0, (m.vx || 0.0001));
      let stretch = caught ? 0 : Math.min(0.5, spd * 0.02);
      const breathe = 1 + 0.05 * Math.sin(tSurv * (caught ? 3 : 11));
      const rHue = caught ? 210 : Math.max(0, 340 - caps * 6);
      if ((spd > 3.4 || caps > 4) && !caught) {
        ctx.globalCompositeOperation = 'lighter';
        for (let k = 1; k <= 2; k++) { ctx.beginPath(); ctx.fillStyle = `hsla(${rHue},90%,50%,${0.10 / k})`; ctx.arc(m.x - (m.vx || 0) * k * 1.6, m.y - (m.vy || 0) * k * 1.6, baseR * (1 - 0.12 * k), 0, 7); ctx.fill(); }
        ctx.globalCompositeOperation = 'source-over';
      }
      const sq = caught ? 1 : (m.squash || 1);
      ctx.save(); ctx.translate(m.x, m.y); ctx.rotate(ang); ctx.scale((1 + stretch) * breathe * sq, (1 - stretch * 0.55) * breathe * sq);
      ctx.fillStyle = caught ? '#20242c' : '#080709'; ctx.beginPath(); ctx.arc(0, 0, baseR, 0, 7); ctx.fill(); ctx.restore();
      if (!caught && m.phase === 'coil') {
        const k = Math.max(0, (m.phaseT || 0) / view.mote.coilT);
        ctx.strokeStyle = `hsla(45,100%,70%,${0.8 * (1 - k) + 0.2})`; ctx.lineWidth = 2.5; ctx.shadowBlur = 12; ctx.shadowColor = 'hsl(45,100%,60%)';
        ctx.beginPath(); ctx.arc(m.x, m.y, baseR + 4 + k * 16, 0, 7); ctx.stroke(); ctx.shadowBlur = 0;
      }
      ctx.lineWidth = 2; ctx.strokeStyle = `hsla(${rHue},${caught ? 10 : 85}%,60%,${0.5 + 0.25 * Math.sin(tSurv * (caught ? 2 : 10))})`;
      ctx.shadowBlur = caps > 4 && !caught ? 14 : 0; ctx.shadowColor = `hsl(${rHue},85%,55%)`;
      ctx.beginPath(); ctx.arc(m.x, m.y, baseR + 3, 0, 7); ctx.stroke(); ctx.shadowBlur = 0;
      if (!caught && m.snareT > 0) { // SNARED — controlled by your trail; your window to loop it
        ctx.strokeStyle = `hsla(190,100%,78%,${0.55 + 0.4 * Math.sin(tSurv * 18)})`; ctx.lineWidth = 3;
        ctx.shadowBlur = 12; ctx.shadowColor = 'hsl(190,100%,60%)';
        ctx.beginPath(); ctx.arc(m.x, m.y, baseR + 8, 0, 7); ctx.stroke(); ctx.shadowBlur = 0;
        for (let a = 0; a < 4; a++) { const ang = a * Math.PI / 2 + tSurv * 2; ctx.beginPath(); ctx.moveTo(m.x + Math.cos(ang) * (baseR + 4), m.y + Math.sin(ang) * (baseR + 4)); ctx.lineTo(m.x + Math.cos(ang) * (baseR + 13), m.y + Math.sin(ang) * (baseR + 13)); ctx.stroke(); }
      }
      if (caught) {
        ctx.strokeStyle = '#8899aa'; ctx.lineWidth = 2;
        ctx.beginPath(); ctx.moveTo(m.x - 5, m.y - 5); ctx.lineTo(m.x + 5, m.y + 5); ctx.moveTo(m.x + 5, m.y - 5); ctx.lineTo(m.x - 5, m.y + 5); ctx.stroke();
      } else {
        const eD = Math.atan2((m.ty || m.y) - m.y, (m.tx || m.x) - m.x), pr = baseR * (0.42 + 0.34 * tp);
        const eyeOff = baseR * (m.phase === 'coil' ? 0.52 : 0.26);
        const ex = m.x + Math.cos(eD) * eyeOff, ey = m.y + Math.sin(eD) * eyeOff, ec = (m.fleeing || tp > 0.4 || m.phase === 'coil') ? '#ffffff' : `hsl(${rHue},100%,62%)`;
        ctx.beginPath(); ctx.fillStyle = ec; ctx.shadowBlur = 10 + tp * 10; ctx.shadowColor = ec; ctx.arc(ex, ey, pr, 0, 7); ctx.fill(); ctx.shadowBlur = 0;
        ctx.beginPath(); ctx.fillStyle = 'rgba(255,255,255,.85)'; ctx.arc(ex - pr * 0.3, ey - pr * 0.3, pr * 0.28, 0, 7); ctx.fill();
      }
      ctx.restore();
    }

    // player
    if (!dead) {
      const r = 13; ctx.globalCompositeOperation = 'lighter';
      ctx.beginPath(); ctx.fillStyle = `hsl(${HUE},100%,70%)`; ctx.shadowBlur = 22; ctx.shadowColor = `hsl(${HUE},100%,65%)`;
      ctx.arc(player.x, player.y, r, 0, 7); ctx.fill(); ctx.globalCompositeOperation = 'source-over'; ctx.shadowBlur = 0;
    }

    particles.draw(ctx);
    for (const t of fxT) { const k = t.t / t.t0; ctx.textAlign = 'center'; ctx.fillStyle = `hsla(${HUE},100%,85%,${k})`; ctx.font = '700 20px ui-monospace,monospace'; ctx.fillText(t.txt, t.x, t.y); }
    ctx.restore();

    ctx.fillStyle = `rgba(80,6,10,${(1 - lf) * 0.5})`; ctx.fillRect(0, 0, W, H);
    if (dead) {
      ctx.fillStyle = 'rgba(0,0,0,0.6)'; ctx.fillRect(0, 0, W, H); ctx.textAlign = 'center';
      ctx.fillStyle = '#cfe6ff'; ctx.font = '600 36px ui-monospace,monospace'; ctx.fillText('caught ' + caps, W / 2, H / 2 - 24);
      ctx.font = '15px ui-monospace,monospace'; ctx.fillStyle = '#7f93a8'; ctx.fillText(`survived ${tSurv.toFixed(1)}s   ·   best ${view.best}`, W / 2, H / 2 + 8);
      ctx.fillStyle = '#9fd8ff'; ctx.fillText('press SPACE / tap to try again', W / 2, H / 2 + 40);
    }
    if (hud) hud.innerHTML = dead ? '' : `caught <b>${caps}</b>${view.goal ? ' / ' + view.goal : ''} · life <i>${Math.ceil(view.life)}</i><br>circle the mote to trap it`;
  };
}
