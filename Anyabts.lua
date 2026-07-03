-- MM2 Murderer Aim Lock for Innocent/Sheriff
local shared = odh_shared_plugins
local my_section = shared.AddSection("MM2 Aim Lock")

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- Settings
local AimLockEnabled = false
local TargetPart = "Head"
local TargetPlayer = nil
local WallCheckEnabled = false

-- Credits
my_section:AddLabel("Credits: @anya_bts")

-- Description
my_section:AddParagraph("MM2 Aim Lock", "Aim lock for mm2")

-- Toggle: Enable/Disable Aim Lock
my_section:AddToggle("Enable Aim Lock", function(bool)
    AimLockEnabled = bool
    if bool then
        if not IsLocalInLobby() then
            TargetPlayer = FindMurderer()
        end
    else
        TargetPlayer = nil
    end
end)

-- Toggle: Enable/Disable Wall Check
my_section:AddToggle("Wall Check", function(bool)
    WallCheckEnabled = bool
    if WallCheckEnabled then
        shared.Notify("Wall Check enabled", 2)
    else
        shared.Notify("Wall Check disabled", 2)
    end
end)

-- Dropdown: Head or Body
local dropdown = my_section:AddDropdown("Target Part", {"Head", "Body"}, function(selected)
    TargetPart = selected
end)

-- Keybind: Toggle Aim Lock (default T)
my_section:AddKeybind("Toggle Key", "T", function()
    AimLockEnabled = not AimLockEnabled
    if AimLockEnabled then
        if not IsLocalInLobby() then
            TargetPlayer = FindMurderer()
        end
    else
        TargetPlayer = nil
    end
end)

-- Check if local player is in lobby (Y 180-380 = round, else = lobby)
function IsLocalInLobby()
    local character = LocalPlayer.Character
    if not character then return true end
    
    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then return true end
    
    local y = root.Position.Y
    
    if y >= 180 and y <= 380 then
        return false -- Round
    end
    
    return true -- Lobby
end

-- Wall check: raycast from camera to target
function IsTargetVisible(target)
    if not target or not target.Character then return false end
    
    local targetPart = nil
    if TargetPart == "Head" then
        targetPart = target.Character:FindFirstChild("Head")
    elseif TargetPart == "Body" then
        targetPart = target.Character:FindFirstChild("HumanoidRootPart")
    end
    
    if not targetPart then return false end
    
    local cameraPos = Camera.CFrame.Position
    local targetPos = targetPart.Position
    
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
    
    local raycastResult = workspace:Raycast(cameraPos, (targetPos - cameraPos).Unit * (targetPos - cameraPos).Magnitude, raycastParams)
    
    if raycastResult then
        local hitInstance = raycastResult.Instance
        -- Check if the hit object belongs to the target player
        if hitInstance:IsDescendantOf(target.Character) then
            return true -- Visible
        else
            return false -- Wall or something else in the way
        end
    end
    
    return true -- No obstruction
end

-- Find the Murderer (player with knife)
function FindMurderer()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local humanoid = player.Character:FindFirstChild("Humanoid")
            if humanoid and humanoid.Health > 0 then
                -- Check character for knife
                for _, item in ipairs(player.Character:GetChildren()) do
                    if item:IsA("Tool") and (item.Name:lower():find("knife") or item.Name:lower():find("нож")) then
                        if WallCheckEnabled then
                            if IsTargetVisible(player) then
                                return player
                            end
                        else
                            return player
                        end
                    end
                end
                -- Check backpack for knife
                local backpack = player:FindFirstChild("Backpack")
                if backpack then
                    for _, item in ipairs(backpack:GetChildren()) do
                        if item:IsA("Tool") and (item.Name:lower():find("knife") or item.Name:lower():find("нож")) then
                            if WallCheckEnabled then
                                if IsTargetVisible(player) then
                                    return player
                                end
                            else
                                return player
                            end
                        end
                    end
                end
            end
        end
    end
    return nil
end

-- Get target position
function GetTargetPosition(player)
    if not player or not player.Character then return nil end
    
    if TargetPart == "Head" then
        local head = player.Character:FindFirstChild("Head")
        if head then return head.Position end
    elseif TargetPart == "Body" then
        local hrp = player.Character:FindFirstChild("HumanoidRootPart")
        if hrp then return hrp.Position end
    end
    
    return nil
end

-- Main loop
RunService.RenderStepped:Connect(function()
    local inLobby = IsLocalInLobby()
    
    if inLobby then
        return -- In lobby, do nothing
    end
    
    if not AimLockEnabled then return end
    
    -- Wall check: if enabled and target is behind wall, stop aiming
    if WallCheckEnabled and TargetPlayer then
        if not IsTargetVisible(TargetPlayer) then
            TargetPlayer = nil
        end
    end
    
    -- Validate current target
    local validTarget = false
    if TargetPlayer and TargetPlayer.Character then
        local hum = TargetPlayer.Character:FindFirstChild("Humanoid")
        if hum and hum.Health > 0 then
            local hasKnife = false
            for _, item in ipairs(TargetPlayer.Character:GetChildren()) do
                if item:IsA("Tool") and (item.Name:lower():find("knife") or item.Name:lower():find("нож")) then
                    hasKnife = true
                    break
                end
            end
            if not hasKnife then
                local bp = TargetPlayer:FindFirstChild("Backpack")
                if bp then
                    for _, item in ipairs(bp:GetChildren()) do
                        if item:IsA("Tool") and (item.Name:lower():find("knife") or item.Name:lower():find("нож")) then
                            hasKnife = true
                            break
                        end
                    end
                end
            end
            if hasKnife then
                -- Additional wall check validation
                if WallCheckEnabled then
                    if IsTargetVisible(TargetPlayer) then
                        validTarget = true
                    end
                else
                    validTarget = true
                end
            end
        end
    end
    
    if not validTarget then
        TargetPlayer = FindMurderer()
    end
    
    if TargetPlayer then
        local targetPos = GetTargetPosition(TargetPlayer)
        if targetPos then
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, targetPos)
        end
    end
end)

-- Reset target on respawn
LocalPlayer.CharacterAdded:Connect(function()
    TargetPlayer = nil
end)

print("MM2 Aim Lock working")
