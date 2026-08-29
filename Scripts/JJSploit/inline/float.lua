--[[
    Float — toggles a bodyvelocity (5 studs/s upward) and slowly spins the
    character. Press F again to disable.
    This mirrors the original JJSploit "Float" button which loaded
    https://cdn.wearedevs.net/scripts/Float%20Character.txt.
]]
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local rootPart = character:WaitForChild("HumanoidRootPart")

-- Persist state across re-injection via the player's PlayerGui.
local gui = player:FindFirstChild("PlayerGui")
if not gui then gui = Instance.new("PlayerGui"); gui.Parent = player end
local stateName = "_jjsploit_float_state"
local stateValue = gui:FindFirstChild(stateName)
if not stateValue then
    stateValue = Instance.new("BoolValue")
    stateValue.Name = stateName
    stateValue.Parent = gui
end
local isFloating = stateValue.Value

-- Toggle on F (toggle key, chosen to be unlikely to conflict).
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.F and not isFloating then
        isFloating = true
    elseif input.KeyCode == Enum.KeyCode.F and isFloating then
        isFloating = false
    end
end)

local floatForce
local rotateConn

local function setFloating(on)
    if on then
        if not floatForce or floatForce.Parent ~= rootPart then
            floatForce = Instance.new("BodyVelocity")
            floatForce.MaxForce = Vector3.new(0, math.huge, 0)
            floatForce.Velocity = Vector3.new(0, 5, 0)
            floatForce.Parent = rootPart
        end
        if not rotateConn then
            rotateConn = RunService.RenderStepped:Connect(function()
                if rootPart and rootPart.Parent then
                    rootPart.CFrame = rootPart.CFrame * CFrame.Angles(0, math.rad(2), 0)
                end
            end)
        end
    else
        if floatForce then floatForce:Destroy(); floatForce = nil end
        if rotateConn then rotateConn:Disconnect(); rotateConn = nil end
    end
    stateValue.Value = on
end

setFloating(isFloating)

-- Auto-toggle by state value (the F key listener flips isFloating).
task.spawn(function()
    while task.wait(0.2) do
        if stateValue.Value ~= isFloating then
            isFloating = stateValue.Value
            setFloating(isFloating)
        end
    end
end)
