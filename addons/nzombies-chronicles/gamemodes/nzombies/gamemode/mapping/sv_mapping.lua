--

function nzMapping:ZedSpawnerRadiusEditor(radius, has_mp_radius, mp_radius, pos)
	local ent = ents.Create("edit_spawn_radius")
	ent:SetPos(pos)
	ent:Spawn()
	ent:SetRadius(radius)
	ent:SetHasMultiplayerRadius(has_mp_radius)
	ent:SetMultiplayerRadius(mp_radius)

	return ent
end

function nzMapping:ZedSpawn(class, pos, link, spawnnearplayers, customsettings, ply)
	-- if (true) then
	-- 	nzMapping:PropBuy(pos, Angle(0,0,0), "models/nz_zombie/zombie_hellhound.mdl", nil, ply)
	-- return end

	local ent = ents.Create(class or "nz_spawn_zombie_normal")
	pos.z = pos.z - ent:OBBMaxs().z
	ent:SetModel("models/nz_zombie/zombie_hellhound.mdl")
	ent:SetPos( pos )
	ent:Spawn()

	if (customsettings and ent.SetCustomSettings) then
		ent:SetCustomSettings(customsettings)
	end

	-- For the link displayer
	if link != nil and link != "disabled" then
		ent:SetLink(tostring(link))
		ent.link = tostring(link)
	end

	if link == nil or #link <= 0 then
		ent.flag = 0
	end

	if spawnnearplayers != nil then
		ent:SetSpawnNearPlayers(spawnnearplayers)
	else -- So we don't break all configs, we make sure undefined just means zombies can spawn near players
		if (class == "nz_spawn_zombie_special" or class == "nz_spawn_zombie_dog") then
			ent:SetSpawnNearPlayers(false)
		else
			ent:SetSpawnNearPlayers(true)
		end
	end

	if ply then
		undo.Create( ent.PrintName .. " Spawnpoint" )
			undo.SetPlayer( ply )
			undo.AddEntity( ent )
		undo.Finish( "Effect (" .. tostring( model ) .. ")" )
	end
	return ent
end

function nzMapping:PlayerSpecialSpawn(pos, link, ply)

	local ent = ents.Create("nz_spawn_player_special")
	pos.z = pos.z - ent:OBBMaxs().z
	ent:SetPos( pos )
	ent:Spawn()
	-- For the link displayer
	if link != nil then
		ent:SetLink(tostring(link))
		ent.link = tostring(link)
	end

	if ply then
		undo.Create( "Special Player Spawnpoint" )
			undo.SetPlayer( ply )
			undo.AddEntity( ent )
		undo.Finish( "Effect (" .. tostring( model ) .. ")" )
	end
	return ent
end

function nzMapping:PlayerSpawn(pos, ply)

	local ent = ents.Create("player_spawns")
	pos.z = pos.z - ent:OBBMaxs().z
	ent:SetPos( pos )
	ent:Spawn()

	if ply then
		undo.Create( "Player Spawnpoint" )
			undo.SetPlayer( ply )
			undo.AddEntity( ent )
		undo.Finish( "Effect (" .. tostring( model ) .. ")" )
	end
	return ent

end

function nzMapping:EasterEgg(pos, ang, model, ply)
	local egg = ents.Create( "easter_egg" )
	egg:SetModel( model )
	egg:SetPos( pos )
	egg:SetAngles( ang )
	egg:Spawn()

	local phys = egg:GetPhysicsObject()
	if phys:IsValid() then
		phys:EnableMotion(false)
	end

	if ply then
		undo.Create( "Easter Egg" )
			undo.SetPlayer( ply )
			undo.AddEntity( egg )
		undo.Finish( "Effect (" .. tostring( model ) .. ")" )
	end
	return egg
end

function nzMapping:WallBuy(pos, gun, price, angle, oldent, ply, flipped)

	if IsValid(oldent) then oldent:Remove() end

	local ent = ents.Create("wall_buys")
	ent:SetAngles(angle)
	pos.z = pos.z - ent:OBBMaxs().z
	ent:SetPos( pos )
	ent:SetWeapon(gun, price)
	ent:Spawn()
	--ent:PhysicsInit( SOLID_VPHYSICS )

	local phys = ent:GetPhysicsObject()
	if phys:IsValid() then
		phys:EnableMotion(false)
	end

	if flipped != nil then
		ent:SetFlipped(flipped)
	end

	if ply then
		undo.Create( "Wall Gun" )
			undo.SetPlayer( ply )
			undo.AddEntity( ent )
		undo.Finish( "Effect (" .. tostring( model ) .. ")" )
	end
	return ent

