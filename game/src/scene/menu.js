// Placeholder main menu. Any input begins the demo.
export function makeMenuScene(ctx, size, hud, { onStart }) {
  let t = 0;
  return {
    enter() { if (hud) hud.innerHTML = ''; },
    press() { onStart(); },
    key() { onStart(); },
    update(dt) { t += dt; },
    draw() {
      const W = size.w, H = size.h;
      ctx.setTransform(1, 0, 0, 1, 0, 0);
      ctx.fillStyle = '#0b0c0f'; ctx.fillRect(0, 0, W, H);
      ctx.textAlign = 'center';
      ctx.fillStyle = '#cfe6ff'; ctx.font = '700 46px ui-monospace,monospace';
      ctx.fillText('CHROMAESCAPE', W / 2, H / 2 - 28);
      ctx.fillStyle = '#5a6a7a'; ctx.font = '13px ui-monospace,monospace';
      ctx.fillText('escape · draw · trap', W / 2, H / 2 + 6);
      ctx.fillStyle = `hsla(190,100%,72%,${0.5 + 0.4 * Math.sin(t * 3)})`; ctx.font = '15px ui-monospace,monospace';
      ctx.fillText('click / tap / press any key to begin', W / 2, H / 2 + 46);
    },
  };
}
