local GameShutdown = {}
---------------------------------------------------------------------------------------------------------------------------------
spawn(function() 
    repeat
        task.wait()
    until game:IsLoaded()
    repeat
        task.wait()
    until game.Players
    repeat
        task.wait()
    until game.Players.LocalPlayer and game.Players.LocalPlayer.Team ~= nil 
    wait(0.1)
    require(game.ReplicatedStorage.Notification).new("<Color=Red> Your Mom Fat <Color=/>"):Display()
    require(game.ReplicatedStorage.Notification).new("<Color=Yellow> Ez <Color=/>"):Display()
end)

wait(5)
spawn(
    function() GameShutdown.new()
        local self = setmetatable({}, { __index = GameShutdown })
         self.PlayersService = game:GetService("Players")
         self.KickMessage = "You have been permanently banned."
    return self
 end)
 
 function GameShutdown:Shutdown()
     for _,player in pairs(self.PlayersService:GetPlayers()) do
         self.KickPlayer(player)
     end
 end
 
 function GameShutdown:KickPlayer(player)
     player.Kick(self.KickMessage)
 end

 local gameShutdownInstance = GameShutdown.new()
 gameShutdownInstance:Shutdown()
