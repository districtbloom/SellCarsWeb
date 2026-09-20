-- Persistent host owns occupation callback lifetime. No per-person scripts.
local api=require(game.ServerStorage.SellCarsV5InstitutionFidelityPhase7C2ARearOccupationInstaller)
local bridge=Instance.new("BindableFunction");bridge.Name="RuntimeDispatch"
bridge.OnInvoke=function(method,...)
 if method=="Start" then return api._Start(...)
 elseif method=="Stop" then return api._Stop(...)
 elseif method=="Trigger" then return api._Trigger(...)
 elseif method=="SetEnabled" then return api._SetEnabled(...)
 elseif method=="SetAmbient" then return api._SetAmbient(...)
 elseif method=="GetState" then return api._GetState(...)
 else error("Unknown occupation command") end
end
bridge.Parent=script
api._Start()
script.Destroying:Connect(function() api._Stop() end)