end

function nzMapping:PropBuy(pos, ang, model, flags, ply)
	local prop = ents.Create( "prop_buys" )
	prop:SetModel( model )
	prop:SetPos( pos )
	prop:SetAngles( ang )
	prop:Spawn()
	prop:PhysicsInit( SOLID_VPHYSICS )

	if flags == nil or flags == 0 or flags == "disabled" then
		prop.flag = 0
	else
		prop.flag = 1
	end

	-- REMINDER APPY FLAGS
	if flags != nil then
		nzDoors:CreateLink( prop, flags )
	end

	local phys = prop:GetPhysicsObject()
	if phys:IsValid() then
		phys:EnableMotion(false)
	end

	if ply then
		undo.Create( "Prop" )
			undo.SetPlayer( ply )
			undo.AddEntity( prop )
		undo.Finish( "Effect (" .. tostring( model ) .. ")" )
	end
	return prop
end

function nzMapping:Electric(pos, ang, model, ply)
	--THERE CAN ONLY BE ONE TRUE HERO
	local prevs = ents.FindByClass("power_box")
	if prevs[1] != nil then
		prevs[1]:Remove()
	end

	local ent = ents.Create( "power_box" )
	ent:SetPos( pos )
	ent:SetAngles( ang )
	ent:Spawn()
	ent:PhysicsInit( SOLID_VPHYSICS )

	local phys = ent:GetPhysicsObject()
	if phys:IsValid() then
		phys:EnableMotion(false)
	end

	if ply then
		undo.Create( "Power Switch" )
			undo.SetPlayer( ply )
			undo.AddEntity( ent )
		undo.Finish( "Effect (" .. tostring( model ) .. ")" )
	end
	return ent
end

function nzMapping:BlockSpawn(pos, ang, model, flags, ply)
	local block = ents.Create( "wall_block" )
	
	-- Replace with nZombies versions of the same model (if exist) which are grate-based (bullets go through)
	local model2 = string.Replace(model, "/hunter/plates/", "/nzombies_plates/")
	if !util.IsValidModel(model2) then
		model2 = model
	end
	print(model2)
	
	block:SetModel( model2 )
	block:SetPos( pos )
	block:SetAngles( ang )
	block:Spawn()
	block:PhysicsInit( SOLID_VPHYSICS )

	if (nzRound:GetState() != ROUND_CREATE) then
		block:EnableCustomCollisions(true)
		block:SetSolidFlags(FSOLID_CUSTOMRAYTEST)
		block.TestCollision = function (startpos, delta, isbox, extents, mask) 
			if (nzRound:GetState() == ROUND_CREATE) then 
				return true 
			else 
				return false 
			end
		end
	end

	print(block:GetModel())

	-- REMINDER APPLY FLAGS
	if flags != nil then
		nzDoors:CreateLink( block, flags )
	end

	local phys = block:GetPhysicsObject()
	if IsValid(phys) then
		phys:EnableMotion(false)
	end

	if ply then
		undo.Create( "Invisible Block" )
			undo.SetPlayer( ply )
			undo.AddEntity( block )
		undo.Finish( "Effect (" .. tostring( model ) .. ")" )
	end
	return block
end

-- Nothing to say here, I just hate the fucking Source Engine collisions...
hook.Add("OnRoundCreative", "UnFuckTheWallBlockCollisions", function()
	for _,wallblock in pairs(ents.FindByClass("wall_block")) do
		wallblock:EnableCustomCollisions(false)
		wallblock:RemoveSolidFlags(FSOLID_CUSTOMRAYTEST)
		wallblock.TestCollision = nil
	end
end)

hook.Add("OnRoundPlay", "ReFuckTheWallBlockCollisions", function()
	for _,wallblock in pairs(ents.FindByClass("wall_block")) do
		wallblock:EnableCustomCollisions(true)
		wallblock:SetSolidFlags(FSOLID_CUSTOMRAYTEST)
		wallblock.TestCollision = function (startpos, delta, isbox, extents, mask) 
			if (nzRound:GetState() == ROUND_CREATE) then 
				return true 
			else 
				return false 
			end
		end
	end
end)
---------------------------------------------------------------------------

