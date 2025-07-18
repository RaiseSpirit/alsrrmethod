-- Hardcoded Plant Positions (vector.create)
local PlantPositions = {
    vector.create(-28.2359, 2, -54.3214),
    vector.create(-36.6004, 2, -21.4151),
    vector.create(-1.4068, 2.1355, -101.6832),
}

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local VirtualInput = game:GetService("VirtualInputManager")

-- Player & Character
local player = Players.LocalPlayer
local gui = player:WaitForChild("PlayerGui")
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")
local backpack = player:WaitForChild("Backpack")


-- Remote Events
local buyEvent = ReplicatedStorage:WaitForChild("GameEvents"):WaitForChild("BuySeedStock")
local SellInventoryEvent = ReplicatedStorage:WaitForChild("GameEvents"):WaitForChild("Sell_Inventory")
local PlantRE = ReplicatedStorage:WaitForChild("GameEvents"):WaitForChild("Plant_RE")

-- UI Elements
local seedShop = gui:WaitForChild("Seed_Shop")
local scrollingFrame = seedShop.Frame:WaitForChild("ScrollingFrame")
local leaderstats = player:WaitForChild("leaderstats")
local sheckles = leaderstats:WaitForChild("Sheckles")
local TeleportUI = player.PlayerGui:WaitForChild("Teleport_UI")
local GardenButton = TeleportUI.Frame:WaitForChild("Garden")

-- Crop pickup count tracker
local cropPickupCount = 0

--== BLACKSCREEN UI ==--
local StatusLabel = nil
local function createStatusUI()
    if not Config.ShowBlackscreen then return nil end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "StatusUI"
    screenGui.IgnoreGuiInset = true
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.DisplayOrder = 999999
    screenGui.Parent = gui

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundColor3 = Color3.new(0, 0, 0)
    frame.ZIndex = 999999
    frame.BorderSizePixel = 0
    frame.Parent = screenGui

    local ignLabel = Instance.new("TextLabel")
    ignLabel.Size = UDim2.new(1, 0, 0.2, 0)
    ignLabel.Position = UDim2.new(0, 0, 0.2, 0)
    ignLabel.BackgroundTransparency = 1
    ignLabel.TextColor3 = Color3.new(1, 1, 1)
    ignLabel.TextScaled = true
    ignLabel.Font = Enum.Font.SourceSansBold
    ignLabel.ZIndex = 999999
    ignLabel.Text = "IGN: " .. player.Name
    ignLabel.Parent = frame

    local statusLabel = Instance.new("TextLabel")
    statusLabel.Size = UDim2.new(1, 0, 0.2, 0)
    statusLabel.Position = UDim2.new(0, 0, 0.5, 0)
    statusLabel.BackgroundTransparency = 1
    statusLabel.TextColor3 = Color3.new(1, 1, 1)
    statusLabel.TextScaled = true
    statusLabel.Font = Enum.Font.SourceSans
    statusLabel.ZIndex = 999999
    statusLabel.Text = "Waiting..."
    statusLabel.Parent = frame

    return statusLabel
end

StatusLabel = createStatusUI()

local function setStatus(text)
    if StatusLabel then
        StatusLabel.Text = text
    end
    print("[STATUS]: " .. text)
end

--== Farm Detection ==--
local function getFarmImportant()
    local farm = workspace:FindFirstChild("Farm")
    if not farm then return nil end
    if farm:FindFirstChild("Farm") and farm.Farm:FindFirstChild("Important") then
        return farm.Farm.Important
    elseif farm:FindFirstChild("Important") then
        return farm.Important
    end
    return nil
end

local function getPlantsPhysical()
    local important = getFarmImportant()
    return important and important:FindFirstChild("Plants_Physical") or nil
end

--== Seed Buying ==--
local function buySeeds()
    if not Config.SeedsBuyList then return end
    setStatus("Buying seeds...")
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
                            return numStr and tonumber(numStr)
                        end

                        local cost = parseNumber(costText.Text)
                        local stock = parseNumber(stockText.Text)

                        if cost and stock and stock > 0 and sheckles.Value >= cost then
                            print("Buying seed:", seedName, "Cost:", cost, "Stock:", stock)
                            buyEvent:FireServer(seedName)
                            task.wait(0.5)
                        end
                    end
                end
            end
        end
    end
end

--== AutoPlant Function ==--

local function findToolForSeed(seedName)
    local targetName = seedName .. " Seed"
    for _, tool in ipairs(backpack:GetChildren()) do
        if tool:IsA("Tool") and tool.Name:lower():find(targetName:lower()) then
            return tool
        end
    end
    for _, tool in ipairs(character:GetChildren()) do
        if tool:IsA("Tool") and tool.Name:lower():find(targetName:lower()) then
            return tool
        end
    end
    return nil
end

local function equipTool(tool)
    if tool then
        humanoid:EquipTool(tool)
        for _ = 1, 10 do
            if character:FindFirstChildOfClass("Tool") == tool then
                return true
            end
            task.wait(0)
        end
    end
    return false
