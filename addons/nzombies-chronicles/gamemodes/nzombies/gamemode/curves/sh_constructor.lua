if SERVER then
	-- Main Tables
	nzCurves = nzCurves or AddNZModule("Curves")

	function nzCurves.GenerateHealthCurve(round, ignorecap, vanilla)
		if !ignorecap then
			round = math.Clamp(round, -1, nzMapping.Settings.maxhealthround) -- Map defined round health cap.
		end

		local base = GetConVar("nz_difficulty_zombie_health_base"):GetFloat()
		local scale = GetConVar("nz_difficulty_zombie_health_scale"):GetFloat()

		if (vanilla) then -- What nZombies used to have for health scaling
			return math.Round(base*math.pow(scale,round - 1))
		end
		
		-- What it should actually be if we're going off of BO1:
		local first10RoundScale = base + (math.Clamp(base - 50, 10, math.huge) * math.Clamp(round - 1, 0, 8)) -- The first 10 rounds have different scaling.

		if (round >= 10) then
			local hp = first10RoundScale

			for i = 9, round - 1 do
				hp = math.floor(hp * scale)
			end

			return hp
		else
			return first10RoundScale
		end
	end

	function nzCurves.GenerateHellHoundHealth(round)
		local baseScale = GetConVar("nz_difficulty_zombie_health_scale"):GetFloat()
		local extraScale = math.Clamp(baseScale - 1.1, baseScale, math.huge) 
		local extraBase = GetConVar("nz_difficulty_zombie_health_base"):GetFloat() - 75

		if extraScale <= 0 then 
			extraScale = 1 
		end

		local val = 800 + extraBase
		local specialCount = nzRound:GetSpecialCount() + 1

		-- This logic copies what's in BO1's Source Code
		if (specialCount == 1) then
			val = (200 + extraBase) * extraScale
		elseif (specialCount == 2) then
			val = (450 + extraBase) * extraScale
		elseif (specialCount == 3) then
			val = (650 + extraBase) * extraScale
		else
			val = (800 + extraBase) * extraScale
		end

		return val
	end

	function nzCurves.GenerateMaxZombies(round)
		if round == -1 then return math.huge end -- It's round infinity, so do infinite zombies.

		local base = GetConVar("nz_difficulty_zombie_amount_base"):GetInt()
		local scale = GetConVar("nz_difficulty_zombie_amount_scale"):GetFloat()
		local num = math.Round((base + (scale * (#player.GetAllPlaying() - 1))) * round)
		
		return math.Round((base + (scale * (#player.GetAllPlaying() - 1))) * round)
	end

	function nzCurves.GenerateSpeedTable(round)
		if !round then return {[50] = 100} end -- Default speed for any invalid round (Say, creative mode test zombies)
		local tbl = {}
		local range = 3 -- The range on either side of the tip (current round) of speeds in steps of "steps"
		local min = 30 -- Minimum speed (Round 1)
		local max = 200 -- Maximum speed
		local custMax = nzMapping.Settings.maxzombiespeed
		if (isnumber(custMax) and custMax > 0) then
			max = custMax
		end

		local maxround = nzMapping.Settings.maxspeedround --27 -- The round at which the max speed has its tip
		local steps = ((max-min)/maxround) -- The different speed steps speed can exist in

		print("Generating round speeds with steps of "..steps.."...")
		for i = -range, range do
			local speed = (min - steps + steps*round) + (steps*i)
			if speed >= min and speed <= max then
				local chance = 100 - 10*math.abs(i)^2
				--print("Speed is "..speed..", with a chance of "..chance)
				tbl[speed] = chance
			elseif speed >= max then
				tbl[max] = 100
			end
		end
		return tbl
	end

	local startVar = GetConVar("nz_difficulty_barricade_points_cap_start")
	local perroundVar = GetConVar("nz_difficulty_barricade_points_cap_per_round")
	local maximumVar = GetConVar("nz_difficulty_barricade_points_cap_max")
	function nzCurves.GenerateBarricadePointCap(round)
		if startVar and maximumVar and perroundVar then
			local start = startVar:GetFloat()
			local maximum = maximumVar:GetFloat()
			local perround = perroundVar:GetFloat()

			if !round then return maximum end 
			if round <= 1 then return start end

			return math.Clamp(start + (perround * (round - 1)), 0, maximum)
		end

		return 500
	end
end
