// Audio feel. Subscribes to gameplay events; owns all synthesis and the heartbeat/panic cadence.
// Philosophy preserved: silence baseline; sound marks change. All tones ported verbatim.
export function makeAudio(bus) {
  let AC = null, master = null, on = false;
  const cd = {};                 // one-shot throttles
  let threat = -1, panicLvl = 0; // per-frame levels pushed by events
  let heartT = 0, squeakT = 0;   // cadence timers owned here (moved out of gameplay)

  function init() {
    if (on) return;
    try {
      AC = new (window.AudioContext || window.webkitAudioContext)();
      if (AC.state === 'suspended') AC.resume();
      master = AC.createGain(); master.gain.value = 0.9; master.connect(AC.destination);
      on = true;
    } catch (e) { /* audio unavailable */ }
  }
  const env = (t, f0, f1, pk, dur) => {
    const o = AC.createOscillator(), g = AC.createGain(); o.connect(g); g.connect(master); o.type = t;
    o.frequency.setValueAtTime(f0, AC.currentTime); o.frequency.exponentialRampToValueAtTime(f1, AC.currentTime + dur);
    g.gain.setValueAtTime(pk, AC.currentTime); g.gain.exponentialRampToValueAtTime(0.001, AC.currentTime + dur);
    o.start(); o.stop(AC.currentTime + dur + 0.02);
  };
  function trapTone(streak) {
    if (!on) return; const now = AC.currentTime, m = 1 + Math.min(streak, 12) * 0.06;
    const o = AC.createOscillator(), g = AC.createGain(); o.type = 'triangle'; o.connect(g); g.connect(master);
    o.frequency.setValueAtTime(240 * m, now); o.frequency.exponentialRampToValueAtTime(720 * m, now + 0.34);
    g.gain.setValueAtTime(0.24, now); g.gain.exponentialRampToValueAtTime(0.001, now + 0.36); o.start(now); o.stop(now + 0.38);
    const o2 = AC.createOscillator(), g2 = AC.createGain(); o2.type = 'sine'; o2.connect(g2); g2.connect(master);
    o2.frequency.setValueAtTime(180, now); o2.frequency.exponentialRampToValueAtTime(40, now + 0.24);
    g2.gain.setValueAtTime(0.34, now); g2.gain.exponentialRampToValueAtTime(0.001, now + 0.28); o2.start(now); o2.stop(now + 0.3);
  }
  function sfxHit() { const t = performance.now(); if (cd.hit && t - cd.hit < 120) return; cd.hit = t; if (on) env('square', 72, 46, 0.22, 0.13); }
  function sfxCoil() { if (on) env('triangle', 320, 560, 0.05, 0.12); }
  function squeak(p) { if (!on) return; const now = AC.currentTime, o = AC.createOscillator(), g = AC.createGain(); o.type = 'sawtooth'; o.connect(g); g.connect(master); const f = 680 + p * 880; o.frequency.setValueAtTime(f, now); o.frequency.linearRampToValueAtTime(f * 1.14, now + 0.05); o.frequency.linearRampToValueAtTime(f * 0.9, now + 0.1); g.gain.setValueAtTime(0.045 + p * 0.05, now); g.gain.exponentialRampToValueAtTime(0.001, now + 0.11); o.start(now); o.stop(now + 0.12); }
  function gasp() { if (on) env('sine', 920, 280, 0.12, 0.26); }
  function snareTone() { if (on) env('triangle', 220, 380, 0.10, 0.09); } // soft snap — enemy rooted
  function heartbeat(vol) {
    if (!on) return; const now = AC.currentTime;
    const mk = (at, f, v) => { const o = AC.createOscillator(), g = AC.createGain(); o.type = 'sine'; o.frequency.setValueAtTime(f, at); o.frequency.exponentialRampToValueAtTime(f * 0.6, at + 0.12); g.gain.setValueAtTime(v, at); g.gain.exponentialRampToValueAtTime(0.001, at + 0.15); o.connect(g); g.connect(master); o.start(at); o.stop(at + 0.17); };
    mk(now, 60, vol); mk(now + 0.15, 50, vol * 0.65);
  }

  bus.on('coil', () => sfxCoil());
  bus.on('hit', () => sfxHit());
  bus.on('caught', (e) => trapTone(e.streak));
  bus.on('emptyLoop', () => trapTone(0));
  bus.on('escape', () => gasp());
  bus.on('snare', () => snareTone());
  bus.on('threat', (e) => { threat = e.level; });
  bus.on('panic', (e) => { panicLvl = e.level; });

  return {
    init,
    update(dt) {
      if (on && threat >= 0) { heartT -= dt; if (heartT <= 0) { heartT = 0.72 - threat * 0.44; heartbeat(0.05 + threat * 0.09); } }
      else heartT = 0;
      if (on && panicLvl > 0.42) { squeakT -= dt; if (squeakT <= 0) { squeak(panicLvl); squeakT = 0.30 - panicLvl * 0.18; } }
    },
  };
}
