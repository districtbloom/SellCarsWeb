if not game:GetService('RunService'):IsStudio()or game.PlaceId~=125334614375606 then return end
local api=require(game.ServerStorage.SellCarsV5FullJourneyComposer)
local data=require(game.ReplicatedStorage.SellCarsV5FullJourneyData)
local walk=require(game.ServerStorage.SellCarsV5WalkJourney)
local milestones={};for _,m in data.Milestones or{}do milestones[m.last]=m end
local remote=Instance.new('RemoteEvent');remote.Name='SellCarsV5FullJourneyRemote';remote.Parent=game.ReplicatedStorage
local pending={}
remote.OnServerEvent:Connect(function(player,action,token,index,side)
 if type(token)~='number'or token%1~=0 or token<0 or token>2147483647 then return end
 local old=pending[player];if old and old.token>token then return end
 if action=='CANCEL'then pending[player]={token=token};return end
 if action=='BENCHMARK'then pending[player]={token=token};local ok,r=pcall(api.Benchmark);remote:FireClient(player,ok and'BENCHMARK'or'ERROR',token,index,r);return end
 if type(index)~='number'or index%1~=0 or index<0 or index>240 then return end
 if action=='WALK_START'then
  pending[player]={token=token,walking=true,index=index};local ok,r=pcall(function()
   api.SetStep(index);local state=walk.State(index);pending[player].target=state.next
   if side=='BEGIN'and state.next then walk.Travel(player,state.next);state.travelled=true end;return state
  end)
  remote:FireClient(player,ok and'WALK_READY'or'ERROR',token,index,r);return
 elseif action=='WALK_TRAVEL'and old and old.walking and old.token==token and not old.busy then
  local ok,r=pcall(function()assert(old.target,'Journey complete');walk.Travel(player,old.target);local state=walk.State(old.index);state.travelled=true;return state end)
  remote:FireClient(player,ok and'WALK_READY'or'ERROR',token,old.index,r);return
 elseif action=='WALK_ADVANCE'and old and old.walking and old.token==token and old.target and not old.busy then
  if index~=old.index+1 or not walk.Near(player,old.target)then remote:FireClient(player,'WALK_HINT',token,old.index,'Walk closer to the next marker.');return end
  old.busy=true;remote:FireClient(player,'WALK_HOLD',token,old.index,{step=old.index,seconds=1.6})
  task.delay(1.6,function()
   if pending[player]~=old or not player.Parent then return end
   old.busy=false
   if not walk.Near(player,old.target)then remote:FireClient(player,'WALK_READY',token,old.index,walk.State(old.index));return end
   local completedTarget=old.target
   local ok,r=pcall(function()api.SetStep(index);old.index=index;local state=walk.State(index);old.target=state.next;state.changedParts=completedTarget.parts;return state end)
   remote:FireClient(player,ok and'WALK_AFTER'or'ERROR',token,old.index,r)
  end);return
 end
 if action=='PREPARE'then
  local milestone=side=='MILESTONE'and milestones[index]or nil
  local before=milestone and milestone.first-1 or math.max(0,index-1)
  pending[player]={token=token,index=index,before=before};local ok,r=pcall(api.SetStep,before)
  if ok then local camera,look,targets,review;if side=='CHAPTER'then camera,look,targets,review=api.ChapterCamera(index)else camera,look,targets,review=api.Camera(index,before)end;if milestone then review.benefit=milestone.summary end;r.camera=camera;r.look=look;r.targets=targets;r.review=review;r.beforeStep=before end
  remote:FireClient(player,ok and'READY'or'ERROR',token,index,r)
 elseif action=='SHOW'and old and old.token==token and old.index==index and(side=='BEFORE'or side=='AFTER')then
  local ok,r=pcall(api.SetStep,side=='BEFORE'and(old.before or math.max(0,index-1))or index);remote:FireClient(player,ok and side or'ERROR',token,index,r)
 end
end)
game.Players.PlayerRemoving:Connect(function(p)pending[p]=nil end)

