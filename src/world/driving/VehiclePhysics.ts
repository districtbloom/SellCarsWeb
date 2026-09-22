import { Body, Box, Material, Quaternion, SAPBroadphase, Vec3, World } from 'cannon-es';
import { SuspensionVehicle } from './SuspensionVehicle.js';

export interface VehicleTuning {
  horsepower: number;
  mass: number;
  engineForce: number;
  brakeForce: number;
  maxSpeedKmh: number;
  maxSteer: number;
  suspensionRestLength: number;
  suspensionStiffness: number;
  dampingCompression: number;
  dampingRelaxation: number;
  suspensionTravel: number;
  tireGrip: number;
}

export const defaultTuning: VehicleTuning = {
  horsepower: 150,
  mass: 1200, engineForce: 5200, brakeForce: 30000, maxSpeedKmh: 130,
  maxSteer: 0.48, suspensionRestLength: 0.3, suspensionStiffness: 35,
  dampingCompression: 4.4, dampingRelaxation: 5.2, suspensionTravel: 0.2,
  tireGrip: 2.2,
};

export interface WheelSpec { center: Vec3; radius: number; front: boolean }
export interface VehicleSpec {
  position: Vec3;
  quaternion: Quaternion;
  halfExtents: Vec3;
  shapeOffset: Vec3;
  wheels: WheelSpec[];
}
export interface DriverInput { throttle: number; steering: number; brake: boolean; sprint?: boolean }

export class VehiclePhysics {
  readonly world: World;
  readonly body: Body;
  readonly vehicle: SuspensionVehicle;
  readonly tuning: VehicleTuning;
  readonly fixedStep = 1 / 120;
  poseRevision = 0;
  private accumulator = 0;
  private steering = 0;
  private throttle = 0;
  private driftAmount = 0;
  private readonly up = new Vec3();
  private readonly forward = new Vec3();
  private readonly spawnPosition: Vec3;
  private readonly spawnQuaternion: Quaternion;

  constructor(spec: VehicleSpec, tuning: Partial<VehicleTuning> = {}, world?: World) {
    this.world = world ?? new World({ gravity: new Vec3(0, -9.81, 0), allowSleep: false });
    this.tuning = { ...defaultTuning, ...tuning };
    for (const [key, value] of Object.entries(this.tuning)) {
      if (typeof value !== 'number' || !Number.isFinite(value) || value <= 0) {
        throw new Error(`Vehicle setting ${key} must be a positive number`);
      }
    }
    if (!world) this.world.broadphase = new SAPBroadphase(this.world);
    // Solid car/scenery contacts; raycast tire grip is configured separately.
    this.world.defaultContactMaterial.friction = 0.4 / 3;
    this.world.defaultContactMaterial.restitution = 0;
    this.body = new Body({
      mass: this.tuning.mass, position: spec.position, quaternion: spec.quaternion,
      material: new Material('chassis'), linearDamping: 0.015, angularDamping: 0.35,
    });
    this.body.addShape(new Box(spec.halfExtents), spec.shapeOffset);
    this.spawnPosition = spec.position.clone();
    this.spawnQuaternion = spec.quaternion.clone();
    this.vehicle = new SuspensionVehicle({ chassisBody: this.body, indexRightAxis: 0, indexUpAxis: 1, indexForwardAxis: 2 });
    for (const wheel of spec.wheels) {
      this.vehicle.addWheel({
        radius: wheel.radius,
        chassisConnectionPointLocal: wheel.center.vadd(new Vec3(0, this.tuning.suspensionRestLength, 0)),
        directionLocal: new Vec3(0, -1, 0), axleLocal: new Vec3(-1, 0, 0),
        isFrontWheel: wheel.front,
        suspensionRestLength: this.tuning.suspensionRestLength,
        suspensionStiffness: this.tuning.suspensionStiffness,
        dampingCompression: this.tuning.dampingCompression,
        dampingRelaxation: this.tuning.dampingRelaxation,
        maxSuspensionTravel: this.tuning.suspensionTravel,
        maxSuspensionForce: this.tuning.mass * 9.81,
        frictionSlip: this.tuning.tireGrip, rollInfluence: 0.08,
        useCustomSlidingRotationalSpeed: true, customSlidingRotationalSpeed: 30,
      });
    }
    this.vehicle.addToWorld(this.world);
  }

  get speed(): number {
    this.body.quaternion.vmult(new Vec3(0, 0, -1), this.forward);
    return this.body.velocity.dot(this.forward);
  }

  get isDrifting(): boolean { return this.driftAmount > 0.2; }

  addStaticBox(halfExtents: Vec3, position: Vec3, quaternion = new Quaternion()): Body {
    const body = new Body({ mass: 0, position, quaternion, shape: new Box(halfExtents), material: this.world.defaultMaterial });
    this.world.addBody(body);
    return body;
  }

  update(delta: number, input: DriverInput, beforeStep?: (dt: number) => void) {
    this.accumulator += Math.min(Math.max(delta, 0), 0.1);
    while (this.accumulator + 1e-9 >= this.fixedStep) {
      this.applyInput(input);
      beforeStep?.(this.fixedStep);
      this.world.step(this.fixedStep);
      this.accumulator -= this.fixedStep;
    }
  }

