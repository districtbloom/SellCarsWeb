-- HC: existing counters, held-object reach and restrained working history.
local M={Version='2026-09-09.HC03',RootName='HC_HumanScaleCraft'}
local V,CF=Vector3.new,CFrame.new
local function save(rec,p,k,v)
 local q=Instance.new('ObjectValue');q.Name=string.format('%04d',#rec:GetChildren()+1);q.Value=p;q:SetAttribute('Key',k);q:SetAttribute('HadValue',p:GetAttribute(k)~=nil);q:SetAttribute('Before',p:GetAttribute(k));q.Parent=rec;p:SetAttribute(k,v)
end
local function setpart(rec,p,f,s)
 assert((p:GetAttribute('FJ_MoveAt')or 999)>240,'Moving support needs a separate migration')
 assert(not p:GetAttribute('PB_CF'),'Staged position requires explicit migration')
 save(rec,p,'FJ_CF',f);p.CFrame=f
 if s then save(rec,p,'FJ_Size',s);p.Size=s end
end
local function path(root,p)local a={}while p~=root do table.insert(a,1,p.Name);p=p.Parent end;return table.concat(a,'/')end
local function aim(j,rest,target)
 local mount=j.Part0.CFrame*j.C0;local part=mount*rest*j.C1:Inverse()
 local a=(part:PointToWorldSpace(V(0,-1,0))-mount.Position).Unit
 local b=(target-mount.Position).Unit;local axis=a:Cross(b);local rot=CF()
 if axis.Magnitude>.00001 then rot=CFrame.fromAxisAngle(axis.Unit,math.acos(math.clamp(a:Dot(b),-1,1)))end
 local desired=CF(mount.Position)*rot*CF(-mount.Position)*part
 return mount:Inverse()*desired*j.C1
end
function M.Build(root,reg,ids,rec)
 assert(not root:FindFirstChild(M.RootName),'HC already exists')
 local owner=Instance.new('Model');owner.Name=M.RootName;owner:SetAttribute('Version',M.Version);owner.Parent=root
 local counts={benches=0,movedParts=0,dependentGroups=0,actors=0,wearParts=0}
 local specs={{'Tool_Bench_And_Vice','Mechanical'},{'Mix_Bank_And_Rare_Finishes','Paint'},{'Film_Cutting_And_Glass','Film'}}
 for _,spec in specs do
  local m=assert(root:FindFirstChild(spec[1],true));local top=assert(m:FindFirstChild('SteelWorktop'));local old=top:GetAttribute('FJ_CF');local oldSize=top:GetAttribute('FJ_Size');local drop=V(0,1.2,0)
  local dependencies={}
  for _,o in root:GetDescendants()do if o:IsA('ObjectValue')and o.Name=='ExistingSupport'and o.Value and o.Value:IsDescendantOf(m)then dependencies[o.Parent]=true end end
  for _,p in m:GetDescendants()do if p:IsA('BasePart')then
   local f=p:GetAttribute('FJ_CF');local s=p:GetAttribute('FJ_Size')
   if p.Name=='BenchLeg'then setpart(rec,p,f-drop/2,V(s.X,s.Y-1.2,s.Z));counts.movedParts+=1
   elseif p.Name=='Drawer'or p.Name=='Pull'then
    local ratio=.6;local y=2.9+(f.Y-2.9)*ratio
    setpart(rec,p,f+V(0,y-f.Y,0),p.Name=='Drawer'and V(s.X,s.Y*ratio,s.Z)or nil);counts.movedParts+=1
   elseif p.Name~='LowerShelf'and p.Name~='BenchOperator'and p.Name~='ShieldedTaskLight'then
    setpart(rec,p,f-drop);counts.movedParts+=1
   end
  end end
  for g in dependencies do
   local support=g.ExistingSupport.Value
   -- These five dependent kits are fitted to the moved tabletop, not the wall light.
   assert(support==top,'Unreviewed dependent support '..support.Name)
   for _,p in g:GetDescendants()do if p:IsA('BasePart')then setpart(rec,p,p:GetAttribute('FJ_CF')-drop);counts.movedParts+=1 end end
   if g:GetAttribute('ReplacementPivot')then save(rec,g,'ReplacementPivot',g:GetAttribute('ReplacementPivot')-drop)end
   counts.dependentGroups+=1
  end
  counts.benches+=1
  local g=Instance.new('Model');g.Name=spec[2]..'_Working_Surface_History';g.Parent=owner
  local support=Instance.new('ObjectValue');support.Name='ExistingSupport';support.Value=top;support.Parent=g
  local first=top:GetAttribute('FJ_First');local n=math.max(first,top:GetAttribute('FJ_Mid')or first)
  g:SetAttribute('FirstStep',n);g:SetAttribute('SupportPath',path(root,top));g:SetAttribute('AssetStatus','NATIVE_SURFACE_HISTORY_PROXY')
  local function detail(name,x,z,w,d,col,angle)
   local p=Instance.new('Part');p.Name=name;p.Size=V(w,.014,d);p.CFrame=top.CFrame*CF(x,oldSize.Y/2+.012,z)*CFrame.Angles(0,angle or 0,0);p.Color=Color3.fromRGB(table.unpack(col));p.Material=Enum.Material.SmoothPlastic;p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.CastShadow=false;p.Parent=g
   reg(p,{first=n,finish=n,kind='extra',retire=top:GetAttribute('FJ_Retire')or 999});p:SetAttribute('FJ_Path',path(root,p));counts.wearParts+=1
  end
  -- Broken, thin edge rubs: keep most of each counter clear and cleanable.
  for i=1,7 do detail('PolishedEdgeRub',oldSize.X/2-.12,-oldSize.Z*.35+i*oldSize.Z*.075,.045,.2+(i%3)*.16,{150,151,140},.03*(i%2))end
  if spec[2]=='Mechanical'then
   for i=1,6 do detail('ViceWorkScuff',.5+i*.16,3.2+(i%3)*.2,.025,.35,{74,78,74},.3+i*.19)end
   for i=1,3 do detail('LocalOilWitness',-.7+i*.12,1.7+i*.18,.12,.16,{62,65,56},i*.6)end
  elseif spec[2]=='Paint'then
   for i=1,8 do detail('MixingPigmentTrace',-.8+(i%3)*.13,-3+i*.09,.055,.09,({{105,129,123},{147,100,76},{190,170,112}})[i%3+1],i*.7)end
  else
   detail('ReplaceableCuttingPatch',0,0,3.8,3.5,{69,89,78})
   for i=1,7 do detail('BladeScore',-.9+i*.27,-.25,.015,2.5,{115,131,112},.05)end
  end
  local f,s=g:GetBoundingBox();g.WorldPivot=f;g:SetAttribute('ReplacementPivot',f);g:SetAttribute('ReplacementBounds',s)
 end
 local cast=root.EL_EverydayLife.R6_Cast
 -- Keep positions, gates and bodies; only orient the adviser to the existing buyer.
 local advisor=cast.SalesAdvisor;local torso=advisor.Torso;local f=torso:GetAttribute('FJ_CF');local buyer=cast.Buyer.Torso.Position
 local turn=CFrame.lookAt(f.Position,V(buyer.X,f.Y,buyer.Z))*f:Inverse()
 for _,p in advisor:GetDescendants()do if p:IsA('BasePart')then setpart(rec,p,turn*p:GetAttribute('FJ_CF'))end end
 for _,m in cast:GetChildren()do
  local kind=m:GetAttribute('OC_Activity')
  if kind=='CONTROL'or kind=='SWATCH'then
   local left=m.Torso:FindFirstChild('Left Shoulder');assert(left)
   local rest=left:GetAttribute('EL_RestTransform')or CF()
   local nextRest=aim(left,rest,m.Torso.CFrame:PointToWorldSpace(V(0,0,-.9)))
   save(rec,left,'EL_RestTransform',nextRest);save(rec,m,'HC_Contact',true)
   local oldArm=left.Part1.CFrame;local newArm=left.Part0.CFrame*left.C0*nextRest*left.C1:Inverse();local delta=newArm*oldArm:Inverse()
   local affected={[left.Part1]=true}
   for _,j in m:GetDescendants()do if j:IsA('Weld')and j.Part0==left.Part1 then affected[j.Part1]=true end end
   for p in affected do setpart(rec,p,delta*p:GetAttribute('FJ_CF'))end
   left.Transform=nextRest;counts.actors+=1
  end
 end
 owner:SetAttribute('Counts',game.HttpService:JSONEncode(counts));return counts
end
return M

