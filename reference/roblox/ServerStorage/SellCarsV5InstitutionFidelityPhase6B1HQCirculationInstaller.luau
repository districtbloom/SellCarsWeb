--!nocheck
-- Phase 6B1 owns HQ circulation only. All machines are parked; no independent runtime.
local I={Version="2026-09-07.phase6b1.1"}
local Kit=require(game.ServerStorage.SellCarsV5InstitutionFidelitySharedKit)
local C=Kit.Colors
local M,P=Enum.Material.Metal,Enum.Material.SmoothPlastic
local ROOT,PHASE,NAME="SellCars_Dealership_Growth_V5","05_Prestige_And_Public_Realm","02_HQ_Circulation"
local function root() return (assert(workspace:FindFirstChild(ROOT),"V5 root missing")) end
local function layer() local p=root()["10_Institution_Fidelity_R1"]:FindFirstChild(PHASE);return p and p:FindFirstChild(NAME) end
local function group(parent,n,role,first,ancestor)
 local m=Instance.new("Model");m.Name=n;m.Parent=parent
 for k,v in pairs({BundleId="Institution.HQ_Circulation."..n..".FidelityR1",FunctionId="HQ_Circulation",ZoneId="HQ_Circulation",FidelityRole=role,PhaseMin=first,Ancestor=ancestor,InheritanceRule="UPGRADE",AssetStatus="PROXY",CollisionClass=role=="ARCHITECTURE" and "STRUCTURE" or "EQUIPMENT",InteractionAnchor="",FXSocket="",SourceGeometry="PARAMETRIC_PROXY"}) do m:SetAttribute(k,v) end
 return m
end
local function box(m,n,x,y,z,w,h,d,col,mat,solid,rot)
 local p=Instance.new("Part");p.Name=n;p.Anchored=true;p.Size=Vector3.new(w,h,d);p.CFrame=CFrame.new(x,y,z)*(rot or CFrame.identity)
 p.Material=mat or M;p.Color=col or C.Stainless;p.CanCollide=solid==true;p.CanTouch=false;p.CanQuery=true;p.CastShadow=solid==true;p.TopSurface=0;p.BottomSurface=0
 p:SetAttribute("V5Blocker",solid==true);p:SetAttribute("Phase6B1HQGeometry",true);p.Parent=m;return p
end
local function cyl(m,n,x,y,z,length,diam,col,axis,solid)
 local rot=axis=="Y" and CFrame.Angles(0,0,math.pi/2) or axis=="Z" and CFrame.Angles(0,math.pi/2,0) or CFrame.identity
 local p=box(m,n,x,y,z,length,diam,diam,col,M,solid,rot);p.Shape=Enum.PartType.Cylinder;return p
end
local function pipe(m,n,a,b,diam,col)
 local d=b-a;local p=box(m,n,(a.X+b.X)/2,(a.Y+b.Y)/2,(a.Z+b.Z)/2,d.Magnitude,diam,diam,col,M,false)
 p.Shape=Enum.PartType.Cylinder;p.CFrame=CFrame.lookAt((a+b)/2,b)*CFrame.Angles(0,math.pi/2,0);return p
end
local function point(m,n,x,y,z,kind)
 local p=box(m,n,x,y,z,.1,.1,.1,C.Green,P,false);p.Transparency=1;p.CanQuery=false;p:SetAttribute("AnchorKind",kind)
 local a=Instance.new("Attachment");a.Name=n.."_Socket";a.Parent=p;m:SetAttribute(kind=="FX" and "FXSocket" or "InteractionAnchor",n);return p
end
local function path(owner,n,points)
 local f=owner:FindFirstChild("98_Access_Paths") or Instance.new("Folder");f.Name="98_Access_Paths";f.Parent=owner
 local p=Instance.new("Folder");p.Name=n;p.Parent=f
 for i,v in ipairs(points) do local a=Instance.new("Vector3Value");a.Name=string.format("%02d",i);a.Value=Vector3.new(v[1],v[2],v[3]);a.Parent=p end
end



