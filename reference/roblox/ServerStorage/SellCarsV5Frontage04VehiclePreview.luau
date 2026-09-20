--!nocheck
-- F04-4 EDIT PREVIEW ONLY. Move the six retained cars, never replace their identity.
-- Installer calls Show after its visual mask, Restore before restoring that mask.
-- Recovery lives in the current Recovery_Preview_N; no original attributes,
-- physics flags, sources, Intake routes, actors or unrelated sockets are edited.
local V={Version="2026-09-08.frontage04.vehicle-preview.1"}
local schedule={
 {"Ground_Display_1/SalesCar_1","SalesDisplay_1",3098,15,-90},
 {"Elevated_Centreline_Display_1/ElevatedSalesCar_1","SalesDisplay_2",3098,35,-90},
 {"Ground_Display_2/SalesCar_2","SalesDisplay_3",3156.5,13,90},
 {"Ground_Display_3/SalesCar_3","SalesDisplay_4",3098,58,-90},
 {"Elevated_Centreline_Display_2/ElevatedSalesCar_2","SalesDisplay_5",3156.5,32,90},
 {"Ground_Display_4/SalesCar_4","SalesDisplay_6",3156.5,51,90},
}
local function folder(parent,name)
 local v=Instance.new("Folder");v.Name=name;v.Parent=parent;return v
end
local function reference(parent,name,target)
 local v=Instance.new("ObjectValue");v.Name=name;v.Value=target;v.Parent=parent;return v
end
local function target(parent,name)
 local v=parent:FindFirstChild(name)
 assert(v and v:IsA("ObjectValue")and v.Value,"Lost recovery reference: "..name)
 return v.Value
end
local function at(parent,path)
 for name in path:gmatch("[^/]+")do parent=assert(parent:FindFirstChild(name),"Missing "..path)end
 return parent
end
local function attributeSnapshot(parent,instance)
 local snapshot=folder(parent,"OriginalAttributes")
 for k,value in instance:GetAttributes()do snapshot:SetAttribute(k,value)end
 return snapshot
end
local function attributesEqual(instance,snapshot)
 local saved=snapshot:GetAttributes();local current=instance:GetAttributes()
 for key,value in saved do if current[key]~=value then return false end end
 for key,value in current do if saved[key]~=value then return false end end
 return true
end
local function sameCF(a,b)
 local aa={a:GetComponents()};local bb={b:GetComponents()}
 for i=1,12 do if math.abs(aa[i]-bb[i])>.003 then return false end end
 return true
end
local function visualKeys(v)
 if v:IsA("BasePart")then return {"Transparency","CastShadow"}
 elseif v:IsA("Decal")or v:IsA("Texture")then return {"Transparency"}
 elseif v:IsA("Light")or v:IsA("SurfaceGui")or v:IsA("BillboardGui")or v:IsA("ParticleEmitter")or v:IsA("Beam")or v:IsA("Trail")then return {"Enabled"}end
end
local function restoreVisible(v,entry)
 for _,key in visualKeys(v)or{}do
  local value=entry:GetAttribute(key);assert(value~=nil,"Missing original visual property "..key)
  v[key]=value
 end
end
local function visualLookup(state)
 local lookup={}
 for _,entry in assert(state:FindFirstChild("ExactModifiedProperties")):GetChildren()do
  assert(entry:IsA("ObjectValue")and entry.Value,"Lost original mask reference")
  assert(not lookup[entry.Value],"Duplicate original mask reference")
  lookup[entry.Value]=entry
 end
 return lookup
end
-- Duplicate sibling names (four Wheel parts) are matched by class/name ordinal.
-- This makes a full original-visibility clone without changing the masked original.
local function originalVisibilityOnClone(original,copy,lookup)
 if visualKeys(original)then restoreVisible(copy,assert(lookup[original],"Unrecorded car visual"))end
 local ordinal={};local children=copy:GetChildren()
 for _,child in original:GetChildren()do
  local key=child.ClassName.."/"..child.Name;ordinal[key]=(ordinal[key]or 0)+1
  local n=0;local match
  for _,candidate in children do
   if candidate.ClassName==child.ClassName and candidate.Name==child.Name then
    n+=1;if n==ordinal[key]then match=candidate;break end
   end
  end
  assert(match,"Incomplete ordinal-matched car clone")
  originalVisibilityOnClone(child,match,lookup)
 end
end
local function captureObject(parent,name,v)
 local rec=reference(parent,name,v);reference(rec,"OriginalParent",assert(v.Parent))
 rec:SetAttribute("OriginalName",v.Name);attributeSnapshot(rec,v)
 return rec
end
local function checkIdentity(rec,allowParent)
 local v=assert(rec.Value,"Original object missing: "..rec.Name)
 assert(v.Name==rec:GetAttribute("OriginalName"),"Original renamed externally; preserve: "..rec.Name)
 assert(attributesEqual(v,rec.OriginalAttributes),"Original attributes changed externally; preserve: "..rec.Name)
 local oldParent=target(rec,"OriginalParent")
 assert(v.Parent==oldParent or v.Parent==allowParent,"Original reparented externally; preserve: "..rec.Name)
 return v,oldParent
