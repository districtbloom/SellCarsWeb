local Players=game:GetService('Players');local RS=game:GetService('ReplicatedStorage');local Run=game:GetService('RunService');local UIS=game:GetService('UserInputService');local Tween=game:GetService('TweenService')
local player=Players.LocalPlayer;local controls;local controlsLock;task.spawn(function()local mod=player.PlayerScripts:WaitForChild('PlayerModule',15);if mod then controls=require(mod):GetControls()end end);local pkg=RS:WaitForChild('HubSlice');local D=require(pkg.HubData);local M=require(pkg.HubModel);local event=pkg:WaitForChild('HubEvent');local world=workspace:WaitForChild('HubSlice')
local C={ink=Color3.fromRGB(32,48,48),paper=Color3.fromRGB(246,241,225),soft=Color3.fromRGB(222,229,215),green=Color3.fromRGB(144,201,122),teal=Color3.fromRGB(74,135,134),yellow=Color3.fromRGB(234,203,109)}
local function make(class,parent,props)local o=Instance.new(class);for k,v in props do o[k]=v end;o.Parent=parent;return o end
local function round(o,r)make('UICorner',o,{CornerRadius=UDim.new(0,r or 12)})end
local function edge(o)make('UIStroke',o,{Color=C.ink,Thickness=2,ApplyStrokeMode=Enum.ApplyStrokeMode.Border})end
local function money(n)return '$'..tostring(math.floor(n or 0)):reverse():gsub('(%d%d%d)','%1,'):reverse():gsub('^,','')end
local function text(p,name,value,y,h,size)
 return make('TextLabel',p,{Name=name,Text=value,Position=UDim2.new(0,16,0,y),Size=UDim2.new(1,-32,0,h),BackgroundTransparency=1,TextColor3=C.ink,Font=Enum.Font.GothamBold,TextSize=size or 16,TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left})
end
local gui=make('ScreenGui',player:WaitForChild('PlayerGui'),{Name='SellCarsHubUI',ResetOnSpawn=false,DisplayOrder=50,ScreenInsets=Enum.ScreenInsets.CoreUISafeInsets,ZIndexBehavior=Enum.ZIndexBehavior.Sibling})
local base=make('Frame',gui,{Name='SafeFrame',Size=UDim2.fromScale(1,1),BackgroundTransparency=1})
local s;local focus='world';local tab='Home';local counter=false;local draft=0;local depth='Quick';local custom;local customTab='Looks';local orbit=.6;local orbitShown=.6;local walkToken=0;local walking=false;local driving=false;local heldW=false;local lastSent=0;local lastSig='';local seenCinema=false;local cinemaStart=0;local resultUntil=0;local receipt;local lastSale=0;local lastPads=0;local celebrateUntil=0;local ownerId;local routeEnabled=true;local pending=false;local soundOn=true;local lastLead;local ringAt=0;local lastJobs=0;local receiptCamera;local pathPoints={};local pathKey;local pathAt=0;local pathBusy=false;local pathFrom
local wallet=make('TextButton',base,{Name='Wallet',AnchorPoint=Vector2.new(.5,0),Position=UDim2.new(.5,0,0,4),Size=UDim2.fromOffset(166,44),Text='$7,000',TextSize=25,Font=Enum.Font.GothamBlack,TextColor3=Color3.new(1,1,1),BackgroundColor3=Color3.fromRGB(64,166,83),BorderSizePixel=0});round(wallet);edge(wallet)
local phone=make('TextButton',base,{Name='Phone',AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,-14,0,4),Size=UDim2.fromOffset(68,44),Text='Phone',TextSize=14,Font=Enum.Font.GothamBold,TextColor3=C.ink,BackgroundColor3=C.paper,BorderSizePixel=0});round(phone);edge(phone)
local guide=make('Frame',base,{Name='Narrator',AnchorPoint=Vector2.new(.5,1),Position=UDim2.new(.5,0,1,-8),Size=UDim2.fromOffset(440,70),BackgroundColor3=C.paper,BorderSizePixel=0});round(guide);edge(guide)
local portrait=make('TextButton',guide,{Name='Guide',Text='',TextSize=20,Font=Enum.Font.GothamBold,Size=UDim2.fromOffset(48,48),Position=UDim2.fromOffset(10,11),BackgroundColor3=C.teal,TextColor3=C.paper,BorderSizePixel=0});round(portrait,8)
local face=make('Frame',portrait,{Name='Head',Position=UDim2.fromOffset(15,12),Size=UDim2.fromOffset(21,24),BackgroundColor3=Color3.fromRGB(199,156,104),BorderSizePixel=0})
make('Frame',portrait,{Name='Body',Position=UDim2.fromOffset(9,34),Size=UDim2.fromOffset(32,14),BackgroundColor3=Color3.fromRGB(39,89,78),BorderSizePixel=0})
make('Frame',portrait,{Name='Hat',Position=UDim2.fromOffset(10,7),Size=UDim2.fromOffset(29,10),BackgroundColor3=Color3.fromRGB(30,63,57),BorderSizePixel=0})
make('Frame',portrait,{Name='Brim',Position=UDim2.fromOffset(6,14),Size=UDim2.fromOffset(37,4),BackgroundColor3=Color3.fromRGB(30,63,57),BorderSizePixel=0})
for _,xy in {{5,8},{14,8},{9,18}}do make('Frame',face,{Position=UDim2.fromOffset(xy[1],xy[2]),Size=UDim2.fromOffset(3,3),BackgroundColor3=C.ink,BorderSizePixel=0})end
local gt=text(guide,'Words','Opening your dealership…',8,52,14);gt.Position=UDim2.fromOffset(68,8);gt.Size=UDim2.new(1,-216,0,52)
local go=make('TextButton',guide,{Name='Next',AnchorPoint=Vector2.new(1,.5),Position=UDim2.new(1,-10,.5,0),Size=UDim2.fromOffset(136,44),Text='Next',TextSize=14,Font=Enum.Font.GothamBold,BackgroundColor3=C.green,TextColor3=C.ink,BorderSizePixel=0});round(go,8)
local panel=make('ScrollingFrame',base,{Name='Panel',AnchorPoint=Vector2.new(1,.5),Position=UDim2.new(1,-14,.5,0),Size=UDim2.fromOffset(338,310),BackgroundColor3=C.paper,BorderSizePixel=0,ScrollBarThickness=3,CanvasSize=UDim2.new(),Visible=false,ScrollingDirection=Enum.ScrollingDirection.Y});round(panel,16);edge(panel)
local panelHeader=make('Frame',base,{Name='PanelHeader',AnchorPoint=Vector2.new(1,0),BackgroundColor3=C.paper,BorderSizePixel=0,Visible=false,ZIndex=6});round(panelHeader,16)
local customFooter=make('Frame',base,{Name='CustomFooter',AnchorPoint=Vector2.new(1,1),Position=UDim2.new(1,-14,1,-5),Size=UDim2.fromOffset(338,56),BackgroundColor3=C.paper,Visible=false,BorderSizePixel=0,ZIndex=5});round(customFooter)
local phoneNav=make('Frame',base,{Name='PhoneNav',AnchorPoint=Vector2.new(1,1),BackgroundColor3=C.paper,BorderSizePixel=0,Visible=false,ZIndex=5});round(phoneNav)
local apply=make('TextButton',customFooter,{Name='Apply',Position=UDim2.fromOffset(12,6),Size=UDim2.new(1,-24,0,44),BackgroundColor3=C.green,Text='Apply',TextSize=16,TextColor3=C.ink,Font=Enum.Font.GothamBold,BorderSizePixel=0});round(apply,9)

