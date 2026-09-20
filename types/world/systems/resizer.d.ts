import { PerspectiveCamera, WebGLRenderer } from "three";
export declare class Resizer {
    constructor(container: HTMLElement, camera: PerspectiveCamera, renderer: WebGLRenderer);
    onResize(): void;
}