  wheelTransform(index: number) {
    const wheel = this.vehicle.wheelInfos[index];
    const contact = wheel.isInContact;
    // Steering and wheel pose update even in the air. Rendering must not erase
    // Cannon's last solved contact state, which tire forces and the HUD use.
    this.vehicle.updateWheelTransform(index);
    wheel.isInContact = contact;
    return wheel.worldTransform;
  }

  applyInput(input: DriverInput) {
    const dt = this.fixedStep;
    const speed = this.speed;
    const requestedThrottle = Math.max(-1, Math.min(1, input.throttle));
    // Space locks only the rear axle. Grip loss under speed and yaw lets the
    // rear slide while front tire forces continue to steer the rigid chassis.
    const braking = input.brake;
    const targetThrottle = braking ? 0 : requestedThrottle;
    const reverseToForward = requestedThrottle > 0 && (speed < 0 || this.throttle < 0);
    const throttleResponse = reverseToForward ? 18 : 6;
    this.throttle += (targetThrottle - this.throttle) * (1 - Math.exp(-throttleResponse * dt));
    if (braking) this.throttle = 0;
    const steeringLimit = this.tuning.maxSteer / (1 + Math.abs(speed) / 18);
    const targetSteering = Math.max(-1, Math.min(1, input.steering)) * steeringLimit;
    this.steering += (targetSteering - this.steering) * (1 - Math.exp(-24 * dt));
    const limit = this.tuning.maxSpeedKmh / 3.6;
    const speedInDriveDirection = Math.max(0, speed * Math.sign(this.throttle));
    const torqueFactor = Math.max(0, 1 - (speedInDriveDirection / limit) ** 2);
    // Stronger opposing tire force shortens the actual reversal, not just the
    // pedal ramp. Normal forward power resumes once reverse motion has stopped.
    const reversalForce = reverseToForward && this.throttle > 0 ? 3 : 1;
    const availableForce = Math.min(this.tuning.engineForce * torqueFactor,
      this.tuning.horsepower * 745.7 / Math.max(1, Math.abs(speed)));
    const driveForce = this.throttle * availableForce * reversalForce;
    this.body.quaternion.vmult(new Vec3(0, 1, 0), this.up);
    const yawSpeed = Math.abs(this.body.angularVelocity.dot(this.up));
    const groundSpeed = Math.hypot(this.body.velocity.x, this.body.velocity.z);
    const speedFactor = Math.max(0, Math.min(1, (groundSpeed - 7) / 7));
    const turnFactor = Math.max(0, Math.min(1, (yawSpeed - 0.08) / 0.35));
    const rearContact = this.vehicle.wheelInfos.some(wheel => !wheel.isFrontWheel && wheel.isInContact);
    const targetDrift = braking && rearContact ? speedFactor * turnFactor : 0;
    const gripRate = targetDrift > this.driftAmount ? 12 : 3;
    this.driftAmount += (targetDrift - this.driftAmount) * (1 - Math.exp(-gripRate * dt));
    this.body.angularDamping = 0.35 - this.driftAmount * 0.115;
    // Cannon brakes are contact impulses, hence force * fixed time step.
    const brakeForce = braking ? this.tuning.brakeForce : 0;
    // Use an opposing tire force for coasting. A nonzero Cannon brake locks the
    // wheel's visual rotation, which would make rolling wheels appear stationary.
    const coastForce = !braking && Math.abs(requestedThrottle) < 0.01
      ? -Math.sign(speed) * Math.min(650, Math.abs(speed) * 2000) : 0;
    this.vehicle.wheelInfos.forEach((wheel, index) => {
      this.vehicle.setSteeringValue(wheel.isFrontWheel ? this.steering : 0, index);
      this.vehicle.applyEngineForce(wheel.isFrontWheel ? 0 : (driveForce + (wheel.isInContact ? coastForce : 0)) / 2, index);
      wheel.frictionSlip = this.tuning.tireGrip * (wheel.isFrontWheel ? 1 : 1 - 0.35 * this.driftAmount);
      this.vehicle.setBrake(wheel.isFrontWheel ? 0 : brakeForce * dt / 2, index);
    });
  }

  setResetPose(position: Vec3, quaternion: Quaternion) {
    this.spawnPosition.copy(position); this.spawnQuaternion.copy(quaternion);
  }

  reset() {
    this.poseRevision++;
    this.body.position.copy(this.spawnPosition);
    this.body.position.y += 0.35;
    this.body.quaternion.copy(this.spawnQuaternion);
    this.body.velocity.setZero();
    this.body.angularVelocity.setZero();
    this.body.force.setZero();
    this.body.torque.setZero();
    this.body.previousPosition.copy(this.body.position);
    this.body.previousQuaternion.copy(this.body.quaternion);
    this.body.aabbNeedsUpdate = true;
    this.body.wakeUp();
    this.accumulator = this.steering = this.throttle = 0;
    this.driftAmount = 0;
    this.body.angularDamping = 0.35;
    this.vehicle.wheelInfos.forEach((wheel, index) => {
      wheel.rotation = wheel.deltaRotation = 0;
      wheel.suspensionLength = wheel.suspensionRestLength;
      wheel.frictionSlip = this.tuning.tireGrip;
      this.vehicle.setSteeringValue(0, index);
      this.vehicle.applyEngineForce(0, index);
      this.vehicle.setBrake(0, index);
    });
  }
}
