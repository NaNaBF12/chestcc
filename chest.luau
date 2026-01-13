local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer
local PlaceId = game.PlaceId

local StopFarm = false
local UncheckedChests, FirstRun = {}, true

-- ================= CHECK ITEM =================
local function HasSpecialItem()
    local function check(container)
        for _, v in pairs(container:GetChildren()) do
            if v.Name == "Holy Grail" or v.Name == "Blackbeard Key" then
                return true
            end
        end
        return false
    end

    return check(LocalPlayer.Backpack) or
           (LocalPlayer.Character and check(LocalPlayer.Character))
end

-- ================= SERVER HOP =================
local function ServerHop()
    local servers = HttpService:JSONDecode(
        game:HttpGet("https://games.roblox.com/v1/games/" .. PlaceId .. "/servers/Public?sortOrder=Asc&limit=100")
    )

    for _, server in pairs(servers.data) do
        if server.playing < server.maxPlayers then
            TeleportService:TeleportToPlaceInstance(PlaceId, server.id, LocalPlayer)
            break
        end
    end
end

-- ================= CHARACTER =================
local function getCharacter()
    if not LocalPlayer.Character then
        LocalPlayer.CharacterAdded:Wait()
    end
    return LocalPlayer.Character
end

-- ================= SORT CHEST =================
local function DistanceFromPlrSort(ObjectList)
    local RootPart = getCharacter().HumanoidRootPart
    table.sort(ObjectList, function(A, B)
        return (RootPart.Position - A.Position).Magnitude <
               (RootPart.Position - B.Position).Magnitude
    end)
end

local function getChestsSorted()
    if FirstRun then
        FirstRun = false
        for _, obj in pairs(game:GetDescendants()) do
            if obj:IsA("Part") and obj.Name:find("Chest") then
                table.insert(UncheckedChests, obj)
            end
        end
    end

    local Chests = {}
    for _, chest in pairs(UncheckedChests) do
        if chest:FindFirstChild("TouchInterest") then
            table.insert(Chests, chest)
        end
    end

    DistanceFromPlrSort(Chests)
    return Chests
end

-- ================= TELEPORT =================
local function Teleport(cf)
    local hrp = getCharacter().HumanoidRootPart
    hrp.CFrame = cf + Vector3.new(0, 3, 0)
end

-- ================= FARM =================
local function startFarm()
    task.spawn(function()
        while task.wait(0.2) do
            if StopFarm then return end

            -- CHECK ITEM QUAN TRỌNG
            if HasSpecialItem() then
                StopFarm = true
                warn("ĐÃ CÓ CHÉN THÁNH / KEY RÂU ĐEN → DỪNG FARM")
                return
            end

            local Chests = getChestsSorted()

            if #Chests > 0 then
                Teleport(Chests[1].CFrame)
            else
                warn("HẾT RƯƠNG → ĐỔI SERVER")
                task.wait(1)
                ServerHop()
                return
            end
        end
    end)
end

-- ================= AUTO START =================
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    if not StopFarm then
        startFarm()
    end
end)

startFarm()
