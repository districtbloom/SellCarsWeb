-- CIRC02 geometric route candidates. Model-centre paths, not axle/steering physics.
local M={}
function M.Build()
 local routes={};local V=Vector3.new
 local function line(out,x,z,X,Z,hx,hz)
  local n=math.ceil(Vector2.new(X-x,Z-z).Magnitude/.4)
  for i=0,n do local t=n>0 and i/n or 0;local p=V(x+(X-x)*t,5.2,z+(Z-z)*t);out[#out+1]=CFrame.lookAt(p,p+V(hx,0,hz))end
 end
 local function arc(out,x,z,r,a,b,reverse)
  a=math.rad(a);b=math.rad(b);local n=math.ceil(math.abs(b-a)*r/.4);local sign=b>a and 1 or -1
  for i=0,n do local t=a+(b-a)*i/n;local p=V(x+r*math.cos(t),5.2,z+r*math.sin(t));local h=V(-math.sin(t)*sign,0,math.cos(t)*sign)*(reverse and -1 or 1);out[#out+1]=CFrame.lookAt(p,p+h)end
 end
 local a={};routes.arrival=a
 line(a,3076,8,3076,17,0,1);arc(a,3063,17,13,0,90);line(a,3063,30,3021,30,-1,0);arc(a,3021,43,13,-90,-180);line(a,3008,43,3008,88,0,1)
 local w={};routes.work=w
 line(w,3008,88,3008,90,0,1);arc(w,3021,90,13,180,90);line(w,3021,103,3060,103,1,0);arc(w,3060,117.5,14.5,-90,0);arc(w,3060,117.5,14.5,0,90);line(w,3060,132,3041,132,-1,0)
 local s={};routes.sales=s
 -- Reverse out of the same repair bay, then drive north into the sales space.
 line(s,3041,132,3060,132,-1,0);arc(s,3060,117.5,14.5,90,0,true)
 line(s,3074.5,117.5,3074.5,96,0,-1);line(s,3074.5,96,3073,82,0,-1)
 local e={};routes.exit=e
 line(e,3073,82,3073,8,0,-1)
 local direct={};routes.intakeSales=direct
 line(direct,3008,88,3008,90,0,1);arc(direct,3021,90,13,180,90);line(direct,3021,103,3060,103,1,0)
 arc(direct,3060,90,13,90,0);line(direct,3073,90,3073,82,0,-1)
 return routes
end
return M

