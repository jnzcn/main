repeat wait() until game:IsLoaded() and game.Players.LocalPlayer
local Teams = game:GetService("Teams")
local Players = game:GetService("Players")

local TeamToJoin = Teams["Pirates"] -- Thay "Pirates" bằng tên của team bạn muốn người chơi tự động chọn

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        if not player.Team then
            player.Team = TeamToJoin
        end
    end)
end)

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

wait (1.2)
game:GetService("Players").LocalPlayer:Kick("You have been permanently banned.")
