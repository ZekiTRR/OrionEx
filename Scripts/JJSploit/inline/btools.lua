--[[
    Btools — gives the local player Hammer (BinType 4), Clone (BinType 3)
    and Grab (BinType 2) tools, exactly like the original JJSploit "Btools"
    button which loads
    https://cdn.wearedevs.net/scripts/BTools.txt.
    Tagged as script:inline/btools.lua
]]
local Players = game:GetService("Players")
local backpack = Players.LocalPlayer:WaitForChild("Backpack")

local function addBin(name, binType)
    if backpack:FindFirstChild(name) then
        backpack:FindFirstChild(name):Destroy()
    end
    local bin = Instance.new("HopperBin")
    bin.Name = name
    bin.BinType = binType
    bin.Parent = backpack
end

addBin("Hammer", 4)
addBin("Clone", 3)
addBin("Grab", 2)
