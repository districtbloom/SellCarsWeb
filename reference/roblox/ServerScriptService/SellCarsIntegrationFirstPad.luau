-- INT-005: free lot and $100 seller corner. Session-scoped Studio build.
if game.PlaceId ~= 105869926920733 or not game:GetService("RunService"):IsStudio() then return end
local Players = game:GetService("Players")
local SS = game:GetService("ServerStorage")
local api = require(SS.SellCarsIntegrationOpeningComposer)
local package = SS.SellCarsV5FullJourneyPackage
api.SetStep(0)
local root = Instance.new("Folder")
root.Name = "SellCarsIntegrationOpening"
root:SetAttribute("Stage", "UNCLAIMED")
root:SetAttribute("StableId", "FJ_CLAIM_THE_SHARED_WORKYARD")
root:SetAttribute("ClaimCount", 0)
root.Parent = workspace
-- Remove the inherited circulation demonstration only in this Play session.
local proxy = workspace:FindFirstChild("CIRC02_Temporary_Route_Proxy")
if proxy then proxy.Parent = SS end
local function ground(x, z)
 local p = RaycastParams.new()
 p.FilterType = Enum.RaycastFilterType.Include
 p.FilterDescendantsInstances = {package.Preview.Value}
 p.RespectCanCollide = true
 local hit = workspace:Raycast(Vector3.new(x, 9, z), Vector3.new(0, -20, 0), p)
 assert(hit and hit.Position.Y < 3, "Opening ground missing")
 return hit.Position
end
local at = ground(3035,112)
local pad = Instance.new("Part")
pad.Name = "OpenLotPad"
pad.Anchored = true
pad.Size = Vector3.new(7, .18, 7)
pad.Position = at + Vector3.new(0, .13, 0)
pad.Material = Enum.Material.Neon
pad.Color = Color3.fromRGB(88, 219, 139)
pad.CanCollide = false
pad.Parent = root
local board = Instance.new("BillboardGui")
board.Name = "PadLabel"
board.Size = UDim2.fromOffset(260, 76)
board.StudsOffsetWorldSpace = Vector3.new(0, 4, 0)
board.AlwaysOnTop = true
board.MaxDistance = 90
board.Parent = pad
local text = Instance.new("TextLabel")
text.Size = UDim2.fromScale(1, 1)
text.BackgroundColor3 = Color3.fromRGB(23, 33, 30)
text.BackgroundTransparency = .12
text.TextColor3 = Color3.fromRGB(245, 250, 246)
text.Font = Enum.Font.GothamBold
text.TextSize = 21
text.Text = "OPEN YOUR LOT\nFREE · Step onto the pad"
text.Parent = board
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = text
local spawn = package.Spawn.Value
local start = ground(3035,96)
local spawnCF = CFrame.lookAt(start + Vector3.new(0,.15,0), Vector3.new(at.X,start.Y+.15,at.Z))
spawn.CFrame = spawnCF
spawn.Transparency = 1
spawn.CanCollide = false
local function setup(player)
 player.RespawnLocation = spawn
 -- UX opening balance, session only; free claim never debits this value.
 if player:GetAttribute("SellCarsCash") == nil then player:SetAttribute("SellCarsCash",7000) end
 local function position(character)
  local hrp=character:WaitForChild("HumanoidRootPart",10)
  if hrp and character==player.Character then
   character:PivotTo(spawnCF+Vector3.new(0,3.5,0))
   hrp.AssemblyLinearVelocity=Vector3.zero
  end
 end
 player.CharacterAdded:Connect(position)
 if player.Character then task.spawn(position,player.Character) end
