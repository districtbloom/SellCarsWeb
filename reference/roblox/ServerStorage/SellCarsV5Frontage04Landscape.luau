--!nocheck
-- F04-5 / customer frontage only. Native desert garden and crafted seat pockets.
-- The four-stud public walk Z-2..2, vehicle court and all rear routes stay clear.
-- No imported assets, lights, scripts, runtime seats or gameplay anchors.
return function(K, parent)
 local C,E,V,CF=K.C,Enum.Material,Vector3.new,CFrame.new
 local root=K.model(parent,"05_Frontage_Landscape","LANDSCAPE")
 root:SetAttribute("Version","2026-09-08.frontage04.f5.1")
 root:SetAttribute("FidelityBatch","F04_5")
 root:SetAttribute("Scope","Six bounded outer gateway, lounge and south canopy pockets only")
 root:SetAttribute("PhysicalFinishTop",.23)
 root:SetAttribute("PublicWalkClearZMin",-2)
 root:SetAttribute("PublicWalkClearZMax",2)
 local stone=C.stone:Lerp(C.paper,.15)
 local soil=C.gravel:Lerp(C.woodDark,.20)
 local blue=Color3.fromRGB(104,140,138)
 local count=0
 local function box(m,n,x,y,z,w,h,d,col,mat,solid)
  local p=K.box(m,n,x,y,z,w,h,d,col,mat,solid)
  p.CanTouch=false;p:SetAttribute("Frontage04Landscape",true)
  count+=1;return p
 end
 local function ball(m,n,pos,size,col,mat)
  local p=box(m,n,pos.X,pos.Y,pos.Z,size.X,size.Y,size.Z,col,mat,false)
  local mesh=Instance.new("SpecialMesh");mesh.MeshType=Enum.MeshType.Sphere;mesh.Parent=p
  p.CastShadow=false;return p
 end
 local function bar(m,n,a,b,d,col,mat)
  local p=box(m,n,0,0,0,(b-a).Magnitude,d,d,col,mat,false)
  p.Shape=Enum.PartType.Cylinder;p.CFrame=CFrame.lookAt((a+b)/2,b)*CFrame.Angles(0,math.pi/2,0)
  return p
 end
 -- A narrow two-wedge lance is a true pointed silhouette, not a colored block.
 -- Plant sizes and centres are inset well beyond the small wedge cross-section.
 local function lance(m,n,a,b,w,col)
  for _,sign in ipairs({-1,1})do
   local p=Instance.new("WedgePart");p.Name=n..(sign==1 and "_R" or "_L")
   p.Size=V(.035,w/2,(b-a).Magnitude)
   p.CFrame=CFrame.lookAt((a+b)/2,b)*CFrame.Angles(0,0,sign*math.pi/2)*CF(0,w/4,0)
   p.Color=col;p.Material=E.SmoothPlastic;p.Anchored=true
   p.CanCollide=false;p.CanTouch=false;p.CanQuery=true;p.CastShadow=false
   p:SetAttribute("Frontage04Landscape",true);p.Parent=m;count+=1
  end
 end
 local function agave(m,n,x,y,z,r)
  local g=K.model(m,n,"LANDSCAPE");local o=V(x,y+.06,z)
  g:SetAttribute("PlantType","Blue agave / radial bent pointed leaves")
  for i=1,11 do
   local a=i*2.39996;local up=i>7;local dir=V(math.cos(a),0,math.sin(a))
   local bend=o+dir*r*(up and .20 or .42)+V(0,r*(up and .78 or .55),0)
   local tip=o+dir*r*(up and .56 or 1)+V(0,r*(up and 1.2 or .28),0)
   local width=r*(up and .25 or .36);local col=i%3==0 and C.sage or blue
   lance(g,"FoldedLeafBase_"..i,bend,o,width,col)
   lance(g,"PointedLeafTip_"..i,bend,tip,width,col)
  end
  return g
 end
 local function grass(m,n,x,y,z,r)
  local g=K.model(m,n,"LANDSCAPE");local o=V(x,y,z)
  g:SetAttribute("PlantType","Dried native bunchgrass")
  for i=1,7 do local a=i*2.39996
   lance(g,"FineGrassFan_"..i,o,o+V(math.cos(a)*r,r*(1.4+(i%3)*.2),math.sin(a)*r),r*.20,i%3==0 and C.olive or C.pale)
  end
 end
 local function sage(m,n,x,y,z,r)
  local g=K.model(m,n,"LANDSCAPE")
  g:SetAttribute("PlantType","Low silver sage cushions")
  for i=1,4 do local a=i*2.39996
   ball(g,"SilverSageCluster_"..i,V(x+math.cos(a)*r*.25,y+r*(.40+(i%2)*.12),z+math.sin(a)*r*.25),V(r*1.0,r*.85,r*.9),i%2==0 and C.sage or C.olive,E.Grass)
  end
 end
 local function yucca(m,n,x,y,z,mirror)
  local g=K.model(m,n,"LANDSCAPE")
  g:SetAttribute("PlantType","Two-crown desert yucca / fibrous trunk")
  local o=V(x,y,z);local c1=o+V(.12,5.4,.08);local c2=o+V(mirror*.47,4.15,.40)
  bar(g,"FibrousMainTrunk",o,c1,.34,C.bark,E.Wood)
  bar(g,"ForkedSideTrunk",o+V(.05,2.65,.04),c2,.24,C.bark,E.Wood)
  for i=1,6 do
   local p=box(g,"OldLeafScar_"..i,x,y+i*.52,z,.39,.10,.38,C.woodDark,E.Wood,false)
   p.CFrame*=CFrame.Angles(0,i*.72,.08)
  end
  for k,crown in ipairs({c1,c2})do
   for i=1,10 do local a=i*2.39996+k*.71
    lance(g,"SpikedCrown_"..k.."_"..i,crown,crown+V(math.cos(a)*1.15,(i%3-1)*.65,math.sin(a)*1.15),.27,i%3==0 and C.pale or C.olive)
   end
  end
 end
 local function pocket(name,x0,z0,x1,z1,h)
  local g=K.model(root,name,"LANDSCAPE")
  for k,v in pairs({PocketXMin=x0,PocketXMax=x1,PocketZMin=z0,PocketZMax=z1})do g:SetAttribute(k,v)end
  local x,z,w,d=(x0+x1)/2,(z0+z1)/2,x1-x0,z1-z0
  box(g,"GroundedLimestoneBase",x,.23+h/2,z,w,h,d,stone,E.Limestone,true)
  box(g,"RecessedDesertGravel",x,.23+h+.012,z,w-.32,.055,d-.32,soil,E.Pebble,false)
  for _,s in ipairs({-1,1})do
   box(g,"StoneCopingX_"..s,x+s*(w/2-.12),.23+h+.04,z,.24,.12,d,stone,E.Limestone,false)
   box(g,"StoneCopingZ_"..s,x,.23+h+.04,z+s*(d/2-.12),w-.3,.12,.24,stone,E.Limestone,false)
   box(g,"StoneCourseJoint_"..s,x,.23+h*.45,z+s*(d/2-.006),w-.05,.026,.02,C.woodDark,E.Concrete,false)
  end
  return g,.23+h+.045
 end
 local function stones(m,x,y,z,s)
  for i=1,3 do local a=i*2.39996
   local p=ball(m,"WeatheredLimestone_"..i,V(x+math.cos(a)*s*.48,y+s*.18,z+math.sin(a)*s*.45),V(s*.68,s*.42,s*.56),stone,E.Limestone)
   p.CFrame*=CFrame.Angles(.12,a,.08)
  end
 end
 -- These beds sit OUTSIDE both gateway feet, never inside the axial opening.
 for i,q in ipairs({{3108.4,3113.6,1},{3149.4,3154.6,-1}})do
  local x=(q[1]+q[2])/2;local g,y=pocket("Gateway_Desert_Garden_"..i,q[1],-12.5,q[2],-5.5,.52)
  yucca(g,"YuccaLandmark",x,y,-10.1,q[3])
  agave(g,"AgaveAtArrival",x-q[3]*.66,y,-7.25,.93)
  sage(g,"LowSageShoulder",x+q[3]*1.35,y,-7.0,.70)
  grass(g,"GoldenGrass",x-q[3]*1.23,y,-11.55,.56)
  stones(g,x+q[3]*1.10,y,-11.85,.54)
 end
 -- Tiny bespoke planter-benches flank the lounge entrance, not the front door.
 -- Benches face the street, with planting at one end; no seats add runtime touch.
 for i,q in ipairs({{3061.2,3065.8,1},{3078.2,3082.8,-1}})do
  local x0,x1,side=q[1],q[2],q[3];local x=(x0+x1)/2
  local g,y=pocket("Lounge_Planter_Bench_"..i,x0,2.25,x1,4.85,.36)
  local px=x+side*1.20;local sx=x-side*.85
  box(g,"RaisedPlantCell",px,.23+.72,3.55,1.62,1.44,2.28,stone,E.Limestone,true)
  box(g,"PlantCellGravel",px,1.68,3.55,1.38,.065,2.03,soil,E.Pebble,false)
  agave(g,"SmallSculpturalAgave",px,1.715,3.55,.59)
  for _,dx in ipairs({-.67,.67})do
   box(g,"BenchSteelBearer_"..dx,sx+dx,1.53,3.55,.14,.20,2.08,C.steel,E.Metal,false)
   box(g,"BenchGroundedLeg_"..dx,sx+dx,.89,3.55,.16,1.32,.30,C.steel,E.Metal,true)
  end
  for j=1,5 do
   box(g,"OiledTimberSeatSlat_"..j,sx,1.73,2.67+(j-1)*.43,1.90,.20,.37,j%3==0 and C.woodDark or C.wood,E.Wood,true)
  end
  for _,dx in ipairs({-.63,.63})do
   box(g,"SeatCapFastener_"..dx,sx+dx,1.837,2.72,.075,.014,.075,C.steel,E.Metal,false)
  end
 end
 -- Low south-end punctuation leaves a clear public path in front and does not
 -- wrap around column feet, the first car buffers (Z6+) or browsing walks.
 for i,q in ipairs({{3091,3097},{3161,3167}})do
  local g,y=pocket("Sales_Canopy_Low_Garden_"..i,q[1],2.3,q[2],4.9,.43)
  local x=(q[1]+q[2])/2
  agave(g,"CanopyBlueAgave",x-.65,y,3.6,.87)
  sage(g,"SilverSage",x+1.87,y,3.65,.67)
  grass(g,"FineGrassAccent",x-2.10,y,3.55,.49)
  stones(g,x+.90,y,3.52,.41)
 end
 root:SetAttribute("NativeLandscapePartCount",count)
 root:SetAttribute("LandscapePocketCount",6)
 root:SetAttribute("RuntimeSeatCount",0)
 return root
end

