-- Visual-only "copy" (safe) — Advanced UI + visual simulator
-- Paste into executor (loadstring) while in-game.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")

-- cleanup
if PlayerGui:FindFirstChild("VisualDupeGUI") then
    PlayerGui.VisualDupeGUI:Destroy()
end
if workspace:FindFirstChild("LocalVisualCopies_"..tostring(player.UserId)) then
    workspace["LocalVisualCopies_"..tostring(player.UserId)]:Destroy()
end

-- small helper: clone appearance of a part (handle)
local function cloneAppearanceOfDescendants(srcParent, destParent)
    for _,obj in ipairs(srcParent:GetDescendants()) do
        if obj:IsA("BasePart") then
            local p = Instance.new("Part")
            p.Name = obj.Name
            p.Size = obj.Size
            p.CFrame = obj.CFrame
            p.Anchored = true
            p.CanCollide = false
            p.Material = obj.Material
            p.BrickColor = obj.BrickColor
            p.Transparency = obj.Transparency
            p.Parent = destParent
            -- copy special mesh if present
            local mesh = obj:FindFirstChildOfClass("SpecialMesh")
            if mesh then
                local m = mesh:Clone()
                m.Parent = p
            end
            -- copy meshpart properties if original was MeshPart
        elseif obj:IsA("MeshPart") then
            local mp = Instance.new("Part")
            mp.Name = obj.Name.."_mesh"
            mp.Size = obj.Size
            mp.CFrame = obj.CFrame
            mp.Anchored = true
            mp.CanCollide = false
            mp.Transparency = obj.Transparency
            mp.Material = obj.Material
            mp.BrickColor = obj.BrickColor
            mp.Parent = destParent
            local sm = Instance.new("SpecialMesh", mp)
            sm.MeshType = Enum.MeshType.FileMesh
            sm.MeshId = obj.MeshId or ""
            sm.TextureId = obj.TextureID or ""
        end
        -- decals/texture not copied to keep safe/simple
    end
end

-- create root folder for local visual copies
local copiesFolder = Instance.new("Folder")
copiesFolder.Name = "LocalVisualCopies_"..tostring(player.UserId)
copiesFolder.Parent = workspace

-- UI: create nice Advanced look (icon, panel, progress bar)
local sg = Instance.new("ScreenGui")
sg.Name = "VisualDupeGUI"
sg.ResetOnSpawn = false
sg.Parent = PlayerGui

local icon = Instance.new("TextButton", sg)
icon.Name = "VDIcon"
icon.Text = "📜"
icon.Font = Enum.Font.Code
icon.TextScaled = true
icon.TextColor3 = Color3.fromRGB(0,255,110)
icon.BackgroundColor3 = Color3.fromRGB(6,20,6)
icon.Size = UDim2.new(0,48,0,48)
icon.Position = UDim2.new(1, -64, 0, 12)
local ic = Instance.new("UICorner", icon); ic.CornerRadius = UDim.new(0,10)

local panel = Instance.new("Frame", sg)
panel.Name = "VDPanel"
panel.Size = UDim2.new(0,420,0,240)
panel.Position = UDim2.new(1, -20, 0, 72)
panel.BackgroundColor3 = Color3.fromRGB(8,12,8)
local pc = Instance.new("UICorner", panel); pc.CornerRadius = UDim.new(0,14)
local grad = Instance.new("UIGradient", panel)
grad.Color = ColorSequence.new{ ColorSequenceKeypoint.new(0, Color3.fromRGB(0,40,0)), ColorSequenceKeypoint.new(1, Color3.fromRGB(0,120,50)) }
grad.Rotation = 90

local title = Instance.new("TextLabel", panel)
title.Size = UDim2.new(1, -24, 0, 44)
title.Position = UDim2.new(0,12,0,8)
title.BackgroundTransparency = 1
title.Font = Enum.Font.Code
title.TextScaled = true
title.Text = "💸 Visual Dupe Simulator"
title.TextColor3 = Color3.fromRGB(0,255,140)

local sub = Instance.new("TextLabel", panel)
sub.Size = UDim2.new(1, -24, 0, 20)
sub.Position = UDim2.new(0,12,0,48)
sub.BackgroundTransparency = 1
sub.Font = Enum.Font.Code
sub.TextScaled = true
sub.Text = "Local simulation — no server changes"
sub.TextColor3 = Color3.fromRGB(120,255,160)

