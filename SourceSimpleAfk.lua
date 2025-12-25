Local Version = "1.6.62"
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/download/" .. Version .. "/main.lua"))()

-- // 1. Variabel Kontrol // --
local Config = {
    TargetName = "",
    Price = 100,
    MaxWeight = 2.0, 
    TargetAmount = 3,
    Delay = 6.0,      
    LoopDelay = 10.0, 
    IsRunning = false,
    AutoLoop = false,
    MaxBoothItems = 50, 
    BlacklistedUUIDs = {}
}

-- // 2. Setup Window // --
local Window = WindUI:CreateWindow({
    Title = "MISTHIOS RHYTHM",
    SubTitle = "v6.0 | SMART DIAGNOSTICS",
    Author = "by Misthios (iPowfu)",
    Folder = "MisthiosScan",
    Icon = "solar:shield-check-bold",
    NewElements = true,
    Transparent = true,
    Acrylic = true,
    TransparencyValue = 0.15,
    
    OpenButton = { 
        Title = "Open Misthios UI",
        Enabled = true, 
        Draggable = true,
        Icon = "solar:ghost-bold",
        Size = UDim2.fromOffset(45, 45),
        StrokeThickness = 0,
        CornerRadius = UDim.new(1, 0),
        Color = ColorSequence.new(
            Color3.fromHex("#30FF6A"), 
            Color3.fromHex("#e7ff2f")
        )
    },
    Topbar = {
        Height = 44,
        ButtonsType = "Mac", 
    }
})

Window:Tag({
    Title = "STAGENAME: iPowfu",
    Icon = "solar:verified-check-bold",
    Color = Color3.fromHex("#1c1c1c"),
    Border = true,
})

WindUI:ToggleAcrylic(true)

-- // 3. Tabs // --
local MainTab = Window:Tab({ Title = "Scanner", Icon = "solar:scanner-bold", IconColor = Color3.fromHex("#7775F2") })
local SettingTab = Window:Tab({ Title = "Settings", Icon = "solar:settings-bold", IconColor = Color3.fromHex("#257AF7") })

-- // 4. UI Components // --
local MainSection = MainTab:Section({ Title = "Pet Configuration" })

MainSection:Input({
    Title = "Nama Pet Target",
    Value = "",
    Placeholder = "Contoh: Huge Cat",
    Callback = function(v) Config.TargetName = v end
})

MainSection:Input({
    Title = "Set Harga Jual",
    Value = "100",
    Callback = function(v) Config.Price = tonumber(v) or 100 end
})

MainSection:Input({
    Title = "Jumlah Pet Per Siklus",
    Value = "3",
    Callback = function(v) Config.TargetAmount = tonumber(v) or 3 end
})

local ActionSection = MainTab:Section({ Title = "Execution" })

ActionSection:Toggle({
    Title = "Auto Rhythm Active",
    Value = false,
    Icon = "solar:play-bold",
    Color = Color3.fromHex("#10C550"),
    Callback = function(state)
        Config.AutoLoop = state
        if state then
            WindUI:Notify({Title = "System Active", Content = "Script dimulai oleh iPowfu", Icon = "solar:bell-bing-bold", Type = "success"})
            Config.BlacklistedUUIDs = {} 
            StartRhythmScan()
        else
            WindUI:Notify({Title = "System Stopped", Content = "Script dinonaktifkan", Icon = "solar:bell-bing-bold", Type = "warning"})
        end
    end
})

local RhythmSection = SettingTab:Section({ Title = "Filter & Timing" })

RhythmSection:Input({
    Title = "Max Weight Pet (Angka)",
    Value = "2.0",
    Callback = function(v) Config.MaxWeight = tonumber(v) or 2.0 end
})

RhythmSection:Slider({
    Title = "Delay Antar Pet (Detik)",
    Step = 0.5,
    Value = { Min = 1, Max = 20, Default = 6 },
    Callback = function(v) Config.Delay = v end
})

