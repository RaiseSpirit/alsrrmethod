print(hi its working)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local leaderstats = player:WaitForChild("leaderstats")
local moneyValue = leaderstats:WaitForChild("Sheckles")

local buySeedRemote = ReplicatedStorage:WaitForChild("GameEvents"):WaitForChild("BuySeedStock")
local seedShopFrame = playerGui:WaitForChild("Seed_Shop"):WaitForChild("Frame"):WaitForChild("ScrollingFrame")

local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
if not hrp then return end

local farmFolder = workspace:WaitForChild("Farm"):WaitForChild("Farm"):WaitForChild("Important"):WaitForChild("Plants_Physical")

local function buySeeds()
    for _, seedFrame in pairs(seedShopFrame:GetChildren()) do
        if seedFrame:IsA("Frame") then
            local seedName = seedFrame.Name
            if getgenv().Config.SeedsBuyList[seedName] then
                local mainFrame = seedFrame:FindFirstChild("Main_Frame")
                if mainFrame then
                    local costLabel = mainFrame:FindFirstChild("Cost_Text")
                    local stockLabel = mainFrame:FindFirstChild("Stock_Text")
                    if costLabel and stockLabel then
                        local cost = tonumber(costLabel.Text:gsub("%D", "")) or math.huge
                        local stock = tonumber(stockLabel.Text) or 0
                        local money = moneyValue.Value
                        
                        if money >= cost and stock > 0 then
                            buySeedRemote:FireServer(seedName)
                            print("Bought seed:", seedName, "Cost:", cost, "Money left:", money - cost)
                        end
                    end
                end
            end
        end
    end
end

local function fireProxAtDistance(prompt, part)
    local originalPos = hrp.CFrame
    hrp.CFrame = part.CFrame + Vector3.new(0, 3, 0)
    wait(0.1)
    fireproximityprompt(prompt, 1)
    wait(0.1)
    hrp.CFrame = originalPos
end

local function pickupAll()
    for _, plantType in ipairs(farmFolder:GetChildren()) do
        local plantName = plantType.Name
        if getgenv().Config.PickupList[plantName] then
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
end

-- Main loop, runs forever with delays between actions
while true do
    pcall(buySeeds)
    pcall(pickupAll)
    wait(5) -- Adjust delay as needed
end