local call=make('TextButton',base,{Name='IncomingCall',AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,-14,0,56),Size=UDim2.fromOffset(178,48),Text='Jo is calling',TextSize=15,Font=Enum.Font.GothamBold,TextColor3=C.ink,BackgroundColor3=C.paper,BorderSizePixel=0,Visible=false});round(call);edge(call)
local cinema=make('TextLabel',base,{Name='Reveal',AnchorPoint=Vector2.new(.5,1),Position=UDim2.new(.5,0,1,-30),Size=UDim2.fromOffset(430,86),Text='RARE FIND\n1972 Phoenix GT',TextSize=30,Font=Enum.Font.GothamBlack,TextColor3=C.paper,TextStrokeTransparency=.3,BackgroundTransparency=1,Visible=false})
local skip=make('TextButton',base,{Name='Skip',Position=UDim2.new(1,-84,0,8),Size=UDim2.fromOffset(70,44),Text='Skip',TextSize=15,BackgroundColor3=C.paper,Visible=false});round(skip)
local function cameraBack()workspace.CurrentCamera.CameraType=Enum.CameraType.Custom;local h=player.Character and player.Character:FindFirstChildOfClass('Humanoid');if h then workspace.CurrentCamera.CameraSubject=h end end
local cue=make('Sound',gui,{Name='FeedbackSound',SoundId='rbxasset://sounds/volume_slider.ogg',Volume=.22})
local function ping(pitch)if soundOn then cue.PlaybackSpeed=pitch or 1;cue:Play()end end
local function pulse(o)local scale=o:FindFirstChildOfClass('UIScale')or make('UIScale',o,{Scale=1});scale.Scale=.96;Tween:Create(scale,TweenInfo.new(.16,Enum.EasingStyle.Quad),{Scale=1}):Play()end
local render
local function close()focus='world';custom=nil;panel.Visible=false;if customFooter then customFooter.Visible=false end;counter=false;phoneNav.Visible=false;pending=false;cameraBack()end
local function open(which)walkToken+=1;walking=false;focus=which;panel.CanvasPosition=Vector2.zero;if which=='custom'and s.car then custom=M.copy(s.car.custom or{paint='original',wheels='original',stripe=false});customTab='Looks';orbit=.6 end;render()end
local function fire(a,v)
 if a=='Counter'or a=='Accept'then if pending or not s.car or not s.car.quote then return end;pending=true;v={carId=s.car.id,revision=s.car.quote.revision or 0,amount=a=='Counter'and v or s.car.quote.accepted}end
 event:FireServer(a,v);if pending and render then render()end
end
local function button(name,label,y,fn,kind,x,w)
 local b=make('TextButton',panel,{Name=name,Text=label,Position=UDim2.new(x or 0,x and 0 or 16,0,y),Size=UDim2.new(w or 1,w and -8 or -32,0,44),BackgroundColor3=kind=='soft'and C.soft or kind=='text'and C.paper or C.green,TextColor3=C.ink,TextSize=15,Font=Enum.Font.GothamBold,BorderSizePixel=0,TextWrapped=true});round(b,9);b.Activated:Connect(function()if pending and focus=='deal'then return end;ping(.9);fn()end);if pending and focus=='deal'then b.AutoButtonColor=false;b.BackgroundColor3=C.soft;if name=='Accept'or name=='SendCounter'then b.Text='Waiting…'end end;return b
