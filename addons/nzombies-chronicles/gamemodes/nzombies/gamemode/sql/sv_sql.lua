-- SQL support added to nZombies by: Ethorbit.

-- This is because Chronicles adds many things that are
-- better suited in databases rather than text files. (Record System, Map Stats, Player Stats, and more)

-- Check the README.MD for more information.

nzSQL = nzSQL or {}

function nzSQL:ShowError(message, dontShowLastError)
    PrintMessage(HUD_PRINTTALK, "nZombies Database Error, check the host's console for details or inform an admin.")
    ServerLog(string.format("[nZombies] %s (%s)\n", message, !dontShowLastError and sql.LastError() or ""))
end

-- Override below functions in a thirdparty addon if you want to
-- use a different database other than Gmod's SQLite sv.db file

-- Of course only change what is incompatible with your database's type

-- If you're not comfortable with this, you can override the individual
-- functions from the other sql/ .lua files instead

function nzSQL:PrimaryKey()
    return "PRIMARY KEY"
end

function nzSQL:Default(value)
    return string.format("DEFAULT %s", SQLStr(value))
end

function nzSQL:Number()
    return "INT"
end

function nzSQL:String(max_length)
    return "TEXT"
end

function nzSQL:NotNull()
    return "NOT NULL"
end

-- nzSQL:CreateTable(
--    "nz_maps",
--    {
--      {
--          ["name"] = "firstCategory",
--          ["type"] = nzSQL:String(),
--          ["primary"] = true,
--          ["not_null"] = true,
--          ["default"] = "MY default value"
--      },
--      {
--          ["name"] = "secondButUselessCategory",
--            ["type"] = nzSQL:String(),
--            ["default"] = "NULL"
--      }
--    }
-- )
function nzSQL:CreateTable(table_name, columns)
    if (!sql.TableExists(table_name)) then
        local query = string.format("CREATE TABLE %s (", SQLStr(table_name))

        for i = 1, #columns do
            local column = columns[i]

            if !column.name or !column.type then
                PrintTable(column)
                nzSQL:ShowError("nzSQL.CreateTable call failed! You HAVE to provide a [name] and [type]!", true)
            return end

            query = string.format("%s %s %s", query, column.name, column.type)

            if column.primary then
                query = string.format("%s %s", query, nzSQL:PrimaryKey())
            end

            if column.default then
                query = string.format("%s %s", query, nzSQL:Default(column.default))
            end

            if column.not_null then
                query = string.format("%s %s", query, nzSQL:NotNull())
            end

            if #columns > i then
                query = query .. ","
            end
        end

        query = query .. ");"
        return query
    end
end

-- nzSQL:Equals("name", "nz_ravine")
function nzSQL:Equals(first, second)
    return string.format("%s = %s", SQLStr(first), SQLStr(second))
end

local function get_like(first, second, type)
    local str
    if !type then
        str = SQLStr("%" .. second .. "%")
    else
        str = (type == "endswith" and SQLStr("%" .. second) or type == "beginswith" and SQLStr(second .. "%"))
    end

    return string.format("%s LIKE %s", SQLStr(first), str)
end

-- nzSQL:Contains("name", "nz_ra")
function nzSQL:Contains(column, text)
    return get_like(column, text)
end

-- nzSQL:BeginsWith("name", "nz_")
function nzSQL:BeginsWith(column, text)
    return get_like(column, text, "beginswith")
end

-- nzSQL:EndsWith("name", "_ravine")
function nzSQL:EndsWith(column, text)
    return get_like(column, text, "endswith")
end

-- nzSQL:Where( nzSQL:Equals("name", "nz_ravine") )
function nzSQL:Where(strOrNil)
    return "WHERE" .. (strOrNil and " " .. strOrNil or "")
end

local function get_condition_string(condition_type, condition_table)
    local return_string = ""

    for i = 1, #condition_table do
        local condition = condition_table[i]

        return_string = return_string .. condition

        if i != #condition_table then
            return_string = return_string .. " " .. condition_type .. " "
        end
    end

    return return_string
end

-- nzSQL:Where( nzSQL:And({ nzSQL:Contains("name", "ttt_"), nzSQL:Contains("name", "gm_") }) )
function nzSQL:And(condition_table)
    return get_condition_string("AND", condition_table)
end

-- nzSQL:Or({ nzSQL:Equals("name", "gm_flatgrass"), nzSQL:Equals("name", "gm_construct") })
function nzSQL:Or(condition_table)
    return get_condition_string("OR", condition_table)
end

-- nzSQL:UpdateRow("nz_maps", "category", "Unlisted Maps", nzSQL:Where( nzSQL:Equals("name", "nz_ravine")) )
function nzSQL:UpdateRow(table_name, column_name, value, condition)

end

-- local ravineStats = nzSQL:SelectRow("nz_maps", "map", nzSQL:Where( nzSQL:Equals("name", "nz_ravine")) )
function nzSQL:SelectRow(table_name, column_name, condition)

end

-- if (nzSQL:RowExists("nz_maps", "map_name", "gm_flatgrass")) then // code end
function nzSQL:RowExists(table_name, column_name, value)
    local query = string.format("SELECT EXISTS(SELECT %s FROM %s)", nzSQL:Equals(column_name, value), SQLStr(table_name))
    local val = sql.Query(query)

    if (val == false) then
        nzSQL:ShowError("Failed to check row's existence in table: " .. table_name)
    return end

    return val
end
