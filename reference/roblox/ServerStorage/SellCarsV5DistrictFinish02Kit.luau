--!nocheck
local K={Version="2026-09-08.districtfinish02.1"}
K.C={charcoal=Color3.fromRGB(43,46,43),edge=Color3.fromRGB(60,63,57),wood=Color3.fromRGB(155,112,71),stone=Color3.fromRGB(173,167,151),paper=Color3.fromRGB(224,216,193),ink=Color3.fromRGB(47,56,56),bronze=Color3.fromRGB(160,126,79)}
function K.group(p,n,fn,role)
 local m=Instance.new("Model");m.Name=n;m.Parent=p
 for k,v in {BundleId="Institution.DistrictFinish02."..fn.."."..n,FunctionId=fn,PhaseMin="INSTITUTION",UpgradeIntent=role or n,PurchaseWired=false,Ancestor="Existing fixed "..fn.." setting; earlier chapter mapping deferred",SourceVersion=K.Version}do m:SetAttribute(k,v)end
 return m
end
function K.box(p,n,cf,size,color,mat)
 local v=Instance.new("Part");v.Name=n;v.CFrame=cf;v.Size=size;v.Color=color or K.C.charcoal;v.Material=mat or Enum.Material.Metal
 v.Anchored=true;v.CanCollide=false;v.CanTouch=false;v.CanQuery=true;v.TopSurface=0;v.BottomSurface=0;v.Parent=p;return v
end
function K.text(p,title,subtitle,face)
 local g=Instance.new("SurfaceGui");g.Name="EnvironmentalPrint";g.Face=face or Enum.NormalId.Front;g.CanvasSize=Vector2.new(1000,160);g.LightInfluence=.6;g.Parent=p
 local a=Instance.new("TextLabel");a.Name="Title";a.BackgroundTransparency=1;a.Size=UDim2.fromScale(.96,subtitle and .67 or .9);a.Position=UDim2.fromScale(.02,.02);a.Font=Enum.Font.GothamMedium;a.Text=title;a.TextScaled=true;a.TextColor3=K.C.paper;a.Parent=g
 if subtitle then local b=a:Clone();b.Name="Caption";b.Text=subtitle;b.Font=Enum.Font.Gotham;b.TextColor3=Color3.fromRGB(199,178,142);b.Size=UDim2.fromScale(.96,.24);b.Position=UDim2.fromScale(.02,.73);b.Parent=g end
 p:SetAttribute("ContentBinding","STATIC_ENVIRONMENTAL_STORY_NOT_GAME_STATE");return g
end
function K.stats(m)local r={parts=0,descendants=#m:GetDescendants(),lights=0};for _,v in m:GetDescendants()do if v:IsA("BasePart")then r.parts+=1 elseif v:IsA("Light")then r.lights+=1 end end;return r end
function K.book(p,cf,col,wide)
 local w=wide or 1.6
 K.box(p,"BoundFolio",cf,Vector3.new(w,.16,2.2),col or K.C.ink,Enum.Material.SmoothPlastic)
 K.box(p,"PaperBlock",cf*CFrame.new(0,.12,0),Vector3.new(w-.12,.1,2.06),K.C.paper,Enum.Material.SmoothPlastic)
 K.box(p,"FolioCover",cf*CFrame.new(0,.2,0),Vector3.new(w,.06,2.2),col or K.C.ink,Enum.Material.SmoothPlastic)
 K.box(p,"Spine",cf*CFrame.new(-w/2+.04,.1,0),Vector3.new(.08,.25,2.2),col or K.C.ink)
end
function K.light(p,cf,w,range)
 local mount=K.box(p,"FittedLightHousing",cf,Vector3.new(w,.22,.8),K.C.charcoal)
 local lens=K.box(p,"WarmDiffuser",cf*CFrame.new(0,-.13,0),Vector3.new(w-.3,.04,.52),Color3.fromRGB(255,224,177),Enum.Material.Neon)
 local l=Instance.new("SurfaceLight");l.Name="LocalWarmTask";l.Face=Enum.NormalId.Bottom;l.Color=Color3.fromRGB(255,224,177);l.Brightness=.75;l.Range=range or 18;l.Angle=110;l.Shadows=false;l.Parent=lens
 local ref=Instance.new("ObjectValue");ref.Name="HousingReference";ref.Value=mount;ref.Parent=lens
 return lens
end
return K

