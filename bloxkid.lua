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
    wait(1.5)
    require(game.ReplicatedStorage.Notification).new("<Color=Red> Your Mom Fat <Color=/>"):Display()
    require(game.ReplicatedStorage.Notification).new("<Color=Yellow> Tuan Nguyen Is The Best <Color=/>"):Display()
end)