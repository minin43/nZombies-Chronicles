nzSpectate = nzSpectate or {}

--Get the meta Table
local plyMeta = FindMetaTable( "Player" )
--accessors
AccessorFunc( plyMeta, "iSpectatingID", "SpectatingID", FORCE_NUMBER )
AccessorFunc( plyMeta, "iSpectatingType", "SpectatingType", FORCE_NUMBER )

function plyMeta:SetSpectator()
	if self:Alive() then
		self:KillSilent()
	end
	self:SetTeam( TEAM_SPECTATOR )
	self:SetSpectatingType( OBS_MODE_CHASE )
	self:Spectate(OBS_MODE_CHASE)
	self:SetSpectatingID( 1 )
end

local spectate_ent_blacklist = {
	["predicted_viewmodel"] = true,
	["manipulate_bone"] = true,
	["hl2mp_ragdoll"] = true,
}

function plyMeta:SpectateClosestEntity()
	local closestEnt = nzMisc:GetClosestEntityToPosition(self:GetPos(), function(ent)
		--!spectate_ent_blacklist[ent:GetClass()]
		return ent != self and ent:GetParent() != self and ent:IsInWorld() and (!ent:IsPlayer() or ent:Team() == TEAM_PLAYERS)
	end)

	self:SpectateEntity(closestEnt)
end
