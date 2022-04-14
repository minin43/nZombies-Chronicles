-- SQL support added to nZombies by: Ethorbit.

-- This is because Chronicles adds many things that are
-- better suited in databases rather than text files.

-- Check the README.MD for more information.

nzSQL = nzSQL or {}
nzSQL.Maps = nzSQL.Maps or {}

function nzSQL.Maps:CreateTable()
    if (!sql.TableExists("nz_maps")) then
        local query = [[CREATE TABLE nz_maps (
            name TEXT PRIMARY KEY,
            category TEXT DEFAULT "",
            seconds_played INT,
            size_kilobytes INT,
            is_whitelisted INT DEFAULT 0 NOT NULL,
            is_blacklisted INT DEFAULT 0 NOT NULL,
            is_mounted INT DEFAULT 1 NOT NULL
        );]]

        if (sql.Query(query) == false) then
            nzSQL:ShowError("Error creating nz_maps table.")
        end
    end
end

nzSQL.Maps:CreateTable()

function nzSQL.Maps:MapExists(map_name)
    local query = string.format("SELECT EXISTS(SELECT name = %s FROM nz_maps)", SQLStr(map_name))
    return sql.Query(query) == 1
end

function nzSQL.Maps:GetNames()
    return sql.Query("SELECT name FROM nz_maps")
end

function nzSQL.Maps:SetCategory(map_name, category_name)
    local query = string.format("UPDATE nz_maps SET category = %s WHERE name = %s", SQLStr(category_name), SQLStr(map_name))

    if (sql.Query(query) == false) then
        nzSQL:ShowError("Error setting map " .. map_name .. "'s category to: " .. category_name)
    end
end

function nzSQL.Maps:GetCategory(map_name)
    local query = string.format("SELECT category FROM nz_maps WHERE name = %s", SQLStr(map_name))

    if (sql.Query(query) == false) then
        nzSQL:ShowError("Error getting category for map: " .. map_name)
    end
end

function nzSQL.Maps:SetKBSize(map_name, kb_size)

end

function nzSQL.Maps:SetSecondsPlayed(map_name, seconds_played)

end

function nzSQL.Maps:GetSecondsPlayed(map_name)

end

function nzSQL.Maps:GetAllWhitelisted()

end

function nzSQL.Maps:GetAllBlacklisted()

end

function nzSQL.Maps:SetWhitelisted(map_name, is_whitelisted)

end

function nzSQL.Maps:SetBlacklisted(map_name, is_blacklisted)

end

function nzSQL.Maps:GetWhitelisted(map_name)

end

function nzSQL.Maps:GetBlacklisted(map_name)

end

-- Update all maps on server start
-- hook.Add("Initialize", "NZ_UpdateMapDatabase", function()
--     local db_maps = nzSQL.Maps:GetNames()
--     for _,map in pairs(db_maps) do
--
--     end
--
--     for _,map in pairs(nzConfig.Maps) do
--         if !current_map_list[map.name] then
--             -- Mark as not mounted
--         else
--             -- Mark as mounted if not already
--         end
--     end
-- end)
