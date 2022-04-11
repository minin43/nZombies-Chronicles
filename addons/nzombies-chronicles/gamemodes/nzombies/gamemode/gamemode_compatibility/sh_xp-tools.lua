-- XP-Tools support added by: Ethorbit
if !Maxwell then return end

if SERVER then
    -- For my custom HUD stuff
    util.AddNetworkString("DoubleXPGreet")
    util.AddNetworkString("DoubleXPNotify")
end

-- Remove default perks so that programmers can make their own if they REALLY want them
-- Comment this out if you actually want the default Maxwell perks
local exclude = {
    ["Armored I"] = true,
    ["Armored II"] = true,
    ["Endurance I"] = true,
    ["Endurance II"] = true,
    ["Endurance III"] = true,
    ["Resistance"] = true
}

hook.Add(SERVER and "Initialize" or "InitPostEntity", "NZ_RemoveDefaultMaxwellPerks", function()
    for k,v in pairs(Maxwell.Perks) do
        if v.name and exclude[v.name] then
            Maxwell.Perks[k] = nil
            print("[nZ Maxwell XP Compatibility] Removed default perk (" .. v.name .. ")")
        end
    end
end)

-- More config options (commands are in config/sh_constructor.lua)
Maxwell.XPFromNPCs = GetConVar("nz_xp_from_zombies_allowed"):GetBool()
Maxwell.XPFromReviving = GetConVar("nz_xp_from_reviving_allowed"):GetBool()
Maxwell.XPFromDoors = GetConVar("nz_xp_from_doors_allowed"):GetBool() -- Scales with cost
Maxwell.XPFromBarriers = GetConVar("nz_xp_from_barriers_allowed"):GetBool()
Maxwell.XPFromPowerUps = GetConVar("nz_xp_from_powerups_allowed"):GetBool()
Maxwell.XPFromBox = GetConVar("nz_xp_from_box_allowed"):GetBool()
Maxwell.XPFromBoss = GetConVar("nz_xp_from_boss_allowed"):GetBool()
Maxwell.XPFromRecords = GetConVar("nz_xp_from_map_records_allowed"):GetBool()
Maxwell.XPAmountFromNPCs = GetConVar("nz_xp_amount_from_zombies"):GetInt()
Maxwell.XPAmountFromRevives = GetConVar("nz_xp_amount_from_reviving"):GetInt()
Maxwell.XPAmountFromBarriers = GetConVar("nz_xp_amount_from_barriers"):GetInt()
Maxwell.XPAmountFromPowerUps = GetConVar("nz_xp_amount_from_powerups"):GetInt()
Maxwell.XPAmountFromBox = GetConVar("nz_xp_amount_from_box"):GetInt()
Maxwell.XPAmountFromBoss = GetConVar("nz_xp_amount_from_boss"):GetInt()
Maxwell.XPAmountFromRecords = GetConVar("nz_xp_amount_from_map_records"):GetInt()

-- Fix checking Perks without first seeing if they're even enabled or not
hook.Add('PlayerInitialSpawn', 'LoadOnConnect', function(ply)

	Log('Loading data for ' .. ply:Nick() .. ' - ' .. ply:SteamID() .. ' (CONNECT)') --Log this
	ply:LoadXP()

	if Maxwell.PerksEnabled == false then return end -- This was the fix
	ply:FetchPerks()
	ply:NetPerks() --Networking perks

end)

hook.Add('PlayerLevelUp', 'LevelUpCheckPerks', function(ply, lvl)
	if Maxwell.PerksEnabled == false then return end -- This was the fix

    for i=1,#Maxwell.Perks do

		if (!Maxwell.Perks[i]['cat'] and lvl == Maxwell.Perks[i]['lvl']) then

			Maxwell.PerksFunctions[i](ply)

		end

	end
end)

hook.Add('PlayerSpawn', 'PerksOnSpawn', function(ply)
	if Maxwell.PerksEnabled == false then return end -- This was the fix

	--Weird thing where player hasn't fully spawned yet and perks don't work, so add a 1 second delay
	timer.Simple( 1, function()

		for i=1,#ply.Maxwellperks do
			if Maxwell.Perks[ply.Maxwellperks[i]]['cat'] then
				Maxwell.PerksFunctions[ply.Maxwellperks[i]](ply)
			end

		end

	end)

end)
-----------------------------------

