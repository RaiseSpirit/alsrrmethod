local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local gui = player:WaitForChild("PlayerGui")
local seedShop = gui:WaitForChild("Seed_Shop")
local scrollingFrame = seedShop.Frame:WaitForChild("ScrollingFrame")

local leaderstats = player:WaitForChild("leaderstats")
local sheckles = leaderstats:WaitForChild("Sheckles")

local buyEvent = ReplicatedStorage:WaitForChild("GameEvents"):WaitForChild("BuySeedStock")

local Config = getgenv().Config

for _, seedFrame in pairs(scrollingFrame:GetChildren()) do
    if seedFrame:IsA("Frame") then
        local seedName = seedFrame.Name
        if Config.SeedsBuyList[seedName] then
            local mainFrame = seedFrame:FindFirstChild("Main_Frame")
            if mainFrame then
                local costText = mainFrame:FindFirstChild("Cost_Text")
                local stockText = mainFrame:FindFirstChild("Stock_Text")

                if costText and stockText then
                    local function parseNumber(str)
                        local numStr = str:match("%d+%.?%d*")
                        if numStr then
                            return tonumber(numStr)
                        else
                            return nil
                        end
                    end

                    local cost = parseNumber(costText.Text)
                    local stock = parseNumber(stockText.Text)

                    if cost and stock then
                        if stock > 0 and sheckles.Value >= cost then
                            print("Buying seed:", seedName, "Cost:", cost, "Stock:", stock)
                            buyEvent:FireServer(seedName)
                            wait(0.5)
                        else
                            print("Cannot buy", seedName, "Stock:", stock, "Cost:", cost, "Sheckles:", sheckles.Value)
                        end
                    else
                        warn("Could not parse cost or stock for seed:", seedName)
                    end
                else
                    warn("Cost_Text or Stock_Text missing for seed:", seedName)
                end
            else
                warn("Main_Frame missing for seed:", seedName)
            end
        end
    end
end
function PickupFruits()
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local HRP = Character:WaitForChild("HumanoidRootPart")

    local Config = getgenv().Config or {}
    local PickupList = Config.PickupList or {}

    local Farm = workspace:FindFirstChild("Farm") and workspace.Farm:FindFirstChild("Farm")
    if not Farm then return end

    local OwnerValue = Farm.Important.Data:FindFirstChild("Owner")
    if not OwnerValue or OwnerValue.Value ~= LocalPlayer.Name then
        warn("Farm is not owned by you.")
        return
    end

    local Plants_Physical = Farm.Important:FindFirstChild("Plants_Physical")
    if not Plants_Physical then return end

    for _, plantModel in ipairs(Plants_Physical:GetChildren()) do
        local fruits = plantModel:FindFirstChild("Fruits")
        if fruits then
            for _, fruitContainer in ipairs(fruits:GetChildren()) do
                local fruitName = fruitContainer.Name
                if PickupList[fruitName] then
                    for _, fruitPart in ipairs(fruitContainer:GetChildren()) do
                        local prompt = fruitPart:FindFirstChildOfClass("ProximityPrompt")
                        if prompt and prompt.Enabled then
                            -- Teleport on top of the fruit and collect it
                            HRP.CFrame = fruitPart.CFrame + Vector3.new(0, 3, 0)
                            task.wait(0.2)
                            pcall(function()
                                prompt.HoldDuration = 0
                                prompt:InputHoldBegin()
                                task.wait(0.1)
                                prompt:InputHoldEnd()
                            end)
                            task.wait(0.2)
                        end
                    end
                end
            end
        end
    end
end

