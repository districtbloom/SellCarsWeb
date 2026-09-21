import { Vector3 } from 'three';
import { Vec3 } from 'cannon-es';
import type { CarInstance } from '../driving/CarInstance.js';
import type { DrivingSystem } from '../driving/DrivingSystem.js';
import { METERS_PER_UNIT } from '../driving/CarRig.js';
import { logicalPoint, worldPoint } from './TycoonCoordinates.js';
import { garageVehicles, personalModel } from './PersonalCars.js';
import { CarPaint } from './CarPaint.js';
import type { PersonalCar, TycoonState } from './types.js';

/** Uses the existing physical car, so the selected model keeps its real handling. */
export class PersonalCarController {
  private car?: CarInstance;
  private state?: PersonalCar;
  private scripted = false;
  private readonly paint = new CarPaint();
  constructor(private driving: DrivingSystem) {}

  sync(s: TycoonState) {
    const p = s.personal, id = personalModel(p);
    if (this.car?.id !== id || p !== this.state) {
      this.driving.setScriptedCar(); this.scripted = false;
      if (this.car && this.car.id !== id) this.car.restoreAuthoredPose();
      this.car = this.driving.cars.find(car => car.id === id); this.state = p;
      if (this.car && p) this.place(p, true);
    }
    if (!this.car || !p) return;
    this.paint.apply(this.car.car, garageVehicles(s).find(c => c.id === p.id)?.paint);
    if (p.route) {
      this.driving.setScriptedCar(this.car.id); this.scripted = true;
      this.place(p, false);
    } else if (this.scripted) {
      this.place(p, true); this.driving.setScriptedCar(); this.scripted = false;
    } else {
      const { body } = this.car.physics;
      p.pos = logicalPoint(new Vector3(body.position.x, body.position.y, body.position.z).multiplyScalar(1 / METERS_PER_UNIT));
      const forward = body.quaternion.vmult(new Vec3(0, 0, -1));
      p.yaw = Math.atan2(-forward.x, -forward.z);
      const clearance = Math.max(...this.car.rig.spec.wheels.map(wheel => wheel.radius - wheel.center.y));
      p.height = (body.position.y - clearance - .08) / METERS_PER_UNIT;
    }
  }

  private place(p: PersonalCar, remember: boolean) {
    const point = worldPoint(p.pos), car = this.car!;
    if (!p.route && p.height !== undefined) point.y = p.height;
    else {
      let ground = -Infinity;
      this.driving.physics.world.raycastAll(new Vec3(point.x * METERS_PER_UNIT, 3, point.z * METERS_PER_UNIT),
        new Vec3(point.x * METERS_PER_UNIT, -10, point.z * METERS_PER_UNIT), { skipBackfaces: true }, hit => {
          if (hit.body !== car.physics.body && hit.body !== this.driving.player.body && hit.hitNormalWorld.y > .65) ground = Math.max(ground, hit.hitPointWorld.y);
        });
      point.y = Number.isFinite(ground) ? ground / METERS_PER_UNIT : 0;
    }
    car.place(point, p.route || this.scripted ? Math.PI - (p.angle ?? 0) : p.yaw ?? Math.PI, remember);
    if (remember && !p.route && !this.driving.isDriving) {
      const body = car.physics.body, player = this.driving.player;
      body.updateAABB(); player.body.updateAABB();
      if (body.aabb.overlaps(player.body.aabb)) {
        const exit = player.findExit(body); if (exit) player.place(exit);
      }
    }
  }

  walkingTarget() {
    if (!this.car) return undefined;
    const exit = this.driving.player.findExit(this.car.physics.body);
    return exit ? new Vector3(exit.x, exit.y, exit.z).multiplyScalar(1 / METERS_PER_UNIT) : undefined;
  }
  dispose() { this.paint.dispose(); this.driving.setScriptedCar(); }
}
