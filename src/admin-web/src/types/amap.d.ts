declare namespace AMap {
  class Map {
    constructor(container: string | HTMLElement, opts?: MapOptions);
    destroy(): void;
    setCenter(center: [number, number]): void;
    setZoom(zoom: number): void;
    setFitView(overlays?: any[], immediately?: boolean, avoid?: number[]): void;
    getCenter(): LngLat;
    getZoom(): number;
    add(overlay: any | any[]): void;
    remove(overlay: any | any[]): void;
    clearMap(): void;
    on(event: string, handler: Function): void;
  }

  interface MapOptions {
    zoom?: number;
    center?: [number, number];
    viewMode?: '2D' | '3D';
    resizeEnable?: boolean;
    mapStyle?: string;
  }

  class LngLat {
    constructor(lng: number, lat: number);
    getLng(): number;
    getLat(): number;
  }

  class Marker {
    constructor(opts?: MarkerOptions);
    setMap(map: Map | null): void;
    getMap(): Map | null;
    setPosition(lnglat: [number, number] | LngLat): void;
    getPosition(): LngLat;
    setLabel(label: { content: string; offset?: [number, number] }): void;
    setContent(content: string | HTMLElement): void;
    on(event: string, handler: Function): void;
    setExtData(data: any): void;
    getExtData(): any;
    getTitle(): string;
    setTitle(title: string): void;
  }

  interface MarkerOptions {
    position?: [number, number] | LngLat;
    icon?: string | Icon;
    content?: string | HTMLElement;
    title?: string;
    label?: { content: string; offset?: [number, number] };
    offset?: Pixel;
    zIndex?: number;
    visible?: boolean;
  }

  class Icon {
    constructor(opts?: { size?: [number, number]; image?: string; imageSize?: [number, number]; imageOffset?: Pixel });
  }

  class Pixel {
    constructor(x: number, y: number);
  }

  class InfoWindow {
    constructor(opts?: { content?: string; offset?: Pixel });
    open(map: Map, pos: [number, number] | LngLat): void;
    close(): void;
    setContent(content: string): void;
  }

  class Polyline {
    constructor(opts?: { path: [number, number][]; strokeColor?: string; strokeWeight?: number; strokeOpacity?: number });
    setMap(map: Map | null): void;
  }
}
