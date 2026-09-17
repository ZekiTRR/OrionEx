local settings = ManagedSettings.new({
  id = "myscript", -- Script's id. Required.
  name = "My Script", -- Human readable name for script. Required.
  icon = "url/to/icon.png", -- URL to icon. Only relevant for the UI. Optional.
  saveOnChange = true, -- Save all changes when a setting is set. Optional. Defaults to true.
  cloudSync = true, -- This script's settings syncs to the cloud. Optional. Defaults to true.
  schematics = {
    -- Boolean.
    enableAimbot = {
      name = "Enable aimbot",
      description = "Only aims at people with dark skin tones.",
      default = false,
      extra = "Arbitrary value that can be set by the player to anything. Not saved.",
      hidden = false -- If true, this setting will NOT show up in any interface.
    },

    -- Numeric (slider).
    speedhack = {
      name = "Speedhack",
      description = "Player go weeee",
      default = 0,
      minimum = 0,
      maximum = 100,
      step = 2
    },

    -- List.
    teleportTo = {
      name = "Teleport to",
      description = "Select player to teleport to",
      default = {"john", "madden", 123, 456}
    },

    -- Button.
    resetButton = {
      name = "Reset everything",
      description = "Script fucked up? Click here to reset",
      caption = "Reset",
      default = function() -- Cannot be overriden.
        print("Haha u thought")
      end
    }
  }
})

-- Get a setting.
-- Errors if setting ID does not exist.
settings:Get("enableAimbot")

-- Set a setting.
-- Errors if setting ID does not exist, if
-- value type is incorrect, or if they are
-- trying to set a button's behavior.
settings:Set("enableAimbot", true)

-- Reset all settings to their default values.
settings:Reset()

-- Invoke a button manually. Can pass arguments.
settings:Invoke('resetButton', 'abc', 123)

-- Manually trigger a setting save. Useful if "saveOnChange" is false.
settings:Save()

-- Listen to setting changes.
settings.OnChange:Connect(function(settingName, settingValue)
  print("Setting update:", settingName, settingValue)
end)