end
local function title(t,sub)
 local h=text(panelHeader,'Title',t,10,27,20);h.Size=UDim2.new(1,-76,0,27);h.TextWrapped=false;h.TextTruncate=Enum.TextTruncate.AtEnd
 if sub then local v=text(panelHeader,'Subtitle',sub,36,23,13);v.TextColor3=C.teal;v.TextWrapped=false;v.TextTruncate=Enum.TextTruncate.AtEnd end
 local x=button('Close','×',5,close,'text',.85,.14);x.Parent=panelHeader;x.Size=UDim2.fromOffset(44,44)
end
local function say(line,y,h)local t=text(panel,'Words',line,y,h,20);t.BackgroundTransparency=0;t.BackgroundColor3=C.soft;round(t,10);make('UIPadding',t,{PaddingLeft=UDim.new(0,10),PaddingRight=UDim.new(0,10)});return t end
local function actorPosition()return s.car and s.car.remote and{43,-43}or s.car and s.car.status=='seller'and{-6,-5.33333}or{10.33333,-6.7}end
local function context()
 if not s then return 'Loading…','',nil,nil end
 if ownerId~=player.UserId then return 'Watching the dealership','',nil,nil end
 if s.personal and s.personal.route then return s.personal.route.target=='lead'and'Drive to Elias’s garage.'or'Drive your car home.',driving and'Brake'or'Drive →','drive' end
 local c=s.car
 if c then
  if c.status=='seller'or c.status=='buyer'then return c.status=='seller'and(M.def(s).seller..' has a car for you.')or(M.buyer(s).name..' is ready to make an offer.'),c.status=='seller'and'Meet seller'or'View offer','deal',actorPosition()end
  if c.status=='choose'then return 'Choose how much work to put into this flip.','Choose flip','build',{c.pos[1],c.pos[2]+3}end
  if c.status=='repair'then local j=M.job(s);return s.worker.hired and'Jo has the repairs covered.'or j and('Repair '..j.name..'.')or'Finishing up.',s.worker.hired and'View Jo'or j and j.started and'Working…'or j and('Fix '..j.name)or'','repair',{c.pos[1],c.pos[2]+3}end
  if c.status=='photo'then return 'Ready. Let’s find it a buyer.','Take photo','photo'end
  if c.status=='sold'then return 'Off to its new owner.','',nil end
  if c.status=='moving'or c.status=='arriving'or c.status=='waitingBuyer'or c.status=='discovery'then return c.status=='waitingBuyer'and'Another buyer is on the way.'or'Your car is on its way.','',nil end
 end
 local p=M.nextPad(s);if p then return p.id=='lot'and'Step onto the first pad to open your lot.'or('Next, add '..p.name:lower()..'.'),'Show me →','pad',p.pos,p.id end
 if s.rareCallAt then return 'Your own car. You’ve earned this.','',nil end
 if s.lead then return 'There’s a call for you.','Open phone','phone'end
 if s.completed then return 'Your first rare flip. A real business.','Your journey','complete'end
 return 'Explore your dealership.','Phone','phone'
end
local function act(kind,id)
 if kind=='pad'then fire('Pad',id)elseif kind=='deal'then fire('Deal')elseif kind=='repair'then if s.worker.hired then open('worker')else fire('Repair')end elseif kind=='photo'then fire('Photo');close()elseif kind=='drive'then driving=not driving;fire('Drive',driving)elseif kind then open(kind)end
end
local function navigate(pos,kind,id)
 if not pos then act(kind,id);return end
 local char=player.Character;local h=char and char:FindFirstChildOfClass('Humanoid');local r=char and char:FindFirstChild('HumanoidRootPart');if not r or not h then return end
 if(r.Position-D.world(pos)).Magnitude<12 then act(kind,id);return end
 walkToken+=1;local token=walkToken;walking=true
 task.spawn(function()
  local path=game:GetService('PathfindingService'):CreatePath({AgentRadius=2,AgentCanJump=true,WaypointSpacing=5});local ok=pcall(function()path:ComputeAsync(r.Position,D.world(pos,3))end)
  local points=ok and path.Status==Enum.PathStatus.Success and path:GetWaypoints()or{{Position=D.world(pos,3)}}
  for _,wp in points do if token~=walkToken or not char.Parent then return end;if wp.Action==Enum.PathWaypointAction.Jump then h.Jump=true end;h:MoveTo(wp.Position);local untilAt=os.clock()+6;repeat task.wait(.05)until token~=walkToken or(r.Position-wp.Position).Magnitude<4 or os.clock()>untilAt;if token~=walkToken then return end;if os.clock()>untilAt then walking=false;return end end
  walking=false;act(kind,id)
 end)