function nzMapping:BlockSpawnZombie(pos, ang, model, ply)
	local block = ents.Create( "wall_block_zombie" )
	
	-- Replace with nZombies versions of the same model (if exist) which are grate-based (bullets go through)
	local model2 = string.Replace(model, "/hunter/plates/", "/nzombies_plates/")
	if !util.IsValidModel(model2) then
		model2 = model
	end
	print(model2)
	
	block:SetModel( model2 )
	block:SetPos( pos )
	block:SetAngles( ang )
	block:Spawn()
	block:PhysicsInit( SOLID_VPHYSICS )
	print(block:GetModel())

	local phys = block:GetPhysicsObject()
	if IsValid(phys) then
		phys:EnableMotion(false)
	end

	if ply then
		undo.Create( "Invisible Zombie Block" )
			undo.SetPlayer( ply )
			undo.AddEntity( block )
		undo.Finish( "Effect (" .. tostring( model ) .. ")" )
	end
	return block
end

function nzMapping:BoxSpawn(pos, ang, spawn, ply)
	local box = ents.Create( "random_box_spawns" )
	box:SetPos( pos )
	box:SetAngles( ang )
	box:Spawn()
	box:PhysicsInit( SOLID_VPHYSICS )
	box:SetCollisionGroup( COLLISION_GROUP_DEBRIS_TRIGGER )
	box.PossibleSpawn = spawn

	if ply then
		undo.Create( "Random Box Spawnpoint" )
			undo.SetPlayer( ply )
			undo.AddEntity( box )
		undo.Finish( "Effect (" .. tostring( model ) .. ")" )
	end
	return box
end

function nzMapping:PerkMachine(pos, ang, id, ply)
	if id == "wunderfizz" then
		local perk = ents.Create("wunderfizz_machine")
		perk:SetPos(pos)
		perk:SetAngles(ang)
		perk:Spawn()
		perk:Activate()
		perk:PhysicsInit( SOLID_VPHYSICS )
		perk:TurnOff()

		local phys = perk:GetPhysicsObject()
		if phys:IsValid() then
			phys:EnableMotion(false)
		end

		if ply then
			undo.Create( "Der Wunderfizz" )
				undo.SetPlayer( ply )
				undo.AddEntity( perk )
			undo.Finish( "Effect (" .. tostring( model ) .. ")" )
		end
		return perk
	else
		local perkData = nzPerks:Get(id)

		local perk = ents.Create("perk_machine")
		perk:SetPerkID(id)
		perk:TurnOff()
		perk:SetPos(pos)
		perk:SetAngles(ang)
		perk:Spawn()
		perk:Activate()
		perk:PhysicsInit( SOLID_VPHYSICS )

		local phys = perk:GetPhysicsObject()
		if phys:IsValid() then
			phys:EnableMotion(false)
		end

		if ply then
			undo.Create( "Perk Machine" )
				undo.SetPlayer( ply )
				undo.AddEntity( perk )
			undo.Finish( "Effect (" .. tostring( model ) .. ")" )
		end
		return perk
	end
end

function nzMapping:BreakEntry(pos, ang, planks, jump, ply)
	local planks = planks
	if planks == nil then planks = true else planks = tobool(planks) end
	local jump = jump
	if jump == nil then jump = false else jump = tobool(jump) end

	local entry = ents.Create( "breakable_entry" )
	entry:SetPos( pos )
	entry:SetAngles( ang )
	entry:SetHasPlanks(planks)
	entry:SetTriggerJumps(jump)
	entry:Spawn()
	entry:PhysicsInit( SOLID_VPHYSICS )

	local phys = entry:GetPhysicsObject()
	if phys:IsValid() then
		phys:EnableMotion(false)
	end

	if ply then
		undo.Create( "Barricade" )
			undo.SetPlayer( ply )
			undo.AddEntity( entry )
		undo.Finish( "Effect (" .. tostring( model ) .. ")" )
	end
	return entry
end

function nzMapping:SpawnEffect( pos, ang, model, ply )

	local e = ents.Create("nz_prop_effect")
	e:SetModel(model)
	e:SetPos(pos)
	e:SetAngles( ang )
	e:Spawn()
	e:Activate()
	if ( !IsValid( e ) ) then return end

	if ply then
		undo.Create( "Effect" )
			undo.SetPlayer( ply )
			undo.AddEntity( e )
		undo.Finish( "Effect (" .. tostring( model ) .. ")" )
	end
	return e

end

