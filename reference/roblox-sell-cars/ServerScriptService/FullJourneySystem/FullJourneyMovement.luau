-- FullJourney supplies destinations; the original Sell Cars modules own motion.
-- No replacement interpolation, steering, walk pose, or animation implementation.
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local JunkLot = ServerScriptService.TycoonSystem.JunkLot
local LotNpc = require(JunkLot.LotNpc)
local RoadTraffic = require(JunkLot.RoadTraffic)
local CarVisuals = require(JunkLot.CarVisuals)
local DealerCarConfig = require(ReplicatedStorage.DealerCarConfig)
local Movement = {}
Movement.CarVisuals=CarVisuals
Movement.LotNpc=LotNpc
Movement.RoadTraffic=RoadTraffic

function Movement.prepareNPC(rig, footFrame, role)
	LotNpc.applyPhysics(rig)
	LotNpc.resetFooting(rig)
	LotNpc.place(rig, footFrame.Position, footFrame.LookVector)
	rig:SetAttribute("FullJourneyMovementRole", role)
	rig:SetAttribute("MovementImplementation", "TycoonSystem.JunkLot.LotNpc.walk")
	LotNpc.play(rig, "idle")
end

function Movement.walkNPC(rig, footFrame, valid, multiplier)
	if not rig or not rig.Parent or not valid() then return false end
	LotNpc.applyPhysics(rig)
	-- BayStaff deliberately uses authored floor heights. A roof probe would put
	-- mechanics on top of the workshop, so keep its existing foot-frame contract.
	local from = LotNpc.footPosition(rig)
	local destination = footFrame.Position
	local points = {from}
	local distance = (destination-from).Magnitude
	local count = math.max(1, math.ceil(distance/2.4))
	for index=1,count do points[#points+1]=from:Lerp(destination,index/count) end
	local role=rig:GetAttribute("FullJourneyMovementRole")
	local speed=(role=="Seller" or role=="Customer") and DealerCarConfig.WALK_SPEED
		or DealerCarConfig.STAFF_WALK_SPEED
	if not LotNpc.walk(rig,points,(speed or 11)*(multiplier or 1),valid) then return false end
	if not rig.Parent or not valid() then return false end
	LotNpc.place(rig,footFrame.Position,footFrame.LookVector)
	LotNpc.play(rig,"idle")
	return true
end

function Movement.playNPC(rig, animation)
	if rig and rig.Parent then return LotNpc.play(rig,animation) end
end

function Movement.destroyNPC(rig)
	if rig then LotNpc.destroy(rig) end
end

function Movement.spawnNPC(name,parent,footFrame,personId,isBuyer)
	local rig
	if isBuyer and personId then
		rig=LotNpc.spawnBuyer(name,parent,footFrame.Position,footFrame.LookVector,personId)
	else
		rig=LotNpc.spawn(name,parent,footFrame.Position,footFrame.LookVector,personId)
	end
	if rig then
		rig:SetAttribute("FullJourneyMovementRole",isBuyer and "Customer" or name)
		rig:SetAttribute("MovementImplementation","TycoonSystem.JunkLot.LotNpc.walk")
	end
	return rig
end

function Movement.driver(car)
	if not car then return nil end
	for _,child in ipairs(car:GetChildren()) do
		if child:IsA("Model") and child:FindFirstChildOfClass("Humanoid") then return child end
	end
	return nil
end

function Movement.seatDriver(rig,car)
	if not rig or not car or not car.Parent then return nil end
	LotNpc.seat(rig,car,CarVisuals.driverSeat(car))
	return rig
end

-- The same lightweight composition as original DealerCar.addDriver; loading the
-- full DealerCar module here would boot its old progression/save dependencies.
function Movement.addDriver(car,personId)
	local existing=Movement.driver(car)
	if existing then return existing end
	local pivot=car:GetPivot()
	local foot=Vector3.new(pivot.X,pivot.Y-2,pivot.Z)
	local rig=LotNpc.spawn("CarDriver",car,foot,pivot.LookVector,personId)
	return rig and Movement.seatDriver(rig,car) or nil
end

function Movement.unseatDriver(rig,parent,footFrame,animation)
	if not rig then return nil end
	LotNpc.unseat(rig,parent,footFrame.Position,footFrame.LookVector,animation or "idle")
	return rig
end

function Movement.prepareCar(car, initialFrame)
	CarVisuals.lockDealerDriving(car)
	CarVisuals.pivotToConditionFrame(car,initialFrame)
	car:SetAttribute("MovementImplementation","TycoonSystem.JunkLot.RoadTraffic.drive")
end

function Movement.driveCar(car, route, valid, options)
	if not car or not car.Parent or not valid() then return false end
	if #route==0 then return true end
	options=options or {}
	local speed=(options.departure and DealerCarConfig.DEPART_SPEED or DealerCarConfig.ARRIVE_SPEED) or 45
	speed*=options.speedMultiplier or 1
	local groups={}
	local current=car:GetPivot().Position
	local lastFrame=route[#route]
	for _,target in ipairs(route) do
		local travel=target.Position-current
		local flat=Vector3.new(travel.X,0,travel.Z)
		if travel.Magnitude>.01 then
			-- The authored route's facing distinguishes backing out of a bay
			-- from driving forward. RoadTraffic already implements reverse motion.
			local reverse=flat.Magnitude>.01 and flat.Unit:Dot(target.LookVector)<-.1
			local group=groups[#groups]
			if not group or group.reverse~=reverse then
				group={reverse=reverse,points={current}}
				groups[#groups+1]=group
			end
			group.points[#group.points+1]=target.Position
			current=target.Position
		end
	end
	for _,group in ipairs(groups) do
		if not valid() or not car.Parent then return false end
		local initialLook=car:GetPivot().LookVector*(group.reverse and -1 or 1)
		if not RoadTraffic.drive(car,group.points,speed,valid,{
			steer=true,reverse=group.reverse,initialLook=initialLook,
		}) then return false end
	end
	if not valid() or not car.Parent then return false end
	-- The original visual module owns the final authored parked pose as well.
	CarVisuals.pivotToConditionFrame(car,lastFrame)
	CarVisuals.resetWheels(car)
	return true
end

return Movement
