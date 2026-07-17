// Input: raw keyboard + pointer -> a normalized movement intent. No gameplay knowledge.
// Press/key callbacks let the Game decide start/restart based on its own state.
export function makeInput(cv, handlers = {}) {
  const keys = {};
  let touch = null;
  addEventListener('keydown', (e) => {
    if (['ArrowUp', 'ArrowDown', 'ArrowLeft', 'ArrowRight', ' '].includes(e.key)) e.preventDefault();
    keys[e.key.toLowerCase()] = true;
    handlers.key && handlers.key(e.key.toLowerCase());
  });
  addEventListener('keyup', (e) => { keys[e.key.toLowerCase()] = false; });
  cv.addEventListener('pointerdown', (e) => { handlers.press && handlers.press(); touch = { x: e.clientX, y: e.clientY }; });
  cv.addEventListener('pointermove', (e) => { if (touch) touch = { x: e.clientX, y: e.clientY }; });
  cv.addEventListener('pointerup', () => { touch = null; });

  return {
    keys,
    get touch() { return touch; },
    clearTouch() { touch = null; },
    // returns {x,y,moving} — a unit vector toward the desired heading, or moving:false
    moveVector(px, py) {
      let dx = 0, dy = 0;
      if (keys['w'] || keys['arrowup']) dy -= 1;
      if (keys['s'] || keys['arrowdown']) dy += 1;
      if (keys['a'] || keys['arrowleft']) dx -= 1;
      if (keys['d'] || keys['arrowright']) dx += 1;
      if (touch) { const vx = touch.x - px, vy = touch.y - py, d = Math.hypot(vx, vy); if (d > 6) { dx = vx / d; dy = vy / d; } }
      const m = Math.hypot(dx, dy);
      if (m > 0.01) return { x: dx / m, y: dy / m, moving: true };
      return { x: 0, y: 0, moving: false };
    },
  };
}
