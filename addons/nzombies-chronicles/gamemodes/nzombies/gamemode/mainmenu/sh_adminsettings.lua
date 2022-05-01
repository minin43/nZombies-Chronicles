-- Admin Settings menu created by Ethorbit,
-- based on my Chronicles server's "nZombies Settings Menu"

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
        local configOrMapButton = vgui.Create("DButton", mapFilterPanel)
        configOrMapButton:Dock(TOP)

        local filter_list = vgui.Create("DListView", mapFilterPanel)
        filter_list:Dock(FILL)
        local whitelisted_map_or_config_column = filter_list:AddColumn("Whitelisted")
        local unlisted_map_column = filter_list:AddColumn("Map")
        local unlisted_config_column = filter_list:AddColumn("Config")
        local blacklisted_map_or_config_column = filter_list:AddColumn("Blacklisted")
        whitelisted_map_or_config_column:SetMinWidth(90)
        unlisted_map_column:SetMinWidth(90)
        unlisted_config_column:SetMinWidth(90)
        blacklisted_map_or_config_column:SetMinWidth(90)

        local function switch_to_configs_or_maps()
            filter_list:Clear()

            whitelisted_map_or_config_column:SetWidth(120)
            blacklisted_map_or_config_column:SetWidth(120)

            if isEditingMaps then
                configOrMapButton:SetText("Edit Configs")
                unlisted_config_column:SetWidth(0)
                unlisted_config_column:SetMaxWidth(0)

                net.Start("NZ_AdminSettings_NeedMaps")
                net.SendToServer()
            else
                unlisted_config_column:SetWidth(90)
                unlisted_map_column:SetWidth(90)
                unlisted_config_column:SetMaxWidth(1000)
                filter_list:Refresh()
                configOrMapButton:SetText("Edit Maps")
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
                filter_list:AddLine(map.is_whitelisted == "1" and "yes" or nil, map.name, nil, map.is_blacklisted == "1" and "yes" or nil)
            end
        end)

        configOrMapButton.DoClick = function()
            isEditingMaps = !isEditingMaps
            switch_to_configs_or_maps()
        end

        local mapCategoryPanel = vgui.Create("DPanel", mapSheet)
        mapSheet:AddSheet("Categories", mapCategoryPanel, "icon16/map.png", false, false, "Configure the category names of maps and configs.")

        nzAdminSettingsPropertySheet:AddSheet("Maps", mapPanel, "icon16/map.png", false, false, "Configure advanced Map Vote settings.")
    end, false, "Opens the Admin Settings panel.")
end