local function slab(m,n,x1,x2,z1,z2,top,thick,col)
 local p=box(m,n,(x1+x2)/2,top-thick/2,(z1+z2)/2,x2-x1,thick,z2-z1,col or C.Concrete,Enum.Material.Concrete,true)
 p:SetAttribute("WalkSurface",true);return p
end
local function edge(m,n,a,b)
 local d=b-a
 local horizontal=Vector3.new(d.X,0,d.Z).Magnitude
 local infillLength=math.max(.1,d.Magnitude-3.3*math.abs(d.Y)/math.max(.01,horizontal))
 local rail=pipe(m,n.."Handrail",a+Vector3.new(0,3.6,0),b+Vector3.new(0,3.6,0),.22,C.Bronze);rail.CanCollide=true
 local glass=box(m,n.."GuardInfill",(a.X+b.X)/2,(a.Y+b.Y)/2+1.8,(a.Z+b.Z)/2,.16,3.3,infillLength,C.Galvanized,Enum.Material.Glass,true)
 glass.CFrame=CFrame.lookAt((a+b)/2+Vector3.new(0,1.8,0),b+Vector3.new(0,1.8,0));glass.Transparency=.78
 local count=math.max(1,math.ceil(d.Magnitude/4))
 for i=0,count do local p=a:Lerp(b,i/count);box(m,n.."GuardPost",p.X,p.Y+1.8,p.Z,.22,3.6,.22,C.Charcoal,M,true) end
end
local function flight(m,n,x,z0,z1,y0,y1,count)
 local points={{x,y0,z0}};local step=(z1-z0)/count;local rise=(y1-y0)/count
 for i=1,count do local z=z0+(i-.5)*step;local top=y0+i*rise
  slab(m,n.."Tread_"..i,x-3,x+3,z-math.abs(step)/2,z+math.abs(step)/2,top,.20,C.Concrete)
  box(m,n.."Riser",x,top-rise/2,z-step/2,6,rise,.12,C.Steel,M,false)
  box(m,n.."BronzeNosing",x,top+.015,z-step/2+.06*(step>0 and 1 or -1),5.9,.03,.10,C.Bronze,M,false)
  table.insert(points,{x,top,z})
 end
 table.insert(points,{x,y1,z1})
 for _,dx in ipairs({-3.1,3.1}) do
  local a,b=Vector3.new(x+dx,y0,z0),Vector3.new(x+dx,y1,z1)
  edge(m,n,a,b)
  local va,vb=a-Vector3.new(0,.4,0),b-Vector3.new(0,.4,0)
  local p=box(m,n.."SteelStringer",(va.X+vb.X)/2,(va.Y+vb.Y)/2,(va.Z+vb.Z)/2,.32,.5,(vb-va).Magnitude,C.Charcoal,M,true);p.CFrame=CFrame.lookAt((va+vb)/2,vb)
 end
 return points
end
local function floors(l)
 local m=group(l,"HQ_Cut_Floor_Decks","ARCHITECTURE","PROFESSIONAL","Working office slab -> permanent guarded three-level circulation")
 -- Same outer floor dimensions and heights, assembled around fixed stair holes.
 slab(m,"Floor2West",3091,3100,456,498,16.5,.8,C.Navy)
 slab(m,"Floor2East",3116,3169,456,498,16.5,.8,C.Navy)
 slab(m,"Floor2Front",3100,3116,456,465,16.5,.8,C.Navy)
 slab(m,"Floor2Rear",3100,3116,489.5,498,16.5,.8,C.Navy)
 slab(m,"UpperStairEntryLanding",3100,3108,465,471,16.5,.8,C.Navy)
 slab(m,"Floor3West",3098,3100,467,497,28.8,.8,C.Navy)
 slab(m,"Floor3East",3116,3162,467,497,28.8,.8,C.Navy)
 slab(m,"Floor3FrontLanding",3100,3116,467,471,28.8,.8,C.Navy)
 slab(m,"Floor3Rear",3100,3116,489.5,497,28.8,.8,C.Navy)
 for _,v in ipairs({{16.5,465},{28.8,471}}) do
  local y,z=v[1],v[2]
  edge(m,"WellEast",Vector3.new(3116,y,z),Vector3.new(3116,y,489.5))
  edge(m,"WellWest",Vector3.new(3100,y,v[1]==16.5 and 471 or 471),Vector3.new(3100,y,489.5))
  edge(m,"WellRear",Vector3.new(3100,y,489.5),Vector3.new(3116,y,489.5))
 end
 edge(m,"CrownWellFront",Vector3.new(3100,28.8,471),Vector3.new(3108.6,28.8,471))
