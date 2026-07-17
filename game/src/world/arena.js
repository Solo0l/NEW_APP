// Arena = SPACE only: bounds, spawn points, clamping, fling-out targets.
// Knows nothing about Mote AI or Situations. Future obstacles/walls live here.
export function makeArena(size) {
  return {
    get w() { return size.w; },
    get h() { return size.h; },
    center() { return { x: size.w / 2, y: size.h / 2 }; },
    clamp(p) { p.x = Math.max(0, Math.min(size.w, p.x)); p.y = Math.max(0, Math.min(size.h, p.y)); },
    spawnMote() { return { x: Math.random() < 0.5 ? -40 : size.w + 40, y: Math.random() * size.h }; },
    fling(fromX) { return { x: fromX < size.w / 2 ? -50 : size.w + 50, y: Math.random() * size.h }; },
  };
}
