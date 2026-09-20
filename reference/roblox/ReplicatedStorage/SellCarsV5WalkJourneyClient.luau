-- Presentation only. All progression requests and proximity checks go through the Studio server.
local M={}
function M.Create(o)
 local self={active=false};local player=o.player;local remote=o.remote;local gui=o.gui
 local current=0;local target;local busy=false;local marker;local prompt;local stamp=0
 local walkHighlights={}
 local card=Instance.new('Frame');card.Name='WalkJourneyCard';card.Position=UDim2.new(0,16,1,-206);card.Size=UDim2.new(0,490,0,192);card.BackgroundColor3=Color3.fromRGB(24,31,33);card.BackgroundTransparency=.05;card.Visible=false;card.Parent=gui
 local limit=Instance.new('UISizeConstraint');limit.MaxSize=Vector2.new(490,192);limit.Parent=card
 local corner=Instance.new('UICorner');corner.CornerRadius=UDim.new(0,9);corner.Parent=card
 local function label(name,y,h,size)
  local t=Instance.new('TextLabel');t.Name=name;t.Position=UDim2.fromOffset(14,y);t.Size=UDim2.new(1,-28,0,h);t.BackgroundTransparency=1;t.Font=Enum.Font.GothamMedium;t.TextSize=size;t.TextColor3=Color3.fromRGB(240,230,207);t.TextWrapped=true;t.TextXAlignment=Enum.TextXAlignment.Left;t.TextYAlignment=Enum.TextYAlignment.Top;t.Parent=card;return t
 end
 label('Scope',9,14,10).Text='ON FOOT · VISUAL PREVIEW · NO MONEY OR SAVES'
 local heading=label('NextUpgrade',29,38,15)
 local benefit=label('Benefit',69,38,12)
 local goal=label('OpeningGoal',109,30,11)
 local status=label('WalkStatus',142,17,11)
 local function button(name,text,x,width,fn)
  local b=Instance.new('TextButton');b.Name=name;b.Text=text;b.Position=UDim2.fromOffset(x,164);b.Size=UDim2.new(width,-5,0,23);b.TextSize=11;b.Font=Enum.Font.GothamMedium;b.BackgroundColor3=Color3.fromRGB(66,80,76);b.TextColor3=Color3.fromRGB(246,234,202);b.Parent=card;b.Activated:Connect(fn);return b
 end
 local function clearMarker()if marker then marker:Destroy();marker=nil end;prompt=nil end
 local function request()if self.active and target and not busy then remote:FireServer('WALK_ADVANCE',o.token(),current+1)end end
 self.Reveal=request
 self.Travel=function()if self.active and not busy then remote:FireServer('WALK_TRAVEL',o.token(),current)end end
 button('Reveal','REVEAL NEXT',14,.34,request)
 button('TravelAid','GO TO MARKER',173,.34,self.Travel)
 button('BackToSlider','BACK TO SLIDER',332,.30,function()o.review(current)end)
 local function camera()
  local cam=workspace.CurrentCamera;cam.CameraType=Enum.CameraType.Custom;cam.FieldOfView=o.fov
  local h=player.Character and player.Character:FindFirstChildOfClass('Humanoid');if h then cam.CameraSubject=h end
  gui:SetAttribute('SolidRoofRecommended',true)
 end
 function self.Stop()
  self.active=false;busy=false;stamp+=1;clearMarker();card.Visible=false;gui:SetAttribute('WalkingJourney',false)
  for _,h in walkHighlights do h:Destroy()end;table.clear(walkHighlights)
 end
 function self.Start(n,beginning)
  o.cancel();o.stopAuto();self.active=true;stamp+=1;current=n;target=nil;busy=true;card.Visible=true;o.frame.Visible=false;gui.Enabled=true;gui:SetAttribute('WalkingJourney',true);gui:SetAttribute('Phase','WALK_LOADING');camera()
  heading.Text='Preparing your next upgrade…';benefit.Text='';goal.Text='';status.Text='Finding a supported inspection point.'
  remote:FireServer('WALK_START',o.token(),n,beginning and'BEGIN'or'RESUME')
 end
 local function setState(r)
  current=r.step;target=r.next;busy=false;gui:SetAttribute('Selected',current);gui:SetAttribute('ShownStep',current);gui:SetAttribute('WalkStep',current);gui:SetAttribute('Phase','WALK_READY');clearMarker()
  if not target then heading.Text='240 / 240 · Journey complete';benefit.Text='The whole environment is visible. Gameplay and economic effects remain separate.';goal.Text='Return to the slider for before/after comparisons.';status.Text='Preview complete';return end
  if r.travelled then
   local center=target.point+Vector3.new(0,3,0);local dir=Vector3.new(target.look.X-center.X,0,target.look.Z-center.Z)
   dir=dir.Magnitude>1 and dir.Unit or Vector3.zAxis
   local cam=workspace.CurrentCamera;cam.CFrame=CFrame.lookAt(center-dir*13+Vector3.new(0,5,0),center+dir*8);camera()
  end
  heading.Text=string.format('NEXT %03d / 240 · %s',target.step,target.title)
  local b=target.benefit;benefit.Text='INTENDED '..b.primaryBenefit:gsub('_',' '):upper()..' · '..b.intendedOutcome
  goal.Text=b.openingGoal or'Approach the marker, look toward the upgrade, then reveal it. Use the slider for an elevated detail view.'
  marker=Instance.new('Part');marker.Name='PX_NextUpgradeMarker';marker.Anchored=true;marker.CanCollide=false;marker.CanQuery=false;marker.CanTouch=false;marker.Size=Vector3.new(2.5,.1,2.5);marker.Position=target.point+Vector3.new(0,.1,0);marker.Material=Enum.Material.Neon;marker.Color=Color3.fromRGB(236,191,98);marker.Parent=workspace
  local billboard=Instance.new('BillboardGui');billboard.Name='NextUpgrade';billboard.Size=UDim2.fromOffset(180,44);billboard.StudsOffset=Vector3.new(0,2.5,0);billboard.AlwaysOnTop=true;billboard.MaxDistance=300;billboard.Parent=marker
  local t=Instance.new('TextLabel');t.Size=UDim2.fromScale(1,1);t.BackgroundColor3=Color3.fromRGB(31,40,42);t.BackgroundTransparency=.12;t.Text=string.format('NEXT %03d\n%s',target.step,target.title);t.TextScaled=true;t.TextColor3=Color3.fromRGB(247,229,181);t.Font=Enum.Font.GothamMedium;t.Parent=billboard
  prompt=Instance.new('ProximityPrompt');prompt.Name='PreviewUpgrade';prompt.ActionText='Reveal upgrade';prompt.ObjectText='Preview only · no purchase';prompt.HoldDuration=.4;prompt.MaxActivationDistance=12;prompt.RequiresLineOfSight=false;prompt.Parent=marker;prompt.Triggered:Connect(request)
  gui:SetAttribute('WalkTarget',target.point)
 end
 local function flash(parts)
  local highlights={};for i,p in parts or{}do if i<=10 and p:IsA('BasePart')and p:IsDescendantOf(workspace)and p.Transparency<1 then
   local h=Instance.new('Highlight');h.Name='PX_WalkChange';h.Adornee=p;h.FillTransparency=1;h.OutlineTransparency=.15;h.OutlineColor=Color3.fromRGB(243,200,110);h.Parent=gui;table.insert(highlights,h);table.insert(walkHighlights,h)
  end end
  task.delay(2,function()for _,h in highlights do h:Destroy();local i=table.find(walkHighlights,h);if i then table.remove(walkHighlights,i)end end end)
 end
 remote.OnClientEvent:Connect(function(kind,id,index,r)
  if not self.active or id~=o.token()then return end
  if kind=='ERROR'then busy=false;gui:SetAttribute('Phase','WALK_ERROR');status.Text=tostring(r):sub(-110);return end
  if kind=='WALK_HINT'then status.Text=r;return end
  if kind=='WALK_READY'then setState(r)
  elseif kind=='WALK_HOLD'then busy=true;if prompt then prompt.Enabled=false end;gui:SetAttribute('Phase','WALK_BEFORE');status.Text='BEFORE · look at the work area; revealing in 1.6 seconds…'
  elseif kind=='WALK_AFTER'then
   current=r.step;target=nil;busy=true;clearMarker();gui:SetAttribute('ShownStep',current);gui:SetAttribute('WalkStep',current);gui:SetAttribute('Phase','WALK_AFTER');flash(r.changedParts)
   heading.Text=string.format('ADDED %03d · %s',current,r.completed.title);benefit.Text='INTENDED BENEFIT · '..r.completed.intendedOutcome
   goal.Text=current==6 and'FIRST WORKFLOW READY · acquisition, preparation, listing and handover are physically represented. No sale was simulated.'or(current==24 and'BIRTH COMPLETE · a small owner-operated business with its first personal ambition.'or'Look at what changed. Your view stays under your control.')
   status.Text='AFTER · no money spent';stamp+=1;local mine=stamp;task.delay(current==6 and 4 or 2.4,function()if self.active and stamp==mine then setState(r)end end)
  end
 end)
 local elapsed=0
 game:GetService('RunService').Heartbeat:Connect(function(dt)
  if not self.active or busy or not target then return end;elapsed+=dt;if elapsed<.15 then return end;elapsed=0
  local c=player.Character;local h=c and c:FindFirstChild('HumanoidRootPart')
  if h then local distance=(h.Position-target.point).Magnitude;status.Text=distance<=12 and'HOLD E / TAP THE PROMPT · reveal the next visual upgrade'or string.format('Next marker: %.0f studs · walk there or use GO TO MARKER',distance)end
 end)
 player.CharacterAdded:Connect(function()if self.active then task.defer(camera)end end)
 local start=Instance.new('TextButton');start.Name='StartWalkingJourney';start.Position=UDim2.new(1,-342,0,56);start.Size=UDim2.fromOffset(184,32);start.Text='START ON FOOT / 0';start.TextSize=12;start.Font=Enum.Font.GothamMedium;start.BackgroundColor3=Color3.fromRGB(71,90,69);start.TextColor3=Color3.fromRGB(246,233,203);start.Parent=gui;start.Activated:Connect(function()self.Start(0,true)end)
 local resume=start:Clone();resume.Name='ResumeWalkingJourney';resume.Position=UDim2.new(1,-146,0,56);resume.Size=UDim2.fromOffset(130,32);resume.Text='WALK FROM HERE';resume.Parent=gui;resume.Activated:Connect(function()self.Start(math.clamp(gui:GetAttribute('ShownStep')or 0,0,240),false)end)
 return self
end
return M

