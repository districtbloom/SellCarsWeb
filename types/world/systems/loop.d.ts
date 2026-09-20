import { PerspectiveCamera, Scene, WebGLRenderer } from "three";
export declare type Updatable<T = unknown> = T & {
    tick?: (delta: number) => void;
};
export declare class Loop {
    updatables: Updatable[];
    private camera;
    private scene;
    private renderer;
    private clock;
    constructor(camera: PerspectiveCamera, scene: Scene, renderer: WebGLRenderer);
    start(): void;
    stop(): void;
    tick(): void;
}
