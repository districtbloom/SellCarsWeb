-- CIRC02 manual Studio/Edit kinematic replay; never a live vehicle controller.
local M={};local V=Vector3.new;local session;local generation=0
function M.CanBegin(leg,occupied)
 if leg=='arrival'then return not occupied.intake
 elseif leg=='work'then return not occupied.shared
 elseif leg=='sales'then return not occupied.sales and not occupied.apron
 elseif leg=='exit'then return not occupied.intake and not occupied.apron end
 return false
end
function M.Status()
 if not session then return {running=false,phase='stopped'}end
 return {running=session.running,phase=session.phase,waiting=session.waiting,step=session.step,completed=session.completed,position=session.car and session.car:GetPivot().Position,occupied=table.clone(session.occupied),error=session.error}
end
function M.SetOccupied(name,value)
 assert(session,'Start the replay first');assert(name=='intake'or name=='shared'or name=='sales'or name=='apron','Unknown reservation');session.occupied[name]=value==true
end
function M.Stop()
 generation+=1;local s=session;session=nil
 if not s then return end
 s.running=false
 for p,t in s.hidden do if p.Parent then p.Transparency=t end end
 if s.car then s.car:Destroy()end
 if s.api.Status().step==s.step then s.api.SetStep(s.beforeStep)end
 if workspace.CurrentCamera then workspace.CurrentCamera.CFrame=s.camera;workspace.CurrentCamera.FieldOfView=s.fov end
end
function M.Start(step,options)
 assert(game.RunService:IsStudio()and not game.RunService:IsRunning(),'Manual replay: use Edit mode')
 assert(type(step)=='number'and step%1==0 and step>=2 and step<=24,'Choose Birth step2–24')
 M.Stop();options=options or{};generation+=1;local token=generation
 local api=require(game.ServerStorage.SellCarsV5FullJourneyComposer);local root=workspace.SellCars_Dealership_FullJourney
 local s={api=api,beforeStep=api.Status().step,step=step,running=true,completed=0,phase='starting',waiting=false,hidden={},occupied=table.clone(options.occupied or{}),camera=workspace.CurrentCamera.CFrame,fov=workspace.CurrentCamera.FieldOfView};session=s
 api.SetStep(step)
 -- The static sale prop represents this same demonstration car, not another occupied slot.
 for _,p in root:GetDescendants()do if p:IsA('BasePart')then
  if p:GetFullName():find('.SalesCar_3.',1,true)then s.hidden[p]=p.Transparency;p.Transparency=1
  elseif p.Transparency<.75 and p.Position.X>3000 and p.Position.X<3090 and p.Position.Z>110 and p.Position.Z<152 and p.Position.Y>9 and p.Size.X>8 and p.Size.Z>8 then s.hidden[p]=p.Transparency;p.Transparency=.75 end
 end end
 local car=Instance.new('Model');car.Name='CIRC02_Temporary_Route_Proxy';s.car=car
 local function part(name,size,cf,color)
  local p=Instance.new('Part');p.Name=name;p.Size=size;p.CFrame=cf;p.Color=color;p.Material=Enum.Material.SmoothPlastic;p.Anchored=true;p.CanCollide=false;p.CanQuery=false;p.CanTouch=false;p.Parent=car;return p
 end
 local body=part('ProxyBody',V(10.58,2.3,18.94),CFrame.new(0,-1.3,0),Color3.fromRGB(226,163,55));car.PrimaryPart=body
 part('Cab',V(8,2.5,9),CFrame.new(0,1,0),Color3.fromRGB(52,85,95))
 part('Front',V(8,.35,.2),CFrame.new(0,-.9,-9.5),Color3.fromRGB(240,233,192))
 for _,x in {-4.85,4.85}do for _,z in {-6.1,6.1}do local p=part('Wheel',V(.85,2.2,2.2),CFrame.new(x,-2.3,z),Color3.fromRGB(30,32,32));p.Shape=Enum.PartType.Cylinder end end
 -- Pivot is the envelope centre, independent of PrimaryPart/body offset.
 car.WorldPivot=CFrame.new();car.PrimaryPart=nil;car.Parent=workspace
 local gui=Instance.new('BillboardGui');gui.Size=UDim2.fromOffset(310,58);gui.StudsOffsetWorldSpace=V(0,6,0);gui.AlwaysOnTop=true;gui.Adornee=body;gui.Parent=body
 local label=Instance.new('TextLabel');label.Size=UDim2.fromScale(1,1);label.BackgroundColor3=Color3.fromRGB(20,24,27);label.BackgroundTransparency=.15;label.TextColor3=Color3.new(1,1,1);label.TextSize=16;label.Font=Enum.Font.GothamBold;label.Parent=gui
 workspace.CurrentCamera.CFrame=CFrame.lookAt(V(3130,102,18),V(3040,2,98));workspace.CurrentCamera.FieldOfView=65
 local routes=require(game.ServerStorage.SellCarsV5BirthCirculationRoutes).Build();car:PivotTo(routes.arrival[1])
 task.spawn(function()
  local ok,err=pcall(function()
   for _,leg in {'arrival','work','sales','exit'}do
    if leg=='work'and step<3 then break end;if leg=='sales'and step<6 then break end
    s.phase=leg
    while not M.CanBegin(leg,s.occupied)do
     if generation~=token then return end
     if api.Status().step~=step then M.Stop();return end
     s.waiting=true;label.Text='WAIT · '..leg:upper()..'\nDestination / shared apron occupied';task.wait(.05)
    end
    s.waiting=false;label.Text=leg:upper()..' · BIRTH '..step..'\nKinematic route preview'
    local poses=routes[leg];local distance=0;local lengths={0}
    for i=2,#poses do distance+=(poses[i].Position-poses[i-1].Position).Magnitude;lengths[i]=distance end
    local travelled=0;local i=1;local speed=math.clamp(options.speed or 18,4,45)
    while travelled<distance do
     if generation~=token then return end
     if api.Status().step~=step then M.Stop();return end
     travelled=math.min(distance,travelled+game.RunService.Heartbeat:Wait()*speed)
     while i<#poses-1 and lengths[i+1]<=travelled do i+=1 end
     local span=lengths[i+1]-lengths[i];car:PivotTo(poses[i]:Lerp(poses[i+1],span>0 and(travelled-lengths[i])/span or 1))
    end
    s.completed+=1;task.wait(.8)
   end
   if generation==token then s.phase='complete';s.running=false;label.Text='BIRTH ROUTE COMPLETE\n4 legs at6+ · no steering-physics claim' end
  end)
  if not ok and generation==token then s.error=tostring(err);s.phase='error';s.running=false;label.Text='REPLAY ERROR · use Stop()' end
 end)
 return M.Status()
end
return M

