if game.PlaceId~=105869926920733 then return end
local RS=game:GetService('ReplicatedStorage');local Players=game:GetService('Players');local Run=game:GetService('RunService')
local D=require(RS.HubSlice.HubData);local M=require(RS.HubSlice.HubModel);local W=require(RS.HubSlice.HubWorld).new()
local remote=Instance.new('RemoteEvent');remote.Name='HubEvent';remote.Parent=RS.HubSlice
local s=M.fresh();local owner;local throttle=0;local throttleAt=0;local budget={};local uiCounter=0;local frozen=false
local function near(player,pos,range)local r=player.Character and player.Character:FindFirstChild('HumanoidRootPart');return r and(r.Position-D.world(pos)).Magnitude<(range or 20)end
local function send()if owner then owner:SetAttribute('SellCarsCash',s.cash);remote:FireAllClients('State',s,owner.UserId);workspace:SetAttribute('HubStage',s.car and s.car.status or 'pads');workspace:SetAttribute('HubSales',s.sales)end end
local function sync()W:sync(s);send()end
local function join(p)if not owner then owner=p end;p.CharacterAdded:Connect(function(char)char:WaitForChild('HumanoidRootPart');char:PivotTo(CFrame.new(3035,6,124));send()end);if p.Character then p.Character:PivotTo(CFrame.new(3035,6,124))end;send()end
Players.PlayerAdded:Connect(join);for _,p in Players:GetPlayers()do join(p)end
Players.PlayerRemoving:Connect(function(p)budget[p]=nil;if p==owner then owner=nil;throttle=0;for _,nextPlayer in Players:GetPlayers()do if nextPlayer~=p then owner=nextPlayer;break end end end end)
local purchase
remote.OnServerEvent:Connect(function(player,action,data)
 if action=='Ready'then send();return end
 if player~=owner or type(action)~='string'then return end
 local now=os.clock();local rate=budget[player]or{at=now,n=0};if now-rate.at>1 then rate={at=now,n=0}end;rate.n+=1;budget[player]=rate;if rate.n>30 then return end
 local c=s.car
 if action=='Counter'or action=='Accept'then
  if not c or not c.quote or type(data)~='table'or data.carId~=c.id or data.revision~=(c.quote.revision or 0)or(action=='Accept'and data.amount~=c.quote.accepted)then
   M.note(s,'The offer changed. Check the current price.');sync();remote:FireClient(player,'Ack');return
  end
 end
 if action=='Drive'then throttle=data==true and 1 or 0;throttleAt=now;return end
 if action=='Discover'then if c and c.status=='discovery'then M.discover(s)end
 elseif action=='Pad'then for _,p in D.pads do if p.id==data and near(player,p.pos,12)then purchase(p.id)end end
 elseif action=='Deal'then if W.actorPos and near(player,W.actorPos,24)and M.openDeal(s)then remote:FireClient(player,'Open','deal')end
 elseif action=='Counter'then if c and W.actorPos and near(player,W.actorPos,26)then M.counter(s,data.amount)end
 elseif action=='Accept'then if c and c.quote and W.actorPos and near(player,W.actorPos,26)then
  local buying=c.quote.mode=='buy';local amount=c.quote.accepted;local b=not buying and M.buyer(s);local ok=buying and M.buy(s)or not buying and M.sell(s)
  if ok then remote:FireClient(player,'Result',{title=buying and'It’s yours'or'Deal done',buying=buying,carId=c.id,car=M.def(s).name,person=buying and M.def(s).seller or b.name,role=buying and'Seller'or b.role,purchase=c.purchase,work=c.workSpent,fit=b and b.cue,amount=amount,profit=not buying and amount-c.purchase-c.workSpent or nil,line=buying and(c.remote and'Elias brings it back. Drive home.'or(c.index==1 and'Build your workshop. Repairs cost $500.'or'Next: choose how to prepare it.'))or'Thanks. I’ll take good care of it.'});if s.personal and s.personal.route then W:sync(s);W:mount(player);throttle=0 end end
 end
 elseif action=='Decline'then if W.actorPos and near(player,W.actorPos,26)then M.decline(s)end
 elseif action=='Plan'then if c and near(player,c.pos,25)then if M.plan(s,data)then remote:FireClient(player,'Done',action)end else M.note(s,'Come closer to your car.')end
 elseif action=='Repair'then if c and near(player,c.pos,22)then M.startJob(s)end
 elseif action=='Photo'then if M.list(s)then remote:FireClient(player,'Done',action)end
 elseif action=='Custom'then if c and near(player,c.pos,30)then if M.customize(s,data)then remote:FireClient(player,'Done',action)else M.note(s,'Not enough cash for this look.')end else M.note(s,'Come closer to your car.')end
 elseif action=='Train'then if not M.upgrade(s)then M.note(s,'Finish a job and keep $350 spare to train Jo.')end
 elseif action=='Invite'then if s.lead and M.arrive(s,s.lead.index)then remote:FireClient(player,'Done',action)end
 elseif action=='Recovery'then if not c and s.sales>=3 and s.lead and s.lead.kind=='rare'and s.cash<6000 then if M.arrive(s,3)then remote:FireClient(player,'Done',action)end end
 elseif action=='Visit'then if M.visit(s)then remote:FireClient(player,'Done',action);W:sync(s);W:mount(player);throttle=0;throttleAt=now end
 elseif action=='Leave'then if M.leave(s)then W:sync(s);W:mount(player);throttle=0;throttleAt=now end
 end
 sync();if action=='Counter'or action=='Accept'then remote:FireClient(player,'Ack')end
end)
-- Real pad contact and server proximity validation; no client-authoritative purchases.
local padContact={}
purchase=function(id)
 if padContact[id]then return end;padContact[id]=true;M.buyPad(s,id);sync()
end
for id,pad in W.pads do pad.Touched:Connect(function(hit)if owner and owner.Character and hit:IsDescendantOf(owner.Character)and pad:GetAttribute('Available')then purchase(id)end end)end
Run.Heartbeat:Connect(function(dt)
 dt=math.min(dt,.1);if not owner or frozen then return end
 local r=owner.Character and owner.Character:FindFirstChild('HumanoidRootPart');if r then for id in padContact do local pad=W.pads[id];if pad and(Vector2.new(r.Position.X-pad.Position.X,r.Position.Z-pad.Position.Z)).Magnitude>7 then padContact[id]=nil end end end
 local driving=s.personal and s.personal.route~=nil
 if os.clock()-throttleAt>1.5 then throttle=0 end
 if not(s.car and s.car.status=='discovery')then M.tick(s,dt,throttle)end
 if driving and s.personal and not s.personal.route then W:dismount(owner,s);throttle=0 end
 W:sync(s);uiCounter+=dt;if uiCounter>=.12 then uiCounter=0;send()end
end)
-- Server-only Studio review entry; never exposed as a client remote.
if Run:IsStudio()then
 local review={state=function()return s end,world=W,model=M,set=function(state)s=state;throttle=0;W.lastPads=-1;sync();return s end,sync=sync,freeze=function(v)frozen=v end}
 local tool=Instance.new('BindableFunction');tool.Name='HubReview';tool.Parent=game.ServerStorage;tool.OnInvoke=function(action,value)if action=='State'then return M.copy(s)elseif action=='Set'then return review.set(value)elseif action=='Freeze'then frozen=value;return true end end
end
sync()

