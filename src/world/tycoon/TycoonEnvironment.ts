import { BoxGeometry, BufferGeometry, CanvasTexture, Color, CylinderGeometry, DoubleSide, Float32BufferAttribute, Group,
  InstancedMesh, Matrix4, Mesh, MeshBasicMaterial, MeshStandardMaterial, PlaneGeometry, Quaternion, SphereGeometry, Vector3, Raycaster } from 'three';
import { Body, Box, ConvexPolyhedron, Quaternion as PhysicsQuaternion, Vec3, World } from 'cannon-es';
import { METERS_PER_UNIT } from '../driving/CarRig.js';
import { frameMatrix, LOT_ORIGIN, SOURCE_ORIGIN } from './TycoonCoordinates.js';
import { openingStep, partPose } from './BuildingProgression.js';
import type { ImportedPart, PartPose } from './BuildingProgression.js';
import type { TycoonState, Vec } from './types.js';
import { assetUrl } from '../../runtimeAssets.js';
import { ownsCosmetic, cosmeticPads } from './FullJourney.js';
import { importedNPCs } from './NPCRoutines.js';
import { COSMETIC_STEPS } from './PurchaseCategories.js';

function wedgeGeometry() {
  const g = new BufferGeometry();
  const v = [[-.5,-.5,-.5],[.5,-.5,-.5],[-.5,-.5,.5],[.5,-.5,.5],[-.5,.5,.5],[.5,.5,.5]];
  const triangles = [0,2,1,1,2,3,2,4,3,3,4,5,0,4,2,1,3,5,0,1,4,1,5,4];
  for (let i = 0; i < triangles.length; i += 3) [triangles[i + 1], triangles[i + 2]] = [triangles[i + 2], triangles[i + 1]];
  g.setAttribute('position', new Float32BufferAttribute(triangles.flatMap(i => v[i]), 3)); g.computeVertexNormals(); return g;
}
export class TycoonEnvironment {
  readonly root = new Group();
  readonly cameraObstacles: Mesh[] = [];
  private readonly colliders: Body[] = [];
  private signature = '';
  private readonly npcStems: string[];
  private readonly geometries: Record<string, BufferGeometry> = {
    Block: new BoxGeometry(1, 1, 1), WedgePart: wedgeGeometry(),
    Ball: new SphereGeometry(.5, 12, 8), Cylinder: new CylinderGeometry(.5, .5, 1, 12).rotateZ(Math.PI / 2),
  };
  private readonly colliderGeometry = new BoxGeometry(1, 1, 1);
  private readonly colliderMaterial = new MeshBasicMaterial({ visible: false });
  constructor(readonly parts: ImportedPart[], private physics: World) { this.root.name = 'Sell Cars Integration'; this.npcStems = importedNPCs(parts).map(npc => npc.stem + '.'); }
  static async load(baseUrl: string, physics: World) {
    const response = await fetch(assetUrl(`${baseUrl}tycoon/dealership.json`));
    if (!response.ok) throw new Error(`Dealership import: HTTP ${response.status}`);
    const data = await response.json() as { parts: ImportedPart[] };
    if (!Array.isArray(data.parts) || !data.parts.length) throw new Error('Missing authored dealership parts');
    return new TycoonEnvironment(data.parts, physics);
  }
  sync(s: TycoonState, reviewStep?: number) {
    const signature = reviewStep === undefined ? `${s.journey?.step ?? 'opening'}:${s.pads.join('|')}:${s.journey?.cosmetics?.join('|') ?? 'legacy'}` : `review:${reviewStep}`;
    if (signature === this.signature && this.root.children.length) return;
    this.signature = signature; this.clear();
    const step = reviewStep ?? s.journey?.step ?? openingStep(s);
    const legacyStep = s.journey && s.pads.length ? openingStep({ ...s, journey: undefined }) : 0;
    const batches = new Map<string, { part: ImportedPart; pose: PartPose }[]>();
    for (const part of this.parts) {
      if (this.npcStems.some(stem => part.path.startsWith(stem))) continue;
      if (reviewStep === undefined && s.journey && !ownsCosmetic(s, part.attributes.FJ_First)) continue;
      const cosmetic = reviewStep === undefined && s.journey && COSMETIC_STEPS.has(part.attributes.FJ_First);
      const retirement = part.attributes.FJ_Retire;
      const partStep = cosmetic ? Math.max(part.attributes.FJ_First, Math.min(step,
        retirement > part.attributes.FJ_First ? retirement - 1 : step)) : step;
      let pose = partPose(part, partStep, reviewStep === undefined && !s.journey ? s : undefined);
      if (cosmetic) pose.collide = false;
      if (!pose.visible && reviewStep === undefined && legacyStep > step) {
        const inherited = partPose(part, legacyStep, { ...s, journey: undefined });
        if (inherited.visible) pose = inherited;
      }
      if (!pose.visible) continue;
      if (pose.collide) this.addCollider(part, pose);
      if (pose.transparency >= 1) continue;
      const shape = part.mesh?.type === 'Sphere' || part.mesh?.type === 'Head' ? 'Ball' : part.shape;
      const key = `${shape}:${pose.material}:${pose.transparency}`;
      const batch = batches.get(key) ?? []; batch.push({ part, pose }); batches.set(key, batch);
      if (part.labels) this.addLabels(part, pose);
    }
    for (const [key, batch] of batches) {
      const [shape, material] = key.split(':'), opacity = 1 - batch[0].pose.transparency;
      const metal = ['Metal', 'DiamondPlate', 'Foil', 'CorrodedMetal'].includes(material);
      const mat = new MeshStandardMaterial({ color: 0xffffff, roughness: material === 'Glass' ? .15 : metal ? .5 : .85,
        metalness: metal ? .35 : 0, opacity, transparent: opacity < 1, depthWrite: opacity >= 1, side: DoubleSide });
      if (material === 'Neon') { mat.emissive.setHex(0x999999); mat.emissiveIntensity = .5; }
      const mesh = new InstancedMesh(this.geometries[shape] ?? this.geometries.Block, mat, batch.length);
      mesh.name = key; mesh.frustumCulled = false; mesh.castShadow = opacity >= 1; mesh.receiveShadow = true;
      for (let i = 0; i < batch.length; i++) {
        const { part, pose } = batch[i], matrix = frameMatrix(pose.cf);
        if (part.mesh) matrix.multiply(new Matrix4().makeTranslation(...part.mesh.offset));
        const scale = new Vector3(...pose.size);
        if (part.mesh?.type === 'Sphere') scale.multiply(new Vector3(...part.mesh.scale));
        matrix.scale(scale); mesh.setMatrixAt(i, matrix); mesh.setColorAt(i, new Color(...pose.color));
      }
      mesh.instanceMatrix.needsUpdate = true; if (mesh.instanceColor) mesh.instanceColor.needsUpdate = true;
      this.root.add(mesh);
    }
    this.addCustomerParking(step);
    if (reviewStep === undefined && s.journey && ownsCosmetic(s, 222)) this.addArrivalGarden();
    this.root.updateMatrixWorld(true);
    if (s.journey && reviewStep === undefined) {
      const positions: Record<string, Vec> = {};
      for (const pad of cosmeticPads(s)) positions[pad.id] = this.purchasePosition(pad.sourcePosition);
      s.journey.cosmeticPadPositions = positions;
    }
  }
  private addCustomerParking(step: number) {
    for (const part of this.parts.filter(p => /SalesCar.*\.Body$/.test(p.path) && p.attributes.FJ_First > 6 && p.attributes.FJ_First <= step)) {
      const cf = [...part.attributes.FJ_CF] as typeof part.attributes.FJ_CF; cf[1] = 1.72;
      const matrix = frameMatrix(cf);
      const ground = new Mesh(new BoxGeometry(14, .035, 20), new MeshStandardMaterial({ color: 0x48535a, roughness: 1 }));
      ground.name = 'Customer parking surface'; ground.applyMatrix4(matrix); ground.receiveShadow = true; this.root.add(ground);
      for (const x of [-6.5, 6.5]) {
        const line = new Mesh(new BoxGeometry(.2, .02, 19), new MeshBasicMaterial({ color: 0xe8e6c9 }));
        line.name = 'Customer parking stripe'; line.position.set(x, .035, 0); line.applyMatrix4(matrix); this.root.add(line);
      }
    }
  }
  private addArrivalGarden() {
    // This source purchase changed palette only; give its independent blue pad a visible result.
    for (const side of [-1, 1]) {
      const position = new Vector3(3086 + side * 11, 2.6, 32).sub(SOURCE_ORIGIN).add(LOT_ORIGIN);
      const planter = new Mesh(new BoxGeometry(7, 1.6, 4), new MeshStandardMaterial({ color: 0xb9a37f, roughness: 1 }));
      planter.name = 'Optional arrival garden planter'; planter.position.copy(position); this.root.add(planter);
      for (const x of [-2, 0, 2]) {
        const shrub = new Mesh(new SphereGeometry(1.5, 8, 5), new MeshStandardMaterial({ color: x === 0 ? 0x709666 : 0x55764d, roughness: 1 }));
        shrub.name = 'Optional arrival garden shrub'; shrub.position.copy(position).add(new Vector3(x, 1.4, 0)); this.root.add(shrub);
      }
    }
  }
  /** FullJourneyService padPlacement: ground support plus six-stud clearance,
   * with cardinal searches and the source's front-lane fallback. */
  purchasePosition(suggestion: Vec, reserved: Vec[] = []): Vec {
    const candidates = [suggestion];
    for (const radius of [8, 16, 24]) for (const [x, z] of [[radius, 0], [-radius, 0], [0, radius], [0, -radius]]) candidates.push([suggestion[0] + x, suggestion[1], suggestion[2] + z]);
    candidates.push([3035, 1.9, 58], [3035, 1.75, 48]);
    const ray = new Raycaster();
    for (const [x, , z] of candidates) {
      if (reserved.some(p => Math.hypot(x - p[0], z - p[2]) < 8)) continue;
      const origin = new Vector3(x, 12, z).sub(SOURCE_ORIGIN).add(LOT_ORIGIN);
      ray.set(origin, new Vector3(0, -1, 0)); ray.far = 20;
      const hit = ray.intersectObjects(this.cameraObstacles, false).find(h => h.face && h.face.normal.clone().transformDirection(h.object.matrixWorld).y > .8);
      if (!hit || hit.point.y + SOURCE_ORIGIN.y > 4.5) continue;
      const y = hit.point.y, blocked = this.colliders.some(b => {
        b.updateAABB(); const lo = b.aabb.lowerBound, hi = b.aabb.upperBound, m = METERS_PER_UNIT;
        return hi.y > (y + .3) * m && lo.y < (y + 6) * m
          && hi.x > (origin.x - 3) * m && lo.x < (origin.x + 3) * m
          && hi.z > (origin.z - 3) * m && lo.z < (origin.z + 3) * m;
      });
      if (!blocked) return [x, y + SOURCE_ORIGIN.y + .12, z];
    }
    return [3035, 1.75, 48];
  }
  private addCollider(part: ImportedPart, pose: PartPose) {
    const matrix = frameMatrix(pose.cf), pos = new Vector3(), q = new Quaternion(), scale = new Vector3();
    matrix.decompose(pos, q, scale);
    const half = pose.size.map(n => n * METERS_PER_UNIT / 2) as [number, number, number];
    const shape = part.shape === 'WedgePart' ? new ConvexPolyhedron({
      vertices: [[-1,-1,-1],[1,-1,-1],[-1,-1,1],[1,-1,1],[-1,1,1],[1,1,1]].map(v => new Vec3(v[0] * half[0], v[1] * half[1], v[2] * half[2])),
      faces: [[0,1,3,2],[2,3,5,4],[0,2,4],[1,5,3],[0,4,5,1]],
    }) : new Box(new Vec3(...half));
    const body = new Body({ mass: 0, position: new Vec3(pos.x * METERS_PER_UNIT, pos.y * METERS_PER_UNIT, pos.z * METERS_PER_UNIT),
      quaternion: new PhysicsQuaternion(q.x, q.y, q.z, q.w), material: this.physics.defaultMaterial,
      shape });
    this.physics.addBody(body); this.colliders.push(body);
    // Separate unrendered surfaces keep camera ray tests proportional to collision geometry.
    const obstacle = new Mesh(part.shape === 'WedgePart' ? this.geometries.WedgePart : this.colliderGeometry, this.colliderMaterial);
    obstacle.name = part.path; obstacle.matrixAutoUpdate = false; obstacle.matrix.copy(frameMatrix(pose.cf, pose.size));
    obstacle.updateMatrixWorld(true); this.cameraObstacles.push(obstacle);
  }
  private addLabels(part: ImportedPart, pose: PartPose) {
    // SurfaceGui text is kept on the original face, with a browser canvas font fallback.
    const faces = new Map<string, NonNullable<ImportedPart['labels']>>();
    for (const label of part.labels ?? []) { const list = faces.get(label.face) ?? []; list.push(label); faces.set(label.face, list); }
    for (const [face, labels] of faces) {
      const canvas = document.createElement('canvas'); canvas.width = 512; canvas.height = 256;
      const ctx = canvas.getContext('2d')!;
      for (const l of labels) {
        if (l.backgroundTransparency < 1) { ctx.fillStyle = new Color(...l.background).getStyle(); ctx.globalAlpha = 1 - l.backgroundTransparency; ctx.fillRect(0, 0, 512, 256); }
        ctx.globalAlpha = 1; ctx.fillStyle = new Color(...l.color).getStyle(); ctx.textAlign = 'center'; ctx.textBaseline = 'middle';
        const words = l.text.replace(/<[^>]*>/g, '').split('\n'); const max = Math.max(...words.map(w => w.length), 1);
        const size = Math.min(48, 780 / max, 180 / words.length); ctx.font = `bold ${size}px system-ui`;
        words.forEach((line, i) => ctx.fillText(line, 256, 128 + (i - (words.length - 1) / 2) * size * 1.18, 480));
      }
      const texture = new CanvasTexture(canvas), material = new MeshBasicMaterial({ map: texture, transparent: true, side: DoubleSide, depthWrite: false });
      const sx = face === 'Left' || face === 'Right' ? pose.size[2] : pose.size[0];
      const sy = face === 'Top' || face === 'Bottom' ? pose.size[2] : pose.size[1];
      const label = new Mesh(new PlaneGeometry(sx, sy), material);
      const local = new Matrix4();
      if (face === 'Back') local.makeTranslation(0, 0, pose.size[2] / 2 + .012);
      else if (face === 'Top') local.makeTranslation(0, pose.size[1] / 2 + .012, 0).multiply(new Matrix4().makeRotationX(-Math.PI / 2));
      else if (face === 'Bottom') local.makeTranslation(0, -pose.size[1] / 2 - .012, 0).multiply(new Matrix4().makeRotationX(Math.PI / 2));
      else if (face === 'Left' || face === 'Right') local.makeTranslation((face === 'Left' ? -1 : 1) * (pose.size[0] / 2 + .012), 0, 0).multiply(new Matrix4().makeRotationY(face === 'Left' ? -Math.PI / 2 : Math.PI / 2));
      else local.makeTranslation(0, 0, -pose.size[2] / 2 - .012).multiply(new Matrix4().makeRotationY(Math.PI));
      label.matrixAutoUpdate = false; label.matrix.copy(frameMatrix(pose.cf).multiply(local)); this.root.add(label);
    }
  }
  /** Coarse walk routing around solid furniture, with the same physical controller doing movement. */
  walkPath(from: Vector3, to: Vector3): Vector3[] {
    const size = 4, minX = Math.min(from.x, to.x) - 45, minZ = Math.min(from.z, to.z) - 45;
    const width = Math.ceil((Math.abs(to.x - from.x) + 90) / size), height = Math.ceil((Math.abs(to.z - from.z) + 90) / size);
    const cell = (v: Vector3) => [Math.floor((v.x - minX) / size), Math.floor((v.z - minZ) / size)];
    const [sx, sz] = cell(from), [tx, tz] = cell(to), start = sz * width + sx, goal = tz * width + tx;
    const blocked = new Set<number>();
    for (const b of this.colliders) {
      b.updateAABB(); const low = b.aabb.lowerBound.scale(1 / METERS_PER_UNIT), high = b.aabb.upperBound.scale(1 / METERS_PER_UNIT);
      if (high.y < from.y - 2.6 || low.y > from.y + 3.4) continue;
      for (let z = Math.max(0, Math.floor((low.z - 1.7 - minZ) / size)); z <= Math.min(height - 1, Math.floor((high.z + 1.7 - minZ) / size)); z++)
        for (let x = Math.max(0, Math.floor((low.x - 1.7 - minX) / size)); x <= Math.min(width - 1, Math.floor((high.x + 1.7 - minX) / size)); x++) blocked.add(z * width + x);
    }
    blocked.delete(start); blocked.delete(goal);
    const queue = [start], parents = new Map<number, number>([[start, start]]);
    for (let head = 0; head < queue.length && head < 16000; head++) {
      const at = queue[head]; if (at === goal) break;
      const x = at % width, z = Math.floor(at / width);
      for (const [dx, dz] of [[1, 0], [-1, 0], [0, 1], [0, -1]]) {
        const nx = x + dx, nz = z + dz, key = nz * width + nx;
        if (nx < 0 || nz < 0 || nx >= width || nz >= height || blocked.has(key) || parents.has(key)) continue;
        parents.set(key, at); queue.push(key);
      }
    }
    if (!parents.has(goal)) return [to];
    const path: Vector3[] = [to]; let at = goal;
    while (at !== start) { path.push(new Vector3(minX + (at % width + .5) * size, from.y, minZ + (Math.floor(at / width) + .5) * size)); at = parents.get(at)!; }
    return path.reverse();
  }
  private clear() {
    for (const body of this.colliders) this.physics.removeBody(body); this.colliders.length = 0; this.cameraObstacles.length = 0;
    for (const child of [...this.root.children]) {
      if (child instanceof Mesh) {
        const materials = Array.isArray(child.material) ? child.material : [child.material];
        for (const m of materials) { if ('map' in m) (m as MeshBasicMaterial).map?.dispose(); m.dispose(); }
        if (!(child instanceof InstancedMesh)) child.geometry.dispose();
      }
      child.removeFromParent();
    }
  }
  dispose() { this.clear(); Object.values(this.geometries).forEach(g => g.dispose()); this.colliderGeometry.dispose(); this.colliderMaterial.dispose(); this.root.removeFromParent(); }
}
