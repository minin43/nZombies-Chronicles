-- Admin Settings menu created by Ethorbit,
-- created because I needed to merge my
-- Chronicles admin settings into the gamemode
-- itself.

if SERVER then
    util.AddNetworkString("NZ_AdminSettings_NeedMaps")
    util.AddNetworkString("NZ_AdminSettings_HereIsMaps")

    net.Receive("NZ_AdminSettings_NeedMaps", function(len, ply)
        if !ply:IsNZAdmin() then return end

        nzSQL.Maps:GetAll(function(maps)
            if IsValid(ply) and ply:IsNZAdmin() then
                local compressedSqlMaps = util.Compress(util.TableToJSON(maps))
                local compressedSqlSize = #compressedSqlMaps
                net.Start("NZ_AdminSettings_HereIsMaps")
                net.WriteUInt(compressedSqlSize, 32)
                net.WriteData(compressedSqlMaps, compressedSqlSize)
                net.Send(ply)
            end
        end)
    end)

    util.AddNetworkString("NZ_AdminSettings_NeedConfigs")
    util.AddNetworkString("NZ_AdminSettings_HereIsConfigs")

    net.Receive("NZ_AdminSettings_NeedConfigs", function(len, ply)
        if !ply:IsNZAdmin() then return end

        nzSQL.Configs:GetAll(function(configs)
            if IsValid(ply) and ply:IsNZAdmin() then
                local compressedSqlConfigs = util.Compress(util.TableToJSON(configs))
                local compressedSqlSize = #compressedSqlConfigs
                net.Start("NZ_AdminSettings_HereIsConfigs")
                net.WriteUInt(compressedSqlSize, 32)
                net.WriteData(compressedSqlConfigs, compressedSqlSize)
                net.Send(ply)
            end
        end)
    end)

    util.AddNetworkString("NZ_AdminSettings_UpdateMap")
    util.AddNetworkString("NZ_AdminSettings_UpdateConfig")

    net.Receive("NZ_AdminSettings_UpdateMap", function(len, ply)
        if !ply:IsNZAdmin() then return end

        local map_name = net.ReadString()
        local is_whitelisted = net.ReadBool()
        local is_blacklisted = net.ReadBool()
        if is_whitelisted then is_blacklisted = false end
        if is_blacklisted then is_whitelisted = false end

        if is_whitelisted then

        else

        end
    end)

    net.Receive("NZ_AdminSettings_UpdateConfig", function(len, ply)
        if !ply:IsNZAdmin() then return end

        local map_name = net.ReadString()
        local config_name = net.ReadString()
        local is_whitelisted = net.ReadBool()
        local is_blacklisted = net.ReadBool()
        if is_whitelisted then is_blacklisted = false end
        if is_blacklisted then is_whitelisted = false end

        if is_whitelisted then

        else

        end
    end)
end