end
local function stairs(l)
 local m=group(l,"HQ_Return_Stair","HERO","PROFESSIONAL","Small office access -> crafted steel return stair through fixed floor levels")
 local p1=flight(m,"GroundToTurn",3104,465,484.2,.7,8.6,16)
 local p2=flight(m,"TurnToSecond",3112,484.2,465,8.6,16.5,16)
 local p3=flight(m,"SecondToTurn",3104,471,483,16.5,22.65,12)
 local p4=flight(m,"TurnToCrown",3112,483,471,22.65,28.8,12)
 slab(m,"LowerReturnLanding",3100,3116,484.2,489.5,8.6,.5,C.Concrete)
 slab(m,"UpperReturnLanding",3100,3116,483,489.5,22.65,.5,C.Concrete)
 for _,v in ipairs({{8.6,484.2},{22.65,483}}) do
  edge(m,"ReturnRear",Vector3.new(3100,v[1],489.2),Vector3.new(3116,v[1],489.2))
  for _,x in ipairs({3100,3116}) do edge(m,"ReturnSide",Vector3.new(x,v[1],v[2]),Vector3.new(x,v[1],489.2)) end
 end
 for _,x in ipairs({3100.3,3115.7}) do
  box(m,"StairLandingSupport",x,11.6,488.8,.55,21.8,.55,C.Charcoal,M,true)
  box(m,"SupportBasePlate",x,.8,488.8,1.1,.2,1.1,C.Steel,M,false)
 end
 path(l,"LowerFlightA",p1);path(l,"LowerFlightB",p2);path(l,"UpperFlightA",p3);path(l,"UpperFlightB",p4)
 path(l,"LowerReturn",{{3104,8.6,484.2},{3104,8.6,486.7},{3112,8.6,486.7},{3112,8.6,484.2}})
 path(l,"UpperReturn",{{3104,22.65,483},{3104,22.65,486},{3112,22.65,486},{3112,22.65,483}})
 point(m,"StairServiceAnchor",3119,16.5,487,"OPERATOR")
end
local function doors(l)
 local m=group(l,"HQ_True_Entrance_Openings","ARCHITECTURE","DEDICATED","Small deal office entrance -> formal pedestrian lobby and gallery connection")
 for _,v in ipairs({{3107,447,36,8,14},{3153,447,36,8,14},{3109.5,456,31,22.2,10.5},{3150.5,456,31,22.2,10.5}}) do
  local p=box(m,"RetainedFacadeSideLight",v[1],v[4],v[2],v[3],v[5],.35,C.Galvanized,Enum.Material.Glass,true);p.Transparency=.76
 end
 for _,v in ipairs({{447,.7,11.2},{456,16.5,10.5}}) do
  for _,x in ipairs({3125,3135}) do box(m,"DoorJamb",x,v[2]+v[3]/2,v[1],.35,v[3],.55,C.Charcoal,M,true) end
  box(m,"DoorLintel",3130,v[2]+v[3]-.35,v[1],10,.7,.6,C.Charcoal,M,true)
 end
 slab(m,"LobbyFirstStep",3124.7,3135.3,445,446,.3975,.30,C.Concrete)
 slab(m,"LobbyThreshold",3124.7,3135.3,446,447.2,.7,.30,C.Concrete)
