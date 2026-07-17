// Global, situation-independent constants. Per-Mote tunables live in data/situations.js.
// Values ported verbatim from ChromaEscape_Situation02_Feinter — do not retune here (architecture only).
export const CFG = {
  MAX_LIFE: 100,
  START_LIFE: 100,
  SPEED: 300,          // player px/s
  TRAIL_LIFE: 2.6,     // seconds a lasso trail point lasts
  DROP_SPACING: 9,     // px between lasso deposits
  HEAL: 22,            // life regained per catch
  HUE: 190,            // player / lasso hue
  LOOP_MIN: 12,        // min stroke points before a loop can close
  LOOP_CLOSE_R: 17,    // px proximity that closes a loop
  STROKE_MAX: 280,     // max live-stroke length
  TRAIL_MAX: 2000,     // max fading-trail points
  ENC_R: 230,          // encirclement sense radius (mote)
  ENC_BINS: 16,        // angular bins for encirclement
  DANGER: 205,         // heartbeat danger radius
  IDLE_BREAK: 0.28,    // s of no-move before the stroke resets
};
