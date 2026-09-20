local M={RootName='CC04_PersonalCraftsmanship',Version='2026-09-09.CC04'}
function M.Build(root,reg,_,rec)
 local K=require(game.ServerStorage.SellCarsV5CraftsmanshipKit);local V,CF=K.V,K.CF;local p,rod,disc=K.part,K.rod,K.disc;local g,done=K.begin(root,reg,M.RootName,M.Version);local fid=root['10_Institution_Fidelity_R1'];local photo=K.find(fid,'05_Photo');local bench=K.find(fid,'Owner_Craft_Bench')
 g(217,'Editorial_Rig_And_Light_Control',photo,function(m)
  for _,studio in photo:GetChildren()do if studio.Name:match('Editorial_Turntable_Studio')then
   for _,q in studio:GetDescendants()do
    if q:IsA('BasePart')and q.Name=='SoftboxFabricDiffuser'then
     -- Shallow egg-crate grid sits against the existing diffusion surface.
     for i=-2,2 do p(m,'SoftboxFabricLouvre',q.CFrame*CF(i*.73,0,-.07),V(.035,2.63,.14),'black')end
     for i=-1,1 do p(m,'SoftboxHorizontalLouvre',q.CFrame*CF(0,i*.73,-.07),V(4.1,.035,.14),'black')end
    elseif q:IsA('BasePart')and q.Name=='CameraLensBarrel'then
     for _,x in {-.37,0,.37}do K.ring(m,'KnurledFocusCollar',q.CFrame*CF(x,0,0)*CFrame.Angles(0,math.pi/2,0),.45,.04,'black',12)end
    elseif q:IsA('BasePart')and q.Name=='OverheadDiffusionSail'then
     local f=q.CFrame;for _,x in {-6.65,6.65}do p(m,'SailExtrusionEdge',f*CF(x,.18,0),V(.12,.18,14.3),'steel')end
     for _,z in {-7.1,7.1}do p(m,'SailCrossEdge',f*CF(0,.18,z),V(13.4,.18,.12),'steel')end
     for _,x in {-6.3,6.3}do for _,z in {-6.5,6.5}do rod(m,'SailSafetySuspension',f:PointToWorldSpace(V(x,.27,z)),f:PointToWorldSpace(V(x,1.65,z)),.055,'steel')end end
    elseif q:IsA('BasePart')and q.Name=='BackdropRearUpright'then
     for _,y in {-2.5,2.5}do p(m,'BackdropLockingCollar',q.CFrame*CF(0,y,0),V(.52,.18,.52),'black')end
    end
   end
  end end
 end)
 g(225,'Owner_Vise_And_Rotor_Craft',bench,function(m)
  for _,name in {'ViseFixedJaw','ViseSlidingJaw'}do local q=bench[name]
   -- Copper soft jaws preserve machined finishes; the inherited vise remains.
   p(m,'ReplaceableCopperSoftJaw',q.CFrame*CF(0,.32,0),V(q.Size.X,.08,q.Size.Z+.05),'gold')
   for _,dx in {-.55,.55}do disc(m,'SoftJawFixing',q.CFrame*CF(dx,.38,0)*CFrame.Angles(math.pi/2,0,0),.09,.05,'steel')end
  end
  local screw=bench.ViseLeadScrew;for i=0,10 do disc(m,'ViseScrewMachinedThread',screw.CFrame*CF(-.95+i*.18,0,0)*CFrame.Angles(0,math.pi/2,0),.31,.055,'steel')end
  local base=bench.BenchViseBase;for _,x in {-.66,.66}do for _,z in {-.59,.59}do disc(m,'ViseSwivelBaseBolt',base.CFrame*CF(x,.24,z)*CFrame.Angles(math.pi/2,0,0),.15,.1,'steel')end end
  local q=bench.BrakeCaliperSample;for _,dy in {-.28,.28}do disc(m,'CaliperPistonStudy',CF(q.Position+V(.29,dy,0))*CFrame.Angles(0,math.pi/2,0),.37,.1,'steel')end
  local top=bench.ToolBenchTop
  -- Edge strip follows actual rotated top; local X is the long dimension.
  p(m,'RepairedWorkbenchEdgeBand',top.CFrame*CF(0,-.1,-top.Size.Z/2-.05),V(top.Size.X,.32,.1),'wood',Enum.Material.Wood)
  for _,x in {-4.8,-2.4,0,2.4,4.8}do disc(m,'WorkbenchRepairScrew',top.CFrame*CF(x,-.1,-top.Size.Z/2-.12),.09,.055,'steel')end
 end)
 g(225,'Personal_Bench_Task_Light',bench,function(m)
  K.lamp(m,CF(3160.4,11.4,82),9,true)
  for _,z in {78,86}do rod(m,'BenchLightWallBracket',V(3158.72,11.52,z),V(3160.4,11.52,z),.09,'steel')end
 end)
 return done()
end
return M

