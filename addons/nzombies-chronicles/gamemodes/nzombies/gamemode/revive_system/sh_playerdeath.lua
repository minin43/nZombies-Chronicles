
-- Better function by Ethorbit (Doesn't rely on PlayerShouldTakeDamage and ROUNDS the damage with health
-- so that when it checks like 0.5, it actually is 0 and downs the player like it should...)
-- function nzRevive.DoPlayerDeath(ply, dmg)
-- 	if IsValid(ply) and ply:IsPlayer() then
-- 		if (dmg:GetAttacker():IsPlayer()) then return end

-- 		if (math.floor(ply:Health() - dmg:GetDamage()) <= 0) then
-- 			local allow = hook.Call("PlayerShouldTakeDamage", nil, ply, dmg:GetAttacker())
-- 			if allow != false then
-- 				if ply:GetNotDowned() then
-- 					print(ply:Nick() .. " got downed!")
-- 					ply:DownPlayer()
-- 				else
-- 					ply:KillDownedPlayer() -- Kill them if they are already downed
-- 				end
-- 			end
-- 		return true end
-- 	end
-- end

function nzRevive.DoPlayerDeath(ply, dmg)
	if IsValid(ply) and ply:IsPlayer() then
		if (math.floor(ply:Health() - dmg:GetDamage()) <= 0) then
			local allow = hook.Call("PlayerShouldTakeDamage", nil, ply, dmg:GetAttacker())

			if allow != false then -- Only false should prevent it (not nil)
				if ply:GetNotDowned() then
					print(ply:Nick() .. " got downed!")
					ply:DownPlayer()
					--ply:SetMaxHealth(100) -- failsafe for Jugg not resetting
					return true
				else
					ply:KillDownedPlayer() -- Kill them if they are already downed
				end
			end

			return true
		elseif !ply:GetNotDowned() then
			return true -- Downed players cannot take non-fatal damage
		end
	end
end

function nzRevive.PostPlayerDeath(ply)
	-- Performs all the resetting functions without actually killing the player
	if !ply:GetNotDowned() then ply:KillDownedPlayer(nil, false, true) end
end

local function HandleKillCommand(ply)
	if (ply:IsPlaying() and !ply:IsSpectating()) or ply:IsInCreative() then
		if ply:GetNotDowned() then
			ply:DownPlayer()
		else
			ply:KillDownedPlayer()
		end
	end
	return false
end

-- Hooks
hook.Add("EntityTakeDamage", "nzDownKilledPlayers", nzRevive.DoPlayerDeath)
hook.Add("PostPlayerDeath", "nzPlayerDeathRevivalReset", nzRevive.PostPlayerDeath)
hook.Add("CanPlayerSuicide", "nzSuicideDowning", HandleKillCommand)
