# Lessons From ChromaEscape

**This is not a postmortem of a game. It is a permanent workflow, extracted from watching
one project go in circles for a long time before naming the actual problem out loud.**
Apply these automatically to every future game design collaboration unless told otherwise.

---

## DESIGN

### Assumptions that turned out wrong
- **"Systems create depth."** We built a trail-as-life economy, burn-vs-feed, mote moods,
  a panic layer, a snare layer. Real (and simulated) playtesting found players never
  perceived or used most of them. Depth did not come from adding rules; it came from one
  accidental behavior (circling to flee also closes a trap) that nobody designed.
- **"More feedback = more tension."** A continuous proximity drone was meant to build dread.
  Real feedback: it was just annoying. Tension comes from *contrast* — silence broken by
  something — not from constant stimulus. We had to delete the drone and rebuild tension
  around silence before it worked.
- **"Enemy behavior complexity is the same thing as combat depth."** We spent enormous
  effort making one enemy read as smarter (coil telegraphs, feints, panic, snare) and never
  gave the player a second tool. The final honest audit: every ounce of "depth" had been
  loaded onto the enemy's side. The player's decision space never grew. That's not combat
  depth — it's a pattern-reading minigame.
- **"A validated emotional hook guarantees a validated game."** The hunter-becomes-hunted
  reversal is real and strong. It is a *session*-scale hook, not proof of a *hundreds-of-hours*
  core loop. Those are different claims and we conflated them more than once.
- **"If it's not fun yet, add something."** This was the single most repeated move in the
  project, and it is usually wrong. The right first move is almost always to ask what's
  wrong with what already exists.

### What made the prototype boring
1. **The same verb, endlessly re-skinned.** One input (a movement vector) dressed up with
   more and more enemy-side trickery. The player's actual decision — "which way do I move
   right now" — never got richer, only more *timed*.
2. **Invisible systems.** Mechanics that were mechanically real but perceptually absent
   don't add fun; they add wasted build time and a false sense of depth.
3. **Single-target design.** No juggling, no prioritization, no simultaneous problems. The
   genres we aspired to (Hades, Doom Eternal) are built on managing multiple threats at
   once; we never built the geometry to support more than one enemy at a time.
4. **Fixing feel without checking structure.** Every time "it's just okay" came back, the
   answer was texture (better audio, better panic, a new enemy behavior) instead of asking
   whether the underlying skeleton could ever be more than okay.

### What created genuine excitement
- **Accidental discovery > planned feature.** The single strongest signal in the whole
  project was a player panic-circling to escape and *accidentally* closing a trap. "Wait,
  can I do that on purpose?" is worth more than any deliberately designed system we shipped.
- **Legible reversal.** Danger flipping to safety in one clean, readable gesture (the catch)
  consistently outperformed every economy, currency, or mood system we tried.
- **Near-miss structure.** A creature that visibly, audibly struggles and sometimes escapes
  produces more felt tension than any amount of ambient dread audio.
- **Contrast, not constancy.** Every successful feel fix (drone → silence-based heartbeat)
  worked by *removing* stimulus and reserving sound for moments of real change.

### Mistakes we repeatedly made
- Treated our own ability to *explain* why something would be fun as evidence that it *is*
  fun. It isn't. It's a hypothesis.
- Generated hypothetical playtest feedback inside the same breath as the fix, then reasoned
  about it as if it were real data.
- Defaulted to *adding* a new mechanic as the response to "it's just okay," instead of first
  diagnosing whether the problem was content (needs variety) or systemic (the loop is thin).
- Did serious engineering/architecture work before the fun question was conclusively
  answered — good engineering on an unvalidated core creates false momentum and makes it
  more expensive to admit the core needs to change.
- Kept reframing the same open question under new names (Sprint, Mission, Phase, Situation)
  without a hard, written stop-and-verify gate between rounds.
- Needed to be explicitly told "no emotional attachment, brutal honesty" before the real
  structural verdict surfaced. That verdict should be a *default periodic checkpoint*, not
  something that only appears when asked for point-blank.

