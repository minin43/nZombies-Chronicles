-- Created by Ethorbit to aid in dealing with TFA's problematic spaghetti code mess
nzMisc = nzMisc or {}

-- function nzMisc:GetObjectWithDotString(tbl, str) -- Access property of object through a series of dot separated string, example: weapon:GetTable(), "Primary.MaxAmmo"
--     local separated_string = string.Explode(str, ".")
--     local cur_tbl = tbl[separated_string[1]]
--
--     for k,v in pairs(cur_tbl) do
--         if k > 1 and k < #cur_tbl then
--             cur_tbl = cur_tbl[k]
--         end
--     end
--
--     return cur_tbl[separated_string[#separated_string]]
-- end
--
-- function nzMisc:SetObjectValueWithDotString(tbl, str, val) -- Set property's value using a dot separated string instead of normal indexing, example above ^^^^^^^^
--
-- end

--local listeners = {}

-- Add a getter and setter listener for all variables in provided table
-- Created by Ethorbit
function nzMisc:AddListenerToTable(alias, tbl, get_callback, set_callback)
    -- --listeners[alias] = listeners[alias] or {}
    local _tbl = table.Copy(tbl)
    local listener = {
        __index = function(tbl, index)
            local res = !isfunction(get_callback) or get_callback(tbl, index)
            if res == nil or res == true then
                return _tbl[index]
            end
        end,
        __newindex = function(tbl, index, val)
            local res = !isfunction(set_callback) or set_callback(tbl, index, val)
            if res == nil or res == true then
                 _tbl[index] = val
            end
        end
    }

    setmetatable(tbl, listener)
end

-- TODO, add a RemoveListenerFromTable function,
-- I don't even know how to reverse a setmetatable..


-- Goes through all tables of a table and adds a listener to it
-- so that you can see all gets and sets to all variables inside

-- Created by Ethorbit
function nzMisc:RecursivelyAddListenersToTable(alias, tbl, ...)
    if !tbl or !istable(tbl) then return end
    nzMisc:AddListenerToTable(alias, tbl, ...)

    for k,v in pairs(tbl) do
        if istable(v) then
            v.parent = tbl
            v.parentKey = k
            nzMisc:RecursivelyAddListenersToTable(alias, v, ...)
        end
    end
end
