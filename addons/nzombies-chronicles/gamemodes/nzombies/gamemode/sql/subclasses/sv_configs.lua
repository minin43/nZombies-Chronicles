nzSQL = nzSQL or {}
nzSQL.Configs = nzSQL.Configs or {}

nzSQL.Configs.TableName                    =      "nz_configs"
nzSQL.Configs.ColumnNames                  =      {}
nzSQL.Configs.ColumnNames.Map              =      "map"
nzSQL.Configs.ColumnNames.Name             =      "name"
nzSQL.Configs.ColumnNames.Size             =      "size_kilobytes"
nzSQL.Configs.ColumnNames.SecondsPlayed    =      "seconds_played"

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
            ["name"] = nzSQL.Configs.ColumnNames.Size,
            ["type"] = nzSQL.Q:Number()
        },
        {
            ["name"] = nzSQL.Configs.ColumnNames.SecondsPlayed,
            ["type"] = nzSQL.Q:Number()
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
                nzSQL.Q:Equals(nzSQL.Maps.ColumnNames.Map, map_name),
                nzSQL.Q:Equals(nzSQL.Maps.ColumnNames.Name, config_name)
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
                nzSQL.Q:Equals(nzSQL.Maps.ColumnNames.Map, map_name),
                nzSQL.Q:Equals(nzSQL.Maps.ColumnNames.Name, config_name)
            })
        ),
        callback
    )
end

function nzSQL:ConfigExists(map_name, config_name, callback)
    get_value(map_name, config_name, "*", function(value)
        callback(value != nil)
    end)
end

function nzSQL.Configs:GetAll(callback)
    nzSQL:SelectRow(nzSQL.Configs.TableName, "*", nil, callback)
end

function nzSQL.Configs:GetByMap(map_name, callback)
    get_value(map_name, config_name, nzSQL.Configs.ColumnNames.Map, callback)
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
hook.Add("nzConfig.UpdatedConfigFileData", "NZ_UpdateMapDatabase", function()
    -- Add any currently existing configs not in the database yet
    for map_name,tbl in pairs(nzConfig.FileData) do
        nzSQL.Configs:ConfigExists(map_name, tbl.config_name, function(exists)
            if !exists then
                nzSQL:InsertIntoTable(nzSQL.Configs.TableName, {nzSQL.Configs.ColumnNames.Map, nzSQL.Configs.ColumnNames.Config}, {map_name, tbl.config_name})
            else -- Update the data that can change outside of the database
                -- Config size
                update_value(map_name, tbl.config_name, nzSQL.Configs.ColumnNames.Size, tbl.config_size)
            end
        end)
    end
end)
