// Tiny pub/sub event bus — the decoupling backbone.
// Gameplay EMITS semantic events; feel modules SUBSCRIBE. Gameplay never calls feel directly.
export function makeBus() {
  const map = new Map();
  return {
    on(type, fn) {
      if (!map.has(type)) map.set(type, []);
      map.get(type).push(fn);
      return () => { const a = map.get(type); const i = a.indexOf(fn); if (i >= 0) a.splice(i, 1); };
    },
    emit(type, ev) {
      const a = map.get(type);
      if (a) for (let i = 0; i < a.length; i++) a[i](ev);
    },
  };
}
