--!nocheck
-- Small native art kit for additive Campus03. All dimensions in studs.
local K={Version="2026-09-08.campus03.2"}
local V,CF=Vector3.new,CFrame.new
K.C={steel=Color3.fromRGB(44,49,46),wood=Color3.fromRGB(172,124,74),woodDark=Color3.fromRGB(130,92,55),stone=Color3.fromRGB(190,175,141),gravel=Color3.fromRGB(161,145,111),sage=Color3.fromRGB(105,124,101),olive=Color3.fromRGB(106,117,70),pale=Color3.fromRGB(160,161,108),bark=Color3.fromRGB(111,90,65),warm=Color3.fromRGB(255,207,135),black=Color3.fromRGB(29,34,32),paper=Color3.fromRGB(218,211,186),navy=Color3.fromRGB(43,67,76)}
local C=K.C
function K.model(parent,name,role,fn)
 local m=Instance.new("Model");m.Name=name
 for k,v in {BundleId="Institution.Campus03."..name,FunctionId=fn or "Campus",PhaseMin="INSTITUTION",AssetStatus="SOURCE_BUILT_VISUAL_PROXY",FidelityRole=role or "STORY",SourceOwned=true,SourceGeometry="DETERMINISTIC_NATIVE_GEOMETRY",InheritanceRule="ADDITIVE",FinalDetailIntent=name}do m:SetAttribute(k,v)end
 m.Parent=parent;return m
end
function K.box(m,n,x,y,z,w,h,d,col,mat,solid)
 local p=Instance.new("Part");p.Name=n;p.Size=V(w,h,d);p.CFrame=CF(x,y,z);p.Anchored=true;p.Color=col or C.steel;p.Material=mat or Enum.Material.SmoothPlastic
 p.CanCollide=solid==true;p.CanQuery=true;p.CanTouch=false;p.CastShadow=true;p.TopSurface=0;p.BottomSurface=0;p.Parent=m;return p
end
function K.bar(m,n,a,b,diameter,col,mat,solid)
 local p=K.box(m,n,0,0,0,(b-a).Magnitude,diameter,diameter,col,mat or Enum.Material.Metal,solid)
 p.Shape=Enum.PartType.Cylinder;p.CFrame=CFrame.lookAt((a+b)/2,b)*CFrame.Angles(0,math.pi/2,0);return p
end
function K.meshBall(m,n,p,size,col,mat)
 local q=K.box(m,n,p.X,p.Y,p.Z,size.X,size.Y,size.Z,col,mat,false)
 local mesh=Instance.new("SpecialMesh");mesh.MeshType=Enum.MeshType.Sphere;mesh.Parent=q;return q
end
local function leaf(m,n,a,b,w,col)
 for _,sign in {-1,1}do
  local p=Instance.new("WedgePart");p.Name=n;p.Size=V(.065,w/2,(b-a).Magnitude);p.CFrame=CFrame.lookAt((a+b)/2,b)*CFrame.Angles(0,0,sign*math.pi/2)*CF(0,w/4,0)
  p.Color=col;p.Material=Enum.Material.SmoothPlastic;p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=true;p.CastShadow=false;p.Parent=m
 end
end
function K.agave(m,n,x,y,z,s)
 local g=K.model(m,n,"LANDSCAPE","EstateLandscape");local o=V(x,y+.12*s,z)
 for i=1,13 do
  local a=i*2.39996;local upright=i>8;local dir=V(math.cos(a),0,math.sin(a));local r=(upright and 1.45 or 2.4)*s
  local bend=o+dir*(upright and .58 or 1.1)*s+V(0,(upright and 1.65 or 1.25)*s,0)
  local tip=o+dir*r+V(0,(upright and 2.85 or .75)*s,0)
  local col=i%3==0 and C.sage or Color3.fromRGB(111,143,143)
  local width=(upright and .66 or 1.0)*s
  leaf(g,"UprightBladeBase_"..i,bend,o,width,col)
  leaf(g,"TaperedBladeTip_"..i,bend,tip,width,col)
 end
 return g
end
function K.grass(m,n,x,y,z,s)
 local g=K.model(m,n,"LANDSCAPE","EstateLandscape");local o=V(x,y,z)
 for i=1,11 do local a=i*2.39996
  leaf(g,"GrassFan_"..i,o,o+V(math.cos(a)*1.3*s,(1.2+(i%3)*.35)*s,math.sin(a)*1.3*s),.46*s,i%3==0 and C.olive or C.pale)
 end
 return g
end
function K.rock(m,n,x,y,z,s)
 local p=K.meshBall(m,n,V(x,y+s*.36,z),V(s*1.4,s*.8,s),C.stone,Enum.Material.Limestone)
 p.CFrame*=CFrame.Angles(.2,(x+z)%6,.12);return p
