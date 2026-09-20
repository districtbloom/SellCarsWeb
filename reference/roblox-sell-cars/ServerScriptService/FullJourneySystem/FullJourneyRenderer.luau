--!strict
-- FullJourney's authored visual recipes, evaluated independently for each plot.
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local rules = require(script.Parent.PreviewRules)
local Renderer = {}
local records = {}
local sourceRoot: Model
local function order(n) if n==233 then return 229 elseif n>=229 and n<233 then return n+1 end return n end
local function clip(cf,size,axis,maximum)
 local c=cf.Position[axis];local h=size[axis]/2
 if c-h>=maximum then return cf,size,false end
 if c+h<=maximum then return cf,size,true end
 local s=math.max(.04,maximum-(c-h));local shift=(s-size[axis])/2
 local v=axis=='X'and Vector3.new(shift,0,0)or(axis=='Y'and Vector3.new(0,shift,0)or Vector3.new(0,0,shift))
 local sz=axis=='X'and Vector3.new(s,size.Y,size.Z)or(axis=='Y'and Vector3.new(size.X,s,size.Z)or Vector3.new(size.X,size.Y,s))
 return cf+v,sz,true
end
local function desired(r,n)
 local show=n>=r.first and n<r.retire;local cf,size=r.cf,r.size;local color,mat=r.color,r.material
 if n>=r.moveAt then cf+=r.move end
 if n<order(233)then cf=r.pbCF or cf;size=r.pbSize or size;if r.pbTrans==1 then show=false end end
 local d=r.dept and rules.Departments[r.dept]
 if r.kind=='parcelSoil'and n<65 then
  color=Color3.fromRGB(151,125,91);mat=Enum.Material.Ground
 elseif r.kind=='productionShell'and d then
  if n<order(d.second)then cf,size,show=clip(cf,size,'Z',d.z);show=show and n>=r.first end
  if n<order(d.shell)then
   local bottom=cf.Position.Y-size.Y/2
   if size.Y>3 then size=Vector3.new(size.X,size.Y*.7,size.Z);cf=CFrame.new(cf.Position.X,bottom+size.Y/2,cf.Position.Z)*cf.Rotation
   elseif cf.Position.Y>10 then cf+=Vector3.new(0,-4,0)end
   mat=Enum.Material.CorrodedMetal;color=Color3.fromRGB(121,108,87)
  end
 elseif r.kind=='hq'and n<order(235)then
  if r.path:find('SecondToTurn',1,true)or r.path:find('TurnToCrown',1,true)or r.path:find('UpperReturnLanding',1,true)or r.path:find('Floor3',1,true)then show=false
  else local good;cf,size,good=clip(cf,size,'Y',29.1);show=show and good end
 elseif r.kind=='wing'and n<order(192)then
  -- Complete rear half-shelter, not a full roof hovering beyond hidden posts.
  local front=cf.Position.Z-size.Z/2
  if cf.Position.Z+size.Z/2<=461 then show=false
  elseif front<461 then local depth=cf.Position.Z+size.Z/2-461;cf+=Vector3.new(0,0,(size.Z-depth)/2);size=Vector3.new(size.X,size.Y,depth)end
  local permanent=r.path:find('Parts_Logistics',1,true)and 112 or 115
  if n<permanent then
   local ground=1.63;local scale=.63
   cf=CFrame.new(cf.X,ground+(cf.Y-ground)*scale,cf.Z)*cf.Rotation;size=Vector3.new(size.X,size.Y*scale,size.Z)
   mat=Enum.Material.CorrodedMetal;color=Color3.fromRGB(116,108,92)
  end
 elseif r.kind=='owner'then
  if n<62 then local good;cf,size,good=clip(cf,size,'X',3193);show=show and good end
  local maxZ=n<120 and 66 or(n<183 and 94 or 999)
  local good;cf,size,good=clip(cf,size,'Z',maxZ);show=show and good
 elseif r.kind=='receiving'and n<197 then
  if n<141 and cf.Position.Z<69 then show=false end
  if size.Y>8 then local bottom=cf.Position.Y-size.Y/2;local h=n<141 and math.min(size.Y,10)or math.min(size.Y,15);size=Vector3.new(size.X,h,size.Z);cf=CFrame.new(cf.Position.X,bottom+h/2,cf.Position.Z)*cf.Rotation
  elseif cf.Position.Y>12 then cf+=Vector3.new(0,n<141 and-9 or-4,0)end
 end
 if n<r.finish and r.finish>r.first then
  if r.material==Enum.Material.Wood or r.material==Enum.Material.WoodPlanks or r.material==Enum.Material.Limestone or r.material==Enum.Material.Marble then
   mat=Enum.Material.Concrete;color=Color3.fromRGB(141,139,127)
  elseif r.material==Enum.Material.Metal or r.material==Enum.Material.DiamondPlate then color=r.color:Lerp(Color3.fromRGB(101,110,109),n>=r.mid and r.mid>0 and .12 or .3)end
 end
 if r.kind=='productionShell'and d and n>=123 and n<order(d.pro)then color=Color3.fromRGB(66,79,85)end
 for _,stage in r.stagePalette do if n>=stage.step then color=Color3.fromRGB(table.unpack(stage.color));mat=Enum.Material[stage.material]end end
 if r.artFirst and n>=r.artFirst then color=r.artColor or color;mat=r.artMaterial and Enum.Material[r.artMaterial]or mat end
 -- CIRC02 overrides are limited to the opening chapter; inherited later poses are untouched.
 if n>=1 and n<=24 then cf=r.o:GetAttribute('FJ_CIRC02_BirthCF')or cf end
 return show,cf,size,color,mat