end
render=function()
 if not s then return end
 panel.Visible=focus~='world'and focus~='cinema';for _,o in panel:GetChildren()do if o:IsA('GuiObject')then o:Destroy()end end
 for _,o in panelHeader:GetChildren()do if o:IsA('GuiObject')then o:Destroy()end end
 local c=s.car;local d=M.def(s);local height=300
 phoneNav.Visible=focus=='phone'
 for _,o in phoneNav:GetChildren()do if o:IsA('GuiObject')then o:Destroy()end end
 if focus=='deal'and c and c.quote then
  local q=c.quote;local b=q.mode=='sell'and M.buyer(s);title(d.name,(b and b.name..' · '..b.role or d.seller..' · Seller'));say('“'..q.line..'”',60,52)
  local label=text(panel,'Price',money(q.accepted),116,38,31);if b then local margin=q.accepted-c.purchase-c.workSpent;local t=text(panel,'Profit',money(math.abs(margin))..(margin<0 and' loss' or' profit')..' · '..b.cue,154,20,13);t.TextColor3=margin<0 and Color3.fromRGB(162,63,46)or C.teal;local sub=panelHeader:FindFirstChild('Subtitle');sub.TextColor3=b.role=='Collector'and Color3.fromRGB(124,79,152)or b.role=='Enthusiast'and Color3.fromRGB(35,113,136)or C.teal end
  if counter then button('Minus','−',178,function()draft=math.max(q.mode=='sell'and q.accepted or 50,draft-50);render()end,'soft',.05,.17);local val=text(panel,'Draft',money(draft),178,44,20);val.Position=UDim2.new(.22,0,0,178);val.Size=UDim2.new(.30,0,0,44);val.TextXAlignment=Enum.TextXAlignment.Center;button('Plus','+',178,function()draft=math.min(q.mode=='buy'and M.terms(s).ask or 20000,draft+50);render()end,'soft',.53,.15);button('SendCounter','Send',178,function()fire('Counter',draft);counter=false;render()end,'soft',.70,.26)
  else button('Counter','Make a counter',178,function()counter=true;draft=q.accepted;render()end,'soft')end
  local y=228;button('Accept',(b and'Sell for 'or'Buy for ')..money(q.accepted),y,function()fire('Accept')end,nil,.045,.64);button('Pass',b and'Pass on offer'or c.remote and'Head home'or'Not now',y,function()if b then fire('Decline')elseif c.remote then fire('Leave')end;close()end,'text',.71,.25);height=284
 elseif focus=='build'and c then title('Choose your flip',d.name)
  button('Quick','Quick Flip · Repair',76,function()depth='Quick';render()end,depth=='Quick'and 'selected' or'soft')
  local enhanced=button('Enhanced',M.has(s,'finish')and'Enhanced · Repair + finish'or'Enhanced · Later',126,function()if M.has(s,'finish')then depth='Good';render()end end,depth=='Good'and 'selected' or'soft');enhanced.AutoButtonColor=M.has(s,'finish')
  local estimate=M.estimate(s,depth);text(panel,'Profit','~'..money(estimate.profit)..' margin · '..estimate.seconds..'s work',178,25,17);text(panel,'EstimateNote','Buyer offers vary. Extras can change the margin.',202,22,12)
  button('Start','Fund work · '..money(estimate.cost),236,function()fire('Plan',depth)end)
 elseif focus=='prepare'and c then title('Ready for its next owner',d.name);button('Photo','Take photo',90,function()fire('Photo');close()end);if M.has(s,'finish')then button('Customize','Customize',146,function()open('custom')end,'soft')end;button('Journal','Car story',202,function()open('journal')end,'soft')
 elseif focus=='custom'and c and custom then
  title('Make it yours',d.name)
  for i,t in {'Looks','Paint','Details'}do button(t,t,98,function()customTab=t;render()end,customTab==t and 'selected' or'soft',(i-1)/3+.03,.30)end
  if customTab=='Looks'then for i,name in {'Original','Street','Weekend'}do button(name,name,146,function()custom=name=='Original'and{paint='original',wheels='original',stripe=false}or name=='Street'and{paint='red',wheels='sport',stripe=false}or{paint='cream',wheels='sport',stripe=true};render()end,'soft',(i-1)/3+.025,.31)end
  elseif customTab=='Paint'then for i,col in {'original','cream','blue','red','green'}do local b=button(col,(custom.paint==col and'✓ 'or'')..col,146+math.floor((i-1)/3)*48,function()custom.paint=col;render()end,'soft',((i-1)%3)/3+.025,.31)end
  else button('Wheels',custom.wheels=='sport'and'✓ Sport wheels'or'Original wheels',146,function()custom.wheels=custom.wheels=='sport'and'original'or'sport';render()end,'soft');button('Stripe',custom.stripe and'✓ Stripe on'or'Stripe off',194,function()custom.stripe=not custom.stripe;render()end,'soft')end
  local fit=c.index==4 and'Collectors pay more for the original look.'or c.index==2 and'Sport wheels add value. Paint is mainly for style.'or'Practical buyers pay for repairs, not style.';text(panel,'BuyerFit',fit,62,32,13)
  local old=c.custom or{paint='original',wheels='original',stripe=false};local cost=(custom.paint~=old.paint and 180 or 0)+(custom.wheels~=old.wheels and 120 or 0)+(custom.stripe~=old.stripe and 80 or 0)
  button('OrbitLeft','Left',customTab=='Looks'and 194 or 242,function()orbit-=.6 end,'soft',.04,.20);button('OrbitRight','Right',customTab=='Looks'and 194 or 242,function()orbit+=.6 end,'soft',.26,.20);button('Undo','Undo',customTab=='Looks'and 194 or 242,function()custom=M.copy(old);render()end,'soft',.52,.44)
  apply.Text=cost==0 and'Keep this look'or'Apply · '..money(cost);height=customTab=='Looks'and 266 or 316
 elseif focus=='worker'then title('Jo','Your mechanic');say(s.worker.activity,74,58);text(panel,'Jobs',s.worker.jobs..' cars finished · '..(s.worker.level>1 and'Trained'or'Rookie'),144,28,18);button('Train',s.worker.level>1 and'Trained · 20% less work time'or s.worker.jobs>0 and'Train Jo · $350'or'Finish one job to train',193,function()fire('Train')end,'soft')
 elseif focus=='phone'then
  title('Dealership phone',tab=='Home'and s.lead and(s.lead.caller..' calling')or tab);local y=76
  if tab=='Home'then
   if s.personal and s.personal.route then say('On the road. Your lead is waiting.',y,68);button('BackDrive','Back to driving',154,close)
   elseif s.lead then say(s.lead.kind=='rare'and'Elias found a Phoenix. Take your car, or bring it here.'or s.lead.text,66,50)
    if s.lead.kind=='rare'then button('Visit','Drive there · save $300',124,function()fire('Visit')end);button('Invite','Bring it here',174,function()fire('Invite')end,'soft');height=232
    else button('Invite','Bring it here',124,function()fire('Invite')end)end
    if s.lead.kind=='rare'then local _,short=M.leadBudget(s,true);if short>0 then text(panel,'Budget','Need '..money(short)..' more. Find a flip in Deals.',224,42,13);height=276 end end
   else say(c and'One car. Your attention.'or'Your dealership, connected.',y,76);button('Sound',soundOn and'Sound on'or'Sound off',170,function()soundOn=not soundOn;render()end,'soft')end
  elseif tab=='Deals'then if c then say(d.name..' · '..D.grade(c.condition),76,62);button('DealAction',c.status=='photo'and'Take photo'or'Car story',152,function()if c.status=='photo'then fire('Photo');close()else open('journal')end end);if c.status=='photo'and M.has(s,'finish')then button('Customize','Customize',204,function()open('custom')end,'soft')end elseif s.lead and s.lead.kind=='rare'and s.cash<6000 then say('Build cash with an ordinary flip. Your rare lead stays saved.',76,70);button('Recovery','Find an ordinary flip',166,function()fire('Recovery')end)else say('No active listing.',76,62)end
  elseif tab=='Team'then say(s.worker.hired and'Jo has your workshop covered.'or'It starts with you.',76,72);if s.worker.hired then button('ViewJo','View Jo',168,function()open('worker')end)end
  elseif tab=='Garage'then say(s.personal and'Your Desert Coupe' or 'Earn a car of your own.',76,62);if s.personal then button('Personal','Your own car',150,function()open('personal')end)end;button('History','Your car stories',202,function()open('complete')end,'soft')end
  for i,t in {'Home','Deals','Team','Garage'}do local b=button('Tab'..t,t,6,function()tab=t;panel.CanvasPosition=Vector2.zero;render()end,tab==t and 'selected' or'soft',(i-1)/4+.015,.24);b.Parent=phoneNav;b.TextSize=12 end
 elseif focus=='personal'then title('Your Desert Coupe','Your own car');say('A car for chasing your next lead.',78,80);if s.lead and s.lead.kind=='rare'then button('CallJo','Call Jo',182,function()tab='Home';open('phone')end)end
 elseif focus=='journal'and c then title(d.name,'Car story');text(panel,'Condition',c.arrivalGrade..' on arrival',76,24,18);local y=110;for _,line in c.history do text(panel,'Entry',line,y,35,14);y+=39 end;height=math.max(300,y+16)
 elseif focus=='wallet'then title('Your money');text(panel,'Cash',money(s.cash),58,46,34);text(panel,'Reserved',money(M.reserve(s))..' reserved for work',108,30,14);local y=150;for _,e in s.ledger do text(panel,'Entry',e.subject..'  '..(e.amount<0 and'−'or'+')..money(math.abs(e.amount)),y,36,13);y+=40 end;height=math.max(300,y+16)
 elseif focus=='result'and receipt then
  title(receipt.title,receipt.car..' · '..receipt.person)
  if receipt.buying then text(panel,'Amount',money(receipt.amount)..' paid',80,46,30);say(receipt.line,138,66)
  else local net=receipt.profit;local t=text(panel,'Profit',money(math.abs(net))..(net<0 and' loss'or' profit'),76,44,30);t.TextColor3=net<0 and Color3.fromRGB(162,63,46)or C.teal;text(panel,'Costs','Bought '..money(receipt.purchase)..' · Work '..money(receipt.work),126,26,14);text(panel,'Sale','Sold for '..money(receipt.amount),158,28,19);text(panel,'Fit',receipt.role..' · '..(receipt.fit or''),194,25,13)end
  button('Continue','Continue',240,close);height=296
 elseif focus=='complete'then title('Your dealership',s.sales..' cars sold');local y=72;for _,car in s.history do text(panel,'History',D.cars[car.index].name..'\n'..money(car.sale-car.purchase-car.workSpent)..' profit',y,56,16);y+=62 end;height=math.max(300,y+16)
 end
 panel.CanvasSize=UDim2.fromOffset(0,height);customFooter.Visible=focus=='custom'
