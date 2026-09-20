-- Source owned by Institution 7C1. This persistent host owns callback lifetimes.
local api = require(game.ServerStorage.SellCarsV5InstitutionFidelityPhase7C1ActivityInstaller)
local bridge = Instance.new("BindableFunction")
bridge.Name = "RuntimeDispatch"
bridge.OnInvoke = function(method, ...)
 if method == "Start" then return api._Start(...)
 elseif method == "Stop" then return api._Stop(...)
 elseif method == "SetJob" then return api._SetJob(...)
 elseif method == "Cancel" then return api._Cancel(...)
 elseif method == "GetState" then return api._GetState(...)
 else error("Unknown Institution activity request") end
end
bridge.Parent = script
api._Start()
script.Destroying:Connect(function() api._Stop() end)

