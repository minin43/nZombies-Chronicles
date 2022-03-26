-- Recoded from scratch by: Ethorbit
AddCSLuaFile( )

ENT.Type = "anim"

ENT.PrintName		= "Part_table"
ENT.Author			= "Ethorbit"
ENT.Contact			= ""
ENT.Purpose			= ""
ENT.Instructions	= ""
ENT.Editable = true

ENT.NZEntity = true
ENT.BuiltProps = {} -- This holds all the combined props until the item is successfully built
ENT.PartsAdded = {}
ENT.LinkedWorkbenches = {} -- All the workbenches that have the same buildclass as us

function ENT:SetupDataTables() -- Moved all configuration here, so they can be edited in context menu's right-click as well! :D
	local classes = {}
	for k,v in pairs(weapons.GetList()) do
		if !v.NZTotalBlacklist then
			if v.Category and v.Category != "" then
				classes[v.PrintName and v.PrintName != "" and v.Category.. " - "..v.PrintName or v.ClassName] = v.ClassName
			else
				classes[v.PrintName and v.PrintName != "" and v.PrintName or v.ClassName] = v.ClassName
			end
		end
	end
	
	self:NetworkVar("String", 0, "BuildClass", {KeyName = "nz_buildbench_buildclass", Edit = {type = "Combo", title = "Weapon this makes", values = classes, order = -1}})
	self:NetworkVar("Bool", 0, "TreatAsWonderWeapon", {KeyName = "nz_buildbench_wonderweapon", Edit = {type = "Boolean", title = "Wonder Weapon?", order = 1}})
	self:NetworkVar("Bool", 1, "RefillAmmo", {KeyName = "nz_buildbench_refillammo", Edit = {type = "Boolean", title = "Refill ammo on Re-Equip", order = 3}})
	self:NetworkVar("Bool", 2, "AddToBox", {KeyName = "nz_buildbench_addtobox", Edit = {type = "Boolean", category = "Mystery Box", title = "Add to Box? (After Max Crafts)", order = 8}})
	self:NetworkVar("Int", 0, "BoxChance", {KeyName = "nz_buildbench_boxchance", Edit = {type = "Int", category = "Mystery Box", title = "Box Chance", order = 9, min = 1, max = 1000}})
	self:NetworkVar("Int", 1, "CraftUses", {KeyName = "nz_buildbench_craftuses", Edit = {type = "Int", category = "Advanced", title = "Uses Per Craft", order = 5, min = 0, max = 99999}})
	self:NetworkVar("Int", 2, "MaxCrafts", {KeyName = "nz_buildbench_maxcrafts", Edit = {type = "Int", category = "Advanced", title = "Max Allowed Crafts", order = 6, min = 0, max = 99999}})
	self:NetworkVar("Int", 3, "CooldownTime", {KeyName = "nz_buildbench_cooldowntime", Edit = {type = "Int", category = "Advanced", title = "Weapon Cooldown Time", order = 7, min = 0, max = 99999}})
	self:NetworkVar("Int", 4, "MaxParts")
	self:NetworkVar("Int", 5, "AddedParts")
	self:NetworkVar("Int", 6, "WeaponsGiven")
	self:NetworkVar("Int", 7, "CraftedItemCount")
	self:NetworkVar("Int", 8, "CurrentCooldownTime")
	self:NetworkVar("Bool", 3, "Completed")
	self:NetworkVar("Bool", 4, "InUse")

	self:SetBuildClass("")	
	self:SetTreatAsWonderWeapon(false)
	self:SetRefillAmmo(false)
	self:SetCraftUses(99999)
	self:SetMaxCrafts(99999)
	self:SetCooldownTime(0)
	self:SetAddToBox(false)
	self:SetBoxChance(10)
end	

function ENT:Initialize()
	self:SetModel("models/nzprops/table_workbench.mdl")
	self:SetMoveType( MOVETYPE_NONE )
	self:SetSolid(SOLID_VPHYSICS)
	self:Reset()

	if SERVER then
		self:SetUseType( SIMPLE_USE )
	end
end

