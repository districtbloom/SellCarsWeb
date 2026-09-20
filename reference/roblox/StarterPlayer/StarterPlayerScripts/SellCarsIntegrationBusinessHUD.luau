if game.PlaceId~=105869926920733 or not game.RunService:IsStudio()then return end
local player=game.Players.LocalPlayer;local core=player.PlayerGui:WaitForChild('CorePrototypeUI');local event=game.ReplicatedStorage:WaitForChild('CorePrototypeRemotes'):WaitForChild('PrototypeEvent')
local C={ink=Color3.fromRGB(30,39,42),cream=Color3.fromRGB(244,241,227),green=Color3.fromRGB(77,173,94)}
local function make(c,p,t)local o=Instance.new(c);for k,v in t do o[k]=v end;o.Parent=p;return o end
local function label(p,t)local base={BackgroundTransparency=1,Font=Enum.Font.GothamBold,TextSize=16,TextColor3=C.ink,TextWrapped=true};for k,v in t do base[k]=v end;return make('TextLabel',p,base)end
local gui=make('ScreenGui',player.PlayerGui,{Name='IntegrationBusinessHUD',ResetOnSpawn=false,IgnoreGuiInset=true,DisplayOrder=30})
local budget=label(gui,{Name='OperatingBudget',AnchorPoint=Vector2.new(.5,0),Position=UDim2.new(.5,0,0,132),Size=UDim2.fromOffset(390,28),TextSize=13,Visible=false,Text=''})
local card=make('Frame',gui,{Name='SaleReceipt',AnchorPoint=Vector2.new(.5,1),Position=UDim2.new(.5,0,1,-18),Size=UDim2.fromOffset(430,210),BackgroundColor3=C.cream,BorderSizePixel=0,Visible=false})
make('UICorner',card,{CornerRadius=UDim.new(0,12)});make('UIStroke',card,{Color=C.ink,Thickness=2,ApplyStrokeMode=Enum.ApplyStrokeMode.Border})
local title=label(card,{Position=UDim2.fromOffset(16,10),Size=UDim2.new(1,-32,0,28),Text='CAR SOLD',TextXAlignment=Enum.TextXAlignment.Left})
local detail=label(card,{Position=UDim2.fromOffset(20,133),Size=UDim2.new(1,-40,0,62),Text='',TextSize=17,TextXAlignment=Enum.TextXAlignment.Left})
local profit=label(card,{Position=UDim2.fromOffset(20,44),Size=UDim2.new(1,-40,0,77),Text='',TextColor3=C.green,TextSize=38,TextXAlignment=Enum.TextXAlignment.Left})
local queue={};local seen={};local state={};local shownAt;local current
local function money(n)return '$'..tostring(math.floor(n or 0)):reverse():gsub('(%d%d%d)','%1,'):reverse():gsub('^,','')end
local function layout()local v=workspace.CurrentCamera.ViewportSize;card.Size=UDim2.fromOffset(math.min(430,v.X-32),210);budget.Size=UDim2.fromOffset(math.min(390,v.X-24),28);budget.Position=UDim2.new(.5,0,0,v.Y<550 and 94 or 132)end
workspace.CurrentCamera:GetPropertyChangedSignal('ViewportSize'):Connect(layout);layout()
event.OnClientEvent:Connect(function(kind,data)
 if kind=='State'then state=data;budget.Text=(data.rareFocus and 'REPAIR RESERVE 'or'OPERATING ')..money(data.operatingReserve or 0)..'  ·  AVAILABLE '..money(math.max(0,(data.cash or 0)-(data.operatingReserve or 0)))
 elseif kind=='Receipt'then local id=data.id or ('first-'..tostring(data.sold));if not seen[id]then seen[id]=true;table.insert(queue,data)end end
end)
local tracked={}
local function track(model,field,name)
 local root=model:FindFirstChild('Head')or model:FindFirstChild('Body');if not root then return end
 local bill=make('BillboardGui',root,{Name=name,Size=UDim2.fromOffset(200,30),StudsOffsetWorldSpace=Vector3.new(0,3,0),MaxDistance=24,AlwaysOnTop=false,Enabled=false})
 local text=label(bill,{Size=UDim2.fromScale(1,1),BackgroundTransparency=.04,BackgroundColor3=C.cream,Text='',TextSize=13});make('UICorner',text,{CornerRadius=UDim.new(0,8)})
 table.insert(tracked,{model=model,root=root,bill=bill,text=text,field=field})
end
local w=workspace:WaitForChild('CoreUXPrototype')
for _,m in {w.Workshop.Mechanic,w.Operations.CarBuyer,w.Operations.SalesRep}do track(m,'StaffJob','StaffJobLabel')end
for _,m in {w.SecondDeal.SecondCar,w.Operations.AutoRouteCar,w.RareArrival.Transporter.RareCar}do track(m,'BusinessStatus','BusinessReadiness')end
game.RunService.Heartbeat:Connect(function()
 local mode=core:GetAttribute('UIMode');local free=mode=='World'or mode=='PadPreview';local moneyHUD=player.PlayerGui:FindFirstChild('SellCarsOpeningHUD');local change=moneyHUD and moneyHUD.Money:FindFirstChild('Change');budget.Visible=free and (state.operatingReserve or 0)>0 and (not change or change.Text=='')
 if not current and #queue>0 and free then current=table.remove(queue,1);shownAt=os.clock();title.Text=(current.car or 'Car')..' · SOLD';detail.Text='Sold for '..money(current.sold);profit.Text='+'..money(current.profit)..' PROFIT'end
 if current and free and shownAt and os.clock()-shownAt>2 then current=nil end
 card.Visible=current~=nil and free;core:SetAttribute('ReceiptShowing',card.Visible)
 local r=player.Character and player.Character:FindFirstChild('HumanoidRootPart')
 for _,t in tracked do local text=t.model:GetAttribute(t.field);local d=r and (r.Position-t.root.Position).Magnitude or math.huge;t.bill.Enabled=free and t.root.Transparency<.9 and text~=nil and d<22;t.text.Text=text or '' end
end)

