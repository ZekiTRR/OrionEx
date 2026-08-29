--[[
    Teleport to Vector3 — placeholders {x}, {y}, {z} are replaced at load time.
    Format: teleport:<x>:<y>:<z>   e.g. teleport:100:50:0
    CFrame.new(x, y, z) sets the absolute world position of the HumanoidRootPart.
]]
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local rootPart = character:WaitForChild("HumanoidRootPart")
rootPart.CFrame = CFrame.new({x}, {y}, {z})
