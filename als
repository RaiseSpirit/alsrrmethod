-- CONFIG
local FOUND_WEBHOOK = "https://discord.com/api/webhooks/1367259636616663122/pYz5XUFncqU_Bh4o6zwpOYeac5nlPlSbio8VcvFFT17jAd6se3kLmR5f2gaqueDJh5Rh" -- Egg found
local LOG_WEBHOOK = "https://discord.com/api/webhooks/1128856038137933885/5QenGJa5Ip8gb7rBLJs_q9gkYhsL134ARFz8HVTp0obEyE6jQiVULi7-pSgcKeu8OMQh"   -- Joined server log
local FIREBASE_URL = "https://robloxeggtracker-default-rtdb.firebaseio.com/joinedServers.json" -- grog dont try skid ur dumb
local GAME_ID = 85896571713843

local HttpService = game:GetService("HttpService")
local TPService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Send message to webhook
local function sendWebhook(url, msg)
    local payload = HttpService:JSONEncode({content = msg})
    pcall(function()
        request({
            Url = url,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = payload
        })
    end)
end

-- Read joined servers from Firebase
local function getJoinedServers()
    local success, response = pcall(function()
        return HttpService:GetAsync(FIREBASE_URL)
    end)
    if success and response then
        local data = HttpService:JSONDecode(response)
        local list = {}
        for serverId, _ in pairs(data or {}) do
            list[serverId] = true
        end
        return list
    else
        warn("Failed to get Firebase data")
        return {}
    end
end

-- Add current server to Firebase
local function markServerAsJoined(serverId)
    local payload = HttpService:JSONEncode(true)
    pcall(function()
        request({
            Url = FIREBASE_URL:gsub("%.json", "/" .. serverId .. ".json"),
            Method = "PUT",
            Headers = {["Content-Type"] = "application/json"},
            Body = payload
        })
    end)
    sendWebhook(LOG_WEBHOOK, "[JOINED] Server ID: " .. serverId)
end

-- Scan workspace for egg
local function scanForEgg()
    for _, egg in ipairs(workspace:GetDescendants()) do
        if egg:IsA("Model") and egg.Name:lower():find("egg") then
            local name = egg.Name:lower()
            if name:find("silly") then return "SILLY EGG" end
            if name:find("rainbow") then return "Rainbow Egg" end
            if name:find("void") then return "Void Egg" end
        end
    end
end

-- Get public servers list
local function getServers()
    local servers, cursor = {}, ""
    while true do
        local url = ("https://games.roblox.com/v1/games/%s/servers/Public?sortOrder=Asc&limit=100&cursor=%s"):format(GAME_ID, cursor)
        local success, result = pcall(function()
            return HttpService:JSONDecode(game:HttpGet(url))
        end)
        if success and result and result.data then
            for _, server in ipairs(result.data) do
                if server.playing < server.maxPlayers then
                    table.insert(servers, server)
                end
            end
            if result.nextPageCursor then
                cursor = result.nextPageCursor
            else
                break
            end
        else
            break
        end
    end
    return servers
end

-- MAIN
local function run()
    task.wait(5)

    local found = scanForEgg()
    if found then
        sendWebhook(FOUND_WEBHOOK, ("**%s FOUND!** [Join it](https://www.roblox.com/games/%s)"):format(found, GAME_ID))
        if found:lower():find("silly") then return end -- only stop for silly
    end

    local joined = getJoinedServers()
    local servers = getServers()

    for _, server in ipairs(servers) do
        if not joined[server.id] then
            markServerAsJoined(server.id)
            TPService:TeleportToPlaceInstance(GAME_ID, server.id, LocalPlayer)
            break
        end
    end
end

run()
