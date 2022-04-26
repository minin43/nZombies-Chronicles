nzSQL = nzSQL or {}
nzSQL.Configs = nzSQL.Configs or {}

nzSQL.Configs.TableName                    =      "nz_configs"
nzSQL.Configs.ColumnNames                  =      {}
nzSQL.Configs.ColumnNames.Map              =      "map"
nzSQL.Configs.ColumnNames.Name             =      "name"
nzSQL.Configs.ColumnNames.Category         =      "category"
nzSQL.Configs.ColumnNames.Size             =      "size_kilobytes"
nzSQL.Configs.ColumnNames.SecondsPlayed    =      "seconds_played"
nzSQL.Configs.ColumnNames.IsWhitelisted    =      "is_whitelisted"
nzSQL.Configs.ColumnNames.IsBlacklisted    =      "is_blacklisted"
nzSQL.Configs.ColumnNames.IsMounted        =      "is_mounted"

nzSQL:CreateTable(
   nzSQL.Configs.TableName,
   {
        {
            ["name"] = nzSQL.Configs.ColumnNames.Map,
            ["type"] = nzSQL.Q:String(32),
            ["not_null"] = true
        },
        {
            ["name"] = nzSQL.Configs.ColumnNames.Name,
            ["type"] = nzSQL.Q:String(260),
            ["not_null"] = true
        },
        {
            ["name"] = nzSQL.Configs.ColumnNames.Category,
            ["type"] = nzSQL.Q:String(120),
            ["default"] = ""
        },
        {
            ["name"] = nzSQL.Configs.ColumnNames.Size,
            ["type"] = nzSQL.Q:Number(),
            ["default"] = "0"
        },
        {
            ["name"] = nzSQL.Configs.ColumnNames.SecondsPlayed,
            ["type"] = nzSQL.Q:Number(),
            ["default"] = "0"
        },
        {
            ["name"] = nzSQL.Configs.ColumnNames.IsWhitelisted,
            ["type"] = nzSQL.Q:Number(),
            ["default"] = "0",
            ["not_null"] = true
        },
        {
            ["name"] = nzSQL.Configs.ColumnNames.IsBlacklisted,
            ["type"] = nzSQL.Q:Number(),
            ["default"] = "0",
            ["not_null"] = true
        },
        {
            ["name"] = nzSQL.Configs.ColumnNames.IsMounted,
            ["type"] = nzSQL.Q:Number(),
            ["default"] = "1",
            ["not_null"] = true
        }
   }
)

local function update_value(map_name, config_name, column_name, value)
    nzSQL:UpdateRow(
        nzSQL.Configs.TableName,
        column_name,
        value,
        nzSQL.Q:Where(
            nzSQL.Q:And({
                nzSQL.Q:Equals(nzSQL.Configs.ColumnNames.Map, map_name),
                nzSQL.Q:Equals(nzSQL.Configs.ColumnNames.Name, config_name)
            })
        )
    )
end

local function get_value(map_name, config_name, column_name, callback)
    nzSQL:SelectRow(
        nzSQL.Configs.TableName,
        column_name,
        nzSQL.Q:Where(
            nzSQL.Q:And({
                nzSQL.Q:Equals(nzSQL.Configs.ColumnNames.Map, map_name),
                nzSQL.Q:Equals(nzSQL.Configs.ColumnNames.Name, config_name)
            })
        ),
        callback
    )
end

local function get_value_filtered(map_name, whitelisted, includeUnmounted, callback)
    nzSQL:SelectRow(
        nzSQL.Configs.TableName,
        "*",
        nzSQL.Q:Where(
            nzSQL.Q:And({
                nzSQL.Q:Equals(whitelisted and nzSQL.Configs.ColumnNames.IsWhitelisted or nzSQL.Configs.ColumnNames.IsBlacklisted, "1"),
                nzSQL.Q:Equals(nzSQL.Configs.ColumnNames.Map, map_name),
                includeUnmounted and nzSQL.Q:Equals(nzSQL.Configs.ColumnNames.IsMounted, "1") or nil
            })
        ),
        callback
    )
end

function nzSQL.Configs:ConfigExists(map_name, config_name, callback)
    get_value(map_name, config_name, "*", function(value)
        callback(value != nil)
    end)
end

function nzSQL.Configs:GetAll(callback)
    nzSQL:SelectRow(nzSQL.Configs.TableName, "*", nil, callback)
end

function nzSQL.Configs:GetAllWhitelisted(map_name, callback, includeUnmounted)
    get_value_filtered(map_name, true, includeUnmounted, callback)
end

function nzSQL.Configs:GetAllBlacklisted(map_name, callback, includeUnmounted)
    get_value_filtered(map_name, false, includeUnmounted, callback)
end

function nzSQL.Configs:GetByMap(map_name, callback)
    get_value(map_name, config_name, nzSQL.Configs.ColumnNames.Map, callback)
end

function nzSQL.Configs:SetWhitelisted(map_name, config_name, is_whitelisted, callback)
    update_value(map_name, config_name, nzSQL.Configs.ColumnNames.IsWhitelisted, is_whitelisted)
end

function nzSQL.Configs:GetWhitelisted(map_name, config_name, callback)
    get_value(map_name, config_name, nzSQL.Configs.ColumnNames.IsWhitelisted, callback)
end

function nzSQL.Configs:SetBlacklisted(map_name, config_name, is_blacklisted, callback)
    update_value(map_name, config_name, nzSQL.Configs.ColumnNames.IsBlacklisted, is_blacklisted)
end

function nzSQL.Configs:GetBlacklisted(map_name, config_name, callback)
    get_value(map_name, config_name, nzSQL.Configs.ColumnNames.IsBlacklisted, callback)
end

function nzSQL.Configs:GetSize(map_name, config_name, callback)
    get_value(map_name, config_name, nzSQL.Configs.ColumnNames.Size, callback)
end

function nzSQL.Configs:GetSecondsPlayed(map_name, config_name, callback)
    get_value(map_name, config_name, nzSQL.Configs.ColumnNames.SecondsPlayed, callback)
end

function nzSQL.Configs:SetSecondsPlayed(map_name, config_name, seconds)
    update_value(map_name, config_name, nzSQL.Configs.ColumnNames.SecondsPlayed, seconds)
end

-- Update all configs on server start
hook.Add("nzConfig.UpdatedConfigFileData", "NZ_UpdateConfigDatabase", function()
    -- Add any currently existing configs not in the database yet
    for map_name,tbl in pairs(nzConfig.FileData) do
        for _,map_tbl in pairs(tbl) do
            nzSQL.Configs:ConfigExists(map_name, map_tbl.config_name, function(exists)
                if !exists then
                    nzSQL:InsertIntoTable(nzSQL.Configs.TableName, {nzSQL.Configs.ColumnNames.Map, nzSQL.Configs.ColumnNames.Name}, {map_name, map_tbl.config_name})
                else -- Update the data that can change outside of the database
                    -- Config size
                    update_value(map_name, map_tbl.config_name, nzSQL.Configs.ColumnNames.Size, map_tbl.config_size)
                end
            end)
        end
    end
end)
