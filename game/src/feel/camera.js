// Camera feel: screen shake + hit-stop. Subscribes to gameplay events; owns no logic.
export function makeCamera(bus) {
  const cam = { shake: 0, freeze: 0 };
  bus.on('caught', () => { cam.freeze = Math.max(cam.freeze, 0.09); cam.shake = Math.max(cam.shake, 14); });
  bus.on('emptyLoop', () => { cam.freeze = Math.max(cam.freeze, 0.04); cam.shake = Math.max(cam.shake, 6); });
  bus.on('hit', () => { cam.shake = Math.max(cam.shake, 5); });
  cam.update = (dt) => { if (cam.freeze > 0) cam.freeze -= dt; if (cam.shake > 0) cam.shake = Math.max(0, cam.shake - dt * 55); };
  return cam;
}
