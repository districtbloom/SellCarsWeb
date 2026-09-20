import { Body, Box, Vec3, World as PhysicsWorld } from 'cannon-es';
import { BoxGeometry, BufferGeometry, CanvasTexture, Color, ConeGeometry, Float32BufferAttribute, Fog, Group,
  InstancedMesh, Matrix4, Mesh, MeshBasicMaterial, MeshStandardMaterial, Quaternion, Scene, Vector3 } from 'three';
import { BlockCharacterAnimator, createNPCCharacter, disposeBlockCharacter } from './components/blockCharacter.js';
import { METERS_PER_UNIT } from './driving/CarRig.js';
import { COURIER_DEPOT } from './TownPlaces.js';

type Piece = { position: Vector3; size: Vector3; color: Color; yaw: number };
type Shape = 'box' | 'roof' | 'tree';
export interface TownLot { zone: 'residential' | 'commercial' | 'service' | 'park'; x: number; z: number; width: number; depth: number }
export const TOWN_ROAD_X = [140, 360, 580, 800, 1020];
export const TOWN_ROAD_Z = [-480, -260, -40, 180, 400, 620];

/** Seeded American town. Small shared-mesh batches and simple building colliders keep its cost bounded. */
export class OpenWorldTown {
  readonly root = new Group();
  readonly cameraObstacles: Mesh[] = [];
  readonly lots: TownLot[] = [];
  private readonly bodies: Body[] = [];
  private readonly batches = new Map<string, { shape: Shape; pieces: Piece[]; center: Vector3 }>();
  private readonly chunks: { mesh: InstancedMesh; center: Vector3 }[] = [];
  private readonly material = new MeshStandardMaterial({ roughness: .95 });
  private readonly colliderMaterial = new MeshBasicMaterial({ visible: false });
  private readonly geometries: Record<Shape, BufferGeometry>;
  private readonly labels: { text: string; x: number; y: number; z: number; width: number; yaw: number }[] = [];
  private readonly pedestrians: { character: Group; animator: BlockCharacterAnimator; x: number; z: number; phase: number }[] = [];
  private sign?: Mesh;
  private seed: number;

  constructor(scene: Scene, private physics: PhysicsWorld, private focus: () => Vector3, seed = 314159) {
    this.seed = seed; this.root.name = 'Maple County open world';
    const roof = new BufferGeometry();
    roof.setAttribute('position', new Float32BufferAttribute([
      -.5,-.5,-.5, .5,-.5,-.5, 0,.5,-.5, -.5,-.5,.5, .5,-.5,.5, 0,.5,.5,
    ], 3));
    roof.setIndex([0,2,1,3,4,5,0,3,5,0,5,2,1,2,5,1,5,4,0,1,4,0,4,3]);
    const flatRoof = roof.toNonIndexed(); flatRoof.computeVertexNormals(); roof.dispose();
    this.geometries = { box: new BoxGeometry(1, 1, 1), roof: flatRoof, tree: new ConeGeometry(.5, 1, 6) };
    // The existing test course remains usable; extend its ground without overlapping physics floors.
    const ground = scene.getObjectByName('Driving ground');
    if (ground instanceof Mesh && ground.material instanceof MeshStandardMaterial) ground.material.color.setHex(0x71865d).convertSRGBToLinear();
    for (const [x, z, width, depth] of [[910,0,620,1480],[-650,0,100,1480],[0,-670,1200,140],[0,670,1200,140]]) {
      this.box(x,-1,z,width,2,depth,0x71865d); this.collider(x,-1,z,width,2,depth, false);
    }
    for (const x of TOWN_ROAD_X) this.road(x,70,28,1150, true);
    for (const z of TOWN_ROAD_Z) this.road(580,z,908,28, false);
    // Arrival lane and sandbox driveway connect to the same street network.
    this.road(-59.5,-260,399,24,false); this.road(-259,-133,24,254,true);
    this.road(70,40,140,24,false);
    for (let col = 0; col < 4; col++) for (let row = 0; row < 5; row++) this.block(col, row);
    this.signpost('SELL CARS', -235,-260,0);
    this.signpost('DELIVERY DRIVERS', COURIER_DEPOT.x, COURIER_DEPOT.z, 0);
    this.box(COURIER_DEPOT.x,.07,COURIER_DEPOT.z,38,.14,30,0x687071);

    this.signpost('ELIAS GARAGE', 310,-286,0);
    this.signpost('MAPLE HEIGHTS', 166,-470,0);
    this.signpost('MAIN STREET', 166,-30,0);
    this.signpost('SERVICE DISTRICT', 826,190,0);
    this.buildBatches(); this.buildSigns();
    // Pedestrians stay on plaza footpaths, away from the road lanes.
    for (const [i, lot] of this.lots.filter(lot => lot.zone === 'park').entries()) {
      const character = createNPCCharacter(`Town pedestrian ${i + 1}`, [0xc96a54,0x678cad,0xbea45b,0x6d9877][i % 4]);
      character.position.set(lot.x - 18, 3.6, lot.z - 18); this.root.add(character);
      this.pedestrians.push({ character, animator: new BlockCharacterAnimator(character, character, true), x: lot.x, z: lot.z, phase: i * 18 });
    }
    this.root.updateMatrixWorld(true); scene.add(this.root);
    scene.background = new Color(0xc5dce8); scene.fog = new Fog(0xc5dce8, 650, 1400);
    this.tick(0);
  }

