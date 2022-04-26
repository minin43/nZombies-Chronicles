-- SQL support added to nZombies by: Ethorbit.

-- This is because Chronicles adds many things that are
-- better suited in databases rather than text files. (Record System, Map Stats, Player Stats, and more)

-- Check the README.MD for more information.

nzSQL = nzSQL or {} -- Class for working with a database
nzSQL.Q = nzSQL.Q or {} -- Class for turning argumments into strings compatible with database queries
nzSQL.Result = nzSQL.Result or {} -- Class for working with callback data returned from nzSQL.Query

-- Override below functions in a thirdparty addon if you want to
-- use a different database other than Gmod's SQLite sv.db file

-- Of course only change what is incompatible with your database's type

-- If you're not comfortable with this, you can override the individual
-- functions from the other sql/ .lua files instead

-- nzSQL:ShowError({"Error with", table_name, sql.LastError()})
function nzSQL:ShowError(messages) -- Error handling is SQLite only, override func otherwise
    PrintMessage(HUD_PRINTTALK, "nZombies Database Error, check the host's console for details or inform an admin.")

    local message_string = ""

    for k,message in pairs(messages) do
        message_string = message_string .. (k != 1 and " " or "") .. message
    end

    debug.Trace()
    ServerLog(string.format("[nZombies Database Error] %s\n", message_string))
end

-- nzSQL:Query(nzSQL:SelectRow("nz_maps", "name"), function(maps) PrintTable(maps) end)
-- If you're overriding this, know that the above would send data structured like so to callback:
-- 1:
-- 		name	=	dm_lockdown
-- 2:
-- 		name	=	gm_flatgrass
-- 3:
-- 		name	=	gm_construct

