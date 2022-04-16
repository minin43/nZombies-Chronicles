-- SQL support added to nZombies by: Ethorbit.

-- This is because Chronicles adds many things that are
-- better suited in databases rather than text files.

-- Check the README.MD for more information.

nzSQL = nzSQL or {}
nzSQL.Maps = nzSQL.Maps or {}

nzSQL.Maps.TableName                    =      "nz_maps"
nzSQL.Maps.ColumnNames                  =      {}
nzSQL.Maps.ColumnNames.Name             =      "name"
nzSQL.Maps.ColumnNames.Category         =      "category"
nzSQL.Maps.ColumnNames.SecondsPlayed    =      "seconds_played"
nzSQL.Maps.ColumnNames.Size             =      "size_kilobytes"
nzSQL.Maps.ColumnNames.IsWhitelisted    =      "is_whitelisted"
nzSQL.Maps.ColumnNames.IsBlacklisted    =      "is_blacklisted"
nzSQL.Maps.ColumnNames.IsMounted        =      "is_mounted"

nzSQL:CreateTable(
   nzSQL.Maps.TableName,
   {
        {
            ["name"] = nzSQL.Maps.ColumnNames.Name,
            ["type"] = nzSQL.Q:String(32),
            ["primary"] = true
        },
        {
            ["name"] = nzSQL.Maps.ColumnNames.Category,
            ["type"] = nzSQL.Q:String(120),
            ["default"] = "Other"
        },
        {
            ["name"] = nzSQL.Maps.ColumnNames.SecondsPlayed,
            ["type"] = nzSQL.Q:Number()
        },
        {
            ["name"] = nzSQL.Maps.ColumnNames.Size,
            ["type"] = nzSQL.Q:Number()
        },
        {
            ["name"] = nzSQL.Maps.ColumnNames.IsWhitelisted,
            ["type"] = nzSQL.Q:Number(),
            ["default"] = "0",
            ["not_null"] = true
        },
        {
            ["name"] = nzSQL.Maps.ColumnNames.IsBlacklisted,
            ["type"] = nzSQL.Q:Number(),
            ["default"] = "0",
            ["not_null"] = true
        },
        {
            ["name"] = nzSQL.Maps.ColumnNames.IsMounted,
            ["type"] = nzSQL.Q:Number(),
            ["default"] = "1",
            ["not_null"] = true
        }
   }
)

function nzSQL.Maps:MapExists(map_name, callback)
    nzSQL:SelectRow(nzSQL.Maps.TableName, "*", nzSQL.Q:Where(nzSQL.Q:Equals(nzSQL.Maps.ColumnNames.Name, map_name)), function(value)
        callback(value != nil)
    end)
end

function nzSQL.Maps:GetAllNames(callback, includeUnmounted)
    nzSQL:SelectRow(nzSQL.Maps.TableName, nzSQL.Maps.ColumnNames.Name, !includeUnmounted and nzSQL.Q:Where( nzSQL.Q:Equals(nzSQL.Maps.ColumnNames.IsMounted, "1")) or nil, callback)
end

function nzSQL.Maps:GetAllWhitelisted(callback, includeUnmounted)
    nzSQL:SelectRow(nzSQL.Maps.TableName, nzSQL.Maps.ColumnNames.Name, nzSQL.Q:Where( !includeUnmounted and nzSQL.Q:And({nzSQL.Q:Equals(nzSQL.Maps.ColumnNames.IsWhitelisted, "1"), nzSQL.Q:Equals(nzSQL.Maps.ColumnNames.IsMounted, "1")}) or nzSQL.Q:Equals(nzSQL.Maps.ColumnNames.IsWhitelisted, "1")), callback)
end

function nzSQL.Maps:GetAllBlacklisted(callback, includeUnmounted)
    nzSQL:SelectRow(nzSQL.Maps.TableName, nzSQL.Maps.ColumnNames.Name, nzSQL.Q:Where(!includeUnmounted and nzSQL.Q:And({nzSQL.Q:Equals(nzSQL.Maps.ColumnNames.IsBlacklisted, "1"), nzSQL.Q:Equals(nzSQL.Maps.ColumnNames.IsMounted, "1")}) or nzSQL.Q:Equals(nzSQL.Maps.ColumnNames.IsBlacklisted, "1")), callback)
end

