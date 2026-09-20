import './style.css';
import { World } from './world/world.js';
import { initializeStandaloneAssets } from './runtimeAssets.js';

async function main() {
  await initializeStandaloneAssets();
  const container: HTMLElement | null = document.querySelector('#scene-container');
  if (!container) {
    throw new Error('No container element found');
  }
  const world = new World(container);

  await world.init();
  world.start();
  document.getElementById('standalone-loading')?.remove();
}

main().catch((error: unknown) => {
  console.error('Failed to load the scene:', error);
  document.getElementById('standalone-loading')?.remove();
  const message = document.createElement('p');
  message.textContent = `Unable to start the game: ${error instanceof Error ? error.message : 'Unknown error'}`;
  message.style.cssText = 'position:fixed;top:16px;left:16px;color:white;background:#121a25;padding:16px;z-index:100';
  document.body.append(message);
});