end
apply.Activated:Connect(function()if custom then fire('Custom',custom)end end)
wallet.Activated:Connect(function()open('wallet')end);phone.Activated:Connect(function()tab='Home';open('phone')end);call.Activated:Connect(function()tab='Home';open('phone')end)
portrait.Activated:Connect(function()local _,_,kind,pos,id=context();navigate(pos,kind,id)end)
go.Activated:Connect(function()if walking then walkToken+=1;walking=false;local h=player.Character and player.Character:FindFirstChildOfClass('Humanoid');if h then h:MoveTo(h.RootPart.Position)end;return end;local _,_,kind,pos,id=context();navigate(pos,kind,id)end)
skip.Activated:Connect(function()fire('Discover');close()end)
local carTag=make('Frame',base,{Name='CarState',Size=UDim2.fromOffset(202,48),AnchorPoint=Vector2.new(.5,1),BackgroundTransparency=1,Visible=false})
local carLabel=make('TextButton',carTag,{Name='Readiness',Size=UDim2.fromScale(1,1),Text='',TextSize=14,TextWrapped=true,TextColor3=C.ink,Font=Enum.Font.GothamBold,BackgroundColor3=C.paper,BackgroundTransparency=1,TextStrokeColor3=C.ink,TextStrokeTransparency=.2,BorderSizePixel=0});carLabel.TextColor3=C.paper
carLabel.Activated:Connect(function()if s.car.status=='photo'then open('prepare')elseif s.car.status=='seller'or s.car.status=='buyer'then navigate(actorPosition(),'deal')elseif s.car.status=='repair'then local _,_,kind,pos=context();navigate(pos,kind)else open('journal')end end)
local padTag=make('Frame',base,{Name='PadLabel',Size=UDim2.fromOffset(180,48),AnchorPoint=Vector2.new(.5,1),BackgroundTransparency=1,Visible=false});local padText=text(padTag,'Title','',0,48,15);padText.Position=UDim2.new();padText.Size=UDim2.fromScale(1,1);padText.BackgroundColor3=C.paper;padText.BackgroundTransparency=0;padText.TextXAlignment=Enum.TextXAlignment.Center;round(padText,8)
local arrows={};for i=1,10 do local p=Instance.new('Part');p.Name='HelperArrow';p.Size=Vector3.new(1.5,.08,.5);p.Anchored=true;p.CanCollide=false;p.CanQuery=false;p.CanTouch=false;p.Color=C.yellow;p.Material=Enum.Material.Neon;p.Transparency=1;p.Parent=workspace;arrows[i]=p end
local ghost;local ghostId
local previewFirst={tools=3,power=16,air=15,sales=5,salesdesk=6,finish=8,restoration=7,shade=13,servicefloor=4,wheeltools=9,fluidkit=10,finishtrolley=11,partsshelves=12}
local function ghostFor(p)
 if ghostId==(p and p.id)then return end;if ghost then ghost:Destroy();ghost=nil end;ghostId=p and p.id;if not p then return end
 ghost=Instance.new('Model');ghost.Name='PurchasePreview';ghost.Parent=workspace;local source=workspace:FindFirstChild('SellCars_Dealership_FullJourney');local first=previewFirst[p.id]
 if source and first then local count=0;for _,o in source:GetDescendants()do if o:IsA('BasePart')and o:GetAttribute('FJ_First')==first and count<150 then local copy=o:Clone();copy:ClearAllChildren();copy.Transparency=.7;copy.Color=C.green;copy.Material=Enum.Material.ForceField;copy.CanCollide=false;copy.CanTouch=false;copy.CanQuery=false;copy.Parent=ghost;count+=1 end end end
 if #ghost:GetChildren()==0 then local p1=Instance.new('Part');p1.Size=Vector3.new(6,.2,6);p1.CFrame=CFrame.new(D.world(p.pos,2));p1.Transparency=.65;p1.Color=C.green;p1.Anchored=true;p1.CanCollide=false;p1.CanQuery=false;p1.Parent=ghost end
