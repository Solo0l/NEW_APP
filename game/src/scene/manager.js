// Thin scene manager: holds the current scene, forwards the frame + input to it.
// The only "glue" the demo flow needs — every scene it runs is something the player sees.
export function makeSceneManager() {
  let cur = null;
  return {
    set(scene) { if (cur && cur.exit) cur.exit(); cur = scene; if (cur && cur.enter) cur.enter(); },
    update(dt) { if (cur && cur.update) cur.update(dt); },
    draw() { if (cur && cur.draw) cur.draw(); },
    press() { if (cur && cur.press) cur.press(); },
    key(k) { if (cur && cur.key) cur.key(k); },
    get current() { return cur; },
  };
}
