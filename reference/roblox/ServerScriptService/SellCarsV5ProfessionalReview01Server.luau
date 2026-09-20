-- Studio-only phase review host. Never exposes a chapter mutation remote in a live game.
if not game:GetService("RunService"):IsStudio() or game.PlaceId~=125334614375606 then return end
local api=require(game.ServerStorage.SellCarsV5ProfessionalReview01)
local remote=Instance.new("RemoteEvent");remote.Name="SellCarsV5ProfessionalReview01";remote.Parent=game.ReplicatedStorage
local last={}
remote.OnServerEvent:Connect(function(player,chapter)
 if chapter~="INSTITUTION" and chapter~="PROFESSIONAL" then return end
 local now=os.clock();if last[player] and now-last[player]<.8 then return end;last[player]=now
 local ok,result=pcall(api.SetChapter,chapter)
 remote:FireClient(player,ok,ok and result.chapter or tostring(result))
end)
game.Players.PlayerRemoving:Connect(function(player)last[player]=nil end)