end

local function autoplantSeeds()
    if not Config.Autoplant then return end
    setStatus("Auto-planting seeds...")

    for seedName, enabled in pairs(Config.AutoplantList) do
        if enabled then
            local tool = findToolForSeed(seedName)
            if tool then
                local equipped = equipTool(tool)
                if not equipped then
                    warn("Failed to equip tool for seed: " .. seedName)
                    continue
                end

                for _, pos in ipairs(PlantPositions) do
                    local plantPos = pos + Config.PlantOffset
                    setStatus("Planting " .. seedName .. " at " .. tostring(plantPos))
                    PlantRE:FireServer(plantPos, seedName)
                    cropPickupCount = cropPickupCount + 1
                    task.wait(0.7)
                end
            else
                warn("No seed tool found for " .. seedName)
            end
        end
    end
end

--== Fruit Pickup ==--
local function PickupFruits()
    local HRP = character:FindFirstChild("HumanoidRootPart")
    if not HRP then return false end

    local PickupList = Config.PickupList or {}
    local Important = getFarmImportant()
    if not Important then return false end

    local Data = Important:FindFirstChild("Data")
    if not Data or not Data:FindFirstChild("Owner") then return false end
    if Data.Owner.Value ~= player.Name then return false end

    local Plants_Physical = Important:FindFirstChild("Plants_Physical")
    if not Plants_Physical then return false end

    local didPickup = false
    for _, plantModel in ipairs(Plants_Physical:GetChildren()) do
        local fruits = plantModel:FindFirstChild("Fruits")
        if fruits then
            for _, fruitContainer in ipairs(fruits:GetChildren()) do
                if PickupList[fruitContainer.Name] then
                    for _, fruitPart in ipairs(fruitContainer:GetChildren()) do
                        if fruitPart:IsA("BasePart") then
                            local prompt = fruitPart:FindFirstChildOfClass("ProximityPrompt")
                            if prompt and prompt.Enabled then
                                setStatus("Picking up crops...")
                                HRP.CFrame = fruitPart.CFrame + Vector3.new(0, 3, 0)
                                task.wait(0.2)
                                pcall(function()
                                    prompt.HoldDuration = 0
                                    prompt:InputHoldBegin()
                                    task.wait(0.1)
                                    prompt:InputHoldEnd()
                                end)
                                task.wait(0.2)
                                didPickup = true
                                cropPickupCount = cropPickupCount + 1
                                print("Picked crop count:", cropPickupCount)
                                if cropPickupCount >= Config.SellAfterCount then
                                    return true, true
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    return didPickup, false
end

--== Proxy Pickup ==--
local function shouldPickup(itemName)
    for plant, enabled in pairs(Config.PickupList or {}) do
        if enabled and string.find(itemName:lower(), plant:lower()) then
            return true
        end
    end
    return false
end

local function pickupNearby()
    local pickupFolder = getPlantsPhysical()
    if not pickupFolder or not Config.Enabled then return false end

    local didPickup = false
    for _, item in ipairs(pickupFolder:GetChildren()) do
        if shouldPickup(item.Name) then
            local primary = item:FindFirstChild("PrimaryPart") or item:FindFirstChildWhichIsA("BasePart")
            if primary and (primary.Position - rootPart.Position).Magnitude <= (Config.Range or 20) then
                local prompt = item:FindFirstChildWhichIsA("ProximityPrompt", true)
                if prompt then fireproximityprompt(prompt) end
                didPickup = true
                cropPickupCount = cropPickupCount + 1
                print("Picked crop count:", cropPickupCount)
                if cropPickupCount >= Config.SellAfterCount then
                    return true, true
                end
            end
        end
    end
    return didPickup, false
end

--== Autosell ==--
local function doAutosell()
    setStatus("Selling inventory...")
    rootPart.CFrame = CFrame.new(Config.SellTeleportPosition)
    task.wait(0.5)
    SellInventoryEvent:FireServer()

    GuiService.SelectedObject = GardenButton
    task.wait(0.1)
    VirtualInput:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
    task.wait(0.1)
    VirtualInput:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
    GuiService.SelectedObject = nil

    cropPickupCount = 0
    setStatus("Waiting to pick up...")
end

--== Main Loop ==--
task.spawn(function()
    setStatus("Waiting to pick up...")
    while true do
        task.wait(Config.Interval or 1)
        if Config.Enabled then
            buySeeds()
            autoplantSeeds()
            local didPickupFruits, forceSellFruits = PickupFruits()
            local didPickupProxies, forceSellProxies = pickupNearby()

            if Config.Autosell and (forceSellFruits or forceSellProxies) then
                doAutosell()
            elseif Config.Autosell and not (didPickupFruits or didPickupProxies) and cropPickupCount >= Config.SellAfterCount then
                doAutosell()
            end
        end
    end
end)
