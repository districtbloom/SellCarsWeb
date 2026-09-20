import { RaycastVehicle, Vec3, WheelInfo } from 'cannon-es';

/** Cannon's stock ray stops at rest length, leaving configured droop unused. */
export class SuspensionVehicle extends RaycastVehicle {
  override castRay(wheel: WheelInfo): number {
    if (!this.world) throw new Error('Vehicle must be added to the physics world');
    this.updateWheelTransformWorld(wheel);
    const maximumLength = wheel.suspensionRestLength + wheel.maxSuspensionTravel;
    const minimumLength = Math.max(0, wheel.suspensionRestLength - wheel.maxSuspensionTravel);
    const source = wheel.chassisConnectionPointWorld;
    const end = wheel.directionWorld.scale(maximumLength + wheel.radius).vadd(source);
    const result = wheel.raycastResult;
    result.reset();
    const previousResponse = this.chassisBody.collisionResponse;
    try {
      this.chassisBody.collisionResponse = false;
      this.world.rayTest(source, end, result);
    } finally {
      this.chassisBody.collisionResponse = previousResponse;
    }

    if (!result.body) {
      wheel.isInContact = false;
      wheel.suspensionLength = maximumLength;
      wheel.suspensionRelativeVelocity = 0;
      wheel.clippedInvContactDotSuspension = 1;
      wheel.directionWorld.scale(-1, result.hitNormalWorld);
      return -1;
    }

    wheel.isInContact = true;
    wheel.suspensionLength = Math.max(minimumLength, Math.min(maximumLength, result.distance - wheel.radius));
    const denominator = result.hitNormalWorld.dot(wheel.directionWorld);
    const velocity = new Vec3();
    this.chassisBody.getVelocityAtWorldPoint(result.hitPointWorld, velocity);
    if (denominator >= -0.1) {
      wheel.suspensionRelativeVelocity = 0;
      wheel.clippedInvContactDotSuspension = 10;
    } else {
      const inverse = -1 / denominator;
      wheel.suspensionRelativeVelocity = result.hitNormalWorld.dot(velocity) * inverse;
      wheel.clippedInvContactDotSuspension = inverse;
    }
    return result.distance;
  }
}