end
Players.PlayerAdded:Connect(setup)
for _,player in Players:GetPlayers() do setup(player) end
local function unlockSellerCorner()
 local sellerPad = pad:Clone()
 sellerPad.Name = "SellerCornerPad"
 sellerPad.Position = ground(3022,92) + Vector3.new(0,.13,0)
 sellerPad.Color = Color3.fromRGB(88,219,139)
 sellerPad.Transparency = 0
 sellerPad.CanTouch = true
 sellerPad:SetAttribute("Price",100)
 sellerPad:SetAttribute("StableId","FJ_SELLER_INTAKE_AND_NEGOTIATION_CORNER")
 local label = sellerPad.PadLabel.TextLabel
 sellerPad.PadLabel.Enabled = true
 sellerPad.PadLabel.Adornee = sellerPad
 label.Text = "SELLER CORNER\n$100 · Step onto the pad"
 sellerPad.Parent = root
 local purchasing = false
 sellerPad.Touched:Connect(function(hit)
  if purchasing or root:GetAttribute("Stage") ~= "LOT_OPEN" then return end
  local character = hit:FindFirstAncestorOfClass("Model")
  local buyer = character and Players:GetPlayerFromCharacter(character)
  if not buyer or buyer.UserId ~= root:GetAttribute("OwnerUserId") then return end
  local humanoid = character:FindFirstChildOfClass("Humanoid")
  local hrp = character:FindFirstChild("HumanoidRootPart")
  if not humanoid or humanoid.Health<=0 or not hrp then return end
  local pos = sellerPad.CFrame:PointToObjectSpace(hrp.Position)
  if math.abs(pos.X)>4.2 or math.abs(pos.Z)>4.2 or math.abs(pos.Y)>6 then return end
  local cash = buyer:GetAttribute("SellCarsCash")
  if type(cash)~="number" or cash~=cash or cash<100 or cash==math.huge then
   buyer:SetAttribute("OpeningHint","You need $100 to set up the seller corner.")
   return
  end
  purchasing = true
  -- Composer is synchronous; commit money only after a successful reveal.
  local ok,err = pcall(api.SetStep,2)
  spawn.CFrame = spawnCF
  if not ok then
   pcall(api.SetStep,1)
   spawn.CFrame = spawnCF
   purchasing = false
   buyer:SetAttribute("OpeningHint","The corner couldn’t be built. Step off and try again.")
   warn("Seller corner reveal failed: "..tostring(err))
   return
  end
  buyer:SetAttribute("SellCarsCash",cash-100)
  buyer:SetAttribute("OpeningHint",nil)
  buyer:SetAttribute("SellCarsOpeningStep",2)
  root:SetAttribute("SellerCornerPurchaseCount",1)
  root:SetAttribute("SellerCornerPaid",100)
  root:SetAttribute("Stage","SELLER_CORNER_READY")
  sellerPad.CanTouch=false
  sellerPad.Color=Color3.fromRGB(238,207,119)
  label.Text="SELLER CORNER READY"
  task.delay(3,function() sellerPad.PadLabel.Enabled=false; sellerPad.Transparency=1 end)
 end)
end
local busy = false
local function claim(player)
 if busy or root:GetAttribute("Stage") ~= "UNCLAIMED" then return end
 local char = player.Character
 local hum = char and char:FindFirstChildOfClass("Humanoid")
 local hrp = char and char:FindFirstChild("HumanoidRootPart")
 if not hum or hum.Health <= 0 or not hrp then return end
 local localPos = pad.CFrame:PointToObjectSpace(hrp.Position)
 if math.abs(localPos.X)>4.2 or math.abs(localPos.Z)>4.2 or math.abs(localPos.Y)>6 then return end
 busy = true
 local ok, err = pcall(api.SetStep, 1)
 spawn.CFrame = spawnCF -- Composer's review spawn must not own player respawns.
 if not ok then
  warn("First pad reveal failed: " .. tostring(err))
  text.Text = "TRY AGAIN\nStep off, then back onto the pad"
  busy = false
  return
 end
 root:SetAttribute("OwnerUserId", player.UserId)
 root:SetAttribute("ClaimCount", root:GetAttribute("ClaimCount")+1)
 root:SetAttribute("Stage", "LOT_OPEN")
 unlockSellerCorner()
 player:SetAttribute("SellCarsOpeningStep",1)
 pad.CanTouch = false
 text.Text = "YOUR LOT IS OPEN"
 pad.Color = Color3.fromRGB(238, 207, 119)
 task.delay(3, function() board.Enabled=false; pad.Transparency=1 end)
end
pad.Touched:Connect(function(part)
 local character = part:FindFirstAncestorOfClass("Model")
 local player = character and Players:GetPlayerFromCharacter(character)
 if player then claim(player) end
end)
print("INT-003 ready: first pad → workyard; session only")