if CLIENT then
    -- Add ability to scale the bar, some people like it thinner, also change the theme to suit nZombies better
    local offsetVar = GetConVar("nz_xp_bar_shrink_amount")
    local ScreenH = ScrH()

    local function BaseHUDOne()
        --local offset = offsetVar and offsetVar:GetFloat() or 0.0
        local ScreenW = ScrW() --- offset
        draw.RoundedBox( 10, 90, 8, ScreenW - 180, 24, Color(0, 0, 0, 255) )

        draw.RoundedBox( 10, ScreenW / 2 - 100, 2, 200, 20, Color(0, 0, 0, 255) )  --Background
        draw.RoundedBox( 10, ScreenW / 2 - 60, 20, 120, 30, Color(0, 0, 0, 255) )  --Background 2

        draw.RoundedBox( 10, ScreenW / 2 - 98, 4, 196, 16, Color(0, 0, 0, 255) )  --Background 3
        draw.RoundedBox( 10, ScreenW / 2 - 58, 22, 116, 26, Color(0, 0, 0, 255) )  --Background 4

        draw.RoundedBox( 0, 100, 12, ScreenW - 200, 16, Color(0, 0, 0, 255) )  --Background 5
        draw.RoundedBox( 0, 102, 14, ScreenW - 204, 12, Color(140, 150, 150, 255) ) --Background 6

        // XP bar

        draw.RoundedBox( 0, 102, 14, math.Clamp((Maxwell.XP / Maxwell.XPReq * (ScreenW - 204)), 0, ScreenW - 204), 12, Color(255, 0, 0, 200) )

        // Level text

        draw.DrawText('Level ' .. Maxwell.Level, 'MaxwellFont', ScreenW / 2, 28, Color(255, 255, 255, 160), TEXT_ALIGN_CENTER)

        //XP Percent Text

        local percent = math.Round( ( (Maxwell.XP or 0)/(Maxwell.XPReq or 1) ) * 100, 2)

        local XPPercent = math.Clamp(percent, 0, 100)

        draw.DrawText(XPPercent..'%', 'MaxwellFont', ScreenW / 2, 10, Color(255, 255, 255, 160), TEXT_ALIGN_CENTER)

    end

    local function BaseHUDTwo()
        local offset = offsetVar and offsetVar:GetFloat() or 0.0
        local ScreenW = ScrW() - offset
        draw.RoundedBox( 0, 400 + (offset / 2), ScreenH-18, ScreenW - 800, 12, Color(0, 0, 0, 255) )  --Background 5
        draw.RoundedBox( 0, 402 + (offset / 2), ScreenH-16, ScreenW - 804, 8, Color(0, 0, 0, 255) ) --Background 6

        // XP bar

        draw.RoundedBox( 0, 402 + (offset / 2), ScreenH - 16, math.Clamp((Maxwell.XP / Maxwell.XPReq * (ScreenW - 800)), 0, ScreenW - 804), 4, Color(255, 0, 0, 200) )
        // Level text

        draw.DrawText('Lv. ' .. Maxwell.Level, 'MaxwellFont', ScreenW / 2 + (offset / 2), ScreenH - 40, Color(255, 255, 255, 160), TEXT_ALIGN_CENTER)

    end

    -- Swap default HUD type, as the original annoys many players to the point of leaving (yes, they're too stupid to use console)
    hook.Add("HUDPaint", "BaseHUD", function()

        if (GetConVarNumber('nz_xp_hudtype') >= 2) then
            BaseHUDOne()
        elseif (GetConVarNumber('nz_xp_hudtype') <= 1) then
            BaseHUDTwo()
        end

    end)
end

-- Remove the XP for doing nothing, there's little point when there's so many ways to get it in nZombies:
print("[nZ Maxwell XP Compatibility] Removed Auto XP timer.")
timer.Remove("AutoXPTimer")

-- Add proper Nextbot support:
