--!nocheck
-- Frontage04 / F04-2 ground only. Final F04-1: H73, Intake R13.9 / R13.1.
-- No installer, runtime behavior, imported assets, furniture, walls or lights.
-- Physical top .23; nonphysical finishes never exceed .232.
return function(K, parent)
 local C = K.C
 local ground = K.model(parent, "01_Unified_Frontage_Ground", "GROUND")
 ground:SetAttribute("SourceGeometry", "FRONTAGE04_DETERMINISTIC_NATIVE_GROUND")
 ground:SetAttribute("LayoutSource", "Frontage04Layout.json / 2026-09-08 / H73")
 ground:SetAttribute("PhysicalFinishTop", .23)
 ground:SetAttribute("MaximumVisualFinishTop", .232)
 ground:SetAttribute("ProtectedCrossoverExcluded", true)
 ground:SetAttribute("GroundBoundary", "X3004..3178; Z-17..97.2; exclude X3096..3164 Z89+")
 ground:SetAttribute("UnfeatheredBoundaryLimit", "Other outside edges retain a provisional .135 finish difference; do not claim all perimeter tie-ins complete.")

 local concrete = C.stone:Lerp(C.steel, .34)
 local concreteLight = concrete:Lerp(C.paper, .10)
 local asphalt = C.black:Lerp(C.stone, .13)
 local joint = C.steel:Lerp(C.stone, .20)
 local stone = C.stone:Lerp(C.paper, .14)
 local ink = C.stone:Lerp(C.woodDark, .29)
 local foundations = K.model(ground, "Continuous_Physical_Finish", "SUPPORT")
 local paving = K.model(ground, "Warm_Stone_And_Joined_Concrete", "FINISH")
 local movement = K.model(ground, "Flush_Vehicle_And_Crossing_Surfaces", "ACCESS")
 local details = K.model(ground, "Inset_Drains_And_Socket_Registration", "DETAIL")
 local partCount = 0

 local function box(m, name, x, y, z, w, h, d, color, material, solid)
  local p = K.box(m, name, x, y, z, w, h, d, color, material, solid)
  p.CastShadow = false
  p.CanTouch = false
  p.CanQuery = solid == true
  p:SetAttribute("Frontage04Ground", true)
  partCount += 1
  return p
 end
 local function rect(m, name, x0, z0, x1, z1, color, material, top)
  return box(m, name, (x0+x1)/2, (top or .2308)-.006, (z0+z1)/2,
   x1-x0, .012, z1-z0, color, material, false)
 end
 local function slab(name, x0, z0, x1, z1)
  return box(foundations, name, (x0+x1)/2, .15, (z0+z1)/2,
   x1-x0, .16, z1-z0, concrete, Enum.Material.Concrete, true)
 end

 -- Do not run a slab underneath either wedge: the low edges meet the measured
 -- retained physical apron at .095. Default wedge rises toward local +Z, as in
 -- the accepted SouthEntryRamp / NorthEntryRamp source convention.
 slab("Main_Joined_Substrate", 3004, -15, 3178, 87)
 slab("West_Rear_Substrate", 3004, 87, 3096, 97.2)
 slab("East_Edge_Substrate", 3164, 87, 3178, 97.2)
 local function feather(name, x0, x1, z, yaw)
  local p = Instance.new("WedgePart")
  p.Name = name
  p.Size = Vector3.new(x1-x0, .135, 2)
  p.CFrame = CFrame.new((x0+x1)/2, .1625, z) * CFrame.Angles(0, yaw, 0)
  p.Anchored = true
  p.Color = concrete
  p.Material = Enum.Material.Concrete
  p.CanCollide = true
  p.CanQuery = true
  p.CanTouch = false
  p.CastShadow = false
  p.TopSurface = Enum.SurfaceType.Smooth
  p.BottomSurface = Enum.SurfaceType.Smooth
  p:SetAttribute("Frontage04Ground", true)
  p:SetAttribute("PhysicalLowTop", .095)
  p:SetAttribute("PhysicalHighTop", .23)
  p:SetAttribute("NoSubstrateBelowRamp", true)
  p.Parent = foundations
  partCount += 1
 end
 feather("Street_Feather_2stud", 3004, 3178, -16, 0)
 feather("Crossover_Feather_2stud", 3096, 3164, 88, math.pi)

 -- Finishes are inset into the solid substrate, not unsupported walkable plates.
 -- The court has no centreline, arrows, raised kerbs or display plinths.
 rect(movement, "Street_Arrival_Apron", 3004, -15, 3178, -2, asphalt, Enum.Material.Asphalt)
 rect(movement, "Court_South", 3118, 6, 3145, 39.5, asphalt, Enum.Material.Asphalt)
 rect(movement, "Court_North", 3118, 43.5, 3145, 85, asphalt, Enum.Material.Asphalt)
 rect(movement, "Court_Exit_Transition", 3118, 85, 3145, 87, asphalt, Enum.Material.Asphalt)
 rect(movement, "Special_Straight_Arrival_And_Unload", 3007, 6, 3021, 52.5, asphalt, Enum.Material.Asphalt)
 rect(movement, "Rear_Receiving_Release_West", 3004, 76, 3077, 97.2, asphalt, Enum.Material.Asphalt)
 rect(movement, "Rear_Receiving_Release_East", 3077, 83, 3094, 97.2, asphalt, Enum.Material.Asphalt)

 local function panels(name, x0, z0, x1, z1, targetX, targetZ, color, material, gap, top)
  local nx = math.max(1, math.ceil((x1-x0)/targetX))
  local nz = math.max(1, math.ceil((z1-z0)/targetZ))
  local sx, sz = (x1-x0)/nx, (z1-z0)/nz
  local g = K.model(paving, name, "FINISH")
  for ix=1,nx do
   for iz=1,nz do
    local col = color:Lerp(C.paper, ((ix*7+iz*3)%5)*.012)
    rect(g, string.format("Panel_%02d_%02d", ix, iz),
     x0+(ix-1)*sx+gap/2, z0+(iz-1)*sz+gap/2,
     x0+ix*sx-gap/2, z0+iz*sz-gap/2, col, material, top)
   end
  end
  return g
 end
 local function stoneField(name, x0, z0, x1, z1, sx, sz)
  return panels(name, x0, z0, x1, z1, sx or 7, sz or 7, stone, Enum.Material.Limestone, .055, .2313)
 end

 -- Broad showroom panels stop at the crossing bands, avoiding coincident skins.
 panels("West_Gallery_South", 3085, 6, 3110, 43, 12.5, 13, concreteLight, Enum.Material.Concrete, .055, .2308)
 panels("West_Gallery_North", 3085, 51, 3110, 85, 12.5, 12, concreteLight, Enum.Material.Concrete, .055, .2308)
 panels("East_Gallery_South", 3145, 6, 3170, 39.5, 12.5, 12, concreteLight, Enum.Material.Concrete, .055, .2308)
 panels("East_Gallery_North", 3145, 43.5, 3170, 85, 12.5, 14, concreteLight, Enum.Material.Concrete, .055, .2308)
 panels("Ordinary_Arrival_Concrete", 3026, 6, 3059, 44, 11, 13, concrete, Enum.Material.Concrete, .06, .2308)

 stoneField("Shared_Customer_Room", 3060, 8, 3084, 43, 6, 7)
 stoneField("Room_Entry_Threshold", 3060, 6, 3084, 8, 6, 2)
 stoneField("Receiving_Terrace_Controlled_Crossings", 3022, 44, 3084, 52, 7, 8)
 stoneField("Room_To_Gallery_Link", 3084, 43, 3110, 51, 6.5, 8)
 stoneField("Main_Eight_Stud_Promenade", 3110, 6, 3118, 85, 8, 7)
 stoneField("Staff_And_Handover_Walk", 3077, 52, 3085, 83, 8, 6.2)
 stoneField("East_Eight_Stud_Walk", 3170, 6, 3178, 85, 8, 7)
 stoneField("East_Controlled_Browse_Crossing", 3118, 39.5, 3170, 43.5, 6.5, 4)
 stoneField("Street_Public_Walk_And_Entry_Crossings", 3004, -2, 3178, 6, 7, 8)

 -- Flush charcoal drainage with sparse metal bridges: construction detail,
 -- never a kerb or a tripping obstacle. No drain breaks the physical substrate.
 local function drain(name, x0, z0, x1, z1, axis)
  local g = K.model(details, name, "DRAINAGE")
  rect(g, "Recessed_Channel", x0, z0, x1, z1, joint, Enum.Material.Metal, .2317)
  local length = axis == "X" and x1-x0 or z1-z0
  local count = math.max(1, math.floor(length/5))
  for i=1,count do
   local t = (i-.5)/count
   if axis == "X" then
    rect(g, "Grate_Bridge_"..i, x0+t*(x1-x0)-.06, z0, x0+t*(x1-x0)+.06, z1, C.steel, Enum.Material.Metal, .232)
   else
    rect(g, "Grate_Bridge_"..i, x0, z0+t*(z1-z0)-.06, x1, z0+t*(z1-z0)+.06, C.steel, Enum.Material.Metal, .232)
   end
  end
 end
 drain("Customer_Threshold_Drain", 3060, 7.72, 3084, 7.90, "X")
 drain("Main_Walk_Edge_Drain", 3117.76, 6, 3117.94, 85, "Z")
 drain("East_Gallery_Edge_Drain", 3169.78, 6, 3169.96, 85, "Z")
 drain("Rear_Release_Collector", 3005, 96.70, 3093, 96.90, "X")
 drain("Special_Lane_Edge_Drain", 3021.15, 6, 3021.33, 52.5, "Z")

 -- Eight short inset corner marks per socket, rather than bright full boxes.
 -- These reserve six sales, three Intake, one handover and one staging only.
 local function bay(name, x, z, w, d, kind)
  local g = K.model(details, name, "SOCKET_REGISTRATION")
  g:SetAttribute("SemanticId", name)
  g:SetAttribute("OperatingKind", kind)
  g:SetAttribute("BufferX", w)
  g:SetAttribute("BufferZ", d)
  g:SetAttribute("PhysicalSurfaceTop", .23)
  for _,sx in ipairs({-1,1}) do
   for _,sz in ipairs({-1,1}) do
    local xx, zz = x+sx*(w/2-.18), z+sz*(d/2-.18)
    local mx = xx-sx*1.1
    local mz = zz-sz*1.1
    rect(g, "Corner_X_"..sx.."_"..sz, mx-1.1, zz-.045, mx+1.1, zz+.045, ink, Enum.Material.Concrete, .232)
    rect(g, "Corner_Z_"..sx.."_"..sz, xx-.045, mz-1.1, xx+.045, mz+1.1, ink, Enum.Material.Concrete, .232)
   end
  end
  return g
 end
 local segments = {
  a={0,-.5,1,.09}, b={.455,-.25,.09,.5}, c={.455,.25,.09,.5},
  d={0,.5,1,.09}, e={-.455,.25,.09,.5}, f={-.455,-.25,.09,.5},
  g={0,0,1,.09}, i={0,0,.09,1},
 }
 local glyphs = { ["1"]="bc", ["2"]="abged", ["3"]="abgcd", ["4"]="fgbc",
  ["5"]="afgcd", ["6"]="afgecd", I="i", S="afgcd", H="febcg", B="afgbcde" }
 local function glyph(g, label, x, z, width, depth)
  for n=1,#label do
   local char = label:sub(n,n)
   local list = glyphs[char]
   local cx = x+(n-(#label+1)/2)*(width+.35)
   for j=1,#list do
    local q = segments[list:sub(j,j)]
    rect(g, "Inset_"..char.."_"..n.."_"..j,
     cx+(q[1]-q[3]/2)*width, z+(q[2]-q[4]/2)*depth,
     cx+(q[1]+q[3]/2)*width, z+(q[2]+q[4]/2)*depth,
     ink, Enum.Material.Concrete, .232)
   end
  end
 end
 for _,q in ipairs({
  {"SalesDisplay_1",3098,15,"1",3087.3},
  {"SalesDisplay_2",3098,35,"2",3087.3},
  {"SalesDisplay_4",3098,58,"4",3087.3},
  {"SalesDisplay_3",3156.5,13,"3",3167.1},
  {"SalesDisplay_5",3156.5,32,"5",3167.1},
  {"SalesDisplay_6",3156.5,51,"6",3167.1},
  {"SalesReveal",3098,73,"H",3087.3},
  {"SalesStaging",3156.5,70,"B",3167.1},
 }) do
  local kind = q[1] == "SalesReveal" and "HANDOVER" or q[1] == "SalesStaging" and "STAGING" or "SALES_DISPLAY"
  local g = bay(q[1], q[2], q[3], 23, 14, kind)
  glyph(g, q[4], q[5], q[3], 1.0, 1.8)
 end
 for _,q in ipairs({{"Intake_1",3033,"I1"},{"Intake_2",3052,"I2"},{"Intake_3",3014,"S"}}) do
  rect(paving, q[1].."_Concrete_Finish", q[2]-7, 52.5, q[2]+7, 75.5, concreteLight, Enum.Material.Concrete, .2308)
  local g = bay(q[1], q[2], 64, 14, 23, q[1] == "Intake_3" and "RARE_OR_TOW" or "ORDINARY_INTAKE")
  glyph(g, q[3], q[2], 53.3, .9, 1.2)
 end

 -- Restrained stop ticks identify the two shared pedestrian crossing bands.
 -- They are markings only: F04-2 introduces no automatic traffic controller.
 for _,x in ipairs({3033,3052}) do
  for _,z in ipairs({43.55,52.45}) do
   rect(details, "Ordinary_Crossing_Hold_"..x.."_"..z, x-4.5,z-.06,x+4.5,z+.06,ink,Enum.Material.Concrete,.232)
  end
 end
 for _,z in ipairs({39.13,43.87}) do
  for i=1,3 do
   local x = 3119.5+(i-1)*8.0
   rect(details,"Court_Crossing_Hold_"..z.."_"..i,x,z-.055,x+3,z+.055,ink,Enum.Material.Concrete,.232)
  end
 end
 ground:SetAttribute("NativeGroundPartCount", partCount)
 ground:SetAttribute("CrossingRule", "Ordinary receiving and west display servicing hold pedestrian crossings; markings do not implement a controller.")
 return ground
end

