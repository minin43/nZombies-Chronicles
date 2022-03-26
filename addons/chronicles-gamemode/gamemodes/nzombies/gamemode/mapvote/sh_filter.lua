-- Whitelist/Blacklist ULX MapVote support added by Ethorbit

-- This is helpful if you have a server with configs that don't work
-- or are still being developed and don't want people to
-- play them.

-- Excuse the spaghetti code, working with ULX is very weird.
-- (And yes, I want NZ commands to support ULX as well, it's widely used and looks good)

nzMapVote = nzMapVote or {}
nzMapVote.WhitelistedMaps = nzMapVote.WhitelistedMaps or {}
nzMapVote.BlacklistedMaps = nzMapVote.BlacklistedMaps or {}

nzMapVote.NetworkedWhitelistedMaps = nzMapVote.NetworkedWhitelistedMaps or {}
nzMapVote.NetworkedBlacklistedMaps = nzMapVote.NetworkedBlacklistedMaps or {}
nzMapVote.NetworkedUnwhitelistedMaps = nzMapVote.NetworkedUnwhitelistedMaps or {}
nzMapVote.NetworkedUnblacklistedMaps = nzMapVote.NetworkedUnblacklistedMaps or {}

local function sync_maps(is_whitelist, ply) -- Sync the server maps with clients
    net.Start(is_whitelist and "UpdatedWhitelistedMaps" or "UpdatedBlacklistedMaps")
    net.WriteTable(nzMapVote[is_whitelist and "NetworkedWhitelistedMaps" or "NetworkedBlacklistedMaps"])
    net.WriteTable(nzMapVote[is_whitelist and "NetworkedUnwhitelistedMaps" or "NetworkedUnblacklistedMaps"])

    if IsValid(ply) then
        net.Send(ply)
    else
        net.Broadcast()
    end
end

if SERVER then
    util.AddNetworkString("INeedWhitelistBlacklistMaps")
    util.AddNetworkString("UpdatedWhitelistedMaps")
    util.AddNetworkString("UpdatedBlacklistedMaps")

    net.Receive("INeedWhitelistBlacklistMaps", function(len, ply)
        if !ply:IsNZAdmin() then return end

        sync_maps(true, ply)
        sync_maps(false, ply)
    end)
else
    hook.Add("InitPostEntity", "MapVoteFiltersAddWhitelistBlacklist", function()
        net.Start("INeedWhitelistBlacklistMaps")
        net.SendToServer()
    end)

    net.Receive("UpdatedWhitelistedMaps", function()
        table.Empty(nzMapVote.NetworkedWhitelistedMaps)
        table.Empty(nzMapVote.NetworkedUnwhitelistedMaps)
        table.Merge(nzMapVote.NetworkedWhitelistedMaps, net.ReadTable())
        table.Merge(nzMapVote.NetworkedUnwhitelistedMaps, net.ReadTable())
    end)

    net.Receive("UpdatedBlacklistedMaps", function()
        table.Empty(nzMapVote.NetworkedBlacklistedMaps)
        table.Empty(nzMapVote.NetworkedUnblacklistedMaps)
        table.Merge(nzMapVote.NetworkedBlacklistedMaps, net.ReadTable())
        table.Merge(nzMapVote.NetworkedUnblacklistedMaps, net.ReadTable())
    end)
end

if SERVER then
    local function update_unset_maps(unlisted_tbl, is_whitelist) -- Update the 'Unwhitelisted' and 'Unblacklisted' lists
        table.Empty(unlisted_tbl)

        for _,map in pairs(nzConfig.Maps) do
            if ((is_whitelist and !nzMapVote.WhitelistedMaps[map]) or (!is_whitelist and !nzMapVote.BlacklistedMaps[map])) then
                unlisted_tbl[#unlisted_tbl + 1] = map
            end
        end
    end

    -- File management
    local function get_item_path(is_whitelist)
        return is_whitelist and "mapvote/whitelisted.txt" or "mapvote/blacklisted.txt"
    end

    local function get_items(is_whitelist) -- Get file contents
        local content = file.Read(get_item_path(is_whitelist), "DATA")
        return content and util.JSONToTable(content) or {}
    end

    local function load_items(is_whitelist) -- Load the whitelisted and blacklisted maps
        local items = get_items(is_whitelist)
        nzMapVote[is_whitelist and "WhitelistedMaps" or "BlacklistedMaps"] = items

        local tbl = nzMapVote[is_whitelist and "NetworkedWhitelistedMaps" or "NetworkedBlacklistedMaps"]
        table.Empty(tbl)
        table.Merge(tbl, table.GetKeys(items))

        -- Only keep the maps that aren't blacklisted/whitelisted (for ULX when adding maps)
        update_unset_maps(nzMapVote[is_whitelist and "NetworkedUnwhitelistedMaps" or "NetworkedUnblacklistedMaps"], is_whitelist)
    end

    hook.Add("nzConfig.UpdatedConfigFileData", "NZUnwhitelistUnblacklistUpdate", function()
        update_unset_maps(nzMapVote.NetworkedUnwhitelistedMaps, true)
        update_unset_maps(nzMapVote.NetworkedUnblacklistedMaps, false)
    end)

    local function save_items(is_whitelist, tbl) -- Overwrite file contents
        file.Write(get_item_path(is_whitelist), util.TableToJSON(tbl))
    end

    local function clear_items(is_whitelist) -- Clear all items from blacklisted or whitelisted maps
        file.Delete(get_item_path(is_whitelist))

        local listed_tbl = nzMapVote[is_whitelist and "NetworkedWhitelistedMaps" or "NetworkedBlacklistedMaps"]
        table.Empty(listed_tbl)
        table.Empty(nzMapVote[is_whitelist and "WhitelistedMaps" or "BlacklistedMaps"])
        table.Empty(nzMapVote[is_whitelist and "NetworkedUnwhitelistedMaps" or "NetworkedUnblacklistedMaps"])

        update_unset_maps(nzMapVote.NetworkedUnwhitelistedMaps, true)
        update_unset_maps(nzMapVote.NetworkedUnblacklistedMaps, false)
    end

    local function edit_item(map, is_whitelist, is_removed) -- Add or remove map to whitelist or blacklist
        local tbl = get_items(is_whitelist) or {}
        local listed_tbl = nzMapVote[is_whitelist and "NetworkedWhitelistedMaps" or "NetworkedBlacklistedMaps"]
        local unlisted_tbl = nzMapVote[is_whitelist and "NetworkedUnwhitelistedMaps" or "NetworkedUnblacklistedMaps"]

        if is_removed then -- Removing a whitelist/blacklist
            tbl[map] = nil
            nzMapVote[is_whitelist and "WhitelistedMaps" or "BlacklistedMaps"][map] = nil
            table.RemoveByValue(listed_tbl, map)
            unlisted_tbl[#unlisted_tbl + 1] = map
        else -- Adding a whitelist/blacklist
            tbl[map] = 1
            nzMapVote[is_whitelist and "WhitelistedMaps" or "BlacklistedMaps"][map] = 1
            table.RemoveByValue(unlisted_tbl, map)
            listed_tbl[#listed_tbl + 1] = map
        end

        if !is_removed then
            clear_items(!is_whitelist) -- Clear the opposite (You can't have a blacklist AND a whitelist)
            sync_maps(!is_whitelist)
        end

        sync_maps(is_whitelist)
        save_items(is_whitelist, tbl)
    end

    load_items(true)
    load_items(false)

    function nzMapVote.AddMapToWhitelist(map)
        if nzMapVote.IsMapWhitelisted(map) then return end
        edit_item(map, true, false)
    end

    function nzMapVote.RemoveMapFromWhitelist(map)
        edit_item(map, true, true)
    end

    function nzMapVote.AddMapToBlacklist(map)
        if nzMapVote.IsMapBlacklisted(map) then return end
        edit_item(map, false, false)
    end

    function nzMapVote.RemoveMapFromBlacklist(map)
        edit_item(map, false, true)
    end
end
--------------------------------------------------------------------------------------

-- Shared getters
function nzMapVote.IsMapWhitelisted(map)
    return nzMapVote.WhitelistedMaps and nzMapVote.WhitelistedMaps[map] != nil
end

function nzMapVote.IsMapBlacklisted(map)
    return nzMapVote.BlacklistedMaps and nzMapVote.BlacklistedMaps[map] != nil
end

-- Chat commands

-- Ugly ass ULX commands lol
if (ulx and ulx.command and ULib and ULib.cmds and ULib.cmds.StringArg and ULib.ACCESS_ADMIN) then
    -- ADD whitelist map -------------------------------------------------------------
    local function ulx_Whitelist_Add(calling_ply, map)
        nzMapVote.AddMapToWhitelist(map)

        if !ulx.fancyLogAdmin then return end
        ulx.fancyLogAdmin(calling_ply, "#A added #s to the MapVote's whitelist.", map)
    end

    local whitelist = ulx.command("nZombies MapVote", "mapvote whitelist add", ulx_Whitelist_Add, "!mapvote whitelist add")
    if whitelist.addParam and whitelist.defaultAccess and whitelist.help then
        whitelist:addParam{type=ULib.cmds.StringArg, completes=nzMapVote.NetworkedUnwhitelistedMaps, hint="map", error="invalid config map \"%s\" specified or it has already been whitelisted.", ULib.cmds.restrictToCompletes}
        whitelist:defaultAccess(ULib.ACCESS_ADMIN)
        whitelist:help("Add a map to the whitelist.")
    end

    -- ADD blacklist map -------------------------------------------------------------
    local function ulx_Blacklist_Add(calling_ply, map)
        nzMapVote.AddMapToBlacklist(map)

        if !ulx.fancyLogAdmin then return end
        ulx.fancyLogAdmin(calling_ply, "#A added #s to the MapVote's blacklist.", map)
    end

    local blacklist = ulx.command("nZombies MapVote", "mapvote blacklist add", ulx_Blacklist_Add, "!mapvote blacklist add")
    if blacklist.addParam and blacklist.defaultAccess and blacklist.help then
        blacklist:addParam{type=ULib.cmds.StringArg, completes=nzMapVote.NetworkedUnblacklistedMaps, hint="map", error="invalid config map \"%s\" specified or it has already been blacklisted.", ULib.cmds.restrictToCompletes}
        blacklist:defaultAccess(ULib.ACCESS_ADMIN)
        blacklist:help("Add a map to the blacklist.")
    end

    -- REMOVE whitelist map -----------------------------------------------------------
    local function ulx_Whitelist_Remove(calling_ply, map)
        nzMapVote.RemoveMapFromWhitelist(map)

        if !ulx.fancyLogAdmin then return end
        ulx.fancyLogAdmin(calling_ply, "#A removed #s from the MapVote's whitelist.", map)
    end

    local whitelist = ulx.command("nZombies MapVote", "mapvote whitelist remove", ulx_Whitelist_Remove, "!mapvote whitelist remove")
    if whitelist.addParam and whitelist.defaultAccess and whitelist.help then
        whitelist:addParam{type=ULib.cmds.StringArg, completes=nzMapVote.NetworkedWhitelistedMaps, hint="map", error="\"%s\" is not whitelisted!", ULib.cmds.restrictToCompletes}
        whitelist:defaultAccess(ULib.ACCESS_ADMIN)
        whitelist:help("Remove a map from the whitelist.")
    end

    -- REMOVE blacklist map -----------------------------------------------------------
    local function ulx_Blacklist_Remove(calling_ply, map)
        nzMapVote.RemoveMapFromBlacklist(map)

        if !ulx.fancyLogAdmin then return end
        ulx.fancyLogAdmin(calling_ply, "#A removed #s from the MapVote's blacklist.", map)
    end

    local blacklist = ulx.command("nZombies MapVote", "mapvote blacklist remove", ulx_Blacklist_Remove, "!mapvote blacklist remove")
    if blacklist.addParam and blacklist.defaultAccess and blacklist.help then
        blacklist:addParam{type=ULib.cmds.StringArg, completes=nzMapVote.NetworkedBlacklistedMaps, hint="map", error="\"%s\" is not blacklisted!", ULib.cmds.restrictToCompletes}
        blacklist:defaultAccess(ULib.ACCESS_ADMIN)
        blacklist:help("Remove a map from the blacklist.")
    end
end
