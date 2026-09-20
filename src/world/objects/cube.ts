import { BoxGeometry, Mesh, MeshStandardMaterial } from "three";

export function createCube() {
  const material = new MeshStandardMaterial({ color: 0x880000 });
  const geometry = new BoxGeometry(1, 1, 1);
  const mesh = new Mesh(geometry, material);
  return mesh;
}
