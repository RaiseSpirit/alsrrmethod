task.wait(2)
local args = {
    [1] = "Play",
    [2] = 0,
    [3] = "True"
}

game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("InfiniteCastleManager"):FireServer(unpack(args))
