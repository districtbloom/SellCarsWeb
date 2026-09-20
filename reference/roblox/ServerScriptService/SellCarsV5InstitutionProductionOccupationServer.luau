-- Persistent shared host; never attach callbacks to a temporary tool caller.
local api=require(game.ServerStorage.SellCarsV5InstitutionFidelityPhase7C2B1ProductionOccupationInstaller)
local b=Instance.new("BindableFunction");b.Name="RuntimeDispatch"
b.OnInvoke=function(method,...)
 if method=="Start" then return api._Start(...)
 elseif method=="Stop" then return api._Stop(...)
 elseif method=="SetJob" then return api._SetJob(...)
 elseif method=="Cancel" then return api._Cancel(...)
 elseif method=="SetEnabled" then return api._SetEnabled(...)
 elseif method=="GetState" then return api._GetState(...)
 else error("Unknown production occupation command") end
end
b.Parent=script
api._Start()
script.Destroying:Connect(function() api._Stop() end)

