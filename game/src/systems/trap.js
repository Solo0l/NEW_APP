import { CFG } from '../config.js';

// --- geometry helpers (pure) ---
function segInt(a, b, c, d) {
  const r = (p, q, s) => (q.x - p.x) * (s.y - p.y) - (q.y - p.y) * (s.x - p.x);
  const d1 = r(c, d, a), d2 = r(c, d, b), d3 = r(a, b, c), d4 = r(a, b, d);
  return ((d1 > 0) !== (d2 > 0)) && ((d3 > 0) !== (d4 > 0));
}
export function pointInPoly(pt, poly) {
  let n = poly.length, inside = false;
  for (let i = 0, j = n - 1; i < n; j = i++) {
    const xi = poly[i].x, yi = poly[i].y, xj = poly[j].x, yj = poly[j].y;
    if (((yi > pt.y) !== (yj > pt.y)) && (pt.x < (xj - xi) * (pt.y - yi) / (yj - yi) + xi)) inside = !inside;
  }
  return inside;
}

// Trap system: owns the live stroke + the fading trail, detects loop closure,
// and reports how encircled a point is. It knows nothing about who it traps.
export function makeTrap() {
  let stroke = [];
  let trail = [];

  return {
    get stroke() { return stroke; },
    get trail() { return trail; },
    reset() { stroke = []; trail = []; },
    breakStroke() { stroke.length = 0; },
    // is (x,y) touching FRESH trail (age <= maxAge, within r)? drives the snare (control, not damage)
    freshContact(x, y, r, maxAge) {
      const r2 = r * r;
      for (const p of trail) { if (p.age <= maxAge) { const dx = p.x - x, dy = p.y - y; if (dx * dx + dy * dy < r2) return true; } }
      return false;
    },
    update(dt) {
      for (let i = trail.length - 1; i >= 0; i--) { trail[i].age += dt; if (trail[i].age > CFG.TRAIL_LIFE) trail.splice(i, 1); }
    },
    // add a lasso deposit; returns the enclosing polygon if this point closed a loop, else null
    addPoint(x, y) {
      const np = { x, y };
      trail.push({ x, y, age: 0 });
      if (trail.length > CFG.TRAIL_MAX) trail.shift();
      let hit = -1;
      if (stroke.length > CFG.LOOP_MIN) {
        const a = stroke[stroke.length - 1], b = np;
        for (let j = 0; j < stroke.length - CFG.LOOP_MIN; j++) {
          if (Math.hypot(np.x - stroke[j].x, np.y - stroke[j].y) < CFG.LOOP_CLOSE_R) { hit = j; break; }
          if (j > 0 && segInt(a, b, stroke[j - 1], stroke[j])) { hit = j; break; }
        }
      }
      stroke.push(np);
      if (stroke.length > CFG.STROKE_MAX) stroke.shift();
      if (hit >= 0) { const poly = stroke.slice(hit); stroke = []; return poly; }
      return null;
    },
    // how surrounded is (x,y) by the live stroke? returns { cover:0..1, fleeing, gapX, gapY }
    senseEncirclement(x, y) {
      const out = { cover: 0, fleeing: false, gapX: x, gapY: y };
      if (stroke.length <= 10) return out;
      const BINS = CFG.ENC_BINS, R2 = CFG.ENC_R * CFG.ENC_R;
      const cov = new Array(BINS).fill(false);
      let n = 0;
      for (const s of stroke) {
        const ex = s.x - x, ey = s.y - y;
        if (ex * ex + ey * ey < R2) { const b = ((Math.atan2(ey, ex) + Math.PI) / (2 * Math.PI) * BINS | 0) % BINS; if (!cov[b]) { cov[b] = true; n++; } }
      }
      out.cover = n / BINS;
      if (n >= BINS * 0.5) {
        let bestStart = 0, bestLen = 0, curStart = 0, curLen = 0;
        for (let i = 0; i < BINS * 2; i++) {
          if (!cov[i % BINS]) { if (curLen === 0) curStart = i; curLen++; if (curLen > bestLen) { bestLen = Math.min(curLen, BINS); bestStart = curStart; } }
          else curLen = 0;
        }
        if (bestLen > 0 && bestLen < BINS) {
          const ang = (((bestStart + bestLen / 2) % BINS) / BINS) * 2 * Math.PI - Math.PI;
          out.gapX = x + Math.cos(ang) * 300; out.gapY = y + Math.sin(ang) * 300; out.fleeing = true;
        }
      }
      return out;
    },
  };
}