  private random() { this.seed = (Math.imul(this.seed, 1664525) + 1013904223) >>> 0; return this.seed / 4294967296; }
  private choose<T>(items: T[]) { return items[Math.floor(this.random() * items.length)]; }
  private piece(shape: Shape, x: number, y: number, z: number, width: number, height: number, depth: number, color: number, yaw = 0) {
    const cellX = Math.floor(x / 220), cellZ = Math.floor(z / 220), key = `${cellX}:${cellZ}:${shape}`;
    let batch = this.batches.get(key);
    if (!batch) { batch = { shape, pieces: [], center: new Vector3(cellX * 220 + 110, 0, cellZ * 220 + 110) }; this.batches.set(key, batch); }
    batch.pieces.push({ position: new Vector3(x,y,z), size: new Vector3(width,height,depth), color: new Color(color).convertSRGBToLinear(), yaw });
  }
  private box(x: number,y: number,z: number,w: number,h: number,d: number,color: number,yaw = 0) { this.piece('box',x,y,z,w,h,d,color,yaw); }
  private collider(x: number,y: number,z: number,w: number,h: number,d: number,camera = true) {
    const k = METERS_PER_UNIT;
    const body = new Body({ mass: 0, material: this.physics.defaultMaterial, position: new Vec3(x*k,y*k,z*k), shape: new Box(new Vec3(w*k/2,h*k/2,d*k/2)) });
    this.physics.addBody(body); this.bodies.push(body);
    if (camera) {
      const obstacle = new Mesh(this.geometries.box,this.colliderMaterial); obstacle.position.set(x,y,z); obstacle.scale.set(w,h,d);
      obstacle.updateMatrixWorld(true); this.cameraObstacles.push(obstacle);
    }
  }
  private road(x: number,z: number,width: number,depth: number,vertical: boolean) {
    this.box(x,.025,z,width,.05,depth,0x41484b);
    const length = vertical ? depth : width;
    for (let p = -length/2+7; p < length/2-5; p += 14) {
      const X = vertical ? x : x+p, Z = vertical ? z+p : z;
      // Leave clear intersection boxes instead of painting dashes across cross streets.
      if ((vertical ? TOWN_ROAD_Z : TOWN_ROAD_X).some(cross => Math.abs(cross - (vertical ? Z : X)) < 17)) continue;
      for (const side of [-1,1]) this.box(X+(vertical?side*.5:0),.058,Z+(vertical?0:side*.5),vertical?.22:7,.015,vertical?7:.22,0xeac66b);
    }
    for (const side of [-1,1]) this.box(x+(vertical?side*(width/2-1):0),.054,z+(vertical?0:side*(depth/2-1)),vertical?.22:width,.012,vertical?depth:.22,0xd8dbce);
  }
  private block(col: number,row: number) {
    const x = TOWN_ROAD_X[col]+110, z = TOWN_ROAD_Z[row]+110;
    const zone = row < 2 && col < 3 || row === 4 ? 'residential' : row === 2 ? 'commercial' : row === 3 && col >= 2 ? 'service' : 'park';
    this.lots.push({ zone,x,z,width:188,depth:188 });
    this.box(x,.02,z,188,.04,188,zone==='service'?0x999789:zone==='commercial'?0x75806f:0x83966b);
    for (const side of [-1,1]) {
      for (const [X,Z,w,d] of [[x+side*92,z,5,188],[x,z+side*92,178,5]]) {
        this.box(X,.2,Z,w,.4,d,0xc5c4b6); this.collider(X,.2,Z,w,.4,d,false);
      }
    }
    if (zone === 'residential') {
      for (const dx of [-46,46]) for (const side of [-1,1]) this.house(x+dx,z+side*49,side);
    } else if (zone === 'commercial') {
      const names = ['MAPLE MARKET','JOE’S DINER','HARDWARE','COFFEE & DONUTS','PHARMACY','AUTO PARTS'];
      for (let i = 0; i < 3; i++) this.shop(x+(i-1)*58,z-20,i === 1 && (col === 0 || col === 2) ? 'CAR PART SHOP' : names[(col*3+i)%names.length]);
      this.box(x,.065,z+47,168,.04,61,0x505659);
      for (let p = -72; p <=72; p+=18) {
        this.box(x+p,.092,z+60,.25,.015,26,0xe5e2cd);
        this.box(x+p,.092,z+32,.25,.015,18,0xe5e2cd);
      }
      this.box(x,.095,z+47,168,.015,.3,0xe5e2cd);
      // A wide entrance joins the parking lot to Main Street.
      this.box(x,.06,z+82,26,.06,24,0x505659);
    } else if (zone === 'service') {
      for (const dx of [-48,48]) {
        this.box(x+dx,15,z-20,78,30,85,0x9a9e9b); this.collider(x+dx,15,z-20,78,30,85);
        this.box(x+dx,31,z-20,82,2,89,0x515d61);
        for (const offset of [-20,20]) {
          this.box(x+dx+offset,9,z+22.6,25,18,.2,0x4a555b);
          for(let y=2;y<18;y+=3)this.box(x+dx+offset,y,z+22.75,24,.18,.1,0x8e9697);
        }
        this.box(x+dx,3,z-9,80,.15,2,0xc2b07b);
      }
      if (col === 3) this.labels.push({text:'CAR PART SHOP',x:x-48,y:20,z:z+23,width:63,yaw:Math.PI});
      this.labels.push({text:'LOGISTICS & REPAIR',x,y:23,z:z+22.9,width:65,yaw:Math.PI});
    } else {
      this.box(x,.22,z,7,.44,175,0xcbbf9f); this.box(x,.22,z,175,.44,7,0xcbbf9f);
      for (const dx of [-18,18]) this.box(x+dx,.24,z,4,.48,40,0xcbbf9f);
      for (const dz of [-18,18]) this.box(x,.24,z+dz,40,.48,4,0xcbbf9f);
      this.box(x,1,z,21,2,21,0xaab6ab); this.box(x,2.1,z,17,.2,17,0x739caa);
      this.collider(x,1,z,21,2,21);
      for (const dx of [-57,57]) for (const dz of [-57,57]) this.tree(x+dx,z+dz);
      for (const dx of [-38,38]) { this.box(x+dx,1.6,z+29,12,.5,3,0x815c3c); this.box(x+dx,3,z+30.4,12,2,.4,0x815c3c); }
    }
    // Stop lines / zebra crossings are legible at driving speed.
    for (const offset of [-8,-4,0,4,8]) this.box(x-110+offset,.064,z-91,2,.02,5,0xe7e5d6);
  }
  private house(x: number,z: number,front: number) {
    const width = 33+this.random()*10, depth=29+this.random()*8, height=this.random()<.32?23:14;
    const siding=this.choose([0xd7c7a5,0xabbebc,0xc3b8ab,0xb6bd9a,0xc5a69a]), roof=this.choose([0x565b61,0x786557,0x565e51]);
    this.box(x,height/2+.45,z,width,height,depth,siding); this.collider(x,height/2+.45,z,width,height,depth);
    this.box(x,.23,z,width+2,.46,depth+2,0xb4b1a5);
    this.piece('roof',x,height+4.3,z,width+5,8,depth+5,roof);
    const wall=z+front*(depth/2+.15);
    this.box(x,4.45,wall,5,8,.25,0x654e3b);
    this.box(x,.24,wall+front*9,7,.48,18,0xc9c3b0); this.collider(x,.24,wall+front*9,7,.48,18,false);
    this.box(x,9.2,wall+front*3,12,.5,7,0xeee5d4);
    for(const dx of [-5,5])this.box(x+dx,4.7,wall+front*5.7,.55,9,.55,0xece6d4);
    for(const dx of [-width*.31,width*.31])for(const y of height>18?[7,18]:[7]) {
      this.box(x+dx,y,wall,7,5.5,.25,0xf1ebd9); this.box(x+dx,y,wall+front*.15,5.7,4.3,.1,0x587783);
      this.box(x+dx,y,wall+front*.24,.22,4.4,.1,0xf1ebd9); this.box(x+dx,y,wall+front*.24,5.8,.22,.1,0xf1ebd9);
    }
    // Detached garages, driveways, mailboxes and setbacks give the residential blocks their shape.
    const garage=x+width/2+12;
    this.box(garage,5.5,z,17,11,23,0xc0b69f); this.collider(garage,5.5,z,17,11,23);
    this.piece('roof',garage,12.3,z,20,4,26,roof);
    this.box(garage,4.6,z+front*11.6,13,9,.2,0xe3dccc);
    this.box(garage,.08,z+front*30,16,.16,38,0xb5b2a6);
    this.box(x-10,2,wall+front*22,.5,4,.5,0xddd9ca); this.box(x-10,4.4,wall+front*22,2,1.5,3,0x465363);
    this.box(x-width*.25,height+7,z+depth*.22,3,8,3,0x96695b);
    if(this.random()>.25)this.tree(x-25,z-front*21);
    // No interiors are generated: building shells remain solid, cheap collision boxes.
  }
  private shop(x: number,z: number,name: string) {
    const brick=this.choose([0xa77860,0xb7aa8c,0x8e9c99]), accent=this.choose([0x456e67,0xb2674b,0x466785]);
    this.box(x,10,z,52,20,57,brick); this.collider(x,10,z,52,20,57);
    this.box(x,21,z,55,2,60,0x515a5d);
    this.box(x,18.5,z+28.8,49,5,.5,accent);
    this.labels.push({text:name,x,y:18.5,z:z+29.1,width:46,yaw:Math.PI});
    this.box(x,12.7,z+31,54,.7,7,accent);
    for(const dx of [-17,0,17]) {
      this.box(x+dx,6,z+28.7,14,10,.3,0xede7d3); this.box(x+dx,6,z+28.9,12.5,8.7,.15,0x496d7b);
      this.box(x+dx,6,z+29, .22,9,.1,0xdadacb);
    }
    this.box(x,.2,z+33,55,.4,8,0xc9c4b7); this.collider(x,.2,z+33,55,.4,8,false);
    if(name.includes('DINER'))for(const dx of [-17,17])this.box(x+dx,23,z+31,4,3,4,0xb76952);
  }
  private tree(x: number,z: number) {
    const height=16+this.random()*10;
    this.box(x,height*.3,z,1.7,height*.6,1.7,0x796349);
    this.piece('tree',x,height*.75,z,13,height*.8,13,this.choose([0x53765b,0x608060,0x71875b]));
  }
  private signpost(text: string,x: number,z: number,yaw: number) {
    this.box(x,5,z,.5,10,.5,0x747c7c); this.box(x,10,z,25,5,.5,0x35564d,yaw);
    this.labels.push({text,x,y:10,z:z-.3,width:24,yaw});
  }
  private buildBatches() {
    const matrix=new Matrix4(),rotation=new Quaternion();
    for(const [name,batch] of this.batches) {
      const mesh=new InstancedMesh(this.geometries[batch.shape],this.material,batch.pieces.length); mesh.name=`Town ${name}`;
      mesh.frustumCulled=false; mesh.castShadow=batch.shape!=='box'; mesh.receiveShadow=true;
      batch.pieces.forEach((piece,i)=>{rotation.setFromAxisAngle(new Vector3(0,1,0),piece.yaw); matrix.compose(piece.position,rotation,piece.size);mesh.setMatrixAt(i,matrix);mesh.setColorAt(i,piece.color);});
      mesh.instanceMatrix.needsUpdate=true;if(mesh.instanceColor)mesh.instanceColor.needsUpdate=true;
      this.root.add(mesh);this.chunks.push({mesh,center:batch.center});
    }
    this.batches.clear();
  }
  private buildSigns() {
    const names=[...new Set(this.labels.map(l=>l.text))],canvas=document.createElement('canvas');canvas.width=1024;canvas.height=1024;
    const ctx=canvas.getContext('2d')!;ctx.fillStyle='#f6eed9';ctx.textAlign='center';ctx.textBaseline='middle';ctx.font='bold 64px system-ui';
    names.forEach((text,i)=>ctx.fillText(text,(i%4)*256+128,Math.floor(i/4)*128+64,244));
    const texture=new CanvasTexture(canvas),geometry=new BufferGeometry(),vertices:number[]=[],uv:number[]=[];
    for(const label of this.labels){const index=names.indexOf(label.text),left=(index%4)/4,right=left+.25,top=1-Math.floor(index/4)/8,bottom=top-.125;
      const transform=new Matrix4().makeRotationY(label.yaw).setPosition(label.x,label.y,label.z);
      // These faces point toward local -Z, so screen-left is positive local X.
      for(const [x,y,u,v] of [[-.5,-.5,right,bottom],[-.5,.5,right,top],[.5,.5,left,top],[-.5,-.5,right,bottom],[.5,.5,left,top],[.5,-.5,left,bottom]]){
        const p=new Vector3(x*label.width,y*4,0).applyMatrix4(transform);vertices.push(p.x,p.y,p.z);uv.push(u,v);
      }
    }
    geometry.setAttribute('position',new Float32BufferAttribute(vertices,3));geometry.setAttribute('uv',new Float32BufferAttribute(uv,2));geometry.computeVertexNormals();
    this.sign=new Mesh(geometry,new MeshBasicMaterial({map:texture,transparent:true,depthWrite:false}));this.sign.name='Town signs';this.root.add(this.sign);
  }
  tick(delta: number) {
    const focus=this.focus();
    for(const chunk of this.chunks)chunk.mesh.visible=Math.hypot(focus.x-chunk.center.x,focus.z-chunk.center.z)<1100;
    for(const p of this.pedestrians){p.phase=(p.phase+Math.min(delta,.1)*7)%144;const t=p.phase;
      p.character.position.set(p.x+(t<36?-18+t:t<72?18:t<108?18-(t-72):-18),4.8,p.z+(t<36?-18:t<72?-18+t-36:t<108?18:18-(t-108)));
      p.character.visible=p.character.position.distanceTo(focus)<450;p.animator.update(delta);
    }
  }
  dispose() {
    this.bodies.forEach(body=>this.physics.removeBody(body));
    this.pedestrians.forEach(p=>disposeBlockCharacter(p.character));
    for(const geometry of Object.values(this.geometries))geometry.dispose();this.material.dispose();this.colliderMaterial.dispose();
    if(this.sign){this.sign.geometry.dispose();const material=this.sign.material as MeshBasicMaterial;material.map?.dispose();material.dispose();}
    this.root.removeFromParent();this.cameraObstacles.length=0;
  }
}
