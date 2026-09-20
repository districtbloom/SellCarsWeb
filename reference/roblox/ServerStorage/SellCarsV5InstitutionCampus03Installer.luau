--!nocheck
-- Direct user-approved art pass. No regeneration of accepted scene; no runtime scripts.
local I={Version="2026-09-08.campus03.2"}
local function root()
 assert(game.PlaceId==125334614375606 and not game.RunService:IsRunning(),"Sell Cars Tycoon / Edit required")
 return assert(workspace:FindFirstChild("SellCars_Dealership_Growth_V5"))
end
local names={Promenade="01_Desert_Promenade",Operations="02_Operations_Courtyard",Parts="03_Parts_Work_Yard"}
local function parent()
 local p=root()["10_Institution_Fidelity_R1"]:FindFirstChild("09_Campus03")
 if not p then p=Instance.new("Model");p.Name="09_Campus03";p:SetAttribute("SourceOwned",true);p:SetAttribute("Version",I.Version);p.Parent=root()["10_Institution_Fidelity_R1"]end
 return p
end
local function source(name)return assert(game.ServerStorage:FindFirstChild("SellCarsV5"..name),name)end
function I.Install(batch)
 assert(names[batch],"Unknown batch")
 local p=parent();assert(not p:FindFirstChild(names[batch]),"Existing layer preserved; detach explicitly before replacing")
 local m=Instance.new("Model");m.Name=names[batch];m:SetAttribute("Version",I.Version);m:SetAttribute("Status","BUILT_AWAITING_VISUAL");m.Parent=p
 local ok,err=pcall(function() require(source("Campus03"..batch))(require(source("Campus03Kit")),m)end)
 if not ok then m:Destroy();error(err)end
 return I.Inventory(batch)
end
function I.Inventory(batch)
 local p=parent();local m=batch and assert(p:FindFirstChild(names[batch])) or p
 local out={name=m.Name,parts=0,models=0,seats=0,lights=0,descendants=#m:GetDescendants()}
 for _,v in m:GetDescendants()do if v:IsA("BasePart")then out.parts+=1;if v:IsA("Seat")then out.seats+=1 end elseif v:IsA("Model")then out.models+=1 elseif v:IsA("Light")then out.lights+=1 end end
 return out
end
function I.Detach(batch)
 local p=parent();local m=assert(p:FindFirstChild(names[batch]));assert(m:GetAttribute("Version")==I.Version,"Unknown layer; preserve")
 local archive=game.ServerStorage:FindFirstChild("SellCarsV5Campus03Detached")
 if not archive then archive=Instance.new("Folder");archive.Name="SellCarsV5Campus03Detached";archive.Parent=game.ServerStorage end
 assert(not archive:FindFirstChild(m.Name),"Existing detached model; preserve")
 m.Parent=archive;return m:GetFullName()
end
function I.Reattach(batch)
 local a=assert(game.ServerStorage:FindFirstChild("SellCarsV5Campus03Detached"));local m=assert(a:FindFirstChild(names[batch]));assert(not parent():FindFirstChild(m.Name));m.Parent=parent();return I.Inventory(batch)
end
function I.Accept(batch)
 local m=assert(parent():FindFirstChild(names[batch]));m:SetAttribute("Status","SHIPPED_VISUAL_PROXY");m:SetAttribute("ExtendedTestsRun",false);return I.Inventory(batch)
end
return I

