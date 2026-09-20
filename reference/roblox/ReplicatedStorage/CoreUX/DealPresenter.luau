-- Stable conversation layout: speech first, one amount, tap-only counters.
local P={};P.__index=P
local Tween=game:GetService('TweenService')
local function make(c,p,t)local o=Instance.new(c);for k,v in t do o[k]=v end;o.Parent=p;return o end
local function cash(n)return '$'..tostring(math.floor(math.abs(n or 0))):reverse():gsub('(%d%d%d)','%1,'):reverse():gsub('^,','')end
function P.new(gui,dialogue,theme,event)
 local self=setmetatable({gui=gui,dialogue=dialogue,event=event,C=theme.Colors},P);local C=self.C
 self.scene=require(script.Parent.DealScene).new(gui)
 self.panel=make('Frame',dialogue,{Name='DealPanel',AnchorPoint=Vector2.new(.5,1),Position=UDim2.new(.5,0,1,-16),Size=UDim2.fromOffset(520,420),BackgroundColor3=C.Panel,BorderSizePixel=0,ZIndex=170,Visible=false})
 make('UICorner',self.panel,{CornerRadius=UDim.new(0,18)});make('UIStroke',self.panel,{Color=C.Ink,Thickness=3})
 self.scale=make('UIScale',self.panel,{Scale=1})
 local function text(name,y,h,size,font)
  return make('TextLabel',self.panel,{Name=name,Position=UDim2.new(0,24,0,y),Size=UDim2.new(1,-48,0,h),BackgroundTransparency=1,Text='',TextColor3=C.Ink,TextSize=size,Font=font or Enum.Font.GothamBold,TextWrapped=true,ZIndex=172})
 end
 self.car=text('Car',16,22,14);self.person=text('Person',43,24,17);self.person.RichText=true
 self.speech=text('BuyerWords',81,80,27,Enum.Font.GothamBold);self.speech.BackgroundColor3=Color3.fromRGB(224,229,219);self.speech.BackgroundTransparency=0
 make('UICorner',self.speech,{CornerRadius=UDim.new(0,12)});make('UIPadding',self.speech,{PaddingLeft=UDim.new(0,12),PaddingRight=UDim.new(0,12)})
 self.caption=text('OfferLabel',171,20,13);self.amount=text('Price',193,52,44,Enum.Font.GothamBlack)
 self.profit=text('Profit',249,25,16);self.profit.TextColor3=C.Green
 self.actions=make('Frame',self.panel,{Name='Actions',Position=UDim2.fromOffset(24,290),Size=UDim2.new(1,-48,0,112),BackgroundTransparency=1,ZIndex=173})
 local function button(name,label,parent)
  local b=make('TextButton',parent or self.actions,{Name=name,Text=label,TextSize=18,Font=Enum.Font.GothamBold,TextColor3=C.Ink,BackgroundColor3=C.SoftPanel,BorderSizePixel=0,AutoButtonColor=true,ZIndex=174})
  make('UICorner',b,{CornerRadius=UDim.new(0,11)});return b
 end
 self.primary=button('Accept','');self.primary.Position=UDim2.fromScale(0,0);self.primary.Size=UDim2.new(.62,-5,0,50);self.primary.BackgroundColor3=C.Green
 self.counter=button('Counter','Counter');self.counter.Position=UDim2.new(.62,5,0,0);self.counter.Size=UDim2.new(.38,-5,0,50)
 self.pause=button('Pause','Not now');self.pause.Position=UDim2.fromOffset(0,59);self.pause.Size=UDim2.new(.5,-4,0,44);self.pause.BackgroundTransparency=1
 self.dismiss=button('Dismiss','Dismiss buyer');self.dismiss.Position=UDim2.new(.5,4,0,59);self.dismiss.Size=UDim2.new(.5,-4,0,44);self.dismiss.BackgroundTransparency=1;self.dismiss.TextSize=15
 self.minus=button('Minus','−',self.panel);self.minus.Position=UDim2.fromOffset(24,198);self.minus.Size=UDim2.fromOffset(48,48)
 self.plus=button('Plus','+',self.panel);self.plus.AnchorPoint=Vector2.new(1,0);self.plus.Position=UDim2.new(1,-24,0,198);self.plus.Size=UDim2.fromOffset(48,48)
 self.number=Instance.new('NumberValue');self.number.Changed:Connect(function(n)self.amount.Text=cash(n)end)
 function self:send(suffix,amount)
  if self.pending then return end
  self.pending=true;local q=self.info.quote
  if suffix=='Counter' then self.scene:React('thinking') end
  event:FireServer((q.prefix or 'Trade')..suffix,{id=q.id,revision=q.revision,amount=amount})
  local revision=q.revision;task.delay(1.5,function()if self.info.quote and self.info.quote.revision==revision then self.pending=false end end)
 end
 self.primary.Activated:Connect(function()
  if self.fallback then event:FireServer(self.fallback[1].id);return end
  if self.confirmDismiss then self:send('Dismiss');return end
  self:send(self.editing and 'Counter' or 'Accept',self.editing and self.draft or nil)
 end)
 self.counter.Activated:Connect(function()
  if self.pending then return end
  if self.fallback then if self.fallback[2]then event:FireServer(self.fallback[2].id)end;return end
  if self.confirmDismiss then self.confirmDismiss=false;self:refresh();return end
  if not self.editing and not self.info.quote.canCounter then return end
  self.editing=not self.editing;self.draft=math.clamp(self.info.quote.suggest,self.info.quote.minimum,self.info.quote.maximum);self:refresh()
 end)
 self.pause.Activated:Connect(function()if self.fallback then event:FireServer('CloseDialogue')else self:send('Pause')end end)
 self.dismiss.Activated:Connect(function()if not self.pending then self.confirmDismiss=true;self.editing=false;self:refresh()end end)
 for _,pair in {{self.minus,-1},{self.plus,1}}do pair[1].Activated:Connect(function()if not self.pending and self.editing then local q=self.info.quote;self.draft=math.clamp(self.draft+q.step*pair[2],q.minimum,q.maximum);self:refresh()end end)end
 self.layout=function(view)
  local v=typeof(view)=='Vector2' and view or workspace.CurrentCamera.ViewportSize
  local portrait=v.X<v.Y;local compact=v.Y<550
  local w=portrait and math.min(420,v.X-24) or math.min(450,math.floor(v.X*.49)-24)
  local h=compact and 314 or 390
  self.scale.Scale=1
  self.panel.AnchorPoint=portrait and Vector2.new(.5,1) or Vector2.new(1,.5)
  self.panel.Position=portrait and UDim2.new(.5,0,1,-12) or UDim2.new(1,-20,.5,compact and 8 or 20)
  self.panel.Size=UDim2.fromOffset(w,h)
  local function rect(o,y,height) o.Position=UDim2.fromOffset(16,y);o.Size=UDim2.new(1,-32,0,height)end
  rect(self.car,compact and 10 or 16,18);rect(self.person,compact and 30 or 40,22)
  rect(self.speech,compact and 59 or 76,compact and 65 or 86);self.speech.TextSize=compact and 20 or 25
  rect(self.caption,compact and 130 or 172,18);self.caption.TextSize=11
  rect(self.amount,compact and 149 or 193,44);self.amount.TextSize=compact and 34 or 40
  rect(self.profit,compact and 195 or 241,20);self.profit.TextSize=compact and 13 or 15
  self.actions.Position=UDim2.fromOffset(16,compact and 225 or 286);self.actions.Size=UDim2.new(1,-32,0,90)
  self.primary.Size=UDim2.new(.61,-4,0,44);self.primary.TextSize=compact and 16 or 18
  self.counter.Position=UDim2.new(.61,4,0,0);self.counter.Size=UDim2.new(.39,-4,0,44);self.counter.TextSize=compact and 16 or 18
  self.pause.Position=UDim2.fromOffset(0,44);self.dismiss.Position=UDim2.new(.5,4,0,44);self.pause.TextSize=15;self.dismiss.TextSize=14
  self.minus.Position=UDim2.fromOffset(16,compact and 150 or 193);self.plus.Position=UDim2.new(1,-16,0,compact and 150 or 193)
  self.minus.Size=UDim2.fromOffset(44,44);self.plus.Size=UDim2.fromOffset(44,44)
 end
 workspace.CurrentCamera:GetPropertyChangedSignal('ViewportSize'):Connect(self.layout);self.layout();return self
