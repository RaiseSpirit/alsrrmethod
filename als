-- CONFIGURATION
local placeId = 85896571713843 -- Confirmed BSGI place ID
local maxServers = 200
local eggWebhookUrl = "https://discord.com/api/webhooks/1367259636616663122/pYz5XUFncqU_Bh4o6zwpOYeac5nlPlSbio8VcvFFT17jAd6se3kLmR5f2gaqueDJh5Rh" -- Webhook for egg found
local logWebhookUrl = "https://discord.com/api/webhooks/1128856038137933885/5QenGJa5Ip8gb7rBLJs_q9gkYhsL134ARFz8HVTp0obEyE6jQiVULi7-pSgcKeu8OMQh" -- Webhook to log server IDs

-- Egg names to check for in Rendered.Rifts
local eggNames = {"silly-egg"}

-- SERVICES
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- UNIVERSAL HTTP SUPPORT
local requestFunc = (syn and syn.request) or (http and http.request) or (http_request) or (request) or (fluxus and fluxus.request) or (getgenv and getgenv().request)

if not requestFunc then
    error("❌ Your executor does not support HTTP requests.")
end

-- SERVER HOP LOGIC
local checked = {}
local visitedServers = {}
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

-- Send a Discord webhook for egg found
local function sendEggWebhook(eggName)
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

    local success, err = pcall(function()
        local data = HttpService:JSONEncode(message)
        requestFunc({
            Url = eggWebhookUrl,
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = data
        })
    end)
    if not success then
        warn("Failed to send egg webhook: " .. err)
    end
end

-- Send a Discord webhook to log server IDs
local function sendLogWebhook(serverId)
    local message = {
        content = "Joined Server: " .. serverId,
        embeds = {
            {
                title = "Server ID Logged",
                description = "The script has joined a new server.",
                fields = {
                    { name = "Server ID", value = serverId },
                    { name = "Player", value = LocalPlayer.Name }
                }
            }
        }
    }

    local success, err = pcall(function()
        local data = HttpService:JSONEncode(message)
        requestFunc({
            Url = logWebhookUrl,
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = data
        })
    end)
    if not success then
        warn("Failed to send log webhook: " .. err)
    end
end

-- Get public servers
local function getServers()
    local url = "https://games.roblox.com/v1/games/" .. placeId .. "/servers/Public?sortOrder=Asc&limit=100"
    if cursor then
        url = url .. "&cursor=" .. cursor
    end

    local success, res = pcall(function()
        return requestFunc({ Url = url, Method = "GET" })
    end)
    
    if not success or not res then
        warn("Failed to get servers: " .. (res or "unknown error"))
        return {}
    end

    local data = HttpService:JSONDecode(res.Body)
    cursor = data.nextPageCursor
    return data.data or {}
end

-- Check if queue_on_teleport exists, if not create a dummy function
if not queue_on_teleport then
    queue_on_teleport = function(code)
        warn("queue_on_teleport not supported, continuing without it")
    end
end

-- Queue the script for re-execution after teleport
queue_on_teleport([[
    loadstring(game:HttpGet("https://pastebin.com/raw/XXXXXXX"))()
]])

-- Main execution
local function main()
    -- Check current server first
    local eggName = foundEgg()
    if eggName == "silly-egg" then
        warn("✅ Found the silly-egg in this server!")
        sendEggWebhook(eggName)
        return
    elseif eggName then
        warn("Found a " .. eggName .. ", but continuing to hop to other servers.")
        sendEggWebhook(eggName)
    end

    -- Start hopping
    local count = 0
    while count < maxServers do
        local servers = getServers()
        if #servers == 0 then
            warn("No more servers available to check.")
            break
        end

        for _, srv in ipairs(servers) do
            if srv.playing < srv.maxPlayers and not visitedServers[srv.id] then
                visitedServers[srv.id] = true
                count += 1
                warn("🌐 Hopping to server " .. count .. ": " .. srv.id)
                sendLogWebhook(srv.id)
                
                local success = pcall(function()
                    TeleportService:TeleportToPlaceInstance(placeId, srv.id, LocalPlayer)
                end)
                
                if not success then
                    warn("Failed to teleport to server " .. srv.id)
                end
                
                task.wait(3) -- Wait before next attempt
                break -- Break after teleport attempt
            end
        end
        
        if not cursor then 
            warn("No more pages to check.")
            break 
        end
    end

    warn("❌ No eggs found after checking " .. count .. " servers.")
end

-- Run the main function
local success, err = pcall(main)
if not success then
    warn("Script error: " .. err)
end