-- (the name is the table's column and the value is row's column value)
-- If it's any different, the gamemode will not utilize this properly.
function nzSQL:Query(query, messagesOnError, callback)
    -- sql.Query and sql.LastError is
    -- for SQLite only, override func otherwise
    local val = sql.Query(query)

    if val == false then
        messagesOnError = messagesOnError or {"Error"}
        messagesOnError[#messagesOnError + 1] = sql.LastError()
        messagesOnError[#messagesOnError + 1] = " The query that failed: " .. query
        nzSQL:ShowError(messagesOnError)
    end

    print("[nZombies Database] " .. query)

    if isfunction(callback) then
        callback(val)
    end
end

-- PrintTable(nzSQL.Result:GetFirstRow(value))
-- name   =	  dm_lockdown
function nzSQL.Result:GetFirstRow(nzsql_query_data)
    return nzsql_query_data[1]
end

-- print(nzSQL.Result:GetFirstValue(value))
-- dm_lockdown
function nzSQL.Result:GetFirstValue(nzsql_query_data)
    if istable(nzsql_query_data) and istable(nzsql_query_data[1]) then
        nzsql_query_data = nzSQL.Result:GetFirstRow(nzsql_query_data)
    end

    for _,v in pairs(nzsql_query_data) do
        return v
    end
end

-- 1	=	dm_lockdown
-- 2	=	gm_flatgrass
-- 3	=	gm_construct
function nzSQL.Result:GetValues(nzsql_query_data)
    local values = {}

    for _,tbl in pairs(nzsql_query_data) do
        for _,value in pairs(tbl) do
            values[#values + 1] = value
        end
    end

    return values
end

-- nzSQL:CreateTable(
--    "nz_maps",
--    {
--      {
--          ["name"] = "firstColumn",
--          ["type"] = nzSQL:String(),
--          ["primary"] = true,
--          ["not_null"] = true,
--          ["default"] = "MY default value"
--      },
--      {
--          ["name"] = "secondButUselessColumn",
--            ["type"] = nzSQL:String(),
--            ["default"] = "NULL"
--      }
--    }
-- )
function nzSQL:CreateTable(table_name, columns, callback)
    if (!sql.TableExists(table_name)) then
        local query = string.format("CREATE TABLE %s (", SQLStr(table_name))

        local primary_key_defined

        for k,v in pairs(columns) do
            if v.primary then
                primary_key_defined = true
                break
            end
        end

        if !primary_key_defined then -- There should always be a primary key.
            query = string.format("%s id %s,", query, nzSQL.Q:PrimaryKey())
        end

        for i = 1, #columns do
            local column = columns[i]

            if !column.name or !column.type then
                PrintTable(column)
                nzSQL:ShowError("nzSQL.CreateTable call failed! You HAVE to provide a [name] and [type]!", true)
            return end

            query = string.format("%s %s %s", query, column.name, column.type)

            if column.primary then
                query = string.format("%s %s", query, nzSQL.Q:PrimaryKey())
            end

            if column.default then
                query = string.format("%s %s", query, nzSQL.Q:Default(column.default))
            end

            if column.not_null then
                query = string.format("%s %s", query, nzSQL.Q:NotNull())
            end

            if #columns > i then
                query = query .. ","
            end
        end

        query = query .. ");"
        nzSQL:Query(query, {"Error creating table:", table_name or ""}, callback)
    end
end

-- nzSQL:InsertIntoTable("nz_maps", {"name", "category"}, {"Map Name", "Category Name"})
-- nzSQL:InsertIntoTable("columns_test", nil, {"First Column's Value", "Second Column's Value", "Third Column's Value"})
function nzSQL:InsertIntoTable(table_name, keys, values, callback)
    local query = string.format("INSERT INTO %s %s", SQLStr(table_name), keys != nil and "(" or "")

    if keys != nil then
        for i = 1, #keys do
            local key = keys[i]
            query = string.format("%s%s", query, SQLStr(key))

            if i < #keys then
                query = query .. ", "
            end
        end
    end

    query = string.format("%s%s", query, keys != nil and ") VALUES (" or "VALUES (")

    for i = 1, #values do
        local value = values[i]
        query = string.format("%s%s", query, SQLStr(value))

        if i < #values then
            query = query .. ", "
        end
    end

    query = query .. ");"
    nzSQL:Query(query, {"Failed to insert new row into table:", table_name or ""}, callback)
end

-- nzSQL:UpdateRow("nz_maps", "category", "Unlisted Maps", nzSQL.Q:Where( nzSQL.Q:Equals("name", "nz_ravine")) )
function nzSQL:UpdateRow(table_name, column_name, value, condition)
    local query = string.format("UPDATE %s SET %s = %s %s", SQLStr(table_name), SQLStr(column_name, true), SQLStr(value), condition or "")
    nzSQL:Query(query, {"Error updating row for table:", table_name})
end

-- local ravineStats = nzSQL:SelectRow("nz_maps", "map", nzSQL.Q:Where( nzSQL.Q:Equals("name", "nz_ravine")) )
function nzSQL:SelectRow(table_name, column_name, condition, callback)
    local query = string.format("SELECT %s FROM %s %s", SQLStr(column_name, true), SQLStr(table_name), condition or "")
    nzSQL:Query(query, {"Error selecting row for table:", column_name or ""}, callback)
end

-- nzSQL:SelectExists("nz_maps", "*", function(value) if value then // nz_maps table exists! end end)
function nzSQL:SelectExists(table_name, column_name, callback)
    local query = string.format("SELECT EXISTS(SELECT %s FROM %s)", SQLStr(column_name, true), SQLStr(table_name))
    nzSQL:Query(query, {"Error checking column existence for table:", table_name or ""}, callback)
end

function nzSQL.Q:PrimaryKey()
    return "PRIMARY KEY"
end

function nzSQL.Q:Default(value)
    return string.format("DEFAULT %s", SQLStr(value))
end

function nzSQL.Q:Number()
    return "INT"
end

function nzSQL.Q:String(max_length)
    return "TEXT"
end

function nzSQL.Q:NotNull()
    return "NOT NULL"
end

-- nzSQL.Q:Equals("name", "nz_ravine")
function nzSQL.Q:Equals(first, second)
    return string.format("%s = %s", SQLStr(first, true), SQLStr(second))
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

-- nzSQL.Q:Contains("name", "nz_ra")
-- Unmodified: "name LIKE '%nz_ra%'"
function nzSQL.Q:Contains(column, text)
    return get_like(column, text)
end

-- nzSQL.Q:BeginsWith("name", "nz_")
-- Unmodified: "name LIKE 'nz_%'"
function nzSQL.Q:BeginsWith(column, text)
    return get_like(column, text, "beginswith")
end

-- nzSQL.Q:EndsWith("name", "_ravine")
-- Unmodified: "name LIKE '%_ravine'"
function nzSQL.Q:EndsWith(column, text)
    return get_like(column, text, "endswith")
end

-- nzSQL.Q:Where( nzSQL.Q:Equals("name", "nz_ravine") )
-- Unmodified: "WHERE name = 'nz_ravine'"
function nzSQL.Q:Where(strOrNil)
    return "WHERE" .. (strOrNil and " " .. strOrNil or "")
end

-- Helper function that chains AND, OR, etc between conditionals in the conditional_table
-- condition_type - what to separate the conditionals with
local function get_condition_string(condition_type, condition_table)
    local return_string = ""

    for i = 1, #condition_table do
        local condition = condition_table[i]
        if !condition then return end -- So nil values are ignored, to make complex queries easier to do inside of function conditionals (onlyWhitelisted and nzSQL.Q:Equals("whitelisted", "1") or nil)

        return_string = return_string .. condition

        if i != #condition_table then
            return_string = return_string .. " " .. condition_type .. " "
        end
    end

    return return_string
end

-- nzSQL.Q:And({ nzSQL.Q:Equals("name", "gm_flatgrass"), nzSQL.Q:Equals("whitelisted", "1") })
-- Unmodified: "name = 'gm_flatgrass' AND whitelisted = '1'"
function nzSQL.Q:And(condition_table)
    return get_condition_string("AND", condition_table)
end

-- nzSQL.Q:Or({ nzSQL.Q:Contains("name", "ttt_"), nzSQL.Q:Contains("name", "gm_") })
-- Unmodified: "name LIKE '%ttt_%' OR name LIKE '%gm_%'"
function nzSQL.Q:Or(condition_table)
    return get_condition_string("OR", condition_table)
end

-----------------------------------------------------------------
-- Load the subclass files:
local path = "nzombies/gamemode/sql/subclasses/"
local files,_ = file.Find(path .. "*.lua", "LUA")
for _,file in pairs(files) do
    include(path .. file)
end
