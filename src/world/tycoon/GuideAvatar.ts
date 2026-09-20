import { Color, DirectionalLight, HemisphereLight, Mesh, MeshBasicMaterial, OrthographicCamera, Scene, Vector4, WebGLRenderTarget } from 'three';
import type { WebGLRenderer } from 'three';
import { createBlockCharacter } from '../components/blockCharacter.js';

/** Render a small 3D portrait once using the game's context, then cache it in the HUD canvas. */
export function renderGuideAvatar(renderer: WebGLRenderer, canvas: HTMLCanvasElement) {
  const context = canvas.getContext('2d');
  if (!context) return;
  const size = 192;
  canvas.width = size; canvas.height = size;
  const scene = new Scene(), character = createBlockCharacter('Player portrait', 0x56b5ef);
  scene.add(character, new HemisphereLight(0xffffff, 0x627a83, 1.5));
  const light = new DirectionalLight(0xfff4de, 2.4); light.position.set(-4, 7, -6); scene.add(light);
  const camera = new OrthographicCamera(-3.1, 3.1, 3.1, -3.1, .1, 50);
  camera.position.set(4, 3.2, -12); camera.lookAt(0, 1.1, 0);
  const target = new WebGLRenderTarget(size, size);
  target.texture.encoding = renderer.outputEncoding;
  target.samples = renderer.capabilities.isWebGL2 ? 4 : 0;
  const previous = {
    target: renderer.getRenderTarget(), viewport: renderer.getViewport(new Vector4()),
    scissor: renderer.getScissor(new Vector4()), scissorTest: renderer.getScissorTest(),
    color: renderer.getClearColor(new Color()), alpha: renderer.getClearAlpha(), autoClear: renderer.autoClear,
  };
  try {
    renderer.setRenderTarget(target); renderer.setViewport(0, 0, size, size); renderer.setScissorTest(false);
    renderer.setClearColor(0x000000, 0); renderer.autoClear = true;
    renderer.render(scene, camera);
    const pixels = new Uint8Array(size * size * 4), image = context.createImageData(size, size);
    renderer.readRenderTargetPixels(target, 0, 0, size, size, pixels);
    // WebGL reads from the bottom-left; canvas image data starts at the top-left.
    for (let row = 0; row < size; row++) {
      const from = (size - row - 1) * size * 4;
      image.data.set(pixels.subarray(from, from + size * 4), row * size * 4);
    }
    context.putImageData(image, 0, 0);
  } finally {
    renderer.setRenderTarget(previous.target); renderer.setViewport(previous.viewport);
    renderer.setScissor(previous.scissor); renderer.setScissorTest(previous.scissorTest);
    renderer.setClearColor(previous.color, previous.alpha); renderer.autoClear = previous.autoClear;
    target.dispose();
    character.traverse(object => {
      if (!(object instanceof Mesh)) return;
      object.geometry.dispose();
      for (const material of Array.isArray(object.material) ? object.material : [object.material]) {
        (material as MeshBasicMaterial).map?.dispose(); material.dispose();
      }
    });
  }
}
