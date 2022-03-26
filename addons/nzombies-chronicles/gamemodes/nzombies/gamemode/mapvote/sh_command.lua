if (ulx) then -- The ULX command is preferrable as that's what MapVote used originally
    local function AMB_mapvote( calling_ply, votetime, should_cancel )
    	if not should_cancel then
    		nzMapVote.Start(votetime, nil, nil, nil)
    		ulx.fancyLogAdmin( calling_ply, "#A called a votemap!" )
    	else
    		nzMapVote.Cancel()
    		ulx.fancyLogAdmin( calling_ply, "#A canceled the votemap" )
    	end
    end

    local CATEGORY_NAME = "nZombies MapVote"
    local mapvotecmd = ulx.command( CATEGORY_NAME, "mapvote", AMB_mapvote, "!mapvote" )
    mapvotecmd:addParam{ type=ULib.cmds.NumArg, min=15, default=25, hint="time", ULib.cmds.optional, ULib.cmds.round }
    mapvotecmd:addParam{ type=ULib.cmds.BoolArg, invisible=true }
    mapvotecmd:defaultAccess( ULib.ACCESS_ADMIN )
    mapvotecmd:help( "Invokes the map vote logic" )
    mapvotecmd:setOpposite( "unmapvote", {_, _, true}, "!unmapvote" )
elseif SERVER then -- But we can compromise with a normal server gmod command instead.
    concommand.Add("mapvote", function(ply, cmd, args)
        if IsValid(ply) and !ply:IsNZAdmin() then return end

        local votetime = args[1]
        nzMapVote.Start(votetime, nil, nil, nil)
    end)

    concommand.Add("unmapvote", function(ply)
        if IsValid(ply) and !ply:IsNZAdmin() then return end
        nzMapVote.Cancel()
    end)
end

nzChatCommand.Add("/mapvote", SERVER, function(ply, text)
    nzMapVote.Start(nil, nil, nil, nil)
end, false, "   Activates the Map Vote.")
