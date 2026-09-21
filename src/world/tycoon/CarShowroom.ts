import { Box3, Color, CylinderGeometry, DirectionalLight, Group, HemisphereLight, Mesh, MeshStandardMaterial,
  PerspectiveCamera, Scene, Vector2, Vector3 } from 'three';
import type { WebGLRenderer } from 'three';
import type { DrivingSystem } from '../driving/DrivingSystem.js';
import { CarPaint } from './CarPaint.js';

/** Separate preview scene using the main renderer and untouched authored model copies. */
export class CarShowroom {
  readonly scene = new Scene();
  readonly camera = new PerspectiveCamera(38, 1, .1, 500);
  private readonly turntable = new Group();
  private readonly plinth = new Mesh(new CylinderGeometry(1, 1, .2, 64), new MeshStandardMaterial({ color: 0x31473e, roughness: .75 }));
  private readonly size = new Vector2();
  private selected?: number;
  private readonly paint = new CarPaint();
  private radius = 10;
  private height = 5;
  get active() { return this.selected !== undefined; }
  constructor(private driving: DrivingSystem) {
    this.scene.background = new Color(0x12221f);
    this.scene.add(new HemisphereLight(0xe7f4ff, 0x526043, 1.8));
    const key = new DirectionalLight(0xfff2d6, 2.5); key.position.set(-15, 24, -20);
    const rim = new DirectionalLight(0x9ac8ff, 1.6); rim.position.set(18, 12, 14);
    this.scene.add(key, rim, this.plinth, this.turntable);
  }
  select(id?: number, color?: string) {
    if (id === this.selected) { if (this.turntable.children[0]) this.paint.apply(this.turntable.children[0], color); return; }
    this.paint.dispose();
    this.turntable.clear(); this.selected = id;
    const car = this.driving.cars.find(candidate => candidate.id === id);
    if (!car) { this.selected = undefined; return; }
    const model = car.cloneModel();
    const bounds = new Box3().setFromObject(model), size = bounds.getSize(new Vector3());
    model.position.sub(bounds.getCenter(new Vector3())); model.position.y += size.y / 2;
    this.turntable.add(model);
    this.paint.apply(model, color);
    this.height = size.y; this.radius = Math.hypot(size.x, size.z) * .6;
    this.plinth.scale.set(this.radius, 1, this.radius); this.plinth.position.y = -.12;
    this.turntable.rotation.y = -.6;
  }
  tick(delta: number) { if (this.active) this.turntable.rotation.y += Math.min(delta, .1) * .16; }
  render(renderer: WebGLRenderer): boolean {
    if (!this.active) return false;
    renderer.getSize(this.size);
    // Leave the lower portion for the selection card and keep the model above it.
    const height = Math.max(1, this.size.y * (this.size.y < 500 ? .8 : .68));
    const width = this.size.y < 500 && this.size.x > 620 ? Math.max(1, this.size.x - 365) : this.size.x;
    this.camera.aspect = width / height;
    const distance = this.radius / Math.sin(this.camera.fov * Math.PI / 360) / Math.min(1, this.camera.aspect) * 1.05;
    this.camera.position.set(0, this.height * .5 + distance * .23, -distance);
    this.camera.lookAt(0, this.height * .45, 0); this.camera.updateProjectionMatrix();
    renderer.setViewport(0, this.size.y - height, width, height);
    renderer.render(this.scene, this.camera);
    renderer.setViewport(0, 0, this.size.x, this.size.y);
    return true;
  }
  dispose() {
    this.paint.dispose();
    // Clones share their geometry and materials with the live cars.
    this.turntable.clear(); this.plinth.geometry.dispose(); this.plinth.material.dispose(); this.selected = undefined;
  }
}