end
local function bridge(l)
 local m=group(l,"Gallery_Stepped_Link","ARCHITECTURE","PROFESSIONAL","Collection room beside office -> safe elevated public gallery link")
 -- Bridge platform is retained. Only the previously absent connection is inserted.
 local points=flight(m,"GalleryLink",3130,456,446,16.5,21,9)
 -- Gallery link uses10stud width; flight helper creates6, widen only its treads/risers here.
 for _,p in ipairs(m:GetChildren()) do
  if p:IsA("BasePart") then
   if p.Name:find("Tread") or p.Name:find("Riser") then p.Size=Vector3.new(10,p.Size.Y,p.Size.Z)
   elseif p.Name:find("Nosing") then p.Size=Vector3.new(9.9,p.Size.Y,p.Size.Z)
   elseif p.Position.X<3129 then p.Position+=Vector3.new(-2,0,0)
   elseif p.Position.X>3131 then p.Position+=Vector3.new(2,0,0) end
  end
 end
 for _,x in ipairs({3118,3142}) do edge(m,"BridgeSide",Vector3.new(x,21,435),Vector3.new(x,21,446)) end
 edge(m,"BridgeEndWest",Vector3.new(3118,21,446),Vector3.new(3124.9,21,446))
 edge(m,"BridgeEndEast",Vector3.new(3135.1,21,446),Vector3.new(3142,21,446))
 path(l,"GallerySteppedLink",points)
 point(m,"GalleryEntryAnchor",3130,21,439,"VIEWING")
end
local function connections(l)
 path(l,"PublicLobbyApproach",{{3130,.095,440},{3130,.095,444.8},{3130,.3975,445.5},{3130,.7,446.5},{3130,.7,451},{3104,.7,451},{3104,.7,465}})
 path(l,"Level2Connections",{{3112,16.5,465},{3112,16.5,460},{3130,16.5,460},{3130,16.5,456}})
 path(l,"Level2ToUpperStair",{{3112,16.5,460},{3104,16.5,460},{3104,16.5,471}})
 path(l,"CrownArrival",{{3112,28.8,471},{3112,28.8,469.2},{3130,28.8,469.2},{3140,28.8,469.2},{3140,28.8,487}})
 path(l,"GalleryBridge",{{3130,21,446},{3130,21,439},{3130,21,435},{3130,20.94,433},{3130,20.94,432},{3116,20.94,432}})
 local m=group(l,"Circulation_Review_Anchors","UTILITY","PROFESSIONAL","Stair landing task light -> controlled upper-campus wayfinding")
 for i,v in ipairs({{3104,3.8,462},{3112,19.6,462},{3112,31.9,469.2}}) do point(m,"LandingReview_"..i,v[1],v[2],v[3],"FX") end
end
local function suppress(owner,target)
 local rs=owner:FindFirstChild("90_Restoration") or Instance.new("Folder");rs.Name="90_Restoration";rs.Parent=owner
 local list=target:GetDescendants();table.insert(list,1,target)
 for _,o in ipairs(list) do if o:IsA("BasePart") or o:IsA("Light") or o:IsA("SurfaceGui") or o:IsA("BillboardGui") then
  local r=Instance.new("ObjectValue");r.Name="Saved_"..o.Name;r.Value=o;r.Parent=rs
  if o:IsA("BasePart") then
   for _,k in ipairs({"Transparency","CanCollide","CanTouch","CanQuery","CastShadow"}) do r:SetAttribute(k,o[k]) end
   o.Transparency=1;o.CanCollide=false;o.CanTouch=false;o.CanQuery=false;o.CastShadow=false
  else r:SetAttribute("Enabled",o.Enabled);o.Enabled=false end
 end end
end
local function signature(l)
 local rows={};for _,p in ipairs(l:GetDescendants()) do if p:IsA("BasePart") then
  local cf={};for _,v in ipairs({p.CFrame:GetComponents()}) do local n=string.format("%.3f",v);if n=="-0.000" then n="0.000" end;table.insert(cf,n) end
  table.insert(rows,p:GetFullName().."|"..table.concat(cf,",").."|"..tostring(p.Size).."|"..tostring(p.Color).."|"..p.Material.Name.."|"..tostring(p.Transparency))
 end end;table.sort(rows);local h=5381;for _,s in ipairs(rows) do for i=1,#s do h=(h*33+s:byte(i))%4294967296 end end;return string.format("%08x",h)
