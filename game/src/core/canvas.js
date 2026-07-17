// Canvas ownership: context, size, resize. Knows nothing about the game.
export function makeCanvas(cv) {
  const ctx = cv.getContext('2d');
  const size = { w: 0, h: 0 };
  function resize() { size.w = cv.width = cv.clientWidth || innerWidth; size.h = cv.height = cv.clientHeight || innerHeight; }
  addEventListener('resize', resize);
  resize();
  return { cv, ctx, size, resize };
}
