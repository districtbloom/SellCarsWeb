import { PCFSoftShadowMap, sRGBEncoding, WebGLRenderer } from "three";

export function createRenderer() {
  const renderer = new WebGLRenderer({
    antialias: true,
  });

  renderer.physicallyCorrectLights = true;
  renderer.outputEncoding = sRGBEncoding;
  renderer.shadowMap.enabled = true;
  renderer.shadowMap.type = PCFSoftShadowMap;

  return renderer;
}
