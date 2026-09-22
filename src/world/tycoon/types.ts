export type Point = [number, number];
export type Vec = [number, number, number];
export type Grade = 'Good' | 'Worn' | 'Damaged' | 'Ruined';
export type PartId = 'Body' | 'RunningGear' | 'Mechanical' | 'Exterior';
export type Depth = 'Quick' | 'Good';
export type Condition = Record<PartId, Grade>;
export interface Pad {
  id: string; name: string; description: string; cost: number; pos: Point; after: string[];
  at: number; sourceId: string; sourcePosition: Vec; gameplayWired: boolean; category: string;
  ownedCar?: boolean; readyCar?: boolean; optional?: boolean; scope?: string;
}
export interface CarDefinition {
  id: string; name: string; rarity: string; color: string; seller: string; sellerRole: string;
  sellerLine: string; ask: number; floor: number; condition: Condition; offers: number[];
  buyer: string; buyerRole: string; buyerLine: string; buyerMax: number;
}
export interface Catalog {
  points: Record<string, Point>; pads: Pad[]; grades: Record<Grade, number>;
  base: Record<PartId, { cost: number; seconds: number; name: string }>;
  cars: CarDefinition[]; tiers: { id: string; name: string; copy: string; extra: number }[];
}
export interface Job {
  id: PartId | 'Tune' | 'Wash' | 'Body_Restoration' | 'Tune_Performance' | 'Paint_Exterior' | 'Detail_QC' | 'Photo_Listing'; name: string; cost: number; seconds: number;
  done: boolean; started: boolean; progress: number; speed?: number; manual?: boolean;
  position?: Point; staffAt?: number;
  repair?: import('./RepairGame.js').RepairProgress;
}
export interface Plan { jobs: Job[]; cost: number; seconds: number; funded?: boolean; cashCost?: number; partsCost?: number; deferredCash?: number; pricedServices?: number }
export interface Route { target: string; points: Point[]; step: number; curved?: boolean; speed?: number; reverse?: boolean }
export interface Moving { pos: Point; angle?: number; route?: Route }
export interface Look { paint: 'original' | 'cream' | 'blue' | 'red' | 'green'; wheels: 'original' | 'sport'; stripe: boolean }
export interface Quote { mode: 'buy' | 'sell'; accepted: number; line: string; reaction: 'neutral' | 'happy' | 'firm'; revision: number }
export interface Buyer { name: string; role: string; line: string; cue: string; ask: number; max: number; lowball?: boolean }
export type CarStatus = 'arriving' | 'discovery' | 'seller' | 'owned' | 'choose' | 'moving' | 'repair' | 'ready' | 'photo' | 'buyer' | 'waitingBuyer' | 'sold';
export interface TradingCar extends Moving {
  id: string; index: number; owned: boolean; status: CarStatus; condition: Condition;
  arrivalGrade: Grade; depth: Depth; workSpent: number; purchase: number; history: string[];
  remote: boolean; buyerAttempt: number; photo: boolean; listing?: boolean; quote?: Quote;
  plan?: Plan; custom?: Look; wait?: number; sale?: number; soldTo?: Buyer; receiptUntil?: number;
  keptAs?: string;
  definition?: CarDefinition;
  business?: { tutorial: boolean; templateId: string; consignment: boolean; offer?: number };
}
export interface Worker extends Moving { hired: boolean; level: number; jobs: number; activity: string; goal?: Point }
export interface PersonalCar extends Moving {
  id: string; home: Point; status: 'parked' | 'driving' | 'atLead';
  modelId?: number; ownedModels?: number[];
  // Physics yaw and height are separate from the legacy guided-route heading.
  yaw?: number; height?: number;
}
export interface GarageVehicle {
  id: string; name: string; modelId: number; paint?: string; sourceCarId?: string;
}
export interface Lead { kind: 'rare' | 'ordinary'; index: number; status: string; caller: string; text: string; remindAt?: number }
export interface Courier extends Moving { id: number; phase: 'idle' | 'outbound' | 'loading' | 'returning' | 'unloading'; wait: number; cargo: number; trips: number }
export interface TycoonState {
  cash: number; pads: string[]; sales: number; clock: number; history: TradingCar[];
  ledger: { amount: number; kind: string; subject: string }[]; worker: Worker;
  seen: boolean; lowballPassed: boolean; completed: boolean; car?: TradingCar;
  personal?: PersonalCar; lead?: Lead; rareCallAt?: number; notice?: string; noticeUntil?: number;
  garage?: GarageVehicle[]; garageSerial?: number;
  journey?: JourneyState;
  revenue?: { at: number; amount: number }[];
  parts?: { level: number; completed: number; remaining?: number; manual?: boolean };
  partsStock?: number;
  couriers?: Courier[];
  onboarding?: { welcomed?: boolean; phonePrompted?: boolean };
  raceClaims?: string[];
}
export interface JourneyState {
  step: number; tutorialComplete: boolean; cycle: number; nextSellerAt: number;
  intakePaused: boolean; automation: boolean; seenCars: string[];
  // Runtime placement is recomputed after loading; it never grants ownership.
  padPosition?: Vec;
  cosmetics?: string[];
  cosmeticPadPositions?: Record<string, Vec>;
}
export interface OfflineReceipt { seconds: number; rate: number; amount: number; capped: boolean }
export interface Receipt { buying: boolean; car: string; person: string; amount: number; purchase: number; work: number; profit?: number; line: string }
