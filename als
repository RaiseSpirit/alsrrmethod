-- CONFIG
local placeId = 85896571713843 -- Confirmed BSGI place ID
local maxServers = 200
local webhookUrl = "https://discord.com/api/webhooks/1128856038137933885/5QenGJa5Ip8gb7rBLJs_q9gkYhsL134ARFz8HVTp0obEyE6jQiVULi7-pSgcKeu8OMQh" -- Discord Webhook URL

-- Egg names to check for in Rendered.Rifts
local eggNames = {"silly-egg"}

-- SERVICES
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- UNIVERSAL HTTP SUPPORT
local requestFunc =
    (http and http.request) or
    (http_request) or
    (request) or
    (fluxus and fluxus.request) or
    (getgenv and getgenv().request)

if not requestFunc then
    error("❌ Your executor does not support HTTP requests.")
end

-- SERVER HOP LOGIC
local checked = {}
local cursor = nil

-- Function to check for any of the eggs in workspace.Rendered.Rifts
local function foundEgg()
    local riftFolder = workspace:FindFirstChild("Rendered") and workspace.Rendered:FindFirstChild("Rifts")
    if riftFolder then
        for _, eggName in ipairs(eggNames) do
            local egg = riftFolder:FindFirstChild(eggName)
            if egg then
                return eggName
            end
        end
    end
    return nil
end

-- Send a Discord webhook
local function sendWebhook(eggName)
    local joinLink = "https://www.roblox.com/games/" .. placeId .. "/?join-through-client=true"
    local message = {
        content = "Egg found: " .. eggName,
        embeds = {
            {
                title = "Egg Found in Server",
                description = "Found the " .. eggName .. " in the server!",
                fields = {
                    { name = "Join Link", value = joinLink },
                    { name = "Player", value = LocalPlayer.Name }
                }
            }
        }
    }

    local data = HttpService:JSONEncode(message)
    requestFunc({
        Url = webhookUrl,
        Method = "POST",
        Headers = { ["Content-Type"] = "application/json" },
        Body = data
    })
end

-- Get public servers
local function getServers()
    local url = "https://games.roblox.com/v1/games/" .. placeId .. "/servers/Public?sortOrder=Asc&limit=100"
    if cursor then
        url = url .. "&cursor=" .. cursor
    end

    local res = requestFunc({ Url = url, Method = "GET" })
    local data = HttpService:JSONDecode(res.Body)
    cursor = data.nextPageCursor
    return data.data
end

-- Script to requeue after teleporting
local requeueScript = [[
loadstring(game:HttpGet("https://pastebin.com/raw/XXXXXXX"))()
]]
-- OPTIONAL: If you don't want to host it externally, replace with this script again:
-- queue_on_teleport([[ FULL SCRIPT AS STRING HERE ]])

queue_on_teleport(requeueScript)

-- Check current server for eggs
local found = foundEgg()
if found then
    warn("✅ " .. found .. " found in this server!")
    sendWebhook(found)
    return
end

-- Start hopping
local count = 0
while count < maxServers do
    local servers = getServers()
    for _, srv in ipairs(servers) do
        if srv.playing < srv.maxPlayers and not checked[srv.id] then
            checked[srv.id] = true
            count += 1
            warn("🌐 Hopping to server " .. count .. ": " .. srv.id)
            TeleportService:TeleportToPlaceInstance(placeId, srv.id, LocalPlayer)
            task.wait(3)
        end
    end
    if not cursor then break end
end

warn("❌ No eggs found after checking all servers.")
