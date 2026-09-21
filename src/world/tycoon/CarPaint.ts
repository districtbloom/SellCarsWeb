import { Mesh, MeshPhongMaterial, MeshStandardMaterial } from 'three';
import type { Material, Object3D } from 'three';

/** Paint copies are owned here; glass, wheels and authored shared materials stay intact. */
export class CarPaint {
  private originals = new Map<Mesh, Material | Material[]>();
  private copies: Material[] = [];
  private model?: Object3D;
  private color?: string;
  apply(model: Object3D, color?: string) {
    if (model === this.model && color === this.color) return;
    this.dispose(); this.model = model; this.color = color;
    if (!color) return;
    model.traverse(object => {
      if (!(object instanceof Mesh) || !/^(?:Body|Chassis)\d*$/.test(object.name)) return;
      this.originals.set(object, object.material);
      const tint = (source: Material) => {
        const copy = source.clone(); this.copies.push(copy);
        if (copy instanceof MeshPhongMaterial || copy instanceof MeshStandardMaterial) {
          copy.color.set(color);
          // These imported shells also carry baked emissive color. Tint it too so
          // the old paint cannot wash out the new color under showroom lighting.
          if (copy.emissiveMap) { copy.emissive.set(color); copy.emissiveIntensity = Math.min(copy.emissiveIntensity, .35); }
          else copy.emissive.setHex(0);
        }
        return copy;
      };
      object.material = Array.isArray(object.material) ? object.material.map(tint) : tint(object.material);
    });
  }
  dispose() {
    for (const [mesh, material] of this.originals) mesh.material = material;
    this.copies.forEach(material => material.dispose()); this.copies = []; this.originals.clear();
    this.model = undefined; this.color = undefined;
  }
}
