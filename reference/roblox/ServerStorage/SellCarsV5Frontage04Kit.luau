--!nocheck
-- F04-2: deterministic native architecture kit. No external assets/runtime.
local K={Version="2026-09-08.frontage04.f2.1"}
K.C={steel=Color3.fromRGB(44,49,46),wood=Color3.fromRGB(172,124,74),woodDark=Color3.fromRGB(130,92,55),stone=Color3.fromRGB(190,175,141),gravel=Color3.fromRGB(161,145,111),sage=Color3.fromRGB(105,124,101),olive=Color3.fromRGB(106,117,70),pale=Color3.fromRGB(160,161,108),bark=Color3.fromRGB(111,90,65),warm=Color3.fromRGB(255,207,135),black=Color3.fromRGB(29,34,32),paper=Color3.fromRGB(218,211,186),navy=Color3.fromRGB(43,67,76)}
function K.model(parent,name,role)
 local m=Instance.new("Model");m.Name=name
 m:SetAttribute("BundleId","Institution.Frontage04."..name)
 m:SetAttribute("SourceOwned",true);m:SetAttribute("PhaseMin","INSTITUTION")
 m:SetAttribute("AssetStatus","SOURCE_BUILT_ARCHITECTURE_CANDIDATE")
 m:SetAttribute("FidelityRole",role or "ARCHITECTURE")
 m:SetAttribute("Version",K.Version);m.Parent=parent;return m
end
function K.box(m,n,x,y,z,w,h,d,col,mat,solid)
 local p=Instance.new("Part");p.Name=n;p.Size=Vector3.new(w,h,d);p.CFrame=CFrame.new(x,y,z)
 p.Anchored=true;p.Color=col or K.C.steel;p.Material=mat or Enum.Material.SmoothPlastic
 p.CanCollide=solid==true;p.CanQuery=true;p.CanTouch=false;p.CastShadow=true
 p.TopSurface=Enum.SurfaceType.Smooth;p.BottomSurface=Enum.SurfaceType.Smooth;p.Parent=m;return p
end
function K.bar(m,n,a,b,diameter,col,mat,solid)
 local p=K.box(m,n,0,0,0,(b-a).Magnitude,diameter,diameter,col,mat or Enum.Material.Metal,solid)
 p.Shape=Enum.PartType.Cylinder;p.CFrame=CFrame.lookAt((a+b)/2,b)*CFrame.Angles(0,math.pi/2,0);return p
end
return K