local messageLabel = Instance.new("TextLabel", panel)
messageLabel.Size = UDim2.new(1, -24, 0, 32)
messageLabel.Position = UDim2.new(0, 12, 0, 76)
messageLabel.BackgroundTransparency = 1
messageLabel.Font = Enum.Font.Code
messageLabel.TextScaled = true
messageLabel.Text = "Ready."
messageLabel.TextColor3 = Color3.fromRGB(180,255,160)

local barBg = Instance.new("Frame", panel)
barBg.Size = UDim2.new(0, 396, 0, 28)
barBg.Position = UDim2.new(0,12,0,112)
barBg.BackgroundColor3 = Color3.fromRGB(6,6,6)
local bcorner = Instance.new("UICorner", barBg); bcorner.CornerRadius = UDim.new(0,10)

local bar = Instance.new("Frame", barBg)
bar.Size = UDim2.new(0,0,1,0)
bar.Position = UDim2.new(0,0,0,0)
bar.BackgroundColor3 = Color3.fromRGB(0,255,140)
local barCorner = Instance.new("UICorner", bar); barCorner.CornerRadius = UDim.new(0,10)

local progressLabel = Instance.new("TextLabel", barBg)
progressLabel.Size = UDim2.new(1,0,1,0)
progressLabel.BackgroundTransparency = 1
progressLabel.Font = Enum.Font.Code
progressLabel.TextScaled = true
progressLabel.Text = "Idle"
progressLabel.TextColor3 = Color3.fromRGB(0,0,0)

local input = Instance.new("TextBox", panel)
input.Size = UDim2.new(0,220,0,34)
input.Position = UDim2.new(0,12,0,152)
input.Font = Enum.Font.Code
input.PlaceholderText = "Local name for copy (optional)"
input.Text = ""
input.TextColor3 = Color3.fromRGB(0,255,110)
input.BackgroundColor3 = Color3.fromRGB(6,6,6)
local ic2 = Instance.new("UICorner", input); ic2.CornerRadius = UDim.new(0,8)

local startBtn = Instance.new("TextButton", panel)
startBtn.Size = UDim2.new(0,160,0,36)
startBtn.Position = UDim2.new(0,244,0,152)
startBtn.Font = Enum.Font.Code
startBtn.Text = "Start Visual Copy"
startBtn.TextScaled = true
startBtn.BackgroundColor3 = Color3.fromRGB(0,150,50)
startBtn.TextColor3 = Color3.fromRGB(0,0,0)
local sbcorner = Instance.new("UICorner", startBtn); sbcorner.CornerRadius = UDim.new(0,8)

local footer = Instance.new("TextLabel", panel)
footer.Size = UDim2.new(1,-24,0,20)
footer.Position = UDim2.new(0,12,0,196)
footer.BackgroundTransparency = 1
footer.Font = Enum.Font.Code
footer.TextScaled = true
footer.Text = "Client-only visual simulator"
footer.TextColor3 = Color3.fromRGB(100,255,160)

-- panel slide helpers
local shown = false
local tweenInfo = TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local function togglePanel()
    shown = not shown
    if shown then
        TweenService:Create(panel, tweenInfo, {Position = UDim2.new(1, -440, 0, 72)}):Play()
    else
        TweenService:Create(panel, tweenInfo, {Position = UDim2.new(1, -20, 0, 72)}):Play()
    end
end
icon.MouseButton1Click:Connect(togglePanel)

