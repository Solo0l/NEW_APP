import { makeGame } from './game.js';

// Entry point. DOM wiring only.
makeGame(
  document.getElementById('c'),
  document.getElementById('hud'),
  document.getElementById('boot'),
);
