-- Uses Roblox Studio's bundled R6 mannequin, not external avatar/animation assets.
local M={Version='2026-09-09.EL_R6'}
local V,CF=Vector3.new,CFrame.new
local function save(rec,o,k,v)local r=Instance.new('ObjectValue');r.Name=string.format('%04d',#rec:GetChildren()+1);r.Value=o;r:SetAttribute('Key',k);r:SetAttribute('HadValue',o:GetAttribute(k)~=nil);r:SetAttribute('Before',o:GetAttribute(k));r.Parent=rec;o:SetAttribute(k,v)end
local function stamp(p,old,root)
 for _,k in {'FJ_First','FJ_Finish','FJ_Mid','FJ_Retire','FJ_MoveAt','FJ_Move'}do p:SetAttribute(k,old:GetAttribute(k))end
 for k,v in {FJ_Kind='extra',FJ_CF=p.CFrame,FJ_Size=p.Size,FJ_Color=p.Color,FJ_Material=p.Material.Name,FJ_Transparency=p.Transparency,FJ_Collide=false,FJ_Query=false,FJ_Touch=false}do p:SetAttribute(k,v)end
 local names={};local q=p;while q~=root do table.insert(names,1,q.Name);q=q.Parent end;p:SetAttribute('FJ_Path',table.concat(names,'/'))
end
local function forward(m)
 local joints={};for _,o in m:GetDescendants()do if o:IsA('Motor6D')or o:IsA('Weld')then table.insert(joints,o)end end
 for _=1,4 do for _,j in joints do if j.Part0 and j.Part1 then j.Part1.CFrame=j.Part0.CFrame*j.C0*(j:IsA('Motor6D')and(j:GetAttribute('EL_RestTransform')or CF())or CF())*j.C1:Inverse()end end end
end
function M.Build(root,rec,template)
 assert(game.RunService:IsStudio()and not game.RunService:IsRunning(),'Edit only');assert(not root.EL_EverydayLife:FindFirstChild('R6_Cast'),'R6 cast exists')
 template=template or game:GetObjects('rbxasset://models/Thumbnails/Mannequins/R6.rbxm')[1]
 local cast=Instance.new('Model');cast.Name='R6_Cast';cast:SetAttribute('Version',M.Version);cast.Parent=root.EL_EverydayLife
 local originals={};for _,m in root:GetDescendants()do if m:IsA('Model')and m:GetAttribute('EL_Activity')and m:FindFirstChild('Torso')and m:FindFirstChild('HandR')then table.insert(originals,m)end end
 table.sort(originals,function(a,b)return a.Name<b.Name end);local out={}
 for _,old in originals do
  local oldTorso=old.Torso;local torso=oldTorso:GetAttribute('FJ_CF');local foot=torso*CF(0,-3.3,0)
  local rig=template:Clone();rig.Name=old.Name
  for _,o in rig:GetDescendants()do if o:IsA('BasePart')then o.Anchored=true elseif o:IsA('JointInstance')then o.Enabled=false end end
  rig.Parent=cast;rig.PrimaryPart=rig.HumanoidRootPart
  for _,o in rig:GetDescendants()do if o:IsA('BaseScript')or o:IsA('Decal')or o:IsA('BodyColors')then o:Destroy()end end
  local h=rig:FindFirstChildOfClass('Humanoid')or Instance.new('Humanoid',rig);h.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None;h.AutoRotate=false;h.PlatformStand=true;h.EvaluateStateMachine=false;h.BreakJointsOnDeath=false;h.RequiresNeck=false
  if not h:FindFirstChildOfClass('Animator')then Instance.new('Animator',h)end
  rig.HumanoidRootPart.CFrame=foot*CF(0,3,0)
  rig:SetAttribute('EL_Activity',old:GetAttribute('EL_Activity'));rig:SetAttribute('EL_Offset',old:GetAttribute('EL_Offset'));rig:SetAttribute('EL_R6',true);rig:SetAttribute('FirstStep',oldTorso:GetAttribute('FJ_First'));rig:SetAttribute('SourceActor',old:GetFullName());rig:SetAttribute('PoseOnly',true)
  local skin=old.Head.Color;local shirt=oldTorso.Color;local pants=old:FindFirstChild('Waist')and old.Waist.Color or Color3.fromRGB(45,52,53)
  for _,p in rig:GetChildren()do if p:IsA('BasePart')then p.Color=p.Name=='Head'and skin or p.Name:find('Leg')and pants or shirt;p.Material=p.Name=='Head'and Enum.Material.SmoothPlastic or Enum.Material.Fabric end end
  local holds=old:FindFirstChild('HeldBoard')or old:FindFirstChild('HandheldControl')or old:FindFirstChild('MeasuringRule')or old:FindFirstChild('FinishSwatch1')or old:FindFirstChild('InspectionLightGrip')or old:FindFirstChild('RadioBody')
  for _,j in rig:GetDescendants()do if j:IsA('Motor6D')then
   if j.Name=='Root Hip'then j.Name='RootJoint'end
   local rest=CF();if holds and j.Name=='Left Shoulder'then local desired=CF(j.C0.Position)*CFrame.Angles(-.85,0,-.18)*j.C0.Rotation;rest=j.C0:Inverse()*desired end
   if old.Name=='CrewOnBreak'and j.Name:find('Hip')then local desired=CF(j.C0.Position)*CFrame.Angles(-math.pi/2,0,0)*j.C0.Rotation;rest=j.C0:Inverse()*desired end
   j:SetAttribute('EL_RestTransform',rest);j.Transform=rest
  end end
  forward(rig)
  -- Weld retained headwear, patches and tools to the appropriate standard R6 body part.
  local bodyNames={Torso=true,Waist=true,Belt=true,Neck=true,Head=true,UpperArmL=true,UpperArmR=true,ForearmL=true,ForearmR=true,HandL=true,HandR=true,ThighL=true,ThighR=true,ShinL=true,ShinR=true,BootL=true,BootR=true}
  local count=0
  for _,p in old:GetChildren()do if p:IsA('BasePart')and not bodyNames[p.Name]then
   local n=p.Name;local head=n=='Hair'or n=='Cap'or n=='CapBill'or n=='Mouth'or n:find('Eye')or n:find('Hearing')or n=='SafetySpectacles'
   local chest=n=='ChestPocket'or n=='IdentityPatch'or n=='Buckle'or n=='WaterproofApron'
   local target=head and rig.Head or chest and rig.Torso or n=='FoldedMicrofibre'and rig['Right Arm']or rig['Left Arm']
   local source=head and old.Head or chest and oldTorso or n=='FoldedMicrofibre'and old.HandR or old.HandL
   local localCF=source.CFrame:ToObjectSpace(p.CFrame)
   if head then
    local pos=V(localCF.X,localCF.Y*.8,localCF.Z*.83)
    if n=='Mouth'or n:find('Eye')or n=='SafetySpectacles'then pos=V(pos.X,pos.Y,-.64)end
    if n=='Hair'then pos=V(0,.5,0)end
    localCF=localCF.Rotation+pos
   elseif chest then localCF=localCF.Rotation+V(localCF.X,localCF.Y,-.53)
   else localCF=CF(0,-.85,-.1)*localCF end
   local c=p:Clone();c.Transparency=p:GetAttribute('FJ_Transparency')or 0;for _,q in c:GetChildren()do q:Destroy()end;for k in c:GetAttributes()do c:SetAttribute(k,nil)end;c.CFrame=target.CFrame*localCF;c.Parent=rig
   local weld=Instance.new('Weld');weld.Name='PropAttachment';weld.Enabled=false;weld.Part0=target;weld.Part1=c;weld.C0=localCF;weld.Parent=c;count+=1
  end end
  for _,p in rig:GetDescendants()do if p:IsA('BasePart')then p.Anchored=true;p.CanCollide=false;p.CanQuery=false;p.CanTouch=false;p.Massless=true;if p.Name=='HumanoidRootPart'then p.Transparency=1 end;stamp(p,oldTorso,root)end end
  for _,p in old:GetDescendants()do if p:IsA('BasePart')then save(rec,p,'FJ_Retire',0)end end
  table.insert(out,{name=rig.Name,first=rig:GetAttribute('FirstStep'),parts=7+count,rigType=h.RigType.Name})
 end
 cast:SetAttribute('Manifest',game.HttpService:JSONEncode(out));return out
end
return M

