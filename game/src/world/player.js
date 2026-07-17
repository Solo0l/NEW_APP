import { CFG } from '../config.js';

// Player = movement + life + lasso-emission bookkeeping. No trap geometry (that's systems/trap.js).
export function makePlayer(arena) {
  const c = arena.center();
  return {
    x: c.x, y: c.y,
    life: CFG.START_LIFE,
    ldx: c.x, ldy: c.y, // last lasso drop position
    idleT: 0,
    reset() { const cc = arena.center(); this.x = cc.x; this.y = cc.y; this.life = CFG.START_LIFE; this.ldx = cc.x; this.ldy = cc.y; this.idleT = 0; },
    update(dt, intent) {
      if (intent.moving) {
        this.x += intent.x * CFG.SPEED * dt;
        this.y += intent.y * CFG.SPEED * dt;
        arena.clamp(this);
      }
    },
    // true once the player has travelled DROP_SPACING since the last lasso deposit
    maybeDrop() {
      const dd = Math.hypot(this.x - this.ldx, this.y - this.ldy);
      if (dd >= CFG.DROP_SPACING) { this.ldx = this.x; this.ldy = this.y; return true; }
      return false;
    },
  };
}
