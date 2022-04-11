-- File and other TFA compatibility files created by Ethorbit
-- for actual TFA support since they couldn't be bothered to test
if !TFA then return end

local SWEP = FindMetaTable("Weapon")

-- (They broke support for NZ ammo types)
function SWEP:GetPrimaryAmmoTypeC()
    return self:GetPrimaryAmmoType() -- Defined in weapons/sh_ammo.lua
end

-- Remove the silly damage conflicts
hook.Add(SERVER and "Initialize" or "InitPostEntity", "Remove_Garbage_TFA_Hooks", function()
    timer.Simple(0.5, function()
        hook.Remove("EntityTakeDamage", "TFA_MeleeScaling")
        hook.Remove("EntityTakeDamage", "TFA_MeleeReceiveLess")
        hook.Remove("EntityTakeDamage", "TFA_MeleePaP")
    end)
end)

-- This is Old TFA's version of ClearStatCache,

-- I'm adding this because everybody calls this function
-- in their OnPaP weapons and New TFA has made it problematic
-- for that.
function SWEP:ClearStatCache(vn)
    if !self.StatCache or !self.StatCache2 then return end -- Just in case another update..

    if vn then
        self.StatCache[vn] = nil
        self.StatCache2[vn] = nil
    else
        table.Empty(self.StatCache)
        table.Empty(self.StatCache2)
    end
end

-- Give tfa_exp_base a configurable Radius property based on weapon that fired it, instead of just guessing from its damage
-- Hopefully they consider this so I can remove this silly override.. :
hook.Add("OnEntityCreated", "NZC.OverrideTFAExpExplosion", function(ent)
    if ent.Base == "tfa_exp_base" then
        ent.Explode = function()
            local self = ent

            if not IsValid(self.Inflictor) then
                self.Inflictor = self
            end

            self.Damage = self.mydamage or self.Damage

            local dmg = DamageInfo()
            dmg:SetInflictor(self.Inflictor)
            dmg:SetAttacker(IsValid(self:GetOwner()) and self:GetOwner() or self)
            dmg:SetDamage(self.Damage)
            dmg:SetDamageType(bit.bor(DMG_BLAST, DMG_AIRBOAT))

            -- Customizable radius
            local radius
            local wepOwner = self.Owner
            if (IsValid(wepOwner)) then
                local wep = wepOwner:GetActiveWeapon()
                if (IsValid(wep)) then
                    radius = wep.ProjectileRadius
                end
            end

            if (!isnumber(radius)) then
                radius = math.pow( self.Damage / 150, 0.75) * 200
            end

            util.BlastDamageInfo(dmg, self:GetPos(), radius)

            -- Disable the shaking, most people don't like it.
            --util.ScreenShake(self:GetPos(), self.Damage, 255, self.Damage / 200, radius * 1.5)

            self:DoExplosionEffect()

            self:Remove()
        end
    end
end)
