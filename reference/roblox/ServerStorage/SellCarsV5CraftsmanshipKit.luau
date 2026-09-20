-- CC02–06: fitted, static native-part art proxies. No capacity or gameplay changes.
local K={}
K.V=Vector3.new;K.CF=CFrame.new
K.colors={steel=Color3.fromRGB(153,163,158),black=Color3.fromRGB(29,34,35),cream=Color3.fromRGB(223,214,192),stone=Color3.fromRGB(160,156,142),gold=Color3.fromRGB(170,130,65),oxide=Color3.fromRGB(145,66,40),teal=Color3.fromRGB(62,105,107),wood=Color3.fromRGB(117,79,48)}
function K.part(m,n,f,s,c,mat)
 local p=Instance.new('Part');p.Name=n;p.CFrame=f;p.Size=s;p.Color=K.colors[c]or c;p.Material=mat or Enum.Material.Metal;p.Anchored=true;p.CanCollide=false;p.CanQuery=false;p.CanTouch=false;p.CastShadow=math.min(s.X,s.Y,s.Z)>.12;p.Parent=m;return p
end
function K.rod(m,n,a,b,d,c)local p=K.part(m,n,CFrame.lookAt((a+b)/2,b)*CFrame.Angles(0,math.pi/2,0),Vector3.new((b-a).Magnitude,d,d),c);p.Shape=Enum.PartType.Cylinder;return p end
function K.disc(m,n,f,d,h,c)local p=K.part(m,n,f*CFrame.Angles(0,math.pi/2,0),Vector3.new(h,d,d),c);p.Shape=Enum.PartType.Cylinder;return p end
function K.ring(m,n,f,r,d,c,N)N=N or 12;for i=0,N-1 do local a,b=i*math.pi*2/N,(i+1)*math.pi*2/N;K.rod(m,n,f:PointToWorldSpace(Vector3.new(r*math.cos(a),r*math.sin(a),0)),f:PointToWorldSpace(Vector3.new(r*math.cos(b),r*math.sin(b),0)),d,c)end end
function K.save(rec,p,key,value)local v=Instance.new('ObjectValue');v.Name=string.format('%04d',#rec:GetChildren()+1);v.Value=p;v:SetAttribute('Key',key);v:SetAttribute('HadValue',p:GetAttribute(key)~=nil);v:SetAttribute('Before',p:GetAttribute(key));v.Parent=rec;p:SetAttribute(key,value)end
function K.find(root,name)local p=root:FindFirstChild(name,true);assert(p,'Missing audited support '..name);return p end
function K.retire(rec,p,step)K.save(rec,p,'FJ_Retire',step)end
function K.begin(root,reg,name,version)
 assert(not root:FindFirstChild(name),name..' already installed');local owner=Instance.new('Model');owner.Name=name;owner:SetAttribute('Version',version);owner.Parent=root;local manifest={};local ids=require(game.ReplicatedStorage.SellCarsV5FullJourneyData).Entries
 local function group(step,label,support,fn)
  local m=Instance.new('Model');m.Name=string.format('P%03d_%s',step,label);m:SetAttribute('FirstStep',step);m:SetAttribute('PurchaseId',ids[step].id);m:SetAttribute('AssetStatus','AUTHORED_NATIVE_PROXY');m.Parent=owner;local link=Instance.new('ObjectValue');link.Name='ExistingSupport';link.Value=support;link.Parent=m;fn(m)
  local count=0;for _,p in m:GetDescendants()do if p:IsA('BasePart')then reg(p,{first=step,finish=step,kind='extra'});local path={};local a=p;while a~=root do table.insert(path,1,a.Name);a=a.Parent end;p:SetAttribute('FJ_Path',table.concat(path,'/'));count+=1 end end
  local f,s=m:GetBoundingBox();m.WorldPivot=f;m:SetAttribute('ReplacementPivot',f);m:SetAttribute('ReplacementBounds',s);table.insert(manifest,{name=m.Name,step=step,id=ids[step].id,parts=count,pivot={f:GetComponents()},bounds={s.X,s.Y,s.Z},support=support:GetFullName()});return m
 end
 return group,function()owner:SetAttribute('Manifest',game.HttpService:JSONEncode(manifest));return manifest end
end
function K.frame(m,f,w,h,c)
 for _,x in {-w/2,w/2}do K.part(m,'FoldedPerimeterUpright',f*CFrame.new(x,0,0),Vector3.new(.12,h,.16),c)end
 for _,y in {-h/2,h/2}do K.part(m,'FoldedPerimeterRail',f*CFrame.new(0,y,0),Vector3.new(w,.12,.16),c)end
end
function K.lamp(m,f,length,warm)
 local V=Vector3.new;K.part(m,'ShieldedTaskHousing',f,V(.8,.22,length),'black');local p=K.part(m,'RecessedTaskDiffuser',f*CFrame.new(0,-.13,0),V(.55,.03,length-.3),'cream',Enum.Material.Neon)
 local l=Instance.new('SurfaceLight');l.Face=Enum.NormalId.Bottom;l.Brightness=.45;l.Range=11;l.Angle=95;l.Color=warm and Color3.fromRGB(255,205,148)or Color3.fromRGB(241,242,229);l.Shadows=true;l.Parent=p
end
return K

