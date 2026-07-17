// Placeholder end screen. Any input loops back to the menu.
export function makeCompleteScene(ctx, size, hud, { onStart }) {
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
      ctx.fillStyle = '#cfe6ff'; ctx.font = '700 40px ui-monospace,monospace';
      ctx.fillText('DEMO COMPLETE', W / 2, H / 2 - 20);
      ctx.fillStyle = '#7f93a8'; ctx.font = '15px ui-monospace,monospace';
      ctx.fillText('you became the hunter', W / 2, H / 2 + 14);
      ctx.fillStyle = `hsla(190,100%,72%,${0.5 + 0.4 * Math.sin(t * 3)})`;
      ctx.fillText('press / tap to return to the menu', W / 2, H / 2 + 46);
    },
  };
}