end
function K.shrub(m,n,x,y,z,s)
 local g=K.model(m,n,"LANDSCAPE","EstateLandscape")
 for i=1,5 do local a=i*2.39996;local p=K.meshBall(g,"SageCushion_"..i,V(x+math.cos(a)*s*.5,y+s*(.4+(i%2)*.16),z+math.sin(a)*s*.5),V(s*1.3,s*.9,s*1.25),i%2==0 and C.sage or C.olive,Enum.Material.Grass);p.CastShadow=false end
 return g
end
function K.yucca(m,n,x,y,z,s)
 local g=K.model(m,n,"LANDSCAPE","EstateLandscape");local o=V(x,y,z)
 local stems={{0,0,0,.1,7,0,.72},{0,3,0,-1.45,5.8,.75,.5},{0,4.6,0,1.5,8.6,-.5,.46}}
 for i,q in stems do K.bar(g,"Branch_"..i,o+V(q[1],q[2],q[3])*s,o+V(q[4],q[5],q[6])*s,q[7]*s,C.bark,Enum.Material.Wood,true)end
 for k,q in {{.1,7,0},{-1.45,5.8,.75},{1.5,8.6,-.5}}do
  local crown=o+V(unpack(q))*s
  for i=1,15 do local a=i*2.39996+k*.7;leaf(g,"Crown_"..k.."_"..i,crown,crown+V(math.cos(a)*2.4*s,(i%3-1)*1.25*s,math.sin(a)*2.4*s),.65*s,i%3==0 and C.pale or C.olive)end
 end
 return g
end
function K.tree(m,n,x,y,z,s)
 local g=K.model(m,n,"LANDSCAPE","EstateLandscape");local o=V(x,y,z)
 K.bar(g,"Trunk",o,o+V(.2,6,0)*s,.9*s,C.bark,Enum.Material.Wood,true)
 for i=1,6 do local a=i*2.39996;local tip=o+V(math.cos(a)*3.9,9.2+(i%3),math.sin(a)*3.5)*s
  K.bar(g,"OpenBranch_"..i,o+V(.2,4.5+i*.2,0)*s,tip,.32*s,C.bark,Enum.Material.Wood,true)
  for j=1,7 do local t=j*2.39996;local pos=tip+V(math.cos(t)*1.6*s,math.sin(j)*.4*s,math.sin(t)*1.4*s)
   local p=K.meshBall(g,"LeafSpray_"..i.."_"..j,pos,V(3.2,.75,2.2)*s,j%3==0 and C.pale or C.olive,Enum.Material.Grass);p.CFrame*=CFrame.Angles(.1,t,.1);p.CastShadow=false
  end
 end
 return g
end
function K.cactus(m,n,x,y,z,s)
 local g=K.model(m,n,"LANDSCAPE","EstateLandscape");local o=V(x,y,z)
 K.bar(g,"RootedStem",o,o+V(0,4.5*s,0),.58*s,C.sage,nil,true)
 for i,q in {{0,1.5,0},{-.75,3,.05},{.7,4,.04},{-.9,5.2,0},{.6,6.1,.02}}do
  local p=K.meshBall(g,"PricklyPearPad_"..i,o+V(q[1],q[2],q[3])*s,V(1.4,2,.4)*s,i%2==0 and C.olive or C.sage);p.CFrame*=CFrame.Angles(0,.35,(i%3-1)*.28)
 end;return g
end
function K.planter(m,n,x,y,z,w,d,h)
 local g=K.model(m,n,"LANDSCAPE","Campus")
 K.box(g,"GroundedCore",x,y+h/2,z,w,h,d,C.stone,Enum.Material.Limestone,true)
 K.box(g,"WarmGravel",x,y+h+.018,z,w-.55,.055,d-.55,C.gravel,Enum.Material.Pebble,false)
 for _,sign in {-1,1}do
  K.box(g,"SteelRimX",x+sign*(w/2-.09),y+h+.07,z,.18,.18,d,C.steel,Enum.Material.Metal,false)
  K.box(g,"SteelRimZ",x,y+h+.07,z+sign*(d/2-.09),w-.3,.18,.18,C.steel,Enum.Material.Metal,false)
  local count=math.max(1,math.floor(w/3))
  for i=1,count-1 do K.box(g,"StoneJoint",x-w/2+i*w/count,y+h*.48,z+sign*(d/2+.006),.035,h*.86,.018,C.woodDark,Enum.Material.Concrete,false).CastShadow=false end
 end;return g
