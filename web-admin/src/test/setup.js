import '@testing-library/jest-dom/vitest';

// Node 26's experimental global `localStorage` shadows jsdom's working
// implementation before vitest can wire it up (vitest only overrides globals
// that are absent from `global`, and Node predefines this one as a stub that
// throws without --localstorage-file). Replace it with a small polyfill.
if (typeof localStorage === 'undefined' || typeof localStorage.setItem !== 'function') {
  const store = new Map();
  const polyfill = {
    getItem: (key) => (store.has(String(key)) ? store.get(String(key)) : null),
    setItem: (key, value) => store.set(String(key), String(value)),
    removeItem: (key) => store.delete(String(key)),
    clear: () => store.clear(),
    key: (index) => Array.from(store.keys())[index] ?? null,
    get length() {
      return store.size;
    },
  };
  Object.defineProperty(globalThis, 'localStorage', {
    value: polyfill,
    writable: true,
    configurable: true,
  });
}
