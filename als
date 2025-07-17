--===[ Config must be set first externally using getgenv().Config ]===--

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local gui = player:WaitForChild("PlayerGui")
local leaderstats = player:WaitForChild("leaderstats")
local sheckles = leaderstats:WaitForChild("Sheckles")

local Config = getgenv().Config or { SeedsBuyList = {}, PickupList = {} }

--===[ BUYING SEEDS ]===--
local seedShop = gui:WaitForChild("Seed_Shop")
local scrollingFrame = seedShop.Frame:WaitForChild("ScrollingFrame")
local buyEvent = ReplicatedStorage:WaitForChild("GameEvents"):WaitForChild("BuySeedStock")

local function parseNumber(str)
    local numStr = str:match("%d+%.?%d*")
    return numStr and tonumber(numStr) or nil
end

for _, seedFrame in pairs(scrollingFrame:GetChildren()) do
    if seedFrame:IsA("Frame") then
        local seedName = seedFrame.Name
        if Config.SeedsBuyList[seedName] then
            local mainFrame = seedFrame:FindFirstChild("Main_Frame")
            if mainFrame then
                local costText = mainFrame:FindFirstChild("Cost_Text")
                local stockText = mainFrame:FindFirstChild("Stock_Text")

                if costText and stockText then
                    local cost = parseNumber(costText.Text)
                    local stock = parseNumber(stockText.Text)

                    if cost and stock then
                        if stock > 0 and sheckles.Value >= cost then
                            print("Buying:", seedName, "Cost:", cost, "Stock:", stock)
                            buyEvent:FireServer(seedName)
                            wait(0.5)
                        else
                            print("Too expensive or out of stock:", seedName)
                        end
                    else
                        warn("Could not parse cost/stock for", seedName)
                    end
                end
            end
        end
    end
end

--===[ PICKING PLANTS ]===--
local plantsFolder = workspace:WaitForChild("Farm"):WaitForChild("Farm"):WaitForChild("Important"):WaitForChild("Plants_Physical")

for _, plant in pairs(plantsFolder:GetChildren()) do
    local plantName = plant.Name
    if Config.PickupList[plantName] then
        local prompt = plant:FindFirstChildOfClass("ProximityPrompt") 
                    or plant:FindFirstChildWhichIsA("ProximityPrompt", true)

        if prompt then
            prompt:InputHoldBegin()
            wait(0.1)
            prompt:InputHoldEnd()
            print("Picked:", plantName)
        else
            print("No prompt found for:", plantName)
        end
    end
end
