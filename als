-- CONFIGURATION
local GAME_ID = 85896571713843
local FIREBASE_URL = "https://robloxeggtracker-default-rtdb.firebaseio.com/ServerList.json" -- Set to your Firebase database
local EGG_WEBHOOK = "https://discord.com/api/webhooks/1367259636616663122/pYz5XUFncqU_Bh4o6zwpOYeac5nlPlSbio8VcvFFT17jAd6se3kLmR5f2gaqueDJh5Rh"
local JOIN_WEBHOOK = "https://discord.com/api/webhooks/1128856038137933885/5QenGJa5Ip8gb7rBLJs_q9gkYhsL134ARFz8HVTp0obEyE6jQiVULi7-pSgcKeu8OMQh"

-- SERVICES
local HttpService = game:GetService("HttpService")
local TPService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- FUNCTION: Send Discord Webhook
local function sendWebhook(url, message)
    pcall(function()
        request({
            Url = url,
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = HttpService:JSONEncode({ content = message })
        })
    end)
end

-- FUNCTION: Fetch 200 servers and upload to Firebase
local function fetchAndUploadServers()
    local allServers, cursor = {}, ""
    while #allServers < 200 do
        local url = string.format("https://games.roblox.com/v1/games/%s/servers/Public?sortOrder=Asc&limit=100&cursor=%s", GAME_ID, cursor)
        local success, result = pcall(function()
            return HttpService:JSONDecode(game:HttpGet(url))
        end)
        if not success or not result or not result.data then break end

        for _, server in ipairs(result.data) do
            if server.playing < server.maxPlayers then
                allServers[#allServers + 1] = server.id
            end
        end

        if result.nextPageCursor then
            cursor = result.nextPageCursor
        else
            break
        end
    end

    local serverData = {}
    for _, sid in ipairs(allServers) do
        serverData[sid] = true
    end

    local success, err = pcall(function()
        request({
            Url = FIREBASE_URL,
            Method = "PUT",
            Headers = { ["Content-Type"] = "application/json" },
            Body = HttpService:JSONEncode(serverData)
        })
    end)

    if success then
        warn("[Firebase] Uploaded " .. tostring(#allServers) .. " servers")
    else
        warn("[Firebase] Upload failed", err)
    end

    return serverData
end

-- FUNCTION: Get server list from Firebase
local function getServerList()
    local success, response = pcall(function()
        return HttpService:GetAsync(FIREBASE_URL)
    end)

    if success then
        local decoded = HttpService:JSONDecode(response)
        return decoded or {}
    else
        warn("[Firebase] Failed to read server list:", response)
        return {}
    end
end

-- FUNCTION: Remove server from Firebase
local function removeServer(serverId)
    local url = FIREBASE_URL:gsub(".json", "/" .. serverId .. ".json")
    pcall(function()
        request({
            Url = url,
            Method = "DELETE" 
        })
    end)
end

-- FUNCTION: Scan for eggs
local function scanForEgg()
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") or obj:IsA("Part") then
            local name = obj.Name:lower()
            if name:find("silly%-egg") then
                return "SILLY"
            end
        end
    end
end

-- MAIN EXECUTION
local function main()
    task.wait(3)
    local eggType = scanForEgg()
    if eggType then
        sendWebhook(EGG_WEBHOOK, string.format("**%s Egg Found!** [Click to join](https://www.roblox.com/games/%s)", eggType, GAME_ID))
        if eggType == "SILLY" then
            warn("[EXIT] Silly Egg found.")
            return
        end
    end

    local servers = getServerList()
    if not servers or next(servers) == nil then
        servers = fetchAndUploadServers()
    end

    local keys = {}
    for id, _ in pairs(servers) do table.insert(keys, id) end

    if #keys == 0 then
        warn("[Hopper] No servers to join.")
        return
    end

    local offset = math.random(1, math.min(10, #keys))
    local chosen = keys[offset]
    warn("[Joining] Server:", chosen)
    sendWebhook(JOIN_WEBHOOK, "Joined server: ``" .. chosen .. "``")
    removeServer(chosen)
    TPService:TeleportToPlaceInstance(GAME_ID, chosen, LocalPlayer)
end

main()