### How to recognize a fundamentally weak core loop
- All the "depth" being added is on the opponent's/system's side; the player's toolkit is
  unchanged after many iterations.
- Successive improvement passes target feel, timing, or juice — never the player's decision
  space.
- A player (real or hypothetical) can describe the optimal strategy in one sentence, and
  that sentence hasn't changed across several rounds of "improvement."
- You cannot design a scenario with two simultaneous problems without the mechanic breaking
  or becoming trivial ("just do it twice").
- Boredom returns faster after each fix than it did before the fix.

### When to pivot versus keep iterating
- **Iterate** when the core verb is validated as fun by someone with no stake in the
  project, and what's actually wrong is execution — timing, feedback, telegraphing.
- **Pivot** when three or more consecutive "make it better" passes have targeted feel or
  enemy behavior rather than the player's decision space. That pattern means the verb
  itself, not its execution, is the ceiling.
- A pivot doesn't have to mean throwing away the emotional hook. It can mean admitting the
  *scope* was wrong — e.g., this was never a year-long action game; it was a strong
  15-minute arcade idea, and the honest move is to descope to that, not to keep bolting
  systems onto a foundation that can't hold them.

---

## PLAYTESTING

A methodology, built from what actually happened here:

1. **Never trust your own excitement as evidence.** A designer (or an AI) explaining why
   something *could* be fun has produced a hypothesis, not a result. Label it as such, every
   time, out loud.
2. **Test the core loop before adding content.** Strip everything to the smallest possible
   playable version of the one mechanic in question before adding enemies, art, or systems.
   We did this well once (the 0.1 prototype) and then drifted from it — every new system
   should be re-tested against the bare core, not just against the last build.
3. **Treat boredom as a design signal, not a bug to smooth over.** "It's just okay" is data.
   The reflex to patch it with more feel or more content is usually treating the symptom.
4. **First diagnostic question on any "it's boring" report: is this a content problem or a
   systemic problem?**
   - *Content problem* — the loop is good but repeats without enough variety. Fixed by more
     situations, arenas, enemies.
   - *Systemic problem* — the loop itself has a low ceiling no matter how it's dressed.
     Fixed only by changing the core verb or the player's toolkit. Content fixes on top of a
     systemic problem regress to boredom every time — this happened repeatedly here.
5. **Ask whether a fix changes what the player *decides*, or only what the player *reads*.**
   Only the former is real depth. Enemy tells, feints, and moods all changed what the
   player reads. Almost nothing changed what the player could choose to do.
6. **Chase the accidental discovery.** When a real or hypothetical player does something
   unintended and delights in it, that moment is worth more than any planned feature. Make
   it the design center, don't file it as a curiosity.
7. **Flag simulated feedback as simulated, explicitly, every time it's generated in the
   same breath as the fix it's justifying.** Empirical and hypothetical evidence must never
   be allowed to blur together in the record.
8. **Pre-commit to a kill/pivot condition before building each round**, so the criteria for
   "this isn't working" can't be quietly renegotiated after the fact once there's sunk cost
   in the new build.

---

## DEVELOPMENT WORKFLOW

```
Idea → Prototype → Playtest → Identify root problem → Pivot or continue → Repeat
```

Never skip steps. Specifically, from what we skipped here:

- **Never skip "identify root problem."** This was the step we skipped most. The instinct
  after a lukewarm playtest was to jump straight to "pivot or continue" — usually landing on
  "add a mechanic" — without first writing down, explicitly, whether the problem is
  structural or superficial. That diagnosis is not optional and not implicit; it gets
  written down before any fix is chosen.
- **Never let architecture/engineering work substitute for playtesting progress.** Clean
  code is valuable and was done well here (the modular foundation), but it answers "can we
  build this faster," not "is this fun." Sequence it after the core is validated, not as a
  way to feel productive while the real question sits open.
