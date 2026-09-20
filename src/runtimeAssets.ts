import { DefaultLoadingManager } from 'three';

type Archive = Record<string, { type: string; data: string }>;

function decodeBase64(encoded: string): Uint8Array {
  const binary = atob(encoded);
  return Uint8Array.from(binary, character => character.charCodeAt(0));
}

// Both Three.js loaders and the game's JSON requests use this resolver.
export function assetUrl(url: string): string {
  return DefaultLoadingManager.resolveURL(url);
}

export async function initializeStandaloneAssets(): Promise<void> {
  const payload = document.getElementById('standalone-assets');
  if (!payload) return;

  // TypeScript 4.6 predates this browser API's DOM declarations.
  const { DecompressionStream } = globalThis as unknown as {
    DecompressionStream?: new (format: string) => ReadableWritablePair<Uint8Array, Uint8Array>;
  };
  if (!DecompressionStream) throw new Error('This standalone game needs a current version of Chrome, Edge, Firefox, or Safari.');
  const compressed = new Blob([decodeBase64(payload.textContent!.trim())]);
  const archive: Archive = await new Response(compressed.stream().pipeThrough(new DecompressionStream('gzip'))).json();
  payload.remove();

  const root = new URL('.', window.location.href).href;
  const urls = new Map<string, string>();
  DefaultLoadingManager.setURLModifier(url => {
    if (/^(data|blob):/i.test(url)) return url;
    const absolute = new URL(url, root).href;
    const key = decodeURIComponent(absolute.startsWith(root) ? absolute.slice(root.length) : new URL(absolute).pathname.replace(/^\//, ''))
      .split(/[?#]/, 1)[0];
    const cached = urls.get(key);
    if (cached) return cached;
    const asset = Object.prototype.hasOwnProperty.call(archive, key) ? archive[key] : undefined;
    if (!asset) throw new Error(`Asset is missing from the standalone build: ${url}`);
    const embedded = URL.createObjectURL(new Blob([decodeBase64(asset.data)], { type: asset.type }));
    urls.set(key, embedded);
    delete archive[key];
    return embedded;
  });
  // Blob URLs live for this document's lifetime, including back/forward restores.
}
