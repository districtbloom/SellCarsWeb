/** Shared pixel geometry for the rendered bottle and its actual pouring tip. */
export const BOTTLE_WIDTH = 64;
export const BOTTLE_HEIGHT = BOTTLE_WIDTH * 90 / 70;
export function bottleTip(x: number, y: number, angle: number) {
  const radians = angle * Math.PI / 180, dx = (52 - 35) * BOTTLE_WIDTH / 70, dy = (5 - 45) * BOTTLE_HEIGHT / 90;
  return { x: x + dx * Math.cos(radians) - dy * Math.sin(radians), y: y + dx * Math.sin(radians) + dy * Math.cos(radians) };
}
export interface FunnelBounds { left: number; top: number; width: number; height: number }
export function aboveFunnel(tip: { x: number; y: number }, funnel: FunnelBounds) {
  return tip.x >= funnel.left + 3 && tip.x <= funnel.left + funnel.width - 3 && tip.y >= 0 && tip.y < funnel.top;
}
