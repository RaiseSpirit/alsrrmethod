game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(26.264843, 2.77689433, -38.3558578, 0.195475832, 0, -0.980708539, 0, 1, 0, 0.980708539, 0, 0.195475832)


task.wait(0.5)

local args = {
    [1] = "Play",
    [2] = 0,
    [3] = "True"
}

game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("InfiniteCastleManager"):FireServer(unpack(args))