end
local function checkPart(rec)
 local v=checkIdentity(rec)
 assert(v:IsA("BasePart")and v.Size==rec:GetAttribute("OriginalSize"),"Original part changed externally; preserve: "..rec.Name)
 assert(sameCF(v.CFrame,rec:GetAttribute("OriginalCFrame"))or sameCF(v.CFrame,rec:GetAttribute("PreviewCFrame")),"Original transform changed externally; preserve: "..rec.Name)
 return v
end

function V.Show(p,c,r,state)
 assert(not game:GetService("RunService"):IsRunning()and game.PlaceId==125334614375606,"Sell Cars Tycoon / Edit only")
 local actual=c:FindFirstChild("06_Actual_Sales_Vehicles")
 if not actual then return {skipped=true,reason="F04_4_NOT_BUILT"}end
 assert(actual:IsA("Model")and #actual:GetChildren()==0,"Expected empty F04 actual-car container")
 assert(p:GetAttribute("PreviewActive")and c.Parent==workspace and state.Parent==p,"Installer preview state mismatch")
 assert(state:GetAttribute("PreviewOnly")==true and not state:FindFirstChild("F04_VehicleSwap"),"Recovery already used or not a preview")
 local copies=assert(c:FindFirstChild("90_Scale_Car_Previews"),"Scale-copy container missing")
 assert(#copies:GetChildren()==6,"Expected exactly six scale-copy cars")
 for _,copy in copies:GetChildren()do assert(copy:IsA("Model")and copy:GetAttribute("Frontage04CarPreview")==true,"Unknown scale-copy content; preserve")end
 local sales=at(r,"09_Institution_Production_B/01_Frontage_Commercial/02_Sales_Delivery")
 local sockets=at(r,"04_Capacity_Sockets");local lookup=visualLookup(state)
 local swap=folder(nil,"F04_VehicleSwap");swap:SetAttribute("Version",V.Version)
 swap:SetAttribute("Status","CAPTURING");swap:SetAttribute("EditOnly",true)
 reference(swap,"RootReference",r);reference(swap,"CandidateReference",c)
 reference(swap,"ActualFolderReference",actual);reference(swap,"ScaleCopiesReference",copies)
 reference(swap,"ScaleCopiesOriginalParent",c)
 local carsFolder=folder(swap,"Cars");local socketFolder=folder(swap,"Sockets")
 local clones=folder(swap,"FullCarClones");folder(swap,"ScaleCopyArchive")
 -- Complete every reference, clone and target pose before moving even one object.
 local ok,err=pcall(function()
  local seen={}
  for i,row in schedule do
   local car=at(sales,row[1]);assert(car:IsA("Model")and not seen[car],"Missing/duplicate retained car")
   seen[car]=true
   local rec=captureObject(carsFolder,string.format("Car_%02d",i),car)
   rec:SetAttribute("SemanticSocket",row[2]);rec:SetAttribute("OriginalPath",car:GetFullName())
   local pivot=car:GetPivot();local cf,size=car:GetBoundingBox()
   local bottom=cf.Y-size.Y/2
   local preview=CFrame.new(row[3],.23+pivot.Y-bottom,row[4])*CFrame.Angles(0,math.rad(row[5]),0)
   rec:SetAttribute("OriginalPivot",pivot);rec:SetAttribute("OriginalWorldPivot",car.WorldPivot)
   rec:SetAttribute("PreviewPivot",preview);rec:SetAttribute("OriginalDescendantCount",#car:GetDescendants())
   reference(rec,"OriginalPrimaryPart",car.PrimaryPart)
   local parts=folder(rec,"Parts");local visuals=folder(rec,"Visuals")
   local objects=folder(rec,"NonPartObjects");local delta=preview*pivot:Inverse()
   for j,v in car:GetDescendants()do
    if v:IsA("BasePart")then
     local partRec=captureObject(parts,string.format("Part_%03d",j),v)
     partRec:SetAttribute("OriginalCFrame",v.CFrame);partRec:SetAttribute("PreviewCFrame",delta*v.CFrame)
     partRec:SetAttribute("OriginalSize",v.Size)
    else captureObject(objects,string.format("Object_%03d",j),v)end
    if visualKeys(v)then
     local entry=assert(lookup[v],"Original car visual missing from installer recovery")
     reference(visuals,string.format("Visual_%03d",j),entry)
    end
   end
   assert(#parts:GetChildren()>0,"Retained car has no parts")
   local clone=assert(car:Clone(),"Cannot clone retained car")
   assert(#clone:GetDescendants()==#car:GetDescendants(),"Incomplete retained-car clone")
   originalVisibilityOnClone(car,clone,lookup)
   clone.Name=string.format("Original_Car_%02d",i);clone.Parent=clones
   reference(rec,"FullCarClone",clone)
  end
  local rows={}
  for _,row in schedule do table.insert(rows,{row[2],row[3],row[4],row[5]})end
  table.insert(rows,{"SalesReveal",3098,73,-90});table.insert(rows,{"SalesStaging",3156.5,70,90})
  for _,row in rows do
   local socket=assert(sockets:FindFirstChild(row[1]),"Missing original sales socket "..row[1])
   assert(socket:IsA("BasePart")and socket:GetAttribute("V5CapacitySocket")==true,"Socket identity mismatch")
   local rec=captureObject(socketFolder,row[1],socket)
   rec:SetAttribute("OriginalCFrame",socket.CFrame);rec:SetAttribute("OriginalSize",socket.Size)
   rec:SetAttribute("PreviewCFrame",CFrame.new(row[2],socket.Position.Y,row[3])*CFrame.Angles(0,math.rad(row[4]),0))
  end
 end)
 if not ok then swap:Destroy();error("F04 vehicle preflight failed before moves: "..tostring(err))end
 swap:SetAttribute("Status","PREPARED");swap.Parent=state
 -- Records are now durable. A partial failure must use Restore, never destroy them.
 copies.Parent=swap.ScaleCopyArchive
 for _,rec in carsFolder:GetChildren()do
  rec:SetAttribute("MoveStarted",true)
  local car=rec.Value;car.Parent=actual;car:PivotTo(rec:GetAttribute("PreviewPivot"))
  for _,link in rec.Visuals:GetChildren()do
   local entry=assert(link.Value);restoreVisible(assert(entry.Value),entry)
  end
  rec:SetAttribute("Moved",true)
 end
 for _,rec in socketFolder:GetChildren()do rec.Value.CFrame=rec:GetAttribute("PreviewCFrame")end
 swap:SetAttribute("Status","SHOWN");swap:SetAttribute("Cars",6);swap:SetAttribute("Sockets",8)
 return {cars=6,sockets=8,scaleCopiesHidden=6,identity="SIX_ORIGINAL_MODELS",recovery=swap:GetFullName(),editOnly=true}
end

function V.Restore(p,c,state)
 local swap=state:FindFirstChild("F04_VehicleSwap")
 if not swap then return {skipped=true,reason="NO_VEHICLE_SWAP"}end
 assert(not game:GetService("RunService"):IsRunning(),"Vehicle preview restore requires Edit mode")
 assert(swap:GetAttribute("Version")==V.Version,"Unknown vehicle-recovery version; preserve")
 assert(target(swap,"CandidateReference")==c and state.Parent==p,"Recovery/candidate mismatch")
 if swap:GetAttribute("Status")=="RESTORED"then return {restored=true,alreadyRestored=true}end
 local r=target(swap,"RootReference");local actual=target(swap,"ActualFolderReference")
 local copies=target(swap,"ScaleCopiesReference");local originalCopyParent=target(swap,"ScaleCopiesOriginalParent")
 assert(actual.Parent==c,"Actual-car container moved externally; preserve")
 assert(copies.Parent==originalCopyParent or copies.Parent==swap.ScaleCopyArchive,"Scale-copy container moved externally; preserve")
 local known={}
 -- Verify the entire restoration set before changing any original. Accept old OR
 -- preview CFrames to support an interrupted Show/Restore; reject unrelated edits.
 for _,rec in swap.Cars:GetChildren()do
  local car,oldParent=checkIdentity(rec,actual);known[car]=true
  assert(oldParent:IsDescendantOf(r),"Original car parent left V5; preserve")
  assert(#car:GetDescendants()==rec:GetAttribute("OriginalDescendantCount"),"Retained car content changed externally; preserve")
  assert(car.PrimaryPart==rec.OriginalPrimaryPart.Value,"Retained car PrimaryPart changed externally; preserve")
  for _,partRec in rec.Parts:GetChildren()do checkPart(partRec)end
  for _,objectRec in rec.NonPartObjects:GetChildren()do checkIdentity(objectRec)end
 end
 for _,child in actual:GetChildren()do assert(known[child],"Unknown actual-car container content; preserve")end
 for _,rec in swap.Sockets:GetChildren()do checkPart(rec)end
 swap:SetAttribute("Status","RESTORING")
 for _,rec in swap.Cars:GetChildren()do
  local car=rec.Value
  car:PivotTo(rec:GetAttribute("OriginalPivot"))
  -- Explicit original per-part values prevent repeated PivotTo roundoff drift.
  for _,partRec in rec.Parts:GetChildren()do partRec.Value.CFrame=partRec:GetAttribute("OriginalCFrame")end
  car.WorldPivot=rec:GetAttribute("OriginalWorldPivot")
  car.Parent=target(rec,"OriginalParent")
  rec:SetAttribute("Restored",true)
 end
 for _,rec in swap.Sockets:GetChildren()do rec.Value.CFrame=rec:GetAttribute("OriginalCFrame")end
 copies.Parent=originalCopyParent
 swap:SetAttribute("Status","RESTORED")
 -- Main EndPreview now hides the candidate and restores ExactModifiedProperties.
 -- These records and full clones intentionally remain for evidence and recovery.
 return {restored=true,cars=6,sockets=8,scaleCopiesRestored=6,recovery=swap:GetFullName()}
end
return V

