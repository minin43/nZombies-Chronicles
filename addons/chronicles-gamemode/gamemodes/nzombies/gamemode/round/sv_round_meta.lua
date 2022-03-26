--pool network strings
util.AddNetworkString( ", nzRoundNumber" )
util.AddNetworkString( ", nzRoundState" )
util.AddNetworkString( ", nzRoundSpecial" )
util.AddNetworkString( "nzPlayerReadyState" )
util.AddNetworkString( "nzPlayerPlayingState" )

nzRound.Number = nzRound.Number or 0 -- Default for reloaded scenarios
nzRound.ZombiesKilled = nzRound.ZombiesKilled or {}

function nzRound:ClearZombiesKilled()
	self.ZombiesKilled = {}
end

function nzRound:GetZombiesKilled(spawner_class)
	if (spawner_class) then
		return self.ZombiesKilled[spawner_class] or 0
	else
		return self.ZombiesKilled["Round"] or 0
	end
end

function nzRound:SetZombiesKilled(num, spawner_class)
	if (spawner_class) then
		self.ZombiesKilled[spawner_class] = num
	else
		self.ZombiesKilled["Round"] = num
	end
end

function nzRound:GetZombiesMax()
	return self.ZombiesMax
end

function nzRound:SetZombiesMax( num )
	self.ZombiesMax = num

	net.Start("update_prog_bar_max")
	net.WriteUInt(nzRound:GetZombiesMax(), 32)
	net.Broadcast()

	net.Start("update_prog_bar_killed")
	net.WriteUInt(nzRound:GetZombiesKilled(), 32)
	net.Broadcast()
end

function nzRound:GetPowerUpsToSpawn()
	return self.PowerupsToSpawn
end

function nzRound:SetPowerUpsToSpawn(num)
	self.PowerupsToSpawn = num
end

function nzRound:SetPowerUpsGrabbed(num)
	self.PowerUpsGrabbed = num
end

function nzRound:GetPowerUpsGrabbed()
	return self.PowerUpsGrabbed
end

function nzRound:SetPowerUpPointsRequired(num)
	self.PowerupPointsRequired = num
end

function nzRound:GetPowerUpPointsRequired()
	return self.PowerupPointsRequired
end

function nzRound:GetZombiesToSpawn()
	return self.ZombiesToSpawn
end
function nzRound:SetZombiesToSpawn(num)
	self.ZombiesToSpawn = num
end
function nzRound:GetZombiesSpawned()
	return self.ZombiesMax - self.ZombiesToSpawn
end

function nzRound:GetZombieHealth()
	return self.ZombieHealth
end

function nzRound:SetZombieHealth( num )
	self.ZombieHealth = num
end

function nzRound:GetHellHoundHealth()
	return self.ZombieHellHoundHealth
end

function nzRound:SetHellHoundHealth( num )
	self.ZombieHellHoundHealth = num
end

function nzRound:GetPanzerHealth()
	return self.PanzerHealth
end

function nzRound:SetPanzerHealth(num)
	self.PanzerHealth = num
end

-- function nzRound:GetNormalSpawner()
-- 	return self.hNormalSpawner
-- end

-- function nzRound:SetNormalSpawner(spawner)
-- 	self.hNormalSpawner = spawner
-- end

-- function nzRound:GetSpecialSpawner()
-- 	return self.hSpecialSpawner
-- end

-- function nzRound:SetSpecialSpawner(spawner)
-- 	self.hSpecialSpawner = spawner
-- end

function nzRound:GetZombieSpeeds()
	return self.ZombieSpeeds
end

function nzRound:SetZombieSpeeds( tbl )
	self.ZombieSpeeds = tbl
end

function nzRound:SetGlobalZombieData( tbl )
	self:SetZombiesMax(tbl.maxzombies or 5)
	self:SetZombieHealth(tbl.health or 75)
	self:SetHellHoundHealth(tbl.hellhoundhealth or 75)
	self:SetSpecial(tbl.special or false)
end

function nzRound:InState( state )
	return self:GetState() == state
end

function nzRound:IsSpecial()
	if nzRound:GetSpecialRoundType() == "Hellhounds" and !nzMapping.Settings.enabledogs then return false end

	return self.SpecialRound or false
end

function nzRound:SetSpecial( bool )
	self.SpecialRound = bool or false
	self:SendSpecialRound( self.SpecialRound )
end

function nzRound:InProgress()
	return self:GetState() == ROUND_PREP or self:GetState() == ROUND_PROG
end

function nzRound:SetState( state )

	local oldstate = self.RoundState
	self.RoundState = state

	self:SendState( state )

	hook.Call("OnRoundChangeState", nzRound, state, oldstate)

end

function nzRound:GetState()

	return self.RoundState

end

function nzRound:SetNumber( number )
	self.Number = number

	self:SendNumber( number )

end

function nzRound:IncrementNumber()

	self:SetNumber( self:GetNumber() + 1 )

end

function nzRound:GetNumber()

	return self.Number

end

function nzRound:AutoSpawnRadius()
	local val = 2500

	local spawns = #ents.FindByClass("player_spawns") > 0 and ents.FindByClass("player_spawns") or ents.FindByClass("info_player_start")
	if spawns then
		local startPoint = spawns[1]:GetPos()

		if startPoint then
			local farthest_zombie_spawn_dist = nil

			for k,v in pairs(ents.FindByClass("nz_spawn_zombie_normal")) do
				if (!farthest_zombie_spawn_dist or startPoint:Distance(v:GetPos()) > farthest_zombie_spawn_dist) then -- This zombie position is currently the farthest
					farthest_zombie_spawn_dist = startPoint:Distance(v:GetPos())
				end
			end

			if farthest_zombie_spawn_dist then
				val = math.Clamp(math.Round(farthest_zombie_spawn_dist / 2.2), 1300, math.huge)
				val = val == 1300 and 0 or val
			end
		end
	end

	return val
end

function nzRound:GetSpawnRadius()
	return #player.GetAllPlaying() > 1 and self.fSpawnRadiusMP or self.fSpawnRadiusSP
end

function nzRound:SetTotalPoints(num)
	self.TotalPoints = num
end

function nzRound:GetTotalPoints()
	return self.TotalPoints or 0
end

function nzRound:SetSpawnRadiusMP(radius)
	self.fSpawnRadiusMP = radius
end

function nzRound:GetSpawnRadiusMP()
	return self.fSpawnRadiusMP
end

function nzRound:SetSpawnRadiusSP(radius)
	self.fSpawnRadiusSP = radius
end

function nzRound:GetSpawnRadiusSP()
	return self.fSpawnRadiusSP
end

function nzRound:GetBarricadePointCap()
	return self.BarricadePointCap
end

function nzRound:SetBarricadePointCap(points)
	self.BarricadePointCap = points
end

function nzRound:GetBoxHasMoved()
	return self.BoxHasMoved
end

function nzRound:SetBoxHasMoved(val)
	self.BoxHasMoved = val
end

function nzRound:SetEndTime( time )

	SetGlobalFloat( "nzEndTime", time )

end

function nzRound:GetEndTime( time )

	GetGlobalFloat( "nzEndTime" )

end

function nzRound:GetNextSpawnTime()
	return self.NextSpawnTime or 0
end
function nzRound:SetNextSpawnTime( time )
	self.NextSpawnTime = time
end