if CLIENT then
    local nzAdminSettingsFrame
    local nzAdminPanel
    local nzAdminSettingsPropertySheet

    nzChatCommand.Add("/adminsettings", function(ply, text)
        if nzAdminSettingsFrame and nzAdminSettingsFrame:IsValid() then nzAdminSettingsFrame:Close() end
        nzAdminSettingsFrame = vgui.Create("DFrame")
        nzAdminSettingsFrame:SetSize(500, 500)
        nzAdminSettingsFrame:SetTitle("nZombies Administrator Settings")
        nzAdminSettingsFrame:Center()
        nzAdminSettingsFrame:MakePopup()

        nzAdminSettingsFrame:ApplynZombiesTheme()

        nzAdminSettingsPropertySheet = vgui.Create("DPropertySheet", nzAdminSettingsFrame)
        nzAdminSettingsPropertySheet:SetSize( 480, 460 )
        nzAdminSettingsPropertySheet:SetPos( 10, 30 )

        local DProperties = vgui.Create("DProperties", nzAdminSettingsPropertySheet)
        DProperties:SetSize(280, 220)
        nzAdminSettingsPropertySheet:AddSheet("Convars", DProperties, "icon16/cog.png", false, false, "Configure nZombies' ConVars.")

        local mapPanel = vgui.Create("DPanel", nzAdminSettingsPropertySheet)

        local mapSheet = vgui.Create("DPropertySheet", mapPanel)
        mapSheet:Dock(FILL)

        local mapFilterPanel = vgui.Create("DPanel", mapSheet)
        mapSheet:AddSheet("Filters", mapFilterPanel, "icon16/map.png", false, false, "Configure the blacklist/whitelist for maps and configs.")

        local isEditingMaps = true
        local unsavedChanges = false
        local whitelistedCount = 0
        local blacklistedCount = 0
        local filter_applied_text = "yes" -- What to show under the Whitelisted/Blacklisted category when said filter is set

        local oldClose = nzAdminSettingsFrame.Close
        nzAdminSettingsFrame.Close = function()
            if unsavedChanges then
                mapFilterPanel:ShowConfirmationMenu("Close?", "You have unsaved changes, are you sure you want to discard them and close?", function(val)
                    if val then
                        oldClose(nzAdminSettingsFrame)
                    end
                end)
            else
                oldClose(nzAdminSettingsFrame)
            end
        end

        local controlPanel = vgui.Create("DPanel", mapFilterPanel)
        controlPanel:Dock(TOP)
        controlPanel:SetHeight(30)

        local controlPanelLeft = vgui.Create("DPanel", controlPanel)
        controlPanelLeft:Dock(FILL)

        local controlPanelRight = vgui.Create("DPanel", controlPanel)
        controlPanelRight:Dock(RIGHT)
        controlPanelRight:SetWide(300)

        local controlPanelRightScroller = vgui.Create("DHorizontalScroller", controlPanelRight)
        controlPanelRightScroller:Dock(FILL)
        controlPanelRightScroller:SetOverlap(-4)

        local controlPanelSpacer = vgui.Create("DPanel", mapFilterPanel)
        controlPanelSpacer:Dock(TOP)
        controlPanelSpacer:SetHeight(5)

        local configOrMapButton = vgui.Create("DButton", controlPanelLeft)
        configOrMapButton:Dock(LEFT)
        configOrMapButton:SetWide(140)

        local whiteListButton = vgui.Create("DButton")
        whiteListButton:Dock(LEFT)
        whiteListButton:SetWide(85)
        whiteListButton:SetText("Whitelist")
        controlPanelRightScroller:AddPanel(whiteListButton)

        local blackListButton = vgui.Create("DButton")
        blackListButton:Dock(LEFT)
        blackListButton:SetWide(85)
        blackListButton:SetText("Blacklist")
        controlPanelRightScroller:AddPanel(blackListButton)

        local whiteListAllButton = vgui.Create("DButton")
        whiteListAllButton:Dock(LEFT)
        whiteListAllButton:SetWide(85)
        whiteListAllButton:SetText("Whitelist All")
        controlPanelRightScroller:AddPanel(whiteListAllButton)

        whiteListButton.Think = function()
            if blacklistedCount > 0 and !whiteListButton:GetDisabled() then
                whiteListButton:SetDisabled(true)
                whiteListAllButton:SetDisabled(true)
            end

            if whiteListButton:GetDisabled() and blacklistedCount <= 0 then
                whiteListButton:SetDisabled(false)
                whiteListAllButton:SetDisabled(false)
            end
        end

        local blackListAllButton = vgui.Create("DButton")
        blackListAllButton:Dock(LEFT)
        blackListAllButton:SetWide(85)
        blackListAllButton:SetText("Blacklist All")
        controlPanelRightScroller:AddPanel(blackListAllButton)

        blackListButton.Think = function()
            if whitelistedCount > 0 and !blackListButton:GetDisabled() then
                blackListButton:SetDisabled(true)
                blackListAllButton:SetDisabled(true)
            end

            if blackListButton:GetDisabled() and whitelistedCount <= 0 then
                blackListButton:SetDisabled(false)
                blackListAllButton:SetDisabled(false)
            end
        end

        local resetButton = vgui.Create("DButton")
        resetButton:Dock(LEFT)
        resetButton:SetWide(85)
        resetButton:SetText("Clear")
        controlPanelRightScroller:AddPanel(resetButton)

        local filter_list = vgui.Create("DListView", mapFilterPanel)
        filter_list:Dock(FILL)
        filter_list:SetMultiSelect(false)

        local function whitelist_current_line()
            if blacklistedCount > 0 then return end
            local selected_line = filter_list:GetSelectedLine()
            if selected_line then
                selected_line = filter_list:GetLine(selected_line)
                local is_whitelisted = selected_line:GetColumnText(1) == filter_applied_text
                if !is_whitelisted then
                    selected_line:SetColumnText(1, filter_applied_text)
                    whitelistedCount = whitelistedCount + 1
                else
                    selected_line:SetColumnText(1, "")
                    whitelistedCount = whitelistedCount - 1
                end

                unsavedChanges = true
            end
        end

        local function blacklist_current_line()
            if whitelistedCount > 0 then return end
            local selected_line = filter_list:GetSelectedLine()
            if selected_line then
                selected_line = filter_list:GetLine(selected_line)
                local is_blacklisted = selected_line:GetColumnText(4) == filter_applied_text

                if !is_blacklisted then
                    selected_line:SetColumnText(4, filter_applied_text)
                    blacklistedCount = blacklistedCount + 1
                else
                    selected_line:SetColumnText(4, "")
                    blacklistedCount = blacklistedCount - 1
                end

                unsavedChanges = true
            end
        end

        filter_list.DoDoubleClick = function()
            if whitelistedCount > 0 then
                whitelist_current_line()
            elseif blacklistedCount > 0 then
                blacklist_current_line()
            end
        end

        local whitelisted_map_or_config_column = filter_list:AddColumn("Whitelisted")
        local unlisted_map_column = filter_list:AddColumn("Map")
        local unlisted_config_column = filter_list:AddColumn("Config")
        local blacklisted_map_or_config_column = filter_list:AddColumn("Blacklisted")
        whitelisted_map_or_config_column:SetFixedWidth(90)
        unlisted_map_column:SetMinWidth(90)
        unlisted_config_column:SetMinWidth(90)
        blacklisted_map_or_config_column:SetFixedWidth(90)

        filter_list.Think = function()
            local whitelistWide = whitelisted_map_or_config_column:GetWide()
            if whitelistWide == 0 and blacklistedCount <= 0 then
                whitelisted_map_or_config_column:SetFixedWidth(90)
                unlisted_map_column:SetWidth(100)
            end

            if whitelistWide == 90 and blacklistedCount > 0 then
                whitelisted_map_or_config_column:SetFixedWidth(0)
                unlisted_map_column:SetWidth(100)
            end

            local blacklistWide = blacklisted_map_or_config_column:GetWide()
            if blacklistWide == 0 and whitelistedCount <= 0 then
                blacklisted_map_or_config_column:SetFixedWidth(90)
                unlisted_map_column:SetWidth(100)
            end

            if blacklistWide == 90 and whitelistedCount > 0 then
                blacklisted_map_or_config_column:SetFixedWidth(0)
                unlisted_map_column:SetWidth(100)
            end
        end

        local function switch_to_configs_or_maps(skipWarning)
            local function go_on()
                filter_list:Clear()
                unsavedChanges = false
                whitelistedCount = 0
                blacklistedCount = 0

                if isEditingMaps then
                    --whitelisted_map_or_config_column:SetFixedWidth(90)
                    --blacklisted_map_or_config_column:SetFixedWidth(90)

                    configOrMapButton:SetText("Edit Configs")
                    unlisted_config_column:SetWidth(0)
                    unlisted_config_column:SetMaxWidth(0)
                    unlisted_map_column:SetWidth(100)

                    net.Start("NZ_AdminSettings_NeedMaps")
                    net.SendToServer()
                else
                    --whitelisted_map_or_config_column:SetFixedWidth(70)
                    --blacklisted_map_or_config_column:SetFixedWidth(70)

                    unlisted_config_column:SetWidth(100)
                    unlisted_map_column:SetWidth(100)
                    unlisted_config_column:SetMaxWidth(1000)
                    configOrMapButton:SetText("Edit Maps")

                    net.Start("NZ_AdminSettings_NeedConfigs")
                    net.SendToServer()
                end
            end

            if unsavedChanges and !skipWarning then
                mapFilterPanel:ShowConfirmationMenu("Switch editor?", "You have unsaved changes, are you sure you want to discard them?", function(val)
                    if val then
                        go_on()
                    end
                end)
            else
                go_on()
            end
        end
        switch_to_configs_or_maps()

        net.Receive("NZ_AdminSettings_HereIsMaps", function()
            local map_sql_len = net.ReadUInt(32)
            local map_sql_data = net.ReadData(map_sql_len)
            local map_sql_json = util.Decompress(map_sql_data)
            if !map_sql_json then print("Got nothing for some reason") return end
            local map_sql_tbl = util.JSONToTable(map_sql_json)
            for _,map in pairs(map_sql_tbl) do
                whitelistedCount = map.is_whitelisted == "1" and whitelistedCount + 1 or whitelistedCount
                blacklistedCount = map.is_blacklisted == "1" and blacklistedCount + 1 or blacklistedCount
                filter_list:AddLine(map.is_whitelisted == "1" and filter_applied_text or nil, map.name, nil, map.is_blacklisted == "1" and filter_applied_text or nil)
            end
        end)

        net.Receive("NZ_AdminSettings_HereIsConfigs", function()
            local config_sql_len = net.ReadUInt(32)
            local config_sql_data = net.ReadData(config_sql_len)
            local config_sql_json = util.Decompress(config_sql_data)
            if !config_sql_json then print("Got nothing for some reason") return end
            local config_sql_tbl = util.JSONToTable(config_sql_json)
            for _,config in pairs(config_sql_tbl) do
                whitelistedCount = config.is_whitelisted == "1" and whitelistedCount + 1 or whitelistedCount
                blacklistedCount = config.is_blacklisted == "1" and blacklistedCount + 1 or blacklistedCount
                filter_list:AddLine(config.is_whitelisted == "1" and filter_applied_text or nil, config.map, config.name, config.is_blacklisted == "1" and filter_applied_text or nil)
            end
        end)

        filter_list.OnRowRightClick = function(lineID, line)
            local filter_line = filter_list:GetLine(line)
            local is_whitelisted = filter_line:GetColumnText(1) == filter_applied_text
            -- local map_name = filter_line:GetColumnText(2)
            -- local config_name = !isEditingMaps and filter_line:GetColumnText(3) or nil
            local is_blacklisted = filter_line:GetColumnText(4) == filter_applied_text

            local subMenu = DermaMenu()

            if !is_whitelisted then
                local pnl = subMenu:AddOption("Add to Whitelist", function()
                    filter_line:SetColumnText(1, filter_applied_text)
                    unsavedChanges = true
                    whitelistedCount = whitelistedCount + 1
                end)

                if blacklistedCount > 0 then
                    pnl:SetDisabled(true)
                end
            else
                subMenu:AddOption("Remove from Whitelist", function()
                    filter_line:SetColumnText(1, "")
                    unsavedChanges = true
                    whitelistedCount = whitelistedCount - 1
                end)
            end

            if !is_blacklisted then
                local pnl = subMenu:AddOption("Add to Blacklist", function()
                    filter_line:SetColumnText(4, filter_applied_text)
                    unsavedChanges = true
                    blacklistedCount = blacklistedCount + 1
                end)

                if whitelistedCount > 0 then
                    pnl:SetDisabled(true)
                end
            else
                subMenu:AddOption("Remove from Blacklist", function()
                    filter_line:SetColumnText(4, "")
                    unsavedChanges = true
                    blacklistedCount = blacklistedCount - 1
                end)
            end

            subMenu:Open()
        end

        whiteListAllButton.DoClick = function()
            if blacklistedCount > 0 then return end
            mapFilterPanel:ShowConfirmationMenu("Whitelist All?", "Are you sure you want to whitelist ALL items?", function(val)
                if val then
                    unsavedChanges = true
                    whitelistedCount = 0

                    for _,line in pairs(filter_list:GetLines()) do
                        line:SetColumnText(1, filter_applied_text)
                        whitelistedCount = whitelistedCount + 1
                    end
                end
            end)
        end

        blackListAllButton.DoClick = function()
            if whitelistedCount > 0 then return end
            mapFilterPanel:ShowConfirmationMenu("Blacklist All?", "Are you sure you want to blacklist ALL items?", function(val)
                if val then
                    unsavedChanges = true
                    blacklistedCount = 0

                    for _,line in pairs(filter_list:GetLines()) do
                        line:SetColumnText(4, filter_applied_text)
                        blacklistedCount = blacklistedCount + 1
                    end
                end
            end)
        end

        whiteListButton.DoClick = function()
            whitelist_current_line()
        end

        blackListButton.DoClick = function()
            blacklist_current_line()
        end

        resetButton.DoClick = function()
            mapFilterPanel:ShowConfirmationMenu("Clear Filters?", "Are you sure?\n\nThis will remove ALL whitelist or blacklist filters EVER applied.", function(val)
                if val then
                    switch_to_configs_or_maps(true)
                    unsavedChanges = true
                end
            end)
        end

        local saveButton = vgui.Create("DButton", mapFilterPanel)
        saveButton:Dock(BOTTOM)
        saveButton:SetText("Save Changes")
        saveButton:SetHeight(30)
        saveButton.DoClick = function()
            mapFilterPanel:ShowConfirmationMenu("Save Settings?", "Are you sure you want to override the map filters with these new settings?", function(val)
                if val then
                    unsavedChanges = false
                    LocalPlayer():ChatPrint("[nZ] Successfully saved map filter changes.")
                end
            end)
        end

        local controlPanelBottomSpacer = vgui.Create("DPanel", mapFilterPanel)
        controlPanelBottomSpacer:Dock(BOTTOM)
        controlPanelBottomSpacer:SetHeight(5)

        configOrMapButton.DoClick = function()
            isEditingMaps = !isEditingMaps
            switch_to_configs_or_maps()
        end

        local mapCategoryPanel = vgui.Create("DPanel", mapSheet)
        mapSheet:AddSheet("Categories", mapCategoryPanel, "icon16/map.png", false, false, "Configure the category names of maps and configs.")

        nzAdminSettingsPropertySheet:AddSheet("Maps", mapPanel, "icon16/map.png", false, false, "Configure advanced Map Vote settings.")
    end, false, "Opens the Admin Settings panel.")
end