function ENT:Reset()
	hook.Remove("DecideBoxWeapons", "WorkbenchRandomBoxWeapon" .. self:EntIndex())
	hook.Remove("WindBoxWeapons", "WorkbenchRandomBoxWind" .. self:EntIndex())
	self:ClearProps()

	self:SetCompleted(false)
	self:SetInUse(false)
	self:SetAddedParts(0)
	self:SetMaxParts(0)
	self:SetCraftedItemCount(0)
	self:SetWeaponsGiven(0)

	self.PartsAdded = {}
	self.LinkedWorkbenches = {}
	self.ValidWeapon = nil

	for _,v in pairs(nzParts:GetAll()) do
		self:AddNewPart(v)
	end

	-- Auto link all the workbenches that use our buildclass
	for _,bench in pairs(nzBenches:GetByBuildClass(self:GetBuildClass())) do
		if bench != self then
			self.LinkedWorkbenches[#self.LinkedWorkbenches + 1] = bench
		end
	end

	-- Respawn all the parts attached to us if they are disabled
	for _,part in pairs(nzParts:GetByBuildClass(self:GetBuildClass())) do
		part:SetInvalid(false)

		if part:IsDisabled() then
			part:Reset()
		end
	end
end

function ENT:AddLinkedBench(bench)
	if bench != self then
		self.LinkedWorkbenches[#self.LinkedWorkbenches + 1] = bench
	end
end

function ENT:GetWeapon() -- Get the weapon table of the Workbench's BuildClass
	if self.ValidWeapon then return self.ValidWeapon end
	self.ValidWeapon = weapons.Get(self:GetBuildClass())
	return self.ValidWeapon
end

function ENT:WeaponNotDuplicate() -- If we are allowed to give out players our built weapon
	if !self:GetTreatAsWonderWeapon() then return true end
	return !nzWeps:IsWonderWeaponOut(self:GetBuildClass(), true) -- We just reuse what the gamemode uses for REAL wonder weapons
end

function ENT:FilterCompatibleParts(parts) -- Returns the parts passed in that are compatible with this bench
	local partTbl = {}

	for _,part in pairs(parts) do
		if self:IsPartCompatible(part) then
			partTbl[#partTbl + 1] = part
		end
	end

	return partTbl 
end

function ENT:IsPartCompatible(part) -- If this part can be used to build something
	return !self.BuiltProps[part] and (#nzBenches:GetAll() == 1 or (self.GetBuildClass and part.GetBuildClass and self:GetBuildClass() == part:GetBuildClass()))
end

function ENT:AttachProp(mdl, relPos, interaction, slot) -- Attaches a prop to the Workbench
	local prop = ents.Create("workbench_prop")
	prop:SetParent(self)
	prop:SetOwner(self)
	prop:SetModel(mdl)
	prop:SetLocalPos(relPos)
	prop:Spawn()
	prop:Activate()

	if interaction then
		prop:SetBenchInteraction(true)
	end

	self.BuiltProps[slot or prop] = prop
end

function ENT:AddParts(parts) -- Add a table of Parts to the workbench
	self:SetAddedParts(self:GetAddedParts() + table.Count(parts))

	for _,part in pairs(parts) do
		if SERVER then
			self:AttachProp(part:GetModel(), Vector(0,0,50))
		end

		part:Disable()
		part:StopRespawnTimer() -- We don't want this to respawn, we'll enable it again if our built item amount threshold is reached and it can be rebuilt again
	end
end

function ENT:RemoveParts(parts) -- Remove a table of Parts from the workbench
	self:SetAddedParts(math.Clamp(self:GetAddedParts() - table.Count(parts), 0, self:GetAddedParts()))

	if SERVER then
		for _,part in pairs(parts) do
			if IsValid(self.BuiltProps[part]) then
				self.BuiltProps[part]:Remove()
			end

			self.BuiltProps[part] = nil
		end
	end
end

function ENT:FinishCrafting()
	self:SetCompleted(true)
	self:ClearProps()

	if self:GetCraftUses() > 0 and self:GetWeapon().WorldModel then -- The craftuses check is there because if you're unable to ever use it, why show the weapon model like you can?
		local newPart = ents.Create("workbench_prop")
		self:AttachProp(self:GetWeapon().WorldModel, Vector(0,0,40), true, 1)	
		if #self.LinkedWorkbenches > 0 then for _,v in pairs(self.LinkedWorkbenches) do v:AttachProp(self:GetWeapon().WorldModel, Vector(0,0,40), true, 1) end end
	end

	self:SetCraftedItemCount(self:GetCraftedItemCount() + 1)
end

function ENT:StartTimedUse(ply) -- This function makes the entity use progress-based using instead of normal
	if self:GetInUse() then return end -- Someone's already building something
	if !self:GetWeapon() then print("[NZ Workbench] Weapon class points to non-existent entity, this will cease to function.", game.GetMap()) return end
	
	if IsValid(ply) then
		if self:GetCompleted() and self:WeaponNotDuplicate() and CurTime() > self:GetCurrentCooldownTime() then
			if !ply:HasWeapon(self:GetBuildClass()) then	
				if self:GetCraftUses() > 0 then 
					if SERVER then
						local wep = ply:GiveNoAmmo(self:GetBuildClass())	
						--nzWeps:TrackAmmo(ply, self:GetBuildClass()) 

						-- Ammo stuff
						if !self:GetRefillAmmo() then
							wep:RestoreTrackedAmmo()	
						end
					end
					
					self:SetCurrentCooldownTime(CurTime() + self:GetCooldownTime())
				end 

				self:SetWeaponsGiven(self:GetWeaponsGiven() + 1)
		
				if (self:GetWeaponsGiven() >= self:GetCraftUses()) then -- The maximum allowed uses of this craft item was reached
					self:ClearProps()
					self:SetCompleted(false)
					self:SetAddedParts(0)
					
					if self:GetCraftedItemCount() < self:GetMaxCrafts() then -- Only respawn our parts if we're able to build again
						self:SetWeaponsGiven(0)
						
						for _,part in pairs(nzParts:GetByBuildClass(self:GetBuildClass())) do
							part:Reset()
						end
					elseif (self:GetAddToBox()) then -- We're unable to build anymore and we have the AddToBox (After Max Crafts) option enabled, so add the weapon to the Mystery Box now
						hook.Add("DecideBoxWeapons", "WorkbenchRandomBoxWeapon" .. self:EntIndex(), function(buyer, guns)
							guns[self:GetBuildClass()] = self:GetBoxChance()
							return guns
						end)

						hook.Add("WindBoxWeapons", "WorkbenchRandomBoxWind" .. self:EntIndex(), function(buyer, guns)
							if guns then 
								guns[#guns + 1] = self:GetBuildClass()
								return guns
							end
						end)
					end
				end
			end
		elseif ply:HasPartsForBench(self) then
			if (self:GetCraftedItemCount() >= self:GetMaxCrafts()) then return end
			if #self.LinkedWorkbenches > 0 then for _,v in pairs(self.LinkedWorkbenches) do v:SetInUse(true) end end
			self:SetInUse(true)
			ply:Give("nz_packapunch_arms") -- For the animation
			return 2.5 -- We only return here, other cases it doesn't even use time
		end
	end
end

function ENT:StopTimedUse(ply)
	ply:SetUsingSpecialWeapon(false)
	ply:StripWeapon("nz_packapunch_arms")
	ply:EquipPreviousWeapon()

	self:SetInUse(false)
	if #self.LinkedWorkbenches > 0 then for _,v in pairs(self.LinkedWorkbenches) do v:SetInUse(false) end end
end

function ENT:FinishTimedUse(ply)
	if IsValid(ply) then
		if !self:GetCompleted() then -- We do nothing if we can no longer craft
			local plyParts = self:FilterCompatibleParts(ply:GetParts())
			ply:StripParts(plyParts)

			self:AddParts(plyParts)		
			if #self.LinkedWorkbenches > 0 then for _,v in pairs(self.LinkedWorkbenches) do v:AddParts(plyParts) end end

			if (self:GetAddedParts() >= self:GetMaxParts()) then
				
				self:FinishCrafting()
				if #self.LinkedWorkbenches > 0 then for _,v in pairs(self.LinkedWorkbenches) do v:FinishCrafting() end end
			end
		end
	end

	self:SetInUse(false)
	if #self.LinkedWorkbenches > 0 then for _,v in pairs(self.LinkedWorkbenches) do v:SetInUse(false) end end
end

function ENT:ClearProps() -- Cleanup all the attached part props
	for _,v in pairs(self.BuiltProps) do
		if (IsValid(v)) then
			v:Remove()
		end
	end	

	self.BuiltProps = {}
end

function ENT:AddNewPart(part) -- New part was created in the game
	if (!self.PartsAdded[part:GetModel()] and self:IsPartCompatible(part)) then
		self:SetMaxParts(self:GetMaxParts() + 1)
		self.PartsAdded[part:GetModel()] = true
	end
end

function ENT:RemoveOldPart(part) -- A part was removed from the game
	-- if (self:IsPartCompatible(part)) then
	-- 	self:SetMaxParts(self:GetMaxParts() - 1)
	-- 	--self:SetAddedParts(math.Clamp(self:GetAddedParts() - 1, 0, self:GetAddedParts()))
	-- 	self.PartsAdded[part:GetModel()] = false
	-- end
end

function ENT:RemoveParts()
	self.PartsAdded = {}
	self:SetMaxParts(0)
end

if CLIENT then -- Text related stuff for clients only
	function ENT:GetMaxUsesText()
		if (self:GetCraftUses() < 200) then return "  -  " .. (self:GetCraftUses() - self:GetWeaponsGiven()) .. " left." end -- I'm assuming if it's any higher than 100 then it will likely never be hit and if it does it won't cause too much confusion
		return ""
	end

	function ENT:GetWeaponName()
		return (self:GetWeapon() and self:GetWeapon().PrintName) or self:GetBuildClass()
	end

	function ENT:PutWeaponNameAtEndOfText(text, force)
		if force or self:GetAddedParts() > 0 then
			return text .. " [" .. self:GetWeaponName() .. "]"
		else
			return text
		end
	end

	function ENT:GetNZTargetText() -- The text when looking at this
		if LocalPlayer():IsInCreative() then return self:PutWeaponNameAtEndOfText("Workbench", true) end
		if !LocalPlayer():GetNotDowned() then return "You cannot use this when down." end
		if !self:GetWeapon() then return "Broken Workbench (Non existent weapon)" end
		if !self:WeaponNotDuplicate() then return "Workbench (Weapon already in use)" end
		
		if self:GetCraftedItemCount() >= self:GetMaxCrafts() and self:GetWeaponsGiven() >= self:GetCraftUses() then -- When no more weapons can be crafted and all the weapons have been given
			if self:GetAddToBox() then return "Workbench (" .. self:GetWeaponName() .. " is in the Mystery Box now)" end

			return self:PutWeaponNameAtEndOfText("Workbench (No longer usable)")
		end

		if self:GetCompleted() then -- When the weapon has been crafted
			if CurTime() < self:GetCurrentCooldownTime() then return "Workbench (On Cooldown for " .. math.Round(self:GetCurrentCooldownTime() - CurTime()) .. " seconds)" end
			if LocalPlayer():HasWeapon(self:GetBuildClass())  then return "Workbench (You already have this weapon)" end
			return "Workbench (Press " .. nzDisplay.GetKeyFromCommand("+use") .. " to take " .. self:GetWeaponName() .. ")" .. self:GetMaxUsesText()
		end

		if self:GetInUse() then return "Workbench (In use)" end
		if LocalPlayer():HasParts() and !LocalPlayer():HasPartsForBench(self) then return self:PutWeaponNameAtEndOfText("Workbench (Incompatible Parts)") end
		if self:GetMaxParts() <= 0 then return "Workbench (There are no parts for this)" end
		
		return self:PutWeaponNameAtEndOfText("Workbench (" .. self:GetAddedParts() .. "/" .. self:GetMaxParts() .. " parts needed)")
	end	
end

function ENT:OnRemove()
	hook.Remove("DecideBoxWeapons", "WorkbenchRandomBoxWeapon" .. self:EntIndex())
	hook.Remove("WindBoxWeapons", "WorkbenchRandomBoxWind" .. self:EntIndex())
	self:ClearProps()
end