end
function I.Uninstall()
 local l=layer();if l then
  local rs=l:FindFirstChild("90_Restoration");if rs then for _,r in ipairs(rs:GetChildren()) do if r.Value then for k,v in pairs(r:GetAttributes()) do r.Value[k]=v end end end end
  l:Destroy()
 end
 local p=root()["10_Institution_Fidelity_R1"]:FindFirstChild(PHASE);if p and #p:GetChildren()==0 then p:Destroy() end
 root():SetAttribute("InstitutionFidelityPhase6B1HQStatus",nil);return true
end


function I.Install()
 assert(root():GetAttribute("InstitutionFidelityPhase6ACollectorStatus")=="ACCEPTED_LOCAL_GALLERY","Accepted Collector required")
 I.Uninstall();local p=root()["10_Institution_Fidelity_R1"][PHASE]
 local l=Instance.new("Model");l.Name=NAME;l.Parent=p;l:SetAttribute("Version",I.Version)
 local ok,err=pcall(function()
  local h=root()["09_Institution_Production_B"]["02_Rear_Operations_And_Prestige"]["07_Institution_Headquarters"]
  for _,d in ipairs(h:GetChildren()) do
   local hide=d.Name=="HQFloor2" or d.Name=="HQFloor3" or d.Name=="HQGlassFront1" or d.Name=="HQGlassFront2" or d.Name=="LobbyDoorLeft" or d.Name=="LobbyDoorRight" or d.Name=="BridgeGlass"
   if d.Name=="AnalyticsPanel" and d:IsA("BasePart") and d.Position.X>3120 and d.Position.X<3140 then hide=true end
   if d.Name=="AnalyticsDesk" and d:IsA("Model") and d:GetPivot().Position.X<3110 then hide=true end
   if hide then suppress(l,d) end
  end
  floors(l);stairs(l);doors(l);bridge(l);connections(l)
 end)
 if not ok then I.Uninstall();error(err) end
 l:SetAttribute("Status","BUILT_AWAITING_REVIEW");root():SetAttribute("InstitutionFidelityPhase6B1HQStatus","BUILT_AWAITING_REVIEW")
 return I.Audit()
