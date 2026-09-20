local M={RootName='CC03_FabricationCraftsmanship',Version='2026-09-09.CC03'}
function M.Build(root,reg,_,rec)
 local K=require(game.ServerStorage.SellCarsV5CraftsmanshipKit);local V,CF=K.V,K.CF;local p,rod,disc,ring=K.part,K.rod,K.disc,K.ring;local g,done=K.begin(root,reg,M.RootName,M.Version)
 local fid=root['10_Institution_Fidelity_R1'];local wheel=K.find(fid,'English_Wheel_And_Planishing');local ecu=K.find(fid,'ECU_And_Sensor_Calibration_Bench')
 g(209,'English_Wheel_Fabricated_Details',wheel,function(m)
  for _,z in {270.12,271.88}do
   p(m,'LaminatedFrameSidePlate',CF(2988.1,6.5,z),V(1.58,6.9,.14),'oxide')
   p(m,'UpperArmFishplate',CF(2990.9,9.63,z),V(5.9,.94,.14),'oxide')
   for _,y in {3.65,5.3,7.2,9.3}do disc(m,'FrameThroughBolt',CF(2988.1,y,z),.19,.16,'steel')end
   for _,x in {2989.3,2991,2993.2}do disc(m,'UpperArmBolt',CF(x,9.64,z),.16,.16,'steel')end
  end
  for _,n in {'PolishedUpperWheel','LowerAnvilWheel'}do local q=wheel[n];for _,sign in {-1,1}do disc(m,'WheelBearingCap',q.CFrame*CF(sign*(q.Size.X/2+.04),0,0)*CFrame.Angles(0,math.pi/2,0),.42,.12,'gold')end end
  for i=0,7 do disc(m,'FineAnvilAdjustmentThread',CF(2993.2,4.42+i*.14,271)*CFrame.Angles(math.pi/2,0,0),.4,.055,'steel')end
  ring(m,'RolledAdjustmentHandwheel',CF(2993.2,3.48,271)*CFrame.Angles(math.pi/2,0,0),1.04,.1,'steel',16)
  -- A gently formed sheet, with the existing cradle and throat clearance retained.
  K.retire(rec,wheel.AluminiumWorkpiece,209)
  for i=0,8 do local z=-1.24+i*.31;local y=6.19+.12*(z/1.24)^2;p(m,'WheeledAluminiumPanelStrip',CF(2994.55,y,271+z)*CFrame.Angles(.18*z,0,-.025),V(4.4,.06,.33),'steel')end
 end)
 g(210,'Oscilloscope_And_ECU_Interfaces',ecu,function(m)
  local f=CF(2991.675,6.28,324)*CFrame.Angles(0,-math.pi/2,0)
  for i=-2,2 do p(m,'ScopeHorizontalGraticule',f*CF(0,i*.16,-.014),V(1.28,.013,.018),'teal')end
  for i=-3,3 do p(m,'ScopeVerticalGraticule',f*CF(i*.18,0,-.014),V(.013,.84,.018),'teal')end
  for i=0,17 do local x=-.6+i*.07;local nx=x+.07;rod(m,'FrozenCalibrationTrace',f:PointToWorldSpace(V(x,.25*math.sin(i*.58),-.025)),f:PointToWorldSpace(V(nx,.25*math.sin((i+1)*.58),-.025)),.027,'cream')end
  for _,z in {323.85,324.15,324.45}do disc(m,'ScopeProbeSocket',CF(2991.68,5.55,z)*CFrame.Angles(0,math.pi/2,0),.14,.07,'gold')end
  for i=0,5 do p(m,'ECUConnectorLockingPin',CF(2994.45,5.85,321.47+i*.2),V(.14,.09,.055),'gold')end
  for _,z in {321.15,322.85}do for _,x in {2992.6,2993.8}do disc(m,'ECUCaseFastener',CF(x,6.16,z)*CFrame.Angles(math.pi/2,0,0),.09,.06,'steel')end end
  p(m,'ESDEarthTerminal',CF(2994.25,5.49,325.8),V(.35,.07,.35),'gold');rod(m,'BenchBondingLead',V(2994.25,5.49,325.8),V(2994.7,3.7,326.6),.045,'black')
 end)
 g(211,'Acoustic_Service_Wall',root['05_Architecture_Massing']['02_Production'].Tune_Performance.OuterWall,function(m)
  for _,z in {310,318,331,341,351}do
   p(m,'AcousticPanelBacking',CF(2983.11,8.5,z),V(.12,6.4,5.6),'black')
   for i=0,8 do p(m,'SlottedAcousticTimber',CF(2983.23,8.5,z-2.5+i*.62),V(.15,6.4,.16),'wood',Enum.Material.Wood)end
  end
 end)
 g(209,'Body_Fabrication_Wall_Joints',root['05_Architecture_Massing']['02_Production'].Body_Restoration.OuterWall,function(m)
  for _,z in {237,248,260,276,287}do p(m,'SteelServiceWallRib',CF(2983.16,7.5,z),V(.24,10.7,.32),'oxide');for _,y in {3,12}do disc(m,'WallRibAnchor',CF(2983.34,y,z)*CFrame.Angles(0,math.pi/2,0),.18,.09,'steel')end end
  for _,z in {245,270}do K.lamp(m,CF(2991,12.7,z),5,false);rod(m,'FabricationTaskLightStem',V(2991,12.83,z),V(2991,14.25,z),.09,'steel')end
 end)
 return done()
end
return M

