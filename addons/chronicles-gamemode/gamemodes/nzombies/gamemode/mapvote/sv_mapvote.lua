nzMapVote = nzMapVote or {}

util.AddNetworkString("RAM_MapVoteStart")
util.AddNetworkString("RAM_MapVoteUpdate")
util.AddNetworkString("RAM_MapVoteCancel")
util.AddNetworkString("RTV_Delay")

hook.Add("Initialize", "MapVoteConfigSetup", function()
    if not file.Exists("mapvote", "DATA") then file.CreateDir("mapvote") end
    if not file.Exists("mapvote/config.txt", "DATA") then
        file.Write("mapvote/config.txt", util.TableToJSON(MapVoteConfigDefault))
    end

    hook.Run("nzMapVote.Initialized")
end)

nzMapVote.CurrentMaps = {}
nzMapVote.Votes = {}

nzMapVote.Allow = false

nzMapVote.UPDATE_VOTE = 1
nzMapVote.UPDATE_WIN = 3

nzMapVote.Continued = false

net.Receive("RAM_MapVoteUpdate", function(len, ply)
    if (nzMapVote.Allow) then
        if (IsValid(ply)) then
            local update_type = net.ReadUInt(3)

            if (update_type == nzMapVote.UPDATE_VOTE) then
                local map_id = net.ReadUInt(32)

                if (nzMapVote.CurrentMaps[map_id]) then
                    nzMapVote.Votes[ply:SteamID()] = map_id

                    net.Start("RAM_MapVoteUpdate")
                    net.WriteUInt(nzMapVote.UPDATE_VOTE, 3)
                    net.WriteEntity(ply)
                    net.WriteUInt(map_id, 32)
                    net.Broadcast()
                end
            end
        end
    end
end)

if file.Exists("mapvote/recentmaps.txt", "DATA") then
    recentmaps = util.JSONToTable(file.Read("mapvote/recentmaps.txt", "DATA"))
else
    recentmaps = {}
end

if file.Exists("mapvote/playcount.txt", "DATA") then
    playCount = util.JSONToTable(file.Read("mapvote/playcount.txt", "DATA"))
else
    playCount = {}
end

if file.Exists("mapvote/config.txt", "DATA") then
    nzMapVote.Config = util.JSONToTable(file.Read("mapvote/config.txt", "DATA"))
else
    nzMapVote.Config = {}
end

local function CoolDownDoStuff()
    cooldownnum = nzMapVote.Config.MapsBeforeRevote or 3

    if table.getn(recentmaps) == cooldownnum then table.remove(recentmaps) end

    local curmap = game.GetMap():lower() .. ".bsp"

    if not table.HasValue(recentmaps, curmap) then
        table.insert(recentmaps, 1, curmap)
    end

    if playCount[curmap] == nil then
        playCount[curmap] = 1
    else
        playCount[curmap] = playCount[curmap] + 1
    end

    file.Write("mapvote/recentmaps.txt", util.TableToJSON(recentmaps))
    file.Write("mapvote/playcount.txt", util.TableToJSON(playCount))
end

function nzMapVote.Start(length, current, limit)
    current = current or GetConVar("nz_mapvote_allow_current_map"):GetBool() or false
    length = length or GetConVar("nz_mapvote_map_time_limit"):GetInt() or 28
    limit = limit or GetConVar("nz_mapvote_item_limit"):GetInt() or 24
    local is_expression = false
    local vote_maps = {}
    local play_counts = {}

    local amt = 0

    for _, map in RandomPairs(nzConfig.Maps) do
        if (!current and map == game.GetMap()) then continue end
        if (nzMapVote.BlacklistedMaps and nzMapVote.BlacklistedMaps[map]) then continue end
        if (nzMapVote.WhitelistedMaps and !nzMapVote.WhitelistedMaps[map]) then continue end

        local plays = playCount[map]

        if (plays == nil) then
            plays = 0
        end

        vote_maps[#vote_maps + 1] = map
        play_counts[#play_counts + 1] = plays
        amt = amt + 1
        if (limit and amt >= limit) then break end
    end

    net.Start("RAM_MapVoteStart")
    net.WriteUInt(#vote_maps, 32)

    for i = 1, #vote_maps do
        net.WriteString(vote_maps[i])
        net.WriteUInt(play_counts[i], 32)
    end

    net.WriteUInt(length, 32)
    net.Broadcast()

    nzMapVote.Allow = true
    nzMapVote.CurrentMaps = vote_maps
    nzMapVote.Votes = {}

    timer.Create("RAM_MapVote", length, 1, function()
        nzMapVote.Allow = false
        local map_results = {}

        for k, v in pairs(nzMapVote.Votes) do
            if (not map_results[v]) then map_results[v] = 0 end

            for k2, v2 in pairs(player.GetAll()) do
                if (v2:SteamID() == k) then
                    map_results[v] = map_results[v] + 1
                end
            end
        end

        CoolDownDoStuff()

        local winner = table.GetWinningKey(map_results) or 1

        net.Start("RAM_MapVoteUpdate")
        net.WriteUInt(nzMapVote.UPDATE_WIN, 3)

        net.WriteUInt(winner, 32)
        net.Broadcast()

        local map = nzMapVote.CurrentMaps[winner]

        timer.Simple(4, function()
            nzMapVote.StartConfig(map) -- Now let them vote for a config
        end)
    end)
end

function nzMapVote.StartConfig(map, length, limit) -- Start a config vote for the specified map
    length = length or GetConVar("nz_mapvote_config_time_limit"):GetInt() or 20
    limit = limit or GetConVar("nz_mapvote_item_limit"):GetInt() or 24

    local config_data = nzConfig.GetMapConfigFileList(map)

    if (#player.GetAll() <= 0 or #config_data <= 1) then -- Nobody's on to choose or there's only 1 config for the map
        if (hook.Run("nzMapVote.ShouldChangeMap", map) ~= false) then
            RunConsoleCommand("changelevel", map)
        end
    return end

    local amt
    local configs

    for _,v in RandomPairs(config_data) do
        config[#configs + 1] = v.configname
        amt = amt + 1
    end
end

hook.Add("Shutdown", "RemoveRecentMaps", function()
    if file.Exists("mapvote/recentmaps.txt", "DATA") then
        file.Delete("mapvote/recentmaps.txt")
    end
end)

function nzMapVote.Cancel()
    if nzMapVote.Allow then
        nzMapVote.Allow = false

        net.Start("RAM_MapVoteCancel")
        net.Broadcast()

        timer.Destroy("RAM_MapVote")
    end
end
