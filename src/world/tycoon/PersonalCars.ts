import { carProfile } from '../driving/CarProfiles.js';
import { DEALERSHIP_GARAGE } from '../TownPlaces.js';
import type { VehicleTuning } from '../driving/VehiclePhysics.js';
import type { GarageVehicle, PersonalCar, TycoonState } from './types.js';

export interface PersonalCarOption { id: number; name: string; price: number; description: string; tuning: VehicleTuning }
export const GARAGE_ENTRY: [number, number] = [DEALERSHIP_GARAGE[0] + 3, DEALERSHIP_GARAGE[1] - 8];
// Appearance notes and handling profiles from docs/car-profiles.md. Prices are game
// balance: performance carries a premium, with extra value for utility and off-road capability.
const lineup = [
  [9, 1500, 'A light, older compact. Modest power and an easy first car.'],
  [10, 2400, 'A small city hatchback with light weight and nimble steering.'],
  [13, 3200, 'A boxy sedan with a little more power for everyday trips.'],
  [14, 3900, 'An everyday sedan with balanced grip, weight and power.'],
  [7, 4800, 'A boxy work van. Heavier and steady, with useful low-speed pull.'],
  [8, 6200, 'A family minivan with more power and a comfortable suspension setup.'],
  [5, 7400, 'A compact off-roader with long suspension travel and generous steering.'],
  [4, 9800, 'A utility pickup with a strong engine and a heavy, planted chassis.'],
  [11, 11800, 'A tall off-roader with the longest suspension and plenty of ground clearance.'],
  [3, 13500, 'A heavy tow truck. Strong pulling force, with a modest cruising speed.'],
  [12, 16500, 'A low sport coupe with firm suspension, strong grip and lively acceleration.'],
  [2, 21000, 'A heavy pickup with a powerful engine and strong low-speed drive.'],
  [6, 28500, 'A light sports roadster with quick acceleration and a high speed setting.'],
  [1, 65000, 'A dedicated track racer. The most power, the highest speed and the strongest grip.'],
] as const;
export const personalCars: readonly PersonalCarOption[] = lineup.map(([id, price, description]) => {
  const profile = carProfile(id); return { id, price, description, name: profile.label, tuning: profile.tuning };
});
export const personalCarOption = (id: number) => personalCars.find(car => car.id === id);
// Existing saves earned a coupe: preserve that entitlement using the authored sport coupe.
export const personalModel = (car?: PersonalCar) => car ? car.modelId ?? 12 : undefined;
export const ownedPersonalModels = (car?: PersonalCar): readonly number[] => car ? car.ownedModels ?? [personalModel(car)!] : [];
export const garageUnlocked = (s: TycoonState) => !!s.personal || !!s.garage?.length || (s.journey?.tutorialComplete ?? s.sales > 0);

const adjectives = ['Amber', 'Midnight', 'Silver', 'Golden', 'Crimson', 'Cobalt', 'Lucky', 'Velvet', 'Wild', 'Quiet', 'Starlit', 'Copper'];
const nouns = ['Comet', 'Falcon', 'Wanderer', 'Arrow', 'Echo', 'Ranger', 'Sparrow', 'Thunder', 'Voyager', 'Ember', 'Spirit', 'Meteor'];
export const garageName = (serial: number) => `${adjectives[(serial - 1) % adjectives.length]} ${nouns[Math.floor((serial - 1) / adjectives.length) % nouns.length]} ${String(serial).padStart(3, '0')}`;
/** Read-only legacy projection keeps old saves usable before their first garage action. */
export function garageVehicles(s: TycoonState): GarageVehicle[] {
  if (s.garage && (!s.personal || s.garage.some(c => c.id === s.personal!.id))) return s.garage;
  if (s.garage && s.personal) return [...s.garage, { id: s.personal.id, name: garageName((s.garageSerial ?? s.garage.length) + 1), modelId: personalModel(s.personal)! }];
  return ownedPersonalModels(s.personal).map((modelId, i) => ({
    id: modelId === personalModel(s.personal) ? s.personal!.id : 'legacy-' + modelId,
    name: garageName(i + 1), modelId,
  }));
}
export function ensureGarage(s: TycoonState) {
  s.garage = garageVehicles(s);
  s.garageSerial = Math.max(s.garageSerial ?? 0, s.garage.length);
  return s.garage;
}
export function addGarageVehicle(s: TycoonState, modelId: number, paint?: string, sourceCarId?: string) {
  const cars = ensureGarage(s), serial = ++s.garageSerial!;
  const vehicle: GarageVehicle = { id: 'garage-' + serial, name: garageName(serial), modelId, paint, sourceCarId };
  cars.push(vehicle);
  if (s.personal) s.personal.ownedModels = [...new Set(cars.map(c => c.modelId))];
  return vehicle;
}
export const GARAGE_PAINTS = [
  ['Cream', '#ead8aa'], ['Blue', '#357dc3'], ['Red', '#b54736'], ['Green', '#3d8063'],
  ['Black', '#24282e'], ['White', '#ecedef'], ['Gold', '#c9973e'], ['Purple', '#79549e'],
] as const;
