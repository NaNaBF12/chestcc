-- ================= SERVICES =================
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer
local PlaceId = game.PlaceId

-- ================= BIẾN =================
local Farming = false
local UncheckedChests, FirstRun = {}, true

-- ================= CHARACTER =================
local function getCharacter()
    if not LocalPlayer.Character then
        LocalPlayer.CharacterAdded:Wait()
    end
    return LocalPlayer.Character
end

-- ================= SORT CHEST =================
local function DistanceFromPlrSort(list)
    local hrp = getCharacter().HumanoidRootPart
    table.sort(list, function(a, b)
        return (hrp.Position - a.Position).Magnitude <
               (hrp.Position - b.Position).Magnitude
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

-- ================= NOCLIP + TP =================
local function toggleNoclip(on)
    for _, v in pairs(getCharacter():GetChildren()) do
        if v:IsA("BasePart") then
            v.CanCollide = not on
        end
    end
end

local function Teleport(cf)
    local hrp = getCharacter().HumanoidRootPart
    toggleNoclip(true)
    hrp.CFrame = cf + Vector3.new(0, 3, 0)
    toggleNoclip(false)
end

-- ================= SERVER HOP =================
local function ServerHop()
    if not Farming then return end

    local servers = HttpService:JSONDecode(
        game:HttpGet("https://games.roblox.com/v1/games/" .. PlaceId .. "/servers/Public?sortOrder=Asc&limit=100")
    )

    for _, s in pairs(servers.data) do
        if s.playing < s.maxPlayers then
            TeleportService:TeleportToPlaceInstance(PlaceId, s.id, LocalPlayer)
            break
        end
    end
end

-- ================= FARM =================
local function StartFarm()
    if Farming then return end
    Farming = true

    task.spawn(function()
        while Farming do
            task.wait(0.2)

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

local function StopFarm()
    Farming = false
end

-- ================= GUI =================
local gui = Instance.new("ScreenGui", game.CoreGui)
gui.Name = "ChestFarmGUI"

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 200, 0, 120)
frame.Position = UDim2.new(0, 20, 0.4, 0)
frame.BackgroundColor3 = Color3.fromRGB(30,30,30)
frame.Active = true
frame.Draggable = true

local startBtn = Instance.new("TextButton", frame)
startBtn.Size = UDim2.new(1, -20, 0, 40)
startBtn.Position = UDim2.new(0, 10, 0, 10)
startBtn.Text = "▶ START FARM"
startBtn.BackgroundColor3 = Color3.fromRGB(0,170,0)
startBtn.TextColor3 = Color3.new(1,1,1)

local stopBtn = Instance.new("TextButton", frame)
stopBtn.Size = UDim2.new(1, -20, 0, 40)
stopBtn.Position = UDim2.new(0, 10, 0, 60)
stopBtn.Text = "⛔ STOP FARM"
stopBtn.BackgroundColor3 = Color3.fromRGB(170,0,0)
stopBtn.TextColor3 = Color3.new(1,1,1)

startBtn.MouseButton1Click:Connect(StartFarm)
stopBtn.MouseButton1Click:Connect(StopFarm)

-- ================= RESPAWN SAFE =================
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    if Farming then
        StartFarm()
    end
end)
