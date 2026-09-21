import { PCFSoftShadowMap, sRGBEncoding, WebGLRenderer } from "three";

export function createRenderer() {
  const renderer = new WebGLRenderer({
    antialias: true,
    // Preserve tiny surface separations when viewing the far side of the campus.
    logarithmicDepthBuffer: true,
  });

  renderer.physicallyCorrectLights = true;
  renderer.outputEncoding = sRGBEncoding;
  renderer.shadowMap.enabled = true;
  renderer.shadowMap.type = PCFSoftShadowMap;

  return renderer;
}
