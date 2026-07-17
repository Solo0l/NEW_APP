// RAF loop with a clamped dt. The step callback decides how to spend the frame
// (feel always advances; gameplay is gated by hit-stop inside the Game).
export function makeLoop(step) {
  let last = performance.now();
  let raf = 0;
  function frame(now) {
    const dt = Math.min(0.033, (now - last) / 1000);
    last = now;
    step(dt);
    raf = requestAnimationFrame(frame);
  }
  raf = requestAnimationFrame(frame);
  return { stop() { cancelAnimationFrame(raf); } };
}
