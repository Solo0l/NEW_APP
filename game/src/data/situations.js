// Situations are DATA, not code forks. A new Situation = a new object here.
// S01 and S02 run the exact same Mote/Trap/Scene code; they differ only in these numbers.
// Values ported verbatim from the standalone prototypes.

const SPRINTER_LOCOMOTION = {
  speed0: 150, speedPer: 13,   // moteSpeed = speed0 + caps*speedPer
  rBase: 12, rGrow: 1.1,       // moteR = rBase + min(caps,12)*rGrow
  drain: 30,                   // life/s on contact
  restT: 0.72, coilT: 0.26, burstT: 0.18, burstSpeed: 520, restCreep: 48,
  fleeEnabled: true,           // bolt for the gap when encircled
};

// Placeholder tutorial: a slow, gentle mote — teaches the trap with one easy catch, no text.
const TUTORIAL_MOTE = { ...SPRINTER_LOCOMOTION, speed0: 90, speedPer: 0, burstSpeed: 300, drain: 10, feintChanceFlee: 0, feintChanceHunt: 0 };

export const TUTORIAL = {
  id: 'TUT', name: 'Tutorial',
  mote: TUTORIAL_MOTE,
  win: { catches: 1 },
};

export const SITUATION_01 = {
  id: 'S01', name: 'The Sprinter',
  mote: { ...SPRINTER_LOCOMOTION, feintChanceFlee: 0, feintChanceHunt: 0 }, // no feint
  win: { catches: 3 },
};

export const SITUATION_02 = {
  id: 'S02', name: 'The Feinter',
  mote: { ...SPRINTER_LOCOMOTION, feintChanceFlee: 0.45, feintChanceHunt: 0.28 }, // feint on
  win: { catches: 3 },
};

// Placeholder final: feint on, a touch faster. Numbers only, no new mechanic.
export const FINAL = {
  id: 'FIN', name: 'Final Challenge',
  mote: { ...SPRINTER_LOCOMOTION, speed0: 165, burstSpeed: 560, feintChanceFlee: 0.5, feintChanceHunt: 0.32 },
  win: { catches: 5 },
};

// The ordered playable stations between menu and complete.
export const DEMO_SITUATIONS = [TUTORIAL, SITUATION_01, SITUATION_02, FINAL];
