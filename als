--[[ 
Expected config outside this script, like:

getgenv().Config = {
    PickupList = {
        ["Carrot"] = false,
        ["Strawberry"] = true,
        ["Watering Can"] = true,
        ["Common Egg"] = false,
        -- etc, include plants, gears, eggs, whatever you want to pick
    }
}
]]

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
if not hrp then return end

local farmFolder = workspace:WaitForChild("Farm"):WaitForChild("Farm"):WaitForChild("Important"):WaitForChild("Plants_Physical")

local function fireProxAtDistance(prompt, part)
    local originalPos = hrp.CFrame
    hrp.CFrame = part.CFrame + Vector3.new(0, 3, 0)
    wait(0.1)
    fireproximityprompt(prompt, 1)
    wait(0.1)
    hrp.CFrame = originalPos
end

for _, plantType in ipairs(farmFolder:GetChildren()) do
    local plantName = plantType.Name
    if getgenv().Config and getgenv().Config.PickupList and getgenv().Config.PickupList[plantName] then
        local fruitsFolder = plantType:FindFirstChild("Fruits")
        if fruitsFolder then
            for _, fruitModel in ipairs(fruitsFolder:GetChildren()) do
                for _, part in ipairs(fruitModel:GetChildren()) do
                    if part:IsA("BasePart") then
                        local prompt = part:FindFirstChildWhichIsA("ProximityPrompt", true)
                        if prompt and prompt.Enabled then
                            fireProxAtDistance(prompt, part)
                            wait(0.3)
                        end
                    end
                end
            end
        end
    end
end
