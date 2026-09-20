-- INT-004: bottom helper and top cash, following the Captain reference.
if game.PlaceId ~= 105869926920733 or not game:GetService("RunService"):IsStudio() then return end
local player = game:GetService("Players").LocalPlayer
local TweenService = game:GetService("TweenService")
local root = workspace:WaitForChild("SellCarsIntegrationOpening",30)
if not root then return end
local function make(class, parent, props)
 local o=Instance.new(class)
 for k,v in props do o[k]=v end
 o.Parent=parent
 return o
end
local function round(o,r) make("UICorner",o,{CornerRadius=UDim.new(0,r)}) end
local function stroke(o,color,width) make("UIStroke",o,{Color=color,Thickness=width}) end
local ink=Color3.fromRGB(30,39,42)
local gui=make("ScreenGui",player:WaitForChild("PlayerGui"),{Name="SellCarsOpeningHUD",ResetOnSpawn=false,DisplayOrder=10})
-- All monetary HUD information belongs in this top-center group.
local wallet=make("Frame",gui,{Name="Money",AnchorPoint=Vector2.new(.5,0),Position=UDim2.new(.5,0,0,12),Size=UDim2.fromOffset(244,58),BackgroundColor3=Color3.fromRGB(73,182,92)})
round(wallet,12);stroke(wallet,ink,3)
local cashIcon=make("TextLabel",wallet,{Name="CashIcon",Position=UDim2.fromOffset(10,8),Size=UDim2.fromOffset(43,42),BackgroundColor3=Color3.fromRGB(184,236,115),Text="$",TextColor3=Color3.fromRGB(30,88,41),TextSize=32,Font=Enum.Font.GothamBlack,Rotation=-8})
round(cashIcon,6);stroke(cashIcon,ink,2)
local cash=make("TextLabel",wallet,{Name="Balance",Position=UDim2.fromOffset(61,0),Size=UDim2.new(1,-69,1,0),BackgroundTransparency=1,TextColor3=Color3.new(1,1,1),Font=Enum.Font.GothamBlack,TextSize=31,TextStrokeColor3=ink,TextStrokeTransparency=0,Text="$7,000"})
local lastCash
local deltaVersion=0
local delta=make("TextLabel",wallet,{Name="Change",Position=UDim2.new(0,0,1,5),Size=UDim2.new(1,0,0,30),BackgroundTransparency=1,TextColor3=Color3.fromRGB(255,230,154),TextStrokeColor3=ink,TextStrokeTransparency=0,Font=Enum.Font.GothamBold,TextSize=21,Text=""})
local function updateCash()
 local value=player:GetAttribute("SellCarsCash")
 if type(value)~="number" then cash.Text="—";return end
 local formatted=tostring(math.floor(value)):reverse():gsub("(%d%d%d)","%1,"):reverse():gsub("^,","")
 cash.Text="$"..formatted
 if lastCash and value<lastCash then
  deltaVersion+=1
  local token=deltaVersion
  delta.Text="−$"..tostring(lastCash-value)
  task.delay(3,function() if deltaVersion==token then delta.Text="" end end)
 end
 lastCash=value
end
player:GetAttributeChangedSignal("SellCarsCash"):Connect(updateCash)
updateCash()
local helper=make("Frame",gui,{Name="Helper",AnchorPoint=Vector2.new(.5,1),Position=UDim2.new(.5,0,1,170),Size=UDim2.fromOffset(540,132),BackgroundColor3=Color3.fromRGB(244,241,227)})
round(helper,13);stroke(helper,ink,3)
make("UIStroke",helper,{Color=Color3.fromRGB(124,201,204),Thickness=1,ApplyStrokeMode=Enum.ApplyStrokeMode.Border})
local title=make("TextLabel",helper,{Name="Speaker",Position=UDim2.fromOffset(0,-29),Size=UDim2.fromOffset(230,26),BackgroundTransparency=1,Text="YOUR GUIDE",TextColor3=Color3.new(1,1,1),TextStrokeColor3=ink,TextStrokeTransparency=0,TextSize=20,Font=Enum.Font.GothamBlack,TextXAlignment=Enum.TextXAlignment.Left})
local portrait=make("ViewportFrame",helper,{Name="Portrait",Position=UDim2.fromOffset(10,10),Size=UDim2.fromOffset(108,112),BackgroundColor3=Color3.fromRGB(120,185,199),Ambient=Color3.fromRGB(200,200,200),LightColor=Color3.new(1,1,1),LightDirection=Vector3.new(-1,-1,-3)})
round(portrait,8);stroke(portrait,ink,2)
-- Original block-character bust; no downloaded portrait or external asset dependency.
local world=make("WorldModel",portrait,{Name="GuideBust"})
local function part(name,size,pos,color)
 return make("Part",world,{Name=name,Anchored=true,CanCollide=false,Size=size,CFrame=CFrame.new(pos),Color=color,Material=Enum.Material.SmoothPlastic})
