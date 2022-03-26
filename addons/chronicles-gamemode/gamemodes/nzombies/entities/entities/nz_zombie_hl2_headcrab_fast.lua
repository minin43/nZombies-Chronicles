-- I made this as a tribute to the (no longer existing) Half-Life 2: Deathmatch Zombies (@ Phoneburnia) community
-- It may not exist any more, but it was my childhood, and fighting waves of HL2 zombies with teammates was a very fun
-- and unforgettable experience, I'm not letting that get lost to time.
AddCSLuaFile()

ENT.Base = "nz_hl2_headcrab_base"
ENT.PrintName = "PB Fast Headcrab"
ENT.Category = "Brainz"
ENT.Author = "Ethorbit"

ENT.DamageLow = 25
ENT.DamageHigh = 25

ENT.HeadcrabSpeed = 150

ENT.BlockHardcodedSwingSound = true
ENT.BlodHardcodedAttackSound = true
ENT.BlodHardcodedAttackMissSound = true
ENT.PauseOnAttack = false

ENT.Models = {
	"models/headcrab.mdl",
}

ENT.AttackMissSounds = {

}


local AttackSequences = {
--	{seq = "attack", dmgtimes = {0, 0}},
}

local AttackSounds = {
   -- "NPC_Headcrab.Attack",
}

local JumpSequences = {
	{seq = "attack", speed = 15, time = 2.7},
}

ENT.ActStages = {
	[2] = {
		act = ACT_RUN,
		minspeed = 0,
		attackanims = AttackSequences,
		sounds = {},
		barricadejumps = JumpSequences,
	}
}

ENT.RedEyes = false -- We have no eyes, we are a headcrab lol

ENT.ElectrocutionSequences = {
	"Drown",
}

ENT.EmergeSequences = {
	"cannisterDeploy_Middle",
}

ENT.PainSounds = {
	"nzr/zombies/death/nz_flesh_impact_0.wav",
	"nzr/zombies/death/nz_flesh_impact_1.wav",
	"nzr/zombies/death/nz_flesh_impact_2.wav",
	"nzr/zombies/death/nz_flesh_impact_3.wav",
	"nzr/zombies/death/nz_flesh_impact_4.wav"
}
ENT.DeathSounds = {
	"NPC_FastHeadcrab.Die"
}

DEFINE_BASECLASS(ENT.Base)

function ENT:OnInitialize()
	BaseClass.OnInitialize(self)

	if !self:GetDetachedFromZombie() then
		self:SetLastLeap(CurTime() + 2)
	end

	self:SetLeapDelayMin(1.5)
	self:SetLeapDelayMax(1.5)
	self:SetLeapDamage(5.0)
	self:SetLeapDamageRadius(80.0)
end	

function ENT:SetupDataTables()
	self:NetworkVar("Int", 0, "EmergeSequenceIndex")
end

function ENT:StatsInitialize()
	if SERVER then
		self:SetRunSpeed(150)
		self:SetHealth(25)
		self:SetMaxHealth(25)

		--Preselect the emerge sequnces for clientside use
		self:SetEmergeSequenceIndex(math.random(#self.EmergeSequences))
	end
end

function ENT:OnPreHL2Leap()
	self:EmitSound("NPC_FastHeadcrab.Attack")
end