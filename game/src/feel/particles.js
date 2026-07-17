// Particle feel. Subscribes to gameplay events and owns the "what a burst looks like"
// decision. Gameplay only says WHAT happened (caught / escape), never how it looks.
export function makeParticles(bus) {
  const parts = [];
  function burst(x, y, n, hue, spd, life) {
    for (let i = 0; i < n; i++) {
      const a = Math.random() * 6.283, v = spd * (0.35 + Math.random());
      parts.push({ x, y, vx: Math.cos(a) * v, vy: Math.sin(a) * v, life: life * (0.6 + Math.random() * 0.6), t0: life, hue, r: 1.4 + Math.random() * 2.6 });
    }
  }
  bus.on('caught', (e) => { burst(e.x, e.y, 34, 190, 320, 0.6); burst(e.x, e.y, 12, 45, 180, 0.6); });
  bus.on('escape', (e) => { burst(e.x, e.y, 9, 190, 150, 0.45); });
  bus.on('snare', (e) => { burst(e.x, e.y, 10, 190, 90, 0.35); });
  return {
    parts, burst,
    update(dt) { for (let i = parts.length - 1; i >= 0; i--) { const p = parts[i]; p.x += p.vx * dt; p.y += p.vy * dt; p.vx *= 0.9; p.vy *= 0.9; p.life -= dt; if (p.life <= 0) parts.splice(i, 1); } },
    draw(ctx) {
      ctx.globalCompositeOperation = 'lighter';
      for (const p of parts) {
        const k = Math.max(0, p.life / p.t0);
        ctx.beginPath(); ctx.fillStyle = `hsla(${p.hue},100%,62%,${k})`; ctx.shadowBlur = 6 * k; ctx.shadowColor = `hsl(${p.hue},100%,60%)`;
        ctx.arc(p.x, p.y, p.r * k + 0.4, 0, 7); ctx.fill();
      }
      ctx.globalCompositeOperation = 'source-over'; ctx.shadowBlur = 0;
    },
  };
}
