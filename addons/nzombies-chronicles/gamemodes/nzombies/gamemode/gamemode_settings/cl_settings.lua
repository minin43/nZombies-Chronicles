-- Settings menu developed by: Ethorbit, originally for the servers.

nzGamemodeSettings = nzGamemodeSettings or {}
nzGamemodeSettings.Menu = nil

-- Add helper funcs for creating/removing controls on our custom Settings menu
function nzGamemodeSettings:AddSetting()

end

function nzGamemodeSettings:RemoveSetting()

end

-- Add command for opening menu
concommand.Remove("nz_settings_menu")
concommand.Add("nz_settings_menu", function()
    print("We would open the settings panel here.")
end)

-- Add as button in the Menu Settings
hook.Add("NZ.MenuSettingsList_PreButtonInit", "NZC_AddClientSettingsButton", function(menusettingsList)
    menusettingsList:AddButton("Your Settings", "nz_settings_menu", "/settings")
end)

-- Add the chat commands
local cmdDesc = "View your personal nZombies settings"
local function cmdCallback(ply, text)
    ply:ConCommand("nz_settings_menu")
end
nzChatCommand.Add("/settings", CLIENT, cmdCallback, true, cmdDesc)
nzChatCommand.Add("!settings", CLIENT, cmdCallback, true, cmdDesc)
