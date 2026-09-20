-- EL: lightweight local occupation. No NPC AI, purchases, vehicles or server motion.
if not game.RunService:IsStudio()or game.PlaceId~=125334614375606 then return end
local V,CF=Vector3.new,CFrame.new
local pg=game.Players.LocalPlayer:WaitForChild('PlayerGui')
local journey=pg:WaitForChild('SellCarsV5FullJourney',30);if not journey then return end
local ui=Instance.new('ScreenGui');ui.Name='SellCarsV5EverydayLife';ui.ResetOnSpawn=false;ui.DisplayOrder=104;ui.Parent=pg
local viewCaption=Instance.new('TextLabel');viewCaption.Name='ViewCaption';viewCaption.Position=UDim2.fromOffset(16,94);viewCaption.Size=UDim2.fromOffset(610,25);viewCaption.BackgroundColor3=Color3.fromRGB(26,36,36);viewCaption.BackgroundTransparency=.15;viewCaption.TextColor3=Color3.fromRGB(235,222,190);viewCaption.Font=Enum.Font.Gotham;viewCaption.TextSize=12;viewCaption.TextXAlignment=Enum.TextXAlignment.Left;viewCaption.Visible=false;viewCaption.Parent=ui
local function button(name,text,x,w,fn)
 local b=Instance.new('TextButton');b.Name=name;b.Text=text;b.Size=UDim2.fromOffset(w,30);b.Position=UDim2.fromOffset(x,56);b.BackgroundColor3=Color3.fromRGB(50,78,71);b.TextColor3=Color3.fromRGB(235,222,190);b.Font=Enum.Font.GothamBold;b.TextSize=12;b.Parent=ui;b.Activated:Connect(fn);return b
end
local enabled,focused=true,true;local activeView=false;local index=1;local generation=0
local records={};local trackedRoot;local dirty=true;local rootAdded,rootRemoving;local clock,dtSum,rescan=0,0,0
local function root()return workspace:FindFirstChild('SellCars_Dealership_FullJourney')end
local function base(p,step)
 local cf=p:GetAttribute('FJ_CF');if not cf then return p.CFrame end
 return cf+(step>=(p:GetAttribute('FJ_MoveAt')or 999)and(p:GetAttribute('FJ_Move')or V())or V())
end
local function reset(r,step)
 for _,j in r.joints do if j.Parent then j.Transform=j:GetAttribute('EL_RestTransform')or CF()end end
