import { CanvasTexture, Group, Sprite, SpriteMaterial } from 'three';

/** Attach to the character root so idle head motion never shakes the text. */
export function nameNPC(person: Group, name: string) {
  if (person.userData.npcName === name) return;
  let label = person.getObjectByName('NPC name') as Sprite | undefined;
  if (!label) {
    label = new Sprite(new SpriteMaterial({ transparent: true, depthTest: true, depthWrite: false }));
    label.name = 'NPC name'; label.position.y = 5; label.scale.set(12, 2, 1); person.add(label);
  }
  const canvas = document.createElement('canvas'); canvas.width = 512; canvas.height = 96;
  const context = canvas.getContext('2d')!;
  context.textAlign = 'center'; context.textBaseline = 'middle'; context.font = 'bold 38px system-ui';
  context.lineJoin = 'round'; context.lineWidth = 9; context.strokeStyle = '#182c31';
  context.strokeText(name, 256, 48, 492); context.fillStyle = '#fff6dd'; context.fillText(name, 256, 48, 492);
  label.material.map?.dispose(); label.material.map = new CanvasTexture(canvas); label.material.needsUpdate = true;
  person.userData.npcName = name;
}
