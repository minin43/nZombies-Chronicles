-- File and other TFA compatibility files created by Ethorbit
-- for actual TFA support since they couldn't be bothered to test

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