end

local function getCF(source)
	local cf=source:GetAttribute("FJ_CF")
	return if typeof(cf)=="CFrame" then cf else source.CFrame
end

function Renderer.init(template: Model)
	sourceRoot=template
	table.clear(records)
	for _,o in template:GetDescendants() do
		if o:IsA("BasePart") and o:GetAttribute("FJ_First")~=nil then
			local effects={}
			for _,e in o:GetDescendants() do
				if e:GetAttribute("FJ_Enabled")~=nil then table.insert(effects,{on=e:GetAttribute("FJ_Enabled")}) end
			end
			local palette={}
			pcall(function() palette=HttpService:JSONDecode(o:GetAttribute("FJ_StagePalette") or "[]") end)
			table.insert(records,{
				o=o,stagePalette=palette,artFirst=o:GetAttribute("FJ_ArtFirst"),artColor=o:GetAttribute("FJ_ArtColor"),artMaterial=o:GetAttribute("FJ_ArtMaterial"),
				first=o:GetAttribute("FJ_First"),finish=o:GetAttribute("FJ_Finish") or o:GetAttribute("FJ_First"),mid=o:GetAttribute("FJ_Mid") or 0,
				kind=o:GetAttribute("FJ_Kind"),dept=o:GetAttribute("FJ_Department"),retire=o:GetAttribute("FJ_Retire") or 999,
				moveAt=o:GetAttribute("FJ_MoveAt") or 999,move=o:GetAttribute("FJ_Move") or Vector3.zero,cf=getCF(o),
				size=o:GetAttribute("FJ_Size") or o.Size,color=o:GetAttribute("FJ_Color") or o.Color,
				material=Enum.Material[o:GetAttribute("FJ_Material") or o.Material.Name],trans=o:GetAttribute("FJ_Transparency") or 0,
				collide=o:GetAttribute("FJ_Collide")==true,query=o:GetAttribute("FJ_Query")==true,touch=false,effects=effects,
				path=o:GetAttribute("FJ_Path") or o.Name,pbCF=o:GetAttribute("FJ_PB_CFrame"),pbSize=o:GetAttribute("FJ_PB_Size"),pbTrans=o:GetAttribute("FJ_PB_Transparency"),
			})
		end
	end
	assert(#records>0,"FullJourney template has no authored progression records")
	return #records
end

function Renderer.create(folder: Folder, origin: CFrame, sourceOrigin: CFrame)
	local visual=Instance.new("Folder")
	visual.Name="Buildings"
	visual.Parent=folder
	return {root=visual,origin=origin,delta=origin*sourceOrigin:Inverse(),live={},parents={[sourceRoot]=visual},tweens={},generation=0,step=-1}
end

local function cancelTweens(state)
	for part,animation in state.tweens do
		state.tweens[part]=nil
		animation:Cancel()
		animation:Destroy()
	end
end

local function parentFor(state, source)
	if state.parents[source] then return state.parents[source] end
	local parent=parentFor(state,source.Parent)
	local item
	if source:IsA("Model") then
		item=Instance.new("Model")
		item.WorldPivot=state.delta*source:GetPivot()
	else
		item=Instance.new("Folder")
	end
	item.Name=source.Name
	item.Parent=parent
	state.parents[source]=item
	return item
end

local function clonePart(state,r)
	local part=r.o:Clone()
	-- Cross-part joints in decorative source rigs must not point back at the authoring template.
	for _,d in part:GetDescendants() do
		if d:IsA("JointInstance") or d:IsA("Constraint") or d:IsA("ObjectValue") or d:IsA("BaseScript") then
			d:Destroy()
		else
			local enabled=d:GetAttribute("FJ_Enabled")
			if enabled~=nil then pcall(function() d.Enabled=enabled end) end
			for _,tag in d:GetTags() do d:RemoveTag(tag) end
			for key in d:GetAttributes() do if key:match("^FJ_") then d:SetAttribute(key,nil) end end
		end
	end
	for _,tag in part:GetTags() do part:RemoveTag(tag) end
	for key in part:GetAttributes() do if key:match("^FJ_") then part:SetAttribute(key,nil) end end
	part.Anchored=true
	part.CanTouch=false
	part.AssemblyLinearVelocity=Vector3.zero
	part.AssemblyAngularVelocity=Vector3.zero
	part:SetAttribute("FullJourneyAsset",true)
	return part
end

function Renderer.apply(state,step: number,animate: boolean?)
	assert(step>=0 and step<=240 and step%1==0,"Invalid FullJourney step")
	state.generation+=1
	-- A started tween can otherwise overwrite the next stage's canonical dimensions.
	cancelTweens(state)
	local generation=state.generation
	local made,removed,changed=0,0,0
	local animated=0
	for _,r in records do
		local show,cf,size,color,mat=desired(r,step)
		-- Invisible route/evidence parts remain source data unless they carry an effect or collision.
		show=show and (r.trans<1 or r.collide or #r.effects>0)
		local part=state.live[r]
		if show then
			local isNew=part==nil
			if isNew then
				part=clonePart(state,r)
				state.live[r]=part
				made+=1
			end
			local world=state.delta*cf
			local changedShape=isNew or part.CFrame~=world or part.Size~=size or part.Color~=color or part.Material~=mat
			if changedShape then changed+=1 end
			part.CFrame=world
			part.Size=size
			part.Color=color
			part.Material=mat
			part.Transparency=r.trans
			part.CanCollide=r.collide
			part.CanQuery=r.query
			if isNew then
				part.Parent=parentFor(state,r.o.Parent)
				if animate and animated<120 and r.trans<1 and not r.collide then
					animated+=1
					local finalSize=size
					part.Size=Vector3.new(math.max(.01,size.X*.12),math.max(.01,size.Y*.12),math.max(.01,size.Z*.12))
					local delaySeconds=math.min(animated*.003,.28)
					task.delay(delaySeconds,function()
						if state.generation==generation and state.live[r]==part and part.Parent then
							local animation=TweenService:Create(part,TweenInfo.new(.38,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Size=finalSize})
							state.tweens[part]=animation
							animation.Completed:Once(function()
								if state.tweens[part]==animation then state.tweens[part]=nil end
								animation:Destroy()
							end)
							animation:Play()
						end
					end)
				end
			end
		elseif part~=nil then
			part:Destroy()
			state.live[r]=nil
			removed+=1
		end
	end
	state.step=step
	local live=0 for _ in state.live do live+=1 end
	state.root:SetAttribute("JourneyStep",step)
	state.root:SetAttribute("LivePartCount",live)
	return {created=made,removed=removed,changed=changed,live=live}
end

function Renderer.clear(state)
	state.generation+=1
	cancelTweens(state)
	state.root:Destroy()
	table.clear(state.live)
	table.clear(state.parents)
end

-- Pure source-space geometry for test coverage and plot-local route/interaction placement.
function Renderer.evaluate(step)
	local out={visible=0,collidable=0,finite=true}
	for _,r in records do
		local show,cf,size=desired(r,step)
		if show and (r.trans<1 or r.collide or #r.effects>0) then
			out.visible+=1
			if r.collide then out.collidable+=1 end
			if cf.Position.Magnitude~=cf.Position.Magnitude or size.X<=0 or size.Y<=0 or size.Z<=0 then out.finite=false end
		end
	end
	return out
end

return Renderer