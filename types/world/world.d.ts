export declare class World {
    private camera;
    private scene;
    private renderer;
    private loop;
    private controls;
    constructor(container: HTMLElement | null);
    render(): void;
    start(): void;
    stop(): void;
}
