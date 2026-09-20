-- One automatic acknowledgement; payment and progression remain server-owned.
local P={};P.__index=P
local function make(c,p,t)local o=Instance.new(c);for k,v in t do o[k]=v end;o.Parent=p;return o end
local function money(n)return '$'..tostring(math.floor(math.abs(n or 0))):reverse():gsub('(%d%d%d)','%1,'):reverse():gsub('^,','')end
function P.new(gui,theme,motion)
 local self=setmetatable({token=0},P);local C=theme.Colors
 self.result=make('Frame',gui,{Name='DealClosureResult',AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.63),Size=UDim2.fromOffset(430,204),BackgroundColor3=C.Panel,BorderSizePixel=0,Visible=false,ZIndex=180})
 make('UICorner',self.result,{CornerRadius=UDim.new(0,18)});make('UIStroke',self.result,{Color=C.Ink,Thickness=3})
 local function label(name,y,h,size,color)return make('TextLabel',self.result,{Name=name,Position=UDim2.fromOffset(18,y),Size=UDim2.new(1,-36,0,h),BackgroundTransparency=1,Text='',TextColor3=color or C.Ink,TextSize=size,TextWrapped=true,Font=Enum.Font.GothamBold,ZIndex=181})end
 self.car=label('Car',16,24,14);self.status=label('Status',48,28,21);self.amount=label('Amount',83,62,42,C.Green);self.detail=label('Detail',151,30,16)
 local function layout()local v=workspace.CurrentCamera.ViewportSize;local portrait=v.X<v.Y;self.result.AnchorPoint=portrait and Vector2.new(.5,1)or Vector2.new(1,.5);self.result.Position=portrait and UDim2.new(.5,0,1,-12)or UDim2.new(1,-20,.5,8);self.result.Size=UDim2.fromOffset(portrait and math.min(420,v.X-24)or math.min(450,math.floor(v.X*.49)-24),204)end
 workspace.CurrentCamera:GetPropertyChangedSignal('ViewportSize'):Connect(layout);layout();return self
end
function P:Cancel()self.token+=1;self.playing=false;self.result.Visible=false end
function P:Play(data,head,onComplete)
 self:Cancel();local token=self.token;self.playing=true;self.result.Visible=true
 local sold=data.kind=='Sell';local profit=data.profit or 0
 self.car.Text=data.carName or 'Your car';self.status.Text=sold and 'SOLD' or 'YOURS'
 self.amount.Text=sold and ((profit<0 and '−'or'+')..money(profit)) or money(data.amount)
 self.detail.Text=sold and ('Profit · Sold for '..money(data.amount)) or 'Paid · Ready for the repair bay'
 task.delay(2,function()if self.token~=token then return end;self.result.Visible=false;self.playing=false;if onComplete then onComplete()end end)
end
return P

