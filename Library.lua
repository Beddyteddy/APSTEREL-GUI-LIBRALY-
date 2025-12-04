-- Load Discord UI Library
local DiscordLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/UI-Libs/main/discord%20lib.txt"))()

local win = DiscordLib:Window("Zeg's Master Hub")

-- SHOP TAB
local shop = win:Server("Shop", "")
local main = shop:Channel("Items")

-- Auto Chests
local chestTypes = {
    {name = "Common Chest", enabled = false},
    {name = "Uncommon Chest", enabled = false},
    {name = "Rare Chest", enabled = false},
    {name = "Epic Chest", enabled = false},
    {name = "Legendary Chest", enabled = false}
}

for _, chest in ipairs(chestTypes) do
    main:Toggle("Auto Buy "..chest.name, false, function(state)
        chest.enabled = state
    end)
end

-- Pine Tree (manual buy with amount input)
local pricePerTree = 80
local amountText = "1"

main:Textbox("Amount of Pine Trees", "Enter number (min 1)", false, function(txt)
    amountText = txt
end)

main:Button("Buy Pine Tree (80 Gold)", function()
    local amount = tonumber(amountText)
    if amount and amount >= 1 then
        local totalCost = amount * pricePerTree
        game.Workspace.ItemBoughtFromShop:InvokeServer("PineTree", amount)
        DiscordLib:Notification("Success", "Bought "..amount.." Pine Trees for "..totalCost.." Gold!", "Nice!")
    else
        DiscordLib:Notification("Error", "Please enter a valid number (min 1)!", "Okay")
    end
end)

-- Robux Items
local robuxItems = {
    {name = "Cookies Wheels", id = 1126385328},
    {name = "Dragon Harpoons", id = 1109792341},
    {name = "Christmas Harpoons", id = 915766549},
    {name = "Mega Thrusters", id = 139121474}
}

for _, item in ipairs(robuxItems) do
    main:Button("Buy "..item.name.." (Robux)", function()
        game.Workspace.PromptRobuxEvent:InvokeServer(item.id, "Product")
    end)
end

-- Auto Chest Buying Loop
spawn(function()
    while true do
        task.wait(1)
        for _, chest in ipairs(chestTypes) do
            if chest.enabled then
                pcall(function()
                    game.Workspace.ItemBoughtFromShop:InvokeServer(chest.name, 1)
                end)
            end
        end
    end
end)

-- UNIVERSE TAB
local universe = win:Server("Universe", "")
local teleports = universe:Channel("Teleport")

teleports:Button("Winter Place", function()
    game:GetService("TeleportService"):Teleport(1930866268, game.Players.LocalPlayer)
end)

teleports:Button("Inner Cloud", function()
    game:GetService("TeleportService"):Teleport(1930863474, game.Players.LocalPlayer)
end)

teleports:Button("The Secret Place", function()
    game:GetService("TeleportService"):Teleport(1930665568, game.Players.LocalPlayer)
end)

-- AUTOFARM TAB
local farm = win:Server("Autofarm", "")
local farmMain = farm:Channel("Gold Grind")

local autofarm = false
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local TweenService = game:GetService("TweenService")
local chestTrigger = workspace.BoatStages.NormalStages.TheEnd.GoldenChest.Trigger

farmMain:Toggle("Enable Autofarm", false, function(state)
    autofarm = state
    if autofarm and LocalPlayer.Character then
        autofarmstart()
    elseif not autofarm then
        game.Workspace.Gravity = 196.2
    end
end)

function autofarmstart()
    game.Workspace.Gravity = 0
    local HRP = LocalPlayer.Character:WaitForChild("HumanoidRootPart")

    local Tween1 = TweenService:Create(HRP, TweenInfo.new(0, Enum.EasingStyle.Linear), {
        CFrame = CFrame.new(-51.565643310546875, 65.00004577636719, 1369.090087890625)
    })
    Tween1:Play()
    Tween1.Completed:Wait()

    local Tween2 = TweenService:Create(HRP, TweenInfo.new(24, Enum.EasingStyle.Linear), {
        CFrame = CFrame.new(-60.1640434, 45.5146027, 8749.81738)
    })
    Tween2:Play()
    Tween2.Completed:Wait()

    local Tween3 = TweenService:Create(HRP, TweenInfo.new(2, Enum.EasingStyle.Linear), {
        CFrame = CFrame.new(-54.7364044, -353.343506, 9499.69141)
    })
    Tween3:Play()
    spawn(function()
        while autofarm and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") do
            task.wait(0.2)
            local dist = (HRP.Position - chestTrigger.Position).Magnitude
            if dist <= 50 then
                firetouchinterest(HRP, chestTrigger, 0)
                wait(0.1)
                firetouchinterest(HRP, chestTrigger, 1)
                wait(0.1)
                LocalPlayer.Character:BreakJoints()
                break
            end
        end
    end)
end

LocalPlayer.CharacterAdded:Connect(function(char)
    local hrp = char:WaitForChild("HumanoidRootPart")
    local part = workspace.BoatStages.NormalStages.CaveStage1:FindFirstChild("DarknessPart")
    if part and autofarm == true then
        hrp.CFrame = CFrame.new(part.Position + Vector3.new(0, 5, 0))
    end
    wait(0.2)
    if autofarm then
        autofarmstart()
    end
end)

spawn(function()
    while true do
        task.wait()
        pcall(function()
            game.Workspace.ClaimRiverResultsGold:FireServer()
        end)
    end
end)

-- RespawnTime set to 0
pcall(function()
    game:GetService("Players").RespawnTime = 0
end)

-- Run autofarm immediately if already spawne
