# ChromaEscape — Project Constitution

**This document has higher priority than every future prompt. Never violate these rules.**
Read it at the start of every session before proposing or building anything.

**Also read `LESSONS_FROM_CHROMAESCAPE.md` at the start of every session.** It is the
permanent game-design workflow extracted from this project — playtesting discipline,
design red flags, and how Solo and Claude work together — and applies automatically to
all design and development work here, not only to ChromaEscape itself.

---

## THE GAME
The game is NOT about colors. NOT about combat. NOT about upgrades.
The game is about ONE emotional reversal: **the hunter becomes the hunted.**

## CORE FANTASY
I am being hunted. I escape. I draw. I trap. I survive.

## CORE VERB
**Move → Draw (the trail is a living blade) → Trap.**
Movement is the only weapon. The Trap remains the finisher. *(See Amendment 01.)*
No traditional attacks (swords, guns, projectiles, press-to-hit) may ever exist.

## GOLDEN RULE
If trapping the enemy is not the most satisfying move in the game, nothing else matters.

## DESIGN RULES
- No mechanic exists unless it improves trapping.
- No feature exists unless it creates better trapping.
- No content exists unless it creates new trapping *situations*.

## FORBIDDEN (never suggest, never build)
Skill trees · RPG systems · currencies · crafting · loot · random upgrades ·
talent systems · quest systems · dialogue systems · story systems · collectibles ·
power progression · **swords · guns · projectiles · any press-to-hit "attack" button.**
Combat may ONLY emerge from movement and the trail.

## PROGRESSION
The player becomes more **SKILLFUL**, never more **POWERFUL**.

## CONTENT
Future content may ONLY change: Arena · Enemy behaviour · Timing · Pressure ·
Geometry · Patterns · Psychology. **Never the core mechanic.**

## THE ONE TEST (apply to every future idea)
Does this make **Move → Draw → Trap** better, and does it emerge from movement?
If it weakens the core, or if it is combat that does NOT come from movement/the trail —
**delete it**, even if it is my own idea.

---

## AMENDMENT 01 (ratified) — Movement is combat; the trail is a living blade
The game grew from a pure trapping toy into a **fast action game** (Hades / Doom Eternal
tempo) — but combat still comes only from movement. What changed and what is preserved:

- **Movement remains the core.** The player is always moving fast; moving IS attacking.
- **The trail is no longer passive — it is dangerous.** Enemies can be **damaged,
  manipulated, or controlled** by contact with the trail. You "attack" by drawing your line
  across, around, or between enemies. Fresh trail is potent; faded trail is inert.
- **The Trap remains the highest-risk, highest-reward FINISHER, and the win condition.**
  The player still *wins through trapping*. The trail softens, staggers, and herds;
  the loop executes. (Recommended: trail damage staggers/controls but does not kill —
  only the Trap kills — so "win through trapping" always holds.)
- **No traditional weapons.** No swords, guns, projectiles, or attack buttons. If combat
  did not emerge from movement or the trail, it does not belong.
- **Still SKILL, not POWER.** No upgrades. Difficulty comes from Arena · Enemy behaviour ·
  Timing · Pressure · Geometry · Patterns · Psychology.

Everything already built is reused: the Mote, the Trap, the AI, the Situations, the feel
become the *combat*. The Situations are now the enemy roster (each is a trap-opportunity puzzle).

---

## CURRENT STATE (context for future sessions)
- **Production codebase:** `game/` — modular ES source (`src/`), bundled to one self-contained
  file via `node build.mjs` → `game/dist/chromaescape_demo.html`. Modules: core (bus/canvas/
  input/loop), world (arena/player), systems (trap geometry), entities (mote FSM, config-driven),
  feel (audio/particles/camera — pure bus subscribers), render, scene (situation/manager/menu/
  complete/flow), data (situations). Gameplay emits events; feel subscribes. Situations are DATA.
- **Playable demo spine exists:** menu → wordless tutorial → Situation 01 (Sprinter) →
  Situation 02 (Feinter) → Final → Demo Complete, each a catch-goal station.
- Feel: ~90ms hit-stop, shake, spark burst, rising trap-tone on catch; the mote has a watching
  eye + squash/stretch + panic (struggle/cry/gasp); audio is silence-based with a proximity
  heartbeat and a coil/feint telegraph.
- Legacy standalone prototypes `ChromaEscape_*.html` in the repo root are frozen references.
- **NEXT per Amendment 01:** make the trail a living blade (damage/stagger/control on contact),
  give enemies a stagger state, keep the Trap as the executing finisher. Start with the smallest
  prototype: one enemy, movement-slashing staggers it, the Trap finishes it.
