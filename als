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
