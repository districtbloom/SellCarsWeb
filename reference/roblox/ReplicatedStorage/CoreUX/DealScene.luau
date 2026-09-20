-- Local direction only: framing and expressive face; never changes the negotiated outcome.
local S={};S.__index=S
local Tween=game:GetService('TweenService')
function S.new(gui)
 local self=setmetatable({gui=gui,hidden={}},S)
 workspace.CurrentCamera:GetPropertyChangedSignal('ViewportSize'):Connect(function()if self.head then self:Frame()end end)
 return self
end
function S:Frame()
 local camera=workspace.CurrentCamera;local v=camera.ViewportSize;local h=self.head
 if not h or not h.Parent then return end
 local portrait=v.X<v.Y
 local distance=portrait and 8 or 8.5;local fov=45
 local center=h.Position+Vector3.new(0,-.9,0)
 local base=CFrame.lookAt(h.Position+h.CFrame.LookVector*distance+Vector3.new(0,.3,0),center)
 local offset=portrait and 0 or distance*math.tan(math.rad(fov/2))*(v.X/v.Y)*.48
 local shot=base+base.RightVector*offset
 if self.cameraTween then self.cameraTween:Cancel()end
 camera.CameraType=Enum.CameraType.Scriptable
 self.cameraTween=Tween:Create(camera,TweenInfo.new(.3,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{CFrame=shot,FieldOfView=fov});self.cameraTween:Play()
end
function S:React(mood)
 if not self.face then return end
 -- Readable, restrained expressions on the existing block-character face.
 self.face.Text=({neutral='•  •\n╰─╯',thinking='•  •\n ─ ',firm='•  •\n ━ ',happy='^  ^\n╰─╯',leaving='•  •\n╭─╮'})[mood]or'•  •\n╰─╯'
 self.face.TextScaled=true
 self.gui:SetAttribute('DealReaction',mood)
end
function S:Open(head,quote)
 if self.head~=head then
  self:Close();self.head=head
  local face=head and head:FindFirstChild('Face');self.face=face and face:FindFirstChild('Expression')
  if self.face then self.originalText=self.face.Text;self.originalScaled=self.face.TextScaled end
  local character=game.Players.LocalPlayer.Character
  if character then for _,p in character:GetDescendants()do if p:IsA('BasePart')then self.hidden[p]=p.LocalTransparencyModifier;p.LocalTransparencyModifier=1 end end end
  self:Frame()
 end
 self.gui:SetAttribute('DealSceneActive',true)
 self:React(quote and quote.agreed and 'happy' or quote and quote.final and 'firm' or 'neutral')
end
function S:Close()
 if self.cameraTween then self.cameraTween:Cancel()end
 if self.face and self.face.Parent then self.face.Text=self.originalText;self.face.TextScaled=self.originalScaled end
 for p,t in self.hidden do if p.Parent then p.LocalTransparencyModifier=t end end;table.clear(self.hidden)
 self.head=nil;self.face=nil;self.gui:SetAttribute('DealSceneActive',false)
end
return S

