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

        local controlPanel = vgui.Create("DPanel", mapFilterPanel)
        controlPanel:Dock(TOP)
        controlPanel:SetHeight(30)

        local controlPanelSpacer = vgui.Create("DPanel", mapFilterPanel)
        controlPanelSpacer:Dock(TOP)
        controlPanelSpacer:SetHeight(5)

        local configOrMapButton = vgui.Create("DButton", controlPanel)
        configOrMapButton:Dock(LEFT)
        configOrMapButton:SetWide(178)

        local whiteListAllButton = vgui.Create("DButton", controlPanel)
        whiteListAllButton:Dock(LEFT)
        whiteListAllButton:SetWide(90)
        whiteListAllButton:SetText("Whitelist All")

        local blackListAllButton = vgui.Create("DButton", controlPanel)
        blackListAllButton:Dock(LEFT)
        blackListAllButton:SetWide(90)
        blackListAllButton:SetText("Blacklist All")

        local resetButton = vgui.Create("DButton", controlPanel)
        resetButton:Dock(LEFT)
        resetButton:SetWide(90)
        resetButton:SetText("Clear")

        local filter_list = vgui.Create("DListView", mapFilterPanel)
        filter_list:Dock(FILL)
        filter_list:SetMultiSelect(false)

        local whitelisted_map_or_config_column = filter_list:AddColumn("Whitelisted")
        local unlisted_map_column = filter_list:AddColumn("Map")
        local unlisted_config_column = filter_list:AddColumn("Config")
        local blacklisted_map_or_config_column = filter_list:AddColumn("Blacklisted")
        whitelisted_map_or_config_column:SetMinWidth(90)
        unlisted_map_column:SetMinWidth(90)
        unlisted_config_column:SetMinWidth(90)
        blacklisted_map_or_config_column:SetMinWidth(90)

        local filter_applied_text = "yes" -- What to show under the Whitelisted/Blacklisted category when said filter is set

        local function switch_to_configs_or_maps()
            filter_list:Clear()

            if isEditingMaps then
                whitelisted_map_or_config_column:SetFixedWidth(90)
                blacklisted_map_or_config_column:SetFixedWidth(90)

                configOrMapButton:SetText("Edit Configs")
                unlisted_config_column:SetWidth(0)
                unlisted_config_column:SetMaxWidth(0)
                unlisted_map_column:SetWidth(100)

                net.Start("NZ_AdminSettings_NeedMaps")
                net.SendToServer()
            else
                whitelisted_map_or_config_column:SetFixedWidth(70)
                blacklisted_map_or_config_column:SetFixedWidth(70)

                unlisted_config_column:SetWidth(100)
                unlisted_map_column:SetWidth(100)
                unlisted_config_column:SetMaxWidth(1000)
                configOrMapButton:SetText("Edit Maps")

                net.Start("NZ_AdminSettings_NeedConfigs")
                net.SendToServer()
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
                filter_list:AddLine(config.is_whitelisted == "1" and filter_applied_text or nil, config.map, config.name, config.is_blacklisted == "1" and filter_applied_text or nil)
            end
        end)

        filter_list.OnRowRightClick = function(lineID, line)
            local filter_line = filter_list:GetLine(line)
            local is_whitelisted = filter_line:GetColumnText(1) == filter_applied_text
            -- local map_name = filter_line:GetColumnText(2)
            -- local config_name = !isEditingMaps and filter_line:GetColumnText(3) or nil
            local is_blacklisted = filter_line:GetColumnText(isEditingMaps and 3 or 4) == filter_applied_text

            local subMenu = DermaMenu()

            if !is_whitelisted then
                subMenu:AddOption("Add to Whitelist", function()
                    filter_line:SetColumnText(1, filter_applied_text)
                end)
            else
                subMenu:AddOption("Remove from Whitelist", function()
                    filter_line:SetColumnText(1, "")
                end)
            end

            if !is_blacklisted then
                subMenu:AddOption("Add to Blacklist", function()
                    filter_line:SetColumnText(isEditingMaps and 3 or 4, filter_applied_text)
                end)
            else
                subMenu:AddOption("Remove from Blacklist", function()
                    filter_line:SetColumnText(isEditingMaps and 3 or 4, "")
                end)
            end

            subMenu:Open()
        end

        whiteListAllButton.DoClick = function()
            mapFilterPanel:ShowConfirmationMenu("Whitelist All?", "Are you sure you want to whitelist ALL items?", function(val)
                print(val)
            end)

            --for _,line in pairs()
        end

        blackListAllButton.DoClick = function()
            mapFilterPanel:ShowConfirmationMenu("Blacklist All?", "Are you sure you want to blacklist ALL items?", function(val)
                print(val)
            end)
        end

        resetButton.DoClick = function()
            mapFilterPanel:ShowConfirmationMenu("Clear Filters?", "Are you sure?\n\nThis will remove ALL whitelist or blacklist filters EVER applied.", function(val)
                print(val)
            end)
        end

        local saveButton = vgui.Create("DButton", mapFilterPanel)
        saveButton:Dock(BOTTOM)
        saveButton:SetText("Save Changes")
        saveButton:SetHeight(30)
        saveButton.DoClick = function()
            mapFilterPanel:ShowConfirmationMenu("Save Settings?", "Are you sure you want to override the map filters with these new settings?", function(val)
                if val then
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
