import { Matrix4 } from 'three';

export function editorProject(json) {
  const scene = json.scene ?? json;
  if (scene.object?.type !== 'Scene') throw new Error('Expected an exported Scene JSON');
  let camera;
  function visit(object, parentMatrix) {
    const matrix = parentMatrix.clone().multiply(new Matrix4().fromArray(object.matrix ?? new Matrix4().elements));
    if (object.name === 'MainCamera' && object.type === 'PerspectiveCamera') {
      if (camera) throw new Error('Multiple MainCamera objects found');
      camera = { ...object, matrix: matrix.toArray(), children: [] };
    }
    for (const child of object.children ?? []) visit(child, matrix);
  }
  visit(scene.object, new Matrix4());
  if (!camera) throw new Error('The scene needs a PerspectiveCamera named MainCamera');
  return {
    metadata: { type: 'App' },
    project: { shadows: true, shadowType: 2, physicallyCorrectLights: true, toneMapping: 0, toneMappingExposure: 1 },
    camera: { metadata: { type: 'Object', version: 4.5 }, object: { ...camera, name: 'Editor camera' } },
    scene, scripts: {}, history: { undos: [], redos: [] },
  };
}
