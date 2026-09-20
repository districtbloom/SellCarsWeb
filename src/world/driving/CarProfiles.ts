import { defaultTuning, type VehicleTuning } from './VehiclePhysics.js';

// Visual/gameplay estimates: screenshot order is Car 14 (left) to Car 1 (right).
// Every car retains the requested rear-wheel-drive layout.
const profiles = [
  [1, 'Track racer', 650, 1150, 12500, 280, 0.42, 0.20, 48, 0.12, 3.0],
  [2, 'Heavy pickup', 320, 2350, 10000, 165, 0.44, 0.36, 38, 0.26, 2.15],
  [3, 'Tow truck', 260, 2900, 11000, 125, 0.42, 0.38, 42, 0.28, 2.1],
  [4, 'Utility pickup', 240, 2000, 8500, 155, 0.46, 0.34, 36, 0.25, 2.1],
  [5, 'Compact off-roader', 165, 1550, 6500, 140, 0.52, 0.38, 32, 0.30, 2.25],
  [6, 'Sports roadster', 300, 1250, 8500, 230, 0.50, 0.24, 42, 0.16, 2.65],
  [7, 'Boxy van', 140, 1800, 6000, 135, 0.44, 0.34, 34, 0.24, 2.0],
  [8, 'Family minivan', 180, 1650, 6500, 155, 0.46, 0.32, 33, 0.22, 2.15],
  [9, 'Older compact', 85, 1000, 3700, 120, 0.52, 0.30, 30, 0.20, 1.9],
  [10, 'City hatchback', 105, 1050, 4300, 140, 0.55, 0.28, 32, 0.18, 2.1],
  [11, 'Tall off-roader', 220, 2050, 8200, 150, 0.48, 0.42, 36, 0.32, 2.3],
  [12, 'Sport coupe', 230, 1300, 7200, 205, 0.50, 0.26, 40, 0.17, 2.5],
  [13, 'Boxy sedan', 125, 1250, 4700, 145, 0.48, 0.32, 32, 0.22, 2.05],
  [14, 'Everyday sedan', 150, 1200, 5200, 130, 0.48, 0.30, 35, 0.20, 2.2],
] as const;

export function carProfile(id: number): { label: string; tuning: VehicleTuning } {
  const row = profiles.find(profile => profile[0] === id);
  if (!row) throw new Error(`No vehicle profile for Car ${id}`);
  const [, label, horsepower, mass, engineForce, maxSpeedKmh, maxSteer,
    suspensionRestLength, suspensionStiffness, suspensionTravel, tireGrip] = row;
  return { label, tuning: { ...defaultTuning, horsepower, mass, engineForce, maxSpeedKmh, maxSteer,
    suspensionRestLength, suspensionStiffness, suspensionTravel, tireGrip,
    brakeForce: mass * 25,
    dampingCompression: 4.4 * Math.sqrt(suspensionStiffness / 35),
    dampingRelaxation: 5.2 * Math.sqrt(suspensionStiffness / 35) } };
}
