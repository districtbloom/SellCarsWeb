local S={}
local Http=game:GetService('HttpService')
local store=game:GetService('DataStoreService'):GetDataStore('SellCarsIntegrationJourney_v1')
local session=game.JobId~='' and game.JobId or Http:GenerateGUID(false)
local enabled={}
local writes={}
local memory={}
function S.Load(player)
 local value
 local ok,err=pcall(function()
  value=store:UpdateAsync('Player_'..player.UserId,function(old)
   old=old or {}
   if old.session and old.session~=session and (old.lease or 0)>os.time()then return nil end
   old.session=session;old.lease=os.time()+120;return old
  end)
  assert(value and value.session==session,'Profile locked by another session')
 end)
 enabled[player]=ok
 player:SetAttribute('IntegrationSaveStatus',ok and 'Connected' or 'Session only: storage unavailable')
 if not ok then warn('Integration save unavailable: '..tostring(err));return memory[player.UserId] end
 return value.data
end
function S.Write(player,state,release)
 local snapshot=Http:JSONDecode(Http:JSONEncode(state))
 snapshot.automationDemoRunning=false;snapshot.driving=false;snapshot.routineRunning=false
 memory[player.UserId]=snapshot
 if not enabled[player]then return end
 writes[player]={data=snapshot,release=release}
end
local function flush(player)
 local pending=writes[player];if not pending then return end
 writes[player]=nil
 local ok,err=pcall(function()
  store:UpdateAsync('Player_'..player.UserId,function(old)
   assert(old and old.session==session,'Profile ownership changed')
   return {data=pending.data,session=not pending.release and session or nil,lease=not pending.release and os.time()+120 or 0}
  end)
 end)
 if not ok then player:SetAttribute('IntegrationSaveStatus','Save failed; retrying');writes[player]=writes[player]or pending;warn(tostring(err))
 else player:SetAttribute('IntegrationSaveStatus','Saved')end
end
function S.Release(player,state)S.Write(player,state,true);flush(player);enabled[player]=nil end
function S.Flush(player)flush(player)end
task.spawn(function()while true do task.wait(5);for player in writes do flush(player)end end end)
game:BindToClose(function()for player in writes do flush(player)end end)
return S

