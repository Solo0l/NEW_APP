// Minimal bundler: concatenates the ES modules (in dependency order), strips import/export,
// and inlines them into ONE self-contained HTML so the game still double-clicks (file://)
// and drops into an Artifact. Replace with esbuild later (see TECH-DEBT).
//   usage: node build.mjs
import { readFileSync, writeFileSync, mkdirSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = dirname(fileURLToPath(import.meta.url));

// concatenation order = dependency order; config first, main last
const ORDER = [
  'src/config.js',
  'src/core/bus.js', 'src/core/canvas.js', 'src/core/input.js', 'src/core/loop.js',
  'src/world/arena.js', 'src/world/player.js',
  'src/systems/trap.js', 'src/entities/mote.js',
  'src/feel/camera.js', 'src/feel/particles.js', 'src/feel/audio.js',
  'src/render/renderer.js',
  'src/data/situations.js', 'src/scene/situation.js',
  'src/game.js', 'src/main.js',
];

function strip(src) {
  return src
    .split('\n')
    .filter((l) => !/^\s*import\s.+from\s.+;?\s*$/.test(l)) // drop `import ... from '...'`
    .map((l) => l.replace(/^\s*export\s+/, ''))             // drop leading `export `
    .join('\n');
}

const bundle = ORDER.map((f) => `// ===== ${f} =====\n${strip(readFileSync(join(ROOT, f), 'utf8'))}`).join('\n\n');

const HTML = `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=no">
<title>ChromaEscape — Demo (modular foundation)</title>
<style>
  html,body{margin:0;height:100%;background:#0a0a0c;overflow:hidden;
    font-family:ui-monospace,Menlo,Consolas,monospace;-webkit-tap-highlight-color:transparent;}
  #c{display:block;position:fixed;inset:0;width:100%;height:100%;touch-action:none;}
  #hud{position:fixed;top:10px;left:12px;color:#5a6a7a;font-size:12px;letter-spacing:.05em;
    pointer-events:none;line-height:1.6;text-shadow:0 1px 3px #000;z-index:2;}
  #hud b{color:#9fd8ff;} #hud i{color:#ff9db3;font-style:normal;}
  #boot{position:fixed;inset:0;display:flex;flex-direction:column;align-items:center;justify-content:center;
    color:#9fd8ff;font-size:15px;letter-spacing:.1em;background:#0a0a0c;z-index:3;cursor:pointer;text-align:center;line-height:2;padding:20px;}
  #boot span{opacity:.65;font-size:13px;color:#7d8ea0;line-height:1.9;}
</style>
</head>
<body>
<canvas id="c"></canvas>
<div id="hud"></div>
<div id="boot">CHROMAESCAPE · modular foundation
<span>🔊 sound on — click / tap here, then WASD · arrows · drag to move<br><br>
draw a loop around the mote to catch it<br>
(same game, now built from clean modules)</span></div>
<script>
${bundle}
</script>
</body>
</html>
`;

mkdirSync(join(ROOT, 'dist'), { recursive: true });
writeFileSync(join(ROOT, 'dist', 'chromaescape_demo.html'), HTML);
console.log('built dist/chromaescape_demo.html  (' + HTML.length + ' bytes, ' + ORDER.length + ' modules)');
