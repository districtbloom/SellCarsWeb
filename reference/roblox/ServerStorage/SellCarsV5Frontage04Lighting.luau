--!nocheck
-- F04-5: sixteen native, supported, shielded fixtures; no global Lighting edits.
-- This is geometry/data only. The shared preset adapter owns Enabled/Brightness.
-- Exact candidate mount references are retained for integration and rollback.
return function(K, parent, candidate)
 local C, V, E = K.C, Vector3.new, Enum.Material
 local root=K.model(parent,"07_Frontage_Warm_Lighting","ARCHITECTURAL_LIGHTING")
 root:SetAttribute("Version","2026-09-08.frontage04.f5.1")
 root:SetAttribute("AssetStatus","DETAILED_PROXY_CANDIDATE")
 root:SetAttribute("LightPolicy","BOUNDED_SHARED_PRESET_NO_PER_PROP_SCRIPT")
 root:SetAttribute("FixtureCount",16)
 root:SetAttribute("WarmColor",Color3.fromRGB(255,224,177))
 local architecture=assert(candidate:FindFirstChild("01_Architecture"),"Missing canonical frontage architecture")
 local bronze=Color3.fromRGB(157,122,66)
 local lensColor=Color3.fromRGB(230,218,191)
 local function box(m,n,x,y,z,w,h,d,col,mat)
  local p=K.box(m,n,x,y,z,w,h,d,col or C.black,mat or E.Metal,false)
  p.CanTouch=false;p.CastShadow=false
  return p
 end
 local function withinFootprint(p,x,z,halfX,halfZ)
  local q=p.CFrame:PointToObjectSpace(V(x,p.Position.Y,z))
  return math.abs(q.X)+halfX<=p.Size.X/2+.001 and math.abs(q.Z)+halfZ<=p.Size.Z/2+.001
 end
 local function soffit(department,roof,x,z)
  local d=assert(architecture:FindFirstChild(department),"Missing department "..department)
  local r=assert(d:FindFirstChild(roof),"Missing roof "..roof)
  local best,bestX,bestZ,bestDistance
  for _,p in r:GetChildren()do
   if p:IsA("BasePart")and p.Name:match("^TimberSoffit_")then
    if withinFootprint(p,x,z,.53,.43)then return p,x,z end
    -- A target over a board joint moves only the fixture plate, never a roof
    -- or car. Keep the whole plate on one board rather than spanning its gap.
    local px=math.clamp(x,p.Position.X-p.Size.X/2+.54,p.Position.X+p.Size.X/2-.54)
    local pz=math.clamp(z,p.Position.Z-p.Size.Z/2+.44,p.Position.Z+p.Size.Z/2-.44)
    local distance=math.sqrt((px-x)^2+(pz-z)^2)
    if not bestDistance or distance<bestDistance then best,bestX,bestZ,bestDistance=p,px,pz,distance end
   end
  end
  assert(best and bestDistance<.65,"No nearby complete soffit mounting contact at "..department.." "..x..","..z)
  return best,bestX,bestZ
 end
 local function fixture(name,lightName,mount,x,z,range,night,day,tilt)
  assert(mount:IsA("BasePart")and withinFootprint(mount,x,z,.53,.43),"Fixture plate exceeds its support: "..name)
  assert(math.abs(mount.CFrame.UpVector.Y-1)<.0001,"Unexpected tilted mounting support")
  local y=mount.Position.Y-mount.Size.Y/2
  local m=K.model(root,name,"ARCHITECTURAL_LIGHTING")
  m:SetAttribute("AssetStatus","DETAILED_PROXY_CANDIDATE")
  m:SetAttribute("FixtureRole","SHIELDED_WARM_DOWNLIGHT")
  m:SetAttribute("CollisionClass","OVERHEAD_DECORATIVE")
  m:SetAttribute("MountContactY",y)
  m:SetAttribute("AllowedMin",V(x-1.7,y-1.65,z-1.6))
  m:SetAttribute("AllowedMax",V(x+1.7,y+.005,z+1.6))
  local ref=Instance.new("ObjectValue");ref.Name="MountReference";ref.Value=mount;ref.Parent=m
  local plate=box(m,"MountPlate",x,y-.045,z,1.06,.09,.86,C.steel)
  box(m,"ShortStem",x,y-.235,z,.18,.30,.18,C.black)
  box(m,"BronzeStemCollar",x,y-.34,z,.34,.09,.34,bronze)
  local cf=CFrame.new(x,y-.56,z)*CFrame.Angles(math.rad(tilt or 0),0,0)
  local function localBox(n,px,py,pz,w,h,d,col,mat)
   local p=box(m,n,0,0,0,w,h,d,col,mat);p.CFrame=cf*CFrame.new(px,py,pz);return p
  end
  localBox("FoldedSteelHousing",0,0,0,2.44,.28,1.86,C.black)
  localBox("BronzeHousingSeam",0,-.10,0,2.46,.055,1.88,bronze)
  local lens=localBox("RecessedDiffuser",0,-.165,0,2.06,.035,1.48,lensColor,E.Glass)
  lens.Transparency=.12; lens.Reflectance=.025
  for i,s in ipairs({-1,1})do
   localBox("SideCutoffShield_"..i,s*1.16,-.20,0,.12,.31,1.85,C.black)
   localBox("EndCutoffShield_"..i,0,-.20,s*.865,2.20,.31,.12,C.black)
   localBox("CaptiveFastener_"..i,s*.87,.15,0,.09,.035,.09,bronze)
  end
  local lamp=Instance.new("SurfaceLight");lamp.Name=lightName
  lamp.Face=Enum.NormalId.Bottom;lamp.Angle=110;lamp.Range=range
  lamp.Color=Color3.fromRGB(255,224,177);lamp.Brightness=day;lamp.Shadows=false;lamp.Enabled=false
  lamp:SetAttribute("Role","Public");lamp:SetAttribute("StoreRole","Public")
  lamp:SetAttribute("NightBrightness",night);lamp:SetAttribute("DayBrightness",day)
  lamp:SetAttribute("ManagedRange",range);lamp:SetAttribute("Range",range)
  lamp:SetAttribute("F04LightKey",lightName);lamp:SetAttribute("SharedPresetManaged",true)
  lamp.Parent=lens
  local socket=Instance.new("Attachment");socket.Name=name.."_MountSocket";socket.Parent=plate
  return m
 end
 local function under(name,key,department,roof,x,z,range,night,day)
  local mount,px,pz=soffit(department,roof,x,z)
  local m=fixture(name,key,mount,px,pz,range,night,day)
  m:SetAttribute("RequestedTargetXZ",V(x,0,z))
  return m
 end
 -- Clear receiving frontage: distinct pools over each of the three positions.
 -- Existing F03 optical-rig cloned lights remain untouched/disabled; integration
 -- may redirect their historic consumers to these roof-supported replacements.
 under("01_Ordinary_Receiving_One","Old034Ordinary1","01_Receiving_Cantilever_Canopy","SeamedReceivingRoof",3033,64,27,1.30,.48)
 under("02_Ordinary_Receiving_Two","Old035Ordinary2","01_Receiving_Cantilever_Canopy","SeamedReceivingRoof",3052,64,27,1.30,.48)
 under("03_Special_Receiving","SpecialReceiving","01_Receiving_Cantilever_Canopy","SeamedReceivingRoof",3014,64,28,1.25,.42)
 -- Four restrained pools per gallery, not continuous luminous strips. The
 -- furthest west fixture is dedicated to the separate delivery/reveal position.
 under("04_West_First_Display","WestFirstDisplay","03_West_Sales_Colonnade","CraftedSalesRoof",3098,15,25,1.15,.38)
 under("05_West_Centre_Display","Old036WestSales","03_West_Sales_Colonnade","CraftedSalesRoof",3098,35,25,1.20,.42)
 under("06_West_Third_Display","WestThirdDisplay","03_West_Sales_Colonnade","CraftedSalesRoof",3098,58,25,1.15,.38)
 under("07_West_Handover","Old038Handover","03_West_Sales_Colonnade","CraftedSalesRoof",3098,73,25,1.30,.45)
 under("08_East_First_Display","EastFirstDisplay","04_East_Sales_Colonnade","CraftedSalesRoof",3156.5,13,25,1.15,.38)
 under("09_East_Centre_Display","Old037EastSales","04_East_Sales_Colonnade","CraftedSalesRoof",3156.5,32,25,1.20,.42)
 under("10_East_Third_Display","EastThirdDisplay","04_East_Sales_Colonnade","CraftedSalesRoof",3156.5,51,25,1.15,.38)
 under("11_East_Service_Staging","ServiceStaging","04_East_Sales_Colonnade","CraftedSalesRoof",3156.5,70,23,1.05,.32)
 -- Room lighting reads warm on leather/oak but does not cast shadows or blow
 -- out the clear glazing. A small entry downlight gives the door a destination.
 under("12_Lounge_Seating","LoungeSeating","02_Shared_Customer_Room","CustomerRoomRoof",3078,18,22,1.20,.48)
 under("13_Lounge_Coffee_And_Craft","LoungeCoffee","02_Shared_Customer_Room","CustomerRoomRoof",3066,33,22,1.20,.48)
 under("14_Welcome_Entry","WelcomeEntry","02_Shared_Customer_Room","WelcomeEyebrow",3072,6.85,17,.90,.22)
 local gateway=assert(architecture:FindFirstChild("05_Desert_Customs_Street_Gateway"))
 local beam=assert(gateway:FindFirstChild("CrownStructuralBeam"))
 fixture("15_Gateway_West","GateWest",beam,3120,-11,25,1.20,.20,18)
 fixture("16_Gateway_East","GateEast",beam,3140,-11,25,1.20,.20,18)
 return root
end