end
function K.bench(m,n,x,y,z,w,yaw)
 local g=K.model(m,n,"SUPPORT","Campus");local pivot=CF(x,y,z)*CFrame.Angles(0,math.rad(yaw or 0),0)
 local function b(name,a,b,c,ww,hh,dd,col,mat,solid)
  local p=K.box(g,name,0,0,0,ww,hh,dd,col,mat,solid);p.CFrame=pivot*CF(a,b,c);return p
 end
 for _,dx in {-w*.36,w*.36}do
  for _,dz in {-.8,.8}do b("AnchoredLeg",dx,.89,dz,.24,1.78,.25,C.steel,Enum.Material.Metal,true)end
  b("SeatBearer",dx,1.66,0,.3,.24,2.55,C.steel,Enum.Material.Metal,true)
  b("BackUpright",dx,2.25,-1.12,.22,2,.22,C.steel,Enum.Material.Metal,true)
 end
 for j=0,5 do b("TimberSlat_"..j,0,1.9,-1.05+j*.42,w,.22,.37,j%3==0 and C.woodDark or C.wood,Enum.Material.Wood,true)end
 for j=0,2 do b("BackSlat_"..j,0,2.5+j*.32,-1.15,w,.27,.2,C.wood,Enum.Material.Wood,true)end
 local seat=Instance.new("Seat");seat.Name="RestSeat";seat.Size=V(2.4,.06,1.8);seat.CFrame=pivot*CF(0,2.04,0)*CFrame.Angles(0,math.pi,0);seat.Anchored=true;seat.Transparency=1;seat.CanCollide=true;seat.CanTouch=true;seat.Parent=g
 return g
end
function K.pergola(m,n,x,y,z,w,d,h)
 local g=K.model(m,n,"ARCHITECTURE","Campus")
 for _,sx in {-1,1}do for _,sz in {-1,1}do
  local px,pz=x+sx*(w/2-.5),z+sz*(d/2-.5)
  K.box(g,"FootPlate",px,y+.09,pz,.95,.18,.95,C.steel,Enum.Material.Metal,true)
  K.box(g,"SteelPost",px,y+h/2,pz,.34,h,.34,C.steel,Enum.Material.Metal,true)
 end end
 for _,sx in {-1,1}do K.box(g,"SideBoxBeam",x+sx*(w/2-.25),y+h,z,.5,.6,d,C.steel,Enum.Material.Metal,true)end
 for _,sz in {-1,1}do K.box(g,"EndBoxBeam",x,y+h,z+sz*(d/2-.25),w-.7,.6,.5,C.steel,Enum.Material.Metal,true)end
 local count=math.floor(d/.95)
 for i=0,count do K.box(g,"TimberShadeBlade_"..i,x,y+h+.17,z-d/2+.4+i*(d-.8)/count,w-.6,.22,.45,i%4==0 and C.woodDark or C.wood,Enum.Material.Wood,false)end
 local lens=K.box(g,"RecessedWorkLight",x,y+h-.34,z+d/2-.4,w-1.3,.07,.11,C.warm,Enum.Material.Neon,false)
 local light=Instance.new("PointLight");light.Name="WarmWorkPool";light.Color=C.warm;light.Range=20;light.Brightness=.7;light.Shadows=false;light.Parent=lens
 return g
end
function K.light(m,n,x,y,z,range)
 local g=K.model(m,n,"AMBIENCE","Campus")
 K.box(g,"Foot",x,y+.06,z,.64,.12,.64,C.steel,Enum.Material.Metal,true)
 K.box(g,"Housing",x,y+1.4,z,.35,2.8,.35,C.steel,Enum.Material.Metal,true)
 local lens=K.box(g,"WarmLens",x,y+2.55,z,.39,.32,.39,C.warm,Enum.Material.Neon,false)
 K.box(g,"ShieldCap",x,y+2.79,z,.56,.14,.56,C.steel,Enum.Material.Metal,false)
 local light=Instance.new("PointLight");light.Color=C.warm;light.Range=range or 11;light.Brightness=.42;light.Shadows=false;light.Parent=lens;return g
end
function K.paving(m,n,x,y,z,w,d)
 local g=K.model(m,n,"ARCHITECTURE","Campus")
 -- Surface-only finish on the existing physical apron; never a new raised platform.
 local nx,nz=math.ceil(w/5),math.ceil(d/5)
 for i=1,nx do for j=1,nz do
  local p=K.box(g,"StonePaver_"..i.."_"..j,x-w/2+(i-.5)*w/nx,math.max(y+.095,.215),z-d/2+(j-.5)*d/nz,w/nx-.055,.04,d/nz-.055,(i+j)%3==0 and C.gravel or C.stone,Enum.Material.Limestone,false);p.CanQuery=false;p.CastShadow=false
 end end;return g
end
return K

