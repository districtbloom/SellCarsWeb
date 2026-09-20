-- Studio-only environment review; no live purchase or economy remote.
if not game.RunService:IsStudio() or game.PlaceId~=125334614375606 then return end
local api=require(game.ServerStorage.SellCarsV5FirstLoopPreview)
local remote=Instance.new('RemoteEvent');remote.Name='SellCarsV5JourneyPreview';remote.Parent=game.ReplicatedStorage
local last={}
local tour=Instance.new('RemoteEvent');tour.Name='SellCarsV5GuidedTour';tour.Parent=game.ReplicatedStorage
local tourData=require(game.ReplicatedStorage.SellCarsV5GuidedTourData)
local pending={}
tour.OnServerEvent:Connect(function(player,action,token,index,side)
 if type(token)~='number'or token%1~=0 or token<0 or token>2147483647 then return end
 local prior=pending[player]
 if prior and token<prior.token then return end
 if action=='CANCEL'then pending[player]={token=token};return end
 if type(index)~='number'or not tourData.Steps[index]then return end
 local step=tourData.Steps[index]
 if action=='PREPARE'then
  pending[player]={token=token,index=index}
  local ok,result=pcall(api.SetTourLevel,step.Before)
  tour:FireClient(player,ok and 'READY'or 'ERROR',token,index,ok and result or tostring(result))
 elseif action=='SHOW'and prior and prior.token==token and prior.index==index and(side=='BEFORE'or side=='AFTER')then
  local ok,result=pcall(api.SetTourLevel,side=='BEFORE'and step.Before or step.After)
  tour:FireClient(player,ok and side or 'ERROR',token,index,ok and result or tostring(result))
 end
end)
local function safeSpawn(player)
 local char=player.Character;local s=workspace:FindFirstChild('SellCars_V5_PlayerSpawn')
 if char and s then char:PivotTo(s.CFrame+Vector3.new(0,4,0));local p=char:FindFirstChild('HumanoidRootPart');if p then p.AssemblyLinearVelocity=Vector3.zero;p.AssemblyAngularVelocity=Vector3.zero end end
end
remote.OnServerEvent:Connect(function(player,action,value)
 if action=='STATUS' then remote:FireClient(player,true,api.Status());return end
 if action~='STEP' and action~='CAR' then return end
 for p,v in pending do tour:FireClient(p,'CANCELLED',v.token);pending[p]=nil end
 if last[player] and os.clock()-last[player]<.12 then remote:FireClient(player,false,'Please release the slider before the next change',api.Status());return end
 last[player]=os.clock()
 local ok,result=pcall(function()if action=='STEP' then return api.SetStep(value)else return api.PlaceCar(value)end end)
 if ok then
  if action=='STEP' then for _,p in game.Players:GetPlayers()do safeSpawn(p)end end
  remote:FireAllClients(true,result)
 else remote:FireClient(player,false,tostring(result),api.Status())end
end)
game.Players.PlayerRemoving:Connect(function(p)last[p]=nil;pending[p]=nil end)

