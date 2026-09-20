-- Studio-only adapter. Composer owns geometry; this module only selects review points.
local M={Version='PX02'}
local SS=game.ServerStorage
local api=require(SS.SellCarsV5FullJourneyComposer)
local data=require(game.ReplicatedStorage.SellCarsV5FullJourneyData)
local benefits=require(game.ReplicatedStorage.SellCarsV5PurchaseBenefits)
assert(#benefits.entries==#data.Entries,'Regenerate purchase benefits after journey changes')
for i,e in data.Entries do assert(benefits.entries[i].id==e.id,'Benefit ID/order mismatch at '..i)end
local V=Vector3.new
local early={
 {3035,112},{3022,92},{3020,127},{3068,133},{3073,121},{3060,84},
 {3015,111},{3056,110},{3015,154},{3013,135},{3063,153},{3006,130},
 {3042,115},{3042,115},{3001,146},{2993,148},{2993,123},{3020,57},
 {3060,83},{3038,101},{3001,104},{3166,31},{3020,57},{3164,36}
}
M.EarlyPoints=early
local function root()return SS.SellCarsV5FullJourneyPackage.Preview.Value end
local function ground(x,z)
 local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Include;params.FilterDescendantsInstances={root()};params.RespectCanCollide=true
 local hit=workspace:Raycast(V(x,9,z),V(0,-16,0),params)
 if not hit or hit.Position.Y>3 or hit.Position.Y<0 then return nil end
 local overlap=OverlapParams.new();overlap.FilterType=Enum.RaycastFilterType.Include;overlap.FilterDescendantsInstances={root()};overlap.RespectCanCollide=true
 for _,p in workspace:GetPartBoundsInBox(CFrame.new(hit.Position+V(0,3.1,0)),V(4,5,4),overlap)do
  if p.CanCollide and p.Transparency<1 then return nil end
 end
 return hit.Position
end
local function futureClear(point,parts)
 for _,p in parts do
  local size=p:GetAttribute('FJ_Size')or p.Size;local cf=p:GetAttribute('FJ_CF')or p.CFrame
  local half=cf.RightVector:Abs()*size.X/2+cf.UpVector:Abs()*size.Y/2+cf.LookVector:Abs()*size.Z/2
  if size.Y>1 and half.X<55 and half.Z<55 and cf.Y-half.Y<point.Y+6 and cf.Y+half.Y>point.Y+.5 then
   if math.abs(point.X-cf.X)<half.X+2.2 and math.abs(point.Z-cf.Z)<half.Z+2.2 then return false end
  end
 end;return true
end
function M.Target(n)
 assert(n>=1 and n<=240 and n%1==0,'Invalid walk step')
 local _,look,_,review=api.Camera(n,n-1)
 if n==1 then look=V(3041,4,132)elseif n==6 then look=V(3073,4,82)end
 local x,z
 if early[n]then x,z=table.unpack(early[n])else
  -- Ground-side viewing edge derived from actual changed components, never a car socket.
  local total=V(0,0,0);local count=0
  for _,p in review.parts or{}do local cf=p:GetAttribute('FJ_CF')or p.CFrame;local s=p:GetAttribute('FJ_Size')or p.Size
   if s.X<100 and s.Z<100 then total+=cf.Position;count+=1 end
  end
  local center=count>0 and total/count or look
  x=center.X<3071 and 3070 or(center.X>3139 and 3140 or 3105)
  z=math.clamp(center.Z,38,465)
 end
 local point
 for _,o in {{0,0},{0,-5},{0,5},{-5,0},{5,0},{0,-10},{0,10},{-10,0},{10,0},{-7,-7},{7,-7},{-7,7},{7,7},{0,-18},{0,18}}do
  local candidate=ground(x+o[1],z+o[2])
  if candidate and futureClear(candidate,review.parts or{})then point=candidate;break end
 end
 assert(point,'No supported clear review point for '..n..'; use the slider for this step')
 return {step=n,id=data.Entries[n].id,title=data.Entries[n].title,point=point,look=look,parts=review.parts,benefit=benefits.entries[n],scope='VISUAL PREVIEW / NO PURCHASE'}
end
function M.State(n)
 return {step=n,next=n<240 and M.Target(n+1)or nil,completed=n>0 and benefits.entries[n]or nil}
end
function M.Near(player,target)
 local c=player.Character;local h=c and c:FindFirstChildOfClass('Humanoid');local hrp=c and c:FindFirstChild('HumanoidRootPart')
 return h and h.Health>0 and hrp and(hrp.Position-target.point).Magnitude<=13 or false
end
function M.Travel(player,target)
 local c=player.Character;local h=c and c:FindFirstChildOfClass('Humanoid')
 assert(c and h and h.Health>0,'Character is not ready')
 local point=ground(target.point.X,target.point.Z);assert(point,'Review point is no longer clear')
 local toward=V(target.look.X,point.Y+3.5,target.look.Z);local start=point+V(0,3.5,0)
 if(toward-start).Magnitude<1 then toward=start+V(0,0,1)end
 c:PivotTo(CFrame.lookAt(start,toward));local hrp=c:FindFirstChild('HumanoidRootPart');if hrp then hrp.AssemblyLinearVelocity=V(0,0,0);hrp.AssemblyAngularVelocity=V(0,0,0)end
end
return M

