-- SQL support added to nZombies by: Ethorbit.

-- This is because Chronicles adds many things that are
-- better suited in databases rather than text files. (Record System, Map Stats, Player Stats, and more)

-- Check the README.MD for more information.

nzSQL = nzSQL or {}

function nzSQL:ShowError(message)
    PrintMessage(HUD_PRINTTALK, "nZombies Database Error, check the host's console for details or inform an admin.")
    ServerLog(string.format("[nZombies] %s (%s)\n", message, sql.LastError()))
end

-- Override below functions in a thirdparty addon if you want to
-- use a different database other than Gmod's SQLite sv.db file

-- If you're not comfortable with this, you can override the individual
-- functions from the other sql/ .lua files instead


-- nzSQL:CreateTable("nz_maps", { {"test", {"PRIMARY", "NOT NULL"}, "test2", {"INT", "NOT NULL"} })
function nzSQL:CreateTable(tbl_name, category_tables)
    local query = string.format("CREATE TABLE %s (", SQLStr(tbl_name))

    for i = 1, #category_tables do
        local category_table = category_tables[i]

        local category_name = category_table.name
        local category_properties = category_table.properties

        --query = query ..

        --query = query .. category

        if k != #categories then
            query = query .. ","
        end
    end

    query = query .. ");"
end

-- nzSQL:Equals("name", "nz_ravine")
function nzSQL:Equals(first, second)
    return string.format("%s = %s", SQLStr(first), SQLStr(second))
end

-- nzSQL:Like("name", "nz_ra")
function nzSQL:Like(first, second)
    return string.format("%s LIKE %s", SQLStr(first), SQLStr("%" .. second .. "%"))
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

-- nzSQL:Where( nzSQL:AndCondition({ LikeCondition("name", "ttt_"), nzSQL:LikeCondition("name", "gm_") }) )
function nzSQL:And(condition_table)
    return get_condition_string("AND", condition_table)
end

-- nzSQL:OrCondition({ nzSQL:WhereEqualsCondition("name", "gm_flatgrass"), nzSQL:WhereEqualsCondition("name", "gm_construct") })
function nzSQL:Or(condition_table)
    return get_condition_string("OR", condition_table)
end

-- nzSQL:UpdateRow("nz_maps", "category", "Unlisted Maps", nzSQL:Where( nzSQL:Equals("name", "nz_ravine")) )
function nzSQL:UpdateRow(tbl_name, key_name, value, condition)

end

-- local ravineStats = nzSQL:SelectRow("nz_maps", "map", nzSQL:Where( nzSQL:Equals("name", "nz_ravine")) )
function nzSQL:SelectRow(tbl_name, key_name, condition)

end