function nzMapping:SpawnEntity(pos, ang, ent, ply)
	local entity = ents.Create( ent )
	entity:SetPos( pos )
	entity:SetAngles( ang )
	entity:Spawn()
	entity:PhysicsInit( SOLID_VPHYSICS )

	table.insert(nzQMenu.Data.SpawnedEntities, entity)

	entity:CallOnRemove("nzSpawnedEntityClean", function(ent)
		table.RemoveByValue(nzQMenu.Data.SpawnedEntities, ent)
	end)

	if ply then
		undo.Create( "Entity" )
			undo.SetPlayer( ply )
			undo.AddEntity( entity )
		undo.Finish( "Effect (" .. tostring( model ) .. ")" )
	end
	return entity
end

function nzMapping:CreateInvisibleWall(vec1, vec2, ply)
	local wall = ents.Create( "invis_wall" )
	wall:SetPos( vec1 ) -- Later we might make the position the center
	--wall:SetAngles( ang )
	--wall:SetMinBound(vec1) -- Just the position for now
	wall:SetMaxBound(vec2)
	wall:Spawn()
	wall:PhysicsInitBox( Vector(0,0,0), vec2 )

	local phys = wall:GetPhysicsObject()
	if IsValid(phys) then
		phys:EnableMotion(false)
	end

	if ply then
		undo.Create( "Invis Wall" )
			undo.SetPlayer( ply )
			undo.AddEntity( wall )
		undo.Finish( "Effect (" .. tostring( model ) .. ")" )
	end
	return wall
end

function nzMapping:CreateInvisibleWallZombie(vec1, vec2, ply)
	local wall = ents.Create( "invis_wall_zombie" )
	wall:SetPos( vec1 ) -- Later we might make the position the center
	--wall:SetAngles( ang )
	--wall:SetMinBound(vec1) -- Just the position for now
	wall:SetMaxBound(vec2)
	wall:Spawn()
	wall:PhysicsInitBox( Vector(0,0,0), vec2 )

	local phys = wall:GetPhysicsObject()
	if IsValid(phys) then
		phys:EnableMotion(false)
	end

	if ply then
		undo.Create( "Invis Zombie Wall" )
			undo.SetPlayer( ply )
			undo.AddEntity( wall )
		undo.Finish( "Effect (" .. tostring( model ) .. ")" )
	end
	return wall
end

function nzMapping:CreateAntiCheatExclusion(vec1, vec2, ply)
	local wall = ents.Create( "anticheat_exclude" )
	wall:SetPos( vec1 ) -- Later we might make the position the center
	--wall:SetAngles( ang )
	--wall:SetMinBound(vec1) -- Just the position for now
	wall:SetMaxBound(vec2)
	wall:Spawn()
	wall:PhysicsInitBox( Vector(0,0,0), vec2 )

	local phys = wall:GetPhysicsObject()
	if IsValid(phys) then
		phys:EnableMotion(false)
	end

	if ply then
		undo.Create( "Anti-Cheat Exclusion" )
			undo.SetPlayer( ply )
			undo.AddEntity( wall )
		undo.Finish( "Effect (" .. tostring( model ) .. ")" )
	end
	return wall
end

function nzMapping:CreateAntiCheatWall(vec1, vec2, ply)
	local wall = ents.Create( "anticheat_wall" )
	wall:SetPos( vec1 ) -- Later we might make the position the center
	--wall:SetAngles( ang )
	--wall:SetMinBound(vec1) -- Just the position for now
	wall:SetMaxBound(vec2)
	wall:Spawn()
	wall:PhysicsInitBox( Vector(0,0,0), vec2 )

	local phys = wall:GetPhysicsObject()
	if IsValid(phys) then
		phys:EnableMotion(false)
	end

	if ply then
		undo.Create( "Anti-Cheat Wall" )
			undo.SetPlayer( ply )
			undo.AddEntity( wall )
		undo.Finish( "Effect (" .. tostring( model ) .. ")" )
	end
	return wall
end

function nzMapping:CreateInvisibleDamageWall(vec1, vec2, ply, dmg, delay, radiation, poison, tesla, killzombies)
	local wall = ents.Create( "invis_damage_wall" )
	wall:SetPos( vec1 )
	wall:SetMaxBound(vec2)
	wall:Spawn()
	wall:PhysicsInitBox( Vector(0,0,0), vec2 )
	wall:SetNotSolid(true)
	wall:SetTrigger(true)
	wall:SetKillZombies(tobool(killzombies))
	wall:SetDamage(dmg)
	wall:SetDelay(delay)

	wall:SetRadiation(radiation)
	wall:SetPoison(poison)
	wall:SetTesla(tesla)

	local phys = wall:GetPhysicsObject()
	if IsValid(phys) then
		phys:EnableMotion(false)
	end

	if ply then
		undo.Create( "Damage Wall" )
			undo.SetPlayer( ply )
			undo.AddEntity( wall )
		undo.Finish( "Effect (" .. tostring( model ) .. ")" )
	end
	return wall
