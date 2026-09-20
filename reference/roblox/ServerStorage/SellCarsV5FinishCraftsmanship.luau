local M={RootName='CC02_FinishCraftsmanship',Version='2026-09-09.CC02'}
function M.Build(root,reg,_,rec)
 local K=require(game.ServerStorage.SellCarsV5CraftsmanshipKit);local V,CF=K.V,K.CF;local p,rod,disc,ring=K.part,K.rod,K.disc,K.ring;local g,done=K.begin(root,reg,M.RootName,M.Version)
 local fid=root['10_Institution_Fidelity_R1'];local wash=K.find(fid,'Reclaim_Filtration_And_Pump_Skid');local paint=K.find(fid,'Paint_Shaker_And_Match');local cart=K.find(fid,'Steam_And_Spot_Extraction_Cart')
 g(203,'Reclaim_Filter_Service_Interfaces',wash,function(m)
  for _,z in {129.5,137}do
   local f=CF(2990,8.99,z)*CFrame.Angles(math.pi/2,0,0)
   ring(m,'AccessLidRolledRim',f,1.34,.1,'steel',16)
   for i=0,7 do local a=i*math.pi/4;disc(m,'CaptiveLidBolt',f*CF(1.13*math.cos(a),1.13*math.sin(a),-.06),.12,.1,'gold')end
   for _,y in {3.8,7.4}do p(m,'SightGlassMountingClamp',CF(2992.67,y,z),V(.12,.16,.48),'steel')end
   for j=0,7 do p(m,'EtchedLevelGraduation',CF(2992.64,4.1+j*.42,z+.2),V(.035,.04,j%2==0 and .3 or .16),'cream')end
  end
  for _,z in {143.3,147.2}do
   ring(m,'CartridgeVBandClosure',CF(2991,7.35,z)*CFrame.Angles(math.pi/2,0,0),1.16,.1,'steel',16)
   p(m,'QuickReleaseClampLatch',CF(2992.22,7.35,z),V(.24,.3,.45),'gold')
   for _,y in {4,6.7}do p(m,'FilterServiceBracket',CF(2990.12,y,z),V(.4,.2,2.3),'steel')end
  end
  for _,z in {136.5,140.5}do
   for i=0,7 do local a=i*math.pi/4;disc(m,'PumpFlangeStud',CF(2999.41,3.88+.83*math.cos(a),z+.83*math.sin(a))*CFrame.Angles(0,math.pi/2,0),.11,.09,'gold')end
   for i=0,5 do p(m,'CouplingGuardVent',CF(2998.02+i*.1,4.3,z),V(.04,.04,.52),'black')end
  end
 end)
 local wall=root['05_Architecture_Massing']['02_Production'].Wash.OuterWall
 g(176,'Washable_Plant_Wall',wall,function(m)
  for i=0,7 do local z=126.5+i*5;p(m,'WetServicePanel',CF(2983.12,6.85,z),V(.12,8.7,4.84),'teal');p(m,'HygienicPanelJoint',CF(2983.21,6.85,z+2.43),V(.09,8.7,.07),'steel')end
  p(m,'RaisedCovedSplashSkirt',CF(2983.24,2.4,144),V(.28,.6,39),'steel')
 end)
 g(172,'Paint_Shaker_Clamp_And_Can',paint,function(m)
  -- Cylinder length is local X; inherit its actual rotated axis, not world X.
  local can=paint.PaintCan;for _,dx in {-1.18,1.18}do ring(m,'RolledCanSeam',can.CFrame*CF(dx,0,0)*CFrame.Angles(0,math.pi/2,0),1.06,.07,'steel',16)end
  for _,z in {321.25,324.75}do for i=0,9 do disc(m,'ClampLeadScrewThread',CF(3214.28+i*.28,5.23,z)*CFrame.Angles(0,math.pi/2,0),.35,.07,'steel')end end
  local f=CF(3213.17,5.23,323)*CFrame.Angles(0,math.pi/2,0);K.frame(m,f,4.2,3.5,'steel')
  for _,dy in {-1.5,1.5}do for _,dz in {-1.9,1.9}do disc(m,'GuardCaptiveFastener',CF(3213.05,5.23+dy,323+dz)*CFrame.Angles(0,math.pi/2,0),.11,.08,'gold')end end
 end)
 g(214,'Clean_Finish_Panel_Construction',root['05_Architecture_Massing']['02_Production'].Paint_Exterior.OuterWall,function(m)
  for i=0,9 do local z=302+i*6;p(m,'EnamelFinishWallCassette',CF(3226.87,8.35,z),V(.13,7.4,5.86),'cream');p(m,'SealedCassetteJoint',CF(3226.78,8.35,z+2.94),V(.07,7.4,.05),'stone')end
  p(m,'PaintUtilityCapping',CF(3226.68,12.14,331),V(.38,.16,63),'steel')
 end)
 g(216,'Extraction_Cart_Service_Detail',cart,function(m)
  for _,y in {3.25,6.53}do ring(m,'BoilerRolledServiceSeam',CF(3215,y,241)*CFrame.Angles(math.pi/2,0,0),1.6,.08,'steel',16)end
  for i=0,7 do local a=i*math.pi/4;disc(m,'BoilerCaptiveClosure',CF(3215+1.33*math.cos(a),6.88,241+1.33*math.sin(a))*CFrame.Angles(math.pi/2,0,0),.1,.1,'gold')end
  for _,z in {240.1,241.9}do p(m,'CartProtectiveRubberBumper',CF(3212.56,3.08,z),V(.16,.36,.5),'black')end
  p(m,'QuickCouplingSleeve',CF(3213.35,7.2,240.5),V(.22,.22,.48),'gold');rod(m,'WandRetentionClip',V(3212.4,6.4,241.5),V(3212.8,6.4,241.5),.07,'steel')
 end)
 g(216,'Neutral_Inspection_Wall',root['05_Architecture_Massing']['02_Production'].Detail_QC.OuterWall,function(m)
  for _,z in {243,251,263,275,283}do p(m,'InspectionWallVerticalReveal',CF(3226.88,7.25,z),V(.12,10.4,.2),'steel')end
  p(m,'CleanToolRail',CF(3226.7,5.6,263),V(.25,.2,49),'steel')
  for _,z in {245,267,281}do K.lamp(m,CF(3223,12.8,z),5,false);for _,dz in {-2,2}do rod(m,'InspectionLightHanger',V(3223,12.94,z+dz),V(3223,14.24,z+dz),.06,'steel')end end
 end)
 return done()
end
return M

