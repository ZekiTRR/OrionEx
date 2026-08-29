--[[
    Walkspeed setter — placeholder {value} is replaced at load time.
    Format: walkspeed:<value> e.g. walkspeed:120
    The C# host substitutes the value before sending to the bridge.
]]
game:GetService("Players").LocalPlayer.Character.Humanoid.WalkSpeed = {value}
