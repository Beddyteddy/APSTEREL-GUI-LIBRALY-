-- lib.lua (full) - GUI library with position control + pastel style + extra widgets
-- Provides: MakeWindow(title, opts) -> window with MakeTab(name)
-- Tab provides: MakeButton, MakeToggle, MakeLabel, MakeTextbox, MakeSlider, MakeDropdown, MakeBind, MakeList
-- Styling: dark translucent bg, pastel blue default buttons, pastel-yellow teleport available by color override

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local plr = Players.LocalPlayer

local library = {}
library.__index = library

-- Style palette
local DARK_BG = Color3.fromRGB(30, 30, 30)
local DARK_BG_TRANSPARENCY = 0.2

local OFF_BTN      = Color3.fromRGB(255, 188, 215) -- pastel pink (toggles off)
local OFF_STROKE   = Color3.fromRGB(233, 160, 190)

local ON_BTN       = Color3.fromRGB(180, 235, 210) -- pastel mint (toggles on)
local ON_STROKE    = Color3.fromRGB(160, 214, 192)

local PASTEL_BLUE  = Color3.fromRGB(183, 218, 255) -- regular buttons (default)
local TP_BTN       = Color3.fromRGB(255, 245, 200) -- pastel yellow (teleport override)

-- Helpers
local function tween(inst, props, t)
    local info = TweenInfo.new(t or 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local tw = TweenService:Create(inst, info, props)
    tw:Play()
    return tw
end

local function new(cls, props)
    local inst = Instance.new(cls)
    if props then
        for k,v in pairs(props) do inst[k] = v end
    end
    return inst
end

local function makeUICorner(parent, radius)
    local c = Instance.new("UICorner")
    c.Parent = parent
    c.CornerRadius = UDim.new(0, radius or 10)
    return c
end

local function makeUIStroke(parent, color, thickness, trans)
    local s = Instance.new("UIStroke")
    s.Parent = parent
    s.Color = color or Color3.new(1,1,1)
    s.Thickness = thickness or 1
    s.Transparency = trans or 0
    return s
end

-- MakeWindow: accepts optional opts table: { Position = UDim2, Size = UDim2 }
-- returns window object with :MakeTab(name), :SetPosition(UDim2), :GetPosition()
function library.MakeWindow(_, title, opts)
    opts = opts or {}
    local win = {}
    win._tabs = {}
    win._activeTab = nil

    -- create ScreenGui
    local screenGui = new("ScreenGui", {Name = title or "Window", ResetOnSpawn = false, DisplayOrder = 999})
    screenGui.Parent = plr:WaitForChild("PlayerGui")

    -- default size/position
    local defaultSize = opts.Size or UDim2.new(0, 360, 0, 240)
    local defaultPos = opts.Position or UDim2.new(0.5, -defaultSize.X.Offset/2, 0.5, -defaultSize.Y.Offset/2)

    -- main window frame
    local window = new("Frame", {
        Parent = screenGui,
        Name = "WindowMain",
        Size = defaultSize,
        Position = defaultPos,
        AnchorPoint = Vector2.new(0, 0),
        BackgroundColor3 = DARK_BG,
        BackgroundTransparency = DARK_BG_TRANSPARENCY,
        ZIndex = 1
    })
    makeUICorner(window, 16)
    makeUIStroke(window, OFF_STROKE, 1, 0.6)

    -- header bar
    local header = new("Frame", {
        Parent = window,
        Size = UDim2.new(1, 0, 0, 40),
        Position = UDim2.new(0,0,0,0),
        BackgroundTransparency = 1
    })
    local titleLbl = new("TextLabel", {
        Parent = header,
        Size = UDim2.new(1, -24, 1, 0),
        Position = UDim2.new(0, 12, 0, 0),
        BackgroundTransparency = 1,
        Text = title or "Window",
        Font = Enum.Font.GothamBold,
        TextSize = 18,
        TextColor3 = Color3.fromRGB(240,240,240),
        TextXAlignment = Enum.TextXAlignment.Left,
    })

    -- left: tabs list
    local tabsList = new("Frame", {
        Parent = window,
        Size = UDim2.new(0, 120, 1, -40),
        Position = UDim2.new(0, 0, 0, 40),
        BackgroundTransparency = 1
    })
    local tabsLayout = new("UIListLayout", {Parent = tabsList, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8)})
    tabsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    tabsLayout.Padding = UDim.new(0, 8)

    -- right: content area
    local content = new("Frame", {
        Parent = window,
        Size = UDim2.new(1, -120, 1, -40),
        Position = UDim2.new(0, 120, 0, 40),
        BackgroundTransparency = 1
    })

    -- Make draggable using header: updates window.Position directly
    do
        local dragging, dragStart, startPos
        header.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
                dragStart = input.Position
                startPos = window.Position
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                    end
                end)
            end
        end)
        header.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement then
                if dragging and dragStart and startPos then
                    local delta = input.Position - dragStart
                    local newX = startPos.X.Offset + delta.X
                    local newY = startPos.Y.Offset + delta.Y
                    window.Position = UDim2.new(startPos.X.Scale, newX, startPos.Y.Scale, newY)
                end
            end
        end)
    end

    -- window methods
    function win:MakeTab(tabName)
        local tab = {}
        tab._frame = new("Frame", {
            Parent = content,
            Size = UDim2.new(1, -24, 1, -24),
            Position = UDim2.new(0, 12, 0, 12),
            BackgroundTransparency = 1,
            Visible = false
        })
        local layout = new("UIListLayout", {Parent = tab._frame, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 10)})
        layout.Padding = UDim.new(0, 10)
        layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
        layout.VerticalAlignment = Enum.VerticalAlignment.Top

        -- create tab button in tabsList
        local tabBtn = new("TextButton", {
            Parent = tabsList,
            Size = UDim2.new(1, -16, 0, 36),
            BackgroundColor3 = OFF_BTN,
            AutoButtonColor = false,
            Text = tabName,
            Font = Enum.Font.GothamSemibold,
            TextSize = 14,
            TextColor3 = Color3.fromRGB(40,40,40)
        })
        makeUICorner(tabBtn, 10)
        local tabStroke = makeUIStroke(tabBtn, OFF_STROKE, 1, 0.5)

        -- activation handler
        local function activate()
            for _,t in ipairs(win._tabs) do
                t._frame.Visible = false
                if t._btn then
                    tween(t._btn, {BackgroundColor3 = OFF_BTN}, 0.18)
                end
            end
            tab._frame.Visible = true
            tween(tabBtn, {BackgroundColor3 = ON_BTN}, 0.18)
            tab._btn = tabBtn
            win._activeTab = tab
        end

        tabBtn.MouseButton1Click:Connect(function()
            activate()
        end)

        -- add to tabs list
        table.insert(win._tabs, tab)

        -- default activate first tab
        if #win._tabs == 1 then
            activate()
        end

        -- === Core widgets: Button / Toggle / Label (existing) ===
        function tab:MakeButton(text, callback, opt)
            opt = opt or {}
            local btn = new("TextButton", {
                Parent = tab._frame,
                Size = UDim2.new(0, 220, 0, 44),
                BackgroundColor3 = opt.color or PASTEL_BLUE,
                AutoButtonColor = false,
                Text = text or "Button",
                Font = Enum.Font.GothamSemibold,
                TextSize = 14,
                TextColor3 = opt.textColor or Color3.fromRGB(30,30,30)
            })
            makeUICorner(btn, 12)
            makeUIStroke(btn, OFF_STROKE, 1, 0.6)
            btn.MouseButton1Click:Connect(function()
                tween(btn, {Size = UDim2.new(0, 210, 0, 42)}, 0.06)
                task.delay(0.09, function() tween(btn, {Size = UDim2.new(0, 220, 0, 44)}, 0.06) end)
                if callback then
                    local ok, err = pcall(callback)
                    if not ok then warn("Button callback error:", err) end
                end
            end)
            return btn
        end

        function tab:MakeToggle(text, default, callback)
            local container = new("Frame", {
                Parent = tab._frame,
                Size = UDim2.new(0, 280, 0, 44),
                BackgroundTransparency = 1
            })
            local label = new("TextLabel", {
                Parent = container,
                Size = UDim2.new(0, 180, 1, 0),
                Position = UDim2.new(0,0,0,0),
                BackgroundTransparency = 1,
                Text = text or "Toggle",
                Font = Enum.Font.Gotham,
                TextSize = 14,
                TextColor3 = Color3.fromRGB(240,240,240),
                TextXAlignment = Enum.TextXAlignment.Left
            })
            local togg = new("TextButton", {
                Parent = container,
                Size = UDim2.new(0, 84, 0, 32),
                Position = UDim2.new(1, -84, 0, 6),
                BackgroundColor3 = default and ON_BTN or OFF_BTN,
                AutoButtonColor = false,
                Text = default and "On" or "Off",
                Font = Enum.Font.GothamSemibold,
                TextSize = 12,
                TextColor3 = Color3.fromRGB(40,40,40)
            })
            makeUICorner(togg, 12)
            makeUIStroke(togg, OFF_STROKE, 1, 0.5)

            local state = not not default
            local function setState(s)
                state = s
                togg.Text = state and "On" or "Off"
                tween(togg, {BackgroundColor3 = state and ON_BTN or OFF_BTN}, 0.18)
                if callback then
                    local ok, err = pcall(function() callback(state) end)
                    if not ok then warn("Toggle callback error:", err) end
                end
            end

            togg.MouseButton1Click:Connect(function()
                setState(not state)
            end)

            return {
                Set = setState,
                Get = function() return state end,
                Instance = container
            }
        end

        function tab:MakeLabel(text)
            local lbl = new("TextLabel", {
                Parent = tab._frame,
                Size = UDim2.new(0, 280, 0, 24),
                BackgroundTransparency = 1,
                Text = text or "",
                Font = Enum.Font.Gotham,
                TextSize = 12,
                TextColor3 = Color3.fromRGB(200,200,200),
                TextXAlignment = Enum.TextXAlignment.Left
            })
            return lbl
        end

        -- === NEW widgets ===

        -- Textbox: callback(text) on Enter or FocusLost
        function tab:MakeTextbox(labelText, placeholder, callback)
            local container = new("Frame", {
                Parent = tab._frame,
                Size = UDim2.new(0, 280, 0, 44),
                BackgroundTransparency = 1
            })
            local label = new("TextLabel", {
                Parent = container,
                Size = UDim2.new(0, 100, 1, 0),
                Position = UDim2.new(0,0,0,0),
                BackgroundTransparency = 1,
                Text = labelText or "TextBox",
                Font = Enum.Font.Gotham,
                TextSize = 14,
                TextColor3 = Color3.fromRGB(240,240,240),
                TextXAlignment = Enum.TextXAlignment.Left
            })
            local box = new("TextBox", {
                Parent = container,
                Size = UDim2.new(0, 160, 0, 32),
                Position = UDim2.new(1, -160, 0, 6),
                BackgroundColor3 = Color3.fromRGB(250,250,250),
                Text = "",
                PlaceholderText = placeholder or "",
                Font = Enum.Font.Gotham,
                TextSize = 14,
                TextColor3 = Color3.fromRGB(30,30,30)
            })
            makeUICorner(box, 8)
            makeUIStroke(box, OFF_STROKE, 1, 0.6)

            local function call()
                if callback then
                    local ok, err = pcall(function() callback(box.Text) end)
                    if not ok then warn("Textbox callback:", err) end
                end
            end

            box.FocusLost:Connect(function(enterPressed)
                if enterPressed then call() end
            end)

            -- expose API
            return {
                Get = function() return box.Text end,
                Set = function(v) box.Text = tostring(v) end,
                Instance = container
            }
        end

        -- Slider: numeric, callback(value)
        function tab:MakeSlider(labelText, min, max, default, callback)
            min = tonumber(min) or 0
            max = tonumber(max) or 100
            default = tonumber(default) or min
            if default < min then default = min end
            if default > max then default = max end

            local container = new("Frame", { Parent = tab._frame, Size = UDim2.new(0, 320, 0, 56), BackgroundTransparency = 1 })
            local label = new("TextLabel", {
                Parent = container,
                Size = UDim2.new(0, 160, 0, 20),
                Position = UDim2.new(0,0,0,0),
                BackgroundTransparency = 1,
                Text = labelText or "Slider",
                Font = Enum.Font.Gotham,
                TextSize = 14,
                TextColor3 = Color3.fromRGB(240,240,240),
                TextXAlignment = Enum.TextXAlignment.Left
            })
            local valueLbl = new("TextLabel", {
                Parent = container,
                Size = UDim2.new(0, 60, 0, 20),
                Position = UDim2.new(1, -60, 0, 0),
                BackgroundTransparency = 1,
                Text = tostring(default),
                Font = Enum.Font.Gotham,
                TextSize = 14,
                TextColor3 = Color3.fromRGB(240,240,240),
                TextXAlignment = Enum.TextXAlignment.Right
            })
            local track = new("Frame", { Parent = container, Size = UDim2.new(1, -20, 0, 10), Position = UDim2.new(0,10,0,30), BackgroundColor3 = Color3.fromRGB(220,220,220) })
            makeUICorner(track, 6)
            local knob = new("ImageButton", { Parent = track, Size = UDim2.new(0, 16, 1, 0), Position = UDim2.new((default - min)/(max - min), 0, 0, 0), BackgroundTransparency = 1, Image = "" })
            local knobVisual = new("Frame", { Parent = knob, Size = UDim2.new(1,0,1,0), BackgroundColor3 = PASTEL_BLUE, Name = "KnobVis" })
            makeUICorner(knobVisual, 8)
            makeUIStroke(knobVisual, OFF_STROKE, 1, 0.6)

            local dragging = false
            local function setFromPosition(absX)
                local relative = math.clamp((absX - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
                local value = min + (max - min) * relative
                value = math.floor((value * 100) + 0.5) / 100 -- round 2 decimals
                knob.Position = UDim2.new(relative, 0, 0, 0)
                valueLbl.Text = tostring(value)
                if callback then
                    local ok, err = pcall(function() callback(value) end)
                    if not ok then warn("Slider callback:", err) end
                end
            end

            knob.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = true
                end
            end)
            UserInputService.InputChanged:Connect(function(input)
                if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                    setFromPosition(input.Position.X)
                end
            end)
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = false
                end
            end)

            -- allow clicking track
            track.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    setFromPosition(input.Position.X)
                end
            end)

            -- API
            return {
                Set = function(v)
                    v = math.clamp(tonumber(v) or min, min, max)
                    local relative = (v - min) / (max - min)
                    knob.Position = UDim2.new(relative,0,0,0)
                    valueLbl.Text = tostring(v)
                    if callback then
                        pcall(callback, v)
                    end
                end,
                Get = function()
                    return tonumber(valueLbl.Text)
                end,
                Instance = container
            }
        end

        -- Dropdown: options = { "a", "b", ... } callback(index, value)
        function tab:MakeDropdown(labelText, options, callback)
            options = options or {}
            local container = new("Frame", { Parent = tab._frame, Size = UDim2.new(0, 280, 0, 44), BackgroundTransparency = 1 })
            local label = new("TextLabel", {
                Parent = container,
                Size = UDim2.new(0, 120, 1, 0),
                Position = UDim2.new(0,0,0,0),
                BackgroundTransparency = 1,
                Text = labelText or "Dropdown",
                Font = Enum.Font.Gotham,
                TextSize = 14,
                TextColor3 = Color3.fromRGB(240,240,240),
                TextXAlignment = Enum.TextXAlignment.Left
            })
            local btn = new("TextButton", {
                Parent = container,
                Size = UDim2.new(0, 140, 0, 32),
                Position = UDim2.new(1, -140, 0, 6),
                BackgroundColor3 = PASTEL_BLUE,
                AutoButtonColor = false,
                Text = options[1] or "Select",
                Font = Enum.Font.GothamSemibold,
                TextSize = 13,
                TextColor3 = Color3.fromRGB(30,30,30)
            })
            makeUICorner(btn, 10)
            makeUIStroke(btn, OFF_STROKE, 1, 0.5)

            local open = false
            local itemsFrame = new("Frame", { Parent = container, Size = UDim2.new(0, 140, 0, 0), Position = UDim2.new(1, -140, 0, 44), BackgroundTransparency = 1, ClipsDescendants = true })
            local scroll = new("ScrollingFrame", { Parent = itemsFrame, Size = UDim2.new(1,1,1,0), CanvasSize = UDim2.new(0,0,0,0), BackgroundTransparency = 1, ScrollBarThickness = 6 })
            local listLayout = new("UIListLayout", { Parent = scroll, SortOrder = Enum.SortOrder.LayoutOrder })
            listLayout.Padding = UDim.new(0,4)

            local function rebuild()
                scroll:ClearAllChildren()
                listLayout.Parent = scroll
                local total = 0
                for i,v in ipairs(options) do
                    local optBtn = new("TextButton", {
                        Parent = scroll,
                        Size = UDim2.new(1, -8, 0, 30),
                        BackgroundColor3 = Color3.fromRGB(250,250,250),
                        AutoButtonColor = false,
                        Text = tostring(v),
                        Font = Enum.Font.Gotham,
                        TextSize = 13,
                        TextColor3 = Color3.fromRGB(30,30,30)
                    })
                    optBtn.Position = UDim2.new(0,4,0,total)
                    makeUICorner(optBtn, 8)
                    makeUIStroke(optBtn, OFF_STROKE, 1, 0.6)
                    optBtn.MouseButton1Click:Connect(function()
                        btn.Text = tostring(v)
                        if callback 