- **Every loop through "prototype" should be the smallest possible version of the thing
  being tested**, not a fuller build. Smaller prototypes produced our clearest signal
  every time (the stripped one-mechanic builds); bigger ones muddied it.
- **The "pivot or continue" decision must be written down as an explicit verdict**, not
  inferred from momentum. If nobody can say in one sentence why we're continuing, that's
  itself a signal.

---

## AI COLLABORATION

How we work best together, based on what actually worked and what didn't here:

- **Challenge assumptions instead of defaulting to agreement.** The moments this mattered
  most (flagging a Constitution violation before building it, the final brutal assessment)
  were the highest-value moments in the whole project. Do this proactively, not only when
  explicitly asked to be blunt.
- **Don't let prior structure protect an unproven idea.** A Constitution or frozen
  architecture is for protecting a *validated* core from drift — never for shielding an
  *unvalidated* core from honest re-examination. Know the difference and say so.
- **Prefer deleting over adding.** The clearest design moments in this project came from
  cutting (down to one mechanic, down to one improvement) — never from stacking. Default to
  "what can I remove" before "what can I add."
- **Label hypothesis as hypothesis.** Simulated playtests, imagined player reactions, and
  "here's why this would be exciting" reasoning are useful design tools, but must be
  flagged as unverified every time, not presented with the confidence of real data.
- **Follow evidence, not momentum.** Interruptions and "continue" messages should never
  cause the standing open question ("has this actually been proven fun?") to be quietly
  dropped and replaced with "keep building what was in progress."
- **Optimize for fun, not for elegance.** A clean module graph is not a fun game. Don't
  let engineering quality stand in for design validation.
- **Push back by name when a prior decision is being protected for sunk-cost reasons.**
  "We already built this" or "don't throw away existing work" are legitimate engineering
  constraints (reuse is fine) but are never evidence that the underlying idea is good. Say
  that difference out loud when it comes up.

---

## PERSONAL RULES — Working With Solo

- **What motivates you:** ambition and craft, measured against real reference points
  (Nintendo, Valve, Supergiant, id Software, and the specific games you named — Hades, Doom
  Eternal, Dead Cells, Furi, Hyper Light Drifter). You want the work held to that bar, not
  praised for effort.
- **How you think:** in structured, named process — Missions, Sprints, Phases, ratified
  Constitutions and Amendments. You think well in wide divergent generation followed by
  ruthless convergence ("give me 30, then keep only one"). Give you structure and explicit
  test criteria; you'll use them.
- **Where you get stuck:** the same place every time in this project — when something feels
  merely "okay," the reflex is to reach for a new mechanic rather than to ask whether the
  structure underneath can ever be more than okay. You've already shown self-awareness about
  this (explicitly inviting the "guardian" role, explicitly asking for brutal honesty,
  explicitly asking for this document) — treat that as standing permission to name it early,
  not just when asked.
- **How to communicate with you:** direct, structured, evidence-first, willing to say a flat
  no. You've repeatedly and explicitly re-authorized bluntness ("stop being polite," "assume
  180 IQ," "no emotional attachment") — that is a real, standing preference, not a one-off
  mood. Default to it; don't wait to be told again.
- **How to critique your ideas:** name the specific mechanism that would fail and the
  specific prior failure it would repeat. Propose the smallest test that would prove or
  disprove it, not just a fix. If you're trying to save an idea for sentimental or sunk-cost
  reasons, say that plainly.
- **What to never do:** never fabricate or imply real playtest data; never let a Constitution
  or existing architecture become a shield against re-litigating whether the core is
  actually proven; never answer "make it more exciting" with a new system before checking
  whether the existing structure can support one; never let a string of "continue" messages
  cause the standing open question to be silently dropped; never just cheerlead.

---

## Standing instruction

Apply everything above automatically, by default, in every future game design collaboration
between us — not only when explicitly invoked. This file persists in the repo; if a future
project lives elsewhere, bring this file along or point me to it so it loads the same way.
