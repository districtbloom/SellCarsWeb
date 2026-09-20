-- Set FIRST and LAST to the desired inclusive part range before execution.
-- Read-only export. Does not require gameplay modules or modify the place.
local function encode(v)
 local t=typeof(v)
 if t=='Vector3' then return {v.X,v.Y,v.Z}
 elseif t=='CFrame' then return {v:GetComponents()}
 elseif t=='Color3' then return {v.R,v.G,v.B}
 elseif t=='EnumItem' then return v.Name
 elseif t=='UDim2' then return {v.X.Scale,v.X.Offset,v.Y.Scale,v.Y.Offset}
 elseif t=='table' then local out={}for k,x in v do out[k]=encode(x)end return out
 elseif t=='Instance' then return v:GetFullName()
 else return v end
end
local root=workspace.SellCars_Dealership_FullJourney
local out={} local index=0
for _,p in root:GetDescendants()do if p:IsA('BasePart')then
 index+=1
 if index>=FIRST and index<=LAST then
  local labels={}for _,t in p:GetDescendants()do if t:IsA('TextLabel')then table.insert(labels,{text=t.Text,color=encode(t.TextColor3),background=encode(t.BackgroundColor3),backgroundTransparency=t.BackgroundTransparency,face=t.Parent:IsA('SurfaceGui')and t.Parent.Face.Name or 'Front',size=t.TextSize,position=encode(t.Position),dimensions=encode(t.Size)})end end
  local mesh=p:FindFirstChildWhichIsA('SpecialMesh')
  table.insert(out,{id=index,path=p:GetFullName():sub(#root:GetFullName()+2),shape=p:IsA('Part')and p.Shape.Name or p.ClassName,cf=encode(p.CFrame),size=encode(p.Size),color=encode(p.Color),material=p.Material.Name,transparency=p.Transparency,collide=p.CanCollide,attributes=encode(p:GetAttributes()),labels=#labels>0 and labels or nil,mesh=mesh and {type=mesh.MeshType.Name,scale=encode(mesh.Scale),offset=encode(mesh.Offset),meshId=mesh.MeshId,textureId=mesh.TextureId}or nil})
 end
end end
local json=game.HttpService:JSONEncode(out)
local encoding=game:GetService('EncodingService')
return buffer.tostring(encoding:Base64Encode(encoding:CompressBuffer(buffer.fromstring(json),Enum.CompressionAlgorithm.Zstd,6)))
