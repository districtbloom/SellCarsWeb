import { FileLoader, ObjectLoader, PerspectiveCamera, Scene, Vector3 } from 'three';

export function sceneDocument(document: unknown): Record<string, unknown> {
  if (!document || typeof document !== 'object') throw new Error('Expected a scene JSON object');
  const input = document as Record<string, unknown>;
  // Accept both an exported Scene and an editor project wrapper.
  const scene = (input.scene ?? input) as Record<string, unknown>;
  if (!scene || typeof scene !== 'object' ||
      (scene.object as { type?: string } | undefined)?.type !== 'Scene') {
    throw new Error('Export the entire Scene from the editor, not an individual Object');
  }
  return scene;
}

export async function loadAuthoredScene(url: string): Promise<Scene> {
  const text = await new FileLoader().loadAsync(url);
  const json = sceneDocument(JSON.parse(text as string));
  // Editor scripts are not evaluated; behavior lives in TypeScript.
  const scene = await new ObjectLoader()
    .setResourcePath(new URL('.', new URL(url, window.location.href)).href)
    .parseAsync(json);
  if (!(scene instanceof Scene)) throw new Error('The exported root must be a Scene');
  return scene;
}

export function sceneCamera(scene: Scene): { camera: PerspectiveCamera; target: Vector3 } {
  const cameras: PerspectiveCamera[] = [];
  scene.traverse(object => {
    if (object.name === 'MainCamera' && object instanceof PerspectiveCamera) cameras.push(object);
  });
  if (cameras.length !== 1) throw new Error('The scene needs exactly one PerspectiveCamera named MainCamera');
  const source = cameras[0];
  scene.updateMatrixWorld(true);
  // Preserve world pose even if the artist parents the camera to another object.
  const camera = source.clone();
  source.matrixWorld.decompose(camera.position, camera.quaternion, camera.scale);
  camera.updateMatrixWorld(true);
  const focusDistance = source.userData.focusDistance ?? 10;
  if (typeof focusDistance !== 'number' || !Number.isFinite(focusDistance) || focusDistance <= 0) {
    throw new Error('MainCamera user data focusDistance must be a positive number');
  }
  const target = camera.getWorldDirection(new Vector3())
    .multiplyScalar(focusDistance).add(camera.position);
  return { camera, target };
}