RhythmSection:Slider({
    Title = "Jeda Antar Siklus (Detik)",
    Step = 1,
    Value = { Min = 5, Max = 60, Default = 10 },
    Callback = function(v) Config.LoopDelay = v end
})

-- // 5. LOGIKA RITME V6.0 // --
function StartRhythmScan()
    task.spawn(function()
        while Config.AutoLoop do
            if not Config.IsRunning then
                Config.IsRunning = true
                
                local lp = game.Players.LocalPlayer
                
                -- DETEKSI JUMLAH BOOTH
                local function GetBoothCount()
                    local bGui = lp.PlayerGui:FindFirstChild("TradeBooth") or lp.PlayerGui:FindFirstChild("Booth")
                    if bGui then
                        local listFrame = bGui:FindFirstChild("List", true) or bGui:FindFirstChild("ScrollingFrame", true)
                        if listFrame then
                            local c = 0
                            for _, item in pairs(listFrame:GetChildren()) do
                                if item:IsA("Frame") or item:IsA("ImageButton") then c = c + 1 end
                            end
                            return c
                        end
                    end
                    return 0
                end

                local boothItems = GetBoothCount()
                
                if boothItems >= Config.MaxBoothItems then
                    WindUI:Notify({Title = "Booth Full", Content = "Slot 50/50. Menunggu...", Icon = "solar:bell-bing-bold", Type = "warning"})
                else
                    local bp = lp:FindFirstChild("Backpack")
                    local targets = {}
                    local foundAnyWithName = false
                    local rejectedByWeight = 0

                    if bp and Config.TargetName ~= "" then
                        for _, item in pairs(bp:GetChildren()) do
                            if #targets >= Config.TargetAmount or (boothItems + #targets) >= Config.MaxBoothItems then break end
                            
                            if string.find(item.Name:lower(), Config.TargetName:lower()) then
                                foundAnyWithName = true
                                local rawWeight = string.match(item.Name, "%d+%.?%d*")
                                local currentWeight = tonumber(rawWeight) or 0
                                
                                if currentWeight <= Config.MaxWeight then
                                    local uuid = item:GetAttribute("PET_UUID")
                                    if uuid and not Config.BlacklistedUUIDs[uuid] then
                                        table.insert(targets, {Instance = item, UUID = uuid, Weight = currentWeight})
                                    end
                                else
                                    rejectedByWeight = rejectedByWeight + 1
                                end
                            end
                        end

                        -- DIAGNOSTIC NOTIFICATIONS
                        if #targets == 0 then
                            if not foundAnyWithName then
                                WindUI:Notify({
                                    Title = "No Pet Found",
                                    Content = "Tidak ada pet bernama '" .. Config.TargetName .. "' di backpack.",
                                    Icon = "solar:bell-bing-bold",
                                    Type = "warning"
                                })
                            elseif rejectedByWeight > 0 then
                                WindUI:Notify({
                                    Title = "Filter Match",
                                    Content = rejectedByWeight .. " pet ditemukan tapi beratnya > " .. Config.MaxWeight .. " KG.",
                                    Icon = "solar:bell-bing-bold",
                                    Type = "info"
                                })
                            end
                        else
                            -- PROSES LISTING
                            for _, pet in pairs(targets) do
                                if not Config.AutoLoop then break end
                                local ok = game:GetService("ReplicatedStorage").GameEvents.TradeEvents.Booths.CreateListing:InvokeServer(
                                    "Pet", tostring(pet.UUID), Config.Price
                                )
                                if ok then
                                    Config.BlacklistedUUIDs[pet.UUID] = true
                                    WindUI:Notify({
                                        Title = "Pet Added",
                                        Content = pet.Instance.Name .. " dipasang!",
                                        Icon = "solar:bell-bing-bold",
                                        Type = "success"
                                    })
                                end
                                task.wait(Config.Delay)
                            end
                        end
                    end
                end
                
                task.wait(Config.LoopDelay)
                Config.IsRunning = false
            else
                task.wait(1)
            end
        end
    end)
end