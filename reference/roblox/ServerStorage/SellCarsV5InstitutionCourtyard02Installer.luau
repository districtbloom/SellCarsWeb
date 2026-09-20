--!nocheck
-- Institution-only additive design garden. No runtime drivers and no accepted-object edits.
local I={Version="2026-09-08.courtyard02.5"}
local ROOT,NAME="SellCars_Dealership_Growth_V5","08_Courtyard02"
local function round(value: number): number
	return math.floor(value * 1000 + (if value >= 0 then 0.5 else -0.5)) / 1000
end

local function addHash(seed: number, value: string): number
	local hash = seed
	for index = 1, #value do
		hash = (hash * 33 + string.byte(value, index)) % 4294967296
	end
	return hash
end

local function relativePath(item: Instance, ancestor: Instance): string
	local names = {}
	local cursor: Instance? = item
	while cursor and cursor ~= ancestor do
		table.insert(names, 1, cursor.Name)
		cursor = cursor.Parent
	end
	return table.concat(names, "/")
end

local function geometryHash(instance: Instance, excluded: Instance?): (string, number)
	local records = { ".|" .. instance.ClassName }
	for _, item in ipairs(instance:GetDescendants()) do
		if excluded and (item == excluded or item:IsDescendantOf(excluded)) then continue end
		local record = relativePath(item, instance) .. "|" .. item.ClassName
		if item:IsA("BasePart") then
			local position = item.Position
			local size = item.Size
			local orientation = item.Orientation
			local color = item.Color
			record ..= string.format(
				"|p=%.3f,%.3f,%.3f|s=%.3f,%.3f,%.3f|o=%.3f,%.3f,%.3f|t=%.3f|c=%s%s%s%s|m=%s|rgb=%.3f,%.3f,%.3f",
				round(position.X), round(position.Y), round(position.Z),
				round(size.X), round(size.Y), round(size.Z),
				round(orientation.X), round(orientation.Y), round(orientation.Z),
				round(item.Transparency),
				if item.CanCollide then "1" else "0",
				if item.CanTouch then "1" else "0",
				if item.CanQuery then "1" else "0",
				if item.CastShadow then "1" else "0",
				tostring(item.Material), round(color.R), round(color.G), round(color.B)
			)
		elseif item:IsA("Light") then
			record ..= string.format(
				"|e=%s|b=%.3f|r=%.3f|s=%s",
				if item.Enabled then "1" else "0",
				round(item.Brightness), round(item.Range),
				if item.Shadows then "1" else "0"
			)
		elseif item:IsA("LuaSourceContainer") then
			record ..= "|sourceLen=" .. tostring(#item.Source)
		end
		table.insert(records, record)
	end
	table.sort(records)
	local hash = 5381
	for _, record in ipairs(records) do
		hash = addHash(hash, record)
		hash = addHash(hash, "\n")
	end
	return string.format("%08x", hash), #records
end


local V,CF=Vector3.new,CFrame.new
local function root()
 assert(game.PlaceId==125334614375606 and not game.RunService:IsRunning(),"Correct existing place / Edit required")
 return assert(workspace:FindFirstChild(ROOT))
end
local function parent()return root()["10_Institution_Fidelity_R1"]end
local function layer()return parent():FindFirstChild(NAME)end
local function bounds(p)
 local c,s=p.CFrame,p.Size
 local h=V(math.abs(c.RightVector.X)*s.X+math.abs(c.UpVector.X)*s.Y+math.abs(c.LookVector.X)*s.Z,math.abs(c.RightVector.Y)*s.X+math.abs(c.UpVector.Y)*s.Y+math.abs(c.LookVector.Y)*s.Z,math.abs(c.RightVector.Z)*s.X+math.abs(c.UpVector.Z)*s.Y+math.abs(c.LookVector.Z)*s.Z)/2
 return p.Position-h,p.Position+h
end
local function overlaps(a,b,c,d)return a.X<d.X-.002 and b.X>c.X+.002 and a.Y<d.Y-.002 and b.Y>c.Y+.002 and a.Z<d.Z-.002 and b.Z>c.Z+.002 end
local function signature(r,excluded)
 local rows={(geometryHash(r,excluded))}
 local all={r};for _,v in r:GetDescendants()do table.insert(all,v)end
 for _,v in all do if not(excluded and(v==excluded or v:IsDescendantOf(excluded)))then
  local path=relativePath(v,r)
  if v:IsA("BasePart")then table.insert(rows,path.."|form|"..(v:IsA("Part")and v.Shape.Name or v.ClassName).."|"..tostring(v.Anchored).."|"..tostring(v.Massless).."|"..v.MaterialVariant.."|"..v.CollisionGroup.."|"..tostring(v.Reflectance).."|"..tostring(v.CustomPhysicalProperties).."|"..v.TopSurface.Name.."|"..v.BottomSurface.Name..(v:IsA("Seat")and tostring(v.Disabled)or""))end
  if v:IsA("Light")then table.insert(rows,path.."|light|"..tostring(v.Color).."|"..((v:IsA("SurfaceLight")or v:IsA("SpotLight"))and(v.Face.Name..":"..v.Angle)or"Point"))end
  if v:IsA("DataModelMesh")then table.insert(rows,path.."|mesh|"..tostring(v.Scale).."|"..tostring(v.Offset)..(v:IsA("SpecialMesh")and(v.MeshType.Name..v.MeshId..v.TextureId)or""))end
  if v:IsA("ObjectValue")then table.insert(rows,path.."|ref|"..(v.Value and v.Value:GetFullName()or"nil"))end
  if v:IsA("LuaSourceContainer")then table.insert(rows,path.."|source|"..v.Source)end
  for k,value in v:GetAttributes()do if not(v==r and k=="ContentSignature")then table.insert(rows,path.."|attr|"..k.."|"..typeof(value).."|"..tostring(value))end end
  for _,tag in v:GetTags()do table.insert(rows,path.."|tag|"..tag)end
 end end
 table.sort(rows);local h=5381;for _,s in rows do h=addHash(h,s.."\n")end;return string.format("%08x",h)
end
I.Signature=signature;I.GeometryHash=geometryHash
local C={steel=Color3.fromRGB(43,48,45),rust=Color3.fromRGB(124,77,46),wood=Color3.fromRGB(167,121,74),grain=Color3.fromRGB(139,98,58),stone=Color3.fromRGB(173,158,126),gravel=Color3.fromRGB(150,134,102),sage=Color3.fromRGB(101,115,80),olive=Color3.fromRGB(92,105,65),pale=Color3.fromRGB(124,136,95),bark=Color3.fromRGB(107,94,73),paper=Color3.fromRGB(219,212,187),ink=Color3.fromRGB(43,64,69),warm=Color3.fromRGB(255,197,111)}
local function model(l,n,role,intent)
 local m=Instance.new("Model");m.Name=n
 for k,v in {BundleId="Institution.Courtyard02."..n,FunctionId="Owner_Garage",ZoneId="OwnerPhotoDesignGarden",FidelityRole=role,PhaseMin="INSTITUTION",Ancestor="Owner workshop folio becomes a shared outdoor design garden",InheritanceRule="ADDITIVE",AssetStatus="PROXY",CollisionClass="FURNITURE_OR_PLANTED_RESERVE",InteractionAnchor="",FXSocket="",SourceOwned=true,SourceGeometry="DETERMINISTIC_NATIVE_GEOMETRY",FinalDetailIntent=intent}do m:SetAttribute(k,v)end
 m.Parent=l;return m
end
local function part(m,n,p,s,col,mat,solid,cls,cf)
 local v=Instance.new(cls or"Part");v.Name=n;v.Size=s;v.CFrame=cf or CF(p);v.Color=col;v.Material=mat or Enum.Material.SmoothPlastic
 v.Anchored=true;v.CanCollide=solid==true;v.CanQuery=true;v.CanTouch=v:IsA("Seat");v.CastShadow=true;v.TopSurface=0;v.BottomSurface=0;v.Parent=m;return v
end
local function bar(m,n,a,b,d,c,solid)
 local p=part(m,n,(a+b)/2,V((b-a).Magnitude,d,d),c,Enum.Material.Wood,solid,nil,CFrame.lookAt((a+b)/2,b)*CFrame.Angles(0,math.pi/2,0));p.Shape=Enum.PartType.Cylinder;return p
end
local function leaf(m,n,a,b,w,c)
 return part(m,n,(a+b)/2,V(.07,w,(b-a).Magnitude),c,nil,false,"WedgePart",CFrame.lookAt((a+b)/2,b)*CFrame.Angles(0,0,math.pi/2))
end
local function bed(l,n,x,z,w,d)
 local m=model(l,n,"LANDSCAPE","FOLDED_WEATHERING_STEEL_PLANTER_RECESSED_GRAVEL_WITH_REAL_ROOT_RESERVE")
 part(m,"GroundedPlinth",V(x,.279,z),V(w-.24,.32,d-.24),C.steel,Enum.Material.Concrete,true)
 part(m,"GravelCore",V(x,.88,z),V(w-.3,.88,d-.3),C.gravel,Enum.Material.Pebble,true)
 for _,s in {-1,1}do
  part(m,"FoldedEdgeX_"..s,V(x+s*(w/2-.09),.75,z),V(.18,1.262,d),C.rust,Enum.Material.Metal,true)
  part(m,"FoldedEdgeZ_"..s,V(x,.75,z+s*(d/2-.09)),V(w-.36,1.262,.18),C.rust,Enum.Material.Metal,true)
  part(m,"RimX_"..s,V(x+s*(w/2-.11),1.41,z),V(.24,.08,d),C.grain,Enum.Material.Metal,false)
  part(m,"RimZ_"..s,V(x,1.41,z+s*(d/2-.11)),V(w-.48,.08,.24),C.grain,Enum.Material.Metal,false)
 end
 return m
end
local function agave(m,n,x,z,s)
 local a=V(x,1.35,z)
 for ring=1,2 do for i=1,6 do local t=i*math.pi*2/6+ring*.4
  local tip=a+V(math.cos(t)*(ring==1 and 1.7 or .8)*s,(ring==1 and .65 or 1.55)*s,math.sin(t)*(ring==1 and 1.7 or .8)*s)
  for _,sign in {-1,1}do
   local cf=CFrame.lookAt((a+tip)/2,tip)*CFrame.Angles(0,0,sign*math.pi/2)*CF(0,.14*s,0)
   part(m,n..ring.."_"..i.."_"..sign,(a+tip)/2,V(.065,.28*s,(tip-a).Magnitude),ring==1 and C.sage or C.pale,nil,false,"WedgePart",cf)
  end
 end end
end
local function rock(m,n,x,z,s)
 local p=part(m,n,V(x,1.35+s*.19,z),V(s*1.23,s*.46,s*.88),C.stone,Enum.Material.Slate,false)
 local mesh=Instance.new("SpecialMesh");mesh.MeshType=Enum.MeshType.Sphere;mesh.Parent=p;p.CFrame*=CFrame.Angles(.16,.55,.19);return p
end
local function grasses(m,n,x,z,s)
 for i=1,6 do local a=i*math.pi/3+.35
  local base=V(x,1.32,z)
  leaf(m,n..i,base,base+V(math.cos(a)*.8*s,(.9+.35*(i%2))*s,math.sin(a)*.8*s),.35*s,i%2==0 and C.pale or C.sage)
 end
end
local function cactus(m,n,x,z,s)
 local a=V(x,1.3,z);bar(m,n.."Stem",a,a+V(.1,2.8*s,0),.75*s,C.sage,true)
 for i,q in {{-.55,1.1,.14},{.6,1.65,-.15},{-.22,2.9,0}}do
  local p=part(m,n.."Pad"..i,a+V(q[1]*s,q[2]*s,q[3]),V(1.1*s,1.65*s,.3*s),i==2 and C.pale or C.sage,nil,false)
  local mesh=Instance.new("SpecialMesh");mesh.MeshType=Enum.MeshType.Sphere;mesh.Parent=p;p.CFrame*=CFrame.Angles(0,math.pi/2+.23*(i-2),.22*(i-2))
 end
end
local function tree(l)
 local m=model(l,"02_Airy_Shade_Tree","LANDSCAPE","ASYMMETRIC_MESQUITE_INSPIRED_BRANCHING_TREE_FINAL_BOTANICAL_MESH_PENDING")
 m:SetAttribute("BotanicalIntent","STYLIZED_BRANCHING_DESERT_SHADE_TREE_NOT_FINAL_SPECIES_ACCURACY")
 local o=V(3202,1.32,123.6)
 local joints={{0,0,0,-.35,3.7,.15,1.15},{-.35,3.6,.15,.05,7.3,.1,.85},{.05,7.2,.1,1.1,11.0,-.5,.58},{-.35,3.5,.15,-2,6.3,1,.75},{-2,6.2,1,-4.5,9.3,1.8,.49},{.05,7.1,.1,3.7,9.2,2.6,.48},{.05,7.1,.1,-1.9,10.7,-2.6,.44},{-.2,5.2,.12,2.8,7.7,-2.8,.56},{2.8,7.6,-2.8,4.7,9.0,-3.5,.33},{-2,6.2,1,-4.9,7.7,-1.8,.4}}
 for i,q in joints do bar(m,"ConnectedBranch_"..i,o+V(q[1],q[2],q[3]),o+V(q[4],q[5],q[6]),q[7],C.bark,true)end
 local crowns={{-4.5,9.3,1.8},{3.7,9.2,2.6},{-1.9,10.7,-2.6},{1.1,11,-.5},{4.7,9,-3.5},{-4.9,7.7,-1.8},{-1.1,9.9,3.5},{2.7,10.4,0}}
 for k,q in crowns do
  local p=o+V(q[1],q[2],q[3])
  if k>6 then bar(m,"CrownShoulder_"..k,o+V(.05,7.3,.1),p,.26,C.bark,false)end
  for j=1,5 do
   local a=j*math.pi*2/5+k*.49;local tip=p+V(math.cos(a)*2.05,.3+.22*math.sin(j+k),math.sin(a)*1.75)
   bar(m,"FineTwig_"..k.."_"..j,p,tip,.075,C.bark,false).CastShadow=false
   for s=1,3 do
    local b=p:Lerp(tip,.16+s*.24);local aa=a+(s%2==1 and .7 or -.7)
    local spray=part(m,"CompoundLeafSpray_"..k.."_"..j.."_"..s,b,V(2.5,.50,1.35),(k+j+s)%3==0 and C.pale or C.olive,Enum.Material.Grass,false)
    local mesh=Instance.new("SpecialMesh");mesh.MeshType=Enum.MeshType.Sphere;mesh.Parent=spray
    spray.CFrame*=CFrame.Angles(.32*math.sin(j),-aa,.28*math.cos(k+s));spray.CastShadow=false
   end
  end
 end
 return m
end
local function nativeSeat(m,n,p,s,cf,order,ax,az)
 local v=part(m,n,p,s,C.wood,Enum.Material.Wood,true,"Seat",cf);v.Disabled=false
 for k,val in {AccessTestOrder=order,ApproachX=ax,ApproachZ=az,ExitX=ax,ExitZ=az,AccessSeatContact=true}do v:SetAttribute(k,val)end
 return v
end
local function seatMark(m)for _,p in m:GetChildren()do if p:IsA("BasePart")then p:SetAttribute("AccessSeatContact",true)end end end
local function bench(l,n,x,z,w,order)
 local m=model(l,n,"SUPPORT","CRAFTED_TIMBER_SEAT_STEEL_CARRIAGE_SAGE_BACK_CUSHIONS_NATIVE_SINGLE_SEAT")
 for _,dx in {-w*.37,w*.37}do
  for _,dz in {-.75,.75}do part(m,"Leg_"..dx.."_"..dz,V(x+dx,.91,z+dz),V(.23,1.582,.23),C.steel,Enum.Material.Metal,true)end
  part(m,"SeatBearer_"..dx,V(x+dx,1.73,z),V(.25,.20,2.65),C.steel,Enum.Material.Metal,true)
  part(m,"BackUpright_"..dx,V(x+dx,2.30,z-1.24),V(.24,2.3,.22),C.steel,Enum.Material.Metal,true)
 end
 for j=0,5 do part(m,"TimberSlat_"..j,V(x,1.95,z-1.12+j*.445),V(w,.24,.40),j%3==0 and C.grain or C.wood,Enum.Material.Wood,true)end
 nativeSeat(m,"GardenSeat",V(x,2.105,z),V(2.4,.07,1.8),CF(x,2.105,z)*CFrame.Angles(0,math.pi,0),order,x,z+4.5)
 for j=0,2 do part(m,"BackSlat_"..j,V(x,2.6+j*.35,z-1.27),V(w,.29,.22),C.wood,Enum.Material.Wood,true)end
 for _,dx in {-w*.29,w*.29}do local p=part(m,"SageBackCushion_"..dx,V(x+dx,2.72,z-.91),V(1.9,1.35,.42),C.sage,Enum.Material.Fabric,false);p.CFrame*=CFrame.Angles(-.13,0,0)end
 seatMark(m);return m
end
local function chair(l,n,x,z,order)
 local m=model(l,n,"SUPPORT","TUBULAR_STEEL_CANTILEVER_CHAIR_TIMBER_SEAT_NATIVE_USE")
 for _,dz in {-.95,.95}do
  part(m,"GroundRail_"..dz,V(x,.22,z+dz),V(2.75,.20,.20),C.steel,Enum.Material.Metal,true)
  part(m,"FrontLeg_"..dz,V(x+.96,.95,z+dz),V(.20,1.45,.20),C.steel,Enum.Material.Metal,true)
  part(m,"SeatRail_"..dz,V(x,1.66,z+dz),V(2.15,.18,.20),C.steel,Enum.Material.Metal,true)
  part(m,"BackUpright_"..dz,V(x-.96,2.17,z+dz),V(.20,1.35,.20),C.steel,Enum.Material.Metal,true)
 end
 nativeSeat(m,"DesignChairSeat",V(x,1.86,z),V(2.1,.24,2.3),CF(x,1.86,z)*CFrame.Angles(0,-math.pi/2,0),order,x-4.1,z)
 for j=0,2 do part(m,"TimberBack_"..j,V(x-1.03,2.32+j*.32,z),V(.16,.26,2.3),C.wood,Enum.Material.Wood,true)end
 seatMark(m);return m
end
local function tableBuild(l)
 local m=model(l,"05_Coachbuilder_Review_Table","STORY","OPEN_BUILD_FOLIO_FINISH_SWATCHES_AND_FORMED_FENDER_BUCK_FOR_PERSONAL_DESIGN")
 for _,z in {120.7,129.3}do
  for _,x in {3184.6,3187.4}do part(m,"BoxSteelLeg_"..x.."_"..z,V(x,1.66,z),V(.28,3.082,.38),C.steel,Enum.Material.Metal,true)end
  part(m,"TableBearer_"..z,V(3186,3.14,z),V(3.9,.24,.34),C.steel,Enum.Material.Metal,true)
 end
 for j=0,4 do part(m,"OakTop_"..j,V(3184.48+j*.76,3.40,125),V(.70,.28,11),j%3==0 and C.grain or C.wood,Enum.Material.Wood,true)end
 part(m,"FolioCover",V(3185.8,3.59,122.65),V(2.8,.09,2.85),C.steel,Enum.Material.Fabric,false)
 for j=0,1 do part(m,"FolioPaper_"..j,V(3185.8,3.65,121.96+j*1.36),V(2.59,.03,1.26),C.paper,nil,false)end
 local function line(n,a,b,w)
  local d=b-a;return part(m,n,(a+b)/2,V(d.Magnitude,.022,w or .045),C.ink,nil,false,nil,CFrame.lookAt((a+b)/2,b)*CFrame.Angles(0,math.pi/2,0))
 end
 local z=121.96;local pts={{3184.8,z+.32},{3184.83,z-.02},{3185.35,z-.13},{3185.64,z-.45},{3186.25,z-.45},{3186.55,z-.12},{3186.88,z-.02},{3186.9,z+.32},{3184.8,z+.32}}
 for i=2,#pts do line("CarProfile_"..i,V(pts[i-1][1],3.68,pts[i-1][2]),V(pts[i][1],3.68,pts[i][2]))end
 for _,x in {3185.2,3186.5}do local p=part(m,"ProfileWheel_"..x,V(x,3.69,z+.26),V(.03,.33,.33),C.ink,nil,false);p.Shape=Enum.PartType.Cylinder;p.CFrame*=CFrame.Angles(0,0,math.pi/2)end
 for j=1,4 do line("SpecificationLine_"..j,V(3184.9,3.68,123+j*.17),V(3186.3-(j%2)*.35,3.68,123+j*.17),.025)end
 for i,col in {C.olive,Color3.fromRGB(36,65,84),Color3.fromRGB(140,64,44),Color3.fromRGB(188,175,141)}do
  part(m,"FinishSample_"..i,V(3185.15+(i%2)*.9,3.66,126.15+math.floor((i-1)/2)*.72),V(.73,.12,.57),col,Enum.Material.Metal,false)
 end
 part(m,"BuckStand",V(3186.35,3.70,129),V(1.7,.22,1.7),C.steel,Enum.Material.Wood,false)
 -- A small coachbuilder wheel-arch specimen: eight joined arc facets on a supported buck.
 local center=V(3186.35,3.80,129)
 for i=0,7 do local a=math.pi*i/8;local b=math.pi*(i+1)/8
  local p1=center+V(math.cos(a)*.86,math.sin(a)*.86,0);local p2=center+V(math.cos(b)*.86,math.sin(b)*.86,0)
  local delta=p2-p1
  local p=part(m,"FormedWheelArch_"..i,(p1+p2)/2,V(delta.Magnitude+.02,.12,1.26),Color3.fromRGB(168,177,175),Enum.Material.Metal,false)
  p.CFrame=CF(center)*CFrame.Angles(0,math.pi/2,0)*CF(p.Position-center)*CFrame.Angles(0,0,math.atan2(delta.Y,delta.X))
 end
 part(m,"RetainedDraftingPencil",V(3187.43,3.62,123.5),V(.06,.07,1.7),C.rust,Enum.Material.Wood,false)
 return m
end
local function build(l)
 local main=bed(l,"01_Main_Design_Garden",3202,123.3,22,11)
 tree(l)
 for i,q in {{3193,119.5,1.1},{3196,126.4,1.2},{3207,119.6,1.0},{3210,126,1.0}}do agave(main,"Agave"..i.."_",q[1],q[2],q[3])end
 for i,q in {{3196,122.8,2.1},{3201,126,1.8},{3207,124,2.2},{3209.8,120.2,1.5}}do rock(main,"Limestone"..i,q[1],q[2],q[3])end
 cactus(main,"PricklyPear",3193.4,126,1.1)
 for i,q in {{3192.2,121.8},{3198.3,119.5},{3199.3,126.8},{3204.8,121.2},{3206.5,126.9},{3211.7,122.8}}do grasses(main,"SageGrass_"..i.."_",q[1],q[2],1.15)end
 for _,s in {-1,1}do
  part(main,"LimestoneGroundFrameX_"..s,V(3202+s*11.25,.36,123.3),V(.45,.482,11.9),C.stone,Enum.Material.Limestone,true)
  part(main,"LimestoneGroundFrameZ_"..s,V(3202,.36,123.3+s*5.725),V(22.05,.482,.45),C.stone,Enum.Material.Limestone,true)
 end
 bench(l,"03_Main_Garden_Bench",3202,131,15,3)
 tableBuild(l);chair(l,"06_Design_Chair_A",3181.6,122,1);chair(l,"07_Design_Chair_B",3181.6,128,2)
 local far=bed(l,"08_Far_Garden",3242,125.5,9.8,15)
 agave(far,"FarAgaveA_",3239.2,120.7,1.15);agave(far,"FarAgaveB_",3244.6,130,1.25)
 cactus(far,"FarPricklyPear",3243.6,121.5,1.8)
 rock(far,"FarLimestoneA",3239.7,127.8,2.0);rock(far,"FarLimestoneB",3244,126.1,1.8)
 grasses(far,"FarGrassA_",3245.2,124,1.25);grasses(far,"FarGrassB_",3238.8,130.4,1.3)
 local fb=bench(l,"09_Far_Garden_Bench",3242,135,6,4);fb.GardenSeat:SetAttribute("ApproachZ",139.5);fb.GardenSeat:SetAttribute("ExitZ",139.5)
 local m=model(l,"10_Shielded_Garden_Light","AMBIENCE","TWO_STATIC_OWNED_LOW_WARM_LIGHTS_NO_RUNTIME_LOOP")
 local lens=part(m,"RecessedBenchLens",V(3202,1.78,130),V(11,.10,.07),C.warm,Enum.Material.Neon,false);lens.CastShadow=false
 local light=Instance.new("SurfaceLight");light.Name="ShieldedWarmBench";light.Face=Enum.NormalId.Bottom;light.Angle=110;light.Range=9;light.Brightness=.6;light.Color=C.warm;light.Shadows=false;light.Parent=lens
 local housing=part(m,"TreeUplightHousing",V(3201.2,1.47,122.5),V(.65,.30,.65),C.steel,Enum.Material.Metal,false)
 local lamp=Instance.new("PointLight");lamp.Name="BoundedTreeWash";lamp.Color=C.warm;lamp.Range=15;lamp.Brightness=.65;lamp.Shadows=false;lamp.Parent=housing
end
function I.Install()
 local r=root();assert(not layer(),"Existing owned layer; do not overwrite")
 assert(#r:GetDescendants()==14383 and geometryHash(r)=="dbccb16f","Unknown predecessor; preserve")
 assert(r:GetAttribute("InstitutionElevation01OStatus")=="ACCEPTED_PROXY","Accepted O required")
 local before=signature(r);local l=Instance.new("Model");l.Name=NAME;l:SetAttribute("Version",I.Version);l:SetAttribute("Status","BUILT_AWAITING_REVIEW");l:SetAttribute("PredecessorSignature",before);l.Parent=parent()
 local ok,err=pcall(build,l);if not ok then l:Destroy();error(err)end
 assert(signature(r,l)==before,"Retained-state drift")
 l:SetAttribute("ContentSignature",signature(l));return I.Audit()
end
function I.Uninstall()
 local r,l=root(),assert(layer());assert(l:GetAttribute("Version")==I.Version,"Version mismatch")
 assert(signature(l)==l:GetAttribute("ContentSignature"),"Owned edits; preserve")
 assert(signature(r,l)==l:GetAttribute("PredecessorSignature"),"Retained edits or later dependencies; preserve")
 l:Destroy();assert(#r:GetDescendants()==14383 and geometryHash(r)=="dbccb16f");return true
end
function I.Audit()
 local r,l=root(),assert(layer());local a={issues={},parts=0,models=0,seats=0,lights=0,scripts=0,externalPairs=0,protectedVolumes=0,routeVolumes=0,geometry=geometryHash(r),descendants=#r:GetDescendants()}
 local own,other={},{}
 for _,p in r:GetDescendants()do if p:IsA("BasePart")and(p.Transparency<.98 or p.CanCollide)then local mn,mx=bounds(p);table.insert(p:IsDescendantOf(l)and own or other,{p=p,mn=mn,mx=mx})end end
 for _,p in l:GetDescendants()do
  if p:IsA("BasePart")then a.parts+=1;if p:IsA("Seat")then a.seats+=1 end
   if not p.Anchored or not p.CanQuery or(p.CanTouch and not p:IsA("Seat"))then table.insert(a.issues,"Behavior:"..p.Name)end
  elseif p:IsA("Model")then a.models+=1;for _,k in {"BundleId","AssetStatus","FinalDetailIntent","PhaseMin","SourceGeometry"}do if p:GetAttribute(k)==nil then table.insert(a.issues,"Metadata:"..p.Name..":"..k)end end
  elseif p:IsA("Light")then a.lights+=1
  elseif p:IsA("LuaSourceContainer")then a.scripts+=1 end
 end
 for _,v in own do
  if v.mn.X<3179.9 or v.mx.X>3247.01 or v.mn.Z<113 or v.mx.Z>136.6 or v.mn.Y<.118 or v.mx.Y>17 then table.insert(a.issues,"Outside:"..v.p.Name)end
  for _,o in other do if overlaps(v.mn,v.mx,o.mn,o.mx)then a.externalPairs+=1;table.insert(a.issues,"RetainedOverlap:"..v.p.Name..":"..o.p:GetFullName())end end
 end
 for _,p in r["03_Protected_Clearances"]:GetChildren()do if p:IsA("BasePart")then a.protectedVolumes+=1;local mn,mx=bounds(p);for _,v in own do if overlaps(v.mn,v.mx,mn,mx)then table.insert(a.issues,"Protected:"..p.Name..":"..v.p.Name)end end end end
 for _,p in r["02_Vehicle_Routes"]:GetDescendants()do if p:IsA("BasePart")then a.routeVolumes+=1;local mn,mx=bounds(p);for _,v in own do if v.mn.X<mx.X-.001 and v.mx.X>mn.X+.001 and v.mn.Z<mx.Z-.001 and v.mx.Z>mn.Z+.001 then table.insert(a.issues,"Route:"..p.Name..":"..v.p.Name)end end end end
 a.retainedUnchanged=signature(r,l)==l:GetAttribute("PredecessorSignature")
 a.ownedUnchanged=signature(l)==l:GetAttribute("ContentSignature")
 if not a.retainedUnchanged then table.insert(a.issues,"RetainedDrift")end
 if not a.ownedUnchanged then table.insert(a.issues,"OwnedDrift")end
 if a.parts>550 or a.seats~=4 or a.lights~=2 or a.scripts~=0 then table.insert(a.issues,"Inventory")end
 return a
end
function I.Accept(e)
 local a=I.Audit();assert(#a.issues==0,game.HttpService:JSONEncode(a))
 -- Explicit Sep8 user direction: ship visual volume/beauty; extended proofs are not a shipping gate.
 -- Keep additive ownership and the already-measured static footprint; never invent missing test results.
 if e.UserDirectedVisualAcceptance then
  for _,k in {"VisualPass","SourceMatch","ReversibleLayer"}do assert(e[k],"Missing:"..k)end
 else
  for _,k in {"VisualPass","DayNightReviewed","ActualWalkingPass","SeatPass","PhotoAccessPass","CarProofPass","RollbackPass","SourceMatch","RenderingReviewed","PreservationGuardPass"}do assert(e[k],"Missing:"..k)end
 end
 local l=layer();assert(l:GetAttribute("Status")=="BUILT_AWAITING_REVIEW","Already accepted")
 local f=Instance.new("Folder");f.Name="97_Evidence";for k,v in e do f:SetAttribute(k,v)end;f.Parent=l
 l:SetAttribute("Status",e.UserDirectedVisualAcceptance and "SHIPPED_VISUAL_PROXY" or "ACCEPTED_PROXY");for _,m in l:GetChildren()do if m:IsA("Model")then m:SetAttribute("AssetStatus","MODELER_READY")end end
 l:SetAttribute("ContentSignature",signature(l));return I.Audit()
end
return I

