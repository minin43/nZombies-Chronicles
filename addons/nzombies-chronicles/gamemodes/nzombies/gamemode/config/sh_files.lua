-- Created by Ethorbit to make the implementation of the Chronicles server's (heavily modified) Map Vote much simpler

-- Also I think it's useful to be able to get this data, for example, maybe you created a thirdparty addon
-- that will list the easter eggs currently active in every single map, well now that won't be so painful for you to get.

nzConfig = nzConfig or AddNZModule("Config")
nzConfig.Filenames = nzConfig.Filenames or {}
nzConfig.FileData = nzConfig.FileData or {}
nzConfig.Maps = nzConfig.Maps or {}

function nzConfig.GetAllMaps() -- Get all maps that have configs
    return table.Copy(nzConfig.Maps)
end

function nzConfig.GetAllFilenames() -- Get all config filenames
    return table.Copy(nzConfig.Filenames)
end

function nzConfig.GetFilenameProperties(filename) -- Gets the map, config name and workshop id (if present), from a config filename
    local cfg = string.Explode(";", string.StripExtension(filename))
    local map, configname, workshopid = string.sub(cfg[1], 4), cfg[2], cfg[3]

    return {
        ["map"] = map,
        ["configname"] = configname,
        ["workshopid"] = workshopid
    }
end

function nzConfig.GetConfigData() -- Get a table of all maps with their configs, each containing file data like name, config name, path, type, etc
    return table.Copy(nzConfig.FileData)
end

function nzConfig.GetMapConfigFileList(map) -- Get a map's config file data
    return table.Copy(nzConfig.FileData[map])
end

if SERVER then -- We don't network stuff in here due to net packet and config privacy concerns - it is up to YOU to do that.
    -- Get a specific config's map settings:
    function nzConfig.GetMapSettings(mapname, configname)
        if !nzConfig.FileData[mapname] then ServerLog("[nzConfig.GetMapSettings] There is no config for that map." .. " (" .. mapname .. ")\n") return {} end

        for _,data in pairs(nzConfig.FileData[mapname]) do
            if (!configname or data.configname == configname) then
                local content = file.Read(data.directory .. data.filename, data.pathtype)
                if content == nil then continue end

                local tbl = util.JSONToTable(content)
                if tbl == nil then continue end -- It's not a valid config

                return tbl.MapSettings
            end
        end

        ServerLog("[nzConfig.GetMapSettings] There is no config called " .. configname .. " for " .. mapname .. "\n")
        return {}
    end
end

----------------------------------------------------------------------
if SERVER then
    util.AddNetworkString("RequestConfigData")
    util.AddNetworkString("HereIsConfigData")

    local last_update = 0
    local last_data = nil
    local function getCachedCompressedData() -- Returns cached data from a minimum of the last 10 seconds, for performance when dealing with multiple clients at once.
        if (!isnumber(last_update) or CurTime() - last_update > 10) then
            last_data = util.Compress(util.TableToJSON(nzConfig.FileData))
            last_update = CurTime()
        end

        return last_data or ""
    end

    function nzConfig.SendDataToClientside(ply)
        local filedata = getCachedCompressedData()
        net.Start("HereIsConfigData")
        net.WriteTable(nzConfig.Filenames)
        net.WriteInt(#filedata, 32)
        net.WriteData(filedata, #filedata)
        net.WriteTable(nzConfig.Maps)

        if !ply then
            net.Broadcast()
        else
            net.Send(ply)
        end
    end

    net.Receive("RequestConfigData", function(len, ply)
        if (!isnumber(ply.LastConfigDataUpdate) or CurTime() - ply.LastConfigDataUpdate > 1) then -- Nobody should be requesting data more often than this..
            ply.LastConfigDataUpdate = CurTime()
            nzConfig.SendDataToClientside(ply)
        end
    end)
end

if CLIENT then
    net.Receive("HereIsConfigData", function()
        nzConfig.Filenames = net.ReadTable()

        local data_filedata_length = net.ReadInt(32)
        local data_filedata = util.Decompress(net.ReadData(data_filedata_length))
        nzConfig.FileData = util.JSONToTable(data_filedata)
        nzConfig.Maps = net.ReadTable()

        hook.Run("nzConfig.UpdatedConfigFileData")
    end)
end

function nzConfig.UpdateData(is_first_time) -- Add the filenames and FileData for all mounted configs
    if SERVER then
        nzConfig.Filenames = {}
        nzConfig.FileData = {}
        nzConfig.Maps = {}
        local added_maps = {}

        for _,fileData in pairs({
            {path = "nz/", pattern = "*.txt", type = "DATA"},
            {path = "nz/", pattern = "*.lua", type = "LUA"},
            {path = "gamemodes/nzombies/officialconfigs/", pattern = "*.lua", type = "GAME"}
        }) do
            local directory = type == "GAME" and "" or string.lower(fileData.type) .. "/"
            local filenames = file.Find(fileData.path .. fileData.pattern, fileData.type)

            for _,filename in pairs(filenames) do
                if (hook.Run("NZConfig.ShouldAddFilename", filename) == false) then continue end

                local full_path = directory .. fileData.path .. filename
                local props = nzConfig.GetFilenameProperties(filename)
                if !props.configname then continue end

                if (hook.Run("NZConfig.ShouldAddMap", props.map) == false) then continue end

                nzConfig.Filenames[#nzConfig.Filenames + 1] = filename
                nzConfig.FileData = nzConfig.FileData or {}
                nzConfig.FileData[props.map] = nzConfig.FileData[props.map] or {}

                if !added_maps[props.map] then
                    nzConfig.Maps[#nzConfig.Maps + 1] = props.map
                    added_maps[props.map] = true
                end

                table.insert(nzConfig.FileData[props.map], { -- We won't store big data here, rather we make functions for that above to save on memory/network bandwidth
                    ["filepath"] = full_path,
                    ["filename"] = filename,
                    ["directory"] = fileData.path,
                    ["pathtype"] = fileData.type,
                    ["configname"] = props.configname
                    --["workshopid"] = props.workshopid
                })
            end
        end

        if !is_first_time then
            nzConfig.SendDataToClientside()
        end

        hook.Run("nzConfig.UpdatedConfigFileData")
    else
        net.Start("RequestConfigData")
        net.SendToServer()
    end
end
hook.Add(SERVER and "Initialize" or "InitPostEntity", "UpdateConfigFNAndData", function()
    nzConfig.UpdateData(true)
end)

--nzConfig.UpdateData()
