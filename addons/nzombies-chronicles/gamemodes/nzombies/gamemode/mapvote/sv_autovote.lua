-- Made for the automatic Map Vote, ported from a Chronicles server addon.

-- It allows for the map to automatically change when nobody is on (if turned on), which is a nice
-- feature to have if you are running a dedicated server with many maps.

-- (ConVars are in the gamemode's config/ constructor)

nzMapVote = nzMapVote or {}
nzMapVote.AutoVoteUnlocked = false

function nzMapVote.GetAutoUnlockRound()
    return GetConVar("nz_mapvote_unlock_round"):GetInt()
end

function nzMapVote.GetAutoChangeNoPlayers()
    return GetConVar("nz_mapvote_auto_change_no_players"):GetBool()
end

function nzMapVote.GetAutoMap()
    return hook.Run("nzMapVote.GetAutoMap") or table.Random(nzConfig.Maps)
end

local announcedAlready = false
hook.Add("OnGameBegin", "nzAutoMapChangeGameStart", function()
    timer.Simple(1, function()
        PrintMessage(HUD_PRINTTALK, "Map voting will unlock at round " .. nzMapVote.GetAutoUnlockRound() .. ".")
    end)
end)

hook.Add("OnRoundEnd", "nzMapChangeRoundEnd", function(nzRound) -- Game ended
    announcedAlready = false

    if nzMapVote.AutoVoteUnlocked then
        if #player.GetAll() > 0 then -- Don't force change the map when no one is on
            MapVote.Start(nil, nil, nil, nil)
            ServerLog("[nZ] Game ended past round " .. nzMapVote.GetAutoUnlockRound() .. ", MapVote Initiated.")
        else
            nzMapVote.AutoVoteUnlocked = false
        end
    end
end)

hook.Add("OnRoundPreparation", "NZautoMapShouldUnlockVote2", function()
    if nzRound:GetNumber() != nil and !nzMapVote.AutoVoteUnlocked then
        if nzRound:GetNumber() >= nzMapVote.GetAutoUnlockRound() then
            PrintMessage(HUD_PRINTTALK, "Map voting has been unlocked, voting will occur when the game ends.")
            nzMapVote.AutoVoteUnlocked = true
        end
    end
end)

hook.Add("PlayerConnect", "NZMapChangerPlyConnected", function()
    if timer.Exists("NZAutoMapChange") then
        timer.Destroy("NZAutoMapChange")
    end
end)

gameevent.Listen("player_disconnect")
hook.Add("player_disconnect", "NZMapChangerPlyLeft", function() -- Automatically change the map if no one's on
    if (!nzMapVote.GetAutoChangeNoPlayers()) then return end

    timer.Simple(1, function()
        if #player.GetAll() == 0 then -- Nobody's on, make the map change soon
            timer.Create("NZAutoMapChange", GetConVar("nz_mapvote_auto_change_no_players_seconds"):GetInt(), 0, function()
                if (!nzMapVote.GetAutoChangeNoPlayers()) then return end

                if #player.GetAll() == 0 then -- Nobody is on still, it is ok to change
                    hook.Run("MapVoteChange", nzMapVote.GetRandomMap())
                end
            end)
        end
    end)
end)