end
local function discover(r)
 for _,a in records do reset(a,journey:GetAttribute('ShownStep')or 240)end
 records={};trackedRoot=r;dirty=false
 if rootAdded then rootAdded:Disconnect();rootRemoving:Disconnect()end
 if not r then return end
 rootAdded=r.DescendantAdded:Connect(function()dirty=true end);rootRemoving=r.DescendantRemoving:Connect(function()dirty=true end)
 for _,m in r:GetDescendants()do if m:IsA('Model')and m:GetAttribute('EL_R6')and m:FindFirstChild('Torso')and m:FindFirstChild('HumanoidRootPart')then
  local joints={};for _,p in m:GetDescendants()do if p:IsA('Motor6D')then p.Transform=p:GetAttribute('EL_RestTransform')or CF();table.insert(joints,p)end end
  for _,p in m:GetDescendants()do if p:IsA('BasePart')then p.Anchored=p.Name=='HumanoidRootPart'elseif p:IsA('JointInstance')then p.Enabled=true end end
  table.insert(records,{m=m,torso=m.Torso,joints=joints,kind=m:GetAttribute('OC_Activity')or m:GetAttribute('EL_Activity'),offset=m:GetAttribute('EL_Offset')or 0})
 end end
 table.sort(records,function(a,b)return a.offset<b.offset end);ui:SetAttribute('TrackedActors',#records)
end
local function render(a,step,t)
 local envelope=math.min(t,7-t,1);envelope=math.clamp(envelope,0,1);envelope=envelope*envelope*(3-2*envelope)
 local pulse=math.sin(t*2.1);local k=a.kind
 -- Held objects are already welded to the left arm; right hand points/checks.
 -- Phased anticipation/action/settle instead of one generic shoulder wobble.
 local action=math.clamp((t-1)/1.5,0,1)*math.clamp((6-t)/1.4,0,1)
 local right,left,neck=CF(),CF(),CF()
 if k=='CONTROL'then right=CFrame.Angles(-.18*action,0,.5*action+.04*pulse*action);left=CFrame.Angles(-.08*action,0,-.06*action);neck=CFrame.Angles(.14*action,0,0)
 elseif k=='MEASURE'then right=CFrame.Angles(-.12*action,0,.45*action);left=CFrame.Angles(-.12*action,.08*math.sin(t)*action,0);neck=CFrame.Angles(.12*action,0,.07*math.sin(t)*action)
 elseif k=='SWATCH'then left=CFrame.Angles(-.23*action,.16*math.sin(t*.8)*action,0);right=CFrame.Angles(0,0,.16*action);neck=CFrame.Angles(.06*action,0,-.1*action)
 elseif k=='CHECK'then right=CFrame.Angles(-.16*action,0,.2*action+.1*math.sin(t*1.5)*action);left=CFrame.Angles(-.12*action,0,-.1*action);neck=CFrame.Angles(.1*action,0,.08*math.sin(t)*action)
 elseif k=='CONVERSE'then right=CFrame.Angles(-.08*action,0,.28*action+.06*pulse*action);neck=CFrame.Angles(.05*math.sin(t*2)*action,0,.1*math.sin(t*.7)*action)
 elseif k=='RADIO'then left=CFrame.Angles(-.28*action,0,-.12*action);neck=CFrame.Angles(.04*action,0,-.12*action)
 elseif k=='HANDOVER'then left=CFrame.Angles(-.2*action,0,-.13*action);right=CFrame.Angles(-.12*action,0,.32*action);neck=CFrame.Angles(.05*action,0,.1*action)
 elseif k=='RECORD'then right=CFrame.Angles(-.12*action,0,.48*action+.025*math.sin(t*5)*action);neck=CFrame.Angles(.15*action,0,0)
 else neck=CFrame.Angles(.025*action,0,.16*math.sin(t*.6)*action)end
 for _,j in a.joints do
  local rest=j:GetAttribute('EL_RestTransform')or CF();local delta=CF()
  if j.Name=='Right Shoulder'then delta=right
  elseif j.Name=='Left Shoulder'then delta=left
  elseif j.Name=='Neck'then delta=neck end
  j.Transform=rest*delta
 end
 -- HC: derive contact from the held object and real shoulder mounts.
 -- R6 has no elbow/fingers; use a rigid-arm reach, never stretch or detach a limb.
 if a.m:GetAttribute('HC_Contact')then
  local lj=a.torso:FindFirstChild('Left Shoulder');local rj=a.torso:FindFirstChild('Right Shoulder')
  local held=a.m:FindFirstChild('HandheldControl')or a.m:FindFirstChild('FinishSwatch2')
  if lj and rj and held then
   local weld;for _,j in a.m:GetDescendants()do if j:IsA('Weld')and j.Part0==lj.Part1 and j.Part1==held then weld=j;break end end
   if weld then
    local leftCF=lj.Part0.CFrame*lj.C0*lj.Transform*lj.C1:Inverse()
    local objectCF=leftCF*weld.C0*weld.C1:Inverse()
    local mount=rj.Part0.CFrame*rj.C0;local rest=rj:GetAttribute('EL_RestTransform')or CF()
    local arm=mount*rest*rj.C1:Inverse();local from=(arm:PointToWorldSpace(V(0,-1,0))-mount.Position).Unit
    local target=objectCF:PointToWorldSpace(V(held.Size.X*.3,held.Size.Y/2+.06,0))
    local toward=(target-mount.Position).Unit;local axis=from:Cross(toward)
    if axis.Magnitude>.00001 then
     local rotation=CFrame.fromAxisAngle(axis.Unit,math.acos(math.clamp(from:Dot(toward),-1,1)))
     local desired=CF(mount.Position)*rotation*CF(-mount.Position)*arm
     local contact=mount:Inverse()*desired*rj.C1
     rj.Transform=rest:Lerp(contact,action)
     if action>.95 then
      local endpoint=(mount*rj.Transform*rj.C1:Inverse()):PointToWorldSpace(V(0,-1,0))
      a.m:SetAttribute('HC_ContactGap',(endpoint-target).Magnitude)
     end
    end
    -- Neck aims toward the actual sample/control, rather than away from the work.
    local neckJoint=a.torso:FindFirstChild('Neck')
    if neckJoint then
     local localTarget=a.torso.CFrame:PointToObjectSpace(target)-V(0,1.5,0)
     local pitch=math.clamp(math.atan2(-localTarget.Y,math.max(.2,-localTarget.Z)),0,.48)
     local yaw=math.clamp(math.atan2(-localTarget.X,math.max(.2,-localTarget.Z)),-.35,.35)
     local restNeck=neckJoint:GetAttribute('EL_RestTransform')or CF()
     local rotation=CFrame.Angles(-pitch*action,yaw*action,0)
     neckJoint.Transform=restNeck*neckJoint.C0.Rotation:Inverse()*rotation*neckJoint.C0.Rotation
    end
   end
  end
 end
end
local views={
 {'Working hands',V(3040,9,169),V(3045,5,177)},
 {'Body / shaping metal',V(3007,7,268),V(2998,4.2,262)},
 {'Tune / electronics bench',V(3003,8,329),V(2993,6,325)},
 {'Paint / mixing and checking',V(3204,9,304),V(3214,7,309)},
 {'Parts / unpacking',V(3001,10,403),V(2987,6,411)},
 {'Customer conversation',V(3058,9,37),V(3049,5,43)},
 {'Finish samples',V(3138,7,479),V(3134,4.5,485)},
 {'Crew break',V(3153,8,155),V(3165,4.3,152)},
 {'Detail / correction tools',V(3205,8,279),V(3215,5.5,285)},
 {'Photo / preparation',V(3206,9,201),V(3216,5.7,200)},
 {'Welcome and handover',V(3087,8,99),V(3079,5.5,105)},
 {'Wash / nozzle care',V(2995,8,158),V(2985,6,153)},
 {'Wash / rinse demonstration',V(3051,8,139),V(3030,7,132)},
 {'Tune / fan and diagnostic activity',V(3030,8,312),V(3018,6.5,319)},
 {'Tune / live trace',V(2997,8,326),V(2991.6,6.3,324)},
 {'Arrival / customer-first frontage',V(3105,7,-8),V(3105,12,100)},
 {'Workshop street / earned roofline',V(3105,7,190),V(3035,15,265)},
 {'Rear landmark / craft institution',V(3105,7,365),V(3105,19,446)},
 {'Parts courtyard / receiving',V(3030,7,418),V(2995,8,465)},
 {'Operations / the people behind the shop',V(3180,7,421),V(3193,8,469)},
 {'Mechanical / lowered craft bench',V(3002,8,213),V(2994,5.6,217)},
 {'Paint / human-scale mixing bench',V(3201,8,302),V(3213,5.4,309)},
 {'Film / renewed cutting surface',V(3204,8,339),V(3215,5.4,345)},
 {'Owner / welded exhaust garden',V(3209,10,143),V(3219,8,153)},
 {'Owner / handbuilt listening corner',V(3215,8,79),V(3225,4.5,85)},
 {'Yard / dominoes and workday rituals',V(3171,9,144),V(3161,5,149)},
 {'Arrival / folded coachwork ribbon',V(3073,9,3),V(3086,6,14)},
 {'Plaza / salvaged vane windmill',V(3104,11,343),V(3091,9,359)},
 {'Body / hand-formed metal studies',V(3007,9,280),V(2995.7,8,284.5)},
 {'Paint / original pinstripe trials',V(3213,9,345),V(3225.3,8,351)},
 {'Tune / sound-system experiments',V(2995,9,345),V(2985,7,349)},
 {'Parts / the treasured donor find',V(3007,9,429),V(2997,5,439)},
 {'Hospitality / handmade daily rituals',V(3047,9,57),V(3037.7,6,62)},
 {'Mechanical reference / complete service edge',V(3013,10,185),V(2994,7,205)},
 {'Mechanical reference / powertrain teardown',V(3003,10,193),V(2996,7,200)},
 {'Mechanical reference / fluids and precision',V(3005,9,220),V(2994,7,225)},
 {'Mechanical reference / framed service wall',V(3007,11,197),V(2985,10,203)},
 {'Mechanical reference / exposed cylinder bank',V(2991,11,194),V(2996,7.4,200)},
 {'Craftsmanship / Wash water-treatment plant',V(3009,13,150),V(2993,6,137)},
 {'Craftsmanship / Paint matching machine',V(3204,9,316),V(3216,5.5,323)},
 {'Craftsmanship / Detail inspection edge',V(3203,10,250),V(3218,6,243)},
 {'Craftsmanship / Body forming wheel',V(3004,10,279),V(2992,6,271)},
 {'Craftsmanship / Tune calibration bench',V(2999,8,327),V(2992,6,323)},
 {'Craftsmanship / Photo light-control rig',V(3154,12,173),V(3171,11,187)},
 {'Craftsmanship / Owner handwork',V(3170,9,87),V(3160,6,82)},
 {'Craftsmanship / Client clubhouse entry',V(3049,8,26),V(3046,8,33)},
 {'Craftsmanship / Receiving mechanisms',V(3007,10,451),V(3020,4.5,445)},
 {'Craftsmanship / Operations joinery',V(3205,10,460),V(3218,7,470)},
 {'Craftsmanship / Central garden soundscape',V(3105,9,271),V(3105,4,252)},
}
local function view(n)
 index=(n-1)%#views+1;activeView=true;local v=views[index];local c=workspace.CurrentCamera;c.CameraType=Enum.CameraType.Scriptable;c.FieldOfView=64;c.CFrame=CFrame.lookAt(v[2],v[3]);journey:SetAttribute('SolidRoofRecommended',false);ui:SetAttribute('View',index);ui:SetAttribute('ViewTitle',v[1])
 local bar=journey:FindFirstChild('JourneyBar');if bar then bar.Visible=false end
 viewCaption.Text='  '..v[1]..'  ·  JOURNEY restores the pad slider';viewCaption.Visible=true
 -- See the hands/held object rather than the worker's back. Existing rig is the anchor.
 local actorName=({[1]='Mechanical_1',[2]='Body_Restoration_1',[4]='Paint_Exterior_1'})[index]
 local scene=root();local cast=scene and scene:FindFirstChild('EL_EverydayLife');cast=cast and cast:FindFirstChild('R6_Cast')
 local actor=cast and actorName and cast:FindFirstChild(actorName)
 if actor then local f=actor.Torso.CFrame;local offset=index==1 and CF(-6,2.5,-7)or CF(6,3,-12);c.CFrame=CFrame.lookAt((f*offset).Position,(f*CF(0,.3,-.6)).Position)end
 local nearest,dist;for _,a in records do if a.torso.Parent and a.torso.Transparency<.95 then local d=(a.torso.Position-v[3]).Magnitude;if not dist or d<dist then nearest=a;dist=d end end end
 if nearest then clock=(1.5-nearest.offset)%24 end
 local nextButton=ui:FindFirstChild('NextLife');if nextButton then nextButton.Text=string.format('%02d / %02d  NEXT',index,#views)end
end
local function open()
 generation+=1;local mine=generation;local s=pg:FindFirstChild('SellCarsV5ShopStories');if s and s:FindFirstChild('StoryAction')then s.StoryAction:Fire('CLOSE')end
 journey.ReviewAction:Fire('CHAPTER',240)
 task.spawn(function()local t=os.clock();repeat task.wait(.05);if mine~=generation then return end until(journey:GetAttribute('ShownStep')==240 and journey:GetAttribute('Phase')=='AFTER')or os.clock()-t>8;if journey:GetAttribute('ShownStep')==240 then view(1)end end)
end
button('OpenLife','SHOP LIFE',304,105,open)
button('NextLife','NEXT VIEW',417,105,function()if activeView then view(index+1)else open()end end)
local toggle;toggle=button('ToggleLife','ACTIVITY: ON',530,120,function()enabled=not enabled;toggle.Text=enabled and'ACTIVITY: ON'or'ACTIVITY: OFF';ui:SetAttribute('Enabled',enabled)end);ui:SetAttribute('Enabled',true)
local qa=Instance.new('BindableEvent');qa.Name='LifeAction';qa.Parent=ui;qa.Event:Connect(function(n,v)if n=='START'then open()elseif n=='VIEW'then view(v)elseif n=='OFF'then enabled=false;toggle.Text='ACTIVITY: OFF'elseif n=='ON'then enabled=true;toggle.Text='ACTIVITY: ON'end;ui:SetAttribute('Enabled',enabled)end)
local connections={}
table.insert(connections,game.UserInputService.WindowFocused:Connect(function()focused=true end));table.insert(connections,game.UserInputService.WindowFocusReleased:Connect(function()focused=false end))
table.insert(connections,journey:GetAttributeChangedSignal('Phase'):Connect(function()local p=journey:GetAttribute('Phase');if p=='LOADING'or p=='BENCHMARK'or p=='PAUSED'then activeView=false;viewCaption.Visible=false end end))
local hb=game.RunService.Heartbeat:Connect(function(dt)
 dtSum+=dt;if dtSum<.1 then return end;local tick=dtSum;dtSum=0;rescan+=tick
 local r=root();if r~=trackedRoot or(dirty and rescan>1)then discover(r);rescan=0 end
 local phase=journey:GetAttribute('Phase');local step=journey:GetAttribute('ShownStep')or 0;local s=pg:FindFirstChild('SellCarsV5ShopStories')
 local run=enabled and focused and(not s or s:GetAttribute('MotionEnabled')~=false)and(phase=='AFTER'or phase=='PAUSED')and step>0 and r~=nil
 if run then clock+=tick end
 local near={};local cam=workspace.CurrentCamera
 for _,a in records do if a.torso.Parent and a.torso.Transparency<.95 then local distance=(a.torso.Position-cam.CFrame.Position).Magnitude;if run and distance<75 then local t=(clock+a.offset)%24;if t<7 then table.insert(near,{a=a,t=t,d=distance})else reset(a,step)end else reset(a,step)end end end
 table.sort(near,function(a,b)return a.d<b.d end)
 for i,v in near do if i<=4 then render(v.a,step,v.t)else reset(v.a,step)end end
 ui:SetAttribute('ActiveActors',math.min(#near,4));ui:SetAttribute('Clock',clock)
end)
ui.Destroying:Connect(function()hb:Disconnect();if rootAdded then rootAdded:Disconnect();rootRemoving:Disconnect()end;for _,c in connections do c:Disconnect()end;for _,a in records do reset(a,journey:GetAttribute('ShownStep')or 240)end;local bar=journey:FindFirstChild('JourneyBar');if activeView and bar then bar.Visible=true end end)

