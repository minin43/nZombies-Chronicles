-- SQL support added to nZombies by: Ethorbit.

-- This is because Chronicles adds many things that are
-- better suited in databases rather than text files.

-- Check the README.MD for more information.

nzSQL = nzSQL or {}
nzSQL.Maps = nzSQL.Maps or {}
nzSQL.Maps.TableName = "nz_maps"

nzSQL:CreateTable(
   nzSQL.Maps.TableName,
   {
        {
            ["name"] = "name",
            ["type"] = nzSQL.Q:String(32),
            ["primary"] = true
        },
        {
            ["name"] = "category",
            ["type"] = nzSQL.Q:String(120),
            ["default"] = "Other"
        },
        {
            ["name"] = "seconds_played",
            ["type"] = nzSQL.Q:Number()
        },
        {
            ["name"] = "size_kilobytes",
            ["type"] = nzSQL.Q:Number()
        },
        {
            ["name"] = "is_whitelisted",
            ["type"] = nzSQL.Q:Number(),
            ["default"] = "0",
            ["not_null"] = true
        },
        {
            ["name"] = "is_blacklisted",
            ["type"] = nzSQL.Q:Number(),
            ["default"] = "0",
            ["not_null"] = true
        },
        {
            ["name"] = "is_mounted",
            ["type"] = nzSQL.Q:Number(),
            ["default"] = "1",
            ["not_null"] = true
        }
   }
)

function nzSQL.Maps:MapExists(map_name, callback)
    nzSQL:RowExists(nzSQL.Maps.TableName, "name", map_name, nil, callback)
end

function nzSQL.Maps:GetNames(callback)
    nzSQL:SelectRow(nzSQL.Maps.TableName, "name", nil, callback)
end

function nzSQL.Maps:SetCategory(map_name, category_name, callback)
    nzSQL:UpdateRow(nzSQL.Maps.TableName, "category", category_name, nzSQL.Q:Where(nzSQL.Q:Equals("name", map_name)), callback)
end

function nzSQL.Maps:GetCategory(map_name, callback)
    nzSQL:SelectRow(nzSQL.Maps.TableName, "category", nil, callback)
end

function nzSQL.Maps:SetKBSize(map_name, kb_size, callback)
    nzSQL:UpdateRow(nzSQL.Maps.TableName, "size_kilobytes", kb_size, nzSQL.Q:Where(nzSQL.Q:Equals("name", map_name)), callback)
end

function nzSQL.Maps:SetSecondsPlayed(map_name, seconds_played, callback)
    nzSQL:UpdateRow(nzSQL.Maps.TableName, "seconds_played", seconds_played, nzSQL.Q:Where(nzSQL.Q:Equals("name", map_name)), callback)
end

function nzSQL.Maps:GetSecondsPlayed(map_name, callback)
    nzSQL:SelectRow(nzSQL.Maps.TableName, "seconds_played", nil, callback)
end

function nzSQL.Maps:GetAllWhitelisted(callback)
    nzSQL:SelectRow(nzSQL.Maps.TableName, "name", nzSQL.Q:Where(nzSQL.Q:Equals("is_whitelisted", "1")), callback)
end

function nzSQL.Maps:GetAllBlacklisted(callback)
    nzSQL:SelectRow(nzSQL.Maps.TableName, "name", nzSQL.Q:Where(nzSQL.Q:Equals("is_blacklisted", "1")), callback)
end

function nzSQL.Maps:SetWhitelisted(map_name, is_whitelisted, callback)
    nzSQL:UpdateRow(nzSQL.Maps.TableName, "is_whitelisted", is_whitelisted, nzSQL.Q:Where(nzSQL.Q:Equals("name", map_name)), callback)
end

function nzSQL.Maps:SetBlacklisted(map_name, is_blacklisted, callback)
    nzSQL:UpdateRow(nzSQL.Maps.TableName, "is_blacklisted", is_blacklisted, nzSQL.Q:Where(nzSQL.Q:Equals("name", map_name)), callback)
end

function nzSQL.Maps:GetWhitelisted(map_name, callback)
    nzSQL:SelectRow(nzSQL.Maps.TableName, "name", nzSQL.Q:Where( nzSQL.Q:And({ nzSQL.Q:Equals("is_whitelisted", "1"), nzSQL.Q:Equals("name", map_name)} )), callback)
end

function nzSQL.Maps:GetBlacklisted(map_name, callback)
    nzSQL:SelectRow(nzSQL.Maps.TableName, "name", nzSQL.Q:Where( nzSQL.Q:And({ nzSQL.Q:Equals("is_blacklisted", "1"), nzSQL.Q:Equals("name", map_name)} )), callback)
end

-- Update all maps on server start
hook.Add("Initialize", "NZ_UpdateMapDatabase", function()
    local db_maps = nzSQL.Maps:GetNames()
    -- for _,map in pairs(db_maps) do
    --     if !nzConfig.FileData[map] then
    --
    --     else
    --
    --     end
    -- end

    for mapname,maptbl in pairs(nzConfig.MapData) do
        nzSQL:SelectExists(nzSQL.Maps.TableName, mapname, function(value)
            if value == 0 then
                nzSQL:InsertIntoTable(nzSQL.Maps.TableName, {"name", "size_kilobytes"}, {mapname, maptbl.map_size})
            end
        end)
    end
end)
