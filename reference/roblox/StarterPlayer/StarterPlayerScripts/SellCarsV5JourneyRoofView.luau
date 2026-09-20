-- Studio-only viewing aid. Never changes replicated transparency or collisions.
if not game:GetService('RunService'):IsStudio() or game.PlaceId ~= 125334614375606 then return end
local player = game:GetService('Players').LocalPlayer
local pg = player:WaitForChild('PlayerGui')
local previous = pg:FindFirstChild('SellCarsV5RoofView')
if previous then previous:Destroy() end
local gui = Instance.new('ScreenGui')
gui.Name = 'SellCarsV5RoofView'
gui.ResetOnSpawn = false
gui.DisplayOrder = 101
gui.Parent = pg
local button = Instance.new('TextButton')
button.Name = 'RoofMode'
button.Position = UDim2.new(1, -516, 0, 16)
button.Size = UDim2.fromOffset(162, 32)
button.BackgroundColor3 = Color3.fromRGB(48, 70, 70)
button.TextColor3 = Color3.fromRGB(246, 233, 203)
button.Font = Enum.Font.GothamMedium
button.TextSize = 12
button.Parent = gui

local modes = {'AUTO', 'TRANSLUCENT', 'HIDDEN', 'SOLID'}
local amounts = {TRANSLUCENT = .92, HIDDEN = 1, SOLID = 0}
local modeIndex = 1
local tracked = {}
local connections = {}
local watched = setmetatable({}, {__mode = 'k'})
local alive = true
local roots = {SellCars_Dealership_FullJourney = true, SellCars_Dealership_Growth_V5 = true}
local function effectiveMode()
 if modes[modeIndex] ~= 'AUTO' then return modes[modeIndex] end
 local journey = pg:FindFirstChild('SellCarsV5FullJourney')
 return journey and journey:GetAttribute('SolidRoofRecommended') == true and 'SOLID' or 'TRANSLUCENT'
end

local function isRoof(part)
 if not part:IsA('BasePart') then return false end
 local n = part.Name:lower()
 -- Names observed in the actual build; do not classify generic slats, decks,
 -- gantries, lids, floors or entire shell folders as roofs.
 if n:find('waterproof', 1, true) or n:find('ceilingmount', 1, true) then return false end
 if n:find('roof', 1, true) or n:find('soffit', 1, true)
  or n:find('ceiling', 1, true) or n:find('canopy', 1, true) then return true end
 local parent = part.Parent
 while parent and parent ~= workspace do
  if parent.Name:match('Roof$') then return true end
  parent = parent.Parent
 end
 if n:find('standingseam', 1, true) then return true end
 if n == 'diffusegallerylight' or n == 'overheaddiffusionsail' then return true end
 local path = part:GetAttribute('FJ_Path') or part:GetFullName()
 if path:find('P013_Retained_Starter_Frame', 1, true) and n == 'corrugation' then return true end
 if path:find('01_Envelope_Finish', 1, true) then
  return n:find('fascia', 1, true) ~= nil or n:find('drip', 1, true) ~= nil
   or n == 'foldedsideflashing'
 end
 return false
end

local function apply(part, original)
 local amount = amounts[effectiveMode()]
 -- Compose with an existing local visibility effect; SOLID restores it exactly.
 part.LocalTransparencyModifier = 1 - (1 - original) * (1 - amount)
end

local function track(part)
 if tracked[part] ~= nil or not isRoof(part) then return end
 tracked[part] = part.LocalTransparencyModifier
 apply(part, tracked[part])
 gui:SetAttribute('RoofParts', (gui:GetAttribute('RoofParts') or 0) + 1)
end

local function watchRoot(root)
 if not roots[root.Name] or not root:IsA('Model') or watched[root] then return end
 watched[root] = true
 for _,part in root:GetDescendants() do track(part) end
 local added = root.DescendantAdded:Connect(track)
 table.insert(connections, added)
end

local function setMode(mode)
 local found = table.find(modes, mode)
 if not found then return end
 modeIndex = found
 local count = 0
 for part, original in tracked do
  if part.Parent then apply(part, original); count += 1 else tracked[part] = nil end
 end
 local effective = effectiveMode()
 button.Text = modes[modeIndex] == 'AUTO' and ('ROOFS: AUTO / ' .. (effective == 'SOLID' and 'SOLID' or 'OPEN')) or ('ROOFS: ' .. modes[modeIndex])
 gui:SetAttribute('Mode', modes[modeIndex])
 gui:SetAttribute('EffectiveMode', effective)
 gui:SetAttribute('RoofParts', count)
end

for _,root in workspace:GetChildren() do watchRoot(root) end
table.insert(connections, workspace.ChildAdded:Connect(watchRoot))
local function watchJourney(child)
 if child.Name ~= 'SellCarsV5FullJourney' then return end
 table.insert(connections, child:GetAttributeChangedSignal('SolidRoofRecommended'):Connect(function()
  if modes[modeIndex] == 'AUTO' then setMode('AUTO') end
 end))
 if modes[modeIndex] == 'AUTO' then setMode('AUTO') end
end
for _,child in pg:GetChildren() do watchJourney(child) end
table.insert(connections, pg.ChildAdded:Connect(watchJourney))
button.Activated:Connect(function()setMode(modes[modeIndex % #modes + 1])end)
local action = Instance.new('BindableEvent')
action.Name = 'SetRoofMode'
action.Parent = gui
action.Event:Connect(setMode)
gui.Destroying:Connect(function()
 if not alive then return end
 alive = false
 for _,connection in connections do connection:Disconnect() end
 for part, original in tracked do if part.Parent then part.LocalTransparencyModifier = original end end
 table.clear(tracked)
end)
setMode(modes[modeIndex])