end
function I.Audit()
 local l=assert(layer());local issues,meta,missing,ids={},{},{},{}
 local stats={parts=0,solids=0,models=0,paths=0,bodySamples=0,floorSamples=0,standingVolumes=0,envelopeCorners=0,issues=issues,missingFloor=missing,metadataIssues=meta,signature=signature(l)}
 local params=OverlapParams.new();params.FilterType=Enum.RaycastFilterType.Include;params.FilterDescendantsInstances={l};params.RespectCanCollide=false
 local function top(p) return p.Position.Y+(math.abs(p.CFrame.RightVector.Y)*p.Size.X+math.abs(p.CFrame.UpVector.Y)*p.Size.Y+math.abs(p.CFrame.LookVector.Y)*p.Size.Z)/2 end
 local function check(n,cf,size,feet)
  for _,p in ipairs(workspace:GetPartBoundsInBox(cf,size,params)) do
   if p.Transparency<.98 and top(p)>feet+.55 then table.insert(issues,n..": "..p:GetFullName()) end
  end
 end
 for _,p in ipairs(root()["03_Protected_Clearances"]:GetChildren()) do if p:IsA("BasePart") then check(p.Name,p.CFrame,p.Size,0) end end
 for _,p in ipairs(root()["02_Vehicle_Routes"]:GetDescendants()) do if p:IsA("BasePart") then check(p.Name,p.CFrame+Vector3.new(0,4.2,0),Vector3.new(p.Size.X,7,p.Size.Z),0) end end
 params.FilterDescendantsInstances={root()}
 local rays=RaycastParams.new();rays.FilterType=Enum.RaycastFilterType.Include;rays.FilterDescendantsInstances={root()};rays.RespectCanCollide=true
 for _,route in ipairs(l["98_Access_Paths"]:GetChildren()) do
  stats.paths+=1;local points=route:GetChildren();table.sort(points,function(a,b)return a.Name<b.Name end)
  for i=1,#points-1 do local a,b=points[i].Value,points[i+1].Value;local diff=b-a;local horizontal=Vector3.new(diff.X,0,diff.Z)
   if horizontal.Magnitude>.001 then
    local side=Vector3.new(horizontal.Z,0,-horizontal.X).Unit;local steps=math.max(1,math.ceil(horizontal.Magnitude/.45))
    for j=0,steps do local v=a:Lerp(b,j/steps);stats.bodySamples+=1
     check(route.Name,CFrame.lookAt(v+Vector3.new(0,3.3,0),v+Vector3.new(0,3.3,0)+horizontal),Vector3.new(3,5.8,.4),v.Y)
     for _,dx in ipairs({-1,0,1}) do local q=v+side*dx;stats.floorSamples+=1
      local hit=workspace:Raycast(q+Vector3.new(0,.65,0),Vector3.new(0,-1.4,0),rays)
      if not hit or math.abs(hit.Position.Y-v.Y)>.55 then table.insert(missing,route.Name..":"..tostring(q)) end
     end
    end
   end
  end
 end
 for _,name in ipairs({"StairServiceAnchor","GalleryEntryAnchor"}) do
  local anchor=assert(l:FindFirstChild(name,true));stats.standingVolumes+=1
  check(name,CFrame.new(anchor.Position+Vector3.new(0,3.3,0)),Vector3.new(3,5.8,3),anchor.Position.Y)
 end
 for _,m in ipairs(l:GetDescendants()) do
  if m:IsA("Model") then stats.models+=1
   for _,k in ipairs({"BundleId","FunctionId","ZoneId","FidelityRole","PhaseMin","Ancestor","InheritanceRule","AssetStatus","CollisionClass","InteractionAnchor","FXSocket"}) do if m:GetAttribute(k)==nil then table.insert(meta,m.Name..":"..k) end end
   local id=m:GetAttribute("BundleId");if id then if ids[id] then table.insert(meta,"Duplicate:"..id) end;ids[id]=true end
   for _,k in ipairs({"InteractionAnchor","FXSocket"}) do local n=m:GetAttribute(k);if n and n~="" and not m:FindFirstChild(n,true) then table.insert(meta,"Missing anchor:"..n) end end
  elseif m:IsA("BasePart") then stats.parts+=1;if m.CanCollide then stats.solids+=1 end
   for _,sx in ipairs({-1,1}) do for _,sy in ipairs({-1,1}) do for _,sz in ipairs({-1,1}) do
    local v=m.CFrame:PointToWorldSpace(m.Size*Vector3.new(sx,sy,sz)/2);stats.envelopeCorners+=1
    if v.X<3084 or v.X>3176 or v.Z<434.8 or v.Z>498.2 or v.Y>56 then table.insert(issues,"HQEnvelope:"..m:GetFullName()) end
   end end end
  end
 end
 return stats
end
function I.Accept(e)
 local a=I.Audit();assert(#a.issues==0 and #a.missingFloor==0 and #a.metadataIssues==0,"Unresolved circulation audit")
 assert(e.VisualPass and e.ActualWalkBothDirections and e.RollbackPass and e.SourceMatch and e.CollectorRegression,"Evidence missing")
 local f=Instance.new("Folder");f.Name="99_Evidence";f.Parent=layer();for k,v in pairs(e) do f:SetAttribute(k,v) end
 for _,m in layer():GetDescendants() do if m:IsA("Model") then m:SetAttribute("AssetStatus","MODELER_READY") end end
 layer():SetAttribute("Status","ACCEPTED_CIRCULATION");root():SetAttribute("InstitutionFidelityPhase6B1HQStatus","ACCEPTED_CIRCULATION");return a
end
return I

