--!nocheck
-- Campus03 / Operations: inhabited staff courtyard, additive Institution art layer.
-- Coordinates retain the accepted operations entry and the full z394..400 staff ribbon.
-- No runtime scripts, vehicle positions, capacities, existing props or building edits.
return function(K, parent)
	local C = K.C
	local V = Vector3.new
	local G = .095
	local M, W = Enum.Material.Metal, Enum.Material.Wood
	local court = K.model(parent, "02_Operations_Staff_Courtyard", "PUBLIC_REALM", "Staff_Operations")
	court:SetAttribute("DesignIntent", "A staffed custom-car institution: shared shift table, coffee, field notes and a mature desert garden")
	court:SetAttribute("ClearAccess", "Entire transverse staff ribbon z394..400; Operations entry x3228 from z397 onward")
	court:SetAttribute("BoundsIntent", "New apron occupation south of the rear service ribbon; no roof above the staff crossing")

	-- The lounge is a distinct occupied island, not scattered furniture across the apron.
	local lounge = K.model(court, "01_Timber_And_Steel_Shift_Pavilion", "ARCHITECTURE", "Staff_Operations")
	K.paving(lounge, "WarmCutStoneLounge", 3241, G, 381.5, 22, 23)
	K.pergola(lounge, "LowOpenTimberPergola", 3241, G, 381.5, 22, 23, 11.5)
	lounge:SetAttribute("ArchitecturalHierarchy", "Lower than the existing Operations wing; open sides preserve workshop sightlines")
	for _, x in ipairs({3230.6, 3251.4}) do
		for _, z in ipairs({370.6, 392.4}) do
			K.box(lounge, "PostLimestoneShoe", x, G + .29, z, 1.55, .58, 1.55, C.stone, Enum.Material.Limestone, true)
			for _, dx in ipairs({-.46, .46}) do
				for _, dz in ipairs({-.46, .46}) do
					K.bar(lounge, "VisibleFoundationBolt", V(x + dx, G + .58, z + dz), V(x + dx, G + .66, z + dz), .12, C.black, M, false)
				end
			end
		end
	end

	-- A six-person shared table anchors the covered volume. Small objects communicate work.
	local tableSet = K.model(court, "02_Shared_Shift_Table_And_Six_Chairs", "FURNITURE", "Staff_Operations")
	local tx, tz = 3241, 381
	for i = 0, 6 do
		K.box(tableSet, "SolidTimberTableBoard_" .. i, tx - 2.61 + i * .87, G + 3.38, tz, .82, .34, 12.6,
			i % 3 == 0 and C.woodDark or C.wood, W, true)
	end
	for _, z in ipairs({tz - 4.7, tz + 4.7}) do
		K.box(tableSet, "SteelTrestleFoot", tx, G + .3, z, 5.1, .28, .7, C.steel, M, true)
		K.box(tableSet, "BoxSectionTrestle", tx, G + 1.71, z, .55, 2.68, .55, C.steel, M, true)
		K.box(tableSet, "UnderTopBearing", tx, G + 3.04, z, 5.6, .25, .7, C.steel, M, true)
	end
	K.box(tableSet, "LongitudinalFootRail", tx, G + .63, tz, .42, .35, 9.4, C.steel, M, true)

	local function chair(name, x, z, towardsX)
		local cm = K.model(tableSet, name, "FURNITURE", "Staff_Operations")
		local origin = CFrame.lookAt(V(x, G, z), V(x + towardsX, G, z))
		local function localBox(n, lx, ly, lz, w, h, d, color, material, solid)
			local p = origin:PointToWorldSpace(V(lx, ly, lz))
			local item = K.box(cm, n, p.X, p.Y, p.Z, w, h, d, color, material, solid)
			item.CFrame = origin * CFrame.new(lx, ly, lz)
			return item
		end
		for _, sx in ipairs({-1.06, 1.06}) do
			for _, sz in ipairs({-.91, .91}) do
				localBox("ChairSteelLeg", sx, 1.01, sz, .16, 1.9, .16, C.steel, M, true)
				localBox("RubberFoot", sx, .09, sz, .21, .18, .21, C.black, Enum.Material.SmoothPlastic, false)
			end
			localBox("SeatSideRail", sx, 1.95, 0, .18, .22, 2.2, C.steel, M, true)
			localBox("BackUpright", sx, 2.98, 1.04, .18, 2.08, .18, C.steel, M, true)
		end
		for i = 0, 3 do
			localBox("SeatTimberSlat_" .. i, 0, 2.16, -.81 + i * .54, 2.34, .22, .47, i == 0 and C.woodDark or C.wood, W, true)
		end
		for i = 0, 2 do
			localBox("BackTimberSlat_" .. i, 0, 2.7 + i * .42, 1.09, 2.34, .33, .18, C.wood, W, true)
		end
		-- One reliable native seat per chair; visual slats remain below its top.
		local seat = Instance.new("Seat")
		seat.Name = "NativeStaffSeat"
		seat.Size = V(2.3, .12, 2.04)
		seat.CFrame = origin * CFrame.new(0, 2.32, 0)
		seat.Anchored = true
		seat.Material = W
		seat.Color = C.wood
		seat.CanCollide = true
		seat.CanTouch = true
		seat.CanQuery = true
		seat.Disabled = false
		seat.TopSurface = Enum.SurfaceType.Smooth
		seat.BottomSurface = Enum.SurfaceType.Smooth
		seat:SetAttribute("Use", "Native sit only; no controller")
		seat.Parent = cm
	end
	for i, z in ipairs({377, 381, 385}) do
		chair("WestStaffChair_" .. i, 3235.5, z, 1)
		chair("EastStaffChair_" .. i, 3246.5, z, -1)
	end

	local objects = K.model(court, "03_Shift_Notes_And_Coffee", "STORY", "Staff_Operations")
	local function cup(n, x, y, z)
		K.bar(objects, n .. "CeramicBody", V(x, y, z), V(x, y + .52, z), .48, C.paper, Enum.Material.SmoothPlastic, false)
		K.bar(objects, n .. "CoffeeSurface", V(x, y + .521, z), V(x, y + .539, z), .38, C.woodDark, Enum.Material.SmoothPlastic, false)
		K.box(objects, n .. "HandleTop", x + .3, y + .4, z, .24, .11, .13, C.paper, nil, false)
		K.box(objects, n .. "HandleSide", x + .39, y + .28, z, .1, .26, .13, C.paper, nil, false)
		K.box(objects, n .. "HandleBottom", x + .3, y + .16, z, .24, .11, .13, C.paper, nil, false)
	end
	for i, p in ipairs({{3242.4, 377.3}, {3239.6, 383.5}, {3242.4, 385.5}}) do
		cup("SharedCoffee_" .. i, p[1], G + 3.58, p[2])
	end
	K.box(objects, "VehicleBuildFolio", 3240, G + 3.615, 378.8, 2.6, .1, 1.9, C.navy, nil, false)
	K.box(objects, "BuildSpecPaper", 3240, G + 3.68, 378.8, 2.26, .025, 1.6, C.paper, nil, false)
	for i = 0, 3 do
		K.box(objects, "ReadableSpecRows", 3240, G + 3.7, 378.3 + i * .28, 1.65 - .16 * i, .012, .055, C.steel, nil, false)
	end
	K.box(objects, "MaterialSampleTray", 3241.5, G + 3.62, 382, 2.3, .15, 1.8, C.steel, M, false)
	for i, color in ipairs({C.wood, C.paper, C.navy}) do
		K.box(objects, "FinishSample_" .. i, 3240.9 + i * .35, G + 3.75, 382, .3, .12, 1.05, color, nil, false)
	end
	K.box(objects, "FoldedWorkJacket", 3239.9, G + 3.68, 385.5, 1.9, .23, 1.5, C.navy, Enum.Material.Fabric, false)

	-- Outdoor coffee and water counter: an institutional staff benefit, not another department.
	local service = K.model(court, "04_Staff_Hydration_And_Pinboard", "SUPPORT", "Staff_Operations")
	K.box(service, "CoffeeCounterBase", 3241, G + 1.55, 390.35, 12.5, 3, 2.6, C.steel, M, true)
	K.box(service, "CoffeeCounterStoneTop", 3241, G + 3.22, 390.35, 13, .34, 2.9, C.stone, Enum.Material.Limestone, true)
	for i = 0, 3 do
		local x = 3236.5 + i * 3
		K.box(service, "TimberCabinetFront_" .. i, x, G + 1.7, 388.99, 2.82, 2.42, .16, i % 2 == 0 and C.woodDark or C.wood, W, false)
		K.box(service, "BlackDrawerPull_" .. i, x, G + 2.6, 388.85, .86, .11, .15, C.black, M, false)
	end
	K.box(service, "CoffeeMachine", 3237.7, G + 4.28, 390.3, 2.4, 1.78, 1.85, C.black, M, false)
	K.box(service, "CoffeeMachineFront", 3237.7, G + 4.35, 389.32, 2.13, 1.44, .12, C.steel, M, false)
	K.box(service, "CoffeeDripTray", 3237.7, G + 3.51, 389.08, 2.04, .16, .95, C.black, M, false)
	for _, dx in ipairs({-.45, .45}) do
		K.bar(service, "CoffeeDispenser", V(3237.7 + dx, G + 4.48, 389.13), V(3237.7 + dx, G + 3.99, 389.13), .18, C.stone, M, false)
	end
	K.bar(service, "WaterDispenserBody", V(3242.1, G + 3.4, 390.25), V(3242.1, G + 5.15, 390.25), 1.48, C.steel, M, false)
	K.bar(service, "WaterDispenserLid", V(3242.1, G + 5.15, 390.25), V(3242.1, G + 5.28, 390.25), 1.6, C.black, M, false)
	K.box(service, "WaterTap", 3242.1, G + 3.8, 389.38, .28, .42, .44, C.black, M, false)
	cup("CounterMug", 3243.5, G + 3.42, 389.9)
	K.box(service, "CrewPinboardFrame", 3245.2, G + 5.35, 391.45, 3.4, 3.4, .25, C.woodDark, W, true)
	K.box(service, "CrewPinboardCork", 3245.2, G + 5.35, 391.29, 3.07, 3.07, .08, C.wood, W, false)
	for i, p in ipairs({{-1, .8}, {.65, .6}, {-.65, -.65}, {.8, -.7}}) do
		K.box(service, "CrewNote_" .. i, 3245.2 + p[1], G + 5.35 + p[2], 391.22, .85, .89, .04, i == 2 and C.pale or C.paper, nil, false)
		K.box(service, "NotePin_" .. i, 3245.2 + p[1], G + 5.67 + p[2], 391.18, .08, .08, .05, C.black, M, false)
	end
	for _, x in ipairs({3232.6, 3249.4}) do
		K.box(service, "SortingBin", x, G + 1.35, 389.8, 1.75, 2.5, 1.7, C.steel, M, true)
		K.box(service, "SortingBinRecess", x, G + 2.66, 389.8, 1.39, .1, 1.29, C.black, nil, false)
		K.box(service, "SortingBinLid", x, G + 2.82, 390.29, 1.86, .13, .69, C.wood, W, false)
	end

	-- Green mass counterbalances the pergola, and visibly brings the work campus to maturity.
	local garden = K.model(court, "05_Desert_Shade_And_Bench_Island", "LANDSCAPE", "Staff_Operations")
	local bed = K.planter(garden, "LimestoneAndWeatheredSteelIsland", 3208, G, 382, 20, 14, 1.12)
	local plantedY = G + 1.12
	K.tree(bed, "MatureBranchingStaffShade", 3203.2, plantedY, 383.1, 1.24)
	K.yucca(bed, "ArchitecturalYucca", 3213.8, plantedY, 386.2, .95)
	for i, q in ipairs({{3200.7, 378.2, 1.05}, {3205.8, 376.9, .88}, {3213.4, 377.3, 1.15}, {3206.1, 386.7, .86}, {3215.8, 383.4, .78}}) do
		K.agave(bed, "BlueAgave_" .. i, q[1], plantedY, q[2], q[3])
	end
	for i, q in ipairs({{3200.4, 385.8, 1.1}, {3208.9, 376.7, 1.0}, {3215.2, 379.9, .83}, {3209.9, 387, .95}, {3203.2, 376.3, .68}}) do
		K.grass(bed, "SoftDesertGrasses_" .. i, q[1], plantedY, q[2], q[3])
	end
	for i, q in ipairs({{3203.7, 379.6, 1.8}, {3208.8, 385.5, 1.5}, {3212, 378.6, 1.25}, {3201.4, 387, 1.1}}) do
		K.rock(bed, "LimestoneOutcrop_" .. i, q[1], plantedY, q[2], q[3])
	end
	-- Bench stands outside the soil reserve and faces the open pedestrian approach.
	K.bench(garden, "GardenConversationBench", 3220.0, G, 382, 8.2, 90)
	K.light(garden, "GardenApproachLantern", 3219.1, G, 387.9, 13)
	K.light(lounge, "LoungeApproachLantern", 3231.6, G, 374, 14)

	-- Dry border gives the court a front edge without fencing it off or adding a new program.
	local border = K.model(court, "06_Pavilion_Planting_Shoulders", "LANDSCAPE", "Staff_Operations")
	for i, q in ipairs({{3233.8, 369.1, 5.4, 2.0}, {3248.1, 369.1, 5.4, 2.0}}) do
		local p = K.planter(border, "TimberPavilionToeGarden_" .. i, q[1], G, q[2], q[3], q[4], .62)
		K.agave(p, "LowPavilionAgave_" .. i, q[1] - .6, G + .62, q[2], .62)
		K.grass(p, "FinePavilionGrass_" .. i, q[1] + 1.6, G + .62, q[2], .62)
	end

	court:SetAttribute("Implementation", "Additive named assemblies; rollback by removing this owned subtree")
	return court
end

