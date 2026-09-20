import type { PerspectiveCamera } from 'three';

const locks = new WeakMap<PerspectiveCamera, ReturnType<typeof snapshot>>();
function snapshot(camera: PerspectiveCamera) {
  return { count: 0, position: camera.position.clone(), quaternion: camera.quaternion.clone(), up: camera.up.clone(), fov: camera.fov, zoom: camera.zoom };
}
/** Capture before an interaction changes player placement, orientation or menu state. */
export function lockCameraPose(camera: PerspectiveCamera): () => void {
  let pose = locks.get(camera);
  if (!pose || pose.count === 0) { pose = snapshot(camera); locks.set(camera, pose); }
  pose.count++;
  const captured = pose;
  let released = false;
  return () => {
    if (released) return;
    released = true; restoreCameraPose(camera); captured.count--;
  };
}
export function restoreCameraPose(camera: PerspectiveCamera): boolean {
  const pose = locks.get(camera); if (!pose) return false;
  camera.position.copy(pose.position); camera.quaternion.copy(pose.quaternion); camera.up.copy(pose.up);
  if (camera.fov !== pose.fov || camera.zoom !== pose.zoom) { camera.fov = pose.fov; camera.zoom = pose.zoom; camera.updateProjectionMatrix(); }
  camera.updateMatrixWorld(true); return true;
}
/** A released snapshot survives until the follow camera rebases its orbit around it. */
export function cameraPoseState(camera: PerspectiveCamera): 'locked' | 'released' | undefined {
  const pose = locks.get(camera); return pose ? pose.count > 0 ? 'locked' : 'released' : undefined;
}
export function consumeCameraPose(camera: PerspectiveCamera) { locks.delete(camera); }