end
function P:refresh()
 local info=self.info;local q=info.quote;local selling=info.mode=='Sell'
 local amount=self.editing and self.draft or info.price or 0
 if self.tween then self.tween:Cancel()end
 self.tween=Tween:Create(self.number,TweenInfo.new(.18,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Value=amount});self.tween:Play()
 self.minus.Visible=self.editing and not self.confirmDismiss;self.plus.Visible=self.minus.Visible
 self.caption.Text=self.editing and ('THEIR PRICE '..cash(info.price)..'  ·  YOUR COUNTER') or (q and q.agreed and 'AGREED PRICE' or selling and 'THEIR OFFER' or 'ASKING PRICE')
 local profit=selling and amount-(info.cost or 0)or (info.value or 0)-amount-(info.cost or 0)
 self.profit.Text=(profit<0 and '−' or '+')..cash(profit)..(selling and ' profit' or ' estimated profit')
 self.profit.Visible=info.price~=nil
 self.primary.Text=self.editing and 'Offer '..cash(amount)or(selling and 'Sell for 'or'Buy for ')..cash(amount)
 self.counter.Text=self.editing and 'Cancel' or 'Counter';self.counter.Visible=not q or q.canCounter or self.editing
 self.pause.Visible=true;self.dismiss.Visible=q and q.canDismiss or false
 self.pause.Size=UDim2.new(self.dismiss.Visible and .5 or 1,self.dismiss.Visible and -4 or 0,0,44)
 if self.confirmDismiss then self.speech.Text='Let this buyer go? The next offer may be lower.';self.primary.Text='Dismiss buyer';self.counter.Text='Keep offer';self.counter.Visible=true;self.dismiss.Visible=false
 else self.speech.Text=self.data.line or ''end
 if self.fallback then self.caption.Text='';self.amount.Text='';self.primary.Text=self.fallback[1]and self.fallback[1].text or 'Continue';self.counter.Visible=self.fallback[2]~=nil;if self.fallback[2]then self.counter.Text=self.fallback[2].text end end
end
function P:Show(data,head,state)
 self.data=data;self.info=data.deal or {};self.scene:Open(head,self.info.quote);self.editing=false;self.confirmDismiss=false;self.pending=false;self.fallback=not self.info.quote and data.options or nil
 self.panel.Visible=true;self.actions.Visible=true;self.car.Text=self.info.car or 'Make a deal'
 local role=self.info.quote and self.info.quote.role or 'Seller'
 local color=({Collector='#7144a1',['Daily driver']='#176874',Enthusiast='#965017',Seller='#506563'})[role]or'#506563'
 self.person.Text=(data.name or 'Seller')..'  ·  <font color="'..color..'">'..role..'</font>'
 self.number.Value=self.info.price or 0;self:refresh();self.layout()
 for _,o in self.dialogue:GetChildren()do if o:IsA('GuiObject')and o~=self.panel then o.Visible=false end end
end
function P:End(line)
 self.scene:React('leaving');self.speech.Text=line;self.pending=true;self.actions.Visible=false;self.minus.Visible=false;self.plus.Visible=false
end
function P:Hide()self.panel.Visible=false;self.pending=false end
return P

