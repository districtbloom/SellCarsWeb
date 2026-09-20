--!nocheck
-- Full planted shoulders; original eight-stud walks/crossovers and older details retained.
return function(K,parent)
 local C=K.C
 local beds={{104.5,137.5},{154.5,202.5},{219.5,267.5},{284.5,339.5}}
 for index,v in beds do
  local lo,hi=v[1],v[2];local z=(lo+hi)/2;local d=hi-lo
  local m=K.model(parent,"Garden_"..index,"LANDSCAPE","EstateLandscape")
  m:SetAttribute("ClearWalkMinX",3126);m:SetAttribute("ClearWalkMaxX",3134)
  for side,x in {3120.4,3139.6}do
   -- Warm mulch only in planted shoulders. Do not cover the retained walk/bench apron.
   local mulch=K.box(m,"WarmGravelShoulder_"..side,x,.17,z,9.7,.035,d-.8,C.gravel,Enum.Material.Pebble,false);mulch.CanQuery=false;mulch.CastShadow=false
   K.box(m,"OuterLimestoneEdge_"..side,side==1 and 3115.55 or 3144.45,.24,z,.38,.18,d-.6,C.stone,Enum.Material.Limestone,false)
   for j=0,math.floor(d/6)do
    local zz=lo+2+j*(d-4)/math.floor(d/6)
    local benchPocket=(side==1 and ((index==1 and zz>123 and zz<135)or(index==2 and zz>181 and zz<193)or(index==3 and zz>243 and zz<255)))or(side==2 and index==4 and zz>321 and zz<333)
    if not benchPocket then
     local xx=x+(j%2==0 and -1.55 or 1.55)
     if j%3==0 then K.agave(m,"BlueAgave_"..side.."_"..j,xx,.195,zz,1.03)
     elseif j%3==1 then K.grass(m,"GoldenGrass_"..side.."_"..j,xx,.195,zz,1.2)
     else K.shrub(m,"SageMass_"..side.."_"..j,xx,.195,zz,1.7)end
     K.rock(m,"LimestoneBoulder_"..side.."_"..j,x+(j%2==0 and 1.35 or -1.35),.195,zz+1.1,1.5+(j%2)*.5)
    end
   end
  end
  if index==1 then
   K.yucca(m,"ArrivalYucca",3119.6,.18,111.5,.92)
   K.paving(m,"ArrivalBenchPocket",3124,.095,129,3.5,9)
   K.bench(m,"ArrivalTimberBench",3123.9,.095,129,7.5,90)
  elseif index==2 then
   K.cactus(m,"CactusComposition",3140,.18,169.5,1.35)
  elseif index==3 then
   -- Retain older mature east yucca at3140/226; shade tree is elsewhere.
   K.tree(m,"AiryDesertShade",3119.5,.18,257,.70)
   K.paving(m,"ShadeBenchPocket",3124,.095,249,3.5,9)
   K.bench(m,"ShadedGardenBench",3124,.095,249,7.5,90)
  else
   K.yucca(m,"DistantGardenYucca",3140,.18,301,.68)
   K.paving(m,"RearBenchPocket",3136,.095,327,3.5,10)
   K.bench(m,"RearRestBench",3136.2,.095,327,8,-90)
  end
  for _,q in {{3116.6,lo+4},{3143.4,hi-4}}do K.light(m,"ShieldedPathLight_"..q[1],q[1],.18,q[2],12)end
 end
end

