local M={RootName='CC05_CampusJoinery',Version='2026-09-09.CC05'}
function M.Build(root,reg,_,rec)
 local K=require(game.ServerStorage.SellCarsV5CraftsmanshipKit);local V,CF=K.V,K.CF;local p,rod,disc=K.part,K.rod,K.disc;local g,done=K.begin(root,reg,M.RootName,M.Version);local fid=root['10_Institution_Fidelity_R1'];local front=fid['11_Frontage04'];local room=K.find(front,'02_Shared_Customer_Room');local receiving=K.find(fid,'Covered_Receiving_And_Pallet_Jack');local office=K.find(fid,'Office_Rooms_And_Circulation');local hq=K.find(fid,'HQ_True_Entrance_Openings')
 g(221,'Client_Entry_Metalwork',room,function(m)
  for _,entryName in {'FrontEntry','NorthReceivingEntry','EastGalleryEntry'}do local entry=room[entryName];local east=entryName=='EastGalleryEntry'
   local lintel=entry.TimberEntryLintel;local f=lintel.CFrame*(east and CFrame.Angles(0,math.pi/2,0)or CF());local w=east and lintel.Size.Z or lintel.Size.X
   p(m,'RecessedPortalSoffit',f*CF(0,-.2,0),V(w,.06,.54),'gold')
   for _,name in {'LeftRecessedJamb','RightRecessedJamb'}do local q=entry[name];local j=q.CFrame*(east and CFrame.Angles(0,math.pi/2,0)or CF())
    p(m,'DeepFoldedEntryReturn',j*CF(0,0,.09),V(.19,q.Size.Y,.62),'black')
    for _,y in {-3.8,3.8}do disc(m,'PortalFlushFixing',j*CF(0,y,-.24),.085,.04,'gold')end
    p(m,'EntryKickProtection',j*CF(0,-4.1,-.27),V(.2,1.75,.06),'gold')
   end
   local glass=entry.HighClearTransom;local f2=glass.CFrame*(east and CFrame.Angles(0,math.pi/2,0)or CF());K.frame(m,f2,w-.35,glass.Size.Y,'gold')
  end
 end)
 g(202,'Receiving_Mechanism_And_Packing_Craft',receiving,function(m)
  for _,q in receiving:GetDescendants()do if q:IsA('BasePart')and q.Name=='Roller'then
   for _,x in {-2.55,2.55}do disc(m,'RollerCaptiveBearing',q.CFrame*CF(x,0,0)*CFrame.Angles(0,math.pi/2,0),.29,.1,'gold')end
  end end
  for _,z in {442.28,447.72}do p(m,'FoldedConveyorEdgeGuard',CF(3020,4.59,z),V(17,.55,.12),'steel');for _,x in {3012,3016,3020,3024,3028}do disc(m,'ConveyorGuardFixing',CF(x,4.55,z),.1,.07,'black')end end
  local jack=receiving.JackHydraulicBody
  rod(m,'JackChromePumpPiston',V(2993,3.7,456),V(2993,4.65,456),.19,'steel');disc(m,'TillerPivotBolt',CF(2993,4.9,456.5),.28,.42,'gold')
  for _,q in receiving:GetDescendants()do if q:IsA('BasePart')and q.Name=='PalletJackFork'then for _,z in {-2.6,2.6}do p(m,'ForkWearPad',q.CFrame*CF(0,.19,z),V(.85,.04,.35),'steel')end end end
  local pack=K.find(fid,'Kitting_Packing_And_Dispatch');local printer=pack.LabelPrinter
  p(m,'PrinterOutputMouth',printer.CFrame*CF(0,-.25,-printer.Size.Z/2-.025),V(1.35,.14,.05),'black')
  for i=0,8 do p(m,'ThermalJobLabelBarcode',pack.PrintedJobTicket.CFrame*CF(-.52+i*.13,.025,0),V(i%3==0 and .06 or .025,.012,.6),'black')end
 end)
 g(238,'Operations_Partition_Joinery',office,function(m)
  for _,q in office:GetDescendants()do if q:IsA('BasePart')and q.Name=='OfficeGlass'then
   local f=q.CFrame;K.frame(m,f*CF(0,0,-.13),q.Size.X,q.Size.Y,'wood')
   for _,x in {-q.Size.X/2+.17,q.Size.X/2-.17}do for _,y in {-q.Size.Y/2+.3,q.Size.Y/2-.3}do disc(m,'GlazingRetentionClip',f*CF(x,y,-.25),.12,.07,'steel')end end
  end end
 end)
 g(237,'HQ_Reception_Threshold_Craft',hq,function(m)
  for _,q in hq:GetChildren()do if q:IsA('BasePart')and q.Name=='DoorJamb'then
   p(m,'HQPortalRecessLining',q.CFrame*CF(0,0,.2),V(.4,q.Size.Y,.92),'wood',Enum.Material.Wood)
   for _,y in {-4.7,4.7}do disc(m,'HQPortalPinnedConnection',q.CFrame*CF(0,y,-.29),.12,.055,'gold')end
  end end
  local t=hq.LobbyThreshold;p(m,'InsetStoneThresholdStrip',t.CFrame*CF(0,t.Size.Y/2+.02,0),V(t.Size.X-.4,.035,.3),'gold')
  local l=hq.DoorLintel;p(m,'HQWarmSoffitInset',l.CFrame*CF(0,-.37,0),V(9.4,.045,.42),'cream',Enum.Material.Neon)
 end)
 return done()
end
return M