-- function: create local visual copy of the currently equipped tool (appearance only)
local function createLocalVisualCopyFromTool(tool, name)
    if not tool then return nil end
    local model = Instance.new("Model")
    model.Name = "LocalVisualCopy_" .. (tostring(name) ~= "" and name or tool.Name)
    model.Parent = copiesFolder

    -- try to copy Handle or first BasePart
    local handle = tool:FindFirstChild("Handle") or tool:FindFirstChildWhichIsA("BasePart") or tool:FindFirstChildWhichIsA("MeshPart")
    if handle then
        -- create a visual part with same appearance
        local p = Instance.new("Part")
        p.Name = "Visual_"..handle.Name
        p.Size = handle.Size
        p.Anchored = true
        p.CanCollide = false
        p.Material = handle.Material
        p.BrickColor = handle.BrickColor
        p.Transparency = handle.Transparency
        p.CFrame = (player.Character and player.Character.PrimaryPart and player.Character.PrimaryPart.CFrame) or CFrame.new(0,5,0)
        p.Parent = model

        -- if handle contains a SpecialMesh, clone it
        local sm = handle:FindFirstChildOfClass("SpecialMesh")
        if sm then
            local nsm = sm:Clone()
            nsm.Parent = p
        elseif handle:IsA("MeshPart") then
            -- MeshPart -> copy MeshId/TextureId if present
            local nsm = Instance.new("SpecialMesh", p)
            if handle.MeshId then nsm.MeshId = handle.MeshId end
            if handle.TextureID then nsm.TextureId = handle.TextureID end
        end

        -- tag label (BillboardGui attached to part)
        local tag = Instance.new("BillboardGui", p)
        tag.Size = UDim2.new(0,140,0,40)
        tag.AlwaysOnTop = true
        tag.Adornee = p
        local tl = Instance.new("TextLabel", tag)
        tl.Size = UDim2.new(1,0,1,0)
        tl.BackgroundTransparency = 1
        tl.Font = Enum.Font.Code
        tl.TextScaled = true
        tl.TextColor3 = Color3.fromRGB(0,0,0)
        tl.Text = "Copy: "..(name ~= "" and name or tool.Name)
    else
        -- if no parts, try to clone appearance of descendants (safe)
        cloneAppearanceOfDescendants(tool, model)
    end

    -- position model near player (to the right)
    local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if hrp then
        local pos = hrp.Position + hrp.CFrame.RightVector * 2 + Vector3.new(0,1,0)
        for _, part in ipairs(model:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CFrame = CFrame.new(pos) * CFrame.Angles(0, math.rad(45), 0)
            end
        end
    end

    -- floating animation
    spawn(function()
        local t = 0
        while model.Parent == copiesFolder do
            t = t + 0.03
            for _, part in ipairs(model:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CFrame = part.CFrame * CFrame.new(0, math.sin(t)*0.002, 0)
                end
            end
            RunService.Heartbeat:Wait()
        end
    end)

    Debris:AddItem(model, 12)
    return model
end

-- visual progress sequence (similar steps to your second script)
local function runVisualCopySequence(name)
    messageLabel.Text = "Initializing visual copy..."
    progressLabel.Text = "0%"
    bar.Size = UDim2.new(0,0,1,0)

    local steps = {
        {label = "Scanning item...", time = 0.9, pct = 15},
        {label = "Locking visuals...", time = 0.7, pct = 35},
        {label = "Simulating transfer...", time = 1.2, pct = 65},
        {label = "Finalizing local model...", time = 0.9, pct = 90},
        {label = "Finishing...", time = 0.6, pct = 100},
    }

    spawn(function()
        for i,step in ipairs(steps) do
            messageLabel.Text = step.label
            progressLabel.Text = tostring(math.floor(step.pct)) .. "%"
            local target = UDim2.new(step.pct/100, 0, 1, 0)
            bar:TweenSize(target, Enum.EasingDirection.Out, Enum.EasingStyle.Quad, step.time, true)
            task.wait(step.time + 0.05)
        end

        -- after progress finished: create local visual copy
        local equippedTool = nil
        if player.Character then
            for _,c in ipairs(player.Character:GetChildren()) do
                if c:IsA("Tool") then
                    equippedTool = c
                    break
                end
            end
        end
        -- fallback: try Backpack's first tool
        if not equippedTool then
            local bp = player:FindFirstChild("Backpack")
            if bp then
                for _,t in ipairs(bp:GetChildren()) do
                    if t:IsA("Tool") then
                        equippedTool = t
                        break
                    end
                end
            end
        end

        if equippedTool then
            createLocalVisualCopyFromTool(equippedTool, name)
            messageLabel.Text = "Local visual copy created ✔"
            progressLabel.Text = "100%"
            bar.BackgroundColor3 = Color3.fromRGB(255,255,255)
            task.wait(0.12)
            bar.BackgroundColor3 = Color3.fromRGB(0,255,140)
        else
            messageLabel.Text = "No tool found to copy (local only)."
            toast("No Tool found in hand or backpack", 2)
        end
    end)
end

-- start button behavior
startBtn.MouseButton1Click:Connect(function()
    local nm = tostring(input.Text)
    if nm == "" then nm = "item" end
    runVisualCopySequence(nm)
end)

-- initial positioning (slide a little hidden)
panel.Position = UDim2.new(1, -20, 0, 72)
task.wait(0.05)
togglePanel() togglePanel() -- ensure closed state
toast("Visual Dupe Simulator ready. Click 📜 to open.", 2)