end
local mouse=player:GetMouse();mouse.Button1Down:Connect(function()if focus~='world'or UIS:GetFocusedTextBox()then return end;local o=mouse.Target;if not o then return end;local pad=o:GetAttribute('HubPad');if pad then for _,p in D.pads do if p.id==pad then navigate(p.pos,'pad',p.id)end end;return end;local m=o:FindFirstAncestorWhichIsA('Model');if m then if m:GetAttribute('HubActor')then navigate(actorPosition(),'deal')elseif m:GetAttribute('HubWorker')then open('worker')elseif m:GetAttribute('HubPersonal')then open('personal')elseif m:GetAttribute('HubCar')then if s.car.status=='photo'then open('prepare')elseif s.car.status=='seller'or s.car.status=='buyer'then navigate(actorPosition(),'deal')elseif s.car.status=='repair'then local _,_,kind,pos=context();navigate(pos,kind)else open('journal')end end end end)
UIS.InputBegan:Connect(function(input,processed)if processed then return end;if input.KeyCode==Enum.KeyCode.W then heldW=true;walkToken+=1;walking=false elseif input.KeyCode==Enum.KeyCode.S then heldW=false;driving=false elseif input.KeyCode==Enum.KeyCode.Escape then close()end end)
UIS.InputEnded:Connect(function(i)if i.KeyCode==Enum.KeyCode.W then heldW=false end end);UIS.WindowFocusReleased:Connect(function()heldW=false;driving=false;fire('Drive',false)end)
event.OnClientEvent:Connect(function(kind,data,id)
 if kind=='State'then s=data;ownerId=id
  if #s.pads>lastPads then lastPads=#s.pads;celebrateUntil=os.clock()+1.5;ping(1.2);pulse(wallet)end
  if s.worker.jobs>lastJobs then lastJobs=s.worker.jobs;ping(1.35)end
  local leadKey=s.lead and(s.lead.kind..'-'..s.lead.index);if leadKey and leadKey~=lastLead then ringAt=os.clock();ping(1.05)end;lastLead=leadKey
  if s.car and s.car.status=='discovery'and focus~='cinema'then focus='cinema';cinemaStart=os.clock();panel.Visible=false;walkToken+=1;walking=false end
  if focus=='deal'and(not s.car or not s.car.quote)then close()end
  local sig=table.concat({s.car and s.car.id or'',s.car and s.car.status or'',s.car and s.car.quote and s.car.quote.line or'',s.cash,s.worker.level,s.worker.jobs,s.worker.activity,s.lead and s.lead.status or'',s.personal and s.personal.status or''},'|')
  if sig~=lastSig then lastSig=sig;if focus~='world'and focus~='cinema'then render()end end
 elseif kind=='Open'then counter=false;open(data)
 elseif kind=='Ack'then pending=false;if focus=='deal'then render()end
 elseif kind=='Done'then ping(1.3);if data=='Custom'then open('prepare')else close()end
 elseif kind=='Result'then pending=false;receipt=data;receiptCamera=workspace.CurrentCamera.CFrame;ping(1.4);open('result')end
end)
Run.RenderStepped:Connect(function(dt)
 if not s then return end
 local lock=focus~='world'or(s.personal and s.personal.route~=nil)or false;local touch=player.PlayerGui:FindFirstChild('TouchGui');if touch then touch.Enabled=not lock end;if controls and lock~=controlsLock then controlsLock=lock;if lock then controls:Disable()else controls:Enable()end end
 local v=base.AbsoluteSize;local footer=focus=='phone'or focus=='custom';local ph=math.min(390,v.Y-8);local pw=math.min(370,math.max(290,v.X*.47));panel.Size=UDim2.fromOffset(pw,ph-(footer and 56 or 0));panel.Position=UDim2.new(1,-14,.5,footer and -28 or 0);panelHeader.Position=UDim2.new(1,-14,.5,-ph/2);panelHeader.Size=UDim2.fromOffset(pw,62);panelHeader.Visible=focus~='world'and focus~='cinema'
 local notice=s.notice and s.noticeUntil and s.clock<s.noticeUntil;local sideNotice=notice and focus~='world'and focus~='cinema'
 guide.Size=UDim2.fromOffset(sideNotice and math.max(220,v.X-pw-48)or math.min(460,v.X-160),70);guide.AnchorPoint=sideNotice and Vector2.new(0,1)or Vector2.new(.5,1);guide.Position=sideNotice and UDim2.new(0,14,1,-8)or UDim2.new(.5,0,1,-8);gt.Size=UDim2.new(1,sideNotice and -80 or -216,0,52)
 phoneNav.Size=UDim2.fromOffset(pw,56);phoneNav.Position=UDim2.new(1,-14,.5,ph/2);phoneNav.Visible=focus=='phone'
 customFooter.Size=UDim2.fromOffset(panel.AbsoluteSize.X,56);customFooter.Position=UDim2.new(1,-14,.5,ph/2);customFooter.Visible=focus=='custom';wallet.Text=money(s.cash);local message,action,kind,pos=context();gt.Text=notice and s.notice or walking and'Follow the path. I’ll show you the way.'or message;go.Text=walking and'Stop'or action;go.Visible=action~=''and not sideNotice;guide.Visible=focus=='world'or sideNotice;wallet.Visible=focus=='world';phone.Visible=focus=='world'
 call.Visible=focus=='world'and s.lead~=nil and s.lead.status=='ringing'and not walking and os.clock()>celebrateUntil and not(s.personal and s.personal.route);phone.Visible=focus=='world'and not call.Visible;if call.Visible then call.Position=UDim2.new(1,-14,0,4);call.BackgroundColor3=os.clock()-ringAt<3 and C.yellow or C.paper end;if s.lead then call.Text=s.lead.caller..' is calling\n'..(s.lead.kind=='rare'and'A rare lead'or'A car for your lot')end
 -- Receipts remain until the player chooses Continue.
 cinema.Visible=focus=='cinema';skip.Visible=cinema.Visible
 if player.Character then for _,p in player.Character:GetDescendants()do if p:IsA('BasePart')then p.LocalTransparencyModifier=(focus=='deal'or focus=='result'or focus=='custom'or focus=='cinema')and 1 or 0 end end end
 local c=s.car;local model=world:FindFirstChild('TradingCar');local actor=world:FindFirstChild('DealPerson');local camera=workspace.CurrentCamera
 if focus=='cinema'and model then local t=os.clock()-cinemaStart;local beat=math.min(8,math.floor(t/.42)+1);local a=({-.9,-.65,-.4,-.1,.2,.45,.65,.8})[beat];local radius=beat<6 and 17 or 14;local p=model:GetPivot().Position;camera.CameraType=Enum.CameraType.Scriptable;camera.CFrame=CFrame.lookAt(p+Vector3.new(math.sin(a)*radius,6,math.cos(a)*radius),p+Vector3.new(0,1,0));cinema.Text=t<2.6 and'RARE FIND'or t<3.4 and'1972'or'1972 PHOENIX GT\nRARE FIND';cinema.TextSize=t<3.4 and 34 or 27;if t>5 then fire('Discover');close()end
 elseif(focus=='deal'or focus=='result')and actor then local p=actor.Head.Position;camera.CameraType=Enum.CameraType.Scriptable;local desired=CFrame.lookAt(p+Vector3.new(5,3,15),p+Vector3.new(6,0,0));camera.CFrame=camera.CFrame:Lerp(desired,math.min(1,dt*8))
 elseif focus=='result'then camera.CameraType=Enum.CameraType.Scriptable;if receiptCamera then camera.CFrame=receiptCamera end
 elseif focus=='custom'and model then orbitShown+=(orbit-orbitShown)*math.min(1,dt*8);local p=model:GetPivot().Position;camera.CameraType=Enum.CameraType.Scriptable;local offset=Vector3.new(math.cos(orbitShown)*7,0,-math.sin(orbitShown)*7);camera.CFrame=CFrame.lookAt(p+Vector3.new(math.sin(orbitShown)*18,7,math.cos(orbitShown)*18)+offset,p+offset);if custom then local color=Color3.fromHex(({cream='#e8d9b2',blue='#609fb6',red='#bd594a',green='#648b71'})[custom.paint]or M.def(s).color);model.Body.Color=color;local cabin=model:FindFirstChild('Cabin');if cabin then cabin.Color=color end end
 elseif s.personal and s.personal.route then local p=D.world(s.personal.pos);camera.CameraType=Enum.CameraType.Scriptable;camera.CFrame=camera.CFrame:Lerp(CFrame.lookAt(p+Vector3.new(8,24,36),p),math.min(1,dt*6));if os.clock()-lastSent>.3 then lastSent=os.clock();fire('Drive',focus=='world'and(driving or heldW))end
 elseif focus=='world'and camera.CameraType==Enum.CameraType.Scriptable then driving=false;cameraBack()end
 if model and c then local preview=focus=='custom'and custom or c.custom or{paint='original',wheels='original',stripe=false};local color=Color3.fromHex(({cream='#e8d9b2',blue='#609fb6',red='#bd594a',green='#648b71'})[preview.paint]or M.def(s).color)
  for _,p in model:GetChildren()do if p:IsA('BasePart')then if p.Name=='Body'or p.Name=='Cabin'then p.Color=color elseif p.Name=='Wheel'then p.Color=preview.wheels=='sport'and Color3.fromRGB(31,38,45)or Color3.fromRGB(55,53,48)end end end
  local stripe=model:FindFirstChild('DraftStripe');if preview.stripe and not stripe then stripe=Instance.new('Part');stripe.Name='DraftStripe';stripe.Size=Vector3.new(6,.04,.45);stripe.Anchored=true;stripe.CanCollide=false;stripe.CanQuery=false;stripe.Color=C.paper;stripe.Parent=model end
  if stripe then stripe.Transparency=preview.stripe and 0 or 1;stripe.CFrame=model.Body.CFrame*CFrame.new(0,model.Body.Size.Y/2+.06,0)end
 end
 local function project(point,w,h)
  local pt,shown=camera:WorldToViewportPoint(point);local y=pt.Y-select(1,game.GuiService:GetGuiInset()).Y
  if not shown then return UDim2.new(),false end
  y=math.clamp(y,58+h,math.max(58+h,v.Y-90));return UDim2.fromOffset(math.clamp(pt.X,w/2+8,v.X-w/2-8),y),true
 end
 local rootPart=player.Character and player.Character:FindFirstChild('HumanoidRootPart');carTag.Visible=focus=='world'and model~=nil and c and c.status~='sold'and rootPart~=nil and(rootPart.Position-model:GetPivot().Position).Magnitude<(carTag.Visible and 30 or 26) or false
 if model and c then local point,onScreen=project(model.Body.Position+Vector3.new(0,5,0),202,48);carTag.Position=point;carTag.Visible=carTag.Visible and onScreen;local j=M.job(s);local labels={arriving='Arriving',moving=c.route and('To '..(c.route.target=='repair'and'workshop'or c.route.target=='sales'and'sales bay'or c.route.target=='exit'and'new owner'or'intake'))or'On the move',choose='Choose your flip',owned='Workshop needed',ready='Ready',photo='Ready to list',buyer='Buyer ready',waitingBuyer='Finding a buyer',seller=M.def(s).name}
  local total,remaining=0,0;if c.plan then for _,job in c.plan.jobs do total+=job.seconds;remaining+=job.seconds*(1-job.progress)end end
  carLabel.Text=(c.status=='repair'and(j and(j.name..(j.started and' · Working'or s.worker.hired and' · Jo approaching'or' · Tap to repair'))or'Ready')or labels[c.status]or M.def(s).name)..'\n'..(c.status=='repair'and(math.ceil(total>0 and remaining/total*100 or 0)..'% work left')or not c.owned and(c.arrivalGrade..' · '..M.def(s).rarity)or D.grade(c.condition))end
 local r=player.Character and player.Character:FindFirstChild('HumanoidRootPart');local nearest;local dist=14
 if r and focus=='world'and not(s.personal and s.personal.route)then for _,p in D.pads do if M.eligible(s,p)then local dd=(r.Position-D.world(p.pos)).Magnitude;if dd<dist then dist=dd;nearest=p end end end end
 padTag.Visible=nearest~=nil;if nearest then local point,onScreen=project(D.world(nearest.pos,6),180,48);padTag.Position=point;padTag.Visible=onScreen;local short=nearest.cost-math.max(0,s.cash-M.reserve(s));padText.Text=nearest.name..'\n'..(short>0 and('Need '..money(short)..' more')or nearest.cost==0 and'FREE'or nearest.id=='air'and(money(nearest.cost)..' + '..money(D.quote(M.def(s)).cost)..' work')or money(nearest.cost)..(nearest.optional and' · Build only'or''));padText.TextColor3=short>0 and Color3.fromRGB(150,66,44)or C.ink end;ghostFor(nearest)
 if r and pos and routeEnabled and focus=='world'and not pathBusy then
  local key=tostring(pos[1])..':'..tostring(pos[2]);if key~=pathKey or os.clock()-pathAt>1.5 and(not pathFrom or(r.Position-pathFrom).Magnitude>6)then
   pathBusy=true;pathKey=key;pathAt=os.clock();pathFrom=r.Position;local from=r.Position;local goal=D.world(pos,3)
   task.spawn(function()local path=game:GetService('PathfindingService'):CreatePath({AgentRadius=2,AgentCanJump=true,WaypointSpacing=4});local ok=pcall(function()path:ComputeAsync(from,goal)end);pathPoints=ok and path.Status==Enum.PathStatus.Success and path:GetWaypoints()or{};pathBusy=false end)
  end
 end
 for i,a in arrows do a.Transparency=1;local wp=pathPoints[i+1];if r and pos and focus=='world'and wp and routeEnabled then local nextPoint=pathPoints[i+2];a.CFrame=CFrame.lookAt(Vector3.new(wp.Position.X,1.94,wp.Position.Z),nextPoint and Vector3.new(nextPoint.Position.X,1.94,nextPoint.Position.Z)or D.world(pos,1.94));a.Transparency=.15 end end

end)
fire('Ready')