end
local skin=Color3.fromRGB(222,171,119)
part("WorkShirt",Vector3.new(2,1.7,1),Vector3.new(0,-.9,0),Color3.fromRGB(51,108,103))
local head=part("Head",Vector3.new(1.45,1.45,1.15),Vector3.new(0,.58,0),skin)
make("SpecialMesh",head,{MeshType=Enum.MeshType.Head,Scale=Vector3.new(1,1,1)})
part("Cap",Vector3.new(1.57,.35,1.3),Vector3.new(0,1.3,0),Color3.fromRGB(45,64,62))
part("CapBrim",Vector3.new(1.6,.12,.65),Vector3.new(0,1.17,-.73),Color3.fromRGB(45,64,62))
part("LeftEye",Vector3.new(.09,.14,.025),Vector3.new(-.25,.65,-.578),ink)
part("RightEye",Vector3.new(.09,.14,.025),Vector3.new(.25,.65,-.578),ink)
part("Smile",Vector3.new(.29,.055,.025),Vector3.new(0,.31,-.582),ink)
part("ShirtPocket",Vector3.new(.5,.55,.03),Vector3.new(-.52,-.7,-.51),Color3.fromRGB(75,134,125))
local camera=make("Camera",portrait,{CFrame=CFrame.lookAt(Vector3.new(0,.65,-5.2),Vector3.new(0,.25,0)),FieldOfView=34})
portrait.CurrentCamera=camera
local message=make("TextLabel",helper,{Name="Message",Position=UDim2.fromOffset(134,12),Size=UDim2.new(1,-150,1,-24),BackgroundTransparency=1,TextColor3=ink,Font=Enum.Font.GothamBold,TextSize=23,TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Center,Text=""})
local shown=UDim2.new(.5,0,1,-28)
local hidden=UDim2.new(.5,0,1,180)
local motion
local visible=false
local function slide(show)
 visible=show
 if motion then motion:Cancel() end
 motion=TweenService:Create(helper,TweenInfo.new(.38,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),{Position=show and shown or hidden})
 motion:Play()
end
local function layout()
 local viewport=workspace.CurrentCamera.ViewportSize
 local compact=viewport.Y<550 or viewport.X<700
 local width=math.min(540,viewport.X-40)
 if compact and viewport.X>600 then width=math.min(width,viewport.X-300) end
 helper.Size=UDim2.fromOffset(width,compact and 112 or 132)
 portrait.Size=UDim2.fromOffset(compact and 88 or 108,compact and 92 or 112)
 local inset=compact and 112 or 134
 message.Position=UDim2.fromOffset(inset,10)
 message.Size=UDim2.new(1,-inset-16,1,-20)
 message.TextSize=compact and 18 or 23
 shown=UDim2.new(.5,0,1,compact and -12 or -28)
 if motion then motion:Cancel() end
 helper.Position=visible and shown or hidden
end
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(layout)
layout()
local revision=0
local function update()
 revision+=1
 local token=revision
 local stage=root:GetAttribute("Stage")
 if stage=="SELLER_CORNER_READY" then
  message.Text="Ready for your first deal? Let’s find you a car."
  slide(true)
  task.delay(4,function()
   if revision==token then message.Text="You’re open. Let’s set up a place to meet sellers. Step onto the seller-corner pad." end
  end)
 elseif stage=="LOT_OPEN" then
  message.Text="Your lot is ready. This is where you’ll build your business."
  slide(true)
  task.delay(4,function()
   if revision==token then message.Text="You’re open. Let’s set up a place to meet sellers. Step onto the seller-corner pad." end
  end)
 else
  message.Text="Let’s open your dealership. Step onto the green pad."
  slide(true)
 end
end
player:GetAttributeChangedSignal("OpeningHint"):Connect(function()
 local hint=player:GetAttribute("OpeningHint")
 if hint then revision+=1;message.Text=hint;slide(true) end
end)
root:GetAttributeChangedSignal("Stage"):Connect(update)
update()

