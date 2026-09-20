--!nocheck
return function(K,root,target,fn,change)
 local C=K.C;local V=Vector3.new;local roof=target.OpenCanopy;local wall=target.OuterWall
 local signData={
 Wash={"WASH","PREP  /  CLEAN  /  DRY",Color3.fromRGB(77,116,119)},
 Mechanical={"MECHANICAL","ENGINE  /  COOLING  /  FLUIDS",Color3.fromRGB(135,69,54)},
 Body_Restoration={"BODY & RESTORATION","DENTS  /  RUST  /  FRAME",Color3.fromRGB(151,111,63)},
 Tune_Performance={"TUNE & PERFORMANCE","WHEELS  /  STEERING  /  SUSPENSION",Color3.fromRGB(107,96,128)},
 Paint_Exterior={"PAINT & EXTERIOR","FINISH  /  GLASS  /  PERSONALITY",Color3.fromRGB(135,94,111)},
 Detail_QC={"DETAIL & QUALITY","FINISHING TOUCHES  /  FINAL CHECK",Color3.fromRGB(87,120,106)},
 Photo_Listing={"PHOTO & LISTING","PRESENT  /  PHOTOGRAPH  /  LIST",Color3.fromRGB(77,106,130)}
 }
 local d=assert(signData[fn]);local side=wall.Position.X<roof.Position.X and 1 or -1
 local cf=roof.CFrame;local w,h,depth=roof.Size.X,roof.Size.Y,roof.Size.Z
 local function part(p,n,x,y,z,sx,sy,sz,c,mat)return K.box(p,n,cf*CFrame.new(x,y,z),V(sx,sy,sz),c,mat)end
 if fn~="Mechanical"then
  local shell=K.group(root,"01_Envelope_Finish",fn,"Mature workshop canopy and edge finish")
  change(roof,{Color=C.charcoal,Material=Enum.Material.Metal,Reflectance=.025})
  for z=-depth/2+1,depth/2-1,4.5 do local seam=part(shell,"StandingSeam",0,h/2+.08,z,w-.4,.16,.16,C.edge);seam.CastShadow=false end
  for _,z in {-depth/2+.06,depth/2-.06}do part(shell,"FoldedSideFlashing",0,.1,z,w-.1,.92,.1,C.edge)end
  part(shell,"FrontDrip",side*(w/2-.03),h/2-.06,0,.12,.16,depth-.2,C.edge)
  local count=math.ceil((depth-2)/4);local span=(depth-2)/count
  for i=1,count do local z=-depth/2+1+(i-.5)*span
   part(shell,"WarmFasciaBoard",side*(w/2+.045),-.07,z,.09,.76,span-.14,C.wood,Enum.Material.Wood)
   part(shell,"WarmSoffitReturn",side*(w/2-1.1),-h/2-.03,z,2.15,.06,span-.14,C.wood,Enum.Material.Wood)
  end
  local id=K.group(root,"02_Department_Identity",fn,"Function identification and service position")
  for i=1,2 do local hdr=target["OpenPortal_"..i].PortalHeader
   local board=K.box(id,"BayIdentity_"..i,hdr.CFrame*CFrame.new(side*(hdr.Size.X/2+.055),0,0),V(.08,1.1,13.2),C.charcoal)
   K.text(board,d[1],i==1 and d[2]or"SECOND SERVICE POSITION",side==1 and Enum.NormalId.Right or Enum.NormalId.Left)
  end
 end
 local lining=K.group(root,"03_Service_Wall_Finish",fn,"Readable equipment backdrop and fitted service edge")
 change(wall,{Color=C.stone,Material=Enum.Material.Concrete})
 local wc=wall.CFrame;local wx=side*(wall.Size.X/2+.045)
 K.box(lining,"HardwearingKickPlate",wc*CFrame.new(wx,-wall.Size.Y/2+1.15,0),V(.07,1.7,wall.Size.Z-.2),C.charcoal)
 K.box(lining,"DepartmentServiceBand",wc*CFrame.new(wx,2.9,0),V(.08,.22,wall.Size.Z-.3),d[3])
 for z=-wall.Size.Z/2+2,wall.Size.Z/2-1,8 do
  K.box(lining,"PanelJoint",wc*CFrame.new(wx,.8,z),V(.05,7.4,.055),Color3.fromRGB(134,131,118))
 end
 -- A shallow, wall-supported service rail adds a utility reading, not equipment in a bay.
 K.box(lining,"UpperServiceRail",wc*CFrame.new(wx+.05*side,4.0,0),V(.15,.18,wall.Size.Z-.6),C.edge)
 for z=-wall.Size.Z/2+2,wall.Size.Z/2-1,10 do K.box(lining,"RailBracket",wc*CFrame.new(wx,4,z),V(.23,.6,.28),C.edge)end
 return K.stats(root)
end