end

function nzMapping:Teleporter(data)
	if !data then return end
	local tele = ents.Create("nz_teleporter")
	tele:SetMoveType( MOVETYPE_NONE )
	tele:SetSolid( SOLID_VPHYSICS )
--	tele:SetCollisionGroup( COLLISION_GROUP_DEBRIS_TRIGGER )

	if data.pos != nil then
		tele:SetPos(data.pos)
	end

	if data.angles != nil then
		tele:SetAngles(data.angles)
	end

	if data.flag != nil then
		tele:SetFlag(data.flag)
	end
	
	if data.destination != nil then
		tele:SetDestination(data.destination)
	end

	if data.requiresdoor != nil then
		tele:SetRequiresDoor(data.requiresdoor)
	end

	if data.door != nil then
		tele:SetDoor(data.door)
	end
	
	if data.price != nil then
		tele:SetPrice(data.price)
	end

	if data.mdltype != nil then 
		tele:SetModelType(data.mdltype)
	end

	if data.mdlcollisions != nil then
		tele:SetModelCollisions(data.mdlcollisions)
	end

	if data.visible != nil then
		tele:SetModelVisible(data.visible)
	end

	if data.useable != nil then
		tele:SetUseable(data.useable)
	end

	if data.gif != nil then
		tele:SetGifType(data.gif)
	end

	if data.teleportertime != nil then
		tele:SetTeleporterTime(data.teleportertime)
	end
	
	if data.cooldown != nil then
		tele:SetCooldownTime(data.cooldown)
	end

	if data.tpback != nil then
		tele:SetTPBack(tobool(data.tpback))
	end

	if data.tpbackdelay != nil then
		tele:SetTPBackDelay(data.tpbackdelay)
	end

	if data.activatestrap != nil then
		tele:SetActivatesTrap(data.activatestrap)
	end

	if data.trap != nil then
		tele:SetTrap(data.trap)
	end

	-- Compatibility stuff, just so previous NZR config teleporters continue to work
	-- These will not exist for new configs
	-- (not really a fan of these)
	if data.angle != nil then
		tele:SetAngles(data.angle)
	end
	
	if data.id != nil then
		tele:SetFlag(tostring(data.id))
	end

	if data.desti != nil then
		tele:SetDestination(tostring(data.desti))
	end

	if data.cd != nil then
		tele:SetCooldownTime(data.cd)
	end

	if data.kino != nil then
		tele:SetTPBack(tobool(data.kino))
	end

	if data.delay != nil then
		tele:SetTPBackDelay(data.delay)
	end
	--------------------------------------------------------------------------------

	tele:TurnOff()
	tele:Spawn()

	tele:PhysicsInit( SOLID_VPHYSICS )
	
	local phys = tele:GetPhysicsObject()
	if phys:IsValid() then
		phys:EnableMotion(false)
	end

	if data.ply then
		undo.Create("Teleporter")
		undo.SetPlayer(data.ply)
		undo.AddEntity(tele)
		undo.Finish("Teleporter")
	end

	return tele
end

-- Physgun Hooks
local ghostentities = {
	["prop_buys"] = true,
	["wall_block"] = true,
	["breakable_entry"] = true,
	["invis_wall"] = true,
	["nz_trap_zapper"] = true,
	["nz_script_prop"] = true,
	["buildable_table"] = true,
	["nz_teleporter"] = true
	--["wall_buys"] = true,
}
local function onPhysgunPickup( ply, ent )
	local class = ent:GetClass()
	if ghostentities[class] or ent:ShouldPhysgunNoCollide() then
		-- Ghost the entity so we can put them in walls.
		local phys = ent:GetPhysicsObject()
		if (IsValid(phys)) then
			phys:EnableCollisions(false)
			phys:Wake()
		end
	end

end

local function onPhysgunDrop( ply, ent )
	local class = ent:GetClass()
	if ghostentities[class] or ent:ShouldPhysgunNoCollide() then
		-- Unghost the entity so we can put them in walls.
		local phys = ent:GetPhysicsObject()
		if (IsValid(phys)) then
			phys:EnableCollisions(true)
			phys:EnableMotion(false)
			phys:Sleep()
		end
	end

end

hook.Add( "PhysgunPickup", "nz.OnPhysPick", onPhysgunPickup )
hook.Add( "PhysgunDrop", "nz.OnDrop", onPhysgunDrop )