function nzSQL.Maps:SetWhitelisted(map_name, is_whitelisted, callback)
    nzSQL:UpdateRow(nzSQL.Maps.TableName, "is_whitelisted", is_whitelisted, nzSQL.Q:Where(nzSQL.Q:Equals(nzSQL.Maps.ColumnNames.Name, map_name)), callback)
end

function nzSQL.Maps:GetWhitelisted(map_name, callback)
    nzSQL:SelectRow(nzSQL.Maps.TableName, nzSQL.Maps.ColumnNames.Name, nzSQL.Q:Where( nzSQL.Q:And({ nzSQL.Q:Equals("is_whitelisted", "1"), nzSQL.Q:Equals(nzSQL.Maps.ColumnNames.Name, map_name)} )), callback)
end

function nzSQL.Maps:SetBlacklisted(map_name, is_blacklisted, callback)
    nzSQL:UpdateRow(nzSQL.Maps.TableName, "is_blacklisted", is_blacklisted, nzSQL.Q:Where(nzSQL.Q:Equals(nzSQL.Maps.ColumnNames.Name, map_name)), callback)
end

function nzSQL.Maps:GetBlacklisted(map_name, callback)
    nzSQL:SelectRow(nzSQL.Maps.TableName, nzSQL.Maps.ColumnNames.Name, nzSQL.Q:Where( nzSQL.Q:And({ nzSQL.Q:Equals("is_blacklisted", "1"), nzSQL.Q:Equals(nzSQL.Maps.ColumnNames.Name, map_name)} )), callback)
end

function nzSQL.Maps:SetCategory(map_name, category_name, callback)
    nzSQL:UpdateRow(nzSQL.Maps.TableName, nzSQL.Maps.ColumnNames.Category, category_name, nzSQL.Q:Where(nzSQL.Q:Equals(nzSQL.Maps.ColumnNames.Name, map_name)), callback)
end

function nzSQL.Maps:GetCategory(map_name, callback)
    nzSQL:SelectRow(nzSQL.Maps.TableName, nzSQL.Maps.ColumnNames.Category, nil, callback)
end

function nzSQL.Maps:GetSize(map_name, callback)
    nzSQL:SelectRow(nzSQL.Maps.TableName, nzSQL.Maps.ColumnNames.Size, nzSQL.Q:Where(nzSQL.Q:Equals(nzSQL.Maps.ColumnNames.Name, map_name)), callback)
end

function nzSQL.Maps:SetSecondsPlayed(map_name, seconds_played, callback)
    nzSQL:UpdateRow(nzSQL.Maps.TableName, nzSQL.Maps.ColumnNames.SecondsPlayed, seconds_played, nzSQL.Q:Where(nzSQL.Q:Equals(nzSQL.Maps.ColumnNames.Name, map_name)), callback)
end

function nzSQL.Maps:GetSecondsPlayed(map_name, callback)
    nzSQL:SelectRow(nzSQL.Maps.TableName, nzSQL.Maps.ColumnNames.SecondsPlayed, nzSQL.Q:Where(nzSQL.Q:Equals(nzSQL.Maps.ColumnNames.Name, map_name)), callback)
end

-- Update all maps on server start
hook.Add("nzConfig.UpdatedConfigFileData", "NZ_UpdateMapDatabase", function()
    -- Add any currently existing maps not in the database yet
    for mapname,maptbl in pairs(nzConfig.MapData) do
        nzSQL.Maps:MapExists(mapname, function(exists)
            if !exists then
                nzSQL:InsertIntoTable(nzSQL.Maps.TableName, {nzSQL.Maps.ColumnNames.Name}, {mapname})
            end
        end)
    end

    -- Update the data that can change outside of the database
    nzSQL.Maps:GetAllNames(function(names)
        for _,map_name in pairs(nzSQL.Result:GetValues(names)) do
            -- Mounted status
            nzSQL:UpdateRow(nzSQL.Maps.TableName, nzSQL.Maps.ColumnNames.IsMounted, nzConfig.MapData[map_name] and "1" or "0", nzSQL.Q:Where(nzSQL.Q:Equals(nzSQL.Maps.ColumnNames.Name, map_name)))

            if nzConfig.MapData[map_name] then
                -- Map size
                local size = nzConfig.MapData[map_name].map_size
                nzSQL:UpdateRow(nzSQL.Maps.TableName, nzSQL.Maps.ColumnNames.Size, size, nzSQL.Q:Where(nzSQL.Q:Equals(nzSQL.Maps.ColumnNames.Name, map_name)))
            end
        end
    end)
end)
